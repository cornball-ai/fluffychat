// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'dart:typed_data';

import 'package:grpc/grpc.dart';

import 'pcm_capture.dart';
import 'proto/agent_voice.pbgrpc.dart' as agent;
import 'proto/gpu_voice.pbgrpc.dart' as gpu;
import 'voice_transport.dart';

/// The credentials the transport presents to the agent: a Matrix OpenID
/// token plus the server name that says where it verifies. Obtained by the
/// caller from the Matrix SDK (`Client.requestOpenIdToken`) so this file
/// stays free of a matrix dependency.
class AgentCredentials {
  final String openIdToken;
  final String matrixServerName;
  const AgentCredentials({
    required this.openIdToken,
    required this.matrixServerName,
  });
}

/// [VoiceTransport] over the real wire: gRPC to the agent, and to the two
/// inference endpoints the agent's grant names.
///
/// Thin on purpose -- protocol mapping and channel lifecycle only. Anything
/// resembling a decision (turn taking, segmentation, accounting) lives above
/// the seam in LiveVoiceSession, where it is testable without a server.
class GrpcVoiceTransport implements VoiceTransport {
  /// The agent's address, the one endpoint not learned from the grant.
  final String agentHost;
  final int agentPort;

  /// Whether the agent channel itself uses TLS. The media endpoints carry
  /// their own declared security in the grant; UNSPECIFIED on either is a
  /// refusal, per the schema.
  final bool agentTls;

  final AgentCredentials credentials;

  GrpcVoiceTransport({
    required this.agentHost,
    required this.agentPort,
    required this.agentTls,
    required this.credentials,
  });

  ClientChannel? _agentChannel;
  ClientChannel? _sttChannel;
  ClientChannel? _ttsChannel;
  agent.AgentVoiceClient? _agent;
  gpu.SpeechToTextClient? _stt;
  gpu.TextToSpeechClient? _tts;

  String? _sessionId;
  String? _mediaToken;

  StreamController<gpu.TranscribeRequest>? _sttRequests;
  ResponseStream<gpu.TranscribeEvent>? _sttResponses;
  final StreamController<SttEvent> _transcripts =
      StreamController<SttEvent>.broadcast();

  CallOptions get _agentOptions => CallOptions(
    metadata: {
      'authorization': 'Bearer ${credentials.openIdToken}',
      'matrix-server-name': credentials.matrixServerName,
    },
  );

  CallOptions get _mediaOptions =>
      CallOptions(metadata: {'authorization': 'Bearer $_mediaToken'});

  @override
  Future<void> connect(String roomId) async {
    final agentChannel = ClientChannel(
      agentHost,
      port: agentPort,
      options: ChannelOptions(
        credentials: agentTls
            ? const ChannelCredentials.secure()
            : const ChannelCredentials.insecure(),
      ),
    );
    _agentChannel = agentChannel;
    final agentClient = agent.AgentVoiceClient(agentChannel);
    _agent = agentClient;

    final grant = await agentClient.allocateVoice(
      agent.AllocateVoiceRequest(roomId: roomId),
      options: _agentOptions,
    );
    _sessionId = grant.sessionId;
    _mediaToken = grant.token;

    _sttChannel = _openMediaChannel(grant.speechToText);
    _ttsChannel = _openMediaChannel(grant.textToSpeech);
    _stt = gpu.SpeechToTextClient(_sttChannel!);
    _tts = gpu.TextToSpeechClient(_ttsChannel!);

    _openTranscribeStream();
  }

  ClientChannel _openMediaChannel(agent.Endpoint endpoint) {
    final security = switch (endpoint.security) {
      agent.ChannelSecurity.CHANNEL_SECURITY_TLS =>
        const ChannelCredentials.secure(),
      agent.ChannelSecurity.CHANNEL_SECURITY_INSECURE =>
        const ChannelCredentials.insecure(),
      // The schema's whole point for the three-state enum: absence is a
      // refusal, never a default.
      _ => throw StateError(
        'endpoint ${endpoint.host} declared no channel security',
      ),
    };
    return ClientChannel(
      endpoint.host,
      port: endpoint.port,
      options: ChannelOptions(credentials: security),
    );
  }

  void _openTranscribeStream() {
    final requests = StreamController<gpu.TranscribeRequest>();
    _sttRequests = requests;
    // Config is the first message on the stream, per the schema's
    // INVALID_ARGUMENT rule.
    requests.add(
      gpu.TranscribeRequest(
        config: gpu.TranscribeConfig(
          sampleRateHz: voiceSampleRate,
          channels: voiceNumChannels,
          encoding: gpu.AudioEncoding.AUDIO_ENCODING_PCM_S16LE,
        ),
      ),
    );
    final responses = _stt!.transcribe(requests.stream, options: _mediaOptions);
    _sttResponses = responses;
    responses.listen(
      (event) {
        if (event.hasSpeechEnded()) {
          _transcripts.add(const SttTurnEnded());
        } else if (event.hasTranscript()) {
          _transcripts.add(
            SttTranscript(
              event.transcript.text,
              stable: event.transcript.stable,
            ),
          );
        }
      },
      onError: _transcripts.addError,
      onDone: _transcripts.close,
    );
  }

  @override
  void sendAudio(Uint8List frame) {
    final requests = _sttRequests;
    if (requests == null || requests.isClosed) return;
    requests.add(gpu.TranscribeRequest(audio: frame));
  }

  @override
  Stream<SttEvent> get transcripts => _transcripts.stream;

  @override
  Stream<ReplyEvent> converse(String text) {
    final sessionId = _sessionId;
    if (sessionId == null) throw StateError('converse() before connect()');
    final responses = _agent!.converse(
      agent.ConverseRequest(sessionId: sessionId, text: text),
      options: _agentOptions,
    );
    return responses.map(
      (event) => switch (event.whichEvent()) {
        agent.ConverseEvent_Event.start => ReplyStart(event.start.turnId),
        agent.ConverseEvent_Event.delta => ReplyDelta(event.delta.text),
        agent.ConverseEvent_Event.end => ReplyEnd(event.end.stopReason),
        agent.ConverseEvent_Event.notSet => throw StateError(
          'empty ConverseEvent',
        ),
      },
    );
  }

  @override
  Stream<TtsEvent> synthesize(String text) {
    final responses = _tts!.synthesize(
      gpu.SynthesizeRequest(text: text),
      options: _mediaOptions,
    );
    return responses.map(
      (event) => switch (event.whichEvent()) {
        gpu.SynthesisEvent_Event.start => TtsStart(
          event.start.sampleRateHz,
          totalChunks: event.start.hasTotalChunks()
              ? event.start.totalChunks
              : null,
        ),
        gpu.SynthesisEvent_Event.chunk => () {
          final chunk = event.chunk;
          // Absence is a server bug the accounting must not paper over
          // with a zero -- the schema's presence rule, enforced at the
          // adapter so nothing above ever sees a defaulted offset.
          if (!chunk.hasInputTextEnd()) {
            throw StateError(
              'chunk ${chunk.index} arrived without input_text_end',
            );
          }
          return TtsChunk(
            index: chunk.index,
            duration: Duration(milliseconds: chunk.durationMs),
            inputTextEnd: chunk.inputTextEnd,
            pcm: Uint8List.fromList(chunk.pcm),
          );
        }(),
        gpu.SynthesisEvent_Event.notSet => throw StateError(
          'empty SynthesisEvent',
        ),
      },
    );
  }

  @override
  Future<String> reportTurn({
    required String turnId,
    required int textHeard,
    required TurnResult result,
  }) async {
    final sessionId = _sessionId;
    if (sessionId == null) throw StateError('reportTurn() before connect()');
    final response = await _agent!.reportTurn(
      agent.ReportTurnRequest(
        sessionId: sessionId,
        turnId: turnId,
        // The generated setter records presence, so an explicit zero
        // crosses the wire as a report rather than an omission.
        textHeard: textHeard,
        outcome: switch (result) {
          TurnResult.completed => agent.TurnOutcome.TURN_OUTCOME_COMPLETED,
          TurnResult.bargeIn => agent.TurnOutcome.TURN_OUTCOME_BARGE_IN,
          TurnResult.abandoned => agent.TurnOutcome.TURN_OUTCOME_ABANDONED,
        },
      ),
      options: _agentOptions,
    );
    return response.storedText;
  }

  @override
  Future<void> close() async {
    await _sttRequests?.close();
    _sttRequests = null;
    await _sttResponses?.cancel();
    _sttResponses = null;
    if (!_transcripts.isClosed) await _transcripts.close();
    await _sttChannel?.shutdown();
    await _ttsChannel?.shutdown();
    await _agentChannel?.shutdown();
  }
}

// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fixnum/fixnum.dart';
import 'package:fluffychat/utils/voice/proto/agent_voice.pbgrpc.dart';
import 'package:fluffychat/utils/voice/proto/gpu_voice.pbgrpc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';

// The generated stubs are excluded from `flutter analyze`, so importing them
// here is what forces them through the compiler at test time -- without this,
// a stale or broken regeneration only surfaces when the app itself is built.
// The .pbgrpc.dart imports re-export the message files and pull in the client
// stubs, which nothing else imports yet: the client constructions below exist
// to compile them, not to connect.
void main() {
  test('grpc client stubs compile and construct', () {
    // ClientChannel does not dial until a call is made, so construction is a
    // pure compile-and-wire check.
    final channel = ClientChannel(
      'localhost',
      port: 1,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
    expect(SpeechToTextClient(channel), isNotNull);
    expect(TextToSpeechClient(channel), isNotNull);
    expect(AgentVoiceClient(channel), isNotNull);
  });

  test('total_chunks distinguishes absent from zero', () {
    // The truncation report depends on this: "none dropped" and "the server
    // never said how many" must not collapse into the same value.
    final unsaid = SynthesisStart();
    expect(unsaid.hasTotalChunks(), isFalse);

    final zero = SynthesisStart(totalChunks: 0);
    expect(zero.hasTotalChunks(), isTrue);
    expect(zero.totalChunks, 0);

    // And the distinction has to survive the wire, not just the constructor.
    final decoded = SynthesisStart.fromBuffer(zero.writeToBuffer());
    expect(decoded.hasTotalChunks(), isTrue);
    expect(decoded.totalChunks, 0);
    expect(
      SynthesisStart.fromBuffer(unsaid.writeToBuffer()).hasTotalChunks(),
      isFalse,
    );
  });

  test('chunk index 0 survives a round trip', () {
    // Proto3 does not encode default values, so the first chunk's index is
    // the one that exercises the "field absent means zero" decode path.
    final chunk = AudioChunk(
      index: 0,
      durationMs: 480,
      pcm: [1, 2, 3],
      inputTextEnd: 17,
    );
    final decoded = AudioChunk.fromBuffer(chunk.writeToBuffer());
    expect(decoded.index, 0);
    expect(decoded.durationMs, 480);
    expect(decoded.pcm, [1, 2, 3]);
    expect(decoded.inputTextEnd, 17);
  });

  test('input_text_end zero keeps presence; absence stays detectable', () {
    // A leading-silence first chunk legitimately reports offset 0, and a
    // synthesiser that never implements the field must not look like it.
    // Presence is what keeps those two apart across the wire.
    final leadingSilence = AudioChunk(index: 0, durationMs: 200, pcm: [0, 0])
      ..inputTextEnd = 0;
    final decoded = AudioChunk.fromBuffer(leadingSilence.writeToBuffer());
    expect(decoded.hasInputTextEnd(), isTrue);
    expect(decoded.inputTextEnd, 0);

    // The field left unset decodes as absent -- the client's cue to treat
    // the server as broken rather than the reply as unspoken.
    final unstamped = AudioChunk(index: 0, durationMs: 200, pcm: [0, 0]);
    expect(
      AudioChunk.fromBuffer(unstamped.writeToBuffer()).hasInputTextEnd(),
      isFalse,
    );
  });

  test('transcribe payload discriminates config from audio', () {
    final config = TranscribeRequest(
      config: TranscribeConfig(
        sampleRateHz: 16000,
        channels: 1,
        encoding: AudioEncoding.AUDIO_ENCODING_PCM_S16LE,
      ),
    );
    expect(config.whichPayload(), TranscribeRequest_Payload.config);

    final audio = TranscribeRequest(audio: [0, 0, 0, 0]);
    expect(audio.whichPayload(), TranscribeRequest_Payload.audio);

    // The server's config-first rule needs "neither" to be representable,
    // so an empty message must not read as either arm.
    expect(
      TranscribeRequest().whichPayload(),
      TranscribeRequest_Payload.notSet,
    );
  });

  test('endpoint security is three-state, and absent means refuse', () {
    // A plain bool here once made "the server said nothing" indistinguishable
    // from "the server said insecure" -- absence decayed into an insecure
    // default. The enum's zero value pins absence to UNSPECIFIED, which a
    // client refuses to connect on.
    final undeclared = Endpoint(host: 'h', port: 1);
    final decoded = Endpoint.fromBuffer(undeclared.writeToBuffer());
    expect(decoded.security, ChannelSecurity.CHANNEL_SECURITY_UNSPECIFIED);

    // The two declared states stay distinct across the wire.
    final insecure = Endpoint(
      host: 'h',
      port: 1,
      security: ChannelSecurity.CHANNEL_SECURITY_INSECURE,
    );
    expect(
      Endpoint.fromBuffer(insecure.writeToBuffer()).security,
      ChannelSecurity.CHANNEL_SECURITY_INSECURE,
    );
    final tls = Endpoint(
      host: 'h',
      port: 1,
      security: ChannelSecurity.CHANNEL_SECURITY_TLS,
    );
    expect(
      Endpoint.fromBuffer(tls.writeToBuffer()).security,
      ChannelSecurity.CHANNEL_SECURITY_TLS,
    );
  });

  test('allocation response carries both endpoints independently', () {
    // Separate fields because the two models need not be co-resident.
    final response = AllocateVoiceResponse(
      sessionId: 's',
      speechToText: Endpoint(
        host: 'stt-host',
        port: 50051,
        security: ChannelSecurity.CHANNEL_SECURITY_INSECURE,
      ),
      textToSpeech: Endpoint(
        host: 'tts-host',
        port: 50052,
        security: ChannelSecurity.CHANNEL_SECURITY_TLS,
      ),
      token: 't',
      expiresAtUnixMs: Int64(1),
    );
    final decoded = AllocateVoiceResponse.fromBuffer(response.writeToBuffer());
    expect(decoded.speechToText.host, 'stt-host');
    expect(decoded.textToSpeech.host, 'tts-host');
    expect(
      decoded.speechToText.security,
      ChannelSecurity.CHANNEL_SECURITY_INSECURE,
    );
    expect(decoded.textToSpeech.security, ChannelSecurity.CHANNEL_SECURITY_TLS);
  });

  test('turn report distinguishes reported-zero from never-reported', () {
    // text_heard = 0 is the barge-in-before-the-first-word case. It has to
    // arrive as an explicit report, because the agent rejects absence rather
    // than reading it as zero -- otherwise a client that said nothing could
    // erase a fully-heard reply from history.
    final nothing = ReportTurnRequest(
      sessionId: 's',
      turnId: 't',
      textHeard: 0,
      outcome: TurnOutcome.TURN_OUTCOME_BARGE_IN,
    );
    final decoded = ReportTurnRequest.fromBuffer(nothing.writeToBuffer());
    expect(decoded.hasTextHeard(), isTrue);
    expect(decoded.textHeard, 0);
    expect(decoded.outcome, TurnOutcome.TURN_OUTCOME_BARGE_IN);

    final unreported = ReportTurnRequest(sessionId: 's', turnId: 't');
    expect(
      ReportTurnRequest.fromBuffer(unreported.writeToBuffer()).hasTextHeard(),
      isFalse,
    );
  });
}

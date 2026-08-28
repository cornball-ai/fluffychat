// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'dart:typed_data';

import 'package:matrix/matrix.dart' show Logs;

import 'chunk_playback.dart';
import 'heard_offset_ledger.dart';
import 'pcm_capture.dart';
import 'pcm_gain.dart';
import 'pcm_sink.dart';
import 'self_echo_filter.dart';
import 'speech_energy.dart';
import 'tts_segmenter.dart';
import 'voice_transport.dart';

/// What the UI needs to render a live conversation, delivered as callbacks
/// because every one of them changes what is on screen.
class LiveVoiceCallbacks {
  /// The user's transcript so far this turn: stable prefix plus current
  /// provisional tail, already concatenated per the schema's contract.
  final void Function(String text) onTranscript;

  /// The assistant's reply text so far this turn, growing delta by delta.
  ///
  /// This runs ahead of the speaker: generation and synthesis are streams,
  /// so text arrives before it is spoken. [onSpoken] is what says how far
  /// the voice has actually got.
  final void Function(String text) onReply;

  /// The part of the reply that has been spoken, as a prefix of the text
  /// [onReply] last delivered.
  ///
  /// Fired as each chunk starts playing, from the same offsets that decide
  /// what a barge-in reports as heard -- so what a reader sees marked as
  /// said and what the agent is told was heard cannot drift apart.
  final void Function(String text) onSpoken;

  /// A turn finished; [storedText] is what the agent kept after truncation,
  /// which is what belongs in the room history the UI shows.
  final void Function(String storedText) onTurnStored;

  /// The user's completed turn, fired at the server's end-of-turn with the
  /// stable transcript that is being sent to the agent.
  ///
  /// The mount posts this into the room as an ordinary message from the
  /// user's own account -- the agent posts its replies itself, so without
  /// this the history holds replies with no user turns between them, and the
  /// client is the only party that can author the user's words without
  /// impersonation. Fired only for turns that start a reply: silence the
  /// endpointer resolved to nothing is skipped by the same rule that skips
  /// sending it to the agent.
  final void Function(String text) onUserTurn;

  /// The session ended. [error] is null for a caller-initiated stop and the
  /// cause for everything else -- the distinction pcm_capture's onEnded
  /// exists to preserve, carried through to the surface.
  final void Function(Object? error) onEnded;

  const LiveVoiceCallbacks({
    required this.onTranscript,
    required this.onReply,
    required this.onSpoken,
    required this.onTurnStored,
    required this.onUserTurn,
    required this.onEnded,
  });
}

/// Orchestrates one live voice conversation.
///
/// The client holds every stream in this exchange -- microphone, speaker,
/// transcription, generation, synthesis -- which is the whole reason the
/// client is the orchestrator: barge-in is "cancel the streams I hold", and
/// nobody else holds them.
///
/// The turn loop: WHAT COMES BACK AS WORDS decides whether the user
/// interrupted. A turn whose text is substantially the reply we are
/// currently speaking is our own voice arriving back through the
/// microphone and is discarded; a turn that says something else is a real
/// interruption and cuts the reply.
///
/// Loudness decides nothing, after three failed attempts to make it. With
/// no working acoustic echo cancellation the microphone hears our own
/// speaker, and no energy threshold can separate that from a person: a
/// fixed threshold cut the reply on its own first syllable, an adaptive
/// floor learned silence during the seconds before audio arrived and then
/// did the same, and priming the floor at playback start missed the sound
/// entirely because output latency delivers it after the window closes.
/// Every version cut the reply mid-word with nobody speaking. Words are
/// the one signal that carries the answer: we know what we just said.
///
/// Energy keeps one job, and it is not deciding: while a reply plays the
/// wire stays closed until sustained input opens it, holding the last
/// half second so the syllable that opened it still arrives. That is for
/// the ENDPOINTER's benefit. Streaming bleed continuously gives the
/// server's voice-activity model no pause to find, so it never declares
/// a turn over, and a cut that only happens at turn end never happens --
/// which is exactly how full duplex broke interruption while fixing
/// self-interruption. A gate that is wrong costs a little wasted
/// transcription; a gate that decides costs the reply.
///
/// The remaining cost is honest: interruption latency is the
/// endpointer's rather than 200 ms of energy, so a few more words play
/// before the reply stops. It shrinks the day real echo cancellation
/// exists under the capture path -- at which point energy barge-in can
/// come back as the fast path it was meant to be.
///
/// Stable transcripts accumulate; the server's SttTurnEnded sends the
/// accumulated turn to the agent. Reply deltas stream to the UI and through
/// the segmenter into per-segment synthesis; chunks play through the sink
/// while ChunkPlayback keeps the heard count and the ledger keeps the
/// offset frame. The user speaking over the reply cancels generation,
/// synthesis and playback, settles what was heard, and reports it -- in
/// that order, so nothing said after the cut can smear the accounting.
class LiveVoiceSession {
  final VoiceTransport _transport;
  final PcmCapture _capture;
  final PcmSink _sink;
  final BargeInDetector _bargeIn;
  final TtsSegmenter Function() _newSegmenter;
  final LiveVoiceCallbacks _callbacks;

  LiveVoiceSession({
    required VoiceTransport transport,
    required PcmCapture capture,
    required PcmSink sink,
    required LiveVoiceCallbacks callbacks,
    BargeInDetector? bargeIn,
    TtsSegmenter Function()? segmenterFactory,
    SelfEchoFilter? echoFilter,
  }) : _transport = transport,
       _capture = capture,
       _sink = sink,
       _callbacks = callbacks,
       _bargeIn = bargeIn ?? BargeInDetector(),
       _echoFilter = echoFilter ?? SelfEchoFilter(),
       _newSegmenter = segmenterFactory ?? TtsSegmenter.new;

  final SelfEchoFilter _echoFilter;

  /// Whether mic frames are currently reaching transcription during a
  /// reply. Closed when a reply starts, opened by the first loud input.
  bool _wireOpen = false;

  /// Frames held back while the wire is closed, flushed the moment it
  /// opens so the syllable that opened it is not the syllable lost.
  final List<Uint8List> _prebuffer = [];
  int _prebufferedBytes = 0;

  /// About half a second at 16 kHz mono 16-bit: enough to carry the onset
  /// the detector needed to make up its mind, not enough to matter.
  static const int _prebufferMaxBytes = voiceSampleRate * 2 ~/ 2;

  StreamSubscription<SttEvent>? _sttSubscription;
  bool _running = false;
  bool _stopping = false;

  /// Stable transcript accumulated for the current user turn.
  final StringBuffer _stableTurn = StringBuffer();
  String _provisional = '';

  _ReplyTurn? _reply;

  bool get isRunning => _running;

  /// Whether a reply is generating or playing. While true, sustained energy
  /// on the microphone is interpreted as barge-in.
  bool get replying => _reply != null;

  bool _muted = false;

  bool get muted => _muted;

  /// While muted, microphone frames are dropped before they reach the wire
  /// or the barge-in detector: the server hears nothing, a playing reply
  /// cannot be interrupted by room noise, and the endpointer's audio clock
  /// simply pauses. The capture itself keeps running so unmuting is
  /// instant -- no device reopen, no permission re-prompt.
  set muted(bool value) {
    if (_muted == value) return;
    _muted = value;
    // Audio captured before the mute must not survive it: held frames
    // would otherwise be flushed to transcription by the next gate
    // opening, sending the server words spoken while the microphone was
    // supposed to be off.
    _clearPrebuffer();
    // The detector's energy window would otherwise straddle the gap and
    // read stale pre-mute audio against fresh speech.
    if (!value) _bargeIn.reset();
  }

  Future<bool> start(String roomId) async {
    if (_running) return true;
    await _transport.connect(roomId);
    _sttSubscription = _transport.transcripts.listen(
      _onSttEvent,
      onError: _fail,
      onDone: () {
        if (_running && !_stopping) _fail(StateError('transcription closed'));
      },
    );
    final started = await _capture.start(
      _onMicFrame,
      onEnded: (error) {
        // Capture dying is fatal either way; a null error just means the
        // platform closed it politely.
        if (_running) _fail(error ?? StateError('capture ended'));
      },
    );
    if (!started) {
      await _teardown();
      return false;
    }
    _running = true;
    return true;
  }

  /// User-initiated stop. A reply cut off by leaving the conversation is
  /// reported as abandoned -- what was heard is still what was heard.
  Future<void> stop() async {
    if (!_running || _stopping) return;
    _stopping = true;
    await _cutReply(TurnResult.abandoned);
    await _teardown();
    _running = false;
    _callbacks.onEnded(null);
  }

  void _fail(Object error) {
    if (!_running || _stopping) return;
    Logs().w('Live voice: session failed', error);
    _stopping = true;
    // Best-effort: the truncation report matters, failures during a teardown
    // that is already dying do not.
    unawaited(
      _cutReply(TurnResult.abandoned)
          .catchError((_) {})
          .then((_) => _teardown().catchError((_) {}))
          .then((_) {
            _running = false;
            _callbacks.onEnded(error);
          }),
    );
  }

  Future<void> _teardown() async {
    await _capture.stop();
    await _sttSubscription?.cancel();
    _sttSubscription = null;
    await _sink.dispose();
    await _transport.close();
  }

  void _onMicFrame(Uint8List frame) {
    if (!_running || _stopping || _muted) return;
    if (_reply != null && !_wireOpen) {
      // Hold the wire closed until something is worth transcribing. This
      // is about the ENDPOINTER, not about interruption: streaming our
      // own speaker bleed continuously gives the server's voice-activity
      // model no pause to find, so it never declares a turn over, and a
      // cut that only happens at turn end never happens at all. Silence
      // withheld here is silence it can endpoint against.
      _prebuffer.add(frame);
      _prebufferedBytes += frame.lengthInBytes;
      while (_prebufferedBytes > _prebufferMaxBytes && _prebuffer.length > 1) {
        _prebufferedBytes -= _prebuffer.removeAt(0).lengthInBytes;
      }
      if (!_bargeIn.addFrame(frame)) return;
      // With echo cancellation working the floor sits in the -60s or
      // quieter, and input towering over THAT is a person -- cut now
      // rather than waiting out the endpointer, which is the difference
      // between an interruption that feels instant and one that takes a
      // second and a half. Without AEC the floor stays in the -40s, this
      // stays false, and the words go on deciding alone.
      final fastCut = _bargeIn.floorIsQuiet && _bargeIn.strongInput;
      Logs().d(
        'Live voice: opening the wire mid-reply '
        '(level ${_bargeIn.triggerLevel.toStringAsFixed(1)} dBFS, '
        'floor ${_bargeIn.floorDbfs.toStringAsFixed(1)} dBFS) -- '
        '${fastCut ? 'cutting now, the floor says the echo is gone' : 'the transcript decides whether it interrupts'}',
      );
      _wireOpen = true;
      for (final held in _prebuffer) {
        _transport.sendAudio(held);
      }
      _clearPrebuffer();
      if (fastCut) unawaited(_cutReply(TurnResult.bargeIn));
      return;
    }
    _transport.sendAudio(frame);
  }

  void _clearPrebuffer() {
    _prebuffer.clear();
    _prebufferedBytes = 0;
  }

  void _onSttEvent(SttEvent event) {
    if (_stopping) return;
    switch (event) {
      case SttTranscript(:final text, :final stable):
        if (stable) {
          _stableTurn.write(text);
          _provisional = '';
        } else {
          _provisional = text;
        }
        _callbacks.onTranscript('$_stableTurn$_provisional');
      case SttTurnEnded():
        // Contract: everything committed has arrived stable by now; a
        // leftover provisional is discarded, not promoted.
        _provisional = '';
        final turnText = _stableTurn.toString();
        _stableTurn.clear();
        if (turnText.trim().isEmpty) return;
        // Our own speech, transcribed off the speaker: without this, the
        // bot's reply posts as the user's words and the agent answers
        // itself. Discarded entirely -- not posted, not sent.
        if (_echoFilter.isSelfEcho(turnText, speaking: _reply != null)) {
          Logs().i(
            'Live voice: discarded self-echo turn '
            '("${turnText.length > 60 ? '${turnText.substring(0, 60)}…' : turnText}")',
          );
          _callbacks.onTranscript('');
          // Re-arm the gate. It was opened by something that turned out
          // to be us, and leaving it open streams the rest of the reply's
          // bleed straight back into the endpointer -- the wall of noise
          // this gate exists to prevent, restored by its own false
          // positive.
          if (_reply != null) {
            _wireOpen = false;
            _clearPrebuffer();
            _bargeIn.reset();
          }
          return;
        }
        // Concurrent with the reply on purpose: posting is a room-history
        // concern and must not sit on the turn's latency path. The ordering
        // race against the agent's reply post is theoretical -- the agent
        // posts at its generation end, hundreds of milliseconds after this
        // local send at soonest.
        _callbacks.onUserTurn(turnText);
        _startReply(turnText);
    }
  }

  void _startReply(String userText) {
    // A new user turn while the previous reply still plays is itself a
    // barge-in, even when energy detection missed it -- soft speech the
    // endpointing model still resolved.
    if (_reply != null) {
      Logs().i('Live voice: new user turn cut the pending reply');
    }
    unawaited(
      _cutReply(TurnResult.bargeIn).then((_) {
        if (_stopping) return;
        final reply = _ReplyTurn(
          transport: _transport,
          sink: _sink,
          segmenter: _newSegmenter(),
          onReplyText: _callbacks.onReply,
          onStored: _callbacks.onTurnStored,
          onError: _fail,
          // What the speaker has actually reached, as it reaches it: the
          // only text the microphone can be echoing back, and the same
          // prefix a reader sees marked as already said.
          onAudibleText: (text) {
            _echoFilter.audibleText(text);
            _callbacks.onSpoken(text);
          },
        );
        _reply = reply;
        _bargeIn.reset();
        // A new reply closes the wire again: its own audio must not be
        // what keeps the endpointer from ever finding a pause.
        _wireOpen = false;
        _clearPrebuffer();
        unawaited(
          reply.run(userText).then((_) {
            if (identical(_reply, reply)) {
              _reply = null;
              _echoFilter.replyEnded();
            }
          }),
        );
      }),
    );
  }

  Future<void> _cutReply(TurnResult result) async {
    final reply = _reply;
    if (reply == null) return;
    _reply = null;
    await reply.cut(result);
    // The cut reply's words stay in the air (and the capture pipeline)
    // for a moment; the filter keeps them as an echo source.
    _echoFilter.replyEnded();
  }
}

/// One assistant turn: generation, segmentation, synthesis, playback, and
/// the truncation report. Isolated so a cut turn can settle itself while the
/// session moves on -- late events from a cancelled stream find a dead
/// object here instead of the next turn's accounting.
class _ReplyTurn {
  final VoiceTransport transport;
  final PcmSink sink;
  final TtsSegmenter segmenter;
  final void Function(String) onReplyText;
  final void Function(String) onStored;
  final void Function(Object) onError;
  final void Function(String) onAudibleText;

  _ReplyTurn({
    required this.transport,
    required this.sink,
    required this.segmenter,
    required this.onReplyText,
    required this.onStored,
    required this.onError,
    required this.onAudibleText,
  });

  final HeardOffsetLedger _ledger = HeardOffsetLedger();
  final ChunkPlayback _playback = ChunkPlayback();

  /// Per reply, so one loud turn cannot set the level for the next.
  final SpeechGain _gain = SpeechGain();

  /// (segment, inputTextEnd) for every chunk in the order playback STARTS
  /// them -- the list ChunkPlayback's count indexes into. Appended in the
  /// play queue, not on chunk arrival: synthesis can run ahead of playback,
  /// and an arrival-ordered list under an arrival-ordered startChunk would
  /// let a fast synthesiser stomp the accounting of a chunk still playing.
  final List<(int, int)> _chunkOffsets = [];

  final StringBuffer _replyText = StringBuffer();
  String? _turnId;
  bool _cut = false;
  bool _reported = false;

  StreamSubscription<ReplyEvent>? _replySubscription;
  StreamSubscription<TtsEvent>? _ttsSubscription;

  /// Serialises synthesis calls: segments must hit the synthesiser in reply
  /// order.
  Future<void> _synthQueue = Future.value();

  /// Serialises playback: exactly one chunk owns ChunkPlayback's "current"
  /// slot at a time.
  Future<void> _playQueue = Future.value();

  Future<void> run(String userText) async {
    final generationDone = Completer<void>();
    _replySubscription = transport
        .converse(userText)
        .listen(
          (event) {
            if (_cut) return;
            switch (event) {
              case ReplyStart(:final turnId):
                _turnId = turnId;
              case ReplyDelta(:final text):
                _replyText.write(text);
                onReplyText(_replyText.toString());
                for (final segment in segmenter.feed(text)) {
                  _enqueueSegment(segment);
                }
              case ReplyEnd():
                final rest = segmenter.flush();
                if (rest != null) _enqueueSegment(rest);
            }
          },
          onError: (Object error) {
            if (!_cut) onError(error);
            if (!generationDone.isCompleted) generationDone.complete();
          },
          onDone: () {
            if (!generationDone.isCompleted) generationDone.complete();
          },
        );
    await generationDone.future;
    if (_cut) return;
    // All segments synthesised, then all chunks played out, then the report.
    // The playback drain matters: generation being over does not mean the
    // user has heard the tail, and reporting completed while audio still
    // plays would close the barge-in window early.
    await _synthQueue;
    if (_cut) return;
    await _playQueue;
    if (_cut) return;
    await _report(TurnResult.completed, _ledger.totalCodePoints);
  }

  void _enqueueSegment(String text) {
    final segmentIndex = _ledger.addSegment(text);
    _synthQueue = _synthQueue.then((_) async {
      if (_cut) return;
      await _synthesizeSegment(segmentIndex, text);
    });
  }

  Future<void> _synthesizeSegment(int segmentIndex, String text) async {
    final streamDone = Completer<void>();
    var sampleRate = 0;
    _ttsSubscription = transport
        .synthesize(text)
        .listen(
          (event) {
            if (_cut) return;
            switch (event) {
              case TtsStart(:final sampleRateHz):
                sampleRate = sampleRateHz;
              case TtsChunk(
                :final index,
                :final duration,
                :final inputTextEnd,
                :final pcm,
              ):
                if (sampleRate == 0) {
                  onError(StateError('audio chunk before SynthesisStart'));
                  return;
                }
                _enqueueChunk(
                  segmentIndex: segmentIndex,
                  index: index,
                  duration: duration,
                  inputTextEnd: inputTextEnd,
                  pcm: pcm,
                  sampleRateHz: sampleRate,
                );
            }
          },
          onError: (Object error) {
            if (!_cut) onError(error);
            if (!streamDone.isCompleted) streamDone.complete();
          },
          onDone: () {
            if (!streamDone.isCompleted) streamDone.complete();
          },
        );
    await streamDone.future;
  }

  void _enqueueChunk({
    required int segmentIndex,
    required int index,
    required Duration duration,
    required int inputTextEnd,
    required Uint8List pcm,
    required int sampleRateHz,
  }) {
    _playQueue = _playQueue.then((_) async {
      if (_cut) return;
      _chunkOffsets.add((segmentIndex, inputTextEnd));
      // This chunk is about to be heard, so everything up to its text
      // boundary counts as audible from now on.
      final audible = _ledger.globalOffset(segmentIndex, inputTextEnd);
      final full = _replyText.toString();
      final runes = full.runes.toList();
      onAudibleText(
        String.fromCharCodes(runes.sublist(0, audible.clamp(0, runes.length))),
      );
      // Level, then play. The gain reads the chunk before the speaker does,
      // so the peak it corrects for is one it has already seen.
      final applied = _gain.apply(pcm);
      if (index == 0) {
        Logs().v(
          'Live voice: reply peaks at ${_gain.peakDbfs?.toStringAsFixed(1)} '
          'dBFS, playing at ${applied.toStringAsFixed(2)}x',
        );
      }
      _playback.startChunk(index, duration);
      final played = await sink.play(
        pcm,
        sampleRateHz: sampleRateHz,
        onProgress: _playback.progress,
      );
      if (played && !_cut) _playback.completeChunk();
    });
  }

  /// Cut order is the contract: stop generation, stop synthesis, stop the
  /// speaker, THEN settle the count, THEN report. Settling before the sink
  /// stops would count audio still playing; reporting before settling would
  /// report a number still moving.
  Future<void> cut(TurnResult result) async {
    if (_cut) return;
    _cut = true;
    await _replySubscription?.cancel();
    _replySubscription = null;
    await _ttsSubscription?.cancel();
    _ttsSubscription = null;
    await sink.cancel();
    final heardChunks = _playback.truncate();
    final textHeard = heardChunks == 0
        ? 0
        : () {
            final (segment, inputTextEnd) = _chunkOffsets[heardChunks - 1];
            return _ledger.globalOffset(segment, inputTextEnd);
          }();
    await _report(result, textHeard);
  }

  Future<void> _report(TurnResult result, int textHeard) async {
    if (_reported) return;
    _reported = true;
    final turnId = _turnId;
    // No ReplyStart means generation never began; there is no turn to
    // report.
    if (turnId == null) return;
    try {
      final stored = await transport.reportTurn(
        turnId: turnId,
        textHeard: textHeard,
        result: result,
      );
      onStored(stored);
    } catch (error) {
      // The report failing must not take down a session that outlives this
      // turn; the history staying untruncated is the server's documented
      // fallback for a missing report.
      onError(error);
    }
  }
}

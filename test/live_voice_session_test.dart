// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'dart:typed_data';

import 'package:fluffychat/utils/voice/live_voice_session.dart';
import 'package:fluffychat/utils/voice/pcm_capture.dart';
import 'package:fluffychat/utils/voice/pcm_sink.dart';
import 'package:fluffychat/utils/voice/speech_energy.dart';
import 'package:fluffychat/utils/voice/tts_segmenter.dart';
import 'package:fluffychat/utils/voice/voice_transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';

/// Recorder whose stream the test feeds by hand.
class _FakeRecorder extends Fake implements AudioRecorder {
  final frames = StreamController<Uint8List>();
  @override
  Future<bool> hasPermission({bool request = true}) async => true;
  @override
  Future<Stream<Uint8List>> startStream(RecordConfig config) async =>
      frames.stream;
  @override
  Future<String?> stop() async => null;
  @override
  Future<void> dispose() async {}
}

/// Barge-in detector the test flips by hand: energy heuristics have their
/// own tests, and the session only cares about the bool.
class _ScriptedBargeIn extends BargeInDetector {
  bool trigger = false;
  @override
  bool addFrame(Uint8List frame) => trigger;
  @override
  void reset() {}
}

/// Sink scripted per chunk: how far playback got, as a fraction. A fraction
/// below 1.0 hangs the chunk (reporting its progress) until cancel.
class _FakeSink implements PcmSink {
  final List<double> fractions;
  _FakeSink(this.fractions);

  final playedChunks = <Uint8List>[];
  int cancels = 0;
  bool disposed = false;
  Completer<bool>? _hanging;

  @override
  Future<bool> play(
    Uint8List pcm, {
    required int sampleRateHz,
    void Function(Duration elapsed)? onProgress,
  }) {
    playedChunks.add(pcm);
    final fraction = fractions[playedChunks.length - 1];
    // The session passes the chunk's announced duration through startChunk;
    // the sink only knows bytes, so scripted duration = 1s for simplicity.
    const duration = Duration(seconds: 1);
    onProgress?.call(duration * fraction);
    if (fraction >= 1.0) return Future.value(true);
    final hanging = Completer<bool>();
    _hanging = hanging;
    return hanging.future;
  }

  @override
  Future<void> cancel() async {
    cancels++;
    _hanging?.complete(false);
    _hanging = null;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await cancel();
  }
}

class _TurnReport {
  final String turnId;
  final int textHeard;
  final TurnResult result;
  _TurnReport(this.turnId, this.textHeard, this.result);
}

class _FakeTransport implements VoiceTransport {
  final _transcripts = StreamController<SttEvent>.broadcast();
  final sentFrames = <Uint8List>[];
  final converseCalls = <String>[];
  final synthesizeCalls = <String>[];
  final reports = <_TurnReport>[];

  /// Deltas the next converse() call streams before ending.
  List<String> replyDeltas = const [];
  bool closed = false;

  @override
  Future<void> connect(String roomId) async {}

  @override
  void sendAudio(Uint8List frame) => sentFrames.add(frame);

  @override
  Stream<SttEvent> get transcripts => _transcripts.stream;

  void emitStt(SttEvent event) => _transcripts.add(event);

  @override
  Stream<ReplyEvent> converse(String text) {
    converseCalls.add(text);
    final controller = StreamController<ReplyEvent>();
    controller.add(const ReplyStart('turn-1'));
    for (final delta in replyDeltas) {
      controller.add(ReplyDelta(delta));
    }
    controller.add(const ReplyEnd('end_turn'));
    controller.close();
    return controller.stream;
  }

  @override
  Stream<TtsEvent> synthesize(String text) {
    synthesizeCalls.add(text);
    final controller = StreamController<TtsEvent>();
    controller.add(const TtsStart(16000));
    // One chunk per segment, stamped with the segment's own full length --
    // the shape a well-behaved synthesiser produces.
    controller.add(
      TtsChunk(
        index: 0,
        duration: const Duration(seconds: 1),
        inputTextEnd: text.runes.length,
        pcm: Uint8List(4),
      ),
    );
    controller.close();
    return controller.stream;
  }

  @override
  Future<String> reportTurn({
    required String turnId,
    required int textHeard,
    required TurnResult result,
  }) async {
    reports.add(_TurnReport(turnId, textHeard, result));
    return 'stored';
  }

  @override
  Future<void> close() async {
    closed = true;
    await _transcripts.close();
  }
}

class _Harness {
  final transport = _FakeTransport();
  final recorder = _FakeRecorder();
  final bargeIn = _ScriptedBargeIn();
  final _FakeSink sink;
  final transcripts = <String>[];
  final replies = <String>[];
  final stored = <String>[];
  final userTurns = <String>[];
  final ended = <Object?>[];
  late final LiveVoiceSession session;

  _Harness({List<double> sinkFractions = const [1.0, 1.0, 1.0, 1.0]})
    : sink = _FakeSink(sinkFractions) {
    session = LiveVoiceSession(
      transport: transport,
      capture: PcmCapture(recorder: recorder),
      sink: sink,
      bargeIn: bargeIn,
      // Tiny minimum so short test sentences split like real ones.
      segmenterFactory: () => TtsSegmenter(minSegmentLength: 1),
      callbacks: LiveVoiceCallbacks(
        onTranscript: transcripts.add,
        onReply: replies.add,
        onTurnStored: stored.add,
        onUserTurn: userTurns.add,
        onEnded: ended.add,
      ),
    );
  }

  Future<void> start() async {
    expect(await session.start('!room:example.org'), isTrue);
  }

  /// One full user turn: stable transcript then the server's end-of-turn.
  Future<void> speak(String text) async {
    transport.emitStt(SttTranscript(text, stable: true));
    transport.emitStt(const SttTurnEnded());
    await pumpEventQueue();
  }
}

void main() {
  test(
    'a full turn flows: transcript, reply, synthesis, completed report',
    () async {
      final harness = _Harness();
      harness.transport.replyDeltas = ['Hello there. ', 'General Kenobi.'];
      await harness.start();

      await harness.speak('hi there');

      expect(harness.transport.converseCalls, ['hi there']);
      // The spoken turn is handed to the mount for posting, verbatim, the
      // same text the agent receives.
      expect(harness.userTurns, ['hi there']);
      // Segments cover the reply exactly, in order.
      expect(harness.transport.synthesizeCalls.join(), harness.replies.last);
      expect(harness.replies.last, 'Hello there. General Kenobi.');
      // Every chunk fully heard -> completed, with the whole reply's length.
      final report = harness.transport.reports.single;
      expect(report.result, TurnResult.completed);
      expect(report.textHeard, 'Hello there. General Kenobi.'.runes.length);
      expect(harness.stored, ['stored']);
      expect(harness.ended, isEmpty);
    },
  );

  test('provisional transcripts replace; stable ones append', () async {
    final harness = _Harness();
    await harness.start();

    harness.transport.emitStt(const SttTranscript('hel', stable: false));
    harness.transport.emitStt(const SttTranscript('hello wor', stable: false));
    harness.transport.emitStt(
      const SttTranscript('hello world. ', stable: true),
    );
    harness.transport.emitStt(const SttTranscript('again', stable: false));
    await pumpEventQueue();

    expect(harness.transcripts, [
      'hel',
      'hello wor',
      'hello world. ',
      'hello world. again',
    ]);

    // The leftover provisional is discarded at turn end, per the schema:
    // only stable text reaches the agent.
    harness.transport.emitStt(const SttTurnEnded());
    await pumpEventQueue();
    expect(harness.transport.converseCalls, ['hello world. ']);
    // The posted turn obeys the same rule: stable text only, the leftover
    // provisional discarded, never promoted into the room history.
    expect(harness.userTurns, ['hello world. ']);
  });

  test(
    'barge-in mid-chunk cuts playback and reports the heard offset',
    () async {
      // First chunk plays out, second hangs at 40% -- before its midpoint, so
      // it does not count as heard.
      final harness = _Harness(sinkFractions: [1.0, 0.4]);
      harness.transport.replyDeltas = ['Hello there. ', 'General Kenobi.'];
      await harness.start();
      await harness.speak('hi');

      // The reply is mid-playback; the user starts talking.
      harness.bargeIn.trigger = true;
      harness.recorder.frames.add(Uint8List(320));
      await pumpEventQueue();

      final report = harness.transport.reports.single;
      expect(report.result, TurnResult.bargeIn);
      // Heard through the first segment only.
      expect(report.textHeard, 'Hello there. '.runes.length);
      expect(harness.sink.cancels, greaterThan(0));
      expect(harness.session.replying, isFalse);
      // The session survives a barge-in; only the turn died.
      expect(harness.ended, isEmpty);
    },
  );

  test('barge-in before anything played reports an explicit zero', () async {
    // The one chunk hangs at 10%: started, never half-heard.
    final harness = _Harness(sinkFractions: [0.1]);
    harness.transport.replyDeltas = ['One single sentence here.'];
    await harness.start();
    await harness.speak('hi');

    harness.bargeIn.trigger = true;
    harness.recorder.frames.add(Uint8List(320));
    await pumpEventQueue();

    final report = harness.transport.reports.single;
    expect(report.result, TurnResult.bargeIn);
    expect(report.textHeard, 0);
  });

  test('muted frames reach neither the wire nor barge-in', () async {
    // The one chunk hangs at 40%, holding the reply open so barge-in stays
    // meaningful for the whole test.
    final harness = _Harness(sinkFractions: [0.4]);
    harness.transport.replyDeltas = ['One single sentence here.'];
    await harness.start();

    harness.recorder.frames.add(Uint8List(320));
    await pumpEventQueue();
    expect(harness.transport.sentFrames, hasLength(1));

    await harness.speak('hi');
    harness.session.muted = true;
    // A trigger-happy detector plus a playing reply: the frame is dropped
    // before the detector sees it, so nothing is cut and nothing is sent.
    harness.bargeIn.trigger = true;
    harness.recorder.frames.add(Uint8List(320));
    await pumpEventQueue();
    expect(harness.transport.sentFrames, hasLength(1));
    expect(harness.transport.reports, isEmpty);
    expect(harness.session.replying, isTrue);

    // Unmuting restores the path: the reply is still playing, so the frame
    // goes to the detector (not the wire) and the trigger cuts the reply.
    harness.session.muted = false;
    harness.recorder.frames.add(Uint8List(320));
    await pumpEventQueue();
    expect(harness.transport.reports.single.result, TurnResult.bargeIn);
    expect(harness.transport.sentFrames, hasLength(1));

    // And with the reply gone, frames reach transcription again.
    harness.bargeIn.trigger = false;
    harness.recorder.frames.add(Uint8List(320));
    await pumpEventQueue();
    expect(harness.transport.sentFrames, hasLength(2));
  });

  test('stop() mid-reply reports abandoned and ends cleanly', () async {
    final harness = _Harness(sinkFractions: [1.0, 0.3]);
    harness.transport.replyDeltas = ['First bit. ', 'Second bit.'];
    await harness.start();
    await harness.speak('hi');

    await harness.session.stop();

    final report = harness.transport.reports.single;
    expect(report.result, TurnResult.abandoned);
    expect(report.textHeard, 'First bit. '.runes.length);
    expect(harness.ended, [null]);
    expect(harness.transport.closed, isTrue);
    expect(harness.sink.disposed, isTrue);
  });

  test(
    'mic frames are gated while a reply plays; the cut reopens them',
    () async {
      // The first design sent frames to transcription during playback and
      // trusted echo cancellation. No platform honored it: the mic heard
      // the synthesis under the barge-in threshold but over the server
      // VAD's, and the agent conversed with itself. This pins the gate.
      final harness = _Harness(sinkFractions: [0.2]);
      harness.transport.replyDeltas = ['A reply that keeps playing.'];
      await harness.start();
      await harness.speak('hi');

      // Quiet room noise (or our own speaker) during the reply: dropped.
      harness.recorder.frames.add(Uint8List(320));
      await pumpEventQueue();
      expect(harness.transport.sentFrames, isEmpty);
      expect(harness.session.replying, isTrue);

      // Confirmed interruption energy: cuts the reply. The confirming
      // frame itself is dropped -- the cut is what reopens the path.
      harness.bargeIn.trigger = true;
      harness.recorder.frames.add(Uint8List(320));
      await pumpEventQueue();
      expect(harness.transport.reports.single.result, TurnResult.bargeIn);
      expect(harness.transport.sentFrames, isEmpty);

      // With the reply dead, frames flow to transcription again.
      harness.bargeIn.trigger = false;
      harness.recorder.frames.add(Uint8List(320));
      await pumpEventQueue();
      expect(harness.transport.sentFrames, hasLength(1));
    },
  );

  test(
    'a failing turn report surfaces as session failure, not silence',
    () async {
      final harness = _Harness();
      harness.transport.replyDeltas = ['Anything at all. '];
      await harness.start();

      final failing = _FailingReportTransport(harness.transport);
      // Rebuild a session over the failing transport.
      final ended = <Object?>[];
      final session = LiveVoiceSession(
        transport: failing,
        capture: PcmCapture(recorder: _FakeRecorder()),
        sink: _FakeSink(const [1.0]),
        bargeIn: _ScriptedBargeIn(),
        segmenterFactory: () => TtsSegmenter(minSegmentLength: 1),
        callbacks: LiveVoiceCallbacks(
          onTranscript: (_) {},
          onReply: (_) {},
          onTurnStored: (_) {},
          onUserTurn: (_) {},
          onEnded: ended.add,
        ),
      );
      expect(await session.start('!room:example.org'), isTrue);
      failing.emitStt(const SttTranscript('hi', stable: true));
      failing.emitStt(const SttTurnEnded());
      await pumpEventQueue();

      expect(ended, hasLength(1));
      expect(ended.single, isA<StateError>());
    },
  );

  test('an empty turn (silence resolved to nothing) starts no reply', () async {
    final harness = _Harness();
    await harness.start();
    await harness.speak('   ');
    expect(harness.transport.converseCalls, isEmpty);
    // One rule, both sinks: a turn too empty to send is too empty to post.
    expect(harness.userTurns, isEmpty);
    expect(harness.transport.reports, isEmpty);
  });
}

/// Wraps the fake but fails every reportTurn.
class _FailingReportTransport implements VoiceTransport {
  final _FakeTransport inner;
  _FailingReportTransport(this.inner);

  final _transcripts = StreamController<SttEvent>.broadcast();
  void emitStt(SttEvent event) => _transcripts.add(event);

  @override
  Future<void> connect(String roomId) async {}
  @override
  void sendAudio(Uint8List frame) {}
  @override
  Stream<SttEvent> get transcripts => _transcripts.stream;
  @override
  Stream<ReplyEvent> converse(String text) => inner.converse(text);
  @override
  Stream<TtsEvent> synthesize(String text) => inner.synthesize(text);
  @override
  Future<String> reportTurn({
    required String turnId,
    required int textHeard,
    required TurnResult result,
  }) async {
    throw StateError('report refused');
  }

  @override
  Future<void> close() async {
    await _transcripts.close();
  }
}

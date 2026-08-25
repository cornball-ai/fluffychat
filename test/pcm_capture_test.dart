// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'dart:typed_data';

import 'package:fluffychat/utils/voice/pcm_capture.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';

class _FakeRecorder extends Fake implements AudioRecorder {
  final frames = StreamController<Uint8List>();
  int startCalls = 0;
  bool permission = true;

  @override
  Future<bool> hasPermission({bool request = true}) async => permission;

  @override
  Future<Stream<Uint8List>> startStream(RecordConfig config) async {
    startCalls++;
    return frames.stream;
  }

  @override
  Future<String?> stop() async => null;

  @override
  Future<void> dispose() async {}
}

void main() {
  test(
    'recorder errors mark capture stopped and surface through onEnded',
    () async {
      final recorder = _FakeRecorder();
      final capture = PcmCapture(recorder: recorder);
      final endings = <Object?>[];

      await capture.start((_) {}, onEnded: endings.add);
      expect(capture.isRunning, isTrue);

      recorder.frames.addError(StateError('device gone'));
      await pumpEventQueue();

      expect(capture.isRunning, isFalse);
      expect(endings, hasLength(1));
      expect(endings.single, isA<StateError>());
    },
  );

  test('the platform closing the stream surfaces as onEnded(null)', () async {
    final recorder = _FakeRecorder();
    final capture = PcmCapture(recorder: recorder);
    final endings = <Object?>[];

    await capture.start((_) {}, onEnded: endings.add);
    await recorder.frames.close();
    await pumpEventQueue();

    expect(capture.isRunning, isFalse);
    expect(endings, [null]);
  });

  test('a caller-initiated stop does not fire onEnded', () async {
    final recorder = _FakeRecorder();
    final capture = PcmCapture(recorder: recorder);
    final endings = <Object?>[];

    await capture.start((_) {}, onEnded: endings.add);
    await capture.stop();
    await recorder.frames.close();
    await pumpEventQueue();

    // The distinction the callback exists for: "I stopped it" is not an
    // ending worth reporting; "it fell over" is.
    expect(endings, isEmpty);
  });

  test('concurrent start() calls open the recorder once', () async {
    final recorder = _FakeRecorder();
    final capture = PcmCapture(recorder: recorder);

    final results = await Future.wait([
      capture.start((_) {}),
      capture.start((_) {}),
    ]);

    expect(results, [true, true]);
    expect(recorder.startCalls, 1);
  });

  test('frames reach onFrame while running', () async {
    final recorder = _FakeRecorder();
    final capture = PcmCapture(recorder: recorder);
    final received = <Uint8List>[];

    await capture.start(received.add);
    recorder.frames.add(Uint8List.fromList([1, 2]));
    await pumpEventQueue();

    expect(received, hasLength(1));
  });

  test('refused permission returns false without starting', () async {
    final recorder = _FakeRecorder()..permission = false;
    final capture = PcmCapture(recorder: recorder);
    expect(await capture.start((_) {}), isFalse);
    expect(capture.isRunning, isFalse);
    expect(recorder.startCalls, 0);
  });
}

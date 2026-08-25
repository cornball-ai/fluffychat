// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';
import 'dart:typed_data';

import 'package:fluffychat/utils/voice/aplay_pcm_sink.dart';
import 'package:flutter_test/flutter_test.dart';

/// These run the real aplay binary against the ALSA null device, so they
/// need alsa-utils but no sound hardware. Machines without it (some CI
/// runners) skip rather than fail: absence of the tool is not a bug in the
/// sink, and pretending to test it with a mocked process would test the
/// mock.
void main() {
  late bool hasAplay;

  setUpAll(() async {
    try {
      final probe = await Process.run('aplay', ['--version']);
      hasAplay = probe.exitCode == 0;
    } on ProcessException {
      hasAplay = false;
    }
  });

  /// 16 kHz mono S16LE silence of [ms] milliseconds.
  Uint8List silence(int ms) => Uint8List(2 * 16000 * ms ~/ 1000);

  test('plays a chunk to completion with monotonic progress', () async {
    if (!hasAplay) {
      markTestSkipped('aplay not installed');
      return;
    }
    final sink = AplayPcmSink(device: 'null');
    final progress = <Duration>[];
    final played = await sink.play(
      silence(150),
      sampleRateHz: 16000,
      onProgress: progress.add,
    );
    await sink.dispose();

    expect(played, isTrue);
    expect(progress, isNotEmpty);
    expect(progress.last, const Duration(milliseconds: 150));
    for (var i = 1; i < progress.length; i++) {
      expect(progress[i] >= progress[i - 1], isTrue);
    }
  });

  test('cancel cuts an in-flight chunk and resolves it false', () async {
    if (!hasAplay) {
      markTestSkipped('aplay not installed');
      return;
    }
    final sink = AplayPcmSink(device: 'null');
    final pending = sink.play(silence(5000), sampleRateHz: 16000);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await sink.cancel();

    expect(await pending, isFalse);
    await sink.dispose();
  });

  test('chunks queue and play sequentially', () async {
    if (!hasAplay) {
      markTestSkipped('aplay not installed');
      return;
    }
    final sink = AplayPcmSink(device: 'null');
    final order = <int>[];
    final first = sink
        .play(silence(100), sampleRateHz: 16000)
        .then((played) => order.add(1));
    final second = sink
        .play(silence(100), sampleRateHz: 16000)
        .then((played) => order.add(2));
    await Future.wait([first, second]);
    await sink.dispose();

    expect(order, [1, 2]);
  });

  test('a disposed sink refuses new chunks quietly', () async {
    if (!hasAplay) {
      markTestSkipped('aplay not installed');
      return;
    }
    final sink = AplayPcmSink(device: 'null');
    await sink.dispose();
    expect(await sink.play(silence(50), sampleRateHz: 16000), isFalse);
  });
}

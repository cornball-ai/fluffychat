// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:typed_data';

import 'package:fluffychat/utils/voice/speech_energy.dart';
import 'package:flutter_test/flutter_test.dart';

/// A frame of [sampleCount] identical 16-bit samples at [amplitude].
///
/// Constant amplitude makes the expected RMS exactly the amplitude, so the
/// dBFS values below are arithmetic rather than something recorded from a
/// previous run of this same code.
Uint8List constantFrame(int amplitude, int sampleCount) {
  final bytes = ByteData(sampleCount * 2);
  for (var i = 0; i < sampleCount; i++) {
    bytes.setInt16(i * 2, amplitude, Endian.little);
  }
  return bytes.buffer.asUint8List();
}

void main() {
  group('rmsDbfs', () {
    test('digital silence reports the silence floor, not negative infinity', () {
      // log(0) is -inf, which propagates through any comparison as a value
      // that is neither above nor below a threshold in the way a caller
      // expects. The floor is what keeps the detector's arithmetic total.
      final level = rmsDbfs(constantFrame(0, 160));
      expect(level, silenceDbfs);
      expect(level.isFinite, isTrue);
    });

    test('an empty frame reports the silence floor', () {
      expect(rmsDbfs(Uint8List(0)), silenceDbfs);
    });

    test('half full-scale is -6 dBFS', () {
      // 20 * log10(16384 / 32768) = 20 * log10(0.5) = -6.0206
      expect(rmsDbfs(constantFrame(16384, 160)), closeTo(-6.02, 0.01));
    });

    test('quarter full-scale is -12 dBFS', () {
      expect(rmsDbfs(constantFrame(8192, 160)), closeTo(-12.04, 0.01));
    });

    test('full-scale is approximately 0 dBFS', () {
      expect(rmsDbfs(constantFrame(32767, 160)), closeTo(0.0, 0.01));
    });

    test('reads a frame that starts at an odd byte offset', () {
      // Frames arriving from a platform channel can be views into a larger
      // buffer at an arbitrary offset. `asInt16List` throws on an odd offset
      // rather than copying, so this is the case that decides whether the
      // implementation may use it. Swapping ByteData for asInt16List makes
      // this test throw, and nothing else here would notice.
      final backing = Uint8List(1 + 160 * 2);
      backing.setRange(1, backing.length, constantFrame(16384, 160));
      final unaligned = Uint8List.sublistView(backing, 1);

      expect(unaligned.offsetInBytes.isOdd, isTrue,
          reason: 'the view is aligned, so this proves nothing');
      expect(rmsDbfs(unaligned), closeTo(-6.02, 0.01));
    });

    test('ignores a trailing odd byte instead of reading past the end', () {
      final frame = Uint8List.fromList([
        ...constantFrame(16384, 4),
        0x7f, // half a sample
      ]);
      expect(rmsDbfs(frame), closeTo(-6.02, 0.01));
    });
  });

  group('frameDuration', () {
    test('160 samples at 16 kHz is 10 ms', () {
      expect(
        frameDuration(constantFrame(0, 160), sampleRate: voiceSampleRateForTest),
        const Duration(milliseconds: 10),
      );
    });

    test('an empty frame has no duration', () {
      expect(
        frameDuration(Uint8List(0), sampleRate: voiceSampleRateForTest),
        Duration.zero,
      );
    });
  });

  group('BargeInDetector', () {
    /// 10 ms per frame at 16 kHz, so a 200 ms sustain needs 20 of them.
    BargeInDetector detector() => BargeInDetector(
          thresholdDbfs: -35.0,
          sustain: const Duration(milliseconds: 200),
          sampleRate: voiceSampleRateForTest,
        );

    final loud = constantFrame(16384, 160); // -6 dBFS, well above threshold
    final quiet = constantFrame(100, 160); // about -50 dBFS, below it

    test('does not fire before the sustain window is satisfied', () {
      final d = detector();
      for (var i = 0; i < 19; i++) {
        expect(d.addFrame(loud), isFalse, reason: 'fired early at frame $i');
      }
      expect(d.aboveFor, const Duration(milliseconds: 190));
    });

    test('fires once the level has been up for the full window', () {
      final d = detector();
      for (var i = 0; i < 19; i++) {
        d.addFrame(loud);
      }
      expect(d.addFrame(loud), isTrue);
    });

    test('a brief spike does not fire it', () {
      // The whole point of the sustain window: a door slam or a keyboard is
      // loud but short, and cutting the bot off for one is worse than not
      // cutting it off at all.
      final d = detector();
      for (var i = 0; i < 5; i++) {
        expect(d.addFrame(loud), isFalse);
      }
      expect(d.addFrame(quiet), isFalse);
      for (var i = 0; i < 5; i++) {
        expect(d.addFrame(loud), isFalse);
      }
    });

    test('a quiet frame restarts the count rather than pausing it', () {
      final d = detector();
      for (var i = 0; i < 15; i++) {
        d.addFrame(loud);
      }
      d.addFrame(quiet);
      expect(d.aboveFor, Duration.zero);
    });

    test('fires only on the frame that satisfies the window', () {
      // A caller that keeps feeding frames must not get a barge-in event on
      // every subsequent frame, or playback would be cut once and then the
      // event would repeat for as long as the user keeps talking.
      final d = detector();
      var fires = 0;
      for (var i = 0; i < 30; i++) {
        if (d.addFrame(loud)) fires++;
      }
      expect(fires, 1);
    });

    test('reset clears an accumulated run', () {
      final d = detector();
      for (var i = 0; i < 19; i++) {
        d.addFrame(loud);
      }
      d.reset();
      expect(d.aboveFor, Duration.zero);
      expect(d.addFrame(loud), isFalse, reason: 'reset did not clear the run');
    });

    test('exposes the last level for tuning against real hardware', () {
      final d = detector();
      d.addFrame(loud);
      expect(d.lastLevel, closeTo(-6.02, 0.01));
    });
  });
}

/// An arbitrary rate for the arithmetic below, not a mirror of the app's
/// capture setting -- [frameDuration] and [BargeInDetector] take the rate as a
/// parameter, so what is under test here is the conversion, not the choice.
/// The app's actual capture format is pinned in voice_capture_test.dart.
const int voiceSampleRateForTest = 16000;

// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:typed_data';

import 'package:fluffychat/utils/voice/pcm_gain.dart';
import 'package:flutter_test/flutter_test.dart';

/// A chunk of S16LE mono at a given peak amplitude.
Uint8List _chunk(List<int> samples) =>
    Uint8List.view(Int16List.fromList(samples).buffer);

List<int> _samples(Uint8List pcm) => Int16List.view(
  pcm.buffer,
  pcm.offsetInBytes,
  pcm.lengthInBytes ~/ 2,
).toList();

int _peak(Uint8List pcm) =>
    _samples(pcm).map((s) => s.abs()).reduce((a, b) => a > b ? a : b);

void main() {
  test('the ceiling binds before the target on a very quiet source', () {
    // Worth pinning: below -24 dBFS the target is out of reach, so a source
    // that quiet comes out quieter than everything else. The log line at
    // playback is what says whether that is happening.
    final gain = SpeechGain();
    final pcm = _chunk([1000, -1000]);

    expect(gain.apply(pcm), 16.0);
    expect(_peak(pcm), 16000);
  });

  test('a quiet reply is lifted to the target', () {
    // Playback has no volume of its own, so this is the whole difference
    // between an audible assistant and an inaudible one.
    final gain = SpeechGain();
    // A peak of -12 dBFS: quiet, but well inside what the ceiling can lift.
    final pcm = _chunk([8000, -8000, 4000, 0]);

    final applied = gain.apply(pcm);

    expect(applied, greaterThan(1.0));
    expect(_peak(pcm), closeTo(0.89 * 32767, 1));
  });

  test('a synthesiser that already runs hot is left alone', () {
    final gain = SpeechGain();
    final pcm = _chunk([32000, -31000]);

    expect(gain.apply(pcm), 1.0);
    expect(_samples(pcm), [32000, -31000]);
  });

  test('amplification stops at the ceiling', () {
    // Otherwise near-silence asks for unbounded gain and room tone arrives
    // as a roar.
    final gain = SpeechGain(maxGain: 4.0);
    final pcm = _chunk([10, -10]);

    expect(gain.apply(pcm), 4.0);
    expect(_samples(pcm), [40, -40]);
  });

  test('silence is left silent rather than divided by zero', () {
    final gain = SpeechGain();
    final pcm = _chunk([0, 0, 0]);

    expect(gain.apply(pcm), 1.0);
    expect(_samples(pcm), [0, 0, 0]);
    expect(gain.peakDbfs, isNull);
  });

  test('no sample can clip, whatever the chunk', () {
    final gain = SpeechGain();
    for (final peak in [1, 100, 5000, 20000, 32767]) {
      final pcm = _chunk([peak, -peak, peak ~/ 2]);
      gain.apply(pcm);
      expect(_samples(pcm).every((s) => s.abs() <= 32767), isTrue);
    }
  });

  test('the most negative sample does not overflow into itself', () {
    // -32768 has no positive counterpart, so a naive abs() returns it
    // unchanged and the peak reads as negative.
    final gain = SpeechGain();
    final pcm = _chunk([-32768]);

    expect(gain.apply(pcm), 1.0);
    expect(gain.peakAmplitude, 32767);
  });

  test('the gain only falls within a reply, never rises', () {
    // A later chunk louder than the ones before it must not be scaled by a
    // gain chosen when the reply looked quiet -- and the correction has to
    // be downward only, or the volume pumps mid-sentence.
    final gain = SpeechGain();
    final first = gain.apply(_chunk([2000, -2000]));
    final second = gain.apply(_chunk([16000, -16000]));
    final third = gain.apply(_chunk([100, -100]));

    expect(first, greaterThan(second));
    expect(third, second);
  });

  test('a loud chunk after a quiet one still cannot clip', () {
    final gain = SpeechGain();
    gain.apply(_chunk([500, -500]));
    final loud = _chunk([30000, -30000]);
    gain.apply(loud);

    expect(_peak(loud), lessThanOrEqualTo(32767));
  });

  test(
    'the peak is reported in dBFS for the log that explains a quiet turn',
    () {
      final gain = SpeechGain();
      gain.apply(_chunk([3277])); // a tenth of full scale
      expect(gain.peakDbfs, closeTo(-20, 0.1));
    },
  );

  test('a new reply starts from its own level', () {
    // One instance per turn, so a shouted reply cannot set the level for the
    // whisper that follows it.
    final loud = SpeechGain()..apply(_chunk([32000]));
    final quiet = SpeechGain();

    expect(loud.gain, 1.0);
    expect(quiet.apply(_chunk([1000])), greaterThan(1.0));
  });
}

// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:math';
import 'dart:typed_data';

import 'package:fluffychat/utils/voice/pcm_gain.dart';
import 'package:flutter_test/flutter_test.dart';

const _rate = 16000;

/// A second of tone at [amplitude], which gives a chunk a real RMS instead
/// of the spike a handful of samples would produce.
Uint8List _tone(int amplitude, {int samples = _rate}) {
  final data = Int16List(samples);
  for (var i = 0; i < samples; i++) {
    data[i] = (amplitude * sin(2 * pi * 200 * i / _rate)).round();
  }
  return Uint8List.view(data.buffer);
}

List<int> _samples(Uint8List pcm) => Int16List.view(
  pcm.buffer,
  pcm.offsetInBytes,
  pcm.lengthInBytes ~/ 2,
).toList();

int _peak(Uint8List pcm) =>
    _samples(pcm).map((s) => s.abs()).reduce((a, b) => a > b ? a : b);

double _rms(Uint8List pcm) {
  final samples = _samples(pcm);
  final sum = samples.fold<double>(0, (acc, s) {
    final f = s / 32767;
    return acc + f * f;
  });
  return sqrt(sum / samples.length);
}

void main() {
  test('a quiet reply is brought up', () {
    // Playback has no volume of its own, so this is the whole difference
    // between an audible assistant and an inaudible one.
    final gain = SpeechGain();
    final pcm = _tone(1600); // about -26 dBFS RMS

    final applied = gain.apply(pcm, sampleRateHz: _rate);

    expect(applied, greaterThan(1.0));
    expect(_rms(pcm), greaterThan(0.02));
  });

  test('a steady level settles at the target', () {
    final gain = SpeechGain();
    Uint8List? last;
    for (var i = 0; i < 12; i++) {
      last = _tone(1600);
      gain.apply(last, sampleRateHz: _rate);
    }
    expect(_rms(last!), closeTo(0.1, 0.02));
  });

  test('one loud syllable does not quieten the rest of the reply', () {
    // The regression, reported from listening to it: the reply started at a
    // decent volume and then went quiet and stayed quiet. The old gain
    // divided the whole reply down by the loudest sample it had seen, so
    // the first emphatic word set the level for everything after it.
    final gain = SpeechGain();
    for (var i = 0; i < 6; i++) {
      gain.apply(_tone(1600), sampleRateHz: _rate);
    }
    final before = _rms(_applied(gain, _tone(1600)));

    // A plosive: brief, and 20 dB above the words around it.
    gain.apply(_tone(16000, samples: _rate ~/ 20), sampleRateHz: _rate);

    final after = _rms(_applied(gain, _tone(1600)));
    // Some ducking is a compressor doing its job; an order of magnitude is
    // the bug.
    expect(after, greaterThan(before * 0.7));
  });

  test('a synthesiser that already runs hot is left alone', () {
    final gain = SpeechGain();
    final pcm = _tone(30000);

    expect(gain.apply(pcm, sampleRateHz: _rate), 1.0);
    expect(_peak(pcm), 30000);
  });

  test('no chunk can clip, at any level or in any order', () {
    final gain = SpeechGain();
    for (final amplitude in [100, 800, 30000, 200, 32767, 1500]) {
      final pcm = _tone(amplitude);
      gain.apply(pcm, sampleRateHz: _rate);
      expect(_peak(pcm), lessThanOrEqualTo(32767));
      expect(_samples(pcm).every((s) => s.abs() <= 32767), isTrue);
    }
  });

  test('a loud chunk after a quiet run is not amplified into a wrap', () {
    // The dangerous ordering: eight quiet chunks wind the level gain up,
    // then a chunk arrives that needs none of it. Its own peak is measured
    // before the gain is chosen, so the ceiling wins -- and since that
    // ceiling is below 1.0 here, the chunk passes through untouched rather
    // than being pulled down. This is a makeup gain, not a normaliser: a
    // source that is already loud enough is already right.
    final gain = SpeechGain();
    for (var i = 0; i < 8; i++) {
      gain.apply(_tone(800), sampleRateHz: _rate);
    }
    expect(gain.gain, greaterThan(4.0));

    final loud = _tone(30000);
    expect(gain.apply(loud, sampleRateHz: _rate), 1.0);
    expect(_peak(loud), 30000);
  });

  test('silence moves the gain nowhere', () {
    // Otherwise a pause between sentences winds the gain to the ceiling and
    // the next word arrives as a shout.
    final gain = SpeechGain();
    for (var i = 0; i < 4; i++) {
      gain.apply(_tone(3000), sampleRateHz: _rate);
    }
    final settled = gain.gain;

    for (var i = 0; i < 10; i++) {
      gain.apply(Uint8List(_rate * 2), sampleRateHz: _rate);
    }
    expect(gain.gain, settled);
  });

  test('the gain comes down faster than it goes back up', () {
    // Being briefly too loud is worse than being briefly too quiet.
    final falling = SpeechGain();
    for (var i = 0; i < 6; i++) {
      falling.apply(_tone(800), sampleRateHz: _rate);
    }
    final high = falling.gain;
    falling.apply(_tone(8000), sampleRateHz: _rate);
    final drop = high - falling.gain;

    final rising = SpeechGain();
    for (var i = 0; i < 6; i++) {
      rising.apply(_tone(8000), sampleRateHz: _rate);
    }
    final low = rising.gain;
    rising.apply(_tone(800), sampleRateHz: _rate);
    final climb = rising.gain - low;

    expect(drop, greaterThan(climb));
  });

  test('the most negative sample does not overflow into itself', () {
    // -32768 has no positive counterpart, so a naive abs() returns it
    // unchanged and the peak reads as negative.
    final gain = SpeechGain();
    final pcm = Uint8List.view(Int16List.fromList([-32768, 0]).buffer);

    gain.apply(pcm, sampleRateHz: _rate);
    expect(gain.peakAmplitude, 32767);
  });

  test('an empty chunk is not a division by zero', () {
    final gain = SpeechGain();
    expect(gain.apply(Uint8List(0), sampleRateHz: _rate), 1.0);
    expect(gain.rmsDbfs, isNull);
    expect(gain.peakDbfs, isNull);
  });

  test('a new reply starts from its own level', () {
    // One instance per turn, so a shouted reply cannot set the level for the
    // whisper that follows it.
    final loud = SpeechGain();
    for (var i = 0; i < 6; i++) {
      loud.apply(_tone(30000), sampleRateHz: _rate);
    }
    final quiet = SpeechGain();

    expect(loud.gain, closeTo(1.0, 0.01));
    expect(quiet.apply(_tone(1600), sampleRateHz: _rate), greaterThan(1.0));
  });

  test('levels are reported for the log that explains a quiet turn', () {
    final gain = SpeechGain();
    gain.apply(_tone(3277), sampleRateHz: _rate); // peak a tenth of full scale
    expect(gain.peakDbfs, closeTo(-20, 0.5));
    expect(gain.rmsDbfs, closeTo(-23, 1.0));
  });
}

/// Applies the gain and hands the chunk back, for reading its level.
Uint8List _applied(SpeechGain gain, Uint8List pcm) {
  gain.apply(pcm, sampleRateHz: _rate);
  return pcm;
}

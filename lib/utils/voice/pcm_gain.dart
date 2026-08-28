// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:math';
import 'dart:typed_data';

/// Brings a reply up to a usable listening level and keeps it there.
///
/// Synthesised speech arrives at whatever level the synthesiser produced, and
/// that level is not ours to choose: it depends on the voice, the reference
/// clip and the model. Playback has no volume of its own -- `aplay` writes
/// the samples it is given -- so a quiet synthesiser is a quiet assistant no
/// matter how far up the system mixer goes.
///
/// Two separate jobs, because one number cannot do both.
///
/// **Level** follows RMS, not peak. Perceived loudness tracks RMS, and speech
/// peaks are spikes: one plosive is 10 dB above the words around it and says
/// almost nothing about how loud the sentence sounds. The gain moves toward
/// whatever would put this chunk's RMS at [targetRms], smoothed over time so
/// it does not pump -- quickly when it has to come down, slowly when it comes
/// back up, the way every compressor does it.
///
/// **Clipping** is prevented per chunk, by peak. Whatever the smoothed gain
/// currently is, this chunk is never scaled past the point where its own
/// loudest sample reaches [targetPeak]. Its peak is measured before the gain
/// is chosen, so this is arithmetic rather than a hope.
///
/// Keeping them apart is the point. An earlier version drove everything from
/// a running peak that only ever grew, so the first loud syllable of a reply
/// permanently divided the rest of it down: the reply started at a good level
/// and got quieter and stayed quieter, which is exactly what it sounded like.
/// Now a loud syllable limits its own chunk and nothing else.
///
/// One instance per reply. Nothing carries across turns.
class SpeechGain {
  /// Where a chunk's RMS should end up, as a fraction of full scale. 0.1 is
  /// -20 dBFS, a normal speech level with headroom left for the peaks.
  final double targetRms;

  /// The most a chunk's loudest sample may reach, as a fraction of full
  /// scale. Just under 1.0, so rounding cannot push a sample over the top.
  final double targetPeak;

  /// The ceiling on amplification. Silence has an RMS of zero and would ask
  /// for infinite gain, so there has to be one. 16x is +24 dB, which reaches
  /// the target from a source at -44 dBFS RMS.
  final double maxGain;

  /// How fast the gain comes down. Short: being briefly too loud is worse
  /// than being briefly too quiet.
  final Duration attack;

  /// How fast the gain goes back up. Long, so a quiet passage inside a
  /// sentence is heard as quiet rather than pumped up to match the rest.
  final Duration release;

  SpeechGain({
    this.targetRms = 0.1,
    this.targetPeak = 0.89,
    this.maxGain = 16.0,
    this.attack = const Duration(milliseconds: 200),
    this.release = const Duration(milliseconds: 1500),
  });

  static const int _fullScale = 32767;

  double _gain = 1.0;
  int _peak = 0;
  double _lastRms = 0;

  /// The loudest sample seen so far this reply, in absolute amplitude.
  int get peakAmplitude => _peak;

  /// That peak as dBFS, or null before any sample has been seen. For logs:
  /// the number that says whether quiet playback is the synthesiser's doing
  /// or the system's.
  double? get peakDbfs => _peak == 0 ? null : _dbfs(_peak / _fullScale);

  /// The most recent chunk's RMS as dBFS, or null before any sound. The
  /// level the gain is actually steering.
  double? get rmsDbfs => _lastRms == 0 ? null : _dbfs(_lastRms);

  /// The smoothed level gain, before this chunk's peak ceiling is applied.
  double get gain => _gain;

  static double _dbfs(double fraction) => 20 * (log(fraction) / ln10);

  /// Scales [pcm] in place, as signed 16-bit little-endian mono, and returns
  /// the gain actually applied to it.
  ///
  /// In place because these buffers are handed straight to the speaker and
  /// nothing else reads them; a copy per chunk would be pure garbage for the
  /// collector during the one part of a turn that has to keep up with real
  /// time.
  double apply(Uint8List pcm, {required int sampleRateHz}) {
    final samples = Int16List.view(
      pcm.buffer,
      pcm.offsetInBytes,
      pcm.lengthInBytes ~/ 2,
    );
    if (samples.isEmpty) return _gain;

    var peak = 0;
    var sumSquares = 0.0;
    for (final sample in samples) {
      // -32768 has no positive counterpart; treat it as full scale rather
      // than letting the negation overflow back to itself.
      final magnitude = sample == -32768 ? _fullScale : sample.abs();
      if (magnitude > peak) peak = magnitude;
      final fraction = magnitude / _fullScale;
      sumSquares += fraction * fraction;
    }
    if (peak > _peak) _peak = peak;
    final rms = sqrt(sumSquares / samples.length);
    _lastRms = rms;

    if (rms > 0) {
      final wanted = (targetRms / rms).clamp(1.0, maxGain);
      // Silence carries no level information, so it moves nothing: a pause
      // between sentences must not wind the gain up to the ceiling and then
      // shout the next word.
      final tau = wanted < _gain ? attack : release;
      final dt = Duration(
        microseconds: samples.length * 1000000 ~/ sampleRateHz,
      );
      final alpha = tau.inMicroseconds <= 0
          ? 1.0
          : 1 - exp(-dt.inMicroseconds / tau.inMicroseconds);
      _gain += alpha * (wanted - _gain);
    }

    // Whatever the level gain says, this chunk does not go past its own
    // peak's headroom. Measured above, before the choice, so it holds.
    final ceiling = peak == 0 ? maxGain : targetPeak * _fullScale / peak;
    final applied = min(_gain, ceiling).clamp(1.0, maxGain);
    if (applied == 1.0) return applied;
    for (var i = 0; i < samples.length; i++) {
      final scaled = (samples[i] * applied).round();
      // Defensive: the ceiling above already keeps the product inside full
      // scale. A wrapped waveform is a far worse failure than a limited one,
      // and this costs a comparison.
      samples[i] = scaled.clamp(-_fullScale, _fullScale);
    }
    return applied;
  }
}

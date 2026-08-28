// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:math';
import 'dart:typed_data';

/// Brings a reply up to a usable listening level.
///
/// Synthesised speech arrives at whatever level the synthesiser produced, and
/// that level is not ours to choose: it depends on the voice, the reference
/// clip and the model. Playback has no volume of its own -- `aplay` writes
/// the samples it is given -- so a quiet synthesiser is a quiet assistant no
/// matter how far up the system mixer goes, which is exactly what it did.
///
/// Rather than a fixed multiplier tuned to one voice, the gain is derived
/// from the audio: it lifts the loudest sample seen so far in this reply to
/// [targetPeak] and never further than [maxGain]. That makes it self-tuning
/// across voices and incapable of clipping the peak it measured, and it does
/// nothing at all to a synthesiser that already runs hot.
///
/// The running peak only ever grows within a reply, so the gain only ever
/// falls: a chunk cannot be quieter than the one before it because the
/// measurement moved. One instance per reply -- a new turn is a new object,
/// so the peak resets with it and a loud reply cannot deafen the next one.
class SpeechGain {
  /// Where the loudest sample should end up, as a fraction of full scale.
  /// Just under 1.0, so rounding cannot push a sample over the top.
  final double targetPeak;

  /// The ceiling on amplification. Silence has a peak of zero and would ask
  /// for infinite gain, so there has to be one.
  ///
  /// 16x is +24 dB, which reaches the target from a source peaking at -24
  /// dBFS. The ceiling can afford to be generous because the peak is measured
  /// over speech, not over the gaps in it: a reply with words in it has a
  /// real peak, and only a reply that is quiet all the way through gets the
  /// full lift.
  final double maxGain;

  SpeechGain({this.targetPeak = 0.89, this.maxGain = 16.0});

  static const int _fullScale = 32767;

  int _peak = 0;

  /// The loudest sample seen so far this reply, in absolute amplitude.
  int get peakAmplitude => _peak;

  /// That peak as dBFS, or null before any sample has been seen. For logs:
  /// it is the number that says whether quiet playback is the synthesiser's
  /// doing or the system's.
  double? get peakDbfs =>
      _peak == 0 ? null : 20 * (log(_peak / _fullScale) / ln10);

  /// The gain [apply] would use right now, given everything measured so far.
  double get gain {
    if (_peak == 0) return 1.0;
    final wanted = targetPeak * _fullScale / _peak;
    return wanted.clamp(1.0, maxGain);
  }

  /// Scales [pcm] in place, as signed 16-bit little-endian mono, and returns
  /// the gain applied.
  ///
  /// In place because these buffers are handed straight to the speaker and
  /// nothing else reads them; a copy per chunk would be pure garbage for the
  /// collector during the one part of a turn that has to keep up with real
  /// time.
  double apply(Uint8List pcm) {
    final samples = Int16List.view(
      pcm.buffer,
      pcm.offsetInBytes,
      pcm.lengthInBytes ~/ 2,
    );
    for (final sample in samples) {
      // -32768 has no positive counterpart; treat it as full scale rather
      // than letting the negation overflow back to itself.
      final magnitude = sample == -32768 ? _fullScale : sample.abs();
      if (magnitude > _peak) _peak = magnitude;
    }
    final gain = this.gain;
    if (gain == 1.0) return gain;
    for (var i = 0; i < samples.length; i++) {
      final scaled = (samples[i] * gain).round();
      // Defensive: this chunk's own peak is measured above before the gain
      // is chosen, so the product cannot reach full scale. The clamp is
      // there because a wrapped waveform is a much worse failure than a
      // limited one, and it costs a comparison.
      samples[i] = scaled.clamp(-_fullScale, _fullScale);
    }
    return gain;
  }
}

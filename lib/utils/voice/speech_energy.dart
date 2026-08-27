// SPDX-FileCopyrightText: 2026-Present cornball.ai
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:math';
import 'dart:typed_data';

/// Barge-in detection: deciding that the user has started talking while the
/// bot is still speaking, so playback can be cut.
///
/// This deliberately runs on plain signal energy rather than a voice-activity
/// model. Barge-in only has to answer "is someone talking over me", which is a
/// much easier question than "did they finish their thought" -- the latter is
/// semantic endpointing and lives server-side, where the model can be retuned
/// without shipping an app release.
///
/// The hard part is not detection, it is not hearing our own text-to-speech
/// coming back in through the microphone. That is handled upstream by platform
/// acoustic echo cancellation (`echoCancel` in the capture config), not here.
/// If AEC turns out to leak on loud speakerphone playback, this is the piece
/// that gets replaced by a real VAD model.

/// Reported for digital silence, standing in for the negative infinity that
/// `log(0)` would otherwise produce.
const double silenceDbfs = -160.0;

/// Full-scale magnitude of a signed 16-bit sample.
const double _fullScale = 32768.0;

/// Root-mean-square level of a signed 16-bit little-endian PCM frame, in dBFS.
///
/// Returns [silenceDbfs] for an empty frame or one that is all zeroes. A
/// trailing odd byte is ignored rather than treated as a sample.
double rmsDbfs(Uint8List frame) {
  final sampleCount = frame.lengthInBytes ~/ 2;
  if (sampleCount == 0) return silenceDbfs;

  // A ByteData view rather than `asInt16List`: a Uint8List arriving from a
  // platform channel may be a view starting at an odd byte offset, and
  // asInt16List throws on that instead of copying. ByteData permits unaligned
  // reads, so this is correct for any offset.
  final bytes = ByteData.sublistView(frame);
  var sumSquares = 0.0;
  for (var i = 0; i < sampleCount; i++) {
    final sample = bytes.getInt16(i * 2, Endian.little);
    sumSquares += sample * sample;
  }

  final rms = sqrt(sumSquares / sampleCount);
  if (rms <= 0) return silenceDbfs;
  return 20 * (log(rms / _fullScale) / ln10);
}

/// How long a frame of 16-bit mono PCM represents at [sampleRate].
Duration frameDuration(Uint8List frame, {required int sampleRate}) {
  final sampleCount = frame.lengthInBytes ~/ 2;
  if (sampleCount == 0 || sampleRate <= 0) return Duration.zero;
  return Duration(microseconds: (sampleCount * 1000000 / sampleRate).round());
}

/// Fires once the input has been continuously above [thresholdDbfs] for
/// [sustain].
///
/// The sustain window is what separates speech from a door slam or a keyboard.
/// A single loud frame is not enough; the level has to stay up. Any frame below
/// the threshold restarts the count, so this measures a continuous run rather
/// than a total.
class BargeInDetector {
  /// Level above which audio counts as someone talking. Default is chosen to
  /// sit above room tone and below conversational speech at arm's length;
  /// it is a starting point to be tuned against real devices, not a constant
  /// anyone has measured yet.
  final double thresholdDbfs;

  /// How long the level must stay up before this fires.
  final Duration sustain;

  /// Sample rate of the frames being fed in, used to convert byte counts to
  /// elapsed time.
  final int sampleRate;

  /// How far above the adaptive noise floor a frame must sit to count as
  /// someone talking over the reply.
  ///
  /// The floor exists because during playback the microphone always hears
  /// SOME of our own speaker output, and on a laptop the speakers sit next
  /// to the mic -- a fixed threshold either cuts the reply on its own
  /// audio or goes deaf to the user, depending on volume. Steady bleed
  /// raises the floor (tracked as a slow exponential moving average); a
  /// human talking over it is a sustained jump ABOVE that floor. Speech
  /// over speech at conversational distance runs 10 dB or more hot, so the
  /// default margin sits just under that.
  final double snrMarginDb;

  /// Smoothing factor for the noise-floor average, per frame. Small on
  /// purpose: the floor should follow the reply's overall loudness, not
  /// chase the very speech burst it exists to detect.
  final double emaAlpha;

  /// How long after [audioStarted] the detector learns instead of judging:
  /// frames update the floor fast and cannot fire.
  ///
  /// This window exists because the floor otherwise spends the silent
  /// generation seconds learning silence, and the speaker's own onset then
  /// trips the trigger before the floor has ever met the bleed -- measured
  /// live as a cut at level -19.9 dBFS against a floor still sitting at
  /// its -44 seed. Nobody genuinely interrupts within the first syllable;
  /// the bleed is all these frames can teach.
  final Duration primeFor;

  /// Fast learning rate used inside the priming window.
  final double primeAlpha;

  BargeInDetector({
    this.thresholdDbfs = -35.0,
    this.sustain = const Duration(milliseconds: 200),
    this.sampleRate = 16000,
    this.snrMarginDb = 9.0,
    this.emaAlpha = 0.05,
    this.primeFor = const Duration(milliseconds: 300),
    this.primeAlpha = 0.5,
  });

  Duration _primeLeft = Duration.zero;

  Duration _aboveFor = Duration.zero;
  Duration _triggeredAfter = Duration.zero;
  double _triggerLevel = silenceDbfs;
  double _lastLevel = silenceDbfs;
  double? _floorDbfs;

  /// Level of the most recent frame, for meters and for diagnosing a threshold
  /// that turns out to be wrong on real hardware.
  double get lastLevel => _lastLevel;

  /// How long the level has been continuously above the threshold.
  ///
  /// This is the *running* count, so it is zero immediately after a fire. Use
  /// [triggeredAfter] to report what actually caused a cut.
  Duration get aboveFor => _aboveFor;

  /// The run length and level that caused the most recent fire, kept because
  /// the running count is cleared by the fire itself.
  ///
  /// These exist for one specific failure. If platform echo cancellation leaks
  /// at high speaker volume, the detector hears our own synthesised speech and
  /// cuts playback with no user input at all -- so the assistant interrupts
  /// itself, repeatedly, mid-sentence. That looks like a fault in whatever is
  /// generating the replies rather than in capture, and someone will debug the
  /// wrong process for a while unless the cut says what triggered it.
  ///
  /// A cut logged with its level and run length is what separates the two: a
  /// user talking over the reply looks different from our own output leaking
  /// back, and both look different from a threshold set too low.
  Duration get triggeredAfter => _triggeredAfter;

  /// Level of the frame that completed the most recent fire. See
  /// [triggeredAfter].
  double get triggerLevel => _triggerLevel;

  /// The current adaptive noise floor, for the same diagnostic purpose as
  /// [triggerLevel]: a cut whose level barely clears a high floor reads
  /// differently from one towering over a quiet room.
  double get floorDbfs => _floorDbfs ?? (thresholdDbfs - snrMarginDb);

  /// The level a frame must reach right now to count toward a fire: the
  /// fixed threshold, or the adaptive floor plus margin, whichever is
  /// higher.
  double get effectiveThresholdDbfs =>
      max(thresholdDbfs, floorDbfs + snrMarginDb);

  /// Feeds one frame. Returns true on the frame where the sustain window is
  /// satisfied, and only that frame -- the count restarts afterwards, so a
  /// caller that keeps feeding does not get a repeat every frame.
  /// Playback is starting a chunk: learn before judging. Called at every
  /// chunk start, not just the first -- the floor decays toward silence
  /// across inter-chunk gaps (generation runs behind real time on small
  /// cards), and each chunk's onset would otherwise reopen the hole this
  /// window closes.
  void audioStarted() {
    _primeLeft = primeFor;
    _aboveFor = Duration.zero;
  }

  bool addFrame(Uint8List frame) {
    final level = _lastLevel = rmsDbfs(frame);
    final floor = _floorDbfs ?? (thresholdDbfs - snrMarginDb);
    if (_primeLeft > Duration.zero) {
      // Priming: this frame is the speaker's own onset by presumption.
      // It teaches the floor and cannot fire.
      _primeLeft -= frameDuration(frame, sampleRate: sampleRate);
      _floorDbfs = floor + primeAlpha * (level - floor);
      _aboveFor = Duration.zero;
      return false;
    }
    final effective = effectiveThresholdDbfs;
    if (level < effective) {
      // Only sub-threshold frames teach the floor: steady speaker bleed is
      // exactly the signal it exists to absorb, while a voice loud enough
      // to count toward a fire must not raise its own bar mid-sustain --
      // with both at similar time constants, the floor would chase the
      // interruption and the trigger could never complete.
      _floorDbfs = floor + emaAlpha * (level - floor);
      _aboveFor = Duration.zero;
      return false;
    }

    _aboveFor += frameDuration(frame, sampleRate: sampleRate);
    if (_aboveFor < sustain) return false;

    _triggeredAfter = _aboveFor;
    _triggerLevel = level;
    _aboveFor = Duration.zero;
    return true;
  }

  /// Clears the run. Call when playback stops, so silence during the gap does
  /// not have to be re-accumulated against a stale count.
  ///
  /// Leaves [triggeredAfter] and [triggerLevel] alone: they describe a cut that
  /// already happened, and a caller logging them after stopping playback should
  /// still see what caused it.
  void reset() {
    _aboveFor = Duration.zero;
    _lastLevel = silenceDbfs;
    // The floor belongs to one reply's acoustic situation; the next reply
    // re-learns it from scratch rather than inheriting a stale one.
    _floorDbfs = null;
    _primeLeft = Duration.zero;
  }
}

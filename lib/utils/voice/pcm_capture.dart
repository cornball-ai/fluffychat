// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

/// Microphone capture for live voice conversation.
///
/// Separate from the recorder behind the voice-message button, which writes a
/// compressed file and uploads it. This one never touches the disk: it streams
/// raw samples for as long as the conversation lasts.
///
/// The format is fixed at 16 kHz mono 16-bit PCM because that is what the
/// speech model resamples to anyway. Encoding to Opus and decoding it again on
/// the other side would add latency to the one path where latency is the whole
/// product. Compression still earns its place on the async voice-message path,
/// which is left alone.

/// Sample rate of the live-voice stream, in samples per second.
const int voiceSampleRate = 16000;

/// Channel count of the live-voice stream. Mono: a second channel doubles the
/// bytes on the wire and the model discards it.
const int voiceNumChannels = 1;

/// Capture settings for live voice.
///
/// [AudioEncoder.pcm16bits] is valid here even though it has no file extension
/// -- extensions only matter to the file-writing path, and streaming never asks
/// for one.
const RecordConfig liveVoiceRecordConfig = RecordConfig(
  encoder: AudioEncoder.pcm16bits,
  sampleRate: voiceSampleRate,
  numChannels: voiceNumChannels,
  // Load-bearing for barge-in: without platform echo cancellation the
  // microphone hears our own speech synthesis coming out of the speaker, and
  // the client interrupts itself the moment the bot starts talking.
  echoCancel: true,
  noiseSuppress: true,
  // Off on purpose. Automatic gain moves the recording level up and down, and
  // barge-in compares that level against a fixed threshold -- so leaving it on
  // would quietly shift the very thing the threshold is calibrated against.
  autoGain: false,
  // Frame size is left at the platform default. Smaller frames would cut
  // barge-in latency, but `streamBufferSize` is documented to throw below a
  // device-specific minimum, and nobody has measured that minimum on the
  // hardware this has to run on. It is the first knob to reach for if barge-in
  // feels sluggish on a real phone.
);

/// Streams microphone frames as raw PCM.
///
/// Frames arrive as they come off the platform, so their size is not
/// guaranteed and callers must not assume a fixed byte count per frame.
class PcmCapture {
  final AudioRecorder _recorder;

  PcmCapture({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  StreamSubscription<Uint8List>? _subscription;
  bool _running = false;

  // Held for the whole of start() so a second call awaits the first instead
  // of racing it: the _running check alone is decided before start()'s first
  // await, so two concurrent calls used to both pass it and open the
  // recorder twice.
  Future<bool>? _starting;

  bool get isRunning => _running;

  /// Whether the user has granted microphone access.
  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Starts capture, delivering frames to [onFrame].
  ///
  /// Returns false without starting if permission is refused, so callers can
  /// tell "declined" apart from "started and produced nothing".
  ///
  /// [onEnded] fires once if capture dies from underneath the caller -- the
  /// platform closing the stream, or an error on it -- with the error when
  /// there was one and null for a plain close. By the time it fires,
  /// [isRunning] is already false. It does not fire for a caller-initiated
  /// [stop]: the caller knows about that one, and a session tearing itself
  /// down must be able to tell "I stopped it" from "it fell over", because
  /// only the second one is worth surfacing to the user.
  Future<bool> start(
    void Function(Uint8List frame) onFrame, {
    void Function(Object? error)? onEnded,
  }) {
    final inFlight = _starting;
    if (inFlight != null) return inFlight;
    final attempt = _start(onFrame, onEnded);
    _starting = attempt;
    return attempt.whenComplete(() => _starting = null);
  }

  Future<bool> _start(
    void Function(Uint8List frame) onFrame,
    void Function(Object? error)? onEnded,
  ) async {
    if (_running) return true;
    if (!await _recorder.hasPermission()) return false;

    final stream = await _recorder.startStream(liveVoiceRecordConfig);
    _running = true;
    _subscription = stream.listen(
      onFrame,
      // Without these, a recorder that dies leaves isRunning true and the
      // error becomes an unhandled zone error instead of a signal: the
      // session keeps waiting on a microphone that no longer exists.
      onError: (Object error) {
        _running = false;
        _subscription = null;
        onEnded?.call(error);
      },
      onDone: () {
        // stop() flips _running before cancelling, so a done event arriving
        // from our own cancel finds it already false and stays silent.
        if (!_running) return;
        _running = false;
        _subscription = null;
        onEnded?.call(null);
      },
      cancelOnError: true,
    );
    return true;
  }

  /// Stops capture. Safe to call when not running.
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    await _subscription?.cancel();
    _subscription = null;
    await _recorder.stop();
  }

  /// Releases the recorder. The instance is not reusable afterwards.
  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
  }
}

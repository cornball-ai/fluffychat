// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'pcm_sink.dart';

/// [PcmSink] for desktop Linux, backed by a piped `aplay` process.
///
/// Chosen over a Flutter audio package because on this app's primary desktop
/// the alternatives are not real: just_audio has no Linux backend here, and
/// upstream's media_kit dependency has not reached a release tag. `aplay`
/// ships with alsa-utils on any Ubuntu desktop, takes raw S16LE on stdin,
/// and dies instantly when killed -- which is precisely the barge-in
/// requirement. The cost is that playback position must be inferred rather
/// than asked for, documented at [play].
///
/// One process serves the whole sink lifetime (per sample rate); chunks are
/// written sequentially with a small lookahead so the pipe never runs dry at
/// a chunk boundary.
class AplayPcmSink implements PcmSink {
  /// ALSA device name. The default plays through the desktop's output;
  /// tests pass `null` (the ALSA null device) to run without hardware.
  final String device;

  /// How far before the previous chunk's scheduled end the next chunk's
  /// bytes are written. Bridges the gap between wall-clock scheduling and
  /// the pipe: without it every chunk boundary risks an underrun of exactly
  /// the scheduling jitter.
  final Duration lookahead;

  AplayPcmSink({
    this.device = 'default',
    this.lookahead = const Duration(milliseconds: 200),
  });

  Process? _process;
  int? _processRate;
  Future<Process>? _starting;

  /// Wall-clock instant the last accepted chunk finishes playing.
  DateTime _tail = DateTime.fromMillisecondsSinceEpoch(0);

  /// Serialises play() calls: each awaits the previous one's completion.
  Future<void> _queue = Future.value();

  int _epoch = 0;
  bool _disposed = false;

  /// Plays the chunk, inferring progress from the wall clock.
  ///
  /// aplay exposes no position API over a pipe, so elapsed time is measured
  /// from the chunk's scheduled start (the previous chunk's scheduled end,
  /// or now). The pipe's own prebuffer makes this honest to within tens of
  /// milliseconds, which the accounting layer's midpoint rule absorbs on
  /// sentence-sized chunks; it is not sample-accurate and does not claim to
  /// be.
  @override
  Future<bool> play(
    Uint8List pcm, {
    required int sampleRateHz,
    void Function(Duration elapsed)? onProgress,
  }) {
    if (_disposed) return Future.value(false);
    final myEpoch = _epoch;
    final result = _queue.then(
      (_) => _playOne(pcm, sampleRateHz, onProgress, myEpoch),
    );
    // Failures propagate through the returned future; the queue itself must
    // keep accepting later chunks after one fails.
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<bool> _playOne(
    Uint8List pcm,
    int sampleRateHz,
    void Function(Duration elapsed)? onProgress,
    int myEpoch,
  ) async {
    if (_disposed || myEpoch != _epoch || pcm.isEmpty) return false;

    final process = await _ensureProcess(sampleRateHz);
    if (_disposed || myEpoch != _epoch) return false;

    // 2 bytes per sample, mono.
    final duration = Duration(
      microseconds: (pcm.length * 1000000) ~/ (2 * sampleRateHz),
    );

    final now = DateTime.now();
    var start = _tail.isAfter(now) ? _tail : now;

    // Wait until the lookahead window before this chunk's start, so bytes
    // for chunk k+1 sit in the pipe before chunk k drains.
    final writeAt = start.subtract(lookahead);
    final wait = writeAt.difference(DateTime.now());
    if (wait > Duration.zero) {
      await Future<void>.delayed(wait);
      if (_disposed || myEpoch != _epoch) return false;
    }

    // Recompute after the delay: a cancel during the wait reset the tail.
    final startedAt = DateTime.now();
    start = _tail.isAfter(startedAt) ? _tail : startedAt;
    _tail = start.add(duration);

    process.stdin.add(pcm);

    final done = Completer<bool>();
    final ticker = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (done.isCompleted) return;
      if (_disposed || myEpoch != _epoch) {
        done.complete(false);
        return;
      }
      final elapsed = DateTime.now().difference(start);
      if (elapsed >= duration) {
        onProgress?.call(duration);
        done.complete(true);
      } else if (elapsed > Duration.zero) {
        onProgress?.call(elapsed);
      }
    });
    final played = await done.future;
    ticker.cancel();
    return played;
  }

  Future<Process> _ensureProcess(int sampleRateHz) {
    final existing = _process;
    if (existing != null && _processRate == sampleRateHz) {
      return Future.value(existing);
    }
    final inFlight = _starting;
    if (inFlight != null) return inFlight;
    final attempt = _spawn(sampleRateHz);
    _starting = attempt;
    return attempt.whenComplete(() => _starting = null);
  }

  Future<Process> _spawn(int sampleRateHz) async {
    await _killProcess();
    final process = await Process.start('aplay', [
      '-q',
      '-D',
      device,
      '-t',
      'raw',
      '-f',
      'S16_LE',
      '-r',
      '$sampleRateHz',
      '-c',
      '1',
      '-',
    ]);
    // A sink that dies (device unplugged, alsa-utils missing at runtime)
    // must not leave writes going to a broken pipe unreported; the next
    // play() respawns, and stderr says why in the log.
    unawaited(
      process.exitCode.then((_) {
        if (identical(_process, process)) {
          _process = null;
          _processRate = null;
        }
      }),
    );
    _process = process;
    _processRate = sampleRateHz;
    return process;
  }

  @override
  Future<void> cancel() async {
    _epoch++;
    _tail = DateTime.fromMillisecondsSinceEpoch(0);
    await _killProcess();
  }

  Future<void> _killProcess() async {
    final process = _process;
    _process = null;
    _processRate = null;
    if (process == null) return;
    // SIGKILL, not SIGTERM. aplay catches SIGTERM for a graceful drain, but
    // it is blocked in a stdin read that the handler's flag never
    // interrupts, so a TERM'd aplay just sits there and exitCode never
    // resolves (measured: dispose() hung forever). SIGKILL is also the
    // semantics barge-in wants -- stop emitting sound NOW, not after
    // draining whatever the pipe still holds.
    process.kill(ProcessSignal.sigkill);
    await process.exitCode;
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await cancel();
  }
}

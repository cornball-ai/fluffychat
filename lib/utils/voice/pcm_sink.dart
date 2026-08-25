// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:typed_data';

/// Where synthesised audio actually goes.
///
/// This seam exists because the app's other audio paths cannot do the job:
/// the voice-message player plays encoded files through just_audio, which has
/// no Linux implementation in this app and no way to accept a queue of raw
/// PCM chunks that must be cancellable mid-chunk. Live voice needs exactly
/// that -- sentence-sized S16LE chunks, played gaplessly enough, with
/// progress the accounting layer can trust and a cancel that takes effect
/// now, not at the end of the chunk.
///
/// One chunk plays at a time; [play] calls queue behind each other. Progress
/// is reported per chunk from its own start, which is what ChunkPlayback
/// feeds on.
abstract class PcmSink {
  /// Plays one chunk of 16-bit little-endian mono PCM.
  ///
  /// Resolves true when the chunk played to its end, false when [cancel] cut
  /// it (or dropped it before it started). [onProgress] reports elapsed time
  /// within THIS chunk, monotonically, ending at or before the chunk's
  /// duration.
  Future<bool> play(
    Uint8List pcm, {
    required int sampleRateHz,
    void Function(Duration elapsed)? onProgress,
  });

  /// Stops the current chunk immediately and drops anything queued. Pending
  /// [play] futures resolve false. Safe to call when idle; the sink is
  /// usable again afterwards.
  Future<void> cancel();

  /// Cancels and releases the output. The sink is not usable afterwards.
  Future<void> dispose();
}

// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Tracks how much of a spoken reply the user actually heard.
///
/// Text-to-speech arrives as indexed chunks, and chunk *i* corresponds to text
/// piece *i* of the reply. When the user talks over the bot, playback is cut
/// and whatever is still queued is dropped -- so the room history would
/// otherwise record the bot as having said sentences that never left the
/// speaker. Reporting the last index actually heard is what lets the server
/// truncate the stored message to match.
///
/// This holds no timers and reads no clock: the caller feeds elapsed time from
/// the audio player. That keeps the rounding rule -- the part that is easy to
/// get wrong and impossible to see once it is wrong -- testable on its own.
class ChunkPlayback {
  /// Total chunks the server said it would send, from `on_chunk(_, _, total)`.
  /// Only used to report how many were dropped.
  int? totalAnnounced;

  int? _lastCompleted;
  int? _currentIndex;
  Duration _currentDuration = Duration.zero;
  Duration _elapsed = Duration.zero;

  /// Index of the chunk currently playing, if any.
  int? get currentIndex => _currentIndex;

  /// Highest chunk index the user is counted as having heard, or null if
  /// nothing was heard at all.
  ///
  /// A chunk that is still playing counts when it is **past halfway** -- heard
  /// more than half of it, count it as said. A chunk cut before its midpoint
  /// does not count, so the report falls back to the last one that finished.
  ///
  /// A zero-length chunk counts as heard, since there was nothing to miss.
  int? get heardThrough {
    final current = _currentIndex;
    if (current == null) return _lastCompleted;
    if (_elapsed * 2 >= _currentDuration) return current;
    return _lastCompleted;
  }

  /// How many chunks never reached the speaker, or null when the server did not
  /// say how many it was sending.
  ///
  /// Deliberately derived from [heardThrough] rather than counted separately:
  /// two numbers that can disagree is how a truncation report ends up plausible
  /// and wrong.
  int? get droppedCount {
    final total = totalAnnounced;
    if (total == null) return null;
    final heard = heardThrough;
    final played = heard == null ? 0 : heard + 1;
    final dropped = total - played;
    return dropped < 0 ? 0 : dropped;
  }

  /// Begins a chunk. [duration] is its full playable length.
  void startChunk(int index, Duration duration) {
    _currentIndex = index;
    _currentDuration = duration;
    _elapsed = Duration.zero;
  }

  /// Reports progress through the current chunk, measured from its start.
  void progress(Duration elapsedInChunk) {
    if (_currentIndex == null) return;
    _elapsed = elapsedInChunk;
  }

  /// Marks the current chunk as having played all the way out.
  void completeChunk() {
    final current = _currentIndex;
    if (current == null) return;
    _lastCompleted = current;
    _currentIndex = null;
    _currentDuration = Duration.zero;
    _elapsed = Duration.zero;
  }

  /// Cuts playback: settles what was heard and clears the in-flight chunk.
  ///
  /// Returns the index to report to the server, which is [heardThrough]
  /// evaluated before the state is cleared.
  int? truncate() {
    final heard = heardThrough;
    _lastCompleted = heard;
    _currentIndex = null;
    _currentDuration = Duration.zero;
    _elapsed = Duration.zero;
    return heard;
  }

  /// Clears everything for the next reply.
  void reset() {
    totalAnnounced = null;
    _lastCompleted = null;
    _currentIndex = null;
    _currentDuration = Duration.zero;
    _elapsed = Duration.zero;
  }
}

// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Tracks how much of a spoken reply the user actually heard.
///
/// When the user talks over the reply, playback is cut and whatever is still
/// queued is dropped -- so the room history would otherwise record the
/// assistant as having said sentences that never left the speaker. Reporting
/// how much was heard is what lets the stored message be truncated to match.
///
/// **This reports a count, not an index**, and that is the whole design.
///
/// An index has to carry two separate conventions to be read correctly: which
/// end it counts from, and whether it includes itself. Each is silently wrong
/// on its own, and the two halves of this system disagree by default -- the
/// synthesis side is written in a one-based language whose emit loop hands out
/// 1 for the first chunk, while this side and the wire format conventionally
/// start at 0. Neither is doing anything unreasonable; each is using its own
/// default in the absence of a statement.
///
/// A count has neither convention. `pieces.take(n)` here and the equivalent
/// one-based slice there are both correct from the same integer, so there is
/// no conversion site to get wrong. Documenting a conversion is weaker than
/// not having one.
///
/// It also removes the need for a separate "nothing was heard" signal: zero is
/// that, unambiguously, with no absent-versus-zero branch for a receiver to
/// forget.
///
/// Turning a count into *which sentences were said* still relies on synthesis
/// chunks mapping one-to-one onto text pieces, and that is an assumption held
/// where the split is made, not a fact observable from here. If chunks are ever
/// merged for prosody, or one carries only punctuation or silence, the mapping
/// shifts with nothing raised. That invariant has to be asserted at synthesis
/// time, where it is cheap and can fail loudly.
///
/// Distinct from wherever generation was cancelled. Text that was generated is
/// a superset of text that was spoken, so the two truncation points do not
/// coincide -- this one cuts further back. Treating them as the same attributes
/// unspoken text to the assistant.
///
/// Holds no timers and reads no clock: the caller feeds elapsed time from the
/// audio player. That keeps the rounding rule -- the part that is easy to get
/// wrong and impossible to see once it is wrong -- testable on its own.
class ChunkPlayback {
  /// Total chunks the server said it would send. Only used to report how many
  /// were dropped.
  int? totalAnnounced;

  int _completed = 0;
  int? _currentIndex;
  Duration _currentDuration = Duration.zero;
  Duration _elapsed = Duration.zero;
  bool _inProgress = false;

  /// Index of the chunk currently playing, as the sender labelled it.
  ///
  /// **Diagnostic only.** Never do arithmetic with this: it arrives from the
  /// other side of a language boundary and carries that side's base, which is
  /// exactly the conversion [chunksHeard] exists to avoid. Useful for a log
  /// line saying which chunk a cut landed in.
  int? get currentIndex => _currentIndex;

  /// How many chunks the user is counted as having heard. Zero means none.
  ///
  /// A chunk still playing counts when it is **past halfway** -- heard more
  /// than half of it, count it as said. A chunk cut before its midpoint does
  /// not count. A zero-length chunk counts, since there was nothing to miss.
  int get chunksHeard {
    if (!_inProgress) return _completed;
    return _elapsed * 2 >= _currentDuration ? _completed + 1 : _completed;
  }

  /// How many chunks never reached the speaker, or null when the server did not
  /// say how many it was sending.
  ///
  /// Derived from [chunksHeard] rather than counted separately: two numbers
  /// that can disagree is how a truncation report ends up plausible and wrong.
  int? get droppedCount {
    final total = totalAnnounced;
    if (total == null) return null;
    final dropped = total - chunksHeard;
    return dropped < 0 ? 0 : dropped;
  }

  /// Begins a chunk. [duration] is its full playable length; [index] is kept
  /// for diagnostics only, see [currentIndex].
  void startChunk(int index, Duration duration) {
    _currentIndex = index;
    _currentDuration = duration;
    _elapsed = Duration.zero;
    _inProgress = true;
  }

  /// Reports progress through the current chunk, measured from its start.
  void progress(Duration elapsedInChunk) {
    if (!_inProgress) return;
    _elapsed = elapsedInChunk;
  }

  /// Marks the current chunk as having played all the way out.
  void completeChunk() {
    if (!_inProgress) return;
    _completed++;
    _clearCurrent();
  }

  /// Cuts playback: settles what was heard and clears the in-flight chunk.
  ///
  /// Returns the number to report to the server, which is [chunksHeard]
  /// evaluated before the state is cleared.
  int truncate() {
    final heard = chunksHeard;
    _completed = heard;
    _clearCurrent();
    return heard;
  }

  /// Clears everything for the next reply.
  void reset() {
    totalAnnounced = null;
    _completed = 0;
    _clearCurrent();
  }

  void _clearCurrent() {
    _currentIndex = null;
    _currentDuration = Duration.zero;
    _elapsed = Duration.zero;
    _inProgress = false;
  }
}

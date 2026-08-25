// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/utils/voice/chunk_playback.dart';
import 'package:flutter_test/flutter_test.dart';

/// When the user talks over the assistant, playback is cut and the queued
/// chunks are dropped. Whatever this reports is what the room history will
/// claim was said -- so getting it wrong does not look like a bug, it looks
/// like the assistant having said something it never said. That is the failure
/// this file exists to prevent, and it is invisible from the client afterwards.
///
/// The report is a count rather than an index on purpose: an index carries a
/// base and an inclusivity convention, and the two sides of this system default
/// to different bases. A count carries neither.
void main() {
  /// An arbitrary chunk label. Deliberately not 0 or 1: the value is
  /// diagnostic only and must never reach the arithmetic, so the tests pick
  /// something that would produce obviously wrong counts if it ever did.
  const someIndex = 7;
  const oneSecond = Duration(seconds: 1);

  /// Plays [n] chunks all the way through.
  void playFully(ChunkPlayback p, int n) {
    for (var i = 0; i < n; i++) {
      p.startChunk(someIndex + i, oneSecond);
      p.completeChunk();
    }
  }

  group('chunksHeard', () {
    test('nothing heard before anything plays', () {
      expect(ChunkPlayback().chunksHeard, 0);
    });

    test('a chunk cut before its midpoint does not count', () {
      final p = ChunkPlayback();
      p.startChunk(someIndex, oneSecond);
      p.progress(const Duration(milliseconds: 499));
      expect(p.chunksHeard, 0);
    });

    test('a chunk played past halfway counts as said', () {
      final p = ChunkPlayback();
      p.startChunk(someIndex, oneSecond);
      p.progress(const Duration(milliseconds: 501));
      expect(p.chunksHeard, 1);
    });

    test('exactly halfway rounds up', () {
      // Round to nearest, and the midpoint goes to the chunk. Stated here
      // because it is the one input where round-up and round-down disagree,
      // and either is defensible until someone writes it down.
      final p = ChunkPlayback();
      p.startChunk(someIndex, oneSecond);
      p.progress(const Duration(milliseconds: 500));
      expect(p.chunksHeard, 1);
    });

    test('a barely-started chunk does not inflate the count', () {
      final p = ChunkPlayback();
      playFully(p, 3);
      p.startChunk(someIndex + 3, oneSecond);
      p.progress(const Duration(milliseconds: 400));
      expect(p.chunksHeard, 3, reason: 'counted a chunk barely started');
    });

    test('a completed chunk counts in full', () {
      final p = ChunkPlayback();
      playFully(p, 1);
      expect(p.chunksHeard, 1);
    });

    test('a zero-length chunk counts as heard', () {
      final p = ChunkPlayback();
      p.startChunk(someIndex, Duration.zero);
      expect(p.chunksHeard, 1);
    });

    test('progress on nothing is ignored rather than throwing', () {
      final p = ChunkPlayback();
      p.progress(const Duration(milliseconds: 100));
      expect(p.chunksHeard, 0);
    });
  });

  group('the sender label never reaches the arithmetic', () {
    // The count is produced from this side's own playback. The index the
    // sender attached carries the sender's base -- one-based, as it happens --
    // and letting it into the count is precisely the off-by-one this design
    // exists to make impossible.

    test('wildly different labels give the same count', () {
      final zeroBased = ChunkPlayback();
      final oneBased = ChunkPlayback();
      final absurd = ChunkPlayback();

      for (var i = 0; i < 4; i++) {
        zeroBased.startChunk(i, oneSecond);
        zeroBased.completeChunk();
        oneBased.startChunk(i + 1, oneSecond);
        oneBased.completeChunk();
        absurd.startChunk(1000 - i, oneSecond);
        absurd.completeChunk();
      }

      expect(zeroBased.chunksHeard, 4);
      expect(oneBased.chunksHeard, 4);
      expect(absurd.chunksHeard, 4);
    });

    test('the label is still available for diagnostics', () {
      final p = ChunkPlayback();
      p.startChunk(42, oneSecond);
      expect(p.currentIndex, 42);
    });

    test('there is no current label once a chunk finishes', () {
      final p = ChunkPlayback();
      playFully(p, 1);
      expect(p.currentIndex, isNull);
    });
  });

  group('truncate', () {
    test('reports what was heard and clears the in-flight chunk', () {
      final p = ChunkPlayback();
      playFully(p, 3);
      p.startChunk(someIndex + 3, oneSecond);
      p.progress(const Duration(milliseconds: 900));

      expect(p.truncate(), 4);
      expect(p.currentIndex, isNull);
      expect(p.chunksHeard, 4, reason: 'the settled count drifted after cut');
    });

    test('truncating before the midpoint does not credit the cut chunk', () {
      final p = ChunkPlayback();
      playFully(p, 1);
      p.startChunk(someIndex + 1, oneSecond);
      p.progress(const Duration(milliseconds: 100));

      expect(p.truncate(), 1);
      expect(p.chunksHeard, 1);
    });

    test('truncating before anything played reports nothing heard', () {
      expect(ChunkPlayback().truncate(), 0);
    });
  });

  group('droppedCount', () {
    test('nine sent, four heard, five dropped', () {
      final p = ChunkPlayback()..totalAnnounced = 9;
      playFully(p, 4);
      expect(p.chunksHeard, 4);
      expect(p.droppedCount, 5);
    });

    test('nine sent, only the first heard, eight dropped', () {
      // The case that separates a count from an inclusive index, and the two
      // index bases from each other. A middle value passes under every
      // reading, so testing "four of nine" alone would prove nothing about
      // the convention -- only the first and last chunks distinguish them.
      final p = ChunkPlayback()..totalAnnounced = 9;
      playFully(p, 1);
      expect(p.chunksHeard, 1);
      expect(p.droppedCount, 8);
    });

    test('null until the server says how many it is sending', () {
      final p = ChunkPlayback();
      playFully(p, 1);
      expect(p.droppedCount, isNull);
    });

    test('nothing heard means everything dropped', () {
      final p = ChunkPlayback()..totalAnnounced = 9;
      expect(p.droppedCount, 9);
    });

    test('a full playout drops nothing', () {
      final p = ChunkPlayback()..totalAnnounced = 3;
      playFully(p, 3);
      expect(p.droppedCount, 0);
    });

    test('never reports a negative drop', () {
      // If the server under-announces, or an extra chunk arrives, the count
      // must not go below zero -- a negative would be read downstream as a
      // number of chunks rather than as an error.
      final p = ChunkPlayback()..totalAnnounced = 1;
      playFully(p, 3);
      expect(p.droppedCount, 0);
    });
  });

  test('reset clears the reply', () {
    final p = ChunkPlayback()..totalAnnounced = 4;
    playFully(p, 1);
    p.reset();

    expect(p.chunksHeard, 0);
    expect(p.droppedCount, isNull);
    expect(p.currentIndex, isNull);
  });
}

// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/utils/voice/chunk_playback.dart';
import 'package:flutter_test/flutter_test.dart';

/// When the user talks over the bot, playback is cut and the queued chunks are
/// dropped. Whatever index this reports is what the room history will claim was
/// said -- so getting it wrong does not look like a bug, it looks like the bot
/// having said something it never said. That is the failure this file exists to
/// prevent, and it is invisible from the client afterwards.
void main() {
  group('heardThrough', () {
    test('nothing heard before anything plays', () {
      expect(ChunkPlayback().heardThrough, isNull);
    });

    test('a chunk cut before its midpoint does not count', () {
      final p = ChunkPlayback();
      p.startChunk(0, const Duration(milliseconds: 1000));
      p.progress(const Duration(milliseconds: 499));
      expect(p.heardThrough, isNull);
    });

    test('a chunk played past halfway counts as said', () {
      final p = ChunkPlayback();
      p.startChunk(0, const Duration(milliseconds: 1000));
      p.progress(const Duration(milliseconds: 501));
      expect(p.heardThrough, 0);
    });

    test('exactly halfway rounds up', () {
      // Round to nearest, and the midpoint goes to the chunk. Stated here
      // because it is the one input where round-up and round-down disagree,
      // and either is defensible until someone writes it down.
      final p = ChunkPlayback();
      p.startChunk(0, const Duration(milliseconds: 1000));
      p.progress(const Duration(milliseconds: 500));
      expect(p.heardThrough, 0);
    });

    test('falls back to the last completed chunk mid-way through the next', () {
      final p = ChunkPlayback();
      for (var i = 0; i < 3; i++) {
        p.startChunk(i, const Duration(milliseconds: 1000));
        p.completeChunk();
      }
      p.startChunk(3, const Duration(milliseconds: 1000));
      p.progress(const Duration(milliseconds: 400));
      expect(p.heardThrough, 2, reason: 'reported a chunk barely started');
    });

    test('a completed chunk counts in full', () {
      final p = ChunkPlayback();
      p.startChunk(0, const Duration(milliseconds: 1000));
      p.completeChunk();
      expect(p.heardThrough, 0);
    });

    test('a zero-length chunk counts as heard', () {
      final p = ChunkPlayback();
      p.startChunk(0, Duration.zero);
      expect(p.heardThrough, 0);
    });

    test('progress on nothing is ignored rather than throwing', () {
      final p = ChunkPlayback();
      p.progress(const Duration(milliseconds: 100));
      expect(p.heardThrough, isNull);
    });
  });

  group('truncate', () {
    test('reports what was heard and clears the in-flight chunk', () {
      final p = ChunkPlayback();
      for (var i = 0; i < 3; i++) {
        p.startChunk(i, const Duration(milliseconds: 1000));
        p.completeChunk();
      }
      p.startChunk(3, const Duration(milliseconds: 1000));
      p.progress(const Duration(milliseconds: 900));

      expect(p.truncate(), 3);
      expect(p.currentIndex, isNull);
      expect(p.heardThrough, 3, reason: 'the settled report drifted after cut');
    });

    test('truncating before the midpoint does not credit the cut chunk', () {
      final p = ChunkPlayback();
      p.startChunk(0, const Duration(milliseconds: 1000));
      p.completeChunk();
      p.startChunk(1, const Duration(milliseconds: 1000));
      p.progress(const Duration(milliseconds: 100));

      expect(p.truncate(), 0);
      expect(p.heardThrough, 0);
    });

    test('truncating before anything played reports nothing heard', () {
      final p = ChunkPlayback();
      expect(p.truncate(), isNull);
    });
  });

  group('droppedCount', () {
    test('nine sent, four heard, five dropped', () {
      final p = ChunkPlayback()..totalAnnounced = 9;
      for (var i = 0; i < 4; i++) {
        p.startChunk(i, const Duration(milliseconds: 1000));
        p.completeChunk();
      }
      expect(p.heardThrough, 3);
      expect(p.droppedCount, 5);
    });

    test('null until the server says how many it is sending', () {
      final p = ChunkPlayback();
      p.startChunk(0, const Duration(milliseconds: 1000));
      p.completeChunk();
      expect(p.droppedCount, isNull);
    });

    test('nothing heard means everything dropped', () {
      final p = ChunkPlayback()..totalAnnounced = 9;
      expect(p.droppedCount, 9);
    });

    test('a full playout drops nothing', () {
      final p = ChunkPlayback()..totalAnnounced = 3;
      for (var i = 0; i < 3; i++) {
        p.startChunk(i, const Duration(milliseconds: 1000));
        p.completeChunk();
      }
      expect(p.droppedCount, 0);
    });

    test('never reports a negative drop', () {
      // If the server under-announces, or an extra chunk arrives, the count
      // must not go below zero -- a negative would be read downstream as a
      // number of chunks rather than as an error.
      final p = ChunkPlayback()..totalAnnounced = 1;
      for (var i = 0; i < 3; i++) {
        p.startChunk(i, const Duration(milliseconds: 1000));
        p.completeChunk();
      }
      expect(p.droppedCount, 0);
    });
  });

  test('reset clears the reply', () {
    final p = ChunkPlayback()..totalAnnounced = 4;
    p.startChunk(0, const Duration(milliseconds: 1000));
    p.completeChunk();
    p.reset();

    expect(p.heardThrough, isNull);
    expect(p.droppedCount, isNull);
    expect(p.currentIndex, isNull);
  });
}

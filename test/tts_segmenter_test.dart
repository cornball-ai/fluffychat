// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/utils/voice/tts_segmenter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Feeds [deltas] and returns (segments emitted, flushed remainder).
(List<String>, String?) run(TtsSegmenter segmenter, List<String> deltas) {
  final segments = <String>[];
  for (final delta in deltas) {
    segments.addAll(segmenter.feed(delta));
  }
  return (segments, segmenter.flush());
}

/// The invariant every case must satisfy: segments plus remainder reproduce
/// the input exactly. Offset accounting is built on this; a segmenter that
/// eats one space shifts every stored truncation after it.
void expectLossless(List<String> deltas, List<String> segments, String? rest) {
  expect(segments.join() + (rest ?? ''), deltas.join());
}

void main() {
  test('splits at sentence ends, keeping the trailing space', () {
    final deltas = ['Hello there. General ', 'Kenobi. You are a bold one.'];
    final (segments, rest) = run(TtsSegmenter(), deltas);
    expectLossless(deltas, segments, rest);
    expect(segments, ['Hello there. General Kenobi. ']);
    expect(rest, 'You are a bold one.');
  });

  test(
    'a boundary is not released while text still ends in its whitespace',
    () {
      final segmenter = TtsSegmenter(minSegmentLength: 1);
      // The delta ends exactly at "word. " -- the gap may still be growing,
      // so nothing is released until the next delta shows what follows it.
      expect(segmenter.feed('A sentence. '), isEmpty);
      expect(segmenter.feed('More.'), ['A sentence. ']);
      expect(segmenter.flush(), 'More.');
    },
  );

  test('minSegmentLength holds back abbreviation-shaped boundaries', () {
    final deltas = ['e.g. this should not split early at all. Done.'];
    final (segments, rest) = run(TtsSegmenter(minSegmentLength: 24), deltas);
    expectLossless(deltas, segments, rest);
    expect(segments, ['e.g. this should not split early at all. ']);
    expect(rest, 'Done.');
  });

  test('decimal points and mid-word periods never split', () {
    final deltas = ['Pi is 3.14159 and pi.day is real. Yes.'];
    final (segments, rest) = run(TtsSegmenter(minSegmentLength: 1), deltas);
    expectLossless(deltas, segments, rest);
    expect(segments, ['Pi is 3.14159 and pi.day is real. ']);
  });

  test('newlines are boundaries on their own', () {
    final deltas = ['First line of a poem\nsecond line arrives'];
    final (segments, rest) = run(TtsSegmenter(minSegmentLength: 1), deltas);
    expectLossless(deltas, segments, rest);
    expect(segments, ['First line of a poem\n']);
    expect(rest, 'second line arrives');
  });

  test('a turn with no boundary at all comes out of flush in one piece', () {
    final deltas = ['no punctuation here just trailing off'];
    final (segments, rest) = run(TtsSegmenter(), deltas);
    expect(segments, isEmpty);
    expect(rest, deltas.join());
  });

  test('token-sized deltas that split a sentence mid-word stay lossless', () {
    final deltas = ['Th', 'e an', 'swer is forty-two', '. ', 'Naturally.'];
    final (segments, rest) = run(TtsSegmenter(minSegmentLength: 1), deltas);
    expectLossless(deltas, segments, rest);
    expect(segments, ['The answer is forty-two. ']);
    expect(rest, 'Naturally.');
  });

  test('multiple boundaries inside one delta all release', () {
    final deltas = ['One is done. Two is done. Three'];
    final (segments, rest) = run(TtsSegmenter(minSegmentLength: 1), deltas);
    expectLossless(deltas, segments, rest);
    expect(segments, ['One is done. ', 'Two is done. ']);
    expect(rest, 'Three');
  });

  test('empty deltas are inert', () {
    final segmenter = TtsSegmenter();
    expect(segmenter.feed(''), isEmpty);
    expect(segmenter.flush(), isNull);
  });
}

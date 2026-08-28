// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/utils/voice/voice_turn.dart';
import 'package:flutter_test/flutter_test.dart';

/// The split the voice screen draws: what has been said, and what is still
/// queued behind it. Getting the boundary wrong shows the reader words the
/// speaker has not reached, which is the one thing this rendering is for.
void main() {
  test('a reply not yet spoken is all pending', () {
    const turn = VoiceTurn.agent('Hello there. General Kenobi.');
    expect(turn.spoken, '');
    expect(turn.pending, 'Hello there. General Kenobi.');
  });

  test('the spoken prefix and the pending tail reconstruct the text', () {
    const text = 'Hello there. General Kenobi.';
    for (final length in [0, 1, 13, text.length]) {
      final turn = const VoiceTurn.agent(text).withSpoken(length);
      expect(turn.spoken + turn.pending, text);
      expect(turn.spoken.length, length);
    }
  });

  test('text can grow past a spoken boundary already reported', () {
    // Generation runs ahead of the speaker, so this is the normal case:
    // deltas arrive for text the voice has not reached.
    final turn = const VoiceTurn.agent(
      'Hello there. ',
    ).withSpoken(13).withText('Hello there. General Kenobi.');

    expect(turn.spoken, 'Hello there. ');
    expect(turn.pending, 'General Kenobi.');
  });

  test('a spoken length past the end of the text cannot overrun it', () {
    // The two arrive on different callbacks, so an ordering where the
    // boundary lands before the delta that justifies it must not throw on a
    // list row mid-conversation.
    final turn = const VoiceTurn.agent('Hi').withSpoken(99);
    expect(turn.spoken, 'Hi');
    expect(turn.pending, '');
  });

  test('a finished turn is spoken in full, whatever the last boundary was', () {
    // Chunk boundaries land where the synthesiser put them, not at the end
    // of the reply; a completed turn has been heard to the end regardless.
    final turn = const VoiceTurn.agent(
      'Hello there.',
    ).withSpoken(5).finished('Hello there.');

    expect(turn.done, isTrue);
    expect(turn.spoken, 'Hello there.');
    expect(turn.pending, '');
  });

  test('an interrupted turn finishes at what the agent kept', () {
    // The stored text IS the truncation: everything in it was said, and
    // what was not said is not in it.
    final turn = const VoiceTurn.agent(
      'Hello there. General Kenobi.',
    ).withSpoken(13).finished('Hello there.');

    expect(turn.spoken, 'Hello there.');
    expect(turn.pending, '');
  });

  test('a user turn has nothing pending', () {
    const turn = VoiceTurn.user('hi there');
    expect(turn.spoken, 'hi there');
    expect(turn.pending, '');
    expect(turn.done, isFalse);
  });
}

// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

/// One side's contribution to a live conversation, as it is happening.
///
/// Immutable, and updated by replacement, because the surface that renders it
/// is driven by a ValueNotifier: a mutated turn is the same object, and the
/// list would not rebuild.
class VoiceTurn {
  final bool fromUser;

  /// Everything said or generated so far. Grows while the turn is live.
  final String text;

  /// How much of [text] has left the speaker, as a length into it.
  ///
  /// Generation and synthesis both run ahead of playback, so a reply exists
  /// as text well before it exists as sound. Rendering the difference is what
  /// makes a spoken reply readable at the pace it is being said, and it is
  /// the same boundary an interruption reports as heard.
  ///
  /// Always zero for the user: their words are heard as they are transcribed,
  /// so there is nothing pending to distinguish.
  final int spokenLength;

  /// The turn is over and will not grow again.
  final bool done;

  const VoiceTurn({
    required this.fromUser,
    required this.text,
    this.spokenLength = 0,
    this.done = false,
  });

  const VoiceTurn.user(this.text)
    : fromUser = true,
      spokenLength = 0,
      done = false;

  const VoiceTurn.agent(this.text, {this.spokenLength = 0})
    : fromUser = false,
      done = false;

  /// The part that has been said aloud.
  String get spoken => text.substring(0, _boundary);

  /// The part that has been written but not yet reached.
  String get pending => text.substring(_boundary);

  /// A finished turn has been said in full, whatever the last chunk boundary
  /// happened to be -- and an interrupted one is finished at the text the
  /// agent kept, which is the part that was heard. The user's words are
  /// spoken by definition: they exist because they were said.
  int get _boundary =>
      done || fromUser ? text.length : spokenLength.clamp(0, text.length);

  VoiceTurn withText(String text) => VoiceTurn(
    fromUser: fromUser,
    text: text,
    spokenLength: spokenLength,
    done: done,
  );

  VoiceTurn withSpoken(int spokenLength) => VoiceTurn(
    fromUser: fromUser,
    text: text,
    spokenLength: spokenLength,
    done: done,
  );

  VoiceTurn finished(String text) => VoiceTurn(
    fromUser: fromUser,
    text: text,
    spokenLength: spokenLength,
    done: true,
  );
}

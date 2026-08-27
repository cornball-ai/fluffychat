// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Textual self-echo detection: recognising our own synthesised speech in
/// the transcription stream.
///
/// Without acoustic echo cancellation, the microphone hears the speaker,
/// and whisper faithfully transcribes the bot's own reply -- which then
/// posts to the room as the user's words and starts a reply to the reply.
/// The one advantage this client has over the acoustics is that it KNOWS
/// what it just said: a turn that is substantially made of the words the
/// bot recently spoke is the bot, not the user.
///
/// Matching is by word multiset, not exact substring, because ASR mangles
/// echo ("mockdown formatting" for "markdown formatting" survived one real
/// run) and playback may be cut mid-word. The bar is deliberately about
/// composition: MOST of the turn's words appearing in the recent reply.
/// A user genuinely quoting one phrase back keeps their turn, because
/// their framing words around the quote are theirs.
class SelfEchoFilter {
  /// Fraction of a turn's words that must appear in recently spoken reply
  /// text for the turn to count as echo.
  final double matchFraction;

  /// Turns shorter than this many words are never filtered: "yes" or
  /// "exactly" will usually appear somewhere in a long reply, and a short
  /// genuine answer wrongly discarded is worse than a short echo fragment
  /// slipping through.
  final int minWords;

  /// How long after a reply ends its text still counts as an echo source.
  /// Room reverb and capture latency deliver the tail of a reply after the
  /// session considers it over.
  final Duration tailWindow;

  final DateTime Function() _clock;

  SelfEchoFilter({
    this.matchFraction = 0.7,
    this.minWords = 3,
    this.tailWindow = const Duration(seconds: 10),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  String _currentReply = '';
  String _previousReply = '';
  DateTime? _previousEndedAt;

  /// Replace the in-progress reply text. Called with the accumulated text
  /// on every delta, so passing the full text so far is correct.
  void replyText(String text) {
    _currentReply = text;
  }

  /// The in-progress reply finished or was cut; its text stays an echo
  /// source for [tailWindow].
  void replyEnded() {
    if (_currentReply.isEmpty) return;
    _previousReply = _currentReply;
    _previousEndedAt = _clock();
    _currentReply = '';
  }

  /// Whether [turnText] is substantially our own recent speech.
  bool isSelfEcho(String turnText) {
    final turnWords = _words(turnText);
    if (turnWords.length < minWords) return false;
    final reference = <String, int>{};
    for (final word in _words(_currentReply)) {
      reference[word] = (reference[word] ?? 0) + 1;
    }
    final endedAt = _previousEndedAt;
    if (endedAt != null && _clock().difference(endedAt) <= tailWindow) {
      for (final word in _words(_previousReply)) {
        reference[word] = (reference[word] ?? 0) + 1;
      }
    }
    if (reference.isEmpty) return false;
    var matched = 0;
    for (final word in turnWords) {
      final remaining = reference[word];
      if (remaining != null && remaining > 0) {
        reference[word] = remaining - 1;
        matched++;
      }
    }
    return matched / turnWords.length >= matchFraction;
  }

  static final _nonWord = RegExp(r'[^a-z0-9\s]');
  static final _whitespace = RegExp(r'\s+');

  static List<String> _words(String text) => text
      .toLowerCase()
      .replaceAll(_nonWord, ' ')
      .split(_whitespace)
      .where((w) => w.isNotEmpty)
      .toList();
}

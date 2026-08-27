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

  /// The same bar while a reply is actually being spoken, where the prior
  /// is different: the microphone is definitely hearing the speaker, so a
  /// turn that half-matches what we are saying is far more likely to be
  /// mangled echo than a person who happens to be quoting us. A user
  /// genuinely interrupting says something of their own, which matches
  /// almost nothing.
  final double matchFractionWhileSpeaking;

  /// How many of our words repeated back to back, in our order, count as
  /// a verbatim run -- the second fingerprint of echo, for transcripts
  /// too mangled to clear the ratio on their own.
  final int verbatimRunWords;

  /// Turns shorter than this many words are never filtered: "yes" or
  /// "exactly" will usually appear somewhere in a long reply, and a short
  /// genuine answer wrongly discarded is worse than a short echo fragment
  /// slipping through.
  final int minWords;

  /// How long after a reply ends its text still counts as an echo source.
  ///
  /// Generous because playback runs well behind generation on a small
  /// card: the session considers a reply finished when the last chunk is
  /// handed over, while the speaker is still working through it and the
  /// microphone is still hearing it.
  final Duration tailWindow;

  final DateTime Function() _clock;

  SelfEchoFilter({
    this.matchFraction = 0.7,
    this.matchFractionWhileSpeaking = 0.65,
    this.verbatimRunWords = 4,
    this.minWords = 3,
    this.tailWindow = const Duration(seconds: 30),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  String _currentReply = '';
  String _previousReply = '';
  DateTime? _previousEndedAt;

  /// Replace the text that has actually been AUDIBLE so far.
  ///
  /// Audible, not generated: a reply arrives from the model far ahead of
  /// the speaker, and text the microphone has had no chance to hear
  /// cannot be echoing back. Matching against the whole generated reply
  /// makes a user's question about what comes next look like our own
  /// voice.
  void audibleText(String text) {
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
  ///
  /// [speaking] says a reply is being played right now, which lowers the
  /// bar to [matchFractionWhileSpeaking]: the microphone is certainly
  /// hearing the speaker, so partial matches are echo until proven
  /// otherwise.
  bool isSelfEcho(String turnText, {bool speaking = false}) {
    final turnWords = _words(turnText);
    if (turnWords.length < minWords) return false;
    final reference = <String>[
      ..._words(_previousReply.isEmpty ? '' : _tailIfFresh()),
      ..._words(_currentReply),
    ];
    if (reference.isEmpty) return false;
    final ratio = _orderedMatch(turnWords, reference) / turnWords.length;
    final bar = speaking ? matchFractionWhileSpeaking : matchFraction;
    if (ratio >= bar) return true;
    // A verbatim run is the other fingerprint of echo. Transcription of
    // our own speech reproduces whole phrases intact even when it mangles
    // words around them ("a rough one last night" survived "asterisk 5
    // bend forward"), while a person reusing our vocabulary rarely
    // repeats four of our words back to back in our order.
    return speaking &&
        ratio >= matchFractionWhileSpeaking &&
        _longestRun(turnWords, reference) >= verbatimRunWords;
  }

  /// Longest run of the turn's words appearing consecutively, in order,
  /// in what we said.
  int _longestRun(List<String> turn, List<String> reference) {
    var best = 0;
    var previous = List<int>.filled(reference.length + 1, 0);
    for (var i = 1; i <= turn.length; i++) {
      final current = List<int>.filled(reference.length + 1, 0);
      for (var j = 1; j <= reference.length; j++) {
        if (turn[i - 1] == reference[j - 1]) {
          current[j] = previous[j - 1] + 1;
          if (current[j] > best) best = current[j];
        }
      }
      previous = current;
    }
    return best;
  }

  /// Longest run of the turn's words that appears IN ORDER in what we
  /// said, as a count.
  ///
  /// Order is the difference between echo and a person. A transcript of
  /// our own speech preserves our word order almost perfectly; a person
  /// reusing our vocabulary ("can you tell me the weather today" against
  /// "I can tell you the weather in Chicago tomorrow") reorders it and
  /// adds their own. An unordered bag of words scores those two the same
  /// and discards the interruption.
  int _orderedMatch(List<String> turn, List<String> reference) {
    // Longest common subsequence length, the standard dynamic program.
    // Both sides are one spoken turn, so the table stays small.
    final previous = List<int>.filled(reference.length + 1, 0);
    final current = List<int>.filled(reference.length + 1, 0);
    for (var i = 1; i <= turn.length; i++) {
      for (var j = 1; j <= reference.length; j++) {
        current[j] = turn[i - 1] == reference[j - 1]
            ? previous[j - 1] + 1
            : (current[j - 1] > previous[j] ? current[j - 1] : previous[j]);
      }
      previous.setAll(0, current);
    }
    return previous[reference.length];
  }

  String _tailIfFresh() {
    final endedAt = _previousEndedAt;
    if (endedAt == null) return '';
    return _clock().difference(endedAt) <= tailWindow ? _previousReply : '';
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

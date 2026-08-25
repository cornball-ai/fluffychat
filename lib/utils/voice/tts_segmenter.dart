// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Turns a stream of generation deltas into synthesis-sized text segments.
///
/// The two wires it sits between disagree about granularity: Converse emits
/// deltas cut wherever the model's tokenizer happened to cut them, and
/// Synthesize takes one complete text per call. Synthesising per delta would
/// hand the synthesiser half a word; waiting for the whole turn would forfeit
/// the streaming the schema exists for. This is the policy in between: buffer
/// deltas, release a segment when a sentence has plausibly ended, flush the
/// remainder when generation does.
///
/// THE INVARIANT THAT MUST HOLD: concatenating every returned segment, in
/// order, reproduces the fed text byte for byte. No trimming, no inserted
/// joins. text_heard offsets are counted over the concatenated reply, and a
/// segmenter that swallows a space makes every offset after it point one
/// character early -- silently, in stored history. The tests assert this
/// invariant on every case; any future policy change has to keep it.
///
/// The boundary rule is deliberately dumb: a sentence-ending mark followed by
/// whitespace, with a minimum length so "e.g. " and "3." do not fire. Dumb is
/// load-bearing -- this runs on the latency path, and a smarter splitter that
/// needs the text to its right cannot decide until that text exists. Prosody
/// across a wrongly-split boundary is the synthesiser's problem to survive,
/// and a missed split only costs latency, not correctness.
class TtsSegmenter {
  /// Segments shorter than this keep accumulating even past a boundary.
  /// Guards against abbreviation-shaped false boundaries and against
  /// synthesising fragments too short to carry prosody.
  final int minSegmentLength;

  TtsSegmenter({this.minSegmentLength = 24});

  final StringBuffer _pending = StringBuffer();

  static const _enders = {'.', '!', '?', '\n'};

  /// Feeds one delta; returns the segments it released, usually zero or one.
  ///
  /// A boundary is a character in [_enders] whose successor is whitespace (or
  /// a newline itself), seen only once at least [minSegmentLength] characters
  /// of segment have accumulated. The whitespace after the mark stays with
  /// the segment it follows, so the invariant holds without the next segment
  /// starting mid-gap.
  List<String> feed(String delta) {
    if (delta.isEmpty) return const [];
    _pending.write(delta);

    final segments = <String>[];
    var text = _pending.toString();
    var searchFrom = 0;
    while (true) {
      final cut = _boundaryAfter(text, searchFrom);
      if (cut == null) break;
      segments.add(text.substring(0, cut));
      text = text.substring(cut);
      searchFrom = 0;
    }
    if (segments.isNotEmpty) {
      _pending.clear();
      _pending.write(text);
    }
    return segments;
  }

  /// Releases whatever is still buffered, if anything. Call on TurnEnd; a
  /// turn whose text never hit a boundary comes out here in one piece.
  String? flush() {
    if (_pending.isEmpty) return null;
    final rest = _pending.toString();
    _pending.clear();
    return rest;
  }

  /// End of the segment ending at or after [from], or null if none is
  /// complete yet. The returned index is AFTER the run of whitespace that
  /// follows the ending mark.
  int? _boundaryAfter(String text, int from) {
    for (var i = from; i < text.length; i++) {
      if (!_enders.contains(text[i])) continue;
      if (i + 1 < minSegmentLength) continue;
      // A newline is a boundary by itself; a sentence mark needs following
      // whitespace so "3.14" and "e.g.x" never split.
      final isNewline = text[i] == '\n';
      final hasSpaceAfter =
          i + 1 < text.length && _isWhitespace(text.codeUnitAt(i + 1));
      if (!isNewline && !hasSpaceAfter) continue;
      // Absorb the trailing whitespace run into this segment. If the text
      // ends inside that run, the boundary is not decidable yet -- the next
      // delta may continue the whitespace, and cutting early would split the
      // gap across two segments (harmless for the invariant, but it would
      // synthesise a segment whose pause has not finished arriving).
      var end = i + 1;
      while (end < text.length && _isWhitespace(text.codeUnitAt(end))) {
        end++;
      }
      if (end == text.length) return null;
      return end;
    }
    return null;
  }

  static bool _isWhitespace(int codeUnit) =>
      codeUnit == 0x20 ||
      codeUnit == 0x09 ||
      codeUnit == 0x0A ||
      codeUnit == 0x0D;
}

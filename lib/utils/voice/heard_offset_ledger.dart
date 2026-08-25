// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Converts per-segment synthesis offsets into the turn-global text offset
/// that ReportTurn carries.
///
/// The two offsets live in different frames on purpose. AudioChunk's
/// `input_text_end` is local to one Synthesize call, because the synthesiser
/// only ever sees one segment and inventing a global frame there would mean
/// telling it about calls it was never part of. `text_heard` is global over
/// the whole reply, because the agent stores whole replies. Someone has to
/// hold the segment bases that bridge the two, and the only party that knows
/// them is the one that did the segmenting -- this ledger is that record.
///
/// Offsets are Unicode CODE POINTS throughout, matching the wire contract.
/// Dart strings index by UTF-16 code unit, so `String.length` is the wrong
/// ruler here -- an emoji in a reply would shift every later offset by one
/// per emoji. `runes.length` is the right one, and the tests pin that with
/// text where the two rulers disagree.
class HeardOffsetLedger {
  final List<int> _bases = [];
  int _total = 0;

  /// Registers the next synthesis segment, in the order segments are sent,
  /// and returns its index. The concatenation invariant upstream (segments
  /// reproduce the reply exactly) is what entitles this to compute global
  /// offsets by summing lengths.
  int addSegment(String text) {
    _bases.add(_total);
    _total += text.runes.length;
    return _bases.length - 1;
  }

  /// Total code points registered so far. After the last segment of a turn,
  /// this is the completed-turn text_heard.
  int get totalCodePoints => _total;

  /// The turn-global offset for [inputTextEnd] within [segmentIndex].
  ///
  /// Throws [RangeError] on a segment never registered and [ArgumentError]
  /// on an offset past the segment's own length: both mean this side's
  /// bookkeeping and the wire disagree, and a truncation report built on the
  /// disagreement would be confidently wrong -- the one failure this whole
  /// path exists to prevent. Loud beats plausible.
  int globalOffset(int segmentIndex, int inputTextEnd) {
    if (segmentIndex < 0 || segmentIndex >= _bases.length) {
      throw RangeError.index(segmentIndex, _bases, 'segmentIndex');
    }
    final base = _bases[segmentIndex];
    final length =
        (segmentIndex + 1 < _bases.length ? _bases[segmentIndex + 1] : _total) -
        base;
    if (inputTextEnd < 0 || inputTextEnd > length) {
      throw ArgumentError.value(
        inputTextEnd,
        'inputTextEnd',
        'past the end of segment $segmentIndex (length $length)',
      );
    }
    return base + inputTextEnd;
  }
}

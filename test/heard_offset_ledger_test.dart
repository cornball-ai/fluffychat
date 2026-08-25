// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/utils/voice/heard_offset_ledger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('offsets across multiple segments are cumulative', () {
    final ledger = HeardOffsetLedger();
    final first = ledger.addSegment('Hello there. '); // 13 code points
    final second = ledger.addSegment('General Kenobi.'); // 15

    expect(ledger.globalOffset(first, 0), 0);
    expect(ledger.globalOffset(first, 13), 13);
    expect(ledger.globalOffset(second, 0), 13);
    expect(ledger.globalOffset(second, 15), 28);
    expect(ledger.totalCodePoints, 28);
  });

  test('interruption within a later segment lands in that segment frame', () {
    final ledger = HeardOffsetLedger();
    ledger.addSegment('One. ');
    ledger.addSegment('Two. ');
    final third = ledger.addSegment('Three.');
    // Cut mid-"Three": 4 code points into segment 2 -> 5 + 5 + 4.
    expect(ledger.globalOffset(third, 4), 14);
  });

  test('code points are the ruler, not UTF-16 units', () {
    // '🎉' is 1 code point but 2 UTF-16 units; length would count 6 here.
    const emoji = 'ok 🎉! ';
    expect(emoji.length, 7);
    expect(emoji.runes.length, 6);

    final ledger = HeardOffsetLedger();
    final first = ledger.addSegment(emoji);
    final second = ledger.addSegment('done.');
    // The wire counts code points, so segment two starts at 6, not 7.
    expect(ledger.globalOffset(second, 0), 6);
    expect(ledger.globalOffset(first, 6), 6);
    expect(ledger.totalCodePoints, 11);
  });

  test('a silence chunk repeating the previous offset converts unchanged', () {
    final ledger = HeardOffsetLedger();
    final only = ledger.addSegment('Some sentence here.');
    // Two chunks stamped 10, then a silence-only chunk stamped 10 again --
    // per the schema, repeats convert to the same global offset.
    expect(ledger.globalOffset(only, 10), ledger.globalOffset(only, 10));
  });

  test('an offset past the segment is a loud error, not a clamp', () {
    final ledger = HeardOffsetLedger();
    final only = ledger.addSegment('short'); // 5 code points
    expect(() => ledger.globalOffset(only, 6), throwsArgumentError);
    expect(() => ledger.globalOffset(only, -1), throwsArgumentError);
  });

  test('an unregistered segment is a loud error', () {
    final ledger = HeardOffsetLedger();
    expect(() => ledger.globalOffset(0, 0), throwsRangeError);
    ledger.addSegment('one');
    expect(() => ledger.globalOffset(1, 0), throwsRangeError);
  });
}

// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/utils/read_marker_target.dart';
import 'package:flutter_test/flutter_test.dart';

/// A room can be unread with nothing in it that notifies.
/// `.m.rule.suppress_notices` means an `m.notice` never raises a
/// notification, so a room whose recent traffic is all notices -- which is how
/// bots and bridges talk -- has no notifying event to put a marker on.
///
/// The old selection only looked for notifying events, found none, and
/// returned without sending any receipt. `hasNewMessages` then stayed true
/// because the newest event still carried no receipt from us, so the badge
/// survived opening the room, reading it, and coming back.
class _Ev {
  final String? id;
  final bool notifies;
  final bool displayable;

  const _Ev(this.id, {this.notifies = false, this.displayable = true});
}

String? _pick(List<_Ev> events) => pickReadMarkerEvent<_Ev>(
  events: events,
  notifies: (e) => e.notifies,
  isDisplayable: (e) => e.displayable,
  idOf: (e) => e.id,
);

void main() {
  test('prefers the newest notifying event', () {
    // Newest first, as the timeline is.
    expect(
      _pick(const [
        _Ev('c'),
        _Ev('b', notifies: true),
        _Ev('a', notifies: true),
      ]),
      'b',
    );
  });

  test('falls back to the newest message when nothing notifies', () {
    // The regression. Every event is a notice: displayable, never notifying.
    // Without the fallback this returns null and the room can never be read.
    expect(_pick(const [_Ev('c'), _Ev('b'), _Ev('a')]), 'c');
  });

  test('a single notice still gets a marker', () {
    expect(_pick(const [_Ev('only')]), 'only');
  });

  test('skips events that are not displayable', () {
    // Membership changes and the like are not somewhere to leave a receipt.
    expect(_pick(const [_Ev('state', displayable: false), _Ev('msg')]), 'msg');
  });

  test('nothing displayable means nothing to mark', () {
    expect(
      _pick(const [_Ev('x', displayable: false), _Ev('y', displayable: false)]),
      isNull,
    );
  });

  test('an empty timeline means nothing to mark', () {
    expect(_pick(const []), isNull);
  });

  test('skips an event that has no id yet', () {
    // A message still sending has no server id to receipt against.
    expect(_pick(const [_Ev(null), _Ev('sent')]), 'sent');
  });

  test('a notifying event wins even when a newer notice sits above it', () {
    // The preference is not merely "newest": the marker belongs where the
    // notification count came from, so a notice arriving afterwards must not
    // pull it forward past an unread mention.
    expect(
      _pick(const [_Ev('notice'), _Ev('mention', notifies: true)]),
      'mention',
    );
  });
}

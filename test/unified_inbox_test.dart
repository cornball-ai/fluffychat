// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/pages/chat_list/unified_rooms.dart';
import 'package:flutter_test/flutter_test.dart';

/// A room reduced to what the list ordering actually reads.
class _Room {
  final String id;
  final int ts;
  final bool favourite;
  final bool space;

  const _Room(this.id, this.ts, {this.favourite = false, this.space = false});
}

/// The SDK's comparator, in the two clauses this exercises: favourites first,
/// then newest first.
int _compare(_Room a, _Room b) {
  if (a.favourite != b.favourite) return a.favourite ? -1 : 1;
  return b.ts.compareTo(a.ts);
}

List<String> _ids(List<_Room> rooms) => rooms.map((r) => r.id).toList();

void main() {
  group('mergeAccountRooms', () {
    test('interleaves two accounts by time', () {
      // Each account arrives sorted; concatenation alone would put every
      // cornball room above every matrix.org one regardless of age.
      const cornball = [_Room('c1', 30), _Room('c2', 10)];
      const matrixOrg = [_Room('m1', 20), _Room('m2', 5)];

      expect(
        _ids(
          mergeAccountRooms(
            [cornball, matrixOrg],
            keep: (_) => true,
            compare: _compare,
          ),
        ),
        ['c1', 'm1', 'c2', 'm2'],
      );
    });

    test('a favourite on either account still sorts first', () {
      const cornball = [_Room('c1', 30)];
      const matrixOrg = [_Room('m1', 1, favourite: true)];

      expect(
        _ids(
          mergeAccountRooms(
            [cornball, matrixOrg],
            keep: (_) => true,
            compare: _compare,
          ),
        ),
        ['m1', 'c1'],
      );
    });

    test('the active filter applies to every account', () {
      const cornball = [_Room('c1', 30), _Room('cs', 25, space: true)];
      const matrixOrg = [_Room('ms', 20, space: true), _Room('m1', 15)];

      expect(
        _ids(
          mergeAccountRooms(
            [cornball, matrixOrg],
            keep: (room) => !room.space,
            compare: _compare,
          ),
        ),
        ['c1', 'm1'],
      );
    });

    test('one account is filtered but never re-sorted', () {
      // The guarantee behind the default-off setting: with a single account
      // the list is whatever order the SDK put it in, even an order this
      // comparator disagrees with. A sort here would silently change the
      // existing list for every user.
      const unsorted = [_Room('a', 1), _Room('b', 99), _Room('c', 50)];

      expect(
        _ids(
          mergeAccountRooms([unsorted], keep: (_) => true, compare: _compare),
        ),
        ['a', 'b', 'c'],
      );
    });

    test('no accounts is an empty list, not a crash', () {
      expect(
        mergeAccountRooms<_Room>([], keep: (_) => true, compare: _compare),
        isEmpty,
      );
    });
  });

  group('RoomRef', () {
    // Two accounts joined to the same room is representable in Matrix and
    // shows as two rows. Anything keyed on the room id alone merges them:
    // duplicate widget keys, one account's space claiming the other's copy,
    // and both rows highlighting when only one of them is open.
    const cornball = 'FluffyChat-cornball';
    const matrixOrg = 'FluffyChat-matrixorg';
    const shared = '!shared:example.com';

    test('the same room on two accounts is two different rows', () {
      const mine = (cornball, shared);
      const theirs = (matrixOrg, shared);
      expect(mine, isNot(theirs));
    });

    test('a space lookup cannot cross accounts', () {
      final spaces = <RoomRef, String>{(cornball, shared): 'cornball space'};

      expect(spaces[(cornball, shared)], 'cornball space');
      expect(spaces[(matrixOrg, shared)], isNull);
    });

    test('the same row on the same account is still one row', () {
      // Equality has to hold as well as fail, or the list rebuilds every
      // element on every frame instead of reusing them.
      const once = (cornball, shared);
      const again = (cornball, shared);
      expect(once, again);
      expect(once.hashCode, again.hashCode);
    });
  });

  group('accountBadgeLabel', () {
    test('two accounts on one homeserver do not collide', () {
      // The domain alone gives both of them "m". Avatar takes the first
      // letter of the first word and of the last, so the localpart has to be
      // in there.
      expect(accountBadgeLabel('@troy:matrix.org'), 'troy matrix.org');
      expect(accountBadgeLabel('@dirk:matrix.org'), 'dirk matrix.org');
    });

    test('one person on two homeservers does not collide', () {
      expect(accountBadgeLabel('@troy:cornball.ai'), 'troy cornball.ai');
      expect(
        accountBadgeLabel('@troyhernandez:matrix.org'),
        'troyhernandez matrix.org',
      );
    });

    test('a missing or malformed id draws nothing rather than throwing', () {
      // Avatar reads the first character of the first word, so an empty
      // localpart or domain is a RangeError waiting on a list row.
      expect(accountBadgeLabel(null), '');
      expect(accountBadgeLabel(''), '');
      expect(accountBadgeLabel('@troy:'), '');
      expect(accountBadgeLabel('@:matrix.org'), '');
    });

    test('an id with no colon is passed through, not split', () {
      expect(accountBadgeLabel('troy'), 'troy');
    });
  });

  group('roomRoute', () {
    test('leaves the route alone for the active account', () {
      expect(roomRoute('!abc:example.com'), '/rooms/!abc:example.com');
    });

    test('carries the account that owns the room', () {
      expect(
        roomRoute('!abc:example.com', clientName: 'FluffyChat'),
        '/rooms/!abc:example.com?client=FluffyChat',
      );
    });

    test('encodes a client name with spaces', () {
      // Client names are generated from the application name, which is a
      // setting and can hold anything.
      expect(
        roomRoute('!abc:example.com', clientName: 'Fluffy Chat & Co'),
        '/rooms/!abc:example.com?client=Fluffy+Chat+%26+Co',
      );
    });

    test('archive keeps its prefix', () {
      expect(
        roomRoute('!abc:example.com', prefix: '/rooms/archive'),
        '/rooms/archive/!abc:example.com',
      );
    });
  });
}

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

  group('accountBadgeLabels', () {
    // These are the strings that get drawn, character for character. The
    // property under test is that no two of them are equal -- checked here
    // per case, and rendered for real in account_badge_test.dart.
    void expectDistinct(Map<String, String> labels) {
      expect(
        labels.values.toSet().length,
        labels.length,
        reason: 'two accounts would draw the same badge: $labels',
      );
    }

    test('two people keep one letter each', () {
      final labels = accountBadgeLabels([
        '@troy:matrix.org',
        '@dirk:matrix.org',
      ]);
      expect(labels['@troy:matrix.org'], 't');
      expect(labels['@dirk:matrix.org'], 'd');
      expectDistinct(labels);
    });

    test('one person on two homeservers takes the server', () {
      final labels = accountBadgeLabels([
        '@troy:cornball.ai',
        '@troyhernandez:matrix.org',
      ]);
      expect(labels['@troy:cornball.ai'], 'tc');
      expect(labels['@troyhernandez:matrix.org'], 'tm');
      expectDistinct(labels);
    });

    test('the same localpart on two homeservers still separates', () {
      final labels = accountBadgeLabels([
        '@troy:cornball.ai',
        '@troy:matrix.org',
      ]);
      expectDistinct(labels);
    });

    test('two localparts sharing an initial take a second letter', () {
      // The case a fixed rule cannot serve: initial and server are both "t"
      // and "m", so the label has to grow into the localpart instead.
      final labels = accountBadgeLabels([
        '@troy:matrix.org',
        '@tom:matrix.org',
      ]);
      expect(labels['@troy:matrix.org'], 'tr');
      expect(labels['@tom:matrix.org'], 'to');
      expectDistinct(labels);
    });

    test('three accounts are all separated at once', () {
      final labels = accountBadgeLabels([
        '@troy:matrix.org',
        '@tom:matrix.org',
        '@dirk:matrix.org',
      ]);
      expectDistinct(labels);
    });

    test('accounts nothing short can separate fall back to numbers', () {
      // Two letters and the server agree throughout. A number nobody can
      // read as a name still beats two badges nobody can tell apart.
      final labels = accountBadgeLabels([
        '@troy:matrix.org',
        '@troyd:matrix.org',
      ]);
      expect(labels['@troy:matrix.org'], '1');
      expect(labels['@troyd:matrix.org'], '2');
      expectDistinct(labels);
    });

    test('a malformed id numbers rather than throwing', () {
      // An empty localpart or domain is a substring RangeError on a list row.
      final labels = accountBadgeLabels(['', '@troy:', '@:matrix.org', 'troy']);
      expect(labels.values, ['1', '2', '3', '4']);
    });

    test('one account and none at all are both fine', () {
      expect(accountBadgeLabels(['@troy:matrix.org']), {
        '@troy:matrix.org': 't',
      });
      expect(accountBadgeLabels([]), isEmpty);
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

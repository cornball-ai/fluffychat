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

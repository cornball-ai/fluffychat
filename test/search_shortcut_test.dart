// SPDX-FileCopyrightText: 2026-Present cornball.ai
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/widgets/app_keyboard_shortcuts.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ctrl+F picks its target from the current route, and the routing table
/// puts a literal `/rooms/settings` alongside `/rooms/<id>`, so the segment
/// after `/rooms/` is not always a room. Getting that wrong opens a search
/// over a room that does not exist, which fails as an empty result rather
/// than as an error. Pumping the real shortcut needs the Matrix provider,
/// whose boot never settles under flutter_tester, so this covers the
/// decision itself, which is the part that can be wrong.
void main() {
  group('searchRouteFor', () {
    test('an open room searches that room', () {
      expect(
        AppKeyboardShortcuts.searchRouteFor('/rooms/!abc:example.org'),
        '/rooms/!abc:example.org/search',
      );
    });

    test('settings is not a room', () {
      expect(AppKeyboardShortcuts.searchRouteFor('/rooms/settings'), isNull);
      expect(
        AppKeyboardShortcuts.searchRouteFor('/rooms/settings/security'),
        isNull,
      );
    });

    test('the chat list falls through to the inline search field', () {
      expect(AppKeyboardShortcuts.searchRouteFor('/rooms'), isNull);
      expect(AppKeyboardShortcuts.searchRouteFor('/rooms/'), isNull);
      expect(AppKeyboardShortcuts.searchRouteFor('/'), isNull);
      expect(AppKeyboardShortcuts.searchRouteFor('/login'), isNull);
    });

    test('pressing it again on the search page stays put', () {
      const route = '/rooms/!abc:example.org/search';
      expect(AppKeyboardShortcuts.searchRouteFor(route), route);
    });

    test('a sub-route of a room still searches that room', () {
      expect(
        AppKeyboardShortcuts.searchRouteFor('/rooms/!abc:example.org/details'),
        '/rooms/!abc:example.org/search',
      );
    });
  });
}

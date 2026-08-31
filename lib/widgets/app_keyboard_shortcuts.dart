// SPDX-FileCopyrightText: 2026-Present cornball.ai
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/unified_rooms.dart';
import 'package:fluffychat/utils/room_list_clients.dart';
import 'package:fluffychat/widgets/fluffy_chat_app.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// App-wide desktop keyboard shortcuts.
///
/// Ctrl+1..9 (also Cmd+1..9 for macOS) jumps to the nth chat,
/// Signal-style. The list is every shown account's activity-sorted rooms
/// with spaces excluded, built from the same pieces the chat list uses so
/// that the third chat here is the third chat on screen. The bindings work
/// while a text field has focus, so switching chats does not require
/// leaving the composer.
///
/// It does not follow the active filter: with "unread" selected the chat
/// list shows a subset and these still count the whole list. That was true
/// before the unified inbox and is left alone here.
///
/// Ctrl+F (also Cmd+F) opens search for whatever is in front of the
/// user: the open conversation's own search route, or failing that the
/// chat list's search field.
class AppKeyboardShortcuts extends StatelessWidget {
  final Widget child;

  const AppKeyboardShortcuts({super.key, required this.child});

  static const List<LogicalKeyboardKey> _digits = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
    LogicalKeyboardKey.digit7,
    LogicalKeyboardKey.digit8,
    LogicalKeyboardKey.digit9,
  ];

  /// Go to the [number]th chat (1-based) in the room list.
  void _goToChat(BuildContext context, int number) {
    final matrix = Matrix.of(context);
    final clients = roomListClientsFor(
      matrix,
    ).where((client) => client.isLogged()).toList();
    if (clients.isEmpty) return;
    final rooms = mergeAccountRooms(
      clients.map((client) => client.rooms).toList(),
      keep: (room) => !room.isSpace,
      compare: clients.first.defaultRoomSorter,
    );
    if (number > rooms.length) return;
    final room = rooms[number - 1];
    // The room may belong to an account that is not the active one, and the
    // chat page resolves the id against whichever is. The route parameter is
    // what switches it, the same way tapping the row does.
    final owner = room.client == matrix.client ? null : room.client;
    FluffyChatApp.router.go(roomRoute(room.id, clientName: owner?.clientName));
  }

  /// The search route ctrl+F should open from [route], or null when the
  /// right target is the chat list's search field, which is inline state
  /// rather than a route.
  ///
  /// The awkward case is `/rooms/settings`: the segment after `/rooms/` is
  /// usually a room id but on the settings routes it is the literal word,
  /// and sending someone to `/rooms/settings/search` opens a search over a
  /// room that does not exist.
  static String? searchRouteFor(String route) {
    if (!route.startsWith('/rooms/')) return null;
    final roomId = route.split('/')[2];
    if (roomId.isEmpty || roomId == 'settings') return null;
    return '/rooms/$roomId/search';
  }

  /// Search whatever the user is currently looking at.
  void _search(BuildContext context) {
    if (!Matrix.of(context).client.isLogged()) return;
    final route = FluffyChatApp.router.routeInformationProvider.value.uri.path;
    final searchRoute = searchRouteFor(route);
    if (searchRoute != null) {
      FluffyChatApp.router.go(searchRoute);
      return;
    }
    ChatListController.searchRequests.value++;
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        for (var i = 0; i < _digits.length; i++) ...{
          SingleActivator(_digits[i], control: true): () =>
              _goToChat(context, i + 1),
          SingleActivator(_digits[i], meta: true): () =>
              _goToChat(context, i + 1),
        },
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
            _search(context),
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () =>
            _search(context),
      },
      child: child,
    );
  }
}

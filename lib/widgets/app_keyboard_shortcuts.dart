// SPDX-FileCopyrightText: 2026-Present cornball.ai
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/widgets/fluffy_chat_app.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// App-wide desktop keyboard shortcuts.
///
/// Ctrl+1..9 (also Cmd+1..9 for macOS) jumps to the nth chat,
/// Signal-style. The list is the client's activity-sorted rooms with
/// spaces excluded, which matches the default chat list ordering. The
/// bindings work while a text field has focus, so switching chats does
/// not require leaving the composer.
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
    final client = Matrix.of(context).client;
    if (!client.isLogged()) return;
    final rooms = client.rooms.where((room) => !room.isSpace).toList();
    if (number > rooms.length) return;
    FluffyChatApp.router.go('/rooms/${rooms[number - 1].id}');
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

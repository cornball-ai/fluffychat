// SPDX-FileCopyrightText: 2026-Present cornball.ai
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

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
      },
      child: child,
    );
  }
}

// SPDX-FileCopyrightText: 2026-Present cornball.ai
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Does this message body invoke a bot's clear/reset/new command?
///
/// Only the slash forms count: a message that merely says "clear" is
/// conversation, not a boundary.
bool isClearCommandBody(String body) => RegExp(
  r'^/+(clear|reset|new)\s*$',
  caseSensitive: false,
).hasMatch(body.trim());

/// A conversation boundary in the timeline.
///
/// A /clear command is a session boundary for the bots in the room,
/// not a message. Rendering it as a labeled rule makes scrolling up
/// read as flipping through past conversations.
class ConversationDivider extends StatelessWidget {
  const ConversationDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.outline;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        children: [
          Expanded(child: Divider(color: color)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              L10n.of(context).newConversation,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ),
          Expanded(child: Divider(color: color)),
        ],
      ),
    );
  }
}

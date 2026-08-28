// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:badges/badges.dart' as b;
import 'package:material_ui/material_ui.dart';
import 'package:matrix/matrix.dart';

import 'matrix.dart';

class UnreadRoomsBadge extends StatelessWidget {
  final bool Function(Room) filter;
  final b.BadgePosition? badgePosition;
  final Widget? child;

  /// Whose rooms to count. Defaults to the active account; the navigation
  /// rail's account avatars pass their own client so each badge counts its
  /// own unreads.
  final Client? client;

  /// Several accounts at once, for a badge over something that spans them --
  /// the unified inbox's "all chats", where counting the active account only
  /// leaves out the rooms the list is showing. Takes precedence over
  /// [client].
  final List<Client>? clients;

  const UnreadRoomsBadge({
    super.key,
    required this.filter,
    this.badgePosition,
    this.child,
    this.client,
    this.clients,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final counted = clients ?? [client ?? Matrix.of(context).client];
    final unreadCount = counted
        .expand((client) => client.rooms)
        .where(filter)
        .where((r) => (r.isUnread || r.membership == Membership.invite))
        .length;
    return b.Badge(
      badgeStyle: b.BadgeStyle(
        badgeColor: theme.colorScheme.primary,
        elevation: 4,
        borderSide: BorderSide(color: theme.colorScheme.surface, width: 2),
      ),
      badgeContent: Text(
        unreadCount.toString(),
        style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 12),
      ),
      showBadge: unreadCount != 0,
      badgeAnimation: const b.BadgeAnimation.scale(),
      position: badgePosition ?? b.BadgePosition.bottomEnd(),
      child: child,
    );
  }
}

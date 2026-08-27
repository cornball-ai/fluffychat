// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/pages/chat_list/unified_rooms.dart';
import 'package:fluffychat/utils/string_color.dart';
import 'package:fluffychat/widgets/avatar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:matrix/matrix.dart';

/// Whose account a room belongs to, for the unified inbox where two accounts'
/// rooms sit in one list and nothing else on the row says which is which.
///
/// It shows the user ID rather than the person, because the accounts are
/// usually the same human: a display name and a profile picture are the two
/// things least likely to tell them apart, and drawing either costs a profile
/// fetch per row. Two letters, the localpart's and the homeserver's, so that
/// neither two accounts on one server nor one person on two servers collapse
/// into the same badge. The colour comes from the whole id, but it is a tie
/// breaker rather than the identity: the palette holds twelve hues.
class AccountBadge extends StatelessWidget {
  final Client client;
  final double size;

  /// What the badge is cut out of, so the ring reads as a gap rather than a
  /// stroke. Defaults to the surface the list sits on.
  final Color? borderColor;

  const AccountBadge({
    required this.client,
    this.size = 22,
    this.borderColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = client.userID ?? '';
    final scheme = userId.colorScheme;
    final borderRadius = BorderRadius.circular(size / 2);
    return Tooltip(
      message: userId,
      child: Avatar(
        client: client,
        name: accountBadgeLabel(userId),
        backgroundColor: scheme.primaryContainer,
        textColor: scheme.onPrimaryContainer,
        size: size,
        borderRadius: borderRadius,
        shapeBorder: RoundedSuperellipseBorder(
          side: BorderSide(
            width: 2,
            color: borderColor ?? theme.colorScheme.surface,
          ),
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

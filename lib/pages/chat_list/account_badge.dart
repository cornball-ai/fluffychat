// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/widgets/avatar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:matrix/matrix.dart';

/// Whose account a room belongs to, for the unified inbox where two
/// accounts' rooms sit in one list and nothing else on the row says which is
/// which.
///
/// It shows the homeserver rather than the person, because the accounts are
/// usually the same human: a display name and a profile picture are the two
/// things least likely to tell them apart, and drawing either costs a profile
/// fetch per row. A domain is already in hand, colours deterministically, and
/// is the thing you actually want to read off the badge.
class AccountBadge extends StatelessWidget {
  final Client client;
  final double size;

  /// What the badge is cut out of, so the ring reads as a gap rather than a
  /// stroke. Defaults to the surface the list sits on.
  final Color? borderColor;

  const AccountBadge({
    required this.client,
    this.size = 20,
    this.borderColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(size / 2);
    return Tooltip(
      message: client.userID ?? '',
      child: Avatar(
        client: client,
        name: client.userID?.domain ?? '',
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

// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/utils/string_color.dart';
import 'package:material_ui/material_ui.dart';

/// Whose account a room belongs to, for the unified inbox where two accounts'
/// rooms sit in one list and nothing else on the row says which is which.
///
/// It draws [label] verbatim -- see `accountBadgeLabels`, which is what makes
/// the labels on screen distinct from one another. Deriving letters from a
/// name is what this deliberately does not do: `Avatar` takes the initial of
/// the first word and of the last, so `matrix.org` came out as a lone "m" and
/// every account on that server drew the same badge.
///
/// It shows the account, not the person. The accounts are usually the same
/// human, so a display name and a profile picture are the two things least
/// likely to tell them apart, and drawing either would cost a profile fetch
/// per row. The colour is decoration on top of the label, not the identity:
/// the palette holds twelve hues and two accounts may well share one.
class AccountBadge extends StatelessWidget {
  /// Colours the badge and names the account in the tooltip.
  final String userId;

  /// One or two characters, drawn as given.
  final String label;

  final double size;

  /// What the badge is cut out of, so the ring reads as a gap rather than a
  /// stroke. Defaults to the surface the list sits on.
  final Color? borderColor;

  const AccountBadge({
    required this.userId,
    required this.label,
    this.size = 22,
    this.borderColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = userId.colorScheme;
    return Tooltip(
      message: userId,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          shape: BoxShape.circle,
          border: Border.all(
            width: 2,
            color: borderColor ?? theme.colorScheme.surface,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontWeight: FontWeight.bold,
            fontSize: (size / 2.4).roundToDouble(),
            color: scheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

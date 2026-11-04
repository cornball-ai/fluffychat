// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/utils/sender_trust/event_sender_trust.dart';
import 'package:fluffychat/utils/sender_trust/sender_trust.dart';
import 'package:material_ui/material_ui.dart';
import 'package:matrix/matrix.dart';

/// One line under an encrypted message whose sending device cannot be
/// trusted: not cross-signed by its owner, unknown, or another user's.
/// Renders nothing for cleartext messages and cross-signed senders.
class SenderTrustWarning extends StatelessWidget {
  final Event event;
  final bool ownMessage;
  final List<Shadow>? shadows;

  const SenderTrustWarning({
    super.key,
    required this.event,
    required this.ownMessage,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final cached = event.senderTrustSync;
    if (cached != null) {
      return _TrustLine(
        trust: cached,
        ownMessage: ownMessage,
        shadows: shadows,
      );
    }
    return FutureBuilder<SenderTrust?>(
      future: event.senderTrust(),
      builder: (context, snapshot) => _TrustLine(
        trust: snapshot.data,
        ownMessage: ownMessage,
        shadows: shadows,
      ),
    );
  }
}

class _TrustLine extends StatelessWidget {
  final SenderTrust? trust;
  final bool ownMessage;
  final List<Shadow>? shadows;

  const _TrustLine({
    required this.trust,
    required this.ownMessage,
    required this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final text = switch (trust) {
      null || SenderTrust.crossSigned => null,
      SenderTrust.unsignedDevice => L10n.of(context).encryptedByUnsignedDevice,
      SenderTrust.unknownDevice => L10n.of(context).encryptedByUnknownDevice,
      SenderTrust.otherUsersDevice => L10n.of(
        context,
      ).encryptedByOtherUsersDevice,
    };
    if (text == null) return const SizedBox.shrink();
    final color = Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 2.0),
      child: Row(
        mainAxisAlignment: ownMessage
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Icon(
            Icons.gpp_maybe_outlined,
            size: 14,
            color: color,
            shadows: shadows,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: color, shadows: shadows),
            ),
          ),
        ],
      ),
    );
  }
}

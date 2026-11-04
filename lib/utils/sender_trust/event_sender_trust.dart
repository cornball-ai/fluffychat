// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:matrix/matrix.dart';

import 'sender_trust.dart';

/// Resolves which device encrypted an event and whether that device can be
/// trusted, from the Megolm session the SDK decrypted it with.
extension EventSenderTrust on Event {
  /// The Megolm session this event was encrypted with. Null when the event
  /// was sent in the clear or has not been decrypted.
  String? get _megolmSessionId {
    final source = originalSource;
    if (source == null || source.type != EventTypes.Encrypted) return null;
    final content = source.parsedRoomEncryptedContent;
    if (content.algorithm != AlgorithmTypes.megolmV1AesSha2) return null;
    return content.sessionId;
  }

  /// Trust in the sending device when its session is already in memory.
  /// Null when the event was not encrypted or the session is not cached
  /// yet; [senderTrust] loads it in that case.
  SenderTrust? get senderTrustSync {
    final sessionId = _megolmSessionId;
    final encryption = room.client.encryption;
    if (sessionId == null || encryption == null) return null;
    final session = encryption.keyManager.getInboundGroupSession(
      room.id,
      sessionId,
    );
    if (session == null) return null;
    return _classify(session.senderKey, session.senderClaimedKeys['ed25519']);
  }

  /// Trust in the sending device, loading its session from the database
  /// when needed. Null when the event was not encrypted or the session is
  /// unknown to this client.
  Future<SenderTrust?> senderTrust() async {
    final sessionId = _megolmSessionId;
    final encryption = room.client.encryption;
    if (sessionId == null || encryption == null) return null;
    final session = await encryption.keyManager.loadInboundGroupSession(
      room.id,
      sessionId,
    );
    if (session == null) return null;
    return _classify(session.senderKey, session.senderClaimedKeys['ed25519']);
  }

  /// [senderKey] is the Curve25519 key the session was received from and
  /// [claimedEd25519] the signing key its sender claimed, if any.
  SenderTrust _classify(String senderKey, String? claimedEd25519) {
    final device = room.client.getUserDeviceKeysByCurve25519Key(senderKey);
    return classifySender(
      eventSenderId: senderId,
      claimedEd25519: claimedEd25519,
      device: device == null
          ? null
          : (
              userId: device.userId,
              ed25519Key: device.ed25519Key,
              crossSigned: device.hasValidSignatureChain(
                verifiedByTheirMasterKey: true,
              ),
            ),
    );
  }
}

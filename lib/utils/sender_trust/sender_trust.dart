// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

/// What is known about the device that created a Megolm session.
typedef SendingDevice = ({String userId, String? ed25519Key, bool crossSigned});

/// Trust in the device that encrypted a message.
///
/// The Client-Server spec's cross-signing section says messages from
/// non-cross-signed devices cannot be trusted and that a message encrypted
/// by another user's device must carry a warning. Everything except
/// [crossSigned] is shown to the user.
enum SenderTrust {
  /// The sending device is cross-signed by its owner.
  crossSigned,

  /// The sending device exists but its owner has not cross-signed it.
  unsignedDevice,

  /// No known device matches the session's sender key, or the signing key
  /// the session claims does not belong to that device.
  unknownDevice,

  /// The session was created by a device that belongs to another user.
  otherUsersDevice,
}

/// Classifies the device a Megolm session came from.
///
/// [eventSenderId] is the Matrix user the event claims as its sender,
/// [claimedEd25519] is the signing key the session's sender claimed, and
/// [device] is the device whose Curve25519 key matches the session's sender
/// key, or null when no tracked device matches.
SenderTrust classifySender({
  required String eventSenderId,
  required String? claimedEd25519,
  required SendingDevice? device,
}) {
  if (device == null) return SenderTrust.unknownDevice;
  if (claimedEd25519 != null && device.ed25519Key != claimedEd25519) {
    return SenderTrust.unknownDevice;
  }
  if (device.userId != eventSenderId) return SenderTrust.otherUsersDevice;
  return device.crossSigned
      ? SenderTrust.crossSigned
      : SenderTrust.unsignedDevice;
}

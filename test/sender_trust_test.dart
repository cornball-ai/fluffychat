// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/utils/sender_trust/sender_trust.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const alice = '@alice:example.com';
  const aliceKey = 'ed25519-key-of-alice-device';

  SendingDevice device({
    String userId = alice,
    String? ed25519Key = aliceKey,
    bool crossSigned = true,
  }) => (userId: userId, ed25519Key: ed25519Key, crossSigned: crossSigned);

  test('a cross-signed device of the sender is trusted', () {
    expect(
      classifySender(
        eventSenderId: alice,
        claimedEd25519: aliceKey,
        device: device(),
      ),
      SenderTrust.crossSigned,
    );
  });

  test('a device its owner has not cross-signed is flagged', () {
    expect(
      classifySender(
        eventSenderId: alice,
        claimedEd25519: aliceKey,
        device: device(crossSigned: false),
      ),
      SenderTrust.unsignedDevice,
    );
  });

  test('no tracked device for the sender key is unknown', () {
    expect(
      classifySender(
        eventSenderId: alice,
        claimedEd25519: aliceKey,
        device: null,
      ),
      SenderTrust.unknownDevice,
    );
  });

  test('a claimed signing key that is not the device\'s is unknown', () {
    expect(
      classifySender(
        eventSenderId: alice,
        claimedEd25519: 'some-other-ed25519-key',
        device: device(),
      ),
      SenderTrust.unknownDevice,
    );
  });

  test('without a claimed signing key the curve25519 match decides', () {
    expect(
      classifySender(
        eventSenderId: alice,
        claimedEd25519: null,
        device: device(crossSigned: false),
      ),
      SenderTrust.unsignedDevice,
    );
  });

  test('a device that belongs to another user is flagged even if signed', () {
    expect(
      classifySender(
        eventSenderId: alice,
        claimedEd25519: aliceKey,
        device: device(userId: '@bridge:example.com'),
      ),
      SenderTrust.otherUsersDevice,
    );
  });
}

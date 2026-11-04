// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/l10n/l10n_en.dart';
import 'package:fluffychat/pages/chat/events/sender_trust_warning.dart';
import 'package:fluffychat/utils/sender_trust/event_sender_trust.dart';
import 'package:fluffychat/utils/sender_trust/sender_trust.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:matrix/matrix.dart';
// ignore: depend_on_referenced_packages
import 'package:vodozemac/vodozemac.dart' as vod;

import 'utils/test_client.dart';

/// Serves the generated English strings synchronously. The app's own
/// delegate loads them through a deferred import, which never completes
/// under the widget test's fake clock.
class _EnglishNow extends LocalizationsDelegate<L10n> {
  const _EnglishNow();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<L10n> load(Locale locale) => SynchronousFuture(L10nEn());

  @override
  bool shouldReload(_EnglishNow old) => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Client client;
  late DeviceKeys crossSignedDevice;
  late DeviceKeys unsignedDevice;
  var roomCount = 0;

  bool isCrossSigned(DeviceKeys device) =>
      device.hasValidSignatureChain(verifiedByTheirMasterKey: true);

  setUpAll(() async {
    client = await prepareTestClient(loggedIn: true);
    await client.updateUserDeviceKeys(
      additionalUsers: {
        '@alice:example.com',
        '@othertest:fakeServer.notExisting',
      },
    );
    final devices = client.userDeviceKeys.values
        .expand((list) => list.deviceKeys.values)
        .where((d) => d.curve25519Key != null && d.ed25519Key != null)
        .toList();
    // Fixture preconditions: the fake key query must contain at least one
    // device signed by its owner's self-signing key and one that is not.
    crossSignedDevice = devices.firstWhere(isCrossSigned);
    unsignedDevice = devices.firstWhere((d) => !isCrossSigned(d));
  });

  tearDownAll(() => client.dispose());

  /// Stores a fresh Megolm session under a fresh room as if [senderKey] had
  /// sent it and returns a decrypted event in that room from [senderId].
  /// Each case gets its own session: the store is keyed by session id, and
  /// the fake sync already delivers the SDK fixture's session.
  Future<Event> decryptedEvent({
    required String senderKey,
    required String? claimedEd25519,
    required String senderId,
  }) async {
    final roomId = '!room${roomCount++}:example.com';
    final room = Room(id: roomId, client: client);
    final outbound = vod.GroupSession();
    final sessionId = outbound.sessionId;
    await client.encryption!.keyManager.setInboundGroupSession(
      roomId,
      sessionId,
      senderKey,
      {
        'algorithm': AlgorithmTypes.megolmV1AesSha2,
        'room_id': roomId,
        'session_id': sessionId,
        'session_key': outbound.sessionKey,
      },
      senderClaimedKeys: claimedEd25519 == null
          ? {}
          : {'ed25519': claimedEd25519},
    );
    final now = DateTime.now();
    final eventId = '\$event$roomCount';
    return Event(
      content: {'msgtype': 'm.text', 'body': 'hello'},
      type: EventTypes.Message,
      eventId: eventId,
      senderId: senderId,
      originServerTs: now,
      room: room,
      originalSource: MatrixEvent(
        type: EventTypes.Encrypted,
        content: {
          'algorithm': AlgorithmTypes.megolmV1AesSha2,
          'sender_key': senderKey,
          'session_id': sessionId,
          'ciphertext': 'AwgA',
        },
        eventId: eventId,
        senderId: senderId,
        originServerTs: now,
        roomId: roomId,
      ),
    );
  }

  test('a cleartext event has no sender trust', () async {
    final event = Event(
      content: {'msgtype': 'm.text', 'body': 'hello'},
      type: EventTypes.Message,
      eventId: '\$clear',
      senderId: '@alice:example.com',
      originServerTs: DateTime.now(),
      room: Room(id: '!clear:example.com', client: client),
    );
    expect(event.senderTrustSync, isNull);
    expect(await event.senderTrust(), isNull);
  });

  test('a session from a cross-signed device is trusted', () async {
    final event = await decryptedEvent(
      senderKey: crossSignedDevice.curve25519Key!,
      claimedEd25519: crossSignedDevice.ed25519Key,
      senderId: crossSignedDevice.userId,
    );
    expect(event.senderTrustSync, SenderTrust.crossSigned);
    expect(await event.senderTrust(), SenderTrust.crossSigned);
  });

  test('a session from a device its owner has not signed is flagged', () async {
    final event = await decryptedEvent(
      senderKey: unsignedDevice.curve25519Key!,
      claimedEd25519: unsignedDevice.ed25519Key,
      senderId: unsignedDevice.userId,
    );
    expect(event.senderTrustSync, SenderTrust.unsignedDevice);
  });

  test('a session from an untracked sender key is unknown', () async {
    final event = await decryptedEvent(
      senderKey: 'nobodyWeKnowHasThisCurve25519Key0000000000',
      claimedEd25519: null,
      senderId: '@alice:example.com',
    );
    expect(event.senderTrustSync, SenderTrust.unknownDevice);
  });

  test('a session from another user\'s device is flagged', () async {
    final event = await decryptedEvent(
      senderKey: crossSignedDevice.curve25519Key!,
      claimedEd25519: crossSignedDevice.ed25519Key,
      senderId: '@someone:else.example',
    );
    expect(event.senderTrustSync, SenderTrust.otherUsersDevice);
  });

  test('senderTrust loads a session that is not cached', () async {
    final event = await decryptedEvent(
      senderKey: unsignedDevice.curve25519Key!,
      claimedEd25519: unsignedDevice.ed25519Key,
      senderId: unsignedDevice.userId,
    );
    client.encryption!.keyManager.clearInboundGroupSessions();
    expect(event.senderTrustSync, isNull);
    expect(await event.senderTrust(), SenderTrust.unsignedDevice);
  });

  testWidgets('the warning line renders for an unsigned device only', (
    tester,
  ) async {
    // The SDK's database writes are real I/O, which the widget test's fake
    // clock would never let complete, so build the events outside it.
    late final Event flagged;
    late final Event trusted;
    await tester.runAsync(() async {
      flagged = await decryptedEvent(
        senderKey: unsignedDevice.curve25519Key!,
        claimedEd25519: unsignedDevice.ed25519Key,
        senderId: unsignedDevice.userId,
      );
      trusted = await decryptedEvent(
        senderKey: crossSignedDevice.curve25519Key!,
        claimedEd25519: crossSignedDevice.ed25519Key,
        senderId: crossSignedDevice.userId,
      );
    });
    // Every delegate here loads synchronously, so one frame is enough and
    // nothing waits on the test client's sync loop.
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en'),
        delegates: const [
          _EnglishNow(),
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Theme(
          data: ThemeData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              children: [
                SenderTrustWarning(event: flagged, ownMessage: true),
                SenderTrustWarning(event: trusted, ownMessage: false),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      find.text('Encrypted by a device its owner has not verified'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.gpp_maybe_outlined), findsOneWidget);
  });
}

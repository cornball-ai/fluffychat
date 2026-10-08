// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/utils/matrix_live_kit_calls/call_keys_event_content.dart';
import 'package:flutter_test/flutter_test.dart';

// MatrixRTC / Element Call send the `io.element.call.encryption_keys` `keys`
// field as an ARRAY of {index, key}. FluffyChat <= 2.10 read and wrote it as a
// single object, so a FluffyChat<->Element/agent call threw on decode and
// shipped a shape the peer could not read -- E2EE failed both ways. These tests
// pin the array shape (and keep tolerating the legacy single-object form).
void main() {
  Map<String, Object?> contentWith(Object? keys) => {
    'keys': keys,
    'member': {'id': '@a:b.c', 'claimed_device_id': 'DEV'},
    'room_id': '!room:b.c',
    'session': {'application': 'm.call', 'call_id': '', 'scope': 'm.room'},
    'sent_ts': 1,
  };

  group('CallKeysEventContent keys encoding', () {
    test('parses the array form (MatrixRTC/Element)', () {
      final content = CallKeysEventContent.fromJson(
        contentWith([
          {'index': 0, 'key': 'AAAA'},
          {'index': 1, 'key': 'BBBB'},
        ]),
      );
      expect(content.keys.length, 2);
      expect(content.keys[0].index, 0);
      expect(content.keys[0].key, 'AAAA');
      expect(content.keys[1].index, 1);
      expect(content.keys[1].key, 'BBBB');
    });

    test('still parses the legacy single-object form', () {
      final content = CallKeysEventContent.fromJson(
        contentWith({'index': 3, 'key': 'CCCC'}),
      );
      expect(content.keys.length, 1);
      expect(content.keys.single.index, 3);
      expect(content.keys.single.key, 'CCCC');
    });

    test('tolerates a missing/invalid keys field', () {
      expect(CallKeysEventContent.fromJson(contentWith(null)).keys, isEmpty);
    });

    test('serializes keys as an array peers can read', () {
      final json = CallKeysEventContent(
        keys: [CallKeysEntry(index: 7, key: 'DDDD')],
        member: CallKeysMember(id: '@a:b.c', claimedDeviceId: 'DEV'),
        roomId: '!room:b.c',
        session: CallKeysSession(
          application: 'm.call',
          callId: '',
          scope: 'm.room',
        ),
      ).toJson();
      expect(json['keys'], isA<List<Object?>>());
      expect(json['keys'], [
        {'index': 7, 'key': 'DDDD'},
      ]);
    });

    test('emits the legacy single-object form for stock FluffyChat', () {
      final content = CallKeysEventContent(
        keys: [CallKeysEntry(index: 7, key: 'DDDD')],
        member: CallKeysMember(id: '@a:b.c', claimedDeviceId: 'DEV'),
        roomId: '!room:b.c',
        session: CallKeysSession(
          application: 'm.call',
          callId: '',
          scope: 'm.room',
        ),
      );
      final legacy = content.toJson(legacyObjectKeys: true);
      expect(legacy['keys'], isA<Map<String, Object?>>());
      expect(legacy['keys'], {'index': 7, 'key': 'DDDD'});
      // The legacy object shape must re-parse to the same single entry.
      final reparsed = CallKeysEventContent.fromJson(legacy);
      expect(reparsed.keys.single.index, 7);
      expect(reparsed.keys.single.key, 'DDDD');
    });

    test('round-trips the array form', () {
      final original = contentWith([
        {'index': 2, 'key': 'EEEE'},
      ]);
      final reencoded = CallKeysEventContent.fromJson(original).toJson();
      expect(reencoded['keys'], original['keys']);
    });
  });
}

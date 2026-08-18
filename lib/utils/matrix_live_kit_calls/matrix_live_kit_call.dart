// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';

import 'package:fluffychat/utils/matrix_live_kit_calls/call_keys_event_content.dart';
import 'package:fluffychat/utils/matrix_live_kit_calls/matrix_live_kit_call_member.dart';
import 'package:matrix/encryption/utils/base64_unpadded.dart';
import 'package:matrix/matrix.dart';

extension LiveKitClientExtension on Client {
  Future<List<String>> getLiveKitBackendUrls() async {
    final wellKnown = await getWellknown();
    final rtcFociMap = wellKnown.additionalProperties
        .tryGetMap<String, Object?>(
          'org.matrix.msc4143.rtc_foci',
          TryGet.silent,
        );
    if (rtcFociMap != null) {
      return [?rtcFociMap.tryGet<String>('livekit_service_url')];
    }

    return wellKnown.additionalProperties
            .tryGetList<Map<String, Object?>>('org.matrix.msc4143.rtc_foci')
            ?.map((foci) => foci.tryGet<String>('livekit_service_url'))
            .whereType<String>()
            .toList() ??
        [];
  }

  Stream<CallKeysEvent> get onCallEncryptionKeys => onToDeviceEvent.stream
      .where((event) => event.type == CallKeysEventContent.eventType)
      .map(CallKeysEvent.fromToDeviceEvent);
}

extension LiveKitRoomExtension on Room {
  bool get hasActiveLiveKitCall => getActiveLiveKitMembers().isNotEmpty;

  bool get hasPermissionForLiveKitCall =>
      canChangeStateEvent(MatrixLiveKitCallMember.eventType);

  List<MatrixLiveKitCallMember> getActiveLiveKitMembers() {
    final states = this.states[MatrixLiveKitCallMember.eventType];
    if (states == null) return [];
    // Empty content {} means the member has left — filter those out
    final activeMemberStates = states.values.where((event) {
      if (event.content.isEmpty) return false;
      if (event is! Event) return false;
      try {
        final validContent = MatrixLiveKitCallMember.fromJson(event.content);
        if (validContent.focusActive?.type != 'livekit') return false;
        final expiresAt = event.originServerTs.add(
          Duration(milliseconds: validContent.expires),
        );
        if (expiresAt.isBefore(DateTime.now())) return false;
        return true;
      } catch (e, s) {
        Logs().d('Invalid "org.matrix.msc3401.call.member" event!', e, s);
        return false;
      }
    });
    return activeMemberStates
        .map((state) => MatrixLiveKitCallMember.fromJson(state.content))
        .toList();
  }

  String get _ownLiveKitMembershipStateKey =>
      '_${client.userID}_${client.deviceID}_m.call';

  MatrixLiveKitCallMember? get ownLiveKitMembership {
    final state = getState(
      MatrixLiveKitCallMember.eventType,
      _ownLiveKitMembershipStateKey,
    );
    if (state == null || state.content.isEmpty) return null;
    try {
      return MatrixLiveKitCallMember.fromJson(state.content);
    } catch (e, s) {
      Logs().d(
        'Unknown format for ${MatrixLiveKitCallMember.eventType} event',
        e,
        s,
      );
      return null;
    }
  }

  Future<void> shareLiveKitCallKey({
    required Uint8List key,
    required int index,
    required String memberId,
    List<DeviceKeys>? deviceKeys,
  }) async {
    if (deviceKeys == null) {
      final callMembers = getActiveLiveKitMembers();
      deviceKeys = [];
      for (final member in callMembers) {
        final membershipId = member.membershipId;
        if (membershipId == null || membershipId == memberId) continue;
        final membershipParts = membershipId.split(':');
        final deviceId = membershipParts.removeLast();
        final userId = membershipParts.join(':');
        final keys = client.userDeviceKeys[userId]?.deviceKeys[deviceId];
        if (keys == null) {
          Logs().w('No device keys found for $membershipId');
          continue;
        }
        deviceKeys.add(keys);
      }
    }
    if (deviceKeys.isEmpty) {
      Logs().d('No devices to share call keys with');
      return;
    }
    Logs().d(
      'Share call keys with',
      deviceKeys.map((key) => '${key.userId}:${key.deviceId}'),
    );
    await client.sendToDeviceEncrypted(
      deviceKeys,
      CallKeysEventContent.eventType,
      CallKeysEventContent(
        keys: CallKeysEntry(index: index, key: encodeBase64Unpadded(key)),
        member: CallKeysMember(id: memberId, claimedDeviceId: client.deviceID!),
        roomId: id,
        sentTs: DateTime.now().millisecondsSinceEpoch,
        session: CallKeysSession(
          application: 'm.call',
          callId: '',
          scope: 'm.room',
        ),
      ).toJson(),
    );
  }

  Future<LiveKitCredentials> joinLiveKitCall({
    MatrixLiveKitCallIntent intent = MatrixLiveKitCallIntent.video,
  }) async {
    await postLoad();
    if (ownLiveKitMembership != null) {
      leaveLiveKitCall();
      throw Exception('User has already joined the call!');
    }
    Logs().d('[Join LiveKit Call] (1/5) Get LiveKit Backend Urls...');
    final urls = await client.getLiveKitBackendUrls();
    if (urls.isEmpty) {
      throw Exception('This server does not support livekit calls!');
    }

    Logs().d(
      '[Join LiveKit Call] (2/5) Set "${MatrixLiveKitCallMember.eventType}" State event...',
    );
    await client.setRoomStateWithKey(
      id,
      MatrixLiveKitCallMember.eventType,
      _ownLiveKitMembershipStateKey,
      MatrixLiveKitCallMember(
        application: 'm.call',
        callId: '',
        deviceId: client.deviceID,
        expires: 14400000,
        fociPreferred: urls
            .map(
              (url) => MatrixLiveKitFocusPreferred(
                type: 'livekit',
                livekitServiceUrl: url,
                livekitAlias: id,
              ),
            )
            .toList(),
        focusActive: MatrixLiveKitFocusActive(
          focusSelection: 'oldest_membership',
          type: 'livekit',
        ),
        callIntent: intent.name,
        membershipId: '${client.userID}:${client.deviceID}',
        scope: 'm.room',
      ).toJson(),
    );

    // TODO: Send RTC Notification

    Logs().v('[Join LiveKit Call] (3/5) Request OpenId Token...');
    final openIdCredentials = await client.requestOpenIdToken(
      client.userID!,
      {},
    );

    final memberUrls =
        states[MatrixLiveKitCallMember.eventType]?.values
            .map(
              (state) => MatrixLiveKitCallMember.fromJson(
                state.content,
              ).fociPreferred.map((focus) => focus.livekitServiceUrl),
            )
            .fold<List<String>>([], (urls, foci) => [...urls, ...foci]) ??
        [];

    for (final url in {...urls, ...memberUrls}) {
      try {
        Logs().d(
          '[Join LiveKit Call] (4/5) Try authenticate to LiveKit instance $url...',
        );
        final response = await client.httpClient.post(
          Uri.parse('${url.replaceAll(RegExp(r'/+$'), '')}/sfu/get'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'room': id,
            'openid_token': openIdCredentials.toJson(),
            'device_id': client.deviceID,
          }),
        );
        if (response.statusCode != 200) {
          throw Exception(response.reasonPhrase ?? response.body);
        }
        final json =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, Object?>;
        return LiveKitCredentials.fromJson(json);
      } catch (e) {
        Logs().v('[Join LiveKit Call] (4/4) Unable to authenticate to $url', e);
      }
    }
    throw Exception(
      'Unable to authenticate to any of the visible LiveKit instances!',
    );
  }

  Future<void> leaveLiveKitCall() async {
    await client.setRoomStateWithKey(
      id,
      MatrixLiveKitCallMember.eventType,
      _ownLiveKitMembershipStateKey,
      {},
    );
  }
}

class LiveKitCredentials {
  final String url, jwt;
  const LiveKitCredentials({required this.url, required this.jwt});
  factory LiveKitCredentials.fromJson(Map<String, Object?> json) =>
      LiveKitCredentials(
        url: json['url'] as String,
        jwt: json['jwt'] as String,
      );
}

enum MatrixLiveKitCallIntent { audio, video }

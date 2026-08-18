// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:matrix/matrix_api_lite/utils/try_get_map_extension.dart';

class MatrixLiveKitCallMember {
  static const String eventType = 'org.matrix.msc3401.call.member';

  final String application;
  final String callId;
  final String? deviceId;
  final int expires;
  final List<MatrixLiveKitFocusPreferred> fociPreferred;
  final MatrixLiveKitFocusActive? focusActive;
  final String callIntent;
  final String? membershipId;
  final String scope;

  const MatrixLiveKitCallMember({
    required this.application,
    required this.callId,
    required this.deviceId,
    required this.expires,
    required this.fociPreferred,
    required this.focusActive,
    required this.callIntent,
    required this.membershipId,
    required this.scope,
  });

  factory MatrixLiveKitCallMember.fromJson(Map<String, Object?> json) =>
      MatrixLiveKitCallMember(
        application: json.tryGet<String>('application') ?? '',
        callId: json.tryGet<String>('call_id') ?? '',
        deviceId: json.tryGet<String>('device_id'),
        expires: json.tryGet<int>('expires') ?? 0,
        fociPreferred:
            (json['foci_preferred'] as List?)
                ?.whereType<Map>()
                .map(
                  (e) => MatrixLiveKitFocusPreferred.fromJson(
                    Map<String, Object?>.from(e),
                  ),
                )
                .toList() ??
            [],
        focusActive: json['focus_active'] is Map
            ? MatrixLiveKitFocusActive.fromJson(
                Map<String, Object?>.from(json['focus_active'] as Map),
              )
            : null,
        callIntent: json.tryGet<String>('m.call.intent') ?? 'video',
        membershipId: json.tryGet<String>('membershipID'),
        scope: json.tryGet<String>('scope') ?? 'm.room',
      );

  Map<String, Object?> toJson() => {
    'application': application,
    'call_id': callId,
    if (deviceId != null) 'device_id': deviceId,
    'expires': expires,
    'foci_preferred': fociPreferred.map((f) => f.toJson()).toList(),
    if (focusActive != null) 'focus_active': focusActive!.toJson(),
    'm.call.intent': callIntent,
    if (membershipId != null) 'membershipID': membershipId,
    'scope': scope,
  };
}

class MatrixLiveKitFocusPreferred {
  final String type;
  final String livekitServiceUrl;
  final String livekitAlias;

  const MatrixLiveKitFocusPreferred({
    required this.type,
    required this.livekitServiceUrl,
    required this.livekitAlias,
  });

  factory MatrixLiveKitFocusPreferred.fromJson(Map<String, Object?> json) =>
      MatrixLiveKitFocusPreferred(
        type: json.tryGet<String>('type') ?? '',
        livekitServiceUrl: json.tryGet<String>('livekit_service_url') ?? '',
        livekitAlias: json.tryGet<String>('livekit_alias') ?? '',
      );

  Map<String, Object?> toJson() => {
    'type': type,
    'livekit_service_url': livekitServiceUrl,
    'livekit_alias': livekitAlias,
  };
}

class MatrixLiveKitFocusActive {
  final String type;
  final String focusSelection;

  const MatrixLiveKitFocusActive({
    required this.type,
    required this.focusSelection,
  });

  factory MatrixLiveKitFocusActive.fromJson(Map<String, Object?> json) =>
      MatrixLiveKitFocusActive(
        type: json.tryGet<String>('type') ?? '',
        focusSelection: json.tryGet<String>('focus_selection') ?? '',
      );

  Map<String, Object?> toJson() => {
    'type': type,
    'focus_selection': focusSelection,
  };
}

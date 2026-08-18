// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:fluffychat/utils/matrix_live_kit_calls/call_keys_event_content.dart';
import 'package:fluffychat/utils/matrix_live_kit_calls/matrix_live_kit_call.dart';
import 'package:fluffychat/utils/matrix_live_kit_calls/matrix_live_kit_call_member.dart';
import 'package:fluffychat/widgets/future_loading_dialog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:matrix/matrix.dart';

class CallViewModel extends ValueNotifier<lk.Room?> {
  final String liveKitUrl, liveKitJwt;
  final Room room;

  StreamSubscription? _onCallEncryptionKeysSub, _onCallMembersChanged;

  CallViewModel({
    required this.room,
    required this.liveKitUrl,
    required this.liveKitJwt,
  }) : super(null) {
    _init();
  }

  Future<void> _onCallEncryptionKeys(CallKeysEvent event) async {
    final callKeys = event.callKeysContent;
    final keyProvider = value?.e2eeManager?.keyProvider;
    if (keyProvider == null) return;

    await keyProvider.setRawKey(
      base64Decode(callKeys.keys.key),
      participantId: '${event.sender}:${callKeys.member.claimedDeviceId}',
      keyIndex: callKeys.keys.index,
    );
  }

  Future<void> _createKeyAndShare({int? index}) async {
    final liveKitRoom = value;
    if (liveKitRoom == null) return;

    // Generate own key
    final rng = Random.secure();
    final key = Uint8List(16);
    key.setAll(0, Iterable.generate(key.length, (i) => rng.nextInt(256)));

    final participantId = '${room.client.userID}:${room.client.deviceID}';

    index ??=
        liveKitRoom.roomOptions.encryption!.keyProvider.getLatestIndex(
          participantId,
        ) +
        1;
    Logs().d('Create and share new call key at index', index);

    await liveKitRoom.roomOptions.encryption!.keyProvider.setRawKey(
      key,
      keyIndex: index,
      participantId: participantId,
    );

    await room.shareLiveKitCallKey(
      key: key,
      index: index,
      memberId: '${room.client.userID}:${room.client.deviceID}',
    );
  }

  Future<void> _init() async {
    _onCallEncryptionKeysSub = room.client.onCallEncryptionKeys.listen(
      _onCallEncryptionKeys,
    );
    _onCallMembersChanged = room.client.onSync.stream
        .where(
          (syncUpdate) =>
              syncUpdate.rooms?.join?[room.id]?.timeline?.events?.any(
                (event) => event.type == MatrixLiveKitCallMember.eventType,
              ) ??
              false,
        )
        .listen((_) => _createKeyAndShare());
    await lk.LiveKitClient.initialize();
    // kHKDF matches the key derivation used by element-web's LiveKit JS SDK
    final keyProviderOptions = rtc.KeyProviderOptions(
      sharedKey: false,
      ratchetSalt: Uint8List.fromList('LKFrameEncryptionKey'.codeUnits),
      ratchetWindowSize: 0,
      discardFrameWhenCryptorNotReady: true,
      keyDerivationAlgorithm: rtc.KeyDerivationAlgorithm.kHKDF,
    );
    final nativeKeyProvider = await rtc.frameCryptorFactory
        .createDefaultKeyProvider(keyProviderOptions);
    final liveKitRoom = value = lk.Room(
      roomOptions: lk.RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultAudioCaptureOptions: lk.AudioCaptureOptions(
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
          highPassFilter: true,
        ),
        encryption: lk.E2EEOptions(
          keyProvider: lk.BaseKeyProvider(
            nativeKeyProvider,
            keyProviderOptions,
          ),
        ),
      ),
    );
    await liveKitRoom.e2eeManager?.setEnabled(true);

    liveKitRoom.events.on<lk.TrackE2EEStateEvent>((event) {
      if (event.state == .kOk || event.state == .kNew) {
        Logs().i('E2EE event', event);
        return;
      }
      if (event.state == .kMissingKey) {
        Logs().d('Waiting for call key...', event);
        return;
      }
      Logs().e('LiveKit E2EE Error', event);
    });
    liveKitRoom.addListener(notifyListeners);

    await _createKeyAndShare(index: 0);
    await liveKitRoom.connect(liveKitUrl, liveKitJwt);
  }

  Future<void> close(BuildContext context) async {
    await showFutureLoadingDialog(
      context: context,
      future: () async {
        await value?.disconnect();
        await value?.dispose();
        value = null;
        await room.leaveLiveKitCall();
      },
    );
    if (context.mounted) context.pop();
  }

  @override
  void dispose() {
    _onCallEncryptionKeysSub?.cancel();
    _onCallMembersChanged?.cancel();
    final liveKitRoom = value;
    if (liveKitRoom != null) {
      liveKitRoom.removeListener(notifyListeners);
      if (liveKitRoom.connectionState != lk.ConnectionState.disconnected) {
        liveKitRoom.disconnect();
      }
      liveKitRoom.dispose();
      room.leaveLiveKitCall();
    }
    super.dispose();
  }
}

// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/show_modal_action_popup.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:material_ui/material_ui.dart';

import 'settings_chat_view.dart';

class SettingsChat extends StatefulWidget {
  const SettingsChat({super.key});

  @override
  SettingsChatController createState() => SettingsChatController();
}

class SettingsChatController extends State<SettingsChat> {
  void updateState() => setState(() {});

  /// The home room's display name for the settings tile, or the
  /// not-set label.
  String homeRoomLabel(BuildContext context) {
    final id = AppSettings.homeRoomId.value;
    final room = id.isEmpty ? null : Matrix.of(context).client.getRoomById(id);
    if (room == null) return L10n.of(context).homeRoomNotSet;
    return room.getLocalizedDisplayname(MatrixLocals(L10n.of(context)));
  }

  /// Pick the home room from the most recently active chats.
  Future<void> setHomeRoom() async {
    final rooms = Matrix.of(
      context,
    ).client.rooms.where((room) => !room.isSpace).take(20);
    final value = await showModalActionPopup<String>(
      context: context,
      title: L10n.of(context).homeRoom,
      cancelLabel: L10n.of(context).cancel,
      actions: [
        if (AppSettings.homeRoomId.value.isNotEmpty)
          AdaptiveModalAction(label: L10n.of(context).homeRoomUnset, value: ''),
        ...rooms.map(
          (room) => AdaptiveModalAction(
            label: room.getLocalizedDisplayname(MatrixLocals(L10n.of(context))),
            value: room.id,
          ),
        ),
      ],
    );
    if (value == null) return;
    await AppSettings.homeRoomId.setItem(value);
    updateState();
  }

  @override
  Widget build(BuildContext context) => SettingsChatView(this);
}

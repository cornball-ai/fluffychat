// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/navigation_rail.dart';
import 'package:fluffychat/pages/chat_list/start_chat_fab.dart';
import 'package:material_ui/material_ui.dart';

import 'chat_list_body.dart';

class ChatListView extends StatelessWidget {
  final ChatListController controller;

  const ChatListView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final columnMode = FluffyThemes.isColumnMode(context);
    // One switch per layout, because they answer different questions: on
    // a phone the rail is an extra the user opts into, on a desktop it is
    // the default the user may want their screen back from.
    final showRail = columnMode
        ? AppSettings.displayNavigationRailWide.value
        : AppSettings.displayNavigationRail.value;
    final oneColumnSpacesMode =
        !columnMode && AppSettings.displayNavigationRail.value;
    return PopScope(
      canPop: !controller.isSearchMode && controller.activeSpaceId == null,
      onPopInvokedWithResult: (pop, _) {
        if (pop) return;
        if (controller.activeSpaceId != null) {
          controller.clearActiveSpace();
          return;
        }
        if (controller.isSearchMode) {
          controller.cancelSearch();
          return;
        }
      },
      child: Row(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: AnimatedSize(
              duration: FluffyThemes.animationDuration,
              curve: FluffyThemes.animationCurve,
              child: showRail
                  ? SpacesNavigationRail(
                      activeSpaceId: controller.activeSpaceId,
                      onGoToChats: controller.clearActiveSpace,
                      onGoToSpaceId: controller.setActiveSpace,
                      onSwitchClient: controller.setActiveClient,
                      allChatsClients: controller.roomListClients,
                    )
                  : SizedBox(
                      width: 0,
                      height: MediaQuery.sizeOf(context).height,
                    ),
            ),
          ),
          if (showRail && columnMode)
            Container(width: 1, color: Theme.of(context).dividerColor),

          Expanded(
            child: GestureDetector(
              onTap: FocusManager.instance.primaryFocus?.unfocus,
              excludeFromSemantics: true,
              behavior: HitTestBehavior.translucent,
              child: Scaffold(
                backgroundColor: oneColumnSpacesMode
                    ? Theme.of(context).colorScheme.surfaceContainer
                    : null,
                body: SafeArea(
                  top: oneColumnSpacesMode,
                  bottom: false,
                  left: false,
                  right: false,
                  child: Material(
                    clipBehavior: oneColumnSpacesMode
                        ? Clip.hardEdge
                        : Clip.none,
                    borderRadius: oneColumnSpacesMode
                        ? BorderRadius.only(
                            topLeft: Radius.circular(AppConfig.borderRadius),
                          )
                        : null,
                    color: oneColumnSpacesMode
                        ? Theme.of(context).colorScheme.surface
                        : null,
                    child: ChatListViewBody(controller),
                  ),
                ),
                floatingActionButton:
                    !controller.isSearchMode &&
                        controller.activeSpaceId == null &&
                        !FluffyThemes.isColumnMode(context)
                    ? ValueListenableBuilder(
                        valueListenable: controller.scrolledToTop,
                        builder: (context, scrolledToTop, _) => StartChatFab(
                          extended:
                              scrolledToTop &&
                              !AppSettings.displayNavigationRail.value,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/chat_list/navi_rail_item.dart';
import 'package:fluffychat/pages/chat_list/start_chat_fab.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/stream_extension.dart';
import 'package:fluffychat/widgets/avatar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:matrix/matrix.dart';

class SpacesNavigationRail extends StatelessWidget {
  final String? activeSpaceId;
  final void Function() onGoToChats;
  final void Function(String) onGoToSpaceId;

  /// Switches the active account. When set and more than one account is
  /// logged in, the rail leads with one avatar per account.
  final void Function(Client client)? onSwitchClient;

  /// The accounts whose rooms "all chats" leads to, so its badge counts the
  /// same set. Null means the active account, as it always did.
  final List<Client>? allChatsClients;

  const SpacesNavigationRail({
    required this.activeSpaceId,
    required this.onGoToChats,
    required this.onGoToSpaceId,
    this.onSwitchClient,
    this.allChatsClients,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final matrix = Matrix.of(context);
    final client = matrix.client;
    final onSwitchClient = this.onSwitchClient;
    final accounts = onSwitchClient == null
        ? const <Client>[]
        : matrix.widget.clients.where((c) => c.isLogged()).toList();
    // A rail of one avatar is the avatar menu with extra steps; the account
    // section appears only once there is something to switch between.
    final showAccounts = accounts.length > 1;
    final coloredMode = !FluffyThemes.isColumnMode(context);
    final theme = Theme.of(context);
    return Material(
      color: coloredMode ? theme.colorScheme.surfaceContainer : null,
      child: SafeArea(
        child: StreamBuilder(
          key: ValueKey(client.userID.toString()),
          stream: client.onSync.stream
              .where((s) => s.hasRoomUpdate)
              .rateLimit(const Duration(seconds: 1)),
          builder: (context, _) {
            final allSpaces = client.rooms
                .where((room) => room.isSpace)
                .toList();

            return SizedBox(
              width: FluffyThemes.isColumnMode(context)
                  ? FluffyThemes.navRailWidth
                  : FluffyThemes.navRailWidth - 8,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      scrollDirection: Axis.vertical,
                      itemCount:
                          (showAccounts ? accounts.length + 1 : 0) +
                          allSpaces.length +
                          2,
                      itemBuilder: (context, i) {
                        if (showAccounts) {
                          if (i < accounts.length) {
                            final account = accounts[i];
                            return NaviRailItem(
                              toolTip: account.userID ?? '',
                              isSelected: account == client,
                              onTap: () => onSwitchClient!(account),
                              unreadBadgeFilter: (room) => true,
                              badgeClient: account,
                              icon: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: FutureBuilder<Profile>(
                                  future: account.fetchOwnProfile(),
                                  builder: (context, snapshot) => Avatar(
                                    mxContent: snapshot.data?.avatarUrl,
                                    name:
                                        snapshot.data?.displayName ??
                                        account.userID?.localpart ??
                                        '',
                                    size: 32,
                                  ),
                                ),
                              ),
                            );
                          }
                          if (i == accounts.length) {
                            return SizedBox(
                              height: 12,
                              child: Center(
                                child: SizedBox(
                                  width: 32,
                                  child: Divider(
                                    height: 1,
                                    color: theme.dividerColor,
                                  ),
                                ),
                              ),
                            );
                          }
                          i -= accounts.length + 1;
                        }
                        if (i == 0) {
                          return NaviRailItem(
                            isSelected: activeSpaceId == null,
                            onTap: onGoToChats,
                            // What "all chats" opens is what it counts. In
                            // the unified inbox that is every account, and
                            // counting the active one would report fewer
                            // unreads than the list it leads to shows.
                            badgeClients: allChatsClients,
                            icon: const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Icon(Icons.forum_outlined),
                            ),
                            selectedIcon: const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Icon(Icons.forum),
                            ),
                            toolTip: L10n.of(context).chats,
                            unreadBadgeFilter: (room) => true,
                          );
                        }
                        i--;
                        if (i == allSpaces.length) {
                          return NaviRailItem(
                            isSelected: false,
                            onTap: () => context.go('/rooms/newspace'),
                            icon: const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Icon(Icons.add),
                            ),
                            toolTip: L10n.of(context).createNewSpace,
                          );
                        }
                        final space = allSpaces[i];
                        final displayname = allSpaces[i]
                            .getLocalizedDisplayname(
                              MatrixLocals(L10n.of(context)),
                            );
                        final spaceChildrenIds = space.spaceChildren
                            .map((c) => c.roomId)
                            .toSet();
                        return NaviRailItem(
                          toolTip: displayname,
                          isSelected: activeSpaceId == space.id,
                          onTap: () => onGoToSpaceId(allSpaces[i].id),
                          unreadBadgeFilter: (room) =>
                              spaceChildrenIds.contains(room.id),
                          icon: Avatar(
                            mxContent: allSpaces[i].avatar,
                            name: displayname,
                            //size: 36,
                            shapeBorder: RoundedSuperellipseBorder(
                              side: BorderSide(
                                width: 1,
                                color: Theme.of(context).dividerColor,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppConfig.spaceBorderRadius,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(
                              AppConfig.spaceBorderRadius,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (FluffyThemes.isColumnMode(context))
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: StartChatFab(),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

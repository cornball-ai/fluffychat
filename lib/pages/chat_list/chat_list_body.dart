// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item.dart';
import 'package:fluffychat/pages/chat_list/dummy_chat_list_item.dart';
import 'package:fluffychat/pages/chat_list/search_title.dart';
import 'package:fluffychat/pages/chat_list/space_view.dart';
import 'package:fluffychat/pages/chat_list/unified_rooms.dart';
import 'package:fluffychat/utils/stream_extension.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/public_room_dialog.dart';
import 'package:fluffychat/widgets/avatar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:matrix/matrix.dart';

import '../../config/themes.dart';
import '../../widgets/adaptive_dialogs/user_dialog.dart';
import 'chat_list_header.dart';

class ChatListViewBody extends StatelessWidget {
  final ChatListController controller;

  const ChatListViewBody(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final activeSpace = controller.activeSpaceId;
    if (activeSpace != null) {
      return SpaceView(
        key: ValueKey(activeSpace),
        spaceId: activeSpace,
        onBack: controller.clearActiveSpace,
        onChatTab: controller.onChatTap,
        activeChat: controller.activeChat,
      );
    }
    // One account outside the unified inbox, so everything below reads the
    // same as it did when it named the active client directly.
    final clients = controller.roomListClients;
    final unified = controller.isUnifiedInbox;
    // Computed over the whole set, because what makes one account's badge
    // readable is which other accounts it has to differ from.
    final accountLabels = unified
        ? accountBadgeLabels(
            clients.map(
              (client) =>
                  (clientName: client.clientName, userId: client.userID ?? ''),
            ),
          )
        : const <String, String>{};
    final anySynced = clients.any((client) => client.prevBatch != null);
    final spaces = clients
        .expand((client) => client.rooms)
        .where((r) => r.isSpace);
    // Keyed by account as well as room, or one account's space claims the
    // other account's copy of a room they are both in.
    final spaceDelegateCandidates = <RoomRef, Room>{};
    for (final space in spaces) {
      for (final spaceChild in space.spaceChildren) {
        final roomId = spaceChild.roomId;
        if (roomId == null) continue;
        spaceDelegateCandidates[(space.client.clientName, roomId)] = space;
      }
    }

    final publicRooms = controller.roomSearchResult
        ?.where((result) => result.chunk.roomType != 'm.space')
        .toList();
    final publicSpaces = controller.roomSearchResult
        ?.where((result) => result.chunk.roomType == 'm.space')
        .toList();
    final userSearchResult = controller.userSearchResult;
    const dummyChatCount = 4;
    final filter = controller.searchController.text.toLowerCase();
    return StreamBuilder(
      key: ValueKey(clients.map((client) => client.userID).join(',')),
      stream: controller.roomListSyncStream
          .where((s) => s.hasRoomUpdate)
          .rateLimit(const Duration(seconds: 1)),
      builder: (context, _) {
        final rooms = controller.filteredRooms
            .where(
              (room) =>
                  !AppSettings.hideRoomsInSpaces.value ||
                  spaceDelegateCandidates[(room.client.clientName, room.id)] ==
                      null,
            )
            .toList();

        return CustomScrollView(
          controller: controller.scrollController,
          slivers: [
            ChatListHeader(controller: controller),
            SliverList(
              delegate: SliverChildListDelegate([
                if (controller.isSearchMode) ...[
                  SearchTitle(
                    title: L10n.of(context).publicRooms,
                    icon: const Icon(Icons.explore_outlined),
                  ),
                  PublicRoomsHorizontalList(
                    publicRooms: publicRooms,
                    onOpen: controller.activateAccount,
                  ),
                  SearchTitle(
                    title: L10n.of(context).publicSpaces,
                    icon: const Icon(Icons.workspaces_outlined),
                  ),
                  PublicRoomsHorizontalList(
                    publicRooms: publicSpaces,
                    onOpen: controller.activateAccount,
                  ),
                  SearchTitle(
                    title: L10n.of(context).users,
                    icon: const Icon(Icons.group_outlined),
                  ),
                  AnimatedContainer(
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(),
                    height: userSearchResult == null || userSearchResult.isEmpty
                        ? 0
                        : 106,
                    duration: FluffyThemes.animationDuration,
                    curve: FluffyThemes.animationCurve,
                    child: userSearchResult == null
                        ? null
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: userSearchResult.length,
                            itemBuilder: (context, i) {
                              final result = userSearchResult[i];
                              return _SearchItem(
                                title:
                                    result.profile.displayName ??
                                    result.profile.userId.localpart ??
                                    L10n.of(context).unknownDevice,
                                avatar: result.profile.avatarUrl,
                                client: result.client,
                                onPressed: () {
                                  // The dialog starts direct chats and reads
                                  // the ignore list off the active account,
                                  // so the account that found this person has
                                  // to be the active one before it opens.
                                  controller.activateAccount(result.client);
                                  UserDialog.show(
                                    context: context,
                                    profile: result.profile,
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
                if (clients.any((client) => client.rooms.isNotEmpty) &&
                    !controller.isSearchMode)
                  Container(
                    height: 36 + 8 + 8,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      children: [
                        ...ActiveFilter.values
                            .where((filter) => filter != ActiveFilter.tag)
                            .map(
                              (filter) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: Center(
                                  child: FilterChip(
                                    selected: filter == controller.activeFilter,
                                    onSelected: (_) => controller
                                        .setActiveFilter(filter, null),
                                    label: Text(
                                      filter.toLocalizedString(context),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ...controller.roomTags.entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: Center(
                              child: FilterChip(
                                selected: entry.key == controller.activeTag,
                                onSelected: (_) => controller.setActiveFilter(
                                  ActiveFilter.tag,
                                  entry.key,
                                ),
                                label: Text(entry.key.replaceFirst('u.', '')),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (controller.isSearchMode)
                  SearchTitle(
                    title: L10n.of(context).chats,
                    icon: const Icon(Icons.forum_outlined),
                  ),
                if (anySynced && rooms.isEmpty && !controller.isSearchMode) ...[
                  Column(
                    mainAxisAlignment: .center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          const Column(
                            mainAxisSize: .min,
                            children: [
                              DummyChatListItem(opacity: 0.5, animate: false),
                              DummyChatListItem(opacity: 0.3, animate: false),
                            ],
                          ),
                          Icon(
                            CupertinoIcons.chat_bubble_text_fill,
                            size: 128,
                            color: theme.colorScheme.secondary,
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          clients.every((client) => client.rooms.isEmpty)
                              ? L10n.of(context).noChatsFoundHere
                              : L10n.of(context).noMoreChatsFound,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ]),
            ),
            if (!anySynced)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => DummyChatListItem(
                    opacity: (dummyChatCount - i) / dummyChatCount,
                    animate: true,
                  ),
                  childCount: dummyChatCount,
                ),
              ),
            if (anySynced)
              SliverSafeArea(
                top: false,
                sliver: SliverList.builder(
                  itemCount: rooms.length,
                  itemBuilder: (BuildContext context, int i) {
                    final room = rooms[i];
                    final ref = (room.client.clientName, room.id);
                    final space = spaceDelegateCandidates[ref];
                    return ChatListItem(
                      room,
                      space: space,
                      account: unified
                          ? (
                              // The id names the account, the client name
                              // identifies it: the two part company when the
                              // same account is logged in twice.
                              userId: room.client.userID ?? '',
                              label:
                                  accountLabels[room.client.clientName] ?? '',
                            )
                          : null,
                      key: ValueKey(ref),
                      filter: filter,
                      onTap: () => controller.onChatTap(room),
                      onLongPress: (context) =>
                          controller.chatContextAction(room, context, space),
                      activeChat: controller.isActiveChat(room),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class PublicRoomsHorizontalList extends StatelessWidget {
  const PublicRoomsHorizontalList({
    super.key,
    required this.publicRooms,
    required this.onOpen,
  });

  final List<({PublishedRoomsChunk chunk, Client client})>? publicRooms;

  /// Called before the join dialog opens, to make the finding account the
  /// active one -- the dialog joins, knocks and reports through it.
  final void Function(Client client) onOpen;

  @override
  Widget build(BuildContext context) {
    final publicRooms = this.publicRooms;
    return AnimatedContainer(
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(),
      height: publicRooms == null || publicRooms.isEmpty ? 0 : 106,
      duration: FluffyThemes.animationDuration,
      curve: FluffyThemes.animationCurve,
      child: publicRooms == null
          ? null
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: publicRooms.length,
              itemBuilder: (context, i) {
                final chunk = publicRooms[i].chunk;
                return _SearchItem(
                  title:
                      chunk.name ??
                      chunk.canonicalAlias?.localpart ??
                      L10n.of(context).group,
                  avatar: chunk.avatarUrl,
                  client: publicRooms[i].client,
                  onPressed: () {
                    onOpen(publicRooms[i].client);
                    showAdaptiveDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (c) => PublicRoomDialog(
                        roomAlias: chunk.canonicalAlias ?? chunk.roomId,
                        chunk: chunk,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _SearchItem extends StatelessWidget {
  final String title;
  final Uri? avatar;
  final void Function() onPressed;

  /// Which account found this, so its thumbnail is fetched from a homeserver
  /// that will serve it.
  final Client? client;

  const _SearchItem({
    required this.title,
    this.avatar,
    this.client,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onPressed,
    child: SizedBox(
      width: 84,
      child: Column(
        mainAxisSize: .min,
        children: [
          const SizedBox(height: 8),
          Avatar(client: client, mxContent: avatar, name: title),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
}

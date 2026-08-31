// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:cross_file/cross_file.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/chat_list/chat_list_view.dart';
import 'package:fluffychat/pages/chat_list/unified_rooms.dart';
import 'package:fluffychat/utils/error_reporter.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/room_read_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/room_list_clients.dart';
import 'package:fluffychat/utils/show_scaffold_dialog.dart';
import 'package:fluffychat/utils/show_update_snackbar.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/show_modal_action_popup.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/show_ok_cancel_alert_dialog.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/show_text_input_dialog.dart';
import 'package:fluffychat/widgets/avatar.dart';
import 'package:fluffychat/widgets/future_loading_dialog.dart';
import 'package:fluffychat/widgets/share_scaffold_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_shortcuts_new/flutter_shortcuts_new.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:matrix/matrix.dart' as sdk;
import 'package:matrix/matrix.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../../utils/account_bundles.dart';
import '../../config/setting_keys.dart';
import '../../utils/url_launcher.dart';
import '../../widgets/matrix.dart';

enum ActiveFilter { allChats, unread, groups, messages, tag }

extension LocalizedActiveFilter on ActiveFilter {
  String toLocalizedString(BuildContext context) {
    switch (this) {
      case ActiveFilter.allChats:
        return L10n.of(context).all;
      case ActiveFilter.messages:
        return L10n.of(context).messages;
      case ActiveFilter.unread:
        return L10n.of(context).unread;
      case ActiveFilter.groups:
        return L10n.of(context).groups;
      case ActiveFilter.tag:
        throw 'Tags should not directly be displayed!';
    }
  }
}

class ChatList extends StatefulWidget {
  final String? activeChat;
  final String? activeSpace;
  final bool displayNavigationRail;

  const ChatList({
    super.key,
    required this.activeChat,
    this.activeSpace,
    this.displayNavigationRail = false,
  });

  @override
  ChatListController createState() => ChatListController();
}

class ChatListController extends State<ChatList>
    with TickerProviderStateMixin, RouteAware {
  StreamSubscription? _intentDataStreamSubscription;

  StreamSubscription? _intentFileStreamSubscription;

  late ActiveFilter activeFilter;
  String? activeTag;

  String? _activeSpaceId;

  String? get activeSpaceId => _activeSpaceId;

  /// Enters a space, on [client] when it is not the active account.
  ///
  /// The space view, its children and the rail all resolve against the active
  /// client, so entering another account's space means becoming that account
  /// first. Resolving the id there rather than asserting on the active client
  /// is also what keeps a stale or foreign id from crashing the list.
  Future<void> setActiveSpace(String spaceId, {Client? client}) async {
    final matrix = Matrix.of(context);
    final owner = client ?? matrix.client;
    final space = owner.getRoomById(spaceId);
    if (space == null) return;
    await space.postLoad();
    if (!mounted) return;

    setState(() {
      if (owner != matrix.client) matrix.setActiveClient(owner);
      _activeSpaceId = spaceId;
    });
  }

  /// Makes [client] the active account, and reports whether it had to.
  ///
  /// Every route and dialog that resolves an id -- the chat page, the
  /// archive, the ignore list, the join dialog -- looks it up on the active
  /// client, so anything belonging to another account has to switch before it
  /// opens, or it opens on the wrong account, or on nothing.
  Client? activateAccount(Client client) {
    final matrix = Matrix.of(context);
    if (client == matrix.client) return null;
    setState(() => matrix.setActiveClient(client));
    return client;
  }

  Client? _activateOwner(Room room) => activateAccount(room.client);

  /// Whether [room] is the chat currently open.
  ///
  /// The open chat resolves against the active account, so the id alone
  /// highlights both accounts' rows for a room they are both in.
  bool isActiveChat(Room room) =>
      activeChat == room.id && room.client == Matrix.of(context).client;

  void clearActiveSpace() => setState(() {
    _activeSpaceId = null;
  });

  Future<void> onChatTap(Room room) async {
    final l10n = L10n.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (room.membership == Membership.invite) {
      final joinResult = await showFutureLoadingDialog(
        context: context,
        future: () async {
          final waitForRoom = room.client.waitForRoomInSync(
            room.id,
            join: true,
          );
          await room.join();
          await waitForRoom;
        },
        exceptionContext: ExceptionContext.joinRoom,
      );
      if (joinResult.error != null) return;
    }
    if (!mounted) return;

    if (room.membership == Membership.ban) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.youHaveBeenBannedFromThisChat)),
      );
      return;
    }

    if (room.isSpace) {
      setActiveSpace(room.id, client: room.client);
      return;
    }

    // Switch here rather than leaving it to the `?client=` below, so the rail
    // and the header agree about whose account this is on the same frame the
    // chat opens. The route parameter still carries it, for the cold start
    // where there is no list to have done this.
    final otherClient = _activateOwner(room);

    if (room.membership == Membership.leave) {
      context.go(
        roomRoute(
          room.id,
          prefix: '/rooms/archive',
          clientName: otherClient?.clientName,
        ),
      );
      return;
    }

    context.go(roomRoute(room.id, clientName: otherClient?.clientName));
  }

  bool Function(Room) getRoomFilterByActiveFilter(ActiveFilter activeFilter) {
    switch (activeFilter) {
      case ActiveFilter.allChats:
        return (room) => true;
      case ActiveFilter.messages:
        return (room) => !room.isSpace && room.isDirectChat;
      case ActiveFilter.groups:
        return (room) => !room.isSpace && !room.isDirectChat;
      case ActiveFilter.unread:
        return (room) => room.isUnreadOrInvited;
      case ActiveFilter.tag:
        return (room) => room.tags.keys.contains(activeTag);
    }
  }

  /// The accounts the list draws from. Shared with everything else that has
  /// to agree about which rooms are on screen.
  List<Client> get roomListClients => roomListClientsFor(Matrix.of(context));

  bool get isUnifiedInbox => roomListClients.length > 1;

  /// Rebuilds the list on any shown account's sync. Listening to the active
  /// account alone leaves the other one's rooms frozen: they never reorder
  /// and their unread badges never clear.
  Stream<SyncUpdate> get roomListSyncStream {
    final clients = roomListClients;
    if (clients.length == 1) return clients.single.onSync.stream;
    return StreamGroup.merge(clients.map((client) => client.onSync.stream));
  }

  List<Room> get filteredRooms {
    final clients = roomListClients;
    return mergeAccountRooms(
      clients.map((client) => client.rooms).toList(),
      keep: getRoomFilterByActiveFilter(activeFilter),
      // Every client sorts with the same comparator -- the app never sets a
      // custom one -- so any of them orders the merged list the way each
      // account's own list is already ordered.
      compare: clients.first.defaultRoomSorter,
    );
  }

  bool isSearchMode = false;
  Future<QueryPublicRoomsResponse>? publicRoomsResponse;
  String? searchServer;
  Timer? _coolDown;

  /// Search results with the account that found them.
  ///
  /// Directory search is a request to one homeserver, so with two accounts
  /// there are two directories and a search that asks only the active one
  /// cannot find what the other account can see. Every result carries its
  /// account because acting on one -- joining the room, opening the profile
  /// -- has to happen on the account that can.
  List<({Profile profile, Client client})>? userSearchResult;
  List<({PublishedRoomsChunk chunk, Client client})>? roomSearchResult;

  bool isSearching = false;
  static const String _serverStoreNamespace = 'im.fluffychat.search.server';

  Future<void> setServer() async {
    final matrix = Matrix.of(context);
    final l10n = L10n.of(context);
    final newServer = await showTextInputDialog(
      useRootNavigator: false,
      title: l10n.changeTheHomeserver,
      context: context,
      okLabel: l10n.ok,
      cancelLabel: l10n.cancel,
      prefixText: 'https://',
      hintText: matrix.client.homeserver?.host,
      initialText: searchServer,
      keyboardType: TextInputType.url,
      autocorrect: false,
      validator: (server) =>
          server.contains('.') == true ? null : l10n.invalidServerName,
    );
    if (newServer == null) return;
    if (!mounted) return;
    matrix.store.setString(_serverStoreNamespace, newServer);
    setState(() {
      searchServer = newServer;
    });
    _coolDown?.cancel();
    _coolDown = Timer(const Duration(milliseconds: 500), _search);
  }

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  /// Bumped by the global ctrl+F shortcut, which sits above the router and
  /// so has no other way to reach this State. Only a mounted controller
  /// answers, which is the behaviour we want: on a narrow layout with a chat
  /// open the list is not built at all, so there is no field to focus.
  static final ValueNotifier<int> searchRequests = ValueNotifier(0);

  void _onSearchRequested() {
    if (mounted) startSearch();
  }

  Future<void> _search() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final active = Matrix.of(context).client;
    final server = searchServer;
    // A server override names one homeserver, so it gets asked once, through
    // the active account. Otherwise every account asks its own directory,
    // active first so that a result both of them can see opens on the
    // account already in use.
    final clients = server != null
        ? [active]
        : [active, ...roomListClients.where((client) => client != active)];

    if (!isSearching) {
      setState(() {
        isSearching = true;
      });
    }
    // Read once, here, and carried through every request this fan-out makes.
    // Reading the controller again inside a request means one invocation can
    // come back with rooms for what was typed then and people for what is
    // typed now.
    final query = searchController.text;
    // Typing again supersedes this search. Without the check the slower of
    // two overlapping fan-outs publishes last, whichever one the user is
    // actually waiting for.
    final generation = ++_searchGeneration;

    // Every account searches at once, but they are merged afterwards in the
    // order the accounts were ASKED, not the order they answered. Merging
    // inside the futures gives a room both accounts can see to whichever
    // homeserver replied first, so which account it opens on would come down
    // to the network.
    final answers = await Future.wait(
      clients.map((client) => _searchOneAccount(client, query, server)),
    );
    if (!isSearchMode || !mounted || generation != _searchGeneration) return;

    final rooms = <String, ({PublishedRoomsChunk chunk, Client client})>{};
    final users = <String, ({Profile profile, Client client})>{};
    Object? lastError;
    var failed = 0;
    for (var i = 0; i < clients.length; i++) {
      final answer = answers[i];
      final error = answer.error;
      if (error != null) {
        failed++;
        lastError = error;
        continue;
      }
      // Keyed, so a room or a person both accounts can see appears once,
      // belonging to the earlier account -- the active one.
      for (final chunk in answer.rooms) {
        rooms.putIfAbsent(
          chunk.roomId,
          () => (chunk: chunk, client: clients[i]),
        );
      }
      for (final profile in answer.users) {
        users.putIfAbsent(
          profile.userId,
          () => (profile: profile, client: clients[i]),
        );
      }
    }
    // Only when nothing at all came back is there nothing to show but the
    // error.
    if (failed == clients.length && lastError != null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(lastError.toLocalizedString(context))),
      );
    }
    setState(() {
      isSearching = false;
      roomSearchResult = failed == clients.length
          ? null
          : rooms.values.toList();
      userSearchResult = failed == clients.length
          ? null
          : users.values.toList();
    });
  }

  /// Bumped by every search, so a fan-out that finishes after a newer one
  /// started can tell that it did and keep its results to itself.
  int _searchGeneration = 0;

  /// One account's two directories, or the reason it could not answer -- one
  /// account failing is no reason to throw away what the others found.
  ///
  /// [query] is the whole search: nothing in here reads the text field, which
  /// has moved on by the time the second request goes out.
  Future<
    ({List<PublishedRoomsChunk> rooms, List<Profile> users, Object? error})
  >
  _searchOneAccount(Client client, String query, String? server) async {
    final trimmed = query.trim();
    try {
      final found = await client.queryPublicRooms(
        server: server,
        filter: PublicRoomQueryFilter(genericSearchTerm: trimmed),
        limit: 20,
      );
      final chunks = [...found.chunk];
      if (trimmed.isValidMatrixIdStrict() &&
          trimmed.sigil == '#' &&
          chunks.any((room) => room.canonicalAlias == trimmed) == false) {
        final response = await client.getRoomIdByAlias(trimmed);
        final roomId = response.roomId;
        if (roomId != null) {
          chunks.add(
            PublishedRoomsChunk(
              name: trimmed,
              guestCanJoin: false,
              numJoinedMembers: 0,
              roomId: roomId,
              worldReadable: false,
              canonicalAlias: trimmed,
            ),
          );
        }
      }
      final directory = await client.searchUserDirectory(query, limit: 20);
      return (rooms: chunks, users: directory.results, error: null);
    } catch (e, s) {
      Logs().w('Searching ${client.userID} has crashed', e, s);
      return (rooms: <PublishedRoomsChunk>[], users: <Profile>[], error: e);
    }
  }

  void onSearchEnter(String text, {bool globalSearch = true}) {
    if (text.isEmpty) {
      cancelSearch(unfocus: false);
      return;
    }

    setState(() {
      isSearchMode = true;
    });
    _coolDown?.cancel();
    if (globalSearch) {
      _coolDown = Timer(const Duration(milliseconds: 500), _search);
    }
  }

  void openNavrail() {
    setState(() {
      AppSettings.displayNavigationRail.setItem(
        !AppSettings.displayNavigationRail.value,
      );
    });
  }

  void startSearch() {
    setState(() {
      isSearchMode = true;
    });
    searchFocusNode.requestFocus();
    _coolDown?.cancel();
    _coolDown = Timer(const Duration(milliseconds: 500), _search);
  }

  void cancelSearch({bool unfocus = true}) {
    setState(() {
      searchController.clear();
      isSearchMode = false;
      roomSearchResult = userSearchResult = null;
      isSearching = false;
    });
    if (unfocus) searchFocusNode.unfocus();
  }

  BoxConstraints? snappingSheetContainerSize;

  final ScrollController scrollController = ScrollController();
  final ValueNotifier<bool> scrolledToTop = ValueNotifier(true);

  final StreamController<Client> _clientStream = StreamController.broadcast();

  Stream<Client> get clientStream => _clientStream.stream;

  void addAccountAction() => context.go('/rooms/settings/account');

  void _onScroll() {
    final newScrolledToTop = scrollController.position.pixels <= 0;
    if (newScrolledToTop != scrolledToTop.value) {
      scrolledToTop.value = newScrolledToTop;
    }
  }

  Future<void> editSpace(BuildContext context, String spaceId) async {
    await Matrix.of(context).client.getRoomById(spaceId)!.postLoad();
    if (!context.mounted) return;
    context.push('/rooms/$spaceId/details');
  }

  // Needs to match GroupsSpacesEntry for 'separate group' checking.
  List<Room> get spaces =>
      Matrix.of(context).client.rooms.where((r) => r.isSpace).toList();

  String? get activeChat => widget.activeChat;

  void _processIncomingSharedMedia(List<SharedMediaFile> files) {
    files.removeWhere(
      (file) => file.path.startsWith(AppConfig.deepLinkPrefix) == true,
    );
    if (files.isEmpty) return;

    showScaffoldDialog(
      context: context,
      builder: (context) => ShareScaffoldDialog(
        items: files.map((file) {
          if ({SharedMediaType.text, SharedMediaType.url}.contains(file.type)) {
            return TextShareItem(file.path);
          }
          return FileShareItem(
            XFile(
              file.path.replaceFirst('file://', ''),
              mimeType: file.mimeType,
            ),
          );
        }).toList(),
      ),
    );
  }

  void _initReceiveSharingIntent() {
    if (!PlatformInfos.isMobile) return;

    // For sharing images coming from outside the app while the app is in the memory
    _intentFileStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(_processIncomingSharedMedia, onError: print);

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then(
      _processIncomingSharedMedia,
    );

    if (PlatformInfos.isAndroid) {
      final shortcuts = FlutterShortcuts();
      shortcuts.initialize().then(
        (_) => shortcuts.listenAction((action) {
          if (!mounted) return;
          UrlLauncher(context, action).launchUrl();
        }),
      );
    }
  }

  final List<StreamSubscription> _onRoomTagUpdate = [];

  /// Once per app start: land in the home room, the rolling
  /// conversation the app is "for". A deep link or notification that
  /// already opened a chat wins over it.
  static bool _homeRoomOpenedOnce = false;

  void _maybeOpenHomeRoom() {
    if (_homeRoomOpenedOnce) return;
    _homeRoomOpenedOnce = true;
    final id = AppSettings.homeRoomId.value;
    if (id.isEmpty) return;
    if (widget.activeChat != null) return;
    if (Matrix.of(context).client.getRoomById(id) == null) return;
    context.go('/rooms/$id');
  }

  @override
  void initState() {
    _initReceiveSharingIntent();
    _activeSpaceId = widget.activeSpace;

    scrollController.addListener(_onScroll);
    searchRequests.addListener(_onSearchRequested);
    _waitForFirstSync();
    Matrix.of(context).voipPlugin?.context = context;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        searchServer = Matrix.of(
          context,
        ).store.getString(_serverStoreNamespace);
        Matrix.of(context).backgroundPush?.setupPush(context);
        UpdateNotifier.showUpdateDialog(context);
        _maybeOpenHomeRoom();
      }

      // Workaround for system UI overlay style not applied on app start
      SystemChrome.setSystemUIOverlayStyle(
        Theme.of(context).appBarTheme.systemOverlayStyle!,
      );
    });

    _updateRoomTags();
    // The settings that shape this list -- the unified inbox, the rail -- are
    // written on a page this one is still mounted behind. Rebuilding on the
    // write is what makes the change land whole: the merged rooms, their
    // badges, the tag counts and the set of accounts being listened to all
    // change together instead of at the next sync, one at a time.
    AppSettings.changes.addListener(_onSettingsChanged);
    // Which account is active decides which row is the open one, which
    // spaces the rail shows and whose profile the header carries, and it can
    // change without this list doing it -- a route carrying ?client= switches
    // accounts from inside the router.
    _matrix = Matrix.of(context)
      ..activeClientChanged.addListener(_onActiveClientChanged);
    // Every account, not just the active one, because the unified inbox can
    // be switched on while this list is mounted and the tag chips it draws
    // would otherwise stop updating for the account that was not active when
    // the list was built.
    for (final client in Matrix.of(context).widget.clients) {
      _onRoomTagUpdate.add(
        client.onSync.stream
            .where(
              (syncUpdate) =>
                  syncUpdate.rooms?.join?.values.any(
                    (roomUpdate) =>
                        roomUpdate.accountData?.any(
                          (accountData) => accountData.type == 'm.tag',
                        ) ??
                        false,
                  ) ??
                  false,
            )
            .listen(_updateRoomTags),
      );
    }

    if (roomTags.containsKey(AppSettings.chatFilter.value)) {
      activeFilter = ActiveFilter.tag;
      activeTag = AppSettings.chatFilter.value;
    } else {
      activeFilter =
          ActiveFilter.values.singleWhereOrNull(
            (filter) => AppSettings.chatFilter.value == filter.name,
          ) ??
          ActiveFilter.allChats;
    }

    _processPushHelperCrashReport();

    super.initState();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    _intentFileStreamSubscription?.cancel();
    for (final subscription in _onRoomTagUpdate) {
      subscription.cancel();
    }
    AppSettings.changes.removeListener(_onSettingsChanged);
    _matrix?.activeClientChanged.removeListener(_onActiveClientChanged);
    scrollController.removeListener(_onScroll);
    searchRequests.removeListener(_onSearchRequested);
    searchController.dispose();
    searchFocusNode.dispose();
    scrollController.dispose();
    scrolledToTop.dispose();
    _clientStream.close();
    super.dispose();
  }

  void _processPushHelperCrashReport() {
    final store = Matrix.of(context).store;
    final report = store.getStringList(AppConfig.pushHelperCrashReportKey);
    if (report == null) return;
    store.remove(AppConfig.pushHelperCrashReportKey);
    ErrorReporter(
      context,
      'Push Helper has been crashed',
    ).onErrorCallback(report.first, StackTrace.fromString(report.last));
  }

  Future<void> chatContextAction(
    Room room,
    BuildContext posContext, [
    Room? space,
  ]) async {
    final overlay =
        Overlay.of(posContext).context.findRenderObject() as RenderBox;

    final button = posContext.findRenderObject() as RenderBox;

    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(const Offset(0, -65), ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero) + const Offset(-50, 0),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final spacesWithPowerLevels = room.client.rooms
        .where(
          (space) =>
              space.isSpace &&
              space.canChangeStateEvent(EventTypes.SpaceChild) &&
              !space.spaceChildren.any((c) => c.roomId == room.id),
        )
        .toList();

    var action = await showMenu<ChatContextAction>(
      context: posContext,
      position: position,
      items: [
        if (space != null)
          PopupMenuItem(
            value: ChatContextAction.goToSpace,
            child: Row(
              mainAxisSize: .min,
              children: [
                Avatar(
                  // The space belongs to the room's account, which is not
                  // necessarily the active one; MxcImage falls back to the
                  // active client and would fetch the media on an account
                  // that cannot see it.
                  client: space.client,
                  mxContent: space.avatar,
                  size: Avatar.defaultSize / 2,
                  name: space.getLocalizedDisplayname(),
                ),
                const SizedBox(width: 12),
                Text(
                  L10n.of(context).goToSpace(space.getLocalizedDisplayname()),
                ),
              ],
            ),
          ),
        if (room.membership == Membership.join) ...[
          PopupMenuItem(
            value: ChatContextAction.mute,
            child: Row(
              mainAxisSize: .min,
              children: [
                Icon(
                  room.pushRuleState == PushRuleState.notify
                      ? Icons.notifications_off_outlined
                      : Icons.notifications_off,
                ),
                const SizedBox(width: 12),
                Text(
                  room.pushRuleState == PushRuleState.notify
                      ? L10n.of(context).muteChat
                      : L10n.of(context).unmuteChat,
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: ChatContextAction.markUnread,
            child: Row(
              mainAxisSize: .min,
              children: [
                // Offer "mark as read" whenever the room is showing as unread
                // by any measure, not only when it was manually marked. A room
                // left unread by actual messages is the case you most want the
                // action for, and it used to be the one case it was missing.
                Icon(
                  room.showsAsUnread
                      ? Icons.mark_as_unread
                      : Icons.mark_as_unread_outlined,
                ),
                const SizedBox(width: 12),
                Text(
                  room.showsAsUnread
                      ? L10n.of(context).markAsRead
                      : L10n.of(context).markAsUnread,
                ),
              ],
            ),
          ),
          if (!room.isLowPriority)
            PopupMenuItem(
              value: ChatContextAction.favorite,
              child: Row(
                mainAxisSize: .min,
                children: [
                  Icon(
                    room.isFavourite ? Icons.push_pin : Icons.push_pin_outlined,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    room.isFavourite
                        ? L10n.of(context).unpin
                        : L10n.of(context).pin,
                  ),
                ],
              ),
            ),
        ],
        PopupMenuItem(
          value: ChatContextAction.leave,
          child: Row(
            mainAxisSize: .min,
            children: [
              Icon(
                Icons.delete_outlined,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 12),
              Text(
                room.membership == Membership.invite
                    ? L10n.of(context).delete
                    : L10n.of(context).leave,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
        ),
        if (room.membership == Membership.invite)
          PopupMenuItem(
            value: ChatContextAction.block,
            child: Row(
              mainAxisSize: .min,
              children: [
                Icon(
                  Icons.block_outlined,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 12),
                Text(
                  L10n.of(context).block,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        if (room.membership == Membership.join)
          PopupMenuItem(
            value: ChatContextAction.showMore,
            child: Row(
              mainAxisSize: .min,
              children: [
                Icon(Icons.adaptive.more_outlined),
                const SizedBox(width: 12),
                Text(L10n.of(context).more),
              ],
            ),
          ),
      ],
    );
    if (!posContext.mounted || !mounted) return;
    if (action == ChatContextAction.showMore) {
      action = await showMenu<ChatContextAction>(
        context: posContext,
        position: position,
        items: [
          if (!room.isFavourite)
            PopupMenuItem(
              value: ChatContextAction.lowPriority,
              child: Row(
                mainAxisSize: .min,
                children: [
                  Icon(
                    room.isLowPriority
                        ? Icons.low_priority
                        : Icons.low_priority_outlined,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    room.isLowPriority
                        ? L10n.of(context).unsetLowPriority
                        : L10n.of(context).setLowPriority,
                  ),
                ],
              ),
            ),
          if (activeTag == null)
            PopupMenuItem(
              value: ChatContextAction.addTag,
              child: Row(
                mainAxisSize: .min,
                children: [
                  Icon(Icons.bookmark_add_outlined),
                  const SizedBox(width: 12),
                  Text(L10n.of(context).addTag),
                ],
              ),
            )
          else
            PopupMenuItem(
              value: ChatContextAction.removeTag,
              child: Row(
                mainAxisSize: .min,
                children: [
                  Icon(Icons.bookmark_remove_outlined),
                  const SizedBox(width: 12),
                  Text(L10n.of(context).removeTag),
                ],
              ),
            ),
          if (spacesWithPowerLevels.isNotEmpty)
            PopupMenuItem(
              value: ChatContextAction.addToSpace,
              child: Row(
                mainAxisSize: .min,
                children: [
                  const Icon(Icons.group_work_outlined),
                  const SizedBox(width: 12),
                  Text(L10n.of(context).addToSpace),
                ],
              ),
            ),
        ],
      );
    }

    if (action == null) return;
    if (!mounted) return;

    switch (action) {
      case ChatContextAction.goToSpace:
        setActiveSpace(space!.id, client: space.client);
        return;
      case ChatContextAction.favorite:
        await showFutureLoadingDialog(
          context: context,
          future: () => room.setFavourite(!room.isFavourite),
        );
        return;
      case ChatContextAction.markUnread:
        await showFutureLoadingDialog(
          context: context,
          future: () =>
              room.showsAsUnread ? room.markRead() : room.markUnread(true),
        );
        return;
      case ChatContextAction.mute:
        await showFutureLoadingDialog(
          context: context,
          future: () => room.setPushRuleState(
            room.pushRuleState == PushRuleState.notify
                ? PushRuleState.mentionsOnly
                : PushRuleState.notify,
          ),
        );
        return;
      case ChatContextAction.block:
        final inviteEvent = room.getState(
          EventTypes.RoomMember,
          room.client.userID!,
        );
        // The ignore list is per account and edits the active one, so
        // blocking from another account's invite has to switch first or it
        // ignores the user on the wrong account and leaves the invite there.
        _activateOwner(room);
        context.go(
          '/rooms/settings/security/ignorelist',
          extra: inviteEvent?.senderId,
        );
      case ChatContextAction.leave:
        final confirmed = await showOkCancelAlertDialog(
          context: context,
          title: L10n.of(context).areYouSure,
          message: L10n.of(context).archiveRoomDescription,
          okLabel: L10n.of(context).leave,
          cancelLabel: L10n.of(context).cancel,
          isDestructive: true,
        );
        if (confirmed == OkCancelResult.cancel) return;
        if (!mounted) return;

        await showFutureLoadingDialog(context: context, future: room.leave);

        return;
      case ChatContextAction.addToSpace:
        final space = await showModalActionPopup(
          context: context,
          title: L10n.of(context).space,
          actions: spacesWithPowerLevels
              .map(
                (space) => AdaptiveModalAction(
                  value: space,
                  label: space.getLocalizedDisplayname(
                    MatrixLocals(L10n.of(context)),
                  ),
                ),
              )
              .toList(),
        );
        if (space == null) return;
        if (!mounted) return;
        await showFutureLoadingDialog(
          context: context,
          future: () => space.setSpaceChild(room.id),
        );
      case ChatContextAction.lowPriority:
        await showFutureLoadingDialog(
          context: context,
          future: () => room.setLowPriority(!room.isLowPriority),
        );
        return;
      case ChatContextAction.addTag:
        final existingTags = List.of(roomTags.keys);
        existingTags.removeWhere(room.tags.containsKey);
        String? tag;
        if (existingTags.isNotEmpty) {
          tag = await showModalActionPopup<String?>(
            context: context,
            actions: [
              ...existingTags.map((tag) {
                final displayTag = tag.replaceFirst('u.', '');
                return AdaptiveModalAction(
                  label: displayTag,
                  value: displayTag,
                );
              }),
              AdaptiveModalAction(
                label: L10n.of(context).createNewTag,
                value: null,
              ),
            ],
          );
          if (!mounted) return;
        }
        tag ??= await showTextInputDialog(
          context: context,
          title: L10n.of(context).addTag,
          hintText: L10n.of(context).tagName,
        );
        final newTag = tag;
        if (!mounted) return;
        if (newTag == null) return;
        await showFutureLoadingDialog(
          context: context,
          future: () => room.addTag('u.$newTag'),
        );
        return;
      case ChatContextAction.removeTag:
        await showFutureLoadingDialog(
          context: context,
          future: () => room.removeTag(activeTag!),
        );
        return;
      case ChatContextAction.showMore:
        throw ('Should not be handled!');
    }
  }

  Map<String, int> roomTags = {};

  /// A settings write recomputes the tags and, through the setState inside,
  /// rebuilds the list against whatever the setting now says.
  void _onSettingsChanged() {
    if (mounted) _updateRoomTags();
  }

  /// Held from initState so the listener can be removed without reaching for
  /// a BuildContext during dispose.
  MatrixState? _matrix;

  void _onActiveClientChanged() {
    if (mounted) setState(() {});
  }

  void _updateRoomTags([_]) {
    roomTags.clear();
    for (final client in roomListClients) {
      for (final room in client.rooms) {
        for (final tag in room.tags.keys) {
          if (tag.startsWith('u.')) roomTags[tag] = (roomTags[tag] ?? 0) + 1;
        }
      }
    }
    setState(() {
      if (activeTag != null && !roomTags.keys.contains(activeTag)) {
        activeTag = null;
        activeFilter = ActiveFilter.allChats;
      }
    });
  }

  Future<void> setStatus() async {
    final l10n = L10n.of(context);
    final client = Matrix.of(context).client;
    final currentPresence = await client.fetchCurrentPresence(client.userID!);
    if (!mounted) return;
    final input = await showTextInputDialog(
      useRootNavigator: false,
      context: context,
      title: l10n.setStatus,
      message: l10n.leaveEmptyToClearStatus,
      okLabel: l10n.ok,
      cancelLabel: l10n.cancel,
      hintText: l10n.statusExampleMessage,
      maxLines: 6,
      minLines: 1,
      maxLength: 255,
      initialText: currentPresence.statusMsg,
    );
    if (input == null) return;
    if (!mounted) return;
    await showFutureLoadingDialog(
      context: context,
      future: () => client.setPresence(
        client.userID!,
        PresenceType.online,
        statusMsg: input,
      ),
    );
  }

  bool waitForFirstSync = false;

  Future<void> _waitForFirstSync() async {
    final router = GoRouter.of(context);
    final client = Matrix.of(context).client;
    await client.roomsLoading;
    await client.accountDataLoading;
    await client.userDeviceKeysLoading;
    if (client.prevBatch == null) {
      await client.onSyncStatus.stream.firstWhere(
        (status) => status.status == SyncStatus.finished,
      );

      if (!mounted) return;
      setState(() {
        waitForFirstSync = true;
      });
    }
    if (!mounted) return;
    setState(() {
      waitForFirstSync = true;
    });

    if (client.userDeviceKeys[client.userID!]?.deviceKeys.values.any(
          (device) => !device.verified && !device.blocked,
        ) ??
        false) {
      late final ScaffoldFeatureController controller;
      final theme = Theme.of(context);
      controller = ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 15),
          showCloseIcon: true,
          backgroundColor: theme.colorScheme.errorContainer,
          closeIconColor: theme.colorScheme.onErrorContainer,
          content: Text(
            L10n.of(context).oneOfYourDevicesIsNotVerified,
            style: TextStyle(color: theme.colorScheme.onErrorContainer),
          ),
          action: SnackBarAction(
            onPressed: () {
              controller.close();
              router.go('/rooms/settings/devices');
            },
            textColor: theme.colorScheme.onErrorContainer,
            label: L10n.of(context).settings,
          ),
        ),
      );
    }
  }

  void setActiveFilter(ActiveFilter filter, String? tag) {
    if (filter == ActiveFilter.tag && tag == null) {
      throw ('Must set a tag when setting filter to tags!');
    }
    setState(() {
      activeTag = tag;
      activeFilter = filter;
    });
    AppSettings.chatFilter.setItem(
      filter == ActiveFilter.tag ? tag! : filter.name,
    );
  }

  void setActiveClient(Client client) {
    context.go('/rooms');
    setState(() {
      activeFilter = ActiveFilter.allChats;
      _activeSpaceId = null;
      Matrix.of(context).setActiveClient(client);
    });
    _clientStream.add(client);
  }

  void setActiveBundle(String bundle) {
    context.go('/rooms');
    setState(() {
      _activeSpaceId = null;
      Matrix.of(context).activeBundle = bundle;
      if (!Matrix.of(
        context,
      ).currentBundle!.any((client) => client == Matrix.of(context).client)) {
        Matrix.of(
          context,
        ).setActiveClient(Matrix.of(context).currentBundle!.first);
      }
    });
  }

  Future<void> editBundlesForAccount(
    String? userId,
    String? activeBundle,
  ) async {
    final l10n = L10n.of(context);
    final client = Matrix.of(
      context,
    ).widget.clients[Matrix.of(context).getClientIndexByMatrixId(userId!)];
    final action = await showModalActionPopup<EditBundleAction>(
      context: context,
      title: L10n.of(context).editBundlesForAccount,
      cancelLabel: L10n.of(context).cancel,
      actions: [
        AdaptiveModalAction(
          value: EditBundleAction.addToBundle,
          label: L10n.of(context).addToBundle,
        ),
        if (activeBundle != client.userID)
          AdaptiveModalAction(
            value: EditBundleAction.removeFromBundle,
            label: L10n.of(context).removeFromBundle,
          ),
      ],
    );
    if (action == null) return;
    switch (action) {
      case EditBundleAction.addToBundle:
        if (!mounted) return;
        final bundle = await showTextInputDialog(
          context: context,
          title: l10n.bundleName,
          hintText: l10n.bundleName,
        );
        if (bundle == null || bundle.isEmpty || bundle.isEmpty) return;
        if (!mounted) return;
        await showFutureLoadingDialog(
          context: context,
          future: () => client.setAccountBundle(bundle),
        );
        break;
      case EditBundleAction.removeFromBundle:
        if (!mounted) return;
        await showFutureLoadingDialog(
          context: context,
          future: () => client.removeFromAccountBundle(activeBundle!),
        );
    }
  }

  bool get displayBundles =>
      Matrix.of(context).hasComplexBundles &&
      Matrix.of(context).accountBundles.keys.length > 1;

  String? get secureActiveBundle {
    if (Matrix.of(context).activeBundle == null ||
        !Matrix.of(
          context,
        ).accountBundles.keys.contains(Matrix.of(context).activeBundle)) {
      return Matrix.of(context).accountBundles.keys.first;
    }
    return Matrix.of(context).activeBundle;
  }

  void resetActiveBundle() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        Matrix.of(context).activeBundle = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) => ChatListView(this);

  Future<void> dehydrate() => Matrix.of(context).dehydrateAction(context);
}

enum EditBundleAction { addToBundle, removeFromBundle }

enum ChatContextAction {
  goToSpace,
  favorite,
  lowPriority,
  addTag,
  removeTag,
  markUnread,
  mute,
  leave,
  addToSpace,
  block,
  showMore,
}

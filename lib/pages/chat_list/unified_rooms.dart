// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

// What the unified inbox decides, kept free of Matrix types so the ordering,
// the identity and the route can be tested without a client.

/// Identifies one row of the list.
///
/// A room id is unique on a homeserver, but two accounts can both be joined
/// to the same room, and then the list holds two rows that are not the same
/// row: their own unread counts, their own read markers, and only one of them
/// is the one that is open. Widget keys, the space lookup and the active
/// highlight all need both halves, or they silently merge the two.
typedef RoomRef = (String clientName, String roomId);

/// The two letters a badge shows for [userId], as a name for `Avatar` to
/// split: the localpart's initial and the homeserver's.
///
/// One letter is not enough either way round. Two accounts on one homeserver
/// share a domain initial, two accounts of the same person share a localpart
/// initial, and colour cannot break the tie -- the palette has twelve hues,
/// so a collision is ordinary rather than unlucky.
String accountBadgeLabel(String? userId) {
  if (userId == null || userId.isEmpty) return '';
  final colon = userId.indexOf(':');
  if (colon < 0) return userId;
  final localpart = userId.substring(0, colon).replaceFirst('@', '');
  final domain = userId.substring(colon + 1);
  if (localpart.isEmpty || domain.isEmpty) return '';
  return '$localpart $domain';
}

/// Every shown account's rooms in one order.
///
/// Each account arrives already sorted by its own client, so concatenating
/// them interleaves two orders: a matrix.org DM from this morning lands under
/// a cornball room from last week. Re-running one comparator over the whole
/// thing is what makes it a single list.
///
/// A single account is returned filtered and otherwise untouched -- no
/// re-sort -- so with the setting off the list is exactly the list the SDK
/// already built.
List<T> mergeAccountRooms<T>(
  List<List<T>> perAccount, {
  required bool Function(T) keep,
  required Comparator<T> compare,
}) {
  if (perAccount.length == 1) return perAccount.single.where(keep).toList();
  return perAccount.expand((rooms) => rooms).where(keep).toList()
    ..sort(compare);
}

/// Where tapping a room goes.
///
/// [clientName] names the owning account when it is not the active one, and
/// is left null when it is. The router's page builder reads `?client=` and
/// switches the active account before the chat page resolves the room id
/// against it, so a room belonging to another account opens rather than
/// coming up empty.
String roomRoute(
  String roomId, {
  String? clientName,
  String prefix = '/rooms',
}) {
  final route = '$prefix/$roomId';
  if (clientName == null) return route;
  return '$route?client=${Uri.encodeQueryComponent(clientName)}';
}

// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

// The two decisions the unified inbox makes, kept free of Matrix types so
// the ordering and the route can be tested without a client.

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

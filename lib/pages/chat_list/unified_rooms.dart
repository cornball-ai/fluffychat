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

/// What each account's badge draws, keyed by client name.
///
/// By client and not by user ID, because the same account can be logged in
/// twice: two clients that share an id are still two rows, and a map keyed on
/// the id collapses them into one entry that both rows then read -- the same
/// badge on both, which is the thing this is here to prevent.
///
/// No fixed rule on a single id can be trusted here, because every short one
/// collides with some other id: `@troy:cornball.ai` and `@troy:matrix.org`
/// share a localpart, `@troy:matrix.org` and `@tom:matrix.org` share both
/// initials. Colour cannot break the tie either -- the palette holds twelve
/// hues, so a collision there is ordinary rather than unlucky.
///
/// So the label is computed against the accounts that are actually in the
/// list. Each rule below is tried in turn and the first that gives every
/// account its own label wins, which keeps the badge as short as these
/// particular accounts allow: one letter for two different people, two when
/// it takes the homeserver or a second letter to separate them.
Map<String, String> accountBadgeLabels(
  Iterable<({String clientName, String userId})> accounts,
) {
  final list = accounts.toList(growable: false);
  final parts = [for (final account in list) _splitUserId(account.userId)];
  for (final rule in _badgeRules) {
    if (parts.any((part) => part == null)) break;
    final labels = {
      for (var i = 0; i < list.length; i++)
        list[i].clientName: rule(parts[i]!.localpart, parts[i]!.domain),
    };
    if (labels.length == list.length &&
        labels.values.toSet().length == list.length) {
      return labels;
    }
  }
  // Nothing this short separates them, an id was not a user ID at all, or the
  // same account is logged in twice. A badge you cannot tell from the one
  // above it is worse than a number.
  return {for (var i = 0; i < list.length; i++) list[i].clientName: '${i + 1}'};
}

/// Matrix restricts both halves to ASCII, so a code unit is a character here.
({String localpart, String domain})? _splitUserId(String userId) {
  final colon = userId.indexOf(':');
  if (colon < 0) return null;
  final localpart = userId.substring(0, colon).replaceFirst('@', '');
  final domain = userId.substring(colon + 1);
  if (localpart.isEmpty || domain.isEmpty) return null;
  return (localpart: localpart, domain: domain);
}

const _badgeRules = <String Function(String localpart, String domain)>[
  _initial,
  _initialAndServer,
  _twoLetters,
];

String _initial(String localpart, String domain) => localpart.substring(0, 1);

String _initialAndServer(String localpart, String domain) =>
    '${localpart.substring(0, 1)}${domain.substring(0, 1)}';

String _twoLetters(String localpart, String domain) =>
    localpart.length >= 2 ? localpart.substring(0, 2) : localpart;

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

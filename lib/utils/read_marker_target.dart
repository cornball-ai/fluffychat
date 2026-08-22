// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Chooses the event a read marker should be placed on.
///
/// The preference is the newest event that would have notified, so the marker
/// lands where the unread count came from. But a room can be unread without
/// anything in it notifying: `.m.rule.suppress_notices` means an `m.notice`
/// never notifies, so a room whose recent traffic is all notices -- which is
/// how bots and bridges usually talk -- has no notifying event at all.
///
/// Without a fallback that room can never be marked read. No receipt is sent,
/// `hasNewMessages` stays true because the newest event still has no receipt
/// from us, and the unread badge survives being read, reopened, and read
/// again. Reading a room has to clear it whether or not its contents would
/// have pinged you.
///
/// Generic over the event type so the choice can be tested without standing up
/// a Matrix client. [events] must be newest-first, as the timeline is.
String? pickReadMarkerEvent<T>({
  required Iterable<T> events,
  required bool Function(T event) notifies,
  required bool Function(T event) isDisplayable,
  required String? Function(T event) idOf,
}) {
  for (final event in events) {
    if (!notifies(event)) continue;
    final id = idOf(event);
    if (id != null) return id;
  }

  for (final event in events) {
    if (!isDisplayable(event)) continue;
    final id = idOf(event);
    if (id != null) return id;
  }

  return null;
}

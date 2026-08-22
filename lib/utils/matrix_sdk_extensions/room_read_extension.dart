// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:matrix/matrix.dart';

extension RoomReadExtension on Room {
  /// Whether the room is currently drawn as unread.
  ///
  /// [Room.isUnread] alone is not it: that is `notificationCount > 0 ||
  /// markedUnread`, and a room can show as unread on [Room.hasNewMessages]
  /// with neither. That happens whenever the newest event carries no receipt
  /// from us but never raised a notification -- an `m.notice`, or anything in
  /// a muted room. This matches what the badge draws, so a "mark as read"
  /// offered on the strength of it can actually clear it.
  bool get showsAsUnread => isUnread || hasNewMessages;

  /// Marks the room read: clears the manual flag and sends a receipt.
  ///
  /// Both halves are needed. [markUnread] only touches the `m.marked_unread`
  /// account data, so on its own it leaves a room that is unread because of
  /// real messages exactly as unread as it found it. And the receipt has to
  /// land on the newest event specifically, because [Room.hasNewMessages] is
  /// computed from the receipts on that event -- a receipt anywhere earlier
  /// leaves the room drawn as unread.
  Future<void> markRead() async {
    if (markedUnread) await markUnread(false);

    final eventId = lastEvent?.eventId;
    if (eventId == null || !eventId.isValidMatrixIdStrict()) return;

    await setReadMarker(eventId, mRead: eventId);
  }
}

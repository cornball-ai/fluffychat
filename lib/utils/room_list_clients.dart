// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:matrix/matrix.dart';

/// The accounts a room list draws from: every logged-in one when the unified
/// inbox is on, otherwise the active one alone.
///
/// Here rather than on the chat list because the chat list is not the only
/// thing that has to agree with it. A keyboard shortcut that jumps to the
/// nth chat is answering a question about the same list, and when it worked
/// this out for itself it landed on a different answer -- ctrl+3 went to the
/// third chat of the active account while the screen showed a third chat
/// belonging to another one.
List<Client> roomListClientsFor(MatrixState matrix) {
  if (!AppSettings.unifiedInbox.value) return [matrix.client];
  final clients = matrix.widget.clients.where((c) => c.isLogged()).toList();
  // One account is not a unified anything, and taking the merge path would
  // re-sort a list the SDK has already ordered.
  return clients.length > 1 ? clients : [matrix.client];
}

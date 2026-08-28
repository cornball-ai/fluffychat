// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/pages/chat_list/account_badge.dart';
import 'package:fluffychat/pages/chat_list/unified_rooms.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// What the badge puts on screen, not what the helper returns.
///
/// The two came apart once already: the label was a full name and `Avatar`
/// rendered the initial of its first word and its last, so `matrix.org` drew
/// as a lone "m" and every account on that server got the same badge while
/// the helper's own test passed on the full string.
Future<List<String>> _render(WidgetTester tester, List<String> userIds) async {
  // One client per entry, which is what the list passes: two of them can
  // share a user ID when the same account is logged in twice.
  final accounts = [
    for (var i = 0; i < userIds.length; i++)
      (clientName: 'client$i', userId: userIds[i]),
  ];
  final labels = accountBadgeLabels(accounts);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            for (final account in accounts)
              AccountBadge(
                userId: account.userId,
                label: labels[account.clientName]!,
              ),
          ],
        ),
      ),
    ),
  );
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data ?? '')
      .toList();
}

void main() {
  testWidgets('two people draw their own initial', (tester) async {
    expect(await _render(tester, ['@troy:matrix.org', '@dirk:matrix.org']), [
      't',
      'd',
    ]);
  });

  testWidgets('one person on two homeservers draws the server', (tester) async {
    expect(
      await _render(tester, ['@troy:cornball.ai', '@troyhernandez:matrix.org']),
      ['tc', 'tm'],
    );
  });

  testWidgets('two localparts sharing an initial draw a second letter', (
    tester,
  ) async {
    // Both are "t" and both servers are "m", so a fixed rule draws "tm"
    // twice. This is the case the rendered check exists for.
    final drawn = await _render(tester, [
      '@troy:matrix.org',
      '@tom:matrix.org',
    ]);
    expect(drawn, ['tr', 'to']);
    expect(drawn.toSet().length, drawn.length);
  });

  testWidgets('every badge on screen is distinct', (tester) async {
    for (final accounts in const [
      ['@troy:matrix.org', '@tom:matrix.org', '@dirk:matrix.org'],
      ['@troy:matrix.org', '@troyd:matrix.org'],
      ['@troy:cornball.ai', '@troy:matrix.org'],
      ['', '@troy:'],
      // The same account logged in twice: one user ID, two rows.
      ['@troy:matrix.org', '@troy:matrix.org'],
    ]) {
      final drawn = await _render(tester, accounts);
      expect(
        drawn.toSet().length,
        drawn.length,
        reason: 'two of $accounts drew the same badge: $drawn',
      );
    }
  });

  testWidgets('the tooltip names the account in full', (tester) async {
    await _render(tester, ['@troy:cornball.ai', '@troyhernandez:matrix.org']);
    expect(
      tester
          .widgetList<Tooltip>(find.byType(Tooltip))
          .map((tooltip) => tooltip.message),
      ['@troy:cornball.ai', '@troyhernandez:matrix.org'],
    );
  });
}

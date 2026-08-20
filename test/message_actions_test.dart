// SPDX-FileCopyrightText: 2026-Present cornball.ai
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/pages/chat/events/message_actions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The hover row sits beside the bubble and holds its width even when it is
/// invisible, so that the bubble does not jump sideways as the pointer
/// crosses it. That reserved-but-hidden state is the dangerous one: if it
/// still took pointer events it would swallow clicks in a strip of apparently
/// empty space next to every message, and nothing would raise so much as a
/// warning. Pumping the real timeline needs the Matrix provider, whose boot
/// never settles under flutter_tester, so this exercises the row directly.
void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  group('MessageHoverActions', () {
    testWidgets('reserves its width whether or not it is visible', (
      tester,
    ) async {
      final actions = [
        MessageAction(icon: Icons.reply_outlined, label: 'Reply', onTap: () {}),
        MessageAction(icon: Icons.more_horiz, label: 'More', onTap: () {}),
      ];

      await tester.pumpWidget(
        wrap(MessageHoverActions(visible: false, actions: actions)),
      );
      final hidden = tester.getSize(find.byType(MessageHoverActions));

      await tester.pumpWidget(
        wrap(MessageHoverActions(visible: true, actions: actions)),
      );
      await tester.pumpAndSettle();
      final shown = tester.getSize(find.byType(MessageHoverActions));

      expect(hidden, shown);
      expect(hidden.width, greaterThan(0));
    });

    testWidgets('takes no pointer events while hidden', (tester) async {
      var taps = 0;
      final actions = [
        MessageAction(
          icon: Icons.reply_outlined,
          label: 'Reply',
          onTap: () => taps++,
        ),
      ];

      await tester.pumpWidget(
        wrap(MessageHoverActions(visible: false, actions: actions)),
      );
      await tester.tap(find.byIcon(Icons.reply_outlined), warnIfMissed: false);
      await tester.pump();
      expect(taps, 0, reason: 'a hidden row swallowed a click');

      await tester.pumpWidget(
        wrap(MessageHoverActions(visible: true, actions: actions)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.reply_outlined));
      await tester.pump();
      expect(taps, 1, reason: 'a visible row ignored a click');
    });

    testWidgets('renders one button per action, destructive ones in error', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          MessageHoverActions(
            visible: true,
            actions: [
              MessageAction(
                icon: Icons.reply_outlined,
                label: 'Reply',
                onTap: () {},
              ),
              MessageAction(
                icon: Icons.delete_outlined,
                label: 'Delete',
                onTap: () {},
                isDestructive: true,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(IconButton), findsNWidgets(2));
      final context = tester.element(find.byType(MessageHoverActions));
      final scheme = Theme.of(context).colorScheme;
      final destructive = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.delete_outlined),
          matching: find.byType(IconButton),
        ),
      );
      expect(destructive.color, scheme.error);
    });
  });

  group('globalRectOf', () {
    testWidgets('reports the widget rectangle in screen coordinates', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const SizedBox(width: 120, height: 40, child: Placeholder())),
      );
      final rect = globalRectOf(tester.element(find.byType(Placeholder)));
      expect(rect.size, const Size(120, 40));
      expect(rect, tester.getRect(find.byType(Placeholder)));
    });

    testWidgets('degrades to a zero rect instead of throwing', (tester) async {
      // A long-press that races a rebuild must not take the app down; a
      // useless hole in the scrim is the acceptable failure.
      await tester.pumpWidget(wrap(const SizedBox.shrink()));
      final element = tester.element(find.byType(MaterialApp));
      expect(() => globalRectOf(element), returnsNormally);
    });
  });
}

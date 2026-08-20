// SPDX-FileCopyrightText: 2026-Present cornball.ai
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The InputBar wires a Focus/onKeyEvent wrapper around the composer's
/// TextField so that tab accepts the highlighted autocomplete
/// suggestion instead of traversing focus. Pumping the real InputBar
/// needs the Matrix provider widget, whose boot never settles under
/// flutter_tester (upstream's own widget tests are all commented out
/// for the same reason), so this exercises the identical wrapper
/// around a plain Autocomplete: same field wiring, same key handling,
/// same onFieldSubmitted path into RawAutocomplete.
void main() {
  testWidgets('tab accepts the highlighted suggestion, not traversal', (
    tester,
  ) async {
    const options = ['alice', 'albert', 'bob'];
    final controller = TextEditingController();
    final focusNode = FocusNode(debugLabel: 'composer');

    List<String> getSuggestions(TextEditingValue value) {
      final match = RegExp(r'(?:\s|^)@([-\w]*)$').firstMatch(value.text);
      if (match == null) return const [];
      return options
          .where((o) => o.contains(match[1]!.toLowerCase()))
          .toList();
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Autocomplete<String>(
                focusNode: focusNode,
                textEditingController: controller,
                optionsBuilder: getSuggestions,
                displayStringForOption: (o) => '@$o ',
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) =>
                        Focus(
                          onKeyEvent: (node, event) {
                            if (event is! KeyUpEvent &&
                                event.logicalKey == LogicalKeyboardKey.tab &&
                                getSuggestions(controller.value).isNotEmpty) {
                              onFieldSubmitted();
                              return KeyEventResult.handled;
                            }
                            return KeyEventResult.ignored;
                          },
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                          ),
                        ),
              ),
              const TextButton(onPressed: null, child: Text('after')),
            ],
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    await tester.enterText(find.byType(TextField), '@al');
    await tester.pump();

    // The overlay shows both matches.
    expect(find.text('@alice '), findsOneWidget);
    expect(find.text('@albert '), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    // Tab completed the highlighted (first) option and kept focus in
    // the field instead of traversing to the button.
    expect(controller.text, '@alice ');
    expect(focusNode.hasFocus, isTrue);

    // Shift+tab with suggestions showing also accepts: modifier state
    // is deliberately ignored because the tracked shift state can
    // desync from reality on desktop embedders.
    await tester.enterText(find.byType(TextField), '@bo');
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(controller.text, '@bob ');
    expect(focusNode.hasFocus, isTrue);

    // With no suggestions, tab traverses as usual.
    await tester.enterText(find.byType(TextField), 'plain text');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
  });
}

// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/pages/chat/events/collapsible_content.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The bug this widget exists for: `Text.maxLines` does not constrain a
/// [WidgetSpan]. A line limit therefore did nothing to exactly the messages
/// that most needed collapsing -- code blocks, blockquotes, lists, tables --
/// because this renderer emits all of those as widget spans. Those messages
/// stayed taller than the viewport and, since the timeline anchors the bottom
/// of each item, opened showing their last lines.
///
/// So the cap has to be a height. These tests assert it holds against widget
/// content, which is the case a line-based clamp silently ignored.
void main() {
  const cap = 100.0;
  const tallWidget = 500.0;

  Widget control(BuildContext context, bool expanded, VoidCallback toggle) =>
      TextButton(onPressed: toggle, child: Text(expanded ? 'less' : 'more'));

  /// Content whose height lives almost entirely in a widget span, the way a
  /// message with a code block does.
  Widget widgetHeavy({double height = tallWidget}) => Text.rich(
    TextSpan(
      children: [
        const TextSpan(text: 'intro\n'),
        WidgetSpan(child: SizedBox(height: height, width: 100)),
      ],
    ),
  );

  Widget host(Widget child) => MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 300, child: child),
      ),
    ),
  );

  Widget collapsible({required Widget child, double collapsedHeight = cap}) =>
      CollapsibleContent(
        collapsedHeight: collapsedHeight,
        duration: const Duration(milliseconds: 200),
        controlBuilder: control,
        child: child,
      );

  group('the cap bounds widget content, which maxLines could not', () {
    testWidgets('a tall widget span is clamped to the cap', (tester) async {
      await tester.pumpWidget(host(collapsible(child: widgetHeavy())));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(ClampedHeight)).height,
        cap,
        reason: 'the widget span escaped the cap, as it does under maxLines',
      );
    });

    testWidgets('it is never rendered full height, not even for one frame', (
      tester,
    ) async {
      // The natural height is only known after a layout, so a cap that starts
      // at "unlimited" would flash the whole message before snapping shut --
      // once per long message, while scrolling.
      //
      // Asserted with no pump after pumpWidget, which is the whole point.
      // pumpWidget already runs a complete frame including the post-frame
      // callback that reports the natural height, so any further pump rebuilds
      // with the height known and reads the *second* frame -- where a cap that
      // started unlimited has already corrected itself. This assertion is the
      // only one that sees the first frame at all.
      await tester.pumpWidget(host(collapsible(child: widgetHeavy())));

      expect(tester.getSize(find.byType(ClampedHeight)).height, cap);
    });

    testWidgets('content that fits is left alone', (tester) async {
      await tester.pumpWidget(
        host(collapsible(child: widgetHeavy(height: 20))),
      );
      await tester.pumpAndSettle();

      final height = tester.getSize(find.byType(ClampedHeight)).height;
      expect(height, lessThan(cap));
      expect(find.text('more'), findsNothing, reason: 'offered to expand');
    });
  });

  group('the control appears only when something is hidden', () {
    testWidgets('shown when the content overflows', (tester) async {
      await tester.pumpWidget(host(collapsible(child: widgetHeavy())));
      await tester.pumpAndSettle();
      expect(find.text('more'), findsOneWidget);
    });

    testWidgets('expanding reveals the full height', (tester) async {
      await tester.pumpWidget(host(collapsible(child: widgetHeavy())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('more'));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(ClampedHeight)).height,
        greaterThan(tallWidget),
      );
      expect(find.text('less'), findsOneWidget);
    });

    testWidgets('collapsing returns to the cap', (tester) async {
      await tester.pumpWidget(host(collapsible(child: widgetHeavy())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('more'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('less'));
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(ClampedHeight)).height, cap);
    });
  });

  group('expanding inside a reversed timeline', () {
    // The timeline is a `reverse: true` ListView, which anchors each item's
    // bottom edge, so growth pushes the top upward and off the screen.
    //
    // The previous attempt measured the height after each layout and corrected
    // on the following frame, which always trailed by one frame. Against an
    // animation that lag repeated on every frame of it, so the correction
    // chased the text for the whole animation -- and the fix at the time was
    // to delete the animation.
    //
    // Driving the height here instead means the new height and the matching
    // scroll offset are both known before layout and land together. So the
    // assertion is taken on every frame, not after settling: settling hides
    // exactly the defect this is for.
    const duration = Duration(milliseconds: 200);

    testWidgets('the top edge holds on every frame of the animation', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: ListView.builder(
                reverse: true,
                itemCount: 12,
                itemBuilder: (context, index) => index == 4
                    ? CollapsibleContent(
                        collapsedHeight: cap,
                        duration: duration,
                        controlBuilder: control,
                        child: widgetHeavy(),
                      )
                    : SizedBox(height: 100, child: Text('item $index')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .jumpTo(250);
      await tester.pumpAndSettle();

      final topBefore = tester.getTopLeft(find.byType(ClampedHeight)).dy;
      await tester.tap(find.text('more'));

      for (var elapsed = 0; elapsed < 240; elapsed += 20) {
        await tester.pump(const Duration(milliseconds: 20));
        expect(
          tester.getTopLeft(find.byType(ClampedHeight)).dy,
          moreOrLessEquals(topBefore, epsilon: 2.0),
          reason: 'the top edge moved ${elapsed + 20}ms into the animation',
        );
      }

      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(ClampedHeight)).height,
        greaterThan(tallWidget),
        reason: 'it never actually expanded, so this proves nothing',
      );
      expect(
        tester.getTopLeft(find.byType(ClampedHeight)).dy,
        moreOrLessEquals(topBefore, epsilon: 2.0),
      );
    });

    testWidgets('the height really does animate rather than snapping', (
      tester,
    ) async {
      // Without this, an implementation that jumps straight to full height
      // would satisfy the anchoring test above -- a single step is trivially
      // in lockstep with itself.
      await tester.pumpWidget(host(collapsible(child: widgetHeavy())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('more'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final midway = tester.getSize(find.byType(ClampedHeight)).height;
      expect(midway, greaterThan(cap), reason: 'never left the cap');
      expect(midway, lessThan(tallWidget), reason: 'snapped to full height');

      await tester.pumpAndSettle();
    });
  });

  group('the cut edge fades', () {
    // A hard clip reads as a rendering fault rather than as "there is more".
    // The fade costs a saveLayer, so it is applied only while something is
    // actually hidden.

    testWidgets('faded while content is cut off', (tester) async {
      await tester.pumpWidget(host(collapsible(child: widgetHeavy())));
      await tester.pumpAndSettle();
      expect(find.byType(ShaderMask), findsOneWidget);
    });

    testWidgets('no fade, and no layer, once fully expanded', (tester) async {
      await tester.pumpWidget(host(collapsible(child: widgetHeavy())));
      await tester.pumpAndSettle();
      await tester.tap(find.text('more'));
      await tester.pumpAndSettle();

      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('no fade on content that fits', (tester) async {
      await tester.pumpWidget(
        host(collapsible(child: widgetHeavy(height: 20))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('can be turned off', (tester) async {
      await tester.pumpWidget(
        host(
          CollapsibleContent(
            collapsedHeight: cap,
            fadeHeight: 0,
            controlBuilder: control,
            child: widgetHeavy(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ShaderMask), findsNothing);
      expect(tester.getSize(find.byType(ClampedHeight)).height, cap);
    });
  });

  testWidgets('what is hidden is not tappable', (tester) async {
    // A link under the fold must not take a tap aimed at the visible message.
    var tapped = false;
    await tester.pumpWidget(
      host(
        collapsible(
          child: Column(
            children: [
              const SizedBox(height: cap),
              GestureDetector(
                onTap: () => tapped = true,
                child: const SizedBox(height: 200, width: 200),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final clamped = tester.getRect(find.byType(ClampedHeight));
    expect(clamped.height, cap);

    // Aim below the cap, where the hidden target sits.
    final hit = tester.hitTestOnBinding(
      Offset(clamped.center.dx, clamped.bottom + 50),
    );
    expect(
      hit.path.any((e) => e.target is RenderClampedHeight),
      isFalse,
      reason: 'a clipped region answered a hit test',
    );
    expect(tapped, isFalse);
  });
}

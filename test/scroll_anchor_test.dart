// SPDX-FileCopyrightText: 2026-Present cornball.ai
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/utils/scroll_anchor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The timeline is a `reverse: true` ListView, which anchors each item's
/// bottom edge, so a message that grows pushes its own top upward and takes
/// the line you were reading off the screen. The correction has to move the
/// scroll offset the same way the box grew, and the sign of that is exactly
/// the thing that is easy to get backwards -- get it wrong and the message
/// jumps twice as far instead of standing still, which still looks like
/// "scrolling happened" rather than like a bug.
///
/// Pumping the real timeline needs the Matrix provider, whose boot never
/// settles under flutter_tester, so this reproduces the geometry with a plain
/// list: a growable box among fixed ones, in a reversed viewport.
void main() {
  const viewport = 600.0;

  /// A stand-in for the collapsible message: same measure/grow/anchor
  /// sequence, no Matrix in sight.
  Widget harness({required bool reverse, required GlobalKey boxKey}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: viewport,
          child: _Harness(reverse: reverse, boxKey: boxKey),
        ),
      ),
    );
  }

  testWidgets('a growing box keeps its top edge in a reversed list', (
    tester,
  ) async {
    final boxKey = GlobalKey();
    await tester.pumpWidget(harness(reverse: true, boxKey: boxKey));
    await tester.pumpAndSettle();

    // Scroll so the growable box is somewhere in the middle, with room above.
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    position.jumpTo(250);
    await tester.pumpAndSettle();

    final topBefore = tester.getTopLeft(find.byKey(boxKey)).dy;
    await tester.tap(find.text('grow'));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(boxKey)).height,
      _grownHeight,
      reason: 'the box did not actually grow, so this proves nothing',
    );
    expect(
      tester.getTopLeft(find.byKey(boxKey)).dy,
      moreOrLessEquals(topBefore, epsilon: 1.0),
      reason: 'the top edge moved, so the reading position was lost',
    );
  });

  testWidgets('a normal list is left alone', (tester) async {
    // Growth already pushes content downward there, so the top edge is fixed
    // without help. Correcting anyway would cause the jump, not prevent it.
    final boxKey = GlobalKey();
    await tester.pumpWidget(harness(reverse: false, boxKey: boxKey));
    await tester.pumpAndSettle();

    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    position.jumpTo(250);
    await tester.pumpAndSettle();

    final offsetBefore = position.pixels;
    final topBefore = tester.getTopLeft(find.byKey(boxKey)).dy;
    await tester.tap(find.text('grow'));
    await tester.pumpAndSettle();

    expect(position.pixels, offsetBefore, reason: 'scrolled a normal list');
    expect(
      tester.getTopLeft(find.byKey(boxKey)).dy,
      moreOrLessEquals(topBefore, epsilon: 1.0),
    );
  });

  testWidgets('no correction when the height did not change', (tester) async {
    final boxKey = GlobalKey();
    await tester.pumpWidget(harness(reverse: true, boxKey: boxKey));
    await tester.pumpAndSettle();
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    position.jumpTo(250);
    await tester.pumpAndSettle();

    final before = position.pixels;
    anchorTopEdge(
      context: tester.element(find.byKey(boxKey)),
      heightBefore: 120,
      heightAfter: 120,
    );
    await tester.pump();
    expect(position.pixels, before);
  });

  testWidgets('the correction lands within one frame of the growth', (
    tester,
  ) async {
    // The correction is measured after layout and applied from a post-frame
    // callback, so it takes effect on the frame after the one that grew. That
    // is the whole budget: pumping a single frame has to be enough. Settling
    // instead would hide a correction that arrived late.
    final boxKey = GlobalKey();
    await tester.pumpWidget(harness(reverse: true, boxKey: boxKey));
    await tester.pumpAndSettle();

    tester.state<ScrollableState>(find.byType(Scrollable)).position.jumpTo(250);
    await tester.pumpAndSettle();

    final topBefore = tester.getTopLeft(find.byKey(boxKey)).dy;
    await tester.tap(find.text('grow'));
    await tester.pump(); // the frame that grows
    await tester.pump(); // the frame the correction lands on

    expect(
      tester.getTopLeft(find.byKey(boxKey)).dy,
      moreOrLessEquals(topBefore, epsilon: 1.0),
      reason: 'the correction had not arrived one frame after the growth',
    );
  });

  testWidgets('an easing height defeats the correction, which is why the '
      'collapsible message does not animate', (tester) async {
    // Executable reasoning rather than a guard. Wrapping the growth in an
    // AnimatedSize is the shape that shipped broken: the height eases over
    // ~300ms, so one correction sized from the final height moves the viewport
    // by the whole growth immediately, into space the list has not made yet.
    //
    // Chasing it frame by frame does not rescue it either -- the correction
    // always trails its own measurement by a frame, so the lag that is
    // invisible once repeats for the length of the animation.
    //
    // Settling first and checking the end state sees none of this: the end
    // state is correct either way. That is exactly why the original test
    // passed while the feature was broken on a real phone.
    const duration = Duration(milliseconds: 300);
    final sizeKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: viewport,
            child: _AnimatedHarness(sizeKey: sizeKey, duration: duration),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    tester.state<ScrollableState>(find.byType(Scrollable)).position.jumpTo(250);
    await tester.pumpAndSettle();

    final topBefore = tester.getTopLeft(find.byKey(sizeKey)).dy;
    await tester.tap(find.text('grow'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      (tester.getTopLeft(find.byKey(sizeKey)).dy - topBefore).abs(),
      greaterThan(10.0),
      reason:
          'an animated height no longer breaks the anchor -- if that is '
          'genuinely true now, the message widget can animate again',
    );
  });

  group('heightOf', () {
    testWidgets('measures a laid-out box', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        // Centred, because MaterialApp.home is given tight constraints and
        // would stretch the box to the full screen height.
        MaterialApp(
          home: Center(child: SizedBox(key: key, height: 42, width: 10)),
        ),
      );
      expect(heightOf(key), 42);
    });

    test('returns null for a key that is not mounted', () {
      expect(heightOf(GlobalKey()), isNull);
    });
  });
}

const double _itemHeight = 100.0;
const double _grownHeight = 400.0;
const int _growableIndex = 4;

class _Harness extends StatelessWidget {
  final bool reverse;
  final GlobalKey boxKey;

  const _Harness({required this.reverse, required this.boxKey});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: reverse,
      itemCount: 12,
      itemBuilder: (context, index) => index == _growableIndex
          ? _GrowableItem(boxKey: boxKey)
          : SizedBox(height: _itemHeight, child: Text('item $index')),
    );
  }
}

/// Must live INSIDE the list, like the real collapsible message does:
/// anchorTopEdge looks up the tree for its Scrollable, so a widget built
/// above the ListView would silently find nothing and correct no one.
class _GrowableItem extends StatefulWidget {
  final GlobalKey boxKey;

  const _GrowableItem({required this.boxKey});

  @override
  State<_GrowableItem> createState() => _GrowableItemState();
}

class _GrowableItemState extends State<_GrowableItem> {
  bool _grown = false;

  void _grow() {
    final before = heightOf(widget.boxKey);
    setState(() => _grown = true);
    if (before == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final after = heightOf(widget.boxKey);
      if (after == null) return;
      anchorTopEdge(context: context, heightBefore: before, heightAfter: after);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          key: widget.boxKey,
          height: _grown ? _grownHeight : _itemHeight,
        ),
        TextButton(onPressed: _grow, child: const Text('grow')),
      ],
    );
  }
}

/// The same reversed list, but with the growing box wrapped in an AnimatedSize
/// the way the real collapsible message is. The key goes on the AnimatedSize,
/// because its height is what occupies space in the list while its child has
/// already jumped to the final value.
class _AnimatedHarness extends StatelessWidget {
  final GlobalKey sizeKey;
  final Duration duration;

  const _AnimatedHarness({required this.sizeKey, required this.duration});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      itemCount: 12,
      itemBuilder: (context, index) => index == _growableIndex
          ? _AnimatedGrowItem(sizeKey: sizeKey, duration: duration)
          : SizedBox(height: _itemHeight, child: Text('item $index')),
    );
  }
}

class _AnimatedGrowItem extends StatefulWidget {
  final GlobalKey sizeKey;
  final Duration duration;

  const _AnimatedGrowItem({required this.sizeKey, required this.duration});

  @override
  State<_AnimatedGrowItem> createState() => _AnimatedGrowItemState();
}

class _AnimatedGrowItemState extends State<_AnimatedGrowItem> {
  bool _grown = false;

  /// The same measure/grow/anchor sequence the message used to run, kept so
  /// the animated case can be demonstrated rather than described.
  void _grow() {
    final before = heightOf(widget.sizeKey);
    setState(() => _grown = true);
    if (before == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final after = heightOf(widget.sizeKey);
      if (after == null) return;
      anchorTopEdge(context: context, heightBefore: before, heightAfter: after);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          key: widget.sizeKey,
          duration: widget.duration,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 100,
            height: _grown ? _grownHeight : _itemHeight,
          ),
        ),
        TextButton(onPressed: _grow, child: const Text('grow')),
      ],
    );
  }
}

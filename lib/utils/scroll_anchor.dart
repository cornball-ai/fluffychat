// SPDX-FileCopyrightText: 2026-Present cornball.ai
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

/// Keeps a widget's top edge where it is on screen while the widget grows.
///
/// The timeline is a `reverse: true` ListView, which anchors each item's
/// BOTTOM edge. A message that grows therefore pushes its own top upward and
/// carries the line you were reading off the top of the screen. Expanding a
/// long message is where that is most obviously wrong: you tap to read more
/// and the text you were on is what leaves.
///
/// Measure the growing box with [heightOf] before the change, then call
/// [anchorTopEdge] once the new layout is in.
double? heightOf(GlobalKey key) {
  final box = key.currentContext?.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.size.height;
}

/// Scrolls by however much a box grew, so its top edge lands back where it
/// started.
///
/// Only corrects in a reversed scroll view. In a normal one, growth pushes
/// content downward and the top edge is already fixed, so correcting there
/// would introduce the very jump this exists to prevent.
///
/// Call this from a post-frame callback, so it runs against the layout that
/// actually happened. That means the correction takes effect one frame after
/// the growth, which is imperceptible for a height that changes in a single
/// step -- and is why the collapsible message expands without an animation.
/// Against an easing height the same lag repeats on every frame, so the
/// correction chases the text for the length of the animation instead of
/// holding it still.
void anchorTopEdge({
  required BuildContext context,
  required double heightBefore,
  required double heightAfter,
}) {
  final delta = heightAfter - heightBefore;
  if (delta == 0) return;

  final position = Scrollable.maybeOf(context)?.position;
  if (position == null || !position.hasPixels) return;
  if (position.axisDirection != AxisDirection.up) return;

  final target = (position.pixels + delta).clamp(
    position.minScrollExtent,
    position.maxScrollExtent,
  );
  if (target == position.pixels) return;
  position.jumpTo(target);
}

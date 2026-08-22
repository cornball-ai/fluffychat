// SPDX-FileCopyrightText: 2026-Present cornball.ai
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:fluffychat/utils/scroll_anchor.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

/// Collapses tall message content to a fixed height, with a control to expand
/// it.
///
/// Clamping by **height** rather than by line count is the whole point.
/// `Text.maxLines` does not constrain a [WidgetSpan] at all -- a `Text.rich`
/// with `maxLines: 2` around a 500px widget lays out at 522px -- and this
/// renderer emits code blocks, blockquotes, lists, tables and spoilers as
/// widget spans. So a line limit silently did nothing to exactly the messages
/// that most needed collapsing, which then opened showing their last lines
/// because the timeline anchors the bottom of each item.
///
/// A pixel cap bounds anything: text, widgets, or a mix.
///
/// Expanding also animates without the scroll correction chasing it. The
/// height is driven here rather than measured after the fact, so the new
/// height and the matching scroll offset are both known before layout and land
/// in the same frame. Measuring a height someone else is animating can only
/// ever correct for where it was on the previous frame.
class CollapsibleContent extends StatefulWidget {
  final Widget child;

  /// Height the content is capped to while collapsed.
  final double collapsedHeight;

  final Duration duration;
  final Curve curve;

  /// Builds the expand/collapse control. Only called when the content actually
  /// overflows, which is measured rather than guessed.
  final Widget Function(BuildContext context, bool expanded, VoidCallback toggle)
  controlBuilder;

  const CollapsibleContent({
    required this.child,
    required this.collapsedHeight,
    required this.controlBuilder,
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.easeOutCubic,
    super.key,
  });

  @override
  State<CollapsibleContent> createState() => _CollapsibleContentState();
}

class _CollapsibleContentState extends State<CollapsibleContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..addListener(_onTick);

  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
  );

  /// The content's height with no cap applied, reported back out of layout.
  /// Null until the first layout has happened.
  double? _natural;

  bool _expanded = false;

  /// The cap as of the previous frame, so each tick corrects the scroll by
  /// what actually changed rather than by the total.
  double _lastCap = 0;

  double get _collapsed => widget.collapsedHeight;

  bool get _overflows {
    final natural = _natural;
    return natural != null && natural > _collapsed + 0.5;
  }

  /// Fully expanded means no cap at all, not a cap that happens to equal the
  /// current content height -- otherwise content that grows later (an image
  /// finishing, a translation arriving) would be clipped at a stale value.
  double get _cap {
    if (_progress.value >= 1.0) return double.infinity;
    // Only lift the cap once the content is known to fit under it. Before the
    // first layout the height is unknown, and guessing "no cap" would render
    // every long message at full height for one frame before snapping shut.
    // Guessing the cap costs nothing the other way: clamping above the natural
    // height changes no pixels.
    if (_natural != null && !_overflows) return double.infinity;
    return lerpDouble(_collapsed, _natural ?? _collapsed, _progress.value)!;
  }

  double get _capForAnchor => _cap.isFinite ? _cap : (_natural ?? _collapsed);

  @override
  void initState() {
    super.initState();
    _lastCap = _collapsed;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTick() {
    // Runs in the animation phase, before build and layout. Correcting the
    // scroll here and rebuilding at the new cap puts both into the same layout
    // pass, which is what keeps the top edge still instead of chasing it.
    final now = _capForAnchor;
    anchorTopEdge(context: context, heightBefore: _lastCap, heightAfter: now);
    _lastCap = now;
    setState(() {});
  }

  void _toggle() {
    _lastCap = _capForAnchor;
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _onNaturalHeight(double height) {
    if (!mounted || _natural == height) return;
    setState(() => _natural = height);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClampedHeight(
          maxHeight: _cap,
          onNaturalHeight: _onNaturalHeight,
          child: widget.child,
        ),
        if (_overflows) widget.controlBuilder(context, _expanded, _toggle),
      ],
    );
  }
}

/// Lays its child out with no height limit, then reports at most [maxHeight]
/// and clips the rest.
///
/// The unclamped layout is what makes [onNaturalHeight] possible: the child's
/// full height is known even while it is being clipped, so a caller can tell
/// whether there is anything hidden without guessing from the text, and knows
/// what height to animate towards.
class ClampedHeight extends SingleChildRenderObjectWidget {
  /// Cap on the reported height. [double.infinity] applies no cap.
  final double maxHeight;

  /// Called after layout when the child's uncapped height changes. Deferred to
  /// a post-frame callback, since layout is not allowed to trigger a rebuild.
  final ValueChanged<double>? onNaturalHeight;

  const ClampedHeight({
    required this.maxHeight,
    required Widget super.child,
    this.onNaturalHeight,
    super.key,
  });

  @override
  RenderObject createRenderObject(BuildContext context) => RenderClampedHeight(
    maxHeight: maxHeight,
    onNaturalHeight: onNaturalHeight,
  );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderClampedHeight renderObject,
  ) {
    renderObject
      ..maxHeight = maxHeight
      ..onNaturalHeight = onNaturalHeight;
  }
}

class RenderClampedHeight extends RenderProxyBox {
  RenderClampedHeight({required double maxHeight, this.onNaturalHeight})
    : _maxHeight = maxHeight;

  double _maxHeight;

  double get maxHeight => _maxHeight;

  set maxHeight(double value) {
    if (_maxHeight == value) return;
    _maxHeight = value;
    markNeedsLayout();
  }

  ValueChanged<double>? onNaturalHeight;

  double? _reported;

  /// The child's height with no cap applied, as of the last layout.
  double? get naturalHeight => _reported;

  BoxConstraints _childConstraints(BoxConstraints constraints) =>
      BoxConstraints(
        minWidth: constraints.minWidth,
        maxWidth: constraints.maxWidth,
      );

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    final size = child.getDryLayout(_childConstraints(constraints));
    return constraints.constrain(
      Size(size.width, math.min(size.height, _maxHeight)),
    );
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }

    child.layout(_childConstraints(constraints), parentUsesSize: true);
    final natural = child.size.height;
    size = constraints.constrain(
      Size(child.size.width, math.min(natural, _maxHeight)),
    );

    if (natural != _reported) {
      _reported = natural;
      final callback = onNaturalHeight;
      if (callback != null) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (attached) callback(natural);
        });
      }
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    if (child.size.height <= size.height) {
      context.paintChild(child, offset);
      return;
    }
    context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      (context, offset) => context.paintChild(child, offset),
      clipBehavior: Clip.hardEdge,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Nothing below the cap is visible, so nothing below it should be
    // tappable -- a link hidden under the fold must not swallow a tap meant
    // for the message.
    if (!size.contains(position)) return false;
    return super.hitTest(result, position: position);
  }
}

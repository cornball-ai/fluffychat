// SPDX-FileCopyrightText: 2026-Present cornball.ai
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/utils/adaptive_bottom_sheet.dart';
import 'package:material_ui/material_ui.dart';

/// A widget's rectangle in global (screen) coordinates, for anchoring a menu
/// or cutting the scrim's hole. Degrades to a zero rect rather than throwing
/// if it is asked before layout.
Rect globalRectOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return Rect.zero;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// The custom-reaction picker, returning the chosen emoji or null.
///
/// Shared by the inline reaction row and the long-press pill so the two
/// cannot drift; the caller decides what sending it means, because the two
/// differ on whether an already-sent reaction is a no-op.
Future<String?> pickCustomReaction(BuildContext context) {
  final theme = Theme.of(context);
  return showAdaptiveBottomSheet<String>(
    context: context,
    builder: (context) => Scaffold(
      appBar: AppBar(
        title: Text(L10n.of(context).customReaction),
        leading: CloseButton(onPressed: () => Navigator.of(context).pop(null)),
      ),
      body: SizedBox(
        height: double.infinity,
        child: EmojiPicker(
          onEmojiSelected: (_, emoji) => Navigator.of(context).pop(emoji.emoji),
          config: Config(
            locale: Localizations.localeOf(context),
            emojiViewConfig: const EmojiViewConfig(
              backgroundColor: Colors.transparent,
            ),
            bottomActionBarConfig: const BottomActionBarConfig(enabled: false),
            categoryViewConfig: CategoryViewConfig(
              initCategory: Category.SMILEYS,
              backspaceColor: theme.colorScheme.primary,
              iconColor: theme.colorScheme.primary.withAlpha(128),
              iconColorSelected: theme.colorScheme.primary,
              indicatorColor: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surface,
            ),
            skinToneConfig: SkinToneConfig(
              dialogBackgroundColor: Color.lerp(
                theme.colorScheme.surface,
                theme.colorScheme.primaryContainer,
                0.75,
              )!,
              indicatorColor: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    ),
  );
}

/// One entry in a message's action list.
///
/// Desktop and mobile present these very differently -- an icon-only row
/// beside the bubble against a full sheet with labels -- so the one thing
/// keeping them from drifting apart as actions are added is that both render
/// from this same list.
class MessageAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Rendered in the error colour, as Signal does for Delete.
  final bool isDestructive;

  const MessageAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}

/// The desktop affordance: a quiet icon row beside the bubble, faded in while
/// the pointer is over the message.
///
/// The row occupies its width whether or not it is showing. A row that only
/// took space when visible would shove the bubble sideways the moment the
/// pointer crossed it, and the bubble would then slide out from under the
/// pointer.
class MessageHoverActions extends StatelessWidget {
  final bool visible;
  final List<MessageAction> actions;

  const MessageHoverActions({
    required this.visible,
    required this.actions,
    super.key,
  });

  static const double buttonSize = 30.0;
  static const double iconSize = 17.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: FluffyThemes.animationDuration,
        curve: FluffyThemes.animationCurve,
        child: Row(
          mainAxisSize: .min,
          children: actions
              .map(
                (action) => SizedBox(
                  width: buttonSize,
                  height: buttonSize,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: iconSize,
                    visualDensity: VisualDensity.compact,
                    tooltip: action.label,
                    color: action.isDestructive
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                    icon: Icon(action.icon),
                    onPressed: action.onTap,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

/// The mobile long-press presentation: everything dims except the message
/// itself, a reaction pill floats above it and the action list sits below.
///
/// Returns the chosen action, or null if the sheet was dismissed or the user
/// only reacted. The caller invokes it, because most of the actions read the
/// controller's selection and need it still standing when they run.
Future<MessageAction?> showMessageActionsSheet({
  required BuildContext context,
  required Rect messageRect,
  required List<MessageAction> actions,
  required List<String> quickReactions,
  required void Function(String emoji) onReact,
  required VoidCallback onMoreReactions,
}) => Navigator.of(context).push(
  _MessageActionsRoute(
    messageRect: messageRect,
    actions: actions,
    quickReactions: quickReactions,
    onReact: onReact,
    onMoreReactions: onMoreReactions,
  ),
);

class _MessageActionsRoute extends PopupRoute<MessageAction> {
  final Rect messageRect;
  final List<MessageAction> actions;
  final List<String> quickReactions;
  final void Function(String emoji) onReact;
  final VoidCallback onMoreReactions;

  _MessageActionsRoute({
    required this.messageRect,
    required this.actions,
    required this.quickReactions,
    required this.onReact,
    required this.onMoreReactions,
  });

  // The scrim is painted by the page itself, because it needs a hole in it.
  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel =>
      MaterialLocalizations.of(navigator!.context).modalBarrierDismissLabel;

  @override
  Duration get transitionDuration => FluffyThemes.animationDuration;

  static const double _gap = 10.0;
  static const double _pillHeight = 52.0;
  static const double _minListHeight = 180.0;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final media = MediaQuery.of(context);
    final safeTop = media.padding.top + 8;
    final safeBottom = media.size.height - media.padding.bottom - 8;

    final pillTop = (messageRect.top - _gap - _pillHeight).clamp(
      safeTop,
      safeBottom - _pillHeight,
    );

    var listTop = messageRect.bottom + _gap;
    var listMaxHeight = safeBottom - listTop;
    if (listMaxHeight < _minListHeight) {
      // Message sits too low for its list to follow it. Anchor the list to
      // the bottom instead; the hole in the scrim keeps the message readable
      // even when the list is no longer directly under it.
      listMaxHeight = (media.size.height * 0.6).clamp(
        _minListHeight,
        safeBottom - safeTop - _pillHeight - _gap,
      );
      listTop = safeBottom - listMaxHeight;
    }

    return FadeTransition(
      opacity: animation,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: CustomPaint(
                painter: _ScrimWithHole(
                  hole: messageRect.inflate(4),
                  radius: AppConfig.borderRadius,
                  color: Colors.black.withAlpha(170),
                ),
              ),
            ),
          ),
          Positioned(
            top: pillTop,
            left: 8,
            right: 8,
            child: Align(
              child: _ReactionPill(
                reactions: quickReactions,
                onReact: (emoji) {
                  Navigator.of(context).pop();
                  onReact(emoji);
                },
                onMore: () {
                  Navigator.of(context).pop();
                  onMoreReactions();
                },
              ),
            ),
          ),
          Positioned(
            top: listTop,
            left: 8,
            right: 8,
            child: Align(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 320,
                  maxHeight: listMaxHeight,
                ),
                child: _ActionList(actions: actions),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dims the whole screen except for one rounded rectangle.
///
/// The message is never redrawn on top: the scrim simply is not painted over
/// it, so what shows through the hole is the real bubble in the timeline.
class _ScrimWithHole extends CustomPainter {
  final Rect hole;
  final double radius;
  final Color color;

  const _ScrimWithHole({
    required this.hole,
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()
          ..addRRect(RRect.fromRectAndRadius(hole, Radius.circular(radius))),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_ScrimWithHole oldDelegate) =>
      oldDelegate.hole != hole ||
      oldDelegate.radius != radius ||
      oldDelegate.color != color;
}

class _ReactionPill extends StatelessWidget {
  final List<String> reactions;
  final void Function(String emoji) onReact;
  final VoidCallback onMore;

  const _ReactionPill({
    required this.reactions,
    required this.onReact,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      elevation: 4,
      borderRadius: BorderRadius.circular(_MessageActionsRoute._pillHeight),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: .min,
          children: [
            for (final emoji in reactions)
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => onReact(emoji),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.more_horiz),
              color: theme.colorScheme.onSurfaceVariant,
              onPressed: onMore,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionList extends StatelessWidget {
  final List<MessageAction> actions;

  const _ActionList({required this.actions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      elevation: 4,
      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      clipBehavior: Clip.antiAlias,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        children: actions.map((action) {
          final color = action.isDestructive ? theme.colorScheme.error : null;
          return ListTile(
            leading: Icon(action.icon, color: color),
            title: Text(action.label, style: TextStyle(color: color)),
            onTap: () => Navigator.of(context).pop(action),
          );
        }).toList(),
      ),
    );
  }
}

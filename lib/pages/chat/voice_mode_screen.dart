// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/utils/voice/voice_turn.dart';
import 'package:flutter/material.dart';

/// The six-bar waveform glyph on the live-voice entry button.
///
/// Painted rather than shipped as an asset so it always takes the current
/// IconTheme color, in both themes, at any size.
class VoiceBarsIcon extends StatelessWidget {
  final double size;

  const VoiceBarsIcon({this.size = 20, super.key});

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? Colors.white;
    return CustomPaint(
      size: Size.square(size),
      painter: _VoiceBarsPainter(color),
    );
  }
}

class _VoiceBarsPainter extends CustomPainter {
  final Color color;

  _VoiceBarsPainter(this.color);

  // Relative bar heights, symmetric-ish like a word being spoken.
  static const _heights = [0.35, 0.65, 1.0, 0.8, 0.5, 0.3];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final barWidth = size.width / (_heights.length * 2 - 1);
    for (var i = 0; i < _heights.length; i++) {
      final barHeight = size.height * _heights[i];
      final left = i * barWidth * 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            left,
            (size.height - barHeight) / 2,
            barWidth,
            barHeight,
          ),
          Radius.circular(barWidth / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_VoiceBarsPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// The full-screen surface a live conversation runs in: the conversation
/// itself as it happens, a mute toggle, and the way out.
///
/// It shows the words rather than a state, because a state cannot be read at
/// the pace speech happens. The reply is drawn twice over: the part the
/// speaker has reached in full contrast, the part still queued behind it
/// dimmed, so a glance says how far along the sentence being spoken is. Both
/// come from the same offsets that decide what an interruption reports as
/// heard, so the page and the agent cannot disagree about what was said.
///
/// The screen renders state it does not own. The session lives in
/// [ChatController] (it must survive navigation), and this screen only
/// listens: when the controller's `liveVoiceRunning` flips false -- user
/// stop, error, session death, any path -- the screen pops itself. The X
/// here asks the controller to stop and lets that same signal do the
/// popping, so there is exactly one way off this screen.
class VoiceModeScreen extends StatefulWidget {
  final ChatController controller;

  const VoiceModeScreen({required this.controller, super.key});

  @override
  State<VoiceModeScreen> createState() => _VoiceModeScreenState();
}

class _VoiceModeScreenState extends State<VoiceModeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.94,
    upperBound: 1.06,
  );

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.liveVoiceRunning.addListener(_onRunningChanged);
    widget.controller.liveVoiceSpeaking.addListener(_onSpeakingChanged);
    widget.controller.liveVoiceTurns.addListener(_onTurnsChanged);
    _onSpeakingChanged();
  }

  @override
  void dispose() {
    widget.controller.liveVoiceRunning.removeListener(_onRunningChanged);
    widget.controller.liveVoiceSpeaking.removeListener(_onSpeakingChanged);
    widget.controller.liveVoiceTurns.removeListener(_onTurnsChanged);
    _scroll.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _onRunningChanged() {
    if (!widget.controller.liveVoiceRunning.value && mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Follows the conversation down. After the frame, because the text that
  /// just arrived has not been laid out yet and the extent to scroll to does
  /// not exist until it has.
  void _onTurnsChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _onSpeakingChanged() {
    if (widget.controller.liveVoiceSpeaking.value) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = L10n.of(context);
    final controller = widget.controller;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                controller.room.getLocalizedDisplayname(),
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<List<VoiceTurn>>(
                valueListenable: controller.liveVoiceTurns,
                builder: (context, turns, _) => turns.isEmpty
                    ? Center(
                        child: ValueListenableBuilder<bool>(
                          valueListenable: controller.liveVoiceMuted,
                          builder: (context, muted, _) => Text(
                            muted
                                ? l10n.voiceModeMuted
                                : l10n.voiceModeListening,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: turns.length,
                        itemBuilder: (context, i) => _VoiceTurnView(turns[i]),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: controller.liveVoiceMuted,
                    builder: (context, muted, _) => IconButton(
                      tooltip: muted
                          ? l10n.unmuteMicrophone
                          : l10n.muteMicrophone,
                      onPressed: controller.toggleLiveVoiceMute,
                      style: IconButton.styleFrom(
                        backgroundColor: muted
                            ? theme.colorScheme.error
                            : theme.colorScheme.surfaceContainerHighest,
                        foregroundColor: muted
                            ? theme.colorScheme.onError
                            : theme.colorScheme.onSurface,
                        minimumSize: const Size(56, 56),
                      ),
                      icon: Icon(muted ? Icons.mic_off : Icons.mic_none),
                    ),
                  ),
                  // The mic stands in the middle as the thing the screen is
                  // about, pulsing while the assistant holds the floor.
                  Expanded(
                    child: Center(
                      child: ScaleTransition(
                        scale: _pulse,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.colorScheme.primaryContainer,
                                theme.colorScheme.primary,
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.mic_none,
                            color: theme.colorScheme.onPrimary,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.stopLiveVoice,
                    onPressed: controller.toggleLiveVoice,
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.onSurface,
                      foregroundColor: theme.colorScheme.surface,
                      minimumSize: const Size(56, 56),
                    ),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One turn in the live conversation.
///
/// The two sides read differently on purpose. What the user said is a short
/// quoted thing and sits in a bubble; what the assistant is saying is the
/// content of the screen and gets the room to be read at speaking pace, with
/// the words already out of the speaker at full contrast and the ones still
/// queued behind them dimmed.
class _VoiceTurnView extends StatelessWidget {
  final VoiceTurn turn;

  const _VoiceTurnView(this.turn);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (turn.fromUser) {
      return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 4, left: 32),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              turn.text,
              style: theme.textTheme.titleMedium?.copyWith(
                // A turn still being transcribed is provisional: the
                // endpointer can still revise it, and it should not read as
                // settled until it has.
                color: turn.done
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }
    final spoken = theme.textTheme.headlineSmall?.copyWith(
      color: theme.colorScheme.onSurface,
      height: 1.4,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: turn.spoken, style: spoken),
            TextSpan(
              text: turn.pending,
              style: spoken?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

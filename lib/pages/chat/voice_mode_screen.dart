// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/chat/chat.dart';
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

/// The simplified full-screen surface a live conversation runs in: a status
/// orb, the words as they happen, a mute toggle, and the way out.
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

  @override
  void initState() {
    super.initState();
    widget.controller.liveVoiceRunning.addListener(_onRunningChanged);
    widget.controller.liveVoiceSpeaking.addListener(_onSpeakingChanged);
    _onSpeakingChanged();
  }

  @override
  void dispose() {
    widget.controller.liveVoiceRunning.removeListener(_onRunningChanged);
    widget.controller.liveVoiceSpeaking.removeListener(_onSpeakingChanged);
    _pulse.dispose();
    super.dispose();
  }

  void _onRunningChanged() {
    if (!widget.controller.liveVoiceRunning.value && mounted) {
      Navigator.of(context).pop();
    }
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _pulse,
                    child: Container(
                      width: 160,
                      height: 160,
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
                    ),
                  ),
                  const SizedBox(height: 24),
                  ValueListenableBuilder<bool>(
                    valueListenable: controller.liveVoiceMuted,
                    builder: (context, muted, _) =>
                        ValueListenableBuilder<bool>(
                          valueListenable: controller.liveVoiceSpeaking,
                          builder: (context, speaking, _) => Text(
                            muted
                                ? l10n.voiceModeMuted
                                : speaking
                                ? l10n.voiceModeSpeaking
                                : l10n.voiceModeListening,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ValueListenableBuilder<String>(
                    valueListenable: controller.liveVoiceTranscript,
                    builder: (context, text, _) => text.isEmpty
                        ? const SizedBox.shrink()
                        : Text(
                            text,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<String>(
                    valueListenable: controller.liveVoiceReply,
                    builder: (context, text, _) => text.isEmpty
                        ? const SizedBox.shrink()
                        : Text(
                            text,
                            style: theme.textTheme.bodyMedium,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

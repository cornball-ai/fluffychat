// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/call/call_view_model.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/view_model_builder.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:material_ui/material_ui.dart';

class CallPage extends StatelessWidget {
  final String roomId, liveKitUrl, liveKitJwt;
  const CallPage({
    super.key,
    required this.roomId,
    required this.liveKitUrl,
    required this.liveKitJwt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ViewModelBuilder(
      create: () => CallViewModel(
        liveKitJwt: liveKitJwt,
        liveKitUrl: liveKitUrl,
        room: Matrix.of(context).client.getRoomById(roomId)!,
      ),
      builder: (context, viewModel, _) {
        final liveKitRoom = viewModel.value;
        final localParticipant = liveKitRoom?.localParticipant;

        return Scaffold(
          body: liveKitRoom == null
              ? Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    for (final participant
                        in liveKitRoom.remoteParticipants.values)
                      for (final pub in participant.videoTrackPublications)
                        if (pub.track != null)
                          _VideoRendererTile(
                            pub.track!,
                            key: ValueKey(pub.participant.identity),
                          ),
                    for (final pub
                        in liveKitRoom
                                .localParticipant
                                ?.videoTrackPublications ??
                            [])
                      if (pub.track != null)
                        _VideoRendererTile(
                          pub.track!,
                          key: ValueKey(pub.participant.identity),
                        ),
                  ],
                ),
          floatingActionButtonLocation: .centerFloat,
          floatingActionButton: localParticipant == null
              ? null
              : Wrap(
                  alignment: .center,
                  spacing: 16,
                  children: [
                    FloatingActionButton(
                      onPressed: () => localParticipant.setMicrophoneEnabled(
                        !localParticipant.isMicrophoneEnabled(),
                      ),
                      child: Icon(
                        localParticipant.isMicrophoneEnabled()
                            ? Icons.mic_outlined
                            : Icons.mic_off_outlined,
                      ),
                    ),
                    FloatingActionButton(
                      onPressed: () => localParticipant.setCameraEnabled(
                        !localParticipant.isCameraEnabled(),
                      ),
                      child: Icon(
                        localParticipant.isCameraEnabled()
                            ? Icons.videocam_outlined
                            : Icons.videocam_off_outlined,
                      ),
                    ),
                    FloatingActionButton(
                      onPressed: () => viewModel.close(context),
                      foregroundColor: theme.colorScheme.onErrorContainer,
                      backgroundColor: theme.colorScheme.errorContainer,
                      child: Icon(Icons.call_end_outlined),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _VideoRendererTile extends StatelessWidget {
  final VideoTrack track;
  const _VideoRendererTile(this.track, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      ),
      margin: EdgeInsets.all(16),
      child: VideoTrackRenderer(track),
    );
  }
}

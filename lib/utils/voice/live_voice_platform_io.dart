// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

// The unused-code checker resolves live_voice_platform.dart's conditional
// export to its default (stub) branch, so everything here -- the branch that
// actually runs on every native platform -- looks uncalled to static
// analysis. The session tests construct this same wiring; the false positive
// is the checker's, not dead code. Line-level ignores are not honored by the
// unused-code pass, hence the file-level one.
// ignore_for_file: unused-code

import 'dart:io';

import 'aplay_pcm_sink.dart';
import 'grpc_voice_transport.dart';
import 'live_voice_session.dart';
import 'pcm_capture.dart';

/// Which native platforms have a working PCM sink today. Linux desktop is
/// the deployment this fork actually runs on; mobile arrives when a sink
/// for it does, behind this same seam.
final bool liveVoiceSupported = Platform.isLinux;

/// Builds the real session: aplay for the speaker, gRPC for every wire.
///
/// [agentAddress] is `host:port`, reaching the agent over the tailnet --
/// plain means an insecure channel (the WireGuard-underneath norm), a
/// `tls://` prefix means TLS. The media endpoints are not configured here at
/// all: the agent's grant names them, security included.
LiveVoiceSession buildLiveVoiceSession({
  required String agentAddress,
  required String openIdToken,
  required String matrixServerName,
  required LiveVoiceCallbacks callbacks,
}) {
  if (!liveVoiceSupported) {
    throw UnsupportedError('live voice has no audio output on this platform');
  }

  var address = agentAddress.trim();
  var tls = false;
  if (address.startsWith('tls://')) {
    tls = true;
    address = address.substring('tls://'.length);
  }
  final colon = address.lastIndexOf(':');
  if (colon <= 0 || colon == address.length - 1) {
    throw FormatException(
      'agent address must be host:port, got "$agentAddress"',
    );
  }
  final host = address.substring(0, colon);
  final port = int.tryParse(address.substring(colon + 1));
  if (port == null || port < 1 || port > 65535) {
    throw FormatException(
      'agent address must be host:port, got "$agentAddress"',
    );
  }

  return LiveVoiceSession(
    transport: GrpcVoiceTransport(
      agentHost: host,
      agentPort: port,
      agentTls: tls,
      credentials: AgentCredentials(
        openIdToken: openIdToken,
        matrixServerName: matrixServerName,
      ),
    ),
    capture: PcmCapture(),
    sink: AplayPcmSink(),
    callbacks: callbacks,
  );
}

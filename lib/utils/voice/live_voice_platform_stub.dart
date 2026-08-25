// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'live_voice_session.dart';

/// Non-io platforms (the web build) compile this instead of the real
/// factory: live voice needs a client-streaming gRPC call and a PCM output
/// process, and the browser has neither -- grpc-web cannot stream uplink at
/// all, so this is a capability boundary, not a missing feature.
const bool liveVoiceSupported = false;

LiveVoiceSession buildLiveVoiceSession({
  required String agentAddress,
  required String openIdToken,
  required String matrixServerName,
  required LiveVoiceCallbacks callbacks,
}) {
  throw UnsupportedError('live voice is not available on this platform');
}

// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Platform door for live voice. Everything io-flavored -- the aplay sink,
/// gRPC channel construction -- sits behind this conditional export so the
/// web build never compiles a dart:io import. Callers check
/// [liveVoiceSupported] and call [buildLiveVoiceSession]; on web the first
/// is false and the second throws.
library;

export 'live_voice_platform_stub.dart'
    if (dart.library.io) 'live_voice_platform_io.dart';

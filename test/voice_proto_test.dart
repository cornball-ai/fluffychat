// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fixnum/fixnum.dart';
import 'package:fluffychat/utils/voice/proto/agent_voice.pb.dart';
import 'package:fluffychat/utils/voice/proto/gpu_voice.pb.dart';
import 'package:flutter_test/flutter_test.dart';

// The generated stubs are excluded from `flutter analyze`, so importing them
// here is what forces them through the compiler at test time -- without this,
// a stale or broken regeneration only surfaces when the app itself is built.
void main() {
  test('total_chunks distinguishes absent from zero', () {
    // The truncation report depends on this: "none dropped" and "the server
    // never said how many" must not collapse into the same value.
    final unsaid = SynthesisStart();
    expect(unsaid.hasTotalChunks(), isFalse);

    final zero = SynthesisStart(totalChunks: 0);
    expect(zero.hasTotalChunks(), isTrue);
    expect(zero.totalChunks, 0);

    // And the distinction has to survive the wire, not just the constructor.
    final decoded = SynthesisStart.fromBuffer(zero.writeToBuffer());
    expect(decoded.hasTotalChunks(), isTrue);
    expect(decoded.totalChunks, 0);
    expect(
      SynthesisStart.fromBuffer(unsaid.writeToBuffer()).hasTotalChunks(),
      isFalse,
    );
  });

  test('chunk index 0 survives a round trip', () {
    // Proto3 does not encode default values, so the first chunk's index is
    // the one that exercises the "field absent means zero" decode path.
    final chunk = AudioChunk(
      index: 0,
      durationMs: 480,
      pcm: [1, 2, 3],
    );
    final decoded = AudioChunk.fromBuffer(chunk.writeToBuffer());
    expect(decoded.index, 0);
    expect(decoded.durationMs, 480);
    expect(decoded.pcm, [1, 2, 3]);
  });

  test('transcribe payload discriminates config from audio', () {
    final config = TranscribeRequest(
      config: TranscribeConfig(
        sampleRateHz: 16000,
        channels: 1,
        encoding: AudioEncoding.AUDIO_ENCODING_PCM_S16LE,
      ),
    );
    expect(config.whichPayload(), TranscribeRequest_Payload.config);

    final audio = TranscribeRequest(audio: [0, 0, 0, 0]);
    expect(audio.whichPayload(), TranscribeRequest_Payload.audio);

    // The server's config-first rule needs "neither" to be representable,
    // so an empty message must not read as either arm.
    expect(
      TranscribeRequest().whichPayload(),
      TranscribeRequest_Payload.notSet,
    );
  });

  test('allocation response carries both endpoints independently', () {
    // Separate fields because the two models need not be co-resident.
    final response = AllocateVoiceResponse(
      sessionId: 's',
      speechToText: Endpoint(host: 'stt-host', port: 50051),
      textToSpeech: Endpoint(host: 'tts-host', port: 50052, tls: true),
      token: 't',
      expiresAtUnixMs: Int64(1),
    );
    final decoded = AllocateVoiceResponse.fromBuffer(response.writeToBuffer());
    expect(decoded.speechToText.host, 'stt-host');
    expect(decoded.textToSpeech.host, 'tts-host');
    expect(decoded.speechToText.tls, isFalse);
    expect(decoded.textToSpeech.tls, isTrue);
  });
}

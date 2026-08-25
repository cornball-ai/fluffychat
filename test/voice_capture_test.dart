// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/utils/voice/pcm_capture.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';

/// The capture format is a contract with the server: it expects 16 kHz mono
/// 16-bit PCM and does no resampling of its own. A change here is silent from
/// the client's side -- audio still records, still streams, still looks fine --
/// and shows up only as a transcript that has gone strange. So the format is
/// pinned rather than left to a default.
void main() {
  group('liveVoiceRecordConfig', () {
    test('captures raw PCM, not a compressed codec', () {
      // Opus in the live loop would cost a decode on the far side for no
      // benefit, since the speech model resamples to 16 kHz regardless.
      expect(liveVoiceRecordConfig.encoder, AudioEncoder.pcm16bits);
    });

    test('is 16 kHz mono', () {
      expect(liveVoiceRecordConfig.sampleRate, 16000);
      expect(liveVoiceRecordConfig.numChannels, 1);
    });

    test('the exported constants match the config actually used', () {
      // Two places state the rate; this is what stops them drifting apart.
      expect(liveVoiceRecordConfig.sampleRate, voiceSampleRate);
      expect(liveVoiceRecordConfig.numChannels, voiceNumChannels);
    });

    test('echo cancellation is on, or barge-in hears our own speech', () {
      // Without this the microphone picks up the synthesised reply coming out
      // of the speaker, the energy detector reads it as the user talking, and
      // the client interrupts itself as soon as the bot starts.
      expect(liveVoiceRecordConfig.echoCancel, isTrue);
    });

    test('automatic gain is off, or the barge-in threshold moves under us', () {
      // Auto gain rides the recording level up and down. The detector compares
      // that level against a fixed dBFS threshold, so leaving gain on would
      // quietly change the thing the threshold is calibrated against.
      expect(liveVoiceRecordConfig.autoGain, isFalse);
    });
  });
}

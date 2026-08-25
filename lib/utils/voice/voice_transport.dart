// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:typed_data';

/// The wire as the session sees it.
///
/// Narrower than the generated gRPC clients on purpose: the session's logic
/// -- turn taking, segmentation, barge-in accounting -- is exactly the code
/// that must be testable without a server, and the generated clients only
/// construct against a live channel. The gRPC adapter implementing this is
/// thin plumbing; everything worth testing lives above the seam.
abstract class VoiceTransport {
  /// Allocates the voice session and opens the media streams. Must be called
  /// once, first.
  Future<void> connect(String roomId);

  /// Feeds one microphone frame to the live transcription stream.
  void sendAudio(Uint8List frame);

  /// Transcription events, across all turns of the session.
  Stream<SttEvent> get transcripts;

  /// Runs one agent turn: [text] in, reply events out. The stream closing
  /// without [ReplyEnd] means the turn died; cancelling the subscription
  /// stops generation.
  Stream<ReplyEvent> converse(String text);

  /// Synthesises one segment. Cancelling the subscription is barge-in for
  /// this segment's remaining chunks.
  Stream<TtsEvent> synthesize(String text);

  /// Reports how much of turn [turnId] was heard; returns the text the agent
  /// stored.
  Future<String> reportTurn({
    required String turnId,
    required int textHeard,
    required TurnResult result,
  });

  /// Tears down streams and channels. The transport is unusable afterwards.
  Future<void> close();
}

enum TurnResult { completed, bargeIn, abandoned }

sealed class SttEvent {
  const SttEvent();
}

/// A transcript update. Stable text APPENDS to the turn; provisional text
/// REPLACES the previous provisional (see the schema for the full contract).
class SttTranscript extends SttEvent {
  final String text;
  final bool stable;
  const SttTranscript(this.text, {required this.stable});
}

/// The server judged the speaker's turn over. All stable text has been
/// flushed by the time this arrives.
class SttTurnEnded extends SttEvent {
  const SttTurnEnded();
}

sealed class ReplyEvent {
  const ReplyEvent();
}

class ReplyStart extends ReplyEvent {
  final String turnId;
  const ReplyStart(this.turnId);
}

class ReplyDelta extends ReplyEvent {
  final String text;
  const ReplyDelta(this.text);
}

class ReplyEnd extends ReplyEvent {
  final String stopReason;
  const ReplyEnd(this.stopReason);
}

sealed class TtsEvent {
  const TtsEvent();
}

class TtsStart extends TtsEvent {
  final int sampleRateHz;
  final int? totalChunks;
  const TtsStart(this.sampleRateHz, {this.totalChunks});
}

class TtsChunk extends TtsEvent {
  final int index;
  final Duration duration;

  /// Cumulative code-point offset into THIS synthesize call's input. The
  /// adapter must reject (error the stream) a chunk that arrives without
  /// this field rather than defaulting it -- absence is a server bug, not a
  /// zero.
  final int inputTextEnd;
  final Uint8List pcm;
  const TtsChunk({
    required this.index,
    required this.duration,
    required this.inputTextEnd,
    required this.pcm,
  });
}

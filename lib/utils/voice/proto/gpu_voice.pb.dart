// This is a generated file - do not edit.
//
// Generated from gpu_voice.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'gpu_voice.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'gpu_voice.pbenum.dart';

enum TranscribeRequest_Payload { config, audio, notSet }

class TranscribeRequest extends $pb.GeneratedMessage {
  factory TranscribeRequest({
    TranscribeConfig? config,
    $core.List<$core.int>? audio,
  }) {
    final result = create();
    if (config != null) result.config = config;
    if (audio != null) result.audio = audio;
    return result;
  }

  TranscribeRequest._();

  factory TranscribeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TranscribeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, TranscribeRequest_Payload>
      _TranscribeRequest_PayloadByTag = {
    1: TranscribeRequest_Payload.config,
    2: TranscribeRequest_Payload.audio,
    0: TranscribeRequest_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TranscribeRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'cornball.voice.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<TranscribeConfig>(1, _omitFieldNames ? '' : 'config',
        subBuilder: TranscribeConfig.create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'audio', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TranscribeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TranscribeRequest copyWith(void Function(TranscribeRequest) updates) =>
      super.copyWith((message) => updates(message as TranscribeRequest))
          as TranscribeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TranscribeRequest create() => TranscribeRequest._();
  @$core.override
  TranscribeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TranscribeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TranscribeRequest>(create);
  static TranscribeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  TranscribeRequest_Payload whichPayload() =>
      _TranscribeRequest_PayloadByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearPayload() => $_clearField($_whichOneof(0));

  /// MUST be the first message on the stream. Sending audio first is an
  /// INVALID_ARGUMENT, not a default-config fallback: silently transcribing
  /// at the wrong sample rate produces plausible text and no error.
  @$pb.TagNumber(1)
  TranscribeConfig get config => $_getN(0);
  @$pb.TagNumber(1)
  set config(TranscribeConfig value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasConfig() => $_has(0);
  @$pb.TagNumber(1)
  void clearConfig() => $_clearField(1);
  @$pb.TagNumber(1)
  TranscribeConfig ensureConfig() => $_ensure(0);

  /// Raw samples. Frame size is whatever the capture platform produced and is
  /// explicitly NOT constant, so the server must not infer timing from the
  /// number of bytes in any single message.
  @$pb.TagNumber(2)
  $core.List<$core.int> get audio => $_getN(1);
  @$pb.TagNumber(2)
  set audio($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAudio() => $_has(1);
  @$pb.TagNumber(2)
  void clearAudio() => $_clearField(2);
}

class TranscribeConfig extends $pb.GeneratedMessage {
  factory TranscribeConfig({
    $core.int? sampleRateHz,
    $core.int? channels,
    AudioEncoding? encoding,
    $core.String? language,
    $core.String? model,
  }) {
    final result = create();
    if (sampleRateHz != null) result.sampleRateHz = sampleRateHz;
    if (channels != null) result.channels = channels;
    if (encoding != null) result.encoding = encoding;
    if (language != null) result.language = language;
    if (model != null) result.model = model;
    return result;
  }

  TranscribeConfig._();

  factory TranscribeConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TranscribeConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TranscribeConfig',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'cornball.voice.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'sampleRateHz',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'channels', fieldType: $pb.PbFieldType.OU3)
    ..aE<AudioEncoding>(3, _omitFieldNames ? '' : 'encoding',
        enumValues: AudioEncoding.values)
    ..aOS(4, _omitFieldNames ? '' : 'language')
    ..aOS(5, _omitFieldNames ? '' : 'model')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TranscribeConfig clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TranscribeConfig copyWith(void Function(TranscribeConfig) updates) =>
      super.copyWith((message) => updates(message as TranscribeConfig))
          as TranscribeConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TranscribeConfig create() => TranscribeConfig._();
  @$core.override
  TranscribeConfig createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TranscribeConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TranscribeConfig>(create);
  static TranscribeConfig? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get sampleRateHz => $_getIZ(0);
  @$pb.TagNumber(1)
  set sampleRateHz($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSampleRateHz() => $_has(0);
  @$pb.TagNumber(1)
  void clearSampleRateHz() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get channels => $_getIZ(1);
  @$pb.TagNumber(2)
  set channels($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChannels() => $_has(1);
  @$pb.TagNumber(2)
  void clearChannels() => $_clearField(2);

  @$pb.TagNumber(3)
  AudioEncoding get encoding => $_getN(2);
  @$pb.TagNumber(3)
  set encoding(AudioEncoding value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasEncoding() => $_has(2);
  @$pb.TagNumber(3)
  void clearEncoding() => $_clearField(3);

  /// BCP-47. Empty means let the model decide.
  @$pb.TagNumber(4)
  $core.String get language => $_getSZ(3);
  @$pb.TagNumber(4)
  set language($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLanguage() => $_has(3);
  @$pb.TagNumber(4)
  void clearLanguage() => $_clearField(4);

  /// Empty means the host's resident default.
  @$pb.TagNumber(5)
  $core.String get model => $_getSZ(4);
  @$pb.TagNumber(5)
  set model($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasModel() => $_has(4);
  @$pb.TagNumber(5)
  void clearModel() => $_clearField(5);
}

enum TranscribeEvent_Event { transcript, speechEnded, notSet }

class TranscribeEvent extends $pb.GeneratedMessage {
  factory TranscribeEvent({
    Transcript? transcript,
    SpeechEnded? speechEnded,
  }) {
    final result = create();
    if (transcript != null) result.transcript = transcript;
    if (speechEnded != null) result.speechEnded = speechEnded;
    return result;
  }

  TranscribeEvent._();

  factory TranscribeEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TranscribeEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, TranscribeEvent_Event>
      _TranscribeEvent_EventByTag = {
    1: TranscribeEvent_Event.transcript,
    2: TranscribeEvent_Event.speechEnded,
    0: TranscribeEvent_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TranscribeEvent',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'cornball.voice.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<Transcript>(1, _omitFieldNames ? '' : 'transcript',
        subBuilder: Transcript.create)
    ..aOM<SpeechEnded>(2, _omitFieldNames ? '' : 'speechEnded',
        subBuilder: SpeechEnded.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TranscribeEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TranscribeEvent copyWith(void Function(TranscribeEvent) updates) =>
      super.copyWith((message) => updates(message as TranscribeEvent))
          as TranscribeEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TranscribeEvent create() => TranscribeEvent._();
  @$core.override
  TranscribeEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TranscribeEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TranscribeEvent>(create);
  static TranscribeEvent? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  TranscribeEvent_Event whichEvent() =>
      _TranscribeEvent_EventByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearEvent() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  Transcript get transcript => $_getN(0);
  @$pb.TagNumber(1)
  set transcript(Transcript value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTranscript() => $_has(0);
  @$pb.TagNumber(1)
  void clearTranscript() => $_clearField(1);
  @$pb.TagNumber(1)
  Transcript ensureTranscript() => $_ensure(0);

  @$pb.TagNumber(2)
  SpeechEnded get speechEnded => $_getN(1);
  @$pb.TagNumber(2)
  set speechEnded(SpeechEnded value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSpeechEnded() => $_has(1);
  @$pb.TagNumber(2)
  void clearSpeechEnded() => $_clearField(2);
  @$pb.TagNumber(2)
  SpeechEnded ensureSpeechEnded() => $_ensure(1);
}

class Transcript extends $pb.GeneratedMessage {
  factory Transcript({
    $core.String? text,
    $core.bool? stable,
  }) {
    final result = create();
    if (text != null) result.text = text;
    if (stable != null) result.stable = stable;
    return result;
  }

  Transcript._();

  factory Transcript.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Transcript.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Transcript',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'cornball.voice.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..aOB(2, _omitFieldNames ? '' : 'stable')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Transcript clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Transcript copyWith(void Function(Transcript) updates) =>
      super.copyWith((message) => updates(message as Transcript)) as Transcript;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Transcript create() => Transcript._();
  @$core.override
  Transcript createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Transcript getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Transcript>(create);
  static Transcript? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);

  /// True once this text will not be revised. A provisional transcript
  /// REPLACES the previous provisional one rather than appending to it, so a
  /// client renders the last provisional it saw, not the concatenation.
  @$pb.TagNumber(2)
  $core.bool get stable => $_getBF(1);
  @$pb.TagNumber(2)
  set stable($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStable() => $_has(1);
  @$pb.TagNumber(2)
  void clearStable() => $_clearField(2);
}

/// Endpointing: the model's judgment that the speaker finished a turn.
///
/// Deliberately server side. The client has an energy-threshold barge-in
/// detector, but that decides "stop the speaker now", which is a different
/// question from "the human's turn is over" and cannot answer it. A pause for
/// breath and the end of a sentence look identical to an energy threshold.
class SpeechEnded extends $pb.GeneratedMessage {
  factory SpeechEnded({
    $fixnum.Int64? audioOffsetMs,
  }) {
    final result = create();
    if (audioOffsetMs != null) result.audioOffsetMs = audioOffsetMs;
    return result;
  }

  SpeechEnded._();

  factory SpeechEnded.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SpeechEnded.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SpeechEnded',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'cornball.voice.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'audioOffsetMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SpeechEnded clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SpeechEnded copyWith(void Function(SpeechEnded) updates) =>
      super.copyWith((message) => updates(message as SpeechEnded))
          as SpeechEnded;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SpeechEnded create() => SpeechEnded._();
  @$core.override
  SpeechEnded createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SpeechEnded getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SpeechEnded>(create);
  static SpeechEnded? _defaultInstance;

  /// Offset into the audio stream where the turn ended, so a client can
  /// attribute it against what it sent.
  @$pb.TagNumber(1)
  $fixnum.Int64 get audioOffsetMs => $_getI64(0);
  @$pb.TagNumber(1)
  set audioOffsetMs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAudioOffsetMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearAudioOffsetMs() => $_clearField(1);
}

class SynthesizeRequest extends $pb.GeneratedMessage {
  factory SynthesizeRequest({
    $core.String? text,
    $core.String? voice,
    $core.String? model,
    $core.int? sampleRateHz,
  }) {
    final result = create();
    if (text != null) result.text = text;
    if (voice != null) result.voice = voice;
    if (model != null) result.model = model;
    if (sampleRateHz != null) result.sampleRateHz = sampleRateHz;
    return result;
  }

  SynthesizeRequest._();

  factory SynthesizeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SynthesizeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SynthesizeRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'cornball.voice.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..aOS(2, _omitFieldNames ? '' : 'voice')
    ..aOS(3, _omitFieldNames ? '' : 'model')
    ..aI(4, _omitFieldNames ? '' : 'sampleRateHz',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SynthesizeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SynthesizeRequest copyWith(void Function(SynthesizeRequest) updates) =>
      super.copyWith((message) => updates(message as SynthesizeRequest))
          as SynthesizeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SynthesizeRequest create() => SynthesizeRequest._();
  @$core.override
  SynthesizeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SynthesizeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SynthesizeRequest>(create);
  static SynthesizeRequest? _defaultInstance;

  /// Text to speak, exactly as the caller holds it. Offsets in AudioChunk
  /// index into THIS string, so the synthesiser must compute them against the
  /// input as received, before any internal normalisation (numbers read as
  /// words, abbreviations expanded, and so on).
  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get voice => $_getSZ(1);
  @$pb.TagNumber(2)
  set voice($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVoice() => $_has(1);
  @$pb.TagNumber(2)
  void clearVoice() => $_clearField(2);

  /// Empty means the host's resident default.
  @$pb.TagNumber(3)
  $core.String get model => $_getSZ(2);
  @$pb.TagNumber(3)
  set model($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasModel() => $_has(2);
  @$pb.TagNumber(3)
  void clearModel() => $_clearField(3);

  /// 0 means the model's native rate.
  @$pb.TagNumber(4)
  $core.int get sampleRateHz => $_getIZ(3);
  @$pb.TagNumber(4)
  set sampleRateHz($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSampleRateHz() => $_has(3);
  @$pb.TagNumber(4)
  void clearSampleRateHz() => $_clearField(4);
}

enum SynthesisEvent_Event { start, chunk, notSet }

class SynthesisEvent extends $pb.GeneratedMessage {
  factory SynthesisEvent({
    SynthesisStart? start,
    AudioChunk? chunk,
  }) {
    final result = create();
    if (start != null) result.start = start;
    if (chunk != null) result.chunk = chunk;
    return result;
  }

  SynthesisEvent._();

  factory SynthesisEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SynthesisEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, SynthesisEvent_Event>
      _SynthesisEvent_EventByTag = {
    1: SynthesisEvent_Event.start,
    2: SynthesisEvent_Event.chunk,
    0: SynthesisEvent_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SynthesisEvent',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'cornball.voice.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<SynthesisStart>(1, _omitFieldNames ? '' : 'start',
        subBuilder: SynthesisStart.create)
    ..aOM<AudioChunk>(2, _omitFieldNames ? '' : 'chunk',
        subBuilder: AudioChunk.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SynthesisEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SynthesisEvent copyWith(void Function(SynthesisEvent) updates) =>
      super.copyWith((message) => updates(message as SynthesisEvent))
          as SynthesisEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SynthesisEvent create() => SynthesisEvent._();
  @$core.override
  SynthesisEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SynthesisEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SynthesisEvent>(create);
  static SynthesisEvent? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  SynthesisEvent_Event whichEvent() =>
      _SynthesisEvent_EventByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearEvent() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  SynthesisStart get start => $_getN(0);
  @$pb.TagNumber(1)
  set start(SynthesisStart value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStart() => $_has(0);
  @$pb.TagNumber(1)
  void clearStart() => $_clearField(1);
  @$pb.TagNumber(1)
  SynthesisStart ensureStart() => $_ensure(0);

  @$pb.TagNumber(2)
  AudioChunk get chunk => $_getN(1);
  @$pb.TagNumber(2)
  set chunk(AudioChunk value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasChunk() => $_has(1);
  @$pb.TagNumber(2)
  void clearChunk() => $_clearField(2);
  @$pb.TagNumber(2)
  AudioChunk ensureChunk() => $_ensure(1);
}

/// MUST be the first event on the stream, exactly once. A chunk arriving
/// before it is a server bug the client treats as INTERNAL and hangs up on:
/// playing audio at a guessed sample rate produces plausible sound at the
/// wrong pitch and no error.
///
/// Audio is always mono. A second channel doubles the bytes and carries
/// nothing; a synthesiser that only produces stereo downmixes before sending.
class SynthesisStart extends $pb.GeneratedMessage {
  factory SynthesisStart({
    $core.int? totalChunks,
    $core.int? sampleRateHz,
    AudioEncoding? encoding,
  }) {
    final result = create();
    if (totalChunks != null) result.totalChunks = totalChunks;
    if (sampleRateHz != null) result.sampleRateHz = sampleRateHz;
    if (encoding != null) result.encoding = encoding;
    return result;
  }

  SynthesisStart._();

  factory SynthesisStart.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SynthesisStart.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SynthesisStart',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'cornball.voice.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'totalChunks',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'sampleRateHz',
        fieldType: $pb.PbFieldType.OU3)
    ..aE<AudioEncoding>(3, _omitFieldNames ? '' : 'encoding',
        enumValues: AudioEncoding.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SynthesisStart clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SynthesisStart copyWith(void Function(SynthesisStart) updates) =>
      super.copyWith((message) => updates(message as SynthesisStart))
          as SynthesisStart;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SynthesisStart create() => SynthesisStart._();
  @$core.override
  SynthesisStart createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SynthesisStart getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SynthesisStart>(create);
  static SynthesisStart? _defaultInstance;

  /// How many chunks will be sent, when the synthesiser knows in advance.
  ///
  /// `optional` on purpose: absent and zero are different states, and a client
  /// reporting how many chunks were dropped needs to tell "none were dropped"
  /// apart from "the server never said". Collapsing those two into 0 is how a
  /// truncation report ends up plausible and wrong.
  @$pb.TagNumber(1)
  $core.int get totalChunks => $_getIZ(0);
  @$pb.TagNumber(1)
  set totalChunks($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTotalChunks() => $_has(0);
  @$pb.TagNumber(1)
  void clearTotalChunks() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get sampleRateHz => $_getIZ(1);
  @$pb.TagNumber(2)
  set sampleRateHz($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSampleRateHz() => $_has(1);
  @$pb.TagNumber(2)
  void clearSampleRateHz() => $_clearField(2);

  @$pb.TagNumber(3)
  AudioEncoding get encoding => $_getN(2);
  @$pb.TagNumber(3)
  set encoding(AudioEncoding value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasEncoding() => $_has(2);
  @$pb.TagNumber(3)
  void clearEncoding() => $_clearField(3);
}

class AudioChunk extends $pb.GeneratedMessage {
  factory AudioChunk({
    $core.int? index,
    $core.int? durationMs,
    $core.List<$core.int>? pcm,
    $core.int? inputTextEnd,
  }) {
    final result = create();
    if (index != null) result.index = index;
    if (durationMs != null) result.durationMs = durationMs;
    if (pcm != null) result.pcm = pcm;
    if (inputTextEnd != null) result.inputTextEnd = inputTextEnd;
    return result;
  }

  AudioChunk._();

  factory AudioChunk.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AudioChunk.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioChunk',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'cornball.voice.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'index', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'durationMs', fieldType: $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'pcm', $pb.PbFieldType.OY)
    ..aI(4, _omitFieldNames ? '' : 'inputTextEnd',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioChunk clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioChunk copyWith(void Function(AudioChunk) updates) =>
      super.copyWith((message) => updates(message as AudioChunk)) as AudioChunk;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AudioChunk create() => AudioChunk._();
  @$core.override
  AudioChunk createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AudioChunk getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AudioChunk>(create);
  static AudioChunk? _defaultInstance;

  /// ZERO-BASED. Diagnostic only.
  ///
  /// Pinned here because this is the field where the two ends disagree by
  /// default: the synthesis side is written in a one-based language whose emit
  /// loop naturally hands out 1 for the first chunk, while the wire and the
  /// Dart client start at 0. Neither default is unreasonable, which is why the
  /// convention has to be stated at the field rather than assumed at either
  /// end.
  ///
  /// Clients do not do arithmetic with this. How much of a reply was heard is
  /// reported as a count (see AgentVoice.ReportTurn), which carries no base and
  /// no inclusivity convention and therefore has no conversion site to get
  /// wrong.
  @$pb.TagNumber(1)
  $core.int get index => $_getIZ(0);
  @$pb.TagNumber(1)
  set index($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearIndex() => $_clearField(1);

  /// Full playable length of this chunk. The client needs it to decide whether
  /// a chunk cut mid-playback counts as heard, without reading a clock itself.
  @$pb.TagNumber(2)
  $core.int get durationMs => $_getIZ(1);
  @$pb.TagNumber(2)
  set durationMs($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDurationMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearDurationMs() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get pcm => $_getN(2);
  @$pb.TagNumber(3)
  set pcm($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPcm() => $_has(2);
  @$pb.TagNumber(3)
  void clearPcm() => $_clearField(3);

  /// Cumulative end of the text this chunk voices, as a count of Unicode code
  /// points into SynthesizeRequest.text as received. After hearing this chunk
  /// in full, the listener has heard the first `input_text_end` code points of
  /// the input. A chunk that voices no text (silence, breath, prosody padding)
  /// repeats the previous chunk's value.
  ///
  /// REQUIRED ON EVERY CHUNK, and `optional` precisely so that requirement is
  /// checkable: zero is a legitimate value (a leading-silence first chunk),
  /// so without presence a synthesiser that never implements this field is
  /// indistinguishable from one reporting nothing voiced yet -- every offset
  /// reads 0, the client reports text_heard 0, and a fully-heard reply is
  /// stored as never spoken. The client treats a chunk with the field absent
  /// as a server bug: INTERNAL, hang up.
  ///
  /// This field exists because only the synthesiser knows how it split text
  /// into audio, and truncation is meaningless in chunks: the agent storing
  /// "what was actually said" needs a TEXT boundary. Without it, a chunk count
  /// reaches the agent and there is nothing the agent can do with it -- the
  /// chunk-to-text mapping died inside this service. Cumulative counts also
  /// survive chunk merging: however chunks are split or coalesced, the last
  /// heard chunk's value is always the answer.
  ///
  /// Code points, not bytes and not UTF-16 units, because the two ends
  /// disagree by default here too: this side's language counts characters,
  /// the client's counts UTF-16 code units, and the wire carries UTF-8.
  /// Code points are the one unit everyone can produce exactly.
  @$pb.TagNumber(4)
  $core.int get inputTextEnd => $_getIZ(3);
  @$pb.TagNumber(4)
  set inputTextEnd($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasInputTextEnd() => $_has(3);
  @$pb.TagNumber(4)
  void clearInputTextEnd() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');

// This is a generated file - do not edit.
//
// Generated from agent_voice.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'agent_voice.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'agent_voice.pbenum.dart';

class AllocateVoiceRequest extends $pb.GeneratedMessage {
  factory AllocateVoiceRequest({
    $core.String? roomId,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    return result;
  }

  AllocateVoiceRequest._();

  factory AllocateVoiceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AllocateVoiceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AllocateVoiceRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'cornball.agent.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'roomId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AllocateVoiceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AllocateVoiceRequest copyWith(void Function(AllocateVoiceRequest) updates) =>
      super.copyWith((message) => updates(message as AllocateVoiceRequest))
          as AllocateVoiceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AllocateVoiceRequest create() => AllocateVoiceRequest._();
  @$core.override
  AllocateVoiceRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AllocateVoiceRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AllocateVoiceRequest>(create);
  static AllocateVoiceRequest? _defaultInstance;

  /// Matrix room the conversation belongs to.
  @$pb.TagNumber(1)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomId() => $_clearField(1);
}

class AllocateVoiceResponse extends $pb.GeneratedMessage {
  factory AllocateVoiceResponse({
    $core.String? sessionId,
    Endpoint? speechToText,
    Endpoint? textToSpeech,
    $core.String? token,
    $fixnum.Int64? expiresAtUnixMs,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (speechToText != null) result.speechToText = speechToText;
    if (textToSpeech != null) result.textToSpeech = textToSpeech;
    if (token != null) result.token = token;
    if (expiresAtUnixMs != null) result.expiresAtUnixMs = expiresAtUnixMs;
    return result;
  }

  AllocateVoiceResponse._();

  factory AllocateVoiceResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AllocateVoiceResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AllocateVoiceResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'cornball.agent.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOM<Endpoint>(2, _omitFieldNames ? '' : 'speechToText',
        subBuilder: Endpoint.create)
    ..aOM<Endpoint>(3, _omitFieldNames ? '' : 'textToSpeech',
        subBuilder: Endpoint.create)
    ..aOS(4, _omitFieldNames ? '' : 'token')
    ..aInt64(5, _omitFieldNames ? '' : 'expiresAtUnixMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AllocateVoiceResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AllocateVoiceResponse copyWith(
          void Function(AllocateVoiceResponse) updates) =>
      super.copyWith((message) => updates(message as AllocateVoiceResponse))
          as AllocateVoiceResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AllocateVoiceResponse create() => AllocateVoiceResponse._();
  @$core.override
  AllocateVoiceResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AllocateVoiceResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AllocateVoiceResponse>(create);
  static AllocateVoiceResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Where the client opens its two media streams. Separate fields rather than
  /// one host because the two models need not be co-resident.
  @$pb.TagNumber(2)
  Endpoint get speechToText => $_getN(1);
  @$pb.TagNumber(2)
  set speechToText(Endpoint value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSpeechToText() => $_has(1);
  @$pb.TagNumber(2)
  void clearSpeechToText() => $_clearField(2);
  @$pb.TagNumber(2)
  Endpoint ensureSpeechToText() => $_ensure(1);

  @$pb.TagNumber(3)
  Endpoint get textToSpeech => $_getN(2);
  @$pb.TagNumber(3)
  set textToSpeech(Endpoint value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasTextToSpeech() => $_has(2);
  @$pb.TagNumber(3)
  void clearTextToSpeech() => $_clearField(3);
  @$pb.TagNumber(3)
  Endpoint ensureTextToSpeech() => $_ensure(2);

  /// Allocation-scoped bearer, sent by the client to the endpoints above as
  /// `authorization: Bearer <token>`.
  ///
  /// Short lived and scoped to this allocation. The client is a Matrix client
  /// that runs on phones, so it must never hold the long-lived host credential:
  /// a leak of this one expires, and cannot be replayed against another
  /// allocation.
  @$pb.TagNumber(4)
  $core.String get token => $_getSZ(3);
  @$pb.TagNumber(4)
  set token($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasToken() => $_has(3);
  @$pb.TagNumber(4)
  void clearToken() => $_clearField(4);

  /// Absolute expiry, not a duration, so a client with a slow start does not
  /// measure the TTL from the wrong instant.
  @$pb.TagNumber(5)
  $fixnum.Int64 get expiresAtUnixMs => $_getI64(4);
  @$pb.TagNumber(5)
  set expiresAtUnixMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasExpiresAtUnixMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearExpiresAtUnixMs() => $_clearField(5);
}

class Endpoint extends $pb.GeneratedMessage {
  factory Endpoint({
    $core.String? host,
    $core.int? port,
    ChannelSecurity? security,
  }) {
    final result = create();
    if (host != null) result.host = host;
    if (port != null) result.port = port;
    if (security != null) result.security = security;
    return result;
  }

  Endpoint._();

  factory Endpoint.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Endpoint.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Endpoint',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'cornball.agent.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'host')
    ..aI(2, _omitFieldNames ? '' : 'port', fieldType: $pb.PbFieldType.OU3)
    ..aE<ChannelSecurity>(3, _omitFieldNames ? '' : 'security',
        enumValues: ChannelSecurity.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Endpoint clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Endpoint copyWith(void Function(Endpoint) updates) =>
      super.copyWith((message) => updates(message as Endpoint)) as Endpoint;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Endpoint create() => Endpoint._();
  @$core.override
  Endpoint createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Endpoint getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Endpoint>(create);
  static Endpoint? _defaultInstance;

  /// Tailnet name. Resolution is the tailnet's job.
  @$pb.TagNumber(1)
  $core.String get host => $_getSZ(0);
  @$pb.TagNumber(1)
  set host($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasHost() => $_has(0);
  @$pb.TagNumber(1)
  void clearHost() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get port => $_getIZ(1);
  @$pb.TagNumber(2)
  set port($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPort() => $_has(1);
  @$pb.TagNumber(2)
  void clearPort() => $_clearField(2);

  /// The server's declared transport security. Three states on purpose: a
  /// plain bool cannot tell "the server said insecure" from "the server said
  /// nothing" (proto3 serialises false as absent), which silently turns
  /// absence into an insecure default -- the exact opposite of a declaration.
  /// A client receiving UNSPECIFIED refuses to connect.
  @$pb.TagNumber(3)
  ChannelSecurity get security => $_getN(2);
  @$pb.TagNumber(3)
  set security(ChannelSecurity value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSecurity() => $_has(2);
  @$pb.TagNumber(3)
  void clearSecurity() => $_clearField(3);
}

class ConverseRequest extends $pb.GeneratedMessage {
  factory ConverseRequest({
    $core.String? sessionId,
    $core.String? text,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (text != null) result.text = text;
    return result;
  }

  ConverseRequest._();

  factory ConverseRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ConverseRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConverseRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'cornball.agent.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConverseRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConverseRequest copyWith(void Function(ConverseRequest) updates) =>
      super.copyWith((message) => updates(message as ConverseRequest))
          as ConverseRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConverseRequest create() => ConverseRequest._();
  @$core.override
  ConverseRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ConverseRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ConverseRequest>(create);
  static ConverseRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Stable transcript of what the user said, as returned by SpeechToText.
  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => $_clearField(2);
}

enum ConverseEvent_Event { start, delta, end, notSet }

class ConverseEvent extends $pb.GeneratedMessage {
  factory ConverseEvent({
    TurnStart? start,
    TextDelta? delta,
    TurnEnd? end,
  }) {
    final result = create();
    if (start != null) result.start = start;
    if (delta != null) result.delta = delta;
    if (end != null) result.end = end;
    return result;
  }

  ConverseEvent._();

  factory ConverseEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ConverseEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ConverseEvent_Event>
      _ConverseEvent_EventByTag = {
    1: ConverseEvent_Event.start,
    2: ConverseEvent_Event.delta,
    3: ConverseEvent_Event.end,
    0: ConverseEvent_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConverseEvent',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'cornball.agent.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3])
    ..aOM<TurnStart>(1, _omitFieldNames ? '' : 'start',
        subBuilder: TurnStart.create)
    ..aOM<TextDelta>(2, _omitFieldNames ? '' : 'delta',
        subBuilder: TextDelta.create)
    ..aOM<TurnEnd>(3, _omitFieldNames ? '' : 'end', subBuilder: TurnEnd.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConverseEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConverseEvent copyWith(void Function(ConverseEvent) updates) =>
      super.copyWith((message) => updates(message as ConverseEvent))
          as ConverseEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConverseEvent create() => ConverseEvent._();
  @$core.override
  ConverseEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ConverseEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ConverseEvent>(create);
  static ConverseEvent? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  ConverseEvent_Event whichEvent() =>
      _ConverseEvent_EventByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  void clearEvent() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  TurnStart get start => $_getN(0);
  @$pb.TagNumber(1)
  set start(TurnStart value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStart() => $_has(0);
  @$pb.TagNumber(1)
  void clearStart() => $_clearField(1);
  @$pb.TagNumber(1)
  TurnStart ensureStart() => $_ensure(0);

  @$pb.TagNumber(2)
  TextDelta get delta => $_getN(1);
  @$pb.TagNumber(2)
  set delta(TextDelta value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDelta() => $_has(1);
  @$pb.TagNumber(2)
  void clearDelta() => $_clearField(2);
  @$pb.TagNumber(2)
  TextDelta ensureDelta() => $_ensure(1);

  @$pb.TagNumber(3)
  TurnEnd get end => $_getN(2);
  @$pb.TagNumber(3)
  set end(TurnEnd value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasEnd() => $_has(2);
  @$pb.TagNumber(3)
  void clearEnd() => $_clearField(3);
  @$pb.TagNumber(3)
  TurnEnd ensureEnd() => $_ensure(2);
}

class TurnStart extends $pb.GeneratedMessage {
  factory TurnStart({
    $core.String? turnId,
  }) {
    final result = create();
    if (turnId != null) result.turnId = turnId;
    return result;
  }

  TurnStart._();

  factory TurnStart.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TurnStart.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TurnStart',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'cornball.agent.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'turnId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TurnStart clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TurnStart copyWith(void Function(TurnStart) updates) =>
      super.copyWith((message) => updates(message as TurnStart)) as TurnStart;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TurnStart create() => TurnStart._();
  @$core.override
  TurnStart createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TurnStart getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TurnStart>(create);
  static TurnStart? _defaultInstance;

  /// Identifies this reply for ReportTurn. The client cannot use the Matrix
  /// event id: the message has not been sent yet, and what finally gets stored
  /// depends on how much of the reply the user heard.
  @$pb.TagNumber(1)
  $core.String get turnId => $_getSZ(0);
  @$pb.TagNumber(1)
  set turnId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTurnId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTurnId() => $_clearField(1);
}

class TextDelta extends $pb.GeneratedMessage {
  factory TextDelta({
    $core.String? text,
  }) {
    final result = create();
    if (text != null) result.text = text;
    return result;
  }

  TextDelta._();

  factory TextDelta.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TextDelta.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TextDelta',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'cornball.agent.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TextDelta clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TextDelta copyWith(void Function(TextDelta) updates) =>
      super.copyWith((message) => updates(message as TextDelta)) as TextDelta;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TextDelta create() => TextDelta._();
  @$core.override
  TextDelta createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TextDelta getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TextDelta>(create);
  static TextDelta? _defaultInstance;

  /// Appended to what came before, unlike a provisional transcript, which
  /// replaces.
  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);
}

class TurnEnd extends $pb.GeneratedMessage {
  factory TurnEnd({
    $core.String? stopReason,
  }) {
    final result = create();
    if (stopReason != null) result.stopReason = stopReason;
    return result;
  }

  TurnEnd._();

  factory TurnEnd.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TurnEnd.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TurnEnd',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'cornball.agent.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'stopReason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TurnEnd clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TurnEnd copyWith(void Function(TurnEnd) updates) =>
      super.copyWith((message) => updates(message as TurnEnd)) as TurnEnd;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TurnEnd create() => TurnEnd._();
  @$core.override
  TurnEnd createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TurnEnd getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TurnEnd>(create);
  static TurnEnd? _defaultInstance;

  /// Set when generation stopped early rather than completing.
  @$pb.TagNumber(1)
  $core.String get stopReason => $_getSZ(0);
  @$pb.TagNumber(1)
  set stopReason($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStopReason() => $_has(0);
  @$pb.TagNumber(1)
  void clearStopReason() => $_clearField(1);
}

class ReportTurnRequest extends $pb.GeneratedMessage {
  factory ReportTurnRequest({
    $core.String? sessionId,
    $core.String? turnId,
    $core.int? textHeard,
    TurnOutcome? outcome,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (turnId != null) result.turnId = turnId;
    if (textHeard != null) result.textHeard = textHeard;
    if (outcome != null) result.outcome = outcome;
    return result;
  }

  ReportTurnRequest._();

  factory ReportTurnRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReportTurnRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReportTurnRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'cornball.agent.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'turnId')
    ..aI(3, _omitFieldNames ? '' : 'textHeard', fieldType: $pb.PbFieldType.OU3)
    ..aE<TurnOutcome>(4, _omitFieldNames ? '' : 'outcome',
        enumValues: TurnOutcome.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReportTurnRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReportTurnRequest copyWith(void Function(ReportTurnRequest) updates) =>
      super.copyWith((message) => updates(message as ReportTurnRequest))
          as ReportTurnRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReportTurnRequest create() => ReportTurnRequest._();
  @$core.override
  ReportTurnRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReportTurnRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReportTurnRequest>(create);
  static ReportTurnRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get turnId => $_getSZ(1);
  @$pb.TagNumber(2)
  set turnId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTurnId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTurnId() => $_clearField(2);

  /// How much of the reply was actually heard, as a count of Unicode code
  /// points of the turn's text (the TextDelta stream, concatenated in order).
  /// The agent stores that prefix; zero explicitly means nothing was heard.
  ///
  /// REQUIRED, and `optional` for exactly that reason: zero is a legitimate
  /// report (barge-in before the first word), so the field needs presence to
  /// keep "reported zero" apart from "never reported" -- an implicit uint32
  /// drops an explicit 0 from the wire and the two collapse. The agent rejects
  /// a request with the field absent (INVALID_ARGUMENT) instead of reading it
  /// as zero, which would erase a fully-heard reply from history on the say-so
  /// of a client that said nothing.
  ///
  /// A TEXT offset, not a chunk count, because the chunk-to-text mapping
  /// exists only inside the synthesiser. A chunk count arriving here is
  /// unusable: the agent never saw how its text was split into audio. The
  /// client converts where the data lives -- it takes the input_text_end of
  /// the last chunk playback counted as heard (the client's midpoint rule; see
  /// AudioChunk in the inference schema) and maps it through its own record of
  /// which slice of the reply each Synthesize call covered.
  ///
  /// A cumulative count rather than an index for the usual reason: an index
  /// carries a base and an inclusivity convention, each silently wrong on its
  /// own; a count carries neither, so there is no conversion site to get
  /// wrong. Code points rather than bytes or UTF-16 units because that is the
  /// one unit both ends can produce exactly.
  ///
  /// Distinct from where generation was cancelled. Text generated is a superset
  /// of text spoken, so the two truncation points do not coincide and this one
  /// cuts further back. Storing the generation cut instead attributes unspoken
  /// sentences to the assistant.
  @$pb.TagNumber(3)
  $core.int get textHeard => $_getIZ(2);
  @$pb.TagNumber(3)
  set textHeard($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTextHeard() => $_has(2);
  @$pb.TagNumber(3)
  void clearTextHeard() => $_clearField(3);

  /// Why the reply was cut, for the record.
  @$pb.TagNumber(4)
  TurnOutcome get outcome => $_getN(3);
  @$pb.TagNumber(4)
  set outcome(TurnOutcome value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasOutcome() => $_has(3);
  @$pb.TagNumber(4)
  void clearOutcome() => $_clearField(4);
}

class ReportTurnResponse extends $pb.GeneratedMessage {
  factory ReportTurnResponse({
    $core.String? storedText,
  }) {
    final result = create();
    if (storedText != null) result.storedText = storedText;
    return result;
  }

  ReportTurnResponse._();

  factory ReportTurnResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReportTurnResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReportTurnResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'cornball.agent.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'storedText')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReportTurnResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReportTurnResponse copyWith(void Function(ReportTurnResponse) updates) =>
      super.copyWith((message) => updates(message as ReportTurnResponse))
          as ReportTurnResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReportTurnResponse create() => ReportTurnResponse._();
  @$core.override
  ReportTurnResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReportTurnResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReportTurnResponse>(create);
  static ReportTurnResponse? _defaultInstance;

  /// What the agent actually stored: the first text_heard code points of the
  /// reply, possibly tidied to a word boundary. Returned so the client can
  /// render the same text the room history holds rather than its own guess at
  /// where the cut landed.
  @$pb.TagNumber(1)
  $core.String get storedText => $_getSZ(0);
  @$pb.TagNumber(1)
  set storedText($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStoredText() => $_has(0);
  @$pb.TagNumber(1)
  void clearStoredText() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');

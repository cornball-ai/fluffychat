// This is a generated file - do not edit.
//
// Generated from agent_voice.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use turnOutcomeDescriptor instead')
const TurnOutcome$json = {
  '1': 'TurnOutcome',
  '2': [
    {'1': 'TURN_OUTCOME_UNSPECIFIED', '2': 0},
    {'1': 'TURN_OUTCOME_COMPLETED', '2': 1},
    {'1': 'TURN_OUTCOME_BARGE_IN', '2': 2},
    {'1': 'TURN_OUTCOME_ABANDONED', '2': 3},
  ],
};

/// Descriptor for `TurnOutcome`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List turnOutcomeDescriptor = $convert.base64Decode(
    'CgtUdXJuT3V0Y29tZRIcChhUVVJOX09VVENPTUVfVU5TUEVDSUZJRUQQABIaChZUVVJOX09VVE'
    'NPTUVfQ09NUExFVEVEEAESGQoVVFVSTl9PVVRDT01FX0JBUkdFX0lOEAISGgoWVFVSTl9PVVRD'
    'T01FX0FCQU5ET05FRBAD');

@$core.Deprecated('Use allocateVoiceRequestDescriptor instead')
const AllocateVoiceRequest$json = {
  '1': 'AllocateVoiceRequest',
  '2': [
    {'1': 'room_id', '3': 1, '4': 1, '5': 9, '10': 'roomId'},
  ],
};

/// Descriptor for `AllocateVoiceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List allocateVoiceRequestDescriptor =
    $convert.base64Decode(
        'ChRBbGxvY2F0ZVZvaWNlUmVxdWVzdBIXCgdyb29tX2lkGAEgASgJUgZyb29tSWQ=');

@$core.Deprecated('Use allocateVoiceResponseDescriptor instead')
const AllocateVoiceResponse$json = {
  '1': 'AllocateVoiceResponse',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {
      '1': 'speech_to_text',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.cornball.agent.v1.Endpoint',
      '10': 'speechToText'
    },
    {
      '1': 'text_to_speech',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.cornball.agent.v1.Endpoint',
      '10': 'textToSpeech'
    },
    {'1': 'token', '3': 4, '4': 1, '5': 9, '10': 'token'},
    {
      '1': 'expires_at_unix_ms',
      '3': 5,
      '4': 1,
      '5': 3,
      '10': 'expiresAtUnixMs'
    },
  ],
};

/// Descriptor for `AllocateVoiceResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List allocateVoiceResponseDescriptor = $convert.base64Decode(
    'ChVBbGxvY2F0ZVZvaWNlUmVzcG9uc2USHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEk'
    'EKDnNwZWVjaF90b190ZXh0GAIgASgLMhsuY29ybmJhbGwuYWdlbnQudjEuRW5kcG9pbnRSDHNw'
    'ZWVjaFRvVGV4dBJBCg50ZXh0X3RvX3NwZWVjaBgDIAEoCzIbLmNvcm5iYWxsLmFnZW50LnYxLk'
    'VuZHBvaW50Ugx0ZXh0VG9TcGVlY2gSFAoFdG9rZW4YBCABKAlSBXRva2VuEisKEmV4cGlyZXNf'
    'YXRfdW5peF9tcxgFIAEoA1IPZXhwaXJlc0F0VW5peE1z');

@$core.Deprecated('Use endpointDescriptor instead')
const Endpoint$json = {
  '1': 'Endpoint',
  '2': [
    {'1': 'host', '3': 1, '4': 1, '5': 9, '10': 'host'},
    {'1': 'port', '3': 2, '4': 1, '5': 13, '10': 'port'},
    {'1': 'tls', '3': 3, '4': 1, '5': 8, '10': 'tls'},
  ],
};

/// Descriptor for `Endpoint`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List endpointDescriptor = $convert.base64Decode(
    'CghFbmRwb2ludBISCgRob3N0GAEgASgJUgRob3N0EhIKBHBvcnQYAiABKA1SBHBvcnQSEAoDdG'
    'xzGAMgASgIUgN0bHM=');

@$core.Deprecated('Use converseRequestDescriptor instead')
const ConverseRequest$json = {
  '1': 'ConverseRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `ConverseRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List converseRequestDescriptor = $convert.base64Decode(
    'Cg9Db252ZXJzZVJlcXVlc3QSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEhIKBHRleH'
    'QYAiABKAlSBHRleHQ=');

@$core.Deprecated('Use converseEventDescriptor instead')
const ConverseEvent$json = {
  '1': 'ConverseEvent',
  '2': [
    {
      '1': 'start',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.cornball.agent.v1.TurnStart',
      '9': 0,
      '10': 'start'
    },
    {
      '1': 'delta',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.cornball.agent.v1.TextDelta',
      '9': 0,
      '10': 'delta'
    },
    {
      '1': 'end',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.cornball.agent.v1.TurnEnd',
      '9': 0,
      '10': 'end'
    },
  ],
  '8': [
    {'1': 'event'},
  ],
};

/// Descriptor for `ConverseEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List converseEventDescriptor = $convert.base64Decode(
    'Cg1Db252ZXJzZUV2ZW50EjQKBXN0YXJ0GAEgASgLMhwuY29ybmJhbGwuYWdlbnQudjEuVHVybl'
    'N0YXJ0SABSBXN0YXJ0EjQKBWRlbHRhGAIgASgLMhwuY29ybmJhbGwuYWdlbnQudjEuVGV4dERl'
    'bHRhSABSBWRlbHRhEi4KA2VuZBgDIAEoCzIaLmNvcm5iYWxsLmFnZW50LnYxLlR1cm5FbmRIAF'
    'IDZW5kQgcKBWV2ZW50');

@$core.Deprecated('Use turnStartDescriptor instead')
const TurnStart$json = {
  '1': 'TurnStart',
  '2': [
    {'1': 'turn_id', '3': 1, '4': 1, '5': 9, '10': 'turnId'},
  ],
};

/// Descriptor for `TurnStart`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List turnStartDescriptor =
    $convert.base64Decode('CglUdXJuU3RhcnQSFwoHdHVybl9pZBgBIAEoCVIGdHVybklk');

@$core.Deprecated('Use textDeltaDescriptor instead')
const TextDelta$json = {
  '1': 'TextDelta',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `TextDelta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List textDeltaDescriptor =
    $convert.base64Decode('CglUZXh0RGVsdGESEgoEdGV4dBgBIAEoCVIEdGV4dA==');

@$core.Deprecated('Use turnEndDescriptor instead')
const TurnEnd$json = {
  '1': 'TurnEnd',
  '2': [
    {'1': 'stop_reason', '3': 1, '4': 1, '5': 9, '10': 'stopReason'},
  ],
};

/// Descriptor for `TurnEnd`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List turnEndDescriptor = $convert
    .base64Decode('CgdUdXJuRW5kEh8KC3N0b3BfcmVhc29uGAEgASgJUgpzdG9wUmVhc29u');

@$core.Deprecated('Use reportTurnRequestDescriptor instead')
const ReportTurnRequest$json = {
  '1': 'ReportTurnRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'turn_id', '3': 2, '4': 1, '5': 9, '10': 'turnId'},
    {'1': 'chunks_heard', '3': 3, '4': 1, '5': 13, '10': 'chunksHeard'},
    {
      '1': 'outcome',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.cornball.agent.v1.TurnOutcome',
      '10': 'outcome'
    },
  ],
};

/// Descriptor for `ReportTurnRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reportTurnRequestDescriptor = $convert.base64Decode(
    'ChFSZXBvcnRUdXJuUmVxdWVzdBIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSFwoHdH'
    'Vybl9pZBgCIAEoCVIGdHVybklkEiEKDGNodW5rc19oZWFyZBgDIAEoDVILY2h1bmtzSGVhcmQS'
    'OAoHb3V0Y29tZRgEIAEoDjIeLmNvcm5iYWxsLmFnZW50LnYxLlR1cm5PdXRjb21lUgdvdXRjb2'
    '1l');

@$core.Deprecated('Use reportTurnResponseDescriptor instead')
const ReportTurnResponse$json = {
  '1': 'ReportTurnResponse',
  '2': [
    {'1': 'stored_text', '3': 1, '4': 1, '5': 9, '10': 'storedText'},
  ],
};

/// Descriptor for `ReportTurnResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reportTurnResponseDescriptor = $convert.base64Decode(
    'ChJSZXBvcnRUdXJuUmVzcG9uc2USHwoLc3RvcmVkX3RleHQYASABKAlSCnN0b3JlZFRleHQ=');

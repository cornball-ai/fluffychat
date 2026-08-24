// This is a generated file - do not edit.
//
// Generated from gpu_voice.proto.

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

@$core.Deprecated('Use audioEncodingDescriptor instead')
const AudioEncoding$json = {
  '1': 'AudioEncoding',
  '2': [
    {'1': 'AUDIO_ENCODING_UNSPECIFIED', '2': 0},
    {'1': 'AUDIO_ENCODING_PCM_S16LE', '2': 1},
  ],
};

/// Descriptor for `AudioEncoding`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List audioEncodingDescriptor = $convert.base64Decode(
    'Cg1BdWRpb0VuY29kaW5nEh4KGkFVRElPX0VOQ09ESU5HX1VOU1BFQ0lGSUVEEAASHAoYQVVESU'
    '9fRU5DT0RJTkdfUENNX1MxNkxFEAE=');

@$core.Deprecated('Use transcribeRequestDescriptor instead')
const TranscribeRequest$json = {
  '1': 'TranscribeRequest',
  '2': [
    {
      '1': 'config',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.cornball.voice.v1.TranscribeConfig',
      '9': 0,
      '10': 'config'
    },
    {'1': 'audio', '3': 2, '4': 1, '5': 12, '9': 0, '10': 'audio'},
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `TranscribeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transcribeRequestDescriptor = $convert.base64Decode(
    'ChFUcmFuc2NyaWJlUmVxdWVzdBI9CgZjb25maWcYASABKAsyIy5jb3JuYmFsbC52b2ljZS52MS'
    '5UcmFuc2NyaWJlQ29uZmlnSABSBmNvbmZpZxIWCgVhdWRpbxgCIAEoDEgAUgVhdWRpb0IJCgdw'
    'YXlsb2Fk');

@$core.Deprecated('Use transcribeConfigDescriptor instead')
const TranscribeConfig$json = {
  '1': 'TranscribeConfig',
  '2': [
    {'1': 'sample_rate_hz', '3': 1, '4': 1, '5': 13, '10': 'sampleRateHz'},
    {'1': 'channels', '3': 2, '4': 1, '5': 13, '10': 'channels'},
    {
      '1': 'encoding',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.cornball.voice.v1.AudioEncoding',
      '10': 'encoding'
    },
    {'1': 'language', '3': 4, '4': 1, '5': 9, '10': 'language'},
    {'1': 'model', '3': 5, '4': 1, '5': 9, '10': 'model'},
  ],
};

/// Descriptor for `TranscribeConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transcribeConfigDescriptor = $convert.base64Decode(
    'ChBUcmFuc2NyaWJlQ29uZmlnEiQKDnNhbXBsZV9yYXRlX2h6GAEgASgNUgxzYW1wbGVSYXRlSH'
    'oSGgoIY2hhbm5lbHMYAiABKA1SCGNoYW5uZWxzEjwKCGVuY29kaW5nGAMgASgOMiAuY29ybmJh'
    'bGwudm9pY2UudjEuQXVkaW9FbmNvZGluZ1IIZW5jb2RpbmcSGgoIbGFuZ3VhZ2UYBCABKAlSCG'
    'xhbmd1YWdlEhQKBW1vZGVsGAUgASgJUgVtb2RlbA==');

@$core.Deprecated('Use transcribeEventDescriptor instead')
const TranscribeEvent$json = {
  '1': 'TranscribeEvent',
  '2': [
    {
      '1': 'transcript',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.cornball.voice.v1.Transcript',
      '9': 0,
      '10': 'transcript'
    },
    {
      '1': 'speech_ended',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.cornball.voice.v1.SpeechEnded',
      '9': 0,
      '10': 'speechEnded'
    },
  ],
  '8': [
    {'1': 'event'},
  ],
};

/// Descriptor for `TranscribeEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transcribeEventDescriptor = $convert.base64Decode(
    'Cg9UcmFuc2NyaWJlRXZlbnQSPwoKdHJhbnNjcmlwdBgBIAEoCzIdLmNvcm5iYWxsLnZvaWNlLn'
    'YxLlRyYW5zY3JpcHRIAFIKdHJhbnNjcmlwdBJDCgxzcGVlY2hfZW5kZWQYAiABKAsyHi5jb3Ju'
    'YmFsbC52b2ljZS52MS5TcGVlY2hFbmRlZEgAUgtzcGVlY2hFbmRlZEIHCgVldmVudA==');

@$core.Deprecated('Use transcriptDescriptor instead')
const Transcript$json = {
  '1': 'Transcript',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
    {'1': 'stable', '3': 2, '4': 1, '5': 8, '10': 'stable'},
  ],
};

/// Descriptor for `Transcript`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transcriptDescriptor = $convert.base64Decode(
    'CgpUcmFuc2NyaXB0EhIKBHRleHQYASABKAlSBHRleHQSFgoGc3RhYmxlGAIgASgIUgZzdGFibG'
    'U=');

@$core.Deprecated('Use speechEndedDescriptor instead')
const SpeechEnded$json = {
  '1': 'SpeechEnded',
  '2': [
    {'1': 'audio_offset_ms', '3': 1, '4': 1, '5': 4, '10': 'audioOffsetMs'},
  ],
};

/// Descriptor for `SpeechEnded`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List speechEndedDescriptor = $convert.base64Decode(
    'CgtTcGVlY2hFbmRlZBImCg9hdWRpb19vZmZzZXRfbXMYASABKARSDWF1ZGlvT2Zmc2V0TXM=');

@$core.Deprecated('Use synthesizeRequestDescriptor instead')
const SynthesizeRequest$json = {
  '1': 'SynthesizeRequest',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
    {'1': 'voice', '3': 2, '4': 1, '5': 9, '10': 'voice'},
    {'1': 'model', '3': 3, '4': 1, '5': 9, '10': 'model'},
    {'1': 'sample_rate_hz', '3': 4, '4': 1, '5': 13, '10': 'sampleRateHz'},
  ],
};

/// Descriptor for `SynthesizeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List synthesizeRequestDescriptor = $convert.base64Decode(
    'ChFTeW50aGVzaXplUmVxdWVzdBISCgR0ZXh0GAEgASgJUgR0ZXh0EhQKBXZvaWNlGAIgASgJUg'
    'V2b2ljZRIUCgVtb2RlbBgDIAEoCVIFbW9kZWwSJAoOc2FtcGxlX3JhdGVfaHoYBCABKA1SDHNh'
    'bXBsZVJhdGVIeg==');

@$core.Deprecated('Use synthesisEventDescriptor instead')
const SynthesisEvent$json = {
  '1': 'SynthesisEvent',
  '2': [
    {
      '1': 'start',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.cornball.voice.v1.SynthesisStart',
      '9': 0,
      '10': 'start'
    },
    {
      '1': 'chunk',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.cornball.voice.v1.AudioChunk',
      '9': 0,
      '10': 'chunk'
    },
  ],
  '8': [
    {'1': 'event'},
  ],
};

/// Descriptor for `SynthesisEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List synthesisEventDescriptor = $convert.base64Decode(
    'Cg5TeW50aGVzaXNFdmVudBI5CgVzdGFydBgBIAEoCzIhLmNvcm5iYWxsLnZvaWNlLnYxLlN5bn'
    'RoZXNpc1N0YXJ0SABSBXN0YXJ0EjUKBWNodW5rGAIgASgLMh0uY29ybmJhbGwudm9pY2UudjEu'
    'QXVkaW9DaHVua0gAUgVjaHVua0IHCgVldmVudA==');

@$core.Deprecated('Use synthesisStartDescriptor instead')
const SynthesisStart$json = {
  '1': 'SynthesisStart',
  '2': [
    {
      '1': 'total_chunks',
      '3': 1,
      '4': 1,
      '5': 13,
      '9': 0,
      '10': 'totalChunks',
      '17': true
    },
    {'1': 'sample_rate_hz', '3': 2, '4': 1, '5': 13, '10': 'sampleRateHz'},
    {
      '1': 'encoding',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.cornball.voice.v1.AudioEncoding',
      '10': 'encoding'
    },
  ],
  '8': [
    {'1': '_total_chunks'},
  ],
};

/// Descriptor for `SynthesisStart`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List synthesisStartDescriptor = $convert.base64Decode(
    'Cg5TeW50aGVzaXNTdGFydBImCgx0b3RhbF9jaHVua3MYASABKA1IAFILdG90YWxDaHVua3OIAQ'
    'ESJAoOc2FtcGxlX3JhdGVfaHoYAiABKA1SDHNhbXBsZVJhdGVIehI8CghlbmNvZGluZxgDIAEo'
    'DjIgLmNvcm5iYWxsLnZvaWNlLnYxLkF1ZGlvRW5jb2RpbmdSCGVuY29kaW5nQg8KDV90b3RhbF'
    '9jaHVua3M=');

@$core.Deprecated('Use audioChunkDescriptor instead')
const AudioChunk$json = {
  '1': 'AudioChunk',
  '2': [
    {'1': 'index', '3': 1, '4': 1, '5': 13, '10': 'index'},
    {'1': 'duration_ms', '3': 2, '4': 1, '5': 13, '10': 'durationMs'},
    {'1': 'pcm', '3': 3, '4': 1, '5': 12, '10': 'pcm'},
  ],
};

/// Descriptor for `AudioChunk`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioChunkDescriptor = $convert.base64Decode(
    'CgpBdWRpb0NodW5rEhQKBWluZGV4GAEgASgNUgVpbmRleBIfCgtkdXJhdGlvbl9tcxgCIAEoDV'
    'IKZHVyYXRpb25NcxIQCgNwY20YAyABKAxSA3BjbQ==');

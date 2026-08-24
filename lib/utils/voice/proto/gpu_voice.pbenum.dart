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

import 'package:protobuf/protobuf.dart' as $pb;

class AudioEncoding extends $pb.ProtobufEnum {
  static const AudioEncoding AUDIO_ENCODING_UNSPECIFIED =
      AudioEncoding._(0, _omitEnumNames ? '' : 'AUDIO_ENCODING_UNSPECIFIED');

  /// Signed 16-bit little-endian PCM, interleaved. The only format live voice
  /// uses: Opus would add encode and decode latency on the one path where
  /// latency is the product.
  static const AudioEncoding AUDIO_ENCODING_PCM_S16LE =
      AudioEncoding._(1, _omitEnumNames ? '' : 'AUDIO_ENCODING_PCM_S16LE');

  static const $core.List<AudioEncoding> values = <AudioEncoding>[
    AUDIO_ENCODING_UNSPECIFIED,
    AUDIO_ENCODING_PCM_S16LE,
  ];

  static final $core.List<AudioEncoding?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static AudioEncoding? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AudioEncoding._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');

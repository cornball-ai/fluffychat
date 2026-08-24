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

import 'package:protobuf/protobuf.dart' as $pb;

class TurnOutcome extends $pb.ProtobufEnum {
  static const TurnOutcome TURN_OUTCOME_UNSPECIFIED =
      TurnOutcome._(0, _omitEnumNames ? '' : 'TURN_OUTCOME_UNSPECIFIED');

  /// Played all the way out.
  static const TurnOutcome TURN_OUTCOME_COMPLETED =
      TurnOutcome._(1, _omitEnumNames ? '' : 'TURN_OUTCOME_COMPLETED');

  /// The user talked over it.
  static const TurnOutcome TURN_OUTCOME_BARGE_IN =
      TurnOutcome._(2, _omitEnumNames ? '' : 'TURN_OUTCOME_BARGE_IN');

  /// The user ended the session, or it dropped.
  static const TurnOutcome TURN_OUTCOME_ABANDONED =
      TurnOutcome._(3, _omitEnumNames ? '' : 'TURN_OUTCOME_ABANDONED');

  static const $core.List<TurnOutcome> values = <TurnOutcome>[
    TURN_OUTCOME_UNSPECIFIED,
    TURN_OUTCOME_COMPLETED,
    TURN_OUTCOME_BARGE_IN,
    TURN_OUTCOME_ABANDONED,
  ];

  static final $core.List<TurnOutcome?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static TurnOutcome? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const TurnOutcome._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');

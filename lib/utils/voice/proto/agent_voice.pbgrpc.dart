// This is a generated file - do not edit.
//
// Generated from agent_voice.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'agent_voice.pb.dart' as $0;

export 'agent_voice.pb.dart';

@$pb.GrpcServiceName('cornball.agent.v1.AgentVoice')
class AgentVoiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  AgentVoiceClient(super.channel, {super.options, super.interceptors});

  /// Opens a voice session and returns where to send audio, plus a credential
  /// scoped to it.
  $grpc.ResponseFuture<$0.AllocateVoiceResponse> allocateVoice(
    $0.AllocateVoiceRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$allocateVoice, request, options: options);
  }

  /// One conversational turn. Text in, tokens out as they are generated so the
  /// client can begin synthesising before generation finishes.
  $grpc.ResponseStream<$0.ConverseEvent> converse(
    $0.ConverseRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$converse, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// How much of a spoken reply actually reached the user.
  $grpc.ResponseFuture<$0.ReportTurnResponse> reportTurn(
    $0.ReportTurnRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$reportTurn, request, options: options);
  }

  // method descriptors

  static final _$allocateVoice =
      $grpc.ClientMethod<$0.AllocateVoiceRequest, $0.AllocateVoiceResponse>(
          '/cornball.agent.v1.AgentVoice/AllocateVoice',
          ($0.AllocateVoiceRequest value) => value.writeToBuffer(),
          $0.AllocateVoiceResponse.fromBuffer);
  static final _$converse =
      $grpc.ClientMethod<$0.ConverseRequest, $0.ConverseEvent>(
          '/cornball.agent.v1.AgentVoice/Converse',
          ($0.ConverseRequest value) => value.writeToBuffer(),
          $0.ConverseEvent.fromBuffer);
  static final _$reportTurn =
      $grpc.ClientMethod<$0.ReportTurnRequest, $0.ReportTurnResponse>(
          '/cornball.agent.v1.AgentVoice/ReportTurn',
          ($0.ReportTurnRequest value) => value.writeToBuffer(),
          $0.ReportTurnResponse.fromBuffer);
}

@$pb.GrpcServiceName('cornball.agent.v1.AgentVoice')
abstract class AgentVoiceServiceBase extends $grpc.Service {
  $core.String get $name => 'cornball.agent.v1.AgentVoice';

  AgentVoiceServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.AllocateVoiceRequest, $0.AllocateVoiceResponse>(
            'AllocateVoice',
            allocateVoice_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.AllocateVoiceRequest.fromBuffer(value),
            ($0.AllocateVoiceResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ConverseRequest, $0.ConverseEvent>(
        'Converse',
        converse_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.ConverseRequest.fromBuffer(value),
        ($0.ConverseEvent value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ReportTurnRequest, $0.ReportTurnResponse>(
        'ReportTurn',
        reportTurn_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ReportTurnRequest.fromBuffer(value),
        ($0.ReportTurnResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.AllocateVoiceResponse> allocateVoice_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.AllocateVoiceRequest> $request) async {
    return allocateVoice($call, await $request);
  }

  $async.Future<$0.AllocateVoiceResponse> allocateVoice(
      $grpc.ServiceCall call, $0.AllocateVoiceRequest request);

  $async.Stream<$0.ConverseEvent> converse_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ConverseRequest> $request) async* {
    yield* converse($call, await $request);
  }

  $async.Stream<$0.ConverseEvent> converse(
      $grpc.ServiceCall call, $0.ConverseRequest request);

  $async.Future<$0.ReportTurnResponse> reportTurn_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ReportTurnRequest> $request) async {
    return reportTurn($call, await $request);
  }

  $async.Future<$0.ReportTurnResponse> reportTurn(
      $grpc.ServiceCall call, $0.ReportTurnRequest request);
}

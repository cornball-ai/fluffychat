// This is a generated file - do not edit.
//
// Generated from gpu_voice.proto.

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

import 'gpu_voice.pb.dart' as $0;

export 'gpu_voice.pb.dart';

@$pb.GrpcServiceName('cornball.voice.v1.SpeechToText')
class SpeechToTextClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  SpeechToTextClient(super.channel, {super.options, super.interceptors});

  /// Bidirectional: audio flows up for as long as the microphone is open,
  /// transcript events flow down as they are produced.
  $grpc.ResponseStream<$0.TranscribeEvent> transcribe(
    $async.Stream<$0.TranscribeRequest> request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$transcribe, request, options: options);
  }

  // method descriptors

  static final _$transcribe =
      $grpc.ClientMethod<$0.TranscribeRequest, $0.TranscribeEvent>(
          '/cornball.voice.v1.SpeechToText/Transcribe',
          ($0.TranscribeRequest value) => value.writeToBuffer(),
          $0.TranscribeEvent.fromBuffer);
}

@$pb.GrpcServiceName('cornball.voice.v1.SpeechToText')
abstract class SpeechToTextServiceBase extends $grpc.Service {
  $core.String get $name => 'cornball.voice.v1.SpeechToText';

  SpeechToTextServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.TranscribeRequest, $0.TranscribeEvent>(
        'Transcribe',
        transcribe,
        true,
        true,
        ($core.List<$core.int> value) => $0.TranscribeRequest.fromBuffer(value),
        ($0.TranscribeEvent value) => value.writeToBuffer()));
  }

  $async.Stream<$0.TranscribeEvent> transcribe(
      $grpc.ServiceCall call, $async.Stream<$0.TranscribeRequest> request);
}

@$pb.GrpcServiceName('cornball.voice.v1.TextToSpeech')
class TextToSpeechClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  TextToSpeechClient(super.channel, {super.options, super.interceptors});

  /// Server streaming: chunks are emitted as they are synthesised so the first
  /// word plays before the last is generated. Barge-in is ordinary gRPC stream
  /// cancellation by the client.
  $grpc.ResponseStream<$0.SynthesisEvent> synthesize(
    $0.SynthesizeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$synthesize, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$synthesize =
      $grpc.ClientMethod<$0.SynthesizeRequest, $0.SynthesisEvent>(
          '/cornball.voice.v1.TextToSpeech/Synthesize',
          ($0.SynthesizeRequest value) => value.writeToBuffer(),
          $0.SynthesisEvent.fromBuffer);
}

@$pb.GrpcServiceName('cornball.voice.v1.TextToSpeech')
abstract class TextToSpeechServiceBase extends $grpc.Service {
  $core.String get $name => 'cornball.voice.v1.TextToSpeech';

  TextToSpeechServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.SynthesizeRequest, $0.SynthesisEvent>(
        'Synthesize',
        synthesize_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.SynthesizeRequest.fromBuffer(value),
        ($0.SynthesisEvent value) => value.writeToBuffer()));
  }

  $async.Stream<$0.SynthesisEvent> synthesize_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SynthesizeRequest> $request) async* {
    yield* synthesize($call, await $request);
  }

  $async.Stream<$0.SynthesisEvent> synthesize(
      $grpc.ServiceCall call, $0.SynthesizeRequest request);
}

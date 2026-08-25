#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2026-Present cornball.ai
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# Regenerates the Dart stubs in lib/utils/voice/proto/ from proto/*.proto.
#
# The generated files are committed, so this only needs running when a .proto
# changes. The toolchain is PINNED and the pins are ENFORCED below, because
# codegen that runs whatever is on PATH lets committed stubs drift from the
# schema with everything still green. To install the pinned plugin:
#
#   dart pub global activate protoc_plugin 25.0.0
#
# A newer toolchain that produces a differing diff is the cue to re-pin here
# (bump the constants, regenerate everything, commit as one change), never to
# commit the mixture.
#
# Both `dart` and ~/.pub-cache/bin must be on PATH (protoc-gen-dart is a shim
# that invokes dart, so a missing dart fails inside protoc with status 127).

set -e
cd "$(dirname "$0")/.."

PROTOC_PIN="3.21.12"
PLUGIN_PIN="25.0.0"

PROTOC_VERSION="$(protoc --version | awk '{print $2}')"
if [ "$PROTOC_VERSION" != "$PROTOC_PIN" ]; then
    echo "protoc is $PROTOC_VERSION, pinned $PROTOC_PIN -- refusing to generate." >&2
    exit 1
fi
if ! dart pub global list | grep -q "^protoc_plugin $PLUGIN_PIN$"; then
    echo "protoc_plugin $PLUGIN_PIN not active -- run:" >&2
    echo "  dart pub global activate protoc_plugin $PLUGIN_PIN" >&2
    exit 1
fi

protoc --dart_out=grpc:lib/utils/voice/proto -I proto \
    proto/gpu_voice.proto \
    proto/agent_voice.proto

# The pbjson descriptors are reflection constants nothing imports, and CI's
# unused-file check rightly flags them. protoc-gen-dart has no flag to skip
# them, so they are dropped here instead.
rm lib/utils/voice/proto/*.pbjson.dart

echo "regenerated:"
ls -1 lib/utils/voice/proto/

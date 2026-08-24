#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2026-Present cornball.ai
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# Regenerates the Dart stubs in lib/utils/voice/proto/ from proto/*.proto.
#
# The generated files are committed, so this only needs running when a .proto
# changes. Requires protoc and the Dart plugin:
#
#   dart pub global activate protoc_plugin
#
# and both `dart` and ~/.pub-cache/bin on PATH (protoc-gen-dart is a shim that
# invokes dart, so a missing dart fails inside protoc with status 127).

set -e
cd "$(dirname "$0")/.."

protoc --dart_out=grpc:lib/utils/voice/proto -I proto \
    proto/gpu_voice.proto \
    proto/agent_voice.proto

echo "regenerated:"
ls -1 lib/utils/voice/proto/

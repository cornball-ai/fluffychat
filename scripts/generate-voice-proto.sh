#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2026-Present cornball.ai
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# Regenerates the Dart stubs in lib/utils/voice/proto/ from proto/*.proto.
#
# The generated files are committed, so this only needs running when a .proto
# changes. Requires protoc and the Dart plugin, PINNED so two machines
# regenerating the same schema produce the same bytes -- unpinned codegen
# means committed stubs can drift from the schema with everything still green:
#
#   dart pub global activate protoc_plugin 25.0.0
#
# The committed stubs were generated with libprotoc 3.21.12 (Ubuntu 24.04's
# protobuf-compiler). A different protoc that produces a differing diff is the
# cue to re-pin here, not to commit the mixture.
#
# Both `dart` and ~/.pub-cache/bin must be on PATH (protoc-gen-dart is a shim
# that invokes dart, so a missing dart fails inside protoc with status 127).

set -e
cd "$(dirname "$0")/.."

protoc --dart_out=grpc:lib/utils/voice/proto -I proto \
    proto/gpu_voice.proto \
    proto/agent_voice.proto

# The pbjson descriptors are reflection constants nothing imports, and CI's
# unused-file check rightly flags them. protoc-gen-dart has no flag to skip
# them, so they are dropped here instead.
rm lib/utils/voice/proto/*.pbjson.dart

echo "regenerated:"
ls -1 lib/utils/voice/proto/

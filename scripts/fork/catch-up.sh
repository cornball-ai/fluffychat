#!/bin/bash

# SPDX-FileCopyrightText: 2026-Present cornball.ai
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# Catch the fork up with krille-chan/fluffychat.
#
#   scripts/fork/catch-up.sh check [ref]   report how far behind HEAD is and
#                                          which files would conflict
#   scripts/fork/catch-up.sh merge [ref]   merge ref into the current branch,
#                                          regenerate what is never merged by
#                                          hand, list what is left
#   scripts/fork/catch-up.sh verify        run the checks of integrate.yaml's
#                                          code_tests and flutter_tests jobs
#
# ref defaults to upstream's newest release tag (vX.Y.Z). check exits 0 when
# HEAD already contains ref and 1 when it does not. merge refuses to run on
# main and never creates a branch or a commit.

set -euo pipefail

UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/krille-chan/fluffychat.git}"

cd "$(git rev-parse --show-toplevel)"

fetch_upstream() {
  git fetch --quiet "$UPSTREAM_URL" 'refs/tags/v*:refs/tags/v*'
}

newest_tag() {
  git tag --list 'v[0-9]*' --sort=-v:refname | head -n 1
}

resolve_ref() {
  local ref="${1:-}"
  if [ -z "$ref" ]; then
    ref="$(newest_tag)"
  fi
  if ! git rev-parse --verify --quiet "$ref^{commit}" >/dev/null; then
    echo "catch-up: unknown ref '$ref'" >&2
    exit 2
  fi
  echo "$ref"
}

check() {
  fetch_upstream
  local ref
  ref="$(resolve_ref "${1:-}")"
  if git merge-base --is-ancestor "$ref" HEAD; then
    echo "Up to date: HEAD contains $ref."
    return 0
  fi
  local base
  base="$(git merge-base HEAD "$ref")"
  echo "Behind: HEAD does not contain $ref."
  echo "Upstream commits to merge: $(git rev-list --count "HEAD..$ref")"
  echo "Upstream files changed: $(git diff --name-only "$base" "$ref" | wc -l)"
  echo "Flutter: .fvmrc here $(flutter_pin HEAD), at $ref $(flutter_pin "$ref")"
  echo "Files that conflict in a dry-run merge:"
  local conflicts
  conflicts="$(git merge-tree --write-tree --name-only --no-messages HEAD "$ref" | tail -n +2 || true)"
  if [ -z "$conflicts" ]; then
    echo "  (none)"
  else
    echo "$conflicts" | while IFS= read -r file; do echo "  $file"; done
  fi
  return 1
}

flutter_pin() {
  git show "$1:.fvmrc" 2>/dev/null | sed -n 's/.*"flutter": *"\([^"]*\)".*/\1/p'
}

merge() {
  local branch
  branch="$(git rev-parse --abbrev-ref HEAD)"
  if [ "$branch" = "main" ]; then
    echo "catch-up: on main. Switch to a catch-up branch first." >&2
    exit 2
  fi
  if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
    echo "catch-up: the working tree has changes. Commit or stash them first." >&2
    exit 2
  fi
  fetch_upstream
  local ref
  ref="$(resolve_ref "${1:-}")"
  git config rerere.enabled true
  git merge --no-ff --no-commit "$ref" || true

  # The lockfile is regenerated, never merged by hand.
  if git ls-files --unmerged -- pubspec.lock | grep -q .; then
    git checkout --theirs pubspec.lock
    git add pubspec.lock
  fi

  local left
  left="$(git diff --name-only --diff-filter=U)"
  if [ -n "$left" ]; then
    echo
    echo "Resolve these by hand, then run 'flutter pub get' and"
    echo "'scripts/fork/catch-up.sh verify' before committing the merge:"
    echo "$left" | while IFS= read -r file; do echo "  $file"; done
    return 1
  fi
  flutter pub get
  echo
  echo "Merged $ref with no conflicts left. Run 'scripts/fork/catch-up.sh verify',"
  echo "then commit the merge. The pull request lands as a merge commit."
}

verify() {
  local want have
  want="$(flutter_pin HEAD)"
  have="$(flutter --version --machine | sed -n 's/.*"frameworkVersion": *"\([^"]*\)".*/\1/p')"
  if [ "$want" != "$have" ]; then
    echo "catch-up: Flutter is $have but .fvmrc pins $want." >&2
    exit 2
  fi

  local failed=()
  step() {
    local name="$1"
    shift
    echo "== $name"
    if ! "$@"; then
      failed+=("$name")
    fi
  }

  no_empty_translations() { ! grep -rn '": ""' lib/l10n/*.arb; }
  no_commented_code() {
    ! grep -R --include="*.dart" -nE '^[[:space:]]*//[^/<].*;[[:space:]]*$' lib/
  }
  no_conflict_markers() {
    ! git grep -nE '^(<<<<<<<|>>>>>>>) ' -- . ':!scripts/fork/catch-up.sh'
  }

  step "conflict markers" no_conflict_markers
  step "pub get" flutter pub get
  step "locale config" ./scripts/generate-locale-config.sh
  step "empty translations" no_empty_translations
  step "format" dart format lib/ test/ --set-exit-if-changed
  step "licenses" dart run license_checker check-licenses -c licenses.yaml --problematic
  step "unused translations" dart pub global run sweeper check
  step "analyze" flutter analyze
  step "unused dependencies" dart pub global run dependency_validator
  step "unused code" dart run dart_code_linter:metrics check-unused-code lib
  step "unused files" dart run dart_code_linter:metrics check-unused-files lib
  step "unused l10n" dart run dart_code_linter:metrics check-unused-l10n lib
  step "commented-out code" no_commented_code
  step "tests" flutter test
  if command -v reuse >/dev/null; then
    step "reuse" reuse lint --quiet
  else
    echo "== reuse: not installed, skipped (CI runs it)"
  fi

  echo
  if [ "${#failed[@]}" -gt 0 ]; then
    echo "Failed: ${failed[*]}"
    return 1
  fi
  echo "All checks passed."
  echo "Review 'git status' for files the generators rewrote."
}

case "${1:-}" in
  check) check "${2:-}" ;;
  merge) merge "${2:-}" ;;
  verify) verify ;;
  *)
    sed -n '7,20p' "$0" | sed 's/^# \{0,1\}//'
    exit 2
    ;;
esac

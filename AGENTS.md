<!--
SPDX-FileCopyrightText: 2026-Present cornball.ai

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Agent instructions for the cornball-ai fork

This is cornball-ai's fork of [FluffyChat](https://github.com/krille-chan/fluffychat).
LLM-assisted work is allowed and expected in this repository: code, tests,
documentation, commit messages, and pull request descriptions. Upstream
removed its own `AGENTS.md` in krille-chan/fluffychat@607edd5a76
(2026-10-22). Item 2 of upstream's `CONTRIBUTING.md` now reads: "We do not
vibe code! You are required to understand and be able to explain every single
line of code of your contribution." This file is the fork's own and is
maintained here.

## What still applies

- Contributions to krille-chan/fluffychat follow upstream's current rules:
  pull requests are limited to collaborators for now (access is requested in
  an issue), and the contributor must understand and be able to explain
  every line. Issues and pull requests drafted with LLM help say so. Nothing
  goes upstream without Troy's review and approval.
- The rest of `CONTRIBUTING.md` still describes the code style this fork
  follows: controller/view split, `dart format`, analyzer rules, no changes
  under the platform directories, minimal dependencies, Conventional Commits.
- CI is `.github/workflows/integrate.yaml`. The deploy, release, Matrix
  notification, and stale workflows are upstream's and are gated to run only
  in krille-chan/fluffychat.

## Fork conventions

- Catch-up merges from upstream land as merge commits, not squashes, so the
  next catch-up sees the shared ancestor. Pull requests from fork branches
  are otherwise squash-merged.
- Fork-added files carry a REUSE header like the one at the top of this
  file: copyright `2026-Present cornball.ai`, license AGPL-3.0-or-later. The
  REUSE check in CI fails on a file without a header or a `REUSE.toml`
  annotation.
- Fork-added strings go in `lib/l10n/intl_en.arb` and must be referenced
  from code; CI runs `sweeper check` for unused keys. Upstream's translations
  come from Weblate and are not edited here.
- Fork-only code lives in its own directories where possible, such as
  `lib/utils/voice/` and `proto/`, so upstream merges touch few shared files.

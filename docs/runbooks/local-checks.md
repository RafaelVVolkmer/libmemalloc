<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Local checks

**Status:** implemented local checks. Run from a prepared checkout with the
[declared tools](../reference/toolchain.md). Shared source discovery includes tracked and untracked
working files and omits deleted files. Git hooks validate the pending commit, while release checks
require the selected source identity and their declared clean-checkout conditions.

<details>
<summary><strong>On this page</strong></summary>

- [Aggregate checks](#aggregate-checks)
- [Individual checks](#individual-checks)
- [Campaigns](#campaigns)

</details>

---

## Aggregate checks

Choose a new output directory for each attempt:

```sh
lua scripts/workspace/with_tools.lua lua scripts/workspace/cache.lua lua scripts/check/all.lua \
  --output=.cache/logs/checks-review-001
```

Inspect `results.json` and the per-check logs in that directory. Missing tools and failed required checks
produce a failed run. `--offline` narrows some checks; it does not isolate network access.
Supply `--root=PATH` only when checking an existing release evidence tree.
This command excludes hosted events and does not execute the full platform or qualification matrices.

The report describes the working tree at execution time. A passing run can include pending changes
that are absent from `HEAD`. Record the tested revision and pending changes, and repeat the relevant
checks from a clean checkout after committing the required scripts, configuration, fixtures and documents.
Hook success covers the configured commit checks; it does not replace the aggregate source checks or
external-link validation. Keep failed attempts and explain environmental retries alongside their results.

---

## Individual checks

Run from the repository root with the tools listed in the lock file installed:

```sh
lua scripts/check/toolchain.lua
lua tests/automation/toolchain/lock_test.lua
lua tests/automation/workspace/commits_test.lua
lua tests/automation/workspace/changes_test.lua
lua tests/automation/check/ci_policy_test.lua
lua scripts/check/c.lua
lua scripts/check/doc_examples.lua
lua scripts/check/modules.lua
lua scripts/check/lua.lua
lua scripts/check/doc_tools.lua
lua scripts/check/mermaid.lua
lua tests/automation/release/release_test.lua
lua scripts/release/build.lua --mock --version=0.0.0-mock
```

Install documentation dependencies with
the commands in the [documentation guide](../getting-started/documentation.md), using the locked Node major.
For local tool paths, the Lua checks accept `LIBMEMALLOC_LUA`,
`LIBMEMALLOC_LUAC`, `LIBMEMALLOC_CLANG_FORMAT`, `LIBMEMALLOC_CLANG_TIDY`,
`LIBMEMALLOC_SELENE`, `LIBMEMALLOC_STYLUA`, and `LIBMEMALLOC_LUALS`.

---

## Campaigns

Use the [workflow catalog](../reference/workflow-catalog.md) to select platform builds, semantic qualification,
C analysis or reproducibility. The [process pilot](process-pilot.md) runs a separate parser contract check;
its Ansible entry point does not wrap this aggregate checker.

<!-- EOF -->


<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Repository-local disposable state

Run local tools through `lua scripts/workspace/cache.lua COMMAND ARGUMENTS` to keep
their cache and temporary paths inside the root `.cache/` directory. The
`workspace-cache` action applies the same environment after checkout on Actions.
Do not override `HOME`, `RUNNER_TEMP`, or other runner-owned variables.

| Directory | Contents |
| --- | --- |
| `.cache/build/` | Build trees and unsealed candidates |
| `.cache/tools/` | Installed tools, dependency stores, package-manager caches |
| `.cache/tests/` | Consumers, signatures with disposable test keys, profiles |
| `.cache/ruff/` | Ruff analysis cache, including direct invocations through the root configuration |
| `.cache/logs/` | Local check reports and language-server logs |
| `.cache/ci/` | Link cache and local CI state |
| `.cache/cd/` | Package export receipts and publication staging |
| `.cache/tmp/` | Exclusively allocated temporary directories |

Install documentation tools into `.cache/tools/md/` using copies of the tracked
package manifest and lockfile. Keep source policy under `tools/`; it is not a
cache. Never commit generated tool environments, private keys, or logs.

Keep `release/` for immutable distribution artifacts and signed evidence.
Retained `test_logs/` inside a sealed release are evidence, not disposable logs.
Never rewrite a signed tree to apply a new cache policy. Previous immutable
mock trees remain valid at their original paths.

Use scoped cache keys and verify downloaded content after restoration. Do not
restore executables, private keys, or credentials from untrusted PR caches.
Upload named reports, not the complete `.cache/` tree. External shared caches
may retain content remotely; their local working copies belong under `.cache/`.

Third-party system installations and runner-managed action downloads sit outside
the repository's control. The policy governs repository-created state; it does
not relocate the user's unrelated global package caches or system tools.

<details>
<summary><strong>On this page</strong></summary>

- [CICD-008: Cache trust](#cicd-008)

</details>

---

<a id="cicd-008"></a>

## CICD-008: Cache trust

**Class:** SECURITY. **Obligation:** project requirement.

Caches are optional acceleration, not release evidence. Keys must distinguish
tool identity, platform, inputs, and trust domain. A cache miss must preserve
the check's meaning. Do not promote pull-request cache content or generated PGO
profiles into a trusted release without reviewed provenance and verification.

Use the directory allocation above for disposable build, test,
tool, log, CI, and publication state. Keep sealed release evidence outside caches.
Use the [cache guide](../../tools/ci/cache-plane/README.md) for deployment
settings. Test both a cold run and a restored run after a cache-policy change.
Never cache signing material, access tokens, or private reports in a public cache.

<!-- EOF -->


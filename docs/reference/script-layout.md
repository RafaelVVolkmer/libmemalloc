<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Script layout and interfaces

Use this reference to locate automation and review its dependencies. The
[command index](../../scripts/README.md) lists each domain's entry points.

<details>
<summary><strong>On this page</strong></summary>

- [Ownership and dependency direction](#ownership-and-dependency-direction)
- [Commands and shared implementations](#commands-and-shared-implementations)
- [Compatibility boundaries](#compatibility-boundaries)
- [Historical paths](#historical-paths)

</details>

---

## Ownership and dependency direction

A domain directory owns commands for one task family. Its `lib/` directory contains reusable implementation
for that family. `scripts/lib/` owns host, path, Git and artifact primitives shared across domains. Versioned
policy, schemas and tool identities stay in `tools/`; reports and generated inputs stay in `.cache/`.

| Layer | Permitted dependencies | Review concern |
| --- | --- | --- |
| Shared primitive | Lua runtime and explicit host utilities. | Avoid importing a task planner or executing a campaign on load. |
| Domain library | Shared primitives, declared policy and related domain contracts. | Keep I/O ownership and failure semantics visible. |
| Command | Domain libraries and validated options. | Own execution, reports, cleanup and exit status. |
| Ansible or Actions | Stable command entry points. | Supply hosts, credentials and scheduling under the workflow's authority. |

Build and qualification share portable build I/O. Process evidence uses native libuv execution to enforce
stream and deadline limits. Those interfaces have different contracts; merging them would erase a useful
boundary. The artifact helper's historical `release` fields identify that existing interface.

---

## Commands and shared implementations

The old process wrappers differed only in the phase passed to the same engine. `scripts/process/main.lua`
dispatches `plan`, `run`, `gate` and `report` through that engine. Each phase retains its options,
records, failure behavior and authorization limits. The Ansible playbook invokes those subcommands.

The Doxygen C and Markdown filters share argument validation and file reading in
`scripts/documentation/filter.lua`; their transformations remain separate library operations.
`lua scripts/documentation/main.lua build` and `eval` use the same driver and trusted configuration.

Retain independent commands when their inputs or acceptance conditions differ. A security integration
report, a process gate and a product qualification report cannot substitute for each other. Move repeated
implementation into the library that owns the contract before introducing another command wrapper.

---

## Compatibility boundaries

Function implementations use module prefixes. Existing exported table keys remain the compatibility
boundary for current callers and injected test ports. Explicit assignments expose those keys; private
implementation names stay local. Preserve external JSON keys, CLI flags, environment variables and library
callbacks when improving source names.

This migration retains existing exceptional failures and early-return control paths where changing them
would alter cleanup or error propagation. That scope covers the existing host/artifact primitives, process
I/O and planner lookup operations under LSTYLE-007 and LSTYLE-023. The maintainer owns review of those
compatibility boundaries. Review them on the next interface change; new functions follow the full naming
and normal-output policy. Syntax, formatting and static analysis do not establish full policy conformance.

Named limits identify units and policy: metadata bytes, child-output bytes, execution deadlines, digest
widths and private POSIX modes. Paths that select an implementation or a versioned policy remain explicit
repository-relative inputs. Runtime destinations come from CLI options, the workspace environment or the
domain's declared defaults. Do not replace protocol bytes or tool flags with arbitrary abstractions.

---

## Historical paths

Use this mapping to update external command callers. Current repository consumers use the new paths.
The table records historical names; the old directories are not compatibility launchers.

| Previous path | Current path |
| --- | --- |
| `scripts/ci/build.lua` | [`scripts/build/run.lua`](../../scripts/build/run.lua) |
| `scripts/ci/cache.lua` | [`scripts/workspace/cache.lua`](../../scripts/workspace/cache.lua) |
| `scripts/ci/changed_areas.lua` | [`scripts/workspace/changes.lua`](../../scripts/workspace/changes.lua) |
| `scripts/ci/check_all.lua` | [`scripts/check/all.lua`](../../scripts/check/all.lua) |
| `scripts/ci/check_c.lua` | [`scripts/check/c.lua`](../../scripts/check/c.lua) |
| `scripts/ci/check_c_analysis.lua` | [`scripts/check/c_analysis.lua`](../../scripts/check/c_analysis.lua) |
| `scripts/ci/check_c_architecture.lua` | [`scripts/check/c_architecture.lua`](../../scripts/check/c_architecture.lua) |
| `scripts/ci/check_c_documentation.lua` | [`scripts/check/c_documentation.lua`](../../scripts/check/c_documentation.lua) |
| `scripts/ci/check_commits.lua` | [`scripts/check/commits.lua`](../../scripts/check/commits.lua) |
| `scripts/ci/check_doc_examples.lua` | [`scripts/check/doc_examples.lua`](../../scripts/check/doc_examples.lua) |
| `scripts/ci/check_doc_tools.lua` | [`scripts/check/doc_tools.lua`](../../scripts/check/doc_tools.lua) |
| `scripts/ci/check_documentation.lua` | [`scripts/check/documentation.lua`](../../scripts/check/documentation.lua) |
| `scripts/ci/check_eof.lua` | [`scripts/check/eof.lua`](../../scripts/check/eof.lua) |
| `scripts/ci/check_format.lua` | [`scripts/check/format.lua`](../../scripts/check/format.lua) |
| `scripts/ci/check_install.lua` | [`scripts/check/install.lua`](../../scripts/check/install.lua) |
| `scripts/ci/check_links.lua` | [`scripts/check/links.lua`](../../scripts/check/links.lua) |
| `scripts/ci/check_lua.lua` | [`scripts/check/lua.lua`](../../scripts/check/lua.lua) |
| `scripts/ci/check_mermaid.lua` | [`scripts/check/mermaid.lua`](../../scripts/check/mermaid.lua) |
| `scripts/ci/check_modules.lua` | [`scripts/check/modules.lua`](../../scripts/check/modules.lua) |
| `scripts/ci/check_msvc.lua` | [`scripts/check/msvc.lua`](../../scripts/check/msvc.lua) |
| `scripts/ci/check_openssf.lua` | [`scripts/check/openssf.lua`](../../scripts/check/openssf.lua) |
| `scripts/ci/check_reproducible.lua` | [`scripts/check/reproducible.lua`](../../scripts/check/reproducible.lua) |
| `scripts/ci/check_toolchain.lua` | [`scripts/check/toolchain.lua`](../../scripts/check/toolchain.lua) |
| `scripts/ci/install_build_tools.lua` | [`scripts/toolchain/install/build.lua`](../../scripts/toolchain/install/build.lua) |
| `scripts/ci/install_c_analysis.lua` | [`scripts/toolchain/install/c_analysis.lua`](../../scripts/toolchain/install/c_analysis.lua) |
| `scripts/ci/install_c_scanners.lua` | [`scripts/toolchain/install/c_scanners.lua`](../../scripts/toolchain/install/c_scanners.lua) |
| `scripts/ci/install_qualification_tools.lua` | [`scripts/toolchain/install/qualification.lua`](../../scripts/toolchain/install/qualification.lua) |
| `scripts/ci/openssf_plan.lua` | [`scripts/security/plan.lua`](../../scripts/security/plan.lua) |
| `scripts/ci/openssf_report.lua` | [`scripts/security/report.lua`](../../scripts/security/report.lua) |
| `scripts/ci/plan.lua` | [`scripts/build/plan.lua`](../../scripts/build/plan.lua) |
| `scripts/ci/qualification_batch.lua` | [`scripts/qualification/batch.lua`](../../scripts/qualification/batch.lua) |
| `scripts/ci/qualification_dependencies.lua` | [`scripts/qualification/dependencies.lua`](../../scripts/qualification/dependencies.lua) |
| `scripts/ci/qualification_plan.lua` | [`scripts/qualification/plan.lua`](../../scripts/qualification/plan.lua) |
| `scripts/ci/qualification_report.lua` | [`scripts/qualification/report.lua`](../../scripts/qualification/report.lua) |
| `scripts/ci/qualify.lua` | [`scripts/qualification/run.lua`](../../scripts/qualification/run.lua) |
| `scripts/ci/report.lua` | [`scripts/build/report.lua`](../../scripts/build/report.lua) |
| `scripts/ci/resolve_toolchain.lua` | [`scripts/toolchain/resolve.lua`](../../scripts/toolchain/resolve.lua) |
| `scripts/ci/run_c_campaigns.lua` | [`scripts/analysis/run.lua`](../../scripts/analysis/run.lua) |
| `scripts/ci/run_openssf.lua` | [`scripts/security/run.lua`](../../scripts/security/run.lua) |
| `scripts/ci/toolchain.lock.toml` | [`tools/toolchain/lock.toml`](../../tools/toolchain/lock.toml) |
| `scripts/docs/doxygen.lua` | [`scripts/documentation/main.lua`](../../scripts/documentation/main.lua) |
| `scripts/doxygen/config.lua` | [`scripts/documentation/config.lua`](../../scripts/documentation/config.lua) |
| `scripts/doxygen/filter.lua` | [`scripts/documentation/filter.lua`](../../scripts/documentation/filter.lua) |
| `scripts/doxygen/markdown-filter.lua` | [`scripts/documentation/filter.lua`](../../scripts/documentation/filter.lua) |
| `scripts/libs/build_cache.lua` | [`scripts/build/lib/cache.lua`](../../scripts/build/lib/cache.lua) |
| `scripts/libs/build_io.lua` | [`scripts/build/lib/io.lua`](../../scripts/build/lib/io.lua) |
| `scripts/libs/build_matrix.lua` | [`scripts/build/lib/matrix.lua`](../../scripts/build/lib/matrix.lua) |
| `scripts/libs/c_analysis.lua` | [`scripts/analysis/lib/context.lua`](../../scripts/analysis/lib/context.lua) |
| `scripts/libs/c_architecture.lua` | [`scripts/analysis/lib/architecture.lua`](../../scripts/analysis/lib/architecture.lua) |
| `scripts/libs/c_comments.lua` | [`scripts/documentation/lib/c_comments.lua`](../../scripts/documentation/lib/c_comments.lua) |
| `scripts/libs/commit_message.lua` | [`scripts/workspace/lib/commit_message.lua`](../../scripts/workspace/lib/commit_message.lua) |
| `scripts/libs/documentation_policy.lua` | [`scripts/documentation/lib/policy.lua`](../../scripts/documentation/lib/policy.lua) |
| `scripts/libs/doxygen.lua` | [`scripts/documentation/lib/driver.lua`](../../scripts/documentation/lib/driver.lua) |
| `scripts/libs/doxygen_brand.lua` | [`scripts/documentation/lib/brand.lua`](../../scripts/documentation/lib/brand.lua) |
| `scripts/libs/doxygen_html.lua` | [`scripts/documentation/lib/html.lua`](../../scripts/documentation/lib/html.lua) |
| `scripts/libs/doxygen_markdown.lua` | [`scripts/documentation/lib/markdown.lua`](../../scripts/documentation/lib/markdown.lua) |
| `scripts/libs/git.lua` | [`scripts/lib/git.lua`](../../scripts/lib/git.lua) |
| `scripts/libs/paths.lua` | [`scripts/lib/paths.lua`](../../scripts/lib/paths.lua) |
| `scripts/libs/platform.lua` | [`scripts/lib/platform.lua`](../../scripts/lib/platform.lua) |
| `scripts/libs/policy.lua` | [`scripts/lib/policy.lua`](../../scripts/lib/policy.lua) |
| `scripts/libs/process_engine.lua` | [`scripts/process/lib/engine.lua`](../../scripts/process/lib/engine.lua) |
| `scripts/libs/process_exec.lua` | [`scripts/process/lib/exec.lua`](../../scripts/process/lib/exec.lua) |
| `scripts/libs/process_io.lua` | [`scripts/process/lib/io.lua`](../../scripts/process/lib/io.lua) |
| `scripts/libs/process_policy.lua` | [`scripts/process/lib/policy.lua`](../../scripts/process/lib/policy.lua) |
| `scripts/libs/qualification.lua` | [`scripts/qualification/lib/model.lua`](../../scripts/qualification/lib/model.lua) |
| `scripts/libs/qualification_build.lua` | [`scripts/qualification/lib/build.lua`](../../scripts/qualification/lib/build.lua) |
| `scripts/libs/qualification_execution.lua` | [`scripts/qualification/lib/execution.lua`](../../scripts/qualification/lib/execution.lua) |
| `scripts/libs/qualification_io.lua` | [`scripts/qualification/lib/io.lua`](../../scripts/qualification/lib/io.lua) |
| `scripts/libs/release.lua` | [`scripts/lib/artifacts.lua`](../../scripts/lib/artifacts.lua) |
| `scripts/libs/release_evidence.lua` | [`scripts/release/lib/evidence.lua`](../../scripts/release/lib/evidence.lua) |
| `scripts/libs/reproducible.lua` | [`scripts/reproducible/lib/context.lua`](../../scripts/reproducible/lib/context.lua) |
| `scripts/libs/toolchain.lua` | [`scripts/toolchain/lib/lock.lua`](../../scripts/toolchain/lib/lock.lua) |
| `scripts/process/plan.lua` | `scripts/process/main.lua plan` |
| `scripts/process/run.lua` | `scripts/process/main.lua run` |
| `scripts/process/gate.lua` | `scripts/process/main.lua gate` |
| `scripts/process/report.lua` | `scripts/process/main.lua report` |

<!-- EOF -->


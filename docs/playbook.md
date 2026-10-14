<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Engineering playbook

Choose the task below, read its scope and prerequisites, then run the linked commands from the repository root.
The [workflow catalog](reference/workflow-catalog.md) records which checks run locally and which require Actions.
Use the shared task registry for local, Ansible and hosted Lua operations. Workflow events, permissions,
protected publication and human approval retain their GitHub authority.

| Task | Procedure or rule | Execution guide | Status |
| --- | --- | --- | --- |
| Prepare a development checkout | [Toolchain](reference/toolchain.md) | [Development setup](getting-started/development.md) | Existing tools and local checks. |
| Define and approve SDD work | [Specification issues](procedures/specifications.md) | [Label commands](procedures/specifications.md#activation-and-recovery) | Maintainer approval; hosted reconciliation after activation. |
| Implement and review a change | [Change procedure](procedures/change.md) | [Local checks](runbooks/local-checks.md) | Proposed wider procedure; implemented checks. |
| Review an engineering choice | [Review procedure](procedures/decision-making.md) | [Verification](procedures/verification.md) | Rationale and evidence in the issue or pull request. |
| Check documentation | [Authoring and validation](getting-started/documentation.md) | [Documentation commands](getting-started/documentation.md#validation) | Implemented. |
| Exercise process evidence | [Evidence contract](reference/evidence.md) | [Local process pilot](runbooks/process-pilot.md) | Four scoped controls and requirement evidence, local and CI. |
| Build supported profiles | [CI reference](reference/automation.md#ci-control-map) | [Build runbook](runbooks/build.md) | Mock build matrix. |
| Verify a candidate | [Verification procedure](procedures/verification.md) | [Qualification](runbooks/qualification.md), [C analysis](runbooks/c-analysis.md) | Mock campaigns. |
| Compare independent builds | [Reproducible-build assurance](assurance/reproducible-builds.md) | [Reproducibility](runbooks/reproducibility.md) | Declared tool campaigns. |
| Prepare a release | [Release procedure](procedures/release.md) | [Release fixture](runbooks/release-fixture.md) | Mock fixture; protected publication. |
| Configure security services | [Security procedure](procedures/security.md) | [Service bootstrap](runbooks/security-services.md) | Service-specific prerequisites. |
| Review process and security evidence | [Workflow assurance](assurance/workflow.md) | [SPICE assessment](assurance/workflow.md#spice-process-assessment), [TISAX preparation](assurance/workflow.md#tisax-information-security-assessment) | Proposed; named owners and adopted assessment scope required. |
| Review assurance gaps | [Framework mappings](assurance/framework-mappings.md) | [OpenSSF plan](assurance/openssf.md), [gaps](assurance/gaps.md) | Proposed assessments. |

<details>
<summary><strong>On this page</strong></summary>

- [Run a registered task](#run-a-registered-task)
- [Clean disposable state](#clean-disposable-state)
- [Pilot requirement](#pilot-requirement)

</details>

---

## Run a registered task

Inspect [the task registry](../tools/process/playbook.lua) with the native [root playbook](../playbook.yml):

Use native Ansible after [installing it once on the machine](getting-started/workspace.md#root-commands).
The playbook checks host prerequisites, prepares or repairs the Lua runtime and installs the selected task
profile on normal runs. No environment activation is required. Campaign-specific inputs and credentials
retain the prerequisites listed below:

```sh
ansible-playbook playbook.yml
ansible-playbook playbook.yml -e lma_task=doctor
ansible-playbook playbook.yml -e lma_task=docs-build
ansible-playbook playbook.yml --check -e lma_task=spec-labels
```

Follow [workspace setup](getting-started/workspace.md) for automatic preparation profiles and host prerequisites.
Normal runs activate the repository Git configuration automatically. Check mode does not write Git settings;
repair and uninstall tasks retain their own behavior. [Nix shells](getting-started/nix.md) provide host tools.
Pass domain arguments as the ordered `lma_arguments` list. Check mode validates the CLI contract and displays
the complete literal argument vector without running the domain operation. Unknown options, duplicate options,
missing values and supported domain-value constraints fail before Git setup or task execution. Planning does
not validate credentials, tool availability or the contents of future evidence files.
Verification tasks report no changes. Mutating commands report their observed changes separately from their
declared effects, so repeating an unchanged setup or cleanup reports `changed=0`.
The supervisor retains per-task logs and JSON/JUnit results with timeout and child-exit information.
The result summary also runs after a failed task. Empty, malformed or structurally invalid JSON retains
the raw exit status and diagnostics; it cannot turn an unsuccessful command into success. A zero exit
without a valid result record fails the result contract. Interpreter selection is resolved in separate
Ansible tasks before the managed environment is applied. This uses Ansible's documented
[always and rescue block behavior](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_blocks.html).

| Playbook action | Registered task family | Prerequisites and contract |
| --- | --- | --- |
| Validate specification plans | `sdd-check`, `sdd-test` | [SDD validation](specs/README.md#mechanical-validation) |
| Validate or build docs | `docs-check`, `docs-eval`, `docs-build` | [Documentation tools](getting-started/documentation.md#validation) |
| Prepare Nix tools | `nix-setup` | [Nix environment](getting-started/nix.md); skips hosts without Nix |
| Generate tool manifests | `toolchain-sync` | [Central version policy](reference/toolchain.md#updating-tool-versions) |
| Prepare a checkout | `setup`, `status`, `setup-repair`, `setup-uninstall` | [Git configuration and hooks](getting-started/workspace.md#git-setup) |
| Clean generated state | `clean` | [Cleanup scopes](#clean-disposable-state); preserves installed tools |
| Test Ansible integration | `ansible-test` | [Workspace controller](getting-started/workspace.md#ansible-and-temporary-state) |
| Test automation | `tests` | [Self-contained suites](getting-started/workspace.md#validation) |
| Check a checkout | `checks`, `lua-check` | [Local checks](runbooks/local-checks.md) |
| Maintain specification labels | `spec-labels`, `spec-reconcile` | [Maintainer authority](procedures/specifications.md#activation-and-recovery) |
| Build and reconstruct locally | `build` | [CMake profiles](reference/cmake-build.md) |
| Build a profile | `build-plan`, `build-run`, `build-report` | [Build campaign](runbooks/build.md) |
| Verify a candidate | `qualification-plan`, `qualification-run`, `qualification-report`, `analysis` | [Qualification](runbooks/qualification.md), [analysis](runbooks/c-analysis.md) |
| Compare rebuilds | `reproducible-prepare`, `reproducible-vary` | [Reproducibility](runbooks/reproducibility.md) |
| Construct and verify a fixture | `release-build`, `release-verify` | [Release fixture](runbooks/release-fixture.md) |
| Exercise security adapters | `security-plan`, `security-run`, `security-report` | [Security integrations](runbooks/security-services.md) |
| Exercise process evidence | `process-ci`, `process-plan`, `process-run`, `process-gate`, `process-report` | [Process pilot](runbooks/process-pilot.md) |

The [workflow task catalog](../tools/process/workflows.lua) extends the registry with the existing CI
commands for provisioning, validation, packaging, analysis and reporting. Discover exact names and contracts:

```sh
lua scripts/process/playbook.lua list
lua scripts/process/playbook.lua describe check-lua
lua scripts/process/playbook.lua plan build --profile=debug --jobs=4
lua scripts/process/playbook.lua --direct check-lua
```

Normal Lua dispatch and Ansible use the bounded supervisor and retain task logs. Hosted workflows use
`--direct` so child `stdout` remains suitable for `GITHUB_OUTPUT` and command substitution; the exact child
exit code propagates. Their job timeouts and domain reports supply the execution boundary. Both modes
resolve the same static command prefixes and preserve literal argument boundaries. Unknown tasks fail.
Lua listing and planning perform no setup; native Ansible prepares a missing runtime before listing.
CLI contracts live in
[`tools/process/arguments.lua`](../tools/process/arguments.lua) and the
[argument validator](../scripts/process/lib/arguments.lua); update them when a registered command's CLI changes.
Ansible consumes the supervisor's structured result using `--result-json`. Its `change_status` is `changed`,
`unchanged` or `unknown`; an unreported mutation is explicitly unknown, never inferred from the task category.
Domain commands use [`scripts/lib/change.lua`](../scripts/lib/change.lua) to report changes without decorating
their normal output. A task's diagnostic files are separate from its domain change count.
An unknown outcome conservatively counts as changed in the Ansible recap and prints an explicit explanation;
the JSON retains `unknown`. Failed mutating tasks cannot confirm a no-op. Python provisioning compares installed
entries before and after synchronization, so a repeated unchanged environment reports no domain change.

Bootstrap, third-party Actions, artifact transport, OIDC and protected deployment remain native workflow
steps. The registry consolidates owned Lua operations and does not grant credentials or bypass approval.
The playbook regression suite checks registered workflow references, both dispatch modes and literal argv.
Use `quality-setup` to install locked tools and `lua-check` for the
[measured Lua gate](reference/lua-quality.md).

The task registry selects commands; a successful task does not establish release acceptance or framework
conformance. Keep decisions, SDD approval and protected deployment in their reviewed workflows.

---

## Clean disposable state

Preview and execute cleanup through the same task registry:

```sh
ansible-playbook playbook.yml --check -e lma_task=clean
ansible-playbook playbook.yml -e lma_task=clean
ansible-playbook playbook.yml -e lma_task=clean \
  -e '{"lma_arguments":["--scope=temporary"]}'
```

The Lua entrypoints also work without an Ansible controller:

```sh
lua scripts/process/playbook.lua plan clean --scope=all
lua scripts/process/playbook.lua --direct clean --dry-run
lua scripts/process/playbook.lua clean --scope=build
```

| Scope | Disposable paths below `.cache/` |
| --- | --- |
| `build` | `build`, `install`, `docs`, `metadata`, `ci`, `cd`, `logs`, `validation` |
| `cache` | `downloads`, `ruff`, `tools/uv-cache`, `tools/npm`, `tools/pip`, `tools/go-build`, `tools/xdg` |
| `temporary` | `tmp`, `tests` |
| `all` | All three scopes; the default |

Cleanup removes build metadata together with its build tree. Installed tools, bootstrap receipts,
`tools/automation.yml`, live Ansible temporary state, Git data and sources remain available. The supervised
command retains cleanup receipts under `.cache/cleanup/`, so a repeated full cleanup can remain unchanged.
Unknown directories are preserved. On Linux and macOS, ordinary playbook execution and build controllers hold
a shared kernel lease. Linux uses util-linux `flock`; macOS uses Python `fcntl.flock`.
Cleanup, automation bootstrap and quality installation require an exclusive lease, protecting
executables from replacement while tasks use them. Conflicting commands fail immediately with exit code
75 before their task starts. Retry after the active task finishes. The kernel releases leases when their owners
exit, including after a crash. `.cache/locks/` is preserved and must not be removed while commands are running.

Commands launched directly with external tools must join the same protocol, for example:

```sh
lua scripts/workspace/with_lock.lua -- cmake --build .cache/build/example
```

Cleanup supports Linux and native macOS. The workspace lease does not coordinate other machines or raw
commands that bypass the wrapper.

`--dry-run` lists targets without removing them. Cleanup rejects tracked cache files, symlinked parent
directories and mounted child directories; links inside disposable trees are unlinked without following them.
Planning validates the complete selection, and execution repeats that validation before its first deletion.
Repeated cleanup reports no domain change when the selected paths are already empty.

---

## Pilot requirement

<a id="lma-eng-001"></a>

The canonical [LMA-ENG-001 requirement](runbooks/process-pilot.md#lma-eng-001), its four Lua commands and
the Ansible invocations now live in the process pilot runbook. Only the `local` profile is implemented.
Its passing gate records `promotion_authorized: false` and `product_qualified: false`.

<!-- EOF -->


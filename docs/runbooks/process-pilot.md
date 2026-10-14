<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Local process pilot

Use this runbook to execute the local process pilot. The [engineering playbook](../playbook.md) links other tasks.
Specification-led development uses the existing [product specifications and design descriptions](../specs/README.md).
Software Design Description (SDD) names an artifact, not the development practice.
The [process model](../procedures/change.md) defines the proposed wider lifecycle and its procedure IDs.

**Implemented scope:** a local POSIX automation pilot with a declarative control catalog, native Lua process
execution, plan/run/gate/report commands, JSON schemas and local Ansible entry points. The pilot runs the
toolchain parser, documentation policy, CMake compatibility campaign and four automation policy suites. It does not
implement the allocator, certify toolchains, establish
TDD chronology, assess a framework or authorize a release. Only the `local` profile is accepted.

<details>
<summary><strong>On this page</strong></summary>

- [Ownership and canonical definitions](#ownership-and-canonical-definitions)
- [LMA-ENG-001: Toolchain contract and evidence acceptance](#lma-eng-001)
- [Additional process requirements](#additional-process-requirements)
- [Execute the local pilot](#execute-the-local-pilot)
- [Ansible entry points](#ansible-entry-points)
- [Trust boundary and future CI adoption](#trust-boundary-and-future-ci-adoption)
- [SDD, TDD and framework mapping](#sdd-tdd-and-framework-mapping)

</details>

---

## Ownership and canonical definitions

| Responsibility | Owner and location |
| --- | --- |
| Product behavior | Specification owners maintain existing `LMA-CORE-*`, `LMA-TEST-*` and related SDD controls. |
| Process and acceptance | Maintainers and reviewers use the [procedure catalog](../procedures/change.md#procedure-catalog). |
| Machine control | [`tools/process/controls.json`](../../tools/process/controls.json) defines pilot obligations. |
| Verifier implementation | [`process_policy.lua`](../../scripts/process/lib/policy.lua) maps known verifier IDs to fixed implementations. |
| Tools | [`tools/toolchain/lock.toml`](../../tools/toolchain/lock.toml) remains the version authority. |
| Execution and evidence | [`scripts/process/`](../../scripts/process) invokes the shared engine and native process adapter. |
| Environment | [`infra/ansible/`](../../infra/ansible) prepares private local directories and checks controller prerequisites. |
| Release acceptance | Human reviewers and existing protected release procedures retain this responsibility. |

The catalog contains data. A control cannot provide a shell command or Lua source. The loader rejects unknown
fields, duplicate IDs and unknown verifier, requirement, procedure or configuration references. JSON decoding
uses `jq` to emit typed data records; it never evaluates the document as Lua. The pilot uses ASCII metadata
and bounded exact integers; it rejects JSON null values.
The [schemas](../../tools/process/schemas) document the same closed record shapes for external validation.

Keep source paths and existing procedure identifiers stable. New CLI entry points live under `scripts/process/`
because the existing `scripts/build/plan.lua` and `report.lua` already own build-matrix contracts. Those scripts
continue to serve their existing workflows.

---

<a id="lma-eng-001"></a>

## LMA-ENG-001: Toolchain contract and evidence acceptance

**Scope:** automation only. **Procedure:** LMA-PROC-003, verification. **Owner role:** tooling maintainer.

The existing toolchain parser must accept its supported lock format and reject duplicate fields, duplicate
tool sections, malformed digests, unexpected fields, missing schema/version information and command-shaped
version values. Its [contract suite](../../tests/automation/toolchain/lock_test.lua) exercises one valid and eight
invalid cases. This requirement describes parser behavior; it does not prove that installed tools match the lock.

The process pilot must plan that registered verifier and retain its exact command, outcome, expected case
count, log hashes, source/configuration identity and attempt identity. A zero exit without the expected suite
completion marker is inconclusive. The gate independently checks the observation against the log and expected
case count, then rejects missing, duplicate, unexpected, foreign, incomplete or altered evidence.

A machine pass means that the declared automation control has matching local evidence. The gate emits
`promotion_authorized: false` and `product_qualified: false`, including on success. A test runner or log writer
with the evaluator's privileges can forge unsigned local evidence; protected execution and authenticated
producer records remain necessary before using this mechanism as a release security boundary.

---

## Additional process requirements

| Requirement | Verifier and acceptance | Evidence scope |
| --- | --- | --- |
| LMA-ENG-002 | Documentation policy passes for all authored Markdown files. | Structure and required decision fields; no prose-quality claim. |
| LMA-ENG-003 | Fresh CMake configure/build and nonempty CTest compatibility campaign pass. | Existing distribution fixture; no allocator or ABI proof. |
| LMA-ENG-004 | Hook, task-dispatch, process-policy and provisioning suites all pass. | Four automation contracts; no recursive full-suite invocation. |

Each control maps to LMA-PROC-003 and the tooling maintainer. Reviewers inspect scope and sufficiency before
acceptance. The registry fixes the script, arguments, deadline and completion marker; the gate reconstructs
the command and rejects altered, absent, duplicated or foreign observations for every control.

---

## Execute the local pilot

Run from the repository root after [workspace bootstrap](../getting-started/workspace.md#root-commands).
The pilot also needs Git, `jq`, `sha256sum`, CMake and GCC/G++ 13 on `PATH`. The compilation control selects the Linux x86_64
`linux-gcc13` profile, its first C dialect and every required C++ dialect. It records the actual
interpreter path/digest, Lua/libuv versions, host identity and selected environment. Installed tool identity
does not imply tool qualification.

Choose a fresh attempt directory. Obtain the reviewed catalog digest separately and supply it to each phase.
For a local developer experiment, `sha256sum tools/process/controls.json` shows the current digest; that local
observation is not an independent policy approval. Replace `REVIEWED_SHA256` below with the 64-character value.

```sh
lua scripts/process/main.lua plan --profile=local --run-id=review-001 \
  --policy-sha256=REVIEWED_SHA256 \
  --output=.cache/logs/process-review-001/plan.json

lua scripts/process/main.lua run \
  --plan=.cache/logs/process-review-001/plan.json \
  --policy-sha256=REVIEWED_SHA256 \
  --output=.cache/logs/process-review-001/evidence

lua scripts/process/main.lua gate \
  --plan=.cache/logs/process-review-001/plan.json \
  --policy-sha256=REVIEWED_SHA256 \
  --evidence=.cache/logs/process-review-001/evidence \
  --output=.cache/logs/process-review-001/gate.json

lua scripts/process/main.lua report \
  --plan=.cache/logs/process-review-001/plan.json \
  --policy-sha256=REVIEWED_SHA256 \
  --evidence=.cache/logs/process-review-001/evidence \
  --output=.cache/logs/process-review-001/report.md
```

Alternatively, execute all four phases with the portable campaign interface:

```sh
lua scripts/process/playbook.lua process-ci --profile=local --run-id=review-003 \
  --policy-sha256=REVIEWED_SHA256 --output=.cache/logs/process-review-003
```

The root Ansible playbook exposes the same `process-ci` task with an ordered `lma_arguments` list.
This campaign writes `plan.json`, `evidence/evidence.json`, per-control results and logs, `gate.json` and
`report.md`. Read [the requirement graph contract](../reference/evidence.md#requirement-evidence-graph)
for links, artifact paths and digest validation. The campaign always attempts gate/report after execution
failure and preserves a nonzero outcome. Failed planning stops before execution.

All valued options use `--key=value`. Output paths must remain under `.cache/`. The implementation rejects
existing destinations, path traversal and symlink output paths. Use one checkout per concurrent attempt.
Every non-ignored source input, including untracked files and deletions, participates in the source identity;
file modes also participate. Changing sources or the recorded runtime between phases invalidates the plan.
Keep the workspace under one trusted writer during execution; the pilot does not provide filesystem isolation.

The source inventory records a dirty checkout for local development. A release profile would require the
accepted clean baseline and additional policy, verification and approval evidence; that profile is not enabled.

The native adapter uses `luv.spawn` with argument vectors, a process group, an output bound and a deadline.
It forwards only the declared environment to the verifier. Helpers invoke fixed executables through argv as
well. Missing executables, timeout, output overflow and unsuccessful exits remain failures. Existing unrelated
scripts may still use the repository's older shell-quoting adapter; this addition does not migrate those scripts.

The exact completion marker ties this pilot to the current test suite. If that suite changes its cases or
report format, update the verifier contract and tests together. General test suites should eventually supply
structured case results rather than relying on a textual marker.

---

## Ansible entry points

Use `ansible-playbook playbook.yml -e lma_task=process-test` to exercise all current controls and tamper cases.
Individual `process-plan`, `process-run`, `process-gate` and `process-report` tasks use the native root playbook
and the ordered `lma_arguments` list. The following lower-level playbooks remain available for explicit
inventory-driven orchestration.

The controller version comes from `tools.ansible_core` in the existing toolchain lock. Install the selected
Ansible controller in an isolated tool environment. The tracked playbooks use built-in modules only.
`prepare.yml` creates private disposable directories, checks the controller version and verifies that the
Lua pilot loads. It does not install compilers or change system users, services or network configuration.

The bootstrap supplies managed runtime paths to both playbooks. Run from the checkout root:

```sh
ansible-playbook infra/ansible/playbooks/prepare.yml
ansible-playbook infra/ansible/playbooks/verify-environment.yml \
  -e '{"lma_run_id":"review-002","lma_policy_sha256":"REVIEWED_SHA256"}'
```

The combined evidence playbook requires a real attempt and rejects `--check`; use the root playbook to
simulate individual phase contracts. Every phase uses the same bounded task supervisor and retains logs.

Use repository-local Ansible working paths, for example `ANSIBLE_HOME` under `.cache/tools/ansible` and
`ANSIBLE_LOCAL_TEMP` under `.cache/tmp/ansible`. Keep remote temporary state in the approved worker workspace.
Repeated preparation should report no changes once directories match. Verification always creates a fresh
attempt. The verification playbook rejects check mode and delegates phase ordering and failure finalization
to the Lua campaign, without rescuing those failures into success.

These playbooks target localhost. Remote inventories, Windows adapters, hardening roles, dependency-store
locks and audit-infrastructure campaigns remain planned. An unreachable host or killed controller needs
CI-level finalization and cannot rely solely on an Ansible `always` block.

---

## Trust boundary and future CI adoption

The CLI requires the expected catalog digest, but the caller supplies its authority. For trusted CI, obtain
that digest and the evaluator itself from an approved protected baseline. A PR may propose policy changes;
its candidate policy must not define the mandatory checks that approve that same PR. Keep candidate execution,
trusted evidence verification and artifact publication in separate permission contexts.

A YAML `approved: true` field is not a human decision. Retrieve approvals from authenticated review records,
bind them to the reviewed revision, and invalidate them according to the change policy. A single person
holding several role names does not satisfy independent review requirements.

The reusable lint workflow runs native Ansible and signed-hook integrations and retains the process
requirement evidence graph. This automation evidence does not grant protected promotion authority.
Run these suites before adopting it as a protected gate:

```sh
lua tests/automation/process/policy_test.lua
lua tests/automation/process/traceability_test.lua
lua tests/automation/process/campaign_test.lua
lua tests/automation/process/exec_test.lua
lua tests/automation/process/io_test.lua
lua tests/automation/process/evidence_test.lua
```

The suites cover closed catalogs, known verifiers, required evidence, duplicate/foreign results, zero case
counts, native argv, timeout/output limits, missing executables, tampering, missing files, policy mismatch,
source identity mismatch, reused destinations and symlink/traversal paths. The evidence suite retains a local
report under `.cache/tests/process-*`. Run it in an isolated unprivileged worker with no release secrets.

Before CI promotion, add protected evaluator selection, platform-specific worker qualification, retained
artifact storage, transport authentication and policy-change review. Reuse existing planners for larger
campaigns instead of copying their matrices into Ansible. Local, PR, merge, nightly, release and audit remain
separate proposed profiles; one job may execute several cases while retaining a result for each configuration.

---

## SDD, TDD and framework mapping

For a product change, link the exact existing SDD control to its acceptance tests, implementation, selected
verification plan and review. Review that the linked artifacts agree in meaning; links alone do not establish
consistency. Preserve red/green observations for the appropriate development scope, with revisions and test
identity. Replaying a new test against an older implementation demonstrates discrimination, not test-first
chronology. A missing tool is an infrastructure failure rather than a valid red phase.

The development log for this pilot first recorded the policy suite failing because the new policy module did
not yet exist. Subsequent runs exercised the implemented contract and negative cases. That local observation
is not a claim about prior allocator development or historical product TDD.

Keep framework mappings separate from execution states. A future control assessment needs the external
criterion, adopted edition, applicability, policy/procedure link, implementation, expected evidence, observed
records, reviewer decision and remaining gaps. Supporting references indicate contribution to a criterion;
passing one control does not close every referenced process or badge obligation.

Use the [canonical framework allocation](../assurance/framework-mappings.md) for lifecycle organization under
ISO 12207, SPICE assessment with selected ISO 330xx models, V&V, secure development and organizational security.
That allocation records editions, model compatibility, sector boundaries and accountable roles. The pilot's
execution records do not establish any of those assessments or human decisions.

Keep four verification questions distinct: reproducible artifact bytes under defined build conditions,
semantic agreement across supported configurations, compatible ABI combinations, and explicitly required
runtime determinism. Pointer addresses or timings do not automatically belong in semantic comparisons.
Independent reconstruction must not reuse the candidate objects it is intended to verify.

Preserve selected evidence in an authorized retained store; `.cache/` remains disposable. Classify access,
incident and unpublished vulnerability records before exporting them. Hashes establish content identity
relative to a trusted reference; signatures establish an origin under their trust policy. Neither proves that
an observation is correct. Review and negative controls remain part of acceptance.

<!-- EOF -->


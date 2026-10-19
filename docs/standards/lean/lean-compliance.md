<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Lean Compliance and Assurance

Record separately whether a proof is readable, valid under the admitted assumptions, and relevant to the
allocator requirement. Apply the [code standard](lean-code-standard.md) and the
[proof acceptance controls](test/lean-tests-formal.md) together.

<details>
<summary><strong>On this page</strong></summary>

- [Acceptance controls](#acceptance-controls)
- [Tool coverage and profiles](#tool-coverage-and-profiles)
- [Review record](#review-record)

</details>

---

## Acceptance controls

<a id="lcomp-001"></a>

### LCOMP-001: Bind evidence to the reviewed inputs

**MUST · delivered results.** Record Lean/Lake versions, dependency revisions, source identity, dirty inputs,
elaborated theorem roots, actual axiom sets, trust profile and command results. Compare both source and
contract snapshots; review changed definitions even when a theorem's printed type stays the same.
Inventory every owned theorem, including private and generated results, and record the adjacent mathematical
statement required by [LSTYLE-MATH-001](lean-code-standard.md#lstyle-math-001). Review its quantifiers, domains,
hypotheses and conclusion against the elaborated proposition. Missing or stale comments remain nonconformance
even when compilation, axiom auditing and replay pass.

**Rationale and examples:** Conforming evidence names `Allocator.Reservation.reserve_no_wrap` and the
reviewed input digests. A record saying only “Lean passed” omits the property and its input identity.

```text
Conforming: root + elaborated statement + axiom set + source identity + replay status.
Nonconforming: editor screenshot + theorem count.
```

**Verification and limits:** Compare the actual report to approved baselines. Hashes detect changes, not
correctness; a baseline update is not evidence that someone reviewed the mathematical meaning.

<a id="lcomp-002"></a>

### LCOMP-002: Preserve rejection and coverage

**MUST · acceptance commands.** Require successful source checks, transitive audit and the specified replay.
Retain negative-control diagnostics. Report a failed or missing stage as incomplete; distinguish the ordinary
kernel replay from optional paranoid replay and any future profile allowing native evaluation.

**Rationale and examples:** A sandbox startup error says nothing about the theorem's truth.

```text
Conforming: REPLAY_FAILED, cause = sandbox startup; acceptance remains incomplete.
Nonconforming: REPLAY_SKIPPED treated as PASS because lake build succeeded.
```

**Verification and limits:** Inspect roots, statuses and rejection reasons. Passing these stages proves only
their declared scope; it does not qualify the complete allocator or replace C implementation evidence.

<a id="lcomp-003"></a>

### LCOMP-003: Record rule exceptions without weakening proof claims

**MUST · deviations.** Record the rule ID, affected declarations, reason, alternate evidence, residual risk,
owner, reviewer and expiry/removal condition under the
[engineering decision procedure](../../procedures/decision-making.md). A `SHOULD` alternative needs a reason.
Changes to a `MUST` or the allowed axiom set require a reviewed policy/profile change.

**Rationale and examples:** A naming exception for an established external API can preserve compatibility.
A silent trust-policy relaxation changes what proof acceptance means.

```text
Conforming: name exception for an existing contract root, with migration and owner recorded.
Nonconforming: permit sorryAx temporarily and still label the result accepted.
```

**Verification and limits:** Check exception scope and removal conditions. Delivered results with incomplete
dependencies cannot satisfy the existing acceptance profile. Missing evidence cannot receive an exception labeled
pass.

---

## Tool coverage and profiles

| Check | Existing coverage | Remaining review obligation |
| --- | --- | --- |
| `scripts/verification/lib/style.lua` | License/doc marker, 100-code-point width, even indentation, import inventory and model boundary | Naming, blank-line groups, mathematical clarity and full mathlib style |
| Lake build with warnings as errors | Elaboration and selected built-in unused/deprecated diagnostics | Statement relevance, all docstrings and external correspondence |
| Mathematical comment review | LSTYLE-MATH-001 and LDOC-004 require an adjacent formula for every theorem | Manual coverage and formula/type comparison; no configured per-theorem documentation gate |
| `LibMemAllocAudit.Support` | Transitive axiom allowlist for inventoried theorem roots | Audit-root completeness and meaning of hypotheses |
| Contract/source baselines | Statement/axiom snapshots and content drift | Whether the reviewed new definition still expresses the requirement |
| `lake check` | Default model/test target export and isolated kernel replay | Intended root selection and representation assumptions |
| `lake check --paranoid` | Additional bundled independent checkers, when run successfully | Report separately; no inference from an ordinary replay |
| FlexibleLinter / mathlib doc linters | Not installed | Apply relevant guidance in review; do not claim a lint result |
| Manual guide example compilation | Standalone illustrative modules | Markdown checks do not extract or compile Lean examples |

The current **model** and **lean-ir** profiles reject native-evaluation axioms. `lean-ir` also binds a generated
program theorem to the imported scalar representation; the C frontend and source-to-IR preservation remain
trusted. See the [trust model](../../../docs/assurance/formal-trust.md) and
[integration contract](../formal-integration.md). A future native profile would require a distinct axiom
policy, compiler/runtime trust inventory and rechecking specification; this guide does not introduce one.

---

## Review record

Use the per-rule verification fields to connect each applicable control to a tool result or review note.
Record passes, failures, not-applicable scope and approved deviations explicitly. Separate model properties,
test observations, source correspondence and product claims. The executable workflow and prerequisites live
in [verification commands](../../../docs/runbooks/formal-verification.md); keep that command source canonical.

<!-- EOF -->


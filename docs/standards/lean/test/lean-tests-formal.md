<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Lean Proof Validation Standard

Use this standard for theorem acceptance and regression design. The
[code standard's governance](../lean-code-standard.md#governance) defines obligation levels and exceptions.
The versioned semantic source is [Lean 4.35.0, Validating a Lean
Proof](https://lean-lang.org/doc/reference/4.35.0/ValidatingProofs/).

<details>
<summary><strong>On this page</strong></summary>

- [Acceptance controls](#acceptance-controls)
- [Negative controls](#negative-controls)
- [Commands and boundaries](#commands-and-boundaries)

</details>

---

## Acceptance controls

<a id="lfv-001"></a>

### LFV-001: Review meaning before accepting the proof

**MUST · mapped theorems.** Compare the elaborated proposition, its definitions and hypotheses to the intended
requirement. Check quantifier order, input domain, units and observable state. Exercise admitted and excluded
boundary cases; identify contradictory hypotheses or an empty domain.
For every theorem, require the adjacent mathematical statement in
[LDOC-004](../lean-documentation.md#ldoc-004), including private helpers and generated certificates.
Review comment coverage and agreement with the elaborated proposition separately from kernel validity.

**Rationale:** A valid proof of an irrelevant implication supplies no evidence for the intended operation.

```lean
/-- Mathematical statement: ∀ used, capacity ∈ ℕ, used ≤ capacity ⇒ used ≤ capacity.
This implication assumes its conclusion; it does not prove an implementation safe.
-/
theorem within (used capacity : Nat) (h : used ≤ capacity) : used ≤ capacity := h
```

```lean
-- Nonconforming as an unconditional safety claim: the premise supplies the conclusion.
theorem safe (safeAlready : False) : False := safeAlready
```

**Verification and limits:** Use elaborated contract snapshots and human specification review. The first
example is an implication, not an implementation proof. No test can substitute for the required universal result.

<a id="lfv-002"></a>

### LFV-002: Audit the transitive theorem closure

**MUST · delivered roots.** Inspect the actual axioms of each accepted result. Reject incomplete imported
helpers and custom/native axioms outside the current allowlist. Check generated roots in addition to repository roots.

**Rationale:** A theorem file may contain no `sorry` while depending on an unfinished imported proof.

```lean
-- Conforming diagnostic for a concrete delivered root.
#print axioms Allocator.Reservation.reserve_no_wrap
```

```lean
-- Nonconforming proof; isolated negative fixture only.
theorem unfinished : False := by
  sorry
```

**Verification and limits:** Run the environment audit and inspect its root selection. A source-text search
cannot replace transitive dependency collection. The allowlist checks axioms, not whether premises hold in C.

<a id="lfv-003"></a>

### LFV-003: Export and replay the intended roots

**MUST · formal acceptance.** Build and audit first, then run isolated replay for the specified roots with the
pinned toolchain. Require the expected export and successful checker exit. Keep independent-checker evidence separate.

**Rationale and examples:** An accepted compilation and a completed replay provide different evidence.

```sh
# Conforming: from verification/theorems with the pinned Lake on PATH.
lake --wfail build LibMemAllocAudit
lake check
```

```sh
# Nonconforming as the entire formal acceptance procedure.
lake build
```

**Verification and limits:** Default replay targets are `LibMemAlloc` and `LibMemAllocTests`; audit code is
built explicitly and does not become a default export. Kernel replay requires working Linux bubblewrap
namespaces. `lake check --paranoid` adds independent checkers only when actually executed successfully.

<a id="lfv-004"></a>

### LFV-004: Require intended negative-control failures

**MUST · proof infrastructure changes.** Exercise imported `sorry`, imported custom axioms, missing roots,
changed statements and changed proof inputs. Preserve expected failure reasons. Do not count a parser error
or missing tool as proof that the axiom policy rejected a fixture.

**Rationale:** A broken checker can appear to pass when the only tested outcome is success.

```lean
-- Negative fixture: the public result depends on a custom imported assumption.
axiom unchecked : False
theorem bogus : False := unchecked
```

```text
Conforming observation: Forbidden axiom ...unchecked in the audited theorem closure.
Nonconforming observation: executable not found, reported as successful axiom rejection.
```

**Verification and limits:** The existing driver includes imported-axiom, imported-sorry and lint negative
controls. Additional scenarios in the pitfall catalogue are regression designs, not claims of current automation.

---

## Negative controls

| Mutation | Required disposition |
| --- | --- |
| An imported helper contains `sorry` | Transitive audit rejects `sorryAx` |
| A helper asserts a custom axiom | Transitive audit reports the forbidden axiom |
| A native proof computation adds a dedicated axiom | Current trust profile rejects it |
| A theorem keeps its name but changes a hypothesis | Contract snapshot comparison exposes the change |
| A definition changes behind the same theorem statement | Content review and source baseline expose the change |
| A new model file is not reachable from its root | Import-inventory check fails |
| A generated proof names a different program | Expected-program binding and proof acceptance fail |
| A theorem has no adjacent mathematical comment | Documentation review rejects conformance, including generated theorems |
| A comment drops a premise or changes a quantifier | Formula/type review rejects the claim even if the theorem compiles |
| Kernel isolation cannot start | Replay fails; no accepted evidence |

---

## Commands and boundaries

Run `lua scripts/verification/check.lua` from the repository root, then the replay command from the Lake
package as described above. The driver validates layout, catalogs, build/lint, snapshots and negative controls;
replay is a separate step. Do not regenerate baselines merely to silence a failure. Review their semantic
changes under [LCOMP-001](../lean-compliance.md#lcomp-001) first.

Proofs over natural-number addresses, abstract atomic steps or a fixed object graph retain those assumptions.
Use the [integration standard](../../formal-integration.md) to state the missing connection to concrete C
memory, concurrency and runtime behavior.

<!-- EOF -->


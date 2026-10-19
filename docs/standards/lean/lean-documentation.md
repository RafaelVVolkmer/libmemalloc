<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Lean Documentation Standard

Document the mathematical meaning, hypotheses and execution limits of a declaration. Use mathlib's module
structure and Lean's declaration docstrings. Apply the [code standard's governance](lean-code-standard.md#governance)
and its exception route to these controls.

<details>
<summary><strong>On this page</strong></summary>

- [Documentation controls](#documentation-controls)
- [Complete module](#complete-module)
- [Validation and sources](#validation-and-sources)

</details>

---

## Documentation controls

<a id="ldoc-001"></a>

### LDOC-001: Give the module a mathematical map

**MUST · owned modules.** Place a `/-!` module docstring after imports. Include a title, represented domain,
main definitions and results, notation, implementation decisions and references where applicable. Identify
the boundary between the mathematical model and C behavior. Omit empty template sections.

**Rationale:** A reader needs to locate the contract before inspecting tactics.

**Conforming fragment:**

```lean
/-!
# Reservation bounds

`Fits` describes a scalar reservation; `reserve_le_capacity` proves its bound.
Addresses and C object lifetimes are outside this module.
-/
```

**Nonconforming fragment:**

```lean
/-! Allocator proved safe. -/
```

**Verification and limits:** Compare the summary to the import graph and theorem inventory. The source checker
requires a module docstring marker; it cannot establish whether the summary is truthful.

<a id="ldoc-002"></a>

### LDOC-002: Document declarations according to their role

**MUST · exported APIs.** Use `/-- ... -/` immediately before the declaration and its attributes. Describe
a definition's result; a predicate's meaning; a structure's fields and invariant; a class's laws; and a
theorem's conclusion under its premises. For syntax or tactics, give accepted forms, effects and a small example.
Every theorem also requires the mathematical comment in [LDOC-004](#ldoc-004), regardless of visibility.

**Rationale:** A type signature alone may not identify units, ownership or the intended formal interpretation.

**Conforming fragment:**

```lean
/-- `Fits used requested capacity` requires the mathematical sum to fit in bytes. -/
def Fits (used requested capacity : Nat) : Prop := used + requested ≤ capacity
```

**Nonconforming fragment:**

```lean
/-- Does the check. -/
def Fits (used requested capacity : Nat) : Prop := used + requested ≤ capacity
```

**Verification and limits:** Inspect editor hover text and rendered source comments; compare the prose with
the elaborated type. The workspace has no configured mathlib documentation generator or missing-doc linter.

<a id="ldoc-003"></a>

### LDOC-003: Expose assumptions and evidence scope

**MUST · mapped results.** Link the requirement, explain hypotheses and identify the representation relation.
State whether the result is a model lemma, a bounded test or an implementation claim. Document noncomputability
and external execution assumptions where they affect callers.

**Rationale:** A valid theorem can have a narrower meaning than its informal description suggests.

**Conforming fragment:**

```lean
/-- Mathematical statement: ∀ used, requested, capacity ∈ ℕ,
(used + requested ≤ capacity) ⇒ used + requested ≤ capacity.
Scalar implication only; concrete pointer ownership remains a caller obligation.
-/
theorem reserve_le_capacity (used requested capacity : Nat)
    (hFits : used + requested ≤ capacity) : used + requested ≤ capacity := hFits
```

**Nonconforming fragment:**

```lean
/-- Proves memory safety of the complete C allocator. -/
theorem reserve_le_capacity (used requested capacity : Nat)
    (hFits : used + requested ≤ capacity) : used + requested ≤ capacity := hFits
```

**Verification and limits:** Review the statement and its source mapping independently of proof checking.
The tautological theorem above illustrates documentation scope; it supplies no implementation evidence.

<a id="ldoc-004"></a>

### LDOC-004: Place the mathematical formalization above every theorem

**MUST · all owned theorems, including private, auxiliary, regression and generated results.** Follow
[LSTYLE-MATH-001](lean-code-standard.md#lstyle-math-001): place a `/-- ... -/` comment immediately before the
theorem's attributes and declaration. For local `have` propositions and anonymous proof examples, put a `--`
comment immediately before the proof declaration. A generator must produce these comments alongside its
theorems; a reference to the generator's documentation is insufficient.

Include `Mathematical statement:` and a formula giving quantified variables, domains, every effective
hypothesis and the conclusion. Account for implicit binders and section variables. Explain mathematical
notation, units, arithmetic domains and any differences between formula symbols and Lean identifiers.
For relations over execution or memory, specify the relevant states, observations and frame conditions.
Preserve distinctions such as `∀` versus `∃`, implication versus equivalence, and equality versus refinement.

**Reason and examples:** The complete module below states each proposition before its proof. A comment
saying only “successful reservation is safe” omits the success premise and the exact capacity bound.
A formula claiming `∀ used, capacity ∈ ℕ, reserve used 0 capacity = some used` omits the required
`used ≤ capacity` premise and disagrees with `reserve_zero`.

**Verification and limits:** Inventory the theorem declarations and their adjacent comments; review each
formula against the elaborated statement and referenced definitions. Update comments and statements together.
Record missing or stale comments as nonconformance, even when the proof passes. The current source checker
checks module docstring markers, not per-theorem coverage or mathematical agreement. Proof checking and
axiom auditing remain separate requirements.

---

## Complete module

This standalone module uses Lean 4.35.0's bundled `Std`. It needs no mathlib dependency. It gives two
conditional facts and a concrete negative boundary case; it does not model memory allocation.

```lean
/-
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-/
import Std

/-!
# Scalar reservation

`reserve` rejects a request whose mathematical sum exceeds capacity.
`reserve_le_capacity` states the success bound; `reserve_zero` states the zero-request behavior.
C representation, pointer validity and concurrency require separate evidence.
-/

set_option autoImplicit false

namespace GuideReservation

/-- Reserve `requested` bytes after `used` bytes, returning the next usage. -/
def reserve (used requested capacity : Nat) : Option Nat :=
  if used + requested ≤ capacity then some (used + requested) else none

/-- Successful scalar reservation stays within capacity.
Mathematical statement: ∀ used, requested, capacity, next ∈ ℕ,
reserve used requested capacity = some next ⇒ next ≤ capacity.
All values count bytes in the scalar model.
-/
theorem reserve_le_capacity (used requested capacity next : Nat)
    (hResult : reserve used requested capacity = some next) : next ≤ capacity := by
  unfold reserve at hResult
  split at hResult
  · cases hResult
    assumption
  · contradiction

/-- Reserving zero preserves usage when the entry usage is valid.
Mathematical statement: ∀ used, capacity ∈ ℕ,
used ≤ capacity ⇒ reserve used 0 capacity = some used.
-/
theorem reserve_zero (used capacity : Nat) (hUsed : used ≤ capacity) :
    reserve used 0 capacity = some used := by
  simp [reserve, hUsed]

/-- Mathematical statement: reserve 3 6 8 = none over natural byte counts.
This concrete case has 3 + 6 > 8; it asserts rejection at that input only.
-/
theorem over_capacity_rejected : reserve 3 6 8 = none := by
  decide

end GuideReservation

#print axioms GuideReservation.reserve_le_capacity
#print axioms GuideReservation.reserve_zero
#print axioms GuideReservation.over_capacity_rejected

-- EOF
```

---

## Validation and sources

Save the complete module as `.cache/docs/lean/GuideReservation.lean` and run the pinned compiler:

```sh
.cache/lean/lean-4.35.0-linux/bin/lean -DwarningAsError=true .cache/docs/lean/GuideReservation.lean
```

Inspect the three axiom reports as well as the exit status. This manual example check does not replace the
workspace root audit or isolated kernel replay. Markdown checks do not elaborate Lean fences.

Sources: [mathlib Documentation Style](https://leanprover-community.github.io/contribute/doc.html), sections
Module docstrings and Docstrings, at the revision in the [source register](lean-code-standard.md#sources);
[Lean v4.35.0 documentation style](https://github.com/leanprover/lean4/blob/v4.35.0/doc/style.md), sections on
documenting declarations. References use backticks for Lean identifiers and prose links to the intended requirement.

<!-- EOF -->


<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Lean Code Standard

Use these local controls to review proof code and the property that code establishes. Apply the
[proof validation standard](test/lean-tests-formal.md) to delivered results and the
[pitfall catalogue](lean-common-pitfalls.md) to challenge assumptions and boundary conditions.

<details>
<summary><strong>On this page</strong></summary>

- [Governance and profile](#governance)
- [Source register](#sources)
- [Declarations and proof structure](#declarations-and-proof-structure)
- [Semantics and specification](#semantics-and-specification)
- [Proof acceptance and trust](#proof-acceptance-and-trust)

<details>
<summary>Detailed control index</summary>

- [LSTYLE-FORMAT-001: Keep source layout predictable](#lstyle-format-001)
- [LSTYLE-NAME-001: Describe the mathematical content in names](#lstyle-name-001)
- [LSTYLE-API-001: Expose hypotheses and useful interfaces](#lstyle-api-001)
- [LSTYLE-MATH-001: State every theorem mathematically above its declaration](#lstyle-math-001)
- [LSTYLE-PROOF-002: Structure proofs around intermediate claims](#lstyle-proof-002)
- [LSTYLE-SIMP-001: Stabilize intermediate simplification](#lstyle-simp-001)
- [LSTYLE-TRANSPARENT-001: Review transparency and instances as API changes](#lstyle-transparent-001)
- [LSTYLE-SPEC-001: Review the statement and assumptions](#lstyle-spec-001)
- [LSTYLE-NUM-001: Connect arithmetic domains explicitly](#lstyle-num-001)
- [LSTYLE-TERMINATION-001: State the termination argument](#lstyle-termination-001)
- [LSTYLE-RUNTIME-001: Keep execution observations distinct from proofs](#lstyle-runtime-001)
- [LSTYLE-PROOF-001: Reject incomplete theorem dependencies](#lstyle-proof-001)
- [LSTYLE-TRUST-001: Record the allowed axioms and mechanisms](#lstyle-trust-001)
- [LSTYLE-NATIVE-001: Audit native evaluation as a trust change](#lstyle-native-001)
- [LSTYLE-REPLAY-001: Recheck the required theorem roots](#lstyle-replay-001)
- [LSTYLE-NAME-002: Module, file and package names](#lstyle-name-002)
- [LSTYLE-NAME-003: Types, structures and inductive families](#lstyle-name-003)
- [LSTYLE-NAME-004: Predicates and proposition-valued functions](#lstyle-name-004)
- [LSTYLE-NAME-005: Computational definitions and constants](#lstyle-name-005)
- [LSTYLE-NAME-006: Theorem names](#lstyle-name-006)
- [LSTYLE-NAME-007: Structure fields and constructors](#lstyle-name-007)
- [LSTYLE-NAME-008: Local values, indices and units](#lstyle-name-008)
- [LSTYLE-NAME-009: Hypotheses and induction hypotheses](#lstyle-name-009)
- [LSTYLE-NAME-010: Type parameters and universes](#lstyle-name-010)
- [LSTYLE-NAME-011: Namespaces and sections](#lstyle-name-011)
- [LSTYLE-NAME-012: Instances and proposition classes](#lstyle-name-012)
- [LSTYLE-NAME-013: Acronyms, primes and generated names](#lstyle-name-013)
- [LSTYLE-NAME-014: Notation, syntax and tactics](#lstyle-name-014)
- [LSTYLE-NAME-015: Regression and boundary names](#lstyle-name-015)
- [LSTYLE-FORMAT-002: Line length and wrapping](#lstyle-format-002)
- [LSTYLE-FORMAT-003: Declaration and proof indentation](#lstyle-format-003)
- [LSTYLE-BLANK-001: License, imports and module documentation](#lstyle-blank-001)
- [LSTYLE-BLANK-002: Declaration and attribute attachment](#lstyle-blank-002)
- [LSTYLE-BLANK-003: Proof phases and branches](#lstyle-blank-003)
- [LSTYLE-BLANK-004: Sections, endings and EOF](#lstyle-blank-004)
- [LSTYLE-FORMAT-004: Operators, binders and delimiters](#lstyle-format-004)
- [LSTYLE-FORMAT-005: Unicode and lexical clarity](#lstyle-format-005)
- [LSTYLE-FORMAT-006: Term applications and lambdas](#lstyle-format-006)
- [LSTYLE-FORMAT-007: Structures and inductive declarations](#lstyle-format-007)
- [LSTYLE-FORMAT-008: Comments and documentation delimiters](#lstyle-format-008)
- [LSTYLE-SYNTAX-001: Tactic blocks and by placement](#lstyle-syntax-001)
- [LSTYLE-SYNTAX-002: Focused goals and named cases](#lstyle-syntax-002)
- [LSTYLE-SYNTAX-003: Calculation chains](#lstyle-syntax-003)
- [LSTYLE-SYNTAX-004: Have, let and show](#lstyle-syntax-004)
- [LSTYLE-SYNTAX-005: Rewriting and equality direction](#lstyle-syntax-005)
- [LSTYLE-SYNTAX-006: Simp lemmas and normal forms](#lstyle-syntax-006)
- [LSTYLE-SYNTAX-007: Pattern matching and conditionals](#lstyle-syntax-007)
- [LSTYLE-SYNTAX-008: Explicit, implicit and instance arguments](#lstyle-syntax-008)
- [LSTYLE-SYNTAX-009: Scoped notation and open commands](#lstyle-syntax-009)
- [LSTYLE-SYNTAX-010: Instances and coercions](#lstyle-syntax-010)
- [LSTYLE-SYNTAX-011: Termination and decreasing measures](#lstyle-syntax-011)
- [LSTYLE-SYNTAX-012: Classical and noncomputable code](#lstyle-syntax-012)
- [LSTYLE-SYNTAX-013: Tactic search and options](#lstyle-syntax-013)
- [LSTYLE-PERF-001: Elaboration and replay costs](#lstyle-perf-001)

</details>

</details>

---

<a id="governance"></a>

## Governance and profile

`MUST` denotes an acceptance requirement; `SHOULD` permits a justified alternative. IDs are local controls,
not mathlib rule numbers. Each control states scope, reason, conforming/nonconforming examples and evidence
limits. The default exception route is [LCOMP-003](lean-compliance.md#lcomp-003), with rule, scope, rationale,
evidence, owner and expiry. An exception cannot turn an incomplete proof into an accepted result.

The **model** contains mathematical definitions and theorems. **Tests** exercise models and deliberate
counterexamples. **Audit** code inspects environments and exports evidence. **Runtime adapters** execute
processes and handle external data. Preserve those boundaries when importing modules.

The [toolchain](../../../verification/theorems/lean-toolchain) pins Lean 4.35.0. The
[Lake package](../../../verification/theorems/lakefile.toml) sets `autoImplicit = false`, `warningAsError = true`
and built-in unused-variable, unused-simp-argument and deprecation linters. No mathlib or Batteries dependency
is present. New checks described as review requirements do not become automated merely by appearing here.

Code fragments need their surrounding declarations. Complete modules identify their imports and can be
checked separately. Deliberate `sorry`, custom axioms and bad statements belong only in isolated negative
fixtures. The mathematical-comment requirement applies to all owned theorems, including existing and generated
ones. Other controls define new and changed work. These guides do not assert whole-tree conformance.
Contextual examples illustrate their named control; complete acceptance also requires the theorem documentation.

---

<a id="sources"></a>

## Source register

Semantics come from Lean 4.35.0. Editorial choices follow mathlib unless the repository profile states a
local difference. Consulted 2026-10-15. The community pages use revision
`8cadd51b3825ac4762b74c181c72db36a420ec8f`; immutable source links retain that revision.

| Source | Sections and role |
| --- | --- |
| [Lean 4.35.0 reference](https://lean-lang.org/doc/reference/4.35.0/) | Elaboration, type system, definitions, axioms and runtime semantics |
| [Validating a Lean Proof](https://lean-lang.org/doc/reference/4.35.0/ValidatingProofs/) | Printing Axioms, rechecking, external checkers and native evaluation |
| [Axioms](https://lean-lang.org/doc/reference/4.35.0/Axioms/) | Standard logical axioms and consequences for computation |
| [Recursive definitions](https://lean-lang.org/doc/reference/4.35.0/Definitions/Recursive-Definitions/) | Structural/well-founded recursion and partial definitions |
| [Mathlib style](https://leanprover-community.github.io/contribute/style.html) · [pinned source](https://github.com/leanprover-community/leanprover-community.github.io/blob/8cadd51b3825ac4762b74c181c72db36a420ec8f/templates/contribute/style.md) | Tactic mode, calculations, squeezing simp, transparency and API design |
| [Mathlib naming](https://leanprover-community.github.io/contribute/naming.html) · [pinned source](https://github.com/leanprover-community/leanprover-community.github.io/blob/8cadd51b3825ac4762b74c181c72db36a420ec8f/templates/contribute/naming.md) | Declaration, theorem and file names |
| [Mathlib documentation](https://leanprover-community.github.io/contribute/doc.html) · [pinned source](https://github.com/leanprover-community/leanprover-community.github.io/blob/8cadd51b3825ac4762b74c181c72db36a420ec8f/templates/contribute/doc.md) | Module docstrings, declaration docs, references and implementation notes |
| [Lean documentation style, v4.35.0](https://github.com/leanprover/lean4/blob/v4.35.0/doc/style.md) | Documentation for definitions, predicates, structures, classes, tactics and syntax |
| [FlexibleLinter](https://leanprover-community.github.io/mathlib4_docs/Mathlib/Tactic/Linter/FlexibleLinter.html) | Flexible tactics and unstable intermediate goals; supplementary review reference |
| [Theorem Proving in Lean 4](https://lean-lang.org/theorem_proving_in_lean4/) | Tactics, induction and axioms; teaching reference, not a local rule source |
| [Functional Programming in Lean](https://lean-lang.org/functional_programming_in_lean/) | Programs, effects and recursion; teaching reference |

The books and generated linter page evolve independently of this workspace. Check examples against 4.35.0;
their links do not authorize a toolchain or dependency upgrade. For maintenance rationale, see the pinned
[Growing Mathlib paper, version 1](https://arxiv.org/html/2508.21593v1), especially sections on linters,
deprecation and review tooling. Local rules below add allocator-specific evidence obligations.

---

## Declarations and proof structure

<a id="lstyle-math-001"></a>

### LSTYLE-MATH-001: State every theorem mathematically above its declaration

**MUST · every owned Lean theorem.** Put a `/-- ... -/` declaration comment immediately above each theorem,
before its attributes and declaration modifiers. Cover exported and private theorems, auxiliary lemmas,
regressions and generated certificates. Generators must emit the comment with the theorem. Use a preceding
`--` comment for a local proposition proved by `have` and for an anonymous proof example. A file-level summary
or a comment inside or after the proof does not replace the statement above the declaration.

Start the mathematical part with `Mathematical statement:`. Express the proposition in mathematical notation
with quantified variables, domains, hypotheses and conclusion. Include implicit and section hypotheses that
affect the elaborated statement. Define notation, units and correspondence to Lean identifiers; distinguish
natural subtraction, integer arithmetic and bounded machine arithmetic. For a state relation, name the initial
and final states and any frame conditions. Preserve the actual quantifier order and logical direction.

**Conforming contextual fragment:**

```lean
/-- Mathematical statement: ∀ used, requested, capacity ∈ ℕ,
(used ≤ capacity ∧ requested ≤ capacity − used) ⇒ used + requested ≤ capacity.
Values count bytes; subtraction is natural subtraction. This is a scalar bound.
-/
theorem reservation_bound (used requested capacity : Nat)
    (hUsed : used ≤ capacity) (hRequested : requested ≤ capacity - used) :
    used + requested ≤ capacity := by
  omega
```

**Nonconforming fragment:**

```lean
/-- Proves reservation safety. -/
theorem reservation_bound (used requested capacity : Nat)
    (hUsed : used ≤ capacity) (hRequested : requested ≤ capacity - used) :
    used + requested ≤ capacity := by
  omega
```

**Reason and verification:** Reviewers must be able to compare a mathematical claim with the elaborated
proposition before reading its proof. Check each comment against its theorem type and referenced definitions
under [LDOC-004](lean-documentation.md#ldoc-004), and update them together. Kernel checking and the transitive
axiom audit remain mandatory; neither checks the truth of prose. The current lexical checker does not enforce
per-theorem mathematical comments, so a successful build alone cannot establish compliance with this rule.
Private visibility, a short proof or generated origin does not exempt a theorem.

<a id="lstyle-format-001"></a>

### LSTYLE-FORMAT-001: Keep source layout predictable

**MUST · owned Lean files.** Use two-space indentation, LF, no trailing whitespace, a license header and a
module docstring. Keep lines within 100 Unicode code points as measured by the local checker. Use one sorted,
unique module import per line. Put a theorem's `by` at the end of its declaration line when it fits.

**Reason and examples:** Conforming: an indented tactic block with focused `·` branches. Nonconforming:
tab indentation or multiple imports on a line that escapes the declared import inventory.

**Verification and limit:** `scripts/verification/lib/style.lua` checks lexical layout and import reachability.
It is not a parser or full mathlib style linter. Proof readability still needs review.

**Conforming contextual fragment:**

```lean
theorem add_zero_value (n : Nat) : n + 0 = n := by
  simp
```

**Nonconforming fragment (do not copy):**

```lean
theorem add_zero_value(n:Nat):n+0=n:=by simp
```

<a id="lstyle-name-001"></a>

### LSTYLE-NAME-001: Describe the mathematical content in names

**SHOULD · declarations.** Use `UpperCamelCase` for types and namespaces, `lowerCamelCase` for data-producing
definitions, and `snake_case` for theorem names. Use `UpperCamelCase` for `Prop`-valued definitions.
Retain semantic components of referenced names when constructing a theorem name. Match module/file case.

**Reason and examples:** Conforming: `reserve`, `ReserveError`, `reserve_preserves_capacity`.
Nonconforming: `lemma42` for a public result or importing C prefixes into new proof names without a binding need.

**Verification and limit:** Review name/content correspondence and search existing APIs. Neither elaboration
nor the local lexical checker enforces full naming conventions. Source: mathlib Naming Conventions.

**Conforming contextual fragment:**

```lean
def Fits (used capacity : Nat) : Prop := used ≤ capacity

def remainingBytes (capacity used : Nat) : Nat := capacity - used
```

**Nonconforming fragment (do not copy):**

```lean
def fits_prop (used capacity : Nat) : Prop := used ≤ capacity
```

<a id="lstyle-api-001"></a>

### LSTYLE-API-001: Expose hypotheses and useful interfaces

**MUST · exported definitions/theorems.** Declare parameters and result types; retain `autoImplicit = false`.
Use namespaces and bounded sections to control variables and instances. Provide interface lemmas for operations
that clients otherwise unfold repeatedly.

**Reason and examples:** Conforming: `(used requested capacity : Nat)` with a named capacity hypothesis.
Nonconforming: an accidental free identifier generalized into a parameter or reliance on an unrelated open namespace.

**Verification and limit:** Inspect elaborated types and declaration dependencies. Explicit binders do not
prove that the statement matches the requirement. Source: Lean reference, Namespaces and Sections; mathlib API style.

**Conforming contextual fragment:**

```lean
set_option autoImplicit false

def reserve (used requested capacity : Nat) : Option Nat :=
  if used + requested ≤ capacity then some (used + requested) else none
```

**Nonconforming fragment (do not copy):**

```lean
set_option autoImplicit true
-- Unreviewed inferred binders may conceal spelling errors.
```

<a id="lstyle-proof-002"></a>

### LSTYLE-PROOF-002: Structure proofs around intermediate claims

**SHOULD · proofs.** Use named `have` statements for semantic steps, `calc` for chains of relations and focused
branches for cases. Keep tactic sequences readable; use short direct terms where they state the argument clearly.

**Reason and examples:** Conforming: a named no-wrap bound followed by its application to the result.
Nonconforming: a long repeated tactic chain that depends on unnamed hypotheses and branch order.

**Verification and limit:** Rebuild affected proofs and review the mathematical steps. Kernel acceptance
does not measure maintainability. Source: mathlib style, Calculations and Tactic mode.

**Conforming contextual fragment:**

```lean
theorem sum_comm (a b : Nat) : a + b + 0 = b + a := by
  calc
    a + b + 0 = a + b := Nat.add_zero _
    _ = b + a := Nat.add_comm a b
```

**Nonconforming fragment (do not copy):**

```lean
-- Nonconforming maintenance pattern: a long search/rotation chain with no named steps.
```

<a id="lstyle-simp-001"></a>

### LSTYLE-SIMP-001: Stabilize intermediate simplification

**SHOULD · simplifier proofs.** Use explicit lemmas or `simp only` when later steps depend on an exact
intermediate shape. Allow terminal `simp` when it closes the goal. Do not expand every terminal simplification
into a long list of incidental lemmas. Review new global `@[simp]` lemmas for orientation and downstream cost.

**Reason and examples:** Conforming fragment: `simpa [definition] using h` for a closing step.
Nonconforming: an intermediate broad `simp` followed by a fragile positional rewrite, without reviewing its shape.

**Verification and limit:** Rebuild callers, inspect changed normal forms and compare elaboration costs.
FlexibleLinter describes this maintenance risk but is not installed here. Source: mathlib style, Squeezing simp calls.

**Conforming contextual fragment:**

```lean
example (n : Nat) : n + 0 = n := by
  simp
```

**Nonconforming fragment (do not copy):**

```lean
-- Nonconforming review policy: require expanded simp only lists for every terminal simp.
```

<a id="lstyle-transparent-001"></a>

### LSTYLE-TRANSPARENT-001: Review transparency and instances as API changes

**MUST · definitions, coercions and instances.** Explain changes to `def`, `abbrev`, opacity, instance scope
and simplification attributes. Prefer a stable operation API to repeated unfolding of representation details.

**Reason and examples:** Conforming: a documented equation lemma for a wrapper operation. Nonconforming:
switch a large `def` to `abbrev` only to make one tactic succeed, without checking dependent elaboration.

**Verification and limit:** Rebuild clients and measure affected proofs. Transparency settings influence
elaboration; they are not an axiom audit. Source: mathlib style, Transparency and API design.

**Conforming contextual fragment:**

```lean
def remainingBytes (capacity used : Nat) : Nat := capacity - used
```

**Nonconforming fragment (do not copy):**

```lean
-- Nonconforming: change a large opaque API to an abbrev solely to unblock one tactic.
```

---

## Semantics and specification

<a id="lstyle-spec-001"></a>

### LSTYLE-SPEC-001: Review the statement and assumptions

**MUST · delivered results.** Trace the elaborated statement to the intended requirement. Identify all premises,
quantifier order, represented operations, arithmetic domains and excluded behaviors. Review assumptions for
consistency and realizability; seek an admitted witness where practical.

**Reason and examples:** Conforming: prove a postcondition from validated entry bounds and defined semantics.
Nonconforming: add the desired postcondition as a premise or quantify over an impossible entry state.

**Verification and limit:** Review contract snapshots, definitions and concrete boundary cases alongside the
proof. The kernel checks the proposition supplied to it; it does not interpret the allocator requirement.
Source: Lean reference, Validating a Lean Proof, distinction between validity and meaning.

**Conforming contextual fragment:**

```lean
theorem requested_fits (used requested capacity : Nat)
    (h : used + requested ≤ capacity) : requested ≤ capacity := by
  omega
```

**Nonconforming fragment (do not copy):**

```lean
theorem result (alreadyProved : False) : False := alreadyProved
-- Not evidence for a realizable allocator operation.
```

<a id="lstyle-num-001"></a>

### LSTYLE-NUM-001: Connect arithmetic domains explicitly

**MUST · allocator arithmetic.** Distinguish `Nat`, `Int`, `Fin`, `UInt` and `BitVec` domains. State width,
range and coercion obligations at each representation boundary. Review subtraction and division at zero.

**Reason and examples:** Conforming: a bound justifies converting a natural sum to a fixed-width result.
Nonconforming: infer C subtraction behavior from `Nat`, where subtraction truncates at zero, or use a
mathematical division result to claim C division by zero is defined.

**Verification and limit:** Prove the representation lemma and test boundary values. Equal printed numerals
do not imply equal arithmetic semantics. Source: Lean 4.35.0 reference, Basic Types and coercions.

**Conforming contextual fragment:**

```lean
example (used capacity : Nat) (h : used ≤ capacity) :
    used + (capacity - used) = capacity := by omega
```

**Nonconforming fragment (do not copy):**

```lean
-- Nonconforming claim: Nat subtraction models unsigned wraparound without a relation.
```

<a id="lstyle-termination-001"></a>

### LSTYLE-TERMINATION-001: State the termination argument

**MUST · executable model definitions.** Use structural recursion or a justified well-founded measure when
the definition participates in proofs. Distinguish termination of that definition from progress, fairness
and wall-clock bounds of the real system. Keep partial runtime algorithms outside the logical model interface.

**Reason and examples:** Conforming: recursive exploration decreases finite fuel and returns incomplete when
fuel ends. Nonconforming: describe a fuel-bounded result as proof of termination for every allocator execution.

**Verification and limit:** Check the recursive definition and review what its measure represents. Lean's
accepted `partial` definitions do not provide ordinary unfolding equations for logical reasoning; runtime
termination still needs its own evidence. Source: Lean reference, Recursive Definitions.

**Conforming contextual fragment:**

```lean
def countdown : Nat → Nat
  | 0 => 0
  | n + 1 => countdown n
```

**Nonconforming fragment (do not copy):**

```lean
partial def spin (n : Nat) : Nat := spin n
```

<a id="lstyle-runtime-001"></a>

### LSTYLE-RUNTIME-001: Keep execution observations distinct from proofs

**MUST · runtime/model boundaries.** Record whether evidence came from `#eval`, a compiled executable, a
kernel-checked theorem or a separate replay. Review `unsafe`, foreign implementations and runtime replacements
as added execution trust. Do not infer representation correctness from equal sample outputs.

**Reason and examples:** Conforming: a regression records a compiled result alongside the theorem it tests.
Nonconforming: a printed `true` is the sole acceptance artifact for a quantified safety property.

**Verification and limit:** Reconstruct the required proof and retain execution logs separately. Kernel proof
checking alone does not verify compiled code. Source: Lean reference, Run-Time Code and Validating a Lean Proof.

**Conforming contextual fragment:**

```lean
theorem sample : (2 : Nat) + 2 = 4 := by decide
```

**Nonconforming fragment (do not copy):**

```lean
#eval (2 : Nat) + 2 == 4
-- Insufficient as the sole proof acceptance evidence.
```

---

## Proof acceptance and trust

<a id="lstyle-proof-001"></a>

### LSTYLE-PROOF-001: Reject incomplete theorem dependencies

**MUST · accepted theorem closures.** Reject `sorryAx`, including through imports and helper lemmas. Audit
transitive axiom dependencies of the delivered results, not only occurrences of `sorry` in their source files.
An isolated negative fixture must demonstrate rejection for this cause.

**Reason and examples:** Conforming: audit a theorem using an imported helper and reject an incomplete helper.
Nonconforming: accept a clean-looking public theorem after searching only that file for `sorry`.

**Verification and limit:** The local audit and negative controls enforce this for their inventoried roots.
Review root coverage: an unaudited declaration is outside that evidence. No exception allows `sorryAx` in an
accepted profile. Source: Lean reference, Validating a Lean Proof, Printing Axioms.

**Conforming contextual fragment:**

```lean
#print axioms Allocator.Reservation.reserve_no_wrap
```

**Nonconforming fragment (do not copy):**

```lean
theorem unfinished : False := by sorry
```

<a id="lstyle-trust-001"></a>

### LSTYLE-TRUST-001: Record the allowed axioms and mechanisms

**MUST · proof profiles.** Record the actual transitive axiom set and the allowed set. The current profile
allows only `propext`, `Quot.sound` and `Classical.choice`. Reject custom and native-evaluation axioms.
Put implementation/environment assumptions in visible theorem premises and the trust record.

**Reason and examples:** Conforming: record use of `Classical.choice` under the declared policy.
Nonconforming: claim “no axioms” while using choice, or hide a backend correctness assumption as a proved fact.

**Verification and limit:** Compare axiom reports with the allowlist and review hypotheses separately. An
allowlist cannot establish that the admitted premises hold in C. Source: Lean reference, Axioms; local
[trust model](../../../docs/assurance/formal-trust.md). A different set requires a new reviewed profile.

**Conforming contextual fragment:**

```text
allowed axioms: propext, Quot.sound, Classical.choice
actual axioms: recorded per delivered theorem
```

**Nonconforming fragment (do not copy):**

```text
allowed axioms: any dependency that makes the build pass
```

<a id="lstyle-native-001"></a>

### LSTYLE-NATIVE-001: Audit native evaluation as a trust change

**MUST · proof-producing computation.** Reject native proof axioms under the current profile. Treat use of
`native_decide`, `decide +native` or other compiled-evaluation proof paths according to their resulting
dependencies. `bv_decide` also needs this scrutiny. Ordinary kernel-reduced `decide` has a different trust path.

**Reason and examples:** Conforming: a small decidable result checks without native axioms. Nonconforming:
accept native computation because the source has no explicit `axiom` command.

**Verification and limit:** Audit transitive dependencies and replay exports. Lean 4.35 uses per-computation
native axioms; checking only the historical `Lean.trustCompiler` name is insufficient. If a future profile
admits native computation, record compiler/runtime/foreign dependencies and reduced rechecking guarantees.
Source: Lean reference, Validating a Lean Proof, native evaluation; 4.35 release notes.

**Conforming contextual fragment:**

```lean
example : (1 : Nat) + 1 = 2 := by decide
```

**Nonconforming fragment (do not copy):**

```lean
example : (1 : Nat) + 1 = 2 := by native_decide
```

<a id="lstyle-replay-001"></a>

### LSTYLE-REPLAY-001: Recheck the required theorem roots

**MUST · formal acceptance.** Run the pinned replay on the intended exported roots, in addition to building
and auditing. Treat a missing executable, failed sandbox startup, timeout or absent root as incomplete evidence.
Report optional independent-checker results under their own profile.

**Reason and examples:** Conforming: retain a successful `lake check` export/replay result for the default
model/test targets. Nonconforming: substitute a successful `lake build` or silently skip an unavailable checker.

**Verification and limit:** Check root inventory, statuses and expected rejection fixtures. Replay increases
confidence in proof checking; it does not establish source-to-C correspondence. See
[LFV-003](test/lean-tests-formal.md#lfv-003) for the current commands and coverage.

**Conforming contextual fragment:**

```sh
lake --wfail build LibMemAllocAudit
lake check
```

**Nonconforming fragment (do not copy):**

```sh
lake build # treated as the whole acceptance procedure
```

---

## Detailed naming, whitespace and syntax controls

These controls define the local spelling and source layout for each category. They refine the earlier policy controls.
Examples are contextual fragments unless marked complete: surrounding types, imports and values may be supplied by the
owning module. A nonconforming fragment may be legal code that violates a local convention, or deliberately invalid
syntax. Do not compile the negative set as positive examples. Formatting examples use the pinned profile.

---

<a id="lstyle-name-002"></a>

### LSTYLE-NAME-002: Module, file and package names

**Class:** local engineering control. **Obligation:** MUST. **Scope:** workspace layout.

Use UpperCamelCase file/module components that match import paths, keeping LibMemAllocImp, LibMemAllocTests and
LibMemAllocAudit as declared roots. Keep the Lake package name libmemalloc-verification distinct from declaration
namespaces, which currently retain Allocator.

**Rationale:** A file path, library root and namespace are different identities.

**Conforming contextual fragment:**

```lean
-- LibMemAllocImp/MemoryAllocator/Reservation.lean
namespace Allocator.Reservation
end Allocator.Reservation
```

**Nonconforming fragment (do not copy):**

```lean
-- libmemallocimp/memory_allocator/reservation.lean
namespace Reservation
end Reservation
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-name-003"></a>

### LSTYLE-NAME-003: Types, structures and inductive families

**Class:** local engineering control. **Obligation:** MUST. **Scope:** type-producing declarations.

Use UpperCamelCase for types and type constructors, including definitions returning a `Type` or `Sort`. Prefer a
domain
name to a representation suffix. Keep type parameters recognizable.

**Rationale:** Mathlib names a function according to the kind of value it returns.

**Conforming contextual fragment:**

```lean
structure Cursor where
  usedBytes : Nat
  capacityBytes : Nat
```

**Nonconforming fragment (do not copy):**

```lean
structure cursor_t where
  used_bytes : Nat
  capacity_bytes : Nat
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-name-004"></a>

### LSTYLE-NAME-004: Predicates and proposition-valued functions

**Class:** local engineering control. **Obligation:** MUST. **Scope:** `Prop` definitions.

Use UpperCamelCase for predicates such as ValidCursor or Fits. Reserve snake_case for proofs of propositions. A
noun-like proposition class may use Is or Has; an adjective can stand alone.

**Rationale:** A proposition and a term proving that proposition have different naming roles.

**Conforming contextual fragment:**

```lean
def Fits (used requested capacity : Nat) : Prop := used + requested ≤ capacity
```

**Nonconforming fragment (do not copy):**

```lean
def fits (used requested capacity : Nat) : Prop := used + requested ≤ capacity
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-name-005"></a>

### LSTYLE-NAME-005: Computational definitions and constants

**Class:** local engineering control. **Obligation:** MUST. **Scope:** data-producing values.

Use lowerCamelCase for functions and constants returning ordinary data, including `Bool`. Use a name that
distinguishes
a `Bool` test from its `Prop` specification when both are exported.

**Rationale:** A decidable proposition and its Boolean representation need an explicit connection.

**Conforming contextual fragment:**

```lean
def fits (used requested capacity : Nat) : Bool := decide (used + requested ≤ capacity)
```

**Nonconforming fragment (do not copy):**

```lean
def FITS (used requested capacity : Nat) : Bool := decide (used + requested ≤ capacity)
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-name-006"></a>

### LSTYLE-NAME-006: Theorem names

**Class:** local engineering control. **Obligation:** MUST. **Scope:** public and private lemmas.

Use snake_case that describes the conclusion and, where useful, the decisive hypothesis. Use established suffixes such
as `_eq`, `_iff`, `_of_le` or `_le`. Preserve lowerCamelCase function components inside the theorem name, such as
`checkedAdd_spec`; do not mechanically split their internal capitals.

**Rationale:** Searchable names connect API operations to their mathematical results.

**Conforming contextual fragment:**

```lean
theorem add_zero_eq (n : Nat) : n + 0 = n := by simp
```

**Nonconforming fragment (do not copy):**

```lean
theorem helper123 (n : Nat) : n + 0 = n := by simp
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-name-007"></a>

### LSTYLE-NAME-007: Structure fields and constructors

**Class:** local engineering control. **Obligation:** MUST. **Scope:** members.

Apply the return-value naming convention to members: lowerCamelCase for data, UpperCamelCase for proposition/type
families and snake_case for proof fields. Use namespace qualification rather than repeating the parent type in every
field. Inductive constructors follow their result category.

**Rationale:** Fields can contain data, predicates or proofs; spelling should distinguish them.

**Conforming contextual fragment:**

```lean
structure Cursor where
  usedBytes : Nat
  capacityBytes : Nat
  used_le_capacity : usedBytes ≤ capacityBytes
```

**Nonconforming fragment (do not copy):**

```lean
structure Cursor where
  cursor_used_bytes : Nat
  cursor_capacity_bytes : Nat
  cursorProof : cursor_used_bytes ≤ cursor_capacity_bytes
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-name-008"></a>

### LSTYLE-NAME-008: Local values, indices and units

**Class:** local engineering control. **Obligation:** MUST. **Scope:** binders and let bindings.

Use descriptive lowerCamelCase for program values and quantity suffixes such as Bytes or Count. Use n, i, x and `xs`
for
short conventional mathematical roles. Keep different units distinct in names or types.

**Rationale:** A local proof can hide a units error while remaining well typed over `Nat`.

**Conforming contextual fragment:**

```lean
def remainingBytes (capacityBytes usedBytes : Nat) : Nat := capacityBytes - usedBytes
```

**Nonconforming fragment (do not copy):**

```lean
def remaining (a b : Nat) : Nat := a - b
-- The interface does not identify units or operand roles.
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-name-009"></a>

### LSTYLE-NAME-009: Hypotheses and induction hypotheses

**Class:** local engineering control. **Obligation:** MUST. **Scope:** proof binders.

Use h with a meaningful suffix such as `hFits` or `hUsed`; use `ih` for an induction hypothesis. Short h, h₁ and h₂
are
acceptable in a small generic argument. Avoid retaining generated names that depend on elaborator choices; rename or
bind them explicitly.

**Rationale:** A proof should say which assumption each step uses.

**Conforming contextual fragment:**

```lean
theorem le_from_lt (used capacity : Nat) (hUsed : used < capacity) : used ≤ capacity :=
  Nat.le_of_lt hUsed
```

**Nonconforming fragment (do not copy):**

```lean
theorem le_from_lt (used capacity : Nat) (a_1 : used < capacity) : used ≤ capacity :=
  Nat.le_of_lt a_1
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-name-010"></a>

### LSTYLE-NAME-010: Type parameters and universes

**Class:** local engineering control. **Obligation:** MUST. **Scope:** generic declarations.

Use α, β, γ for generic types, descriptive names for domain types, and u, v for universe levels. Declare universes and
binders explicitly under `autoImplicit` false. Do not force `Type` when `Type` u or `Sort` u is required by the
intended
generality.

**Rationale:** Accidental monomorphism narrows reusable statements.

**Conforming contextual fragment:**

```lean
universe u

def identity {α : Sort u} (value : α) : α := value
```

**Nonconforming fragment (do not copy):**

```lean
set_option autoImplicit true
def identity (value : α) : α := value
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-name-011"></a>

### LSTYLE-NAME-011: Namespaces and sections

**Class:** local engineering control. **Obligation:** MUST. **Scope:** namespaces and sections.

Use a named namespace for owned API declarations and descriptive section names for temporary contexts. Match explicit
end names for long scopes. Do not encode privacy solely through a leading underscore.

**Rationale:** Qualified identity must remain stable when a file is reorganized.

**Conforming contextual fragment:**

```lean
namespace Allocator.Reservation

section Bounds
-- Related declarations.
end Bounds

end Allocator.Reservation
```

**Nonconforming fragment (do not copy):**

```lean
namespace Stuff
section
-- Unclear ownership and scope.
end
end Stuff
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-name-012"></a>

### LSTYLE-NAME-012: Instances and proposition classes

**Class:** local engineering control. **Obligation:** MUST. **Scope:** typeclass declarations.

Use names consistent with mathlib inst conventions when a named instance is useful, such as instInhabitedCursor.
Anonymous instances are allowed when their generated name is not part of the API. Name proposition classes with the
predicate convention and document their laws.

**Rationale:** Typeclass search and explicit references need predictable ownership.

**Conforming contextual fragment:**

```lean
instance instInhabitedCursor : Inhabited Cursor where
  default := ⟨0, 0, Nat.le_refl 0⟩
```

**Nonconforming fragment (do not copy):**

```lean
instance magicDefault : Inhabited Cursor where
  default := ⟨0, 0, Nat.le_refl 0⟩
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-name-013"></a>

### LSTYLE-NAME-013: Acronyms, primes and generated names

**Class:** local engineering control. **Obligation:** MUST. **Scope:** public names.

Preserve an acronym as a group, following the case of its first character, such as `LE` or `le`. Use a trailing prime only
for an adjacent variant with a documented distinction. Generated theorem names must be deterministic,
collision-checked and bound to a stable input identity.

**Rationale:** Unstable names break contract snapshots and make generated proof review ambiguous.

**Conforming contextual fragment:**

```lean
-- Existing API names remain stable.
-- Generated entry point: CursorRun.accepted_program
-- Variant: reserve_spec' has an explicitly documented alternate premise.
```

**Nonconforming fragment (do not copy):**

```lean
-- Generated entry points must not be random names such as result_43817.
-- A public chain reserve_spec''' hides the intended distinctions.
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-name-014"></a>

### LSTYLE-NAME-014: Notation, syntax and tactics

**Class:** local engineering control. **Obligation:** MUST. **Scope:** language extensions.

Prefer existing notation. Give custom syntax a scoped, documented meaning, precedence and associativity. Give tactic
or command elaborators descriptive implementation names and keep their public keyword stable. Do not shadow standard
arithmetic or equality notation.

**Rationale:** Notation changes the proposition a reviewer thinks they are reading.

**Conforming contextual fragment:**

```lean
namespace CursorNotation
scoped notation "byteLimit" => (256 : Nat)
end CursorNotation
```

**Nonconforming fragment (do not copy):**

```lean
local infix:50 " ≤ " => Nat.lt
-- Changes the apparent meaning of a familiar relation.
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-name-015"></a>

### LSTYLE-NAME-015: Regression and boundary names

**Class:** local engineering control. **Obligation:** MUST. **Scope:** tests and foreign interfaces.

Use a named theorem for a regression retained in the audit; use example for a disposable illustration. Preserve exact
external C symbol spellings in binding records while exposing Lean operations with the appropriate local convention.
Never rename a contract root without updating its inventory.

**Rationale:** Anonymous examples cannot serve as stable theorem identities in evidence records.

**Conforming contextual fragment:**

```lean
theorem zero_request_fits : (0 : Nat) + 0 ≤ 0 := Nat.le_refl 0
```

**Nonconforming fragment (do not copy):**

```lean
example : (0 : Nat) + 0 ≤ 0 := Nat.le_refl 0
-- Inadequate when the contract requires a named auditable root.
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-format-002"></a>

### LSTYLE-FORMAT-002: Line length and wrapping

**Class:** local engineering control. **Obligation:** MUST. **Scope:** source and docstrings.

Keep each line at or below 100 Unicode code points, including comments. Wrap declaration binders and propositions at
semantic boundaries. Keep indivisible external material in a referenced artifact; the existing source checker has no
automatic overlength exception.

**Rationale:** The local line limit is a concrete gate, including for mathematical text.

**Conforming contextual fragment:**

```lean
theorem bounded_sum (used requested capacity : Nat)
    (hUsed : used ≤ capacity) (hRequested : requested ≤ capacity - used) :
    used + requested ≤ capacity := by
  omega
```

**Nonconforming fragment (do not copy):**

```lean
theorem bounded_sum (used requested capacity : Nat) (hUsed : used ≤ capacity) (hRequested : requested ≤ capacity - used) : used + requested ≤ capacity := by omega
```

**Verification and limits:** Run the local style checker for source; count Unicode code points rather than bytes.
Markdown prose has its own 120-column policy, which does not relax Lean source limits.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-format-003"></a>

### LSTYLE-FORMAT-003: Declaration and proof indentation

**Class:** local engineering control. **Obligation:** MUST. **Scope:** multiline definitions.

Keep top-level commands flush left, including inside namespaces and sections. Indent continued declaration lines four
spaces and proof/body lines two spaces. Indent each nested term by two more spaces.

**Rationale:** Statement continuation must remain visually distinct from proof steps.

**Conforming contextual fragment:**

```lean
namespace Demo

theorem same_value (n : Nat)
    (h : n = 0) : n + 0 = 0 := by
  simpa using h

end Demo
```

**Nonconforming fragment (do not copy):**

```lean
namespace Demo
  theorem same_value (n : Nat)
  (h : n = 0) : n + 0 = 0 := by
      simpa using h
end Demo
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-blank-001"></a>

### LSTYLE-BLANK-001: License, imports and module documentation

**Class:** local engineering control. **Obligation:** MUST. **Scope:** file prologue.

Keep the license block first, followed by imports. Use no blank lines within the sorted import block. Use one blank
line before the module /-! docstring, after that docstring and after opening the namespace. The license may meet the
first import directly, matching existing files.

**Rationale:** The prologue should show provenance, dependencies and purpose in that order.

**Conforming contextual fragment:**

```lean
/- SPDX-License-Identifier: GPL-3.0-only -/
import Std

/-!
# Reservation bounds

Scalar bounds for reservation.
-/

namespace Allocator.Reservation
```

**Nonconforming fragment (do not copy):**

```lean
import Std
/-! # Reservation bounds -/
namespace Allocator.Reservation
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-blank-002"></a>

### LSTYLE-BLANK-002: Declaration and attribute attachment

**Class:** local engineering control. **Obligation:** MUST. **Scope:** top-level groups.

Use one blank line between independent declarations. Keep a declaration docstring, attributes and declaration
adjacent. Keep a structure's fields or inductive constructors in a contiguous group unless a documented subsection
warrants separation. Do not pad with multiple blank lines.

**Rationale:** Attachment determines which declaration a reader associates with a contract.

**Conforming contextual fragment:**

```lean
/-- Adding no bytes preserves usage. -/
@[simp] theorem used_add_zero (used : Nat) : used + 0 = used := by
  simp

def zeroUsage : Nat := 0
```

**Nonconforming fragment (do not copy):**

```lean
/-- Adding no bytes preserves usage. -/

@[simp]

theorem used_add_zero (used : Nat) : used + 0 = used := by simp
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-blank-003"></a>

### LSTYLE-BLANK-003: Proof phases and branches

**Class:** local engineering control. **Obligation:** MUST. **Scope:** tactic blocks.

Use one blank line between substantial proof phases. Keep a have declaration adjacent to its proof and keep each case
marker adjacent to its branch. Do not insert blank lines after by or between every tactic.

**Rationale:** Proof structure should follow the argument rather than a fixed spacing after each command.

**Conforming contextual fragment:**

```lean
theorem bounded (n : Nat) : n ≤ n + 1 := by
  have hStep : n ≤ n + 1 := Nat.le_succ n

  exact hStep
```

**Nonconforming fragment (do not copy):**

```lean
theorem bounded (n : Nat) : n ≤ n + 1 := by

  have hStep : n ≤ n + 1 := Nat.le_succ n


  exact hStep
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-blank-004"></a>

### LSTYLE-BLANK-004: Sections, endings and EOF

**Class:** local engineering control. **Obligation:** MUST. **Scope:** namespace and section boundaries.

Use one blank line before closing a namespace or named section and before the terminal -- EOF marker. Retain a final
newline and a blank line after the marker. Do not indent end merely because it closes a namespace.

**Rationale:** A visible closing scope helps review local notation and instance lifetime.

**Conforming contextual fragment:**

```lean
namespace Demo

def capacity : Nat := 8

end Demo

-- EOF
```

**Nonconforming fragment (do not copy):**

```lean
namespace Demo
def capacity : Nat := 8
  end Demo
-- EOF
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-format-004"></a>

### LSTYLE-FORMAT-004: Operators, binders and delimiters

**Class:** local engineering control. **Obligation:** MUST. **Scope:** terms and types.

Use spaces around :, :=, arrows and infix operators. Put separators before a line break rather than at the beginning
of the continuation. Do not pad names to align colons. Keep parentheses attached to their terms.

**Rationale:** Uniform token spacing exposes binders and relations.

**Conforming contextual fragment:**

```lean
def addBytes (used requested : Nat) : Nat := used + requested
```

**Nonconforming fragment (do not copy):**

```lean
def addBytes(used requested:Nat):Nat:=used+requested
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-format-005"></a>

### LSTYLE-FORMAT-005: Unicode and lexical clarity

**Class:** local engineering control. **Obligation:** MUST. **Scope:** mathematical source.

Use conventional Lean Unicode such as →, ≤, ∀ and α where it improves mathematical reading. Use ordinary ASCII domain
identifiers and avoid confusable characters or hidden direction controls. Keep the same symbol convention within a
file; do not imitate Haskell's ASCII-only syntax rule.

**Rationale:** Mathematical notation is part of Lean's established library vocabulary.

**Conforming contextual fragment:**

```lean
def Fits (used capacity : Nat) : Prop := used ≤ capacity
```

**Nonconforming fragment (do not copy):**

<!-- cspell:disable -->

```lean
def Fіts (used capacity : Nat) : Prop := used ≤ capacity
-- The apparent i in Fіts is a different Unicode character.
```

<!-- cspell:enable -->

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-format-006"></a>

### LSTYLE-FORMAT-006: Term applications and lambdas

**Class:** local engineering control. **Obligation:** MUST. **Scope:** expression layout.

Break long applications at argument boundaries with two-space continuation. Use fun with named binders for a short
abstraction. Keep closing delimiters with their arguments; avoid decorative alignment.

**Rationale:** A reader should see application grouping without counting spaces.

**Conforming contextual fragment:**

```lean
def addOneToAll (values : List Nat) : List Nat :=
  values.map (fun value => value + 1)
```

**Nonconforming fragment (do not copy):**

```lean
def addOneToAll (values : List Nat) : List Nat :=
  values.map (fun value =>
                value + 1
             )
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-format-007"></a>

### LSTYLE-FORMAT-007: Structures and inductive declarations

**Class:** local engineering control. **Obligation:** MUST. **Scope:** data definitions.

Place where at the declaration end and fields on two-space-indented lines. Put each nontrivial constructor on its own
line with |. Use named fields for domain records and preserve their documented order.

**Rationale:** Data and invariant fields should be easy to compare with construction sites.

**Conforming contextual fragment:**

```lean
inductive ReserveError where
  | invalidCursor
  | capacityExceeded
  deriving Repr, DecidableEq
```

**Nonconforming fragment (do not copy):**

```lean
inductive ReserveError where | invalidCursor | capacityExceeded deriving Repr, DecidableEq
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-format-008"></a>

### LSTYLE-FORMAT-008: Comments and documentation delimiters

**Class:** local engineering control. **Obligation:** MUST. **Scope:** source prose.

Use /-! for module documentation, /-- for declaration documentation and -- for local explanation. Keep a space after
-- and explain the mathematical or implementation reason, not the tactic spelling. Use backticks for identifiers
inside docstrings.
Every theorem comment must also carry the mathematical statement required by [LSTYLE-MATH-001](#lstyle-math-001).

**Rationale:** Hover documentation depends on attaching the right comment kind.

**Conforming contextual fragment:**

```lean
/-- Remaining bytes after reserving `used` bytes. -/
def remainingBytes (capacity used : Nat) : Nat := capacity - used
```

**Nonconforming fragment (do not copy):**

```lean
--remainingBytes
def remainingBytes (capacity used : Nat) : Nat := capacity - used
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-syntax-001"></a>

### LSTYLE-SYNTAX-001: Tactic blocks and by placement

**Class:** local engineering control. **Obligation:** MUST. **Scope:** proof declarations.

Put := by at the end of the declaration, then one meaningful tactic per line. A short closing proof may fit on the
declaration line. Do not put by alone on a separate line or use long semicolon chains.

**Rationale:** Each tactic should correspond to an inspectable step.

**Conforming contextual fragment:**

```lean
theorem add_zero (n : Nat) : n + 0 = n := by
  simp
```

**Nonconforming fragment (do not copy):**

```lean
theorem add_zero (n : Nat) : n + 0 = n :=
  by
    simp
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-syntax-002"></a>

### LSTYLE-SYNTAX-002: Focused goals and named cases

**Class:** local engineering control. **Obligation:** MUST. **Scope:** branching proofs.

Use · for sibling goals or case with a meaningful case name. Indent the branch body two spaces beyond the focus level.
Name constructor fields and induction hypotheses when later steps use them.

**Rationale:** Positional tactic scripts are brittle when a theorem introduces another goal.

**Conforming contextual fragment:**

```lean
theorem and_swap (p q : Prop) (h : p ∧ q) : q ∧ p := by
  constructor
  · exact h.2
  · exact h.1
```

**Nonconforming fragment (do not copy):**

```lean
theorem and_swap (p q : Prop) (h : p ∧ q) : q ∧ p := by
  constructor; exact h.2; exact h.1
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-syntax-003"></a>

### LSTYLE-SYNTAX-003: Calculation chains

**Class:** local engineering control. **Obligation:** MUST. **Scope:** equational and inequality proofs.

Place `calc` before an indented chain. Use _ for the preceding right-hand side and give a justification for each
relation. Avoid a chain that silently changes numeric domains through inferred coercions.

**Rationale:** Each line should expose one relation and its evidence.

**Conforming contextual fragment:**

```lean
theorem add_swap (a b : Nat) : a + b + 0 = b + a := by
  calc
    a + b + 0 = a + b := Nat.add_zero _
    _ = b + a := Nat.add_comm a b
```

**Nonconforming fragment (do not copy):**

```lean
theorem add_swap (a b : Nat) : a + b + 0 = b + a := by
  simp; omega
-- The second tactic has no remaining goal.
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-syntax-004"></a>

### LSTYLE-SYNTAX-004: Have, let and show

**Class:** local engineering control. **Obligation:** MUST. **Scope:** intermediate terms.

Use have for an intermediate proposition, let for local data and show or change to expose a target when that clarifies
the next step. State the type of a semantically important intermediate result.

**Rationale:** Naming intermediate facts reveals which contract is being applied.

**Conforming contextual fragment:**

```lean
have hNonnegative : 0 ≤ used := Nat.zero_le used
let nextUsed : Nat := used + requested
```

**Nonconforming fragment (do not copy):**

```lean
have := Nat.zero_le used
let x := used + requested
-- Anonymous facts and opaque names conceal the intended roles.
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-syntax-005"></a>

### LSTYLE-SYNTAX-005: Rewriting and equality direction

**Class:** local engineering control. **Obligation:** MUST. **Scope:** proof transformations.

Choose `rw` for targeted rewrites and simp for normalization. Name the intended rewrite direction, especially when
reversing an equation. Prefer an API lemma to unfolding a large representation.

**Rationale:** A proof should not depend on incidental definitional reduction throughout the implementation.

**Conforming contextual fragment:**

```lean
rw [Nat.add_comm used requested]
```

**Nonconforming fragment (do not copy):**

```lean
unfold reserve parseInput normalizeState emitCertificate at *
-- Broad unfolding exposes unrelated implementation details.
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-syntax-006"></a>

### LSTYLE-SYNTAX-006: Simp lemmas and normal forms

**Class:** local engineering control. **Obligation:** MUST. **Scope:** library automation.

Orient simplification toward a chosen normal form and avoid adding both directions of an equality as global simp
rules. Use local attributes for local proof needs. Give an explanation for a new global rule.

**Rationale:** Global simplification changes affect imported proofs and elaboration cost.

**Conforming contextual fragment:**

```lean
@[simp] theorem zero_usage : (0 : Nat) + 0 = 0 := by simp
```

**Nonconforming fragment (do not copy):**

```lean
attribute [simp] Nat.add_comm
-- A global commutativity rule is not a local proof fix.
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-syntax-007"></a>

### LSTYLE-SYNTAX-007: Pattern matching and conditionals

**Class:** local engineering control. **Obligation:** MUST. **Scope:** executable definitions.

Use one nontrivial match alternative per line. Bind a decision proof with if h : condition when the branch needs that
evidence. Cover all constructors and represent domain rejection through Option or Except.

**Rationale:** A total function can still return an unintended default for an invalid operation.

**Conforming contextual fragment:**

```lean
def first? (values : List Nat) : Option Nat :=
  match values with
  | [] => none
  | value :: _ => some value
```

**Nonconforming fragment (do not copy):**

```lean
def first (values : List Nat) : Nat := values.head!
-- A panic/default path is not a domain-level absence result.
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-syntax-008"></a>

### LSTYLE-SYNTAX-008: Explicit, implicit and instance arguments

**Class:** local engineering control. **Obligation:** MUST. **Scope:** binders.

Use explicit arguments for values a caller must choose, implicit braces for inferable parameters and instance brackets
for typeclass obligations. Do not hide a domain precondition in an instance solely to make calls shorter. Review
elaborated parameters after changing section variables.

**Rationale:** Binder choices change API inference and can obscure assumptions.

**Conforming contextual fragment:**

```lean
def preserve {α : Type} (value : α) : α := value
```

**Nonconforming fragment (do not copy):**

```lean
def preserve {α : Type} {value : α} : α := value
-- The caller's actual value is unnecessarily hidden.
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-syntax-009"></a>

### LSTYLE-SYNTAX-009: Scoped notation and open commands

**Class:** local engineering control. **Obligation:** MUST. **Scope:** namespace use.

Keep open and open scoped as narrow as practical. Prefer fully qualified names at semantic boundaries or when names
could collide. Close local notation and instance sections before unrelated declarations.

**Rationale:** An added import or open command can change elaboration without changing theorem text.

**Conforming contextual fragment:**

```lean
theorem zero_add_value (n : Nat) : 0 + n = n := Nat.zero_add n
```

**Nonconforming fragment (do not copy):**

```lean
open NamespaceA NamespaceB NamespaceC
-- Unrelated namespaces obscure which zero_add theorem is intended.
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-syntax-010"></a>

### LSTYLE-SYNTAX-010: Instances and coercions

**Class:** local engineering control. **Obligation:** MUST. **Scope:** elaboration environment.

Give new instances and coercions a domain reason and review ambiguity, search loops and priority. Prefer explicit
conversion at arithmetic or representation boundaries. Keep temporary instances local.

**Rationale:** Elaboration can select a valid theorem about a different inferred structure.

**Conforming contextual fragment:**

```lean
def asInteger (count : Nat) : Int := Int.ofNat count
```

**Nonconforming fragment (do not copy):**

```lean
-- Adding a global coercion merely to make an ambiguous theorem elaborate
-- hides the arithmetic-domain decision from its statement.
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-syntax-011"></a>

### LSTYLE-SYNTAX-011: Termination and decreasing measures

**Class:** local engineering control. **Obligation:** MUST. **Scope:** recursive definitions.

Use `termination_by` and `decreasing_by` when the measure is not structurally evident, with a comment connecting the
measure to the algorithm. Do not replace failed termination evidence by partial in a definition intended for logical
reduction.

**Rationale:** Fuel and mathematical progress express different guarantees.

**Conforming contextual fragment:**

```lean
def steps : Nat → Nat
  | 0 => 0
  | n + 1 => steps n + 1
```

**Nonconforming fragment (do not copy):**

```lean
partial def steps (n : Nat) : Nat := steps n
-- Compilable partial code is not a terminating model definition.
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-syntax-012"></a>

### LSTYLE-SYNTAX-012: Classical and noncomputable code

**Class:** local engineering control. **Obligation:** MUST. **Scope:** proof and runtime boundaries.

Use classical within the proof that needs it. Mark definitions noncomputable when they depend on nonconstructive
choice and keep them out of an executable API unless a separate implementation relation is established. Do not treat
Classical.choice as an automatic policy violation.

**Rationale:** The accepted logical axiom set differs from executable-code availability.

**Conforming contextual fragment:**

```lean
theorem excluded_middle (p : Prop) : p ∨ ¬ p := by
  classical
  exact Classical.em p
```

**Nonconforming fragment (do not copy):**

```lean
-- Treating a noncomputable chosen witness as directly executable
-- omits the required implementation and correspondence argument.
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-syntax-013"></a>

### LSTYLE-SYNTAX-013: Tactic search and options

**Class:** local engineering control. **Obligation:** MUST. **Scope:** proof maintenance.

Use tactic search to discover a proof, then retain a stable readable result when search is expensive or sensitive to
imports. Scope `maxHeartbeats` changes to the declaration with an explanation and measurement. Do not disable warnings
or linters to accept a proof.

**Rationale:** Unbounded search and hidden warning suppression weaken maintenance feedback.

**Conforming contextual fragment:**

```lean
theorem le_refl_value (n : Nat) : n ≤ n := Nat.le_refl n
```

**Nonconforming fragment (do not copy):**

```lean
set_option maxHeartbeats 0
set_option warningAsError false
-- Global suppression conceals regressions.
```

**Verification and limits:** Review the declaration and its elaborated uses; build with the pinned Lean. The local
lexical checker does not enforce this entire convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="lstyle-perf-001"></a>

### LSTYLE-PERF-001: Elaboration and replay costs

**Class:** local engineering control. **Obligation:** MUST. **Scope:** performance changes.

Measure affected module build, elaboration and replay time separately. Record toolchain, inputs, cache state and
resource limits. Review changes to simp sets, instances, imports and transparency for downstream cost.

**Rationale:** A warm editor response is not a reproducible compilation measurement.

**Conforming contextual fragment:**

```lean
-- Record cold/warm build conditions alongside this scoped diagnostic.
set_option profiler true in
theorem zero_refl : (0 : Nat) = 0 := rfl
```

**Nonconforming fragment (do not copy):**

```lean
-- Timing only a cached build does not measure the changed proof search.
```

**Verification and limits:** Retain timings and logs for the declared roots. Profiling does not establish asymptotic
bounds or real-time guarantees for a C implementation.

**Exception:** Use the rule-level review record defined in [governance](#governance).

<!-- EOF -->


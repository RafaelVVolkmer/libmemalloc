<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Common Lean Pitfalls

Use this catalogue to design regressions and review a concrete failure path. Each scenario links a prevention control,
a semantic source and an expected test observation. It adds no competing normative rules; the [code
standard](lean-code-standard.md#governance) defines obligations and exceptions.

<details>
<summary><strong>On this page</strong></summary>

- [Evidence and CWE interpretation](#evidence-model)
- [LEANPIT-001: An imported sorry escapes a text search](#leanpit-001)
- [LEANPIT-002: A custom axiom disguised as a helper](#leanpit-002)
- [LEANPIT-003: Assuming the conclusion](#leanpit-003)
- [LEANPIT-004: Vacuous truth from impossible entry states](#leanpit-004)
- [LEANPIT-005: Wrong quantifier order](#leanpit-005)
- [LEANPIT-006: An implicit parameter changes the theorem](#leanpit-006)
- [LEANPIT-007: Shadowed notation proves a different relation](#leanpit-007)
- [LEANPIT-008: Nat subtraction mistaken for signed subtraction](#leanpit-008)
- [LEANPIT-009: A Nat bound mistaken for machine no-wrap](#leanpit-009)
- [LEANPIT-010: Division by zero inherits the wrong semantics](#leanpit-010)
- [LEANPIT-011: Default-valued access hides invalid input](#leanpit-011)
- [LEANPIT-012: Partial runtime recursion treated as logical termination](#leanpit-012)
- [LEANPIT-013: Finite fuel mistaken for liveness](#leanpit-013)
- [LEANPIT-014: Native evaluation changes the trusted base](#leanpit-014)
- [LEANPIT-015: A printed true mistaken for a theorem](#leanpit-015)
- [LEANPIT-016: Unsafe or foreign execution mistaken for verified execution](#leanpit-016)
- [LEANPIT-017: A namespace filter misses a delivered theorem](#leanpit-017)
- [LEANPIT-018: An unimported file escapes the build](#leanpit-018)
- [LEANPIT-019: Baseline regeneration masks a semantic change](#leanpit-019)
- [LEANPIT-020: Intermediate simp depends on an unstable shape](#leanpit-020)
- [LEANPIT-021: Every terminal simp is expanded mechanically](#leanpit-021)
- [LEANPIT-022: Global instances or simp rules expand search](#leanpit-022)
- [LEANPIT-023: Noncomputable choice used as an executable algorithm](#leanpit-023)
- [LEANPIT-024: Abstract atomicity mistaken for C synchronization](#leanpit-024)
- [LEANPIT-025: Logical locations mistaken for live C pointers](#leanpit-025)
- [LEANPIT-026: Kernel startup failure counted as validation](#leanpit-026)
- [LEANPIT-027: Proof checked for the wrong imported program](#leanpit-027)
- [LEANPIT-028: Generated Lean text interpreted as commands](#leanpit-028)

</details>

---

<a id="evidence-model"></a>

## Evidence and CWE interpretation

Common Weakness Enumeration (CWE) links describe a mechanism only when the scenario meets its stated condition. These
are educational associations, not a finding that libmemalloc has a vulnerability or an assertion that MITRE classifies
proof mistakes. Broad entries such as CWE-20, CWE-400, CWE-682 and CWE-703 are conceptual references; their mapping
guidance may discourage using them for a specific vulnerability when a more precise cause is known.

The catalog consulted MITRE entry descriptions and mapping notes on 2026-10-15 (displayed release 4.20). Record the
actual exploit path and select an allowed specific entry before filing a vulnerability. A broken proof style, a
missing lemma or a weak claim is not automatically a security weakness.

Fragments are contextual and may require imports and surrounding declarations. Failure examples are deliberately
nonconforming. Regression descriptions specify tests to design; they do not claim that the current test suite
implements every scenario. Keep expected rejection separate from missing tools, parser failures and unrelated
infrastructure errors.

---

<a id="leanpit-001"></a>

## LEANPIT-001: An imported sorry escapes a text search

**Failure scenario:** The public theorem has no sorry token but depends on an incomplete helper.

**Nonconforming fragment:**

```lean
-- In an imported module:
theorem unfinished : False := by sorry
-- Public theorem:
theorem publicResult : False := unfinished
```

**Prevention fragment:**

```lean
#print axioms publicResult
-- Require transitive rejection of sorryAx.
```

**Control:** [LSTYLE-PROOF-001](lean-code-standard.md#lstyle-proof-001).

**Regression and expected observation:** Build the two-module negative fixture and require the audit to identify
`sorryAx`, not a parse error.

**CWE applicability:** No direct CWE mapping. The proof, style or evidence defect requires review; classify a concrete
downstream
vulnerability separately.

**Semantic reference:** [adopted manual or style
section](https://lean-lang.org/doc/reference/4.35.0/ValidatingProofs/); revisions and precedence appear in the [source
register](lean-code-standard.md#sources).

---

<a id="leanpit-002"></a>

## LEANPIT-002: A custom axiom disguised as a helper

**Failure scenario:** A claimed result relies on a user assertion instead of an admitted premise or a proof.

**Nonconforming fragment:**

```lean
axiom backendCorrect : False
theorem result : False := backendCorrect
```

**Prevention fragment:**

```lean
-- Prove the property, or expose the unproved environment condition as a premise
-- and narrow the claim to that conditional result.
```

**Control:** [LSTYLE-TRUST-001](lean-code-standard.md#lstyle-trust-001).

**Regression and expected observation:** Introduce a helper axiom outside the public namespace and require transitive
rejection.

**CWE applicability:** No direct CWE mapping. The proof, style or evidence defect requires review; classify a concrete
downstream
vulnerability separately.

**Semantic reference:** [adopted manual or style
section](https://lean-lang.org/doc/reference/4.35.0/ValidatingProofs/); revisions and precedence appear in the [source
register](lean-code-standard.md#sources).

---

<a id="leanpit-003"></a>

## LEANPIT-003: Assuming the conclusion

**Failure scenario:** A theorem states the intended postcondition as a premise, then its documentation claims
implementation correctness.

**Nonconforming fragment:**

```lean
theorem verified (postcondition : Prop) (h : postcondition) : postcondition := h
```

**Prevention fragment:**

```lean
-- Derive the postcondition from the operation definition and admitted entry conditions.
```

**Control:** [LSTYLE-SPEC-001](lean-code-standard.md#lstyle-spec-001).

**Regression and expected observation:** Compare premises to the original contract and reject circular justification.

**CWE applicability:** No direct CWE mapping. The proof, style or evidence defect requires review; classify a concrete
downstream
vulnerability separately.

**Semantic reference:** [adopted manual or style
section](https://lean-lang.org/doc/reference/4.35.0/ValidatingProofs/); revisions and precedence appear in the [source
register](lean-code-standard.md#sources).

---

<a id="leanpit-004"></a>

## LEANPIT-004: Vacuous truth from impossible entry states

**Failure scenario:** Contradictory assumptions make any conclusion derivable.

**Nonconforming fragment:**

```lean
theorem anything (n : Nat) (h : n < 0) : False := by omega
```

**Prevention fragment:**

```lean
-- Exhibit valid entry states and review the consistency of their invariants.
example : (0 : Nat) ≤ 8 := by decide
```

**Control:** [LSTYLE-SPEC-001](lean-code-standard.md#lstyle-spec-001).

**Regression and expected observation:** Construct witnesses at zero and boundary values; flag a domain with no
admitted execution.

**CWE applicability:** No direct CWE mapping. The proof, style or evidence defect requires review; classify a concrete
downstream
vulnerability separately.

**Semantic reference:** [adopted manual or style
section](https://lean-lang.org/doc/reference/4.35.0/ValidatingProofs/); revisions and precedence appear in the [source
register](lean-code-standard.md#sources).

---

<a id="leanpit-005"></a>

## LEANPIT-005: Wrong quantifier order

**Failure scenario:** A theorem chooses one convenient state or output where the requirement quantifies over every
admitted input.

**Nonconforming fragment:**

```lean
-- Claim uses ∃ state, Safe state where the requirement needs ∀ state, Admitted state → Safe state.
```

**Prevention fragment:**

```lean
-- State the admitted domain and quantify each input before its permitted output choice.
```

**Control:** [LSTYLE-SPEC-001](lean-code-standard.md#lstyle-spec-001).

**Regression and expected observation:** Instantiate the intended statement with distinct inputs and review which
witness may depend on which input.

**CWE applicability:** No direct CWE mapping. The proof, style or evidence defect requires review; classify a concrete
downstream
vulnerability separately.

**Semantic reference:** [adopted manual or style
section](https://lean-lang.org/doc/reference/4.35.0/ValidatingProofs/); revisions and precedence appear in the [source
register](lean-code-standard.md#sources).

---

<a id="leanpit-006"></a>

## LEANPIT-006: An implicit parameter changes the theorem

**Failure scenario:** A misspelled name becomes a new parameter under automatic implicit generalization.

**Nonconforming fragment:**

```lean
set_option autoImplicit true
-- A misspelled identifier can become an unintended binder.
```

**Prevention fragment:**

```lean
set_option autoImplicit false
-- Declare all domain parameters and inspect the elaborated type.
```

**Control:** [LSTYLE-API-001](lean-code-standard.md#lstyle-api-001).

**Regression and expected observation:** Misspell a binder in an isolated fixture and require elaboration failure
under the project profile.

**CWE applicability:** No direct CWE mapping. The proof, style or evidence defect requires review; classify a concrete
downstream
vulnerability separately.

**Semantic reference:** [adopted manual or style
section](https://lean-lang.org/doc/reference/4.35.0/ValidatingProofs/); revisions and precedence appear in the [source
register](lean-code-standard.md#sources).

---

<a id="leanpit-007"></a>

## LEANPIT-007: Shadowed notation proves a different relation

**Failure scenario:** An import or local notation changes the meaning of a familiar operator.

**Nonconforming fragment:**

```lean
local infix:50 " ≤ " => Nat.lt
```

**Prevention fragment:**

```lean
-- Use the intended qualified relation when reviewing the statement.
#check Nat.le
```

**Control:** [LSTYLE-NAME-014](lean-code-standard.md#lstyle-name-014).

**Regression and expected observation:** Inspect elaborated constants and run distinguishing boundary examples such as
equality.

**CWE applicability:** No direct CWE mapping. The proof, style or evidence defect requires review; classify a concrete
downstream
vulnerability separately.

**Semantic reference:** [adopted manual or style
section](https://lean-lang.org/doc/reference/4.35.0/ValidatingProofs/); revisions and precedence appear in the [source
register](lean-code-standard.md#sources).

---

<a id="leanpit-008"></a>

## LEANPIT-008: Nat subtraction mistaken for signed subtraction

**Failure scenario:** An arithmetic argument uses truncating natural subtraction where negative or unsigned-wrap
behavior matters.

**Nonconforming fragment:**

```lean
example : (3 : Nat) - 5 = 0 := by decide
```

**Prevention fragment:**

```lean
-- Require requested ≤ capacity before using remaining capacity as a representation.
example (requested capacity : Nat) (h : requested ≤ capacity) :
    requested + (capacity - requested) = capacity := by omega
```

**Control:** [LSTYLE-NUM-001](lean-code-standard.md#lstyle-num-001).

**Regression and expected observation:** Compare requested=capacity and requested=capacity+1 in each concrete
representation.

**CWE applicability:** [CWE-191](https://cwe.mitre.org/data/definitions/191.html): only at a bounded concrete
subtraction that underflows; [CWE-682](https://cwe.mitre.org/data/definitions/682.html): conceptual arithmetic
mismatch, not a Lean runtime underflow.

**Semantic reference:** [adopted manual or style
section](https://lean-lang.org/doc/reference/4.35.0/Basic-Types/Natural-Numbers/); revisions and precedence appear in
the [source register](lean-code-standard.md#sources).

---

<a id="leanpit-009"></a>

## LEANPIT-009: A Nat bound mistaken for machine no-wrap

**Failure scenario:** A theorem about unbounded naturals is applied to a fixed-width addition without a range
relation.

**Nonconforming fragment:**

```lean
-- A + B is a Nat; the implementation uses a fixed-width unsigned word.
```

**Prevention fragment:**

```lean
-- Prove sum ≤ target maximum and relate conversion before claiming no wrap.
```

**Control:** [LSTYLE-NUM-001](lean-code-standard.md#lstyle-num-001).

**Regression and expected observation:** Check the exact width maximum, conversion and overflow case in the
C/Haskell/Lean relation.

**CWE applicability:** [CWE-190](https://cwe.mitre.org/data/definitions/190.html): conditional concrete overflow;
`Nat`
itself does not wrap.

**Semantic reference:** [adopted manual or style
section](https://lean-lang.org/doc/reference/4.35.0/Basic-Types/Bitvectors/); revisions and precedence appear in the
[source register](lean-code-standard.md#sources).

---

<a id="leanpit-010"></a>

## LEANPIT-010: Division by zero inherits the wrong semantics

**Failure scenario:** A total mathematical operation supplies a result at zero that does not describe C division.

**Nonconforming fragment:**

```lean
example : (7 : Nat) / 0 = 0 := by decide
```

**Prevention fragment:**

```lean
-- Require divisor ≠ 0 in the concrete-operation correspondence contract.
```

**Control:** [LSTYLE-NUM-001](lean-code-standard.md#lstyle-num-001).

**Regression and expected observation:** Test zero explicitly and require the C/engine precondition rather than
reusing the mathematical result.

**CWE applicability:** [CWE-369](https://cwe.mitre.org/data/definitions/369.html): only for the concrete
division-by-zero operation; the Lean equation is defined.

**Semantic reference:** [adopted manual or style
section](https://lean-lang.org/doc/reference/4.35.0/Basic-Types/Natural-Numbers/); revisions and precedence appear in
the [source register](lean-code-standard.md#sources).

---

<a id="leanpit-011"></a>

## LEANPIT-011: Default-valued access hides invalid input

**Failure scenario:** A panic/default accessor produces an unintended runtime path instead of an explicit model
rejection.

**Nonconforming fragment:**

```lean
def first (xs : List Nat) : Nat := xs.head!
```

**Prevention fragment:**

```lean
def first? (xs : List Nat) : Option Nat := xs.head?
```

**Control:** [LSTYLE-SYNTAX-007](lean-code-standard.md#lstyle-syntax-007).

**Regression and expected observation:** Execute empty and nonempty cases and require explicit absence or a proof of
the index bound.

**CWE applicability:** [CWE-20](https://cwe.mitre.org/data/definitions/20.html): conceptual input-domain gap; checked
Lean access is not automatically a C out-of-bounds read.

**Semantic reference:** [adopted manual or style
section](https://lean-lang.org/doc/reference/4.35.0/Basic-Types/Linked-Lists/); revisions and precedence appear in the
[source register](lean-code-standard.md#sources).

---

<a id="leanpit-012"></a>

## LEANPIT-012: Partial runtime recursion treated as logical termination

**Failure scenario:** A partial definition runs indefinitely while documentation cites Lean as a termination
guarantee.

**Nonconforming fragment:**

```lean
partial def spin (n : Nat) : Nat := spin n
```

**Prevention fragment:**

```lean
def countdown : Nat → Nat
  | 0 => 0
  | n + 1 => countdown n
```

**Control:** [LSTYLE-TERMINATION-001](lean-code-standard.md#lstyle-termination-001).

**Regression and expected observation:** Exercise a bounded replacement and review whether the theorem concerns fuel
or real progress.

**CWE applicability:** [CWE-835](https://cwe.mitre.org/data/definitions/835.html): conditional nonterminating runtime
computation.

**Semantic reference:** [adopted manual or style
section](https://lean-lang.org/doc/reference/4.35.0/Definitions/Recursive-Definitions/); revisions and precedence
appear in the [source register](lean-code-standard.md#sources).

---

<a id="leanpit-013"></a>

## LEANPIT-013: Finite fuel mistaken for liveness

**Failure scenario:** The model terminates by consuming fuel, but that does not establish eventual allocator progress.

**Nonconforming fragment:**

```lean
-- A run returns after fuel=100, therefore the scheduler is starvation-free.
```

**Prevention fragment:**

```lean
-- Return incomplete on fuel exhaustion and state fairness/progress assumptions separately.
```

**Control:** [LSTYLE-TERMINATION-001](lean-code-standard.md#lstyle-termination-001).

**Regression and expected observation:** Use a cycle that consumes all fuel without progress and check the result
label.

**CWE applicability:** No direct CWE mapping. The proof, style or evidence defect requires review; classify a concrete
downstream
vulnerability separately.

**Semantic reference:** [adopted manual or style
section](https://lean-lang.org/doc/reference/4.35.0/Definitions/Recursive-Definitions/); revisions and precedence
appear in the [source register](lean-code-standard.md#sources).

---

<a id="leanpit-014"></a>

## LEANPIT-014: Native evaluation changes the trusted base

**Failure scenario:** A proof uses compiled evaluation and introduces a dedicated native axiom rejected by the project
profile.

**Nonconforming fragment:**

```lean
example : (1 : Nat) + 1 = 2 := by native_decide
```

**Prevention fragment:**

```lean
example : (1 : Nat) + 1 = 2 := by decide
```

**Control:** [LSTYLE-NATIVE-001](lean-code-standard.md#lstyle-native-001).

**Regression and expected observation:** Audit the transitive native result with Lean 4.35; do not check only the old
Lean.trustCompiler name.

**CWE applicability:** No direct CWE mapping. The proof, style or evidence defect requires review; classify a concrete
downstream
vulnerability separately.

**Semantic reference:** [adopted manual or style
section](https://lean-lang.org/doc/reference/4.35.0/ValidatingProofs/); revisions and precedence appear in the [source
register](lean-code-standard.md#sources).

---

<a id="leanpit-015"></a>

## LEANPIT-015: A printed true mistaken for a theorem

**Failure scenario:** An executable checker produces true but no proof of the required proposition is delivered.

**Nonconforming fragment:**

```lean
#eval (1 : Nat) + 1 == 2
```

**Prevention fragment:**

```lean
theorem two_eq : (1 : Nat) + 1 = 2 := by decide
```

**Control:** [LSTYLE-RUNTIME-001](lean-code-standard.md#lstyle-runtime-001).

**Regression and expected observation:** Require the named theorem, actual axiom report and successful replay in
addition to runtime observations.

**CWE applicability:** No direct CWE mapping. The proof, style or evidence defect requires review; classify a concrete
downstream
vulnerability separately.

**Semantic reference:** [adopted manual or style
section](https://lean-lang.org/doc/reference/4.35.0/ValidatingProofs/); revisions and precedence appear in the [source
register](lean-code-standard.md#sources).

---

<a id="leanpit-016"></a>

## LEANPIT-016: Unsafe or foreign execution mistaken for verified execution

**Failure scenario:** A compiled foreign or unsafe implementation is assumed to behave like the logical definition.

**Nonconforming fragment:**

```lean
-- A runtime replacement is trusted merely because a theorem about the logical definition compiles.
```

**Prevention fragment:**

```lean
-- Record the replacement boundary and require an implementation relation or separate evidence.
```

**Control:** [LSTYLE-RUNTIME-001](lean-code-standard.md#lstyle-runtime-001).

**Regression and expected observation:** Change the runtime implementation while preserving the logical definition;
ensure the evidence labels separate them.

**CWE applicability:** No direct CWE mapping. The proof, style or evidence defect requires review; classify a concrete
downstream
vulnerability separately.

**Semantic reference:** [adopted manual or style section](https://lean-lang.org/doc/reference/4.35.0/Run-Time-Code/);
revisions and precedence appear in the [source register](lean-code-standard.md#sources).

---

<a id="leanpit-017"></a>

## LEANPIT-017: A namespace filter misses a delivered theorem

**Failure scenario:** A new declaration lives outside the audit namespace or expected generated-root list.

**Nonconforming fragment:**

```lean
namespace ExtraEvidence
-- A delivered theorem is placed here without updating the root audit.
end ExtraEvidence
```

**Prevention fragment:**

```lean
-- Retain the expected Allocator namespace or extend the reviewed explicit root inventory.
```

**Control:** [LSTYLE-PROOF-001](lean-code-standard.md#lstyle-proof-001).

**Regression and expected observation:** Add an isolated theorem outside the current filter and verify the inventory
review exposes the missing coverage.

**CWE applicability:** No direct CWE mapping. The proof, style or evidence defect requires review; classify a concrete
downstream
vulnerability separately.

**Semantic reference:** [adopted manual or style
section](https://lean-lang.org/doc/reference/4.35.0/ValidatingProofs/); revisions and precedence appear in the [source
register](lean-code-standard.md#sources).

---

<a id="leanpit-018"></a>

## LEANPIT-018: An unimported file escapes the build

**Failure scenario:** A new proof file is never reached from a library root and does not participate in the reported
run.

**Nonconforming fragment:**

```lean
-- NewProof.lean exists on disk but no root imports it.
```

**Prevention fragment:**

```lean
-- Connect it to the declared library root and inspect modules.tsv.
```

**Control:** [LSTYLE-REPLAY-001](lean-code-standard.md#lstyle-replay-001).

**Regression and expected observation:** Remove a required root import and require the local import-inventory check to
fail.

**CWE applicability:** No direct CWE mapping. The proof, style or evidence defect requires review; classify a concrete
downstream
vulnerability separately.

**Semantic reference:** [adopted manual or style
section](https://lean-lang.org/doc/reference/4.35.0/ValidatingProofs/); revisions and precedence appear in the [source
register](lean-code-standard.md#sources).

---

<a id="leanpit-019"></a>

## LEANPIT-019: Baseline regeneration masks a semantic change

**Failure scenario:** A theorem keeps its name while definitions or hypotheses change, and the author refreshes hashes
without review.

**Nonconforming fragment:**

```lean
-- Regenerate contracts and digests until the check passes.
```

**Prevention fragment:**

```lean
-- Review definitions, elaborated statements, mappings and assumptions before regeneration.
```

**Control:** [LSTYLE-SPEC-001](lean-code-standard.md#lstyle-spec-001).

**Regression and expected observation:** Mutate a definition while keeping the theorem type text; require the source
review to identify the changed meaning.

**CWE applicability:** No direct CWE mapping. The proof, style or evidence defect requires review; classify a concrete
downstream
vulnerability separately.

**Semantic reference:** [adopted manual or style
section](https://lean-lang.org/doc/reference/4.35.0/ValidatingProofs/); revisions and precedence appear in the [source
register](lean-code-standard.md#sources).

---

<a id="leanpit-020"></a>

## LEANPIT-020: Intermediate simp depends on an unstable shape

**Failure scenario:** A broad simplification changes the next goal after an import or simp-set update, breaking a
later positional tactic.

**Nonconforming fragment:**

```lean
simp at h
-- A later exact-shape tactic assumes the old normalized h.
```

**Prevention fragment:**

```lean
simp only [selectedLemma] at h
-- Use an explicit intermediate normalization when its shape matters.
```

**Control:** [LSTYLE-SIMP-001](lean-code-standard.md#lstyle-simp-001).

**Regression and expected observation:** Rebuild after changing relevant simp lemmas and inspect the intermediate
proposition.

**CWE applicability:** No direct CWE mapping. The proof, style or evidence defect requires review; classify a concrete
downstream
vulnerability separately.

**Semantic reference:** [adopted manual or style
section](https://leanprover-community.github.io/contribute/style.html); revisions and precedence appear in the [source
register](lean-code-standard.md#sources).

---

<a id="leanpit-021"></a>

## LEANPIT-021: Every terminal simp is expanded mechanically

**Failure scenario:** A closing simp is replaced by many incidental lemmas, making proof maintenance depend on their
names.

**Nonconforming fragment:**

```lean
-- Copy a long simp? output into every terminal call without a need.
```

**Prevention fragment:**

```lean
-- A short terminal simplification is permitted.
example (n : Nat) : n + 0 = n := by simp
```

**Control:** [LSTYLE-SIMP-001](lean-code-standard.md#lstyle-simp-001).

**Regression and expected observation:** Review the meaningful added lemmas and retain explicit lists only for
stability or measured performance reasons.

**CWE applicability:** No direct CWE mapping. The proof, style or evidence defect requires review; classify a concrete
downstream
vulnerability separately.

**Semantic reference:** [adopted manual or style
section](https://leanprover-community.github.io/contribute/style.html); revisions and precedence appear in the [source
register](lean-code-standard.md#sources).

---

<a id="leanpit-022"></a>

## LEANPIT-022: Global instances or simp rules expand search

**Failure scenario:** A local proof repair changes global normalization or instance search and causes failures or
costly builds elsewhere.

**Nonconforming fragment:**

```lean
attribute [simp] Nat.add_comm
```

**Prevention fragment:**

```lean
-- Use a targeted local rewrite instead.
rw [Nat.add_comm a b]
```

**Control:** [LSTYLE-TRANSPARENT-001](lean-code-standard.md#lstyle-transparent-001).

**Regression and expected observation:** Rebuild dependents and measure affected elaboration; check for loops or
unexpected instance selection.

**CWE applicability:** [CWE-400](https://cwe.mitre.org/data/definitions/400.html): conceptual resource issue only if
uncontrolled search exhausts build/runtime resources.

**Semantic reference:** [adopted manual or style
section](https://leanprover-community.github.io/contribute/style.html); revisions and precedence appear in the [source
register](lean-code-standard.md#sources).

---

<a id="leanpit-023"></a>

## LEANPIT-023: Noncomputable choice used as an executable algorithm

**Failure scenario:** A model selects a witness classically, then an adapter assumes it can execute that selection.

**Nonconforming fragment:**

```lean
-- A Classical.choose-based noncomputable witness is exposed as the runtime search implementation.
```

**Prevention fragment:**

```lean
-- Supply a computable implementation and prove it meets the existential specification.
```

**Control:** [LSTYLE-SYNTAX-012](lean-code-standard.md#lstyle-syntax-012).

**Regression and expected observation:** Compile the intended executable path and review its relation to the logical
witness.

**CWE applicability:** No direct CWE mapping. The proof, style or evidence defect requires review; classify a concrete
downstream
vulnerability separately.

**Semantic reference:** [adopted manual or style section](https://lean-lang.org/doc/reference/4.35.0/Axioms/);
revisions and precedence appear in the [source register](lean-code-standard.md#sources).

---

<a id="leanpit-024"></a>

## LEANPIT-024: Abstract atomicity mistaken for C synchronization

**Failure scenario:** The proof takes an indivisible state transition but the implementation performs unsynchronized
shared writes.

**Nonconforming fragment:**

```lean
-- Abstract Step transfers ownership atomically; no C memory-order relation is recorded.
```

**Prevention fragment:**

```lean
-- State linearization, lifetime and memory-order obligations for the concrete operation.
```

**Control:** [LSTYLE-SPEC-001](lean-code-standard.md#lstyle-spec-001).

**Regression and expected observation:** Compare the concrete interleavings to model steps and retain unsupported
concurrency obligations.

**CWE applicability:** [CWE-362](https://cwe.mitre.org/data/definitions/362.html): only when concrete shared state is
accessed without required synchronization.

**Semantic reference:** [adopted manual or style
section](https://lean-lang.org/doc/reference/4.35.0/ValidatingProofs/); revisions and precedence appear in the [source
register](lean-code-standard.md#sources).

---

<a id="leanpit-025"></a>

## LEANPIT-025: Logical locations mistaken for live C pointers

**Failure scenario:** A `Nat` location satisfies a range theorem but its C object is expired or not owned.

**Nonconforming fragment:**

```lean
-- address < capacity is used as the entire pointer-validity premise.
```

**Prevention fragment:**

```lean
-- Relate logical location to a live concrete object with extent, permission and provenance.
```

**Control:** [LSTYLE-SPEC-001](lean-code-standard.md#lstyle-spec-001).

**Regression and expected observation:** Include stale and wrong-object boundary cases in the implementation relation
and C regressions.

**CWE applicability:** [CWE-416](https://cwe.mitre.org/data/definitions/416.html): only when the concrete
implementation uses freed storage; [CWE-125](https://cwe.mitre.org/data/definitions/125.html): only for an actual
out-of-bounds read.

**Semantic reference:** [adopted manual or style
section](https://lean-lang.org/doc/reference/4.35.0/ValidatingProofs/); revisions and precedence appear in the [source
register](lean-code-standard.md#sources).

---

<a id="leanpit-026"></a>

## LEANPIT-026: Kernel startup failure counted as validation

**Failure scenario:** The environment cannot start isolated replay, but the build result is reported as completed
proof acceptance.

**Nonconforming fragment:**

```lean
-- bubblewrap fails; the report substitutes lake build success.
```

**Prevention fragment:**

```lean
-- Retain replay failure and resolve the execution prerequisite before acceptance.
```

**Control:** [LSTYLE-REPLAY-001](lean-code-standard.md#lstyle-replay-001).

**Regression and expected observation:** Disable the replay prerequisite in an isolated fixture and require an
incomplete acceptance result.

**CWE applicability:** No direct CWE mapping. The proof, style or evidence defect requires review; classify a concrete
downstream
vulnerability separately.

**Semantic reference:** [adopted manual or style
section](https://lean-lang.org/doc/reference/4.35.0/ValidatingProofs/); revisions and precedence appear in the [source
register](lean-code-standard.md#sources).

---

<a id="leanpit-027"></a>

## LEANPIT-027: Proof checked for the wrong imported program

**Failure scenario:** The certificate proves a safe program different from the actual C frontend output.

**Nonconforming fragment:**

```lean
-- Accept any theorem named accepted_program.
```

**Prevention fragment:**

```lean
-- Compare the elaborated program and postcondition with the expected input identities.
```

**Control:** [LSTYLE-SPEC-001](lean-code-standard.md#lstyle-spec-001).

**Regression and expected observation:** Substitute a different valid program and require expected-program binding to
reject it.

**CWE applicability:** [CWE-345](https://cwe.mitre.org/data/definitions/345.html): conceptual evidence
identity/integrity gap; the theorem itself may remain logically valid.

**Semantic reference:** [adopted manual or style
section](https://lean-lang.org/doc/reference/4.35.0/ValidatingProofs/); revisions and precedence appear in the [source
register](lean-code-standard.md#sources).

---

<a id="leanpit-028"></a>

## LEANPIT-028: Generated Lean text interpreted as commands

**Failure scenario:** A generator inserts an external identifier or literal without validation and creates unintended
Lean syntax.

**Nonconforming fragment:**

```lean
-- Splice an untrusted string directly after theorem or import.
```

**Prevention fragment:**

```lean
-- Validate identifiers and emit literals and declarations through a controlled syntax writer.
```

**Control:** [LSTYLE-RUNTIME-001](lean-code-standard.md#lstyle-runtime-001).

**Regression and expected observation:** Inject line breaks, command delimiters and notation; require rejection before
invoking Lean.

**CWE applicability:** [CWE-95](https://cwe.mitre.org/data/definitions/95.html): only when attacker-controlled data
becomes executable generated code.

**Semantic reference:** [adopted manual or style
section](https://lean-lang.org/doc/reference/4.35.0/ValidatingProofs/); revisions and precedence appear in the [source
register](lean-code-standard.md#sources).

<!-- EOF -->


<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# C–Haskell–Lean Integration Standard

Use this standard when a result crosses the implementation, state-engine and proof boundaries. Read the
[C formal standard](c/test/c-tests-formal.md), [Haskell guides](haskell/README.md) and [Lean guides](lean/README.md)
for their language-specific controls. The existing [operation map](../../docs/reference/formal-engine.md),
[mock contract](../../verification/contracts/mock.json) and
[trust model](../../docs/assurance/formal-trust.md) remain the concrete sources of correspondence claims.

<details>
<summary><strong>On this page</strong></summary>

- [Current scope](#current-scope)
- [Integration controls](#integration-controls)
- [Evidence boundaries](#evidence-boundaries)

</details>

---

## Current scope

The implemented pilot analyzes the C mock using actual C frontend output. Haskell imports
the supported representation and constructs evidence. Lean checks a result about the expected scalar program.
The frontend, preprocessing, adapter and concrete representation remain trusted. The pipeline does not prove
source-to-IR preservation or binary correctness, and does not verify a complete allocator. CN serves as a
frontend here; no CN body-verification claim follows from importing its output.

All controls below are `MUST` for an integration claim. Each control's examples are evidence fragments, not
new executable commands. Exceptions require a scoped engineering decision with ID, owner, reason, alternate
evidence, reviewer and expiry. An exception must narrow or rename an unsupported claim; it cannot label missing
evidence as proof.

---

## Integration controls

<a id="xlang-001"></a>

### XLANG-001: Bind the operation at every boundary

**Scope and requirement:** Identify requirement ID, exact C source/symbol/revision, preprocessing inputs,
imported operation, Haskell analysis entry and Lean definition/theorem root. Preserve those identities in artifacts.

**Rationale and examples:** Conforming: a binding record connects `LMA_cursorReserve` to its actual imported
body and expected Lean program. Nonconforming: match names while verifying an independently copied C function.

**Verification and limits:** Compare actual input digests, symbols and generated theorem statements. A hash
binds bytes; it does not prove semantic preservation through preprocessing or parsing.

<a id="xlang-002"></a>

### XLANG-002: Define the state representation relation

**Scope and requirement:** State how C objects and fields correspond to Haskell values and Lean states.
Record widths, signedness, byte units, alignment, initialization, nullability, ownership and permitted aliasing.
Explain which concrete states lie outside the model.

**Rationale and examples:** Conforming: an entry relation requires valid, exclusively owned cursor storage
and bounded fields. Nonconforming: treat a `Nat` address as evidence of valid C pointer provenance.

| Concept | C boundary | Haskell boundary | Lean boundary |
| --- | --- | --- | --- |
| Count | Target width and range | Validated `Integer` or checked conversion | `Nat`/bounded representation with a relation |
| Addition | No undefined signed overflow; explicit unsigned semantics | Mathematical or declared machine arithmetic | Bound/no-wrap lemma for the chosen domain |
| Subtraction | Signed/unsigned rules | Explicit admitted operands | `Nat` truncation requires an operand-bound premise |
| Division | Nonzero divisor and representable result | Explicit signed quotient/remainder convention | Mathematical operator with matching domain assumptions |
| Pointer | Provenance, object lifetime, alignment and permission | Foreign handle or serialized identity | Logical location plus an explicit representation obligation |
| Failure | Outputs and permitted partial effects | Typed rejection plus observed effects | Postcondition for the corresponding failure transition |

**Verification and limits:** Prove domain lemmas and test concrete boundary values; review object assumptions.
Pure mathematical memory models do not establish C effective type, aliasing or compiled memory ordering.

<a id="xlang-003"></a>

### XLANG-003: Relate both successful and failed transitions

**Scope and requirement:** For each admitted operation, relate the initial states, operation parameters,
observable result, final state and unchanged storage. Include rejected inputs, partial effects and unsupported
behavior.

**Rationale and examples:** Conforming: failure preserves cursor/output state according to the actual C contract.
Nonconforming: compare only successful return values while ignoring a write on the rejected path.

**Verification and limits:** Use frame conditions, branch coverage, differential traces and required program
proofs. The current scalar pilot has no general allocation/free lifecycle verification. Abstract atomic steps
also require a separate relation to concrete synchronization and memory-order behavior.

<a id="xlang-004"></a>

### XLANG-004: Validate artifacts and reject incomplete evidence

**Scope and requirement:** Bind schema, producer/tool versions, source identity, model identity, bounds and
required theorem roots. Check complete parses, expected outputs and acceptance statuses. Reject stale artifacts,
missing stages, unsupported constructs, timeouts and altered certificates.

**Rationale and examples:** Conforming: a modified input invalidates the previous campaign receipt.
Nonconforming: reuse a successful certificate after changing the preprocessor definitions or finite-state bound.

**Verification and limits:** Mutate each binding independently and require an intended failure. Authenticity
and completeness checks do not establish the semantic correctness of a trusted frontend.

<a id="xlang-005"></a>

### XLANG-005: Keep the evidence chain within its proved scope

**Scope and requirement:** Record C observations, Haskell tests/refinements, exploration closure, Lean statement
review, axiom audit and kernel replay separately. Require the evidence selected by the claim's profile and
record remaining trusted components and open obligations.

**Rationale and examples:** Conforming: claim a kernel-checked scalar IR result under the stated `lean-ir`
profile. Nonconforming: call the full allocator memory-safe because independent component checks passed.

**Verification and limits:** Review the complete binding and evidence chain against the trust model. No
combination of unconnected green tool statuses supplies a missing refinement theorem.

---

## Evidence boundaries

The semantic references are the [Haskell Report](https://www.haskell.org/onlinereport/haskell2010/haskellch6.html),
[GHC 9.4.7 FFI manual](https://downloads.haskell.org/ghc/9.4.7/docs/users_guide/exts/ffi.html) when direct calls
exist,
and [Lean 4.35.0 proof validation](https://lean-lang.org/doc/reference/4.35.0/ValidatingProofs/). Concrete C
claims also require the target and language model defined by the C standards. The local integration controls
add the representation and evidence obligations; the upstream manuals do not certify this pipeline.

<!-- EOF -->


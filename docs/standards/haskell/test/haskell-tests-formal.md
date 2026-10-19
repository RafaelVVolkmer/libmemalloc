<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Haskell Testing and Formal Evidence

Use tests to challenge the engine's contracts, and use the declared proof tools for the properties they
actually establish. The [code standard's governance](../haskell-code-standard.md#governance) applies to all controls.

<details>
<summary><strong>On this page</strong></summary>

- [Test and exploration controls](#test-and-exploration-controls)
- [Evidence examples](#evidence-examples)
- [Sources and current coverage](#sources-and-current-coverage)

</details>

---

## Test and exploration controls

<a id="htest-001"></a>

### HTEST-001: Derive properties from the operation contract

**MUST · changed transitions.** Test success, rejection and frame properties. Include zero, exact capacity,
one beyond capacity and invalid input. Use an independently expressed oracle for differential tests.

**Reason and examples:** Conforming: a successful reservation preserves capacity and increments usage by
the requested amount; a rejected reservation publishes no changed state. Nonconforming: call the same
implementation twice and compare the results as an independent oracle.

**Verification and limit:** Retain inputs and failures; review generator coverage. Passing examples or random
samples do not prove a quantified property. Exceptions follow [HCOMP-003](../haskell-compliance.md#hcomp-003).

<a id="htest-002"></a>

### HTEST-002: Preserve legal traces during generation and shrinking

**MUST · state-machine property tests when adopted.** Define command preconditions, model update, observable
postconditions and cleanup. Generate legal traces and separate malformed-input tests. Ensure shrinking
preserves handle dependencies or explicitly rebuilds a legal trace. Retain seed, size and minimized trace.

**Reason and examples:** Conforming: shrinking an allocate/use/free history keeps the allocation required by
the remaining use. Nonconforming: discard most generated cases through preconditions and report high coverage.

**Verification and limit:** Measure exercised command families and rejection/discard rates. Run the minimized
trace against C when that boundary is claimed. Sequential traces do not prove concurrent linearizability.

<a id="htest-003"></a>

### HTEST-003: Require finite closure evidence

**MUST · exhaustive exploration claims.** Identify initial states, transition relation, bounds, visited-state
equivalence and all successor obligations. Preserve the frontier and reason when execution stops early.

**Reason and examples:** Conforming: an empty frontier plus accounted successors for every visited state
supports closure of the stated finite machine. Nonconforming: claim closure after a timeout or omit an
unsupported edge. A visited-state hash is not an equivalence proof.

**Verification and limit:** Delete a successor, alter a bound and force exhaustion; acceptance must fail.
Closure over bounded integers cannot cover unbounded allocator executions without an additional argument.

<a id="htest-004"></a>

### HTEST-004: Exercise rejection in the formal pipeline

**MUST · campaigns.** Require negative controls for bad arithmetic/refinements, altered C behavior, invalid
certificates and missing evidence. Record tool versions, declared assumptions, results and failure reasons.
Accept generated evidence only after the required Lean audit and replay.

**Reason and examples:** Conforming: a mutated C increment yields a reproducible mismatch and a rejected
program proof. Nonconforming: count an infrastructure crash as the intended rejection.

**Verification and limit:** Compare each diagnostic to its expected failure and retain successful controls.
The current Liquid Haskell campaign covers the `Refined.hs` slice and does not satisfy the all-function
requirement below. The Haskell producer and C frontend retain their recorded trust boundaries.
Follow [C–Haskell–Lean integration](../../formal-integration.md).

<a id="htest-005"></a>

### HTEST-005: Reconcile complete Liquid Haskell coverage

**MUST · all owned Haskell files and functions.** Apply
[HSTYLE-LIQUID-001](../haskell-code-standard.md#hstyle-liquid-001) to every component, including parsers,
importers, certificate producers, adapters and tests. Compare the expected file/function inventory with
actual body checks under the pinned Liquid Haskell configuration. Record local helpers, lambdas and inferred
contracts through their enclosing checked definitions. Preserve source digests, contracts, tool/solver identities,
effective options, assumptions and positive or intended-negative outcomes.

**Reason and examples:** A green arithmetic module does not account for an unchecked parser. Require a
positive result for each positive function and an intended rejection for each isolated negative fixture.
Missing functions, disabled plugin execution, unchecked assumptions, timeouts and unsupported definitions
must not count as successful coverage. Require negative controls that remove a module from checking, skip
a function body or violate a function's refinement; verify the specific rejection reason.

**Verification and limit:** Review the reconciliation and compare each claimed property with its refinement.
For formal-property functions, also require the adjacent mathematical statement under
[HDOC-004](../haskell-documentation.md#hdoc-004). The current campaign has arithmetic/permission negative
controls but no whole-tree, per-function coverage gate. Implement that coverage before claiming compliance;
neither test success nor generated Lean proof acceptance fills the missing Haskell evidence.

---

## Evidence examples

For `GuideReservation` in the [documentation guide](../haskell-documentation.md#complete-module), execute:

| Input | Expected observation |
| --- | --- |
| Capacity 8, used 3, request 5 | Success with usage 8 |
| Capacity 8, used 3, request 6 | `CapacityExceeded` |
| Capacity 8, used 3, request 0 | Success with usage 3 |
| Capacity 8, used 3, request -1 | `NegativeRequest` |
| Capacity 8, used 9 | `InvalidCursor` at construction |

A useful quantified property is: for each validated cursor and nonnegative request, success is equivalent
to the request fitting the remaining capacity. An author can implement this with QuickCheck, Hedgehog or a
finite enumeration, provided the evidence records which domain was exercised. These examples are regression
designs, not claims of a newly installed property framework.

---

## Sources and current coverage

[QuickCheck](https://github.com/nick8325/quickcheck) documents randomized property testing; its
[2.15.0.1 API](https://hackage.haskell.org/package/QuickCheck-2.15.0.1/docs/Test-QuickCheck.html) describes
generation, shrinking, replay and coverage. [Hedgehog](https://github.com/hedgehogqa/haskell-hedgehog) integrates
shrinking; its [1.4 API](https://hackage.haskell.org/package/hedgehog-1.4/docs/Hedgehog.html) includes sequential
and parallel state-machine testing. These are reference versions, not additions to the dependency freeze.
Consulted 2026-10-15. Pin an adopted version and its generator semantics before using either in CI.

Current regressions live in [engine tests](../../../../verification/engine/test/Main.hs). The
[engine commands](../../../../docs/runbooks/formal-verification.md) describe actual execution, refinement and
negative-control stages. Keep machine reports, C observations and kernel proof results as distinct evidence.

<!-- EOF -->


<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Haskell Module Architecture

Use these controls to keep the engine's transition semantics inspectable and its execution dependencies
explicit. Rule levels and exceptions follow the [code standard](haskell-code-standard.md#governance).

<details>
<summary><strong>On this page</strong></summary>

- [Repository map](#repository-map)
- [Boundary controls](#boundary-controls)
- [Change review](#change-review)

</details>

---

## Repository map

The [Cabal library](../../../verification/engine/libmemalloc-verifier.cabal) exposes modules under
`LibMemAlloc.Verifier`; its `app/Main.hs` owns command execution and `test/Main.hs` owns regressions.
The following table assigns responsibilities, not a claim that a dependency checker enforces this layering.

| Modules | Responsibility |
| --- | --- |
| `Protocol`, `IR` | Serialized input, schema and typed intermediate representation |
| `Import.CN`, `CMachine` | Interpret the supported C frontend representation and access rules |
| `Model`, `Explore`, `Symbolic`, `Differential` | State transitions, path analysis and comparisons |
| `Refined` | Arithmetic and permission primitives checked with Liquid Haskell |
| `Certificate`, `Pipeline` | Bind inputs, construct proof artifacts and combine analysis results |
| `app/Main.hs` | Read/write files and present execution results |

---

## Boundary controls

<a id="hmod-001"></a>

### HMOD-001: Direct dependencies toward model contracts

**MUST · core and adapters.** Keep core types independent of process execution, file locations and presentation.
Let adapters import the core. Pass external observations as validated values with explicit provenance.

**Reason and examples:** Conforming: the command adapter loads bytes and calls a parser. Nonconforming:
`Model` imports `Main` or reads files while deciding a transition.

**Verification and limit:** Review the import graph and effect types. GHC detects many module cycles but
does not enforce this architectural direction. Source: Report chapter 5 and the local module inventory.

<a id="hmod-002"></a>

### HMOD-002: Separate external syntax from admitted states

**MUST · parsers and importers.** Convert external syntax into a validated representation before analysis.
Keep unsupported constructs and locations in errors. Do not make the core reinterpret raw frontend text.

**Reason and examples:** Conforming: reject an unknown branch kind before exploration. Nonconforming:
represent that branch as a no-op to keep the importer running.

**Verification and limit:** Test malformed and unknown nodes and require rejection. A typed representation
can still encode the wrong meaning; source-to-IR preservation remains a separate obligation.

<a id="hmod-003"></a>

### HMOD-003: Keep proof production separate from acceptance

**MUST · certificates.** Give the Haskell producer no authority to declare a Lean proof accepted. Bind each
artifact to its inputs and pass it to the required Lean audit and kernel replay.

**Reason and examples:** Conforming: a generated theorem must check for the expected program and property.
Nonconforming: treat the producer's JSON `success` field as formal evidence.

**Verification and limit:** Mutate the claimed program, theorem and certificate independently; require each
inconsistency to fail. Replay still trusts the declared frontend boundary and formal semantics.

<a id="hmod-004"></a>

### HMOD-004: Own dependencies and native resources

**MUST · package and adapters.** Declare direct dependencies and preserve the dependency freeze. Isolate any
future FFI in an adapter with acquisition, borrowing, callback and shutdown contracts.

**Reason and examples:** Conforming: a dependency addition includes its reason, version and affected checks.
Nonconforming: a developer-global package or callback handle whose lifetime no module owns.

**Verification and limit:** Inspect the build plan, imports and shutdown tests. Dependency resolution alone
does not establish compatibility, provenance or foreign memory safety. Follow
[HSTYLE-FFI-001](haskell-code-standard.md#hstyle-ffi-001) for representation details.

---

## Change review

Review public signatures, constructor visibility, changed error cases and representation relations together.
For a changed state field, inspect equality, ordering, serialization, exploration keys and certificate output.
For a new adapter, identify who releases each resource after failure or cancellation. Record unresolved
boundaries in the [trust model](../../../docs/assurance/formal-trust.md), using the
[integration standard](../formal-integration.md) to scope any C claim.

<!-- EOF -->


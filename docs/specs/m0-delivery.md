<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# M0 execution plan

Implement M0 in the order below. Each step is an internal engineering milestone;
only the complete [M0 acceptance scope](README.md#initial-delivery-scope) qualifies the product.
All steps are **Planned**. The current implementation remains the distribution fixture in
[core/](../../core/mock.c); no allocator implementation or runtime evidence is claimed.

The accountable owner is Rafael V. Volkmer, as recorded in [MAINTAINERS.md](../../MAINTAINERS.md).
This identifies review ownership, not a delivery commitment. Track execution and evidence in the
[roadmap](../../ROADMAP.md#delivery-tracking); link an implementation PR and its exact source identity
before changing a step to Done.

Across these steps, register cases with the [composable test attributes](libmemalloc-tests-SDD.md#case-registry-schema)
and explicit requirements, input domains, oracles and evidence. Qualify the
[suite supervisor and isolation](libmemalloc-tests-SDD.md#lma-test-042) before accepting its product results.
As public declarations become available, add [typing, header and diagnostic fixtures](libmemalloc-tests-SDD.md#lma-test-041)
for the selected C profile; keep compile, link and runtime outcomes distinct. These are planned obligations,
not evidence that the fixture's existing automation already implements the product laboratory.

<details>
<summary><strong>On this page</strong></summary>

- [M0.1: Owned runtime and memory backend](#m01-owned-runtime-and-memory-backend)
- [M0.2: Allocation, metadata and local free](#m02-allocation-metadata-and-local-free)
- [M0.3: calloc and transactional realloc](#m03-calloc-and-transactional-realloc)
- [M0.4: Concurrency and quiescent lifecycle](#m04-concurrency-and-quiescent-lifecycle)
- [M0.5: Complete acceptance and distribution](#m05-complete-acceptance-and-distribution)

</details>

---

## M0.1: Owned runtime and memory backend

Dependency: accepted M0 contracts. Status: Planned.

Deliver owned base types, error values, checked byte operations and a backend with explicit
reserve/commit/release transactions. Keep bootstrap and side metadata independent of the public
allocator. Establish separate `reserved_only` and `owned_growth` resource ledgers.

Primary contracts: [backend](libmemalloc-core-implementation-SDD.md#lma-core-002),
[failure transactions](libmemalloc-core-implementation-SDD.md#lma-core-038),
[owned runtime](libmemalloc-core-implementation-SDD.md#lma-core-042) and
[base primitives](libmemalloc-core-implementation-SDD.md#lma-core-043).

Tests: inject failure at every acquisition and commit boundary; exercise size/alignment overflow,
exhausted reservations, rollback and repeated cleanup. Inspect linked symbols for forbidden runtime
dependencies. Test byte primitives against an independent reference in the test harness.

Exit criteria: every acquired resource is released or remains explicitly owned after failure;
ledger balances match backend observations; bootstrap cannot recurse into allocation. Retain
source identity, backend configuration, negative-control results and symbol inventories.

---

## M0.2: Allocation, metadata and local free

Dependency: M0.1. Status: Planned.

Deliver generated size classes, stable descriptors, domain lookup and a single-context alloc/free
path. Concurrency is not supported by this intermediate milestone. Preserve metadata and ownership
boundaries needed by M0.4; do not expose an intermediate implementation as qualified M0.

Primary contracts: [geometry](libmemalloc-core-implementation-SDD.md#lma-core-004),
[metadata](libmemalloc-core-implementation-SDD.md#lma-core-005),
[span states](libmemalloc-core-implementation-SDD.md#lma-core-006) and
[generated representation](libmemalloc-core-implementation-SDD.md#lma-core-037).

Tests: cover class boundaries, fundamental and extended alignment, large allocations, zero size,
domain rejection before dereference, descriptor exhaustion and reuse. Maintain an independent live
allocation model to detect overlap and account for exact requested sizes and physical storage.

Exit criteria: live blocks never overlap, successful allocations meet the declared alignment,
and failures preserve the existing heap. Record class-generation identity, invariant checks,
sanitizer results and resource accounting after repeated allocation/free cycles.

---

## M0.3: calloc and transactional realloc

Dependency: M0.2. Status: Planned.

Deliver checked count multiplication, zero initialization and realloc with exact requested-size
and prior-alignment preservation. Define zero-size handling through the existing API contract.

Primary contracts: [allocation API](libmemalloc-core-implementation-SDD.md#lma-core-003),
[requested size and alignment](libmemalloc-core-implementation-SDD.md#lma-core-028) and
[transactional outputs](libmemalloc-core-implementation-SDD.md#lma-core-039).

Tests: multiplication and rounding overflow; shrinking, growing and moving blocks; allocation failure
during growth; over-aligned inputs; zero sizes; and zeroed-byte provenance. Compare retained bytes
against an independent reference and verify the old pointer, bytes, size and alignment after failure.

Exit criteria: successful realloc preserves the required byte prefix; unsuccessful realloc preserves
the original allocation; calloc returns zeroed requested bytes without unchecked arithmetic. Retain
boundary-case results and failure-injection traces linked to each applicable planned SDD case.

---

## M0.4: Concurrency and quiescent lifecycle

Dependency: M0.3. Status: Planned.

Deliver owned atomics and synchronization, external execution contexts, the per-span mutex inbox,
bounded remote drainage, handoff and orphan adoption. Keep workers optional and disabled by default.
Implement externally protected admission and quiescent destroy; EBUSY must preserve resources.

Primary contracts: [admission](libmemalloc-core-implementation-SDD.md#lma-core-035),
[reference inbox](libmemalloc-core-implementation-SDD.md#lma-core-036),
[atomics](libmemalloc-core-implementation-SDD.md#lma-core-044) and
[parking protocol](libmemalloc-core-implementation-SDD.md#lma-core-047).

Tests: controlled publication/drain interleavings, remote free during handoff, owner exit,
orphan adoption, pending private work, admission racing with close, and repeated busy-destroy attempts.
Exercise native Linux x86_64 and AArch64 configurations; emulation alone does not qualify concurrency.

Exit criteria: no lost or duplicate frees, premature descriptor reuse or release of busy resources;
every admitted operation and pending remote return remains accounted for. Retain interleaving traces,
race-detector results where supported, stress results and platform-specific atomic/ABI reviews.

---

## M0.5: Complete acceptance and distribution

Dependency: M0.1 through M0.4. Status: Planned.

Reconcile every applicable REQUIRED clause across all six SDDs, including requirements not enumerated
above. The primary-contract links select implementation starting points, not an exhaustive allocation
of acceptance obligations. Optional arenas and workers remain disabled unless their complete evidence
is included; deferred capabilities remain unavailable.

Tests: the accepted SDD scenarios and contract reviews; negative controls; relocatable static/shared
installed consumers; dependency and export inventories; and exact compiler, linker, kernel/ABI and
feature tuples for each advertised target. Qualify C23 and any separately advertised C17 profile.

Include source-bound documentation examples, intended-cause compile-fail controls, order-independence and
repeatability records. Reconcile each accepted clause with its actual assertion or review obligation;
planned links, characterization snapshots, retries and coverage percentages cannot fill missing evidence.

Exit criteria: no unresolved required clause, missing artifact or unqualified advertised tuple.
Record justified NOT_APPLICABLE clauses rather than counting them as passes. Distinguish fixture and
product package identities. The maintainer reviews the complete evidence before accepting M0;
performance measurements and intermediate milestones do not substitute for this gate.

<!-- EOF -->


<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Product specifications

The Software Design Description (SDD) files combine specifications and design
for the proposed libmemalloc product. Specification-led development is the practice
that uses these artifacts; the acronym identifies the documents. Requirement, invariant,
control, and test identifiers provide stable cross-document links. A planned
case is not an executed test, and an example is not an allocator implementation.

| Specification | Responsibility | Diagram |
| --- | --- | --- |
| [Distribution and packaging](libmemalloc-distribution-SDD.md) | Shared installation contract, registry adoption, embedded targets, WebAssembly, and Rust | [Publication flow](libmemalloc-distribution-SDD.md#immutable-release-and-publication) |
| [Manual core and arenas](libmemalloc-core-implementation-SDD.md) | Ownership, allocation domains, metadata, threads, and platform boundaries | [Ownership overview](libmemalloc-core-implementation-SDD.md#core-ownership-overview) |
| [Optional garbage collector](libmemalloc-gc-implementation-SDD.md) | Roots, handshakes, tracing, reclamation, and runtime integration | [Collector states](libmemalloc-gc-implementation-SDD.md#gc-collection-overview) |
| [Compilation and delivery](libmemalloc-compilation-SDD.md) | Dialects, ABI, target qualification, profiles, and release inputs | [Qualification flow](libmemalloc-compilation-SDD.md#build-qualification-overview) |
| [Security](libmemalloc-security-SDD.md) | Threat boundaries, input validation, containment, and detector limits | [Security boundaries](libmemalloc-security-SDD.md#security-boundary-overview) |
| [Tests and evidence](libmemalloc-tests-SDD.md) | Planned cases, independent oracles, campaigns, and acceptance evidence | [Evidence flow](libmemalloc-tests-SDD.md#test-evidence-overview) |

Follow the [specification issue procedure](../procedures/specifications.md) to open SDD work, obtain
maintainer labels and close accepted implementation issues through PRs.

<details>
<summary><strong>On this page</strong></summary>

- [Authority and implementation status](#authority-and-implementation-status)
- [Initial delivery scope](#initial-delivery-scope)
- [Test classification and evidence](#test-classification-and-evidence)
- [Allocator improvement program](#allocator-improvement-program)
- [Source attribution](#source-attribution)
- [Mechanical validation](#mechanical-validation)
- [Reading and review](#reading-and-review)

</details>

---

## Authority and implementation status

Use the [local C standard](../standards/c/c-code-standard.md) for presentation
and local code rules. Its simple-branch, blank-line, and call/check requirements
apply to this repository. Product controls add requirements such as owned base
types, error codes, and strict runtime dependency boundaries.

The [CI reference](../reference/automation.md#ci-control-map) records what runs today and
what remains unimplemented. The [build guide](../assurance/reproducible-builds.md)
and [OpenSSF plan](../assurance/openssf.md) describe release qualification
and security evidence that must be added before making those product claims.

The original document package mentions companion examples, traceability records,
schemas, and validation reports that are not present in this repository. Do not
treat those references as executable tools or current evidence. Repository-owned
automation uses Lua; historical mentions of Python utilities do not authorize
new Python scripts. The current native Conan recipe and locked analysis adapters have explicit
boundaries in the [automation architecture](../reference/automation.md#guides); their Python
checks do not authorize additional orchestration in that language.

---

## Initial delivery scope

The initial implementation sequence is M0 followed by G0. These are proposed product cuts, not released
versions or claims about the current mock. Every control carries explicit `M0` and `G0` membership:

| Membership | Acceptance obligation |
| --- | --- |
| REQUIRED | Implement and verify every applicable clause before accepting that cut. |
| OPTIONAL | Disabled by default; enabling it adds all applicable clauses and evidence to the cut's gate. |
| DEFERRED | Excluded from the cut; it cannot be enabled or advertised under that cut's identity. |

A condition on an absent capability does not require implementing that capability. Its rejection/isolation
contract still applies. The qualification record must identify each such clause as NOT_APPLICABLE with the
selected feature and reason; it cannot count that clause as an executed pass. Phase P0–P5 describes roadmap
order; explicit M0/G0 membership defines acceptance scope and takes precedence over an inferred phase cutoff.

| Decision | M0 | G0 |
| --- | --- | --- |
| Allocation | Manual alloc/free/calloc/realloc; exact requested size and prior alignment | M0 plus a separately linked managed domain |
| Geometry | Fixed generated classes; side metadata; bounded stable descriptors | Same manual geometry; separate GC metadata |
| Remote free | Per-span mutex inbox; bounded drain; private work included in handoff | Same reference implementation |
| Lifetime | Externally protected admission and quiescent destroy; EBUSY preserves resources | Explicit roots, validated types, accessors and loans |
| Collection | Absent; no implicit GC from OOM or a callback | Precise stop-the-world, nonmoving tracing; complete closure before sweep |
| Runtime | Owned base types, byte primitives, atomics and synchronization; no libc dependency | Same strict boundary; external mutators participate in the handshake |
| Storage | Separate `reserved_only` and `owned_growth` configurations with exact resource ledgers | Account for roots, loans and tracing worklists in the selected configuration |
| Threads | External execution contexts supported; library workers are optional and default off | Workers remain optional; no mandatory background collector |
| Arenas | Optional separate component with explicit reset/close contract | Same; no implicit arena-to-GC ownership conversion |
| Reference target | Linux x86_64 and AArch64, 64-bit little-endian, qualified compiler/ABI tuples | Qualify GC separately on each reference tuple |
| Language | Explicit C23 profile; C17 compatibility qualified and labeled separately | Same; no inference of Rust or C++ allocator support |
| Exclusions | Adaptation, CAS inbox, early descriptor reclamation, Mesh, per-CPU, RT claims, interposition | Also generations, movement, incremental/concurrent tracing, conservative roots, weak refs and finalizers |
| Packaging | Relocatable install and static/shared consumers; fixture and product identities distinct | GC opt-in remains explicit in package metadata |

Other operating systems, ISA variants, dialects, Rust implementations, WebAssembly, registry adapters and compiler
integrations remain separate qualification work. Their future matrix entries are not M0/G0 support promises.
Raw-only targets without a qualified syscall/ABI backend remain BLOCKED_UNQUALIFIED; no hidden libc bridge is
introduced to make them pass. Existing automation build matrices qualify the fixture only. A product matrix
must record exact compiler, linker, kernel/ABI, feature and binary identities before either cut is accepted.

The [M0 execution plan](m0-delivery.md) divides implementation into dependency-ordered steps with
exit criteria and evidence. These steps do not change REQUIRED, OPTIONAL or DEFERRED membership,
and completing one step does not qualify an M0 release.

Acceptance requires applicable scenario evidence and contract reviews, negative controls for critical failure
paths, and installed-consumer results for each advertised tuple. Missing implementations, missing native
runners, missing mandatory artifacts or unresolved review clauses block acceptance. Neither benchmark success
nor document validation substitutes for those gates. No numeric speed target or WCET claim is part of M0/G0.

---

## Test classification and evidence

The [test taxonomy](libmemalloc-tests-SDD.md#verification-taxonomy) organizes eleven groups as composable
attributes. Scope, purpose and techniques can overlap in one case; formal methods and coverage retain
their own evidence fields. A label is neither an extra CI job nor proof that a campaign ran.

The [registry contract](libmemalloc-tests-SDD.md#case-registry-schema) binds each selected case to its
requirements, applicability, input domain, oracle, configuration and artifacts. It preserves distinct
variants and repetitions while deduplicating the same run selected through multiple labels. The product
registry is proposed; current documentation checks validate structural traceability, not that schema.

[Typing and compilation](libmemalloc-tests-SDD.md#lma-test-041) distinguish type relations, typed suites,
compile-pass/fail, diagnostics, headers, link tests and documentation examples. Negative compilation must
fail for the intended reason. [Suite reliability](libmemalloc-tests-SDD.md#lma-test-042) adds isolation,
expected termination, order/repetition controls and retention of intermittent failures. Their applicable
C and harness obligations are REQUIRED for M0/G0; optional languages and mechanisms remain conditional.

The [new planned cases](libmemalloc-tests-SDD.md#planned-verification-taxonomy-cases) make these obligations
reviewable. Published references are linked at the relevant taxonomy sections and controls. Coverage,
bounded proofs and passing repository checks do not substitute for executed product acceptance evidence.

---

## Allocator improvement program

Optimize for useful application work within explicit memory, latency and protection budgets. There is no
universal best allocator: a throughput improvement that exceeds the target's memory or security budget does
not qualify that configuration. The following proposals add mechanisms and measurable decisions to the
existing SDDs. They are not implemented capabilities or benchmark results.

| Priority | Technique and contract | Expected benefit to investigate | Main cost or limitation | Acceptance evidence |
| --- | --- | --- | --- | --- |
| Foundation | [Bounded models and refinement](libmemalloc-tests-SDD.md#lma-test-004) | Prevent overflow, lost remote work and premature reuse before optimizing | Models cover only declared states and memory semantics | Counterexamples, source mapping and native failure injection |
| First experiments after M0 | [Ownership-separated layout](libmemalloc-core-implementation-SDD.md#lma-core-050) | Reduce cache contention without replacing the mutex protocol | Padding, metadata footprint and workload dependence | Compact/split ablation, fan-in, churn and application tails |
| First experiments after M0 | [Pressure-aware release](libmemalloc-core-implementation-SDD.md#lma-core-049) | Balance idle memory against refault and hugepage costs | Controller state, maintenance work and prediction error | Fixed/immediate/adaptive policies, burst/reburst and partial backend failures |
| Diagnostic variant after M0 | [Sampled guards](libmemalloc-security-SDD.md#lma-sec-016) | Observe some heap errors with bounded diagnostic resources | Sampling gaps, page slack, VMAs and delayed reuse | Forced faults, valid controls, pool exhaustion and effective coverage |
| Qualified AArch64 variant | [Memory tagging](libmemalloc-security-SDD.md#lma-sec-017) | Detect mismatched-tag accesses with hardware assistance | Platform/ABI requirements, granularity and tag collisions | Native thread modes, remote free, recommit and FFI tests |
| G0 representation comparison | [Bitmap sweep and epoch discipline](libmemalloc-gc-implementation-SDD.md#lma-gc-023) | Skip empty bitmap words while retaining precise tracing | Summary/reset cost and stale epoch risk | Scalar oracle, partial words, wrap and aborted cycles |
| Reserved-profile experiment | [TLSF-style extent indexing](libmemalloc-core-implementation-SDD.md#lma-core-051) | Bound extent-management work with two-level bitmaps | Incomplete-fit misses, metadata and byte-proportional operations | Exhaustive boundary oracle, rollback and fixed-region comparisons |
| Hardened variant after M0 | [Reuse-attempt detection](libmemalloc-security-SDD.md#lma-sec-018) | Detect some stale writes before reuse and diversify placement | Quarantine, check work, padding and repeated-attempt gaps | Verify-before-clear, pressure, offsets and adaptive attempts |
| In-house MTE research | [Short-granule tripwires](libmemalloc-security-SDD.md#lma-sec-019) | Investigate byte-level detection inside an MTE granule | Fault decoding/replay, sampling and restricted concurrency | Valid/fault controls, interrupted replay and coverage retirement |

All new advanced core/security controls are DEFERRED for M0/G0 and disabled in those identities. The bitmap
comparison stays within the existing G0 stop-the-world algorithm and does not require an optimized
representation to accept G0. Earlier H-01 through H-14 hypotheses retain their status and separate obligations;
this program does not silently promote Mesh, per-CPU allocation or concurrent collection.

The [promotion contract](libmemalloc-tests-SDD.md#lma-test-040) requires frozen loss budgets, independent
holdout workloads, uncertainty, negative controls and interaction tests. Tune named constants in reviewed
profiles, preserving a simple reference configuration. Check combined retention from caches, quarantine,
guards and GC rather than granting each mechanism an independent copy of the same memory budget.

The [build matrix](libmemalloc-compilation-SDD.md#lma-build-024) and
[installed variants](libmemalloc-distribution-SDD.md#lma-dist-003) bind evidence to exact features and artifacts.
Sources in the controls motivate the proposals; performance or security results from those projects do not
transfer to libmemalloc. The [new planned cases](libmemalloc-tests-SDD.md#planned-allocator-improvement-cases)
define observable failures and acceptance oracles. Passing the document checker only validates this plan.

The [research review](libmemalloc-compilation-SDD.md#research-basis-and-adoption) links classical work from
1995 onward, established allocator implementations and recent research through 2026 to concrete controls.
The [literature-derived cases](libmemalloc-tests-SDD.md#planned-literature-derived-experiments) make the new
comparisons reviewable. Paired refill caches and correlated fragmentation tests strengthen existing controls;
compiler-assisted protection remains an independently qualified integration experiment.

---

## Source attribution

When an SDD attributes a technique, design choice or result to an academic work, repository or external
technical document, include a direct primary-source link at its first use in that control or standalone
section. This applies to existing controls and every new addition. A bibliography alone does not identify
which claim the source supports; keep application and limitations next to the link.

Use the paper title and year/version when available, or the official repository/documentation. Prefer stable
DOIs and versioned preprints; record an exact commit or release when comparing or reusing code. A link to a
moving branch is a reading reference, not a reproducible implementation identity. Identify LMA's proposed
adaptations explicitly and separate published results from planned product evidence. Do not invent a citation
for a project-specific policy or present a published mechanism as an original LMA invention.

---

## Mechanical validation

```sh
ansible-playbook playbook.yml -e lma_task=sdd-check
ansible-playbook playbook.yml -e lma_task=sdd-test
```

The checker validates the six documents together: unique anchored IDs, requirement ownership, explicit phases
and M0/G0 membership, planned case fields, individual requirement links and coverage allocation. It rejects
broken links, unallocated requirements, the former generic acceptance templates and unsupported evidence
states. Scenario allocation and contract-review allocation are reported separately. All product cases remain
PLANNED; this command checks the plan and does not execute the proposed allocator campaigns.

Requirements not exercised by an existing scenario have an explicit planned contract-review case. Those cases
require source/artifact references, per-clause findings and counterexample analysis. They expose the remaining
implementation work rather than claiming runtime coverage. The checker cannot determine whether prose or an
implementation is semantically correct; reviewers and the eventual product tests must establish that.

Current packaging regression entry points are
[installed consumers](../../tests/automation/build/consumer_test.lua),
[Windows pkg-config consumers](../../tests/automation/build/windows_pkgconfig_test.lua), and the
[README build example](../../tests/automation/build/readme_test.lua). They test the mock installation contract.
A test's presence here does not claim it has run on a Windows or AArch64 host in this workspace.

---

## Reading and review

Start with the responsibility boundary, then follow a control's requirements
and invariants to the planned case catalog. Check the exact configuration and
required evidence before claiming support. Compile-only, emulated, native,
instrumented, and performance results answer different questions.

Maintain descriptive reference titles and stable control anchors when editing.
Update document indexes, validate Markdown and links, and parse Mermaid diagrams
with `lua scripts/check/mermaid.lua`. See the
[local CI commands](../reference/automation.md#local-checks) for the remaining checks.

<!-- EOF -->


<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

<div align="center">

[![GitHub Discussions][discussions-shield]][discussions-url]
[![GitHub Milestones][milestones-shield]][milestones-url]
[![Roadmap Reference][roadmap-reference-shield]][roadmap-reference-url]

</div>

---

<div align="center">

<img
    src="/assets/images/libmemalloc_roadmap.svg"
    alt="libmemalloc roadmap logo"
    width="50%"
  />

</div>

---

## Delivery tracking

The current C implementation is a distribution fixture. The allocator and optional collector remain
planned. The accountable owner for the items below is Rafael V. Volkmer, following
[MAINTAINERS.md](MAINTAINERS.md). Ownership identifies who reviews progress and acceptance;
this roadmap assigns no delivery dates.

| Item | Status | Depends on | Completion and evidence |
| --- | --- | --- | --- |
| M0.1: Owned runtime and memory backend | Planned | Accepted M0 contracts | [Backend transactions, failure injection and symbol inventories](docs/specs/m0-delivery.md#m01-owned-runtime-and-memory-backend) |
| M0.2: Allocation, metadata and local free | Planned | M0.1 | [Geometry, non-overlap and resource accounting](docs/specs/m0-delivery.md#m02-allocation-metadata-and-local-free) |
| M0.3: calloc and transactional realloc | Planned | M0.2 | [Overflow, byte preservation and failure atomicity](docs/specs/m0-delivery.md#m03-calloc-and-transactional-realloc) |
| M0.4: Concurrency and quiescent lifecycle | Planned | M0.3 | [Remote drainage, handoff and native concurrency evidence](docs/specs/m0-delivery.md#m04-concurrency-and-quiescent-lifecycle) |
| M0.5: Complete acceptance and distribution | Planned | M0.1–M0.4 | [All applicable SDD clauses and installed consumers](docs/specs/m0-delivery.md#m05-complete-acceptance-and-distribution) |
| Product test registry and suite qualification | Planned | Accepted case/oracle contracts; harness implementation alongside M0 | [Composable classification, typing diagnostics, isolation and planned controls](docs/specs/README.md#test-classification-and-evidence) |
| G0: Separately linked managed domain | Planned | Accepted M0 | [Precise stop-the-world GC scope](docs/specs/README.md#initial-delivery-scope) |
| M1: Layout and page-release experiments | Planned | Accepted M0; frozen workload and loss budgets | [Ablations, pressure/refault tests and promotion criteria](docs/specs/README.md#allocator-improvement-program) |
| Sampled-guard diagnostic variant | Planned | Accepted M0; qualified protection backend and fault supervisor | [Pool bounds, forced faults and coverage gaps](docs/specs/libmemalloc-security-SDD.md#lma-sec-016) |
| AArch64 MTE variant | Planned | Native MTE target; qualified thread modes, ABI and build isolation | [Tag lifecycle, capability rejection and integration tests](docs/specs/libmemalloc-security-SDD.md#lma-sec-017) |
| Reserved TLSF-style extent index | Planned | Accepted M0; fixed-profile geometry, metadata and work budgets | [Boundary oracle, transactional splits and cost qualification](docs/specs/libmemalloc-core-implementation-SDD.md#lma-core-051) |
| Reuse-attempt hardening | Planned | Accepted M0; qualified entropy and bounded quarantine | [Checkpoint, pressure, offset and repeated-attempt tests](docs/specs/libmemalloc-security-SDD.md#lma-sec-018) |
| Short-granule MTE diagnostics | Planned | Qualified native MTE; safe replay and supported instruction set | [NanoTag-based investigation with coverage and concurrency limits](docs/specs/libmemalloc-security-SDD.md#lma-sec-019) |
| Lua source review and suite diagnostics | In Progress | Existing automation contracts | [Lua quality gate and local evidence](docs/reference/lua-quality.md); maintainer acceptance pending |
| Hosted acceptance and merge enforcement | Open | Matching source and CI evidence; repository administration | [Recorded gaps and required evidence](docs/assurance/gaps.md) |

All product implementation evidence is pending. A plan, passing fixture or mechanically validated
specification does not complete a product milestone. Implementation PRs and retained evidence must be
linked in the corresponding row before marking it Done.

## Runtime constraints

M0 acceptance includes a production core without C standard library calls or allocations
through an external heap. Bootstrap and metadata use storage owned by the project, with
explicit limits and failure paths. The `reserved_only` and `owned_growth` profiles have
separate growth contracts; internal memory consumption must still be accounted for.
These are planned requirements in
[LMA-CORE-042](docs/specs/libmemalloc-core-implementation-SDD.md#lma-core-042),
not properties established by the current distribution fixture.

## Status and acceptance

- **Planned:** scope and dependencies are recorded; implementation evidence is pending.
- **In Progress:** source or verification work is underway; acceptance remains pending.
- **Open:** an adoption gap needs a concrete disposition and evidence.
- **Blocked:** progress requires an identified prerequisite; record it in the item's row.
- **Done:** implementation, tests and required review are complete, with linked source and evidence.

Update this table when work starts, a dependency changes or acceptance completes. Record the exact
source revision, selected configuration, test commands and results with each evidence link.
Use the [specification procedure](docs/procedures/specifications.md) for changes to product contracts.

## Scope after M0

G0 adds the separately linked managed domain only after manual allocation passes complete M0 acceptance.
Other platforms, collection strategies, interposition, compiler integrations and adaptive policies retain
their explicit [SDD membership](docs/specs/README.md#initial-delivery-scope). Intermediate M0 steps do not
change REQUIRED, OPTIONAL or DEFERRED obligations.

## Contribution tracking

Use the local item IDs above when opening an implementation issue or PR. Link the applicable SDD clauses,
planned tests and dependent item. Discuss changes to scope through
[GitHub Discussions](https://github.com/RafaelVVolkmer/libmemalloc/discussions), and retain acceptance
records with the implementation. Existing [adoption gaps](docs/assurance/gaps.md) remain open until their
required evidence is reviewed.

---

<!-- ======================================================================= -->
<!-- Roadmap Badge References                                                -->
<!-- ======================================================================= -->

[discussions-shield]: https://img.shields.io/badge/GitHub-Discussions-2F81F7?style=flat-square&logo=github&logoColor=white&labelColor=1F2328
[discussions-url]: https://github.com/RafaelVVolkmer/libmemalloc/discussions

[milestones-shield]: https://img.shields.io/badge/GitHub-Milestones-3FB950?style=flat-square&logo=github&logoColor=white&labelColor=1F2328
[milestones-url]: https://docs.github.com/issues/using-labels-and-milestones-to-track-work/about-milestones

[roadmap-reference-shield]: https://img.shields.io/badge/Open%20Source-Roadmap%20Reference-2F81F7?style=flat-square&logo=github&logoColor=white&labelColor=1F2328
[roadmap-reference-url]: https://github.com/github/roadmap

<!-- EOF -->


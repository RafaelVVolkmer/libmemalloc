<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Rust Code Standard

Use this standard to implement and review Rust libraries, applications, allocator bindings and platform adapters.
It defines local requirements for code, API design, unsafe boundaries, resources, security and performance.
The [pitfalls catalogue](rust-common-pitfalls.md) explains failure mechanisms and regression designs.
The [architecture guide](rust-module-architecture.md) defines crates, dependency direction and release boundaries.
These three documents contain the Rust requirements and explanations needed for review.

<a id="rule-index"></a>

<details>
<summary><strong>On this page</strong></summary>

<details>
<summary>Executable boundary evidence</summary>

- [Allocation ownership regression](#allocation-regression)

</details>

<details>
<summary>Allocation, scheduling and configuration boundaries</summary>

- [RUST-085: Preserve the complete vector allocation contract](#rust-085)
- [RUST-086: Publish only the initialized prefix of a growing buffer](#rust-086)
- [RUST-087: Review wake registration as part of the readiness protocol](#rust-087)
- [RUST-088: Specify both outcomes of compare-and-exchange](#rust-088)
- [RUST-089: Represent optional foreign callbacks without invalid values](#rust-089)
- [RUST-090: Verify the resolved graph for each supported consumer](#rust-090)

</details>

- [Governance and profiles](#governance-and-profiles)
- [Formatting, layout and documentation](#formatting-layout-and-documentation)
- [Implementation controls](#implementation-controls)
- [Naming and source presentation controls](#naming-and-source-presentation-controls)
- [Performance and machine-specific controls](#performance-and-machine-specific-controls)
- [Appendix A. Canonical RBAN register](#restricted-facilities)
- [Tooling and verification](#tooling-and-verification)
- [Appendix B. Complete local-contract example](#complete-checked-example)
- [Appendix C. Maintained reference and candidate](#reference-candidate)
- [Appendix D. Examples for every RBAN entry](#restricted-examples)
- [Appendix E. Topic coverage](#topic-coverage)
- [Links and references](#sources-and-revision-policy)

<details>
<summary>Formatting, documentation and lint policy</summary>

- [RUST-001: Let rustfmt own mechanical formatting](#rust-001)
- [RUST-002: Resolve warnings and justify narrow lint exceptions](#rust-002)
- [RUST-003: Explain each unsafe obligation at its use](#rust-003)
- [RUST-004: Document public contracts and observable effects](#rust-004)

</details>

<details>
<summary>Naming and vocabulary</summary>

- [RUST-061: Use the naming convention for each Rust construct](#rust-061)
- [RUST-062: Keep vocabulary, abbreviations and acronyms consistent](#rust-062)
- [RUST-063: Name quantities, predicates and coordinate systems explicitly](#rust-063)
- [RUST-064: Make method names describe borrowing, conversion and lifecycle](#rust-064)
- [RUST-065: Give generic parameters and lifetimes a readable role](#rust-065)
- [RUST-066: Make package, module and file names agree with their scope](#rust-066)
- [RUST-067: Name variants, errors and constants for their meaning](#rust-067)
- [RUST-068: Name tests, fixtures and benchmarks after observable behavior](#rust-068)

</details>

<details>
<summary>Columns, spacing and expression layout</summary>

- [RUST-069: Use explicit column budgets and readable line breaks](#rust-069)
- [RUST-070: Use block indentation and formatter-owned spacing](#rust-070)
- [RUST-071: Separate logical stages with one blank line](#rust-071)
- [RUST-072: Separate items without scattering related declarations](#rust-072)
- [RUST-073: Keep documentation, attributes and safety comments attached](#rust-073)
- [RUST-074: Lay out signatures and bounds so the contract is visible](#rust-074)
- [RUST-075: Keep calls, chains and closures easy to follow](#rust-075)
- [RUST-076: Make aggregate and match layouts reflect their structure](#rust-076)
- [RUST-077: Make precedence and control expressions clear](#rust-077)

</details>

<details>
<summary>Imports, comments and source organization</summary>

- [RUST-078: Group imports and keep names traceable](#rust-078)
- [RUST-079: Keep bindings close to use and shadow only a clear refinement](#rust-079)
- [RUST-080: Write comments and diagnostics that explain decisions](#rust-080)
- [RUST-081: Format literals without changing the represented data](#rust-081)
- [RUST-082: Keep macros and conditional attributes readable](#rust-082)
- [RUST-083: Give each source file a predictable reading order](#rust-083)
- [RUST-084: Make destructuring and intentionally ignored values explicit](#rust-084)

</details>

<details>
<summary>Errors, ownership and public invariants</summary>

- [RUST-005: Reserve panics for violated programming invariants](#rust-005)
- [RUST-006: Represent fallibility with Result](#rust-006)
- [RUST-007: Prove production unwrap and expect locally](#rust-007)
- [RUST-008: Express lifetime and ownership in types](#rust-008)
- [RUST-009: Make cloning an ownership decision](#rust-009)
- [RUST-010: Contain unsafe operations and their invariant boundary](#rust-010)
- [RUST-011: Define FFI types and ABI explicitly](#rust-011)
- [RUST-012: Make numeric conversions checked or proven](#rust-012)
- [RUST-013: Preserve public representation independence](#rust-013)
- [RUST-014: Justify interior mutability](#rust-014)
- [RUST-015: Avoid global mutable state by default](#rust-015)

</details>

<details>
<summary>Functions, types and values</summary>

- [RUST-016: Use cohesive functions and idiomatic control flow](#rust-016)
- [RUST-017: Bound source and API complexity](#rust-017)
- [RUST-018: Enforce newtype and trait invariants](#rust-018)
- [RUST-019: Control generics, builders and dynamic dispatch](#rust-019)
- [RUST-020: Select arithmetic semantics explicitly](#rust-020)
- [RUST-021: Define floating-point behavior](#rust-021)
- [RUST-022: Separate text, bytes and filesystem paths](#rust-022)
- [RUST-023: Serialize fields through an explicit format](#rust-023)

</details>

<details>
<summary>Memory, unsafe and foreign boundaries</summary>

- [RUST-024: Preserve allocation and allocator contracts](#rust-024)
- [RUST-025: Make fallible growth meaningful](#rust-025)
- [RUST-026: Keep destruction safe and expose fallible finalization](#rust-026)
- [RUST-027: Bound recursion, stack and retained work](#rust-027)
- [RUST-028: Preserve pointer provenance and aliasing](#rust-028)
- [RUST-029: Establish references only after their full contract holds](#rust-029)
- [RUST-030: Track initialization with MaybeUninit](#rust-030)
- [RUST-031: Prefer typed conversions over transmute](#rust-031)
- [RUST-032: Maintain pinning through projection and destruction](#rust-032)
- [RUST-033: Prove manual Send and Sync implementations](#rust-033)
- [RUST-034: Specify FFI transfer and callback lifetime](#rust-034)
- [RUST-035: Control unwinding across foreign boundaries](#rust-035)

</details>

<details>
<summary>Concurrency, async and platform profiles</summary>

- [RUST-036: Define lock order and poisoning behavior](#rust-036)
- [RUST-037: Keep blocking guards out of suspension](#rust-037)
- [RUST-038: Make cancellation a state transition](#rust-038)
- [RUST-039: Supervise threads, tasks and channels](#rust-039)
- [RUST-040: Hide atomics behind a proved protocol](#rust-040)
- [RUST-041: Separate synchronization from reclamation](#rust-041)
- [RUST-042: Confine MMIO, DMA and assembly to hardware owners](#rust-042)
- [RUST-043: Make no_std and real-time limits explicit](#rust-043)
- [RUST-044: Keep OS-global effects at an application boundary](#rust-044)

</details>

<details>
<summary>External effects, security and dependencies</summary>

- [RUST-045: Validate before publishing effects](#rust-045)
- [RUST-046: Handle partial I/O and durable completion](#rust-046)
- [RUST-047: Use explicit time and randomness contracts](#rust-047)
- [RUST-048: Preserve authority at external interpreters and paths](#rust-048)
- [RUST-049: Bound structured input and outbound requests](#rust-049)
- [RUST-050: Assign secrets and fault resistance to dedicated primitives](#rust-050)
- [RUST-051: Keep loading and plugins under a trust policy](#rust-051)
- [RUST-052: Review macros and compile-time execution](#rust-052)
- [RUST-053: Make features additive and configurations explicit](#rust-053)
- [RUST-054: Own dependencies, generated code and imported sources](#rust-054)
- [RUST-055: Evolve APIs and MSRV deliberately](#rust-055)
- [RUST-056: Keep unsafe allocator implementations non-reentrant](#rust-056)
- [RUST-057: Separate deterministic behavior from build repeatability](#rust-057)

</details>

<details>
<summary>Verification and product assurance</summary>

- [RUST-058: Tie testing to contracts and failure states](#rust-058)
- [RUST-059: Qualify tools and evidence separately](#rust-059)
- [RUST-060: Keep product assurance traceable](#rust-060)

</details>

<details>
<summary>Performance and microarchitecture</summary>

- [RPERF-001: Measure the deployed operation](#rperf-001)
- [RPERF-002: Record the effective machine and build](#rperf-002)
- [RPERF-003: Prefer algorithmic and ownership improvements](#rperf-003)
- [RPERF-004: Account for allocation and container tradeoffs](#rperf-004)
- [RPERF-005: Control monomorphization and hot code size](#rperf-005)
- [RPERF-006: Remove bounds checks through provable structure first](#rperf-006)
- [RPERF-007: Give write-hot cache lines an owner](#rperf-007)
- [RPERF-008: Reduce coherence traffic and synchronize in batches](#rperf-008)
- [RPERF-009: Treat waits and read-mostly schemes as workload decisions](#rperf-009)
- [RPERF-010: Diagnose access geometry with target evidence](#rperf-010)
- [RPERF-011: Plan NUMA and translation locality together](#rperf-011)
- [RPERF-012: Measure branch and dispatch choices](#rperf-012)
- [RPERF-013: Bound software and hardware prefetch experiments](#rperf-013)
- [RPERF-014: Qualify streaming and device stores](#rperf-014)
- [RPERF-015: Centralize specialization and prove backend selection](#rperf-015)
- [RPERF-016: Invalidate cached specialization exactly](#rperf-016)
- [RPERF-017: Preserve an independent oracle and cost limits](#rperf-017)
- [RPERF-018: Store the optimization decision with its owner](#rperf-018)

</details>

<details>
<summary>Restricted facilities</summary>

- [RBAN-001: Unproved `unwrap`, `expect`, unchecked unwrap](#rban-001)
- [RBAN-002: Unjustified unsafe or unsafe impl](#rban-002)
- [RBAN-003: Unchecked indexing, `unreachable_unchecked`](#rban-003)
- [RBAN-004: `transmute`, zeroing arbitrary typed values](#rban-004)
- [RBAN-005: `static mut`, process-global mutation](#rban-005)
- [RBAN-006: Raw owner reconstruction from foreign memory](#rban-006)
- [RBAN-007: Panic as expected failure; exit/abort in libraries](#rban-007)
- [RBAN-008: Blocking guards across `.await`](#rban-008)
- [RBAN-009: Unbounded growth, spawning or retries on input](#rban-009)
- [RBAN-010: Shell interpolation and unauthorized loading](#rban-010)
- [RBAN-011: Deterministic randomness for secrets](#rban-011)
- [RBAN-012: Blanket warning/formatter suppression](#rban-012)
- [RBAN-013: Public-ABI promises from default Rust layout](#rban-013)
- [RBAN-014: `mem::forget`/`ManuallyDrop` as ordinary cleanup](#rban-014)
- [RBAN-015: Unsigned/width casts without range semantics](#rban-015)
- [RBAN-016: Debug-only checks protecting unsafe access](#rban-016)
- [RBAN-017: Volatile as synchronization](#rban-017)
- [RBAN-018: Global “all restriction lints” policy](#rban-018)

</details>

</details>

---

## Governance and profiles

**Must** and imperative rules are requirements. **Should** identifies a default that needs a recorded reason
when changed. **May** grants permission. A review trigger asks the owner to assess a design; it does not
establish a defect by itself. Each `RUST-*`, `RPERF-*`, `RBAN-*` and `RMOD-*` identifier is stable.
`RPIT-*` entries explain failures without adding hidden requirements.

Record deviations with the rule ID, affected paths and configurations, reason, risk, compensating checks,
owner, reviewer, evidence and expiry or review condition. A lint suppression is only one part of that record.
A soundness defect cannot receive a deviation that makes undefined behavior acceptable.

| Class | Meaning and evidence |
| --- | --- |
| PROJECT_STYLE | Readability and presentation; rustfmt and review. |
| CORRECTNESS | Required outputs, state transitions and failure behavior; contract tests. |
| SOUNDNESS | Safe callers cannot trigger undefined behavior through the abstraction; invariant review and tools. |
| SECURITY | Authority, input, secrets and dependency trust; threat-specific checks. |
| PORTABILITY | Compiler, target, ABI and configuration assumptions; build and execution matrix. |
| ARCHITECTURE | Ownership and dependency boundaries; graph, API and integration review. |
| VERIFICATION | Scope and reproducibility of evidence; retained results and limitations. |
| PERFORMANCE | Measured cost under a defined workload; reference comparison and resource limits. |

Language and library contracts constrain implementation. Product requirements select applicable profiles;
this standard supplies project rules within those constraints. External guides provide technical context.
The rules here are deliberate project choices, not a claim that Rust, Clippy or any cited organization
mandates the entire policy. Compliance with coding rules does not establish product certification.

### Effective profile

Select a named combination before claiming conformance:

| Profile | Required decisions |
| --- | --- |
| BASE | Edition, MSRV, pinned compiler, rustfmt, Clippy, targets, features and panic strategy. |
| HOSTED | `std`, filesystem/process/network authority, threads, logging and shutdown. |
| CORE | `#![no_std]`, target support, panic handler owner and permitted language/library subset. |
| ALLOC | `alloc`, allocator owner, fallible growth and allocation budgets; can accompany CORE. |
| UNSAFE/FFI | Reviewed invariant boundary, ABI, allocator pairing, callbacks and unwind policy. |
| ASYNC | Executor, blocking rules, cancellation, task supervision and backpressure. |
| REALTIME/DEVICE | Interrupts, DMA, MMIO, bounded latency/stack, residency and platform evidence. |
| CRITICAL | Hazard-derived requirements, restricted subset, qualified tools and traceable verification. |

MSRV means minimum supported Rust version. Edition and compiler version are separate: select edition 2024
for new crates when their approved MSRV permits it; retain older editions until a tested migration.
Use `rust-version` in Cargo metadata and test it. An edition migration does not select native library versions,
CPU features or a stable binary interface. See the [Edition Guide][edition].

At authoring, this checkout has no tracked Cargo workspace, Rust toolchain policy or Rust CI runner.
These documents specify a policy to apply when Rust code is introduced. Cargo commands below are recipes for
that workspace, not existing repository gates. The [example validation record](#example-validation-record)
identifies the compiler used for documentation examples.

Keep a machine-readable profile record with target triples, feature sets, linker and native dependencies,
`panic`, overflow checks, optimization, LTO, CPU features, allocator, execution environment and tool versions.
Do not infer a `no_std`, no-allocation or real-time claim from a successful desktop build.

### Safety vocabulary

A safe API must preserve memory safety for every safe caller, including callers that panic, forget values,
provide unusual valid inputs or implement safe traits incorrectly. An `unsafe fn` transfers documented
obligations to its caller. An unsafe block discharges particular obligations inside an implementation.
Soundness review includes safe code that maintains those obligations. Memory safety does not establish
logical correctness, confidentiality, authorization, bounded memory or freedom from deadlocks.
See the [Reference's undefined-behavior discussion][ub] and [Fuchsia unsafe review guidance][fuchsia].

---

## Formatting, layout and documentation

The following defaults are detailed in [RUST-061–084](#naming-and-source-presentation-controls). They supply
reviewable source-style rules alongside the safety, API and implementation controls.

| Topic | Project default | Detailed controls |
| --- | --- | --- |
| Names | Rust casing by construct; domain vocabulary, visible units and ownership semantics. | [RUST-061](#rust-061)–[RUST-068](#rust-068) |
| Rust line width | 100 columns including indentation; local exceptions for indivisible content. | [RUST-069](#rust-069) |
| Rust prose comments | Aim for 80 characters from the marker, within 100 columns including indentation. | [RUST-069](#rust-069), [RUST-080](#rust-080) |
| Indentation and spaces | Four spaces per level; rustfmt owns mechanical spacing and continuation layout. | [RUST-070](#rust-070) |
| Blank lines | One between logical stages and distinct definitions; none inside an operation/check pair. | [RUST-071](#rust-071)–[RUST-073](#rust-073) |
| Long expressions | Wrap at syntax boundaries; use meaningful intermediate names when needed. | [RUST-074](#rust-074)–[RUST-077](#rust-077) |
| Imports and source order | Group by origin; keep contract, related definitions and tests easy to locate. | [RUST-078](#rust-078), [RUST-083](#rust-083) |
| Markdown prose | 120 columns under repository lint policy; table and URL exceptions follow that policy. | This overview |

Use the selected toolchain's `rustfmt` and stable configuration. Record the language edition and formatting
style edition; changes to either deserve a dedicated formatting review. Use four-space indentation and the
formatter's default width of 100 unless the repository later adopts an explicit Rust configuration.
Do not copy whitespace rules from another language or maintain manual operator-alignment tables.
The [Rust Style Guide][style] explains the canonical layout.

Organize a file as crate/module documentation, imports, constants and types, implementations, private helpers,
and local tests where that order helps navigation. Keep mutually relevant types and implementations near each
other. Put one blank line between logical stages; keep an operation and its error propagation together.
Place `///` documentation and attributes beside the item. Keep `// SAFETY:` beside the unsafe operation it
justifies. Let rustfmt handle braces, continuation lines, spaces and trailing commas.

Use `snake_case` for modules, functions, methods, variables and Rust source filenames; `UpperCamelCase` for
types and traits; `SCREAMING_SNAKE_CASE` for constants and statics. Use meaningful units such as `_bytes`,
`_count` or a typed `Duration`. Prefer affirmative predicates such as `is_empty` and `has_capacity`.
Use `new` for construction, `try_new` for a fallible constructor when it distinguishes an existing convention,
`as_*` for cheap borrowed views, `to_*` for conversion that generally creates a value, and `into_*` for consuming
conversion. Explain resource acquisition in the contract: `new` does not by itself promise no allocation.
See the [API Guidelines checklist][api] for API naming and common trait conventions.

For one operation, `validate(input)?;` keeps propagation beside the call. A later cleanup obligation belongs
in an owning guard or explicit transaction, not in a distant return label. Use early returns and `?` when
they clarify rejection paths. Review drop order and observable partial effects at each exit.

Comments explain invariants, why a constraint exists and which measurement supports an optimization.
Remove commented-out production code. Track unfinished work with an owner and issue; state the missing
behavior and its acceptance condition. Keep diagnostics searchable and redact secrets from `Debug`, `Display`
and error chains. Avoid editor modelines, invisible directional controls and confusable identifiers in
project-owned names. Strings that intentionally contain such characters need an explicit test and explanation.

Use UTF-8 and LF. Markdown prose stays within 120 columns, with tables and URLs under the repository lint
policy. Owned Markdown ends with a blank line, `<!-- EOF -->`, then a final blank line. For future Rust files,
use `// EOF` and keep any terminal-empty-line exception in a formatter adapter; do not add `rustfmt::skip`
to hide unrelated differences. The current EOF checker has no Rust-specific extension entry.

---

## Implementation controls

Unless a rule names a narrower profile, it applies to BASE and all extensions. Each rule's verification
paragraph states the minimum review or test obligation. Profile-specific deviations use the governance record.

---

<a id="rust-001"></a>

### RUST-001: Let rustfmt own mechanical formatting

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Run `cargo fmt --all -- --check` with the pinned formatter. Review blank-line grouping,
comment placement and readable decomposition separately; formatting cannot identify transactions.
Do not suppress formatting to preserve personal spacing. Verify generated sources with their generator policy.

**Rationale:** Consistent formatting keeps review attention on changed behavior.

**Verification design:** Check the formatter diff and inspect changed logical groups. Source: [Rust Style Guide][style].

#### Local examples

**Contextual Rust example:**

```rust
let used_bytes = header_bytes + payload_bytes;
```

**Noncompliant fragment or claim (do not copy):**

```rust
let used_bytes=header_bytes+payload_bytes;
```

---

<a id="rust-002"></a>

### RUST-002: Resolve warnings and justify narrow lint exceptions

**Class:** VERIFICATION. **Obligation:** project requirement.

Use the compiler-matched Clippy with `-D warnings` in required CI configurations.
Review `correctness`, suspicious, complexity and performance findings; select pedantic and restriction lints
individually rather than enabling contradictory restrictions. Prefer scoped `#[expect(lint, reason = "...")]`
when supported and an occurrence is expected. Review unfulfilled expectations; generated code may need a
narrow documented `allow`. Never suppress a warning instead of fixing unsound code.

**Rationale:** A narrow exception remains attributable and can become stale without hiding other warnings.

**Verification design:** Record lint ID, reason and affected configurations. Sources: [Clippy CI][clippy],
[Microsoft universal guidelines][microsoft].

#### Local examples

**Contextual Rust example:**

```rust
#[expect(clippy::unused_async, reason = "trait requires an async operation")]
async fn ready(&self) {}
```

**Noncompliant fragment or claim (do not copy):**

```rust
#![allow(warnings)]
```

---

<a id="rust-003"></a>

### RUST-003: Explain each unsafe obligation at its use

**Class:** SOUNDNESS. **Obligation:** project requirement.

**Profile:** UNSAFE/FFI.

Put `// SAFETY:` immediately before unsafe operations and unsafe impls.
Explain the origin of alignment, initialized extent, lifetime, aliasing and synchronization facts that matter
there. Repeating “the pointer is valid” is insufficient. An unsafe function's `# Safety` section specifies
caller obligations; the local comment explains how the implementation meets the called operation's contract.

**Rationale:** The reviewer needs evidence for the particular operation, not a restatement of its precondition.

**Verification design:** Trace every stated fact to a type, check or maintained invariant. Sources: [std safety
comments][safety],
[Linux Rust coding guidelines][kernel].

#### Local examples

**Contextual Rust example:**

```rust
// SAFETY: index is below the initialized slice length, checked above;
// the immutable borrow prevents mutation throughout this access.
let byte = unsafe { *bytes.get_unchecked(index) };
```

**Noncompliant fragment or claim (do not copy):**

```rust
// SAFETY: This should be fine.
let byte = unsafe { *bytes.get_unchecked(index) };
```

---

<a id="rust-004"></a>

### RUST-004: Document public contracts and observable effects

**Class:** CORRECTNESS. **Obligation:** project requirement.

Document inputs, outputs, units, ownership, mutation, allocation, blocking and thread
requirements. Add `# Errors`, `# Panics` and `# Safety` where applicable, with an executable example for
nontrivial APIs. Include partial progress, cancellation and cleanup behavior when they matter.

**Rationale:** Consumers need to distinguish returned failure from mutation, panic and resource costs.

**Verification design:** Build rustdoc with warnings denied and test examples. Source: [rustdoc tests][rustdoc].

**Related pitfalls:** [RPIT-038](rust-common-pitfalls.md#rpit-038), [RPIT-050](rust-common-pitfalls.md#rpit-050).

#### Local examples

**Contextual Rust example:**

```rust
/// Appends bytes without changing the buffer on error.
///
/// # Errors
/// Returns Limit if the new length exceeds the configured budget.
pub fn try_append(&mut self, bytes: &[u8]) -> Result<(), AppendError>;
```

**Noncompliant fragment or claim (do not copy):**

```rust
/// Appends bytes.
pub fn try_append(&mut self, bytes: &[u8]) -> Result<(), AppendError>;
```

---

<a id="rust-005"></a>

### RUST-005: Reserve panics for violated programming invariants

**Class:** CORRECTNESS. **Obligation:** project requirement.

Return errors for invalid external input, capacity exhaustion and expected I/O failures.
Document intentional panics and the boundary's unwind or abort behavior. `debug_assert!` cannot enforce a
precondition needed to prevent undefined behavior in optimized builds. Library code must not install a global
panic hook or terminate the process as routine error handling.

**Rationale:** Expected rejection is part of the interface and must remain recoverable under the selected profile.

**Verification design:** Test rejection in debug and release; inspect panic reachability at FFI and critical boundaries.

**Related pitfalls:** [RPIT-014](rust-common-pitfalls.md#rpit-014).

#### Local examples

**Contextual Rust example:**

```rust
let size = text.parse::<usize>().map_err(ParseError::Size)?;
```

**Noncompliant fragment or claim (do not copy):**

```rust
let size = text.parse::<usize>().expect("user supplied a number");
```

---

<a id="rust-006"></a>

### RUST-006: Represent fallibility with Result

**Class:** CORRECTNESS. **Obligation:** project requirement.

Use domain error enums in libraries and preserve causal information at adapters.
Applications may add operation context for diagnostics. Use `Option` for legitimate absence, not for losing a
failure cause. Propagate with `?`; convert deliberately at the abstraction owner. Mark custom result-like types
`#[must_use]` when ignoring them violates their purpose.

**Rationale:** Preserving the failure category lets the owning layer decide whether to retry or report it.

**Verification design:** Exercise each error variant and inspect ignored results, `.ok()` and wildcard error mappings.

#### Local examples

**Contextual Rust example:**

```rust
let payload = read_payload().map_err(LoadError::Read)?;
```

**Noncompliant fragment or claim (do not copy):**

```rust
let payload = read_payload().ok();
```

---

<a id="rust-007"></a>

### RUST-007: Prove production unwrap and expect locally

**Class:** CORRECTNESS. **Obligation:** project requirement.

Production `unwrap` or `expect` requires a nearby proof that the failure state cannot
occur under the function's contract. Prefer matching or type-level construction when the proof is brittle.
A comment claiming valid user input is not a proof. Tests may use `expect` to state fixture assumptions;
a failed fixture must remain visible.

**Rationale:** An unchecked assumption becomes fragile when its establishing condition is distant or external.

**Verification design:** Inspect each occurrence, including generated macros, and test the boundary that
establishes the fact.

#### Local examples

**Contextual Rust example:**

```rust
let first = values.first().ok_or(InputError::Empty)?;
```

**Noncompliant fragment or claim (do not copy):**

```rust
let first = values.first().unwrap();
```

---

<a id="rust-008"></a>

### RUST-008: Express lifetime and ownership in types

**Class:** SOUNDNESS / ARCHITECTURE. **Obligation:** project requirement.

Borrow for temporary access, move for transfer, and return owners for newly
acquired resources. Tie borrowed outputs to the actual owner. Avoid fabricated `'static` lifetimes and raw
pointers used to bypass a borrow conflict. Document who can mutate shared views and when handles become invalid.

**Rationale:** The type signature should constrain the actual owner lifetime instead of relying on caller discipline.

**Verification design:** Add compile-fail tests for forbidden lifetime escapes; exercise success and failure transfers.

**Related pitfalls:** [RPIT-001](rust-common-pitfalls.md#rpit-001), [RPIT-023](rust-common-pitfalls.md#rpit-023),
[RPIT-048](rust-common-pitfalls.md#rpit-048).

#### Local examples

**Contextual Rust example:**

```rust
fn payload(packet: &Packet) -> &[u8] {
    &packet.bytes
}
```

**Noncompliant fragment or claim (do not copy):**

```rust
fn payload(packet: &Packet) -> &'static [u8] {
    unsafe { std::mem::transmute(packet.bytes.as_slice()) }
}
```

---

<a id="rust-009"></a>

### RUST-009: Make cloning an ownership decision

**Class:** PERFORMANCE / CORRECTNESS. **Obligation:** project requirement.

Borrow or move when no independent copy is required. Keep a clone when
it expresses needed ownership or simplifies a cold path within budget; explain expensive hot-path copies.
`Arc::clone` shares the allocation and updates a reference count; it does not deep-copy the value.

**Rationale:** A copy changes cost and ownership; both should be intentional.

**Verification design:** Check ownership intent and measure allocation/copy counts in the production workload.
Source: [Performance Book: heap allocations][heap].

**Related pitfalls:** [RPIT-001](rust-common-pitfalls.md#rpit-001), [RPIT-022](rust-common-pitfalls.md#rpit-022),
[RPIT-047](rust-common-pitfalls.md#rpit-047).

#### Local examples

**Contextual Rust example:**

```rust
inspect(payload.as_slice());
```

**Noncompliant fragment or claim (do not copy):**

```rust
inspect(payload.clone().as_slice());
```

---

<a id="rust-010"></a>

### RUST-010: Contain unsafe operations and their invariant boundary

**Class:** SOUNDNESS. **Obligation:** project requirement.

**Profile:** UNSAFE/FFI.

Keep unsafe blocks small enough to audit and use
`#![deny(unsafe_op_in_unsafe_fn)]` in unsafe-owning crates. Use `#![forbid(unsafe_code)]` in safe cores when
feasible. Audit safe constructors, setters, trait implementations and destructors that maintain the unsafe
invariant too. A tiny unsafe block does not compensate for an unchecked safe setter.

**Rationale:** Safe methods can invalidate an unsafe operation even if they contain no unsafe block.

**Verification design:** Enumerate unsafe sites and invariant-maintaining methods. Source: [Fuchsia guidance][fuchsia].

**Related pitfalls:** [RPIT-023](rust-common-pitfalls.md#rpit-023), [RPIT-024](rust-common-pitfalls.md#rpit-024),
[RPIT-044](rust-common-pitfalls.md#rpit-044).

#### Local examples

**Contextual Rust example:**

```rust
pub fn set_len(&mut self, len: usize) -> Result<(), BoundsError> {
    if len > self.initialized {
        return Err(BoundsError);
    }
    self.len = len;
    Ok(())
}
```

**Noncompliant fragment or claim (do not copy):**

```rust
pub fn set_len(&mut self, len: usize) {
    self.len = len; // Used later by unchecked reads.
}
```

---

<a id="rust-011"></a>

### RUST-011: Define FFI types and ABI explicitly

**Class:** PORTABILITY / SOUNDNESS. **Obligation:** project requirement.

**Profile:** FFI.

Use the matching `extern` calling convention and reviewed ABI-safe
fields. Keep `String`, `Vec`, Rust references and trait objects out of a portable C interface. Prefer opaque
handles or explicit pointer/length records with matching destroy functions. `repr(C)` on an outer type does
not repair an incompatible field. Edition 2024 requires unsafe extern blocks and unsafe attributes where
specified, such as `#[unsafe(no_mangle)]`; document symbol uniqueness and link obligations.

**Rationale:** Both sides must agree on representation and call behavior before exchanging a value.

**Verification design:** Compile and run a foreign-language caller on each ABI. Sources: [FFI][ffi], [type
layout][layout].

**Related pitfalls:** [RPIT-012](rust-common-pitfalls.md#rpit-012), [RPIT-013](rust-common-pitfalls.md#rpit-013).

#### Local examples

**Contextual Rust example:**

```rust
#[repr(C)]
pub struct ByteView {
    pub data: *const u8,
    pub len: usize,
}
```

**Noncompliant fragment or claim (do not copy):**

```rust
#[repr(C)]
pub struct ByteView {
    pub bytes: Vec<u8>,
}
```

---

<a id="rust-012"></a>

### RUST-012: Make numeric conversions checked or proven

**Class:** CORRECTNESS / PORTABILITY. **Obligation:** project requirement.

Use `TryFrom` for rejectable narrowing and signedness conversions.
An `as` cast needs a demonstrated range or an explicit bit-level truncation contract. Bound lengths before
conversion to `usize`; `usize` follows the target pointer width and is not a wire-format integer.

**Rationale:** Checking the original value is ineffective if a later cast changes its meaning.

**Verification design:** Test negative values, extrema and targets with different widths. See
[RPIT-007](rust-common-pitfalls.md#rpit-007).

**Related pitfalls:** [RPIT-007](rust-common-pitfalls.md#rpit-007).

#### Local examples

**Contextual Rust example:**

```rust
let count = usize::try_from(wire_count).map_err(|_| DecodeError::Length)?;
```

**Noncompliant fragment or claim (do not copy):**

```rust
let count = wire_count as usize;
```

---

<a id="rust-013"></a>

### RUST-013: Preserve public representation independence

**Class:** ARCHITECTURE. **Obligation:** project requirement.

Keep fields private when constructors maintain invariants. Use accessors or borrowed
views, deliberate `#[non_exhaustive]` enums and sealed traits only when extension policy needs them.
Do not promise stable Rust layout or ABI by exposing implementation types. Review auto traits and generic
bounds as part of API compatibility.

**Rationale:** Private representation lets the owner change implementation while keeping consumer contracts stable.

**Verification design:** Build an external consumer and compare the previous release's API. Source: [Cargo
SemVer][semver].

#### Local examples

**Contextual Rust example:**

```rust
pub struct Buffer {
    bytes: Vec<u8>,
}
```

**Noncompliant fragment or claim (do not copy):**

```rust
pub struct Buffer {
    pub bytes: Vec<u8>, // Callers can bypass the length budget.
}
```

---

<a id="rust-014"></a>

### RUST-014: Justify interior mutability

**Class:** SOUNDNESS / ARCHITECTURE. **Obligation:** project requirement.

Choose `Cell`, `RefCell`, locks or atomics from the sharing contract.
`RefCell` checks borrows at runtime and does not provide cross-thread synchronization. Keep guards short;
use fallible borrow methods when contention is an expected domain condition. A custom `UnsafeCell` wrapper
must establish aliasing and synchronization invariants for its entire API.

**Rationale:** Interior mutability moves enforcement into a runtime or synchronization protocol that needs review.

**Verification design:** Test reentry and overlapping borrow attempts; review why ordinary `&mut` access is
insufficient.

**Related pitfalls:** [RPIT-006](rust-common-pitfalls.md#rpit-006), [RPIT-033](rust-common-pitfalls.md#rpit-033).

#### Local examples

**Contextual Rust example:**

```rust
let mut state = self.state.try_borrow_mut().map_err(|_| Error::Busy)?;
state.update();
```

**Noncompliant fragment or claim (do not copy):**

```rust
let mut state = self.state.borrow_mut();
callback(self); // Can attempt another mutable borrow.
```

---

<a id="rust-015"></a>

### RUST-015: Avoid global mutable state by default

**Class:** ARCHITECTURE / SOUNDNESS. **Obligation:** project requirement.

Pass state through owners. A justified shared singleton needs an
initialization, synchronization, reset and shutdown contract. Prefer an appropriate once-initialization
primitive to manual publication. `static mut` requires a narrow platform/unsafe deviation and an aliasing proof.

**Rationale:** Hidden singleton state couples callers and tests through initialization and mutation order.

**Verification design:** Run isolated and concurrent tests; ensure test order does not establish hidden initialization.

#### Local examples

**Contextual Rust example:**

```rust
pub struct Service {
    config: Config,
}
```

**Noncompliant fragment or claim (do not copy):**

```rust
static mut CONFIG: Option<Config> = None;
```

---

<a id="rust-016"></a>

### RUST-016: Use cohesive functions and idiomatic control flow

**Class:** STYLE / CORRECTNESS. **Obligation:** project requirement.

Keep each function responsible for one transition or computation. Declare locals
near first use, minimize `mut`, and use exhaustive `match` when new enum variants require design work.
Early returns, `?`, `break` and iterator combinators are allowed when effects and cleanup remain visible.
Review functions above complexity 10, measured cognitive complexity 15 or five parameters; name the metric
and counting convention. These are project review thresholds, not compiler limits.

**Rationale:** Short rejection paths reduce nesting while ownership guards retain cleanup responsibilities.

**Verification design:** Trace success, early error and cleanup paths; use a parameter type when arguments form a
real concept.

#### Local examples

**Contextual Rust example:**

```rust
let header = parse_header(input)?;
if header.is_empty() {
    return Err(Error::Empty);
}
process(header)
```

**Noncompliant fragment or claim (do not copy):**

```rust
parse_header(input).ok().map(|header| process(header));
```

---

<a id="rust-017"></a>

### RUST-017: Bound source and API complexity

**Class:** ARCHITECTURE. **Obligation:** project requirement.

Review source files above 1,000 physical lines and dedicated public-contract modules
above 500 lines for cohesion. There is no universal function-line cap. Keep imports explicit outside narrow
preludes and test modules. Split crates when ownership, reuse or build isolation warrants the cost.

**Rationale:** Splitting by responsibility keeps reviewable boundaries without scattering one state machine.

**Verification design:** Record the owner and decision for large modules; reject arbitrary splits that scatter one
invariant.
Context: [rust-analyzer style][ra-style].

#### Local examples

**Contextual Rust example:**

```rust
mod decode;
mod encode;
pub use decode::{DecodeError, Decoder};
```

**Noncompliant fragment or claim (do not copy):**

```rust
pub mod internals;
pub use internals::*;
```

---

<a id="rust-018"></a>

### RUST-018: Enforce newtype and trait invariants

**Class:** CORRECTNESS / SOUNDNESS. **Obligation:** project requirement.

Use newtypes for distinct units and validated domains. Keep construction
checked and fields private; audit derives, `Default`, deserialization and conversion paths. Implement `Eq`,
`Ord` and `Hash` consistently. Safe traits cannot impose hidden memory-safety obligations on implementors;
use an unsafe trait only when its documented contract genuinely requires them.

**Rationale:** A newtype protects a domain only when every creation and mutation path preserves its invariant.

**Verification design:** Exercise every constructor and implementation path, not just `new`.

**Related pitfalls:** [RPIT-024](rust-common-pitfalls.md#rpit-024), [RPIT-032](rust-common-pitfalls.md#rpit-032).

#### Local examples

**Contextual Rust example:**

```rust
pub struct Port(u16);
impl TryFrom<u16> for Port {
    type Error = InvalidPort;
    fn try_from(value: u16) -> Result<Self, Self::Error> {
        if value == 0 {
            return Err(InvalidPort);
        }
        Ok(Self(value))
    }
}
```

**Noncompliant fragment or claim (do not copy):**

```rust
pub struct Port(pub u16); // Supposedly guarantees nonzero values.
```

---

<a id="rust-019"></a>

### RUST-019: Control generics, builders and dynamic dispatch

**Class:** ARCHITECTURE / PERFORMANCE. **Obligation:** project requirement.

Use generics for useful compile-time variation and trait objects for
needed runtime substitution. Prefer concrete internal signatures when polymorphism adds no value. Public
`impl AsRef<_>` can improve ergonomics but creates more instantiations; measure compile time and code size.
Builders suit optional configuration; typestate suits important legal transitions, without encoding every
runtime fact in a type parameter.

**Rationale:** Polymorphism should express actual substitution needs rather than multiply equivalent implementations.

**Verification design:** Review call sites, extension needs and representative builds. Context: [rust-analyzer
style][ra-style].

**Related pitfalls:** [RPIT-022](rust-common-pitfalls.md#rpit-022).

#### Local examples

**Contextual Rust example:**

```rust
fn checksum(bytes: &[u8]) -> u32 {
    checksum_core(bytes)
}
```

**Noncompliant fragment or claim (do not copy):**

```rust
fn checksum<T: AsRef<[u8]> + Clone>(bytes: T) -> u32 {
    checksum_core(bytes.clone().as_ref())
}
```

---

<a id="rust-020"></a>

### RUST-020: Select arithmetic semantics explicitly

**Class:** CORRECTNESS. **Obligation:** project requirement.

Use checked arithmetic for sizes, offsets and counts; use wrapping or saturating
operations only when those semantics belong to the contract. Check zero divisors, signed minimum divided by
minus one and shift counts. Do not depend on debug/release overflow differences. Keep logical and bitwise
operations distinct and validate external enum tags before constructing enum values.

**Rationale:** Overflow semantics are part of the domain and must survive changes of build profile.

**Verification design:** Test overflow boundaries and release behavior; compare arithmetic to an independent model.

**Related pitfalls:** [RPIT-007](rust-common-pitfalls.md#rpit-007), [RPIT-009](rust-common-pitfalls.md#rpit-009),
[RPIT-021](rust-common-pitfalls.md#rpit-021).

#### Local examples

**Contextual Rust example:**

```rust
let bytes = count.checked_mul(item_size).ok_or(Error::Size)?;
```

**Noncompliant fragment or claim (do not copy):**

```rust
let bytes = count * item_size; // Assumes the debug overflow check is sufficient.
```

---

<a id="rust-021"></a>

### RUST-021: Define floating-point behavior

**Class:** CORRECTNESS / PORTABILITY. **Obligation:** project requirement.

State whether NaN, infinities, signed zero and subnormals are accepted.
Specify comparison tolerances, ordering and reproducibility requirements. Do not use floating point for
allocator sizes. Changing reduction order, fused operations or target instructions needs numeric evidence.

**Rationale:** Exceptional floating-point values and reordering can change decisions without causing a memory error.

**Verification design:** Include exceptional values and cancellation-sensitive inputs; record compiler and target flags.

#### Local examples

**Contextual Rust example:**

```rust
if !sample.is_finite() {
    return Err(Error::NonFinite);
}
```

**Noncompliant fragment or claim (do not copy):**

```rust
if sample == f64::NAN {
    return Err(Error::NonFinite);
}
```

---

<a id="rust-022"></a>

### RUST-022: Separate text, bytes and filesystem paths

**Class:** CORRECTNESS / SECURITY. **Obligation:** project requirement.

Use `&[u8]` for arbitrary bytes, `&str` for validated UTF-8 and `Path`/`OsStr`
for platform paths. String indices are byte offsets and must lie on character boundaries. Define normalization
and case rules at the protocol owner; do not silently replace invalid bytes when identity matters.

**Rationale:** Encoding and path identity need explicit types at the boundary.

**Verification design:** Test multibyte text, embedded NUL, invalid UTF-8 and non-Unicode paths where the OS
supports them.

#### Local examples

**Contextual Rust example:**

```rust
let text = std::str::from_utf8(bytes).map_err(Error::Encoding)?;
```

**Noncompliant fragment or claim (do not copy):**

```rust
let text = String::from_utf8_lossy(bytes); // Used as a unique identity.
```

---

<a id="rust-023"></a>

### RUST-023: Serialize fields through an explicit format

**Class:** PORTABILITY / SECURITY. **Obligation:** project requirement.

Specify length limits, endianness, version, tags and error handling.
Do not serialize a Rust object by reading its raw bytes: padding, pointers and layout are not a protocol.
Decode unaligned input from bytes or reviewed unaligned operations without creating an invalid reference.

**Rationale:** Object storage can contain layout details and uninitialized padding that do not belong on the wire.

**Verification design:** Use golden vectors, truncated input and cross-endian models. Source: [type layout][layout].

**Related pitfalls:** [RPIT-012](rust-common-pitfalls.md#rpit-012), [RPIT-030](rust-common-pitfalls.md#rpit-030).

#### Local examples

**Contextual Rust example:**

```rust
let encoded = counter.to_le_bytes();
```

**Noncompliant fragment or claim (do not copy):**

```rust
let encoded: [u8; 8] = unsafe { std::mem::transmute(record) };
```

---

<a id="rust-024"></a>

### RUST-024: Preserve allocation and allocator contracts

**Class:** SOUNDNESS. **Obligation:** project requirement.

**Profile:** ALLOC/UNSAFE.

Check `Layout` construction, size arithmetic, alignment and zero-size policy.
Pair allocation and deallocation APIs, including layout and allocator identity. Reallocation invalidates
old locations according to its API contract. `Box::from_raw` and `Vec::from_raw_parts` require their exact
ownership and allocation contracts; a pointer obtained from another allocator is not sufficient.

**Rationale:** Raw allocation APIs erase ownership information that must be recovered from the exact producer contract.

**Verification design:** Test failure, growth, zero-sized types and cross-boundary destruction.

**Related pitfalls:** [RPIT-026](rust-common-pitfalls.md#rpit-026), [RPIT-027](rust-common-pitfalls.md#rpit-027).

#### Local examples

**Contextual Rust example:**

```rust
let layout = std::alloc::Layout::array::<Entry>(count).map_err(Error::Layout)?;
```

**Noncompliant fragment or claim (do not copy):**

```rust
let bytes = count * std::mem::size_of::<Entry>();
```

---

<a id="rust-025"></a>

### RUST-025: Make fallible growth meaningful

**Class:** CORRECTNESS / SECURITY. **Obligation:** project requirement.

**Profile:** ALLOC.

Enforce byte and element budgets before growth. Use `try_reserve` or
an approved fallible container where exhaustion must become `Result`. A fallible outer operation cannot
promise complete OOM recovery if formatting, error construction or another dependency allocates infallibly.
No-allocation profiles cover hidden paths, logging and destructors as well as the main loop.

**Rationale:** An error-returning signature does not make every operation inside it fallible on allocation failure.

**Verification design:** Inject allocation failures without invoking UB; check unchanged state and allocation counts.

**Related pitfalls:** [RPIT-002](rust-common-pitfalls.md#rpit-002), [RPIT-022](rust-common-pitfalls.md#rpit-022),
[RPIT-025](rust-common-pitfalls.md#rpit-025), [RPIT-040](rust-common-pitfalls.md#rpit-040).

#### Local examples

**Contextual Rust example:**

```rust
buffer
    .try_reserve(payload.len())
    .map_err(Error::Allocation)?;
buffer.extend_from_slice(payload);
```

**Noncompliant fragment or claim (do not copy):**

```rust
buffer.extend_from_slice(payload);
Ok(()) // Claimed to recover from allocation failure.
```

---

<a id="rust-026"></a>

### RUST-026: Keep destruction safe and expose fallible finalization

**Class:** SOUNDNESS / CORRECTNESS. **Obligation:** project requirement.

`Drop` performs best-effort nonpanicking cleanup; expose `finish`, `flush`
or `close` when callers need a recoverable completion error. Specify ownership after a failed finalization.
Do not make memory safety depend on destructors running: safe callers may use `mem::forget`, and abort or
process termination can bypass cleanup. Avoid double release during partial construction or unwinding.

**Rationale:** Destruction can be skipped, and fallible external completion needs an observable result.

**Verification design:** Test partial initialization, repeated logical close and primary-error preservation.

**Related pitfalls:** [RPIT-005](rust-common-pitfalls.md#rpit-005), [RPIT-016](rust-common-pitfalls.md#rpit-016),
[RPIT-029](rust-common-pitfalls.md#rpit-029), [RPIT-048](rust-common-pitfalls.md#rpit-048).

#### Local examples

**Contextual Rust example:**

```rust
writer.finish()?; // Explicitly observes durable-completion errors.
```

**Noncompliant fragment or claim (do not copy):**

```rust
drop(writer); // Assumes Drop reported every flush failure.
```

---

<a id="rust-027"></a>

### RUST-027: Bound recursion, stack and retained work

**Class:** CORRECTNESS. **Obligation:** project requirement.

**Profile:** stricter REALTIME/CRITICAL.

Bound input nesting, recursion depth, queue size, retries,
retained diagnostics and task counts. Large arrays and recursive destructors can exhaust a thread stack.
Async futures retain locals across suspension and may become large even before execution.

**Rationale:** Bounds on admitted work need to include stack growth and retained asynchronous state.

**Verification design:** Measure configured thread stacks/future sizes, test maximum admitted work and inspect
failure paths.

**Related pitfalls:** [RPIT-025](rust-common-pitfalls.md#rpit-025).

#### Local examples

**Contextual Rust example:**

```rust
if depth >= limits.max_depth {
    return Err(ParseError::Depth);
}
```

**Noncompliant fragment or claim (do not copy):**

```rust
parse_nested(input, depth + 1)?; // No nesting limit.
```

---

<a id="rust-028"></a>

### RUST-028: Preserve pointer provenance and aliasing

**Class:** SOUNDNESS. **Obligation:** project requirement.

**Profile:** UNSAFE.

Preserve allocation origin when deriving pointers. Use pointer APIs whose
contracts match the operation; an address integer alone does not demonstrate access rights. Keep arithmetic
inside the required allocation and range, and avoid dereferencing one-past-end pointers. Shared references
restrict mutation except through appropriate interior mutability. Recheck validity after calls that can
reallocate, release or reenter.

**Rationale:** Pointer derivation must preserve the allocation and access rights required by the operation.

**Verification design:** Review derivation and lifetime chains; exercise the abstraction under Miri. Source:
[pointer APIs][ptr].

**Related pitfalls:** [RPIT-008](rust-common-pitfalls.md#rpit-008), [RPIT-026](rust-common-pitfalls.md#rpit-026).

#### Local examples

**Contextual Rust example:**

```rust
let view = bytes.get(offset..end).ok_or(Error::Bounds)?;
```

**Noncompliant fragment or claim (do not copy):**

```rust
let ptr = saved_address as *const Entry;
let entry = unsafe { &*ptr }; // No retained allocation.
```

---

<a id="rust-029"></a>

### RUST-029: Establish references only after their full contract holds

**Class:** SOUNDNESS. **Obligation:** project requirement.

**Profile:** UNSAFE/FFI.

Before creating a reference or slice, establish non-nullness, alignment,
initialized extent, a live allocation and legal aliasing for the whole lifetime. `NonNull` rules out zero;
it does not prove those other properties. For an FFI convention permitting `(null, 0)`, handle zero length
before calling `slice::from_raw_parts`. A null check cannot validate an arbitrary foreign address.

**Rationale:** Constructing a reference already asserts its validity; validation after construction is too late.

**Verification design:** Test only inputs permitted by the unsafe contract; use safe boundary checks for rejectable
values.
Sources: [raw slices][raw-slice], [NonNull][nonnull].

**Related pitfalls:** [RPIT-011](rust-common-pitfalls.md#rpit-011), [RPIT-024](rust-common-pitfalls.md#rpit-024),
[RPIT-028](rust-common-pitfalls.md#rpit-028), [RPIT-030](rust-common-pitfalls.md#rpit-030).

#### Local examples

**Contextual Rust example:**

```rust
if len == 0 {
    return Ok(&[]);
}
// Nonempty input continues through the documented unsafe contract.
```

**Noncompliant fragment or claim (do not copy):**

```rust
let bytes = unsafe { std::slice::from_raw_parts(ptr, len) };
if ptr.is_null() { return Err(Error::Null); }
```

---

<a id="rust-030"></a>

### RUST-030: Track initialization with MaybeUninit

**Class:** SOUNDNESS. **Obligation:** project requirement.

**Profile:** UNSAFE.

Use `MaybeUninit<T>` for storage that may not yet contain a valid `T`.
Do not create `&T`, read a value or call `assume_init` before proving full initialization. For partial arrays,
track the initialized prefix and drop exactly those elements on error. A zero byte pattern is not valid for
all types. Keep `ManuallyDrop` and union active-member state under the same owner.

**Rationale:** Initialization tracking prevents both premature reads and incorrect cleanup of partial objects.

**Verification design:** Inject a failure after each initialization step and count drops. Source: [MaybeUninit][uninit].

**Related pitfalls:** [RPIT-010](rust-common-pitfalls.md#rpit-010), [RPIT-029](rust-common-pitfalls.md#rpit-029).

#### Local examples

**Contextual Rust example:**

```rust
let mut slot = std::mem::MaybeUninit::<String>::uninit();
slot.write(String::from("ready"));
```

**Noncompliant fragment or claim (do not copy):**

```rust
let value: String = unsafe { std::mem::zeroed() };
```

---

<a id="rust-031"></a>

### RUST-031: Prefer typed conversions over transmute

**Class:** SOUNDNESS. **Obligation:** project requirement.

Use constructors, byte conversion functions and checked casts first. A justified
`transmute` needs size, validity, lifetime, provenance and representation proofs; equal size alone is
insufficient. Do not read uninitialized padding or extend a borrow's lifetime to evade the checker.
Union reads need proof that the chosen field's value is valid.

**Rationale:** A byte-size coincidence does not establish the destination type validity or its lifetime.

**Verification design:** Enumerate legal bit patterns and target assumptions; review the safe alternative explicitly.

**Related pitfalls:** [RPIT-009](rust-common-pitfalls.md#rpit-009).

#### Local examples

**Contextual Rust example:**

```rust
let code = Code::try_from(raw_code)?;
```

**Noncompliant fragment or claim (do not copy):**

```rust
let code: Code = unsafe { std::mem::transmute(raw_code) };
```

---

<a id="rust-032"></a>

### RUST-032: Maintain pinning through projection and destruction

**Class:** SOUNDNESS. **Obligation:** project requirement.

**Profile:** UNSAFE/ASYNC.

`Pin` constrains movement of pinned pointees according to `Unpin` and the
abstraction's contract; it does not freeze arbitrary data. Review structural pinning, projections, replacement,
`Drop` and any manual `Unpin` implementation together. Prefer reviewed projection mechanisms to unchecked
projection code. Self-references need an actual storage and lifetime design.

**Rationale:** Pinning obligations extend to field access and destruction, not just initial construction.

**Verification design:** Inspect every path that can move or invalidate pinned fields. Source: [Pin][pin].

**Related pitfalls:** [RPIT-017](rust-common-pitfalls.md#rpit-017).

#### Local examples

**Contextual Rust example:**

```rust
let future = Box::pin(operation());
```

**Noncompliant fragment or claim (do not copy):**

```rust
let moved = unsafe { std::ptr::read(pinned.as_ref().get_ref()) };
```

---

<a id="rust-033"></a>

### RUST-033: Prove manual Send and Sync implementations

**Class:** SOUNDNESS. **Obligation:** project requirement.

**Profile:** UNSAFE.

`Send` concerns ownership transfer between threads; `Sync` concerns sharing
references between threads. A raw pointer field and a mutex elsewhere do not automatically justify either.
Account for thread-affine resources, destructors, callbacks, generic bounds and reachable interior state.

**Rationale:** Transfer and sharing proofs must account for the resource and its destructor, not only the wrapper
fields.

**Verification design:** State the proof beside each unsafe impl and test concurrent lifecycle behavior.
Source: [Send and Sync][send-sync].

**Related pitfalls:** [RPIT-015](rust-common-pitfalls.md#rpit-015), [RPIT-033](rust-common-pitfalls.md#rpit-033).

#### Local examples

**Contextual review example:**

```text
// Keep a thread-affine handle in its owning thread; send request values
// through a bounded channel to that owner.
```

**Noncompliant fragment or claim (do not copy):**

```rust
unsafe impl Send for ThreadAffineHandle {}
```

---

<a id="rust-034"></a>

### RUST-034: Specify FFI transfer and callback lifetime

**Class:** SOUNDNESS. **Obligation:** project requirement.

**Profile:** FFI.

Document whether each argument is borrowed, consumed or retained, on both success
and failure. Pair returned owners with the matching release operation. Callback contracts include calling
thread, retention, reentry, errors and shutdown. Unregister and drain in-flight callbacks before freeing
context; keeping an `Arc` somewhere does not prove the native callback retains it correctly.

**Rationale:** Native retention must keep the right context alive through the last possible callback.

**Verification design:** Test acquisition failures, callback races and teardown with a native harness. Source:
[FFI][ffi].

**Related pitfalls:** [RPIT-027](rust-common-pitfalls.md#rpit-027).

#### Local examples

**Contextual Rust example:**

```rust
registration.stop_new_calls();
registration.unregister()?;
registration.drain()?;
drop(context);
```

**Noncompliant fragment or claim (do not copy):**

```rust
drop(context);
registration.unregister()?;
```

---

<a id="rust-035"></a>

### RUST-035: Control unwinding across foreign boundaries

**Class:** SOUNDNESS / CORRECTNESS. **Obligation:** project requirement.

**Profile:** FFI.

Select a non-unwinding ABI or a deliberately supported unwind ABI.
Prevent Rust panics escaping boundaries whose contract forbids them; `catch_unwind` catches unwinding panics,
not aborts, arbitrary foreign exceptions or memory corruption. Do not use it to resume a broken invariant.
Foreign `longjmp` must not bypass Rust frames that require destruction.

**Rationale:** The unwind policy must describe what the actual compiled binary does at the foreign boundary.

**Verification design:** Test the chosen panic strategy in a subprocess and document failure mapping. Source:
[FFI][ffi].

**Related pitfalls:** [RPIT-014](rust-common-pitfalls.md#rpit-014).

#### Local examples

**Contextual Rust example:**

```rust
match operation() {
    Ok(value) => encode_success(value),
    Err(error) => encode_error(error),
}
```

**Noncompliant fragment or claim (do not copy):**

```rust
extern "C" fn entry() {
    panic!("recoverable request failure");
}
```

---

<a id="rust-036"></a>

### RUST-036: Define lock order and poisoning behavior

**Class:** CORRECTNESS. **Obligation:** project requirement.

**Profile:** HOSTED/ASYNC.

Name a lock order, keep critical sections bounded and avoid calling unknown
code while holding a lock. Treat poisoning as a signal to inspect protected invariants; neither ignoring nor
unconditionally panicking on it is a universal recovery policy. Poisoning is advisory and cannot underpin
unsafe soundness. Condition-variable waits recheck a predicate in a loop.

**Rationale:** Lock order and reentry determine progress; memory-safe locking can still deadlock.

**Verification design:** Test reentry, opposite acquisition orders and panics during mutation. Source: [Mutex][mutex].

**Related pitfalls:** [RPIT-004](rust-common-pitfalls.md#rpit-004), [RPIT-019](rust-common-pitfalls.md#rpit-019).

#### Local examples

**Contextual Rust example:**

```rust
{
    let mut state = self.state.lock().map_err(Error::Poisoned)?;
    state.prepare();
}
callback();
```

**Noncompliant fragment or claim (do not copy):**

```rust
let mut state = self.state.lock().unwrap();
callback(); // May try to lock self.state again.
```

---

<a id="rust-037"></a>

### RUST-037: Keep blocking guards out of suspension

**Class:** CORRECTNESS. **Obligation:** project requirement.

**Profile:** ASYNC.

Release blocking mutex guards before `.await`, preferably with a lexical scope
that produces owned work. If an async mutex must span suspension, document why exclusive access must persist,
which operations can wait and how cancellation restores state. Do not choose a mutex solely to satisfy a
`Send` error. Move blocking I/O or CPU work to an appropriate bounded execution facility.

**Rationale:** Suspension can prevent the task needed to release a blocking lock from being scheduled.

**Verification design:** Test on a constrained executor with competing tasks. Source: [Tokio shared state][tokio-state].

**Related pitfalls:** [RPIT-003](rust-common-pitfalls.md#rpit-003).

#### Local examples

**Contextual Rust example:**

```rust
let request = {
    let state = shared.lock().map_err(Error::Poisoned)?;
    state.make_request()
};
send(request).await?;
```

**Noncompliant fragment or claim (do not copy):**

```rust
let state = shared.lock().unwrap();
send(state.request()).await?;
```

---

<a id="rust-038"></a>

### RUST-038: Make cancellation a state transition

**Class:** CORRECTNESS. **Obligation:** project requirement.

**Profile:** ASYNC.

Dropping a future can stop it between suspension points. Define partial progress,
resource ownership and retry behavior for each such point. In `select!`-style races, verify cancellation safety
of each operation; losing a race can discard an in-progress read or write. Keep progress in an owner that
survives cancellation when needed. `Drop` cannot perform ordinary awaited cleanup.

**Rationale:** Cancellation is an observable exit and may leave external progress behind.

**Verification design:** Cancel at each suspension boundary and inspect persisted effects. Source: [Tokio
select][tokio-select].

**Related pitfalls:** [RPIT-018](rust-common-pitfalls.md#rpit-018).

#### Local examples

**Contextual Rust example:**

```rust
state.sent += write_some(&payload[state.sent..]).await?;
```

**Noncompliant fragment or claim (do not copy):**

```rust
write_all(payload).await?; // Retry policy assumes an error means zero bytes sent.
```

---

<a id="rust-039"></a>

### RUST-039: Supervise threads, tasks and channels

**Class:** CORRECTNESS / ARCHITECTURE. **Obligation:** project requirement.

The creator owns completion or transfers supervision explicitly.
Specify stop, drain, join and error collection; dropping a task handle is not universally task cancellation.
Bound channels and define full, closed and slow-consumer behavior. Prevent strong-reference cycles between
workers, callbacks and owners; use `Weak` or an explicit breakable ownership edge when appropriate.

**Rationale:** An unobserved worker can outlive the state and shutdown assumptions of its creator.

**Verification design:** Test receiver loss, worker panic, full queues and shutdown with active users.

**Related pitfalls:** [RPIT-005](rust-common-pitfalls.md#rpit-005).

#### Local examples

**Contextual Rust example:**

```rust
stop.send(()).map_err(Error::Stop)?;
worker.join().map_err(Error::Worker)?;
```

**Noncompliant fragment or claim (do not copy):**

```rust
std::thread::spawn(move || use_resource(resource)); // No lifecycle owner.
```

---

<a id="rust-040"></a>

### RUST-040: Hide atomics behind a proved protocol

**Class:** SOUNDNESS / CORRECTNESS. **Obligation:** project requirement.

**Profile:** UNSAFE/concurrent profiles.

Describe publication, observation and reclamation
as one protocol. Justify each ordering and the read-modify-write success/failure pair. `Relaxed` can suit an
independent counter, but does not publish unrelated data. `SeqCst` does not repair a lifetime or logical race.
Use the weakest ordering established by the proof, not the weakest ordering that passed a stress run.

**Rationale:** Atomicity of one field does not publish the other state or keep its allocation alive.

**Verification design:** Model interleavings and run stress tests on relevant architectures. Sources: [atomic
ordering][ordering],
[Atomics and Locks: memory ordering][memory-order].

**Related pitfalls:** [RPIT-020](rust-common-pitfalls.md#rpit-020), [RPIT-033](rust-common-pitfalls.md#rpit-033).

#### Local examples

**Contextual Rust example:**

```rust
// The payload owner and access protocol establish non-atomic validity.
ready.store(true, std::sync::atomic::Ordering::Release);
```

**Noncompliant fragment or claim (do not copy):**

```rust
ready.store(true, std::sync::atomic::Ordering::Relaxed); // Publishes payload.
```

---

<a id="rust-041"></a>

### RUST-041: Separate synchronization from reclamation

**Class:** SOUNDNESS. **Obligation:** project requirement.

**Profile:** UNSAFE/concurrent profiles.

A pointer load does not keep its allocation alive. Use a
reviewed retention, epoch, hazard-pointer or ownership-transfer protocol for shared objects. Address reuse
can cause ABA. One-time initialization must publish the complete value before readers observe readiness.
Define whether retries are bounded and whether the operation is lock-free, wait-free or merely nonblocking.

**Rationale:** Reclamation must wait for permitted readers, including those between acquisition steps.

**Verification design:** Model destruction concurrent with acquisition and test allocator reuse; state the progress
guarantee.

**Related pitfalls:** [RPIT-008](rust-common-pitfalls.md#rpit-008), [RPIT-020](rust-common-pitfalls.md#rpit-020),
[RPIT-034](rust-common-pitfalls.md#rpit-034).

#### Local examples

**Contextual Rust example:**

```rust
let retained = registry.acquire(id)?;
inspect(retained.as_ref());
```

**Noncompliant fragment or claim (do not copy):**

```rust
let ptr = shared.load(Ordering::Acquire);
unsafe { inspect(&*ptr) }; // Another thread may free the pointee.
```

---

<a id="rust-042"></a>

### RUST-042: Confine MMIO, DMA and assembly to hardware owners

**Class:** SOUNDNESS / PORTABILITY. **Obligation:** project requirement.

**Profile:** DEVICE.

Use volatile access only under the peripheral's register contract;
it is not thread synchronization. Account for read-clear/write-one-to-clear bits, access width, alignment,
barriers and reserved bits. DMA needs an ownership handoff and target-specific cache maintenance. Assembly
must declare operands, clobbers, memory/stack effects and supported targets.

**Rationale:** Devices and assembly obey machine contracts outside ordinary borrow checking.

**Verification design:** Review device documentation, generated instructions and hardware tests. Source: [volatile
reads][volatile].

#### Local examples

**Contextual Rust example:**

```rust
// Device-specific adapter owns access width, barriers and register semantics.
device.acknowledge_interrupt(pending);
```

**Noncompliant fragment or claim (do not copy):**

```rust
*register_ptr = pending; // Assumes ordinary memory semantics for MMIO.
```

---

<a id="rust-043"></a>

### RUST-043: Make no_std and real-time limits explicit

**Class:** PORTABILITY / CORRECTNESS. **Obligation:** project requirement.

**Profile:** CORE/REALTIME.

`no_std` removes the implicit standard-library dependency;
it does not prove absence of allocation, locks or panics. Separate optional `alloc` support. State panic and
interrupt policies, stack and WCET assumptions, target atomic support, blocking bounds and priority inversion
controls. A watchdog update follows verified progress, not unconditional loop execution.

**Rationale:** A core profile needs explicit resource and termination limits beyond absence of std.

**Verification design:** Build without default features for the real target; retain stack, timing and hardware evidence.
Context: [Embedded Rust Book][embedded].

**Related pitfalls:** [RPIT-040](rust-common-pitfalls.md#rpit-040).

#### Local examples

**Contextual Rust example:**

```rust
#![no_std]
// Dependencies and target build separately establish the no-allocation profile.
```

**Noncompliant fragment or claim (do not copy):**

```rust
#![no_std]
extern crate alloc; // Claimed as proof that this crate cannot allocate.
```

---

<a id="rust-044"></a>

### RUST-044: Keep OS-global effects at an application boundary

**Class:** SECURITY / ARCHITECTURE. **Obligation:** project requirement.

**Profile:** HOSTED.

Libraries do not own process exit, current directory, environment
mutation, standard streams, signal policy or process-wide hooks. An adapter must justify inherited descriptors
and handles. After fork in a multithreaded process, use only operations permitted by the platform until exec;
Rust abstractions may hide locks or allocations. Signal handlers need their own restricted call contract.

**Rationale:** Process-global changes alter unrelated callers and cannot be scoped by a library object.

**Verification design:** Inspect global effects and child-process inheritance with platform integration tests.

#### Local examples

**Contextual Rust example:**

```rust
let child = std::process::Command::new(program)
    .current_dir(directory)
    .spawn()?;
```

**Noncompliant fragment or claim (do not copy):**

```rust
std::env::set_current_dir(directory)?; // Hidden library-wide process effect.
```

---

<a id="rust-045"></a>

### RUST-045: Validate before publishing effects

**Class:** CORRECTNESS / SECURITY. **Obligation:** project requirement.

Validate type/domain, length, authority and capacity before externally visible
mutation. Construct a candidate value, then commit it when possible. If partial effects are unavoidable,
document progress and compensation; `Result::Err` does not imply rollback. No unsafe invariant may depend
on a validation step that occurs after the unsafe operation.

**Rationale:** A rejected operation must leave the state specified by its error contract.

**Verification design:** Inject failures at each stage and assert the exact post-failure state.

**Related pitfalls:** [RPIT-035](rust-common-pitfalls.md#rpit-035).

#### Local examples

**Contextual Rust example:**

```rust
let candidate = validate_and_prepare(input)?;
self.state = candidate;
```

**Noncompliant fragment or claim (do not copy):**

```rust
self.state.clear();
validate(input)?; // Failure has already destroyed prior state.
```

---

<a id="rust-046"></a>

### RUST-046: Handle partial I/O and durable completion

**Class:** CORRECTNESS. **Obligation:** project requirement.

**Profile:** HOSTED.

Define short-read/write, EOF, interrupted operation and retry behavior.
Use `read_exact`/`write_all` only when their completion contract fits; errors may follow partial external
progress. Buffer flush is distinct from durable storage. Multi-write persistence needs a crash-consistency
protocol, synchronization and recovery rules owned by the platform adapter.

**Rationale:** I/O completion, partial progress and durability are different observable contracts.

**Verification design:** Use short-I/O and interruption adapters, plus crash/restart tests for durability claims.
Source: [Write API][write].

**Related pitfalls:** [RPIT-018](rust-common-pitfalls.md#rpit-018), [RPIT-035](rust-common-pitfalls.md#rpit-035),
[RPIT-036](rust-common-pitfalls.md#rpit-036).

#### Local examples

**Contextual Rust example:**

```rust
writer.write_all(payload)?;
writer.flush()?; // Durability requires the separate platform contract.
```

**Noncompliant fragment or claim (do not copy):**

```rust
let _ = writer.write(payload)?; // Assumes all bytes were accepted.
```

---

<a id="rust-047"></a>

### RUST-047: Use explicit time and randomness contracts

**Class:** CORRECTNESS / SECURITY. **Obligation:** project requirement.

Use a monotonic time domain for elapsed time and deadlines; wall time is for
calendar meaning. Record overflow, suspend and cross-process limitations of the clock. Bound retries with a
budget and cancellation. Use an approved cryptographic randomness source for security material and handle
entropy failure; deterministic test seeds belong in the test record.

**Rationale:** Elapsed deadlines and security entropy cannot inherit wall-clock or test-seed assumptions.

**Verification design:** Inject clock movement, deadline exhaustion and unavailable randomness.

#### Local examples

**Contextual Rust example:**

```rust
let deadline = std::time::Instant::now()
    .checked_add(timeout)
    .ok_or(Error::Time)?;
```

**Noncompliant fragment or claim (do not copy):**

```rust
let elapsed = SystemTime::now().duration_since(start).unwrap();
```

---

<a id="rust-048"></a>

### RUST-048: Preserve authority at external interpreters and paths

**Class:** SECURITY. **Obligation:** project requirement.

**Profile:** HOSTED.

Pass process arguments through an argv API and account for option injection;
avoid shell interpolation of external input. Use parameterized downstream queries. A normalized path or
string prefix is not an authorization proof against symlinks, races or platform path rules. Keep file-open
and authority checks in a capability-aware adapter.

**Rationale:** Downstream interpreters and path resolution can grant authority beyond the validated string.

**Verification design:** Test boundary-specific adversarial inputs, path replacement and argument boundaries.

**Related pitfalls:** [RPIT-037](rust-common-pitfalls.md#rpit-037).

#### Local examples

**Contextual Rust example:**

```rust
Command::new(tool).arg("--").arg(user_path).status()?;
```

**Noncompliant fragment or claim (do not copy):**

```rust
Command::new("sh").arg("-c").arg(format!("tool {user_path}")).status()?;
```

---

<a id="rust-049"></a>

### RUST-049: Bound structured input and outbound requests

**Class:** SECURITY. **Obligation:** project requirement.

Limit bytes, nesting, decompression expansion, collection sizes, parse effort and
concurrent requests. Enforce authentication and authorization before privileged effects and fail closed
when a required decision is unavailable. For outbound requests, validate the effective destination including
redirects and address resolution under the deployment policy.

**Rationale:** Memory-safe parsing still needs admission limits and authorization before privileged effects.

**Verification design:** Test oversized/deep input, denied authority, redirects and resource exhaustion without
unbounded tests.
Context: [ANSSI guide][anssi].

**Related pitfalls:** [RPIT-025](rust-common-pitfalls.md#rpit-025).

#### Local examples

**Contextual Rust example:**

```rust
authorization.require_write(&identity, &target)?;
limits.check_bytes(payload.len())?;
store.write(target, payload)?;
```

**Noncompliant fragment or claim (do not copy):**

```rust
store.write(target, payload)?;
authorization.require_write(&identity, &target)?;
```

---

<a id="rust-050"></a>

### RUST-050: Assign secrets and fault resistance to dedicated primitives

**Class:** SECURITY. **Obligation:** project requirement.

**Profile:** stricter CRITICAL.

Redact sensitive data in logs, formatting and errors. Ordinary equality
and ordinary clearing are not constant-time comparison or guaranteed secure erasure. Use reviewed primitives
and account for copies, allocator retention and crash dumps. If the threat model includes fault injection,
define encoded states, redundant checks and critical side-effect ordering with machine-level evidence.

**Rationale:** Formatting and generated machine behavior can violate confidentiality despite correct ordinary outputs.

**Verification design:** Test redaction and inspect compiled behavior required by the threat model; do not infer
resistance
from duplicated source checks.

**Related pitfalls:** [RPIT-038](rust-common-pitfalls.md#rpit-038).

#### Local examples

**Contextual Rust example:**

```rust
formatter.write_str("Secret([redacted])")
```

**Noncompliant fragment or claim (do not copy):**

```rust
write!(formatter, "Secret({})", self.value)
```

---

<a id="rust-051"></a>

### RUST-051: Keep loading and plugins under a trust policy

**Class:** SECURITY / PORTABILITY. **Obligation:** project requirement.

**Profile:** HOSTED/FFI.

Resolve native libraries and plugins through controlled paths
and provenance checks. A Rust shared library is not a stable plugin ABI by default. Use a versioned boundary,
validate capabilities and drain users before unloading code. In-process unsafe plugins share process authority;
use a process boundary when the trust model requires isolation.

**Rationale:** A valid symbol address does not prove plugin trust, ABI agreement or safe unload timing.

**Verification design:** Test wrong versions, missing symbols, search-path substitution and unload with outstanding
callbacks.

**Related pitfalls:** [RPIT-049](rust-common-pitfalls.md#rpit-049).

#### Local examples

**Contextual Rust example:**

```rust
let plugin = trusted_loader.load_verified(manifest)?;
```

**Noncompliant fragment or claim (do not copy):**

```rust
let plugin = load_library(user_supplied_path)?;
```

---

<a id="rust-052"></a>

### RUST-052: Review macros and compile-time execution

**Class:** CORRECTNESS / SECURITY. **Obligation:** project requirement.

Prefer functions and types for ordinary behavior. Macros need explicit
argument evaluation, hygiene, error and generated-API contracts; expression arguments must not gain surprising
repeated effects. Procedural macros and build scripts execute with build-host authority.

**Rationale:** Macro expansion and build-time execution can hide repeated effects and privileged dependencies.

**Verification design:** Inspect representative expansions, test diagnostics and review
filesystem/network/environment access.

**Related pitfalls:** [RPIT-041](rust-common-pitfalls.md#rpit-041).

#### Local examples

**Contextual Rust example:**

```rust
let value = read_once()?;
checked_operation(value)?;
```

**Noncompliant fragment or claim (do not copy):**

```rust
repeat_argument!(read_once()?); // Expansion evaluates the expression twice.
```

---

<a id="rust-053"></a>

### RUST-053: Make features additive and configurations explicit

**Class:** PORTABILITY. **Obligation:** project requirement.

Prefer features that add capabilities without removing another consumer's behavior.
Cargo feature unification means one dependency can enable features for another. Keep mutually exclusive
backends in explicit supported configurations and diagnose invalid combinations. `cfg!` does not remove a
branch from type checking; use `#[cfg]` for code unavailable on a target.

**Rationale:** Feature availability depends on resolution across consumers and on absent configurations.

**Verification design:** Test default, no-default, individual and supported combined features. Source: [Cargo
features][features].

**Related pitfalls:** [RPIT-039](rust-common-pitfalls.md#rpit-039), [RPIT-043](rust-common-pitfalls.md#rpit-043).

#### Local examples

**Contextual Rust example:**

```rust
#[cfg(target_os = "linux")]
mod linux;
```

**Noncompliant fragment or claim (do not copy):**

```rust
if cfg!(target_os = "linux") {
    linux_only_call(); // Still type-checked on other targets.
}
```

---

<a id="rust-054"></a>

### RUST-054: Own dependencies, generated code and imported sources

**Class:** SECURITY / VERIFICATION. **Obligation:** project requirement.

Review direct and transitive dependencies, native components, licenses,
source registries and build-time execution. Lock reproducible CI/release resolution and record advisory-database
identity. Generated bindings need generator version, inputs, target flags and reproducible output; keep local
patches to upstream imports traceable. Do not hand-edit generated files as the long-term fix.

**Rationale:** The release build depends on source identity and executable build inputs, not just a crate name.

**Verification design:** Rebuild from controlled inputs and inspect dependency/source changes. Sources:
[RustSec][rustsec],
[cargo-deny][deny], [Microsoft project guidance][ms-project].

**Related pitfalls:** [RPIT-041](rust-common-pitfalls.md#rpit-041).

#### Local examples

**Contextual review example:**

```text
// Record Cargo.lock, source registry, native inputs and generator revision
// alongside the release artifact digest.
```

**Noncompliant fragment or claim (do not copy):**

```rust
// Install whichever dependency and generator versions are newest at build time.
```

---

<a id="rust-055"></a>

### RUST-055: Evolve APIs and MSRV deliberately

**Class:** ARCHITECTURE / PORTABILITY. **Obligation:** project requirement.

Define deprecation, feature and MSRV policy. Review public traits,
blanket impls, auto traits, error variants, lifetimes, `impl Trait` captures and macro expansions for downstream
impact. Use semantic-version checks as evidence and maintain representative consumer tests.

**Rationale:** Public bounds, traits and features constrain downstream source even when private code is unchanged.

**Verification design:** Compare a released baseline with each supported feature set and inspect behavior changes
separately.
Source: [Cargo SemVer][semver].

**Related pitfalls:** [RPIT-039](rust-common-pitfalls.md#rpit-039), [RPIT-042](rust-common-pitfalls.md#rpit-042).

#### Local examples

**Contextual Rust example:**

```rust
#[non_exhaustive]
pub enum Error {
    InvalidInput,
    Unavailable,
}
```

**Noncompliant fragment or claim (do not copy):**

```rust
// Add a required method to a publicly implementable trait in a patch release.
```

---

<a id="rust-056"></a>

### RUST-056: Keep unsafe allocator implementations non-reentrant

**Class:** SOUNDNESS. **Obligation:** project requirement.

**Profile:** allocator profile.

Allocator entry points must obey their allocation API, including
alignment and failure results. `GlobalAlloc` implementations must not unwind. Avoid recursive allocation
through logging, synchronization or lazy initialization inside allocator operations. Do not make program
correctness depend on observing allocations that the optimizer may eliminate.

**Rationale:** Allocator entry points can reenter themselves through code that appears unrelated to allocation.

**Verification design:** Test recursion guards, failure paths, deallocation pairing and representative optimized
clients.
Source: [GlobalAlloc][global-alloc].

**Related pitfalls:** [RPIT-002](rust-common-pitfalls.md#rpit-002), [RPIT-046](rust-common-pitfalls.md#rpit-046).

#### Local examples

**Contextual review example:**

```text
// Update an approved nonallocating counter; render diagnostics outside
// allocator entry and its locks.
```

**Noncompliant fragment or claim (do not copy):**

```rust
let message = format!("allocating {size} bytes");
log(message);
```

---

<a id="rust-057"></a>

### RUST-057: Separate deterministic behavior from build repeatability

**Class:** CORRECTNESS / VERIFICATION. **Obligation:** project requirement.

Sort map-derived output when order matters, use explicit seeds for
reproducible tests and define filesystem enumeration order. Keep timestamps, paths and environment-derived
metadata under a reproducible-build policy. A fixed seed alone does not make concurrent execution deterministic.

**Rationale:** Container order, environment and concurrency can change output independently of source revision.

**Verification design:** Repeat across process seeds, debug/release, target widths and controlled environment
variations.

**Related pitfalls:** [RPIT-031](rust-common-pitfalls.md#rpit-031).

#### Local examples

**Contextual Rust example:**

```rust
let mut keys: Vec<_> = values.keys().collect();
keys.sort();
```

**Noncompliant fragment or claim (do not copy):**

```rust
for key in values.keys() {
    serialize(key); // Claims byte-identical output across processes.
}
```

---

<a id="rust-058"></a>

### RUST-058: Tie testing to contracts and failure states

**Class:** VERIFICATION. **Obligation:** project requirement.

Combine unit, external-consumer, property, differential, fuzz and fault-injection
checks according to the claim. Include negative compile tests for lifetime/API restrictions. Code coverage
identifies missing observations; it does not prove soundness or all interleavings. Inspect assertions removed
or weakened by test-only configuration.

**Rationale:** Tests need to observe invariants and errors, not only a successful return.

**Verification design:** Map each high-risk contract to an observable check and retain minimized failing inputs.

**Related pitfalls:** [RPIT-044](rust-common-pitfalls.md#rpit-044), [RPIT-050](rust-common-pitfalls.md#rpit-050).

#### Local examples

**Contextual Rust example:**

```rust
assert!(buffer.try_append(oversized).is_err());
assert_eq!(buffer.as_bytes(), before);
```

**Noncompliant fragment or claim (do not copy):**

```rust
assert!(buffer.try_append(oversized).is_err()); // No state assertion.
```

---

<a id="rust-059"></a>

### RUST-059: Qualify tools and evidence separately

**Class:** VERIFICATION. **Obligation:** project requirement.

Pin tools, commands, inputs, target and enabled checks. Miri, sanitizers, linting,
model checking and fuzzing observe different failure classes. A successful run only supports its tested
scope; unsupported operations and excluded targets remain visible. Select stricter subsets and formal methods
for CRITICAL profiles from product requirements.

**Rationale:** Tool success applies to a configured run and cannot establish excluded properties.

**Verification design:** Keep exit status, logs, limitations and not-run reasons with the review record.

**Related pitfalls:** [RPIT-043](rust-common-pitfalls.md#rpit-043), [RPIT-044](rust-common-pitfalls.md#rpit-044),
[RPIT-045](rust-common-pitfalls.md#rpit-045), [RPIT-047](rust-common-pitfalls.md#rpit-047),
[RPIT-050](rust-common-pitfalls.md#rpit-050).

#### Local examples

**Contextual review example:**

```text
// Record target, features, tool version, checked paths and unsupported FFI.
```

**Noncompliant fragment or claim (do not copy):**

```rust
// Miri passed one case, therefore all clients of this unsafe API are sound.
```

---

<a id="rust-060"></a>

### RUST-060: Keep product assurance traceable

**Class:** VERIFICATION. **Obligation:** project requirement.

**Profile:** CRITICAL.

Link hazards and security requirements to code owners, controls, deviations
and verification results. Pin the revision and maturity of external rules before adoption. Evaluate compiler,
libraries, target and tooling in the product's qualification context. Do not call the result “MISRA Rust” or
claim certification from this guide, a cross-reference matrix or a green tool run.

**Rationale:** Product assurance requires the implementation and evidence chain for each actual hazard.

**Verification design:** Audit traceability and evidence gaps before release. See [sources and revision
policy](#sources-and-revision-policy).

#### Local examples

**Contextual review example:**

```text
// requirement H-12 -> bounded queue owner -> RUST-027 -> exhaustion test
```

**Noncompliant fragment or claim (do not copy):**

```rust
// Clippy passes, therefore the product meets its safety-integrity target.
```

---

## Naming and source presentation controls

These controls apply to BASE and its extensions. They expand [RUST-001](#rust-001) into authoring and review
rules. The pinned formatter determines mechanical layout; reviewers check vocabulary, grouping and meaning.
Preserve existing rule identifiers when extending this section.

---

<a id="rust-061"></a>

### RUST-061: Use the naming convention for each Rust construct

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use the following conventions in project-owned Rust. Keep externally imposed identifiers at the adapter or
generated binding boundary, with any required lint exception scoped there. Avoid Hungarian prefixes, a
project prefix on every private symbol, and `_t` suffixes. Modules already provide namespaces.

| Construct | Convention | Example |
| --- | --- | --- |
| Module, source stem, function, method, local, parameter, field | `snake_case` | `free_list`, `reserve_bytes` |
| Struct, enum, union, type alias, trait, enum variant | `UpperCamelCase` | `AllocationError`, `CapacityExceeded` |
| Constant, static, const generic parameter | `SCREAMING_SNAKE_CASE` | `MAX_BLOCK_BYTES`, `N` |
| Type parameter | `UpperCamelCase`, often a conventional single letter | `T`, `Reader` |
| Lifetime parameter | Short lowercase or meaningful `snake_case` | `'a`, `'arena` |
| Function-like macro | `snake_case` | `checked_offset!` |

Use Rust's standard lint names to diagnose casing, including `non_snake_case`, `non_camel_case_types` and
`non_upper_case_globals`. A clean lint run does not establish that a name describes its purpose.

**Rationale:** The spelling identifies the kind of construct before a reader follows its declaration.

**Verification design:** Run compiler naming lints and review new public identifiers. Reference:
[API naming conventions][api-naming].

#### Local examples

**Contextual Rust example:**

```rust
struct FreeBlock {
    capacity_bytes: usize,
}

const MIN_BLOCK_BYTES: usize = 64;
```

**Noncompliant fragment or claim (do not copy):**

```rust
struct free_block_t {
    nCapacityBytes: usize,
}

const minBlockBytes: usize = 64;
```

---

<a id="rust-062"></a>

### RUST-062: Keep vocabulary, abbreviations and acronyms consistent

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use English domain terms consistently across declarations, docs and diagnostics. Name an allocator region
`region` everywhere unless `arena`, `pool` or `slab` denotes a different documented concept. Avoid vague names
such as `data2`, `thing`, `process_it` and `manager` when a concrete responsibility is known.

Treat acronyms as words in type names: `HttpClient`, `CpuFeatures`, `FfiHandle`, `Uuid`. Use `http_client` and
`cpu_features` in value names. Conventional terms such as `len`, `ptr`, `src` and `dst` are acceptable when
their meaning is local and unambiguous. Use `i` or `j` only for a short index scope; prefer `slot_index` when
several indexes coexist. Document domain-specific abbreviations at their first public use. Keep standardized
external spellings in the boundary that requires them.

**Rationale:** Consistent vocabulary makes searches reliable and reduces interpretation at call sites.

**Verification design:** Search the module for competing names for the same concept and inspect acronyms in
new public names. See [API naming conventions][api-naming].

#### Local examples

**Contextual Rust example:**

```rust
struct CpuFeatures {
    has_avx2: bool,
}

let slot_index = free_slots.next()?;
```

**Noncompliant fragment or claim (do not copy):**

```rust
struct CPUFeatures {
    flag1: bool,
}

let n = free_slots.next()?;
```

---

<a id="rust-063"></a>

### RUST-063: Name quantities, predicates and coordinate systems explicitly

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Distinguish byte lengths, element counts, capacities, offsets and indexes. Use names such as `payload_bytes`,
`element_count`, `capacity_bytes` and `slot_index`; specify the origin of an offset when multiple origins
exist. Prefer a type such as `Duration` or a unit newtype when it prevents accidental mixing. At primitive
boundaries, encode the unit in the name, for example `timeout_ms`.

Name Boolean queries affirmatively, with predicates such as `is_empty`, `has_capacity`, `can_retry` or
`contains`. Avoid a negated field that produces expressions such as `!is_not_ready`. Keep a negated name only
where the domain itself defines that state and document it. Replace several Boolean mode parameters with
named types or an options type when a call would otherwise require looking up each position.

**Rationale:** A reader can check dimensions and branch conditions without reconstructing them from arithmetic.

**Verification design:** Review arithmetic inputs and Boolean call sites without parameter tooltips; require
units and mode meaning to remain clear. See [RUST-018](#rust-018) for type-enforced distinctions.

#### Local examples

**Contextual Rust example:**

```rust
let payload_bytes = input.len();
let has_capacity = payload_bytes <= remaining_bytes;
if has_capacity {
    buffer.extend_from_slice(input);
}
```

**Noncompliant fragment or claim (do not copy):**

```rust
let size = input.len();
let is_not_full = size <= remaining;
if !is_not_full {
    reject();
}
```

---

<a id="rust-064"></a>

### RUST-064: Make method names describe borrowing, conversion and lifecycle

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use `new` for conventional construction and a descriptive constructor such as `with_capacity` when its
parameter changes the construction policy. A constructor may return `Result`; `try_new` is useful when
distinguishing a fallible alternative. Document allocations, fallibility and acquired resources explicitly.

For conversions, follow the established `as_*` borrowed-view, `to_*` value-conversion and `into_*` consuming
conventions. Select the corresponding standard traits when their contracts fit. Use `iter`, `iter_mut` and
`into_iter` consistently with shared borrowing, exclusive borrowing and ownership transfer. Raw-pointer
accessors must document validity and lifetime; their names alone cannot carry those obligations.

Prefer `capacity()` to `get_capacity()` for an ordinary getter. Reserve `get` for established access patterns
such as optional indexed lookup. Use verbs such as `reserve`, `clear`, `reset`, `flush`, `close` and `finish`
only with documented effects: `clear` need not release capacity, `flush` need not establish durability, and
`Drop` cannot report a finalization error. Preserve standard trait method names exactly.

**Rationale:** Familiar method names allow callers to anticipate ownership and lifecycle effects.

**Verification design:** Compare names with receiver types, return types and contracts. Reference:
[API conversion and getter conventions][api-naming]; [RUST-026](#rust-026) covers finalization.

#### Local examples

**Contextual Rust example:**

```rust
impl Buffer {
    pub fn as_bytes(&self) -> &[u8] {
        &self.bytes
    }

    pub fn into_bytes(self) -> Vec<u8> {
        self.bytes
    }
}
```

**Noncompliant fragment or claim (do not copy):**

```rust
impl Buffer {
    pub fn as_bytes(self) -> Vec<u8> {
        self.bytes
    }
}
```

---

<a id="rust-065"></a>

### RUST-065: Give generic parameters and lifetimes a readable role

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use conventional short parameters such as `T`, `E`, `K` and `V` where their roles are immediately clear.
Use role names such as `Reader` or `Backend` when several unrelated parameters would otherwise become
`T`, `U`, `V` and `W`. Trait names describe capabilities or concepts; avoid automatic `I` prefixes or `Trait`
suffixes. Follow established ecosystem names when implementing their interfaces.

Elide lifetimes where the signature remains clear and Rust permits it. Use `'a` for one obvious relationship;
name distinct lifetimes `'arena`, `'input` or `'config` when that explains independent borrows. A name does
not establish a relationship: express necessary outlives constraints in the signature. Document associated
types by their role, such as `Item` or `Error`.

**Rationale:** Generic notation should expose the relationship a caller needs to understand.

**Verification design:** Read the signature without its body and identify each parameter's role and each
borrowed output's source. Review constraints separately from naming.

#### Local examples

**Contextual Rust example:**

```rust
struct Decoder<'input, Backend> {
    input: &'input [u8],
    backend: Backend,
}
```

**Noncompliant fragment or claim (do not copy):**

```rust
struct Decoder<'lifetime1, T1> {
    input: &'lifetime1 [u8],
    backend: T1,
}
```

---

<a id="rust-066"></a>

### RUST-066: Make package, module and file names agree with their scope

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use `snake_case` for Rust crate identifiers, modules and source stems. A Cargo package may use a hyphenated
distribution name, such as `memalloc-core`; document its import name `memalloc_core` where users need both.
Respect an established package name rather than renaming a published package for cosmetic consistency.

Name a module after its responsibility, for example `free_list`, `layout` or `platform`, and its main types
after their domain roles. Prefer `free_list::Cursor` over `free_list::FreeListCursor` when the shorter name is
unambiguous at intended use sites. Avoid dumping unrelated helpers into `utils`, `common` or `misc`.
Choose the existing `module.rs` or `module/mod.rs` arrangement consistently within a subsystem; do not keep
both candidates for the same module. Use `lib.rs`, `main.rs`, `build.rs` and integration-test paths according
to Cargo's conventions.

**Rationale:** A name and its filesystem location should help a reader find the responsible component.

**Verification design:** Compare file names, module declarations and public paths. Review boundary cohesion
with [RMOD-001](rust-module-architecture.md#rmod-001).

#### Local examples

**Contextual review example:**

```text
Cargo package: memalloc-core
Rust crate:    memalloc_core
Source:        src/free_list.rs
Public path:   memalloc_core::free_list::Cursor
```

**Noncompliant fragment or claim (do not copy):**

```text
src/utils2.rs owns free lists, network retries and build configuration.
```

---

<a id="rust-067"></a>

### RUST-067: Name variants, errors and constants for their meaning

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use enum variants that read naturally with their enum, such as `AllocationError::CapacityExceeded`.
Avoid repeating an enum's name in every variant. Prefer named fields for several payloads with distinct
roles; use tuple variants when the payload's single role is evident. Error type names should identify the
operation or domain, such as `AllocationError` or `ParseLayoutError`.

Name constants for the invariant or policy they represent, such as `MAX_ALIGNMENT_BYTES`, and supply a
type or unit where needed. Avoid identifiers such as `VALUE_64` that restate a literal without its purpose.
Several occurrences of the same number may represent different policies and do not automatically belong in
one shared constant. Keep enum discriminants and protocol numbers explicit where required by a format.

**Rationale:** Names should survive a policy change and distinguish errors that need different handling.

**Verification design:** Read variant names at match sites and follow each constant to the policy it controls.
Review representation separately under [RUST-023](#rust-023).

#### Local examples

**Contextual Rust example:**

```rust
enum AllocationError {
    InvalidAlignment,
    CapacityExceeded {
        requested_bytes: usize,
        limit_bytes: usize,
    },
}

const MIN_ALIGNMENT_BYTES: usize = 8;
```

**Noncompliant fragment or claim (do not copy):**

```rust
enum AllocationError {
    AllocationErrorInvalidAlignment,
    Error2(usize, usize),
}

const VALUE_8: usize = 8;
```

---

<a id="rust-068"></a>

### RUST-068: Name tests, fixtures and benchmarks after observable behavior

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use `snake_case` test names that identify the condition and expected behavior, such as
`append_over_limit_preserves_contents`. The containing module may supply the subject; avoid repeating a
long full path in every test name. Use `tests` for the conventional unit-test module and responsibility-based
names for integration-test files. Name fixtures by the boundary they exercise, not by discovery order.

Benchmark names must distinguish workload parameters that change the interpretation, including size,
ownership mode and backend where applicable. Preserve a benchmark identifier deliberately when tracking
history; explain a rename or workload change. Avoid names such as `fast`, `optimized` or `test_2` that hide
the measured or asserted behavior.

**Rationale:** A failing check or changed measurement should identify the affected contract from its name.

**Verification design:** Inspect test listings and benchmark labels without reading bodies; compare each name
with its assertions or workload. See [RUST-058](#rust-058) and [RPERF-001](#rperf-001).

#### Local examples

**Contextual Rust example:**

```rust
#[test]
fn append_over_limit_preserves_contents() {
    let mut buffer = bounded_buffer_with(b"abc", 4);

    assert!(buffer.try_append(b"de").is_err());
    assert_eq!(buffer.as_bytes(), b"abc");
}
```

**Noncompliant fragment or claim (do not copy):**

```rust
#[test]
fn test_2() {
    let mut b = bounded_buffer_with(b"abc", 4);
    assert!(b.try_append(b"de").is_err());
}
```

---

<a id="rust-069"></a>

### RUST-069: Use explicit column budgets and readable line breaks

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use a 100-column budget for Rust source, including indentation, under the selected formatter. Wrap at syntax
boundaries: arguments, fields, bounds and method-chain stages. Preserve complete identifiers and operators.
If repeated wrapping obscures an expression, introduce a meaningful local or extract a cohesive operation;
avoid shortening descriptive names merely to fit the margin.

For prose-only Rust comments, aim for at most 80 characters from the comment marker and remain within
100 columns including indentation. Review comments manually because rustfmt need not reflow them.
Markdown prose in these guides uses the repository's 120-column policy. A required long URL, exact string,
generated record or test fixture may exceed the Rust budget when splitting would obscure or change its
meaning; keep that exception local and explain any non-obvious reason. `max_width` does not guarantee that
every literal or macro body is wrapped.

**Rationale:** A predictable width supports side-by-side review while preserving meaningful source text.

**Verification design:** Run rustfmt, then inspect remaining overlong lines and comment paragraphs. Reference:
[Style Guide formatting conventions][style]. Do not change a literal's value to satisfy a width check.

#### Local examples

**Contextual Rust example:**

```rust
let payload_end = payload_offset
    .checked_add(payload_bytes)
    .ok_or(AllocationError::CapacityExceeded)?;
```

**Noncompliant fragment or claim (do not copy):**

```rust
let payload_end = payload_offset.checked_add(payload_bytes).ok_or(AllocationError::CapacityExceeded)?;
// Rename payload_offset to p and AllocationError to E just to prevent wrapping.
```

---

<a id="rust-070"></a>

### RUST-070: Use block indentation and formatter-owned spacing

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use four spaces per indentation level and spaces rather than tabs for source indentation. Let rustfmt place
continuation lines relative to the block; do not align them manually beneath a distant argument. Keep opening
braces with their declaration or control expression and closing braces at the containing indentation.
Accept the formatter's rules for `else`, compact expressions and empty bodies.

Use formatter-produced spaces around binary operators, after commas and after field/type colons. Keep path
separators, member access and reference syntax compact: `core::ptr`, `value.len()`, `&mut value` and `&[u8]`.
Avoid tabs or repeated spaces used to align assignments, types or trailing comments into columns. Literal
tabs and spaces that are data are governed by [RUST-081](#rust-081).

**Rationale:** Block indentation remains stable when names change and exposes nesting consistently.

**Verification design:** Check rustfmt output and inspect hand-aligned tables in code or macro bodies.
Reference: [Style Guide][style].

#### Local examples

**Contextual Rust example:**

```rust
if requested_bytes <= capacity_bytes {
    let remaining_bytes = capacity_bytes - requested_bytes;
    report(remaining_bytes);
} else {
    reject();
}
```

**Noncompliant fragment or claim (do not copy):**

```rust
if requested_bytes<=capacity_bytes
{
  let remaining_bytes    =capacity_bytes-requested_bytes;
  report( remaining_bytes );
}
```

---

<a id="rust-071"></a>

### RUST-071: Separate logical stages with one blank line

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use one blank line when a function moves between meaningful stages, such as validation, preparation and
publication. Keep statements that implement one small step together. Avoid consecutive blank lines, a blank
line after every statement, and empty padding immediately inside a block. A blank line contains no spaces.

Keep a fallible operation beside its `?`, `match` or explicit result check. Separate a completed operation
from a distinct stage, not from the check that establishes whether it succeeded. Keep an invariant comment
with the statements it explains. A tail expression may directly follow the final preparation step; use a
blank line before it only when it marks a distinct stage. Do not require blank lines around every `return`,
`break`, `continue` or `?`.

**Rationale:** Vertical spacing shows where one thought ends without hiding operation/check relationships.

**Verification design:** Review changed functions with blank lines treated as paragraph boundaries. Rustfmt
can normalize spacing but cannot decide whether the chosen transaction boundaries are meaningful.

#### Local examples

**Contextual Rust example:**

```rust
validate_layout(layout)?;
let required_bytes = checked_size(layout)?;

let reservation = pool.try_reserve(required_bytes)?;
reservation.initialize(input)?;

Ok(reservation.publish())
```

**Noncompliant fragment or claim (do not copy):**

```rust
let result = pool.try_reserve(required_bytes);

record_attempt();

let reservation = result?;


reservation.initialize(input)?;
```

---

<a id="rust-072"></a>

### RUST-072: Separate items without scattering related declarations

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use one blank line between function definitions, impl blocks and distinct type declarations. Within an impl,
separate methods by one blank line; keep each method's docs and attributes attached. Keep a small related
constant group or consecutive simple fields together. Use a single blank line between distinct groups only
when the grouping expresses a domain relationship.

Do not insert empty lines immediately after an opening brace or before a closing brace. Avoid large vertical
banners and multiple blank lines to simulate sections. When a file needs many unrelated visual sections,
review its module responsibilities under [RUST-017](#rust-017). Whitespace alone does not define a boundary.

**Rationale:** Regular separation makes definitions easy to scan while preserving cohesive groups.

**Verification design:** Inspect item boundaries and constant/field groupings after rustfmt. A retained blank
line must separate concepts rather than compensate for an oversized module.

#### Local examples

**Contextual Rust example:**

```rust
impl Buffer {
    pub fn len(&self) -> usize {
        self.bytes.len()
    }

    pub fn is_empty(&self) -> bool {
        self.bytes.is_empty()
    }
}
```

**Noncompliant fragment or claim (do not copy):**

```rust
impl Buffer {

    pub fn len(&self) -> usize { self.bytes.len() }



    pub fn is_empty(&self) -> bool { self.bytes.is_empty() }

}
```

---

<a id="rust-073"></a>

### RUST-073: Keep documentation, attributes and safety comments attached

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Write item documentation with `///` immediately before its attributes and declaration. Use `//!` for crate
and module documentation. Put each outer attribute on its own line, with the indentation of its item.
Use `///` lines to separate paragraphs inside a doc comment rather than inserting an ordinary empty line
between the documentation and its item. Keep `#[cfg]`, lint expectations and other attributes next to the
declaration or expression they control.

Place `// SAFETY:` beside the unsafe operation it justifies, normally immediately above the unsafe block or
impl. Keep a public unsafe API's `# Safety` contract in its rustdoc. These two forms have different jobs under
[RUST-003](#rust-003). Do not move safety comments away from their operation merely to create uniform spacing.
Preserve macro attribute ordering when it affects expansion.

**Rationale:** Readers and tools must agree on which declaration or operation a comment or attribute describes.

**Verification design:** Inspect rendered rustdoc and the scope of every moved attribute or safety comment.
Reference: [Style Guide documentation and attribute conventions][style].

#### Local examples

**Contextual Rust example:**

```rust
/// Returns the number of initialized bytes.
///
/// Spare capacity is excluded.
#[must_use]
pub fn len(&self) -> usize {
    self.bytes.len()
}
```

**Noncompliant fragment or claim (do not copy):**

```rust
/// Returns the number of initialized bytes.

#[must_use]

pub fn len(&self) -> usize {
    self.bytes.len()
}
```

---

<a id="rust-074"></a>

### RUST-074: Lay out signatures and bounds so the contract is visible

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Keep short signatures compact when rustfmt does so. Let long parameter lists break into a block with one
parameter per line and formatter-produced trailing commas. Group a parameter's name and type together;
avoid manually aligning colons or return arrows. Use a `where` clause when several bounds would obscure the
function name, arguments or return type. Keep associated-type constraints readable.

Use a named request type when several arguments form a stable domain concept; do not create a throwaway type
only to hide a long line. Avoid opaque type aliases that conceal ownership or error semantics just to shorten
a signature. Split overly complex contracts by responsibility under [RUST-016](#rust-016).

**Rationale:** Callers should be able to identify inputs, output ownership and constraints from the signature.

**Verification design:** Review the formatted signature independently of the implementation and check that
any extracted type improves the domain model. Let the selected rustfmt decide exact wrapping.

#### Local examples

**Contextual Rust example:**

```rust
fn write_record<W>(writer: &mut W, header: &[u8], payload: &[u8]) -> std::io::Result<()>
where
    W: std::io::Write,
{
    writer.write_all(header)?;
    writer.write_all(payload)
}
```

**Noncompliant fragment or claim (do not copy):**

```rust
fn write_record<W: std::io::Write>(writer  : &mut W,
                                  header  : &[u8],
                                  payload : &[u8]) -> std::io::Result<()> {
    writer.write_all(header)?; writer.write_all(payload)
}
```

---

<a id="rust-075"></a>

### RUST-075: Keep calls, chains and closures easy to follow

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Let rustfmt wrap calls and method chains; use its trailing commas for multiline argument lists. Keep a
fallibility operator attached to the expression it checks. For a long transformation chain, make each stage
express a clear operation. Introduce a named intermediate when a reader needs to inspect a meaningful state
or distinguish separate effects. Prefer a loop when a chain hides branching, error recovery or mutation.

Keep short closures as expressions when they remain clear. Give a multistatement closure a block and the
same logical grouping as a function. Extract a named helper when the closure has an independent contract.
Avoid deeply nested calls that combine input parsing, resource acquisition and publication in one expression.
Check evaluation order and temporary lifetimes when extracting expressions.

**Rationale:** Expression layout should expose the order of computation and the point where failure occurs.

**Verification design:** Trace calls and effects in evaluation order; run rustfmt after decomposition and
review drop timing for moved temporaries.

#### Local examples

**Contextual Rust example:**

```rust
let layout = parse_layout(input)?;
let reservation = pool.try_reserve(layout)?;

registry.publish(reservation)
```

**Noncompliant fragment or claim (do not copy):**

```rust
registry.publish(pool.try_reserve(parse_layout(read_request(source)?)?)?)
```

---

<a id="rust-076"></a>

### RUST-076: Make aggregate and match layouts reflect their structure

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Accept rustfmt's compact layout for simple literals and its multiline layout for larger structs, enums and
matches. Use field shorthand when the binding already has the field's name. Put a multistatement match arm
in a block, keep its binding/guard/body relationship clear, and use formatter-owned commas and indentation.
Do not force a multiline expression onto one line by removing useful names or suppressing formatting.

Keep variant and field ordering meaningful. Field order can affect representation and destruction;
match-arm order can affect which pattern wins. Do not sort either as a cosmetic operation. Use exhaustive
matches when a new variant should force review under [RUST-018](#rust-018); an underscore arm is a semantic
decision. Destructure only the fields the operation needs, following [RUST-084](#rust-084).

**Rationale:** A regular layout lets the reader focus on alternatives and the state each alternative produces.

**Verification design:** Check the formatter diff, arm reachability and any field or variant reordering.
Representation and drop effects require their own review, even in a formatting change.

#### Local examples

**Contextual Rust example:**

```rust
match state {
    State::Ready { offset_bytes } => Ok(offset_bytes),
    State::Exhausted => {
        metrics.record_exhaustion();
        Err(AllocationError::CapacityExceeded)
    }
}
```

**Noncompliant fragment or claim (do not copy):**

```rust
match state { State::Ready { offset_bytes } => Ok(offset_bytes), _ => { metrics.record_exhaustion(); Err(AllocationError::CapacityExceeded) } }
```

---

<a id="rust-077"></a>

### RUST-077: Make precedence and control expressions clear

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use parentheses when mixed arithmetic, shifts, masks or Boolean operators would require readers to recall
precedence. Remove redundant outer parentheses around a simple `if`, `while` or `match` operand. Avoid a
single condition that combines several independent validations; give checks a meaningful name or use early
rejection when that clarifies behavior. Preserve short-circuit evaluation and side effects when rewriting.

Keep one statement per logical source line. Use braces for Rust control-flow bodies and let rustfmt choose
the compact representation of simple value-producing expressions. Do not impose C-style parentheses around
every condition or a final `return` on ordinary Rust tail expressions. See [RUST-016](#rust-016) for exit policy.

**Rationale:** A reader should see the intended grouping and evaluation path without mentally parsing a puzzle.

**Verification design:** Review mixed-precedence expressions, short-circuit dependencies and nested conditions;
use Clippy findings as prompts and inspect any automatic rewrite for preserved behavior.

#### Local examples

**Contextual Rust example:**

```rust
let has_read_access = (flags & READ_MASK) != 0;
let can_publish = is_initialized && (has_read_access || is_owner);
if can_publish {
    publish();
}
```

**Noncompliant fragment or claim (do not copy):**

```rust
if (is_initialized && flags & READ_MASK != 0 || is_owner) { publish(); }
```

---

<a id="rust-078"></a>

### RUST-078: Group imports and keep names traceable

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

At module scope, group imports in this order when the groups exist: standard-library roots (`core`, `alloc`,
`std`), external dependencies, then project paths (`crate`, `super`, `self`). Use one blank line between these
groups. Let the selected formatter order and wrap entries within a group. Default rustfmt need not create
these groups; review them explicitly without assuming an unstable configuration option is enabled.

Prefer explicit imports. A small `use super::*` in a local test module is acceptable when its scope is clear;
other glob imports require a narrow reason, such as a documented prelude. Use aliases to resolve collisions
or convey a stable domain role, not to abbreviate arbitrary types to one letter. Keep a deliberately local
import next to the code it serves. Treat `pub use` as part of public API design and group re-exports coherently.

**Rationale:** A reader can identify where an operation comes from and notice new component dependencies.

**Verification design:** Review new imports alongside the dependency graph, and verify that feature-gated
imports carry the correct `cfg`. See [RUST-013](#rust-013) for visibility and re-exports.

#### Local examples

**Contextual Rust example:**

```rust
use core::num::NonZeroUsize;
use core::ptr::NonNull;

use crate::layout::BlockLayout;
use crate::pool::Pool;
```

**Noncompliant fragment or claim (do not copy):**

```rust
use crate::pool::*;
use core::ptr::NonNull as P;
use crate::layout::*;
```

---

<a id="rust-079"></a>

### RUST-079: Keep bindings close to use and shadow only a clear refinement

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Declare a binding near its first use and use the smallest scope that preserves ownership and required drop
timing. Prefer immutable bindings; add `mut` where mutation is part of the local operation. Use a separate
`let` for unrelated values, while retaining tuple or struct destructuring that expresses one operation.
Specify a type when it establishes an important boundary; let inference handle obvious local detail.

Shadowing is appropriate for an evident refinement, such as trimming then parsing the same input. Use a new
name when the meaning, unit or ownership role changes substantially. Avoid reusing `size` successively for
bytes, elements and aligned storage. Do not use shadowing to suggest that a previous resource has necessarily
been dropped; explicit scopes or `drop` should mark required resource-release points.

**Rationale:** Local bindings should reveal the state being used and prevent stale or ambiguous interpretations.

**Verification design:** Follow each binding through its scope and review shadowing near guards or owning
resources. Confirm that any scope reduction preserves the intended destruction order.

#### Local examples

**Contextual Rust example:**

```rust
let input = input.trim();
let element_count: usize = input.parse()?;
let allocation_bytes = checked_storage_bytes(element_count)?;
```

**Noncompliant fragment or claim (do not copy):**

```rust
let size = input.trim();
let size: usize = size.parse()?;
let size = checked_storage_bytes(size)?;
```

---

<a id="rust-080"></a>

### RUST-080: Write comments and diagnostics that explain decisions

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use `//` followed by a space for ordinary comments and complete sentences for explanations. Prefer a comment above the relevant
code over a long trailing comment. Explain an invariant, protocol choice, workaround or measured tradeoff;
omit comments that merely restate the next statement. Keep diagrams or tables only when they clarify a real
relationship, and maintain their accuracy with the code. Remove disabled production code from comments.

A `TODO` or `FIXME` must identify an issue or accountable owner and state the remaining behavior and acceptance
condition. Use stable searchable terms in diagnostics. Include the failed operation and useful nonsensitive
context, such as requested and allowed sizes; do not expose secrets or invent an error cause. Follow the
error type's `Display` convention and let the application select user-facing presentation.

**Rationale:** Comments preserve reasoning and diagnostics support investigation beyond the author's session.

**Verification design:** Check comment/code agreement, tracked work and diagnostic usefulness. Inspect
redaction under [RUST-050](#rust-050) and contract documentation under [RUST-004](#rust-004).

#### Local examples

**Contextual Rust example:**

```rust
// Publish only after initialization so readers never observe spare capacity.
state.publish(initialized_bytes);
```

**Noncompliant fragment or claim (do not copy):**

```rust
// Call publish.
state.publish(initialized_bytes); // TODO: fix stuff later
```

---

<a id="rust-081"></a>

### RUST-081: Format literals without changing the represented data

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use separators in long numeric literals to show meaningful groups, such as `1_000_000` or `0x00ff_ffff`.
Choose decimal for ordinary counts and hexadecimal for bit patterns where that helps review. Add a numeric
suffix or type annotation when required to establish arithmetic width. A named policy constant still needs
the rationale required by [RUST-067](#rust-067).

Use ordinary, byte or raw strings according to the represented data and escaping needs. Long diagnostic text
may use `concat!` with explicit spaces between segments. Multiline raw strings include their literal line
breaks and indentation; do not reindent them as ordinary prose. Make significant tabs, trailing spaces,
carriage returns or control characters visible through escapes or a documented fixture. Preserve exact
protocol text and test vectors when wrapping, and keep a local overlong line when that is clearer.

**Rationale:** A cosmetic edit must not silently alter bytes, numeric width or a protocol value.

**Verification design:** Inspect the represented value after a literal edit. For fixtures and wire text,
use the existing byte-level assertions; review width exceptions under [RUST-069](#rust-069).

#### Local examples

**Contextual Rust example:**

```rust
const MAX_PAYLOAD_BYTES: usize = 1_048_576;
const MESSAGE: &str = concat!(
    "The requested allocation exceeds the configured limit. ",
    "Reduce the payload or raise the limit explicitly."
);
```

**Noncompliant fragment or claim (do not copy):**

```rust
// Intended to preserve "allocation failed" while wrapping source text.
const MESSAGE: &str = concat!("allocation", "failed");
```

---

<a id="rust-082"></a>

### RUST-082: Keep macros and conditional attributes readable

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Give project-owned function-like macros descriptive `snake_case` names and metavariables meaningful roles,
such as `$offset` and `$layout`. Format macro bodies as ordinary Rust where their grammar permits. Keep
distinct matcher arms visually separated when they implement different accepted forms. For a custom grammar
that rustfmt cannot format, document and consistently apply that grammar's local layout.

Keep `cfg` and `cfg_attr` conditions readable, close to their items and consistent across declarations and
imports. Factor repeated platform selection into a module boundary where that clarifies ownership.
Explain any narrowly scoped formatter exception and keep it out of unrelated code. Do not reorder procedural
attributes, matcher arms or derive inputs as a cosmetic change without checking expansion semantics.

**Rationale:** Macro syntax and conditional compilation need visible structure because readers cannot see all
expanded configurations at once.

**Verification design:** Review each accepted macro form and affected configuration; use the expansion and
feature checks required by [RUST-052](#rust-052) and [RUST-053](#rust-053).

#### Local examples

**Contextual Rust example:**

```rust
#[cfg(all(target_os = "linux", feature = "os-pages"))]
mod linux_pages;
```

**Noncompliant fragment or claim (do not copy):**

```rust
#[cfg(all(target_os="linux",feature="os-pages"))] mod linux_pages;
```

---

<a id="rust-083"></a>

### RUST-083: Give each source file a predictable reading order

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Start owned files with the repository's license notice, followed by crate/module documentation and inner
attributes as applicable. Keep module declarations, imports and public re-exports near the top. Then present
domain constants and types, their implementations, helpers and local tests in an order that explains the
module. Keep a type and its closely related impls near one another instead of separating every impl from
every type mechanically. Group foreign declarations at their owned boundary.

Place unit tests in the conventional `#[cfg(test)] mod tests` near the end when a single local test module
fits. Split large tests by responsibility rather than letting test volume hide implementation structure.
Use UTF-8, LF and the repository EOF policy described in the formatting overview. Avoid editor modelines,
hidden directional controls and decorative comment banners. Imported and generated files retain their
documented provenance and generator policy.

**Rationale:** Predictable ordering helps readers move from contract to representation to behavior and checks.

**Verification design:** Review navigation through the file, license/provenance and source-text consistency.
This ordering is a project policy; it does not claim that Rust requires every item to appear in this order.

#### Local examples

**Contextual review example:**

```text
License notice
Module documentation and inner attributes
Module declarations, grouped imports and public re-exports
Domain constants and types with related implementations
Private helpers
Local tests
Repository EOF marker
```

**Noncompliant fragment or claim (do not copy):**

```text
Public API, platform imports, unrelated helpers and tests are interleaved
in the order in which contributors happened to add them.
```

---

<a id="rust-084"></a>

### RUST-084: Make destructuring and intentionally ignored values explicit

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use destructuring to expose the roles of values returned together. Rename fields in a pattern when the local
role needs clarification. Use `..` only when omitted fields are deliberately irrelevant to the operation;
use explicit fields when an added field should trigger a contract review.

An unused `_name` binding is appropriate when the value must remain owned, such as a lock guard, or a required
callback parameter is unused. A wildcard `_` does not provide the same ownership intent as a named guard.
Do not silence an unused `Result` with `let _ =` unless deliberate best-effort handling is justified locally
and permitted by the operation's contract. A leading underscore must not hide an unhandled failure.

**Rationale:** Patterns express both the data the operation depends on and the values it keeps alive or ignores.

**Verification design:** Inspect ignored fields, must-use results and guard bindings. Verify resource lifetime
and error policy rather than accepting a warning-free build as evidence of intent.

#### Local examples

**Contextual Rust example:**

```rust
let _guard = gate.lock().map_err(|_| AccessError::Poisoned)?;
update_shared_state();
```

**Noncompliant fragment or claim (do not copy):**

```rust
let _ = gate.lock();
update_shared_state(); // The temporary result cannot retain the lock here.
```

---

## Allocation, scheduling and configuration boundaries

---

<a id="rust-085"></a>

### RUST-085: Preserve the complete vector allocation contract

**Class:** SOUNDNESS. **Obligation:** project requirement.

**Profile:** UNSAFE/FFI. Extend [RUST-024](#rust-024) at raw ownership transfers.

Keep pointer, element type, initialized length, allocation capacity and allocator origin together.
Reconstruct `Vec<T>` only when its documented allocation layout and ownership conditions hold.
Do not substitute length for capacity, infer capacity from a foreign byte count, or reinterpret an owned
allocation using a type with a different deallocation layout. A borrowed view needs a separate lifetime
contract; it does not authorize reconstruction. Handle empty and zero-sized-element vectors explicitly.

**Rationale:** A valid readable address does not establish authority to destroy its allocation.

**Verification design:** Review the unique transfer point and matching destructor. Exercise empty, spare-capacity
and zero-sized-element cases in the [complete allocation fixture](#allocation-regression).
Run Miri separately on supported configurations; passing ordinary tests does not establish all raw-part invariants.

**Contextual contract example (not executable):**

```text
Rust vector -> one owned transfer record -> matching Rust destructor
Foreign borrowed bytes -> bounded temporary slice -> no Rust deallocation
```

**Noncompliant claim:** A non-null `malloc` result can always be adopted by `Vec::from_raw_parts`.

**Source:** [Vec raw-part safety contract](https://doc.rust-lang.org/std/vec/struct.Vec.html#method.from_raw_parts).
See [RPIT-051](rust-common-pitfalls.md#rpit-051).

---

<a id="rust-086"></a>

### RUST-086: Publish only the initialized prefix of a growing buffer

**Class:** SOUNDNESS. **Obligation:** project requirement.

**Profile:** ALLOC / UNSAFE/FFI. Refine [RUST-030](#rust-030) for bulk construction.

Prefer `push` or another safe construction API. Before choosing `spare_capacity_mut` and `set_len`,
identify exactly which writes establish valid `T` values and which operation commits the initialized count.
Keep the previous length until every newly published element is initialized. If initialization can panic or
return an error, own the partially constructed elements through a reviewed guard or a safe temporary collection.
Define whether failure leaves the original buffer unchanged or preserves a valid partial result.

**Rationale:** Capacity describes storage; length also controls access and destruction.

**Verification design:** Inject failure before the first element and after each successful element.
Use drop counters to detect lost or repeated destruction. Check that a native writer's result establishes
both the number written and the validity of the element representation. A byte count alone cannot validate `T`.

**Contextual Rust example:** `values.push(construct(index)?);` keeps previously constructed values owned.

**Noncompliant fragment (do not execute):**

```text
set_len(target_count); then initialize elements with a fallible callback
```

**Source:** [Vec initialization obligations](https://doc.rust-lang.org/std/vec/struct.Vec.html#method.set_len).
See [RPIT-052](rust-common-pitfalls.md#rpit-052) and the [drop-count fixture](#allocation-regression).

---

<a id="rust-087"></a>

### RUST-087: Review wake registration as part of the readiness protocol

**Class:** CORRECTNESS. **Obligation:** project requirement.

**Profile:** ASYNC. Apply when implementing `Future`, streams or an executor adapter.

Specify who publishes readiness, registers the current waker and releases retained task state.
Close the race between checking readiness and arranging notification. With an `AtomicWaker`-style primitive,
register before the decisive readiness check, or use its documented equivalent protocol.
Refresh registration when a later poll supplies another waker. Define cancellation and producer completion
under the same synchronization protocol; notification is not a substitute for publishing payload memory.

**Rationale:** `Pending` without a reachable notification path can suspend a task indefinitely.

**Verification design:** Force producer completion before registration, during registration and after `Pending`.
Poll with a replacement waker; verify that the currently waiting task is reachable. Model cancellation at each
state transition. Repeated polls after `Ready` must not introduce UB even when the API allows a panic.

**Contract example (not executable):**

```text
consumer: register current waiter -> inspect synchronized state -> Ready or Pending
producer: publish synchronized result -> notify registered waiter
```

**Noncompliant claim:** An earlier readiness check makes later waker registration sufficient.

**Sources:** [Future polling contract](https://doc.rust-lang.org/std/future/trait.Future.html#tymethod.poll),
[AtomicWaker protocol](https://docs.rs/futures/latest/futures/task/struct.AtomicWaker.html).
The latter is library-specific guidance, not a requirement to add that dependency.
See [RPIT-053](rust-common-pitfalls.md#rpit-053).

---

<a id="rust-088"></a>

### RUST-088: Specify both outcomes of compare-and-exchange

**Class:** CORRECTNESS. **Obligation:** project requirement.

**Profile:** Concurrent code using atomics. Refine [RUST-040](#rust-040).

Record the success read-modify-write ordering and the failed-load ordering separately. For each subsequent
payload access, identify the observation that establishes synchronization. Do not assume a successful
`Acquire` operation publishes preceding writes, or that `Release` acquires data read by the operation.
Use a permitted failure ordering; a failure performs no store, so `Release` and `AcqRel` are invalid there.
Handle spurious failure of weak compare-and-exchange. Bound retries or document the progress requirement.

**Rationale:** A single source expression has two synchronization paths and a retry path.

**Verification design:** Review a state-transition table containing both results and the accessed payload.
Exercise contention and injected retry in a model of the actual protocol. Test reclamation separately:
even `SeqCst` does not keep a removed allocation alive or prevent address reuse.

**Contextual contract example (not executable):**

```text
failure result -> observed state only -> acquire proof before reading published data
successful removal -> retirement protocol -> reclaim only after all readers are excluded
```

**Noncompliant claim:** The strongest ordering automatically solves pointer lifetime and ABA.

**Source:** [Atomic ordering semantics](https://doc.rust-lang.org/std/sync/atomic/enum.Ordering.html).
See [RPIT-054](rust-common-pitfalls.md#rpit-054).

---

<a id="rust-089"></a>

### RUST-089: Represent optional foreign callbacks without invalid values

**Class:** SOUNDNESS. **Obligation:** project requirement.

**Profile:** UNSAFE/FFI. Extend [RUST-034](#rust-034).

Use the documented nullable-function-pointer representation, such as `Option<extern "C" fn(u32)>`,
when the foreign ABI admits a null callback. Match argument types, calling convention and callback safety
requirements exactly. Do not create a null Rust function pointer and test it afterward. Do not generalize
the nullable representation guarantee to arbitrary enums or `Option` around an aggregate.

For a retained callback, separately specify context ownership, calling thread, reentry, unregister acknowledgement
and draining of calls already in progress. A representation guarantee establishes none of those obligations.

**Rationale:** Type validity applies before the first call; a correct ABI still needs a lifetime protocol.

**Verification design:** Test absent and present callbacks through a compiled foreign consumer using the shipped
header. Inject registration failure and a call racing with shutdown. Keep the context alive until the native
provider guarantees no further calls. Do not treat the local Rust-only example as native ABI evidence.

**Contextual Rust example:**

```rust
type Completion = Option<extern "C" fn(u32)>;
```

**Noncompliant claim:** Zeroing any callback-containing Rust struct creates a valid foreign registration.

**Source:** [Nullable pointer optimization](https://doc.rust-lang.org/nomicon/ffi.html#the-nullable-pointer-optimization).
See [RPIT-055](rust-common-pitfalls.md#rpit-055).

---

<a id="rust-090"></a>

### RUST-090: Verify the resolved graph for each supported consumer

**Class:** PORTABILITY. **Obligation:** project requirement.

**Profile:** Cargo packages. Extend [RUST-053](#rust-053) and [RUST-055](#rust-055).

Declare the workspace resolver deliberately, including in virtual workspaces. Record compiler, target, package,
features and lockfile for each supported configuration. Inspect host build dependencies and proc macros separately
from target libraries. Test a minimal external consumer so workspace development dependencies cannot silently
supply required features. Treat resolver selection and an MSRV claim as different decisions.

**Rationale:** Resolver behavior depends on dependency kind, target and selected packages; a successful workspace
build does not establish every consumer's feature graph.

**Verification design:** Retain `cargo tree -e features` for failing or sensitive configurations. Build supported
minimal consumers with the declared MSRV, then inspect their own resolved graph. For resolver 3, review the
Rust-version fallback behavior; it is not a substitute for compiling with the promised compiler.

**Contextual command recipe (requires a real package):**

```sh
cargo tree -e features --target <supported-target> -p <package>
cargo check -p <package> --no-default-features --target <supported-target>
```

**Noncompliant claim:** `cargo test --workspace --all-features` proves the minimal consumer configuration.

**Source:** [Cargo resolver versions and feature unification](https://doc.rust-lang.org/cargo/reference/resolver.html).
See [RPIT-056](rust-common-pitfalls.md#rpit-056). These remain recipes until a Cargo package is introduced.

---

## Performance and machine-specific controls

An optimization must preserve the declared contracts, including timing/resource constraints, and outperform a
maintained reference under a representative experiment. Rust is normally ahead-of-time compiled; there is no
universal LuaJIT-like warm-up requirement. Distinguish process startup, cache/page warming, lazy initialization
and steady state. A runtime code generator needs its own execution, invalidation and W^X policy.

Each `RPERF` control applies when making its corresponding performance claim. The review record identifies the
hypothesis, source/toolchain/target, workload, reference, samples, correctness results, resource changes and
acceptance criterion. Native tuning belongs to its backend owner, with portable public behavior unchanged.

---

<a id="rperf-001"></a>

### RPERF-001: Measure the deployed operation

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Measure end-to-end latency and throughput alongside the kernel. Include construction, copying, allocation,
shutdown and failure paths when the user pays those costs. Keep raw samples and report tails with sample count,
timer resolution and variability. An observed maximum is not WCET. Use repeated baseline/candidate runs and
predeclared regression thresholds. Context: [Performance Book: profiling][profiling].

**Rationale:** A kernel improvement can hide a more expensive setup or cleanup phase.

**Verification design:** Measure startup and complete lifecycle separately; retain sample counts and timer resolution.

#### Local examples

**Experiment design (not a measured result):**

```text
same workload -> baseline/candidate alternation -> raw samples -> latency distributions
```

**Noncompliant claim or experiment:**

```text
time one warm candidate run; compare with a cold baseline
```

---

<a id="rperf-002"></a>

### RPERF-002: Record the effective machine and build

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Record rustc/LLVM, optimization, LTO, codegen units, panic strategy, overflow checks, target features, allocator,
OS, CPU topology, affinity, frequency policy, SMT and speculation mitigations. Keep debug builds out of release
speed claims. Profile-guided optimization needs representative training data and reproducible profile inputs.
Verify deployed instruction compatibility. Context: [build configuration][perf-build].

**Rationale:** Compiler and machine policy can change costs without any source-code change.

**Verification design:** Compare run identities before interpreting timing differences.

#### Local examples

**Experiment design (not a measured result):**

```text
source + rustc + flags + allocator + CPU + affinity + mitigation state -> run identity
```

**Noncompliant claim or experiment:**

```text
compare builds with different target-cpu settings without recording them
```

---

<a id="rperf-003"></a>

### RPERF-003: Prefer algorithmic and ownership improvements

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Remove repeated work and unnecessary copying before unsafe indexing or assembly. Compare complexity across
small, large, skewed and adversarial inputs. Partition state by owner or CPU where feasible, then measure
aggregation and cross-owner frees. A local fast path must include its slow/reclamation costs in the experiment.

**Rationale:** Removing repeated work often improves scaling without adding a new unsafe obligation.

**Verification design:** Sweep input size and contention; include owner handoff and reclamation costs.

#### Local examples

**Experiment design (not a measured result):**

```text
parse configuration once -> bounded per-owner work -> measured aggregation
```

**Noncompliant claim or experiment:**

```text
replace checked indexing while retaining repeated full-table scans
```

---

<a id="rperf-004"></a>

### RPERF-004: Account for allocation and container tradeoffs

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Choose `Box` for ownership/indirection, `Rc` for single-thread sharing, `Arc` for justified cross-thread sharing,
and `Cow` when retaining a borrowed representation avoids common copies. `Cow` may allocate on mutation.
Select `Vec`, ordered maps, hash maps or bounded containers by access, determinism and growth requirements.
Measure retained capacity, fragmentation and relocation; segmented storage can trade locality for stable growth.
Context: [heap allocations][heap].

**Rationale:** Fewer allocations can still mean more retained memory or copying.

**Verification design:** Measure allocations, peak/retained capacity and lifetime under production providers.

#### Local examples

**Experiment design (not a measured result):**

```text
borrowed read: &[u8]
owned growable bytes: Vec<u8>
shared cross-thread owner: Arc<T>
borrow-until-mutation: Cow
```

**Noncompliant claim or experiment:**

```text
Arc for every value, even when one caller owns it exclusively
```

---

<a id="rperf-005"></a>

### RPERF-005: Control monomorphization and hot code size

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Measure runtime, compile time and binary size together. Generic adapters can call a smaller concrete core;
dynamic dispatch can reduce duplicated code while adding an indirect call. Keep rare complex paths out of line
when profiles justify it. Review `#[inline]`, especially `#[inline(always)]`, as an evidence-based decision.
Do not infer an instruction sequence from source appearance. Context: [machine-code inspection][machine-code].

**Rationale:** Machine code grows with instantiated implementations, affecting build and instruction-cache cost.

**Verification design:** Compare code size, compile time, generated code and runtime on representative consumers.

#### Local examples

**Experiment design (not a measured result):**

```text
small generic facade -> concrete hot core -> out-of-line rare path
```

**Noncompliant claim or experiment:**

```text
inline(always) on every generic helper without a profile
```

---

<a id="rperf-006"></a>

### RPERF-006: Remove bounds checks through provable structure first

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Use slices, iterators, chunks and a validated shared bound so the compiler can reason about accesses.
Retain a checked implementation as the oracle. `get_unchecked` requires a complete local bounds proof and a
measured benefit after generated-code inspection; a benchmark win cannot waive its unsafe contract.
Context: [bounds checks][bounds].

**Rationale:** Expressed bounds can remove redundant checks without transferring proof obligations to every caller.

**Verification design:** Inspect generated checks and test boundaries before considering unsafe indexing.

#### Local examples

**Experiment design (not a measured result):**

```text
validated shared range -> slice iterator -> checked reference comparison
```

**Noncompliant claim or experiment:**

```text
get_unchecked used because all current tests happen to pass
```

---

<a id="rperf-007"></a>

### RPERF-007: Give write-hot cache lines an owner

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Measure false sharing before padding. Separate independent locks, counters and compact flags when coherence
traffic explains a bottleneck. State target cache-line assumptions; one line of padding may not account for
adjacent-line prefetch. Keep layout tuning internal and include its larger memory footprint in the result.
Context: [Atomics and Locks: hardware][hardware].

**Rationale:** Sharing a coherence unit couples otherwise independent writers.

**Verification design:** Use contention measurements and access-layout records; include memory overhead.

#### Local examples

**Experiment design (not a measured result):**

```text
writer A counter -> measured isolated placement
writer B counter -> measured isolated placement
```

**Noncompliant claim or experiment:**

```text
add a hard-coded padding width to every public struct
```

---

<a id="rperf-008"></a>

### RPERF-008: Reduce coherence traffic and synchronize in batches

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Avoid repeated shared writes that convey no new information. Consider per-owner statistics and deferred
aggregation. Select batch size using throughput, fairness, memory and maximum queue delay. A remote free,
`Arc` clone/drop or atomic counter update belongs in the synchronization budget, even when the source is short.
Test under the deployed contention topology.

**Rationale:** Batching trades synchronization frequency against latency and retained work.

**Verification design:** Measure throughput, tails, queue depth and cross-owner free cost.

#### Local examples

**Experiment design (not a measured result):**

```text
bounded local batch -> one publication -> measured drain interval
```

**Noncompliant claim or experiment:**

```text
unbounded batch accumulation to minimize atomic operations
```

---

<a id="rperf-009"></a>

### RPERF-009: Treat waits and read-mostly schemes as workload decisions

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Compare locks, bounded spinning, parking, channels and read-mostly schemes using reader/writer mix and tails.
Document wakeup, starvation and priority-inversion behavior. Epoch or RCU-like reclamation needs bounded-retention
and shutdown policies. Raw atomics remain inside semantic operations reviewed under RUST-040 and RUST-041.

**Rationale:** Progress and reclamation behavior depend on the actual reader/writer mix.

**Verification design:** Test starvation, oversubscription, retirement growth and shutdown.

#### Local examples

**Experiment design (not a measured result):**

```text
read-mostly workload -> retention budget -> chosen wait/wake protocol
```

**Noncompliant claim or experiment:**

```text
replace locks with spinning and declare every path wait-free
```

---

<a id="rperf-010"></a>

### RPERF-010: Diagnose access geometry with target evidence

**Class:** PERFORMANCE. Apply the scope and requirement words below.

For hot loads/stores, investigate alignment, split boundaries, store-to-load forwarding geometry, store-buffer
pressure and false 4 KiB aliasing only after counters or controlled experiments identify a cause. Atomic
operands must satisfy the target's alignment and atomicity contract; never construct a split or misaligned
atomic by packed representation. Record exact access sizes and offsets.

**Rationale:** A source-level load or store can cross hardware boundaries that alter its cost or validity.

**Verification design:** Check atomic alignment first; then vary geometry with fixed workload and target.

#### Local examples

**Experiment design (not a measured result):**

```text
access offset + width + alignment -> target counter hypothesis -> controlled experiment
```

**Noncompliant claim or experiment:**

```text
pack atomics into an unaligned wire-format struct
```

---

<a id="rperf-011"></a>

### RPERF-011: Plan NUMA and translation locality together

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Coordinate CPU affinity, first-touch memory placement, IRQ/device locality and cross-node traffic at the
platform owner. Measure TLB/page-walk cost separately from data-cache misses. Page size, residency and
prefaulting affect deterministic latency. Cache coloring and TLB invalidation are allocator/kernel experiments;
user-space Rust cannot claim control it does not have.

**Rationale:** Translation and topology costs require different evidence from data-cache locality.

**Verification design:** Measure remote accesses, page walks, residency and migration under the deployment policy.

#### Local examples

**Experiment design (not a measured result):**

```text
CPU owner + memory placement + page policy + IRQ/device locality -> experiment
```

**Noncompliant claim or experiment:**

```text
claim NUMA improvement after only changing a Rust struct field order
```

---

<a id="rperf-012"></a>

### RPERF-012: Measure branch and dispatch choices

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Compare branches and branchless alternatives under realistic distributions. Do not use UB-producing unchecked
assumptions to remove a branch. Bind stable indirect targets outside inner loops when measurement supports it.
Investigate deep call chains, return prediction, branch hints and code alignment as target-specific hypotheses.
Runtime patching requires an instruction-cache, concurrency and patch-geometry protocol.

**Rationale:** Removing a branch can add work or worsen prediction for common inputs.

**Verification design:** Record input distribution, code size and branch/indirect-target observations.

#### Local examples

**Experiment design (not a measured result):**

```text
representative branch distribution -> branch/branchless candidates -> equal outputs
```

**Noncompliant claim or experiment:**

```text
replace every conditional with branchless arithmetic
```

---

<a id="rperf-013"></a>

### RPERF-013: Bound software and hardware prefetch experiments

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Specify access validity, prefetch distance, reuse and cache pollution. Overlap independent work with long-latency
loads when dependencies allow it. Record hardware prefetcher settings and working-set distribution; a change
that helps one stride can harm another. Keep unsafe intrinsics inside a reviewed backend and preserve bounds.

**Rationale:** Prefetch can consume bandwidth and evict useful data before the consumer reaches it.

**Verification design:** Vary distance and working set; retain bounds and compare pollution effects.

#### Local examples

**Experiment design (not a measured result):**

```text
valid access range + prefetch distance + reuse window + target settings
```

**Noncompliant claim or experiment:**

```text
prefetch arbitrarily beyond the allocation to hide every miss
```

---

<a id="rperf-014"></a>

### RPERF-014: Qualify streaming and device stores

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Use non-temporal stores only with measured streaming reuse and target ordering evidence. Complete cache-line
streams when practical for write-combining paths, and test alignment, tails and partial lines. DMA buffers
need a hardware owner for cache maintenance and ownership handoffs; a Rust borrow alone cannot stop a device
from accessing memory.

**Rationale:** Streaming and DMA behavior depend on device and cache-coherence contracts.

**Verification design:** Test aligned/misaligned starts, tails, partial lines and required device maintenance.

#### Local examples

**Experiment design (not a measured result):**

```text
owned buffer -> complete-line stream -> ordering handoff -> measured reuse
```

**Noncompliant claim or experiment:**

```text
use non-temporal stores for a small buffer reread immediately
```

---

<a id="rperf-015"></a>

### RPERF-015: Centralize specialization and prove backend selection

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Keep a portable independent reference and one dispatch owner. Check CPU/OS support before entering a
`#[target_feature]` backend. Differential-test every supported implementation, including tails, alignment,
feature-disabled fallbacks and variable vector lengths where applicable. Tests must observe which backend
ran; “the test passed” cannot demonstrate specialized execution.

**Rationale:** A passing fallback test does not establish that a specialized backend executed.

**Verification design:** Observe selection and exercise each supported backend without executing unsupported
instructions.

#### Local examples

**Experiment design (not a measured result):**

```text
forced backend ID -> oracle comparison -> target capability check -> candidate
```

**Noncompliant claim or experiment:**

```text
dispatch to the portable fallback and report SIMD coverage
```

---

<a id="rperf-016"></a>

### RPERF-016: Invalidate cached specialization exactly

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Cache keys include the semantic input, target capabilities, code/configuration identity and lifetime domain
needed by the specialization. Synchronize replacement and drain users before release. For generated executable
memory, control writable/executable transitions and instruction-cache synchronization through the platform API.
Do not reuse pointers after their owning module or code allocation has gone away.

**Rationale:** A cached function is valid only while its code and semantic assumptions remain current.

**Verification design:** Change each key dimension and test replacement with active users.

#### Local examples

**Experiment design (not a measured result):**

```text
key + retained code generation -> invoke -> release -> retire after drain
```

**Noncompliant claim or experiment:**

```text
reuse a code pointer after plugin unload because its address did not change
```

---

<a id="rperf-017"></a>

### RPERF-017: Preserve an independent oracle and cost limits

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Compare candidate outputs and errors to an independently understandable implementation, with exact or
explicitly tolerated numeric results. Prevent benchmark elimination with consumed results and appropriate
harness barriers; `black_box` is not a correctness proof. Track latency, throughput, allocations, peak memory,
stack, code size and compilation cost according to the change's claim.

**Rationale:** Two implementations can agree while sharing the same defect or ignored work.

**Verification design:** Compare independent results and check resource limits alongside timing.

#### Local examples

**Experiment design (not a measured result):**

```text
simple oracle -> expected output <- separately structured candidate
```

**Noncompliant claim or experiment:**

```text
reference and candidate both call the same optimized kernel
```

---

<a id="rperf-018"></a>

### RPERF-018: Store the optimization decision with its owner

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Retain raw-data location, scripts, build identity, measurement uncertainty, target coverage and the acceptance
or rejection decision. Keep unsupported machine claims visible. Remeasure after compiler, allocator, topology
or workload changes. Compiler reports and hardware counters explain observations; they do not replace
contract tests or the deployment benchmark.

**Rationale:** Future maintainers need enough evidence to reproduce or reject the original explanation.

**Verification design:** Reproduce from the saved record and identify unsupported target claims.

#### Local examples

**Experiment design (not a measured result):**

```text
owner + hypothesis + scripts + raw data + constraints + decision
```

**Noncompliant claim or experiment:**

```text
commit only a percent speedup without workload or source identity
```

---

<a id="restricted-facilities"></a>

## Appendix A. Canonical RBAN register

These entries identify review boundaries. “Restricted” permits an approved use satisfying the named rule;
“prohibited” forbids the stated use. A wrapper with a different name does not evade the restriction.

| ID | Facility or behavior | Policy and required alternative |
| --- | --- | --- |
| RBAN-001 | Unproved `unwrap`, `expect`, unchecked unwrap | Prohibited in production; RUST-007 and checked matching. |
| RBAN-002 | Unjustified unsafe or unsafe impl | Prohibited; RUST-003, RUST-010 and a complete invariant proof. |
| RBAN-003 | Unchecked indexing, `unreachable_unchecked` | Restricted to proved invariants and measured need; RPERF-006. |
| RBAN-004 | `transmute`, zeroing arbitrary typed values | Restricted; RUST-030 and RUST-031, prefer typed conversion. |
| RBAN-005 | `static mut`, process-global mutation | Restricted platform owner; RUST-015 and RUST-044. |
| RBAN-006 | Raw owner reconstruction from foreign memory | Restricted to exact allocator/ownership contract; RUST-024. |
| RBAN-007 | Panic as expected failure; exit/abort in libraries | Prohibited routine handling; RUST-005 and RUST-006. |
| RBAN-008 | Blocking guards across `.await` | Prohibited; RUST-037. Async mutexes require their own rationale. |
| RBAN-009 | Unbounded growth, spawning or retries on input | Prohibited; enforce RUST-025, RUST-027 and RUST-049. |
| RBAN-010 | Shell interpolation and unauthorized loading | Prohibited on untrusted input; RUST-048 and RUST-051. |
| RBAN-011 | Deterministic randomness for secrets | Prohibited; use the qualified source in RUST-047. |
| RBAN-012 | Blanket warning/formatter suppression | Prohibited; scoped justified exceptions under RUST-001 and RUST-002. |
| RBAN-013 | Public-ABI promises from default Rust layout | Prohibited; RUST-011, RUST-013 and a versioned interface. |
| RBAN-014 | `mem::forget`/`ManuallyDrop` as ordinary cleanup | Restricted to a documented transfer/leak protocol; RUST-026. |
| RBAN-015 | Unsigned/width casts without range semantics | Prohibited at external boundaries; RUST-012 and RUST-020. |
| RBAN-016 | Debug-only checks protecting unsafe access | Prohibited; establish release invariants before access. |
| RBAN-017 | Volatile as synchronization | Prohibited; RUST-040 and a separate device contract. |
| RBAN-018 | Global “all restriction lints” policy | Prohibited without individual review; restrictions may conflict. |

---

## Tooling and verification

Run commands from a real Cargo workspace with its pinned toolchain and reviewed lockfile. Use the repository
cache wrapper for local artifacts. The following recipe assumes every declared feature can coexist; if not,
replace `--all-features` with each supported set and test invalid combinations for the expected diagnostic.

```sh
cargo fmt --all -- --check
cargo clippy --workspace --all-targets --all-features --locked -- -D warnings
cargo test --workspace --all-features --locked
cargo test --workspace --all-features --release --locked
cargo test --workspace --all-features --doc --locked
RUSTDOCFLAGS='-D warnings' cargo doc --workspace --all-features --no-deps --locked
```

`--all-targets` means Cargo target kinds, not every CPU/OS target triple. Add explicit cross-target jobs and
execute on the target or a qualified emulator. `--all-features` does not cover absent features. Add default,
`--no-default-features`, supported minimal combinations, MSRV and each native ABI. A host test harness may
use `std` for a `no_std` library; separately compile the library for its actual target.

| Gate | Scope and operating rule | Limit |
| --- | --- | --- |
| rustfmt | Pinned formatter and style edition. | Presentation only. |
| rustc and Clippy | Same compiler family, required warning-clean profiles. | Do not establish soundness. |
| Unit, integration and rustdoc tests | Contracts and executable examples; run doctests explicitly. | Only observed inputs and paths. |
| Miri | Pin a supported nightly; `cargo +<nightly> miri test` on compatible targets. | Limited host/FFI support; no proof for unexecuted paths. |
| cargo-nextest | Pinned test runner for isolation/scheduling and reports. | Keep `cargo test --doc`; not a soundness checker. |
| cargo-fuzz | Pinned toolchain and bounded harness; retain corpus and minimized cases. | Campaign duration and reachable paths limit evidence. |
| Sanitizers | Target-supported sanitizer profile, including compatible native instrumentation. | Instrumentation/target coverage varies. |
| Concurrency model checker | Model the actual atomic/lock protocol with declared bounds. | A simplified model needs a link back to implementation. |
| cargo-deny | Review advisories, licenses, bans and source policy. | Depends on configured graph and database. |
| cargo-audit | Review the locked dependency graph and dated RustSec data. | Known advisories are not all vulnerabilities. |
| cargo-semver-checks | Compare with an identified release and feature configuration. | Behavior, ABI and all compatibility cases need review. |
| Native ABI/export/hardening checks | Inspect archives/shared objects and foreign consumers. | Target-specific evidence. |
| Formal/product qualification | Named properties, assumptions and qualified tools. | Only the demonstrated scope. |

Tool sources: [Miri][miri], [cargo-fuzz][fuzz], [sanitizers][sanitizers], [cargo-deny][deny],
[RustSec][rustsec], [cargo-semver-checks][semver-tool], [cargo-nextest][nextest] and [rustdoc][rustdoc].
Missing required tools fail the
selected gate; optional or unsupported checks need an explicit not-run record. Do not install unpinned
“latest” tools as part of a reproducibility claim.

---

<a id="complete-checked-example"></a>

## Appendix B. Complete local-contract example

Save this complete library as `bounded_buffer.rs`. It uses safe Rust, private state, `Result`, bounded growth
and a commit-after-validation rule. `try_append` has no logical mutation on a reported error. It does not
promise recovery from arbitrary process failure or a malicious allocator. The caller chooses the limit;
a production ingress adapter must cap that choice under its own resource budget.

<!-- example-file: bounded_buffer.rs -->
```rust
use std::collections::TryReserveError;
use std::fmt;

/// An owned byte buffer with a caller-selected logical limit.
#[derive(Debug)]
pub struct Buffer {
    bytes: Vec<u8>,
    limit: usize,
}

/// Failure to append bytes without exceeding the resource contract.
#[derive(Debug)]
pub enum AppendError {
    Limit,
    Allocation(TryReserveError),
}

impl fmt::Display for AppendError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Limit => formatter.write_str("buffer limit exceeded"),
            Self::Allocation(error) => write!(formatter, "buffer reservation failed: {error}"),
        }
    }
}

impl std::error::Error for AppendError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Self::Limit => None,
            Self::Allocation(error) => Some(error),
        }
    }
}

impl Buffer {
    /// Constructs an empty buffer without reserving payload storage.
    ///
    /// # Examples
    /// ```
    /// use bounded_buffer::Buffer;
    ///
    /// let mut buffer = Buffer::new(4);
    /// buffer.try_append(b"ab")?;
    /// assert_eq!(buffer.as_bytes(), b"ab");
    /// # Ok::<(), bounded_buffer::AppendError>(())
    /// ```
    #[must_use]
    pub fn new(limit: usize) -> Self {
        Self {
            bytes: Vec::new(),
            limit,
        }
    }

    /// Borrows the initialized bytes until the next mutable borrow.
    #[must_use]
    pub fn as_bytes(&self) -> &[u8] {
        &self.bytes
    }

    /// Appends bytes, preserving the existing contents on error.
    ///
    /// May allocate while reserving capacity. Does not perform I/O.
    ///
    /// # Errors
    /// Returns `Limit` for length overflow or a logical limit violation,
    /// and `Allocation` when the required reservation fails.
    pub fn try_append(&mut self, payload: &[u8]) -> Result<(), AppendError> {
        let new_len = self
            .bytes
            .len()
            .checked_add(payload.len())
            .ok_or(AppendError::Limit)?;
        if new_len > self.limit {
            return Err(AppendError::Limit);
        }

        self.bytes
            .try_reserve(payload.len())
            .map_err(AppendError::Allocation)?;
        self.bytes.extend_from_slice(payload);
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::{AppendError, Buffer};

    #[test]
    fn rejected_append_preserves_contents() {
        let mut buffer = Buffer::new(4);
        buffer.try_append(b"ab").expect("fixture fits");
        assert!(matches!(buffer.try_append(b"cde"), Err(AppendError::Limit)));
        assert_eq!(buffer.as_bytes(), b"ab");
        buffer.try_append(b"cd").expect("exact boundary fits");
        assert_eq!(buffer.as_bytes(), b"abcd");
    }

    #[test]
    fn empty_payload_fits_zero_capacity() {
        let mut buffer = Buffer::new(0);
        buffer.try_append(b"").expect("empty input fits");
        assert!(matches!(buffer.try_append(b"x"), Err(AppendError::Limit)));
        assert!(buffer.as_bytes().is_empty());
    }
}

// EOF
```

The example verifies ordinary logical rejection. It does not deterministically force allocator failure;
RUST-025 requires an injected allocation policy or a qualified harness when that claim is part of a product.
No documentation snippet marked `text` should be compiled as a Rust example. Compile-fail cases need an
isolated harness that checks the intended diagnostic rather than accepting any compilation failure.

### Example validation record

Validation on 2026-09-22 used four extracted libraries: `bounded_buffer`, `raw_input`, `composition` and
`byte_count`. The temporary workspace declares edition 2024 and `rust-version = "1.85"`, has no external
crate dependencies and lives under `.cache/tests/rust-guide/`.

| Check | Observed result |
| --- | --- |
| rustc 1.97.1 and Cargo 1.97.1, host Linux x86_64 | Eight unit tests and two rustdoc examples passed. |
| rustc/Cargo 1.85.1, same host | The same eight unit tests and two rustdoc examples passed. |
| Optimized release tests, rustc 1.97.1 | Eight unit tests and two rustdoc examples passed. |
| rustfmt 1.9.0, edition/style edition 2024 | Four complete source files passed the formatting check. |
| Clippy 0.1.97 | All targets passed `-D warnings`, `undocumented_unsafe_blocks` and `missing_safety_doc` checks. |
| rustdoc, rustc 1.97.1 | Documentation built with warnings denied. |
| Negative lifetime example, rustc 1.97.1 | Compilation failed with the expected E0515 diagnostic. |

To reproduce after extraction, create one temporary package per named source file, using that name as the
crate name and the file as `src/lib.rs`. Use a resolver-3 workspace containing those packages. Run the Cargo
recipes in the tooling section against its manifest, plus the explicit safety lints used above:

```sh
cargo clippy --workspace --all-targets --all-features --offline -- \
    -D warnings -D clippy::undocumented_unsafe_blocks -D clippy::missing_safety_doc
```

Keep the expected-failure snippet outside the ordinary packages and check its diagnostic separately.
Contextual snippets require the types and conditions stated in their owning section; negative fragments
must not be executed. The examples do not qualify native FFI, other targets, Miri, fuzzing, sanitizers,
product assurance or performance. No Rust CI runner was added to the repository by this documentation change.

---

<a id="reference-candidate"></a>

## Appendix C. Maintained reference and candidate

Save this complete library as `byte_count.rs`. Both implementations count a byte value in a borrowed slice
without allocating. The reference uses a scalar loop; the candidate separates complete chunks and a tail.
The test varies the length, starting offset and searched value. No measured speedup is claimed: the candidate
still needs the RPERF experiment before adoption. Safe chunking alone does not imply SIMD generation.

<!-- example-file: byte_count.rs -->
```rust
/// Counts occurrences with a simple scalar loop used as the reference.
#[must_use]
pub fn count_reference(bytes: &[u8], needle: u8) -> usize {
    let mut count = 0;
    for byte in bytes {
        if *byte == needle {
            count += 1;
        }
    }
    count
}

/// Counts occurrences through complete chunks and a checked remainder.
#[must_use]
pub fn count_candidate(bytes: &[u8], needle: u8) -> usize {
    let mut chunks = bytes.chunks_exact(8);
    let complete: usize = chunks
        .by_ref()
        .map(|chunk| chunk.iter().filter(|byte| **byte == needle).count())
        .sum();
    let tail = chunks
        .remainder()
        .iter()
        .filter(|byte| **byte == needle)
        .count();
    complete + tail
}

#[cfg(test)]
mod tests {
    use super::{count_candidate, count_reference};

    #[test]
    fn candidate_matches_reference_for_offsets_and_tails() {
        let mut storage = [0_u8; 80];
        for (index, byte) in storage.iter_mut().enumerate() {
            *byte = [0, 1, 255][index % 3];
        }
        for offset in 0..8 {
            for len in 0..=65 {
                let input = &storage[offset..offset + len];
                for needle in [0, 1, 2, 255] {
                    assert_eq!(
                        count_candidate(input, needle),
                        count_reference(input, needle),
                        "offset={offset}, len={len}, needle={needle}"
                    );
                }
            }
        }
    }
}

// EOF
```

---

<a id="restricted-examples"></a>

## Appendix D. Examples for every RBAN entry

The snippets are contextual replacement patterns. They require the owning operation's types and contracts.

---

<a id="rban-001"></a>

### RBAN-001: Unproved `unwrap`, `expect`, unchecked unwrap

**Class:** RESTRICTED_FACILITY. **Action:** Prohibited in production; RUST-007 and checked matching.

#### Local examples

**Contextual replacement example:**

```rust
let value = input.parse::<usize>().map_err(Error::Parse)?;
```

---

<a id="rban-002"></a>

### RBAN-002: Unjustified unsafe or unsafe impl

**Class:** RESTRICTED_FACILITY. **Action:** Prohibited; RUST-003, RUST-010 and a complete invariant proof.

#### Local examples

**Contextual replacement example:**

```rust
// SAFETY: The documented owner, bounds and aliasing proof applies here.
// Replace this review sketch with the facts established at the actual call.
```

---

<a id="rban-003"></a>

### RBAN-003: Unchecked indexing, `unreachable_unchecked`

**Class:** RESTRICTED_FACILITY. **Action:** Restricted to proved invariants and measured need; RPERF-006.

#### Local examples

**Contextual replacement example:**

```rust
let byte = bytes.get(index).ok_or(Error::Bounds)?;
```

---

<a id="rban-004"></a>

### RBAN-004: `transmute`, zeroing arbitrary typed values

**Class:** RESTRICTED_FACILITY. **Action:** Restricted; RUST-030 and RUST-031, prefer typed conversion.

#### Local examples

**Contextual replacement example:**

```rust
let tag = Tag::try_from(raw_tag)?;
```

---

<a id="rban-005"></a>

### RBAN-005: `static mut`, process-global mutation

**Class:** RESTRICTED_FACILITY. **Action:** Restricted platform owner; RUST-015 and RUST-044.

#### Local examples

**Contextual replacement example:**

```rust
let service = Service::new(config);
```

---

<a id="rban-006"></a>

### RBAN-006: Raw owner reconstruction from foreign memory

**Class:** RESTRICTED_FACILITY. **Action:** Restricted to exact allocator/ownership contract; RUST-024.

#### Local examples

**Contextual replacement example:**

```rust
// Keep the native pointer in an owner whose Drop calls the paired
// native destroy operation; do not reconstruct an unrelated Box or Vec.
```

---

<a id="rban-007"></a>

### RBAN-007: Panic as expected failure; exit/abort in libraries

**Class:** RESTRICTED_FACILITY. **Action:** Prohibited routine handling; RUST-005 and RUST-006.

#### Local examples

**Contextual replacement example:**

```rust
return Err(RequestError::InvalidInput);
```

---

<a id="rban-008"></a>

### RBAN-008: Blocking guards across `.await`

**Class:** RESTRICTED_FACILITY. **Action:** Prohibited; RUST-037. Async mutexes require their own rationale.

#### Local examples

**Contextual replacement example:**

```rust
let request = { state.lock()?.make_request() };
send(request).await?;
```

---

<a id="rban-009"></a>

### RBAN-009: Unbounded growth, spawning or retries on input

**Class:** RESTRICTED_FACILITY. **Action:** Prohibited; enforce RUST-025, RUST-027 and RUST-049.

#### Local examples

**Contextual replacement example:**

```rust
limits.check_bytes(payload.len())?;
queue.try_send(request)?;
```

---

<a id="rban-010"></a>

### RBAN-010: Shell interpolation and unauthorized loading

**Class:** RESTRICTED_FACILITY. **Action:** Prohibited on untrusted input; RUST-048 and RUST-051.

#### Local examples

**Contextual replacement example:**

```rust
Command::new(tool).arg("--").arg(path).status()?;
```

---

<a id="rban-011"></a>

### RBAN-011: Deterministic randomness for secrets

**Class:** RESTRICTED_FACILITY. **Action:** Prohibited; use the qualified source in RUST-047.

#### Local examples

**Contextual replacement example:**

```rust
approved_entropy.fill(&mut secret_bytes)?;
```

---

<a id="rban-012"></a>

### RBAN-012: Blanket warning/formatter suppression

**Class:** RESTRICTED_FACILITY. **Action:** Prohibited; scoped justified exceptions under RUST-001 and RUST-002.

#### Local examples

**Contextual replacement example:**

```rust
#[expect(clippy::unused_async, reason = "trait contract requires async")]
async fn ready(&self) {}
```

---

<a id="rban-013"></a>

### RBAN-013: Public-ABI promises from default Rust layout

**Class:** RESTRICTED_FACILITY. **Action:** Prohibited; RUST-011, RUST-013 and a versioned interface.

#### Local examples

**Contextual replacement example:**

```rust
#[repr(C)]
struct ByteView {
    data: *const u8,
    len: usize,
}
```

---

<a id="rban-014"></a>

### RBAN-014: `mem::forget`/`ManuallyDrop` as ordinary cleanup

**Class:** RESTRICTED_FACILITY. **Action:** Restricted to a documented transfer/leak protocol; RUST-026.

#### Local examples

**Contextual replacement example:**

```rust
writer.finish()?;
```

---

<a id="rban-015"></a>

### RBAN-015: Unsigned/width casts without range semantics

**Class:** RESTRICTED_FACILITY. **Action:** Prohibited at external boundaries; RUST-012 and RUST-020.

#### Local examples

**Contextual replacement example:**

```rust
let count = usize::try_from(wire_count).map_err(|_| Error::Length)?;
```

---

<a id="rban-016"></a>

### RBAN-016: Debug-only checks protecting unsafe access

**Class:** RESTRICTED_FACILITY. **Action:** Prohibited; establish release invariants before access.

#### Local examples

**Contextual replacement example:**

```rust
let value = values.get(index).ok_or(Error::Bounds)?;
```

---

<a id="rban-017"></a>

### RBAN-017: Volatile as synchronization

**Class:** RESTRICTED_FACILITY. **Action:** Prohibited; RUST-040 and a separate device contract.

#### Local examples

**Contextual replacement example:**

```rust
// Use the reviewed atomic/locking protocol for shared memory.
// Keep device volatile accesses in their separate hardware adapter.
```

---

<a id="rban-018"></a>

### RBAN-018: Global “all restriction lints” policy

**Class:** RESTRICTED_FACILITY. **Action:** Prohibited without individual review; restrictions may conflict.

#### Local examples

**Contextual replacement example:**

```rust
// Enable selected restriction lints individually and retain justified
// exceptions for each supported configuration.
```

---

<a id="topic-coverage"></a>

## Appendix E. Topic coverage

The topic audit used the repository C standard's implementation, performance and restricted-facility families,
its pitfalls catalogue and its module architecture. The table locates the corresponding Rust treatment.
It compares engineering coverage; readers do not need to apply C rules to interpret the Rust requirements.
Rules about headers, pointer declarator placement and C preprocessing have no direct Rust syntax equivalent.
Their underlying visibility, portability and expansion concerns appear below.

| Engineering topic | Rust treatment |
| --- | --- |
| Naming, lifecycle verbs, source text, spacing, comments | Formatting section; RUST-001–004, RUST-061–084. |
| Column budgets, indentation, blank lines and long expressions | RUST-069–077. |
| Test names, imports, source order and ignored bindings | RUST-068, RUST-078–079, RUST-083–084. |
| Local declarations, conditions, loops, result checks, exits | RUST-005–008, RUST-016, RUST-020, RUST-045. |
| Headers, imports, module privacy and peer communication | RUST-013, RUST-017; RMOD-001–010. |
| Types, constants, enums, unions and compile-time invariants | RUST-012, RUST-018, RUST-020–023, RUST-030–031. |
| Layout, representation, wire formats, ABI and alignment | RUST-011–013, RUST-023–024, RUST-029; RMOD-013–015. |
| Macros, compiler extensions, conditional compilation | RUST-052–055; RMOD-016–020. |
| Ownership, allocation, realloc, pools, arenas, cleanup | RUST-008–009, RUST-024–027, RUST-056; RMOD-011–012. |
| Provenance, pointer extent, aliasing, raw typed access | RUST-028–033; RPIT-008–017. |
| Errors, assertions, logging, callbacks, input validation | RUST-004–007, RUST-034–035, RUST-045; RPIT-014, RPIT-024. |
| Text, encoding, format boundaries and path handling | RUST-022–023, RUST-048–050. |
| Threads, locks, publication, reclamation and reentry | RUST-014–015, RUST-033, RUST-036–041; RMOD-021–023. |
| Async cancellation, partial I/O and resource inheritance | RUST-034–039, RUST-044, RUST-046. |
| Overflow, shifts, division, floating-point exceptional values | RUST-012, RUST-020–021. |
| MMIO, DMA, signals, assembly and real-time progress | RUST-042–044; RPERF-010–014; RMOD-024. |
| Authentication, authorization, filesystem/network ingress | RUST-045, RUST-048–051; RMOD-025. |
| Secrets, fault injection and protected effect sequences | RUST-050, RUST-060; RMOD-025–026. |
| Clocks, resource budgets, stack and exhaustion | RUST-025, RUST-027, RUST-043, RUST-047. |
| Crash consistency and persistent updates | RUST-045–046; RPIT-036. |
| Dependencies, generated/imported code, loaders and plugins | RUST-051–055; RMOD-017–020, RMOD-027. |
| Performance evidence, reference/backend equivalence | RPERF-001–006, RPERF-015–018; RMOD-028–029. |
| Cache lines, coherence, contention, wait/wake, remote frees | RPERF-007–010. |
| Store forwarding, split accesses, 4 KiB aliasing, store buffers | RPERF-010. |
| NUMA, TLB, residency, page walks and cache coloring | RPERF-011. |
| Branching, inlining, code size, indirect and return prediction | RPERF-005, RPERF-012. |
| Prefetch, streaming stores, write combining and device layout | RPERF-013–014. |
| ISA dispatch, vector length, code caches and invalidation | RPERF-015–016. |
| Build/link stages, exports, stripping, hardening, release ABI | RMOD-016–020, RMOD-027, RMOD-030. |
| Traceability, deviations, test modes, docs and static evidence | RUST-002, RUST-058–060; RMOD-026, RMOD-031–032. |

---

<a id="allocation-regression"></a>

## Appendix F. Allocation ownership regression

This complete `allocation_regression.rs` fixture covers [RUST-085](#rust-085) and
[RUST-086](#rust-086). It transfers only valid vectors and uses safe `push` as the initialization reference.
The raw round-trip deliberately has no intervening fallible work. It is not an FFI transfer format.
The unwind test requires `panic=unwind`; it does not establish recoverability under `panic=abort` or OOM.

```rust
use std::cell::Cell;
use std::mem::ManuallyDrop;
use std::panic::{AssertUnwindSafe, catch_unwind};
use std::rc::Rc;

fn round_trip<T>(values: Vec<T>) -> Vec<T> {
    let mut owner = ManuallyDrop::new(values);
    let pointer = owner.as_mut_ptr();
    let length = owner.len();
    let capacity = owner.capacity();

    // SAFETY: These are the unchanged parts of this Vec<T>, using the same
    // element type and global allocator. ManuallyDrop prevents a second
    // destruction. No reference, allocation or other owner escapes. The
    // original vector supplies a valid pointer for empty and ZST cases too.
    unsafe { Vec::from_raw_parts(pointer, length, capacity) }
}

struct Tracked(Rc<Cell<usize>>);

impl Drop for Tracked {
    fn drop(&mut self) {
        self.0.set(self.0.get() + 1);
    }
}

fn build(
    drops: &Rc<Cell<usize>>,
    fail_at: Option<usize>,
    panic_on_failure: bool,
) -> Result<Vec<Tracked>, ()> {
    let mut values = Vec::with_capacity(4);
    for index in 0..4 {
        if fail_at == Some(index) {
            assert!(!panic_on_failure, "injected constructor panic");
            return Err(());
        }
        values.push(Tracked(Rc::clone(drops)));
    }
    Ok(values)
}

#[test]
fn transfer_preserves_spare_capacity_and_contents() {
    let mut values = Vec::with_capacity(8);
    values.extend_from_slice(&[3_u16, 5, 8]);
    let capacity = values.capacity();
    let restored = round_trip(values);
    assert_eq!(restored, [3, 5, 8]);
    assert_eq!(restored.capacity(), capacity);
}

#[test]
fn transfer_accepts_empty_owned_storage() {
    assert!(round_trip(Vec::<u16>::new()).is_empty());
}

#[test]
fn transfer_preserves_zero_sized_element_count() {
    assert_eq!(round_trip(vec![(); 4]).len(), 4);
}

#[test]
fn rejection_drops_exactly_the_constructed_prefix() {
    for fail_at in 0..4 {
        let drops = Rc::new(Cell::new(0));
        assert!(build(&drops, Some(fail_at), false).is_err());
        assert_eq!(drops.get(), fail_at);
    }
}

#[test]
fn unwinding_drops_exactly_the_constructed_prefix() {
    for fail_at in 0..4 {
        let drops = Rc::new(Cell::new(0));
        // The fixture only inspects a drop counter after unwinding; it does
        // not reuse partially mutated application state as a valid object.
        let result = catch_unwind(AssertUnwindSafe(|| {
            let _ = build(&drops, Some(fail_at), true);
        }));
        assert!(result.is_err());
        assert_eq!(drops.get(), fail_at);
    }
}

#[test]
fn completed_buffer_retains_elements_until_owner_drops() {
    let drops = Rc::new(Cell::new(0));
    let values = build(&drops, None, false).expect("fixture has no failure");
    assert_eq!(drops.get(), 0);
    drop(values);
    assert_eq!(drops.get(), 4);
}

// EOF
```

Extract only this block into a disposable directory and run:

```sh
rustc --edition=2024 -D warnings --test allocation_regression.rs -o allocation_regression
./allocation_regression
rustc --edition=2024 -D warnings -O --test allocation_regression.rs -o allocation_regression_opt
./allocation_regression_opt
```

The six tests check successful transfer, two special layouts, rejection, unwinding and final destruction.
They do not exercise native callbacks, waker races, custom allocators or every generic element type.
Run Miri and native integration tests separately before relying on an unsafe production abstraction.

**Authoring check, 2026-09-25:** `rustc 1.95.0 (59807616e 2026-04-14)`, edition 2024, passed all six tests
with warnings denied in both ordinary and optimized builds. The matching rustfmt 1.9.0 check passed.
This is a separate run from the earlier [example validation record](#example-validation-record);
no MSRV matrix, Miri, sanitizer or native-consumer result is inferred from it.

### Boundary review evidence

The boundary sources for RUST-085 through RUST-090 were consulted on 2026-09-25. The API links follow upstream;
select documentation matching the actual compiler or dependency version. Local policy, language/API requirements
and observed test results remain separate, as in the C guide's evidence model.

| Controls | Required evidence | Evidence from this fixture |
| --- | --- | --- |
| RUST-085, RUST-086 | Allocation contract review, failure injection and applicable unsafe tooling. | Six host regression tests; no Miri claim. |
| RUST-087, RUST-088 | Scheduling/model bounds, payload visibility and reclamation review. | Not exercised. |
| RUST-089 | Compiled foreign consumer, callback lifetime and shutdown tests. | Not exercised. |
| RUST-090 | Real package, minimal consumer and supported compiler/feature matrix. | Not exercised; repository has no Cargo workspace. |

---

<a id="sources-and-revision-policy"></a>

## Links and references

Web references below were consulted on 2026-09-22. Rust documentation URLs track upstream and do not constitute
an immutable compiler specification. The repository commit containing this guide fixes the local rule wording.
For a product audit, archive the adopted source revision or content digest alongside its rule mapping, date,
profile, maturity and exceptions. A retrieval date alone does not pin future website content.

| Source | Role and adoption boundary |
| --- | --- |
| [Rust Style Guide][style], [API Guidelines][api] | Formatting and public API conventions; project rules remain explicit. |
| [Rust Reference][ub], [Rust Book][book], [Edition Guide][edition] | Semantics, idioms and migration; select the actual compiler/edition. |
| [Clippy][clippy] | Compiler-matched diagnostics; select lint policy rather than treating all lints as laws. |
| [Microsoft Pragmatic Rust Guidelines][microsoft] | Identified engineering recommendations; evaluate their library/application context. |
| [ANSSI Secure Rust Guidelines][anssi] | Security review context; consulted site is unstable and excludes async Rust. |
| [rust-analyzer style][ra-style] | Component boundaries and complexity; its internal conventions are project-specific. |
| [Standard Library Developers Guide][safety] | Safety comments and library implementation review; std-only facilities are not general APIs. |
| [Linux Rust guidelines][kernel], [Fuchsia unsafe guidance][fuchsia] | Local proof comments and full invariant-boundary review. |
| [Rustonomicon FFI][ffi], [Embedded Rust Book][embedded] | Low-level and target-specific reasoning, checked against the Reference and API contracts. |
| [Safety-Critical Rust Coding Guidelines][critical] | Developing 0.1 guidance; adopt reviewed rules individually with maturity and revision. |
| [Consortium standards matrices][matrices] | Applicability research; unfinished mappings are not conformance evidence. |
| [MISRust research][misrust] | Mapping of MISRA C++:2023 concerns; not an official Rust coding standard. |
| [FLS general scope][fls] | Compiler-validation reference with an explicit edition/compiler scope; verify it matches the target. |
| [UCG Reference][ucg] | Largely archived guidance; maintained glossary is supplementary, not sole unsafe authority. |
| [Performance Book][profiling], [Atomics and Locks][memory-order] | Measurement and synchronization reasoning; hardware observations need target validation. |
| [Effective Rust][effective], [Rust Design Patterns][patterns] | Design alternatives and tradeoffs, not universal prohibitions. |
| [Rust for Rustaceans][rustaceans] | Advanced background; check the edition's errata before relying on an example. |
| [High Assurance Rust][assurance], [Comprehensive Rust][comprehensive] | Further study and teaching; not qualification evidence. |
| [Compiler development conventions][compiler-guide] | Exhaustive matching and review practices in a compiler-specific context. |
| [Tokio shared state][tokio-state] and [select][tokio-select] | Async-profile behavior; pin the actual executor/library version. |

The FLS states a particular edition and compiler scope; do not silently apply it to another profile.
The UCG introduction directs readers to current documentation and does not supply a complete current unsafe
specification. Preserve uncertainty when aliasing or provenance details remain unsettled. For MISRA/CERT
cross-references, record the exact source edition and resolve inconsistent labels before adopting a mapping.

[nextest]: https://nexte.st/docs/running/
[style]: https://doc.rust-lang.org/style-guide/
[api-naming]: https://rust-lang.github.io/api-guidelines/naming.html
[api]: https://rust-lang.github.io/api-guidelines/checklist.html
[book]: https://doc.rust-lang.org/book/
[edition]: https://doc.rust-lang.org/edition-guide/rust-2024/index.html
[ub]: https://doc.rust-lang.org/reference/behavior-considered-undefined.html
[clippy]: https://doc.rust-lang.org/clippy/continuous_integration/index.html
[microsoft]: https://microsoft.github.io/rust-guidelines/guidelines/universal/index.html
[ms-project]: https://microsoft.github.io/rust-guidelines/guidelines/project/index.html
[anssi]: https://anssi-fr.github.io/rust-guide/
[ra-style]: https://rust-analyzer.github.io/book/contributing/style.html
[safety]: https://std-dev-guide.rust-lang.org/policy/safety-comments.html
[kernel]: https://docs.kernel.org/rust/coding-guidelines.html
[fuchsia]: https://fuchsia.dev/fuchsia-src/development/languages/rust/unsafe
[ffi]: https://doc.rust-lang.org/nomicon/ffi.html
[embedded]: https://doc.rust-lang.org/embedded-book/
[layout]: https://doc.rust-lang.org/reference/type-layout.html
[ptr]: https://doc.rust-lang.org/std/ptr/index.html
[raw-slice]: https://doc.rust-lang.org/std/slice/fn.from_raw_parts.html
[nonnull]: https://doc.rust-lang.org/std/ptr/struct.NonNull.html
[uninit]: https://doc.rust-lang.org/std/mem/union.MaybeUninit.html
[pin]: https://doc.rust-lang.org/std/pin/index.html
[send-sync]: https://doc.rust-lang.org/nomicon/send-and-sync.html
[mutex]: https://doc.rust-lang.org/std/sync/struct.Mutex.html
[ordering]: https://doc.rust-lang.org/std/sync/atomic/enum.Ordering.html
[tokio-state]: https://tokio.rs/tokio/tutorial/shared-state
[tokio-select]: https://docs.rs/tokio/latest/tokio/macro.select.html
[write]: https://doc.rust-lang.org/std/io/trait.Write.html
[volatile]: https://doc.rust-lang.org/std/ptr/fn.read_volatile.html
[features]: https://doc.rust-lang.org/cargo/reference/features.html
[semver]: https://doc.rust-lang.org/cargo/reference/semver.html
[global-alloc]: https://doc.rust-lang.org/std/alloc/trait.GlobalAlloc.html
[heap]: https://nnethercote.github.io/perf-book/heap-allocations.html
[profiling]: https://nnethercote.github.io/perf-book/profiling.html
[perf-build]: https://nnethercote.github.io/perf-book/build-configuration.html
[machine-code]: https://nnethercote.github.io/perf-book/machine-code.html
[bounds]: https://nnethercote.github.io/perf-book/bounds-checks.html
[hardware]: https://mara.nl/atomics/hardware.html
[memory-order]: https://mara.nl/atomics/memory-ordering.html
[miri]: https://github.com/rust-lang/miri
[rustsec]: https://rustsec.org/
[deny]: https://embarkstudios.github.io/cargo-deny/
[semver-tool]: https://github.com/obi1kenobi/cargo-semver-checks
[fuzz]: https://rust-fuzz.github.io/book/cargo-fuzz.html
[sanitizers]: https://doc.rust-lang.org/unstable-book/compiler-flags/sanitizer.html
[rustdoc]: https://doc.rust-lang.org/rustdoc/write-documentation/documentation-tests.html
[critical]: https://coding-guidelines.arewesafetycriticalyet.org/
[matrices]: https://coding-guidelines.arewesafetycriticalyet.org/appendices/standards-matrices/index.html
[misrust]: https://arxiv.org/abs/2605.23490
[fls]: https://rust-lang.github.io/fls/general.html
[ucg]: https://rust-lang.github.io/unsafe-code-guidelines/
[effective]: https://effective-rust.com/
[patterns]: https://rust-unofficial.github.io/patterns/
[rustaceans]: https://rust-for-rustaceans.com/
[assurance]: https://highassurance.rs/
[comprehensive]: https://google.github.io/comprehensive-rust/
[compiler-guide]: https://rustc-dev-guide.rust-lang.org/conventions.html

<!-- EOF -->


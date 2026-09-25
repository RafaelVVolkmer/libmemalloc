<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Lua Code Standard

Use this standard when writing or reviewing reusable Lua modules, repository scripts and Git hooks. It
defines names, formatting, normal control flow, values, errors, ownership, resources, native boundaries and
the evidence required for performance changes.

Read [Lua Module Architecture](lua-module-architecture.md) for dependency, port and lifecycle rules. Use
[Common Lua Pitfalls](lua-common-pitfalls.md) to connect a failure scenario to prevention controls and a
verification design. Read [Lua comments and readable layout](lua-comments.md) for source presentation
and [Lua performance and JIT](lua-performance.md) for profiling and optimization procedures.

The Lua guides define their own conventions, explanations and verification requirements. Read the
[guide index](README.md) for source layout, documentation, runtime optimization and module design.
Distinguish project conventions from language semantics and tool capabilities. Review source and tool
configuration changes against these requirements; documentation alone does not establish conformance.

<a id="rule-index"></a>

<details>
<summary><strong>On this page</strong></summary>

<details>
<summary>Executable boundary evidence</summary>

- [Coroutine cleanup regression](#coroutine-regression)

</details>

<details>
<summary>Native lifetime, suspension and runtime compatibility</summary>

- [LSTYLE-073: Account for stack indices and rooted values in native adapters](#lstyle-073)
- [LSTYLE-074: Make native suspension and error boundaries explicit](#lstyle-074)
- [LSTYLE-075: Close abandoned coroutines through their lifecycle owner](#lstyle-075)
- [LSTYLE-076: Retain the backing allocation behind every FFI pointer](#lstyle-076)
- [LSTYLE-077: Bound and drain native callback registrations](#lstyle-077)
- [LSTYLE-078: Qualify new runtime syntax across the entire tool path](#lstyle-078)

</details>

- [Scope, precedence and review records](#governance)
- [Repository baseline and effective profile](#repository-profile)
- [Example and verification policy](#example-policy)
- [Implementation controls](#implementation-controls)
- [Performance and resource evidence](#performance-controls)
- [Restricted facilities register](#restricted-facilities)
- [Lua and host responsibilities](#runtime-responsibilities)
- [Complete resource example](#resource-example)
- [Repository checks and authoring record](#repository-checks)

<details>
<summary>Profiles and governance</summary>

- [LSTYLE-001: Select the effective runtime and tool profile](#lstyle-001)
- [LSTYLE-002: Distinguish project policy from language semantics](#lstyle-002)
- [LSTYLE-003: Keep an imperative and structured core](#lstyle-003)
- [LSTYLE-004: Keep exceptions and compatibility profiles explicit](#lstyle-004)
- [LSTYLE-005: Give examples an explicit execution status](#lstyle-005)

</details>

<details>
<summary>Names and source layout</summary>

- [LSTYLE-006: Use snake_case for variables and record fields](#lstyle-006)
- [LSTYLE-007: Preserve function visibility in names](#lstyle-007)
- [LSTYLE-008: Use explicit public export tables](#lstyle-008)
- [LSTYLE-009: Name annotation types without inventing runtime types](#lstyle-009)
- [LSTYLE-010: Use module-prefixed constants and explicit enum values](#lstyle-010)
- [LSTYLE-011: Keep reserved names and internal markers separate](#lstyle-011)
- [LSTYLE-012: Preserve semantic lifecycle verbs](#lstyle-012)
- [LSTYLE-013: Use predictable file, directory and import names](#lstyle-013)
- [LSTYLE-014: Follow the repository text and formatter configuration](#lstyle-014)
- [LSTYLE-015: Break long expressions without changing their contracts](#lstyle-015)
- [LSTYLE-016: Keep statements, conditions and calls readable](#lstyle-016)
- [LSTYLE-017: Declare locals at the start of their lexical block](#lstyle-017)
- [LSTYLE-018: Avoid shadowing and misleading initialization](#lstyle-018)

</details>

<details>
<summary>Limits and control flow</summary>

- [LSTYLE-019: Apply file-size limits as review triggers](#lstyle-019)
- [LSTYLE-020: Enforce the measured cyclomatic complexity limit](#lstyle-020)
- [LSTYLE-021: Enforce the measured cognitive complexity limit](#lstyle-021)
- [LSTYLE-022: Prefer no more than five parameters](#lstyle-022)
- [LSTYLE-023: Use one normal function output](#lstyle-023)
- [LSTYLE-024: Restrict goto to forward convergence](#lstyle-024)
- [LSTYLE-025: Keep loop termination in the loop contract](#lstyle-025)
- [LSTYLE-026: Separate effects from conditions and argument ordering](#lstyle-026)
- [LSTYLE-027: Bound recursion and reentrant execution](#lstyle-027)

</details>

<details>
<summary>Values, tables and text</summary>

- [LSTYLE-028: Validate external type, shape and domain](#lstyle-028)
- [LSTYLE-029: Distinguish false, nil, zero and empty text](#lstyle-029)
- [LSTYLE-030: Use and/or only with proven value semantics](#lstyle-030)
- [LSTYLE-031: Define sequence invariants explicitly](#lstyle-031)
- [LSTYLE-032: Choose iteration order and mutation rules deliberately](#lstyle-032)
- [LSTYLE-033: Control aliasing and table mutation](#lstyle-033)
- [LSTYLE-034: Keep records explicit and immutable-by-contract](#lstyle-034)
- [LSTYLE-035: Preserve result tuple arity](#lstyle-035)
- [LSTYLE-036: Treat text as bytes unless an encoding contract says otherwise](#lstyle-036)
- [LSTYLE-037: Use literal searches for literal input](#lstyle-037)
- [LSTYLE-038: Make format and replacement strings explicit](#lstyle-038)
- [LSTYLE-039: Validate numerical domains before arithmetic](#lstyle-039)
- [LSTYLE-040: Check bounds before addition and multiplication](#lstyle-040)
- [LSTYLE-041: Specify division, remainder and bitwise semantics](#lstyle-041)
- [LSTYLE-042: Serialize values through an explicit format](#lstyle-042)

</details>

<details>
<summary>Errors, resources and state</summary>

- [LSTYLE-043: Use a project-owned status contract](#lstyle-043)
- [LSTYLE-044: Check every fallible result](#lstyle-044)
- [LSTYLE-045: Keep expected failures on normal SESE paths](#lstyle-045)
- [LSTYLE-046: Protect exception boundaries rather than every line](#lstyle-046)
- [LSTYLE-047: Centralize ownership and cleanup](#lstyle-047)
- [LSTYLE-048: Treat deterministic close as a separate profile decision](#lstyle-048)
- [LSTYLE-049: Validate before publishing mutation](#lstyle-049)
- [LSTYLE-050: Bound input, output and retained state](#lstyle-050)
- [LSTYLE-051: Do not promise ordinary recovery from every OOM](#lstyle-051)

</details>

<details>
<summary>Concurrency and metaprogramming</summary>

- [LSTYLE-052: Prefer lexical privacy over hidden metamethod effects](#lstyle-052)
- [LSTYLE-053: Control closure capture and retained references](#lstyle-053)
- [LSTYLE-054: Make coroutine suspension and resume states explicit](#lstyle-054)
- [LSTYLE-055: Reject reentry unless a contract permits it](#lstyle-055)
- [LSTYLE-056: Give GC policy and weak caches an owner](#lstyle-056)

</details>

<details>
<summary>Security and host boundaries</summary>

- [LSTYLE-057: Keep dynamic loading on a trusted boundary](#lstyle-057)
- [LSTYLE-058: Own require resolution and bootstrap paths](#lstyle-058)
- [LSTYLE-059: Keep process execution behind an argument contract](#lstyle-059)
- [LSTYLE-060: Validate file authority, not only path spelling](#lstyle-060)
- [LSTYLE-061: Keep secrets and diagnostics under a disclosure policy](#lstyle-061)
- [LSTYLE-062: Keep native and FFI details in adapters](#lstyle-062)
- [LSTYLE-063: Use explicit clock, randomness and retry contracts](#lstyle-063)
- [LSTYLE-064: Fail closed at required checks and authority gates](#lstyle-064)

</details>

<details>
<summary>Documentation and verification</summary>

- [LSTYLE-065: Document the public operation contract](#lstyle-065)
- [LSTYLE-066: Run the canonical repository Lua checks](#lstyle-066)
- [LSTYLE-067: Distinguish checked-in Lua from embedded documentation](#lstyle-067)
- [LSTYLE-068: Keep tests tied to contracts and failure states](#lstyle-068)
- [LSTYLE-069: Treat coverage and static reports as evidence](#lstyle-069)
- [LSTYLE-070: Control package and dependency provenance](#lstyle-070)
- [LSTYLE-071: Define the Lua and host responsibility boundary](#lstyle-071)
- [LSTYLE-072: Migrate existing Lua without rewriting history](#lstyle-072)

</details>

<details>
<summary>Performance evidence</summary>

- [LPERF-001: Measure the complete deployed operation](#lperf-001)
- [LPERF-002: Record runtime and machine identity](#lperf-002)
- [LPERF-003: Separate startup, steady state and collection](#lperf-003)
- [LPERF-004: Report tails and limits honestly](#lperf-004)
- [LPERF-005: Improve algorithms before local syntax](#lperf-005)
- [LPERF-006: Use bounded string assembly](#lperf-006)
- [LPERF-007: Control temporary tables and closures](#lperf-007)
- [LPERF-008: Treat local lookup caching as semantic binding](#lperf-008)
- [LPERF-009: Keep caches bounded and invalidation owned](#lperf-009)
- [LPERF-010: Measure callback and native boundary cost](#lperf-010)
- [LPERF-011: Keep an independent reference](#lperf-011)
- [LPERF-012: Separate Lua claims from native microarchitecture](#lperf-012)
- [LPERF-013: Avoid unbounded convenience in hot paths](#lperf-013)
- [LPERF-014: Review GC tuning as a system change](#lperf-014)
- [LPERF-015: Use stable regression criteria](#lperf-015)
- [LPERF-016: Retain optimization review records](#lperf-016)

</details>

<details>
<summary>Restricted facilities</summary>

- [LBAN-001: Untrusted dynamic execution](#lban-001)
- [LBAN-002: Untrusted binary chunks](#lban-002)
- [LBAN-003: Caller-controlled module resolution](#lban-003)
- [LBAN-004: Global writes and peer monkey-patching](#lban-004)
- [LBAN-005: Legacy environment-based modules](#lban-005)
- [LBAN-006: Raw shell execution](#lban-006)
- [LBAN-007: Implicit shared I/O destinations](#lban-007)
- [LBAN-008: Process termination from a library](#lban-008)
- [LBAN-009: Introspection as encapsulation bypass](#lban-009)
- [LBAN-010: Predictable random security material](#lban-010)
- [LBAN-011: Collector tricks as lifetime control](#lban-011)
- [LBAN-012: Hidden control-flow exits](#lban-012)
- [LBAN-013: Unchecked boundary results](#lban-013)
- [LBAN-014: Unlimited ingress and work](#lban-014)
- [LBAN-015: Unsafe native escape hatches](#lban-015)
- [LBAN-016: Diagnostic suppression as implementation](#lban-016)

</details>

</details>

---

<a id="governance"></a>

## Scope, precedence and review records

The standard owns normative local rules, the restricted-facility register and performance evidence. The
architecture guide owns module boundaries, permitted dependencies, lifecycle composition and release
surface. The pitfalls catalogue owns failure scenarios and verification designs; it does not introduce a
second set of hidden requirements.

Use stable `LSTYLE-*`, `LPERF-*`, `LBAN-*`, `LMOD-*` and `LPIT-*` IDs in reviews, deviations and tests.
These identifiers belong to the Lua policy. An ID identifies a control; record the repository
commit or document digest when its exact wording matters.

A **must** or imperative is a project requirement. **Should** is the expected default and needs a recorded
rationale when not followed. **May** grants permission. A **review trigger** calls for a recorded design
review, not an automatic claim that code is incorrect. Risk and obligation are separate: a presentation
violation and a native use-after-free do not have equivalent consequences.

| Class | Meaning |
| --- | --- |
| CORRECTNESS | Language semantics and satisfied functional contracts. |
| PORTABILITY | Runtime, grammar, representation, platform and native ABI assumptions. |
| SECURITY | External authority, executable input, secrets and trust boundaries. |
| SAFETY | Failure, timing or state behavior within an explicit product hazard model. |
| ARCHITECTURE | Ownership, interfaces, dependencies and lifecycle. |
| ANALYZABILITY | Reviewable rules and reproducible verification evidence. |
| PROJECT_STYLE | Names and presentation choices; not language guarantees. |

Honor the selected language and platform semantics first, then approved product safety/security constraints,
then this policy and its authoritative repository configuration. External style guides are supporting
references. A contradiction is a defect or a deviation to resolve, not permission to silently select
whichever rule is convenient. A configuration change is a reviewed policy change; this document does not
authorize weakening existing checks.

A deviation records the rule, baseline, affected paths/profiles, reason, alternatives, risk, compensating
controls, evidence, owner, required approver and expiry/review condition. No blanket lint or formatter
suppressions are introduced by this set. Do not claim certification, MISRA conformance or a
functional-safety level merely because these coding rules were followed.

---

<a id="repository-profile"></a>

## Repository baseline and effective profile

Repository: [RafaelVVolkmer/libmemalloc][repo]. Resolve tool versions from the repository lock and
configuration files. Relative links refer to this repository, not to the upstream style-guide source.

| Authority | Observed setting |
| --- | --- |
| [Toolchain lock][toolchain] | Lua 5.5.1; Selene 0.31.0; StyLua 2.5.2; LuaLS 3.19.1. |
| [EditorConfig][editorconfig] | Lua and extensionless hooks: spaces, indentation 3, width 80. |
| [StyLua configuration][stylua-config] | Lua54 grammar; width 80; Unix newlines; AutoPreferDouble. |
| [Selene configuration][selene-config] | Standard `libmemalloc-lua`. |
| [Selene API catalogue][selene-standard] | Lua 5.4 grammar; `lua51` API base with selected I/O and UTF-8 additions. |
| [LuaLS configuration][luals-config] | Runtime Lua 5.5; explicit diagnostic severities. |
| [Lua runner][check-lua] | Syntax, initialization boundary, measured complexity, dictionary, Selene, StyLua and LuaLS. |
| [Markdown policy][markdown-config] | Markdown lint configuration; ordinary prose width 120. |

**Do not collapse these into one version number.** The selected execution runtime is Lua 5.5.1; the
formatter accepts its configured Lua54 grammar; Selene uses its own declared API catalogue; LuaLS models Lua
5.5. The Selene base does not make Lua 5.1 the execution target. Conversely, LuaLS accepting a name does not
prove Selene recognizes it. Features must satisfy every applicable gate.

The catalogue adds signatures for `io.lines`, `io.stderr.write`, `utf8.codes` and `utf8.len` to its base. It
is not blanket approval of every later API such as `table.pack`, `table.unpack`, `math.type`, `string.pack`
or host-specific libraries. Qualify additions through the catalogue, parser, formatter, runtime and tests;
do not hide missing names behind global allowlists.

LuaLS marks `undefined-global` and `duplicate-set-field` as errors and `redefined-local` as a warning. The
runner invokes LuaLS with `--checklevel=Warning`. Required executables are resolved through `LIBMEMALLOC_LUA`,
`LIBMEMALLOC_LUAC`, `LIBMEMALLOC_SELENE`, `LIBMEMALLOC_STYLUA` and `LIBMEMALLOC_LUALS`.
A missing required tool is a failure. These
observations describe the retrieved configuration, not a full tool run performed while authoring these
files.

### Execution and language model

Use imperative, structured operations with explicit validation, effects, state transitions and output. Small
pure functions, closures, callbacks and data-driven dispatch are allowed when their contracts stay visible.
Metatable-driven object models need an explicit reason; this set does not require classes, inheritance,
fluent interfaces or a particular third-party framework.

Lua values are dynamically typed and objects are managed by the runtime. The runtime model does not supply C
pointer ownership, fixed table layout, deterministic resource finalization or OS-thread synchronization. The
host profile must identify its numeric model, memory/resource limits, encoding, locale, native dependencies,
clock, scheduling and yield rules. LuaLS annotations assist analysis but do not impose runtime types. See
the [Lua manual][lua55].

The baseline is a trusted hosted-tooling profile, not a hard-real-time or hostile-code sandbox profile.
LuaJIT, Luau, other Lua versions, embedded hosts and native extensions require separately named assumptions
and tests. C object-layout and microarchitecture rules remain with the native adapter. A safety- or
security-critical application needs its own hazard/threat analysis and qualification evidence beyond these
documents.

### Normal SESE and exceptional control flow

Every function declares `ret`, has one final `::function_output::` label and one final `return`. Additional
result values follow `ret`. A total predicate may use Boolean `ret`; an action uses a module-owned status,
with zero success and named negative failures. A module chunk ends with its export-table return; that is not
an early return from a function.

Only forward `goto function_output` convergence is allowed. No early function returns, backward jumps,
alternate cleanup labels, `break` or simulated `continue` are introduced. Declare locals at the start of
their lexical block and compile complete functions to catch illegal jumps into scope. Keep loops bounded and
progress visible. Nested functions have independent SESE obligations.

This is **normal source-level flow**, not a guarantee that every exception executes the label. Unprotected
errors, host termination, suspension and resource exhaustion need their own contracts. Put protection at the
owner of an exception boundary; preserve primary errors and attempt cleanup for acquired resources. `pcall`
does not by itself enforce non-yielding behavior. A qualified `<close>` profile must address close semantics
and cannot be treated as an ordinary reassignable handle. See [LSTYLE-046](#lstyle-046) through
[LSTYLE-048](#lstyle-048).

### Lua limits and conventions

| Item | Lua policy | Local explanation |
| --- | --- | --- |
| Lua indentation | Three spaces. | [Source layout](lua-comments.md#source-layout). |
| Lua width | 80 columns. | [LSTYLE-014](#lstyle-014). |
| Markdown prose | At most 120 columns. | Repository documentation convention. |
| Source size | Review above 1,000 physical lines. | [LSTYLE-019](#lstyle-019). |
| Dedicated contract size | Review above 500 lines. | [LSTYLE-019](#lstyle-019). |
| Function length | Review cohesion; no numeric cap. | [LSTYLE-020](#lstyle-020). |
| Cyclomatic complexity | Gate at 10 with the declared Lizard adapter convention. | [LSTYLE-020](#lstyle-020). |
| Cognitive complexity | Gate at 15 with the declared Lua AST convention. | [LSTYLE-021](#lstyle-021). |
| Parameter count | Prefer at most five, including context/self. | [LSTYLE-022](#lstyle-022). |
| Public function | `MODULE_lowerCamelCase`. | [LSTYLE-007](#lstyle-007). |
| Private/internal function | `module_lowerCamelCase` and lexical `local`. | [LSTYLE-007](#lstyle-007). |
| Variables and fields | `snake_case`, with meaningful unit suffixes. | [LSTYLE-006](#lstyle-006). |
| Constants and statuses | `MODULE_SCREAMING_CASE`. | [LSTYLE-010](#lstyle-010). |
| Annotated record / alias | `UpperCamelCase` / `module_name_t`. | [LSTYLE-009](#lstyle-009). |

The repository Lua runner enforces the two complexity limits using its declared metric conventions.
Other limits and presentation rules still need their stated review or tool evidence. Do not
substitute an invented numeric report for an analyzer. Source size excludes no lines unless the selected
review convention says so; a deviation records its counting and applicability rules.

### External guide integration and conflicts

| Reference | Retained contribution | Deliberate boundary |
| --- | --- | --- |
| [LuaRocks][luarocks] | Local scope, modules and three spaces. | Project function names and SESE take precedence. |
| [Kong][kong] | APIs, errors and production review. | Not its two spaces or early-return style. |
| [Roblox][roblox] | Organization, documentation and readable interfaces. | No tabs, Luau syntax or Roblox host APIs. |
| [Olivine Labs][olivine] | Style, modules and tests. | Legacy examples need current-profile review. |
| [Hisham on modules][modules] | Lexical state and module tables. | Not a peer-port architecture. |
| [Lua manuals][lua55] | Semantic authority for the selected runtime. | A manual does not choose project style. |
| [StyLua][stylua], [Selene][selene], [LuaLS][luals] | Tool behavior. | Repository settings and versions. |

Luacheck remains a possible supplementary reference, not a required repository gate introduced here.
LuaRocks the style-guide source and LuaRocks the package manager are different concerns. This set does not
install packages, add a framework or authorize new third-party dependencies.

---

<a id="example-policy"></a>

## Example and verification policy

Examples marked **contextual** show one rule in an enclosing module/function contract. They may use
previously validated values or documented ports. They are not standalone programs and must not be pasted
without their stated preconditions. All complete functions retain SESE. Intentionally noncompliant fragments
are examples to review, not approved patterns or code to execute.

Complete appendices supply named files with their imports, contracts and tests. Save only those named blocks
to a disposable fixture directory when reproducing the example. A Markdown blockquote marker `>` is not part
of Lua source; it preserves three-space Lua indentation inside the two-space Markdown document policy. Do
not copy that marker into a `.lua` file.

The current runner does not extract Markdown Lua fences. This set therefore distinguishes document structure
checks, extracted-source checks, runtime tests and full repository gates. The embedded examples use ordinary
supported APIs and Lua54-compatible syntax, but only the executed checks in the authoring record
are reported as passed.

---

<a id="implementation-controls"></a>

## Implementation controls

---

<a id="lstyle-001"></a>

### LSTYLE-001: Select the effective runtime and tool profile

**Class:** PORTABILITY / CORRECTNESS. **Obligation:** project requirement.

Use the locked Lua 5.5.1 runtime for repository qualification. Write syntax accepted by the configured Lua54
formatter and use APIs recognized by the libmemalloc-lua Selene standard, or obtain a reviewed tool-profile change.
Record these as three different constraints.

**Rationale:** LuaLS selecting Lua 5.5 does not expand the formatter grammar or Selene API catalogue. A
successful parser run is not evidence that every other check accepts a feature.

**Verification design:** Record the lock digest, tool versions, target OS, numeric representation, locale,
dependencies and command results. Reject an unsupported required feature rather than silently changing
interpreters.

**Related failure scenarios:** [LPIT-051](lua-common-pitfalls.md#lpit-051).

**Source context:** [Repository profile](#repository-profile); [Lua 5.5 manual][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> runtime: Lua 5.5.1
> formatter syntax: Lua54
> Selene standard: libmemalloc-lua, based on lua51
> LuaLS runtime: Lua 5.5
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> runtime: whichever lua happens to be on PATH
> ```

---

<a id="lstyle-002"></a>

### LSTYLE-002: Distinguish project policy from language semantics

**Class:** ANALYZABILITY. **Obligation:** project requirement.

Apply the Lua language contract before project conventions. Label portability, correctness, security,
architecture and presentation requirements separately. A project naming rule must not be described as a Lua
implementation restriction.

**Rationale:** Lua values are dynamically typed. The project does not turn Lua into C, add static memory
ownership, or make comments enforce runtime types.

**Verification design:** For every deviation, record the rule ID, baseline commit, owner, affected paths,
rationale, evidence and review condition. Correct diagnostics at their source; do not add blanket
suppressions.

**Source context:** [Governance](#governance); [Lua 5.5 manual][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> rule: LSTYLE-007
> class: PROJECT_STYLE
> reason: preserve project public API spelling
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> Lua itself requires MODULE_lowerCamelCase names.
> ```

---

<a id="lstyle-003"></a>

### LSTYLE-003: Keep an imperative and structured core

**Class:** CORRECTNESS. **Obligation:** project requirement.

Implement operations as explicit validation, state transition, effect and output stages. Permit small pure
functions, closures and data-driven dispatch when their state, errors and cost remain visible. Do not hide
the application lifecycle in metatables or a fluent DSL.

**Rationale:** Explicit stages let reviewers follow state changes and failure paths. Closures and tables
remain useful when their ownership and effects are visible.

**Verification design:** Identify every effectful call and state mutation in review. Trace one success path
and every failure path to the common output.

**Source context:** [LSTYLE-023](#lstyle-023).

#### Local examples

**Contract or layout example (not executable):**

> ```text
> validate request -> compute candidate -> perform bounded effect -> publish -> output
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> A field read silently opens a file, retries and changes global state.
> ```

---

<a id="lstyle-004"></a>

### LSTYLE-004: Keep exceptions and compatibility profiles explicit

**Class:** PORTABILITY / CORRECTNESS. **Obligation:** project requirement.

Place LuaJIT, Luau, Lua 5.1 and native-host compatibility in separately named profiles. Do not introduce
Luau types, continue statements, JIT-only FFI or Lua 5.5-only syntax into the current Lua54 source profile.

**Rationale:** Shared ancestry does not establish parser, number, standard-library, coroutine or ABI
equivalence.

**Verification design:** Test each claimed runtime separately. Record the unsupported features and keep
profile-specific code behind its owning adapter.

**Related failure scenarios:** [LPIT-025](lua-common-pitfalls.md#lpit-025).

**Source context:** [Lua 5.4 manual][lua54]; [Lua 5.5 manual][lua55]; [Roblox guide][roblox].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> portable source: current Lua54-compatible grammar
> Luau or LuaJIT backend: separate opt-in profile
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> Parse under LuaJIT and declare the source qualified for Lua 5.5.1.
> ```

---

<a id="lstyle-005"></a>

### LSTYLE-005: Give examples an explicit execution status

**Class:** ANALYZABILITY. **Obligation:** project requirement.

Distinguish complete runnable programs, contextual fragments and intentionally noncompliant examples. Full
correct functions must follow the same SESE and naming rules as production code. An illustrative fragment is
not an approved exception.

**Rationale:** A fragment may omit its enclosing module and preconditions; treating it as a runnable program
would invent guarantees.

**Verification design:** Extract complete appendices and run them. Check fragments in a declared harness. Do
not execute negative shell, loader, deletion or resource-exhaustion examples.

**Related failure scenarios:** [LPIT-052](lua-common-pitfalls.md#lpit-052).

**Source context:** [Example policy](#example-policy).

#### Local examples

**Contract or layout example (not executable):**

> ```text
> Complete program: includes setup, operation and assertions.
> Contextual fragment: requires the stated owning function or module.
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> Mark a fragment with undefined callbacks as a complete implementation.
> ```

---

<a id="lstyle-006"></a>

### LSTYLE-006: Use snake_case for variables and record fields

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use descriptive snake_case for local variables, parameters and project-owned data fields. Include units or
counts when meaningful: `_ms`, `_us`, `_ns`, `_bytes`, `_count`, `_idx` and `_pct`. Keep Boolean names affirmative.

**Rationale:** Names identify a value's role and units at its use site. Distinguish byte counts, indices
and durations before passing them across a module boundary.

**Verification design:** Compare names with their contracts and callers. Do not rename external protocol
fields without an adapter.

**Source context:** [Lua governance](lua-code-standard.md#governance).

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local timeout_ms = 250
> local payload_bytes = 0
> local retry_count = 3
> local is_ready = false
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> local TimeOut = 250
> local sz = 0
> ```

---

<a id="lstyle-007"></a>

### LSTYLE-007: Preserve function visibility in names

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use MODULE_lowerCamelCase for project public operations and module_lowerCamelCase for private or
module-internal helpers. Define private functions with local function. Use a local table to export only the
public names. The name alone provides no encapsulation.

**Rationale:** The module prefix identifies the owning API, and its case distinguishes public operations
from local helpers during review. Lexical scope and export assignments enforce the actual visibility.

**Verification design:** Inspect exported keys and the lexical scope of helpers. Treat host-defined names
and existing compatibility APIs as named boundary exceptions.

**Source context:** [LuaRocks guide][luarocks].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local function codec_isByte(value)
>    local ret = false
>
>    ret = type(value) == "number"
>       and value >= 0
>       and value <= 255
>       and value % 1 == 0
>
>    ::function_output::
>    return ret
> end
>
> local function CODEC_isByte(value)
>    local ret = false
>
>    ret = codec_isByte(value)
>
>    ::function_output::
>    return ret
> end
>
> local codec = {}
> codec.CODEC_isByte = CODEC_isByte
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> function parseValue(value)
>    return value
> end
> ```

---

<a id="lstyle-008"></a>

### LSTYLE-008: Use explicit public export tables

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Keep the module table local and export a finite, reviewed set of operations. Finish a module chunk with
return module_table. That chunk-level return is not a function-level SESE escape. Do not export private
helpers solely for tests.

**Rationale:** Lua has no C linker visibility for ordinary Lua functions. Module privacy comes from lexical
reachability and the exported object graph.

**Verification design:** Enumerate module keys in API tests. Check that state and private function
references are absent.

**Related failure scenarios:** [LPIT-004](lua-common-pitfalls.md#lpit-004),
[LPIT-043](lua-common-pitfalls.md#lpit-043).

**Source context:** [LMOD-001](lua-module-architecture.md#lmod-001); [Module guidance][modules].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local codec = {}
>
> -- Public operations are assigned here.
>
> return codec
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> _G.codec = {}
> _G.codec.private_state = {}
> ```

---

<a id="lstyle-009"></a>

### LSTYLE-009: Name annotation types without inventing runtime types

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use UpperCamelCase for documented record/class names and prefixed snake_case for aliases; a `_t`
alias suffix is allowed. Describe fields and callback signatures with LuaLS annotations. Do not describe an
annotation as runtime validation or a C ABI layout.

**Rationale:** Distinct type and value names make annotations easier to read. An annotation describes a
contract; callers still need runtime validation at external boundaries.

**Verification design:** Check annotations with LuaLS and validate untrusted values at runtime. Keep public
annotation names stable.

**Source context:** [LuaLS annotations][luals].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> ---@class CodecConfig
> ---@field capacity_bytes integer
> ---@field is_enabled boolean
>
> ---@alias codec_status_t integer
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> ---@class uint32_t
> -- This annotation forces a 32-bit unsigned runtime integer.
> ```

---

<a id="lstyle-010"></a>

### LSTYLE-010: Use module-prefixed constants and explicit enum values

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use MODULE_SCREAMING_CASE for immutable-by-contract constants and symbolic status or state values. Assign
external numeric codes explicitly. Validate sparse values by membership and masks by allowed bits. A count
sentinel is not a valid state.

**Rationale:** Lua has no C enum declaration or unsigned literal suffix. An uppercase table key does not
freeze a mutable table.

**Verification design:** Test unknown, negative, fractional and sentinel inputs. Review mutation of all
exported constant tables.

**Related failure scenarios:** [LPIT-015](lua-common-pitfalls.md#lpit-015).

**Source context:** [Lua governance](lua-code-standard.md#governance).

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local CODEC_OK = 0
> local CODEC_EINVAL = -1
> local CODEC_STATE_IDLE = 1
> local CODEC_STATE_BUSY = 2
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> local CODEC_OK = "success sometimes"
> ```

---

<a id="lstyle-011"></a>

### LSTYLE-011: Keep reserved names and internal markers separate

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Do not invent leading-underscore project names. Preserve Lua-defined `_G`, `_ENV`, `_VERSION` and metamethod
fields such as `__index` only where the language or host requires them. A reviewed portability
marker ends with `__`; it never starts with `__`.

**Rationale:** This is a project naming convention. Preserve the exact spelling of runtime names and
metamethods because the runtime looks them up by name.

**Verification design:** Review all leading-underscore names. Require an actual language or external API
purpose; do not create cosmetic pseudo-metamethods.

**Source context:** [Lua metamethods][lua55].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local metadata = { __index = {} }
> local PLATFORM_FEATURE__ = false
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> local __private_cache = {}
> local metadata = { index__ = {} }
> ```

---

<a id="lstyle-012"></a>

### LSTYLE-012: Preserve semantic lifecycle verbs

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use create/destroy for instance lifetime, init/deinit for initialization of caller-owned state, start/stop
for activity, reset for a documented state reset and close for releasing an external handle. Describe
whether a closed instance can be reused.

**Rationale:** GC reachability and semantic resource lifetime are different. A misleading verb can hide
allocation, authority or an irreversible transition.

**Verification design:** Test repeated close, use after close, restart and failed construction according to
the declared contract.

**Source context:** [Lua governance](lua-code-standard.md#governance).

#### Local examples

**Contract or layout example (not executable):**

> ```text
> create -> configured instance
> start -> active instance
> stop -> quiescent instance
> destroy -> unusable instance
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> reset silently closes a caller-owned file and changes its path.
> ```

---

<a id="lstyle-013"></a>

### LSTYLE-013: Use predictable file, directory and import names

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use snake_case for Lua filenames and project directories. Use stable dot-separated require names
corresponding to the approved source layout. Keep the Lua guide filenames in their established
kebab-case form. Preserve Git-defined hook filenames.

**Rationale:** Case-dependent names and ambiguous search locations make imports dependent on the host
filesystem.

**Verification design:** Test imports on supported platforms and reject case-only module collisions. Review
module aliases in the packaging manifest.

**Source context:** [Lua governance](lua-code-standard.md#governance).

#### Local examples

**Contract or layout example (not executable):**

> ```text
> codec/packet_parser.lua
> contracts/sink_port.lua
> .githooks/pre-commit
> docs/standards/lua/lua-code-standard.md
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> Parser.lua and parser.lua both provide the same logical module.
> ```

---

<a id="lstyle-014"></a>

### LSTYLE-014: Follow the repository text and formatter configuration

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use UTF-8, LF, a final newline, spaces and three columns per Lua indentation level. Keep Lua source at or
below 80 columns. Apply AutoPreferDouble rather than an absolute ban on single quotes. Do not add
formatter-ignore comments.

Follow [Lua comments and readable layout](lua-comments.md) for blank lines,
call/check adjacency, LDoc contracts, and the terminal `EOF` marker. The formatter
adapter checks formatter output without the required final empty line; the EOF
checker validates that line on the original file. This exception changes no code.

**Rationale:** The checked-in EditorConfig and StyLua settings outrank external guide formatting choices. A
formatter target width is not a justification for an overlong unbreakable token.

**Verification design:** Run StyLua with tools/lint/code/lua/stylua.toml and the repository EditorConfig
checker. Check extensionless Lua hooks too.

**Source context:** [EditorConfig][editorconfig]; [StyLua config][stylua-config].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local function codec_isEmpty(value)
>    local ret = false
>
>    ret = value == ""
>
>    ::function_output::
>    return ret
> end
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> local message = "one enormous unbroken source line that exceeds the policy"
> ```

---

<a id="lstyle-015"></a>

### LSTYLE-015: Break long expressions without changing their contracts

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Let StyLua choose continuation indentation and delimiter layout. Break calls and record constructors at
syntax boundaries. Split long strings only when concatenation preserves the intended bytes and performance
contract.

**Rationale:** A wrapped diagnostic must not accidentally insert whitespace into a protocol literal.
Use three spaces for each indentation level, including continuation blocks.

**Verification design:** Compare byte-sensitive string results and run the configured formatter. Count the
Lua content of examples separately from Markdown quote markers.

**Source context:** [StyLua][stylua].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local message = "The packet header is invalid; "
>    .. "check the declared payload length."
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> local token = "ab " .. "cd" -- The inserted space changes the token.
> ```

---

<a id="lstyle-016"></a>

### LSTYLE-016: Keep statements, conditions and calls readable

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use multiline control bodies and explicit call parentheses. Do not use semicolon-packed statements or clever
operator chains for control flow. Use parentheses to make mixed operators clear without overriding the
configured formatter.

**Rationale:** The reader should see each state update and decision as a separate step.

**Verification design:** Review diff-visible state changes and ambiguous arithmetic or Boolean combinations.

**Source context:** [Kong guide][kong].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local is_ready = false
> local has_capacity = true
>
> if has_capacity then
>    is_ready = true
> end
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> local is_ready=false; if true then is_ready=true end
> ```

---

<a id="lstyle-017"></a>

### LSTYLE-017: Declare locals at the start of their lexical block

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Declare a block's ordinary locals before its first executable operation. Keep the block as small as the
contract allows. Treat implicit for-loop variables and local-function bindings as Lua-specific declarations.
Introduce a nested block for a genuinely later lifetime.

**Rationale:** This groups initialization for review and prevents jumps from entering the
scope of later locals. Do not declare a function-wide cache just to avoid a small block.

**Verification design:** Inspect every forward goto against local scopes and initialization. Use separate
declarations; permit multiple assignment when receiving one documented result tuple.

**Related failure scenarios:** [LPIT-005](lua-common-pitfalls.md#lpit-005),
[LPIT-028](lua-common-pitfalls.md#lpit-028).

**Source context:** [Lua local scope][lua55].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local ret = 0
> local value = nil
> local detail = nil
>
> ret, value, detail = codec.CODEC_decode(input)
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> perform_effect()
> local owned_handle = acquire()
> ```

---

<a id="lstyle-018"></a>

### LSTYLE-018: Avoid shadowing and misleading initialization

**Class:** CORRECTNESS. **Obligation:** project requirement.

Do not shadow unrelated project locals, imports or standard-library names. Each nested function has its own
operation scope and must declare its own ret; its result locals may reuse conventional result names when
they do not accidentally capture or conceal state used by that function. Initialize state to a meaningful
neutral or invalid value. Use annotations for documented nil-to-value transitions; do not add false work
merely to silence a checker.

**Rationale:** Lua initializes unassigned locals to nil, but that does not establish a valid domain state. A
late local can also capture a different binding than expected.

**Verification design:** Run Selene and LuaLS; review every redefined-local diagnostic. Trace closure
bindings and result states on failure.

**Related failure scenarios:** [LPIT-004](lua-common-pitfalls.md#lpit-004),
[LPIT-005](lua-common-pitfalls.md#lpit-005).

**Source context:** [Lua scope][lua55]; [LuaLS configuration][luals-config].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> ---@type string|nil
> local payload = nil
> local is_valid = false
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> local string = {}
> local payload = payload
> ```

---

<a id="lstyle-019"></a>

### LSTYLE-019: Apply file-size limits as review triggers

**Class:** PROJECT_STYLE. **Obligation:** review trigger.

Review a Lua source file above 1,000 physical lines for cohesion. Apply the 500-line interface
review trigger to a dedicated contracts or public-annotation file, not to an invented Lua header. These are
review triggers, not automatic correctness failures.

**Rationale:** Large interfaces increase the work needed to understand callers and compatibility. Review
whether each file has one responsibility; function length has no universal numeric cap in this policy.

**Verification design:** Record the count convention, generated-code scope, owner and decision when
retaining a larger file. Do not split a state invariant across arbitrary files.

**Source context:** [Lua governance](lua-code-standard.md#governance).

#### Local examples

**Contract or layout example (not executable):**

> ```text
> packet_parser.lua: parsing only
> packet_contract.lua: fields and public contracts only
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> Move every 100th line into a helper solely to satisfy a metric.
> ```

---

<a id="lstyle-020"></a>

### LSTYLE-020: Enforce the measured cyclomatic complexity limit

**Class:** ANALYZABILITY. **Obligation:** required.

Every owned Lua function must satisfy the cyclomatic limit in
[`tools/analysis/c/gates.json`](../../../tools/analysis/c/gates.json), currently 10.
The [Lua quality gate](../../reference/lua-quality.md) uses the locked Lizard
counter with parser-defined function boundaries. The documented convention counts
branches, loops and boolean decisions while isolating nested function bodies.

**Rationale:** A measured gate makes regression visible across production code,
tests and configuration. Formatting alone cannot establish complexity.

**Verification design:** Retain the complete report with analyzer versions,
source digests and policy digest. Review behavior, cohesion and effects alongside
the score; a failing function must be decomposed before the gate can pass.

**Source context:** [Lua governance](lua-code-standard.md#governance).

#### Local examples

**Contract or layout example (not executable):**

> ```text
> threshold: 10
> measurement: lua-ast-lizard-v1
> action above threshold: fail and refactor
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> StyLua passed, therefore cyclomatic complexity is below 10.
> ```

---

<a id="lstyle-021"></a>

### LSTYLE-021: Enforce the measured cognitive complexity limit

**Class:** ANALYZABILITY. **Obligation:** required.

Every owned Lua function must satisfy the cognitive limit in the shared quality
policy, currently 15. The [Lua quality gate](../../reference/lua-quality.md)
defines `lua-cognitive-v1`, its AST traversal and independently tested counting
rules. This repository metric is not presented as a SonarQube score.

**Rationale:** A metric supports review but cannot guarantee comprehension.
Remove unnecessary nesting and hidden state; moving code into callbacks alone
does not establish a clearer design.

**Verification design:** Store analyzer versions, the convention identifier and
all function scores. Parser failure is a gate failure. Test branch behavior and
side effects after decomposing a function.

**Source context:** [Lua governance](lua-code-standard.md#governance).

#### Local examples

**Contract or layout example (not executable):**

> ```text
> cognitive convention: lua-cognitive-v1
> limit: 15
> manual review: nested decisions and callback effects inspected
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> Report a cognitive score inferred from the number of source lines.
> ```

---

<a id="lstyle-022"></a>

### LSTYLE-022: Prefer no more than five parameters

**Class:** PROJECT_STYLE. **Obligation:** review trigger.

Prefer at most five parameters per operation, including explicit context and an implicit self parameter. A
reviewed DTO may group a cohesive configuration, but an unbounded options table must not hide unrelated
controls. Varargs do not evade the count.

**Rationale:** The parameter threshold is a design review trigger. Typed C parameter checking is not
available to validate arbitrary Lua option tables.

**Verification design:** Review required and optional fields, nil versus absence, defaults and invalid
values. Record an exception when an external callback fixes the signature.

**Related failure scenarios:** [LPIT-008](lua-common-pitfalls.md#lpit-008).

**Source context:** [Lua governance](lua-code-standard.md#governance).

#### Local examples

**Contract or layout example (not executable):**

> ```text
> operation(context, request, deadline_ms)
> request: documented cohesive fields
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> operation(a, b, c, d, e, f, ...)
> ```

---

<a id="lstyle-023"></a>

### LSTYLE-023: Use one normal function output

**Class:** CORRECTNESS. **Obligation:** project requirement.

Every project-owned function must declare a visible ret, converge on one final ::function_output:: label and
have one final return statement. Return additional documented tuple values only after ret. Do not introduce
guard-clause early returns.

**Rationale:** This is the project's source-level normal-flow policy. It is not proof that exceptions,
coroutine suspension or process termination cannot bypass that path.

**Verification design:** Inspect nested functions separately. Every goto target must be function_output and
forward. Use a Lua parser, not a raw keyword count, for future automated enforcement.

**Related failure scenarios:** [LPIT-027](lua-common-pitfalls.md#lpit-027),
[LPIT-029](lua-common-pitfalls.md#lpit-029).

**Source context:** [Lua goto][lua55].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local function codec_isNonempty(value)
>    local ret = false
>
>    if type(value) ~= "string" then
>       goto function_output
>    end
>
>    ret = #value > 0
>
>    ::function_output::
>    return ret
> end
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> local function codec_isNonempty(value)
>    if value == nil then
>       return false
>    end
>    return #value > 0
> end
> ```

---

<a id="lstyle-024"></a>

### LSTYLE-024: Restrict goto to forward convergence

**Class:** CORRECTNESS. **Obligation:** project requirement.

Use goto only to transfer control forward to the owning function's final function_output label. Do not jump
backward, emulate continue, jump into a nested scope or create alternate cleanup labels. A failure inside a
loop exits through the function output, not a second loop exit.

**Rationale:** Lua forbids a jump into the scope of a local. The final label must have the intended cleanup
locals in scope; a shared label does not fix skipped acquisition.

**Verification design:** Compile complete functions. Test failure at each acquisition and prove that only
acquired resources are released.

**Related failure scenarios:** [LPIT-028](lua-common-pitfalls.md#lpit-028).

**Source context:** [Lua block and goto semantics][lua55].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local function codec_validateCount(value)
>    local ret = 0
>
>    if type(value) ~= "number" then
>       ret = -1
>       goto function_output
>    end
>
>    if value < 0 then
>       ret = -1
>       goto function_output
>    end
>
>    ::function_output::
>    return ret
> end
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> ::retry::
> run_operation()
> goto retry
> ```

---

<a id="lstyle-025"></a>

### LSTYLE-025: Keep loop termination in the loop contract

**Class:** CORRECTNESS. **Obligation:** project requirement.

Do not use break or a simulated continue. Use a bound, a progress variable and a termination condition. Use
a while loop when completion depends on mutable state. Do not modify a numeric-for control variable to alter
iteration.

**Rationale:** Normal loop completion should be visible at the loop header. An exceptional function-level
failure may still converge on function_output.

**Verification design:** Test empty, one-element, maximum-size, not-found and early-found inputs. Verify
monotonic progress or a finite retry budget.

**Source context:** [Lua governance](lua-code-standard.md#governance).

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local item_idx = 1
> local has_match = false
>
> while item_idx <= item_count and not has_match do
>    has_match = items[item_idx] == wanted
>    item_idx = item_idx + 1
> end
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> for item_idx = 1, item_count do
>    if items[item_idx] == wanted then
>       break
>    end
> end
> ```

---

<a id="lstyle-026"></a>

### LSTYLE-026: Separate effects from conditions and argument ordering

**Class:** CORRECTNESS. **Obligation:** project requirement.

Perform effectful calls and capture their results before a condition. Permit named pure predicates in
conditions. Do not depend on the relative evaluation order of multiple effectful call arguments or on a
short-circuit chain to sequence a transaction.

**Rationale:** A visible call/result/check sequence makes failure and state mutation auditable.

**Verification design:** Use mocks to record call order and verify that failure prevents later effects.

**Source context:** [Lua governance](lua-code-standard.md#governance).

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local ret = 0
> local is_ready = false
>
> ret, is_ready = port.PROBE_check(context)
> if ret == 0 and is_ready then
>    state.is_ready = true
> end
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> send(acquire_next(), advance_cursor())
> open_resource() and write_resource() or recover()
> ```

---

<a id="lstyle-027"></a>

### LSTYLE-027: Bound recursion and reentrant execution

**Class:** CORRECTNESS. **Obligation:** project requirement.

Prefer iteration for untrusted-depth data. Recursion requires a documented depth/resource bound and profile
approval; prohibit it in critical bounded paths. A tail call is not a substitute for the normal-output
policy or a bound on total work.

**Rationale:** Lua recursion, metamethod calls and callbacks can grow execution depth. Reentry may
invalidate state even without OS threads.

**Verification design:** Test maximum depth, cycles and callback reentry. Measure the actual runtime
behavior instead of assuming a C-style stack frame size.

**Source context:** [Lua function calls][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> walk input with an explicit bounded work queue
> reject depth above the configured limit before descending
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> Recursively expand arbitrary nested input until the VM fails.
> ```

---

<a id="lstyle-028"></a>

### LSTYLE-028: Validate external type, shape and domain

**Class:** CORRECTNESS. **Obligation:** project requirement.

Validate the value type before arithmetic, indexing or method calls; then validate shape, membership, range,
size and allowed effects. Treat values entering through a public API, configuration, file or callback as
untrusted unless a stronger boundary contract is established.

**Rationale:** A table-shaped value may still have a metatable, missing fields or hostile nested content. An
annotation is not a runtime check.

**Verification design:** Test nil, false, incorrect primitive types, missing keys, nested malformed data,
NaN, infinities and over-budget input where applicable.

**Related failure scenarios:** [LPIT-016](lua-common-pitfalls.md#lpit-016),
[LPIT-021](lua-common-pitfalls.md#lpit-021).

**Source context:** [Lua values][lua55].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local function codec_isCapacity(value)
>    local ret = false
>
>    if type(value) ~= "number" then
>       goto function_output
>    end
>
>    ret = value >= 0 and value <= 4096 and value % 1 == 0
>
>    ::function_output::
>    return ret
> end
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> local size_bytes = request.payload.size_bytes
> ```

---

<a id="lstyle-029"></a>

### LSTYLE-029: Distinguish false, nil, zero and empty text

**Class:** CORRECTNESS. **Obligation:** project requirement.

Treat false and nil as different domain values unless the contract explicitly equates them. Preserve a valid
false when applying defaults. Remember that zero and an empty string are true in conditions. Use explicit
nil checks for absence.

**Rationale:** Mechanical translation of C truth tests or a value-or-default expression can change
configuration semantics.

**Verification design:** Test false, nil, zero and empty-string values independently for every optional
field.

**Related failure scenarios:** [LPIT-001](lua-common-pitfalls.md#lpit-001),
[LPIT-002](lua-common-pitfalls.md#lpit-002).

**Source context:** [Lua truth values][lua55].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local is_enabled = config.is_enabled
>
> if is_enabled == nil then
>    is_enabled = true
> end
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> local is_enabled = config.is_enabled or true
> ```

---

<a id="lstyle-030"></a>

### LSTYLE-030: Use and/or only with proven value semantics

**Class:** CORRECTNESS. **Obligation:** project requirement.

Do not use condition and value_a or value_b as a general conditional expression when value_a may be false or
nil. Keep effectful selection in an if/else statement. Permit short-circuit defaults only where discarding
false is part of the contract.

**Rationale:** Lua logical operators return operands rather than always returning booleans.

**Verification design:** Exercise both branches with truthy and false/nil result values. Check that only the
intended effects occur.

**Related failure scenarios:** [LPIT-002](lua-common-pitfalls.md#lpit-002),
[LPIT-003](lua-common-pitfalls.md#lpit-003).

**Source context:** [Lua logical operators][lua55].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local selected = nil
>
> if is_primary then
>    selected = primary_value
> else
>    selected = fallback_value
> end
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> local selected = is_primary and primary_value or fallback_value
> ```

---

<a id="lstyle-031"></a>

### LSTYLE-031: Define sequence invariants explicitly

**Class:** CORRECTNESS. **Obligation:** project requirement.

Use one-based dense sequences for ordinary project collections. Use # only when the object is a string or a
proven sequence with no holes. Store an explicit count for sparse collections or nil-bearing tuples. Do not
rely on # to count a map.

**Rationale:** Lua table length is a border operation, not a general key count. Integer keys and string keys
are distinct.

**Verification design:** Test empty sequences, a hole at the start/middle/end, sparse high indices and
accidental string indices.

**Related failure scenarios:** [LPIT-007](lua-common-pitfalls.md#lpit-007),
[LPIT-009](lua-common-pitfalls.md#lpit-009), [LPIT-010](lua-common-pitfalls.md#lpit-010).

**Source context:** [Lua table length][lua55].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local items = { "header", "payload" }
> local item_count = #items
> local total_bytes = 0
>
> for item_idx = 1, item_count do
>    total_bytes = total_bytes + #items[item_idx]
> end
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> local items = { [1] = "a", [3] = "c" }
> local item_count = #items
> ```

---

<a id="lstyle-032"></a>

### LSTYLE-032: Choose iteration order and mutation rules deliberately

**Class:** CORRECTNESS. **Obligation:** project requirement.

Use numeric iteration for a dense indexed sequence and pairs for maps only when order is irrelevant. Do not
add keys during a next/pairs traversal. Collect intended updates first when mutation would obscure the
traversal contract. Sort explicit keys for deterministic output.

**Rationale:** Map traversal order is not a serialization, hashing or test-order contract.

**Verification design:** Repeat tests under different insertion orders and fresh processes. Test removals
without accidentally skipping shifted elements.

**Related failure scenarios:** [LPIT-010](lua-common-pitfalls.md#lpit-010),
[LPIT-011](lua-common-pitfalls.md#lpit-011), [LPIT-012](lua-common-pitfalls.md#lpit-012).

**Source context:** [Lua traversal][lua55].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local key_list = { "alpha", "beta", "gamma" }
> local ordered_fields = {}
>
> for key_idx = 1, #key_list do
>    ordered_fields[key_idx] = record[key_list[key_idx]]
> end
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> for key, value in pairs(record) do
>    write_signed_record(key, value)
> end
> ```

---

<a id="lstyle-033"></a>

### LSTYLE-033: Control aliasing and table mutation

**Class:** ARCHITECTURE / CORRECTNESS. **Obligation:** project requirement.

Document whether an input table is borrowed read-only, borrowed mutable, copied or retained. Publish outputs
only after validation succeeds. A table assignment is reference copying, not an independent snapshot. Define
shallow versus recursive copying explicitly.

**Rationale:** GC prevents neither accidental shared mutation nor semantic use after close. Cycles and
metatables make generic deep-copy behavior a design decision.

**Verification design:** Mutate the caller's input after construction and inspect the instance. Test that
rejected input leaves public state unchanged.

**Related failure scenarios:** [LPIT-013](lua-common-pitfalls.md#lpit-013),
[LPIT-014](lua-common-pitfalls.md#lpit-014).

**Source context:** [Lua references][lua55].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local snapshot = { timeout_ms = config.timeout_ms }
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> local snapshot = config
> snapshot.timeout_ms = 0
> ```

---

<a id="lstyle-034"></a>

### LSTYLE-034: Keep records explicit and immutable-by-contract

**Class:** ARCHITECTURE / CORRECTNESS. **Obligation:** project requirement.

Use named fields for semantic records. Do not depend on constructor order for effects or repeat the same
record key. Keep constant tables private or expose an interface that enforces the intended access contract.
A __newindex hook alone does not freeze existing fields.

**Rationale:** Ordinary field writes may bypass __newindex when the key already exists. An uppercase name or
annotation is not a write barrier.

**Verification design:** Test all mutation paths, nested aliases and raw operations when a read-only API is
claimed.

**Related failure scenarios:** [LPIT-015](lua-common-pitfalls.md#lpit-015).

**Source context:** [Lua constructors and metatables][lua55].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local config = {
>    timeout_ms = 250,
>    retry_count = 3,
>    is_enabled = true,
> }
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> local config = { timeout_ms = 100, timeout_ms = 250 }
> ```

---

<a id="lstyle-035"></a>

### LSTYLE-035: Preserve result tuple arity

**Class:** CORRECTNESS. **Obligation:** project requirement.

Give every public operation a fixed documented result shape. Capture all required results and distinguish no
results, nil results and a valid false. Do not assume a parenthesized call or a non-final call in a list
preserves multiple values.

**Rationale:** Lua adjusts result counts according to expression position. A wrapper can silently drop an
error code or trailing nil.

**Verification design:** Test success and failure arity, trailing nil and intermediate wrappers. Use a
count-bearing representation when values must be stored.

**Related failure scenarios:** [LPIT-006](lua-common-pitfalls.md#lpit-006),
[LPIT-007](lua-common-pitfalls.md#lpit-007), [LPIT-033](lua-common-pitfalls.md#lpit-033).

**Source context:** [Lua result adjustment][lua55].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local ret = 0
> local value = nil
> local detail = nil
>
> ret, value, detail = codec.CODEC_decode(input)
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> local ret, value = (codec.CODEC_decode(input))
> ```

---

<a id="lstyle-036"></a>

### LSTYLE-036: Treat text as bytes unless an encoding contract says otherwise

**Class:** CORRECTNESS. **Obligation:** project requirement.

Use _bytes for byte lengths and offsets. State whether a string contains arbitrary bytes, ASCII or validated
UTF-8. Do not use # or string.sub as a count or slice of Unicode characters. Define normalization separately
when identity comparisons require it.

**Rationale:** Lua strings are immutable byte sequences and may contain embedded zeros. UTF-8 decoding is
not normalization or grapheme segmentation.

**Verification design:** Test empty input, embedded NUL, multibyte sequences, malformed UTF-8 and visually
equivalent but differently encoded text.

**Related failure scenarios:** [LPIT-017](lua-common-pitfalls.md#lpit-017).

**Source context:** [Lua strings and UTF-8][lua55]; [Selene UTF-8 additions][selene-standard].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local payload_bytes = #payload
> local valid_count, invalid_byte_idx = utf8.len(text)
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> local character_count = #text
> ```

---

<a id="lstyle-037"></a>

### LSTYLE-037: Use literal searches for literal input

**Class:** CORRECTNESS. **Obligation:** project requirement.

Use string.find with plain=true when the searched value is literal text. Treat Lua patterns as a separate
interpreted language: quote or reject external pattern syntax according to the input contract. Bound input
and pattern work.

**Rationale:** Lua patterns are not regular expressions; metacharacters can change what a search accepts.

**Verification design:** Test literal punctuation, percent signs, brackets, empty needles and inputs at the
maximum size.

**Related failure scenarios:** [LPIT-018](lua-common-pitfalls.md#lpit-018).

**Source context:** [Lua pattern functions][lua55].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local match_start = string.find(text, needle, 1, true)
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> local match_start = string.find(text, user_supplied_literal)
> ```

---

<a id="lstyle-038"></a>

### LSTYLE-038: Make format and replacement strings explicit

**Class:** CORRECTNESS. **Obligation:** project requirement.

Keep format strings trusted and validate argument types. Do not pass external replacement text directly as a
gsub replacement when percent escapes must remain literal. Use a reviewed escaping or replacement-function
boundary.

**Rationale:** A data string becomes instructions when used as a format, pattern or replacement template.

**Verification design:** Test percent sequences, unexpected argument types, embedded NUL and oversized
output. Keep output budgets explicit.

**Related failure scenarios:** [LPIT-019](lua-common-pitfalls.md#lpit-019),
[LPIT-020](lua-common-pitfalls.md#lpit-020).

**Source context:** [Lua string functions][lua55].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local diagnostic = string.format("invalid field: %s", field_name)
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> local diagnostic = string.format(untrusted_text, value)
> ```

---

<a id="lstyle-039"></a>

### LSTYLE-039: Validate numerical domains before arithmetic

**Class:** PORTABILITY / CORRECTNESS. **Obligation:** project requirement.

Reject NaN, infinities, fractions and out-of-range values when the contract requires a bounded count or
integer. Do not assume a successful tonumber proves the required textual grammar or integer representation.

**Rationale:** Lua permits numeric conversions and configurable numeric representations. A domain bound must
be checked before it controls work, storage or a native conversion.

**Verification design:** Test signed text, whitespace, exponents, hexadecimal, fractional values and the
largest accepted count. Test the chosen runtime representation independently.

**Related failure scenarios:** [LPIT-021](lua-common-pitfalls.md#lpit-021),
[LPIT-022](lua-common-pitfalls.md#lpit-022), [LPIT-023](lua-common-pitfalls.md#lpit-023),
[LPIT-024](lua-common-pitfalls.md#lpit-024), [LPIT-025](lua-common-pitfalls.md#lpit-025).

**Source context:** [Lua numerals and conversions][lua55].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local function codec_isBoundedCount(value)
>    local ret = false
>
>    if type(value) ~= "number" then
>       goto function_output
>    end
>
>    ret = value >= 0 and value <= 65535 and value % 1 == 0
>
>    ::function_output::
>    return ret
> end
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> local item_count = tonumber(input) or 0
> ```

---

<a id="lstyle-040"></a>

### LSTYLE-040: Check bounds before addition and multiplication

**Class:** CORRECTNESS. **Obligation:** project requirement.

For nonnegative bounded counts, compare count against capacity - used before adding. Check multiplication
against an established quotient bound before multiplying. Do not translate C unsigned-suffix or UB reasoning
into Lua.

**Rationale:** Lua integer arithmetic may wrap, and floating-point arithmetic may lose precision. A result
that looks small after arithmetic does not prove the inputs were safe.

**Verification design:** Test exact capacity, one beyond, zero, negative and representation boundaries.
Establish integer domains before using a subtraction-based bound.

**Related failure scenarios:** [LPIT-024](lua-common-pitfalls.md#lpit-024).

**Source context:** [Lua arithmetic][lua55].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> if payload_bytes > capacity_bytes - used_bytes then
>    ret = CODEC_ENOSPC
> end
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> if used_bytes + payload_bytes <= capacity_bytes then
>    state.used_bytes = used_bytes + payload_bytes
> end
> ```

---

<a id="lstyle-041"></a>

### LSTYLE-041: Specify division, remainder and bitwise semantics

**Class:** PORTABILITY / CORRECTNESS. **Obligation:** project requirement.

Check divisor and domain before division. Distinguish / from // and specify the intended negative-number
rounding rule. Keep logical and/or separate from bitwise operations. Require an explicit width and
representation at a binary boundary.

**Rationale:** Lua arithmetic is not a direct transcription of C integer arithmetic. Bitwise operators,
precision and API availability also depend on the selected profile.

**Verification design:** Test zero divisors, negative operands, large integers and all declared shift or
mask bounds. Compile profile-specific operators with every required checker.

**Related failure scenarios:** [LPIT-025](lua-common-pitfalls.md#lpit-025).

**Source context:** [Lua arithmetic and bitwise operations][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> division contract: nonnegative counts, divisor greater than zero
> mask contract: explicit external width and allowed bits
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> Assume / on two integers produces a C-style truncated integer.
> ```

---

<a id="lstyle-042"></a>

### LSTYLE-042: Serialize values through an explicit format

**Class:** PORTABILITY / CORRECTNESS. **Obligation:** project requirement.

Define encoding, byte order, field widths, length limits, ordering and version independently of in-memory
Lua tables. Keep string.pack/unpack or native encoders behind a profile-approved adapter; the current Selene
catalogue is not a blanket approval of those APIs.

**Rationale:** Lua tables are not C structs or stable wire layouts. Bytecode is executable runtime-specific
content, not a general data format.

**Verification design:** Use golden vectors, malformed-length tests and cross-platform round trips. Verify
canonical ordering where bytes are signed or hashed.

**Related failure scenarios:** [LPIT-011](lua-common-pitfalls.md#lpit-011),
[LPIT-023](lua-common-pitfalls.md#lpit-023), [LPIT-026](lua-common-pitfalls.md#lpit-026).

**Source context:** [Lua binary formats][lua55]; [LSTYLE-001](#lstyle-001).

#### Local examples

**Contract or layout example (not executable):**

> ```text
> version: 1
> length: unsigned 16-bit big-endian
> payload: exactly length bytes
> unknown versions: rejected
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> Persist string.dump(function) as a portable configuration format.
> ```

---

<a id="lstyle-043"></a>

### LSTYLE-043: Use a project-owned status contract

**Class:** CORRECTNESS. **Obligation:** project requirement.

Use ret=0 for success and documented negative module-owned codes for expected failures in action APIs.
Return outputs after ret and initialize unavailable outputs to nil. Total predicates may use a Boolean ret;
do not use them to conceal multi-state failures.

**Rationale:** Standard Lua library calls have different return conventions. Translate them at adapters
rather than pretending every number is a POSIX errno.

**Verification design:** Test all documented status codes, tuple positions and output values on failure.
Check that false can remain a valid payload.

**Related failure scenarios:** [LPIT-001](lua-common-pitfalls.md#lpit-001),
[LPIT-006](lua-common-pitfalls.md#lpit-006), [LPIT-030](lua-common-pitfalls.md#lpit-030),
[LPIT-033](lua-common-pitfalls.md#lpit-033).

**Source context:** [LSTYLE-035](#lstyle-035).

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local function codec_getDefault()
>    local ret = 0
>    local value = false
>
>    ::function_output::
>    return ret, value
> end
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> return true -- Sometimes success, sometimes the operation result.
> ```

---

<a id="lstyle-044"></a>

### LSTYLE-044: Check every fallible result

**Class:** CORRECTNESS. **Obligation:** project requirement.

Capture and inspect status from I/O, callbacks, process operations, close and protected calls. Preserve the
first operation failure unless the public contract explicitly prioritizes a cleanup failure. A pcall success
flag is not the wrapped operation's success code.

**Rationale:** Two success dimensions exist at a protected callback: normal Lua execution and domain-level
success.

**Verification design:** Inject both a thrown error and a normal error tuple. Confirm the caller rejects
both and does not publish a partial output.

**Related failure scenarios:** [LPIT-001](lua-common-pitfalls.md#lpit-001),
[LPIT-030](lua-common-pitfalls.md#lpit-030).

**Source context:** [Lua protected calls][lua55].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local call_ok = false
> local operation_ret = nil
>
> call_ok, operation_ret = pcall(port.WRITE_send, context, data)
> if not call_ok or operation_ret ~= 0 then
>    ret = CODEC_EIO
> end
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> local call_ok = pcall(port.WRITE_send, context, data)
> if call_ok then
>    ret = CODEC_OK
> end
> ```

---

<a id="lstyle-045"></a>

### LSTYLE-045: Keep expected failures on normal SESE paths

**Class:** CORRECTNESS. **Obligation:** project requirement.

Return expected validation, capacity and availability failures through ret and function_output. Reserve
assert and error for documented invariant or host-fatal policies. Always give assert a meaningful message
and keep effects outside assertions.

**Rationale:** Lua assertions are runtime calls; they are not automatically removed in a release build as a
C assert macro might be. An assertion can bypass manual cleanup.

**Verification design:** Run failure tests without relying on assertions for external validation. Check that
changing diagnostic settings cannot remove required work.

**Related failure scenarios:** [LPIT-034](lua-common-pitfalls.md#lpit-034).

**Source context:** [Lua assert and errors][lua55].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local function codec_validateText(value)
>    local ret = 0
>
>    if type(value) ~= "string" then
>       ret = -1
>       goto function_output
>    end
>
>    ::function_output::
>    return ret
> end
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> assert(write_output(data))
> ```

---

<a id="lstyle-046"></a>

### LSTYLE-046: Protect exception boundaries rather than every line

**Class:** CORRECTNESS. **Obligation:** project requirement.

Use pcall or xpcall at a named boundary that owns translation of thrown failures. Document whether callbacks
may throw or yield. Keep error handlers bounded and avoid assuming an error object is a string. Do not
silently turn programming errors into successful output.

**Rationale:** Table access, arithmetic and tostring may invoke metamethods. Manual function_output cleanup
does not run after an unprotected exception.

**Verification design:** Throw a string, a table and an object with a failing __tostring from a test port.
Verify stable status mapping, cleanup and retained primary diagnostics.

**Related failure scenarios:** [LPIT-018](lua-common-pitfalls.md#lpit-018),
[LPIT-029](lua-common-pitfalls.md#lpit-029), [LPIT-030](lua-common-pitfalls.md#lpit-030),
[LPIT-031](lua-common-pitfalls.md#lpit-031), [LPIT-040](lua-common-pitfalls.md#lpit-040).

**Source context:** [Lua error handling][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> call boundary: catch external callback failure
> normal result: validate callback status and payload
> error object: retain bounded diagnostic, never assume string
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> pcall(every_statement) and ignore all errors
> ```

---

<a id="lstyle-047"></a>

### LSTYLE-047: Centralize ownership and cleanup

**Class:** ARCHITECTURE / CORRECTNESS. **Obligation:** project requirement.

Give every external resource one semantic owner. Record successful acquisitions and release them in reverse
dependency order at function_output. Borrowed resources must not be closed by a borrower. Clear references
only after applying the documented close-result policy.

**Rationale:** GC reachability does not establish when a file, process, lock or native handle is released. A
reference can remain alive after its resource is invalid.

**Verification design:** Fail each acquisition, operation and close stage; verify close count, order,
preserved error and output state. Include exception paths through the owning protected boundary.

**Related failure scenarios:** [LPIT-027](lua-common-pitfalls.md#lpit-027),
[LPIT-029](lua-common-pitfalls.md#lpit-029), [LPIT-032](lua-common-pitfalls.md#lpit-032),
[LPIT-035](lua-common-pitfalls.md#lpit-035), [LPIT-036](lua-common-pitfalls.md#lpit-036).

**Source context:** [Lua finalization][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> acquire A -> acquire B -> work -> function_output
> function_output: release B if acquired, then A if acquired
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> Trust __gc to close every file before the next operation.
> ```

---

<a id="lstyle-048"></a>

### LSTYLE-048: Treat deterministic close as a separate profile decision

**Class:** CORRECTNESS. **Obligation:** project requirement.

A Lua `<close>` local requires explicit syntax/checker qualification and an owning adapter contract. Declare
it at the start of its lexical block with an immediately valid value. Do not combine automatic close and
manual close of the same ownership without a proved idempotent contract.

**Rationale:** A to-be-closed local has scope-based semantics and may run on unwinding; it is not a writable
handle slot. Its close handler may also fail. The baseline examples use explicit cleanup to avoid
overstating tool coverage.

**Verification design:** In a separately qualified example, test normal exit, goto, exception, close failure
and coroutine cancellation. Keep close order explicit.

**Related failure scenarios:** [LPIT-037](lua-common-pitfalls.md#lpit-037).

**Source context:** [Lua to-be-closed variables][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> adapter profile: to-be-closed resource
> close owner: exactly one
> manual cleanup: must not duplicate automatic release
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> Declare a nil <close> local and later assign an acquired handle to it.
> ```

---

<a id="lstyle-049"></a>

### LSTYLE-049: Validate before publishing mutation

**Class:** ARCHITECTURE / CORRECTNESS. **Obligation:** project requirement.

Compute and validate a candidate before changing externally visible state. State whether an operation
provides an unchanged-on-failure, partial-progress or terminal-failure guarantee. Keep caller outputs
unchanged or explicitly invalid on failure.

**Rationale:** SESE centralizes the result but does not make a multi-step operation atomic or roll back
effects.

**Verification design:** Inject failure before and after each publication point. Verify the documented state
guarantee rather than only the return code.

**Related failure scenarios:** [LPIT-033](lua-common-pitfalls.md#lpit-033).

**Source context:** [Lua governance](lua-code-standard.md#governance).

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local candidate_count = used_count + incoming_count
>
> -- Bounds were checked before this addition.
> state.used_count = candidate_count
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> state.used_count = state.used_count + 1
> validate_untrusted_record(record)
> ```

---

<a id="lstyle-050"></a>

### LSTYLE-050: Bound input, output and retained state

**Class:** CORRECTNESS. **Obligation:** project requirement.

Declare budgets for bytes, entries, nesting, queued work, retained diagnostics and retries. Enforce them
before growth or repeated work. Avoid unbounded read-all, accumulation and table growth on external input.

**Rationale:** Lua strings, tables and closures may allocate implicitly. Review memory growth from runtime
operations and retained references even when source code has no explicit allocation call.

**Verification design:** Exercise limits, repeated rejected inputs and long-running workloads. Measure
retained memory and allocation behavior on the selected VM.

**Related failure scenarios:** [LPIT-014](lua-common-pitfalls.md#lpit-014),
[LPIT-020](lua-common-pitfalls.md#lpit-020).

**Source context:** [Lua memory management][lua55].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> if incoming_bytes > capacity_bytes - retained_bytes then
>    ret = CODEC_ENOSPC
> end
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> local payload = file:read("*a") -- Arbitrary external file size.
> ```

---

<a id="lstyle-051"></a>

### LSTYLE-051: Do not promise ordinary recovery from every OOM

**Class:** CORRECTNESS. **Obligation:** project requirement.

Document VM-level allocation failure and native allocator behavior separately from a normal capacity error.
Do not claim that pcall, diagnostic allocation or a Lua cleanup callback always makes out-of-memory recovery
safe.

**Rationale:** Allocating the error report or invoking cleanup may itself need resources. A Lua-level
capacity check is not a proof about the entire VM allocator.

**Verification design:** Use controlled host fault injection where supported and retain the
runtime/allocator profile. Keep availability claims narrower than the evidence.

**Source context:** [Lua errors and memory management][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> capacity failure: CODEC_ENOSPC, normal operation contract
> VM allocation failure: host policy, separately tested
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> pcall guarantees graceful recovery from any allocation failure.
> ```

---

<a id="lstyle-052"></a>

### LSTYLE-052: Prefer lexical privacy over hidden metamethod effects

**Class:** ARCHITECTURE / CORRECTNESS. **Obligation:** project requirement.

Use local functions and explicit operation tables for the ordinary core. Keep metatables small, owned and
documented. Do not make field reads, comparisons or tostring perform unexpected I/O, unbounded work or
lifecycle transitions.

**Rationale:** Metamethods are executable callbacks, not passive declarations. Reading a borrowed table may
cross a trust boundary.

**Verification design:** Test missing keys, recursive __index, reentry and throwing metamethods where such
objects are allowed. Reject metatables on untrusted record inputs when the contract requires plain data.

**Related failure scenarios:** [LPIT-015](lua-common-pitfalls.md#lpit-015),
[LPIT-016](lua-common-pitfalls.md#lpit-016).

**Source context:** [Lua metatables][lua55].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local ret = 0
>
> if type(request) ~= "table" then
>    ret = CODEC_EINVAL
> elseif getmetatable(request) ~= nil then
>    ret = CODEC_EINVAL
> end
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> return request.payload -- The read may execute an unknown __index.
> ```

---

<a id="lstyle-053"></a>

### LSTYLE-053: Control closure capture and retained references

**Class:** ARCHITECTURE / CORRECTNESS. **Obligation:** project requirement.

Document captured mutable state and lifetime for every stored callback. Avoid capturing an entire request
graph when a bounded value is sufficient. Define how a callback is unbound and when its captures become
unreachable.

**Rationale:** A closure can retain data long after an operation returns. Capturing a reference is neither a
snapshot nor a synchronization mechanism.

**Verification design:** Replace or mutate the source state in tests and verify intended callback behavior.
Check retained memory after unbind and quiescence.

**Related failure scenarios:** [LPIT-042](lua-common-pitfalls.md#lpit-042).

**Source context:** [Lua lexical scope][lua55]; [LMOD-016](lua-module-architecture.md#lmod-016).

#### Local examples

**Contract or layout example (not executable):**

> ```text
> callback capture: private immutable identifier
> context lifetime: provider remains valid until all calls finish
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> Store a closure over an unbounded request, then retain it forever.
> ```

---

<a id="lstyle-054"></a>

### LSTYLE-054: Make coroutine suspension and resume states explicit

**Class:** CORRECTNESS. **Obligation:** project requirement.

Only yield at documented scheduler boundaries. Do not yield while private invariants are transient or an
external resource requires uninterrupted ownership. Check coroutine.resume status and distinguish yielded
results from a completed coroutine.

**Rationale:** A successful resume may mean suspension rather than completion. Cooperative execution still
allows state changes between resumptions.

**Verification design:** Test every suspension point, errors before and after yield, cancellation and
teardown of a suspended task.

**Related failure scenarios:** [LPIT-038](lua-common-pitfalls.md#lpit-038),
[LPIT-039](lua-common-pitfalls.md#lpit-039).

**Source context:** [Lua coroutines][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> scheduler contract: yielded / completed / failed are separate states
> resource contract: ownership survives or is released at each suspension
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> Treat the first true result from coroutine.resume as task completion.
> ```

---

<a id="lstyle-055"></a>

### LSTYLE-055: Reject reentry unless a contract permits it

**Class:** ARCHITECTURE / CORRECTNESS. **Obligation:** project requirement.

Document reentry and synchronization for instances and callbacks. A local busy flag may reject synchronous
reentry, but it is not an OS-thread lock. Do not share a Lua state across host threads without the host's
approved serialization policy.

**Rationale:** Independent Lua states, coroutine tasks and native OS threads are different execution
domains.

**Verification design:** Use a callback that attempts to call the same instance. Test teardown during active
work under the actual host synchronization model.

**Related failure scenarios:** [LPIT-040](lua-common-pitfalls.md#lpit-040),
[LPIT-041](lua-common-pitfalls.md#lpit-041).

**Source context:** [Lua coroutines and C API][lua55].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> if state.is_busy then
>    ret = CODEC_EBUSY
> end
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> A boolean is_busy field makes every native-thread call safe.
> ```

---

<a id="lstyle-056"></a>

### LSTYLE-056: Give GC policy and weak caches an owner

**Class:** ARCHITECTURE / CORRECTNESS. **Obligation:** project requirement.

Keep collectgarbage policy, weak tables and memory-sensitive cache behavior with a named VM or cache owner.
Do not disable GC around unbounded work. Weak references are an eviction mechanism, not a guaranteed
retained-resource contract.

**Rationale:** GC scheduling and performance vary by runtime and configuration. Collection of Lua memory
does not prove external resource release.

**Verification design:** Measure bounded workloads with the deployed GC policy and test cache misses after
collection. Record retained handles separately from Lua heap estimates.

**Related failure scenarios:** [LPIT-036](lua-common-pitfalls.md#lpit-036).

**Source context:** [Lua GC][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> cache: bounded and recreatable
> GC tuning: VM owner, measured workload and rollback record
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> Stop GC permanently to make a benchmark faster.
> ```

---

<a id="lstyle-057"></a>

### LSTYLE-057: Keep dynamic loading on a trusted boundary

**Class:** SECURITY. **Obligation:** project requirement.

Do not execute external input with load, loadfile or dofile in ordinary modules. A loader adapter must
define code origin, integrity, permitted environment, bytecode policy and process capabilities. Treat
execution as execution even when the input looks like configuration.

**Rationale:** An environment table alone is not a complete sandbox or a memory/time limit. Native
capabilities can escape a nominally restricted Lua environment.

**Verification design:** Test rejected code origins, binary chunks and capability access in the loader's
isolated test environment. Do not execute hostile samples in general unit tests.

**Related failure scenarios:** [LPIT-016](lua-common-pitfalls.md#lpit-016),
[LPIT-047](lua-common-pitfalls.md#lpit-047).

**Source context:** [Lua loading functions][lua55]; [LBAN-001](#lban-001).

#### Local examples

**Contract or layout example (not executable):**

> ```text
> configuration: parse inert data with a size and schema contract
> code loading: separate trusted adapter
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> load(user_configuration)()
> ```

---

<a id="lstyle-058"></a>

### LSTYLE-058: Own require resolution and bootstrap paths

**Class:** SECURITY. **Obligation:** project requirement.

Use fixed approved module names and a controlled search path. Do not compose require names from untrusted
text or mutate package.path/package.cpath inside ordinary modules. Existing trusted dofile bootstrap logic
belongs to the composition boundary, not the module core.

**Rationale:** Search-path order can select a different provider. Clearing package.loaded does not
invalidate references already held by consumers.

**Verification design:** Test a hostile working directory, duplicate module names and missing dependencies.
Record which roots and native libraries are trusted.

**Related failure scenarios:** [LPIT-045](lua-common-pitfalls.md#lpit-045),
[LPIT-046](lua-common-pitfalls.md#lpit-046).

**Source context:** [Lua require][lua55]; [Repository runner][check-lua].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local codec = require("codec.packet_parser")
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> local plugin = require(user_supplied_name)
> ```

---

<a id="lstyle-059"></a>

### LSTYLE-059: Keep process execution behind an argument contract

**Class:** SECURITY. **Obligation:** project requirement.

Do not concatenate external data into os.execute or io.popen commands. Use the repository's approved
platform/process adapter and its documented argv and quoting contract. Standard Lua does not itself supply a
universal cross-platform execve-style interface.

**Rationale:** A list of arguments is only safe if the adapter preserves argument boundaries and
accounts for the downstream program's option syntax.

**Verification design:** Test spaces, quotes, newlines, metacharacters, leading dashes and platform-specific
parsing. Check exit status, timeout and output limits.

**Related failure scenarios:** [LPIT-048](lua-common-pitfalls.md#lpit-048).

**Source context:** [Lua OS and I/O libraries][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> process port: executable identity plus separate validated arguments
> external filename: data argument, never shell source
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> os.execute("tool " .. untrusted_path)
> ```

---

<a id="lstyle-060"></a>

### LSTYLE-060: Validate file authority, not only path spelling

**Class:** SECURITY. **Obligation:** project requirement.

Define the allowed filesystem root, file type, link policy, permissions and lifetime of path validation.
Keep file reads, writes, temporary objects and persistence inside the filesystem adapter. Do not claim
lexical normalization prevents symlink races.

**Rationale:** A relative path, a normalized string and an authorized file object are different things.

**Verification design:** Test traversal, absolute paths, links, replacement between check and use, partial
writes and failed close within an isolated fixture.

**Related failure scenarios:** [LPIT-047](lua-common-pitfalls.md#lpit-047),
[LPIT-049](lua-common-pitfalls.md#lpit-049).

**Source context:** [Lua governance](lua-code-standard.md#governance).

#### Local examples

**Contract or layout example (not executable):**

> ```text
> filesystem contract: trusted root, permitted operation, bounded bytes
> atomic replacement: only when the platform adapter guarantees it
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> Reject ../ and assume all remaining paths are authorized.
> ```

---

<a id="lstyle-061"></a>

### LSTYLE-061: Keep secrets and diagnostics under a disclosure policy

**Class:** SECURITY. **Obligation:** project requirement.

Use an injected diagnostic port for reusable modules. Bound and sanitize external text, redact secrets, and
avoid exposing whole objects or raw callback errors to logs. Do not claim immutable Lua strings can be
reliably zeroized from Lua.

**Rationale:** Formatting and copies can retain sensitive bytes. Module-local logging also couples a library
to process-global output.

**Verification design:** Inspect failure logs for credentials, payloads and control characters. Verify that
disabled diagnostics do not change required state transitions.

**Related failure scenarios:** [LPIT-020](lua-common-pitfalls.md#lpit-020),
[LPIT-031](lua-common-pitfalls.md#lpit-031), [LPIT-050](lua-common-pitfalls.md#lpit-050).

**Source context:** [Lua strings][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> diagnostic: operation ID, bounded error code, redacted context
> secret lifetime: host-owned boundary with an explicit retention policy
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> print("request failed", secret_payload, raw_error_object)
> ```

---

<a id="lstyle-062"></a>

### LSTYLE-062: Keep native and FFI details in adapters

**Class:** PORTABILITY / CORRECTNESS. **Obligation:** project requirement.

Isolate native bindings and LuaJIT FFI in named adapters. Define ABI, integer conversions, pointer
ownership, callback roots, lifetime, thread affinity and error-unwinding rules. Do not copy C pointer casts,
bit-field layouts or memory barriers into portable Lua.

**Rationale:** Native code can reintroduce C memory and concurrency hazards that ordinary Lua tables do not
model.

**Verification design:** Run C-side sanitizers and ABI tests separately from Lua tests. Keep a pure
reference implementation where the contract permits one.

**Related failure scenarios:** [LPIT-023](lua-common-pitfalls.md#lpit-023),
[LPIT-026](lua-common-pitfalls.md#lpit-026), [LPIT-041](lua-common-pitfalls.md#lpit-041).

**Source context:** [Lua C API][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> core -> owned port -> native adapter -> qualified C ABI
> returned native handle: validated type and explicit close state
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> Pass a floating-point number as an unchecked native pointer address.
> ```

---

<a id="lstyle-063"></a>

### LSTYLE-063: Use explicit clock, randomness and retry contracts

**Class:** CORRECTNESS. **Obligation:** project requirement.

Use an injected monotonic clock for elapsed durations and deadlines. Do not treat os.clock as wall time or a
general monotonic I/O timer. Use approved entropy for security; math.random is not a cryptographic source.
Bound retries and record the seed for reproducible tests.

**Rationale:** Correctness depends on the meaning of a clock and a random source, not merely on their
numeric type.

**Verification design:** Test clock jumps, deadline expiry, retry exhaustion and deterministic replay. Keep
the test RNG out of production authentication or token generation.

**Source context:** [Lua clock and random libraries][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> deadline_ms: injected monotonic clock domain
> test randomness: logged seed
> security randomness: separate approved provider
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> local token = tostring(math.random())
> ```

---

<a id="lstyle-064"></a>

### LSTYLE-064: Fail closed at required checks and authority gates

**Class:** ANALYZABILITY. **Obligation:** project requirement.

Reject a missing required checker, unsupported profile, invalid contract or denied authority. Do not turn
security checks into optional warnings merely because a tool or dependency is inconvenient. Keep optional
developer convenience distinct from required merge or release evidence.

**Rationale:** A normal exit code from a skipped check is not evidence that the property was checked.

**Verification design:** Test missing-tool paths and verify they fail with a useful diagnostic. Record
not-run rather than pass when evidence is absent.

**Related failure scenarios:** [LPIT-051](lua-common-pitfalls.md#lpit-051).

**Source context:** [Repository runner][check-lua].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> required tool missing -> failure with tool identity
> check not executed -> NOT RUN, never PASS
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> Skip Selene after an error and print "all checks passed".
> ```

---

<a id="lstyle-065"></a>

### LSTYLE-065: Document the public operation contract

**Class:** ANALYZABILITY. **Obligation:** project requirement.

Describe purpose, parameter domains, return tuple, ownership, effects, error behavior, synchronization,
yield policy and resource bounds. Use LuaLS annotations for machine-readable shapes and ordinary prose for
guarantees they cannot express.

**Rationale:** LDoc-style prose and LuaLS annotations complement each other, but duplicating inconsistent
type declarations creates a second contract.

**Verification design:** Compare documentation, runtime checks and tests. Do not add a new mandatory
documentation generator that is not present in the repository.

**Related failure scenarios:** [LPIT-008](lua-common-pitfalls.md#lpit-008).

**Source context:** [LuaLS annotations][luals]; [LuaRocks guide][luarocks].

#### Local examples

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> --- Validate a bounded byte count without changing external state.
> ---@param value number
> ---@return boolean ret
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> --- Does stuff.
> ---@param value any
> ```

---

<a id="lstyle-066"></a>

### LSTYLE-066: Run the canonical repository Lua checks

**Class:** ANALYZABILITY. **Obligation:** project requirement.

Run scripts/check/lua.lua from the repository root with the locked tools. Preserve its syntax,
dictionary, Selene, StyLua and LuaLS stages. Use LIBMEMALLOC_LUA, LIBMEMALLOC_LUAC,
LIBMEMALLOC_SELENE, LIBMEMALLOC_STYLUA and
LIBMEMALLOC_LUALS only as documented executable overrides.

**Rationale:** A parallel ad hoc lint recipe can omit extensionless hooks, the custom standard or
warning-level LuaLS failures.

**Verification design:** Resolve the absolute root with git rev-parse --show-toplevel, change to it and
invoke the script there. Save versions and the complete exit status.

**Related failure scenarios:** [LPIT-051](lua-common-pitfalls.md#lpit-051).

**Source context:** [Repository runner][check-lua]; [Toolchain lock][toolchain].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> lua ./scripts/check/lua.lua
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> Run stylua with default settings and call that repository validation.
> ```

---

<a id="lstyle-067"></a>

### LSTYLE-067: Distinguish checked-in Lua from embedded documentation

**Class:** ANALYZABILITY. **Obligation:** project requirement.

The current runner discovers tracked .lua files and extensionless programs through its shebang logic; it
does not extract Lua fences from Markdown. Validate embedded complete examples explicitly. Do not claim
documentation-only changes caused all examples to be linted by that runner.

**Rationale:** Documentation examples can drift even when the repository check passes. The wrapper and
workflow also have distinct source-detection code.

**Verification design:** Extract examples to a disposable checkout, use exact paths with direct checkers,
and run complete tests. Never accidentally stage extraction artifacts in a production branch.

**Related failure scenarios:** [LPIT-052](lua-common-pitfalls.md#lpit-052).

**Source context:** [Repository runner][check-lua]; [Workflow Lua job][lint-workflow].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> Markdown example -> extracted temporary .lua -> syntax/lint/test
> tracked repository source -> canonical Lua runner
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> The Markdown file was checked, therefore every Lua example was checked.
> ```

---

<a id="lstyle-068"></a>

### LSTYLE-068: Keep tests tied to contracts and failure states

**Class:** ANALYZABILITY. **Obligation:** project requirement.

Cover public contracts, boundary values, malformed inputs, every acquisition stage, callback exceptions,
resource cleanup and state after failure. Use mocks for injected ports and a deterministic seed for
randomized sequences. Preserve an independent expected-result model.

**Rationale:** Passing happy-path unit tests or a coverage percentage does not prove ownership, ordering or
bounds.

**Verification design:** Record which requirements each test addresses and which profiles ran. Avoid
executing uncontrolled resource exhaustion, arbitrary shell commands or hostile bytecode.

**Source context:** [Common Lua Pitfalls](lua-common-pitfalls.md#catalogue).

#### Local examples

**Contract or layout example (not executable):**

> ```text
> case: callback returns failure
> assert: failure propagated, busy flag reset, no partial publication
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> Assert only that the operation returns a non-nil value.
> ```

---

<a id="lstyle-069"></a>

### LSTYLE-069: Treat coverage and static reports as evidence

**Class:** ANALYZABILITY. **Obligation:** project requirement.

Identify statement, branch and other coverage metrics separately. Report numerator, denominator, excluded
code and unreachable-path justification. Do not equate 100 percent statement coverage with complete path
coverage, MC/DC or product assurance.

**Rationale:** The review discipline requires evidence proportional to the claim. The baseline Lua
runner is not a coverage or safety-case generator.

**Verification design:** Keep reports linked to code and tool versions. Investigate missing branches and
mutation-test survivors where such testing is used.

**Related failure scenarios:** [LPIT-054](lua-common-pitfalls.md#lpit-054).

**Source context:** [Lua governance](lua-code-standard.md#governance).

#### Local examples

**Contract or layout example (not executable):**

> ```text
> statement coverage: measured with named tool
> branch coverage: separately measured
> SESE review: separate evidence
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> 100 percent coverage proves the library safe for every critical system.
> ```

---

<a id="lstyle-070"></a>

### LSTYLE-070: Control package and dependency provenance

**Class:** ANALYZABILITY. **Obligation:** project requirement.

Pin runtime and tool dependencies through the repository lock. Treat LuaRocks style guidance separately from
LuaRocks package installation. A new rock, native module or test framework requires dependency and profile
review; do not add it solely because an external guide mentions it.

**Rationale:** Package identity, build inputs and transitive native dependencies can change program behavior
and authority.

**Verification design:** Record package version, source integrity, license, native build settings and
affected tests. Avoid network installation inside ordinary module initialization.

**Source context:** [Toolchain lock][toolchain]; [LuaRocks guide][luarocks].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> style source: LuaRocks guide
> new package: separate dependency review
> tool versions: tools/toolchain/lock.toml
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> require a missing package and auto-install it from the network.
> ```

---

<a id="lstyle-071"></a>

### LSTYLE-071: Define the Lua and host responsibility boundary

**Class:** PORTABILITY / CORRECTNESS. **Obligation:** project requirement.

Define which guarantees the Lua module supplies and which require its host or native adapter. Lua owns
export visibility, argument validation, status contracts, aliases and logical resource lifetime. The host
owns OS-thread synchronization, native memory access, ABI compatibility and process resource enforcement.

**Rationale:** A reachable Lua reference can hold a closed resource. A coroutine busy flag cannot lock
shared native memory against another OS thread. State each guarantee at the boundary that can enforce it.

**Verification design:** Use the responsibility table and exercise invalid input, closed handles, callback
retention and host failures. Identify the owner and test for each requirement.

**Source context:** [Lua and host responsibilities](#runtime-responsibilities).

#### Local examples

**Contract or layout example (not executable):**

> ```text
> module visibility -> lexical local and explicit exports
> resource lifetime -> open/closed state and an explicit owner
> native buffer -> adapter bounds checks and a retained backing allocation
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> Use an include guard table to make Lua memory safe.
> ```

---

<a id="lstyle-072"></a>

### LSTYLE-072: Migrate existing Lua without rewriting history

**Class:** ANALYZABILITY. **Obligation:** project requirement.

Apply this new policy to new or deliberately revised code through a reviewed migration plan. Record existing
snake_case function APIs, early returns and trusted bootstrap loading as migration items rather than
claiming the baseline already satisfies the new SESE/naming policy.

**Rationale:** The checked-in runner itself uses existing Lua conventions. Passing its checks does not
enforce all rules in these documents.

**Verification design:** Map affected paths, preserve public compatibility at adapters and update tests with
each migration. Do not loosen checks to make a migration appear complete.

**Source context:** [Repository runner][check-lua]; [Governance](#governance).

#### Local examples

**Contract or layout example (not executable):**

> ```text
> existing public name -> compatibility adapter -> project operation
> SESE migration -> reviewed control-flow change with failure tests
> ```

**Noncompliant fragment or claim (do not copy):**

> ```text
> Claim every existing Lua source already follows these new rules.
> ```

---

## Native lifetime, suspension and runtime compatibility

---

<a id="lstyle-073"></a>

### LSTYLE-073: Account for stack indices and rooted values in native adapters

**Class:** CORRECTNESS / SAFETY. **Obligation:** project requirement.

**Profile:** PUC-Lua C API. Refine [LSTYLE-062](#lstyle-062).

Document entry arguments, temporary pushes, returned values and error exits for each native operation.
Convert a relative index with `lua_absindex` before pushes that would change its meaning; this does not root
the indexed value or make a removed slot valid. Check stack growth when the adapter needs additional slots.
Give every retained Lua object a reachable Lua owner or an explicit registry reference, with one release owner.
Keep a Lua string rooted for the entire use of a pointer obtained from it, and carry its byte length.

**Rationale:** A C local containing an index or address is not a Lua ownership record.

**Verification design:** Record expected stack height at each normal return and protected failure boundary.
Force collection between registration and later callback; exercise empty strings and embedded NUL bytes.
Count acquired and released registry references through failed construction and repeated shutdown.

**Contract example (not executable):**

```text
Lua argument -> validated absolute stack index -> rooted owner -> temporary native view
retained callback -> registry reference -> unregister and drain -> release registry reference
```

**Noncompliant claim:** Saving `lua_tolstring`'s address in a C struct keeps its Lua string alive.

**Sources:** [Lua C API stack](https://www.lua.org/manual/5.5/manual.html#4.1),
[registry reference ownership](https://www.lua.org/pil/27.3.2.html).
The latter explains an older Lua edition; use the selected runtime's API contracts for implementation.
See [LPIT-055](lua-common-pitfalls.md#lpit-055).

---

<a id="lstyle-074"></a>

### LSTYLE-074: Make native suspension and error boundaries explicit

**Class:** CORRECTNESS / PORTABILITY. **Obligation:** project requirement.

**Profile:** Embedded Lua with native calls that may invoke Lua. Refine [LSTYLE-046](#lstyle-046).

Classify each adapter call as non-yielding or continuation-aware. For a continuation-aware API, store state
in an owner that survives suspension, and define completion, failure and cancellation cleanup separately.
Do not expect code after a yielding call to act as its continuation. Do not keep a borrowed C stack address
as resumed-operation state. A C++ host must review how its Lua build propagates errors across native frames;
do not assume destructors run across a C `longjmp` boundary.

**Rationale:** Source adjacency does not establish a resumed control-flow path.

**Verification design:** Use a native harness that invokes a Lua callback which yields, resumes with values,
raises an error and is cancelled. Check each acquired resource has one release path. For a non-yielding
adapter, verify that attempted suspension reports a controlled failure without publishing partial state.

**Contract example (not executable):**

```text
entry -> persistent operation record -> lua_pcallk -> continuation -> result and release
```

**Noncompliant claim:** Calling `lua_pcall` makes a native adapter transparently support suspension.

**Source:** [Lua continuation handling](https://www.lua.org/manual/5.4/manual.html#4.5).
Verify the corresponding section in the selected runtime; a LuaJIT adapter requires separate evidence.
See [LPIT-056](lua-common-pitfalls.md#lpit-056).

---

<a id="lstyle-075"></a>

### LSTYLE-075: Close abandoned coroutines through their lifecycle owner

**Class:** CORRECTNESS. **Obligation:** project requirement.

**Profile:** PUC-Lua 5.4/5.5 resource-owning coroutines. Refine [LSTYLE-048](#lstyle-048).

Assign an owner to every coroutine that can suspend with resources in scope. On abandonment or failure,
inspect its state and explicitly close it when the selected runtime allows that operation. Keep the original
resume result and the close result separate. Define which error is primary and retain bounded cleanup diagnostics.
Do not resume an abandoned operation merely to run arbitrary remaining work as cleanup.

This rule's examples close a separate suspended or dead coroutine. Lua 5.5 additionally permits closing the
running coroutine; do not adopt that non-returning path under the normal SESE convention without a profile review.

**Rationale:** Removing a scheduler entry does not establish resource release.

**Verification design:** Test normal completion, suspended abandonment, body failure and close-method failure.
Observe the number of releases and the final coroutine state. See the [complete fixture](#coroutine-regression).
Include native cancellation acknowledgement separately if the coroutine submitted asynchronous native work.

**Contextual Lua fragment:**

> ```lua
> close_ok, close_error = coroutine.close(worker)
> if not close_ok then
>    cleanup_error = close_error
> end
> ```

**Noncompliant claim:** Dropping the last scheduler reference promptly executes every pending `__close`.

**Source:** [Lua 5.5 coroutine.close](https://www.lua.org/manual/5.5/manual.html#pdf-coroutine.close).
See [LPIT-057](lua-common-pitfalls.md#lpit-057).

---

<a id="lstyle-076"></a>

### LSTYLE-076: Retain the backing allocation behind every FFI pointer

**Class:** SAFETY. **Obligation:** project requirement.

**Profile:** LuaJIT FFI, separately qualified. Refine [LSTYLE-062](#lstyle-062).

Store the backing array or string in the operation owner for as long as native code can use its address.
A cdata pointer does not cause the collector to follow its pointed-to allocation. A retained native pointer
therefore requires a retained Lua reference to the backing object, not merely another copy of its address.
Specify who releases native storage and whether `ffi.gc` remains attached after an explicit release or transfer.

**Rationale:** Pointer reachability and allocation reachability are different properties in this runtime.

**Verification design:** Force collection after submission and before completion, with allocator churn.
Verify the owner remains retained until the provider acknowledges completion or cancellation. Check explicit
close followed by collection for duplicate native destruction. Never execute a deliberately dangling pointer
to demonstrate the failure in an ordinary test process.

**Contract example (not executable):**

```text
pending request owns backing cdata + native request handle
native completion acknowledgement -> release handle -> remove backing reference
```

**Noncompliant claim:** Keeping a pointer field alive also retains the array assigned to that field.

**Sources:** [LuaJIT cdata lifetime](https://luajit.org/ext_ffi_semantics.html#gc),
[ffi.gc ownership](https://luajit.org/ext_ffi_api.html#ffi_gc).
See [LPIT-058](lua-common-pitfalls.md#lpit-058).

---

<a id="lstyle-077"></a>

### LSTYLE-077: Bound and drain native callback registrations

**Class:** SAFETY / CORRECTNESS. **Obligation:** project requirement.

**Profile:** LuaJIT FFI callbacks. Refine [LMOD-012](lua-module-architecture.md#lmod-012).

For registrations that can be removed, own an explicit callback cdata value and its release operation.
Bound outstanding registrations. Do not rely on repeated implicit function-to-callback conversions for
temporary registrations: they consume callback resources without an explicit reclamation handle.
Free a callback only after native unregister and completion of any in-flight call. Document allowed calling
threads, reentry, errors and the JIT policy of the native call site.

**Rationale:** Registration owns executable entry points as well as captured application state.

**Verification design:** Repeat register/unregister beyond expected production churn and measure retained
registrations. Inject registration failure and late delivery in the native provider fixture. Exercise a rare
callback after warm-up; a call path that later calls Lua may require a documented `jit.off` boundary.

**Contract example (not executable):**

```text
create callback -> register -> active -> unregister -> drain -> callback:free()
```

**Noncompliant claim:** Freeing the callback immediately after requesting unregister is always safe.

**Source:** [LuaJIT callback semantics](https://luajit.org/ext_ffi_semantics.html#callback).
See [LPIT-059](lua-common-pitfalls.md#lpit-059). No LuaJIT support is implied for baseline repository tools.

---

<a id="lstyle-078"></a>

### LSTYLE-078: Qualify new runtime syntax across the entire tool path

**Class:** PORTABILITY / ANALYZABILITY. **Obligation:** project requirement.

**Profile:** Runtime or syntax upgrades. Extend [LSTYLE-001](#lstyle-001).

Before adopting version-specific syntax, run a minimal fixture through the compiler, formatter, Selene,
LuaLS and complexity parser that inspect the affected files. Record a failure as an unsupported configuration;
do not hide the file from discovery or suppress parse errors. Keep runtime support and tooling support as
separate rows in the compatibility record.

For example, Lua 5.5 adds explicit global declarations. Their language semantics do not authorize additional
global state under this project's lexical module policy. Introducing that syntax requires tool qualification
and a documented use case. Do not place it in a shared Lua 5.4 or LuaJIT source file.

**Rationale:** Compiler acceptance alone cannot establish an analyzable repository source profile.

**Verification design:** Keep accepted and intentionally rejected syntax fixtures per supported runtime.
Check the expected diagnostic rather than accepting any failing exit code. The existing analyzer's supported
syntax remains a constraint until a separately reviewed tool upgrade passes its parser regressions.

**Contract example (not executable):**

```text
runtime parses feature -> formatter preserves it -> analysis parses it -> semantic tests pass
```

**Noncompliant claim:** Changing only `_VERSION` expectations qualifies all Lua 5.5 syntax for CI.

**Sources:** [Lua 5.5 global declarations](https://www.lua.org/manual/5.5/manual.html#3.3.7),
[repository analyzer contract](../../reference/lua-quality.md).
See [LPIT-060](lua-common-pitfalls.md#lpit-060).

---

<a id="performance-controls"></a>

## Performance and resource evidence

Accept a Lua optimization after measuring its benefit for a declared runtime and workload and checking
contract equivalence. [Lua performance and JIT](lua-performance.md) explains profiling, trace behavior,
allocation tradeoffs and the benchmark procedure for applying these controls.

---

<a id="lperf-001"></a>

### LPERF-001: Measure the complete deployed operation

**Class:** ANALYZABILITY. **Obligation:** project requirement.

Require a baseline, candidate, representative workload, repeat count and correctness oracle before accepting
a performance change. Measure the externally meaningful operation, including necessary validation and
cleanup.

**Rationale:** A faster isolated expression can make the complete operation slower or remove a contract.

**Verification design:** Record inputs, output equivalence, memory use and dispersion, not only the fastest
sample.

**Related controls:** [LSTYLE-068](lua-code-standard.md#lstyle-068),
[LSTYLE-069](lua-code-standard.md#lstyle-069).

**Related failure scenarios:** [LPIT-053](lua-common-pitfalls.md#lpit-053).

**Source context:** [Lua runtime and collection model][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> baseline = public operation with validation and cleanup
> candidate = same operation and contract
> comparison = correctness plus latency, throughput and memory
> ```

---

<a id="lperf-002"></a>

### LPERF-002: Record runtime and machine identity

**Class:** ANALYZABILITY. **Obligation:** project requirement.

Record the Lua implementation and version, native dependencies, operating system, processor, build flags,
clock, GC mode and effective workload configuration. Keep JIT and interpreter results separate.

**Rationale:** The same source can have different costs on different interpreters and native backends.

**Verification design:** Reproduce the experiment with the recorded environment and preserve raw results.

**Related controls:** [LSTYLE-001](lua-code-standard.md#lstyle-001),
[LSTYLE-004](lua-code-standard.md#lstyle-004).

**Source context:** [Lua runtime and collection model][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> runtime + native modules + workload + clock + GC policy + raw samples
> ```

---

<a id="lperf-003"></a>

### LPERF-003: Separate startup, steady state and collection

**Class:** ANALYZABILITY. **Obligation:** project requirement.

Measure startup/import cost separately from steady-state operations. State whether samples include GC, cache
population, native initialization or JIT warm-up in a separate JIT profile.

**Rationale:** Excluding a cost does not remove that cost from the deployed application.

**Verification design:** Compare cold and warm runs and include a deployment-representative run with normal
collection enabled.

**Related controls:** [LSTYLE-050](lua-code-standard.md#lstyle-050),
[LSTYLE-056](lua-code-standard.md#lstyle-056).

**Related failure scenarios:** [LPIT-053](lua-common-pitfalls.md#lpit-053).

**Source context:** [Lua runtime and collection model][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> cold import / first operation / sustained operation / full lifecycle
> ```

---

<a id="lperf-004"></a>

### LPERF-004: Report tails and limits honestly

**Class:** ANALYZABILITY. **Obligation:** project requirement.

Report P50, P90, P95 and P99 when the sample count and measurement resolution support them. Name the
quantile estimator, sample count and units. Do not describe an observed maximum or P99 as a worst-case
execution-time proof.

**Rationale:** A tail percentile based on too few samples is unstable and does not bound future executions.

**Verification design:** Retain samples, measurement overhead and uncertainty. Use a separately justified
method for hard deadlines.

**Related controls:** [LSTYLE-063](lua-code-standard.md#lstyle-063),
[LSTYLE-069](lua-code-standard.md#lstyle-069).

**Related failure scenarios:** [LPIT-054](lua-common-pitfalls.md#lpit-054).

**Source context:** [Lua runtime and collection model][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> P50 / P90 / P95 / P99 + sample count + clock resolution + estimator
> ```

---

<a id="lperf-005"></a>

### LPERF-005: Improve algorithms before local syntax

**Class:** ANALYZABILITY. **Obligation:** project requirement.

Review asymptotic work, repeated scans, copying and external calls before changing local spellings. Keep
resource bounds and failure behavior explicit.

**Rationale:** A linear algorithmic improvement can dominate a small lookup optimization without relying on
runtime internals.

**Verification design:** Measure across input sizes, including empty, typical and maximum accepted values.

**Related controls:** [LSTYLE-050](lua-code-standard.md#lstyle-050).

**Source context:** [Lua runtime and collection model][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> one validated scan instead of repeated full rescans
> ```

---

<a id="lperf-006"></a>

### LPERF-006: Use bounded string assembly

**Class:** ANALYZABILITY. **Obligation:** project requirement.

For substantial repeated assembly, compare collecting bounded string pieces and table.concat with repeated
concatenation. Account for the piece table, final string and peak memory. Do not assume the builder is
always faster.

**Rationale:** Intermediate immutable strings and retained pieces both consume resources.

**Verification design:** Differential-test empty pieces, embedded NUL bytes and maximum aggregate length.
Measure peak memory.

**Related controls:** [LSTYLE-036](lua-code-standard.md#lstyle-036),
[LSTYLE-050](lua-code-standard.md#lstyle-050).

**Source context:** [Lua runtime and collection model][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> validated pieces -> bounded piece table -> one final concatenation
> ```

---

<a id="lperf-007"></a>

### LPERF-007: Control temporary tables and closures

**Class:** ANALYZABILITY. **Obligation:** project requirement.

Measure allocation churn before reusing tables or hoisting closures. A reused table must not leak prior
values or remain borrowed by a previous caller. A hoisted closure must retain the intended context.

**Rationale:** Reducing allocation can accidentally introduce shared mutable state or extend object
lifetime.

**Verification design:** Test interleaved instances and retained outputs; compare live memory after repeated
operations.

**Related controls:** [LSTYLE-033](lua-code-standard.md#lstyle-033),
[LSTYLE-053](lua-code-standard.md#lstyle-053).

**Source context:** [Lua runtime and collection model][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> private scratch storage + explicit reset + no escaping aliases
> ```

---

<a id="lperf-008"></a>

### LPERF-008: Treat local lookup caching as semantic binding

**Class:** ANALYZABILITY. **Obligation:** project requirement.

Cache a library function locally only when the binding is intended to remain stable and measurements justify
the change. Decide how tests and approved dependency replacement interact with that binding.

**Rationale:** A local alias captures the old function even if the source table later changes.

**Verification design:** Test supported replacement or initialization order and record the speed difference
on the selected runtime.

**Related controls:** [LSTYLE-058](lua-code-standard.md#lstyle-058).

**Source context:** [Lua runtime and collection model][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> bind once at composition -> stable dependency -> measure
> ```

---

<a id="lperf-009"></a>

### LPERF-009: Keep caches bounded and invalidation owned

**Class:** ANALYZABILITY. **Obligation:** project requirement.

Define cache key semantics, capacity, eviction, invalidation and ownership. Do not use weak tables as a
substitute for a specified retention policy.

**Rationale:** A cache can improve latency while causing stale results or retaining an unbounded object
graph.

**Verification design:** Test configuration changes, key collisions, eviction and memory plateau under
adversarial key diversity.

**Related controls:** [LSTYLE-056](lua-code-standard.md#lstyle-056).

**Source context:** [Lua runtime and collection model][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> cache owner -> capacity -> versioned key -> invalidation test
> ```

---

<a id="lperf-010"></a>

### LPERF-010: Measure callback and native boundary cost

**Class:** ANALYZABILITY. **Obligation:** project requirement.

Attribute crossing, conversion, copying and native work separately where useful, while preserving an
end-to-end measurement. Batch only when latency, cancellation and failure reporting remain acceptable.

**Rationale:** A cheap Lua function may hide expensive native work or process creation.

**Verification design:** Test partial completion and compare throughput against worst observed latency at
each batch size.

**Related controls:** [LSTYLE-059](lua-code-standard.md#lstyle-059),
[LSTYLE-062](lua-code-standard.md#lstyle-062).

**Source context:** [Lua runtime and collection model][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> batch size is a measured parameter, not a universal constant
> ```

---

<a id="lperf-011"></a>

### LPERF-011: Keep an independent reference

**Class:** ANALYZABILITY. **Obligation:** project requirement.

Retain a clear, independent reference implementation or model for specialized algorithms. Do not generate
the oracle from the same optimized transformation being tested.

**Rationale:** Agreement between two implementations sharing the same defect is weak evidence.

**Verification design:** Differential-test deterministic corpora, boundary values and randomized sequences.

**Related controls:** [LSTYLE-068](lua-code-standard.md#lstyle-068).

**Source context:** [Lua runtime and collection model][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> portable reference -> expected result <- specialized candidate
> ```

---

<a id="lperf-012"></a>

### LPERF-012: Separate Lua claims from native microarchitecture

**Class:** ANALYZABILITY. **Obligation:** project requirement.

Keep SIMD, cache-line layout, atomics, prefetch, NUMA and ISA dispatch decisions inside the owning native
adapter. Lua source cannot promise the physical placement of an ordinary table.

**Rationale:** Native machine properties need measurements of the deployed implementation; they do not establish
physical placement or alignment guarantees for ordinary Lua tables.

**Verification design:** Review native ABI, bounds, lifetime and machine measurements and test the same public Lua contract
against every backend.

**Related controls:** [LSTYLE-062](lua-code-standard.md#lstyle-062),
[LSTYLE-071](lua-code-standard.md#lstyle-071).

**Source context:** [Lua runtime and collection model][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> Lua API -> native adapter -> target-specific implementation
> ```

---

<a id="lperf-013"></a>

### LPERF-013: Avoid unbounded convenience in hot paths

**Class:** ANALYZABILITY. **Obligation:** project requirement.

Keep logging, formatting, dynamic loading, process creation and uncontrolled retries out of latency-critical
loops unless the execution profile explicitly budgets them.

**Rationale:** The slow exceptional path is still part of a public operation when it can occur in
deployment.

**Verification design:** Inject slow and failing ports and record the operation behavior and upper resource
limits.

**Related controls:** [LSTYLE-050](lua-code-standard.md#lstyle-050),
[LSTYLE-063](lua-code-standard.md#lstyle-063).

**Source context:** [Lua runtime and collection model][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> critical operation -> bounded work; diagnostics -> owned bounded port
> ```

---

<a id="lperf-014"></a>

### LPERF-014: Review GC tuning as a system change

**Class:** ANALYZABILITY. **Obligation:** project requirement.

Treat collector tuning as a runtime-profile change with latency, memory and long-run evidence. Do not stop
collection merely to make a benchmark look faster.

**Rationale:** Deferred collection can shift time out of the measurement window and increase memory without
improving the lifecycle.

**Verification design:** Include long-running workloads and realistic resource pressure. Record all
collector settings.

**Related controls:** [LSTYLE-051](lua-code-standard.md#lstyle-051),
[LSTYLE-056](lua-code-standard.md#lstyle-056).

**Related failure scenarios:** [LPIT-053](lua-common-pitfalls.md#lpit-053).

**Source context:** [Lua runtime and collection model][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> compare latency and memory over the complete workload duration
> ```

---

<a id="lperf-015"></a>

### LPERF-015: Use stable regression criteria

**Class:** ANALYZABILITY. **Obligation:** project requirement.

Define performance regression thresholds from representative variance and a controlled environment. Separate
deterministic correctness gates from noisy performance signals.

**Rationale:** A single noisy timing failure can encourage unsafe changes or meaningless baseline resets.

**Verification design:** Record the review and rerun policy; preserve evidence when updating an accepted
baseline.

**Related controls:** [LSTYLE-069](lua-code-standard.md#lstyle-069).

**Source context:** [Lua runtime and collection model][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> correctness gate + controlled performance experiment + reviewed threshold
> ```

---

<a id="lperf-016"></a>

### LPERF-016: Retain optimization review records

**Class:** ANALYZABILITY. **Obligation:** project requirement.

Record the change owner, contract preserved, baseline and candidate identities, experiment, correctness
evidence, risks and rollback condition.

**Rationale:** An optimization is an engineering decision, not a permanent claim about every future target.

**Verification design:** Revisit the decision after runtime, compiler, hardware, dependency or workload
changes.

**Related controls:** [LSTYLE-002](lua-code-standard.md#lstyle-002),
[LSTYLE-070](lua-code-standard.md#lstyle-070).

**Source context:** [Lua runtime and collection model][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> claim -> experiment -> raw data -> result -> decision -> revalidation trigger
> ```

---

<a id="restricted-facilities"></a>

## Canonical restricted-facility register

Each LBAN entry names its scope and permitted owner. The register distinguishes prohibited ordinary-core use
from qualified boundary use. It does not prohibit the language runtime from providing these facilities, nor
override existing trusted bootstrap behavior without a migration review.

---

<a id="lban-001"></a>

### LBAN-001: Untrusted dynamic execution

**Class:** SECURITY / CORRECTNESS. **Obligation:** project requirement.

Scope: load, loadfile and dofile on externally supplied code or paths. Prohibit in ordinary data-processing
modules. Permit only a separately approved code-execution boundary with authority, resource and trust
controls. A restricted environment table alone is not a sandbox.

**Rationale:** The restriction belongs to the named project profile, not a claim that Lua lacks the
facility.

**Verification design:** Review every occurrence and its owner. Exercise the approved alternative and
failure handling.

**Related controls:** [LSTYLE-057](lua-code-standard.md#lstyle-057),
[LSTYLE-060](lua-code-standard.md#lstyle-060).

**Related failure scenarios:** [LPIT-047](lua-common-pitfalls.md#lpit-047).

**Source context:** [Lua facilities and semantics][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> Parse data with a non-executable decoder and explicit size/schema limits.
> ```

---

<a id="lban-002"></a>

### LBAN-002: Untrusted binary chunks

**Class:** SECURITY / CORRECTNESS. **Obligation:** project requirement.

Scope: Externally supplied compiled Lua bytecode. Prohibit in the ordinary ingress profile. Do not treat
binary chunk loading as safe parsing or bytecode stripping as a security boundary.

**Rationale:** The restriction belongs to the named project profile, not a claim that Lua lacks the
facility.

**Verification design:** Review every occurrence and its owner. Exercise the approved alternative and
failure handling.

**Related controls:** [LSTYLE-004](lua-code-standard.md#lstyle-004),
[LSTYLE-057](lua-code-standard.md#lstyle-057).

**Source context:** [Lua facilities and semantics][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> Distribute verified source or explicitly qualified trusted artifacts for the exact runtime.
> ```

---

<a id="lban-003"></a>

### LBAN-003: Caller-controlled module resolution

**Class:** SECURITY / CORRECTNESS. **Obligation:** project requirement.

Scope: require names and package.path/package.cpath derived from untrusted input. Prohibit in reusable
cores. A bootstrap owner may select verified locations before normal execution. Preserve and review the
repository existing trusted bootstrap use of dofile.

**Rationale:** The restriction belongs to the named project profile, not a claim that Lua lacks the
facility.

**Verification design:** Review every occurrence and its owner. Exercise the approved alternative and
failure handling.

**Related controls:** [LSTYLE-058](lua-code-standard.md#lstyle-058).

**Source context:** [Lua facilities and semantics][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> Use an allowlisted mapping of public choices to trusted implementations.
> ```

---

<a id="lban-004"></a>

### LBAN-004: Global writes and peer monkey-patching

**Class:** SECURITY / CORRECTNESS. **Obligation:** project requirement.

Scope: _G writes, shared library-table mutation and replacing peer functions. Prohibit as ordinary module
communication. Test-only replacements require an isolated fixture and guaranteed restoration; injected ports
are the default.

**Rationale:** The restriction belongs to the named project profile, not a claim that Lua lacks the
facility.

**Verification design:** Review every occurrence and its owner. Exercise the approved alternative and
failure handling.

**Related controls:** [LSTYLE-008](lua-code-standard.md#lstyle-008),
[LSTYLE-052](lua-code-standard.md#lstyle-052).

**Source context:** [Lua facilities and semantics][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> Export a local table and bind dependencies through the composition root.
> ```

---

<a id="lban-005"></a>

### LBAN-005: Legacy environment-based modules

**Class:** SECURITY / CORRECTNESS. **Obligation:** project requirement.

Scope: module(), setfenv-based module construction and implicit global exports. Do not introduce into the
baseline profile. Legacy compatibility belongs behind a named adapter with migration tests.

**Rationale:** The restriction belongs to the named project profile, not a claim that Lua lacks the
facility.

**Verification design:** Review every occurrence and its owner. Exercise the approved alternative and
failure handling.

**Related controls:** [LSTYLE-004](lua-code-standard.md#lstyle-004),
[LSTYLE-008](lua-code-standard.md#lstyle-008).

**Source context:** [Lua facilities and semantics][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> Use lexical locals and return a deliberately constructed module table.
> ```

---

<a id="lban-006"></a>

### LBAN-006: Raw shell execution

**Class:** SECURITY / CORRECTNESS. **Obligation:** project requirement.

Scope: os.execute and io.popen in reusable domain code. Restrict to the process adapter. Reject command
strings assembled from external data. A Lua table of strings is not safe argv until the underlying adapter
semantics are verified.

**Rationale:** The restriction belongs to the named project profile, not a claim that Lua lacks the
facility.

**Verification design:** Review every occurrence and its owner. Exercise the approved alternative and
failure handling.

**Related controls:** [LSTYLE-059](lua-code-standard.md#lstyle-059).

**Related failure scenarios:** [LPIT-048](lua-common-pitfalls.md#lpit-048).

**Source context:** [Lua facilities and semantics][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> Use an approved executable-plus-arguments adapter with an explicit shell policy.
> ```

---

<a id="lban-007"></a>

### LBAN-007: Implicit shared I/O destinations

**Class:** SECURITY / CORRECTNESS. **Obligation:** project requirement.

Scope: io.input, io.output and library output through global default streams. Prohibit changing process-wide
default streams from reusable modules. CLI entry points own terminal policy; libraries receive an I/O port
or explicit handle.

**Rationale:** The restriction belongs to the named project profile, not a claim that Lua lacks the
facility.

**Verification design:** Review every occurrence and its owner. Exercise the approved alternative and
failure handling.

**Related controls:** [LSTYLE-047](lua-code-standard.md#lstyle-047),
[LSTYLE-061](lua-code-standard.md#lstyle-061).

**Source context:** [Lua facilities and semantics][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> Pass the owned or borrowed stream and document closing responsibility.
> ```

---

<a id="lban-008"></a>

### LBAN-008: Process termination from a library

**Class:** SECURITY / CORRECTNESS. **Obligation:** project requirement.

Scope: os.exit in reusable module operations. Prohibit outside the application or test-runner boundary. Do
not assume all normal cleanup or pending Lua work executes after process termination.

**Rationale:** The restriction belongs to the named project profile, not a claim that Lua lacks the
facility.

**Verification design:** Review every occurrence and its owner. Exercise the approved alternative and
failure handling.

**Related controls:** [LSTYLE-023](lua-code-standard.md#lstyle-023),
[LSTYLE-045](lua-code-standard.md#lstyle-045).

**Source context:** [Lua facilities and semantics][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> Return a status; the entry point selects an exit code after its shutdown policy.
> ```

---

<a id="lban-009"></a>

### LBAN-009: Introspection as encapsulation bypass

**Class:** SECURITY / CORRECTNESS. **Obligation:** project requirement.

Scope: debug access to hidden state, upvalues or peer implementation details. Restrict to approved
diagnostics or isolated tests. Do not make correctness or public operations depend on bypassing another
module privacy.

**Rationale:** The restriction belongs to the named project profile, not a claim that Lua lacks the
facility.

**Verification design:** Review every occurrence and its owner. Exercise the approved alternative and
failure handling.

**Related controls:** [LSTYLE-052](lua-code-standard.md#lstyle-052),
[LSTYLE-061](lua-code-standard.md#lstyle-061).

**Source context:** [Lua facilities and semantics][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> Use public contracts and injected test ports without exporting private helpers.
> ```

---

<a id="lban-010"></a>

### LBAN-010: Predictable random security material

**Class:** SECURITY / CORRECTNESS. **Obligation:** project requirement.

Scope: math.random or time values as authentication secrets or security nonces. Prohibit for
security-sensitive generation. Select and qualify an appropriate host cryptographic randomness port
separately.

**Rationale:** The restriction belongs to the named project profile, not a claim that Lua lacks the
facility.

**Verification design:** Review every occurrence and its owner. Exercise the approved alternative and
failure handling.

**Related controls:** [LSTYLE-063](lua-code-standard.md#lstyle-063).

**Source context:** [Lua facilities and semantics][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> Inject the security-owned randomness provider with explicit failure handling.
> ```

---

<a id="lban-011"></a>

### LBAN-011: Collector tricks as lifetime control

**Class:** SECURITY / CORRECTNESS. **Obligation:** project requirement.

Scope: GC stopping, forced collection or weak references used as resource-lifetime correctness. Do not rely
on them to release finite external resources or to prove a memory bound. Tuning is restricted to the
runtime-profile owner.

**Rationale:** The restriction belongs to the named project profile, not a claim that Lua lacks the
facility.

**Verification design:** Review every occurrence and its owner. Exercise the approved alternative and
failure handling.

**Related controls:** [LSTYLE-047](lua-code-standard.md#lstyle-047),
[LSTYLE-056](lua-code-standard.md#lstyle-056).

**Source context:** [Lua facilities and semantics][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> Use explicit close/destroy contracts and measured, bounded retention.
> ```

---

<a id="lban-012"></a>

### LBAN-012: Hidden control-flow exits

**Class:** SECURITY / CORRECTNESS. **Obligation:** project requirement.

Scope: Early returns, backward goto, break-based function escape and Luau continue. Prohibit in the baseline
function-level SESE discipline. Use one ret, one function_output label and one final return; loops have
explicit progress and stop conditions.

**Rationale:** The restriction belongs to the named project profile, not a claim that Lua lacks the
facility.

**Verification design:** Review every occurrence and its owner. Exercise the approved alternative and
failure handling.

**Related controls:** [LSTYLE-023](lua-code-standard.md#lstyle-023),
[LSTYLE-024](lua-code-standard.md#lstyle-024), [LSTYLE-025](lua-code-standard.md#lstyle-025).

**Source context:** [Lua facilities and semantics][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> Use forward error convergence and a bounded loop predicate.
> ```

---

<a id="lban-013"></a>

### LBAN-013: Unchecked boundary results

**Class:** SECURITY / CORRECTNESS. **Obligation:** project requirement.

Scope: Ignoring a fallible I/O result, callback status or protected-call outcome. Prohibit. A protected-call
Boolean is not the domain status and zero is truthy in Lua.

**Rationale:** The restriction belongs to the named project profile, not a claim that Lua lacks the
facility.

**Verification design:** Review every occurrence and its owner. Exercise the approved alternative and
failure handling.

**Related controls:** [LSTYLE-043](lua-code-standard.md#lstyle-043),
[LSTYLE-044](lua-code-standard.md#lstyle-044), [LSTYLE-046](lua-code-standard.md#lstyle-046).

**Source context:** [Lua facilities and semantics][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> Store the protected-call outcome and the domain result in distinct variables.
> ```

---

<a id="lban-014"></a>

### LBAN-014: Unlimited ingress and work

**Class:** SECURITY / CORRECTNESS. **Obligation:** project requirement.

Scope: Unbounded read-all, queue growth, recursive parsing or retry loops. Prohibit without a bounded
trusted-profile justification. Limits must address bytes, elements, depth, attempts and time as relevant.

**Rationale:** The restriction belongs to the named project profile, not a claim that Lua lacks the
facility.

**Verification design:** Review every occurrence and its owner. Exercise the approved alternative and
failure handling.

**Related controls:** [LSTYLE-027](lua-code-standard.md#lstyle-027),
[LSTYLE-050](lua-code-standard.md#lstyle-050), [LSTYLE-063](lua-code-standard.md#lstyle-063).

**Source context:** [Lua facilities and semantics][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> Validate before allocating or publishing and stop according to a finite contract.
> ```

---

<a id="lban-015"></a>

### LBAN-015: Unsafe native escape hatches

**Class:** SECURITY / CORRECTNESS. **Obligation:** project requirement.

Scope: Raw pointer/FFI exposure or arbitrary package.loadlib use in domain modules. Restrict to approved
native adapters and trusted loading. A native implementation must satisfy its C ABI, memory and concurrency
requirements.

**Rationale:** The restriction belongs to the named project profile, not a claim that Lua lacks the
facility.

**Verification design:** Review every occurrence and its owner. Exercise the approved alternative and
failure handling.

**Related controls:** [LSTYLE-058](lua-code-standard.md#lstyle-058),
[LSTYLE-062](lua-code-standard.md#lstyle-062).

**Source context:** [Lua facilities and semantics][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> Expose a narrow typed-by-contract Lua API with verified native ownership.
> ```

---

<a id="lban-016"></a>

### LBAN-016: Diagnostic suppression as implementation

**Class:** SECURITY / CORRECTNESS. **Obligation:** project requirement.

Scope: Blanket lint disables, formatter ignores and fabricated PASS records. Do not add them to avoid
correcting the source or qualifying a needed profile change. An approved deviation is explicit, scoped and
independently reviewable.

**Rationale:** The restriction belongs to the named project profile, not a claim that Lua lacks the
facility.

**Verification design:** Review every occurrence and its owner. Exercise the approved alternative and
failure handling.

**Related controls:** [LSTYLE-002](lua-code-standard.md#lstyle-002),
[LSTYLE-064](lua-code-standard.md#lstyle-064), [LSTYLE-069](lua-code-standard.md#lstyle-069).

**Source context:** [Lua facilities and semantics][lua55].

#### Local examples

**Contract or layout example (not executable):**

> ```text
> Correct the implementation or report the requirement and evidence as not satisfied.
> ```

---

<a id="cross-language-matrix"></a>
<a id="runtime-responsibilities"></a>

## Appendix A. Lua and host responsibilities

Use this table to assign implementation and verification work. A host-specific guarantee belongs in the
selected profile and adapter contract, with a failure test at its Lua interface.

| Concern | Lua implementation | Host or adapter responsibility |
| --- | --- | --- |
| Visibility | Lexical locals and explicit export tables. | Control module search paths and native loading. |
| Dependencies | Named imports, injected ports and a composition root. | Package the approved source and artifacts. |
| Ownership | Track aliases, retained closures and open/closed state. | Keep native allocations alive until last use. |
| Immutable data | Copy inputs or restrict access to private records. | Define native buffer mutation rights. |
| Numbers | Validate range, precision and arithmetic domains. | Check integer conversions and ABI widths. |
| Serialization | Define encoding, length, order and version. | Implement explicit codecs without layout assumptions. |
| Failures | Return documented statuses; protect exception boundaries. | Translate host failures and preserve cleanup errors. |
| Cleanup | One normal output; close acquired resources in owner order. | Release each handle through its matching API. |
| Callbacks | Document retention, yield and reentry. | Unregister and drain callbacks before freeing context. |
| Concurrency | Track coroutine state and allowed suspension points. | Synchronize OS threads and shared native memory. |
| Resources | Bound work, input sizes and retained state. | Enforce process memory, time and handle limits. |
| Performance | Measure workloads, allocation and trace behavior. | Measure native layout and hardware-specific effects. |
| Verification | Exercise contracts, failure paths and reference results. | Test deployed runtimes, ABIs and native dependencies. |

---

<a id="resource-example"></a>

## Appendix B. Complete owned-resource example

Save the following block as `bounded_resource.lua`. It exports `RESOURCE_run(ports, context)`. The ports are
a trusted plain table with three stable functions: `open_fn(context)` returns `ret, handle`;
`work_fn(context, handle)` returns `ret, payload`; `close_fn(context, handle)` returns `ret`. Allowed
statuses are integer zero or one of -1 through -5. Names and meanings in this fixture are 0 success, -1
invalid request, -2 open failure, -3 work failure, -4 close failure and -5 unexpected exception/protocol
failure. These are example codes, not POSIX errno values.

The callbacks are synchronous and non-yielding by contract. The example does not enforce a hostile callback
sandbox, host thread safety or a yield prohibition. The open callback owns resources it has not returned and
must clean them up before raising an error. Any non-nil handle it returns, even with a failure status,
transfers one cleanup obligation to this operation. A nil handle on success is a protocol error. A callback
that leaks an undisclosed resource cannot be repaired by the caller.

A successful work payload is a string or false. Failure returns nil output. The public result tuple is `ret,
output, cleanup_ret`. The primary operation failure is preserved and the third result reports cleanup
failure independently. The close callback receives one attempt, not an automatic retry; a failed close does
not prove the underlying resource was released. A production adapter must define its post-failure validity
and recovery policy.

All acquisition/work exceptions are protected before shared cleanup. This demonstrates normal and
callback-error paths under the fixture assumptions, not recovery from arbitrary OOM, fatal host termination
or native process corruption. The multi-branch boundary merits the complexity review; no
complexity analyzer score is fabricated here.

### `bounded_resource.lua`

**Complete named source file:**

> ```lua
> -- SPDX-License-Identifier: GPL-3.0-only
> -- Owned callback fixture. Callbacks are trusted, synchronous and non-yielding.
>
> local resource = {}
> local RESOURCE_OK = 0
> local RESOURCE_EINVAL = -1
> local RESOURCE_EPROTO = -5
>
> local function resource_isStatus(value)
>    local ret = false
>
>    ret = type(value) == "number"
>       and value >= RESOURCE_EPROTO
>       and value <= RESOURCE_OK
>       and value % 1 == 0
>
>    ::function_output::
>    return ret
> end
>
> --- Run one owned-resource operation and preserve its first failure.
> ---@param ports table
> ---@param context table
> ---@return integer ret
> ---@return string|false|nil output
> ---@return integer cleanup_ret
> local function RESOURCE_run(ports, context)
>    local ret = RESOURCE_EINVAL
>    local cleanup_ret = RESOURCE_OK
>    local output = nil
>    local handle = nil
>    local open_fn = nil
>    local work_fn = nil
>    local close_fn = nil
>    local has_completed = false
>    local operation_ret = nil
>    local is_valid_status = false
>
>    if type(ports) ~= "table" or getmetatable(ports) ~= nil then
>       goto function_output
>    end
>
>    open_fn = ports.open_fn
>    work_fn = ports.work_fn
>    close_fn = ports.close_fn
>
>    if
>       type(open_fn) ~= "function"
>       or type(work_fn) ~= "function"
>       or type(close_fn) ~= "function"
>    then
>       goto function_output
>    end
>
>    has_completed, operation_ret, handle = pcall(open_fn, context)
>    ret = RESOURCE_EPROTO
>    if not has_completed then
>       goto function_output
>    end
>
>    is_valid_status = resource_isStatus(operation_ret)
>    if not is_valid_status then
>       goto function_output
>    end
>
>    ret = operation_ret
>    if ret ~= RESOURCE_OK then
>       goto function_output
>    end
>    if handle == nil then
>       ret = RESOURCE_EPROTO
>       goto function_output
>    end
>
>    has_completed, operation_ret, output = pcall(work_fn, context, handle)
>    ret = RESOURCE_EPROTO
>    if not has_completed then
>       goto function_output
>    end
>
>    is_valid_status = resource_isStatus(operation_ret)
>    if not is_valid_status then
>       goto function_output
>    end
>
>    ret = operation_ret
>    if ret == RESOURCE_OK and type(output) ~= "string" and output ~= false then
>       ret = RESOURCE_EPROTO
>    end
>
>    ::function_output::
>    if handle ~= nil then
>       has_completed, operation_ret = pcall(close_fn, context, handle)
>       cleanup_ret = RESOURCE_EPROTO
>       if has_completed then
>          is_valid_status = resource_isStatus(operation_ret)
>          if is_valid_status then
>             cleanup_ret = operation_ret
>          end
>       end
>       handle = nil
>       if ret == RESOURCE_OK and cleanup_ret ~= RESOURCE_OK then
>          ret = cleanup_ret
>       end
>    end
>    if ret ~= RESOURCE_OK then
>       output = nil
>    end
>    return ret, output, cleanup_ret
> end
>
> resource.RESOURCE_run = RESOURCE_run
>
> return resource
> ```

---

<a id="repository-checks"></a>

## Appendix C. Repository checks and authoring record

From a checkout, resolve its root with `git rev-parse --show-toplevel`, change to that absolute directory
and use the locked tools. The canonical invocation is `lua ./scripts/check/lua.lua`. The word `lua` here
means the selected locked executable, not any unrelated program on PATH. Provide the documented `LIBMEMALLOC_*`
overrides when the executables are installed elsewhere.

The runner uses the working Git inventory: tracked files and untracked additions, excluding deleted
files and ignored dependency caches. Its Lua selection includes supported extensionless shebang entries.
Verify that list when adding a new entry form. Markdown fences are not standalone Lua inputs and require
explicit extraction. See the [implemented gate contract](../../reference/lua-quality.md).

| Stage | Actual runner behavior | Evidence it does not supply |
| --- | --- | --- |
| Syntax | Batched `luac -p`. | Runtime behavior or API correctness. |
| Structure | Compiler-listing check of the outer initialization boundary. | Function contracts, complete SESE or ownership proof. |
| Complexity | Locked AST adapter; cyclomatic 10 and cognitive 15 limits. | Cohesion or behavioral correctness. |
| Dictionary | Dictionary generator with `--check`. | Full prose/security correctness. |
| Selene | Repository `selene.toml` and `libmemalloc-lua` standard. | Every rule in the Lua guides. |
| StyLua | `--check` and repository `stylua.toml`. | Semantic correctness or ownership. |
| LuaLS | Workspace check with repository config, level Warning. | Runtime enforcement of annotations. |

The dictionary command is `lua tools/lint/spell/dictionary/generate.lua --check`. The runner invokes Selene
and StyLua in bounded batches and LuaLS across the workspace. [The runner][check-lua] and
[workflow][lint-workflow], rather than this descriptive table, remain executable authority. EditorConfig and
Markdown checks are separate gates. No alternate linter configuration is supplied.

### Reproducing validation

Run the [Lua checker][check-lua] and the full local check driver in a prepared
working checkout; staging is not required for source discovery. Retain commands, tool identities, exit status,
and logs under `.cache/logs/checks/`. Keep failures visible. A formatter result does not prove
SESE, naming, ownership, complexity, or runtime correctness.

Extract complete documentation examples into `.cache/tests/lua-examples/` before
executing them. Test them with the selected runtime and retain their results;
contextual and negative fragments are not standalone test programs. A local Lua
5.4 run does not qualify the locked Lua 5.5 runtime or a LuaJIT profile.

### Integration and migration

Keep the Lua guides in `docs/standards/lua/`. No `.editorconfig` exemption or Lua configuration
edit is required by the document layout. In a disposable checkout, extract and lint the complete examples
with the pinned tools and review contextual snippets in their owning harness. Run the canonical repository
checks and the documentation gates before merge.

Existing Lua, including the current runner, contains snake_case function APIs, early returns and trusted
bootstrap loading. The new policy is not a statement that this existing code already conforms. Track
naming/SESE migration, preserve supported APIs at adapters and test each behavioral change. Add a dedicated
SESE/naming/dependency checker only through a separate reviewed change; the documents do not pretend such
automation is already installed.

---

<a id="coroutine-regression"></a>

## Appendix D. Coroutine cleanup regression

This complete `coroutine_regression.lua` fixture checks [LSTYLE-075](#lstyle-075) with PUC-Lua 5.4/5.5
syntax. It closes a separate worker, never the running coroutine. Assertions and deliberate errors belong to
the test harness; production code needs its own status and diagnostic policy. Release counts measure close
attempts, not successful release by a native provider.

> ```lua
> -- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer
> -- SPDX-License-Identifier: GPL-3.0-only
>
> --- Exercise explicit coroutine cleanup with the selected PUC-Lua runtime.
> local function coroutine_regression_main()
>    --- Create a worker whose body and close failures are independently set.
>    local function regression_createWorker(state, suspend, body_fail, close_fail)
>       --- Observe one release attempt and optionally inject a close failure.
>       local function regression_closeResource(_, cause)
>          local ret = nil
>
>          state.close_count = state.close_count + 1
>          state.close_cause = cause
>
>          if close_fail then
>             error("close failure", 0)
>          end
>
>          ::function_output::
>          return ret
>       end
>
>       --- Hold a close variable across the requested worker state transition.
>       local function regression_runWorker()
>          local ret = 0
>          local _resource <close> = setmetatable({}, {
>             __close = regression_closeResource,
>          })
>
>          if suspend then
>             coroutine.yield("waiting")
>          end
>
>          if body_fail then
>             error("body failure", 0)
>          end
>
>          ::function_output::
>          return ret
>       end
>
>       local ret = coroutine.create(regression_runWorker)
>
>       ::function_output::
>       return ret
>    end
>
>    --- Verify an ordinary completion releases once before explicit close.
>    local function regression_checkCompletion()
>       local ret = 0
>       local state = { close_count = 0 }
>       local worker = regression_createWorker(state, false, false, false)
>       local resume_ok, result = coroutine.resume(worker)
>       assert(resume_ok and result == 0, "normal worker must return success")
>
>       assert(state.close_count == 1, "resource must close exactly once")
>       assert(state.close_cause == nil, "normal close must not receive an error")
>       assert(coroutine.status(worker) == "dead", "closed worker must be dead")
>
>       assert(coroutine.close(worker), "closing a completed worker must succeed")
>       assert(state.close_count == 1, "resource must close exactly once")
>
>       ::function_output::
>       return ret
>    end
>
>    --- Verify abandonment and body failure retain distinct cleanup results.
>    local function regression_checkClose(body_fail, close_fail)
>       local ret = 0
>       local state = { close_count = 0 }
>       local worker =
>          regression_createWorker(state, not body_fail, body_fail, close_fail)
>       local resume_ok, result = nil, nil
>       local close_ok, close_error = nil, nil
>       local expected_error = nil
>
>       resume_ok, result = coroutine.resume(worker)
>       assert(
>          resume_ok == not body_fail,
>          "resume status must match injected failure"
>       )
>       assert(
>          state.close_count == 0,
>          "worker must retain its resource until close"
>       )
>
>       if body_fail then
>          assert(
>             result == "body failure",
>             "original body failure must remain available"
>          )
>          expected_error = "body failure"
>       else
>          assert(result == "waiting", "suspended worker must report waiting")
>          assert(
>             coroutine.status(worker) == "suspended",
>             "worker must be suspended"
>          )
>       end
>
>       if close_fail then
>          expected_error = "close failure"
>       end
>
>       close_ok, close_error = coroutine.close(worker)
>       assert(
>          close_ok == (expected_error == nil),
>          "close status must match expected error"
>       )
>
>       assert(
>          close_error == expected_error,
>          "close error must match injected failure"
>       )
>       assert(state.close_count == 1, "resource must close exactly once")
>       assert(coroutine.status(worker) == "dead", "closed worker must be dead")
>
>       if body_fail then
>          assert(
>             state.close_cause == "body failure",
>             "closer must observe original body error"
>          )
>          assert(
>             result == "body failure",
>             "original body failure must remain available"
>          )
>       else
>          assert(
>             state.close_cause == nil,
>             "normal close must not receive an error"
>          )
>       end
>
>       ::function_output::
>       return ret
>    end
>
>    local ret = 0
>
>    regression_checkCompletion()
>    regression_checkClose(false, false)
>    regression_checkClose(false, true)
>    regression_checkClose(true, false)
>    regression_checkClose(true, true)
>
>    ::function_output::
>    return ret
> end
>
> return coroutine_regression_main()
>
> -- EOF
> ```

Extract only this block, removing the Markdown quote prefix, then execute it with the locked runtime:

```sh
lua scripts/workspace/with_tools.lua luac -p .cache/tests/lua-examples/coroutine_regression.lua
lua scripts/workspace/with_tools.lua lua .cache/tests/lua-examples/coroutine_regression.lua
```

The five cases cover normal completion, suspended close, failed suspended close, body failure and combined
body/close failure. The last case checks that the original body result remains available even when closing
reports another error. This fixture does not establish native cancellation or LuaJIT behavior.

**Authoring check, 2026-09-25:** Lua 5.5.1 syntax and all five runtime cases passed. StyLua 2.5.2 and LuaLS 3.19.1 passed.
The repository metric adapter measured six functions within both complexity limits. Selene 0.31.0 parsed
this fixture but rejected its two `coroutine.close` uses because the current API catalogue does not declare
that operation; it reported no other errors or warnings. This is a runtime-profile example, not a claim
that the current repository source gate admits it. Adopting it as a checked-in Lua source requires a reviewed
API catalogue addition and the remaining profile checks under [LSTYLE-078](#lstyle-078). No suppression or
catalogue change is included here.

### Boundary review evidence

The primary boundary references were consulted on 2026-09-25. Lua semantics, local coding policy and tool
observations have separate authority. Freeze a source revision or digest for an audited runtime profile.

| Controls | Required evidence | Evidence from this fixture |
| --- | --- | --- |
| LSTYLE-073, LSTYLE-074 | Native stack, registry and continuation harness with fault injection. | Not exercised by a Lua-only fixture. |
| LSTYLE-075 | Resource counts, coroutine states and separate operation/cleanup errors. | Five runtime cases. |
| LSTYLE-076, LSTYLE-077 | Qualified LuaJIT build and native retention/drain tests. | Not exercised. |
| LSTYLE-078 | Compatibility results from every required parser. | No new Lua 5.5-only syntax adopted. |

---

<a id="links-and-references"></a>

## Links and references

[check-lua]: ../../../scripts/check/lua.lua
[editorconfig]: ../../../.editorconfig
[kong]: https://github.com/Kong/kong/blob/master/CONTRIBUTING.md
[lint-workflow]: ../../../.github/workflows/_lint.yml
[lua54]: https://www.lua.org/manual/5.4/manual.html
[lua55]: https://www.lua.org/manual/5.5/manual.html
[luals]: https://luals.github.io/wiki/annotations/
[luals-config]: ../../../tools/lint/code/lua/luals.json
[luarocks]: https://github.com/luarocks/lua-style-guide
[markdown-config]: ../../../tools/lint/code/md/markdownlint-cli2.jsonc
[modules]: https://hisham.hm/2014/01/02/how-to-write-lua-modules-in-a-post-module-world/
[olivine]: https://github.com/Olivine-Labs/lua-style-guide
[repo]: https://github.com/RafaelVVolkmer/libmemalloc
[roblox]: https://roblox.github.io/lua-style-guide/
[selene]: https://kampfkarren.github.io/selene/usage/configuration.html
[selene-config]: ../../../tools/lint/code/lua/selene.toml
[selene-standard]: ../../../tools/lint/code/lua/libmemalloc-lua.yml
[stylua]: https://github.com/JohnnyMorganz/StyLua
[stylua-config]: ../../../tools/lint/code/lua/stylua.toml
[toolchain]: ../../../tools/toolchain/lock.toml

<!-- EOF -->


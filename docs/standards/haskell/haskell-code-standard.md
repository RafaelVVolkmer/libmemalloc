<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Haskell Code Standard

Apply these local controls to all repository-owned Haskell files. Separate the pure state model from execution and
foreign adapters. Use the [pitfall catalogue](haskell-common-pitfalls.md) when designing failure tests and
the [compliance guide](haskell-compliance.md) when recording evidence.

<details>
<summary><strong>On this page</strong></summary>

- [Governance and profiles](#governance)
- [Source register](#sources)
- [Refinement audit and mathematical statements](#refinement-audit-and-mathematical-statements)
- [Language and presentation](#language-and-presentation)
- [Interfaces and values](#interfaces-and-values)
- [Evaluation and execution](#evaluation-and-execution)
- [Foreign boundaries](#foreign-boundaries)

<details>
<summary>Detailed control index</summary>

- [HSTYLE-LIQUID-001: Audit every function with Liquid Haskell](#hstyle-liquid-001)
- [HSTYLE-MATH-001: State each Haskell theorem mathematically](#hstyle-math-001)
- [HSTYLE-LANG-001: Declare the effective language](#hstyle-lang-001)
- [HSTYLE-FORMAT-001: Use the repository formatter](#hstyle-format-001)
- [HSTYLE-NAME-001: Use Haskell vocabulary for concepts](#hstyle-name-001)
- [HSTYLE-API-001: Publish explicit, documented interfaces](#hstyle-api-001)
- [HSTYLE-IMPORT-001: Make dependencies legible](#hstyle-import-001)
- [HSTYLE-DATA-001: Encode distinct states and units](#hstyle-data-001)
- [HSTYLE-PARTIAL-001: Make core failure explicit](#hstyle-partial-001)
- [HSTYLE-ERROR-001: Preserve rejection and incomplete work](#hstyle-error-001)
- [HSTYLE-NUM-001: State the arithmetic domain](#hstyle-num-001)
- [HSTYLE-CLASS-001: Preserve class laws and state identity](#hstyle-class-001)
- [HSTYLE-EVAL-001: Define where results are demanded](#hstyle-eval-001)
- [HSTYLE-TERMINATION-001: Account for exploration progress](#hstyle-termination-001)
- [HSTYLE-IO-001: Keep effects at execution boundaries](#hstyle-io-001)
- [HSTYLE-RESOURCE-001: Own cleanup and cancellation](#hstyle-resource-001)
- [HSTYLE-PROTOCOL-001: Validate complete external messages](#hstyle-protocol-001)
- [HSTYLE-FFI-001: Record representation and lifetime](#hstyle-ffi-001)
- [HSTYLE-FFI-002: Select runtime call behavior](#hstyle-ffi-002)
- [HSTYLE-FFI-003: Drain callbacks before releasing them](#hstyle-ffi-003)
- [HSTYLE-NAME-002: Module and source-file names](#hstyle-name-002)
- [HSTYLE-NAME-003: Package and executable names](#hstyle-name-003)
- [HSTYLE-NAME-004: Functions and local helpers](#hstyle-name-004)
- [HSTYLE-NAME-005: Parameters, locals and units](#hstyle-name-005)
- [HSTYLE-NAME-006: Data types and constructors](#hstyle-name-006)
- [HSTYLE-NAME-007: Record fields](#hstyle-name-007)
- [HSTYLE-NAME-008: Newtypes and accessors](#hstyle-name-008)
- [HSTYLE-NAME-009: Classes and methods](#hstyle-name-009)
- [HSTYLE-NAME-010: Type variables and kinds](#hstyle-name-010)
- [HSTYLE-NAME-011: Constants and predicates](#hstyle-name-011)
- [HSTYLE-NAME-012: Effects, lifecycle and errors](#hstyle-name-012)
- [HSTYLE-NAME-013: Aliases, acronyms and primes](#hstyle-name-013)
- [HSTYLE-NAME-014: Operators and fixity](#hstyle-name-014)
- [HSTYLE-NAME-015: Tests and foreign aliases](#hstyle-name-015)
- [HSTYLE-FORMAT-002: Line length and indivisible text](#hstyle-format-002)
- [HSTYLE-FORMAT-003: Indentation and continuation](#hstyle-format-003)
- [HSTYLE-BLANK-001: File block separation](#hstyle-blank-001)
- [HSTYLE-BLANK-002: Declaration groups](#hstyle-blank-002)
- [HSTYLE-BLANK-003: Logical groups inside functions](#hstyle-blank-003)
- [HSTYLE-BLANK-004: Imports, pragmas and EOF](#hstyle-blank-004)
- [HSTYLE-FORMAT-004: Operators and delimiters](#hstyle-format-004)
- [HSTYLE-FORMAT-005: Multiline signatures](#hstyle-format-005)
- [HSTYLE-FORMAT-006: Calls and long expressions](#hstyle-format-006)
- [HSTYLE-FORMAT-007: Lists, tuples and records](#hstyle-format-007)
- [HSTYLE-FORMAT-008: Export and import layout](#hstyle-format-008)
- [HSTYLE-FORMAT-009: Comments and strings](#hstyle-format-009)
- [HSTYLE-FORMAT-010: Source text and Unicode](#hstyle-format-010)
- [HSTYLE-SYNTAX-001: Function equations and guards](#hstyle-syntax-001)
- [HSTYLE-SYNTAX-002: Case expressions](#hstyle-syntax-002)
- [HSTYLE-SYNTAX-003: If expressions](#hstyle-syntax-003)
- [HSTYLE-SYNTAX-004: Let and where bindings](#hstyle-syntax-004)
- [HSTYLE-SYNTAX-005: Do notation and discarded results](#hstyle-syntax-005)
- [HSTYLE-SYNTAX-006: Lambdas and point-free expressions](#hstyle-syntax-006)
- [HSTYLE-SYNTAX-007: Record construction and updates](#hstyle-syntax-007)
- [HSTYLE-SYNTAX-008: Deriving and instance declarations](#hstyle-syntax-008)
- [HSTYLE-SYNTAX-009: Language and compiler pragmas](#hstyle-syntax-009)
- [HSTYLE-SYNTAX-010: Comprehensions and traversal](#hstyle-syntax-010)
- [HSTYLE-PERF-001: Demand and residency measurements](#hstyle-perf-001)
- [HSTYLE-CONCURRENCY-001: Shared state and worker lifetime](#hstyle-concurrency-001)

</details>

</details>

---

<a id="governance"></a>

## Governance and profiles

`MUST` is an acceptance requirement; `SHOULD` permits a recorded reason for an alternative. IDs belong to
libmemalloc, not to external authors. Each control states its scope, reason, contrasting examples,
verification and limits. Unless a control states otherwise, its exception route is
[HCOMP-003](haskell-compliance.md#hcomp-003): record the rule, scope, reason, evidence, owner and expiry.
An exception cannot turn missing evidence into a passed check or change Haskell semantics.

The **core** contains pure transition, exploration and certificate logic. **Adapters** own file access,
processes, clocks, cancellation and any future FFI. **Tests** may contain deliberate failures when isolated
and labeled. Examples marked as fragments need their surrounding declarations; only examples labeled
complete modules are standalone compilation inputs. Noncompliant examples illustrate failures of local
policy and may still compile.

The repository baseline is [GHC 9.4.7](../../../verification/engine/cabal.project), Haskell2010 in all three
[Cabal components](../../../verification/engine/libmemalloc-verifier.cabal), and the versioned dependency
freeze. New dependencies, extensions and warning sets require a reviewed configuration change. The
refinement coverage and mathematical-comment requirements below apply to the entire owned Haskell tree,
including existing code. Other rules apply to new and changed code. These requirements do not certify
the current implementation: functions without checked refinements remain an outstanding conformance gap.
Contextual examples illustrate their named control; a compilable example alone does not establish full compliance.

---

<a id="sources"></a>

## Source register

Read semantics from the Report and the adopted GHC manual. Use Kowainik for organization, Haddock for
documentation, and local configuration for formatting. Tibell and Tweag provide comparison material.
Consulted on 2026-10-15; section names identify the material used, including on pages without stable anchors.

| Source and revision | Sections and role |
| --- | --- |
| [Haskell 2010 Report, chapter 3](https://www.haskell.org/onlinereport/haskell2010/haskellch3.html) | Expressions; section 3.1 errors and bottom, 3.17 pattern matching |
| [Report, chapter 4](https://www.haskell.org/onlinereport/haskell2010/haskellch4.html) | Declarations, types, data and class instances |
| [Report, chapter 5](https://www.haskell.org/onlinereport/haskell2010/haskellch5.html) | Module exports and imports |
| [Report, chapter 6](https://www.haskell.org/onlinereport/haskell2010/haskellch6.html) | Section 6.2 strict evaluation, 6.3 classes and 6.4 numeric types |
| [GHC 9.4.7, controlling extensions](https://downloads.haskell.org/ghc/9.4.7/docs/users_guide/exts/control.html) | Edition and extension selection |
| [GHC 9.4.7, warnings](https://downloads.haskell.org/ghc/9.4.7/docs/users_guide/using-warnings.html) | Warning groups, incomplete patterns and missing signatures |
| [GHC 9.4.7, FFI](https://downloads.haskell.org/ghc/9.4.7/docs/users_guide/exts/ffi.html) | Safe/unsafe imports, callbacks, garbage collection and interruptible calls |
| [GHC 9.4.7 base, Control.Exception](https://downloads.haskell.org/ghc/9.4.7/docs/libraries/base-4.17.2.0/Control-Exception.html) | Evaluation, asynchronous exceptions, masking and resource brackets |
| [Kowainik, Haskell Style Guide](https://kowainik.github.io/posts/2019-02-06-style-guide) | Updated 2020-09-22; naming, exports, imports, data, signatures and strictness |
| [Johan Tibell, Haskell Style Guide](https://github.com/tibbe/haskell-style-guide/blob/0d4fea64a87195192faa376696ea094d1aed4baa/haskell-style.md) | Pinned revision; indentation, naming and comments, supplementary |
| [Tweag, Haskell style](https://github.com/tweag/guides/blob/8b7d8d1127d1368297f7cd636e7b2c04e99a4ef4/style/Haskell.md) | Pinned revision; layout of shared code, supplementary |

Local differences from Kowainik are intentional: two-space indentation, a 100-column formatting target,
single-line Haddock style, no imported extension bundle, and strictness chosen at a documented demand
boundary. Ordinary Haskell2010 deriving remains permitted; explicit strategies need the corresponding
extension. The checked-in [Fourmolu configuration](../../../tools/lint/code/haskell/fourmolu.yaml) decides
mechanical layout. These choices avoid enabling language features through an editorial reference.

---

## Refinement audit and mathematical statements

<a id="hstyle-liquid-001"></a>

### HSTYLE-LIQUID-001: Audit every function with Liquid Haskell

**MUST · all owned `.hs` and `.lhs` files and all their functions.** Include library and executable modules,
importers, parsers, certificate generators, adapters, tests and generated Haskell delivered by project tools.
Include private functions, local `where`/`let` helpers, class and instance methods, callbacks and lambdas.
Account for anonymous functions and inferred local refinements within their checked enclosing definition.
Export visibility, module role and unchanged source do not exempt a function.

Give each named function an explicit Liquid Haskell refinement contract for its admitted inputs and result.
Record invariants, failure behavior, arithmetic bounds and termination obligations where relevant. Check the
implementation against that contract with the pinned Liquid Haskell toolchain. For local functions whose
refinements the checker infers, retain their enclosing contract and evidence that their bodies were checked.
An unconstrained result type cannot substantiate a claimed functional property.

Run Liquid Haskell for every positive module and component in the acceptance inventory. Record each source
digest, function identity or source span, contract, effective options, checker result and dependency assumptions.
Reconcile the expected function inventory with the checked functions; a module-level success message or a
plugin pragma alone is insufficient evidence of complete coverage. Isolated negative fixtures must also run
through the checker and produce their intended rejection, recorded separately from positive coverage.

Do not replace checks of owned function bodies with `assume`, ignored bindings, disabled checks or a build
without the plugin. Identify external-library, `IO` and FFI assumptions and the properties they leave open.
Unsupported code, absent coverage, a timeout or a failed check keeps the affected obligation incomplete;
refactor the boundary or supply supported contracts before claiming conformance. Testing or Lean validation
of generated certificates does not discharge this Haskell coverage requirement.

**Reason and examples:** Auditing arithmetic helpers alone leaves the importer, state machine and certificate
producer outside the required audit. Conforming evidence accounts for every function in every owned component.
Nonconforming evidence labels the engine audited after checking only `Refined.hs`.

**Verification and limits:** Require the function inventory, refinement-check logs and intended negative
rejections under [HTEST-005](test/haskell-tests-formal.md#htest-005). Review contract strength and assumptions.
Liquid Haskell evidence covers the checked refinements under those assumptions; it does not establish a
C-to-IR refinement or binary correctness. The current pipeline checks only the `Refined.hs` slice and does
not yet satisfy this whole-tree requirement. No exemption may relabel an unchecked function as audited.

<a id="hstyle-math-001"></a>

### HSTYLE-MATH-001: State each Haskell theorem mathematically

**MUST · every theorem, lemma and dedicated formal-property function in owned Haskell.** Put its mathematical
statement in a comment immediately above the declaration group, including private, local, regression and
generated proof helpers. Use a `-- |` Haddock block, then the Liquid Haskell annotation, ordinary signature and
equations, with no unrelated declaration between them. Use a preceding `--` block for a local binding where
Haddock cannot attach a declaration comment. A module summary or a comment below the body does not satisfy this rule.

Start the mathematical part with `Mathematical statement:`. Specify quantified variables and their domains,
all hypotheses and the conclusion in mathematical notation. Define symbols that differ from code identifiers,
units, arithmetic semantics and the meaning of any witness value. For a state theorem, include the initial
and final state, permitted changes and unchanged state. State the proved implication even for an obvious lemma.
Keep the comment, refinement and implementation consistent in the same change.

**Conforming contextual fragment:**

```haskell
-- | Mathematical statement: ∀ a, b ∈ ℤ, (0 ≤ a ∧ 0 ≤ b) ⇒ 0 ≤ a + b.
-- 'nonnegativeSum' returns True as a witness; Integer addition is unbounded.
{-@ nonnegativeSum :: a:{Integer | 0 <= a}
                   -> b:{Integer | 0 <= b} -> {ok:Bool | ok} @-}
nonnegativeSum :: Integer -> Integer -> Bool
nonnegativeSum a b = 0 <= a + b
```

**Nonconforming fragment:**

```haskell
-- Proves that the sum is safe.
nonnegativeSum :: Integer -> Integer -> Bool
nonnegativeSum a b = 0 <= a + b
```

**Reason and verification:** The second fragment omits the admitted domain and has no checked refinement.
Review the mathematical statement against the actual contract and checker result, including quantifier order
and assumptions. [HDOC-004](haskell-documentation.md#hdoc-004) defines placement and review evidence.
Comments explain a theorem; they do not constitute its proof. This requirement has no visibility-based exemption.

---

## Language and presentation

<a id="hstyle-lang-001"></a>

### HSTYLE-LANG-001: Declare the effective language

**MUST · all components.** Declare Haskell2010 and the compiler pin; list additional extensions where used.
The current extension inventory is `CPP` in `Refined.hs`, with the Liquid Haskell plugin under `LMA_LIQUID`.
Do not copy Kowainik's extension defaults into Cabal without review.

**Reason and examples:** An implicit compiler default can change. Conforming: `default-language: Haskell2010`
and a reviewed module `LANGUAGE` pragma. Nonconforming: relying on the developer's global GHC options.

**Verification and limit:** Inspect Cabal, pragmas and effective build flags; compile both refinement and
ordinary test profiles. GHC accepts extensions but does not decide whether the project permits them.
Source: GHC 9.4.7, controlling extensions.

**Conforming contextual fragment:**

```text
default-language: Haskell2010
ghc-options: -Wall -Wcompat -Wincomplete-uni-patterns -Werror
```

**Nonconforming fragment (do not copy):**

```text
-- Nonconforming build policy: omit default-language and inherit user-wide flags.
```

<a id="hstyle-format-001"></a>

### HSTYLE-FORMAT-001: Use the repository formatter

**MUST · source.** Run the pinned Fourmolu configuration. Keep two-space indentation, LF endings, a
100-column target and the source license/EOF conventions. Let Fourmolu arrange imports, records and guards.

**Reason and examples:** Stable layout makes semantic changes visible. Conforming: formatting with the
repository configuration. Nonconforming: substituting an editor's default Ormolu output without comparison.

**Verification and limit:** `check-haskell.lua --lint` runs Fourmolu and HLint. A formatting pass establishes
layout only; the column target cannot split every token or comment. Review long indivisible literals.

**Conforming contextual fragment:**

```haskell
remaining capacity used = capacity - used
```

**Nonconforming fragment (do not copy):**

```haskell
remaining capacity used=capacity-used
```

<a id="hstyle-name-001"></a>

### HSTYLE-NAME-001: Use Haskell vocabulary for concepts

**SHOULD · source.** Use `UpperCamelCase` for types, constructors and module components; use `lowerCamelCase`
for functions and values. Prefer domain names to new symbolic operators. Distinguish counts from byte offsets.

**Reason and examples:** Conforming: `ByteCount`, `reserveBytes`, `remainingCapacity`. Nonconforming:
`LMA_RESERVE_BYTES` for a Haskell function or an unexplained `(~#~)` transition operator.

**Verification and limit:** Review names and search call sites; Fourmolu cannot establish meaning.
Source: Kowainik, Naming. Existing public identities need a migration plan before renaming.

**Conforming contextual fragment:**

```haskell
data ReserveError = CapacityExceeded
reserveBytes :: Cursor -> Integer -> Either ReserveError Cursor
```

**Nonconforming fragment (do not copy):**

```haskell
data E = E1
f :: Cursor -> Integer -> Either E Cursor
```

---

## Interfaces and values

<a id="hstyle-api-001"></a>

### HSTYLE-API-001: Publish explicit, documented interfaces

**MUST · library modules.** Write explicit export lists and top-level type signatures. Document exported
types, values and invariants with [Haddock contracts](haskell-documentation.md#hdoc-001). Hide constructors
whose unrestricted use would invalidate a representation invariant.

**Reason and examples:** Conforming fragment: `module Reservation (Cursor, reserve) where` and
`reserve :: Cursor -> Integer -> Either ReserveError Cursor`. Nonconforming: exporting the entire module
and leaving callers to infer an error convention from its implementation.

**Verification and limit:** Review exports and rendered Haddock; current GHC `-Wall` covers missing
top-level signatures, but the configured checks do not establish export completeness or contract accuracy.
Sources: Kowainik, Export lists and Function declaration; Report chapter 5.

**Conforming contextual fragment:**

```haskell
module Reservation (Cursor, reserve) where

-- | Reserve bytes or return the rejection reason.
reserve :: Cursor -> Integer -> Either ReserveError Cursor
```

**Nonconforming fragment (do not copy):**

```haskell
module Reservation where

reserve cursor request = update cursor request
```

<a id="hstyle-import-001"></a>

### HSTYLE-IMPORT-001: Make dependencies legible

**MUST · library modules.** Use explicit import lists or qualified imports with recognizable aliases.
The implicit Prelude is permitted. Keep imports at the module boundary and avoid unrelated reexports.

**Reason and examples:** Conforming: `import qualified Data.Map.Strict as Map`. Nonconforming: an unqualified
wildcard import that silently changes name resolution after a dependency adds an export.

**Verification and limit:** Review imports and package dependencies; compile for name conflicts. HLint and
GHC do not enforce the whole dependency policy. Sources: Report chapter 5; Kowainik, Imports.

**Conforming contextual fragment:**

```haskell
import qualified Data.Map.Strict as Map
import LibMemAlloc.Verifier.IR (Program)
```

**Nonconforming fragment (do not copy):**

```haskell
import Data.Map.Strict
import LibMemAlloc.Verifier.IR
```

<a id="hstyle-data-001"></a>

### HSTYLE-DATA-001: Encode distinct states and units

**SHOULD · core APIs.** Use sum types for alternatives and `newtype` for quantities that must not interchange.
Use total accessors or pattern matches for sums; avoid selectors absent from some constructors.

**Reason and examples:** Conforming: `data Outcome = Rejected ReserveError | Reserved Cursor`.
Nonconforming: a pair of booleans admitting both success and failure, or a partial `cursor` record selector.

**Verification and limit:** Review constructors, matches and instance laws; test all variants. A `newtype`
separates types but does not validate ranges or guarantee termination. Source: Report chapter 4.

**Conforming contextual fragment:**

```haskell
data Outcome = Rejected ReserveError | Reserved Cursor
```

**Nonconforming fragment (do not copy):**

```haskell
data Outcome = Outcome Bool Bool Cursor
```

<a id="hstyle-partial-001"></a>

### HSTYLE-PARTIAL-001: Make core failure explicit

**MUST · core and protocol parsing.** Represent expected failure with `Either`, `Maybe` or a domain sum.
Exclude `undefined`, `error`, unchecked list indexing, partial selectors, `fromJust` and partial `read` on
admitted inputs. Handle empty collections and every constructor. Do not use exceptions for rejection.

**Reason and examples:** Conforming: `case xs of [] -> Nothing; x : _ -> Just x`. Nonconforming: `head xs`
after a comment saying callers supply nonempty input. The Report permits bottom; purity does not imply totality.

**Verification and limit:** Review partial operations, compile with warnings as errors and test malformed
inputs. Exhaustive patterns do not prove recursive termination or exclude bottom inside a value.
Source: Report sections 3.1 and 3.17. Exceptions require changing the admitted domain or using a validated type.

**Conforming contextual fragment:**

```haskell
first [] = Nothing
first (value : _) = Just value
```

**Nonconforming fragment (do not copy):**

```haskell
first values = head values
```

<a id="hstyle-error-001"></a>

### HSTYLE-ERROR-001: Preserve rejection and incomplete work

**MUST · transitions and analysis.** Distinguish a counterexample, unsupported input, resource exhaustion and
successful completion. Define the post-state and effects for each failure. Preserve the original cause.

**Reason and examples:** Conforming: an exploration limit produces an incomplete result with the remaining
frontier. Nonconforming: converting `Left Unsupported` or a timeout into an empty successful result.

**Verification and limit:** Exercise each branch and require the driver to reject incomplete evidence.
A type containing `Either` alone cannot establish that every caller handles `Left` correctly.

**Conforming contextual fragment:**

```haskell
data Exploration = Complete Certificate | Incomplete BudgetReason | Counterexample Trace
```

**Nonconforming fragment (do not copy):**

```haskell
recover (Left _) = Right EmptyCertificate
```

<a id="hstyle-num-001"></a>

### HSTYLE-NUM-001: State the arithmetic domain

**MUST · arithmetic and serialization.** Choose `Integer` for mathematical values and state explicit bounds
when relating them to C. Validate before narrowing to `Int`, `Word` or a foreign type. Check divisors before
division; specify signed division and remainder behavior. Reject malformed and out-of-range input.

**Reason and examples:** Conforming: check `0 <= n && n <= limit` before conversion. Nonconforming:
`fromIntegral n` as range validation, or checking an `Int` sum for overflow only after computing it.

**Verification and limit:** Test zero, the maximum, its successor and negative values; compare to the
[representation contract](../formal-integration.md#xlang-002). GHC type checking does not prove bounds.
Source: Report section 6.4; concrete machine-type behavior also depends on GHC/base and the target.

**Conforming contextual fragment:**

```haskell
fits used request capacity =
  used >= 0 && request >= 0 && used <= capacity && request <= capacity - used
```

**Nonconforming fragment (do not copy):**

```haskell
fits used request capacity = used + request <= capacity -- bounded machine arithmetic
```

<a id="hstyle-class-001"></a>

### HSTYLE-CLASS-001: Preserve class laws and state identity

**MUST · model instances.** Document and test `Eq`/`Ord` agreement for states used in sets or maps. Define
the minimal complete methods. Review deriving and any projection used to identify visited states.

**Reason and examples:** Conforming: equality and ordering use the same semantic state fields.
Nonconforming: `Eq` compares an epoch while `Ord` discards it, merging distinct reachable states.

**Verification and limit:** Test reflexivity, order consistency and distinct-state retention; review each
abstraction relation. Tests sample laws. Source: Report section 6.3, including mutually recursive defaults.

**Conforming contextual fragment:**

```haskell
data StateKey = StateKey Integer Integer deriving (Eq, Ord)
```

**Nonconforming fragment (do not copy):**

```haskell
-- Nonconforming: Eq compares address and epoch; Ord compares address alone.
```

---

## Evaluation and execution

<a id="hstyle-eval-001"></a>

### HSTYLE-EVAL-001: Define where results are demanded

**MUST · core/adapter boundaries.** Document the required evaluation depth before releasing resources or
publishing success. Review strict fields and strict folds against their retention and exception behavior.
Do not enable blanket strictness as a formatting change.

**Reason and examples:** Conforming: consume and validate file contents inside their resource scope.
Nonconforming: returning a lazy file-backed value and closing its handle before consumption. `seq` and
`evaluate` force only weak head normal form; nested fields can retain unevaluated work.

**Verification and limit:** Test nested exceptional values and measure residency on large traces. When using
`force`, review the `NFData` instance and dependency choice. Strictness does not prove a memory bound.
Sources: Report section 6.2; GHC/base Control.Exception, Evaluation.

**Conforming contextual fragment:**

```haskell
content <- hGetContents handle
evaluate (force content) -- within the resource scope
```

**Nonconforming fragment (do not copy):**

```haskell
pure (parse content) -- a lazy result can defer failure beyond the handler
```

<a id="hstyle-termination-001"></a>

### HSTYLE-TERMINATION-001: Account for exploration progress

**MUST · search and recursive analysis.** State a decreasing measure, a finite visited-state argument, or an
explicit budget. Record frontier size, visited-state equality, bounds and completion criteria.

**Reason and examples:** Conforming: reaching a budget returns incomplete evidence, while an empty frontier
with all successors accounted for establishes closure of the declared finite domain. Nonconforming:
labeling a depth-limited search exhaustive or silently dropping successors.

**Verification and limit:** Test cycles, repeated states, budget exhaustion and missing transitions.
Finite test domains do not imply termination or safety for unbounded machine states.

**Conforming contextual fragment:**

```haskell
explore 0 frontier = Left (BudgetExhausted frontier)
explore fuel frontier = continue (fuel - 1) frontier
```

**Nonconforming fragment (do not copy):**

```haskell
explore 0 _ = Right Verified
```

<a id="hstyle-io-001"></a>

### HSTYLE-IO-001: Keep effects at execution boundaries

**MUST · core.** Pass model inputs and results as values. Keep filesystem, environment, time and process
access in adapters; exclude `unsafePerformIO` and hidden mutable global state from model semantics.

**Reason and examples:** Conforming: parse a supplied byte sequence, then call a pure transition.
Nonconforming: read an environment variable inside a supposedly deterministic transition.

**Verification and limit:** Review imports, types and unsafe facilities; repeat traces with explicit inputs.
A pure type does not establish totality or absence of hidden effects in dependencies. Source: Report section 6.1.7.

**Conforming contextual fragment:**

```haskell
transition :: State -> Command -> Either TransitionError State
```

**Nonconforming fragment (do not copy):**

```haskell
transition state command = unsafePerformIO (readEnvironmentAndStep state command)
```

<a id="hstyle-resource-001"></a>

### HSTYLE-RESOURCE-001: Own cleanup and cancellation

**MUST · adapters.** Use scoped acquisition/release such as `bracket`; state how cancellation, subprocess
termination and cleanup failures affect the result. Catch intended exception types. Do not convert asynchronous
cancellation into success or keep masking active across an unbounded operation.

**Reason and examples:** Conforming: an adapter closes its handle on parse failure and propagates cancellation.
Nonconforming: a broad `SomeException` handler returning an empty successful report.

**Verification and limit:** Inject failures after acquisition and during consumption; check resource release
and child-process exit. `bracket` alone does not guarantee bounded cleanup. Source: GHC/base Control.Exception.

**Conforming contextual fragment:**

```haskell
withFile path ReadMode consumeTrace
```

**Nonconforming fragment (do not copy):**

```haskell
handle <- openFile path ReadMode
consumeTrace handle
hClose handle
```

<a id="hstyle-protocol-001"></a>

### HSTYLE-PROTOCOL-001: Validate complete external messages

**MUST · import and certificate boundaries.** Check schema, version, required fields, numeric ranges, input
identity and trailing data. Reject unsupported constructs. Bound message size and nesting before expensive work.
Generate Lean through a controlled syntax writer; do not splice external identifiers as arbitrary Lean code.

**Reason and examples:** Conforming: reject an unknown operation with its source location. Nonconforming:
skip it, then certify the remaining operations or accept an old certificate for a changed input.

**Verification and limit:** Mutate fields, truncate files, add suffixes and replay stale artifacts. Schema
validation does not establish the source-to-model relation. Follow [XLANG-004](../formal-integration.md#xlang-004).

**Conforming contextual fragment:**

```haskell
decodeOperation tag = Left (UnsupportedOperation tag)
```

**Nonconforming fragment (do not copy):**

```haskell
decodeOperation _ = Right NoOp
```

---

## Foreign boundaries

The current engine has no direct Haskell FFI binding. These are conditional requirements for future adapters,
with semantics grounded in GHC 9.4.7's FFI chapter. They do not require adding an FFI dependency now.

<a id="hstyle-ffi-001"></a>

### HSTYLE-FFI-001: Record representation and lifetime

**MUST · each foreign entry point.** Record C declaration, calling convention, widths, alignment, lengths,
nullability, ownership, aliasing, retention and release authority. Use matching `Foreign.C.Types` and checked
`Storable` layouts. Keep the backing allocation alive for the full foreign use.

**Reason and examples:** Conforming: scoped access through `withForeignPtr` while C borrows the pointer and
does not retain it. Nonconforming: store a borrowed address in C after that scope, or assume `Int` equals `size_t`.

**Verification and limit:** Compare C `sizeof`/alignment/offsets, test both sides under C sanitizers, and review
retained references. A `Ptr a` carries no dynamic lifetime proof; finalizers are not prompt release guarantees.

**Conforming contextual fragment:**

```haskell
withForeignPtr owner $ \pointer -> c_useSynchronously pointer lengthBytes
```

**Nonconforming fragment (do not copy):**

```haskell
withForeignPtr owner c_retainWithoutOwnership
```

<a id="hstyle-ffi-002"></a>

### HSTYLE-FFI-002: Select runtime call behavior

**MUST · each foreign call.** Justify `safe`, `unsafe` or `interruptible` using callback, blocking and runtime
requirements. Treat these as GHC execution modes. C memory safety needs its own contract and evidence.

**Reason and examples:** Conforming: a call that may reenter Haskell uses the supported `safe` path and rooted
callback data. Nonconforming: an `unsafe` import that invokes a Haskell callback, or a long blocking call
chosen as `unsafe` solely to save call overhead.

**Verification and limit:** Test callback reentry, concurrent collection and cancellation on the target runtime.
GHC restrictions on GC during `unsafe` calls do not establish pointer validity. Interruptibility does not
promise cancellation of arbitrary C code.

**Conforming contextual fragment:**

```haskell
foreign import ccall safe "invoke_callback" c_invokeCallback :: IO ()
```

**Nonconforming fragment (do not copy):**

```haskell
foreign import ccall unsafe "invoke_callback" c_invokeCallback :: IO ()
```

<a id="hstyle-ffi-003"></a>

### HSTYLE-FFI-003: Drain callbacks before releasing them

**MUST · callback adapters.** Give function pointers and stable pointers an owner. Unregister and drain
in-flight callbacks before freeing their handles. Translate errors at the callback boundary and define thread use.

**Reason and examples:** Conforming: unregister, wait for active callbacks, then release the wrapper and roots.
Nonconforming: free a `FunPtr` while C retains it or allow an uncaught Haskell exception across the foreign boundary.

**Verification and limit:** Exercise callbacks racing with shutdown and repeated registration. A garbage
collector cannot infer C's ownership protocol. Source: GHC FFI, foreign exports, callbacks and memory management.

**Conforming contextual fragment:**

```haskell
c_unregister callback
waitForCallbacks
freeHaskellFunPtr callback
```

**Nonconforming fragment (do not copy):**

```haskell
freeHaskellFunPtr callback
c_unregister callback
```

---

## Detailed naming, whitespace and syntax controls

These controls define the local spelling and source layout for each category. They refine the earlier policy controls.
Examples are contextual fragments unless marked complete: surrounding types, imports and values may be supplied by the
owning module. A nonconforming fragment may be legal code that violates a local convention, or deliberately invalid
syntax. Do not compile the negative set as positive examples. Formatting examples use the pinned profile.

---

<a id="hstyle-name-002"></a>

### HSTYLE-NAME-002: Module and source-file names

**Class:** local engineering control. **Obligation:** MUST. **Scope:** modules and directories.

Use dotted UpperCamelCase module names matching the source-relative directory and filename. Use LibMemAlloc.Verifier
for engine modules. Keep app and test as separate source roots.

**Rationale:** Case-sensitive resolution must work on Linux and in the package inventory.

**Conforming contextual fragment:**

```haskell
-- src/LibMemAlloc/Verifier/Reservation.hs
module LibMemAlloc.Verifier.Reservation (reserve) where
```

**Nonconforming fragment (do not copy):**

```haskell
-- src/libmemalloc/verifier/reservation.hs
module Reservation where
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-name-003"></a>

### HSTYLE-NAME-003: Package and executable names

**Class:** local engineering control. **Obligation:** MUST. **Scope:** Cabal components.

Use lowercase hyphen-separated package and executable names; preserve libmemalloc-verifier. Name a test component
after the behavior it covers, such as engine-tests. Module names retain Haskell case.

**Rationale:** Package identities and module identities serve different resolution mechanisms.

**Conforming contextual fragment:**

```text
name: libmemalloc-verifier
executable libmemalloc-verifier
test-suite engine-tests
```

**Nonconforming fragment (do not copy):**

```text
name: LibMemAllocVerifier
executable runIt
test-suite test
```

**Verification and limits:** Review the Cabal component inventory and build plan with the pinned GHC/Cabal.
The compiler does not enforce package naming or decide which test component owns a contract.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-name-004"></a>

### HSTYLE-NAME-004: Functions and local helpers

**Class:** local engineering control. **Obligation:** MUST. **Scope:** value declarations.

Use lowerCamelCase verbs for operations and nouns for computed values. Apply the same convention to public and private
functions; the export list determines visibility. Use go only for a short local recursion helper.

**Rationale:** A C-style uppercase prefix does not express Haskell visibility.

**Conforming contextual fragment:**

```haskell
remainingBytes :: Cursor -> Integer
remainingBytes (Cursor capacity used) = capacity - used
```

**Nonconforming fragment (do not copy):**

```haskell
CURSOR_REMAINING_BYTES :: Cursor -> Integer
CURSOR_REMAINING_BYTES = getVal
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-name-005"></a>

### HSTYLE-NAME-005: Parameters, locals and units

**Class:** local engineering control. **Obligation:** MUST. **Scope:** bindings.

Use lowerCamelCase and explicit units for quantities: `requestedBytes`, `timeoutMillis`, `stateCount` and `cellIndex`.
Use
short names such as x and `xs` only when the expression is generic and local. Do not shadow domain inputs.

**Rationale:** Units and role distinguish a byte count from a cell index.

**Conforming contextual fragment:**

```haskell
fits :: Integer -> Integer -> Bool
fits capacityBytes requestedBytes = requestedBytes <= capacityBytes
```

**Nonconforming fragment (do not copy):**

```haskell
fits :: Integer -> Integer -> Bool
fits c r = r <= c
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-name-006"></a>

### HSTYLE-NAME-006: Data types and constructors

**Class:** local engineering control. **Obligation:** MUST. **Scope:** algebraic data types.

Use UpperCamelCase for data types and constructors. Name each alternative after its domain state. For a
single-constructor wrapper, use the type name unless an established API requires otherwise.

**Rationale:** Constructor names appear in traces and error messages.

**Conforming contextual fragment:**

```haskell
data ExplorationResult = Complete Certificate | Incomplete BudgetReason
```

**Nonconforming fragment (do not copy):**

```haskell
data X = A Certificate | B BudgetReason
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-name-007"></a>

### HSTYLE-NAME-007: Record fields

**Class:** local engineering control. **Obligation:** MUST. **Scope:** record declarations.

Prefix fields with the lowerCamelCase type name, or a documented abbreviation when the full prefix makes field names
difficult to read.
Include units in quantity fields. Do not enable DuplicateRecordFields just to avoid choosing names.

**Rationale:** The Haskell2010 field namespace otherwise invites collisions and ambiguous imports.

**Conforming contextual fragment:**

```haskell
data Budget = Budget
  { budgetStateCount :: !Integer
  , budgetTimeoutMillis :: !Integer
  }
```

**Nonconforming fragment (do not copy):**

```haskell
data Budget = Budget { count :: Integer, timeout :: Integer }
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-name-008"></a>

### HSTYLE-NAME-008: Newtypes and accessors

**Class:** local engineering control. **Obligation:** MUST. **Scope:** nominal wrappers.

Use a matching constructor and an unTypeName accessor for a simple representation projection. Hide constructors and
accessors when they would bypass validation; provide a checked mkTypeName constructor.

**Rationale:** Naming a smart constructor does not validate unchecked exported constructors.

**Conforming contextual fragment:**

```haskell
newtype ByteCount = ByteCount { unByteCount :: Integer }
-- Export mkByteCount instead of ByteCount (..) when nonnegativity is required.
```

**Nonconforming fragment (do not copy):**

```haskell
type ByteCount = Integer
-- A synonym does not prevent mixing bytes and cell indices.
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-name-009"></a>

### HSTYLE-NAME-009: Classes and methods

**Class:** local engineering control. **Obligation:** MUST. **Scope:** type classes.

Use UpperCamelCase capability names and lowerCamelCase method names. Name laws after the behavior they constrain;
document the minimal complete methods. Avoid a class for a single implementation without a need.

**Rationale:** A class introduces laws and instance-resolution commitments for clients.

**Conforming contextual fragment:**

```haskell
class RenderEvidence a where
  renderEvidence :: a -> String
```

**Nonconforming fragment (do not copy):**

```haskell
class Thing a where
  doStuff :: a -> String
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-name-010"></a>

### HSTYLE-NAME-010: Type variables and kinds

**Class:** local engineering control. **Obligation:** MUST. **Scope:** polymorphic signatures.

Use a, b for generic element types, f for a functor and m for an effect constructor. Use descriptive lowercase
variables when roles differ, such as state or command. Keep kind annotations explicit when an approved extension
introduces nontrivial kinds.

**Rationale:** Role names improve signatures without changing their generality.

**Conforming contextual fragment:**

```haskell
mapResult :: (a -> b) -> Either failure a -> Either failure b
```

**Nonconforming fragment (do not copy):**

```haskell
mapResult :: (x1 -> x2) -> Either x3 x1 -> Either x3 x2
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-name-011"></a>

### HSTYLE-NAME-011: Constants and predicates

**Class:** local engineering control. **Obligation:** MUST. **Scope:** top-level values.

Use lowerCamelCase for constants as well as functions. Use is, has or can for `Bool` predicates when they clarify the
question. Include units in numeric limits and explain their origin.

**Rationale:** Uppercase identifiers are constructor syntax, not a constant convention in Haskell.

**Conforming contextual fragment:**

```haskell
maxTraceBytes :: Integer
maxTraceBytes = 1048576

isEmptyTrace :: [a] -> Bool
isEmptyTrace = null
```

**Nonconforming fragment (do not copy):**

```haskell
maxVal :: Integer
maxVal = 1048576
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-name-012"></a>

### HSTYLE-NAME-012: Effects, lifecycle and errors

**Class:** local engineering control. **Obligation:** MUST. **Scope:** API names.

Use acquire/release for owned resources, with for scoped borrowing and parse/decode for validation. Use a trailing
underscore only for the established convention of discarding a result. Name errors after the rejected condition, not
an arbitrary number.

**Rationale:** Names should distinguish allocation, borrowing and observation.

**Conforming contextual fragment:**

```haskell
withTraceHandle :: FilePath -> (Handle -> IO a) -> IO a
data ParseError = UnknownOperation | TrailingInput
```

**Nonconforming fragment (do not copy):**

```haskell
getTrace :: FilePath -> IO Handle
data ParseError = Error1 | Error2
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-name-013"></a>

### HSTYLE-NAME-013: Aliases, acronyms and primes

**Class:** local engineering control. **Obligation:** MUST. **Scope:** imports and local variants.

Use recognizable qualified aliases such as Map, Set and Text. Treat acronyms consistently within a word such as
JsonError. Reserve a prime for a nearby mathematical variant; prefer `nextState` to an unexplained s'''.

**Rationale:** Opaque aliases and prime chains conceal dependency and state roles.

**Conforming contextual fragment:**

```haskell
import qualified Data.Map.Strict as Map

nextState = Map.insert key value state
```

**Nonconforming fragment (do not copy):**

```haskell
import qualified Data.Map.Strict as M1

s''' = M1.insert k v s''
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-name-014"></a>

### HSTYLE-NAME-014: Operators and fixity

**Class:** local engineering control. **Obligation:** MUST. **Scope:** custom operators.

Prefer named functions for domain operations. A justified operator must have documented meaning, explicit fixity
adjacent to its signature, and a collision review. Retain standard operator meanings.

**Rationale:** Precedence silently changes grouping at call sites.

**Conforming contextual fragment:**

```haskell
infixr 1 >?>
(>?>) :: (a -> Maybe b) -> (b -> Maybe c) -> a -> Maybe c
(f >?> g) x = f x >>= g
```

**Nonconforming fragment (do not copy):**

```haskell
(>?>) f g x = f x >>= g
-- No signature, fixity or documented composition direction.
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-name-015"></a>

### HSTYLE-NAME-015: Tests and foreign aliases

**Class:** local engineering control. **Obligation:** MUST. **Scope:** test and binding names.

Use prop plus the property name for property bindings and descriptive test labels. Name a low-level imported C binding
with `c_` plus the C symbol; give its checked Haskell wrapper an idiomatic name. The `c_` prefix is an explicit
boundary
exception to lowerCamelCase.

**Rationale:** A reviewer must distinguish a raw binding from a validated operation.

**Conforming contextual fragment:**

```haskell
propReservePreservesCapacity :: Cursor -> Integer -> Bool
-- Future FFI binding name: c_LMA_cursorReserve
-- Checked wrapper name: reserveCursor
```

**Nonconforming fragment (do not copy):**

```haskell
test1 = True
-- A raw pointer import named reserveCursor hides its boundary.
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-format-002"></a>

### HSTYLE-FORMAT-002: Line length and indivisible text

**Class:** local engineering control. **Obligation:** MUST. **Scope:** source and comments.

Keep source and comment lines at or below 100 columns. Break signatures, calls and prose at syntactic boundaries.
Record exceptions for indivisible URLs, generated identities or external spellings; never split an identifier or
change literal contents merely to fit. Markdown prose uses the repository 120-column limit.

**Rationale:** A fixed width makes side-by-side review possible while preserving literal meaning.

**Conforming contextual fragment:**

```haskell
checkReservation ::
  Capacity ->
  Cursor ->
  Request ->
  Either ReserveError Cursor
```

**Nonconforming fragment (do not copy):**

```haskell
checkReservation :: Capacity -> Cursor -> Request -> Either ReserveError Cursor -- Append a long contract here until it exceeds the source limit.
```

**Verification and limits:** Fourmolu wraps supported syntax at column-limit 100; review comments and indivisible
tokens separately. The formatter is not a hard line-length validator.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-format-003"></a>

### HSTYLE-FORMAT-003: Indentation and continuation

**Class:** local engineering control. **Obligation:** MUST. **Scope:** layout blocks.

Use two spaces per body nesting level and no tabs. Let Fourmolu choose continuation indentation. Under the current
half-indent where setting, where sits one space from the declaration baseline and its bindings sit two spaces from
that baseline. The half-indent setting is a formatter-specific exception to body indentation.

**Rationale:** Layout determines parsing, so visual indentation and language structure must agree.

**Conforming contextual fragment:**

```haskell
double :: Integer -> Integer
double value = add value
 where
  add :: Integer -> Integer
  add other = value + other
```

**Nonconforming fragment (do not copy):**

```haskell
double value = add value
        where
             add other = value + other
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-blank-001"></a>

### HSTYLE-BLANK-001: File block separation

**Class:** local engineering control. **Obligation:** MUST. **Scope:** module prologue.

Order the file as pragmas when present, license block, module documentation/declaration, imports and declarations.
Use one blank line between those blocks. Keep the module Haddock comment attached to `module`. Keep consecutive
`LANGUAGE` pragmas contiguous. Preserve required CPP ordering when a plugin is conditional. This order follows the
current refinement module and preserves the blank lines under the pinned formatter.

**Rationale:** Each file block has a distinct role and should be easy to find.

**Conforming contextual fragment:**

```haskell
{-# LANGUAGE CPP #-}

-- SPDX-License-Identifier: GPL-3.0-only

-- | Scalar trace input.
module Trace (Trace) where

import Data.Word (Word64)

newtype Trace = Trace [Word64]
```

**Nonconforming fragment (do not copy):**

```haskell
-- | Scalar trace input.

module Trace (Trace) where
import Data.Word (Word64)
newtype Trace = Trace [Word64]
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-blank-002"></a>

### HSTYLE-BLANK-002: Declaration groups

**Class:** local engineering control. **Obligation:** MUST. **Scope:** top-level source.

Use one blank line between independent declarations. Keep a declaration's Haddock comment, signature and equations
adjacent. Keep all equations of the same function in one group. Do not use runs of empty lines for visual alignment;
use a named section when a new topic needs explanation.

**Rationale:** Blank lines should identify independent definitions rather than separate a type from its
implementation.

**Conforming contextual fragment:**

```haskell
-- | Recognize an empty trace.
isEmpty :: [a] -> Bool
isEmpty [] = True
isEmpty (_ : _) = False

traceLength :: [a] -> Int
traceLength = length
```

**Nonconforming fragment (do not copy):**

```haskell
isEmpty :: [a] -> Bool

isEmpty [] = True

isEmpty (_ : _) = False
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-blank-003"></a>

### HSTYLE-BLANK-003: Logical groups inside functions

**Class:** local engineering control. **Obligation:** MUST. **Scope:** do, let and where bodies.

Separate distinct phases with one blank line. Keep a fallible operation adjacent to the bind or case that handles its
result. Do not place a blank line after do, before a closing delimiter or between a guard and its right-hand side. Do
not add an empty line after every statement.

**Rationale:** A reader should see both sequencing and the error path as one unit.

**Conforming contextual fragment:**

```haskell
run path = do
  input <- readTrace path
  model <- decodeTrace input

  result <- execute model
  writeResult result
```

**Nonconforming fragment (do not copy):**

```haskell
run path = do

  input <- readTrace path

  model <- decodeTrace input

  result <- execute model

  writeResult result
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-blank-004"></a>

### HSTYLE-BLANK-004: Imports, pragmas and EOF

**Class:** local engineering control. **Obligation:** MUST. **Scope:** module scaffolding.

Keep related imports contiguous; use at most one blank line between intentional dependency groups. Use one blank line
before the terminal -- EOF and retain a blank line after it. Keep declaration pragmas beside their declaration,
following the definition for INLINE and SPECIALIZE.

**Rationale:** Attachment and end markers must survive routine formatting.

**Conforming contextual fragment:**

```haskell
identity :: a -> a
identity value = value
{-# INLINE identity #-}

-- EOF
```

**Nonconforming fragment (do not copy):**

```haskell
identity :: a -> a
identity value = value


{-# INLINE identity #-}
-- EOF
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-format-004"></a>

### HSTYLE-FORMAT-004: Operators and delimiters

**Class:** local engineering control. **Obligation:** MUST. **Scope:** expressions and types.

Use spaces around infix operators, ::, =, -> and =>; no spaces just inside parentheses or brackets. Let the formatter
choose comma placement. Do not vertically align = or :: with runs of spaces.

**Rationale:** Mechanical alignment creates unrelated diff changes after a rename.

**Conforming contextual fragment:**

```haskell
fits limit requested = requested >= 0 && requested <= limit
pair = (used, capacity)
```

**Nonconforming fragment (do not copy):**

```haskell
fits limit requested=requested>=0&&requested<=limit
pair = ( used , capacity )
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-format-005"></a>

### HSTYLE-FORMAT-005: Multiline signatures

**Class:** local engineering control. **Obligation:** MUST. **Scope:** type declarations.

Keep a short signature on one line. When wrapping, put the signature head before the argument/result lines and use the
formatter's trailing arrows. Keep constraints separate from value parameters. Document argument units when the types
do not encode them.

**Rationale:** The input and output types should remain visible without horizontal scrolling.

**Conforming contextual fragment:**

```haskell
render ::
  (Show state) =>
  state ->
  Either RenderError String
```

**Nonconforming fragment (do not copy):**

```haskell
render
 :: (Show state)
 => state
 -> Either RenderError
 String
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-format-006"></a>

### HSTYLE-FORMAT-006: Calls and long expressions

**Class:** local engineering control. **Obligation:** MUST. **Scope:** application layout.

Keep the function with its first simple arguments when it fits; break a long call into aligned arguments without
padding to the length of the callee. Name intermediate domain results instead of nesting opaque expressions.

**Rationale:** A rename should not move an entire argument column.

**Conforming contextual fragment:**

```haskell
result =
  buildCertificate
    validatedProgram
    initialState
    checkedTransitions
```

**Nonconforming fragment (do not copy):**

```haskell
result = buildCertificate validatedProgram
                          initialState
                          checkedTransitions
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-format-007"></a>

### HSTYLE-FORMAT-007: Lists, tuples and records

**Class:** local engineering control. **Obligation:** MUST. **Scope:** aggregate layout.

Use compact aggregates when short. For multiline ordinary lists and records, use the current leading-comma formatter
style. Use records for tuples whose positions carry several distinct domain meanings.

**Rationale:** Field names help reviewers detect swapped quantities.

**Conforming contextual fragment:**

```haskell
requests =
  [ zeroRequest
  , exactCapacityRequest
  , overflowRequest
  ]
```

**Nonconforming fragment (do not copy):**

```haskell
requests = [zeroRequest,
            exactCapacityRequest,
            overflowRequest]
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-format-008"></a>

### HSTYLE-FORMAT-008: Export and import layout

**Class:** local engineering control. **Obligation:** MUST. **Scope:** module interfaces.

Use the formatter's diff-friendly trailing-comma layout for multiline exports and imports. Group types before
operations and add Haddock headings when the interface has distinct responsibilities. Do not copy the ordinary-list
comma rule into module export syntax.

**Rationale:** The pinned formatter has distinct policies for aggregates and interfaces.

**Conforming contextual fragment:**

```haskell
module Reservation (
  Cursor,
  ReserveError (..),
  reserve,
) where
```

**Nonconforming fragment (do not copy):**

```haskell
module Reservation (reserve,Cursor,ReserveError(..)) where
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-format-009"></a>

### HSTYLE-FORMAT-009: Comments and strings

**Class:** local engineering control. **Obligation:** MUST. **Scope:** explanatory text.

Write -- followed by a space for prose. Place a reason comment before the code it explains and keep Haddock adjacent
to its declaration. Wrap prose manually. Break a long diagnostic by explicit string composition while preserving its
exact emitted bytes; do not add newline characters just for source layout.
For every formal-property declaration, also apply the mathematical statement and placement requirements in
[HSTYLE-MATH-001](#hstyle-math-001).

**Rationale:** Comments and output text have different whitespace contracts.

**Conforming contextual fragment:**

```haskell
-- Keep the original state on rejection.
message =
  "unsupported operation: "
    ++ operationName
```

**Nonconforming fragment (do not copy):**

```haskell
--Do the thing
message = "unsupported operation:\n" ++ operationName
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-format-010"></a>

### HSTYLE-FORMAT-010: Source text and Unicode

**Class:** local engineering control. **Obligation:** MUST. **Scope:** owned Haskell source.

Use UTF-8 files, ASCII identifiers and ASCII syntax in new engine code. Keep non-ASCII test data as explicit literals
with an encoding contract. Reject hidden bidirectional controls and confusable names.

**Rationale:** The formatter uses `unicode: never`; protocol bytes still need deliberate encoding.

**Conforming contextual fragment:**

```haskell
requestedBytes :: Integer
requestedBytes = 8
```

**Nonconforming fragment (do not copy):**

<!-- cspell:disable -->

```haskell
requestedΒytes :: Integer
requestedΒytes = 8
-- The apparent B above is Greek beta, not ASCII B.
```

<!-- cspell:enable -->

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-syntax-001"></a>

### HSTYLE-SYNTAX-001: Function equations and guards

**Class:** local engineering control. **Obligation:** MUST. **Scope:** pure functions.

Group equations in constructor order and use named patterns. Prefer guards for ordered domain predicates. Place
otherwise last and make rejection branches visible before constructing a result.

**Rationale:** Exhaustive cases and ordered predicates expose the admitted domain.

**Conforming contextual fragment:**

```haskell
validate n
  | n < 0 = Left NegativeRequest
  | n > limit = Left CapacityExceeded
  | otherwise = Right n
```

**Nonconforming fragment (do not copy):**

```haskell
validate n = if n < 0 then Left NegativeRequest else if n > limit then Left CapacityExceeded else Right n
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-syntax-002"></a>

### HSTYLE-SYNTAX-002: Case expressions

**Class:** local engineering control. **Obligation:** MUST. **Scope:** sum elimination.

Use one alternative per line when branches are nontrivial. Handle each error constructor when its behavior differs.
Avoid a catch-all branch that silently accepts a future protocol constructor.

**Rationale:** Adding a constructor should force a decision at the boundary.

**Conforming contextual fragment:**

```haskell
case outcome of
  Complete certificate -> publish certificate
  Incomplete reason -> reject reason
```

**Nonconforming fragment (do not copy):**

```haskell
case outcome of
  Complete certificate -> publish certificate
  _ -> pure ()
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-syntax-003"></a>

### HSTYLE-SYNTAX-003: If expressions

**Class:** local engineering control. **Obligation:** MUST. **Scope:** binary choices.

Use if for a genuine binary expression. Keep a short expression inline; wrap longer branches using the formatter's
indented then/else layout. Replace nested decision ladders with guards or a named classification.

**Rationale:** Both alternatives must remain visible at the same structural level.

**Conforming contextual fragment:**

```haskell
result =
  if requested <= remaining
    then acceptReservation requested
    else rejectReservation requested
```

**Nonconforming fragment (do not copy):**

```haskell
result = if requested <= remaining then acceptReservation requested
  else rejectReservation requested
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-syntax-004"></a>

### HSTYLE-SYNTAX-004: Let and where bindings

**Class:** local engineering control. **Obligation:** MUST. **Scope:** local definitions.

Use let for a value needed at a specific expression or do step; use where for helpers shared by equations or guards.
Keep the helper close to its only owner. Give nontrivial helpers signatures; account for fresh type variables unless
ScopedTypeVariables has been approved.

**Rationale:** A local signature under Haskell2010 can quantify different variables from the outer signature.

**Conforming contextual fragment:**

```haskell
remaining :: Integer -> Integer -> Integer
remaining capacity used = capacity - used
```

**Nonconforming fragment (do not copy):**

```haskell
outer :: a -> a
outer value = inner
 where
  inner :: a
  inner = value
-- This local a is not scoped to the outer a in Haskell2010.
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-syntax-005"></a>

### HSTYLE-SYNTAX-005: Do notation and discarded results

**Class:** local engineering control. **Obligation:** MUST. **Scope:** effectful code.

Use one meaningful action per line. Bind values with <- and pure locals with let. Handle fallible results before
publishing success; discard a result only with an explicit reason or a suitable underscore API.

**Rationale:** An IO result can contain a domain failure that successful execution does not handle.

**Conforming contextual fragment:**

```haskell
result <- runChecker input
case result of
  Left failure -> reportFailure failure
  Right proof -> publish proof
```

**Nonconforming fragment (do not copy):**

```haskell
_ <- runChecker input
publishSuccess
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-syntax-006"></a>

### HSTYLE-SYNTAX-006: Lambdas and point-free expressions

**Class:** local engineering control. **Obligation:** MUST. **Scope:** function values.

Use a short lambda for a local transformation and name a function when branching or resource behavior needs
explanation. Use composition only when the input/output relation remains easy to read.

**Rationale:** A dense composition can hide which value is checked and which value is emitted.

**Conforming contextual fragment:**

```haskell
map (\request -> request + headerBytes) requests
```

**Nonconforming fragment (do not copy):**

```haskell
map ((+) headerBytes . id . id) requests
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-syntax-007"></a>

### HSTYLE-SYNTAX-007: Record construction and updates

**Class:** local engineering control. **Obligation:** MUST. **Scope:** state values.

Initialize every field explicitly, unless an approved extension and reviewed convention says otherwise. Use record
updates only for constructors that contain the updated fields. Validate before publishing a new state.

**Rationale:** A well-typed record update can still fail for the wrong constructor.

**Conforming contextual fragment:**

```haskell
data Cursor = Cursor { cursorUsed :: !Integer, cursorCapacity :: !Integer }
next = current { cursorUsed = newUsed }
```

**Nonconforming fragment (do not copy):**

```haskell
data State = Open { used :: Integer } | Closed
next = Closed { used = 1 }
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-syntax-008"></a>

### HSTYLE-SYNTAX-008: Deriving and instance declarations

**Class:** local engineering control. **Obligation:** MUST. **Scope:** classes.

Use ordinary deriving for the admitted Haskell2010 classes. If multiple deriving mechanisms are needed, approve
DerivingStrategies and state stock/newtype/anyclass explicitly. Do not combine extensions by copying an upstream style
example without checking the generated instance.

**Rationale:** Different strategies can generate different methods and runtime behavior.

**Conforming contextual fragment:**

```haskell
data ReserveError = NegativeRequest | CapacityExceeded
  deriving (Eq, Show)
```

**Nonconforming fragment (do not copy):**

```haskell
{-# LANGUAGE DeriveAnyClass, GeneralizedNewtypeDeriving #-}
newtype Count = Count Integer deriving (Num)
-- No reviewed strategy or generated-method inspection.
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-syntax-009"></a>

### HSTYLE-SYNTAX-009: Language and compiler pragmas

**Class:** local engineering control. **Obligation:** MUST. **Scope:** extensions and tuning.

Put LANGUAGE pragmas in the prologue, one extension per pragma. Keep OPTIONS_GHC only for reviewed local needs such as
the conditional refinement plugin. Do not disable warnings or introduce rewrite RULES without semantic evidence and a
scoped decision.

**Rationale:** A pragma can change accepted programs and optimized behavior.

**Conforming contextual fragment:**

```haskell
{-# LANGUAGE CPP #-}
#ifdef LMA_LIQUID
{-# OPTIONS_GHC -fplugin=LiquidHaskell #-}
#endif
```

**Nonconforming fragment (do not copy):**

```haskell
{-# OPTIONS_GHC -w #-}
-- Suppresses the acceptance diagnostics.
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-syntax-010"></a>

### HSTYLE-SYNTAX-010: Comprehensions and traversal

**Class:** local engineering control. **Obligation:** MUST. **Scope:** collections.

Use comprehensions for bounded filtering/mapping and explicit folds for state accumulation. Do not rely on filtering
to hide malformed input or generate an unbounded Cartesian product without a budget.

**Rationale:** A concise expression can change coverage or retain excessive intermediate state.

**Conforming contextual fragment:**

```haskell
validRequests = [request | request <- boundedRequests, request >= 0]
```

**Nonconforming fragment (do not copy):**

```haskell
allTraces = [x : xs | x <- [0 ..], xs <- allTraces]
```

**Verification and limits:** Review the declaration and its uses; run the pinned formatter and compiler on complete
source. The tools do not establish the domain meaning or the whole local convention.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-perf-001"></a>

### HSTYLE-PERF-001: Demand and residency measurements

**Class:** local engineering control. **Obligation:** MUST. **Scope:** performance changes.

Benchmark a demanded result, record input size and compiler/RTS options, and measure allocation and maximum residency.
Test strict folds with the actual accumulator structure; weak head normal form does not force fields of a tuple.

**Rationale:** Timing construction of an unevaluated thunk does not time the intended computation.

**Conforming contextual fragment:**

```haskell
-- Demand the result before ending the timed region.
value <- evaluate (force (explore inputs))
```

**Nonconforming fragment (do not copy):**

```haskell
-- Timing only a lazy binding misses the exploration work.
let value = explore inputs
```

**Verification and limits:** Review `NFData` instances and dependency pins, and use repeated representative runs.
Runtime measurements apply to the measured profile, not a proof of asymptotic or real-time bounds.

**Exception:** Use the rule-level review record defined in [governance](#governance).

---

<a id="hstyle-concurrency-001"></a>

### HSTYLE-CONCURRENCY-001: Shared state and worker lifetime

**Class:** local engineering control. **Obligation:** MUST. **Scope:** parallel adapters.

Keep the pure model immutable. Give each worker an owner that observes completion, failure and cancellation. Use a
synchronization abstraction for shared mutation and define what publication means; a thread launch alone is not
completion evidence.

**Rationale:** A detached worker can outlive the artifact or resource it writes.

**Conforming contextual fragment:**

```haskell
-- The adapter waits for and checks the owned worker.
result <- wait worker
handleResult result
```

**Nonconforming fragment (do not copy):**

```haskell
_ <- forkIO (writeCertificate path)
publishSuccess
```

**Verification and limits:** Review ownership and synchronization; inject worker failure and cancellation. The current
engine profile does not establish a general concurrent adapter protocol.

**Exception:** Use the rule-level review record defined in [governance](#governance).

<!-- EOF -->


<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Common Haskell Pitfalls

Use this catalogue to design regressions and review a concrete failure path. Each scenario links a prevention control,
a semantic source and an expected test observation. It adds no competing normative rules; the [code
standard](haskell-code-standard.md#governance) defines obligations and exceptions.

<details>
<summary><strong>On this page</strong></summary>

- [Evidence and CWE interpretation](#evidence-model)
- [HPIT-001: Partial selection on an empty value](#hpit-001)
- [HPIT-002: Partial record selectors and updates](#hpit-002)
- [HPIT-003: Treating purity as termination](#hpit-003)
- [HPIT-004: Lazy exceptions outside the handler](#hpit-004)
- [HPIT-005: Confusing weak head normal form with full evaluation](#hpit-005)
- [HPIT-006: Retaining the entire trace](#hpit-006)
- [HPIT-007: Overflow before a bound check](#hpit-007)
- [HPIT-008: Unchecked narrowing or signedness conversion](#hpit-008)
- [HPIT-009: Division and remainder disagreement](#hpit-009)
- [HPIT-010: NaN as an ordered state key](#hpit-010)
- [HPIT-011: Unlawful Eq and Ord instances](#hpit-011)
- [HPIT-012: A synonym mistaken for a validated quantity](#hpit-012)
- [HPIT-013: Parsing only a prefix](#hpit-013)
- [HPIT-014: Unknown operations becoming no-ops](#hpit-014)
- [HPIT-015: Ignoring a domain error in IO](#hpit-015)
- [HPIT-016: Lazy input outliving its handle](#hpit-016)
- [HPIT-017: Cancellation swallowed as success](#hpit-017)
- [HPIT-018: Resource acquisition without exception-safe release](#hpit-018)
- [HPIT-019: Finite search reported as universal](#hpit-019)
- [HPIT-020: Shrinking an illegal state-machine trace](#hpit-020)
- [HPIT-021: Treating safe FFI as C memory safety](#hpit-021)
- [HPIT-022: Unsafe call reentering Haskell](#hpit-022)
- [HPIT-023: Borrowed pointer retained by C](#hpit-023)
- [HPIT-024: Callback freed while still registered](#hpit-024)
- [HPIT-025: Foreign layout inferred from a Haskell type](#hpit-025)
- [HPIT-026: Unescaped proof or command generation](#hpit-026)
- [HPIT-027: Stale proof accepted after input changes](#hpit-027)
- [HPIT-028: Formatter or linter treated as proof](#hpit-028)

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

<a id="hpit-001"></a>

## HPIT-001: Partial selection on an empty value

**Failure scenario:** An empty trace reaches head, `fromJust` or an incomplete pattern and aborts analysis.

**Nonconforming fragment:**

```haskell
firstCommand commands = head commands
```

**Prevention fragment:**

```haskell
firstCommand [] = Nothing
firstCommand (command : _) = Just command
```

**Control:** [HSTYLE-PARTIAL-001](haskell-code-standard.md#hstyle-partial-001).

**Regression and expected observation:** Run empty, singleton and malformed traces; require an explicit absence/error
result.

**CWE applicability:** [CWE-703](https://cwe.mitre.org/data/definitions/703.html): conceptual exceptional-condition
handling when an admitted input triggers a partial operation. It is not a C buffer overread.

**Semantic reference:** [adopted manual or style
section](https://www.haskell.org/onlinereport/haskell2010/haskellch3.html); revisions and precedence appear in the
[source register](haskell-code-standard.md#sources).

---

<a id="hpit-002"></a>

## HPIT-002: Partial record selectors and updates

**Failure scenario:** A selector exists only for one constructor but a rejected or closed state reaches it.

**Nonconforming fragment:**

```haskell
data State = Open { used :: Integer } | Closed
readUsed state = used state
```

**Prevention fragment:**

```haskell
readUsed (Open value) = Just value
readUsed Closed = Nothing
```

**Control:** [HSTYLE-SYNTAX-007](haskell-code-standard.md#hstyle-syntax-007).

**Regression and expected observation:** Exercise every constructor through each exported accessor and updater.

**CWE applicability:** [CWE-703](https://cwe.mitre.org/data/definitions/703.html): conditional runtime exception
caused by a partial selector.

**Semantic reference:** [adopted manual or style
section](https://www.haskell.org/onlinereport/haskell2010/haskellch3.html); revisions and precedence appear in the
[source register](haskell-code-standard.md#sources).

---

<a id="hpit-003"></a>

## HPIT-003: Treating purity as termination

**Failure scenario:** A pure recursive computation never produces a result; its type does not imply totality.

**Nonconforming fragment:**

```haskell
explore state = explore state
```

**Prevention fragment:**

```haskell
explore 0 state = Left BudgetExhausted
explore fuel state = stepWithBudget (fuel - 1) state
```

**Control:** [HSTYLE-TERMINATION-001](haskell-code-standard.md#hstyle-termination-001).

**Regression and expected observation:** Use a cyclic machine and verify budget exhaustion is incomplete, with no
accepted certificate.

**CWE applicability:** [CWE-835](https://cwe.mitre.org/data/definitions/835.html): nontermination when the recurrence
has no reachable exit.

**Semantic reference:** [adopted manual or style
section](https://www.haskell.org/onlinereport/haskell2010/haskellch3.html); revisions and precedence appear in the
[source register](haskell-code-standard.md#sources).

---

<a id="hpit-004"></a>

## HPIT-004: Lazy exceptions outside the handler

**Failure scenario:** The handler protects construction of a thunk but the exception occurs when another caller
demands it.

**Nonconforming fragment:**

```haskell
result <- try (pure (parse input))
-- A Right may still contain an exceptional thunk.
```

**Prevention fragment:**

```haskell
result <- try (evaluate (force (parse input)))
-- Select the intended exception type and review NFData.
```

**Control:** [HSTYLE-EVAL-001](haskell-code-standard.md#hstyle-eval-001).

**Regression and expected observation:** Place a failing value in a nested field; demand it inside and outside the
adapter boundary.

**CWE applicability:** [CWE-703](https://cwe.mitre.org/data/definitions/703.html): conceptual handling failure when a
deferred exception escapes the intended boundary.

**Semantic reference:** [adopted manual or style
section](https://downloads.haskell.org/ghc/9.4.7/docs/libraries/base-4.17.2.0/Control-Exception.html); revisions and
precedence appear in the [source register](haskell-code-standard.md#sources).

---

<a id="hpit-005"></a>

## HPIT-005: Confusing weak head normal form with full evaluation

**Failure scenario:** A strict fold or seq forces a tuple constructor but retains deferred work in its fields.

**Nonconforming fragment:**

```haskell
accumulate = foldl' (\(total, count) x -> (total + x, count + 1)) (0, 0)
```

**Prevention fragment:**

```haskell
-- Force the needed fields or use a reviewed strict accumulator type.
data Accumulator = Accumulator !Integer !Integer
```

**Control:** [HSTYLE-EVAL-001](haskell-code-standard.md#hstyle-eval-001).

**Regression and expected observation:** Measure residency for growing traces and demand both fields; compare with the
declared budget.

**CWE applicability:** [CWE-400](https://cwe.mitre.org/data/definitions/400.html): conceptual resource consumption if
deferred work grows without control; not an automatic vulnerability.

**Semantic reference:** [adopted manual or style
section](https://www.haskell.org/onlinereport/haskell2010/haskellch6.html); revisions and precedence appear in the
[source register](haskell-code-standard.md#sources).

---

<a id="hpit-006"></a>

## HPIT-006: Retaining the entire trace

**Failure scenario:** A closure, diagnostic or lazy result keeps old states reachable even after the frontier
advances.

**Nonconforming fragment:**

```haskell
report = \() -> show allVisitedStates
```

**Prevention fragment:**

```haskell
report = summarizeBounded sampleLimit visitedCount finalState
```

**Control:** [HSTYLE-PERF-001](haskell-code-standard.md#hstyle-perf-001).

**Regression and expected observation:** Increase trace size and measure retained heap after a completed batch.

**CWE applicability:** [CWE-400](https://cwe.mitre.org/data/definitions/400.html): conceptual uncontrolled memory
retention when the workload can exceed available resources.

**Semantic reference:** [adopted manual or style
section](https://www.haskell.org/onlinereport/haskell2010/haskellch6.html); revisions and precedence appear in the
[source register](haskell-code-standard.md#sources).

---

<a id="hpit-007"></a>

## HPIT-007: Overflow before a bound check

**Failure scenario:** A machine-width sum wraps before the comparison used to validate capacity.

**Nonconforming fragment:**

```haskell
fits used requested capacity = used + requested <= capacity -- Int or Word
```

**Prevention fragment:**

```haskell
fits used requested capacity =
  used >= 0 && requested >= 0 && used <= capacity && requested <= capacity - used
```

**Control:** [HSTYLE-NUM-001](haskell-code-standard.md#hstyle-num-001).

**Regression and expected observation:** Test the target maximum, its successor in `Integer`, and negative requests
before conversion.

**CWE applicability:** [CWE-190](https://cwe.mitre.org/data/definitions/190.html): overflow or wraparound in the
selected bounded runtime type.

**Semantic reference:** [adopted manual or style
section](https://www.haskell.org/onlinereport/haskell2010/haskellch6.html); revisions and precedence appear in the
[source register](haskell-code-standard.md#sources).

---

<a id="hpit-008"></a>

## HPIT-008: Unchecked narrowing or signedness conversion

**Failure scenario:** `fromIntegral` converts an out-of-range `Integer` into a different machine value.

**Nonconforming fragment:**

```haskell
cell = fromIntegral untrustedInteger :: Int
```

**Prevention fragment:**

```haskell
cell <- checkedCellIndex untrustedInteger
-- Check both lower and upper bounds before conversion.
```

**Control:** [HSTYLE-NUM-001](haskell-code-standard.md#hstyle-num-001).

**Regression and expected observation:** Try -1, the largest allowed cell and one above it; require rejection before
indexing.

**CWE applicability:** [CWE-704](https://cwe.mitre.org/data/definitions/704.html): incorrect conversion when the
destination value no longer represents the admitted source.

**Semantic reference:** [adopted manual or style
section](https://www.haskell.org/onlinereport/haskell2010/haskellch6.html); revisions and precedence appear in the
[source register](haskell-code-standard.md#sources).

---

<a id="hpit-009"></a>

## HPIT-009: Division and remainder disagreement

**Failure scenario:** The engine uses div/mod while the concrete signed operation follows a different quotient
convention, or allows zero.

**Nonconforming fragment:**

```haskell
quotient = numerator `div` denominator
```

**Prevention fragment:**

```haskell
quotient <- checkedQuotient numerator denominator
-- Reject zero and define signed rounding and representability.
```

**Control:** [HSTYLE-NUM-001](haskell-code-standard.md#hstyle-num-001).

**Regression and expected observation:** Test zero divisors, mixed signs and signed minimum divided by -1 for the
target profile.

**CWE applicability:** [CWE-369](https://cwe.mitre.org/data/definitions/369.html): a zero divisor at execution;
[CWE-682](https://cwe.mitre.org/data/definitions/682.html): conceptual incorrect calculation when quotient conventions
differ.

**Semantic reference:** [adopted manual or style
section](https://www.haskell.org/onlinereport/haskell2010/haskellch6.html); revisions and precedence appear in the
[source register](haskell-code-standard.md#sources).

---

<a id="hpit-010"></a>

## HPIT-010: NaN as an ordered state key

**Failure scenario:** A floating-point measurement enters an Eq/Ord-based state key and violates intended
equality/order laws.

**Nonconforming fragment:**

```haskell
visited = Set.insert (0 / 0 :: Double) visited
```

**Prevention fragment:**

```haskell
-- Use exact domain values for state identity.
newtype StateKey = StateKey Integer deriving (Eq, Ord)
```

**Control:** [HSTYLE-CLASS-001](haskell-code-standard.md#hstyle-class-001).

**Regression and expected observation:** Test repeated and distinct keys, including nonfinite input if floating-point
input exists.

**CWE applicability:** [CWE-697](https://cwe.mitre.org/data/definitions/697.html): conditional incorrect comparison
when the algorithm assumes a total ordering.

**Semantic reference:** [adopted manual or style
section](https://www.haskell.org/onlinereport/haskell2010/haskellch6.html); revisions and precedence appear in the
[source register](haskell-code-standard.md#sources).

---

<a id="hpit-011"></a>

## HPIT-011: Unlawful Eq and Ord instances

**Failure scenario:** A map merges states that Eq distinguishes, losing reachable transitions.

**Nonconforming fragment:**

```haskell
-- Eq includes epoch; Ord compares address only.
```

**Prevention fragment:**

```haskell
-- Derive both from the same complete identity representation.
data Key = Key Integer Integer deriving (Eq, Ord)
```

**Control:** [HSTYLE-CLASS-001](haskell-code-standard.md#hstyle-class-001).

**Regression and expected observation:** Check compare x y == EQ if and only if x == y over the admitted state-key
domain.

**CWE applicability:** [CWE-697](https://cwe.mitre.org/data/definitions/697.html): conditional comparison error that
removes required states.

**Semantic reference:** [adopted manual or style
section](https://www.haskell.org/onlinereport/haskell2010/haskellch6.html); revisions and precedence appear in the
[source register](haskell-code-standard.md#sources).

---

<a id="hpit-012"></a>

## HPIT-012: A synonym mistaken for a validated quantity

**Failure scenario:** Two `Integer` aliases accept swapped byte counts and indices; a name does not validate a range.

**Nonconforming fragment:**

```haskell
type Bytes = Integer
type CellIndex = Integer
```

**Prevention fragment:**

```haskell
newtype Bytes = Bytes Integer
newtype CellIndex = CellIndex Integer
-- Export checked constructors for their respective domains.
```

**Control:** [HSTYLE-DATA-001](haskell-code-standard.md#hstyle-data-001).

**Regression and expected observation:** Compile a swapped-argument negative case and test constructor boundary
rejection.

**CWE applicability:** [CWE-704](https://cwe.mitre.org/data/definitions/704.html): only if a concrete conversion
misrepresents a value; weak type modeling alone is not this CWE.

**Semantic reference:** [adopted manual or style
section](https://www.haskell.org/onlinereport/haskell2010/haskellch6.html); revisions and precedence appear in the
[source register](haskell-code-standard.md#sources).

---

<a id="hpit-013"></a>

## HPIT-013: Parsing only a prefix

**Failure scenario:** A parser accepts a valid prefix and ignores trailing commands or malformed data.

**Nonconforming fragment:**

```haskell
parseNumber input = fst (head (reads input))
```

**Prevention fragment:**

```haskell
parseNumber input = case reads input of
  [(value, "")] -> Right value
  _ -> Left InvalidNumber
```

**Control:** [HSTYLE-PROTOCOL-001](haskell-code-standard.md#hstyle-protocol-001).

**Regression and expected observation:** Append junk, a second document, negative fields and oversized numbers;
require complete-parse rejection.

**CWE applicability:** [CWE-20](https://cwe.mitre.org/data/definitions/20.html): conceptual input-validation gap when
unconsumed data alters the intended message.

**Semantic reference:** [adopted manual or style
section](https://www.haskell.org/onlinereport/haskell2010/haskellch3.html); revisions and precedence appear in the
[source register](haskell-code-standard.md#sources).

---

<a id="hpit-014"></a>

## HPIT-014: Unknown operations becoming no-ops

**Failure scenario:** The importer drops an unsupported C construct and proves a different program.

**Nonconforming fragment:**

```haskell
importNode _ = Right NoOp
```

**Prevention fragment:**

```haskell
importNode node = Left (UnsupportedNode (location node))
```

**Control:** [HSTYLE-PROTOCOL-001](haskell-code-standard.md#hstyle-protocol-001).

**Regression and expected observation:** Insert an unknown operation on a reachable branch; the importer must fail
before proof generation.

**CWE applicability:** [CWE-20](https://cwe.mitre.org/data/definitions/20.html): conceptual validation gap at the
importer; no source-preservation claim follows from the remaining model.

**Semantic reference:** [adopted manual or style
section](https://www.haskell.org/onlinereport/haskell2010/haskellch3.html); revisions and precedence appear in the
[source register](haskell-code-standard.md#sources).

---

<a id="hpit-015"></a>

## HPIT-015: Ignoring a domain error in IO

**Failure scenario:** Executing an action succeeds but its Either result reports failure, which the caller discards.

**Nonconforming fragment:**

```haskell
_ <- verify input
publishSuccess
```

**Prevention fragment:**

```haskell
result <- verify input
case result of
  Left failure -> reportFailure failure
  Right proof -> publish proof
```

**Control:** [HSTYLE-ERROR-001](haskell-code-standard.md#hstyle-error-001).

**Regression and expected observation:** Make each stage return Left and check that no successful receipt is
published.

**CWE applicability:** [CWE-252](https://cwe.mitre.org/data/definitions/252.html): an unchecked returned result when
its failure status is required for acceptance.

**Semantic reference:** [adopted manual or style
section](https://www.haskell.org/onlinereport/haskell2010/haskellch3.html); revisions and precedence appear in the
[source register](haskell-code-standard.md#sources).

---

<a id="hpit-016"></a>

## HPIT-016: Lazy input outliving its handle

**Failure scenario:** A file-backed lazy value escapes a `withFile` scope, so later consumption uses a closed handle.

**Nonconforming fragment:**

```haskell
withFile path ReadMode hGetContents
```

**Prevention fragment:**

```haskell
withFile path ReadMode $ \handle -> do
  content <- hGetContents handle
  evaluate (force content)
```

**Control:** [HSTYLE-EVAL-001](haskell-code-standard.md#hstyle-eval-001).

**Regression and expected observation:** Demand the returned value after the scope; ensure all required content was
consumed while the handle lived.

**CWE applicability:** [CWE-703](https://cwe.mitre.org/data/definitions/703.html): conditional deferred I/O failure;
do not equate a closed Haskell handle with a raw C use-after-free.

**Semantic reference:** [adopted manual or style
section](https://downloads.haskell.org/ghc/9.4.7/docs/libraries/base-4.17.2.0/Control-Exception.html); revisions and
precedence appear in the [source register](haskell-code-standard.md#sources).

---

<a id="hpit-017"></a>

## HPIT-017: Cancellation swallowed as success

**Failure scenario:** A broad exception handler converts asynchronous termination into a successful empty result.

**Nonconforming fragment:**

```haskell
recover (_ :: SomeException) = pure EmptySuccess
```

**Prevention fragment:**

```haskell
-- Handle the intended I/O exception type; let cancellation propagate.
recoverIO failure = pure (Left (InputFailure failure))
```

**Control:** [HSTYLE-RESOURCE-001](haskell-code-standard.md#hstyle-resource-001).

**Regression and expected observation:** Cancel after acquisition, during parsing and before publication; require
cleanup and no success receipt.

**CWE applicability:** [CWE-703](https://cwe.mitre.org/data/definitions/703.html): conceptual exception-handling
defect at the adapter boundary.

**Semantic reference:** [adopted manual or style
section](https://downloads.haskell.org/ghc/9.4.7/docs/libraries/base-4.17.2.0/Control-Exception.html); revisions and
precedence appear in the [source register](haskell-code-standard.md#sources).

---

<a id="hpit-018"></a>

## HPIT-018: Resource acquisition without exception-safe release

**Failure scenario:** An exception between open and close leaves a handle or process alive.

**Nonconforming fragment:**

```haskell
handle <- openFile path ReadMode
result <- consume handle
hClose handle
```

**Prevention fragment:**

```haskell
withFile path ReadMode consume
```

**Control:** [HSTYLE-RESOURCE-001](haskell-code-standard.md#hstyle-resource-001).

**Regression and expected observation:** Inject a consumption failure and count open handles or child processes after
cleanup.

**CWE applicability:** [CWE-772](https://cwe.mitre.org/data/definitions/772.html): a resource remains allocated after
its effective lifetime.

**Semantic reference:** [adopted manual or style
section](https://downloads.haskell.org/ghc/9.4.7/docs/libraries/base-4.17.2.0/Control-Exception.html); revisions and
precedence appear in the [source register](haskell-code-standard.md#sources).

---

<a id="hpit-019"></a>

## HPIT-019: Finite search reported as universal

**Failure scenario:** The engine checks a bounded or depth-limited sample but reports unqualified allocator safety.

**Nonconforming fragment:**

```haskell
-- Search stopped at depth 10.
result = VerifiedAllStates
```

**Prevention fragment:**

```haskell
result = Incomplete (DepthLimit 10 remainingFrontier)
```

**Control:** [HSTYLE-TERMINATION-001](haskell-code-standard.md#hstyle-termination-001).

**Regression and expected observation:** Force a counterexample just outside the bound and verify that the report
retains its scope.

**CWE applicability:** No direct CWE mapping. The proof, style or evidence defect requires review; classify a concrete
downstream
vulnerability separately.

**Semantic reference:** [adopted manual or style
section](https://www.haskell.org/onlinereport/haskell2010/haskellch3.html); revisions and precedence appear in the
[source register](haskell-code-standard.md#sources).

---

<a id="hpit-020"></a>

## HPIT-020: Shrinking an illegal state-machine trace

**Failure scenario:** A shrinker deletes allocation but preserves a later use, producing a different failure cause.

**Nonconforming fragment:**

```haskell
-- Shrink [allocate h, write h, free h] to [write h].
```

**Prevention fragment:**

```haskell
-- Preserve producer/consumer dependencies, or rebuild valid handles after shrinking.
```

**Control:** [HSTYLE-ERROR-001](haskell-code-standard.md#hstyle-error-001).

**Regression and expected observation:** Shrink a failing history and replay it with precondition checks; keep
malformed-input tests separate.

**CWE applicability:** No direct CWE mapping. The proof, style or evidence defect requires review; classify a concrete
downstream
vulnerability separately.

**Semantic reference:** [adopted manual or style
section](https://www.haskell.org/onlinereport/haskell2010/haskellch3.html); revisions and precedence appear in the
[source register](haskell-code-standard.md#sources).

---

<a id="hpit-021"></a>

## HPIT-021: Treating safe FFI as C memory safety

**Failure scenario:** A safe import has the required runtime behavior but passes an invalid pointer to C.

**Nonconforming fragment:**

```haskell
foreign import ccall safe "read_value" c_readValue :: Ptr CInt -> IO CInt
-- safe does not validate the pointer.
```

**Prevention fragment:**

```haskell
-- Validate the ownership/length contract and borrow within its live scope.
withForeignPtr owner c_readValue
```

**Control:** [HSTYLE-FFI-001](haskell-code-standard.md#hstyle-ffi-001).

**Regression and expected observation:** Exercise null, alignment, length and lifetime contracts in the owning adapter
and C harness.

**CWE applicability:** [CWE-476](https://cwe.mitre.org/data/definitions/476.html): only if a null pointer is
dereferenced; [CWE-125](https://cwe.mitre.org/data/definitions/125.html): only if the C call reads outside its object.

**Semantic reference:** [adopted manual or style
section](https://downloads.haskell.org/ghc/9.4.7/docs/users_guide/exts/ffi.html); revisions and precedence appear in
the [source register](haskell-code-standard.md#sources).

---

<a id="hpit-022"></a>

## HPIT-022: Unsafe call reentering Haskell

**Failure scenario:** A call declared unsafe invokes a Haskell callback or blocks in a way the runtime profile does
not admit.

**Nonconforming fragment:**

```haskell
foreign import ccall unsafe "run_callback" c_runCallback :: IO ()
```

**Prevention fragment:**

```haskell
foreign import ccall safe "run_callback" c_runCallback :: IO ()
```

**Control:** [HSTYLE-FFI-002](haskell-code-standard.md#hstyle-ffi-002).

**Regression and expected observation:** Run reentry, concurrent collection and shutdown scenarios under the adopted
threaded runtime.

**CWE applicability:** [CWE-703](https://cwe.mitre.org/data/definitions/703.html): conceptual runtime-boundary misuse;
classify a concrete resulting defect separately.

**Semantic reference:** [adopted manual or style
section](https://downloads.haskell.org/ghc/9.4.7/docs/users_guide/exts/ffi.html); revisions and precedence appear in
the [source register](haskell-code-standard.md#sources).

---

<a id="hpit-023"></a>

## HPIT-023: Borrowed pointer retained by C

**Failure scenario:** C stores a pointer beyond the managed allocation lifetime or a temporary borrowing scope.

**Nonconforming fragment:**

```haskell
withForeignPtr owner c_storePointer
-- C retains the raw address after the scope.
```

**Prevention fragment:**

```haskell
-- Transfer an owned allocation, or keep a root until C unregisters and drains use.
withForeignPtr owner c_useSynchronously
```

**Control:** [HSTYLE-FFI-001](haskell-code-standard.md#hstyle-ffi-001).

**Regression and expected observation:** Force collection after registration and race release with C use; verify the
documented ownership protocol.

**CWE applicability:** [CWE-416](https://cwe.mitre.org/data/definitions/416.html): use-after-free only when C accesses
the allocation after release.

**Semantic reference:** [adopted manual or style
section](https://downloads.haskell.org/ghc/9.4.7/docs/users_guide/exts/ffi.html); revisions and precedence appear in
the [source register](haskell-code-standard.md#sources).

---

<a id="hpit-024"></a>

## HPIT-024: Callback freed while still registered

**Failure scenario:** The wrapper function pointer or stable root is released while C can invoke it.

**Nonconforming fragment:**

```haskell
freeHaskellFunPtr callback
c_unregister callback
```

**Prevention fragment:**

```haskell
c_unregister callback
waitForCallbacks
freeHaskellFunPtr callback
```

**Control:** [HSTYLE-FFI-003](haskell-code-standard.md#hstyle-ffi-003).

**Regression and expected observation:** Race callback entry with shutdown and repeat registration; verify all
in-flight users finish before release.

**CWE applicability:** [CWE-416](https://cwe.mitre.org/data/definitions/416.html): conditional use of a freed callback
trampoline; [CWE-362](https://cwe.mitre.org/data/definitions/362.html): conditional unsynchronized teardown.

**Semantic reference:** [adopted manual or style
section](https://downloads.haskell.org/ghc/9.4.7/docs/users_guide/exts/ffi.html); revisions and precedence appear in
the [source register](haskell-code-standard.md#sources).

---

<a id="hpit-025"></a>

## HPIT-025: Foreign layout inferred from a Haskell type

**Failure scenario:** A `Storable` instance assumes `Int` width, alignment or padding matches the C structure.

**Nonconforming fragment:**

```haskell
-- Hard-code sizeof(size_t) = sizeof(Int) for every target.
```

**Prevention fragment:**

```haskell
-- Use the matching Foreign.C.Types representation and validate C layout per target.
```

**Control:** [HSTYLE-FFI-001](haskell-code-standard.md#hstyle-ffi-001).

**Regression and expected observation:** Compare C size, alignment and offsets with the binding, then test boundary
reads/writes.

**CWE applicability:** [CWE-787](https://cwe.mitre.org/data/definitions/787.html): only if the wrong layout causes an
out-of-bounds write; [CWE-704](https://cwe.mitre.org/data/definitions/704.html): conditional representation conversion
error.

**Semantic reference:** [adopted manual or style
section](https://downloads.haskell.org/ghc/9.4.7/docs/users_guide/exts/ffi.html); revisions and precedence appear in
the [source register](haskell-code-standard.md#sources).

---

<a id="hpit-026"></a>

## HPIT-026: Unescaped proof or command generation

**Failure scenario:** External text is concatenated into Lean source or a shell command with executable meaning.

**Nonconforming fragment:**

```haskell
source = "theorem " ++ externalName ++ " : True := by trivial"
```

**Prevention fragment:**

```haskell
name <- validateLeanIdentifier externalName
source <- emitTheoremFromTypedSyntax name statement proof
```

**Control:** [HSTYLE-PROTOCOL-001](haskell-code-standard.md#hstyle-protocol-001).

**Regression and expected observation:** Try delimiters, newlines, quotes and unexpected commands; require rejection
or literal encoding.

**CWE applicability:** [CWE-95](https://cwe.mitre.org/data/definitions/95.html): only when untrusted generated input
becomes executable code; [CWE-78](https://cwe.mitre.org/data/definitions/78.html): only for shell-command
interpretation.

**Semantic reference:** [adopted manual or style
section](https://www.haskell.org/onlinereport/haskell2010/haskellch3.html); revisions and precedence appear in the
[source register](haskell-code-standard.md#sources).

---

<a id="hpit-027"></a>

## HPIT-027: Stale proof accepted after input changes

**Failure scenario:** A prior successful artifact is accepted for a different source, model or tool profile.

**Nonconforming fragment:**

```haskell
-- Existence of certificate.json is treated as success.
```

**Prevention fragment:**

```haskell
-- Validate source, model, schema, profile and expected theorem identities before replay.
```

**Control:** [HSTYLE-PROTOCOL-001](haskell-code-standard.md#hstyle-protocol-001).

**Regression and expected observation:** Alter one input digest at a time and require invalidation of the prior
receipt.

**CWE applicability:** [CWE-345](https://cwe.mitre.org/data/definitions/345.html): conceptual authenticity/integrity
gap when evidence identity is not verified.

**Semantic reference:** [adopted manual or style
section](https://www.haskell.org/onlinereport/haskell2010/haskellch3.html); revisions and precedence appear in the
[source register](haskell-code-standard.md#sources).

---

<a id="hpit-028"></a>

## HPIT-028: Formatter or linter treated as proof

**Failure scenario:** A formatted program with no HLint suggestions is labeled total or memory-safe.

**Nonconforming fragment:**

```haskell
-- fourmolu and hlint pass, therefore all transitions terminate.
```

**Prevention fragment:**

```haskell
-- Retain layout/lint results and a separate termination argument or exploration bound.
```

**Control:** [HSTYLE-TERMINATION-001](haskell-code-standard.md#hstyle-termination-001).

**Regression and expected observation:** Review evidence labels and reject a claim lacking the required semantic
evidence.

**CWE applicability:** No direct CWE mapping. The proof, style or evidence defect requires review; classify a concrete
downstream
vulnerability separately.

**Semantic reference:** [adopted manual or style
section](https://www.haskell.org/onlinereport/haskell2010/haskellch3.html); revisions and precedence appear in the
[source register](haskell-code-standard.md#sources).

<!-- EOF -->


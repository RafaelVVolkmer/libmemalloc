<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Common C Pitfalls

Use this catalogue when reviewing a failure path, designing a regression test, or checking the
assumptions behind a C implementation. It covers memory, arithmetic, concurrency, hardware,
security, and performance failure scenarios.

Find a scenario through the grouped index, inspect its preconditions and examples, then follow the
prevention controls and verification design. The appendices provide complete test programs and a
source record with evidence limits.

Each scenario links to the normative prevention controls in [C Code Standard][c-code-standard] and
[C Module Architecture][c-module-architecture]. It does not add a competing set of implementation
rules. The governance and applicability model is defined [once, in the
standard][c-code-standard-governance].

Connect verification evidence to [C Compliance and Assurance](c-compliance.md).
Organize proof campaigns according to [C Formal Verification](test/c-tests-formal.md).

The [standard's example policy][c-code-standard-example-policy] applies to all embedded examples.
Failure scenarios do not grant exceptions to project requirements.

<a id="rule-index"></a>

<details>
<summary><strong>On this page</strong></summary>

- [Evidence model][evidence-model]
- [Catalogue use][catalogue-use]
- [Failure scenarios][failure-scenarios]
- [Appendix A. Complete host regression program][appendix-a-complete-host-regression-program]
- [Appendix B. Research and link record][appendix-b-research-and-link-record]
- [Appendix C. Maintained optimization regression
  test][appendix-c-maintained-optimization-regression-test]
- [Links and references][links-and-references]

<details>
<summary>Memory, pointers, and ownership</summary>

- [CPIT-001: Dangling pointer][cpit-001]
- [CPIT-002: Use-after-free][cpit-002]
- [CPIT-003: Double free][cpit-003]
- [CPIT-004: Memory leak][cpit-004]
- [CPIT-005: Ambiguous ownership][cpit-005]
- [CPIT-006: Invalid free][cpit-006]
- [CPIT-007: Mismatched allocator][cpit-007]
- [CPIT-008: Stale pointer after `realloc`][cpit-008]
- [CPIT-009: Lost base pointer][cpit-009]
- [CPIT-010: Interior pointer escape][cpit-010]
- [CPIT-011: NULL pointer dereference][cpit-011]
- [CPIT-012: Uninitialized pointer][cpit-012]
- [CPIT-013: Out-of-bounds write][cpit-013]
- [CPIT-014: Out-of-bounds read][cpit-014]
- [CPIT-015: Buffer underflow][cpit-015]
- [CPIT-016: Off-by-one][cpit-016]
- [CPIT-017: One-past-end dereference][cpit-017]
- [CPIT-018: Invalid pointer arithmetic][cpit-018]
- [CPIT-019: Invalid pointer comparison][cpit-019]
- [CPIT-020: Invalid pointer subtraction][cpit-020]
- [CPIT-021: Pointer provenance violation][cpit-021]
- [CPIT-022: Strict aliasing violation][cpit-022]
- [CPIT-023: Invalid `restrict` aliasing][cpit-023]
- [CPIT-024: Invalid alignment][cpit-024]
- [CPIT-025: Pointer truncation][cpit-025]
- [CPIT-026: Function pointer type mismatch][cpit-026]
- [CPIT-027: Object pointer/function pointer mixing][cpit-027]
- [CPIT-028: Union pointer confusion][cpit-028]
- [CPIT-029: Array-to-pointer decay][cpit-029]
- [CPIT-030: Hidden or encoded pointer][cpit-030]
- [CPIT-031: Pointer to moved object][cpit-031]
- [CPIT-032: Borrowed pointer stored beyond lifetime][cpit-032]
- [CPIT-033: Heap object points to stack memory][cpit-033]
- [CPIT-034: MMIO/DMA pointer treated as ordinary heap][cpit-034]
- [CPIT-123: Chained pointer dereference][cpit-123]
- [CPIT-124: Stale validity after a mutating call][cpit-124]
- [CPIT-125: Interleaved mutation through aliases][cpit-125]
- [CPIT-128: Flexible-array capacity mismatch][cpit-128]
- [CPIT-132: Pointer size mistaken for object capacity][cpit-132]
- [CPIT-133: Representation zeroing mistaken for semantic initialization][cpit-133]
- [CPIT-154: Pool-allocated object escapes its scope][cpit-154]

</details>

<details>
<summary>Evaluation and undefined behavior</summary>

- [CPIT-035: Unsequenced modification][cpit-035]
- [CPIT-036: Indeterminate value read][cpit-036]
- [CPIT-037: Trap representation][cpit-037]
- [CPIT-038: Signed integer overflow][cpit-038]
- [CPIT-039: Invalid shift][cpit-039]
- [CPIT-040: Divide overflow][cpit-040]
- [CPIT-041: Invalid effective type access][cpit-041]
- [CPIT-042: VLA with invalid bound][cpit-042]
- [CPIT-043: `longjmp` into dead frame][cpit-043]
- [CPIT-044: Modified non-volatile local after `setjmp`][cpit-044]
- [CPIT-045: Recursive unbounded call chain][cpit-045]
- [CPIT-046: Infinite loop without progress][cpit-046]
- [CPIT-129: Variadic argument contract mismatch][cpit-129]
- [CPIT-130: Control flow hidden in an expression][cpit-130]
- [CPIT-134: Function arguments depend on evaluation order][cpit-134]
- [CPIT-135: Inactive union member read][cpit-135]
- [CPIT-136: Semantic object copied as bytes][cpit-136]
- [CPIT-137: Discarded `const` qualification][cpit-137]
- [CPIT-138: Invalid callback invocation][cpit-138]
- [CPIT-139: String literal modification][cpit-139]
- [CPIT-140: Unproved compiler assumption][cpit-140]
- [CPIT-141: Untrusted input reaches fatal allocation][cpit-141]
- [CPIT-142: Sequence pointer without extent][cpit-142]
- [CPIT-143: Partial mutation before validation][cpit-143]
- [CPIT-144: Logical and bitwise operator confusion][cpit-144]
- [CPIT-145: Boolean collapses a multi-state result][cpit-145]
- [CPIT-146: Inline assembly has an incomplete machine contract][cpit-146]
- [CPIT-149: Host byte order leaks into an external representation][cpit-149]
- [CPIT-150: Unaligned external data is accessed as a typed object][cpit-150]
- [CPIT-160: Lifecycle verb hides the real object transition][cpit-160]
- [CPIT-161: External text crosses a boundary without an encoding contract][cpit-161]
- [CPIT-162: Bidirectional or confusable source text changes review meaning][cpit-162]

</details>

<details>
<summary>Integer and conversion contracts</summary>

- [CPIT-047: Allocation multiplication overflow][cpit-047]
- [CPIT-048: Header plus payload overflow][cpit-048]
- [CPIT-049: Offset plus size overflow][cpit-049]
- [CPIT-050: Alignment rounding overflow][cpit-050]
- [CPIT-051: Division by zero][cpit-051]
- [CPIT-052: Narrowing conversion][cpit-052]
- [CPIT-053: Signed/unsigned mixing][cpit-053]
- [CPIT-054: Enum conversion out of range][cpit-054]
- [CPIT-055: Floating-point in core allocator][cpit-055]
- [CPIT-127: Plain `char` used as binary numeric storage][cpit-127]

</details>

<details>
<summary>Library calls, text, and I/O</summary>

- [CPIT-056: `memcpy` with overlap][cpit-056]
- [CPIT-057: `memcpy`/`memset` invalid pointer][cpit-057]
- [CPIT-058: `strlen` on unterminated data][cpit-058]
- [CPIT-059: `strcpy`/`strcat` unbounded copy][cpit-059]
- [CPIT-060: `strncpy` missing NUL][cpit-060]
- [CPIT-061: `printf` external format string][cpit-061]
- [CPIT-062: `printf("%s", NULL)`][cpit-062]
- [CPIT-063: `ctype.h` negative `char`][cpit-063]
- [CPIT-064: `atoi` silent parse failure][cpit-064]
- [CPIT-065: `rand` for security][cpit-065]
- [CPIT-066: `tmpnam`/`mktemp`][cpit-066]
- [CPIT-067: `system` with external input][cpit-067]
- [CPIT-068: Ignored return value][cpit-068]
- [CPIT-131: Stale or overwritten `errno`][cpit-131]
- [CPIT-147: Partial I/O is treated as complete][cpit-147]
- [CPIT-148: Interrupted I/O loses progress or retry policy][cpit-148]
- [CPIT-153: Counted data is treated as a NUL-terminated string][cpit-153]
- [CPIT-168: Descriptor or handle leaks across an execution boundary][cpit-168]

</details>

<details>
<summary>Concurrency and execution lifetime</summary>

- [CPIT-069: Data race][cpit-069]
- [CPIT-070: Improper locking][cpit-070]
- [CPIT-071: Deadlock][cpit-071]
- [CPIT-072: Spurious wakeup bug][cpit-072]
- [CPIT-073: Destroying locked mutex][cpit-073]
- [CPIT-074: Incorrect atomic memory order][cpit-074]
- [CPIT-075: Volatile used as synchronization][cpit-075]
- [CPIT-076: ISR shared-state race][cpit-076]
- [CPIT-077: Signal handler unsafe call][cpit-077]
- [CPIT-078: ABA problem][cpit-078]
- [CPIT-079: Reentrancy violation][cpit-079]
- [CPIT-080: Thread-local storage leak][cpit-080]
- [CPIT-081: Refcount overflow][cpit-081]
- [CPIT-082: Concurrent double free][cpit-082]
- [CPIT-083: Unbounded blocking][cpit-083]
- [CPIT-151: Wall-clock changes corrupt duration or deadline logic][cpit-151]
- [CPIT-152: Automatic storage exceeds the stack budget][cpit-152]
- [CPIT-159: A lock precondition is visible only in prose][cpit-159]
- [CPIT-163: Shared object is destroyed while another context acquires it][cpit-163]
- [CPIT-164: Concurrent one-time initialization publishes partial state][cpit-164]
- [CPIT-165: Thread cancellation bypasses cleanup][cpit-165]
- [CPIT-166: Forked child calls unsafe code from a multithreaded process][cpit-166]
- [CPIT-167: Priority inversion breaks a bounded real-time path][cpit-167]

</details>

<details>
<summary>Hardware and persistent state</summary>

- [CPIT-084: Reserved register bits clobbered][cpit-084]
- [CPIT-085: Read-clear register mishandled][cpit-085]
- [CPIT-086: DMA cache coherency failure][cpit-086]
- [CPIT-087: Watchdog kicked too early][cpit-087]
- [CPIT-088: Unsafe default state][cpit-088]
- [CPIT-089: Persistent config corruption][cpit-089]
- [CPIT-090: Calibration out of range][cpit-090]
- [CPIT-091: Missing stale-data detection][cpit-091]
- [CPIT-092: Missing sequence or freshness check][cpit-092]
- [CPIT-093: Dynamic allocation in critical path][cpit-093]
- [CPIT-126: Bit-field layout used as an external representation][cpit-126]
- [CPIT-169: Power loss exposes a partially committed persistent update][cpit-169]

</details>

<details>
<summary>Security and external input</summary>

- [CPIT-094: Tainted size trusted][cpit-094]
- [CPIT-095: Format string injection][cpit-095]
- [CPIT-096: Hardcoded secret][cpit-096]
- [CPIT-097: Secret logged][cpit-097]
- [CPIT-098: Missing secure erase][cpit-098]
- [CPIT-099: Homegrown cryptography][cpit-099]
- [CPIT-100: Weak random number][cpit-100]
- [CPIT-101: Missing firmware signature check][cpit-101]
- [CPIT-102: Missing anti-rollback][cpit-102]
- [CPIT-103: Command injection][cpit-103]
- [CPIT-104: Path traversal][cpit-104]
- [CPIT-105: Improper access control][cpit-105]
- [CPIT-106: SQL injection][cpit-106]
- [CPIT-107: Cross-site scripting output injection][cpit-107]
- [CPIT-108: Cross-site request forgery][cpit-108]
- [CPIT-109: Code injection or dynamic evaluation][cpit-109]
- [CPIT-110: Unrestricted dangerous file upload][cpit-110]
- [CPIT-111: Deserialization of untrusted data][cpit-111]
- [CPIT-112: Missing authentication for critical function][cpit-112]
- [CPIT-113: Incorrect authorization or user-controlled object key][cpit-113]
- [CPIT-114: Server-side request forgery][cpit-114]
- [CPIT-115: Unbounded resource consumption][cpit-115]
- [CPIT-116: Security misconfiguration or active debug mode][cpit-116]
- [CPIT-117: Software supply-chain dependency failure][cpit-117]
- [CPIT-118: Untrusted component or plugin inclusion][cpit-118]
- [CPIT-119: Log injection or insufficient security logging][cpit-119]
- [CPIT-120: Fail-open or sensitive error disclosure][cpit-120]
- [CPIT-121: Untrusted search path or environment-controlled loader][cpit-121]
- [CPIT-122: XML external entity or recursive entity expansion][cpit-122]

</details>

<details>
<summary>Build, source, and release integrity</summary>

- [CPIT-155: A supported configuration is never built][cpit-155]
- [CPIT-156: A failure path exists but cannot be injected][cpit-156]
- [CPIT-157: Generated source drift hides the reviewed input][cpit-157]
- [CPIT-158: Imported source loses upstream lineage][cpit-158]
- [CPIT-170: Stable API disappears without a migration window][cpit-170]
- [CPIT-171: Production binary omits an applicable hardening control][cpit-171]
- [CPIT-172: Release artifact changes without a source or toolchain change][cpit-172]
- [CPIT-173: Incompatible ABI change reaches a stable release][cpit-173]

</details>

<details>
<summary>Performance and specialization</summary>

- [CPIT-174: False sharing on write-hot state][cpit-174]
- [CPIT-175: NUMA-remote hot-state placement][cpit-175]
- [CPIT-176: Store-buffer saturation][cpit-176]
- [CPIT-177: Store-to-load forwarding stall][cpit-177]
- [CPIT-178: False 4 KiB memory dependency][cpit-178]
- [CPIT-179: Split lock or cross-line atomic][cpit-179]
- [CPIT-180: TLB shootdown or page-walk pressure][cpit-180]
- [CPIT-181: Cache-set conflict mistaken for capacity pressure][cpit-181]
- [CPIT-182: Software prefetch distance or usefulness failure][cpit-182]
- [CPIT-183: Hardware prefetch increases pollution or bandwidth pressure][cpit-183]
- [CPIT-184: Non-temporal store misuse][cpit-184]
- [CPIT-185: Cross-owner free coordination storm][cpit-185]
- [CPIT-186: Atomic coherence hotspot][cpit-186]
- [CPIT-187: Front-end footprint and predictor pressure][cpit-187]
- [CPIT-188: Nonrepresentative performance profile][cpit-188]
- [CPIT-189: Contention policy creates a spin storm or thundering herd][cpit-189]
- [CPIT-190: Partial-line DMA or streaming transaction][cpit-190]
- [CPIT-191: Independent hot locks share one coherence unit][cpit-191]
- [CPIT-192: Specialized artifact executes after its invariant changed][cpit-192]

</details>

<details>
<summary>Types, storage, and platform assumptions</summary>

- [CPIT-193: Mixed declarator type confusion][cpit-193]
- [CPIT-194: Pointer typedef qualification confusion][cpit-194]
- [CPIT-195: Raw storage reinterpreted without a typed-storage contract][cpit-195]
- [CPIT-196: Compound literal pointer escapes its lifetime][cpit-196]
- [CPIT-197: Undocumented implementation-defined dependency][cpit-197]
- [CPIT-198: Non-finite floating input enters a finite-value algorithm][cpit-198]

</details>

<details>
<summary>Security primitives and synchronization</summary>

- [CPIT-199: Secret comparison leaks through timing][cpit-199]
- [CPIT-200: Compiler transformation breaks a lockless access protocol][cpit-200]
- [CPIT-201: Ad hoc atomic protocol lacks one invariant owner][cpit-201]
- [CPIT-202: Unpaired or unjustified memory barrier][cpit-202]

</details>

<details>
<summary>Hardware faults and resource limits</summary>

- [CPIT-203: Raw MMIO access bypasses the platform register contract][cpit-203]
- [CPIT-204: Single fault flips a security-critical decision][cpit-204]
- [CPIT-205: Compiler removes intended fault-detection redundancy][cpit-205]
- [CPIT-206: Fault-sensitive critical action sequence is only end-state checked][cpit-206]
- [CPIT-207: Monolithic growth causes allocator or latency failure][cpit-207]
- [CPIT-208: Unjustified code alignment or patch geometry][cpit-208]

</details>

</details>

---

<a id="evidence-model"></a>

## Evidence model

A CPIT is a generic engineering failure scenario. CWE identifies weakness classes; CAPEC identifies
attack patterns; a CVE identifies a concrete reported vulnerability. CISA KEV records evidence of
known exploitation for particular vulnerabilities. CVSS expresses a scored vulnerability assessment
using its published version/vector. These are different kinds of evidence.

The CWE associations below are reviewed engineering context, not a claim of exact equivalence or an
official MITRE mapping. Broad categories and CWE views must not be treated as concrete root causes.
CPIT-055 is explicitly a project policy risk and has no automatic CWE equivalence. A software
component that does not implement a technology may mark those entries not applicable, with a reason.

The dated CWE Top 25 and OWASP-oriented application topics remain useful coverage prompts; they are
not the complete scope of C memory, arithmetic, or hardware correctness. No generic CPIT, CWE, or
CAPEC entry receives a fabricated CVSS score. A version-3.1 score must not be relabeled version 4.0.

Keep field evidence as a separate dated record containing: component and affected version, CVE,
publisher/advisory URL, root cause, reachability in this product, KEV lookup result and date, actual
CVSS version/vector/source, mitigation owner, fix/retest status, and the relevant CPIT/control IDs.
A CVE cited as an example does not establish that the project is vulnerable. Check the current KEV
status and the published score against the dated field evidence before making a product claim.

---

<a id="catalogue"></a>

## Catalogue use

Find the failure scenario, review its preconditions, follow its prevention controls, and select a
test or analysis appropriate to the real target. Each entry's **Verification design** describes a
regression or review obligation. A completed verification record must identify the test sources,
target configuration, command, and observed result before the check counts as executed evidence.

Each entry includes local failure and prevention examples. Contextual fragments state only the named
scenario; deliberately invalid examples are marked and excluded from executable tests. Complete test
sources remain in the appendix. The [example policy][c-code-standard-example-policy] applies to
every entry.

---

## Failure scenarios

---

<a id="cpit-001"></a>

<a id="cpit-001-dangling-pointer"></a>

### CPIT-001: Dangling pointer

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

A pointer whose object's lifetime has ended cannot be used as though the object were still alive.
Freeing, leaving a block, resetting an arena, or moving an object can invalidate references.
Retaining the same numeric address does not retain ownership or lifetime. Record the owner and
validity interval, not just the address.

**Prevention controls:** [CSTYLE-084][c-code-standard-cstyle-084].

**Weakness context:** [CWE-825][cwe-825], [CWE-416][cwe-416]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Trace every retained alias across release, block exit, and arena reset;
reject a use after the validity interval.

**Source context:** [asan][c-common-pitfalls-ref-asan]; [ubsan][c-common-pitfalls-ref-ubsan].

**External references:** [CWE-825][cwe-825]; [CWE-416][cwe-416].

#### Local examples

**Failure fragment (do not execute):**

```c
int *EX_badDanglingPointer(void)
{
    int *ret = (int *)(NULL);
    int local_value = 7;

    ret = &local_value;

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
free(item);
item = (item_t *)(NULL);
```

**Noncompliant fragment (do not copy):**

```c
free(item);
item->state = ITEM_READY;
```

---

<a id="cpit-002"></a>

<a id="cpit-002-use-after-free"></a>

### CPIT-002: Use-after-free

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

An access after release can reach reallocated storage and corrupt a different object. Setting one
owner variable to NULL does not repair other aliases. Ownership, pinning, reference counting,
epochs, hazard pointers, or GC references help only when their complete lifetime protocol applies.

**Prevention controls:** [CSTYLE-082][c-code-standard-cstyle-082].

**Weakness context:** [CWE-416][cwe-416]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Delay a consumer across owner release and prove release waits or the
reference remains protected.

**Source context:** [asan][c-common-pitfalls-ref-asan]; [ubsan][c-common-pitfalls-ref-ubsan].

**External references:** [CWE-416][cwe-416].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badUseAfterFree(uint8_t buffer[])
{
    int ret = EXIT_SUCCESS;

    free(buffer);
    buffer[0] = 1u;

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
free(item);
item = (item_t *)(NULL);
```

**Noncompliant fragment (do not copy):**

```c
free(item);
item->state = ITEM_READY;
```

---

<a id="cpit-003"></a>

<a id="cpit-003-double-free"></a>

### CPIT-003: Double free

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Releasing an allocation twice violates the allocator contract. One allocation needs one valid
release authority, or a defined shared-ownership protocol whose last release is unique. Idempotent
destruction of a cleared handle does not make stale copies of that handle safe to destroy.

**Prevention controls:** [CSTYLE-082][c-code-standard-cstyle-082].

**Weakness context:** [CWE-415][cwe-415]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Exercise repeated destruction of a cleared handle and reject release
through a stale ownership copy by protocol review.

**Source context:** [asan][c-common-pitfalls-ref-asan]; [ubsan][c-common-pitfalls-ref-ubsan].

**External references:** [CWE-415][cwe-415].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badDoubleFree(uint8_t buffer[])
{
    int ret = EXIT_SUCCESS;

    free(buffer);
    free(buffer);

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
free(item);
item = (item_t *)(NULL);
```

**Noncompliant fragment (do not copy):**

```c
free(item);
free(item);
```

---

<a id="cpit-004"></a>

<a id="cpit-004-memory-leak"></a>

### CPIT-004: Memory leak

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

A memory leak occurs when the program loses the path needed to release memory or another finite
resource. In embedded systems this is often a safety issue, not only a performance issue, because
long-running firmware may eventually exhaust a fixed RAM budget. Cleanup paths, arenas, pools, and
long-run leak tests are useful evidence for the applicable product.

**Prevention controls:** [CSTYLE-077][c-code-standard-cstyle-077].

**Weakness context:** [CWE-401][cwe-401], [CWE-772][cwe-772]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Fail each acquisition stage and require all previously acquired resources
to be released.

**External references:** [CWE-401][cwe-401]; [CWE-772][cwe-772].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badMemoryLeak(void)
{
    int ret = EXIT_SUCCESS;

    uint8_t *buffer = malloc(128u);

    buffer[0] = 1u;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-005"></a>

<a id="cpit-005-ambiguous-ownership"></a>

### CPIT-005: Ambiguous ownership

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Ambiguous ownership means the API does not say who owns, borrows, stores, or frees a pointer. This
usually creates either leaks or double frees later. Public APIs must document whether a pointer is
owned, borrowed, static, arena-owned, GC-owned, pinned, or caller-owned.

**Prevention controls:** [CSTYLE-082][c-code-standard-cstyle-082].

**Weakness context:** [CWE-664][cwe-664]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Review every public pointer parameter/result against an owner, borrower,
retention, and release statement.

**External references:** [CWE-664][cwe-664].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badAmbiguousOwnership(uint8_t buffer[])
{
    int ret = EXIT_SUCCESS;

    EX_releaseA(buffer);
    EX_releaseB(buffer);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Ownership contract names exactly one current owner; ownership transfer clears
the sender reference on success
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Two modules both believe they own and may free the same object
```

---

<a id="cpit-006"></a>

<a id="cpit-006-invalid-free"></a>

### CPIT-006: Invalid free

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Invalid free passes something to `free()` that was not returned by the matching allocator family as
a base pointer. Stack addresses, static objects, interior pointers, string literals, and foreign
allocator blocks must never be freed through the wrong API. The fix is to preserve allocator family
and base-pointer identity in the type or API contract.

**Prevention controls:** [CSTYLE-086][c-code-standard-cstyle-086].

**Weakness context:** [CWE-590][cwe-590]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Audit release sites to prove a live base from the matching allocator; do
not execute invalid free as a passing test.

**External references:** [CWE-590][cwe-590].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badInvalidFree(void)
{
    int ret = EXIT_SUCCESS;

    uint8_t stack_buffer[16] = { 0 };

    free(stack_buffer);

function_output:
    return ret;
}
```

**Failure fragment (do not execute):**

```c
int EX_badInvalidFree(void)
{
    int ret = EXIT_SUCCESS;

    uint8_t stack_buffer[16] = { 0u };

    free(stack_buffer);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-007"></a>

<a id="cpit-007-mismatched-allocator"></a>

### CPIT-007: Mismatched allocator

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

A mismatched allocator bug allocates with one family and releases with another, such as `malloc()`
with a pool destroy function or a platform allocator with plain `free()`. This breaks allocator
invariants even when the address looks valid. Pair allocation and release functions explicitly in
API names and ownership docs.

**Prevention controls:** [CSTYLE-077][c-code-standard-cstyle-077].

**Weakness context:** [CWE-762][cwe-762]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Instrument allocator-family IDs and verify allocation/release pairs during
each lifecycle.

**External references:** [CWE-762][cwe-762].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badMismatchedAllocator(uint8_t pool_buffer[])
{
    int ret = EXIT_SUCCESS;

    free(pool_buffer);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-008"></a>

<a id="cpit-008-stale-pointer-after-realloc"></a>

### CPIT-008: Stale pointer after `realloc`

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Successful `realloc` ends the old allocation's lifetime. Rebuild references from the returned base
even if the numeric address is unchanged. For positive sizes, a failed `realloc` preserves the old
allocation. Zero size is handled before the call by explicit free/reset or rejection; do not use the
ambiguous old pattern of treating every NULL `realloc` result as an ordinary allocation failure. The
buffer example tests preservation and zero-size reset.

**Prevention controls:** [CSTYLE-080][c-code-standard-cstyle-080].

**Weakness context:** [CWE-416][cwe-416], [CWE-825][cwe-825]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Inject positive-size `realloc` failure; require original bytes and size to
survive. Reset zero without `realloc`.

**Source context:** [asan][c-common-pitfalls-ref-asan]; [ubsan][c-common-pitfalls-ref-ubsan].

**External references:** [CWE-416][cwe-416]; [CWE-825][cwe-825].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badStalePointerAfterRealloc(uint8_t buffer[])
{
    int ret = EXIT_SUCCESS;

    uint8_t *alias = buffer;

    buffer = realloc(buffer, 32u);
    alias[0] = 1u;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-009"></a>

<a id="cpit-009-lost-base-pointer"></a>

### CPIT-009: Lost base pointer

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

A lost base pointer happens when code advances or overwrites the only pointer that can be passed
back to the allocator. Interior pointers are useful for parsing, but they must not replace the
owning base pointer. Keep base and cursor fields separate.

**Prevention controls:** [CSTYLE-082][c-code-standard-cstyle-082].

**Weakness context:** [CWE-401][cwe-401], [CWE-761][cwe-761]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Advance parsing cursors and verify the owning base is unchanged until its
one release.

**External references:** [CWE-401][cwe-401]; [CWE-761][cwe-761].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badLostBasePointer(uint8_t buffer[])
{
    int ret = EXIT_SUCCESS;

    buffer++;
    free(buffer);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-010"></a>

<a id="cpit-010-interior-pointer-escape"></a>

### CPIT-010: Interior pointer escape

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

An interior pointer escape stores a pointer to a field, element, or middle of an object beyond the
parent object's lifetime or ownership boundary. This hides the real allocation and makes lifetime
review difficult. Use handles, indexes, or an explicit parent-object reference when the subobject
must escape.

**Prevention controls:** [CSTYLE-096][c-code-standard-cstyle-096].

**Weakness context:** [CWE-825][cwe-825], [CWE-664][cwe-664]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Retain a subobject reference across parent invalidation in a model and
reject the lifetime transition.

**External references:** [CWE-825][cwe-825]; [CWE-664][cwe-664].

#### Local examples

**Failure fragment (do not execute):**

```c
uint8_t *EX_badInteriorPointerEscape(uint8_t buffer[])
{
    uint8_t *ret = (uint8_t *)(NULL);

    ret = &buffer[4];

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-011"></a>

<a id="cpit-011-null-pointer-dereference"></a>

### CPIT-011: NULL pointer dereference

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Dereferencing `NULL` is undefined behavior in C. It commonly follows unchecked allocation, optional
arguments, failed lookups, or partial initialization. Validate nullable inputs at the boundary and
reserve assertions for internal invariants that cannot be violated by external input.

**Prevention controls:** [CSTYLE-058][c-code-standard-cstyle-058].

**Weakness context:** [CWE-476][cwe-476]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Pass contractually nullable or invalid NULL inputs and require the
documented status before access.

**External references:** [CWE-476][cwe-476].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badNullPointerDereference(void)
{
    int ret = EXIT_SUCCESS;

    uint32_t *value = NULL;

    *value = 1u;

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
if (ptr == (object_t *)(NULL))
{
        ret = -EINVAL;
        goto function_output;
}

value = ptr->value;
```

**Noncompliant fragment (do not copy):**

```c
value = ptr->value; /* ptr may be NULL */
```

---

<a id="cpit-012"></a>

<a id="cpit-012-uninitialized-pointer"></a>

### CPIT-012: Uninitialized pointer

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

An uninitialized pointer contains an indeterminate value, not a safe default. Reading or
dereferencing it can jump into arbitrary memory or trigger undefined behavior before any obvious
branch. Initialize all pointers at function entry using typed `NULL` under CSTYLE-107, then assign
validated live objects before use. Aggregate initialization follows the same control.

**Prevention controls:** [CSTYLE-107][c-code-standard-cstyle-107].

**Weakness context:** [CWE-824][cwe-824], [CWE-457][cwe-457]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Build with initialization diagnostics and review every path that reaches a
pointer read.

**Source context:** [asan][c-common-pitfalls-ref-asan]; [ubsan][c-common-pitfalls-ref-ubsan].

**External references:** [CWE-824][cwe-824]; [CWE-457][cwe-457].

#### Local examples

**Contextual prevention example:**

```c
int EX_badUninitializedPointer(void)
{
        int ret = EXIT_SUCCESS;

        uint32_t *value;

        *value = 1u;

function_output:
        return ret;
}
```

---

<a id="cpit-013"></a>

<a id="cpit-013-out-of-bounds-write"></a>

### CPIT-013: Out-of-bounds write

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

An out-of-bounds write stores data outside the target object. In allocators and embedded runtimes
this may overwrite metadata, control blocks, adjacent objects, return addresses, or hardware
descriptors. Every write must be guarded by a validated base pointer, capacity, offset, and write
size.

**Prevention controls:** [CSTYLE-063][c-code-standard-cstyle-063].

**Weakness context:** [CWE-787][cwe-787], [CWE-120][cwe-120]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Exercise capacity zero, exact capacity, and one-short outputs; verify guard
bytes remain unchanged.

**Source context:** [asan][c-common-pitfalls-ref-asan]; [ubsan][c-common-pitfalls-ref-ubsan].

**External references:** [CWE-787][cwe-787]; [CWE-120][cwe-120].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badOutOfBoundsWrite(void)
{
    int ret = EXIT_SUCCESS;

    uint8_t buffer[4] = { 0 };

    buffer[4] = 1u;

function_output:
    return ret;
}
```

**Failure fragment (do not execute):**

```c
int EX_badOutOfBoundsWrite(void)
{
    int ret = EXIT_SUCCESS;

    uint8_t buffer[4] = { 0u };

    buffer[4] = 1u;

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
if (index < array_count)
        value = array[index];
```

**Noncompliant fragment (do not copy):**

```c
value = array[index]; /* index not proven in bounds */
```

---

<a id="cpit-014"></a>

<a id="cpit-014-out-of-bounds-read"></a>

### CPIT-014: Out-of-bounds read

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

An out-of-bounds read can disclose stale memory, fault on protected pages, or feed invalid values
into control logic. It is still a bug even if it does not modify memory. Validate indexes and
lengths before the read, not after.

**Prevention controls:** [CSTYLE-099][c-code-standard-cstyle-099].

**Weakness context:** [CWE-125][cwe-125]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Exercise truncated frames at each field boundary and require rejection
before an unavailable byte is read.

**Source context:** [asan][c-common-pitfalls-ref-asan]; [ubsan][c-common-pitfalls-ref-ubsan].

**External references:** [CWE-125][cwe-125].

#### Local examples

**Failure fragment (do not execute):**

```c
uint8_t EX_badOutOfBoundsRead(void)
{
    uint8_t ret = 0u;
    uint8_t buffer[4] = { 0 };

    ret = buffer[4];

function_output:
    return ret;
}
```

**Failure fragment (do not execute):**

```c
uint8_t EX_badOutOfBoundsRead(void)
{
    uint8_t ret = 0u;
    uint8_t buffer[4] = { 0u };

    ret = buffer[4];

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
if (index < array_count)
        value = array[index];
```

**Noncompliant fragment (do not copy):**

```c
value = array[index]; /* index not proven in bounds */
```

---

<a id="cpit-015"></a>

<a id="cpit-015-buffer-underflow"></a>

### CPIT-015: Buffer underflow

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Buffer underflow accesses memory before the start of an object, usually through a decremented
pointer, negative index, or unsigned wraparound. It is the same class of boundary violation as
overflow but often missed in reviews because the code visually moves "backward." Check lower bounds
explicitly.

**Prevention controls:** [CSTYLE-099][c-code-standard-cstyle-099].

**Weakness context:** [CWE-124][cwe-124]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Review decrements at index zero and signed negative indices; require the
lower bound before pointer formation.

**External references:** [CWE-124][cwe-124].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badBufferUnderflow(void)
{
    int ret = EXIT_SUCCESS;

    uint8_t buffer[4] = { 0 };
    uint8_t *cursor = buffer;

    cursor[-1] = 1u;

function_output:
    return ret;
}
```

**Failure fragment (do not execute):**

```c
int EX_badBufferUnderflow(void)
{
    int ret = EXIT_SUCCESS;

    uint8_t buffer[4] = { 0u };
    uint8_t *cursor = buffer;

    cursor[-1] = 1u;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-016"></a>

<a id="cpit-016-off-by-one"></a>

### CPIT-016: Off-by-one

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Off-by-one errors use one too many or one too few elements. They often appear in loops, terminator
handling, and one-past pointer logic. Write loop bounds in terms of `index < count`, keep terminator
capacity separate, and test zero, one, max, and boundary sizes.

**Prevention controls:** [CSTYLE-074][c-code-standard-cstyle-074].

**Weakness context:** [CWE-193][cwe-193]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Test empty, one-element, last-valid-element, and terminator-capacity cases.

**External references:** [CWE-193][cwe-193].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badOffByOne(void)
{
    int ret = EXIT_SUCCESS;

    uint8_t buffer[4] = { 0 };

    size_t index = 0u;

    for (index = 0u; index <= 4u; index++)
    {
        buffer[index] = 0u;
    }

function_output:
    return ret;
}
```

**Failure fragment (do not execute):**

```c
int EX_badOffByOne(void)
{
    int ret = EXIT_SUCCESS;

    uint8_t buffer[4] = { 0u };

    for (size_t index = 0u; index <= 4u; index++)
        buffer[index] = 0u;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-017"></a>

<a id="cpit-017-one-past-end-dereference"></a>

### CPIT-017: One-past-end dereference

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

C allows forming a pointer one past the end of an array object, but not dereferencing it. That
pointer is only a sentinel for comparison and range logic. Any access must move back into the valid
object range first.

**Prevention controls:** [CSTYLE-099][c-code-standard-cstyle-099].

**Weakness context:** [CWE-125][cwe-125], [CWE-787][cwe-787]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Review end sentinels and prove each dereference has index strictly below
count.

**External references:** [CWE-125][cwe-125]; [CWE-787][cwe-787].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badOnePastEndDereference(void)
{
    int ret = EXIT_SUCCESS;

    uint8_t buffer[4] = { 0 };
    uint8_t *end = &buffer[4];

    *end = 1u;

function_output:
    return ret;
}
```

**Failure fragment (do not execute):**

```c
int EX_badOnePastEndDereference(void)
{
    int ret = EXIT_SUCCESS;

    uint8_t buffer[4] = { 0u };
    uint8_t *end = &buffer[4];

    *end = 1u;

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
end = &array[array_count];
if (ptr < end)
        value = *ptr;
```

**Noncompliant fragment (do not copy):**

```c
value = *(&array[array_count]); /* dereference one-past */
```

---

<a id="cpit-018"></a>

<a id="cpit-018-invalid-pointer-arithmetic"></a>

### CPIT-018: Invalid pointer arithmetic

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Pointer arithmetic is only defined within the same array object and its one-past position.
Arithmetic derived from external offsets, serialized metadata, or integer addresses must be
validated before forming or using the pointer. Prefer byte-offset validation on integer sizes before
converting to a pointer expression.

**Prevention controls:** [CSTYLE-102][c-code-standard-cstyle-102].

**Weakness context:** [CWE-469][cwe-469], [CWE-129][cwe-129]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Test extreme offsets arithmetically before any pointer is formed; valid
offset plus length must fit.

**External references:** [CWE-469][cwe-469]; [CWE-129][cwe-129].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badInvalidPointerArithmetic(void)
{
    int ret = EXIT_SUCCESS;

    uint8_t buffer[4] = { 0 };
    uint8_t *cursor = buffer + 8u;

    *cursor = 1u;

function_output:
    return ret;
}
```

**Failure fragment (do not execute):**

```c
int EX_badInvalidPointerArithmetic(void)
{
    int ret = EXIT_SUCCESS;

    uint8_t buffer[4] = { 0u };
    uint8_t *cursor = buffer + 8u;

    *cursor = 1u;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-019"></a>

<a id="cpit-019-invalid-pointer-comparison"></a>

### CPIT-019: Invalid pointer comparison

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Equality of valid pointer values is distinct from relational ordering. Relational comparison of
unrelated object pointers is not a portable heap-range or ownership check. Use recorded offsets and
allocation metadata under a defined address-domain contract. Stale or indeterminate pointers are not
made valid by comparing them instead of dereferencing them.

**Prevention controls:** [CSTYLE-100][c-code-standard-cstyle-100].

**Weakness context:** [CWE-758][cwe-758]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Audit relational pointer comparisons and replace cross-allocation ordering
with an owned metadata relation.

**Source context:** [c23][c-common-pitfalls-ref-c23].

**External references:** [CWE-758][cwe-758].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badInvalidPointerComparison(uint8_t *lhs, uint8_t *rhs)
{
    int ret = 0;

    ret = (lhs < rhs);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-020"></a>

<a id="cpit-020-invalid-pointer-subtraction"></a>

### CPIT-020: Invalid pointer subtraction

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Pointer subtraction requires positions in the same array object (including its one-past position),
and the difference must be representable in `ptrdiff_t`. Do not subtract unrelated allocations to
determine size or ownership. Keep explicit lengths or validated within-object offsets.

**Prevention controls:** [CSTYLE-100][c-code-standard-cstyle-100].

**Weakness context:** [CWE-469][cwe-469], [CWE-758][cwe-758]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Prove common array provenance and `ptrdiff_t` representability for each
subtraction.

**Source context:** [c23][c-common-pitfalls-ref-c23].

**External references:** [CWE-469][cwe-469]; [CWE-758][cwe-758].

#### Local examples

**Failure fragment (do not execute):**

```c
ptrdiff_t EX_badInvalidPointerSubtraction(uint8_t *lhs, uint8_t *rhs)
{
    ptrdiff_t ret = 0;

    ret = lhs - rhs;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-021"></a>

<a id="cpit-021-pointer-provenance-violation"></a>

### CPIT-021: Pointer provenance violation

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

A numeric address alone does not establish that a pointer designates a live object with valid
provenance and access rights. Low-level allocators and hardware adapters must document their
target/compiler assumptions. Portable application code must not recreate pointers from serialized or
untrusted integer values. Not every implementation-supported round trip is inherently erroneous.

**Prevention controls:** [CSTYLE-098][c-code-standard-cstyle-098].

**Weakness context:** [CWE-758][cwe-758]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Review every pointer/integer reconstruction against a target-qualified
representation and lifetime contract.

**Source context:** [c23][c-common-pitfalls-ref-c23].

**External references:** [CWE-758][cwe-758].

#### Local examples

**Failure fragment (do not execute):**

```c
uint32_t EX_badPointerProvenanceViolation(uintptr_t raw_address)
{
    uint32_t ret = 0u;
    uint32_t *value = (uint32_t *)raw_address;

    ret = *value;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-022"></a>

<a id="cpit-022-strict-aliasing-violation"></a>

### CPIT-022: Strict aliasing violation

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Access through an incompatible effective type can violate the optimizer's language assumptions.
Character types may inspect object representation; unsigned char is the preferred byte-value view. A
`memcpy` representation copy still needs valid storage, sufficient length, and an allowed
destination representation. It is not an endian conversion or an arbitrary object constructor.

**Prevention controls:** [CSTYLE-098][c-code-standard-cstyle-098].

**Weakness context:** [CWE-843][cwe-843], [CWE-758][cwe-758]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Run optimized builds and inspect type-punning sites; use valid byte copies
or fieldwise decode.

**Source context:** [c23][c-common-pitfalls-ref-c23].

**External references:** [CWE-843][cwe-843]; [CWE-758][cwe-758].

#### Local examples

**Failure fragment (do not execute):**

```c
uint32_t EX_badStrictAliasingViolation(float *value)
{
    uint32_t ret = 0u;
    uint32_t *bits = (uint32_t *)value;

    ret = *bits;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-023"></a>

<a id="cpit-023-invalid-restrict-aliasing"></a>

### CPIT-023: Invalid `restrict` aliasing

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

A violated restrict contract can make an otherwise plausible access invalid. The rule concerns
access paths and modifications over the relevant execution; it is not a blanket ban on every pair of
read-only aliases. Use restrict only when its actual requirements are proved and callers can satisfy
them. Document permitted overlap separately from the qualifier.

**Prevention controls:** [CSTYLE-098][c-code-standard-cstyle-098].

**Weakness context:** [CWE-758][cwe-758], [CWE-664][cwe-664]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Prove restrict access requirements at call sites, including modifications
through other aliases.

**Source context:** [c23][c-common-pitfalls-ref-c23].

**External references:** [CWE-758][cwe-758]; [CWE-664][cwe-664].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badRestrictAliasing(uint32_t *restrict lhs, uint32_t *restrict rhs)
{
    int ret = EXIT_SUCCESS;

    *lhs = 1u;
    *rhs = 2u;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-024"></a>

<a id="cpit-024-invalid-alignment"></a>

### CPIT-024: Invalid alignment

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Typed object access requires suitable alignment. A byte buffer with enough bytes does not
necessarily provide valid storage for an arbitrary struct. Establish alignment and
object/effective-type validity before conversion and use. Prefer fieldwise decoding or an allocator
with the required alignment contract.

**Prevention controls:** [CSTYLE-096][c-code-standard-cstyle-096].

**Weakness context:** [CWE-758][cwe-758], [CWE-119][cwe-119]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Use deliberately unaligned byte input only with bytewise decoders; typed
accesses need proved alignment.

**Source context:** [c23][c-common-pitfalls-ref-c23].

**External references:** [CWE-758][cwe-758]; [CWE-119][cwe-119].

#### Local examples

**Failure fragment (do not execute):**

```c
uint32_t EX_badInvalidAlignment(uint8_t buffer[])
{
    uint32_t ret = 0u;
    uint32_t *value = (uint32_t *)(buffer + 1u);

    ret = *value;

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
alignas(foo_t) uint8_t storage[sizeof(foo_t)] = { 0 };
foo_t *foo                                    = (foo_t *)storage;
```

**Noncompliant fragment (do not copy):**

```c
foo_t *foo = (foo_t *)(storage + 1u);
```

---

<a id="cpit-025"></a>

<a id="cpit-025-pointer-truncation"></a>

### CPIT-025: Pointer truncation

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Pointer truncation stores an address in an integer type that cannot represent all pointer values, or
later casts it back. This breaks on wider address spaces, segmented systems, and capability-like
targets. Use `uintptr_t` only in low-level adapter code and document why the conversion is valid.

**Prevention controls:** [CSTYLE-097][c-code-standard-cstyle-097].

**Weakness context:** [CWE-681][cwe-681], [CWE-704][cwe-704]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Check conversion widths at compile time or before narrowing; test the
supported wider-address profile.

**External references:** [CWE-681][cwe-681]; [CWE-704][cwe-704].

#### Local examples

**Failure fragment (do not execute):**

```c
uint32_t EX_badPointerTruncation(void *ptr)
{
    uint32_t ret = 0u;

    ret = (uint32_t)(uintptr_t)ptr;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-026"></a>

<a id="cpit-026-function-pointer-type-mismatch"></a>

### CPIT-026: Function pointer type mismatch

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Calling a function through an incompatible function pointer type is undefined behavior. The ABI may
pass arguments or return values differently even when the sizes look similar. Callback typedefs must
exactly match the called function signature.

**Prevention controls:** [CSTYLE-071][c-code-standard-cstyle-071].

**Weakness context:** [CWE-758][cwe-758], [CWE-843][cwe-843]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Compile callback bindings with incompatible-pointer diagnostics as errors;
no signature casts are allowed.

**External references:** [CWE-758][cwe-758]; [CWE-843][cwe-843].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badFunctionPointerTypeMismatch(void (*callback)(void))
{
    int ret = EXIT_SUCCESS;

    void (*typed_callback)(int value) = (void (*)(int))callback;

    typed_callback(1);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-027-object-pointerfunction-pointer-mixing"></a> <a id="cpit-027"></a>

<a id="cpit-027-object-pointer-function-pointer-mixing"></a>

### CPIT-027: Object pointer/function pointer mixing

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

C does not guarantee object pointers and function pointers have the same representation or
conversion rules. Storing function pointers in `void *` or object pointers in callback slots is not
portable. Keep object and function pointer paths typed and separate.

**Prevention controls:** [CSTYLE-096][c-code-standard-cstyle-096].

**Weakness context:** [CWE-704][cwe-704], [CWE-758][cwe-758]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Keep loader-specific function resolution in its qualified adapter and
reject generic object/function pointer mixing.

**External references:** [CWE-704][cwe-704]; [CWE-758][cwe-758].

#### Local examples

**Failure fragment (do not execute):**

```c
void *EX_badObjectFunctionPointerMixing(void (*callback)(void))
{
    void *ret = (void *)(NULL);

    ret = (void *)callback;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-028"></a>

<a id="cpit-028-union-pointer-confusion"></a>

### CPIT-028: Union pointer confusion

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

A union that can hold multiple pointer or scalar interpretations needs an explicit active-member
tag. Reading an inactive member or scanning the wrong union arm can corrupt GC tracing,
serialization, or ownership decisions. Prefer tagged unions with checked state transitions.

**Prevention controls:** [CSTYLE-038][c-code-standard-cstyle-038].

**Weakness context:** [CWE-843][cwe-843], [CWE-758][cwe-758]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Review every union read against active representation rules and the
intended C edition/platform contract.

**External references:** [CWE-843][cwe-843]; [CWE-758][cwe-758].

#### Local examples

**Contextual prevention example:**

```c
typedef union ExValue
{
        uint32_t  integer_value;
        uint32_t *ptr_value;
} ex_value_t;

uint32_t EX_badUnionPointerConfusion(ex_value_t value)
{
        uint32_t ret = 0u;

        ret = *value.ptr_value;

function_output:
        return ret;
}
```

---

<a id="cpit-029"></a>

<a id="cpit-029-array-to-pointer-decay"></a>

### CPIT-029: Array-to-pointer decay

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Array parameters decay to pointers, losing size information. `sizeof(param)` then returns pointer
size, not array size. Every API receiving an array must also receive element count, byte size, or a
pointer to an explicitly sized array type.

**Prevention controls:** [CSTYLE-063][c-code-standard-cstyle-063].

**Weakness context:** [CWE-467][cwe-467], [CWE-131][cwe-131]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Compare array length in its defining scope with pointer-based APIs that
require an explicit length.

**External references:** [CWE-467][cwe-467]; [CWE-131][cwe-131].

#### Local examples

**Failure fragment (do not execute):**

```c
size_t EX_badArrayToPointerDecay(uint8_t buffer[])
{
    size_t ret = 0u;

    ret = sizeof(buffer);

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
int PROCESS(const uint8_t *data, size_t data_size_bytes);
```

**Noncompliant fragment (do not copy):**

```c
int PROCESS(uint8_t data[64]); /* callee assumes sizeof(data)==64 */
```

---

<a id="cpit-030"></a>

<a id="cpit-030-hidden-or-encoded-pointer"></a>

### CPIT-030: Hidden or encoded pointer

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Encoding an address into an integer can hide a reference from ownership analysis, GC root scanning,
or a relocation mechanism. Encoding is not inherently a C vulnerability, but treating the result as
an ordinary recoverable pointer without a proved representation/lifetime protocol is unsafe. Confine
legitimate tagging to a qualified low-level adapter or use non-address handles.

**Prevention controls:** [CSTYLE-069][c-code-standard-cstyle-069].

**Weakness context:** [CWE-758][cwe-758], [CWE-664][cwe-664]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Review tagged/encoded pointers against GC scanning, relocation, and
capability/provenance assumptions.

**External references:** [CWE-758][cwe-758]; [CWE-664][cwe-664].

#### Local examples

**Failure fragment (do not execute):**

```c
uintptr_t EX_badHiddenPointer(uint8_t buffer[])
{
    uintptr_t ret = 0u;

    ret = (uintptr_t)buffer ^ UINTPTR_C(0x5a5a5a5a);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-031"></a>

<a id="cpit-031-pointer-to-moved-object"></a>

### CPIT-031: Pointer to moved object

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Relocation invalidates raw references that the moving runtime has not updated. A pointer return
alone is not evidence of this defect; the failing sequence is retain an address, move the object,
then reuse that old reference. Use the runtime's registered roots, handles, or a valid pin/unpin
protocol.

**Prevention controls:** [CSTYLE-082][c-code-standard-cstyle-082].

**Weakness context:** [CWE-416][cwe-416], [CWE-825][cwe-825]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Model relocation between reference creation and use; require handles,
roots, or a valid pin.

**External references:** [CWE-416][cwe-416]; [CWE-825][cwe-825].

#### Local examples

**Failure fragment (do not execute):**

Handle resolver and borrower obey the moving-runtime contract; do not retain `borrowed_object`
across a moving safepoint. Variables are declared at entry.

```c
cached_address = object_address;
collect_and_move(runtime);
consume(cached_address);
```

**Contextual prevention example:**

Handle resolver and borrower obey the moving-runtime contract; do not retain `borrowed_object`
across a moving safepoint. Variables are declared at entry.

```c
ret = resolve_handle(handle_context, object_id, &borrowed_object);
if (ret != EXIT_SUCCESS)
        goto function_output;
ret = consume_before_safepoint(consumer_context, borrowed_object);
```

---

<a id="cpit-032"></a>

<a id="cpit-032-borrowed-pointer-stored-beyond-lifetime"></a>

### CPIT-032: Borrowed pointer stored beyond lifetime

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

A borrowed pointer is valid only for the documented call, scope, or transaction. Storing it in a
long-lived object silently turns a borrow into ownership without the release authority. Copy the
data, retain the owner, or change the API to transfer ownership.

**Prevention controls:** [CSTYLE-071][c-code-standard-cstyle-071].

**Weakness context:** [CWE-825][cwe-825], [CWE-664][cwe-664]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Invoke a deferred callback only while its retained owner remains live, or
require a data copy.

**External references:** [CWE-825][cwe-825]; [CWE-664][cwe-664].

#### Local examples

**Failure fragment (do not execute):**

```c
static uint8_t *g_borrowed_buffer;

int EX_badBorrowedPointerStored(uint8_t borrowed_buffer[])
{
    int ret = EXIT_SUCCESS;

    g_borrowed_buffer = borrowed_buffer;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Borrowed/interior pointer remains within owner lifetime and is never published
as an owning handle
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Store interior/borrowed pointer beyond owner lifetime and later dereference it
```

---

<a id="cpit-033"></a>

<a id="cpit-033-heap-object-points-to-stack-memory"></a>

### CPIT-033: Heap object points to stack memory

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

A longer-lived object may store a pointer to automatic storage and later use it after the storage's
lifetime ends. Heap allocation does not necessarily outlive every stack object; a borrow is valid
when all uses finish first. Document that interval or copy/retain separately owned data before
returning.

**Prevention controls:** [CSTYLE-084][c-code-standard-cstyle-084].

**Weakness context:** [CWE-825][cwe-825], [CWE-562][cwe-562]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Trace a retained automatic object through its block exit; prove all
borrowing users stop first.

**External references:** [CWE-825][cwe-825]; [CWE-562][cwe-562].

#### Local examples

**Failure fragment (do not execute):**

`local_bytes` is an automatic array; `copy_owned` copies it during the call. A heap object pointing
to automatic storage is not inherently invalid if the borrow ends before that storage lifetime.

```c
heap_object->bytes = local_bytes;
/* Returning leaves the heap object alive but the local array dead. */
```

**Contextual prevention example:**

`local_bytes` is an automatic array; `copy_owned` copies it during the call. A heap object pointing
to automatic storage is not inherently invalid if the borrow ends before that storage lifetime.

```c
ret = copy_owned(destination_context, local_bytes, sizeof(local_bytes));
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cpit-034-mmiodma-pointer-treated-as-ordinary-heap"></a> <a id="cpit-034"></a>

<a id="cpit-034-mmio-dma-pointer-treated-as-ordinary-heap"></a>

### CPIT-034: MMIO/DMA pointer treated as ordinary heap

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

MMIO and DMA memory have hardware-defined side effects, cache rules, alignment, and ownership. It
must not be moved by a GC, freed by the heap allocator, scanned as ordinary object memory, or
updated with normal concurrency assumptions. Keep hardware memory in explicit adapter modules.

**Prevention controls:** [CSTYLE-105][c-code-standard-cstyle-105],
[CSTYLE-061][c-code-standard-cstyle-061], [CSTYLE-107][c-code-standard-cstyle-107],
[CSTYLE-100][c-code-standard-cstyle-100], [CSTYLE-101][c-code-standard-cstyle-101],
[CSTYLE-103][c-code-standard-cstyle-103], [CSTYLE-108][c-code-standard-cstyle-108],
[CSTYLE-053][c-code-standard-cstyle-053], [CSTYLE-054][c-code-standard-cstyle-054],
[CSTYLE-074][c-code-standard-cstyle-074].

**Weakness context:** [CWE-119][cwe-119], [CWE-664][cwe-664]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Audit memory classes so MMIO/DMA storage cannot reach ordinary heap release
or GC movement.

**External references:** [CWE-119][cwe-119]; [CWE-664][cwe-664].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badMmioDmaAsHeap(volatile uint32_t *register_ptr)
{
    int ret = EXIT_SUCCESS;

    free((void *)register_ptr);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-123"></a>

<a id="cpit-123-chained-pointer-dereference"></a>

### CPIT-123: Chained pointer dereference

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-122`][c-code-standard-cstyle-122]

**Chained pointer dereference.** A chain combines several validity checks in one expression. In
`(aux->prev)->next`, both `aux` and `aux->prev` may be invalid, while the intermediate pointer's
ownership and lifetime remain implicit. Named intermediates give debuggers, reviewers, and static
analysis a place to verify each precondition.

**External references:** [CWE-476][cwe-476]; [CWE-825][cwe-825].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badChainedPointerDereference(node_t *aux)
{
    int ret = EXIT_SUCCESS;

    if (aux != (node_t *)(NULL))
    {
        (aux->prev)->next = aux->next;
    }

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-124"></a>

<a id="cpit-124-stale-validity-after-a-mutating-call"></a>

### CPIT-124: Stale validity after a mutating call

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-123`][c-code-standard-cstyle-123]

**Stale validity after a mutating call.** A container mutation, ownership transfer, allocator
operation, or callback may release or relocate an object. A check made before that call no longer
proves the pointer valid afterward. Reacquire the object or rely on a callee contract that
explicitly preserves its address and lifetime.

**External references:** [CWE-416][cwe-416]; [CWE-825][cwe-825].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badStaleValidity(list_t *list, node_t *node)
{
    int ret = EXIT_SUCCESS;

    if (node != (node_t *)(NULL))
    {
        LIST_remove(list, node);
        node->flags = 0u;
    }

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-125"></a>

<a id="cpit-125-interleaved-mutation-through-aliases"></a>

### CPIT-125: Interleaved mutation through aliases

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-124`][c-code-standard-cstyle-124]

**Interleaved mutation through aliases.** Two pointers that may name the same object can turn
separate updates into one order-dependent state transition. This fault can duplicate increments,
overwrite a value derived moments earlier, or violate invariants that assumed distinct objects.
Prove the ranges do not overlap or mutate through one canonical pointer.

**External references:** [CWE-362][cwe-362]; [CWE-664][cwe-664].

#### Local examples

**Noncompliant fragment (do not copy):**

```c
int EX_badInterleavedAliasMutation(item_t *first, item_t *second)
{
    int ret = EXIT_SUCCESS;

    if ((first != (item_t *)(NULL)) &&
        (second != (item_t *)(NULL)))
    {
        first->value += 1u;
        second->value = first->value;
    }

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-128"></a>

<a id="cpit-128-flexible-array-capacity-mismatch"></a>

### CPIT-128: Flexible-array capacity mismatch

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-130`][c-code-standard-cstyle-130]

**Flexible-array capacity mismatch.** A flexible array member has no payload storage in
`sizeof(struct_type)`. If allocation size, recorded capacity, and copy length do not describe the
same allocation, an apparently valid index can write beyond the object. Keep the total allocation
size and payload capacity in one checked ownership contract.

**External references:** [CWE-131][cwe-131]; [CWE-787][cwe-787].

#### Local examples

**Failure fragment (do not execute):**

```c
packet_t *EX_badFlexibleArrayAllocation(size_t payload_capacity)
{
    packet_t *ret = (packet_t *)MEM_alloc(sizeof(*ret));

    if (ret != (packet_t *)(NULL))
    {
        ret->capacity = payload_capacity;
    }

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-132"></a>

<a id="cpit-132-pointer-size-mistaken-for-object-capacity"></a>

### CPIT-132: Pointer size mistaken for object capacity

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-136`][c-code-standard-cstyle-136]

**Pointer size mistaken for object capacity.** `sizeof(pointer)` reports the pointer representation
size, not the size of its allocation. Using that value as a copy, clear, comparison, or I/O bound
often processes only four or eight bytes and can leave stale data or weaken validation.

**External references:** [CWE-467][cwe-467].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badPointerSizeCapacity(uint8_t buffer[], size_t buffer_size)
{
    int ret = EXIT_SUCCESS;

    if ((buffer != (uint8_t *)(NULL)) &&
        (buffer_size > 0u))
    {
        memset(buffer, 0, sizeof(buffer));
    }

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-133"></a>

<a id="cpit-133-representation-zeroing-mistaken-for-semantic-initialization"></a>

### CPIT-133: Representation zeroing mistaken for semantic initialization

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-137`][c-code-standard-cstyle-137]

**Representation zeroing mistaken for semantic initialization.** `memset()` writes bytes; it does
not assign the C zero value to each member. An arbitrary typed object may contain pointers,
floating-point values, enums, padding, or a domain default whose representation is not
all-bits-zero. Use C initialization syntax or a type-specific reset function.

**External references:** [CWE-665][cwe-665].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badRepresentationInitialization(config_t *config)
{
    int ret = EXIT_SUCCESS;

    if (config != (config_t *)(NULL))
    {
        memset(config, 0, sizeof(*config));
    }

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-154-pool-allocated-object-escapes-its-scope"></a> <a id="cpit-154"></a>

<a id="cpit-154-pool-object-escape"></a>

### CPIT-154: Pool-allocated object escapes its scope

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CMOD-098`][c-module-architecture-cmod-098]

**Pool-allocated object escapes its scope.** A pointer allocated for one packet, request, frame,
file, phase, or arena is retained by state that survives bulk reclamation. The allocator releases
every object correctly, but the retained pointer becomes dangling. Name allocator scopes in API
contracts, prohibit cross-scope storage, and register cleanup for non-memory resources.

**External references:** [CWE-825][cwe-825].

#### Local examples

**Failure fragment (do not execute):**

The destination callback copies before the arena/pool reset; it does not retain `borrowed_bytes`. A
handle alternative must invalidate on reset.

```c
saved_pointer = arena_object;
arena_reset(arena_context);
consume(saved_pointer);
```

**Contextual prevention example:**

The destination callback copies before the arena/pool reset; it does not retain `borrowed_bytes`. A
handle alternative must invalidate on reset.

```c
ret = copy_owned(destination_context, borrowed_bytes, borrowed_size_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cpit-035"></a>

<a id="cpit-035-unsequenced-modification"></a>

### CPIT-035: Unsequenced modification

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Expressions such as `i = i++ + 1` or calls that modify the same scalar through multiple unsequenced
arguments do not have a defined result. This is not a precedence issue; it is an evaluation-order
issue. Split side effects into separate statements.

**Prevention controls:** [CSTYLE-061][c-code-standard-cstyle-061].

**Weakness context:** [CWE-758][cwe-758]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Compile sequencing diagnostics and inspect multiple modifications/accesses
within one expression.

**External references:** [CWE-758][cwe-758].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badUnsequencedModification(int value)
{
    int ret = EXIT_SUCCESS;

    ret = value++ + value;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use a language-defined representation/access pattern and validate every
precondition
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Depend on undefined/unspecified behavior and treat one compiler build as proof
of correctness
```

---

<a id="cpit-036"></a>

<a id="cpit-036-indeterminate-value-read"></a>

### CPIT-036: Indeterminate value read

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Automatic objects that are not initialized can contain indeterminate values. Reading them can be
undefined behavior, especially for pointer or trap-capable representations. Initialize every object
before first read and avoid using padding bytes as meaningful data.

**Prevention controls:** [CSTYLE-107][c-code-standard-cstyle-107].

**Weakness context:** [CWE-457][cwe-457], [CWE-758][cwe-758]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Review partial initialization paths and test output-state guarantees after
early failure.

**Source context:** [asan][c-common-pitfalls-ref-asan]; [ubsan][c-common-pitfalls-ref-ubsan].

**External references:** [CWE-457][cwe-457]; [CWE-758][cwe-758].

#### Local examples

**Noncompliant fragment (do not copy):**

```c
uint32_t EX_badIndeterminateValueRead(void)
{
    uint32_t ret;

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
config_t config = { 0 };
```

**Noncompliant fragment (do not copy):**

```c
config_t config;
consume(config.flags);
```

---

<a id="cpit-037"></a>

<a id="cpit-037-trap-representation"></a>

### CPIT-037: Trap representation

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Some object types and target representations cannot be populated safely by arbitrary bits. A byte
copy or memset does not necessarily construct a valid pointer, floating value, synchronization
object, or platform handle. Validate representations under the chosen C edition and target rather
than assuming every type has the same zero-bit semantics.

**Prevention controls:** [CSTYLE-100][c-code-standard-cstyle-100].

**Weakness context:** [CWE-758][cwe-758]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Reject arbitrary-byte construction of pointer/synchronization objects;
inspect target representation assumptions.

**Source context:** [c23][c-common-pitfalls-ref-c23].

**External references:** [CWE-758][cwe-758].

#### Local examples

**Failure fragment (do not execute):**

```c
uint32_t EX_badTrapRepresentation(uint8_t bytes[])
{
    uint32_t ret = 0u;
    uint32_t *value = (uint32_t *)bytes;

    ret = *value;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use a language-defined representation/access pattern and validate every
precondition
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Depend on undefined/unspecified behavior and treat one compiler build as proof
of correctness
```

---

<a id="cpit-038"></a>

<a id="cpit-038-signed-integer-overflow"></a>

### CPIT-038: Signed integer overflow

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Signed overflow is undefined behavior in C, not two's-complement wrap in portable code. Optimizers
may remove checks if they assume overflow cannot happen. Use checked arithmetic helpers before
computing sizes, indexes, offsets, counters, or protocol fields.

**Prevention controls:** [CSTYLE-101][c-code-standard-cstyle-101].

**Weakness context:** [CWE-190][cwe-190], [CWE-758][cwe-758]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Test exact signed limits and rejected overflows using a checked operation,
not an overflowing test expression.

**External references:** [CWE-190][cwe-190]; [CWE-758][cwe-758].

#### Local examples

**Failure fragment (do not execute):**

```c
int32_t EX_badSignedIntegerOverflow(int32_t value)
{
    int32_t ret = 0;

    ret = value + INT32_MAX;

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
has_overflow = ARITH_addSize(a, b, &result);
if (has_overflow)
        ret = -EOVERFLOW;
```

**Noncompliant fragment (do not copy):**

```c
result = a + b; /* wrap/truncation not checked */
```

---

<a id="cpit-039"></a>

<a id="cpit-039-invalid-shift"></a>

### CPIT-039: Invalid shift

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Shifting by a negative count or by a count greater than or equal to the promoted type width is
undefined behavior. Left shifting into an invalid signed value is also dangerous. Validate shift
counts and prefer unsigned operands with explicit masks.

**Prevention controls:** [CSTYLE-101][c-code-standard-cstyle-101].

**Weakness context:** [CWE-682][cwe-682], [CWE-758][cwe-758]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Test shift zero, width minus one, width, and negative input through the
checked domain.

**External references:** [CWE-682][cwe-682]; [CWE-758][cwe-758].

#### Local examples

**Failure fragment (do not execute):**

```c
uint32_t EX_badInvalidShift(uint32_t value, uint32_t shift)
{
    uint32_t ret = 0u;

    ret = value << shift;

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
if (shift < 32u)
        value = ((uint32_t)1U << shift);
```

**Noncompliant fragment (do not copy):**

```c
value = 1 << shift; /* signed/unbounded shift */
```

---

<a id="cpit-040"></a>

<a id="cpit-040-divide-overflow"></a>

### CPIT-040: Divide overflow

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

The mathematical quotient of the minimum signed value and negative one may not be representable.
Reject that case for both division and remainder before evaluation. This is separate from the
zero-divisor case; checking only the divisor against zero is insufficient.

**Prevention controls:** [CSTYLE-103][c-code-standard-cstyle-103].

**Weakness context:** [CWE-190][cwe-190], [CWE-369][cwe-369]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Require explicit handling of minimum-signed divided or reduced modulo
negative one.

**Source context:** [c23][c-common-pitfalls-ref-c23].

**External references:** [CWE-190][cwe-190]; [CWE-369][cwe-369].

#### Local examples

**Failure fragment (do not execute):**

```c
int32_t EX_badDivideOverflow(void)
{
    int32_t ret = 0;

    ret = INT32_MIN / -1;

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
has_overflow = ARITH_addSize(a, b, &result);
if (has_overflow)
        ret = -EOVERFLOW;
```

**Noncompliant fragment (do not copy):**

```c
result = a + b; /* wrap/truncation not checked */
```

---

<a id="cpit-041"></a>

<a id="cpit-041-invalid-effective-type-access"></a>

### CPIT-041: Invalid effective type access

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

C tracks the effective type of an object for aliasing and optimization. Reading storage through an
unrelated typed lvalue can break compiler assumptions. Use `memcpy()` for type re-interpretation and
keep serialized representations as bytes until decoded.

**Prevention controls:** [CSTYLE-100][c-code-standard-cstyle-100].

**Weakness context:** [CWE-843][cwe-843], [CWE-758][cwe-758]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Review allocator reuse/effective-type transitions, not only the spelling of
a pointer cast.

**External references:** [CWE-843][cwe-843]; [CWE-758][cwe-758].

#### Local examples

**Failure fragment (do not execute):**

```c
uint32_t EX_badInvalidEffectiveTypeAccess(float *value)
{
    uint32_t ret = 0u;

    ret = *((uint32_t *)value);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use a language-defined representation/access pattern and validate every
precondition
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Depend on undefined/unspecified behavior and treat one compiler build as proof
of correctness
```

---

<a id="cpit-042"></a>

<a id="cpit-042-vla-with-invalid-bound"></a>

### CPIT-042: VLA with invalid bound

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Variable-length arrays depend on runtime sizes. Zero, negative, huge, or tainted bounds can trigger
undefined behavior or stack exhaustion. Project code prohibits VLAs under `CSTYLE-108`; use checked
fixed buffers, explicit heap policy, or caller-provided storage.

**Prevention controls:** [CSTYLE-108][c-code-standard-cstyle-108].

**Weakness context:** [CWE-129][cwe-129], [CWE-789][cwe-789]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Reject VLA declarations at compilation and review stack bounds for fixed
arrays.

**External references:** [CWE-129][cwe-129]; [CWE-789][cwe-789].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badVlaWithInvalidBound(int32_t count)
{
    int ret = EXIT_SUCCESS;

    uint8_t buffer[count];

    buffer[0] = 0u;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use a language-defined representation/access pattern and validate every
precondition
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Depend on undefined/unspecified behavior and treat one compiler build as proof
of correctness
```

---

<a id="cpit-043"></a>

<a id="cpit-043-longjmp-into-dead-frame"></a>

### CPIT-043: `longjmp` into dead frame

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

`longjmp()` is only valid while the target `setjmp()` frame still exists. Jumping into a returned
frame corrupts control flow and stack lifetime. Avoid non-local jumps in project code unless a
narrow adapter owns the full lifetime protocol.

**Prevention controls:** [CSTYLE-053][c-code-standard-cstyle-053].

**Weakness context:** [CWE-758][cwe-758], [CWE-562][cwe-562]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Audit nonlocal jumps for a still-live destination frame; prohibit unsafe
cross-lifecycle jumps.

**External references:** [CWE-758][cwe-758]; [CWE-562][cwe-562].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badLongjmpIntoDeadFrame(jmp_buf jump_buffer)
{
    int ret = EXIT_SUCCESS;

    longjmp(jump_buffer, 1);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use a language-defined representation/access pattern and validate every
precondition
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Depend on undefined/unspecified behavior and treat one compiler build as proof
of correctness
```

---

<a id="cpit-044"></a>

<a id="cpit-044-modified-non-volatile-local-after-setjmp"></a>

### CPIT-044: Modified non-volatile local after `setjmp`

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

After `longjmp()`, local non-`volatile` variables modified after `setjmp()` have indeterminate
values. This surprises error-recovery code. Avoid relying on local state across
`setjmp()`/`longjmp()` or keep the state in an explicitly managed object.

**Prevention controls:** [CSTYLE-100][c-code-standard-cstyle-100].

**Weakness context:** [CWE-758][cwe-758]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Review automatic locals changed after setjmp and read after longjmp under
the selected language rules.

**External references:** [CWE-758][cwe-758].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badModifiedLocalAfterSetjmp(jmp_buf jump_buffer)
{
    int ret = EXIT_SUCCESS;
    int value = 0;

    if (setjmp(jump_buffer) != 0)
    {
        ret = value;
        goto function_output;
    }

    value = 10;
    longjmp(jump_buffer, 1);

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
value = atomic_load_explicit(&shared, memory_order_acquire);
```

**Noncompliant fragment (do not copy):**

```c
volatile bool ready; /* volatile used as thread synchronization */
```

---

<a id="cpit-045"></a>

<a id="cpit-045-recursive-unbounded-call-chain"></a>

### CPIT-045: Recursive unbounded call chain

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Recursion consumes stack per call and can be hard to bound under malformed input. In embedded and
certified software, stack depth must be reviewable. Prefer iterative algorithms or prove and test a
strict recursion bound.

**Prevention controls:** [CSTYLE-054][c-code-standard-cstyle-054].

**Weakness context:** [CWE-674][cwe-674], [CWE-835][cwe-835]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Prove a recursion depth bound where permitted; reject recursion in
hard-real-time core paths.

**External references:** [CWE-674][cwe-674]; [CWE-835][cwe-835].

#### Local examples

**Failure fragment (do not execute):**

```c
uint32_t EX_badRecursiveUnbounded(uint32_t value)
{
    uint32_t ret = 0u;

    ret = EX_badRecursiveUnbounded(value + 1u);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use a language-defined representation/access pattern and validate every
precondition
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Depend on undefined/unspecified behavior and treat one compiler build as proof
of correctness
```

---

<a id="cpit-046"></a>

<a id="cpit-046-infinite-loop-without-progress"></a>

### CPIT-046: Infinite loop without progress

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

An intentional loop must have an explicit progress, wait, watchdog, or shutdown condition. Otherwise
a single bad state can starve safety tasks or prevent fault handling. Document loop exit and
watchdog-service conditions.

**Prevention controls:** [CSTYLE-074][c-code-standard-cstyle-074],
[CSTYLE-102][c-code-standard-cstyle-102], [CSTYLE-103][c-code-standard-cstyle-103],
[CSTYLE-097][c-code-standard-cstyle-097], [CSTYLE-060][c-code-standard-cstyle-060],
[CSTYLE-106][c-code-standard-cstyle-106].

**Weakness context:** [CWE-835][cwe-835]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Show progress or an explicit bounded wait/shutdown protocol for each loop.

**External references:** [CWE-835][cwe-835].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badInfiniteLoopWithoutProgress(void)
{
    int ret = EXIT_SUCCESS;

    while (1)
    {
    }

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use a language-defined representation/access pattern and validate every
precondition
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Depend on undefined/unspecified behavior and treat one compiler build as proof
of correctness
```

---

<a id="cpit-129"></a>

<a id="cpit-129-variadic-argument-contract-mismatch"></a>

### CPIT-129: Variadic argument contract mismatch

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-132`][c-code-standard-cstyle-132]

**Variadic argument contract mismatch.** The `...` syntax carries no count or runtime type metadata.
If the caller and callee disagree about promotions, count, order, or ownership, `va_arg()` reads the
wrong representation or moves past the supplied arguments. Keep variadic access inside a
format-checked or otherwise controlled adapter.

**External references:** [CWE-686][cwe-686].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badVariadicCall(void)
{
    int ret = EXIT_SUCCESS;

    uint8_t *buffer = (uint8_t *)(NULL);

    EX_log("value=%u", buffer);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use a language-defined representation/access pattern and validate every
precondition
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Depend on undefined/unspecified behavior and treat one compiler build as proof
of correctness
```

---

<a id="cpit-130"></a>

<a id="cpit-130-control-flow-hidden-in-an-expression"></a>

### CPIT-130: Control flow hidden in an expression

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-133`][c-code-standard-cstyle-133]

**Related prevention rule:** [`CSTYLE-064`][c-code-standard-cstyle-064]

**Control flow hidden in an expression.** Nested conditional operators, the comma operator, and
direct return expressions can bury calls, mutation, and cleanup inside value computation. An early
return can also bypass the common status and cleanup path. Use branches and separate statements for
state changes, then return `ret` once at `function_output`.

**External references:** [CWE-768][cwe-768].

#### Local examples

**Failure fragment (do not execute):**

```c
result = is_ready ? EX_process() : (EX_cleanup(), -EINVAL);
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use a language-defined representation/access pattern and validate every
precondition
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Depend on undefined/unspecified behavior and treat one compiler build as proof
of correctness
```

---

<a id="cpit-134"></a>

<a id="cpit-134-function-arguments-depend-on-evaluation-order"></a>

### CPIT-134: Function arguments depend on evaluation order

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-116`][c-code-standard-cstyle-116]

**Function arguments depend on evaluation order.** C does not require ordinary function arguments to
run left-to-right. If two calls communicate through shared state, the result can change by compiler,
optimization level, or target. Evaluate each operation in a separate statement and pass stable
values.

**External references:** [CWE-758][cwe-758].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badArgumentEvaluationOrder(void)
{
    int ret = EXIT_SUCCESS;

    ret = EX_process(EX_getNextValue(), EX_getCurrentIndex());

function_output:
    return ret;
}
```

---

<a id="cpit-135"></a>

<a id="cpit-135-inactive-union-member-read"></a>

### CPIT-135: Inactive union member read

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-129`][c-code-standard-cstyle-129]

**Inactive union member read.** Writing one representation and reading another uses the union as an
implicit reinterpretation mechanism or violates a tagged alternative's active-member contract. Use
the explicit discriminator for semantic alternatives and `memcpy()` for representation bytes.

**External references:** [CWE-843][cwe-843].

#### Local examples

**Failure fragment (do not execute):**

```c
uint32_t EX_badInactiveUnionMember(float input)
{
    uint32_t ret = 0u;

    union ValueRepresentation
    {
        float floating;
        uint32_t bits;
    } value = { 0 };

    value.floating = input;
    ret = value.bits;

function_output:
    return ret;
}
```

---

<a id="cpit-136"></a>

<a id="cpit-136-semantic-object-copied-as-bytes"></a>

### CPIT-136: Semantic object copied as bytes

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-152`][c-code-standard-cstyle-152]

**Semantic object copied as bytes.** Whole-object assignment or `memcpy()` can duplicate owned
pointers, locks, reference counts, descriptors, callbacks, or intrusive links without duplicating
their resource and identity contracts. Use a named copy, clone, retain, move, or duplicate
operation.

**External references:** [CWE-664][cwe-664]; [CWE-843][cwe-843].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badSemanticObjectCopy(device_t *destination, const device_t *source)
{
    int ret = EXIT_SUCCESS;

    if ((destination == (device_t *)(NULL)) ||
        (source == (const device_t *)(NULL)))
    {
        ret = -EINVAL;
        goto function_output;
    }

    *destination = *source;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-137"></a>

<a id="cpit-137-discarded-const-qualification"></a>

### CPIT-137: Discarded `const` qualification

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-155`][c-code-standard-cstyle-155]

**Discarded `const` qualification.** A cast can suppress a diagnostic but cannot make a genuinely
const object writable. Mutation through the resulting pointer can violate an API contract or execute
undefined behavior. Correct the callee type or create a mutable copy.

**External references:** [CWE-704][cwe-704].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badDiscardConst(const config_t *config)
{
    int ret = EXIT_SUCCESS;

    config_t *mutable_config = (config_t *)(NULL);

    if (config == (const config_t *)(NULL))
    {
        ret = -EINVAL;
        goto function_output;
    }

    mutable_config = (config_t *)config;
    mutable_config->is_enabled = true;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-138"></a>

<a id="cpit-138-invalid-callback-invocation"></a>

### CPIT-138: Invalid callback invocation

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-147`][c-code-standard-cstyle-147]

**Invalid callback invocation.** An optional, stale, corrupted, or incompletely bound function
pointer can become an indirect call through an invalid address. Validate mandatory callbacks at
binding and nullable callbacks at the call boundary. [CVE-2025-11618][cve-2025-11618] provides
representative field evidence for a missing validation check leading to invalid pointer dereference.

**External references:** [CWE-476][cwe-476]; [CWE-825][cwe-825].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badCallbackInvocation(send_cb_t send, void *context)
{
    int ret = EXIT_SUCCESS;

    ret = send(context, (const uint8_t *)(NULL), 0u);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
create/bind rejects NULL mandatory callback; successful object invariant
guarantees callable target
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
module starts successfully with NULL required callback and crashes on first
invocation
```

---

<a id="cpit-139"></a>

<a id="cpit-139-string-literal-modification"></a>

### CPIT-139: String literal modification

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-144`][c-code-standard-cstyle-144]

**String literal modification.** C can accept a string literal initializer for a mutable character
pointer even though writing the literal has undefined behavior. Keep literal references
pointer-to-const or create a writable array.

**External references:** [CWE-758][cwe-758].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badStringLiteralModification(void)
{
    int ret = EXIT_SUCCESS;

    char *message = "failure";

    message[0] = 'F';

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-140"></a>

<a id="cpit-140-unproved-compiler-assumption"></a>

### CPIT-140: Unproved compiler assumption

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-150`][c-code-standard-cstyle-150]

**Unproved compiler assumption.** An unreachable or assume primitive tells the optimizer that a path
cannot occur. If external input can reach it, later code may lose validation or take arbitrary
optimized behavior instead of returning an error.

**External references:** [CWE-758][cwe-758].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badUnprovedAssumption(size_t length, size_t capacity)
{
    int ret = EXIT_SUCCESS;

    if (length > capacity)
    {
        COMPILER_UNREACHABLE__();
    }

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use a language-defined representation/access pattern and validate every
precondition
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Depend on undefined/unspecified behavior and treat one compiler build as proof
of correctness
```

---

<a id="cpit-141"></a>

<a id="cpit-141-untrusted-input-reaches-fatal-allocation"></a>

### CPIT-141: Untrusted input reaches fatal allocation

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-154`][c-code-standard-cstyle-154]

**Untrusted input reaches fatal allocation.** A fatal allocator turns an attacker-selected or
externally selected size into process termination or system reset. Bound the request and use a
recoverable allocator. [CVE-2026-49975][cve-2026-49975] records denial of service from excessive
allocation controlled by malicious HTTP requests.

**External references:** [CWE-770][cwe-770].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badFatalExternalAllocation(size_t requested_size)
{
    int ret = EXIT_SUCCESS;

    uint8_t *buffer = (uint8_t *)(NULL);

    buffer = (uint8_t *)MEM_allocOrTerminate(requested_size);
    MEM_free(buffer);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Boundary owner validates input and applies the destination-specific safe API
before side effects
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Untrusted or mutable external input flows directly into sensitive
API/configuration/artifact path
```

---

<a id="cpit-142"></a>

<a id="cpit-142-sequence-pointer-without-extent"></a>

### CPIT-142: Sequence pointer without extent

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-158`][c-code-standard-cstyle-158]

**Sequence pointer without extent.** Array parameter notation adjusts to a pointer and does not
communicate the caller's element count. The callee cannot prove that even a fixed-looking index
exists. Pass count, capacity, byte size, begin/end, or a documented compile-time extent.

**External references:** [CWE-119][cwe-119].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badSequenceExtent(const uint16_t samples[])
{
    int ret = EXIT_SUCCESS;

    if (samples == (const uint16_t *)(NULL))
    {
        ret = -EINVAL;
        goto function_output;
    }

    EX_consumeSample(samples[1]);

function_output:
    return ret;
}
```

---

<a id="cpit-143"></a>

<a id="cpit-143-partial-mutation-before-validation"></a>

### CPIT-143: Partial mutation before validation

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CMOD-090`][c-module-architecture-cmod-090]

**Partial mutation before validation.** An operation that changes visible state before checking a
rejectable precondition can return failure while leaving a counter, resource, persistent record, or
hardware state changed. Validate first or provide an explicit rollback transaction.

**External references:** [CWE-841][cwe-841].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badMutationBeforeValidation(state_t *state, const request_t *request)
{
    int ret = EXIT_SUCCESS;

    if ((state == (state_t *)(NULL)) ||
        (request == (const request_t *)(NULL)))
    {
        ret = -EINVAL;
        goto function_output;
    }

    state->accepted_count++;
    if (request->size > REQUEST_SIZE_MAX)
    {
        ret = -E2BIG;
        goto function_output;
    }

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Validate all rejectable preconditions, then commit state; if validation must
reserve resources, define rollback
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Increment counter/write state first, discover invalid request later, return
error with partial mutation left behind
```

---

<a id="cpit-144-logical-and-bitwise-operator-confusion"></a> <a id="cpit-144"></a>

<a id="cpit-144-logical-bitwise-operator-confusion"></a>

### CPIT-144: Logical and bitwise operator confusion

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-160`][c-code-standard-cstyle-160]

**Logical and bitwise operator confusion.** Bitwise operators evaluate integer representations and
both operands; logical operators produce predicate values and short-circuit. Substituting one family
for the other can call an unsafe operand or accept the wrong flag combination.

**External references:** [CWE-480][cwe-480].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badLogicalBitwiseMix(bool is_ready, bool is_enabled)
{
    int ret = EXIT_SUCCESS;

    if (is_ready & is_enabled)
    {
        ret = EX_start();
    }

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Hardware interaction goes through a platform-owned contract that documents
register/DMA/ISR timing and ordering
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Ordinary module accesses raw hardware state with undocumented timing,
coherency, or reserved-bit assumptions
```

---

<a id="cpit-145-boolean-collapses-a-multi-state-result"></a> <a id="cpit-145"></a>

<a id="cpit-145-boolean-collapses-multi-state-result"></a>

### CPIT-145: Boolean collapses a multi-state result

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-159`][c-code-standard-cstyle-159]

**Boolean collapses a multi-state result.** Converting a byte count, descriptor, status, or enum to
`bool` loses the distinction between success values and different failures. Preserve the original
domain and compare against its named result.

**External references:** [CWE-704][cwe-704].

#### Local examples

**Failure fragment (do not execute):**

```c
bool EX_badStatusAsBoolean(file_t *file, uint8_t *buffer, size_t capacity)
{
    bool ret = false;

    ret = FILE_read(file, buffer, capacity);

function_output:
    return ret;
}
```

---

<a id="cpit-146-inline-assembly-has-an-incomplete-machine-contract"></a> <a id="cpit-146"></a>

<a id="cpit-146-inline-assembly-incomplete-contract"></a>

### CPIT-146: Inline assembly has an incomplete machine contract

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-162`][c-code-standard-cstyle-162]

**Inline assembly has an incomplete machine contract.** The instructions appear correct in
isolation, but an omitted output, early clobber, condition code, memory effect, alignment
requirement, or ABI assumption lets the compiler move or reuse values incorrectly. Keep assembly in
a reviewed adapter and encode the complete compiler and machine contract.

**External references:** [CWE-758][cwe-758].

#### Local examples

**Failure fragment (do not execute):**

The platform adapter owns any assembly, clobbers, ABI, volatility and ordering; the core includes
only the declared public contract.

```c
/* Incorrect adapter contract: omitted memory effects are invisible. */
asm volatile("device_operation");
```

**Contextual prevention example:**

The platform adapter owns any assembly, clobbers, ABI, volatility and ordering; the core includes
only the declared public contract.

```c
int PLATFORM_readCounter(uint64_t *counter_out);
```

---

<a id="cpit-149-host-byte-order-leaks-into-an-external-representation"></a> <a id="cpit-149"></a>

<a id="cpit-149-host-byte-order-external-representation"></a>

### CPIT-149: Host byte order leaks into an external representation

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-166`][c-code-standard-cstyle-166]

**Host byte order leaks into an external representation.** A multi-byte integer is copied directly
to wire, disk, shared memory, DMA, or a register format, so the byte sequence changes across
targets. Specify external order, convert once at the owning boundary, and test byte-exact vectors on
both endian profiles.

**External references:** [CWE-198][cwe-198].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Hardware interaction goes through a platform-owned contract that documents
register/DMA/ISR timing and ordering
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Ordinary module accesses raw hardware state with undocumented timing,
coherency, or reserved-bit assumptions
```

---

<a id="cpit-150-unaligned-external-data-is-accessed-as-a-typed-object"></a> <a id="cpit-150"></a>

<a id="cpit-150-unaligned-external-typed-access"></a>

### CPIT-150: Unaligned external data is accessed as a typed object

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-167`][c-code-standard-cstyle-167]

**Unaligned external data is accessed as a typed object.** A byte offset is cast to a wider pointer
and dereferenced even though alignment, effective type, lifetime, and provenance were never
established. The operation can fault, be fixed up slowly, or produce target-specific results. Decode
through a byte-safe helper or `memcpy()` into a valid object.

**External references:** [CWE-758][cwe-758].

#### Local examples

**Failure fragment (do not execute):**

Include <string.h>. `native_value` is a uint32_t declared at entry; `source_bytes` has at least
sizeof(`native_value`) readable bytes. Decode the agreed byte order separately; `memcpy` fixes
alignment/aliasing access, not endianness.

```c
value = *((const uint32_t *)source_bytes);
```

**Contextual prevention example:**

Include <string.h>. `native_value` is a uint32_t declared at entry; `source_bytes` has at least
sizeof(`native_value`) readable bytes. Decode the agreed byte order separately; `memcpy` fixes
alignment/aliasing access, not endianness.

```c
memcpy(&native_value, source_bytes, sizeof(native_value));
```

---

<a id="cpit-160"></a>

<a id="cpit-160-lifecycle-verb-hides-the-real-object-transition"></a>

### CPIT-160: Lifecycle verb hides the real object transition

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-169`][c-code-standard-cstyle-169]

A caller treats `init`, `stop`, `reset`, or `set` according to the project lifecycle vocabulary, but
the implementation allocates, frees, replaces identity, or performs a wider mutation. Reviews miss
ownership changes because the name advertises a smaller operation.

**External references:** [CWE-664][cwe-664].

#### Local examples

**Noncompliant fragment (do not copy):**

```c
int DEVICE_stop(device_t **device); /* frees the object */
```

**Contextual prevention example:**

```c
int DEVICE_stop(device_t *device);

void DEVICE_destroy(device_t **device);
```

---

<a id="cpit-161"></a>

<a id="cpit-161-external-text-crosses-a-boundary-without-an-encoding-contract"></a>

### CPIT-161: External text crosses a boundary without an encoding contract

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-171`][c-code-standard-cstyle-171]

A parser receives bytes described only as text. Locale, platform code page, malformed UTF sequences,
normalization, or length-unit assumptions change how callers interpret the same input.
Security-sensitive identity comparisons can then disagree with display or storage behavior.

Noncompliant contract:

Prevention uses the same API shape with a documented UTF-8 and malformed-input contract under
`CSTYLE-171`.

**External references:** [CWE-176][cwe-176].

#### Local examples

**Noncompliant fragment (do not copy):**

```c
int CONFIG_parseName(
    const uint8_t *input,
    size_t input_bytes,
    text_view_t *name
); /* no encoding contract */
```

---

<a id="cpit-162"></a>

<a id="cpit-162-bidirectional-or-confusable-source-text-changes-review-meaning"></a>

### CPIT-162: Bidirectional or confusable source text changes review meaning

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-170`][c-code-standard-cstyle-170]

Raw Unicode bidirectional controls or visually confusable identifiers can make reviewers see a
different token order or identifier than the compiler reads. Keep identifiers ASCII and reject raw
bidi formatting controls in source.

**External references:** [CWE-838][cwe-838].

#### Local examples

**Noncompliant fragment (do not copy):**

```c
int \u03B1 = 0;
```

**Contextual prevention example:**

```c
int user_count = 0;
```

---

<a id="cpit-047"></a>

<a id="cpit-047-allocation-multiplication-overflow"></a>

### CPIT-047: Allocation multiplication overflow

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Allocation formulas such as `count * sizeof(*ptr)` can wrap to a smaller value than intended. The
allocator then returns a small buffer while later code writes `count` elements. Check the
multiplication before allocation.

**Prevention controls:** [CSTYLE-102][c-code-standard-cstyle-102].

**Weakness context:** [CWE-190][cwe-190], [CWE-131][cwe-131]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Multiply maximum element counts through a checked helper and preserve the
output on overflow.

**External references:** [CWE-190][cwe-190]; [CWE-131][cwe-131].

#### Local examples

**Failure fragment (do not execute):**

```c
void *EX_badAllocationMultiplicationOverflow(size_t count)
{
    void *ret = (void *)(NULL);

    ret = malloc(count * sizeof(uint32_t));

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
has_overflow = ARITH_addSize(a, b, &result);
if (has_overflow)
        ret = -EOVERFLOW;
```

**Noncompliant fragment (do not copy):**

```c
result = a + b; /* wrap/truncation not checked */
```

---

<a id="cpit-048"></a>

<a id="cpit-048-header-plus-payload-overflow"></a>

### CPIT-048: Header plus payload overflow

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Protocol and allocator objects often combine a fixed header with a variable payload. If
`header_size + payload_size` wraps, validation may accept a malicious or corrupt object. Check every
intermediate sum, not only the final allocation.

**Prevention controls:** [CSTYLE-102][c-code-standard-cstyle-102].

**Weakness context:** [CWE-190][cwe-190], [CWE-680][cwe-680]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Check header plus payload plus alignment costs before allocation and reject
exceeding the product budget.

**External references:** [CWE-190][cwe-190]; [CWE-680][cwe-680].

#### Local examples

**Failure fragment (do not execute):**

```c
size_t EX_badHeaderPlusPayloadOverflow(size_t header_size, size_t payload_size)
{
    size_t ret = 0u;

    ret = header_size + payload_size;

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
has_overflow = ARITH_addSize(a, b, &result);
if (has_overflow)
        ret = -EOVERFLOW;
```

**Noncompliant fragment (do not copy):**

```c
result = a + b; /* wrap/truncation not checked */
```

---

<a id="cpit-049"></a>

<a id="cpit-049-offset-plus-size-overflow"></a>

### CPIT-049: Offset plus size overflow

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Validating `offset + size <= capacity` is unsafe if the addition wraps first. This accepts slices
that extend beyond the object. Use checked addition or compare as `offset <= capacity` and
`size <= capacity - offset`.

**Prevention controls:** [CSTYLE-102][c-code-standard-cstyle-102].

**Weakness context:** [CWE-190][cwe-190], [CWE-787][cwe-787]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Check offset plus count against both arithmetic limits and actual capacity
before access.

**External references:** [CWE-190][cwe-190]; [CWE-787][cwe-787].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badOffsetPlusSizeOverflow(size_t offset, size_t size, size_t capacity)
{
    int ret = EXIT_SUCCESS;

    ret = ((offset + size) <= capacity);

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
has_overflow = ARITH_addSize(a, b, &result);
if (has_overflow)
        ret = -EOVERFLOW;
```

**Noncompliant fragment (do not copy):**

```c
result = a + b; /* wrap/truncation not checked */
```

---

<a id="cpit-050"></a>

<a id="cpit-050-alignment-rounding-overflow"></a>

### CPIT-050: Alignment rounding overflow

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Alignment helpers usually add `align - 1` before masking. That addition can overflow, and invalid
alignments such as zero or non-powers of two can corrupt the result. Validate alignment and use
checked addition before rounding.

**Prevention controls:** [CSTYLE-102][c-code-standard-cstyle-102].

**Weakness context:** [CWE-190][cwe-190], [CWE-682][cwe-682]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Test alignment rounding near SIZE_MAX and require power-of-two validation
if that algorithm assumes it.

**External references:** [CWE-190][cwe-190]; [CWE-682][cwe-682].

#### Local examples

**Failure fragment (do not execute):**

```c
size_t EX_badAlignmentRoundingOverflow(size_t size, size_t align)
{
    size_t ret = 0u;

    ret = (size + (align - 1u)) & ~(align - 1u);

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
alignas(foo_t) uint8_t storage[sizeof(foo_t)] = { 0 };
foo_t *foo                                    = (foo_t *)storage;
```

**Noncompliant fragment (do not copy):**

```c
foo_t *foo = (foo_t *)(storage + 1u);
```

---

<a id="cpit-051"></a>

<a id="cpit-051-division-by-zero"></a>

### CPIT-051: Division by zero

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Division and modulo require a non-zero divisor. Divisors derived from input, configuration, hardware
counters, or decoded metadata must be treated as untrusted. Validate before both `/` and `%`.

**Prevention controls:** [CSTYLE-103][c-code-standard-cstyle-103].

**Weakness context:** [CWE-369][cwe-369]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Reject zero before both division and modulo, including externally computed
divisors.

**External references:** [CWE-369][cwe-369].

#### Local examples

**Failure fragment (do not execute):**

```c
int32_t EX_badDivisionByZero(int32_t dividend, int32_t divisor)
{
    int32_t ret = 0;

    ret = dividend / divisor;

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
if (divisor == 0)
{
        ret = -EINVAL;
        goto function_output;
}

result = value / divisor;
```

**Noncompliant fragment (do not copy):**

```c
result = value / divisor; /* divisor may be zero */
```

---

<a id="cpit-052"></a>

<a id="cpit-052-narrowing-conversion"></a>

### CPIT-052: Narrowing conversion

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Narrowing converts a value into a type that may not represent it. This can silently truncate
lengths, file offsets, enum values, or hardware register fields. Check lower and upper bounds before
the cast.

**Prevention controls:** [CSTYLE-097][c-code-standard-cstyle-097].

**Weakness context:** [CWE-681][cwe-681], [CWE-197][cwe-197]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Reject below-minimum and above-maximum values before narrowing; preserve
semantic units.

**External references:** [CWE-681][cwe-681]; [CWE-197][cwe-197].

#### Local examples

**Failure fragment (do not execute):**

```c
uint16_t EX_badNarrowingConversion(uint32_t value)
{
    uint16_t ret = 0u;

    ret = (uint16_t)value;

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
if ((index >= 0) && ((size_t)index < count))
        value = array[(size_t)index];
```

**Noncompliant fragment (do not copy):**

```c
if (index < count)
{
    value = array[index]; /* signed/unsigned domain mixed */
}
```

---

<a id="cpit-053-signedunsigned-mixing"></a> <a id="cpit-053"></a>

<a id="cpit-053-signed-unsigned-mixing"></a>

### CPIT-053: Signed/unsigned mixing

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Mixing signed and unsigned values can convert a negative value into a very large unsigned value.
This affects comparisons, loop termination, and bounds checks. Normalize values to a single checked
domain before comparing or doing arithmetic.

**Prevention controls:** [CSTYLE-097][c-code-standard-cstyle-097].

**Weakness context:** [CWE-195][cwe-195], [CWE-681][cwe-681]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Test negative signed inputs before conversion and comparisons around the
signed/unsigned boundary.

**External references:** [CWE-195][cwe-195]; [CWE-681][cwe-681].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badSignedUnsignedMixing(int32_t value, uint32_t limit)
{
    int ret = EXIT_SUCCESS;

    ret = (value < limit);

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
if ((index >= 0) && ((size_t)index < count))
        value = array[(size_t)index];
```

**Noncompliant fragment (do not copy):**

```c
if (index < count)
{
    value = array[index]; /* signed/unsigned domain mixed */
}
```

---

<a id="cpit-054"></a>

<a id="cpit-054-enum-conversion-out-of-range"></a>

### CPIT-054: Enum conversion out of range

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Casting an integer to an enum does not prove the value is one of the defined enumerators. It can
index jump tables, state tables, or policy arrays out of range. Check the raw integer against the
enum range before casting.

**Prevention controls:** [CSTYLE-060][c-code-standard-cstyle-060].

**Weakness context:** [CWE-704][cwe-704], [CWE-129][cwe-129]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Reject enum sentinels, gaps, unknown bits, and out-of-domain integer
inputs.

**External references:** [CWE-704][cwe-704]; [CWE-129][cwe-129].

#### Local examples

**Failure fragment (do not execute):**

```c
ex_state_t EX_badEnumConversionOutOfRange(int32_t raw_value)
{
    ex_state_t ret = EX_STATE_DEFAULT;

    ret = (ex_state_t)raw_value;

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
if ((index >= 0) && ((size_t)index < count))
        value = array[(size_t)index];
```

**Noncompliant fragment (do not copy):**

```c
if (index < count)
{
    value = array[index]; /* signed/unsigned domain mixed */
}
```

---

<a id="cpit-055"></a>

<a id="cpit-055-floating-point-in-core-allocator"></a>

### CPIT-055: Floating-point in core allocator

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Floating point for allocator addresses or sizes conflicts with this project's exact-integer
invariant policy. Floating point is not by itself a vulnerability or undefined behavior, so this
entry has no automatic CWE equivalence. Review precision, range, rounding, runtime dependencies, and
reproducibility if a non-core analysis tool uses it.

**Prevention controls:** [CSTYLE-106][c-code-standard-cstyle-106],
[CSTYLE-086][c-code-standard-cstyle-086], [CSTYLE-058][c-code-standard-cstyle-058],
[CSTYLE-087][c-code-standard-cstyle-087], [CSTYLE-068][c-code-standard-cstyle-068],
[CSTYLE-097][c-code-standard-cstyle-097], [CSTYLE-059][c-code-standard-cstyle-059],
[CSTYLE-066][c-code-standard-cstyle-066].

**Weakness context:** No automatic CWE equivalence; allocator-core project restriction.

**Verification design:** Audit allocator layout/sizing code for floating operations and keep allowed
analysis tools outside the core.

**External references:** [C language contract][wg14-n3096-late-c23-working-draft].

#### Local examples

**Failure fragment (do not execute):**

```c
size_t EX_badFloatingPointInAllocator(double count)
{
    size_t ret = 0u;

    ret = (size_t)(count * 16.0);

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
if ((index >= 0) && ((size_t)index < count))
        value = array[(size_t)index];
```

**Noncompliant fragment (do not copy):**

```c
if (index < count)
{
    value = array[index]; /* signed/unsigned domain mixed */
}
```

---

<a id="cpit-127"></a>

<a id="cpit-127-plain-char-used-as-binary-numeric-storage"></a>

### CPIT-127: Plain `char` used as binary numeric storage

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-128`][c-code-standard-cstyle-128]

**Plain `char` used as binary numeric storage.** An implementation decides whether plain `char` is
signed. A byte above the positive signed range can therefore become negative and change promotion,
comparison, indexing, or shift behavior across targets. Use a type with an explicit signed or
unsigned interpretation and domain.

**External references:** [CWE-704][cwe-704]; [CWE-681][cwe-681].

#### Local examples

**Failure fragment (do not execute):**

```c
bool EX_badChecksumMatch(char checksum, uint8_t expected)
{
    bool ret = false;

    ret = (checksum == expected);

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
if ((index >= 0) && ((size_t)index < count))
        value = array[(size_t)index];
```

**Noncompliant fragment (do not copy):**

```c
if (index < count)
{
    value = array[index]; /* signed/unsigned domain mixed */
}
```

---

<a id="cpit-056"></a>

<a id="cpit-056-memcpy-with-overlap"></a>

### CPIT-056: `memcpy` with overlap

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

`memcpy()` requires non-overlapping ranges. If the source and destination overlap, behavior is
undefined and may depend on copy direction or optimization. Use `memmove()` when overlap is
possible.

**Prevention controls:** [CSTYLE-086][c-code-standard-cstyle-086].

**Weakness context:** [CWE-475][cwe-475], [CWE-758][cwe-758]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Establish non-overlapping ranges for `memcpy` or use a defined overlapping
move with validated bounds.

**External references:** [CWE-475][cwe-475]; [CWE-758][cwe-758].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badMemcpyWithOverlap(uint8_t buffer[])
{
    int ret = EXIT_SUCCESS;

    memcpy(buffer + 1u, buffer, 8u);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use the project wrapper that carries capacity/error/ownership semantics and
check its result
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Call a reviewed/banned libc API directly without satisfying its preconditions
```

---

<a id="cpit-057-memcpymemset-invalid-pointer"></a> <a id="cpit-057"></a>

<a id="cpit-057-memcpy-memset-invalid-pointer"></a>

### CPIT-057: `memcpy`/`memset` invalid pointer

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

A byte-library call still requires the pointers, ranges, and lifetime required by its contract. A
zero length must not be used as a universal excuse to pass an invalid pointer. The project handles
supported empty/NULL operations before calling libc and never forms a pointer beyond its valid
object range.

**Prevention controls:** [CSTYLE-058][c-code-standard-cstyle-058].

**Weakness context:** [CWE-476][cwe-476], [CWE-787][cwe-787]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Test supported empty/NULL operations without reaching a libc call with
invalid pointers.

**Source context:** [c23][c-common-pitfalls-ref-c23].

**External references:** [CWE-476][cwe-476]; [CWE-787][cwe-787].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badMemcpyInvalidPointer(void)
{
    int ret = EXIT_SUCCESS;

    memcpy(NULL, "abc", 3u);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use the project wrapper that carries capacity/error/ownership semantics and
check its result
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Call a reviewed/banned libc API directly without satisfying its preconditions
```

---

<a id="cpit-058"></a>

<a id="cpit-058-strlen-on-unterminated-data"></a>

### CPIT-058: `strlen` on unterminated data

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

`strlen()` searches until a NUL byte, so it is unsafe for fixed-size data that may not be
terminated. It can scan past the object and disclose or fault on adjacent memory. Track string
length explicitly or use bounded scanning wrappers.

**Prevention controls:** [CSTYLE-087][c-code-standard-cstyle-087].

**Weakness context:** [CWE-126][cwe-126], [CWE-125][cwe-125]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Feed nonterminated bounded data and require tracked-length handling rather
than unbounded scanning.

**External references:** [CWE-126][cwe-126]; [CWE-125][cwe-125].

#### Local examples

**Failure fragment (do not execute):**

```c
size_t EX_badStrlenUnterminated(void)
{
    char buffer[3] = { 'a', 'b', 'c' };
    size_t ret = 0u;

    ret = strlen(buffer);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use the project wrapper that carries capacity/error/ownership semantics and
check its result
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Call a reviewed/banned libc API directly without satisfying its preconditions
```

---

<a id="cpit-059-strcpystrcat-unbounded-copy"></a> <a id="cpit-059"></a>

<a id="cpit-059-strcpy-strcat-unbounded-copy"></a>

### CPIT-059: `strcpy`/`strcat` unbounded copy

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

These functions do not know the destination capacity. They are almost always wrong at trust
boundaries and in embedded code. Use checked formatting or bounded copy wrappers that report
truncation.

**Prevention controls:** [CSTYLE-086][c-code-standard-cstyle-086].

**Weakness context:** [CWE-120][cwe-120], [CWE-787][cwe-787]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Reject unbounded copy calls by API policy and test bounded replacement
capacities.

**External references:** [CWE-120][cwe-120]; [CWE-787][cwe-787]; [CAPEC-100][capec-100].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badStrcpyUnbounded(char dst[], const char src[])
{
    int ret = EXIT_SUCCESS;

    strcpy(dst, src);

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
written = snprintf(dst, dst_capacity, "%s", src);
if ((written < 0) || ((size_t)written >= dst_capacity))
        ret = -ENOSPC;
```

**Noncompliant fragment (do not copy):**

```c
strcpy(dst, src);
```

---

<a id="cpit-060"></a>

<a id="cpit-060-strncpy-missing-nul"></a>

### CPIT-060: `strncpy` missing NUL

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

`strncpy()` is often mistaken for a safe string copy, but it may leave the destination unterminated.
It also pads with zeros in ways that can be inefficient or misleading. Prefer explicit bounded
string helpers with termination guarantees.

**Prevention controls:** [CSTYLE-087][c-code-standard-cstyle-087].

**Weakness context:** [CWE-170][cwe-170]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Test source lengths equal to and greater than destination capacity and
require explicit termination policy.

**External references:** [CWE-170][cwe-170].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badStrncpyMissingNul(char dst[], const char src[])
{
    int ret = EXIT_SUCCESS;

    strncpy(dst, src, 4u);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use the project wrapper that carries capacity/error/ownership semantics and
check its result
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Call a reviewed/banned libc API directly without satisfying its preconditions
```

---

<a id="cpit-061"></a>

<a id="cpit-061-printf-external-format-string"></a>

### CPIT-061: `printf` external format string

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

A format string is executable parsing metadata, not plain text. If external input controls it, `%n`,
width fields, or type mismatches can corrupt memory or leak data. Always pass external strings
through `"%s"` or a literal format.

**Prevention controls:** [CSTYLE-068][c-code-standard-cstyle-068].

**Weakness context:** [CWE-134][cwe-134]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Pass percent directives as data to a fixed-format logger, never as its
format string.

**External references:** [CWE-134][cwe-134]; [CAPEC-135][capec-135]; [OWASP prevention
guidance][owasp-input-validation].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badPrintfExternalFormat(const char user_input[])
{
    int ret = EXIT_SUCCESS;

    printf(user_input);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use the project wrapper that carries capacity/error/ownership semantics and
check its result
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Call a reviewed/banned libc API directly without satisfying its preconditions
```

---

<a id="cpit-062-printfs-null"></a> <a id="cpit-062"></a>

<a id="cpit-062-printf-s-null"></a>

### CPIT-062: `printf("%s", NULL)`

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

The `%s` conversion expects a valid pointer to a NUL-terminated string. Passing `NULL` is not
portable and may crash even if one libc prints `(null)`. Normalize nullable strings before
formatting.

**Prevention controls:** [CSTYLE-068][c-code-standard-cstyle-068].

**Weakness context:** [CWE-476][cwe-476], [CWE-758][cwe-758]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Model absent strings explicitly and ensure NULL never reaches a percent-s
conversion.

**External references:** [CWE-476][cwe-476]; [CWE-758][cwe-758].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badPrintfNullString(void)
{
    int ret = EXIT_SUCCESS;

    printf("%s", NULL);

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
if (ptr == (object_t *)(NULL))
{
        ret = -EINVAL;
        goto function_output;
}

value = ptr->value;
```

**Noncompliant fragment (do not copy):**

```c
value = ptr->value; /* ptr may be NULL */
```

---

<a id="cpit-063-ctypeh-negative-char"></a> <a id="cpit-063"></a>

<a id="cpit-063-ctype-h-negative-char"></a>

### CPIT-063: `ctype.h` negative `char`

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

The ctype argument must be EOF or representable as unsigned char. A negative plain char value can
violate that domain. Convert a byte value through unsigned char before promotion, but preserve a
real EOF sentinel when processing input functions. ASCII protocol parsing is a separate explicit
representation policy.

**Prevention controls:** [CSTYLE-097][c-code-standard-cstyle-097].

**Weakness context:** [CWE-758][cwe-758]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Test all byte values through the valid ctype domain and preserve EOF
handling separately.

**Source context:** [c23][c-common-pitfalls-ref-c23].

**External references:** [CWE-758][cwe-758].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badCtypeNegativeChar(char value)
{
    int ret = EXIT_SUCCESS;

    ret = isalpha(value);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use the project wrapper that carries capacity/error/ownership semantics and
check its result
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Call a reviewed/banned libc API directly without satisfying its preconditions
```

---

<a id="cpit-064"></a>

<a id="cpit-064-atoi-silent-parse-failure"></a>

### CPIT-064: `atoi` silent parse failure

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

`atoi()` provides no reliable error reporting for invalid input or overflow. This is unacceptable
for sizes, counts, IDs, and configuration. Use `strtol()`-style APIs with end-pointer and range
checks.

**Prevention controls:** [CSTYLE-086][c-code-standard-cstyle-086].

**Weakness context:** [CWE-190][cwe-190], [CWE-20][cwe-20]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Reject empty, signed, trailing-garbage, and overflowing decimal inputs with
an explicit result status.

**External references:** [CWE-190][cwe-190]; [CWE-20][cwe-20].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badAtoiSilentParseFailure(const char text[])
{
    int ret = EXIT_SUCCESS;

    ret = atoi(text);

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
ret = PARSE_u32(input, &value);
```

**Noncompliant fragment (do not copy):**

```c
value = (uint32_t)atoi(input);
```

---

<a id="cpit-065"></a>

<a id="cpit-065-rand-for-security"></a>

### CPIT-065: `rand` for security

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

`rand()` is predictable and usually not suitable for tokens, nonces, keys, challenges, or randomized
defenses. Use platform-approved cryptographic random sources behind a wrapper.

**Prevention controls:** [CSTYLE-086][c-code-standard-cstyle-086].

**Weakness context:** [CWE-338][cwe-338]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Review the entropy source, failure policy, and primitive selected for
security tokens.

**External references:** [CWE-338][cwe-338]; [CAPEC-97][capec-97]; [OWASP prevention
guidance][owasp-cryptographic-storage].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badRandForSecurity(void)
{
    int ret = EXIT_SUCCESS;

    ret = rand();

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use the project wrapper that carries capacity/error/ownership semantics and
check its result
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Call a reviewed/banned libc API directly without satisfying its preconditions
```

---

<a id="cpit-066-tmpnammktemp"></a> <a id="cpit-066"></a>

<a id="cpit-066-tmpnam-mktemp"></a>

### CPIT-066: `tmpnam`/`mktemp`

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Name-generation APIs can create race windows where an attacker or another process creates the file
first. Use APIs that atomically create the file with safe permissions.

**Prevention controls:** [CSTYLE-086][c-code-standard-cstyle-086].

**Weakness context:** [CWE-377][cwe-377]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Require atomic exclusive temporary creation with appropriate permissions;
do not separate name choice from creation.

**External references:** [CWE-377][cwe-377]; [CAPEC-29][capec-29].

#### Local examples

**Failure fragment (do not execute):**

```c
char *EX_badTmpnam(char path[])
{
    char *ret = (char *)(NULL);

    ret = tmpnam(path);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use the project wrapper that carries capacity/error/ownership semantics and
check its result
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Call a reviewed/banned libc API directly without satisfying its preconditions
```

---

<a id="cpit-067"></a>

<a id="cpit-067-system-with-external-input"></a>

### CPIT-067: `system` with external input

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Shell execution turns data into commands. Quoting mistakes become command injection, especially with
filenames, device names, network values, and environment variables. Avoid `system()` in runtime
code; use explicit process APIs only behind reviewed wrappers.

**Prevention controls:** [CSTYLE-059][c-code-standard-cstyle-059].

**Weakness context:** [CWE-78][cwe-78]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Prove untrusted values cannot become shell syntax; test argument boundaries
through the chosen process API.

**Source context:** [validation][c-common-pitfalls-ref-validation].

**External references:** [CWE-78][cwe-78]; [CAPEC-88][capec-88]; [OWASP prevention
guidance][owasp-os-command-injection-defense].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badSystemExternalInput(const char command[])
{
    int ret = EXIT_SUCCESS;

    system(command);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use the project wrapper that carries capacity/error/ownership semantics and
check its result
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Call a reviewed/banned libc API directly without satisfying its preconditions
```

---

<a id="cpit-068"></a>

<a id="cpit-068-ignored-return-value"></a>

### CPIT-068: Ignored return value

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Many C library calls signal failure only through a return value or `errno`. Ignoring it turns
recoverable errors into silent data loss, partial writes, lock failures, or invalid state. Check
every meaningful return value and document intentional ignores.

**Prevention controls:** [CSTYLE-066][c-code-standard-cstyle-066],
[CSTYLE-092][c-code-standard-cstyle-092], [CSTYLE-091][c-code-standard-cstyle-091],
[CSTYLE-089][c-code-standard-cstyle-089], [CSTYLE-094][c-code-standard-cstyle-094],
[CSTYLE-095][c-code-standard-cstyle-095], [CSTYLE-102][c-code-standard-cstyle-102],
[CSTYLE-074][c-code-standard-cstyle-074].

**Weakness context:** [CWE-252][cwe-252], [CWE-391][cwe-391]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Inject each documented failure and require outputs/cleanup/state to follow
the contract.

**External references:** [CWE-252][cwe-252]; [CWE-391][cwe-391].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badIgnoredReturnValue(FILE *file, const void *buffer)
{
    int ret = EXIT_SUCCESS;

    fwrite(buffer, 1u, 16u, file);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use the project wrapper that carries capacity/error/ownership semantics and
check its result
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Call a reviewed/banned libc API directly without satisfying its preconditions
```

---

<a id="cpit-131"></a>

<a id="cpit-131-stale-or-overwritten-errno"></a>

### CPIT-131: Stale or overwritten `errno`

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-135`][c-code-standard-cstyle-135]

**Stale or overwritten `errno`.** A successful library call need not clear `errno`, and a later call
may replace the value from an earlier failure. Reading it without checking the documented failure
result can report an old or unrelated error. Capture it immediately after confirmed failure, then
convert the saved value at the boundary.

**External references:** [CWE-391][cwe-391].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badErrnoHandling(const char path[])
{
    int ret = EXIT_SUCCESS;
    int remove_result = 0;

    remove_result = remove(path);
    if (remove_result != 0)
    {
        LOG_error("remove failed");
        ret = -errno;
        goto function_output;
    }

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use the project wrapper that carries capacity/error/ownership semantics and
check its result
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Call a reviewed/banned libc API directly without satisfying its preconditions
```

---

<a id="cpit-147-partial-io-is-treated-as-complete"></a> <a id="cpit-147"></a>

<a id="cpit-147-partial-io-treated-as-complete"></a>

### CPIT-147: Partial I/O is treated as complete

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-163`][c-code-standard-cstyle-163]

**Partial I/O is treated as complete.** A positive result is accepted as proof that the requested
record, packet, file range, or output buffer was transferred. The remaining bytes are silently
discarded or stale bytes are consumed. Track reported progress, remaining extent, EOF, readiness,
and the operation's exact completion contract.

**External references:** [CWE-252][cwe-252].

#### Local examples

**Failure fragment (do not execute):**

Entry-declared counters and ret; caller provides `requested_bytes` writable storage. The injected
`read_part` retries EINTR according to a bounded deadline and never writes past its supplied
capacity. `completed_bytes` remains available to report partial progress on error.

```c
ret = read_part(io_context, buffer, requested_bytes, &received_bytes);
completed_bytes = requested_bytes;
```

**Contextual prevention example:**

Entry-declared counters and ret; caller provides `requested_bytes` writable storage. The injected
`read_part` retries EINTR according to a bounded deadline and never writes past its supplied
capacity. `completed_bytes` remains available to report partial progress on error.

```c
while (completed_bytes < requested_bytes)
{
        ret = read_part(io_context, buffer + completed_bytes,
                        requested_bytes - completed_bytes, &received_bytes);
        if (ret != EXIT_SUCCESS)
                goto function_output;
        if (received_bytes == 0u)
        {
                ret = -EIO;
                goto function_output;
        }

        if (received_bytes > requested_bytes - completed_bytes)
        {
                ret = -EOVERFLOW;
                goto function_output;
        }

        completed_bytes += received_bytes;
}
```

---

<a id="cpit-148-interrupted-io-loses-progress-or-retry-policy"></a> <a id="cpit-148"></a>

<a id="cpit-148-interrupted-io-retry-policy"></a>

### CPIT-148: Interrupted I/O loses progress or retry policy

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-163`][c-code-standard-cstyle-163]

**Interrupted I/O loses progress or retry policy.** Code retries blindly after `EINTR`, duplicates
bytes already reported, abandons a permitted retry, or spins after cancellation or deadline expiry.
Keep retry and progress semantics inside the owning I/O adapter and test interruption before and
after partial progress.

**External references:** [CWE-755][cwe-755].

#### Local examples

**Failure fragment (do not execute):**

Entry-declared counters and ret; caller provides `requested_bytes` writable storage. The injected
`read_part` retries EINTR according to a bounded deadline and never writes past its supplied
capacity. `completed_bytes` remains available to report partial progress on error.

```c
/* Retries from the beginning discard already completed progress. */
completed_bytes = 0u;
ret = read_part(io_context, buffer, requested_bytes, &received_bytes);
```

**Contextual prevention example:**

Entry-declared counters and ret; caller provides `requested_bytes` writable storage. The injected
`read_part` retries EINTR according to a bounded deadline and never writes past its supplied
capacity. `completed_bytes` remains available to report partial progress on error.

```c
while (completed_bytes < requested_bytes)
{
        ret = read_part(io_context, buffer + completed_bytes,
                        requested_bytes - completed_bytes, &received_bytes);
        if (ret != EXIT_SUCCESS)
                goto function_output;
        if (received_bytes == 0u)
        {
                ret = -EIO;
                goto function_output;
        }

        if (received_bytes > requested_bytes - completed_bytes)
        {
                ret = -EOVERFLOW;
                goto function_output;
        }

        completed_bytes += received_bytes;
}
```

---

<a id="cpit-153-counted-data-is-treated-as-a-nul-terminated-string"></a> <a id="cpit-153"></a>

<a id="cpit-153-counted-data-treated-as-c-string"></a>

### CPIT-153: Counted data is treated as a NUL-terminated string

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-165`][c-code-standard-cstyle-165]

**Counted data is treated as a NUL-terminated string.** A parser or protocol provides a pointer and
exact extent, but a later call scans for a terminator that the contract never promised. The scan can
cross the captured object or truncate valid embedded-NUL data. Preserve the view contract or perform
a checked copy to a terminated destination.

**External references:** [CWE-170][cwe-170]; [CWE-125][cwe-125].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-168"></a>

<a id="cpit-168-descriptor-or-handle-leaks-across-an-execution-boundary"></a>

### CPIT-168: Descriptor or handle leaks across an execution boundary

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-172`][c-code-standard-cstyle-172]

A process creates a descriptor or handle as inheritable, then tries to clear the inheritance flag in
a later operation. Another thread can spawn or fork+exec in the gap and leak the resource into the
child.

Noncompliant sequence:

Prevention creates the descriptor with the platform's atomic non-inheritance flag, such as
`O_CLOEXEC`, inside the platform adapter.

**External references:** [CWE-403][cwe-403].

#### Local examples

**Noncompliant fragment (do not copy):**

```c
fd = open(path, O_RDONLY);
if (fd < 0)
{
    ret = PLATFORM_errorFromErrno(errno);
    goto function_output;
}

flags = fcntl(fd, F_GETFD);
if (flags < 0)
{
    ret = PLATFORM_errorFromErrno(errno);
    goto function_output;
}

ret = fcntl(fd, F_SETFD, flags | FD_CLOEXEC);

function_output:
    return ret;
```

---

<a id="cpit-069"></a>

<a id="cpit-069-data-race"></a>

### CPIT-069: Data race

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

A data race happens when concurrent contexts access shared state without a valid synchronization
relationship and at least one access writes. The result is undefined or target-dependent behavior,
not merely "last writer wins." Protect shared objects with mutexes, atomics, critical sections, or
single-owner message passing.

**Prevention controls:** [CSTYLE-092][c-code-standard-cstyle-092].

**Weakness context:** [CWE-362][cwe-362], [CWE-366][cwe-366]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Document happens-before for every conflicting access and apply race
detection plus protocol review.

**External references:** [CWE-362][cwe-362]; [CWE-366][cwe-366].

#### Local examples

**Failure fragment (do not execute):**

```c
static uint32_t g_shared_counter;

int EX_badDataRace(void)
{
    int ret = EXIT_SUCCESS;

    g_shared_counter++;

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
LOCK_lock(&state->lock);
state->value = new_value;
LOCK_unlock(&state->lock);
```

**Noncompliant fragment (do not copy):**

```c
state->value = new_value; /* concurrent writer/readers unsynchronized */
```

---

<a id="cpit-070"></a>

<a id="cpit-070-improper-locking"></a>

### CPIT-070: Improper locking

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Improper locking includes missing locks, locking the wrong object, unlocking from the wrong owner,
or protecting only some accesses. It creates code that appears synchronized while still racing.
Document the protected object set for every lock.

**Prevention controls:** [CSTYLE-092][c-code-standard-cstyle-092].

**Weakness context:** [CWE-667][cwe-667]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Verify every access to protected state holds the required lock or uses the
proved atomic protocol.

**External references:** [CWE-667][cwe-667].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badImproperLocking(void)
{
    int ret = EXIT_SUCCESS;

    g_shared_counter++;
    pthread_mutex_unlock(&g_mutex);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Shared object has one documented lock/atomic protocol and every access follows
it
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
One path mutates protected state without the required lock, or uses a
different lock for the same invariant
```

---

<a id="cpit-071"></a>

<a id="cpit-071-deadlock"></a>

### CPIT-071: Deadlock

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Deadlock occurs when tasks wait forever for resources held by each other. Nested locks, callbacks
under lock, and inconsistent lock ordering are common causes. Define lock order, avoid external
calls while locked, and test shutdown/error paths.

**Prevention controls:** [CSTYLE-092][c-code-standard-cstyle-092].

**Weakness context:** [CWE-833][cwe-833]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Check lock acquisition graph for cycles and include callback/reentrant
paths.

**External references:** [CWE-833][cwe-833].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badDeadlock(void)
{
    int ret = EXIT_SUCCESS;

    pthread_mutex_lock(&g_mutex);
    pthread_mutex_lock(&g_other_mutex);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Acquire locks in documented global order: A then B on every path
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Thread 1 acquires A->B while thread 2 acquires B->A
```

---

<a id="cpit-072"></a>

<a id="cpit-072-spurious-wakeup-bug"></a>

### CPIT-072: Spurious wakeup bug

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Condition-variable waits can wake without the condition being true. Code that uses `if` instead of
`while` may consume missing data or continue in an invalid state. Always re-check the predicate in a
loop while the mutex is held.

**Prevention controls:** [CSTYLE-092][c-code-standard-cstyle-092].

**Weakness context:** [CWE-667][cwe-667]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Wake a waiting thread without satisfying its predicate; it must keep
waiting or honor shutdown.

**External references:** [CWE-667][cwe-667].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badSpuriousWakeupBug(void)
{
    int ret = EXIT_SUCCESS;

    if (g_is_ready == 0)
    {
        pthread_cond_wait(&g_cond, &g_mutex);
    }

function_output:
    return ret;
}
```

**Failure fragment (do not execute):**

```c
int EX_badSpuriousWakeupBug(void)
{
    int ret = EXIT_SUCCESS;

    if (g_is_ready == 0)
        pthread_cond_wait(&g_cond, &g_mutex);

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
LOCK_lock(&mutex);
while (!condition)
{
        COND_wait(&cond, &mutex);
}

consume();
LOCK_unlock(&mutex);
```

**Noncompliant fragment (do not copy):**

```c
LOCK_lock(&mutex);
if (!condition)
{
    COND_wait(&cond, &mutex);
}
consume(); /* assumes wake means predicate is true */
```

---

<a id="cpit-073"></a>

<a id="cpit-073-destroying-locked-mutex"></a>

### CPIT-073: Destroying locked mutex

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Destroying a mutex, condition variable, or other synchronization object while another context can
still access it breaks the lifecycle contract. Shutdown must first stop users, join threads, drain
callbacks, and then destroy synchronization objects.

**Prevention controls:** [CSTYLE-091][c-code-standard-cstyle-091].

**Weakness context:** [CWE-667][cwe-667], [CWE-664][cwe-664]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Stop and join all potential users before destroying synchronization state.

**External references:** [CWE-667][cwe-667]; [CWE-664][cwe-664].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badDestroyLockedMutex(void)
{
    int ret = EXIT_SUCCESS;

    pthread_mutex_lock(&g_mutex);
    pthread_mutex_destroy(&g_mutex);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Stop/join all users, prove mutex unlocked and unreachable, then destroy it
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Destroy mutex while another thread owns it or may still enter its protected
region
```

---

<a id="cpit-074"></a>

<a id="cpit-074-incorrect-atomic-memory-order"></a>

### CPIT-074: Incorrect atomic memory order

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Atomic accesses to the atomic object do not make dependent non-atomic data safe automatically. A
relaxed readiness flag alone does not publish a payload. A valid release/acquire relationship, or
another proved protocol, must connect the initialization and subsequent reads. Publication and safe
reclamation are separate obligations.

**Prevention controls:** [CSTYLE-092][c-code-standard-cstyle-092].

**Weakness context:** [CWE-362][cwe-362]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Show the release/acquire observation relation for a payload and test its
publication lifecycle.

**External references:** [CWE-362][cwe-362].

#### Local examples

**Failure fragment (do not execute):**

A consumer uses acquire on ready before reading value; the initialized object remains alive and is
not concurrently reused. This is a publication fragment, not a complete queue.

```c
payload->value = value;
atomic_store_explicit(&payload->ready, true, memory_order_relaxed);
```

**Contextual prevention example:**

A consumer uses acquire on ready before reading value; the initialized object remains alive and is
not concurrently reused. This is a publication fragment, not a complete queue.

```c
/* Synchronization owner; ready publishes payload exactly once. */
payload->value = value;
atomic_store_explicit(&payload->ready, true, memory_order_release);
```

---

<a id="cpit-075"></a>

<a id="cpit-075-volatile-used-as-synchronization"></a>

### CPIT-075: Volatile used as synchronization

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

`volatile` prevents some compiler access optimizations, but it does not provide atomicity, mutual
exclusion, or inter-thread ordering. It is appropriate for hardware-facing state, not as a threading
primitive. Use atomics or locks for concurrency.

**Prevention controls:** [CSTYLE-089][c-code-standard-cstyle-089].

**Weakness context:** [CWE-362][cwe-362]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Reject volatile-only thread synchronization and identify the actual lock or
atomic protocol.

**External references:** [CWE-362][cwe-362].

#### Local examples

**Failure fragment (do not execute):**

```c
static volatile uint32_t g_volatile_counter;

int EX_badVolatileSynchronization(void)
{
    int ret = EXIT_SUCCESS;

    g_volatile_counter++;

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
value = atomic_load_explicit(&shared, memory_order_acquire);
```

**Noncompliant fragment (do not copy):**

```c
volatile bool ready; /* volatile used as thread synchronization */
```

---

<a id="cpit-076"></a>

<a id="cpit-076-isr-shared-state-race"></a>

### CPIT-076: ISR shared-state race

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Interrupt handlers can preempt normal code in the middle of multi-step updates. `volatile` alone
does not make read-modify-write sequences safe. Use atomic operations, interrupt masking, lock-free
protocols, or hardware-specific critical sections.

**Prevention controls:** [CSTYLE-094][c-code-standard-cstyle-094].

**Weakness context:** [CWE-362][cwe-362], [CWE-667][cwe-667]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Exercise interrupt preemption points on target; verify shared-state access
width and critical sections.

**External references:** [CWE-362][cwe-362]; [CWE-667][cwe-667].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badIsrSharedStateRace(void)
{
    int ret = EXIT_SUCCESS;

    g_shared_counter++;

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
LOCK_lock(&state->lock);
state->value = new_value;
LOCK_unlock(&state->lock);
```

**Noncompliant fragment (do not copy):**

```c
state->value = new_value; /* concurrent writer/readers unsynchronized */
```

---

<a id="cpit-077"></a>

<a id="cpit-077-signal-handler-unsafe-call"></a>

### CPIT-077: Signal handler unsafe call

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

POSIX/C signal handlers run in a restricted execution context. Calling allocator APIs, standard I/O
logging, mutex operations, or most library functions can deadlock or corrupt state. Limit handlers
to async-signal-safe operations and atomic flags.

**Prevention controls:** [CSTYLE-095][c-code-standard-cstyle-095].

**Weakness context:** [CWE-479][cwe-479], [CWE-364][cwe-364]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Review the signal-handler call graph against the supported
async-signal-safe set.

**External references:** [CWE-479][cwe-479]; [CWE-364][cwe-364].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badSignalHandlerUnsafeCall(int signal_number)
{
    int ret = EXIT_SUCCESS;

    (void)signal_number;
    malloc(16u);

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
static volatile sig_atomic_t stop_requested = 0;

void onSignal(int sig)
{
        stop_requested = 1;
}
```

**Noncompliant fragment (do not copy):**

```c
void onSignal(int sig)
{
    printf("stop\n");
    malloc(32u);
}
```

---

<a id="cpit-078"></a>

<a id="cpit-078-aba-problem"></a>

### CPIT-078: ABA problem

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

An intervening change can take a shared location from A to B and back to A, letting a comparison
miss the change. The error needs a schedule and an invariant; returning a pointer by itself does not
demonstrate ABA. Tagged versions need an overflow policy. Hazard pointers/epochs address reclamation
under their protocols but do not eliminate all logical ABA in reused, still-live nodes.

**Prevention controls:** [CSTYLE-092][c-code-standard-cstyle-092].

**Weakness context:** [CWE-362][cwe-362], [CWE-416][cwe-416]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Write an A-B-A schedule and show version/lifetime protection preserves the
algorithm's invariant.

**External references:** [CWE-362][cwe-362]; [CWE-416][cwe-416].

#### Local examples

**Failure fragment (do not execute):**

A protocol-owned handle carries an identity/version and valid retention. The owner proves wrap/reuse
and reclamation safety. Neither an unchanged address nor a hazard pointer alone solves every logical
ABA case.

```c
observed = head;
/* Other threads remove A, reuse its address, and publish it again. */
if (head == observed)
{
    assume_same_logical_object(head);
}
```

**Contextual prevention example:**

A protocol-owned handle carries an identity/version and valid retention. The owner proves wrap/reuse
and reclamation safety. Neither an unchanged address nor a hazard pointer alone solves every logical
ABA case.

```c
ret = acquire_retained_version(head_context, &handle);
if (ret != EXIT_SUCCESS)
        goto function_output;
ret = compare_and_replace(head_context, &handle, replacement);
```

---

<a id="cpit-079"></a>

<a id="cpit-079-reentrancy-violation"></a>

### CPIT-079: Reentrancy violation

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Reentrancy bugs happen when an API can be called again before the first call finishes and both calls
mutate hidden shared state. Allocator hooks, logging callbacks, signal paths, and user callbacks can
all re-enter allocator code. Document reentrancy, avoid hidden mutable state, and do not call
external callbacks while internal allocator locks or partial state updates are active.

**Prevention controls:** [CSTYLE-092][c-code-standard-cstyle-092].

**Weakness context:** [CWE-663][cwe-663], [CWE-362][cwe-362]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Exercise documented synchronous reentry rejection and require no
destruction of the active instance.

**External references:** [CWE-663][cwe-663]; [CWE-362][cwe-362].

#### Local examples

**Failure fragment (do not execute):**

```c
static bool g_is_allocating;

void *EX_badReentrancyViolation(size_t size)
{
    void *ret = (void *)(NULL);

    if (g_is_allocating == true)
    {
        goto function_output;
    }

    g_is_allocating = true;
    EX_userAllocationHook();
    g_is_allocating = false;

    ret = malloc(size);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Document non-reentrant boundary and release/structure locks so callback cannot
recursively enter forbidden state
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Call external callback while internal invariant/lock is half-established;
callback re-enters same API
```

---

<a id="cpit-080"></a>

<a id="cpit-080-thread-local-storage-leak"></a>

### CPIT-080: Thread-local storage leak

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Thread-local caches and arenas are useful for allocator speed, but they create lifecycle
obligations. If a thread exits without deregistering and flushing TLS state, memory can leak or
stale metadata can remain reachable during shutdown. Register TLS at thread entry and clean it
before exit.

**Prevention controls:** [CSTYLE-091][c-code-standard-cstyle-091].

**Weakness context:** [CWE-401][cwe-401], [CWE-664][cwe-664]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Create and retire workers repeatedly; verify registered thread caches/TLS
resources are reclaimed.

**External references:** [CWE-401][cwe-401]; [CWE-664][cwe-664].

#### Local examples

**Failure fragment (do not execute):**

```c
static _Thread_local uint8_t *g_tls_cache;

int EX_badThreadLocalStorageLeak(void)
{
    int ret = EXIT_SUCCESS;

    g_tls_cache = malloc(1024u);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Thread lifecycle releases TLS-owned buffers/contexts before thread termination
or uses destructor mechanism
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Worker repeatedly allocates TLS object and exits/restarts without
destructor/release path
```

---

<a id="cpit-081"></a>

<a id="cpit-081-refcount-overflow"></a>

### CPIT-081: Refcount overflow

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Reference counters are ownership controls, so arithmetic overflow is a memory-safety bug. If a
refcount wraps to zero or a small value, an object can be freed while live references still exist.
Check increments before use and reject, saturate, or fail cleanly before the counter wraps.

**Prevention controls:** [CSTYLE-102][c-code-standard-cstyle-102].

**Weakness context:** [CWE-190][cwe-190], [CWE-416][cwe-416]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Prove refcount increment bounds and unique final release; reject wraparound
before it occurs.

**External references:** [CWE-190][cwe-190]; [CWE-416][cwe-416].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badRefcountOverflow(mem_object_t *object)
{
    int ret = EXIT_SUCCESS;

    object->ref_count++;

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
has_overflow = ARITH_addSize(a, b, &result);
if (has_overflow)
        ret = -EOVERFLOW;
```

**Noncompliant fragment (do not copy):**

```c
result = a + b; /* wrap/truncation not checked */
```

---

<a id="cpit-082"></a>

<a id="cpit-082-concurrent-double-free"></a>

### CPIT-082: Concurrent double free

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

A double free can be caused by a race even when each individual code path appears to free only once.
Two contexts can observe the object as live, then both release it. Free paths must perform an atomic
state transition or hold the object-owner lock before releasing memory.

**Prevention controls:** [CSTYLE-092][c-code-standard-cstyle-092].

**Weakness context:** [CWE-415][cwe-415], [CWE-362][cwe-362]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Model simultaneous release requests and show exactly one owner performs
final deallocation.

**External references:** [CWE-415][cwe-415]; [CWE-362][cwe-362].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badConcurrentDoubleFree(mem_object_t *object)
{
    int ret = EXIT_SUCCESS;

    if (object->is_freed == false)
    {
        object->is_freed = true;
        free(object);
    }

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
free(item);
item = (item_t *)(NULL);
```

**Noncompliant fragment (do not copy):**

```c
free(item);
free(item);
```

---

<a id="cpit-083"></a>

<a id="cpit-083-unbounded-blocking"></a>

### CPIT-083: Unbounded blocking

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

A call may be memory-safe yet fail the product's timing contract by blocking without a bound.
Include scheduler delays, priority inversion, callbacks, I/O, allocator behavior, and cancellation
in the bound. Host elapsed-time tests do not prove a real-time deadline on a different CPU or RTOS.

**Prevention controls:** [CSTYLE-074][c-code-standard-cstyle-074],
[CSTYLE-105][c-code-standard-cstyle-105], [CSTYLE-089][c-code-standard-cstyle-089],
[CSTYLE-066][c-code-standard-cstyle-066], [CSTYLE-107][c-code-standard-cstyle-107],
[CSTYLE-059][c-code-standard-cstyle-059], [CSTYLE-058][c-code-standard-cstyle-058],
[CSTYLE-081][c-code-standard-cstyle-081].

**Weakness context:** [CWE-400][cwe-400], [CWE-835][cwe-835]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Bound blocking including callbacks and lower-layer calls; measure on the
qualified target under interference.

**External references:** [CWE-400][cwe-400]; [CWE-835][cwe-835].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badUnboundedBlocking(void)
{
    int ret = EXIT_SUCCESS;

    while (g_is_ready == 0)
    {
    }

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Blocking operation has timeout/cancellation/WCET contract appropriate to its
context
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Thread/ISR waits indefinitely for peer/device/condition with no bound or
recovery path
```

---

<a id="cpit-151-wall-clock-changes-corrupt-duration-or-deadline-logic"></a> <a id="cpit-151"></a>

<a id="cpit-151-wall-clock-duration-deadline"></a>

### CPIT-151: Wall-clock changes corrupt duration or deadline logic

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-168`][c-code-standard-cstyle-168]

**Wall-clock changes corrupt duration or deadline logic.** The wall clock is adjusted by
synchronization, administration, leap handling, or a platform event while code uses it to measure
elapsed time. A retry can expire early, wait too long, or never finish. Use one monotonic domain and
its checked comparison helpers for durations and relative deadlines.

**External references:** [CWE-682][cwe-682].

#### Local examples

**Failure fragment (do not execute):**

Both timestamps come from the same monotonic epoch and unit, with a no-wrap interval contract.
Variables are entry declarations. Wall-clock timestamps are a different type/domain in the
surrounding API.

```c
elapsed = time((time_t *)(NULL)) - wall_start;
```

**Contextual prevention example:**

Both timestamps come from the same monotonic epoch and unit, with a no-wrap interval contract.
Variables are entry declarations. Wall-clock timestamps are a different type/domain in the
surrounding API.

```c
ret = monotonic_now(clock_context, &now_ns);
if (ret != EXIT_SUCCESS)
        goto function_output;
if (now_ns < start_ns)
{
        ret = -ERANGE;
        goto function_output;
}

elapsed_ns = now_ns - start_ns;
```

---

<a id="cpit-152-automatic-storage-exceeds-the-stack-budget"></a> <a id="cpit-152"></a>

<a id="cpit-152-automatic-storage-stack-budget"></a>

### CPIT-152: Automatic storage exceeds the stack budget

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-164`][c-code-standard-cstyle-164]

**Automatic storage exceeds the stack budget.** A large local array, aggregate temporary, inlined
helper, recursion depth, or rare error path consumes more stack than the execution context provides.
Audit the release call graph and move large workspaces to an explicitly owned bounded storage
policy.

**External references:** [CWE-674][cwe-674].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Bounded profile records worst-case frame + call chain/recursion depth and
fails CI when stack budget is exceeded
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Large automatic buffer or recursive/config-specific path exceeds
thread/ISR/kernel stack without evidence
```

---

<a id="cpit-159-a-lock-precondition-is-visible-only-in-prose"></a> <a id="cpit-159"></a>

<a id="cpit-159-lock-precondition-only-in-prose"></a>

### CPIT-159: A lock precondition is visible only in prose

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CMOD-105`][c-module-architecture-cmod-105]

**A lock precondition is visible only in prose.** A helper assumes that its caller holds a
particular lock, but naming, annotations, and debug assertions do not expose the requirement. A new
caller violates the protocol without a build diagnostic. Name the lock state and make it
machine-checkable where practical.

**External references:** [Clang thread-safety analysis][clang-thread-safety].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Function/API name or contract states caller-held lock;
assertions/annotations/tests verify precondition
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Call _locked helper without owning required lock or acquire same lock again
when helper expected caller ownership
```

---

<a id="cpit-163"></a>

<a id="cpit-163-shared-object-is-destroyed-while-another-context-acquires-it"></a>

### CPIT-163: Shared object is destroyed while another context acquires it

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-174`][c-code-standard-cstyle-174]

A lookup returns a raw pointer while another context can remove the same object and drop its final
reference. A later retain or dereference runs after the object lifetime ended.

Use a lookup that returns a retained reference or hold the lifetime lock across lookup and retain.

**External references:** [CWE-362][cwe-362]; [CWE-416][cwe-416].

#### Local examples

**Failure fragment (do not execute):**

```c
session = SESSION_lookupBorrowed(id);
if (session == (session_t *)(NULL))
{
    ret = -ENOENT;
    goto function_output;
}

ret = SESSION_process(session);

function_output:
    return ret;
```

---

<a id="cpit-164"></a>

<a id="cpit-164-concurrent-one-time-initialization-publishes-partial-state"></a>

### CPIT-164: Concurrent one-time initialization publishes partial state

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-175`][c-code-standard-cstyle-175]

An unsynchronized flag lets multiple threads run initialization or lets one thread observe the flag
without observing all initialized state.

Use the project once primitive.

**External references:** [CWE-362][cwe-362]; [CWE-665][cwe-665].

#### Local examples

**Failure fragment (do not execute):**

```c
if (!g_initialized)
{
    LIBRARY_buildTables();
    g_initialized = true;
}
```

---

<a id="cpit-165"></a>

<a id="cpit-165-thread-cancellation-bypasses-cleanup"></a>

### CPIT-165: Thread cancellation bypasses cleanup

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-176`][c-code-standard-cstyle-176]

A cancellation point runs while the thread owns a lock or resource and no cleanup action releases
it.

Disable cancellation across the bounded critical region or register a cleanup action through the
project thread adapter.

**External references:** [CWE-404][cwe-404].

#### Local examples

**Failure fragment (do not execute):**

```c
ret = MUTEX_lock(&worker->lock);
if (ret != EXIT_SUCCESS)
{
    goto function_output;
}

ret = IO_waitForInput(worker->fd);
MUTEX_unlock(&worker->lock);

function_output:
    return ret;
```

---

<a id="cpit-166"></a>

<a id="cpit-166-forked-child-calls-unsafe-code-from-a-multithreaded-process"></a>

### CPIT-166: Forked child calls unsafe code from a multithreaded process

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-177`][c-code-standard-cstyle-177]

The child inherits process memory and lock state but only the calling thread survives. Calling the
allocator, logger, or a mutex-backed module before exec can deadlock on state owned by a thread that
no longer exists in the child.

Use the project spawn adapter or an async-signal-safe child sequence.

**External references:** [CWE-479][cwe-479].

#### Local examples

**Failure fragment (do not execute):**

```c
child_pid = fork();
if (child_pid == 0)
{
    LOG_info("child starting");
    WORKER_lockGlobalState();
    execve(path, argv, envp);
}
```

---

<a id="cpit-167"></a>

<a id="cpit-167-priority-inversion-breaks-a-bounded-real-time-path"></a>

### CPIT-167: Priority inversion breaks a bounded real-time path

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-178`][c-code-standard-cstyle-178]

A high-priority task waits on a lock owned by a lower-priority task while intermediate-priority work
prevents the owner from running. The critical path loses its bound.

Use bounded critical sections and the profile's approved priority-inheritance, ceiling,
partitioned-owner, or lock-free protocol.

**External references:** [CWE-667][cwe-667].

#### Local examples

**Failure fragment (do not execute):**

```c
ret = MUTEX_lock(&control->lock);
ret = NETWORK_waitForReply(control->socket);
ret = MUTEX_unlock(&control->lock);
```

---

<a id="cpit-084"></a>

<a id="cpit-084-reserved-register-bits-clobbered"></a>

### CPIT-084: Reserved register bits clobbered

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

A generic masked update can write forbidden reserved-bit values or mishandle
write-one-to-clear/read-clear semantics. Follow the register's specific manual for the permitted
width, values, ordering, and access sequence. Keeping old reserved bits is not universally correct.

**Prevention controls:** [CSTYLE-105][c-code-standard-cstyle-105].

**Weakness context:** [CWE-664][cwe-664], [CWE-758][cwe-758]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Verify register writes against the manual's reserved-bit and access-type
rules, not a generic mask recipe.

**External references:** [CWE-664][cwe-664]; [CWE-758][cwe-758].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badReservedRegisterBitsClobbered(volatile uint32_t *reg)
{
    int ret = EXIT_SUCCESS;

    *reg = 0xffffffffu;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Hardware interaction goes through a platform-owned contract that documents
register/DMA/ISR timing and ordering
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Ordinary module accesses raw hardware state with undocumented timing,
coherency, or reserved-bit assumptions
```

---

<a id="cpit-085"></a>

<a id="cpit-085-read-clear-register-mishandled"></a>

### CPIT-085: Read-clear register mishandled

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Some status registers clear bits when read. A debugging read, polling helper, or careless
read-modify-write can lose an event before the real handler sees it. Document side effects and
centralize accessors for such registers.

**Prevention controls:** [CSTYLE-105][c-code-standard-cstyle-105].

**Weakness context:** [CWE-664][cwe-664]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Read a modeled read-clear register exactly as specified and preserve the
consumed event for processing.

**External references:** [CWE-664][cwe-664].

#### Local examples

**Failure fragment (do not execute):**

```c
uint32_t EX_badReadClearRegisterMishandled(volatile uint32_t *reg)
{
    uint32_t ret = 0u;

    ret = *reg | *reg;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Hardware interaction goes through a platform-owned contract that documents
register/DMA/ISR timing and ordering
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Ordinary module accesses raw hardware state with undocumented timing,
coherency, or reserved-bit assumptions
```

---

<a id="cpit-086"></a>

<a id="cpit-086-dma-cache-coherency-failure"></a>

### CPIT-086: DMA cache coherency failure

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

DMA and CPU visibility can differ because of cache state, ordering, or ownership. Volatile does not
flush caches or transfer buffer ownership. Apply the architecture's required cache maintenance and
barriers at the documented handoff points, and verify alignment/length constraints on the actual
target.

**Prevention controls:** [CSTYLE-089][c-code-standard-cstyle-089].

**Weakness context:** [CWE-667][cwe-667], [CWE-664][cwe-664]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Verify DMA handoff/cache/barrier ordering on actual coherent and
noncoherent target configurations where supported.

**External references:** [CWE-667][cwe-667]; [CWE-664][cwe-664].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badDmaCacheCoherency(uint8_t dma_buffer[])
{
    int ret = EXIT_SUCCESS;

    dma_buffer[0] = 1u;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
DMA owner follows platform cache clean/invalidate, alignment,
ownership-transfer, and ordering contract
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
CPU and DMA access same buffer with no cache-coherency/ownership protocol
```

---

<a id="cpit-087"></a>

<a id="cpit-087-watchdog-kicked-too-early"></a>

### CPIT-087: Watchdog kicked too early

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

A watchdog is only useful if it is serviced after the system proves it is healthy. Kicking it at the
start of a loop or before checking dependencies can mask a hung subsystem. Service the watchdog only
after required health checks complete.

**Prevention controls:** [CSTYLE-066][c-code-standard-cstyle-066].

**Weakness context:** [CWE-665][cwe-665]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Withhold a required task heartbeat and require watchdog policy to detect
missing system progress.

**External references:** [CWE-665][cwe-665].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badWatchdogKickedTooEarly(volatile uint32_t *watchdog_reg)
{
    int ret = EXIT_SUCCESS;

    *watchdog_reg = 1u;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Hardware interaction goes through a platform-owned contract that documents
register/DMA/ISR timing and ordering
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Ordinary module accesses raw hardware state with undocumented timing,
coherency, or reserved-bit assumptions
```

---

<a id="cpit-088"></a>

<a id="cpit-088-unsafe-default-state"></a>

### CPIT-088: Unsafe default state

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

On reset, startup failure, brownout, or software fault, outputs may briefly take unsafe values.
Safety outputs and actuator commands must default to a safe state before initialization can fail.
Define safe values in hardware and software.

**Prevention controls:** [CSTYLE-107][c-code-standard-cstyle-107].

**Weakness context:** [CWE-665][cwe-665], [CWE-1188][cwe-1188]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Review reset, partial-init, fault, and shutdown outputs against
hazard-defined safe states.

**External references:** [CWE-665][cwe-665]; [CWE-1188][cwe-1188].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badUnsafeDefaultState(volatile uint32_t *motor_enable_reg)
{
    int ret = EXIT_SUCCESS;

    *motor_enable_reg = 1u;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Hardware interaction goes through a platform-owned contract that documents
register/DMA/ISR timing and ordering
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Ordinary module accesses raw hardware state with undocumented timing,
coherency, or reserved-bit assumptions
```

---

<a id="cpit-089"></a>

<a id="cpit-089-persistent-config-corruption"></a>

### CPIT-089: Persistent config corruption

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Flash, EEPROM, files, and NVM may contain old, partial, corrupt, or malicious data. Treat persistent
configuration as untrusted input. Validate version, length, range, checksum/MAC, and fallback
defaults before use.

**Prevention controls:** [CSTYLE-059][c-code-standard-cstyle-059].

**Weakness context:** [CWE-20][cwe-20], [CWE-354][cwe-354]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Inject interrupted persistent writes and corrupted metadata; require
recovery to a validated configuration.

**External references:** [CWE-20][cwe-20]; [CWE-354][cwe-354].

#### Local examples

**Failure fragment (do not execute):**

```c
uint32_t EX_badPersistentConfigCorruption(const uint8_t nvm_data[])
{
    uint32_t ret = 0u;

    ret = *((const uint32_t *)nvm_data);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Hardware interaction goes through a platform-owned contract that documents
register/DMA/ISR timing and ordering
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Ordinary module accesses raw hardware state with undocumented timing,
coherency, or reserved-bit assumptions
```

---

<a id="cpit-090"></a>

<a id="cpit-090-calibration-out-of-range"></a>

### CPIT-090: Calibration out of range

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Calibration data may be syntactically valid but physically impossible or unsafe. Range checks must
use engineering limits, unit constraints, and plausibility rules, not just serialization validity.

**Prevention controls:** [CSTYLE-058][c-code-standard-cstyle-058].

**Weakness context:** [CWE-20][cwe-20], [CWE-682][cwe-682]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Reject calibration values outside physical/domain limits before activation.

**External references:** [CWE-20][cwe-20]; [CWE-682][cwe-682].

#### Local examples

**Failure fragment (do not execute):**

```c
uint32_t EX_badCalibrationOutOfRange(uint32_t calibration_value)
{
    uint32_t ret = 0u;

    ret = calibration_value * 1000u;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Hardware interaction goes through a platform-owned contract that documents
register/DMA/ISR timing and ordering
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Ordinary module accesses raw hardware state with undocumented timing,
coherency, or reserved-bit assumptions
```

---

<a id="cpit-091"></a>

<a id="cpit-091-missing-stale-data-detection"></a>

### CPIT-091: Missing stale-data detection

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Sensor and network values can expire while remaining numerically plausible. Control logic must know
whether data is fresh. Use timestamps, sequence counters, validity flags, and timeout-to-safe-state
rules.

**Prevention controls:** [CSTYLE-059][c-code-standard-cstyle-059].

**Weakness context:** [CWE-345][cwe-345], [CWE-20][cwe-20]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Test expired samples, clock wrap/reset, and stale cached values under the
chosen freshness protocol.

**External references:** [CWE-345][cwe-345]; [CWE-20][cwe-20].

#### Local examples

**Failure fragment (do not execute):**

```c
uint32_t EX_badMissingStaleDataDetection(uint32_t sensor_value)
{
    uint32_t ret = 0u;

    ret = sensor_value;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Hardware interaction goes through a platform-owned contract that documents
register/DMA/ISR timing and ordering
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Ordinary module accesses raw hardware state with undocumented timing,
coherency, or reserved-bit assumptions
```

---

<a id="cpit-092"></a>

<a id="cpit-092-missing-sequence-or-freshness-check"></a>

### CPIT-092: Missing sequence or freshness check

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Replayed, reordered, duplicated, or delayed messages can be dangerous even when their payload passes
range checks. Safety and security protocols need sequence counters, freshness windows, and replay
rejection.

**Prevention controls:** [CSTYLE-059][c-code-standard-cstyle-059].

**Weakness context:** [CWE-345][cwe-345], [CWE-294][cwe-294]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Reject replayed/out-of-window sequence values and define restart and wrap
behavior.

**External references:** [CWE-345][cwe-345]; [CWE-294][cwe-294].

#### Local examples

**Failure fragment (do not execute):**

```c
uint32_t EX_badMissingSequenceFreshnessCheck(uint32_t command_value)
{
    uint32_t ret = 0u;

    ret = command_value;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Hardware interaction goes through a platform-owned contract that documents
register/DMA/ISR timing and ordering
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Ordinary module accesses raw hardware state with undocumented timing,
coherency, or reserved-bit assumptions
```

---

<a id="cpit-093"></a>

<a id="cpit-093-dynamic-allocation-in-critical-path"></a>

### CPIT-093: Dynamic allocation in critical path

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Heap allocation may be slow, fragmenting, unavailable, or unbounded under load. Critical control
paths should use static storage, pools, preallocation, or bounded arenas with explicit OOM behavior.

**Prevention controls:** [CSTYLE-081][c-code-standard-cstyle-081],
[CSTYLE-059][c-code-standard-cstyle-059], [CSTYLE-068][c-code-standard-cstyle-068],
[CSTYLE-086][c-code-standard-cstyle-086], [CSTYLE-067][c-code-standard-cstyle-067],
[CSTYLE-029][c-code-standard-cstyle-029], [CSTYLE-109][c-code-standard-cstyle-109],
[CSTYLE-110][c-code-standard-cstyle-110].

**Weakness context:** [CWE-400][cwe-400], [CWE-789][cwe-789]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Instrument the transitive critical path and require the declared allocation
and timing policy.

**External references:** [CWE-400][cwe-400]; [CWE-789][cwe-789].

#### Local examples

**Failure fragment (do not execute):**

```c
void *EX_badDynamicAllocationInCriticalPath(size_t size)
{
    void *ret = (void *)(NULL);

    ret = malloc(size);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Hardware interaction goes through a platform-owned contract that documents
register/DMA/ISR timing and ordering
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Ordinary module accesses raw hardware state with undocumented timing,
coherency, or reserved-bit assumptions
```

---

<a id="cpit-126"></a>

<a id="cpit-126-bit-field-layout-used-as-an-external-representation"></a>

### CPIT-126: Bit-field layout used as an external representation

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-127`][c-code-standard-cstyle-127]

**Bit-field layout used as an external representation.** C does not provide a portable bit
allocation order or storage-unit layout for bit-fields. Mapping them onto MMIO, packets, files,
persistent state, or ABI can assign a named field to different physical bits after a compiler,
target, or option change. Use fixed-width values with named masks and explicit encoding.

**External references:** [CWE-758][cwe-758].

#### Local examples

**Failure fragment (do not execute):**

```c
typedef struct ExBadRegister
{
    uint32_t enable : 1u;
    uint32_t mode   : 3u;
    uint32_t status : 4u;
} ex_bad_register_t;
```

**Contextual prevention example:**

```c
#define STATUS_READY_MASK ((uint32_t)(1U << 3U))
```

**Noncompliant fragment (do not copy):**

```c
struct Reg { uint32_t ready : 1; }; /* compiler bit-field layout used as MMIO/wire definition */
```

---

<a id="cpit-169"></a>

<a id="cpit-169-power-loss-exposes-a-partially-committed-persistent-update"></a>

### CPIT-169: Power loss exposes a partially committed persistent update

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-173`][c-code-standard-cstyle-173]

A persistent update overwrites several fields in place. Power loss or reset between writes leaves a
mixture of old and new state that passes no transaction boundary.

Use a journal, A/B slot, write-ahead log, copy-on-write update, or another protocol with a tested
commit point and recovery rule.

**External references:** [CWE-662][cwe-662].

#### Local examples

**Failure fragment (do not execute):**

```c
ret = STORAGE_writeField(
    CONFIG_TIMEOUT_OFFSET,
    &timeout_ms,
    sizeof(timeout_ms)
);
if (ret != EXIT_SUCCESS)
{
    goto function_output;
}

ret = STORAGE_writeField(CONFIG_MODE_OFFSET, &mode, sizeof(mode));

function_output:
    return ret;
```

---

<a id="cpit-094"></a>

<a id="cpit-094-tainted-size-trusted"></a>

### CPIT-094: Tainted size trusted

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Sizes, counts, offsets, indexes, enum values, and state-machine inputs from outside the trust
boundary must be treated as hostile or corrupt. Validate them before allocation, indexing,
arithmetic, casting, or state transitions.

**Prevention controls:** [CSTYLE-059][c-code-standard-cstyle-059].

**Weakness context:** [CWE-20][cwe-20], [CWE-129][cwe-129]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Test tainted lengths before allocation, pointer formation, indexing, and
state transition.

**Source context:** [validation][c-common-pitfalls-ref-validation].

**External references:** [CWE-20][cwe-20]; [CWE-129][cwe-129]; [CAPEC-100][capec-100]; [OWASP
prevention guidance][owasp-input-validation].

#### Local examples

**Failure fragment (do not execute):**

```c
void *EX_badTaintedSizeTrusted(size_t external_size)
{
    void *ret = (void *)(NULL);

    ret = malloc(external_size);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Validate external size against object/protocol/resource limits and checked
arithmetic before allocation/copy/indexing
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use request length directly for malloc/memcpy/loop count because it parsed as
an integer
```

---

<a id="cpit-095"></a>

<a id="cpit-095-format-string-injection"></a>

### CPIT-095: Format string injection

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

A format string controls how variadic arguments are interpreted. External input used as a format can
read memory, write through `%n`, or crash through type mismatches. Logging and formatting wrappers
should require literal formats where possible.

**Prevention controls:** [CSTYLE-068][c-code-standard-cstyle-068].

**Weakness context:** [CWE-134][cwe-134]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Ensure every externally influenced log value remains data under a trusted
format.

**Source context:** [logging][c-common-pitfalls-ref-logging].

**External references:** [CWE-134][cwe-134]; [CAPEC-135][capec-135]; [OWASP prevention
guidance][owasp-input-validation].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badFormatStringInjection(const char user_text[])
{
    int ret = EXIT_SUCCESS;

    printf(user_text);

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
printf("%s", user_text);
```

**Noncompliant fragment (do not copy):**

```c
printf(user_text);
```

---

<a id="cpit-096"></a>

<a id="cpit-096-hardcoded-secret"></a>

### CPIT-096: Hardcoded secret

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Secrets embedded in source or firmware are difficult to rotate and easy to extract from binaries.
Device credentials, keys, passwords, and provisioning tokens must come from a secure provisioning or
storage mechanism, not from constants in code.

**Prevention controls:** [CSTYLE-086][c-code-standard-cstyle-086].

**Weakness context:** [CWE-798][cwe-798]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Inspect source/build outputs for embedded production secrets and test
provisioning/rotation failure paths.

**Source context:** [validation][c-common-pitfalls-ref-validation].

**External references:** [CWE-798][cwe-798]; [OWASP prevention guidance][owasp-secrets-management].

#### Local examples

**Failure fragment (do not execute):**

```c
const char *EX_badHardcodedSecret(void)
{
    const char *ret = (const char *)(NULL);

    ret = "factory-secret";

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Secrets come from approved secure storage/input and are wiped with dedicated
primitive after use
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Hard-code credential/private key in source or leave secret in ordinary
memory/logs
```

---

<a id="cpit-097"></a>

<a id="cpit-097-secret-logged"></a>

### CPIT-097: Secret logged

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Logs often leave the device, persist longer than memory, and reach broader audiences than runtime
state. Never log credentials, private keys, session tokens, personal data, or raw sensitive
payloads. Redact at the logging boundary.

**Prevention controls:** [CSTYLE-067][c-code-standard-cstyle-067].

**Weakness context:** [CWE-532][cwe-532]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Verify denied operations and exceptions do not place credentials or raw
sensitive payloads in logs.

**Source context:** [logging][c-common-pitfalls-ref-logging].

**External references:** [CWE-532][cwe-532]; [OWASP prevention guidance][owasp-logging].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badSecretLogged(const char password[])
{
    int ret = EXIT_SUCCESS;

    printf("password=%s\n", password);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Secrets come from approved secure storage/input and are wiped with dedicated
primitive after use
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Hard-code credential/private key in source or leave secret in ordinary
memory/logs
```

---

<a id="cpit-098"></a>

<a id="cpit-098-missing-secure-erase"></a>

### CPIT-098: Missing secure erase

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Sensitive bytes may remain after their logical use ends. Use a qualified secure-erasure primitive
when the threat model requires it, and verify the compiler/runtime behavior. An ordinary memset or a
generic compiler barrier is not automatically sufficient. C23 `memset_explicit` is an option when
available. Erasing one buffer does not erase its copies, logs, dumps, registers, or media.

**Prevention controls:** [CSTYLE-086][c-code-standard-cstyle-086].

**Weakness context:** [CWE-226][cwe-226]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Review the qualified erase primitive and copies; do not infer erasure from
an optimized-away source statement.

**Source context:** [validation][c-common-pitfalls-ref-validation].

**External references:** [CWE-226][cwe-226]; [OWASP prevention
guidance][owasp-cryptographic-storage].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badMissingSecureErase(char secret[])
{
    int ret = EXIT_SUCCESS;

    free(secret);

function_output:
    return ret;
}
```

**Contextual prevention example:**

```c
SECRET_memzero(key, sizeof(key));
```

**Noncompliant fragment (do not copy):**

```c
memset(key, 0, sizeof(key)); /* ordinary wipe may be optimized away */
```

---

<a id="cpit-099"></a>

<a id="cpit-099-homegrown-cryptography"></a>

### CPIT-099: Homegrown cryptography

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Custom cryptography usually fails in subtle ways: mode misuse, nonce reuse, side channels, weak
randomness, or unauthenticated encryption. Use reviewed libraries and platform-approved primitives
behind a small adapter.

**Prevention controls:** [CSTYLE-029][c-code-standard-cstyle-029].

**Weakness context:** [CWE-327][cwe-327]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Check approved algorithms, nonce rules, randomness, authentication, and
library use against the threat model.

**Source context:** [validation][c-common-pitfalls-ref-validation].

**External references:** [CWE-327][cwe-327]; [OWASP prevention
guidance][owasp-cryptographic-storage].

#### Local examples

**Failure fragment (do not execute):**

```c
uint32_t EX_badHomegrownCryptography(uint32_t value, uint32_t key)
{
    uint32_t ret = 0u;

    ret = value ^ key;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use reviewed cryptographic library/primitive with correct
nonce/key/authentication contract
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Invent custom XOR/encryption/checksum scheme for security property
```

---

<a id="cpit-100"></a>

<a id="cpit-100-weak-random-number"></a>

### CPIT-100: Weak random number

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Predictable random values break keys, tokens, nonces, challenges, and protocol freshness. `rand()`
and simple PRNGs are not security sources. Use a cryptographic RNG and handle entropy-source failure
explicitly.

**Prevention controls:** [CSTYLE-086][c-code-standard-cstyle-086].

**Weakness context:** [CWE-338][cwe-338]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Simulate entropy-source failure and require the security operation to fail
without a predictable fallback.

**Source context:** [validation][c-common-pitfalls-ref-validation].

**External references:** [CWE-338][cwe-338]; [OWASP prevention
guidance][owasp-cryptographic-storage].

#### Local examples

**Failure fragment (do not execute):**

```c
uint32_t EX_badWeakRandomNumber(void)
{
    uint32_t ret = 0u;

    ret = (uint32_t)rand();

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use approved cryptographic RNG and handle entropy-source failure
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use rand()/time-based PRNG for keys, nonces, tokens, or challenges
```

---

<a id="cpit-101"></a>

<a id="cpit-101-missing-firmware-signature-check"></a>

### CPIT-101: Missing firmware signature check

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Executable updates need authenticity rooted in trusted keys or another approved trust mechanism.
Validate target identity, metadata, integrity, and activation policy before execution. A matching
hash from an untrusted source does not authenticate the image. Power-fail-safe activation and
recovery are separate requirements.

**Prevention controls:** [CSTYLE-059][c-code-standard-cstyle-059].

**Weakness context:** [CWE-347][cwe-347], [CWE-494][cwe-494]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Reject wrong signatures/targets/metadata and interrupt activation to
exercise recovery.

**Source context:** [supply-chain][c-common-pitfalls-ref-supply-chain];
[ssdf][c-common-pitfalls-ref-ssdf].

**External references:** [CWE-347][cwe-347]; [CWE-494][cwe-494]; [CAPEC-184][capec-184].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badMissingFirmwareSignatureCheck(const uint8_t image[])
{
    int ret = EXIT_SUCCESS;

    (void)image;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Verify signature, image integrity, target identity and security version before
write/boot activation
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Accept firmware bytes because transport succeeded; activate without
authenticity verification
```

---

<a id="cpit-102"></a>

<a id="cpit-102-missing-anti-rollback"></a>

### CPIT-102: Missing anti-rollback

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

A signed but old image may contain known vulnerabilities. Anti-rollback prevents downgrade to a
still-authentic but unsafe version. Store monotonic version or security counter state in a protected
location.

**Prevention controls:** [CSTYLE-059][c-code-standard-cstyle-059].

**Weakness context:** [CWE-693][cwe-693]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Present an authentic but disallowed old image and require the protected
rollback policy to reject it.

**Source context:** [supply-chain][c-common-pitfalls-ref-supply-chain];
[ssdf][c-common-pitfalls-ref-ssdf].

**External references:** [CWE-693][cwe-693].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badMissingAntiRollback(uint32_t image_version)
{
    int ret = EXIT_SUCCESS;

    (void)image_version;

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Reject authentic image whose security version is below protected monotonic
minimum
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Accept any correctly signed image, including known-vulnerable older release
```

---

<a id="cpit-103"></a>

<a id="cpit-103-command-injection"></a>

### CPIT-103: Command injection

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

If external data reaches a shell command, separators, substitution, quoting, and environment
behavior become attack surface. Runtime C code should avoid shell execution and use explicit APIs
with fixed argument vectors when process launch is unavoidable.

**Prevention controls:** [CSTYLE-109][c-code-standard-cstyle-109].

**Weakness context:** [CWE-78][cwe-78], [CWE-77][cwe-77]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Test shell metacharacters as literal argument data and verify no shell
interpreter is invoked unintentionally.

**Source context:** [validation][c-common-pitfalls-ref-validation].

**External references:** [CWE-78][cwe-78]; [CWE-77][cwe-77]; [CAPEC-88][capec-88]; [OWASP prevention
guidance][owasp-os-command-injection-defense].

#### Local examples

**Noncompliant fragment (do not copy):**

```c
int EX_badCommandInjection(const char user_command[])
{
    int ret = EXIT_SUCCESS;

    system(user_command);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Execute fixed binary with structured argv and keep untrusted values as
arguments
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Concatenate user text into shell command and invoke system()/popen()
```

---

<a id="cpit-104"></a>

<a id="cpit-104-path-traversal"></a>

### CPIT-104: Path traversal

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Untrusted paths can escape a permitted root through traversal, links, platform aliases, or check/use
races. Canonicalizing a pathname once is not enough when another actor can replace a component
before use. Prefer platform-supported handle-relative resolution and constraints applied to the
object opened. Keep normalization and access policy in one filesystem adapter.

**Prevention controls:** [CSTYLE-059][c-code-standard-cstyle-059].

**Weakness context:** [CWE-22][cwe-22]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Test traversal, symlink replacement, platform aliases, and component
replacement between check and open.

**Source context:** [validation][c-common-pitfalls-ref-validation].

**External references:** [CWE-22][cwe-22]; [CAPEC-126][capec-126]; [OWASP prevention
guidance][owasp-input-validation].

#### Local examples

**Failure fragment (do not execute):**

```c
FILE *EX_badPathTraversal(const char user_path[])
{
    FILE *ret = (FILE *)(NULL);

    ret = fopen(user_path, "rb");

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Resolve path under approved root, enforce symlink/canonicalization policy,
then open validated path
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Open caller-provided ../../etc/... path directly
```

---

<a id="cpit-105"></a>

<a id="cpit-105-improper-access-control"></a>

### CPIT-105: Improper access control

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

A function that performs a privileged operation must verify the caller's authority, mode, state, or
capability before acting. This applies inside firmware too: debug, update, calibration, diagnostic,
and factory commands need explicit authorization gates.

**Prevention controls:** [CSTYLE-110][c-code-standard-cstyle-110],
[CSTYLE-109][c-code-standard-cstyle-109], [CSTYLE-111][c-code-standard-cstyle-111],
[CMOD-085][c-module-architecture-cmod-085], [CSTYLE-112][c-code-standard-cstyle-112],
[CSTYLE-113][c-code-standard-cstyle-113], [CMOD-083][c-module-architecture-cmod-083],
[CMOD-084][c-module-architecture-cmod-084], [CMOD-086][c-module-architecture-cmod-086],
[CSTYLE-067][c-code-standard-cstyle-067], [CSTYLE-114][c-code-standard-cstyle-114],
[CSTYLE-115][c-code-standard-cstyle-115].

**Weakness context:** [CWE-284][cwe-284]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Deny unauthorized operations for every privileged mode, including factory
and diagnostic paths.

**Source context:** [authorization][c-common-pitfalls-ref-authorization].

**External references:** [CWE-284][cwe-284]; [OWASP prevention guidance][owasp-authorization].

#### Local examples

**Failure fragment (do not execute):**

```c
int EX_badImproperAccessControl(int is_debug_command)
{
    int ret = EXIT_SUCCESS;

    if (is_debug_command != 0)
    {
        EX_unlockFactoryMode();
    }

function_output:
    return ret;
}
```

**Failure fragment (do not execute):**

```c
int EX_badImproperAccessControl(int is_debug_command)
{
    int ret = EXIT_SUCCESS;

    if (is_debug_command != 0)
        EX_unlockFactoryMode();

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Authenticate identity and check capability/ownership for exact object/action
before privileged side effect
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Treat a valid object ID, debug opcode, or authenticated session as sufficient
authorization for every operation
```

---

<a id="cpit-106"></a>

<a id="cpit-106-sql-injection"></a>

### CPIT-106: SQL injection

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Data becomes SQL syntax when a query is assembled by string concatenation, formatting, or another
text-substitution mechanism. Validate the semantic input, then bind values with the database
driver's parameter API. Do not attempt to secure dynamic SQL with a character denylist.

**Prevention controls:** [CSTYLE-109][c-code-standard-cstyle-109].

**Weakness context:** [CWE-89][cwe-89]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Test quote/comment payloads as bound database values; identifiers require a
separate allowlist.

**Source context:** [sql][c-common-pitfalls-ref-sql].

**External references:** [CWE-89][cwe-89]; [CAPEC-66][capec-66]; [OWASP prevention
guidance][owasp-sql-injection-prevention].

#### Local examples

**Failure fragment (do not execute):**

```c
snprintf(query,
         sizeof(query),
         "SELECT * FROM account WHERE name='%s'",
         user_name);
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Boundary owner validates input and applies the destination-specific safe API
before side effects
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Untrusted or mutable external input flows directly into sensitive
API/configuration/artifact path
```

---

<a id="cpit-107"></a>

<a id="cpit-107-cross-site-scripting-output-injection"></a>

### CPIT-107: Cross-site scripting output injection

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

When C code generates HTML, script, CSS, URLs, or another browser-interpreted representation,
untrusted data must be encoded for the exact output context. Input validation is not a substitute
for context-specific output encoding.

**Prevention controls:** [CSTYLE-109][c-code-standard-cstyle-109].

**Weakness context:** [CWE-79][cwe-79]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Verify context-specific output encoding for HTML, attributes, URLs, CSS,
and script contexts used.

**Source context:** [xss][c-common-pitfalls-ref-xss].

**External references:** [CWE-79][cwe-79]; [CAPEC-63][capec-63]; [OWASP prevention
guidance][owasp-cross-site-scripting-prevention].

#### Local examples

**Failure fragment (do not execute):**

```c
printf("<div>%s</div>", user_text);
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Boundary owner validates input and applies the destination-specific safe API
before side effects
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Untrusted or mutable external input flows directly into sensitive
API/configuration/artifact path
```

---

<a id="cpit-108"></a>

<a id="cpit-108-cross-site-request-forgery"></a>

### CPIT-108: Cross-site request forgery

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

A state-changing service action must not treat ambient browser credentials as proof that the user
intended the request. When a C service uses cookie-based sessions, require an approved anti-CSRF
mechanism and validate origin/session binding before the operation.

**Prevention controls:** [CSTYLE-110][c-code-standard-cstyle-110].

**Weakness context:** [CWE-352][cwe-352]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Reject cross-site state-changing requests without the approved
request-intent/session binding.

**Source context:** [authorization][c-common-pitfalls-ref-authorization].

**External references:** [CWE-352][cwe-352]; [CAPEC-62][capec-62]; [OWASP prevention
guidance][owasp-cross-site-request-forgery-prevention].

#### Local examples

**Failure fragment (do not execute):**

```c
if (session_is_valid != 0)
{
    DEVICE_factoryReset();
}
```

**Failure fragment (do not execute):**

```c
if (session_is_valid != 0)
    DEVICE_factoryReset();
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Boundary owner validates input and applies the destination-specific safe API
before side effects
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Untrusted or mutable external input flows directly into sensitive
API/configuration/artifact path
```

---

<a id="cpit-109"></a>

<a id="cpit-109-code-injection-or-dynamic-evaluation"></a>

### CPIT-109: Code injection or dynamic evaluation

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Configuration, templates, scripts, expressions, JIT input, or generated code from an untrusted
source can cross a data/code boundary. Prefer fixed operations and typed parameters. If an
interpreter is an explicit product feature, isolate it and enforce a narrow allowlist/capability
model.

**Prevention controls:** [CSTYLE-109][c-code-standard-cstyle-109].

**Weakness context:** [CWE-94][cwe-94]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Reject untrusted evaluator input unless an intentionally isolated
interpreter capability permits it.

**Source context:** [validation][c-common-pitfalls-ref-validation].

**External references:** [CWE-94][cwe-94]; [CAPEC-242][capec-242]; [OWASP prevention
guidance][owasp-input-validation].

#### Local examples

**Failure fragment (do not execute):**

```c
SCRIPT_eval(untrusted_text);
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Boundary owner validates input and applies the destination-specific safe API
before side effects
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Untrusted or mutable external input flows directly into sensitive
API/configuration/artifact path
```

---

<a id="cpit-110"></a>

<a id="cpit-110-unrestricted-dangerous-file-upload"></a>

### CPIT-110: Unrestricted dangerous file upload

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

A filename, extension, or client-supplied MIME type does not establish that content is safe. Enforce
a size limit, parse or validate the required content format, generate server-side names, store
outside executable/search paths, and apply least-privilege permissions.

**Prevention controls:** [CSTYLE-111][c-code-standard-cstyle-111].

**Weakness context:** [CWE-434][cwe-434]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Test misleading names/MIME values, excess size, and executable content in a
non-executable storage policy.

**Source context:** [upload][c-common-pitfalls-ref-upload].

**External references:** [CWE-434][cwe-434]; [OWASP prevention guidance][owasp-file-upload].

#### Local examples

**Failure fragment (do not execute):**

```c
fwrite(upload_bytes, 1u, upload_size, fopen(user_name, "wb"));
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Boundary owner validates input and applies the destination-specific safe API
before side effects
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Untrusted or mutable external input flows directly into sensitive
API/configuration/artifact path
```

---

<a id="cpit-111"></a>

<a id="cpit-111-deserialization-of-untrusted-data"></a>

### CPIT-111: Deserialization of untrusted data

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Wire bytes must not recreate arbitrary pointer graphs, function identifiers, object types, lengths,
offsets, or privileged state. Decode into an initialized DTO with explicit bounds and a
schema/version allowlist, then validate semantics before constructing runtime objects.

**Prevention controls:** [CSTYLE-111][c-code-standard-cstyle-111].

**Weakness context:** [CWE-502][cwe-502]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Reject unknown versions, excessive depth/counts, invalid semantic
relations, and executable pointer-like fields.

**Source context:** [validation][c-common-pitfalls-ref-validation].

**External references:** [CWE-502][cwe-502]; [CAPEC-586][capec-586]; [OWASP prevention
guidance][owasp-deserialization].

#### Local examples

**Failure fragment (do not execute):**

```c
memcpy(object, packet, sizeof(*object));
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Boundary owner validates input and applies the destination-specific safe API
before side effects
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Untrusted or mutable external input flows directly into sensitive
API/configuration/artifact path
```

---

<a id="cpit-112"></a>

<a id="cpit-112-missing-authentication-for-critical-function"></a>

### CPIT-112: Missing authentication for critical function

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Update, debug, diagnostic, factory, secret-management, and administrative operations need a verified
caller identity when the system security model requires identity. Network reachability, message
format, or possession of a public identifier is not authentication.

**Prevention controls:** [CSTYLE-110][c-code-standard-cstyle-110].

**Weakness context:** [CWE-306][cwe-306], [CWE-287][cwe-287]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Require verified identity for each critical endpoint according to its
security policy.

**Source context:** [authorization][c-common-pitfalls-ref-authorization].

**External references:** [CWE-306][cwe-306]; [CWE-287][cwe-287]; [OWASP prevention
guidance][owasp-authentication].

#### Local examples

**Failure fragment (do not execute):**

```c
int ADMIN_setKey(const uint8_t key[], size_t key_size)
{
    int ret = EXIT_SUCCESS;

    ret = KEYSTORE_write(key, key_size);

function_output:
    return ret;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Boundary owner validates input and applies the destination-specific safe API
before side effects
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Untrusted or mutable external input flows directly into sensitive
API/configuration/artifact path
```

---

<a id="cpit-113"></a>

<a id="cpit-113-incorrect-authorization-or-user-controlled-object-key"></a>

### CPIT-113: Incorrect authorization or user-controlled object key

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Authentication says who the caller is; authorization says which object and operation that caller may
access. Never infer authority merely because the caller supplied a valid object, record, device,
tenant, channel, or resource identifier.

**Prevention controls:** [CSTYLE-110][c-code-standard-cstyle-110].

**Weakness context:** [CWE-862][cwe-862], [CWE-863][cwe-863], [CWE-639][cwe-639]. See the [official
CWE catalogue][ref-cwe].

**Verification design:** Attempt the same operation on another user's or tenant's valid object ID
and require denial.

**Source context:** [authorization][c-common-pitfalls-ref-authorization].

**External references:** [CWE-862][cwe-862]; [CWE-863][cwe-863]; [CWE-639][cwe-639]; [OWASP
prevention guidance][owasp-authorization].

#### Local examples

**Failure fragment (do not execute):**

```c
ret = STORAGE_read(request->object_id, reply);
goto function_output;
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Authenticate caller and verify capability/ownership for the exact object and
operation before mutation
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Treat possession of object ID or debug command name as authorization
```

---

<a id="cpit-114"></a>

<a id="cpit-114-server-side-request-forgery"></a>

### CPIT-114: Server-side request forgery

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

A remote URL, host, address, protocol, port, or redirect target supplied by an untrusted actor can
turn a server into a proxy to loopback, link-local, management, metadata, or internal services.
Validate the resolved destination against an explicit outbound policy.

**Prevention controls:** [CSTYLE-112][c-code-standard-cstyle-112].

**Weakness context:** [CWE-918][cwe-918]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Test redirects, DNS rebinding, IPv4/IPv6 aliases, proxies, and resolved
internal destinations.

**Source context:** [ssrf][c-common-pitfalls-ref-ssrf].

**External references:** [CWE-918][cwe-918]; [CAPEC-664][capec-664]; [OWASP prevention
guidance][owasp-server-side-request-forgery-prevention].

#### Local examples

**Failure fragment (do not execute):**

```c
ret = HTTP_get(request->url, reply);
goto function_output;
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Resolve destination and enforce explicit scheme/host/IP/port/redirect policy
that blocks loopback/link-local/metadata/internal ranges
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Fetch attacker-controlled URL directly, including redirects to internal or
metadata endpoints
```

---

<a id="cpit-115"></a>

<a id="cpit-115-unbounded-resource-consumption"></a>

### CPIT-115: Unbounded resource consumption

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

A validated integer can still be dangerous when it controls allocation count, decoded objects,
parser depth, queue growth, threads, open files, retries, output bytes, or CPU work. Every
externally influenced resource needs an explicit engineering budget.

**Prevention controls:** [CSTYLE-113][c-code-standard-cstyle-113].

**Weakness context:** [CWE-770][cwe-770], [CWE-400][cwe-400]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Exhaust a bounded queue/input/work budget and require rejection or
backpressure without uncontrolled growth.

**Source context:** [validation][c-common-pitfalls-ref-validation].

**External references:** [CWE-770][cwe-770]; [CWE-400][cwe-400]; [OWASP prevention
guidance][owasp-denial-of-service].

#### Local examples

**Failure fragment (do not execute):**

```c
for (i = 0u; i < request->item_count; i++)
{
    items[i] = malloc(request->item_size);
}
```

**Failure fragment (do not execute):**

```c
for (i = 0u; i < request->item_count; ++i)
    items[i] = malloc(request->item_size);
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Boundary owner validates input and applies the destination-specific safe API
before side effects
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Untrusted or mutable external input flows directly into sensitive
API/configuration/artifact path
```

---

<a id="cpit-116"></a>

<a id="cpit-116-security-misconfiguration-or-active-debug-mode"></a>

### CPIT-116: Security misconfiguration or active debug mode

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Production must not depend on an operator remembering to disable factory credentials, debug
endpoints, unsafe fallbacks, permissive permissions, sample services, or test bypasses. Production
configuration is a controlled artifact and unsafe modes must fail closed or be absent from the
release variant.

**Prevention controls:** [CMOD-083][c-module-architecture-cmod-083].

**Weakness context:** [CWE-16][cwe-16], [CWE-489][cwe-489]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Build the production variant and verify test bypasses/default
credentials/debug paths cannot activate silently.

**Source context:** [supply-chain][c-common-pitfalls-ref-supply-chain];
[ssdf][c-common-pitfalls-ref-ssdf].

**External references:** [CWE-16][cwe-16]; [CWE-489][cwe-489]; [OWASP prevention
guidance][owasp-docker-security].

#### Local examples

**Failure fragment (do not execute):**

```c
if (getenv("DEBUG_UNLOCK") != (char *)(NULL))
{
    security_state = SECURITY_UNLOCKED;
}
```

**Failure fragment (do not execute):**

```c
if (getenv("DEBUG_UNLOCK") != (char *)(NULL))
    security_state = SECURITY_UNLOCKED;
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Production profile disables unsafe debug/factory bypasses and CI verifies the
profile
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Production unlocks privileged mode when DEBUG_UNLOCK environment variable
exists
```

---

<a id="cpit-117"></a>

<a id="cpit-117-software-supply-chain-dependency-failure"></a>

### CPIT-117: Software supply-chain dependency failure

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

A dependency that is untracked, unmaintained, fetched from an untrusted location, silently updated,
or known to be vulnerable can invalidate otherwise sound C code. Pin versions, inventory components,
verify origin/integrity, monitor CVE/KEV exposure, and maintain an upgrade/removal path.

**Prevention controls:** [CMOD-084][c-module-architecture-cmod-084].

**Weakness context:** [CWE-1104][cwe-1104], [CWE-1395][cwe-1395]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Match the shipped inventory to pinned inputs and record vulnerability
review with concrete affected versions.

**Source context:** [supply-chain][c-common-pitfalls-ref-supply-chain];
[ssdf][c-common-pitfalls-ref-ssdf].

**External references:** [CWE-1104][cwe-1104]; [CWE-1395][cwe-1395]; [CAPEC-439][capec-439]; [OWASP
prevention guidance][owasp-software-supply-chain-security].

#### Local examples

**Failure fragment (do not execute):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
curl https://example.invalid/latest.tar.gz | tar xz
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Pin dependency, verify source/integrity/provenance, inventory it, and review
CVE/KEV exposure
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Fetch mutable latest artifact from untrusted location with no
hash/signature/version ownership
```

---

<a id="cpit-118"></a>

<a id="cpit-118-untrusted-component-or-plugin-inclusion"></a>

### CPIT-118: Untrusted component or plugin inclusion

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Loading a shared object, plugin, script, firmware module, or configuration-driven code reference is
equivalent to accepting executable behavior. Use an allowlisted location and identity, verify
integrity/authenticity where required, and do not let an untrusted field select arbitrary code.

**Prevention controls:** [CMOD-086][c-module-architecture-cmod-086].

**Weakness context:** [CWE-829][cwe-829]. See the [official CWE catalogue][ref-cwe].

**Verification design:** Reject untrusted plugin identities, wrong ABI, substituted files, and
unsafe unload sequences.

**Source context:** [supply-chain][c-common-pitfalls-ref-supply-chain];
[ssdf][c-common-pitfalls-ref-ssdf].

**External references:** [CWE-829][cwe-829]; [CAPEC-175][capec-175]; [OWASP prevention
guidance][owasp-software-supply-chain-security].

#### Local examples

**Failure fragment (do not execute):**

```c
handle = dlopen(user_plugin_path, RTLD_NOW);
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Load only from approved location after authenticity/ABI/capability checks
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Search current directory or attacker-controlled environment path for
privileged plugin
```

---

<a id="cpit-119"></a>

<a id="cpit-119-log-injection-or-insufficient-security-logging"></a>

### CPIT-119: Log injection or insufficient security logging

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Untrusted text can forge line boundaries or structured fields, while missing authentication,
authorization, update, configuration, or integrity-failure records can make an attack invisible.
Encode untrusted log data and record security-relevant events without recording secrets.

**Prevention controls:** [CSTYLE-067][c-code-standard-cstyle-067].

**Weakness context:** [CWE-117][cwe-117], [CWE-778][cwe-778]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Submit line breaks/field delimiters and require structurally valid logs
plus required security events.

**Source context:** [logging][c-common-pitfalls-ref-logging].

**External references:** [CWE-117][cwe-117]; [CWE-778][cwe-778]; [OWASP prevention
guidance][owasp-logging].

#### Local examples

**Failure fragment (do not execute):**

```c
printf("user=%s\n", untrusted_user_field);
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Boundary owner validates input and applies the destination-specific safe API
before side effects
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Untrusted or mutable external input flows directly into sensitive
API/configuration/artifact path
```

---

<a id="cpit-120"></a>

<a id="cpit-120-fail-open-or-sensitive-error-disclosure"></a>

### CPIT-120: Fail-open or sensitive error disclosure

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Missing parameters, failed signature checks, storage errors, timeouts, invalid privileges, and
parser failures must not accidentally grant access or continue a privileged operation. Externally
visible errors should expose a stable status, not secrets, memory, paths, keys, stack data, or
internal security state.

**Prevention controls:** [CSTYLE-114][c-code-standard-cstyle-114].

**Weakness context:** [CWE-636][cwe-636], [CWE-209][cwe-209], [CWE-200][cwe-200]. See the [official
CWE catalogue][ref-cwe].

**Verification design:** Inject missing policy, storage errors, and timeouts; protected operations
remain denied without sensitive error data.

**Source context:** [authorization][c-common-pitfalls-ref-authorization].

**External references:** [CWE-636][cwe-636]; [CWE-209][cwe-209]; [CWE-200][cwe-200]; [OWASP
prevention guidance][owasp-error-handling].

#### Local examples

**Failure fragment (do not execute):**

```c
if (AUTH_verify(token) != 0)
{
    ret = ADMIN_execute(request);
    goto function_output;
}
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Boundary owner validates input and applies the destination-specific safe API
before side effects
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Untrusted or mutable external input flows directly into sensitive
API/configuration/artifact path
```

---

<a id="cpit-121"></a>

<a id="cpit-121-untrusted-search-path-or-environment-controlled-loader"></a>

### CPIT-121: Untrusted search path or environment-controlled loader

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

Current-working folders, writable directories, inherited `PATH`-like variables, and relative
library/plugin names can cause a process to load attacker-controlled content. Privileged/runtime
code must construct search locations from trusted policy.

**Prevention controls:** [CSTYLE-115][c-code-standard-cstyle-115].

**Weakness context:** [CWE-426][cwe-426], [CWE-427][cwe-427]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Manipulate working directory and loader environment; only approved
executable content may load.

**Source context:** [supply-chain][c-common-pitfalls-ref-supply-chain];
[ssdf][c-common-pitfalls-ref-ssdf].

**External references:** [CWE-426][cwe-426]; [CWE-427][cwe-427]; [CAPEC-471][capec-471]; [OWASP
prevention guidance][owasp-os-command-injection-defense].

#### Local examples

**Failure fragment (do not execute):**

```c
handle = dlopen("codec.so", RTLD_NOW);
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Load only from approved location after authenticity/ABI/capability checks
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Search current directory or attacker-controlled environment path for
privileged plugin
```

---

<a id="cpit-122"></a>

<a id="cpit-122-xml-external-entity-or-recursive-entity-expansion"></a>

### CPIT-122: XML external entity or recursive entity expansion

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

When XML is accepted from an untrusted boundary, a parser that resolves external entities or permits
unbounded recursive expansion can access local/network resources or consume unbounded memory/CPU.
Disable those features unless the protocol explicitly requires and safely constrains them.

**Prevention controls:** [CSTYLE-111][c-code-standard-cstyle-111].

**Weakness context:** [CWE-611][cwe-611], [CWE-776][cwe-776]. See the [official CWE
catalogue][ref-cwe].

**Verification design:** Supply external and recursive entities; reject resolution/expansion beyond
the explicitly allowed parser policy.

**Source context:** [xxe][c-common-pitfalls-ref-xxe].

**External references:** [CWE-611][cwe-611]; [CWE-776][cwe-776]; [CAPEC-201][capec-201]; [OWASP
prevention guidance][owasp-xml-external-entity-prevention].

#### Local examples

**Failure fragment (do not execute):**

```c
XML_parseWithExternalEntities(parser, packet, packet_size);
```

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Boundary owner validates input and applies the destination-specific safe API
before side effects
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Untrusted or mutable external input flows directly into sensitive
API/configuration/artifact path
```

---

<a id="cpit-155-a-supported-configuration-is-never-built"></a> <a id="cpit-155"></a>

<a id="cpit-155-supported-configuration-not-built"></a>

### CPIT-155: A supported configuration is never built

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CMOD-100`][c-module-architecture-cmod-100]

**A supported configuration is never built.** Conditional code compiles only for a non-default
compiler, byte order, width, optional feature, allocator, or hardening mode, but CI exercises only
the default. Inventory supported products and make every distinctive conditional branch owned by the
build-and-test matrix.

**External references:** [NIST secure development practices][nist-sp-800-218-ssdf-v11].

#### Local examples

**Contextual prevention example:**

Executable commands for the included hosted example. Sanitizers complement, not replace, ordinary
Release tests, target analysis or formal verification.

```sh
cmake -S examples -B build-sanitize -DSAMPLE_SANITIZE=ON
cmake --build build-sanitize
ctest --test-dir build-sanitize --output-on-failure
```

---

<a id="cpit-156-a-failure-path-exists-but-cannot-be-injected"></a> <a id="cpit-156"></a>

<a id="cpit-156-failure-path-not-injectable"></a>

### CPIT-156: A failure path exists but cannot be injected

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CMOD-101`][c-module-architecture-cmod-101]

**A failure path exists but cannot be injected.** Allocation, I/O, hardware, or dependency code
reports errors in theory, but no deterministic test can reach the cleanup and recovery branch. Put
injection at the owned adapter and verify status, invariant preservation, cleanup, retry bounds, and
observable effects.

**External references:** [CWE-755][cwe-755].

#### Local examples

**Contextual prevention example:**

Test-only allocator context. The failpoint index is illustrative; declare/zero `fault_state` at
entry and set this field after validation. Verify ownership and cleanup in addition to the expected
error.

```c
fault_state.fail_on_allocation = 2u;
ret                            = invoke_operation(operation_context);
if (ret != -ENOMEM)
{
        ret = -EDOM;
        goto function_output;
}

ret = verify_unchanged(operation_context);
```

---

<a id="cpit-157-generated-source-drift-hides-the-reviewed-input"></a> <a id="cpit-157"></a>

<a id="cpit-157-generated-source-drift"></a>

### CPIT-157: Generated source drift hides the reviewed input

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CMOD-103`][c-module-architecture-cmod-103]

**Generated source drift hides the reviewed input.** A committed C file is edited manually or
produced with an unknown tool version, so reviewers cannot reconstruct it from authoritative inputs.
Pin or declare the generator policy, regenerate in CI, compare output, and test the emitted
translation unit.

**External references:** [CWE-494][cwe-494]; [CAPEC-184][capec-184]; [OWASP prevention
guidance][owasp-ci-cd-security].

#### Local examples

**Contextual prevention example:**

Build manifest fields. Regeneration checks compare real digests; editing generated C without
updating its generating input violates this contract.

```c
typedef struct GeneratedSourceRecord
{
        const char *generator_revision;
        const char *input_digest;
        const char *invocation_record;
        const char *output_digest;
} generated_source_record_t;
```

---

<a id="cpit-158-imported-source-loses-upstream-lineage"></a> <a id="cpit-158"></a>

<a id="cpit-158-imported-source-loses-lineage"></a>

### CPIT-158: Imported source loses upstream lineage

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CMOD-104`][c-module-architecture-cmod-104]

**Imported source loses upstream lineage.** A local copy no longer records its origin revision,
patch series, or update owner. Security advisories and upstream fixes cannot be matched reliably.
Record immutable provenance and keep local functional patches reviewable and replayable.

**External references:** [CWE-1104][cwe-1104]; [CAPEC-439][capec-439]; [OWASP prevention
guidance][owasp-software-supply-chain-security].

#### Local examples

**Contextual prevention example:**

The record points to preserved upstream history and reviewed patches, not a guessed origin.

```c
typedef struct ImportedSourceRecord
{
        const char *upstream_repository;
        const char *upstream_revision;
        const char *local_patch_series;
        const char *license_id;
} imported_source_record_t;
```

---

<a id="cpit-170"></a>

<a id="cpit-170-stable-api-disappears-without-a-migration-window"></a>

### CPIT-170: Stable API disappears without a migration window

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CMOD-107`][c-module-architecture-cmod-107]

A stable API vanishes or changes contract without a deprecation state, replacement, release note, or
compatibility decision. Consumers discover the break only after upgrading.

Use the project API lifecycle registry and keep stable APIs through the approved migration window.

**External references:** [NIST secure development practices][nist-sp-800-218-ssdf-v11].

#### Local examples

**Contextual prevention example:**

Public-header transition example, with versioned contracts and a documented overlap/removal window.
The old function must remain implemented while promised; declarations alone do not provide ABI
compatibility.

```c
int MODULE_readV1(module_t *module, old_request_t const *request);
int MODULE_readV2(module_t *module, new_request_t const *request);
```

---

<a id="cpit-171"></a>

<a id="cpit-171-production-binary-omits-an-applicable-hardening-control"></a>

### CPIT-171: Production binary omits an applicable hardening control

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CMOD-108`][c-module-architecture-cmod-108]

One target bypasses the project hardening profile and ships without a mitigation that the platform
supports and the threat model requires.

Attach the named hardening profile and verify the resulting binary in CI.

**External references:** [CWE-693][cwe-693]; [OWASP prevention
guidance][owasp-c-based-toolchain-hardening].

#### Local examples

**Failure fragment (do not execute):**

Build/configuration excerpt for the named profile; resolve paths and targets in that project.

```cmake
target_link_libraries(app PRIVATE module_a module_b)
# The target never consumes project_hardening.
```

---

<a id="cpit-172"></a>

<a id="cpit-172-release-artifact-changes-without-a-source-or-toolchain-change"></a>

### CPIT-172: Release artifact changes without a source or toolchain change

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CMOD-106`][c-module-architecture-cmod-106]

Build time, locale, checkout path, directory enumeration order, or generated metadata changes the
release bytes despite identical approved inputs. The team then loses a strong comparison signal for
provenance and incident analysis.

Use stable inputs and source-derived reproducible metadata.

**External references:** [CWE-353][cwe-353]; [CAPEC-184][capec-184]; [OWASP prevention
guidance][owasp-ci-cd-security].

#### Local examples

**Failure fragment (do not execute):**

Build/configuration excerpt for the named profile; resolve paths and targets in that project.

```sh
date > generated/build_timestamp.txt
find src -type f > generated/source_order.txt
```

---

<a id="cpit-173"></a>

<a id="cpit-173-incompatible-abi-change-reaches-a-stable-release"></a>

### CPIT-173: Incompatible ABI change reaches a stable release

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CMOD-109`][c-module-architecture-cmod-109]

A candidate shared library passes source tests but removes an exported symbol or changes a public
type in a way that breaks an existing binary consumer.

Run the platform ABI compatibility gate against the supported baseline.

**External references:** [CWE-758][cwe-758].

#### Local examples

**Failure fragment (do not execute):**

Build/configuration excerpt for the named profile; resolve paths and targets in that project.

```sh
nm -D artifacts/candidate/libdevice.so > candidate.symbols
# No baseline ABI comparison occurs.
```

---

<a id="cpit-174-false-sharing-on-write-hot-state"></a> <a id="cpit-174"></a>

<a id="cpit-174-false-sharing-write-hot-state"></a>

### CPIT-174: False sharing on write-hot state

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CPERF-011`][c-code-standard-cperf-011]

Independent writers modify fields that occupy one coherence line. Profiling shows repeated ownership
transfer even though the logical states do not share a synchronization contract.

**External references:** [Linux false-sharing guidance][kernel-false-sharing].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use perf-c2c/PMU to prove coherence bouncing, then separate write
ownership/cache-line placement and remeasure
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Independent hot writers update different fields on same cache line and cause
repeated ownership transfers
```

---

<a id="cpit-175"></a>

<a id="cpit-175-numa-remote-hot-state-placement"></a>

### CPIT-175: NUMA-remote hot-state placement

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CPERF-020`][c-code-standard-cperf-020]

A hot thread, its memory, IRQ source, and device live on different NUMA nodes, so the critical path
crosses the interconnect for routine work.

**External references:** [Intel optimization reference][intel-optimization-manual].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Co-locate thread, memory, IRQ/device queue under one topology policy and
benchmark remote/local traffic
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Pin CPU on one socket while hot memory/device remains on another without
measurement
```

---

<a id="cpit-176"></a>

<a id="cpit-176-store-buffer-saturation"></a>

### CPIT-176: Store-buffer saturation

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CPERF-018`][c-code-standard-cperf-018]

A hot loop issues enough stores to make store-side resources the throughput limit, including stores
whose values do not change observable state.

**External references:** [Intel optimization reference][intel-optimization-manual].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
PMU identifies store-buffer/full-store-queue stalls; reduce/coalesce redundant
writes and verify throughput
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Hot loop emits unnecessary stores every iteration while store buffer is the
measured bottleneck
```

---

<a id="cpit-177"></a>

<a id="cpit-177-store-to-load-forwarding-stall"></a>

### CPIT-177: Store-to-load forwarding stall

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CPERF-016`][c-code-standard-cperf-016]

A dependent load overlaps an earlier store with a geometry the target cannot forward efficiently.

**External references:** [Intel optimization reference][intel-optimization-manual].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use compatible store/load size/alignment or reschedule dependency after PMU
confirms forwarding failure
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Write byte/partial word then immediately read a wider overlapping value from
same address
```

---

<a id="cpit-178-false-4-kib-memory-dependency"></a> <a id="cpit-178"></a>

<a id="cpit-178-false-4k-memory-dependency"></a>

### CPIT-178: False 4 KiB memory dependency

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CPERF-017`][c-code-standard-cperf-017]

Independent load and store streams share low address bits and the target's memory disambiguator
treats them as potentially dependent.

**External references:** [Intel optimization reference][intel-optimization-manual].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Counters identify 4 KiB alias stalls; adjust hot buffer offset/access schedule
and verify lower replays
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Independent producer/consumer buffers repeatedly share low 12 address bits and
trigger false dependency
```

---

<a id="cpit-179-split-lock-or-cross-line-atomic"></a> <a id="cpit-179"></a>

<a id="cpit-179-split-lock-cross-line-atomic"></a>

### CPIT-179: Split lock or cross-line atomic

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CPERF-019`][c-code-standard-cperf-019]

A locked or atomic operand crosses the target coherence boundary and turns one operation into an
exceptional machine-level path.

**External references:** [Intel optimization reference][intel-optimization-manual].

#### Local examples

**Contextual prevention example:**

```c
value = atomic_load_explicit(&shared, memory_order_acquire);
```

**Noncompliant fragment (do not copy):**

```c
value = shared; /* lockless shared state read as ordinary object */
```

---

<a id="cpit-180-tlb-shootdown-or-page-walk-pressure"></a> <a id="cpit-180"></a>

<a id="cpit-180-tlb-shootdown-page-walk-pressure"></a>

### CPIT-180: TLB shootdown or page-walk pressure

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rules:** [`CPERF-021`][c-code-standard-cperf-021],
[`CPERF-022`][c-code-standard-cperf-022]

The workload spends material time invalidating translations or walking page tables even though
ordinary cache-miss rates look acceptable.

**External references:** [Intel optimization reference][intel-optimization-manual].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use stable mappings/small invalidation scope and improve translation locality
when PMU shows page-walk/shootdown cost
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Frequent global mapping changes trigger remote TLB shootdowns in hot path
```

---

<a id="cpit-181-cache-set-conflict-mistaken-for-capacity-pressure"></a> <a id="cpit-181"></a>

<a id="cpit-181-cache-set-conflict-misdiagnosis"></a>

### CPIT-181: Cache-set conflict mistaken for capacity pressure

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CPERF-023`][c-code-standard-cperf-023]

A small address set repeatedly maps to the same cache sets, causing eviction that a simple
total-cache-capacity calculation does not predict.

**External references:** [Intel optimization reference][intel-optimization-manual].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Counters show conflict misses despite available nominal capacity; test
allocator/set/page-color placement experimentally
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Treat every LLC miss as capacity pressure and add cache/huge memory without
checking set conflicts
```

---

<a id="cpit-182-software-prefetch-distance-or-usefulness-failure"></a> <a id="cpit-182"></a>

<a id="cpit-182-software-prefetch-distance-failure"></a>

### CPIT-182: Software prefetch distance or usefulness failure

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CPERF-035`][c-code-standard-cperf-035]

Software prefetch arrives after demand, arrives so early that useful data gets evicted, or
duplicates work already done by the hardware prefetcher.

**External references:** [Intel optimization reference][intel-optimization-manual].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Tune prefetch distance/compiler placement and verify cache/TLB/bandwidth
effects with representative workload
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Insert prefetch immediately before use or copy a distance from another CPU
```

---

<a id="cpit-183-hardware-prefetch-increases-pollution-or-bandwidth-pressure"></a>
<a id="cpit-183"></a>

<a id="cpit-183-hardware-prefetch-pollution"></a>

### CPIT-183: Hardware prefetch increases pollution or bandwidth pressure

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CPERF-047`][c-code-standard-cperf-047]

Automatic prefetch follows a stream that the workload does not consume and uses cache capacity,
miss-handling resources, or memory bandwidth needed by demand accesses.

**External references:** [Intel optimization reference][intel-optimization-manual].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Tune prefetch distance/compiler placement and verify cache/TLB/bandwidth
effects with representative workload
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Insert prefetch immediately before use or copy a distance from another CPU
```

---

<a id="cpit-184"></a>

<a id="cpit-184-non-temporal-store-misuse"></a>

### CPIT-184: Non-temporal store misuse

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CPERF-037`][c-code-standard-cperf-037]

A streaming-store path bypasses cache for data that the program reuses soon, or publishes completion
without the ordering required by the target.

**External references:** [Intel optimization reference][intel-optimization-manual].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use NT/WC path only for measured streaming write pattern with correct
publication fence/order
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use NT stores for reused small data or publish ready before weakly ordered
writes are complete
```

---

<a id="cpit-185"></a>

<a id="cpit-185-cross-owner-free-coordination-storm"></a>

### CPIT-185: Cross-owner free coordination storm

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CPERF-045`][c-code-standard-cperf-045]

Objects move between allocator owners and are freed remotely at high frequency, creating atomic
traffic, deferred reclamation, or owner-shutdown pressure.

**External references:** [Intel optimization reference][intel-optimization-manual].

#### Local examples

**Contextual prevention example:**

Cross-owner free port. The ID is a validated non-pointer handle with generation protection. Success
transfers release responsibility exactly once; failure retains it with the caller. Queue drain and
owner shutdown are part of the contract.

```c
ret = enqueue_remote_free(queue_context, allocation_id);
if (ret != EXIT_SUCCESS)
        goto function_output;
allocation_id = INVALID_ALLOCATION_ID;
```

---

<a id="cpit-186"></a>

<a id="cpit-186-atomic-coherence-hotspot"></a>

### CPIT-186: Atomic coherence hotspot

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CPERF-024`][c-code-standard-cperf-024]

Many execution contexts update one global atomic cache line. Coherence transfer, not arithmetic,
becomes the serialization point.

**External references:** [Linux false-sharing guidance][kernel-false-sharing].

#### Local examples

**Contextual prevention example:**

```c
value = atomic_load_explicit(&shared, memory_order_acquire);
```

**Noncompliant fragment (do not copy):**

```c
value = shared; /* lockless shared state read as ordinary object */
```

---

<a id="cpit-187-front-end-footprint-and-predictor-pressure"></a> <a id="cpit-187"></a>

<a id="cpit-187-frontend-footprint-predictor-pressure"></a>

### CPIT-187: Front-end footprint and predictor pressure

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rules:** [`CPERF-028`][c-code-standard-cperf-028],
[`CPERF-030`][c-code-standard-cperf-030], [`CPERF-033`][c-code-standard-cperf-033]

Inlining, duplicated specialization, branchless conversion, or unstable indirect dispatch increases
I-cache, decoded-uop, BTB, or dependency pressure on the measured target.

**External references:** [Intel optimization reference][intel-optimization-manual].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Front-end PMU shows I-cache/uop/BTB/return-predictor bottleneck; change
inlining/layout/dispatch and remeasure
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Optimize data path while huge inlined/unrolled code and unstable indirect
branches saturate front end
```

---

<a id="cpit-188"></a>

<a id="cpit-188-nonrepresentative-performance-profile"></a>

### CPIT-188: Nonrepresentative performance profile

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rules:** [`CPERF-001`][c-code-standard-cperf-001],
[`CPERF-003`][c-code-standard-cperf-003]

A benchmark or PGO profile exercises different data sizes, branch frequencies, CPU policy,
concurrency, or request mix from deployment and drives the optimizer toward the wrong objective.

**External references:** [Intel optimization reference][intel-optimization-manual].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use representative versioned profile from deployment-like workload and store
target/toolchain metadata
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Optimize layout/PGO using a synthetic profile unrelated to production behavior
```

---

<a id="cpit-189"></a>

<a id="cpit-189-contention-policy-creates-a-spin-storm-or-thundering-herd"></a>

### CPIT-189: Contention policy creates a spin storm or thundering herd

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CPERF-046`][c-code-standard-cperf-046]

Waiters spin without a bound or a releaser wakes many waiters when only one can make progress. CPU
time and scheduler work rise while useful throughput stays flat.

**External references:** [Intel optimization reference][intel-optimization-manual].

#### Local examples

**Contextual prevention example:**

Synchronization-owner fragment. Entry-declared counters/flags; validated callbacks.
`park_until_change` must atomically verify the generation before sleeping to avoid a lost wakeup.
Waking does not grant ownership; the caller retries acquisition before touching protected data.

```c
while (!is_ready && (attempt_count < spin_limit))
{
        is_ready = try_acquire(lock_context);
        attempt_count++;
}

if (!is_ready)
{
        ret = park_until_change(lock_context, observed_generation);
        if (ret != EXIT_SUCCESS)
                goto function_output;
}
```

---

<a id="cpit-190-partial-line-dma-or-streaming-transaction"></a> <a id="cpit-190"></a>

<a id="cpit-190-partial-line-dma-streaming-transaction"></a>

### CPIT-190: Partial-line DMA or streaming transaction

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rules:** [`CPERF-036`][c-code-standard-cperf-036],
[`CPERF-038`][c-code-standard-cperf-038]

The device or CPU emits repeated partial coherence-unit writes where the target could combine
complete cache-line transactions.

**External references:** [Intel optimization reference][intel-optimization-manual].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
DMA owner follows platform cache clean/invalidate, alignment,
ownership-transfer, and ordering contract
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
CPU and DMA access same buffer with no cache-coherency/ownership protocol
```

---

<a id="cpit-191-independent-hot-locks-share-one-coherence-unit"></a> <a id="cpit-191"></a>

<a id="cpit-191-independent-hot-lock-coherence-coupling"></a>

### CPIT-191: Independent hot locks share one coherence unit

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rules:** [`CPERF-012`][c-code-standard-cperf-012],
[`CPERF-044`][c-code-standard-cperf-044]

Unrelated locks or flags share one word or cache line, so independent owners create avoidable
coherence traffic.

**External references:** [Linux false-sharing guidance][kernel-false-sharing].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
PMU/perf-c2c identifies coherence contention; separate write ownership and
remeasure
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Independent hot writers share/adjacent-prefetch the same coherence domain and
repeatedly bounce lines
```

---

<a id="cpit-192-specialized-artifact-executes-after-its-invariant-changed"></a>
<a id="cpit-192"></a>

<a id="cpit-192-stale-specialized-artifact"></a>

### CPIT-192: Specialized artifact executes after its invariant changed

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CPERF-008`][c-code-standard-cperf-008]

Cached code, a function binding, or another specialized artifact remains active after the state used
to specialize it changes.

**External references:** [CWE-758][cwe-758].

#### Local examples

**Contextual prevention example:**

Externally synchronized owner fragment. Generation changes cover every assumed invariant; wrap/reuse
is prohibited while an older artifact may exist. invalidate, bind and execute are validated owner
callbacks. Rebinding must not publish a partial artifact.

```c
if (cached_generation != current_generation)
{
        ret = invalidate(cache_context);
        if (ret != EXIT_SUCCESS)
                goto function_output;
        ret = bind(cache_context, current_generation);
        if (ret != EXIT_SUCCESS)
                goto function_output;
}

ret = execute(cache_context);
```

---

<a id="cpit-193"></a>

<a id="cpit-193-mixed-declarator-type-confusion"></a>

### CPIT-193: Mixed declarator type confusion

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-138`][c-code-standard-cstyle-138]

**CWE:** [CWE-704][cwe-704], [CWE-843][cwe-843]

A declaration such as `int *a, b;` gives `a` and `b` different indirection even though the visual
prefix is shared. Mixing pointers, arrays, function pointers, and scalars in one declaration makes
review and later edits prone to type mistakes.

**External references:** [CWE-704][cwe-704].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-194"></a>

<a id="cpit-194-pointer-typedef-qualification-confusion"></a>

### CPIT-194: Pointer typedef qualification confusion

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-141`][c-code-standard-cstyle-141]

**CWE:** [CWE-704][cwe-704]

A pointer hidden behind `typedef` changes the meaning of qualifiers in ways that are easy to
misread. `const handle_t` may make the pointer itself const rather than the pointed object. Keep
ordinary indirection visible.

**External references:** [CWE-704][cwe-704].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-195"></a>

<a id="cpit-195-raw-storage-reinterpreted-without-a-typed-storage-contract"></a>

### CPIT-195: Raw storage reinterpreted without a typed-storage contract

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-156`][c-code-standard-cstyle-156]

**CWE:** [CWE-704][cwe-704], [CWE-758][cwe-758]

A byte buffer may have enough bytes for an object while still lacking the required alignment,
effective-type/lifetime conditions, or valid pointer provenance for typed access. This appears
frequently in arenas, packet buffers, DMA memory, and custom allocators.

**External references:** [CWE-843][cwe-843].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-196"></a>

<a id="cpit-196-compound-literal-pointer-escapes-its-lifetime"></a>

### CPIT-196: Compound literal pointer escapes its lifetime

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-153`][c-code-standard-cstyle-153]

**CWE:** [CWE-825][cwe-825], [CWE-562][cwe-562]

A block-scope compound literal has automatic storage duration for its enclosing block. If a callee
retains its address beyond that lifetime, the pointer becomes dangling in the same way as a retained
address of an ordinary local object.

**External references:** [CWE-562][cwe-562].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Establish pointer provenance, lifetime, nullability, ownership, alignment, and
bounds before dereference
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Dereference/copy/free a pointer whose provenance or lifetime contract is not
established
```

---

<a id="cpit-197"></a>

<a id="cpit-197-undocumented-implementation-defined-dependency"></a>

### CPIT-197: Undocumented implementation-defined dependency

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-248`][c-code-standard-cstyle-248]

**CWE:** [CWE-758][cwe-758]

The program produces the expected result only because the current compiler, ABI, or architecture
chooses one permitted implementation-defined behavior. Porting or changing flags silently changes
semantics because the dependency was never recorded.

**External references:** [CWE-758][cwe-758].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use a language-defined representation/access pattern and validate every
precondition
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Depend on undefined/unspecified behavior and treat one compiler build as proof
of correctness
```

---

<a id="cpit-198"></a>

<a id="cpit-198-non-finite-floating-input-enters-a-finite-value-algorithm"></a>

### CPIT-198: Non-finite floating input enters a finite-value algorithm

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-264`][c-code-standard-cstyle-264]

**CWE:** [CWE-20][cwe-20], [CWE-682][cwe-682]

NaN and infinity can bypass ordinary range reasoning: comparisons with NaN do not behave like
comparisons with a very large or very small finite number. Sensor, network, or file inputs that feed
finite physical limits need an explicit exceptional- value check.

**External references:** [CWE-682][cwe-682].

#### Local examples

**Contextual prevention example:**

```c
if ((index >= 0) && ((size_t)index < count))
        value = array[(size_t)index];
```

**Noncompliant fragment (do not copy):**

```c
if (index < count)
{
    value = array[index]; /* signed/unsigned domain mixed */
}
```

---

<a id="cpit-199"></a>

<a id="cpit-199-secret-comparison-leaks-through-timing"></a>

### CPIT-199: Secret comparison leaks through timing

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-269`][c-code-standard-cstyle-269]

**CWE:** [CWE-208][cwe-208]

An ordinary `memcmp` or early-exit equality loop can reveal how much of a secret matched through
execution time or related microarchitectural effects. Use a reviewed constant-time primitive for
secrets when the threat model exposes timing.

**External references:** [CWE-208][cwe-208].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use the project wrapper that carries capacity/error/ownership semantics and
check its result
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Call a reviewed/banned libc API directly without satisfying its preconditions
```

---

<a id="cpit-200"></a>

<a id="cpit-200-compiler-transformation-breaks-a-lockless-access-protocol"></a>

### CPIT-200: Compiler transformation breaks a lockless access protocol

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-259`][c-code-standard-cstyle-259]

**CWE:** [CWE-362][cwe-362], [CWE-667][cwe-667]

A lockless algorithm assumes a source read/store occurs once, but the compiler merges, splits,
reloads, eliminates, or invents accesses under ordinary C rules. The protocol needs an approved
atomic or one-time-access primitive, not hope about generated code.

**External references:** [CWE-362][cwe-362].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use approved READ_ONCE/WRITE_ONCE-style primitive or atomic operation that
establishes compiler access semantics required by protocol
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Ordinary C access is assumed to compile to exactly one load/store in a
lockless protocol
```

---

<a id="cpit-201"></a>

<a id="cpit-201-ad-hoc-atomic-protocol-lacks-one-invariant-owner"></a>

### CPIT-201: Ad hoc atomic protocol lacks one invariant owner

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-260`][c-code-standard-cstyle-260]

**CWE:** [CWE-362][cwe-362], [CWE-667][cwe-667]

Multiple call sites assemble their own loads, compare-and-swap loops, fences, and state transitions
for the same shared object. Small differences in memory order or failure handling create races that
no one function owns or documents.

**External references:** [CWE-362][cwe-362].

#### Local examples

**Contextual prevention example:**

```c
value = atomic_load_explicit(&shared, memory_order_acquire);
```

**Noncompliant fragment (do not copy):**

```c
value = shared; /* lockless shared state read as ordinary object */
```

---

<a id="cpit-202"></a>

<a id="cpit-202-unpaired-or-unjustified-memory-barrier"></a>

### CPIT-202: Unpaired or unjustified memory barrier

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-261`][c-code-standard-cstyle-261]

**CWE:** [CWE-362][cwe-362], [CWE-667][cwe-667]

A fence is inserted because “ordering is needed” without naming the accesses or other observer. The
barrier may be too weak, too strong, on the wrong side, or entirely irrelevant to the actual
synchronization relation.

**External references:** [CWE-362][cwe-362].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Barrier/order primitive names the producer/consumer pairing, protected data
and why weaker order is insufficient
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Insert full fence “for safety” with no matching protocol, or omit required
publication/acquire pairing
```

---

<a id="cpit-203"></a>

<a id="cpit-203-raw-mmio-access-bypasses-the-platform-register-contract"></a>

### CPIT-203: Raw MMIO access bypasses the platform register contract

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-265`][c-code-standard-cstyle-265]

**CWE:** [CWE-664][cwe-664], [CWE-758][cwe-758]

Direct register dereferences scattered across modules bypass the one place that knows width,
ordering, reserved bits, W1C/read-clear semantics, barriers, fault-injection hooks, and
simulator/test substitution. The code may work on one revision and fail on another without an
architectural owner.

**External references:** [CWE-119][cwe-119].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Hardware interaction goes through a platform-owned contract that documents
register/DMA/ISR timing and ordering
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Ordinary module accesses raw hardware state with undocumented timing,
coherency, or reserved-bit assumptions
```

---

<a id="cpit-204"></a>

<a id="cpit-204-single-fault-flips-a-security-critical-decision"></a>

### CPIT-204: Single fault flips a security-critical decision

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-266`][c-code-standard-cstyle-266]

**CWE:** [CWE-1332][cwe-1332] **CAPEC:** [CAPEC-624][capec-624]

A security decision such as verified/not-verified or locked/unlocked is represented by a single
easy-to-flip bit or a single branch. Under a physical fault-injection threat model, an instruction
skip or data fault can invert the decision. Harden only the states named by that threat model;
ordinary logic does not need this representation.

**External references:** [CWE-1332][cwe-1332]; [CAPEC-624][capec-624].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use reviewed compiler-aware hardened primitive and verify critical side-effect
sequence under declared physical threat model
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Duplicate ordinary C checks and assume compiler emits independent
fault-resistant machine instructions
```

---

<a id="cpit-205"></a>

<a id="cpit-205-compiler-removes-intended-fault-detection-redundancy"></a>

### CPIT-205: Compiler removes intended fault-detection redundancy

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-267`][c-code-standard-cstyle-267]

**CWE:** [CWE-1332][cwe-1332] **CAPEC:** [CAPEC-624][capec-624]

Two identical source checks are written for fault resistance, but the optimizer proves them
redundant and emits one effective check. Source duplication is not machine-code redundancy unless a
hardening primitive and generated-code review establish it.

**External references:** [CWE-1332][cwe-1332]; [CAPEC-624][capec-624].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use reviewed compiler-aware hardened primitive and verify critical side-effect
sequence under declared physical threat model
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Duplicate ordinary C checks and assume compiler emits independent
fault-resistant machine instructions
```

---

<a id="cpit-206"></a>

<a id="cpit-206-fault-sensitive-critical-action-sequence-is-only-end-state-checked"></a>

### CPIT-206: Fault-sensitive critical action sequence is only end-state checked

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-268`][c-code-standard-cstyle-268]

**CWE:** [CWE-1332][cwe-1332], [CWE-1256][cwe-1256] **CAPEC:** [CAPEC-624][capec-624]

A privileged hardware sequence requires several writes in a specific order, but code checks only the
final value. A skipped unlock/lock/check instruction can leave the final register looking plausible
while the intended security transition never occurred correctly.

**External references:** [CWE-841][cwe-841]; [CWE-1332][cwe-1332]; [CAPEC-624][capec-624].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use reviewed compiler-aware hardened primitive and verify critical side-effect
sequence under declared physical threat model
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Duplicate ordinary C checks and assume compiler emits independent
fault-resistant machine instructions
```

---

<a id="cpit-207"></a>

<a id="cpit-207-monolithic-growth-causes-allocator-or-latency-failure"></a>

### CPIT-207: Monolithic growth causes allocator or latency failure

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-256`][c-code-standard-cstyle-256]

**CWE:** [CWE-400][cwe-400], [CWE-770][cwe-770]

A long-lived service repeatedly grows one contiguous container. Reallocation copies a large working
set, requires an increasingly large contiguous block, invalidates interior pointers, and creates
latency spikes or fragmentation even when total free memory remains adequate.

**External references:** [CWE-400][cwe-400].

#### Local examples

**Contextual prevention example:**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Boundary owner validates input and applies the destination-specific safe API
before side effects
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Untrusted or mutable external input flows directly into sensitive
API/configuration/artifact path
```

---

<a id="cpit-208"></a>

<a id="cpit-208-unjustified-code-alignment-patch-geometry"></a>

### CPIT-208: Unjustified code alignment or patch geometry

**Class:** FAILURE_SCENARIO. Apply the scope and requirement words below.

**Primary prevention rule:** [`CSTYLE-241`][c-code-standard-cstyle-241]

Manual alignment can increase code footprint or move other hot blocks into worse positions. Runtime
patch sites add an atomicity and instruction-cache synchronization constraint; a boundary that helps
one microarchitecture can hurt another.

**External references:** [Intel optimization reference][intel-optimization-manual].

#### Local examples

**Contextual prevention example:**

```c
alignas(foo_t) uint8_t storage[sizeof(foo_t)] = { 0 };
foo_t *foo                                    = (foo_t *)storage;
```

**Noncompliant fragment (do not copy):**

```c
foo_t *foo = (foo_t *)(storage + 1u);
```

---

<a id="worked-example"></a>

## Appendix A. Complete host regression program

This test translation unit links the complete sources in the two normative documents. Its ten named
test groups cover checked size arithmetic, bounded numeric parsing, wire encoding/decoding,
allocation failure, failure atomicity, zero/capacity boundaries, callback failure, reentry
rejection, invalid contract arguments, and composed ownership. The test allocator counts its bounded
fixture allocations and can reject the next allocation without freeing the old one.

`test_require` has a documented host-test fatal policy. A failed test stops the process even in
release builds; it is not compiled out by NDEBUG. Negative tests exercise documented rejection
paths, including BUSY during a synchronous callback. They are not examples of permitted production
reentry. No test passes a dangling pointer, performs invalid free, or depends on undefined behavior
to count as a pass.

The suite does not claim to exercise every CPIT. Thread races, GC relocation, real-time behavior,
hardware protocols, cryptography, web services, and runtime plugin loading need separate
implementations and target-specific evidence.

---

<a id="example-tests-test_main-c"></a>

### `tests/test_main.c`

<!-- example-file: tests/test_main.c -->

```c
/*
 * SPDX-FileCopyrightText: 2026 Rafael V. Volkmer
 * SPDX-License-Identifier: GPL-3.0-only
 */

#if __STDC_VERSION__ < 202311L
  #include <stdbool.h>
#endif
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "buffer.h"
#include "buffer_sink.h"
#include "checked.h"
#include "emitter.h"
#include "emitter_port.h"
#include "host_memory.h"
#include "memory_port.h"
#include "project_status.h"

#define TEST_PAIR_SIZE      2u
#define TEST_TRIPLE_SIZE    3u
#define TEST_U32_SIZE       4u
#define TEST_PRESERVED_SIZE 7u
#define TEST_INITIAL_SIZE   8u
#define TEST_U32_TEXT_SIZE  10u
#define TEST_LONG_TEXT_SIZE 11u
#define TEST_OUTPUT_SIZE    16u

#define TEST_BUDGET ((size_t)TEST_OUTPUT_SIZE)

static const uint8_t test_wire_expected[] = { 0x12u, 0x34u, 0x56u, 0x78u };
static const uint8_t test_atomic_input[]  = { 5u, 6u };
static const uint8_t test_input[] = { 1u, TEST_PAIR_SIZE, TEST_TRIPLE_SIZE };
static const uint8_t test_oversized[TEST_U32_SIZE] = { 0 };

/* Host-test profile: a failed invariant terminates this test process. */
static void test_require(bool condition, const char *description)
{
        int ret = PROJECT_OK;

        if (!condition)
        {
                ret = fprintf(stderr, "FAIL: %s\n", description);
                (void)ret;
                abort();
        }

        goto function_output;

function_output:
        return;
}

/* Counters are bounded by this finite test suite, not external input. */
typedef struct FaultMemory
{
        size_t live_count;
        size_t resize_calls;

        bool fail_next;
} fault_memory_t;

static void *test_alloc(void *context, size_t size_bytes)
{
        void *ret = (void *)(NULL);

        fault_memory_t *fault = (fault_memory_t *)(NULL);

        test_require(context != (void *)(NULL), "fault context is present");
        test_require(size_bytes != 0u, "allocation size is positive");
        fault = (fault_memory_t *)context;
        if (fault->fail_next)
        {
                fault->fail_next = false;
                goto function_output;
        }

        ret = (void *)malloc(size_bytes);
        if (ret != (void *)(NULL))
                fault->live_count++;

function_output:
        return ret;
}

/* CSTYLE-057: callback ABI fixes the context/base parameter order. */
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
static void *test_resize(void *context, void *base, size_t size_bytes)
{
        void *ret = (void *)(NULL);

        fault_memory_t *fault = (fault_memory_t *)(NULL);

        test_require(context != (void *)(NULL), "fault context is present");
        test_require(base != (void *)(NULL), "resize has an owned base");
        test_require(size_bytes != 0u, "resize never receives zero");
        fault = (fault_memory_t *)context;
        fault->resize_calls++;
        if (fault->fail_next)
        {
                fault->fail_next = false;
                goto function_output;
        }

        /* CBAN-068: hosted adapter preserves base on allocation failure. */
        // NOLINTNEXTLINE(bugprone-unsafe-functions)
        ret = (void *)realloc(base, size_bytes);

function_output:
        return ret;
}

/* CSTYLE-057: callback ABI fixes the context/base parameter order. */
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
static void test_release(void *context, void *base)
{
        fault_memory_t *fault = (fault_memory_t *)(NULL);

        test_require(context != (void *)(NULL), "fault context is present");
        fault = (fault_memory_t *)context;
        if (base != (void *)(NULL))
        {
                test_require(fault->live_count != 0u,
                             "release has a live owner");
                fault->live_count--;
        }

        free(base);
        goto function_output;

function_output:
        return;
}

static memory_port_t test_memory(fault_memory_t *fault)
{
        memory_port_t ret = { 0 };

        test_require(fault != (fault_memory_t *)(NULL),
                     "fault owner is present");
        ret.context = fault;
        ret.alloc   = test_alloc;
        ret.resize  = test_resize;
        ret.release = test_release;
        goto function_output;

function_output:
        return ret;
}

static void test_checkedArithmetic(void)
{
        int    ret    = PROJECT_OK;
        size_t result = 0u;

        result = TEST_PRESERVED_SIZE;
        ret    = CHECKED_addSize(SIZE_MAX, 1u, &result);
        test_require(ret == PROJECT_ERR_RANGE, "add rejects overflow");
        test_require(result == TEST_PRESERVED_SIZE,
                     "add failure preserves output");
        ret = CHECKED_mulSize(SIZE_MAX, TEST_PAIR_SIZE, &result);
        test_require(ret == PROJECT_ERR_RANGE, "multiply rejects overflow");
        test_require(result == TEST_PRESERVED_SIZE,
                     "multiply failure preserves output");
        ret = CHECKED_mulSize(SIZE_MAX, 0u, &result);
        test_require(ret == PROJECT_OK, "multiply accepts zero");
        test_require(result == 0u, "multiply zero result");
        ret = CHECKED_addSize(SIZE_MAX, 0u, &result);
        test_require(ret == PROJECT_OK, "add accepts exact maximum");
        test_require(result == SIZE_MAX, "add maximum result");
        ret = CHECKED_mulSize(1u, 1u, (size_t *)(NULL));
        test_require(ret == PROJECT_ERR_INVALID, "multiply rejects NULL out");
        ret = CHECKED_addSize(1u, 1u, (size_t *)(NULL));
        test_require(ret == PROJECT_ERR_INVALID, "add rejects NULL out");
        goto function_output;

function_output:
        return;
}

static void test_numericParser(void)
{
        int ret = PROJECT_OK;

        uint32_t value = 0u;

        value = TEST_INITIAL_SIZE;
        ret   = CHECKED_parseU32("4294967295", TEST_U32_TEXT_SIZE, &value);
        test_require(ret == PROJECT_OK, "parser accepts UINT32_MAX");
        test_require(value == UINT32_MAX, "parser value is exact");
        ret = CHECKED_parseU32("4294967296", TEST_U32_TEXT_SIZE, &value);
        test_require(ret == PROJECT_ERR_RANGE, "parser rejects overflow");
        test_require(value == UINT32_MAX, "parser failure preserves output");
        ret = CHECKED_parseU32("-1", TEST_PAIR_SIZE, &value);
        test_require(ret == PROJECT_ERR_INVALID, "parser rejects negative");
        ret = CHECKED_parseU32(" 1", TEST_PAIR_SIZE, &value);
        test_require(ret == PROJECT_ERR_INVALID, "parser rejects whitespace");
        ret = CHECKED_parseU32("1x", TEST_PAIR_SIZE, &value);
        test_require(ret == PROJECT_ERR_INVALID, "parser rejects suffix");
        ret = CHECKED_parseU32("", 0u, &value);
        test_require(ret == PROJECT_ERR_RANGE, "parser rejects empty");
        ret = CHECKED_parseU32("00000000000", TEST_LONG_TEXT_SIZE, &value);
        test_require(ret == PROJECT_ERR_RANGE, "parser bounds work");
        ret = CHECKED_parseU32((const char *)(NULL), 0u, &value);
        test_require(ret == PROJECT_ERR_INVALID, "parser rejects NULL input");
        ret = CHECKED_parseU32("0", 1u, (uint32_t *)(NULL));
        test_require(ret == PROJECT_ERR_INVALID, "parser rejects NULL output");
        ret = CHECKED_parseU32("0", 1u, &value);
        test_require((bool)((ret == PROJECT_OK) && (value == 0u)),
                     "parser accepts zero");
        goto function_output;

function_output:
        return;
}

static void test_wireCodec(void)
{
        int ret = PROJECT_OK;

        uint8_t  bytes[TEST_U32_SIZE] = { 0 };
        uint32_t value                = 0u;

        ret = CHECKED_encodeU32(UINT32_C(0x12345678), bytes, sizeof(bytes));
        test_require(ret == PROJECT_OK, "encoder accepts capacity");
        test_require(memcmp(bytes, test_wire_expected,
                            sizeof(test_wire_expected)) == 0,
                     "encoder produces big endian bytes");
        ret = CHECKED_decodeU32(bytes, sizeof(bytes), &value);
        test_require(ret == PROJECT_OK, "decoder accepts exact frame");
        test_require(value == UINT32_C(0x12345678), "codec round trip");
        ret = CHECKED_decodeU32(bytes, TEST_TRIPLE_SIZE, &value);
        test_require(ret == PROJECT_ERR_RANGE, "decoder rejects truncation");
        ret = CHECKED_encodeU32(0u, bytes, TEST_TRIPLE_SIZE);
        test_require(ret == PROJECT_ERR_CAPACITY, "encoder rejects short out");
        test_require(memcmp(bytes, test_wire_expected,
                            sizeof(test_wire_expected)) == 0,
                     "failed encoding preserves output");
        ret = CHECKED_decodeU32((const uint8_t *)(NULL), TEST_U32_SIZE, &value);
        test_require(ret == PROJECT_ERR_INVALID, "decoder rejects NULL input");
        ret = CHECKED_decodeU32(bytes, TEST_U32_SIZE, (uint32_t *)(NULL));
        test_require(ret == PROJECT_ERR_INVALID, "decoder rejects NULL output");
        ret = CHECKED_encodeU32(0u, (uint8_t *)(NULL), TEST_U32_SIZE);
        test_require(ret == PROJECT_ERR_INVALID, "encoder rejects NULL output");
        goto function_output;

function_output:
        return;
}

static void test_bufferAllocationFailure(void)
{
        int ret = PROJECT_OK;

        fault_memory_t fault   = { 0 };
        memory_port_t  memory  = { 0 };
        buffer_t      *buffer  = (buffer_t *)(NULL);
        size_t         written = 0u;

        memory          = test_memory(&fault);
        fault.fail_next = true;
        ret             = BUFFER_create(&buffer, &memory, TEST_BUDGET);
        test_require(ret == PROJECT_ERR_MEMORY, "create propagates failure");
        test_require(buffer == (buffer_t *)(NULL),
                     "create failure preserves NULL handle");
        test_require(fault.live_count == 0u, "failed create owns no storage");
        ret = BUFFER_create(&buffer, &memory, TEST_BUDGET);
        test_require(ret == PROJECT_OK, "buffer created");
        fault.fail_next = true;
        ret             = BUFFER_resize(buffer, TEST_U32_SIZE);
        test_require(ret == PROJECT_ERR_MEMORY, "first payload failure");
        written = TEST_INITIAL_SIZE;
        ret     = BUFFER_copy(buffer, (uint8_t *)(NULL), 0u, &written);
        test_require((bool)((ret == PROJECT_OK) && (written == 0u)),
                     "buffer still empty");
        ret = BUFFER_destroy(&buffer);
        test_require(ret == PROJECT_OK, "buffer destroyed");
        test_require(fault.live_count == 0u, "control object released");
        goto function_output;

function_output:
        return;
}

static void test_bufferFailureAtomicity(void)
{
        int ret = PROJECT_OK;

        uint8_t        output[TEST_PAIR_SIZE] = { 0 };
        fault_memory_t fault                  = { 0 };
        memory_port_t  memory                 = { 0 };
        buffer_t      *buffer                 = (buffer_t *)(NULL);
        size_t         written                = 0u;

        memory = test_memory(&fault);
        ret    = BUFFER_create(&buffer, &memory, TEST_BUDGET);
        test_require(ret == PROJECT_OK, "create for atomicity");
        ret = BUFFER_append(buffer, test_atomic_input,
                            sizeof(test_atomic_input));
        test_require(ret == PROJECT_OK, "initial append");
        fault.fail_next = true;
        ret             = BUFFER_append(buffer, test_atomic_input,
                                        sizeof(test_atomic_input));
        test_require(ret == PROJECT_ERR_MEMORY, "failed growing append");
        ret = BUFFER_copy(buffer, output, sizeof(output), &written);
        test_require(ret == PROJECT_OK, "copy after failure");
        test_require(written == sizeof(test_atomic_input),
                     "failed append preserves size");
        test_require(memcmp(test_atomic_input, output,
                            sizeof(test_atomic_input)) == 0,
                     "failed append preserves bytes");
        ret = BUFFER_resize(buffer, TEST_BUDGET + 1u);
        test_require(ret == PROJECT_ERR_CAPACITY, "payload budget enforced");
        ret = BUFFER_destroy(&buffer);
        test_require(ret == PROJECT_OK, "destroy after allocation failure");
        test_require(fault.live_count == 0u, "no leaked allocation");
        goto function_output;

function_output:
        return;
}

static void test_bufferZeroAndBounds(void)
{
        int ret = PROJECT_OK;

        uint8_t        output[TEST_OUTPUT_SIZE] = { 0 };
        fault_memory_t fault                    = { 0 };
        memory_port_t  memory                   = { 0 };
        buffer_t      *buffer                   = (buffer_t *)(NULL);
        size_t         index                    = 0u;
        size_t         written                  = 0u;
        size_t         resize_calls             = 0u;

        memory  = test_memory(&fault);
        written = TEST_PRESERVED_SIZE;
        ret     = BUFFER_create(&buffer, &memory, TEST_BUDGET);
        test_require(ret == PROJECT_OK, "create for boundaries");
        ret = BUFFER_append(buffer, (const uint8_t *)(NULL), 0u);
        test_require(ret == PROJECT_OK, "empty append allows NULL");
        ret = BUFFER_append(buffer, (const uint8_t *)(NULL), 1u);
        test_require(ret == PROJECT_ERR_INVALID,
                     "nonempty append rejects NULL");
        ret = BUFFER_resize(buffer, TEST_BUDGET);
        test_require(ret == PROJECT_OK, "resize at exact budget");
        ret = BUFFER_copy(buffer, output, sizeof(output) - 1u, &written);
        test_require(ret == PROJECT_ERR_CAPACITY, "short copy rejected");
        test_require(written == 0u, "short copy clears written");
        ret = BUFFER_copy(buffer, output, sizeof(output), &written);
        test_require((bool)((ret == PROJECT_OK) && (written == sizeof(output))),
                     "exact capacity accepted");
        for (index = 0u; index < written; index++)
        {
                test_require(output[index] == 0u, "growth is zero initialized");
        }

        resize_calls = fault.resize_calls;
        ret          = BUFFER_resize(buffer, 0u);
        test_require(ret == PROJECT_OK, "zero size resets buffer");
        test_require(fault.resize_calls == resize_calls, "no realloc zero");
        test_require(fault.live_count == 1u,
                     "zero retains only control object");
        ret = BUFFER_copy(buffer, (uint8_t *)(NULL), 0u, &written);
        test_require((bool)((ret == PROJECT_OK) && (written == 0u)),
                     "empty copy");
        ret = BUFFER_destroy(&buffer);
        test_require((bool)((ret == PROJECT_OK) &&
                            (buffer == (buffer_t *)(NULL))),
                     "destroy clears");
        ret = BUFFER_destroy(&buffer);
        test_require(ret == PROJECT_OK, "destroy NULL is idempotent");
        test_require(fault.live_count == 0u, "empty buffer released");
        goto function_output;

function_output:
        return;
}

static int test_failWrite(void *context, const uint8_t *data, size_t size)
{
        int ret = PROJECT_OK;

        (void)context;
        (void)data;
        (void)size;
        ret = PROJECT_ERR_IO;
        goto function_output;

function_output:
        return ret;
}

static void test_callbackFailure(void)
{
        int ret = PROJECT_OK;

        fault_memory_t fault   = { 0 };
        memory_port_t  memory  = { 0 };
        emitter_port_t port    = { 0 };
        emitter_t     *emitter = (emitter_t *)(NULL);

        memory = test_memory(&fault);
        port   = (emitter_port_t){ .context = (void *)(NULL),
                                   .write   = test_failWrite };
        ret    = EMITTER_create(&emitter, &memory, &port, TEST_BUDGET);
        test_require(ret == PROJECT_OK, "emitter created with failure mock");
        ret = EMITTER_send(emitter, (const uint8_t *)(NULL), 0u);
        test_require(ret == PROJECT_ERR_IO, "callback error propagated");
        ret = EMITTER_send(emitter, (const uint8_t *)(NULL), 0u);
        test_require(ret == PROJECT_ERR_IO,
                     "busy cleared after callback failure");
        ret = EMITTER_destroy(&emitter);
        test_require(ret == PROJECT_OK, "destroy after callback failure");
        test_require(fault.live_count == 0u, "emitter storage released");
        goto function_output;

function_output:
        return;
}

/* Negative protocol tests exercise the defined BUSY rejection. */
typedef struct ReentryContext
{
        emitter_t *emitter;
        int        send_status;
        int        destroy_status;
} reentry_context_t;

static int test_reenter(void *context, const uint8_t *data, size_t size)
{
        int ret = PROJECT_OK;

        reentry_context_t *reentry = (reentry_context_t *)(NULL);

        test_require(context != (void *)(NULL), "reentry context is present");
        reentry                 = (reentry_context_t *)context;
        reentry->send_status    = EMITTER_send(reentry->emitter, data, size);
        reentry->destroy_status = EMITTER_destroy(&reentry->emitter);
        goto function_output;

function_output:
        return ret;
}

static void test_reentryRejected(void)
{
        int ret = PROJECT_OK;

        memory_port_t     memory  = { 0 };
        reentry_context_t reentry = { 0 };
        emitter_port_t    port    = { 0 };

        memory = HOST_memory();
        port   = (emitter_port_t){ .context = &reentry, .write = test_reenter };
        ret    = EMITTER_create(&reentry.emitter, &memory, &port, TEST_BUDGET);
        test_require(ret == PROJECT_OK, "create for reentry");
        ret = EMITTER_send(reentry.emitter, (const uint8_t *)(NULL), 0u);
        test_require(ret == PROJECT_OK, "outer callback completes");
        test_require(reentry.send_status == PROJECT_ERR_BUSY, "send reentry");
        test_require(reentry.destroy_status == PROJECT_ERR_BUSY,
                     "destroy busy");
        test_require(reentry.emitter != (emitter_t *)(NULL),
                     "busy object still alive");
        ret = EMITTER_destroy(&reentry.emitter);
        test_require(ret == PROJECT_OK, "destroy after callback returns");
        goto function_output;

function_output:
        return;
}

static void test_invalidContracts(void)
{
        int ret = PROJECT_OK;

        memory_port_t  memory  = { 0 };
        emitter_port_t port    = { 0 };
        buffer_t      *buffer  = (buffer_t *)(NULL);
        emitter_t     *emitter = (emitter_t *)(NULL);

        memory = HOST_memory();
        ret    = BUFFER_create(&buffer, &memory, 0u);
        test_require(ret == PROJECT_ERR_INVALID, "zero budget rejected");
        ret = BUFFER_create((buffer_t **)(NULL), &memory, TEST_BUDGET);
        test_require(ret == PROJECT_ERR_INVALID,
                     "NULL handle storage rejected");
        ret = EMITTER_create(&emitter, &memory, &port, TEST_BUDGET);
        test_require(ret == PROJECT_ERR_INVALID, "missing callback rejected");
        ret = EMITTER_send((emitter_t *)(NULL), (const uint8_t *)(NULL), 0u);
        test_require(ret == PROJECT_ERR_INVALID, "NULL emitter rejected");
        ret = EMITTER_destroy((emitter_t **)(NULL));
        test_require(ret == PROJECT_ERR_INVALID,
                     "NULL emitter storage rejected");
        ret = BUFFER_destroy((buffer_t **)(NULL));
        test_require(ret == PROJECT_ERR_INVALID,
                     "NULL buffer storage rejected");
        ret = BUFFER_copy((const buffer_t *)(NULL), (uint8_t *)(NULL), 0u,
                          (size_t *)(NULL));
        test_require(ret == PROJECT_ERR_INVALID, "NULL output count rejected");
        goto function_output;

function_output:
        return;
}

static void test_composedModules(void)
{
        int ret = PROJECT_OK;

        uint8_t        output[TEST_TRIPLE_SIZE] = { 0 };
        fault_memory_t fault                    = { 0 };
        memory_port_t  memory                   = { 0 };
        emitter_port_t port                     = { 0 };
        buffer_t      *buffer                   = (buffer_t *)(NULL);
        emitter_t     *emitter                  = (emitter_t *)(NULL);
        size_t         written                  = 0u;

        memory = test_memory(&fault);
        ret    = BUFFER_create(&buffer, &memory, TEST_BUDGET);
        test_require(ret == PROJECT_OK, "composition creates provider");
        port = (emitter_port_t){ .context = buffer,
                                 .write   = ADAPTER_writeBuffer };
        ret  = EMITTER_create(&emitter, &memory, &port, sizeof(test_input));
        test_require(ret == PROJECT_OK, "composition creates consumer");
        ret = EMITTER_send(emitter, test_oversized, sizeof(test_oversized));
        test_require(ret == PROJECT_ERR_CAPACITY,
                     "rejected before buffer read");
        ret = EMITTER_send(emitter, test_input, sizeof(test_input));
        test_require(ret == PROJECT_OK, "composed send succeeds");
        ret = BUFFER_copy(buffer, output, sizeof(output), &written);
        test_require(ret == PROJECT_OK, "composed result readable");
        test_require(written == sizeof(test_input),
                     "exact composed result length");
        test_require(memcmp(test_input, output, sizeof(test_input)) == 0,
                     "exact composed result bytes");
        ret = EMITTER_destroy(&emitter);
        test_require(ret == PROJECT_OK, "consumer stops first");
        ret = BUFFER_destroy(&buffer);
        test_require(ret == PROJECT_OK, "provider stops second");
        test_require(fault.live_count == 0u,
                     "composition releases all objects");
        goto function_output;

function_output:
        return;
}

int main(void)
{
        int ret = EXIT_SUCCESS;

        test_checkedArithmetic();
        test_numericParser();
        test_wireCodec();
        test_bufferAllocationFailure();
        test_bufferFailureAtomicity();
        test_bufferZeroAndBounds();
        test_callbackFailure();
        test_reentryRejected();
        test_invalidContracts();
        test_composedModules();
        goto function_output;

function_output:
        return ret;
}
```

---

<a id="research-record"></a>

## Appendix B. Research and link record

The source records below distinguish language and tool documentation from publication metadata. Each
access record states the scope and date of the recorded review. A live landing page does not mean
the full licensed standard was reviewed. Tools may show a redirected publisher URL; canonical
destinations are used below. Sources can change after this recorded check.

Project requirements remain project decisions unless an explicit source and relevant scope support a
stronger attribution. Use the source records to check the basis and limits of a claim, alongside the
implementation and verification evidence for the target under review.

Some source endpoints could not be retrieved: individual CERT wiki pages, the MISRA site, the CISA
catalogue, POSIX web pages, and the OWASP Top 10 landing page. They are not labeled verified here.
The verified SEI publication page and specific OWASP cheat sheets replace inaccessible broad links.
No claims of full MISRA, CERT, ISO/IEC TS 17961, ISO/IEC 24772, or domain-standard compliance are
made. Those standards remain relevant to an owner's separately licensed and scoped conformance
assessment; this set does not invent clause mappings.

---

<a id="ref-c23"></a>

### WG14 N3096, late C23 working draft

[WG14 N3096, late C23 working draft][wg14-n3096-late-c23-working-draft]

Public working draft, not the published ISO text. Checked pointer conversions (6.3.2.3) and
allocation/reallocation clauses (7.24.3). Relevant PDF pages were inspected.

Access record: read; checked 2026-09-10.

---

<a id="ref-iso-c"></a>

### ISO/IEC 9899:2024 catalogue

[ISO/IEC 9899:2024 catalogue][isoiec-98992024-catalogue]

Confirms edition and publication identity. The licensed full normative text was not audited.

Access record: metadata; checked 2026-09-10.

---

<a id="ref-cert"></a>

### SEI CERT C, 2016 edition landing page

[SEI CERT C, 2016 edition landing page][sei-cert-c-2016-edition-landing-page]

Verified official publication entry. Used as background and a route to the report; not a claim of
exhaustive current CERT rule coverage.

Access record: metadata; checked 2026-09-10.

---

<a id="ref-gcc-dialect"></a>

### GCC C dialect options

[GCC C dialect options][gcc-c-dialect-options]

Dialect selection and extension boundaries; installed-tool behavior must also be qualified.

Access record: read; checked 2026-09-10.

---

<a id="ref-gcc-codegen"></a>

### GCC code-generation options

[GCC code-generation options][gcc-code-generation-options]

Visibility, PIC, ABI-affecting flags, and tentative-definition options.

Access record: read; checked 2026-09-10.

---

<a id="ref-linux-style"></a>

### Linux kernel coding style

[Linux kernel coding style][linux-kernel-coding-style]

Independent project-policy example for cleanup and local C style. It does not govern this project or
prove one style universally safer.

Access record: read; checked 2026-09-10.

---

<a id="ref-cmake-link"></a>

### CMake `target_link_libraries`

[CMake `target_link_libraries`][cmake-target_link_libraries]

Usage requirements, PRIVATE/PUBLIC/INTERFACE, and object-library propagation.

Access record: read; checked 2026-09-10.

---

<a id="ref-cmake-standard"></a>

### CMake C_STANDARD property

[CMake C_STANDARD property][cmake-c_standard-property]

C17/C23 property values require CMake 3.21 or newer; C_STANDARD_REQUIRED prevents silent dialect
fallback. Tested tool versions are recorded separately.

Access record: read; checked 2026-09-10.

---

<a id="ref-cmake-build"></a>

### CMake build-system manual

[CMake build-system manual][cmake-build-system-manual]

Target/artifact distinctions and archive/shared-library behavior.

Access record: read; checked 2026-09-10.

---

<a id="ref-cmake-export"></a>

### CMake GenerateExportHeader

[CMake GenerateExportHeader][cmake-generateexportheader]

Optional export-header generation for qualified SDK builds. The example uses its own narrow compiler
adapter.

Access record: read; checked 2026-09-10.

---

<a id="ref-ld-version"></a>

### GNU `ld` version/export scripts

[GNU `ld` version/export scripts][gnu-ld-versionexport-scripts]

Symbol export/version control at shared linking.

Access record: read; checked 2026-09-10.

---

<a id="ref-nm"></a>

### GNU `nm`

[GNU `nm`][gnu-nm]

Defined, undefined, archive, and dynamic symbol inspection.

Access record: read; checked 2026-09-10.

---

<a id="ref-readelf"></a>

### GNU `readelf`

[GNU `readelf`][gnu-readelf]

ELF dynamic versus static/debug symbol tables.

Access record: read; checked 2026-09-10.

---

<a id="ref-asan"></a>

### Clang AddressSanitizer

[Clang AddressSanitizer][clang-addresssanitizer]

Host memory-error instrumentation and its limits.

Access record: read; checked 2026-09-10.

---

<a id="ref-ubsan"></a>

### Clang UndefinedBehaviorSanitizer

[Clang UndefinedBehaviorSanitizer][clang-undefinedbehaviorsanitizer]

Selected runtime undefined-behavior diagnostics; not an exhaustive proof.

Access record: read; checked 2026-09-10.

---

<a id="ref-cwe"></a>

### MITRE CWE software-development view

[MITRE CWE software-development view][mitre-cwe-software-development-view]

Navigation for weakness IDs. View 699 is a catalogue view, not a weakness to assign to a
vulnerability. Per-entry CWE mappings below are engineering mappings inherited and reviewed here,
not MITRE endorsements.

Access record: read; checked 2026-09-10.

---

<a id="ref-cwe25"></a>

### MITRE CWE Top 25, 2025 snapshot

[MITRE CWE Top 25, 2025 snapshot][mitre-cwe-top-25-2025-snapshot]

Dated coverage context. A ranked list does not define the complete C safety scope.

Access record: read; checked 2026-09-10.

---

<a id="ref-capec"></a>

### MITRE CAPEC

[MITRE CAPEC][mitre-capec]

Attack-pattern catalogue. A failure mode is not automatically an attack pattern; no unsupported
one-to-one mapping is claimed.

Access record: read; checked 2026-09-10.

---

<a id="ref-cvss"></a>

### FIRST CVSS v4.0 specification

[FIRST CVSS v4.0 specification][first-cvss-v40-specification]

Severity framework for concrete vulnerabilities. Preserve the actual version and vector used in a
cited record.

Access record: read; checked 2026-09-10.

---

<a id="ref-validation"></a>

### OWASP Input Validation Cheat Sheet

[OWASP Input Validation Cheat Sheet][owasp-input-validation-cheat-sheet]

Boundary validation context; complements, not replaces, local memory and type preconditions.

Access record: read; checked 2026-09-10.

---

<a id="ref-authorization"></a>

### OWASP Authorization Cheat Sheet

[OWASP Authorization Cheat Sheet][owasp-authorization-cheat-sheet]

Deny-by-default and resource/operation authorization context.

Access record: read; checked 2026-09-10.

---

<a id="ref-sql"></a>

### OWASP SQL Injection Prevention Cheat Sheet

[OWASP SQL Injection Prevention Cheat Sheet][owasp-sql-injection-prevention-cheat-sheet]

Parameterization of values and controls for non-parameterizable query structure.

Access record: read; checked 2026-09-10.

---

<a id="ref-xss"></a>

### OWASP Cross Site Scripting Prevention Cheat Sheet

[OWASP Cross Site Scripting Prevention Cheat
Sheet][owasp-cross-site-scripting-prevention-cheat-sheet]

Output-context-specific encoding and browser interpreter boundaries.

Access record: read; checked 2026-09-10.

---

<a id="ref-upload"></a>

### OWASP File Upload Cheat Sheet

[OWASP File Upload Cheat Sheet][owasp-file-upload-cheat-sheet]

Ingress size/content/storage controls.

Access record: read; checked 2026-09-10.

---

<a id="ref-ssrf"></a>

### OWASP SSRF Prevention Cheat Sheet

[OWASP SSRF Prevention Cheat Sheet][owasp-ssrf-prevention-cheat-sheet]

Resolved destination and redirect/egress policy.

Access record: read; checked 2026-09-10.

---

<a id="ref-xxe"></a>

### OWASP XML External Entity Prevention Cheat Sheet

[OWASP XML External Entity Prevention Cheat Sheet][owasp-xml-external-entity-prevention-cheat-sheet]

External resolution and entity-expansion restrictions.

Access record: read; checked 2026-09-10.

---

<a id="ref-logging"></a>

### OWASP Logging Cheat Sheet

[OWASP Logging Cheat Sheet][owasp-logging-cheat-sheet]

Security event recording, untrusted log values, and sensitive-data exclusion.

Access record: read; checked 2026-09-10.

---

<a id="ref-supply-chain"></a>

### OWASP Software Supply Chain Security Cheat Sheet

[OWASP Software Supply Chain Security Cheat Sheet][owasp-software-supply-chain-security-cheat-sheet]

Dependency identity, provenance, inventory, and update responsibilities.

Access record: read; checked 2026-09-10.

---

<a id="ref-ssdf"></a>

### NIST SP 800-218, SSDF v1.1

[NIST SP 800-218, SSDF v1.1][nist-sp-800-218-ssdf-v11]

Lifecycle context. This selected edition is not described as the newest possible edition.

Access record: read; checked 2026-09-10.

---

<a id="ref-anti-slop"></a>

### anti-slop repository

[anti-slop repository][anti-slop-repository]

Editorial filter requested for this revision. Core, copywriting, and code-comment guidance were
read; no installer or remote script was executed.

Access record: connector; checked 2026-09-10.

---

### Specific corrections and evidence limits

The allocation correction uses the C23 draft's allocation clauses. The draft also describes object
void-pointer conversions; it does not impose this project's required explicit casts or typed NULL.
Project conventions also require function-entry declarations and single-exit control flow. The
initializers and failure scenarios are project implementations, not quotations from that draft. The
final ISO edition is identified by its catalogue entry, not represented by the draft as though they
were the same document.

CMake and binutils documentation supply tool behavior for artifact and export checks. The example is
compiled with the installed tool versions recorded in the validation report, not whatever version a
moving `latest` manual may describe. OWASP sources provide the application-boundary context for
retained controls; no web-service or cryptographic implementation was tested by this delivery.

---

## Appendix C. Maintained optimization regression test

This test supplies executable evidence for the reference/candidate example, not for each contextual
snippet in the catalogue or for microarchitectural speed. It executes 32 offsets, 129 lengths and 5
search bytes, plus explicit invalid- pointer checks. The four-byte candidate includes a scalar tail.

<!-- example-file: performance/test_optimization.c -->

```c
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

#include "optimization_examples.h"
#include "project_status.h"

#define TEST_DATA_SIZE       ((size_t)160u)
#define TEST_OFFSET_COUNT    ((size_t)32u)
#define TEST_MAX_LENGTH      ((size_t)128u)
#define TEST_ALPHABET_SIZE   4u
#define TEST_PRESERVED_COUNT ((size_t)7u)

static int test_compare(const unsigned char *data, size_t length,
                        unsigned char needle)
{
        int    ret      = PROJECT_OK;
        size_t actual   = 0u;
        size_t expected = 0u;

        ret = OPT_countByteReference(data, length, needle, &expected);
        if (ret != PROJECT_OK)
                goto function_output;
        ret = OPT_countByteChunked(data, length, needle, &actual);
        if (ret != PROJECT_OK)
                goto function_output;
        if (actual != expected)
                ret = PROJECT_ERR_IO;

function_output:
        return ret;
}

static int test_matrix(const unsigned char *data, size_t *comparisons)
{
        int          ret    = PROJECT_OK;
        size_t       offset = 0u;
        size_t       length = 0u;
        unsigned int needle = 0u;

        if ((data == (const unsigned char *)(NULL)) ||
            (comparisons == (size_t *)(NULL)))
        {
                ret = PROJECT_ERR_INVALID;
                goto function_output;
        }

        for (offset = 0u; offset < TEST_OFFSET_COUNT; offset++)
        {
                for (length = 0u; length <= TEST_MAX_LENGTH; length++)
                {
                        for (needle = 0u; needle <= TEST_ALPHABET_SIZE;
                             needle++)
                        {
                                ret = test_compare(data + offset, length,
                                                   (unsigned char)needle);
                                if (ret != PROJECT_OK)
                                        goto function_output;
                                (*comparisons)++;
                        }
                }
        }

function_output:
        return ret;
}

static int test_invalid(const unsigned char *data)
{
        int    ret    = PROJECT_OK;
        size_t actual = 0u;
        int    status = PROJECT_OK;

        actual = TEST_PRESERVED_COUNT;
        status = OPT_countByteChunked((const unsigned char *)(NULL), 0u, 0u,
                                      &actual);
        if ((status != PROJECT_ERR_INVALID) || (actual != TEST_PRESERVED_COUNT))
        {
                ret = PROJECT_ERR_IO;
                goto function_output;
        }

        status = OPT_countByteReference((const unsigned char *)(NULL), 0u, 0u,
                                        &actual);
        if ((status != PROJECT_ERR_INVALID) || (actual != TEST_PRESERVED_COUNT))
        {
                ret = PROJECT_ERR_IO;
                goto function_output;
        }

        status = OPT_countByteChunked(data, TEST_DATA_SIZE, 0u,
                                      (size_t *)(NULL));
        if (status != PROJECT_ERR_INVALID)
        {
                ret = PROJECT_ERR_IO;
                goto function_output;
        }

        status = OPT_countByteReference(data, TEST_DATA_SIZE, 0u,
                                        (size_t *)(NULL));
        if (status != PROJECT_ERR_INVALID)
                ret = PROJECT_ERR_IO;

function_output:
        return ret;
}

int main(void)
{
        int           ret                  = PROJECT_OK;
        unsigned char data[TEST_DATA_SIZE] = { 0 };
        size_t        index                = 0u;
        size_t        comparisons          = 0u;
        int           status               = PROJECT_OK;

        for (index = 0u; index < sizeof(data); index++)
        {
                data[index] = (unsigned char)(index % TEST_ALPHABET_SIZE);
        }

        ret = test_matrix(data, &comparisons);
        if (ret != PROJECT_OK)
                goto function_output;
        ret = test_invalid(data);
        if (ret != PROJECT_OK)
                goto function_output;
        status = printf("Differential comparisons: %zu\n", comparisons);
        if (status < 0)
                ret = PROJECT_ERR_IO;

function_output:
{
        {
                ret = (ret == PROJECT_OK) ? EXIT_SUCCESS : EXIT_FAILURE;

                return ret;
        }
}
}
```

---

## Links and references

The three guides share one policy and use stable rule identifiers for cross-references.

- [C Code Standard][c-code-standard]: implementation rules and API restrictions.
- [C Module Architecture][c-module-architecture]: ownership, composition, and builds.
- [Common C Pitfalls][c-common-pitfalls]: failure scenarios and verification designs.
- [Research and link record][c-common-pitfalls-research-record]: source scope and access evidence.

<!-- Document navigation -->

[appendix-a-complete-host-regression-program]: #appendix-a-complete-host-regression-program
[appendix-b-research-and-link-record]: #appendix-b-research-and-link-record
[appendix-c-maintained-optimization-regression-test]:
  #appendix-c-maintained-optimization-regression-test
[catalogue-use]: #catalogue-use
[cpit-001]: #cpit-001
[cpit-002]: #cpit-002
[cpit-003]: #cpit-003
[cpit-004]: #cpit-004
[cpit-005]: #cpit-005
[cpit-006]: #cpit-006
[cpit-007]: #cpit-007
[cpit-008]: #cpit-008
[cpit-009]: #cpit-009
[cpit-010]: #cpit-010
[cpit-011]: #cpit-011
[cpit-012]: #cpit-012
[cpit-013]: #cpit-013
[cpit-014]: #cpit-014
[cpit-015]: #cpit-015
[cpit-016]: #cpit-016
[cpit-017]: #cpit-017
[cpit-018]: #cpit-018
[cpit-019]: #cpit-019
[cpit-020]: #cpit-020
[cpit-021]: #cpit-021
[cpit-022]: #cpit-022
[cpit-023]: #cpit-023
[cpit-024]: #cpit-024
[cpit-025]: #cpit-025
[cpit-026]: #cpit-026
[cpit-027]: #cpit-027
[cpit-028]: #cpit-028
[cpit-029]: #cpit-029
[cpit-030]: #cpit-030
[cpit-031]: #cpit-031
[cpit-032]: #cpit-032
[cpit-033]: #cpit-033
[cpit-034]: #cpit-034
[cpit-035]: #cpit-035
[cpit-036]: #cpit-036
[cpit-037]: #cpit-037
[cpit-038]: #cpit-038
[cpit-039]: #cpit-039
[cpit-040]: #cpit-040
[cpit-041]: #cpit-041
[cpit-042]: #cpit-042
[cpit-043]: #cpit-043
[cpit-044]: #cpit-044
[cpit-045]: #cpit-045
[cpit-046]: #cpit-046
[cpit-047]: #cpit-047
[cpit-048]: #cpit-048
[cpit-049]: #cpit-049
[cpit-050]: #cpit-050
[cpit-051]: #cpit-051
[cpit-052]: #cpit-052
[cpit-053]: #cpit-053
[cpit-054]: #cpit-054
[cpit-055]: #cpit-055
[cpit-056]: #cpit-056
[cpit-057]: #cpit-057
[cpit-058]: #cpit-058
[cpit-059]: #cpit-059
[cpit-060]: #cpit-060
[cpit-061]: #cpit-061
[cpit-062]: #cpit-062
[cpit-063]: #cpit-063
[cpit-064]: #cpit-064
[cpit-065]: #cpit-065
[cpit-066]: #cpit-066
[cpit-067]: #cpit-067
[cpit-068]: #cpit-068
[cpit-069]: #cpit-069
[cpit-070]: #cpit-070
[cpit-071]: #cpit-071
[cpit-072]: #cpit-072
[cpit-073]: #cpit-073
[cpit-074]: #cpit-074
[cpit-075]: #cpit-075
[cpit-076]: #cpit-076
[cpit-077]: #cpit-077
[cpit-078]: #cpit-078
[cpit-079]: #cpit-079
[cpit-080]: #cpit-080
[cpit-081]: #cpit-081
[cpit-082]: #cpit-082
[cpit-083]: #cpit-083
[cpit-084]: #cpit-084
[cpit-085]: #cpit-085
[cpit-086]: #cpit-086
[cpit-087]: #cpit-087
[cpit-088]: #cpit-088
[cpit-089]: #cpit-089
[cpit-090]: #cpit-090
[cpit-091]: #cpit-091
[cpit-092]: #cpit-092
[cpit-093]: #cpit-093
[cpit-094]: #cpit-094
[cpit-095]: #cpit-095
[cpit-096]: #cpit-096
[cpit-097]: #cpit-097
[cpit-098]: #cpit-098
[cpit-099]: #cpit-099
[cpit-100]: #cpit-100
[cpit-101]: #cpit-101
[cpit-102]: #cpit-102
[cpit-103]: #cpit-103
[cpit-104]: #cpit-104
[cpit-105]: #cpit-105
[cpit-106]: #cpit-106
[cpit-107]: #cpit-107
[cpit-108]: #cpit-108
[cpit-109]: #cpit-109
[cpit-110]: #cpit-110
[cpit-111]: #cpit-111
[cpit-112]: #cpit-112
[cpit-113]: #cpit-113
[cpit-114]: #cpit-114
[cpit-115]: #cpit-115
[cpit-116]: #cpit-116
[cpit-117]: #cpit-117
[cpit-118]: #cpit-118
[cpit-119]: #cpit-119
[cpit-120]: #cpit-120
[cpit-121]: #cpit-121
[cpit-122]: #cpit-122
[cpit-123]: #cpit-123
[cpit-124]: #cpit-124
[cpit-125]: #cpit-125
[cpit-126]: #cpit-126
[cpit-127]: #cpit-127
[cpit-128]: #cpit-128
[cpit-129]: #cpit-129
[cpit-130]: #cpit-130
[cpit-131]: #cpit-131
[cpit-132]: #cpit-132
[cpit-133]: #cpit-133
[cpit-134]: #cpit-134
[cpit-135]: #cpit-135
[cpit-136]: #cpit-136
[cpit-137]: #cpit-137
[cpit-138]: #cpit-138
[cpit-139]: #cpit-139
[cpit-140]: #cpit-140
[cpit-141]: #cpit-141
[cpit-142]: #cpit-142
[cpit-143]: #cpit-143
[cpit-144]: #cpit-144
[cpit-145]: #cpit-145
[cpit-146]: #cpit-146
[cpit-147]: #cpit-147
[cpit-148]: #cpit-148
[cpit-149]: #cpit-149
[cpit-150]: #cpit-150
[cpit-151]: #cpit-151
[cpit-152]: #cpit-152
[cpit-153]: #cpit-153
[cpit-154]: #cpit-154
[cpit-155]: #cpit-155
[cpit-156]: #cpit-156
[cpit-157]: #cpit-157
[cpit-158]: #cpit-158
[cpit-159]: #cpit-159
[cpit-160]: #cpit-160
[cpit-161]: #cpit-161
[cpit-162]: #cpit-162
[cpit-163]: #cpit-163
[cpit-164]: #cpit-164
[cpit-165]: #cpit-165
[cpit-166]: #cpit-166
[cpit-167]: #cpit-167
[cpit-168]: #cpit-168
[cpit-169]: #cpit-169
[cpit-170]: #cpit-170
[cpit-171]: #cpit-171
[cpit-172]: #cpit-172
[cpit-173]: #cpit-173
[cpit-174]: #cpit-174
[cpit-175]: #cpit-175
[cpit-176]: #cpit-176
[cpit-177]: #cpit-177
[cpit-178]: #cpit-178
[cpit-179]: #cpit-179
[cpit-180]: #cpit-180
[cpit-181]: #cpit-181
[cpit-182]: #cpit-182
[cpit-183]: #cpit-183
[cpit-184]: #cpit-184
[cpit-185]: #cpit-185
[cpit-186]: #cpit-186
[cpit-187]: #cpit-187
[cpit-188]: #cpit-188
[cpit-189]: #cpit-189
[cpit-190]: #cpit-190
[cpit-191]: #cpit-191
[cpit-192]: #cpit-192
[cpit-193]: #cpit-193
[cpit-194]: #cpit-194
[cpit-195]: #cpit-195
[cpit-196]: #cpit-196
[cpit-197]: #cpit-197
[cpit-198]: #cpit-198
[cpit-199]: #cpit-199
[cpit-200]: #cpit-200
[cpit-201]: #cpit-201
[cpit-202]: #cpit-202
[cpit-203]: #cpit-203
[cpit-204]: #cpit-204
[cpit-205]: #cpit-205
[cpit-206]: #cpit-206
[cpit-207]: #cpit-207
[cpit-208]: #cpit-208
[evidence-model]: #evidence-model
[failure-scenarios]: #failure-scenarios
[links-and-references]: #links-and-references
[ref-cwe]: #ref-cwe

<!-- Companion guides and controls -->

[c-code-standard]: c-code-standard.md
[c-code-standard-cperf-001]: c-code-standard.md#cperf-001
[c-code-standard-cperf-003]: c-code-standard.md#cperf-003
[c-code-standard-cperf-008]: c-code-standard.md#cperf-008
[c-code-standard-cperf-011]: c-code-standard.md#cperf-011
[c-code-standard-cperf-012]: c-code-standard.md#cperf-012
[c-code-standard-cperf-016]: c-code-standard.md#cperf-016
[c-code-standard-cperf-017]: c-code-standard.md#cperf-017
[c-code-standard-cperf-018]: c-code-standard.md#cperf-018
[c-code-standard-cperf-019]: c-code-standard.md#cperf-019
[c-code-standard-cperf-020]: c-code-standard.md#cperf-020
[c-code-standard-cperf-021]: c-code-standard.md#cperf-021
[c-code-standard-cperf-022]: c-code-standard.md#cperf-022
[c-code-standard-cperf-023]: c-code-standard.md#cperf-023
[c-code-standard-cperf-024]: c-code-standard.md#cperf-024
[c-code-standard-cperf-028]: c-code-standard.md#cperf-028
[c-code-standard-cperf-030]: c-code-standard.md#cperf-030
[c-code-standard-cperf-033]: c-code-standard.md#cperf-033
[c-code-standard-cperf-035]: c-code-standard.md#cperf-035
[c-code-standard-cperf-036]: c-code-standard.md#cperf-036
[c-code-standard-cperf-037]: c-code-standard.md#cperf-037
[c-code-standard-cperf-038]: c-code-standard.md#cperf-038
[c-code-standard-cperf-044]: c-code-standard.md#cperf-044
[c-code-standard-cperf-045]: c-code-standard.md#cperf-045
[c-code-standard-cperf-046]: c-code-standard.md#cperf-046
[c-code-standard-cperf-047]: c-code-standard.md#cperf-047
[c-code-standard-cstyle-029]: c-code-standard.md#cstyle-029
[c-code-standard-cstyle-038]: c-code-standard.md#cstyle-038
[c-code-standard-cstyle-053]: c-code-standard.md#cstyle-053
[c-code-standard-cstyle-054]: c-code-standard.md#cstyle-054
[c-code-standard-cstyle-058]: c-code-standard.md#cstyle-058
[c-code-standard-cstyle-059]: c-code-standard.md#cstyle-059
[c-code-standard-cstyle-060]: c-code-standard.md#cstyle-060
[c-code-standard-cstyle-061]: c-code-standard.md#cstyle-061
[c-code-standard-cstyle-063]: c-code-standard.md#cstyle-063
[c-code-standard-cstyle-064]: c-code-standard.md#cstyle-064
[c-code-standard-cstyle-066]: c-code-standard.md#cstyle-066
[c-code-standard-cstyle-067]: c-code-standard.md#cstyle-067
[c-code-standard-cstyle-068]: c-code-standard.md#cstyle-068
[c-code-standard-cstyle-069]: c-code-standard.md#cstyle-069
[c-code-standard-cstyle-071]: c-code-standard.md#cstyle-071
[c-code-standard-cstyle-074]: c-code-standard.md#cstyle-074
[c-code-standard-cstyle-077]: c-code-standard.md#cstyle-077
[c-code-standard-cstyle-080]: c-code-standard.md#cstyle-080
[c-code-standard-cstyle-081]: c-code-standard.md#cstyle-081
[c-code-standard-cstyle-082]: c-code-standard.md#cstyle-082
[c-code-standard-cstyle-084]: c-code-standard.md#cstyle-084
[c-code-standard-cstyle-086]: c-code-standard.md#cstyle-086
[c-code-standard-cstyle-087]: c-code-standard.md#cstyle-087
[c-code-standard-cstyle-089]: c-code-standard.md#cstyle-089
[c-code-standard-cstyle-091]: c-code-standard.md#cstyle-091
[c-code-standard-cstyle-092]: c-code-standard.md#cstyle-092
[c-code-standard-cstyle-094]: c-code-standard.md#cstyle-094
[c-code-standard-cstyle-095]: c-code-standard.md#cstyle-095
[c-code-standard-cstyle-096]: c-code-standard.md#cstyle-096
[c-code-standard-cstyle-097]: c-code-standard.md#cstyle-097
[c-code-standard-cstyle-098]: c-code-standard.md#cstyle-098
[c-code-standard-cstyle-099]: c-code-standard.md#cstyle-099
[c-code-standard-cstyle-100]: c-code-standard.md#cstyle-100
[c-code-standard-cstyle-101]: c-code-standard.md#cstyle-101
[c-code-standard-cstyle-102]: c-code-standard.md#cstyle-102
[c-code-standard-cstyle-103]: c-code-standard.md#cstyle-103
[c-code-standard-cstyle-105]: c-code-standard.md#cstyle-105
[c-code-standard-cstyle-106]: c-code-standard.md#cstyle-106
[c-code-standard-cstyle-107]: c-code-standard.md#cstyle-107
[c-code-standard-cstyle-108]: c-code-standard.md#cstyle-108
[c-code-standard-cstyle-109]: c-code-standard.md#cstyle-109
[c-code-standard-cstyle-110]: c-code-standard.md#cstyle-110
[c-code-standard-cstyle-111]: c-code-standard.md#cstyle-111
[c-code-standard-cstyle-112]: c-code-standard.md#cstyle-112
[c-code-standard-cstyle-113]: c-code-standard.md#cstyle-113
[c-code-standard-cstyle-114]: c-code-standard.md#cstyle-114
[c-code-standard-cstyle-115]: c-code-standard.md#cstyle-115
[c-code-standard-cstyle-116]: c-code-standard.md#cstyle-116
[c-code-standard-cstyle-122]: c-code-standard.md#cstyle-122
[c-code-standard-cstyle-123]: c-code-standard.md#cstyle-123
[c-code-standard-cstyle-124]: c-code-standard.md#cstyle-124
[c-code-standard-cstyle-127]: c-code-standard.md#cstyle-127
[c-code-standard-cstyle-128]: c-code-standard.md#cstyle-128
[c-code-standard-cstyle-129]: c-code-standard.md#cstyle-129
[c-code-standard-cstyle-130]: c-code-standard.md#cstyle-130
[c-code-standard-cstyle-132]: c-code-standard.md#cstyle-132
[c-code-standard-cstyle-133]: c-code-standard.md#cstyle-133
[c-code-standard-cstyle-135]: c-code-standard.md#cstyle-135
[c-code-standard-cstyle-136]: c-code-standard.md#cstyle-136
[c-code-standard-cstyle-137]: c-code-standard.md#cstyle-137
[c-code-standard-cstyle-138]: c-code-standard.md#cstyle-138
[c-code-standard-cstyle-141]: c-code-standard.md#cstyle-141
[c-code-standard-cstyle-144]: c-code-standard.md#cstyle-144
[c-code-standard-cstyle-147]: c-code-standard.md#cstyle-147
[c-code-standard-cstyle-150]: c-code-standard.md#cstyle-150
[c-code-standard-cstyle-152]: c-code-standard.md#cstyle-152
[c-code-standard-cstyle-153]: c-code-standard.md#cstyle-153
[c-code-standard-cstyle-154]: c-code-standard.md#cstyle-154
[c-code-standard-cstyle-155]: c-code-standard.md#cstyle-155
[c-code-standard-cstyle-156]: c-code-standard.md#cstyle-156
[c-code-standard-cstyle-158]: c-code-standard.md#cstyle-158
[c-code-standard-cstyle-159]: c-code-standard.md#cstyle-159
[c-code-standard-cstyle-160]: c-code-standard.md#cstyle-160
[c-code-standard-cstyle-162]: c-code-standard.md#cstyle-162
[c-code-standard-cstyle-163]: c-code-standard.md#cstyle-163
[c-code-standard-cstyle-164]: c-code-standard.md#cstyle-164
[c-code-standard-cstyle-165]: c-code-standard.md#cstyle-165
[c-code-standard-cstyle-166]: c-code-standard.md#cstyle-166
[c-code-standard-cstyle-167]: c-code-standard.md#cstyle-167
[c-code-standard-cstyle-168]: c-code-standard.md#cstyle-168
[c-code-standard-cstyle-169]: c-code-standard.md#cstyle-169
[c-code-standard-cstyle-170]: c-code-standard.md#cstyle-170
[c-code-standard-cstyle-171]: c-code-standard.md#cstyle-171
[c-code-standard-cstyle-172]: c-code-standard.md#cstyle-172
[c-code-standard-cstyle-173]: c-code-standard.md#cstyle-173
[c-code-standard-cstyle-174]: c-code-standard.md#cstyle-174
[c-code-standard-cstyle-175]: c-code-standard.md#cstyle-175
[c-code-standard-cstyle-176]: c-code-standard.md#cstyle-176
[c-code-standard-cstyle-177]: c-code-standard.md#cstyle-177
[c-code-standard-cstyle-178]: c-code-standard.md#cstyle-178
[c-code-standard-cstyle-241]: c-code-standard.md#cstyle-241
[c-code-standard-cstyle-248]: c-code-standard.md#cstyle-248
[c-code-standard-cstyle-256]: c-code-standard.md#cstyle-256
[c-code-standard-cstyle-259]: c-code-standard.md#cstyle-259
[c-code-standard-cstyle-260]: c-code-standard.md#cstyle-260
[c-code-standard-cstyle-261]: c-code-standard.md#cstyle-261
[c-code-standard-cstyle-264]: c-code-standard.md#cstyle-264
[c-code-standard-cstyle-265]: c-code-standard.md#cstyle-265
[c-code-standard-cstyle-266]: c-code-standard.md#cstyle-266
[c-code-standard-cstyle-267]: c-code-standard.md#cstyle-267
[c-code-standard-cstyle-268]: c-code-standard.md#cstyle-268
[c-code-standard-cstyle-269]: c-code-standard.md#cstyle-269
[c-code-standard-example-policy]: c-code-standard.md#example-policy
[c-code-standard-governance]: c-code-standard.md#governance
[c-common-pitfalls]: c-common-pitfalls.md
[c-common-pitfalls-ref-asan]: c-common-pitfalls.md#ref-asan
[c-common-pitfalls-ref-authorization]: c-common-pitfalls.md#ref-authorization
[c-common-pitfalls-ref-c23]: c-common-pitfalls.md#ref-c23
[c-common-pitfalls-ref-logging]: c-common-pitfalls.md#ref-logging
[c-common-pitfalls-ref-sql]: c-common-pitfalls.md#ref-sql
[c-common-pitfalls-ref-ssdf]: c-common-pitfalls.md#ref-ssdf
[c-common-pitfalls-ref-ssrf]: c-common-pitfalls.md#ref-ssrf
[c-common-pitfalls-ref-supply-chain]: c-common-pitfalls.md#ref-supply-chain
[c-common-pitfalls-ref-ubsan]: c-common-pitfalls.md#ref-ubsan
[c-common-pitfalls-ref-upload]: c-common-pitfalls.md#ref-upload
[c-common-pitfalls-ref-validation]: c-common-pitfalls.md#ref-validation
[c-common-pitfalls-ref-xss]: c-common-pitfalls.md#ref-xss
[c-common-pitfalls-ref-xxe]: c-common-pitfalls.md#ref-xxe
[c-common-pitfalls-research-record]: c-common-pitfalls.md#research-record
[c-module-architecture]: c-module-architecture.md
[c-module-architecture-cmod-083]: c-module-architecture.md#cmod-083
[c-module-architecture-cmod-084]: c-module-architecture.md#cmod-084
[c-module-architecture-cmod-085]: c-module-architecture.md#cmod-085
[c-module-architecture-cmod-086]: c-module-architecture.md#cmod-086
[c-module-architecture-cmod-090]: c-module-architecture.md#cmod-090
[c-module-architecture-cmod-098]: c-module-architecture.md#cmod-098
[c-module-architecture-cmod-100]: c-module-architecture.md#cmod-100
[c-module-architecture-cmod-101]: c-module-architecture.md#cmod-101
[c-module-architecture-cmod-103]: c-module-architecture.md#cmod-103
[c-module-architecture-cmod-104]: c-module-architecture.md#cmod-104
[c-module-architecture-cmod-105]: c-module-architecture.md#cmod-105
[c-module-architecture-cmod-106]: c-module-architecture.md#cmod-106
[c-module-architecture-cmod-107]: c-module-architecture.md#cmod-107
[c-module-architecture-cmod-108]: c-module-architecture.md#cmod-108
[c-module-architecture-cmod-109]: c-module-architecture.md#cmod-109

<!-- External sources -->

[anti-slop-repository]: https://github.com/miqdadbadjuber/anti-slop
[capec-624]: https://capec.mitre.org/data/definitions/624.html
[clang-addresssanitizer]: https://clang.llvm.org/docs/AddressSanitizer.html
[clang-undefinedbehaviorsanitizer]: https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html
[cmake-build-system-manual]: https://cmake.org/cmake/help/latest/manual/cmake-buildsystem.7.html
[cmake-c_standard-property]: https://cmake.org/cmake/help/latest/prop_tgt/C_STANDARD.html
[cmake-generateexportheader]: https://cmake.org/cmake/help/latest/module/GenerateExportHeader.html
[cmake-target_link_libraries]:
  https://cmake.org/cmake/help/latest/command/target_link_libraries.html
[cve-2025-11618]: https://www.cve.org/CVERecord?id=CVE-2025-11618
[cve-2026-49975]: https://www.cve.org/CVERecord?id=CVE-2026-49975
[cwe-1256]: https://cwe.mitre.org/data/definitions/1256.html
[cwe-1332]: https://cwe.mitre.org/data/definitions/1332.html
[cwe-20]: https://cwe.mitre.org/data/definitions/20.html
[cwe-208]: https://cwe.mitre.org/data/definitions/208.html
[cwe-362]: https://cwe.mitre.org/data/definitions/362.html
[cwe-400]: https://cwe.mitre.org/data/definitions/400.html
[cwe-562]: https://cwe.mitre.org/data/definitions/562.html
[cwe-664]: https://cwe.mitre.org/data/definitions/664.html
[cwe-667]: https://cwe.mitre.org/data/definitions/667.html
[cwe-682]: https://cwe.mitre.org/data/definitions/682.html
[cwe-704]: https://cwe.mitre.org/data/definitions/704.html
[cwe-758]: https://cwe.mitre.org/data/definitions/758.html
[cwe-770]: https://cwe.mitre.org/data/definitions/770.html
[cwe-825]: https://cwe.mitre.org/data/definitions/825.html
[cwe-843]: https://cwe.mitre.org/data/definitions/843.html
[first-cvss-v40-specification]: https://www.first.org/cvss/v4.0/specification-document
[gcc-c-dialect-options]: https://gcc.gnu.org/onlinedocs/gcc/C-Dialect-Options.html
[gcc-code-generation-options]: https://gcc.gnu.org/onlinedocs/gcc/Code-Gen-Options.html
[gnu-ld-versionexport-scripts]: https://sourceware.org/binutils/docs/ld/VERSION.html
[gnu-nm]: https://sourceware.org/binutils/docs/binutils/nm.html
[gnu-readelf]: https://sourceware.org/binutils/docs/binutils/readelf.html
[isoiec-98992024-catalogue]: https://www.iso.org/standard/82075.html
[linux-kernel-coding-style]: https://www.kernel.org/doc/html/latest/process/coding-style.html
[mitre-capec]: https://capec.mitre.org/
[mitre-cwe-software-development-view]: https://cwe.mitre.org/data/definitions/699.html
[mitre-cwe-top-25-2025-snapshot]: https://cwe.mitre.org/top25/archive/2025/2025_cwe_top25.html
[nist-sp-800-218-ssdf-v11]: https://csrc.nist.gov/pubs/sp/800/218/final
[owasp-authorization-cheat-sheet]:
  https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html
[owasp-cross-site-scripting-prevention-cheat-sheet]:
  https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html
[owasp-file-upload-cheat-sheet]:
  https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html
[owasp-input-validation-cheat-sheet]:
  https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html
[owasp-logging-cheat-sheet]: https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
[owasp-software-supply-chain-security-cheat-sheet]:
  https://cheatsheetseries.owasp.org/cheatsheets/Software_Supply_Chain_Security_Cheat_Sheet.html
[owasp-sql-injection-prevention-cheat-sheet]:
  https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html
[owasp-ssrf-prevention-cheat-sheet]:
  https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html
[owasp-xml-external-entity-prevention-cheat-sheet]:
  https://cheatsheetseries.owasp.org/cheatsheets/XML_External_Entity_Prevention_Cheat_Sheet.html
[sei-cert-c-2016-edition-landing-page]:
  https://www.sei.cmu.edu/library/sei-cert-c-coding-standard-rules-for-developing-safe-reliable-and-secure-systems-2016-edition/
[wg14-n3096-late-c23-working-draft]: https://www.open-std.org/jtc1/sc22/wg14/www/docs/n3096.pdf
[capec-100]: https://capec.mitre.org/data/definitions/100.html
[capec-126]: https://capec.mitre.org/data/definitions/126.html
[capec-135]: https://capec.mitre.org/data/definitions/135.html
[capec-175]: https://capec.mitre.org/data/definitions/175.html
[capec-184]: https://capec.mitre.org/data/definitions/184.html
[capec-201]: https://capec.mitre.org/data/definitions/201.html
[capec-242]: https://capec.mitre.org/data/definitions/242.html
[capec-29]: https://capec.mitre.org/data/definitions/29.html
[capec-439]: https://capec.mitre.org/data/definitions/439.html
[capec-471]: https://capec.mitre.org/data/definitions/471.html
[capec-586]: https://capec.mitre.org/data/definitions/586.html
[capec-62]: https://capec.mitre.org/data/definitions/62.html
[capec-63]: https://capec.mitre.org/data/definitions/63.html
[capec-66]: https://capec.mitre.org/data/definitions/66.html
[capec-664]: https://capec.mitre.org/data/definitions/664.html
[capec-88]: https://capec.mitre.org/data/definitions/88.html
[capec-97]: https://capec.mitre.org/data/definitions/97.html
[clang-thread-safety]: https://clang.llvm.org/docs/ThreadSafetyAnalysis.html
[cwe-1104]: https://cwe.mitre.org/data/definitions/1104.html
[cwe-117]: https://cwe.mitre.org/data/definitions/117.html
[cwe-1188]: https://cwe.mitre.org/data/definitions/1188.html
[cwe-119]: https://cwe.mitre.org/data/definitions/119.html
[cwe-120]: https://cwe.mitre.org/data/definitions/120.html
[cwe-124]: https://cwe.mitre.org/data/definitions/124.html
[cwe-125]: https://cwe.mitre.org/data/definitions/125.html
[cwe-126]: https://cwe.mitre.org/data/definitions/126.html
[cwe-129]: https://cwe.mitre.org/data/definitions/129.html
[cwe-131]: https://cwe.mitre.org/data/definitions/131.html
[cwe-134]: https://cwe.mitre.org/data/definitions/134.html
[cwe-1395]: https://cwe.mitre.org/data/definitions/1395.html
[cwe-16]: https://cwe.mitre.org/data/definitions/16.html
[cwe-170]: https://cwe.mitre.org/data/definitions/170.html
[cwe-176]: https://cwe.mitre.org/data/definitions/176.html
[cwe-190]: https://cwe.mitre.org/data/definitions/190.html
[cwe-193]: https://cwe.mitre.org/data/definitions/193.html
[cwe-195]: https://cwe.mitre.org/data/definitions/195.html
[cwe-197]: https://cwe.mitre.org/data/definitions/197.html
[cwe-198]: https://cwe.mitre.org/data/definitions/198.html
[cwe-200]: https://cwe.mitre.org/data/definitions/200.html
[cwe-209]: https://cwe.mitre.org/data/definitions/209.html
[cwe-22]: https://cwe.mitre.org/data/definitions/22.html
[cwe-226]: https://cwe.mitre.org/data/definitions/226.html
[cwe-252]: https://cwe.mitre.org/data/definitions/252.html
[cwe-284]: https://cwe.mitre.org/data/definitions/284.html
[cwe-287]: https://cwe.mitre.org/data/definitions/287.html
[cwe-294]: https://cwe.mitre.org/data/definitions/294.html
[cwe-306]: https://cwe.mitre.org/data/definitions/306.html
[cwe-327]: https://cwe.mitre.org/data/definitions/327.html
[cwe-338]: https://cwe.mitre.org/data/definitions/338.html
[cwe-345]: https://cwe.mitre.org/data/definitions/345.html
[cwe-347]: https://cwe.mitre.org/data/definitions/347.html
[cwe-352]: https://cwe.mitre.org/data/definitions/352.html
[cwe-353]: https://cwe.mitre.org/data/definitions/353.html
[cwe-354]: https://cwe.mitre.org/data/definitions/354.html
[cwe-364]: https://cwe.mitre.org/data/definitions/364.html
[cwe-366]: https://cwe.mitre.org/data/definitions/366.html
[cwe-369]: https://cwe.mitre.org/data/definitions/369.html
[cwe-377]: https://cwe.mitre.org/data/definitions/377.html
[cwe-391]: https://cwe.mitre.org/data/definitions/391.html
[cwe-401]: https://cwe.mitre.org/data/definitions/401.html
[cwe-403]: https://cwe.mitre.org/data/definitions/403.html
[cwe-404]: https://cwe.mitre.org/data/definitions/404.html
[cwe-415]: https://cwe.mitre.org/data/definitions/415.html
[cwe-416]: https://cwe.mitre.org/data/definitions/416.html
[cwe-426]: https://cwe.mitre.org/data/definitions/426.html
[cwe-427]: https://cwe.mitre.org/data/definitions/427.html
[cwe-434]: https://cwe.mitre.org/data/definitions/434.html
[cwe-457]: https://cwe.mitre.org/data/definitions/457.html
[cwe-467]: https://cwe.mitre.org/data/definitions/467.html
[cwe-469]: https://cwe.mitre.org/data/definitions/469.html
[cwe-475]: https://cwe.mitre.org/data/definitions/475.html
[cwe-476]: https://cwe.mitre.org/data/definitions/476.html
[cwe-479]: https://cwe.mitre.org/data/definitions/479.html
[cwe-480]: https://cwe.mitre.org/data/definitions/480.html
[cwe-489]: https://cwe.mitre.org/data/definitions/489.html
[cwe-494]: https://cwe.mitre.org/data/definitions/494.html
[cwe-502]: https://cwe.mitre.org/data/definitions/502.html
[cwe-532]: https://cwe.mitre.org/data/definitions/532.html
[cwe-590]: https://cwe.mitre.org/data/definitions/590.html
[cwe-611]: https://cwe.mitre.org/data/definitions/611.html
[cwe-636]: https://cwe.mitre.org/data/definitions/636.html
[cwe-639]: https://cwe.mitre.org/data/definitions/639.html
[cwe-662]: https://cwe.mitre.org/data/definitions/662.html
[cwe-663]: https://cwe.mitre.org/data/definitions/663.html
[cwe-665]: https://cwe.mitre.org/data/definitions/665.html
[cwe-674]: https://cwe.mitre.org/data/definitions/674.html
[cwe-680]: https://cwe.mitre.org/data/definitions/680.html
[cwe-681]: https://cwe.mitre.org/data/definitions/681.html
[cwe-686]: https://cwe.mitre.org/data/definitions/686.html
[cwe-693]: https://cwe.mitre.org/data/definitions/693.html
[cwe-755]: https://cwe.mitre.org/data/definitions/755.html
[cwe-761]: https://cwe.mitre.org/data/definitions/761.html
[cwe-762]: https://cwe.mitre.org/data/definitions/762.html
[cwe-768]: https://cwe.mitre.org/data/definitions/768.html
[cwe-77]: https://cwe.mitre.org/data/definitions/77.html
[cwe-772]: https://cwe.mitre.org/data/definitions/772.html
[cwe-776]: https://cwe.mitre.org/data/definitions/776.html
[cwe-778]: https://cwe.mitre.org/data/definitions/778.html
[cwe-78]: https://cwe.mitre.org/data/definitions/78.html
[cwe-787]: https://cwe.mitre.org/data/definitions/787.html
[cwe-789]: https://cwe.mitre.org/data/definitions/789.html
[cwe-79]: https://cwe.mitre.org/data/definitions/79.html
[cwe-798]: https://cwe.mitre.org/data/definitions/798.html
[cwe-824]: https://cwe.mitre.org/data/definitions/824.html
[cwe-829]: https://cwe.mitre.org/data/definitions/829.html
[cwe-833]: https://cwe.mitre.org/data/definitions/833.html
[cwe-835]: https://cwe.mitre.org/data/definitions/835.html
[cwe-838]: https://cwe.mitre.org/data/definitions/838.html
[cwe-841]: https://cwe.mitre.org/data/definitions/841.html
[cwe-862]: https://cwe.mitre.org/data/definitions/862.html
[cwe-863]: https://cwe.mitre.org/data/definitions/863.html
[cwe-89]: https://cwe.mitre.org/data/definitions/89.html
[cwe-918]: https://cwe.mitre.org/data/definitions/918.html
[cwe-94]: https://cwe.mitre.org/data/definitions/94.html
[intel-optimization-manual]:
  https://cdrdv2-public.intel.com/821612/248966-Optimization-Reference-Manual-V1-050.pdf
[kernel-false-sharing]: https://docs.kernel.org/kernel-hacking/false-sharing.html
[owasp-authentication]:
  https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
[owasp-authorization]: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html
[owasp-c-based-toolchain-hardening]:
  https://cheatsheetseries.owasp.org/cheatsheets/C-Based_Toolchain_Hardening_Cheat_Sheet.html
[owasp-ci-cd-security]:
  https://cheatsheetseries.owasp.org/cheatsheets/CI_CD_Security_Cheat_Sheet.html
[owasp-cross-site-request-forgery-prevention]:
  https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html
[owasp-cross-site-scripting-prevention]:
  https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html
[owasp-cryptographic-storage]:
  https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html
[owasp-denial-of-service]:
  https://cheatsheetseries.owasp.org/cheatsheets/Denial_of_Service_Cheat_Sheet.html
[owasp-deserialization]:
  https://cheatsheetseries.owasp.org/cheatsheets/Deserialization_Cheat_Sheet.html
[owasp-docker-security]:
  https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html
[owasp-error-handling]:
  https://cheatsheetseries.owasp.org/cheatsheets/Error_Handling_Cheat_Sheet.html
[owasp-file-upload]: https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html
[owasp-input-validation]:
  https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html
[owasp-logging]: https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
[owasp-os-command-injection-defense]:
  https://cheatsheetseries.owasp.org/cheatsheets/OS_Command_Injection_Defense_Cheat_Sheet.html
[owasp-secrets-management]:
  https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html
[owasp-server-side-request-forgery-prevention]:
  https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html
[owasp-software-supply-chain-security]:
  https://cheatsheetseries.owasp.org/cheatsheets/Software_Supply_Chain_Security_Cheat_Sheet.html
[owasp-sql-injection-prevention]:
  https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html
[owasp-xml-external-entity-prevention]:
  https://cheatsheetseries.owasp.org/cheatsheets/XML_External_Entity_Prevention_Cheat_Sheet.html

<!-- EOF -->


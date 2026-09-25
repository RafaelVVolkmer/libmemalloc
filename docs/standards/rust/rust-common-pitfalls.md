<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Common Rust pitfalls

Use this catalogue to review a concrete failure mechanism and choose a regression test. The
[code standard](rust-code-standard.md) owns the requirements and profiles; the
[architecture guide](rust-module-architecture.md) owns module and lifecycle boundaries.
A pitfall is not a new blanket prohibition. Distinguish performance cost, logical failure and undefined behavior.

<a id="rule-index"></a>

<details>
<summary><strong>On this page</strong></summary>

<details>
<summary>Additional boundary failure scenarios</summary>

- [RPIT-051: Reconstructing a vector with a borrowed-view layout](#rpit-051)
- [RPIT-052: Publishing uninitialized elements before a callback finishes](#rpit-052)
- [RPIT-053: Losing readiness between inspection and waker registration](#rpit-053)
- [RPIT-054: Reading payload on an unsynchronized failed exchange](#rpit-054)
- [RPIT-055: Checking a null function pointer after creating it](#rpit-055)
- [RPIT-056: Letting workspace features hide a broken library consumer](#rpit-056)

</details>

- [How to use the catalogue](#how-to-use-the-catalogue)
- [Ownership, unsafe and execution failures](#ownership-unsafe-and-execution-failures)
- [Boundary, build and verification failures](#boundary-build-and-verification-failures)
- [Appendix A. Complete raw-input boundary example](#complete-raw-input-boundary-example)
- [Links and references](#references)

<details>
<summary>Ownership, allocation and errors</summary>

- [RPIT-001: Excessive cloning](#rpit-001)
- [RPIT-002: Accidental allocations at call sites](#rpit-002)
- [RPIT-003: Holding a blocking lock across await](#rpit-003)
- [RPIT-004: Using poisoning as an invariant proof](#rpit-004)
- [RPIT-005: Rc or Arc ownership cycles](#rpit-005)
- [RPIT-006: RefCell borrow failures under reentry](#rpit-006)
- [RPIT-007: Integer truncation at a boundary](#rpit-007)

</details>

<details>
<summary>Unsafe representations and native boundaries</summary>

- [RPIT-008: Pointer provenance violations](#rpit-008)
- [RPIT-009: Invalid transmute](#rpit-009)
- [RPIT-010: Premature MaybeUninit completion](#rpit-010)
- [RPIT-011: Creating an invalid reference before checking it](#rpit-011)
- [RPIT-012: Assuming a representation guarantee](#rpit-012)
- [RPIT-013: FFI ABI mismatch](#rpit-013)
- [RPIT-014: Panic crossing an FFI boundary](#rpit-014)
- [RPIT-015: Unsound Send or Sync implementation](#rpit-015)
- [RPIT-016: Incorrect Drop implementation](#rpit-016)
- [RPIT-017: Breaking Pin invariants](#rpit-017)

</details>

<details>
<summary>Cancellation, synchronization and resource budgets</summary>

- [RPIT-018: Cancellation loses progress](#rpit-018)
- [RPIT-019: Deadlock from lock order or callbacks](#rpit-019)
- [RPIT-020: Incorrect atomic ordering](#rpit-020)
- [RPIT-021: Overflow-dependent behavior](#rpit-021)
- [RPIT-022: Hidden heap work through abstraction](#rpit-022)
- [RPIT-023: Using unsafe to avoid design work](#rpit-023)
- [RPIT-024: Leaking unsafe obligations through a safe API](#rpit-024)
- [RPIT-025: Unbounded resource consumption](#rpit-025)

</details>

<details>
<summary>Pointer lifetime and shared state</summary>

- [RPIT-026: Borrowed pointer survives reallocation](#rpit-026)
- [RPIT-027: Mismatched native allocator ownership](#rpit-027)
- [RPIT-028: Zero length treated as permission for a null reference](#rpit-028)
- [RPIT-029: Losing initialized values during partial construction](#rpit-029)
- [RPIT-030: Reading packed fields through references](#rpit-030)
- [RPIT-031: Treating HashMap order as stable output](#rpit-031)
- [RPIT-032: Newtype invariant bypass](#rpit-032)
- [RPIT-033: UnsafeCell mistaken for synchronization](#rpit-033)
- [RPIT-034: Atomic pointer lifetime race and ABA](#rpit-034)

</details>

<details>
<summary>I/O, security and build configurations</summary>

- [RPIT-035: Retrying a partial write as a new operation](#rpit-035)
- [RPIT-036: Confusing flush with crash durability](#rpit-036)
- [RPIT-037: Path validation separated from use](#rpit-037)
- [RPIT-038: Secret disclosure through derived formatting](#rpit-038)
- [RPIT-039: Feature unification masks an unsupported build](#rpit-039)
- [RPIT-040: no_std mistaken for no allocation or no panic](#rpit-040)
- [RPIT-041: Uncontrolled build-time code execution](#rpit-041)
- [RPIT-042: MSRV or edition inferred from one compiler run](#rpit-042)
- [RPIT-043: A green all-features build treated as full coverage](#rpit-043)

</details>

<details>
<summary>Verification, specialization and documentation</summary>

- [RPIT-044: Miri success presented as a soundness proof](#rpit-044)
- [RPIT-045: Unsupported ISA reached by dispatch](#rpit-045)
- [RPIT-046: Allocator logging recursively allocates](#rpit-046)
- [RPIT-047: Benchmark eliminates or excludes required work](#rpit-047)
- [RPIT-048: Leaked owner makes a safe abstraction unsound](#rpit-048)
- [RPIT-049: Old backend survives cache invalidation](#rpit-049)
- [RPIT-050: Documentation examples bypass verification](#rpit-050)

</details>

</details>

---

## How to use the catalogue

For each applicable entry, record the trigger in your program, the affected invariant and the observation
that would detect its failure. Safe Rust can reject lifetime misuse at compile time while still permitting
leaks, deadlocks, logic errors and unbounded work. Unsafe abstractions require separate soundness review.

The counterexamples below are short review descriptions or contextual expressions, not executable programs.
Do not execute UB examples to establish correctness. Compile-fail tests check the intended diagnostic;
Miri/sanitizer tests exercise valid API calls that challenge implementation invariants. FFI tests must respect
unsafe caller preconditions unless a separately contained negative-testing harness is explicitly designed for them.

---

## Ownership, unsafe and execution failures

---

<a id="rpit-001"></a>

### RPIT-001: Excessive cloning

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A parser calls `payload.to_vec()` before every read-only helper.

**Failure mechanism:** Each independent buffer can copy bytes and allocate even though no consumer needs ownership.

**Prevention:** Borrow a slice or move the existing owner; keep a deliberate snapshot when isolation requires it.

**Verification design:** Compare allocation and byte-copy counts with representative payload sizes and retained-result
tests.

**Prevention controls:** [RUST-009](rust-code-standard.md#rust-009), [RUST-008](rust-code-standard.md#rust-008).

**External references:** [Technical context](https://nnethercote.github.io/perf-book/heap-allocations.html).

#### Local examples

**Contextual prevention example:**

```rust
inspect(&payload);
```

**Failure fragment or claim (do not execute):**

```text
inspect(&payload.clone());
```

---

<a id="rpit-002"></a>

### RPIT-002: Accidental allocations at call sites

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** `format!`, `collect::<Vec<_>>()` or boxed closures enter an allocation-free operation.

**Failure mechanism:** Short expressions hide heap work and can introduce exhaustion or allocator reentry.

**Prevention:** Use bounded caller-owned storage, borrowed views or a measured preallocation policy; include
diagnostics.

**Verification design:** Instrument allocations after setup, including rejection and cleanup paths.

**Prevention controls:** [RUST-025](rust-code-standard.md#rust-025), [RUST-056](rust-code-standard.md#rust-056).

**External references:** [Technical context](https://nnethercote.github.io/perf-book/heap-allocations.html).

#### Local examples

**Contextual prevention example:**

```rust
write!(bounded_writer, "count={count}")?;
```

**Failure fragment or claim (do not execute):**

```text
let message = format!("count={count}"); // Inside a no-allocation path.
```

---

<a id="rpit-003"></a>

### RPIT-003: Holding a blocking lock across await

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A `std::sync::MutexGuard` remains live when an async function suspends.

**Failure mechanism:** Another task can block the executor thread needed to resume the lock owner, or the future
fails a Send bound.

**Prevention:** End the guard scope before suspension. Use an async mutex only when exclusive access must span the
wait.

**Verification design:** Run competing tasks on a constrained executor and assert completion under a test deadline.

**Prevention controls:** [RUST-037](rust-code-standard.md#rust-037).

**External references:** [Technical context](https://tokio.rs/tokio/tutorial/shared-state).

#### Local examples

**Contextual prevention example:**

```rust
let request = { shared.lock()?.make_request() };
send(request).await?;
```

**Failure fragment or claim (do not execute):**

```text
let guard = shared.lock()?;
send(guard.request()).await?;
```

---

<a id="rpit-004"></a>

### RPIT-004: Using poisoning as an invariant proof

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A wrapper assumes every interrupted mutation must poison its mutex.

**Failure mechanism:** Poisoning is advisory; some panic situations are not detected. Recovery without repair may
expose invalid state.

**Prevention:** Maintain soundness independently of poisoning and define a domain recovery decision.

**Verification design:** Inject panics at mutation stages; inspect protected state before recovery.

**Prevention controls:** [RUST-036](rust-code-standard.md#rust-036).

**External references:** [Technical context](https://doc.rust-lang.org/std/sync/struct.Mutex.html).

#### Local examples

**Contextual prevention example:**

```rust
let state = recover_after_checking_invariants(poisoned)?;
```

**Failure fragment or claim (do not execute):**

```text
let state = poisoned.into_inner(); // Assumes invariants still hold.
```

---

<a id="rpit-005"></a>

### RPIT-005: Rc or Arc ownership cycles

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A parent and callback each retain a strong reference to the other.

**Failure mechanism:** Reference counts never reach zero, so logical shutdown and resource release may never
happen.

**Prevention:** Use a justified weak edge or explicitly unregister the callback and break the cycle.

**Verification design:** Count drops and live callbacks after dropping the external root; include failed initialization.

**Prevention controls:** [RUST-039](rust-code-standard.md#rust-039), [RUST-026](rust-code-standard.md#rust-026).

**External references:** [Technical context](https://doc.rust-lang.org/book/).

#### Local examples

**Contextual prevention example:**

```rust
let parent = std::rc::Rc::downgrade(&parent);
```

**Failure fragment or claim (do not execute):**

```text
child.parent = Some(std::rc::Rc::clone(&parent)); // Completes a strong cycle.
```

---

<a id="rpit-006"></a>

### RPIT-006: RefCell borrow failures under reentry

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A callback reenters while a `borrow_mut()` guard is live.

**Failure mechanism:** The nested borrow panics at runtime; choosing RefCell did not prove non-overlap.

**Prevention:** Shorten guard scope or use `try_borrow_mut` when rejection is expected; document reentry.

**Verification design:** Use a callback that attempts reentry and check both error behavior and later usability.

**Prevention controls:** [RUST-014](rust-code-standard.md#rust-014).

**External references:** [Technical context](https://doc.rust-lang.org/book/).

#### Local examples

**Contextual prevention example:**

```rust
let state = cell.try_borrow_mut().map_err(|_| Error::Busy)?;
```

**Failure fragment or claim (do not execute):**

```text
let state = cell.borrow_mut();
callback_that_reenters();
```

---

<a id="rpit-007"></a>

### RPIT-007: Integer truncation at a boundary

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** An external `u64` length becomes `u32` or `usize` through `as`.

**Failure mechanism:** The converted length can differ from the validated length, undermining bounds or allocation
calculations.

**Prevention:** Use `TryFrom` and validate the target domain before allocation or access.

**Verification design:** Test zero, maximum accepted value, one above it and 32-bit targets.

**Prevention controls:** [RUST-012](rust-code-standard.md#rust-012), [RUST-020](rust-code-standard.md#rust-020).

**External references:** [Technical context](https://doc.rust-lang.org/book/).

#### Local examples

**Contextual prevention example:**

```rust
let length = usize::try_from(wire_length).map_err(|_| Error::Length)?;
```

**Failure fragment or claim (do not execute):**

```text
let length = wire_length as usize;
```

---

<a id="rpit-008"></a>

### RPIT-008: Pointer provenance violations

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A cache reconstructs a pointer from an integer after its original owner was freed.

**Failure mechanism:** A matching numerical address does not restore allocation lifetime or valid provenance.

**Prevention:** Retain the owner and derive pointers through documented APIs; use generational IDs for lookup.

**Verification design:** Review allocation lineage and exercise owner replacement/reuse under Miri.

**Prevention controls:** [RUST-028](rust-code-standard.md#rust-028), [RUST-041](rust-code-standard.md#rust-041).

**External references:** [Technical context](https://doc.rust-lang.org/std/ptr/index.html).

#### Local examples

**Contextual prevention example:**

```rust
let owner = registry.acquire(id)?;
inspect(owner.as_ref());
```

**Failure fragment or claim (do not execute):**

```text
let value = unsafe { &*(saved_address as *const Entry) };
```

---

<a id="rpit-009"></a>

### RPIT-009: Invalid transmute

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** Code transmutes an arbitrary integer into an enum because their sizes match.

**Failure mechanism:** Some bit patterns are invalid for the destination, and equal size proves neither validity
nor lifetime.

**Prevention:** Decode through a checked match or a reviewed conversion with a complete validity proof.

**Verification design:** Test all admitted tags and reject unknown ones without constructing an invalid enum.

**Prevention controls:** [RUST-031](rust-code-standard.md#rust-031), [RUST-020](rust-code-standard.md#rust-020).

**External references:** [Technical context](https://doc.rust-lang.org/reference/behavior-considered-undefined.html).

#### Local examples

**Contextual prevention example:**

```rust
let tag = Tag::try_from(raw_tag)?;
```

**Failure fragment or claim (do not execute):**

```text
let tag: Tag = unsafe { std::mem::transmute(raw_tag) };
```

---

<a id="rpit-010"></a>

### RPIT-010: Premature MaybeUninit completion

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** `assume_init()` runs after only some elements or fields were written.

**Failure mechanism:** The resulting value contains uninitialized or invalid data; partial cleanup may also drop
unwritten elements.

**Prevention:** Track initialization progress, expose initialized values only after completion and drop the valid
prefix.

**Verification design:** Inject failure after each initialized element and verify exact destructor counts.

**Prevention controls:** [RUST-030](rust-code-standard.md#rust-030).

**External references:** [Technical context](https://doc.rust-lang.org/std/mem/union.MaybeUninit.html).

#### Local examples

**Contextual prevention example:**

```rust
slot.write(value);
initialized += 1;
```

**Failure fragment or claim (do not execute):**

```text
let value = unsafe { slot.assume_init() }; // No complete initialization.
```

---

<a id="rpit-011"></a>

### RPIT-011: Creating an invalid reference before checking it

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A wrapper forms `&*ptr` and then checks alignment or nullness.

**Failure mechanism:** Reference creation already requires validity; a later check cannot repair the operation.

**Prevention:** Check rejectable scalar conditions first and require external lifetime/access facts in an unsafe
contract.

**Verification design:** Review operation order and test safe rejection without constructing invalid references.

**Prevention controls:** [RUST-029](rust-code-standard.md#rust-029).

**External references:** [Technical context](https://doc.rust-lang.org/std/slice/fn.from_raw_parts.html).

#### Local examples

**Contextual prevention example:**

```rust
if ptr.is_null() {
    return Err(Error::Null);
}
// The remaining lifetime, extent and aliasing proof is still required.
```

**Failure fragment or claim (do not execute):**

```text
let value = unsafe { &*ptr };
if ptr.is_null() { return Err(Error::Null); }
```

---

<a id="rpit-012"></a>

### RPIT-012: Assuming a representation guarantee

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A decoder reads a default-layout Rust struct from network bytes.

**Failure mechanism:** Field order, padding and value validity are not a wire-format contract; repr(C) alone is not
serialization.

**Prevention:** Decode fields with explicit offsets, byte order and range checks.

**Verification design:** Use byte-level golden vectors and target-width/endianness cases.

**Prevention controls:** [RUST-011](rust-code-standard.md#rust-011), [RUST-023](rust-code-standard.md#rust-023).

**External references:** [Technical context](https://doc.rust-lang.org/reference/type-layout.html).

#### Local examples

**Contextual prevention example:**

```rust
let id = u32::from_le_bytes(encoded_id);
```

**Failure fragment or claim (do not execute):**

```text
let record = unsafe { std::ptr::read(input.as_ptr().cast::<Record>()) };
```

---

<a id="rpit-013"></a>

### RPIT-013: FFI ABI mismatch

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A declaration uses the wrong calling convention, integer width or struct field representation.

**Failure mechanism:** The foreign caller and Rust implementation disagree about arguments or returns, potentially
causing UB.

**Prevention:** Generate or review declarations for the actual target and use an explicit native ABI.

**Verification design:** Compile a real C consumer and assert layout/signature agreement on each supported ABI.

**Prevention controls:** [RUST-011](rust-code-standard.md#rust-011).

**External references:** [Technical context](https://doc.rust-lang.org/nomicon/ffi.html).

#### Local examples

**Contextual prevention example:**

```rust
#[repr(C)]
struct NativeView {
    data: *const u8,
    len: usize,
}
```

**Failure fragment or claim (do not execute):**

```text
struct NativeView { data: Vec<u8> } // Exposed as a C ABI record.
```

---

<a id="rpit-014"></a>

### RPIT-014: Panic crossing an FFI boundary

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** An exported operation panics after a failed allocation or invariant check.

**Failure mechanism:** A non-unwinding boundary can abort; permitted unwinding needs an agreed ABI and foreign
cleanup behavior.

**Prevention:** Use Result internally and a documented boundary error/panic policy; do not treat catch_unwind as an
abort catcher.

**Verification design:** Test panic behavior in a subprocess for each panic strategy.

**Prevention controls:** [RUST-035](rust-code-standard.md#rust-035), [RUST-005](rust-code-standard.md#rust-005).

**External references:** [Technical context](https://doc.rust-lang.org/nomicon/ffi.html).

#### Local examples

**Contextual prevention example:**

```rust
match operation() {
    Ok(value) => encode_success(value),
    Err(error) => encode_error(error),
}
```

**Failure fragment or claim (do not execute):**

```text
extern "C" fn entry() { panic!("bad input"); }
```

---

<a id="rpit-015"></a>

### RPIT-015: Unsound Send or Sync implementation

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A raw-handle wrapper manually implements Send despite thread-affine destruction.

**Failure mechanism:** Safe callers can move it to another thread and invoke an operation the resource contract
forbids.

**Prevention:** Let auto traits apply where possible; otherwise prove transfer, sharing and destructor requirements
separately.

**Verification design:** Audit generic bounds and callback thread rules; use compile-fail cases for forbidden transfer.

**Prevention controls:** [RUST-033](rust-code-standard.md#rust-033).

**External references:** [Technical context](https://doc.rust-lang.org/nomicon/send-and-sync.html).

#### Local examples

**Contextual prevention example:**

```text
// Keep the handle on its owning thread and send requests through a port.
```

**Failure fragment or claim (do not execute):**

```text
unsafe impl Send for ThreadAffineHandle {}
```

---

<a id="rpit-016"></a>

### RPIT-016: Incorrect Drop implementation

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** Drop panics during unwinding or destroys memory already transferred to another owner.

**Failure mechanism:** The process can abort or the resource can be released twice; skipped Drop is also legal in
safe code.

**Prevention:** Track transfer state and provide explicit fallible finalization without relying on guaranteed
destruction.

**Verification design:** Inject errors during construction/finalization and count exactly-once releases.

**Prevention controls:** [RUST-026](rust-code-standard.md#rust-026).

**External references:** [Technical context](https://doc.rust-lang.org/book/).

#### Local examples

**Contextual prevention example:**

```rust
let result = writer.finish();
report_completion(result);
```

**Failure fragment or claim (do not execute):**

```text
impl Drop for Writer {
    fn drop(&mut self) { self.flush().unwrap(); }
}
```

---

<a id="rpit-017"></a>

### RPIT-017: Breaking Pin invariants

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** An unchecked projection exposes a movable field that an internal pointer relies on.

**Failure mechanism:** Pinned address-dependent state can become invalid despite the outer Pin wrapper.

**Prevention:** Define structural pinning and audit projection, replacement, Drop and Unpin together.

**Verification design:** Review every mutable accessor and use a qualified pin-projection implementation.

**Prevention controls:** [RUST-032](rust-code-standard.md#rust-032).

**External references:** [Technical context](https://doc.rust-lang.org/std/pin/index.html).

#### Local examples

**Contextual prevention example:**

```rust
let pinned = Box::pin(operation());
```

**Failure fragment or claim (do not execute):**

```text
let moved = unsafe { std::ptr::read(pinned.as_ref().get_ref()) };
```

---

<a id="rpit-018"></a>

### RPIT-018: Cancellation loses progress

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A select branch drops an in-progress read or write and retries as if nothing happened.

**Failure mechanism:** External progress or consumed bytes may already exist, producing duplication or data loss.

**Prevention:** Keep progress in a surviving owner, or use an operation documented as cancellation safe for that
use.

**Verification design:** Cancel at each await point; compare received bytes and state against uninterrupted execution.

**Prevention controls:** [RUST-038](rust-code-standard.md#rust-038), [RUST-046](rust-code-standard.md#rust-046).

**External references:** [Technical context](https://docs.rs/tokio/latest/tokio/macro.select.html).

#### Local examples

**Contextual prevention example:**

```rust
transfer.sent += write_some(&payload[transfer.sent..]).await?;
```

**Failure fragment or claim (do not execute):**

```text
write_all(payload).await?; // Cancellation retries the whole payload.
```

---

<a id="rpit-019"></a>

### RPIT-019: Deadlock from lock order or callbacks

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** One path acquires A then B while another acquires B then A.

**Failure mechanism:** Each waits for a resource held by the other; reentrant callbacks can create the same cycle.

**Prevention:** Use a declared acquisition order and call unknown code outside internal critical sections.

**Verification design:** Model the lock graph and test coordinated opposing operations with bounded deadlines.

**Prevention controls:** [RUST-036](rust-code-standard.md#rust-036).

**External references:** [Technical context](https://doc.rust-lang.org/std/sync/struct.Mutex.html).

#### Local examples

**Contextual prevention example:**

```rust
let first = lock_a.lock()?;
let second = lock_b.lock()?; // All paths use A before B.
```

**Failure fragment or claim (do not execute):**

```text
let first = lock_b.lock()?;
let second = lock_a.lock()?; // Other paths use the opposite order.
```

---

<a id="rpit-020"></a>

### RPIT-020: Incorrect atomic ordering

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A ready flag uses Relaxed while publishing non-atomic payload data.

**Failure mechanism:** The reader has no required happens-before relation for observing initialized payload.

**Prevention:** Use the ordering/protocol justified by publication and reclamation; stronger ordering alone cannot
fix lifetime.

**Verification design:** Model writer/reader interleavings and run supported weakly ordered targets.

**Prevention controls:** [RUST-040](rust-code-standard.md#rust-040), [RUST-041](rust-code-standard.md#rust-041).

**External references:** [Technical context](https://doc.rust-lang.org/std/sync/atomic/enum.Ordering.html).

#### Local examples

**Contextual prevention example:**

```rust
// Payload validity follows the protocol; Release publishes prior writes.
ready.store(true, Ordering::Release);
```

**Failure fragment or claim (do not execute):**

```text
ready.store(true, Ordering::Relaxed); // Claimed to publish non-atomic data.
```

---

<a id="rpit-021"></a>

### RPIT-021: Overflow-dependent behavior

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** An unchecked size multiplication appears safe because debug tests panic.

**Failure mechanism:** Release behavior can produce an unintended count, and profile configuration can change
checks.

**Prevention:** Use checked multiplication/addition for sizes; choose wrapping only for a specified modular domain.

**Verification design:** Test overflow boundaries in debug and release and verify no mutation after rejection.

**Prevention controls:** [RUST-020](rust-code-standard.md#rust-020).

**External references:** [Technical context](https://doc.rust-lang.org/book/).

#### Local examples

**Contextual prevention example:**

```rust
let bytes = count.checked_mul(item_size).ok_or(Error::Size)?;
```

**Failure fragment or claim (do not execute):**

```text
let bytes = count * item_size;
```

---

<a id="rpit-022"></a>

### RPIT-022: Hidden heap work through abstraction

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A generic method invokes a Clone implementation, iterator adapter or boxed-future provider.

**Failure mechanism:** The public signature does not state the allocation, retention or synchronization cost of its
implementation.

**Prevention:** Define the resource contract for the selected provider; keep generics from hiding an unreviewed
hot-path cost.

**Verification design:** Measure production implementations as well as mocks, including trait dispatch and error
formatting.

**Prevention controls:** [RUST-009](rust-code-standard.md#rust-009), [RUST-019](rust-code-standard.md#rust-019),
[RUST-025](rust-code-standard.md#rust-025).

**External references:** [Technical context](https://nnethercote.github.io/perf-book/heap-allocations.html).

#### Local examples

**Contextual prevention example:**

```rust
// Provider contract: bounded work, no allocation after construction.
provider.process(input)?;
```

**Failure fragment or claim (do not execute):**

```text
let copy = generic_value.clone(); // Assumed cheap for every implementation.
```

---

<a id="rpit-023"></a>

### RPIT-023: Using unsafe to avoid design work

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A borrow conflict is bypassed with raw pointers or unchecked aliasing.

**Failure mechanism:** The original ownership conflict remains; the compiler can no longer enforce the missing
contract.

**Prevention:** Restructure lifetimes, split disjoint slices or move ownership before considering a smaller unsafe
primitive.

**Verification design:** Document the safe alternative and audit the entire invariant boundary.

**Prevention controls:** [RUST-008](rust-code-standard.md#rust-008), [RUST-010](rust-code-standard.md#rust-010).

**External references:** [Technical context](https://fuchsia.dev/fuchsia-src/development/languages/rust/unsafe).

#### Local examples

**Contextual prevention example:**

```rust
let (left, right) = values.split_at_mut(midpoint);
```

**Failure fragment or claim (do not execute):**

```text
let left = unsafe { &mut *ptr };
let right = unsafe { &mut *ptr }; // Overlapping mutable references.
```

---

<a id="rpit-024"></a>

### RPIT-024: Leaking unsafe obligations through a safe API

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A safe setter permits a length larger than the backing allocation used by unchecked reads.

**Failure mechanism:** Safe callers can violate the internal invariant and trigger UB through an apparently safe
method.

**Prevention:** Keep fields private and make every safe mutation preserve the unchecked operation contract.

**Verification design:** Fuzz sequences of safe operations under Miri, not just the unsafe function in isolation.

**Prevention controls:** [RUST-010](rust-code-standard.md#rust-010), [RUST-018](rust-code-standard.md#rust-018),
[RUST-029](rust-code-standard.md#rust-029).

**External references:** [Technical context](https://fuchsia.dev/fuchsia-src/development/languages/rust/unsafe).

#### Local examples

**Contextual prevention example:**

```rust
if len > self.initialized {
    return Err(Error::Bounds);
}
self.len = len;
```

**Failure fragment or claim (do not execute):**

```text
pub fn set_len(&mut self, len: usize) { self.len = len; }
```

---

<a id="rpit-025"></a>

### RPIT-025: Unbounded resource consumption

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** Input controls recursive depth, vector reservation or spawned tasks without admission limits.

**Failure mechanism:** Memory-safe code can exhaust stack, heap, descriptors or scheduling capacity.

**Prevention:** Apply limits before work, bound queues and define an error that does not require more unbounded
resources.

**Verification design:** Exercise each limit and sustained rejection; inspect retained memory and live resources.

**Prevention controls:** [RUST-025](rust-code-standard.md#rust-025), [RUST-027](rust-code-standard.md#rust-027),
[RUST-049](rust-code-standard.md#rust-049).

**External references:** [Technical context](https://anssi-fr.github.io/rust-guide/).

#### Local examples

**Contextual prevention example:**

```rust
limits.check_payload(bytes.len())?;
queue.try_send(request)?;
```

**Failure fragment or claim (do not execute):**

```text
loop {
    tasks.push(spawn_work(next_input()));
}
```

---

## Boundary, build and verification failures

---

<a id="rpit-026"></a>

### RPIT-026: Borrowed pointer survives reallocation

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A pointer into a Vec remains cached while push or reserve may move its storage.

**Failure mechanism:** The saved address can become stale even though the Vec owner still exists.

**Prevention:** Reacquire views after mutation, or use storage with the required stability and a matching API.

**Verification design:** Force growth from small capacities and inspect all saved pointers under Miri.

**Prevention controls:** [RUST-024](rust-code-standard.md#rust-024), [RUST-028](rust-code-standard.md#rust-028).

**External references:** [Technical context](https://doc.rust-lang.org/std/ptr/index.html).

#### Local examples

**Contextual prevention example:**

```rust
values.push(next);
let view = values.as_slice();
```

**Failure fragment or claim (do not execute):**

```text
let ptr = values.as_ptr();
values.push(next);
let value = unsafe { *ptr };
```

---

<a id="rpit-027"></a>

### RPIT-027: Mismatched native allocator ownership

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A wrapper constructs a Rust owner from memory allocated by an unrelated C allocator.

**Failure mechanism:** Drop invokes an incompatible deallocator, layout or capacity contract.

**Prevention:** Keep the native owner with its matching destroy function; copy into a Rust owner when needed.

**Verification design:** Test allocation/deallocation pairing in a native harness and instrument failure transfers.

**Prevention controls:** [RUST-024](rust-code-standard.md#rust-024), [RUST-034](rust-code-standard.md#rust-034).

**External references:** [Technical context](https://doc.rust-lang.org/std/alloc/trait.GlobalAlloc.html).

#### Local examples

**Contextual prevention example:**

```rust
// The native owner calls the paired native destroy function.
native_owner.close()?;
```

**Failure fragment or claim (do not execute):**

```text
let owner = unsafe { Box::from_raw(pointer_from_foreign_allocator) };
```

---

<a id="rpit-028"></a>

### RPIT-028: Zero length treated as permission for a null reference

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A wrapper passes `(null, 0)` directly to `from_raw_parts`.

**Failure mechanism:** The slice constructor still requires a non-null aligned pointer, including empty slices.

**Prevention:** Return an empty slice before raw construction when the foreign contract permits null for empty
input.

**Verification design:** Test the empty-null case through the documented wrapper; never invoke the raw API incorrectly.

**Prevention controls:** [RUST-029](rust-code-standard.md#rust-029).

**External references:** [Technical context](https://doc.rust-lang.org/std/slice/fn.from_raw_parts.html).

#### Local examples

**Contextual prevention example:**

```rust
if len == 0 {
    return Ok(&[]);
}
// Construct the nonempty slice only under the complete unsafe contract.
```

**Failure fragment or claim (do not execute):**

```text
let bytes = unsafe { std::slice::from_raw_parts(std::ptr::null(), 0) };
```

---

<a id="rpit-029"></a>

### RPIT-029: Losing initialized values during partial construction

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** An error path abandons initialized fields or drops uninitialized storage.

**Failure mechanism:** Manual initialization bypasses ordinary automatic cleanup until valid owners are
established.

**Prevention:** Use safe collection construction or an initialized-prefix guard with a precise ownership state.

**Verification design:** Count drops for failure at each step and success after complete initialization.

**Prevention controls:** [RUST-030](rust-code-standard.md#rust-030), [RUST-026](rust-code-standard.md#rust-026).

**External references:** [Technical context](https://doc.rust-lang.org/std/mem/union.MaybeUninit.html).

#### Local examples

**Contextual prevention example:**

```rust
// Initialization guard owns only 0..initialized and drops that prefix.
guard.push_initialized(value)?;
```

**Failure fragment or claim (do not execute):**

```text
initialized = capacity; // Marks unwritten elements as owned values.
```

---

<a id="rpit-030"></a>

### RPIT-030: Reading packed fields through references

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A format macro or accessor borrows a potentially unaligned packed field.

**Failure mechanism:** The implicit reference can violate alignment before any load that appears explicit in
source.

**Prevention:** Copy through a permitted value access or use a reviewed raw unaligned read; prefer byte decoding.

**Verification design:** Inspect expanded operations and test the decoder with deliberately unaligned source placement.

**Prevention controls:** [RUST-023](rust-code-standard.md#rust-023), [RUST-029](rust-code-standard.md#rust-029).

**External references:** [Technical context](https://doc.rust-lang.org/reference/type-layout.html).

#### Local examples

**Contextual prevention example:**

```rust
let word = u32::from_le_bytes([input[0], input[1], input[2], input[3]]);
```

**Failure fragment or claim (do not execute):**

```text
let field_ref = &packed.field; // May create an unaligned reference.
```

---

<a id="rpit-031"></a>

### RPIT-031: Treating HashMap order as stable output

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A report or serialized artifact follows map iteration order.

**Failure mechanism:** Insertion history and randomized hashing can change ordering across runs.

**Prevention:** Sort output keys or choose an ordered collection whose ordering matches the format.

**Verification design:** Repeat with different process seeds and insertion permutations, comparing serialized bytes.

**Prevention controls:** [RUST-057](rust-code-standard.md#rust-057).

**External references:** [Technical context](https://doc.rust-lang.org/book/).

#### Local examples

**Contextual prevention example:**

```rust
let mut entries: Vec<_> = map.iter().collect();
entries.sort_by_key(|entry| entry.0);
```

**Failure fragment or claim (do not execute):**

```text
for entry in &map { encode(entry); } // Claims canonical serialization.
```

---

<a id="rpit-032"></a>

### RPIT-032: Newtype invariant bypass

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A validated identifier derives unchecked deserialization or exposes its inner field.

**Failure mechanism:** A second construction path admits values rejected by the intended constructor.

**Prevention:** Route conversion, deserialization and Default through the same invariant owner.

**Verification design:** Test each public construction path with invalid and boundary values.

**Prevention controls:** [RUST-018](rust-code-standard.md#rust-018).

**External references:** [Technical context](https://rust-lang.github.io/api-guidelines/checklist.html).

#### Local examples

**Contextual prevention example:**

```rust
let port = Port::try_from(decoded_value)?;
```

**Failure fragment or claim (do not execute):**

```text
let port = Port(decoded_value); // Bypasses validation inside the owner.
```

---

<a id="rpit-033"></a>

### RPIT-033: UnsafeCell mistaken for synchronization

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A shared wrapper mutates UnsafeCell storage without a thread protocol.

**Failure mechanism:** Interior mutability permits a category of aliasing; it does not prevent concurrent data
races.

**Prevention:** Provide exclusive access or approved atomic/locking synchronization, with a complete Sync proof.

**Verification design:** Model overlapping readers/writers and review the safe API for unguarded access.

**Prevention controls:** [RUST-014](rust-code-standard.md#rust-014), [RUST-033](rust-code-standard.md#rust-033),
[RUST-040](rust-code-standard.md#rust-040).

**External references:** [Technical context](https://doc.rust-lang.org/nomicon/send-and-sync.html).

#### Local examples

**Contextual prevention example:**

```rust
let mut guard = state.lock()?;
guard.update();
```

**Failure fragment or claim (do not execute):**

```text
unsafe { *shared_cell.get() = next }; // No exclusive-access protocol.
```

---

<a id="rpit-034"></a>

### RPIT-034: Atomic pointer lifetime race and ABA

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A reader loads a pointer while another thread removes and frees the object.

**Failure mechanism:** Atomic access protects the pointer slot, not the pointee; address reuse can mask
replacement.

**Prevention:** Use a retention/reclamation protocol and account for ABA in comparisons.

**Verification design:** Force remove/reuse interleavings and inspect reclamation under model tests.

**Prevention controls:** [RUST-041](rust-code-standard.md#rust-041).

**External references:** [Technical context](https://doc.rust-lang.org/std/ptr/index.html).

#### Local examples

**Contextual prevention example:**

```rust
let retained = shared.acquire()?;
inspect(retained.as_ref());
```

**Failure fragment or claim (do not execute):**

```text
let ptr = shared.load(Ordering::Acquire);
unsafe { inspect(&*ptr) }; // Removal can free it before use.
```

---

<a id="rpit-035"></a>

### RPIT-035: Retrying a partial write as a new operation

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** An adapter reports only failure after writing a prefix, then retries the full buffer.

**Failure mechanism:** The destination can receive duplicate bytes or a malformed record.

**Prevention:** Expose progress or maintain it internally under a bounded retry contract; document non-atomic
effects.

**Verification design:** Inject short writes, interruptions and a later failure; assert exact destination bytes.

**Prevention controls:** [RUST-046](rust-code-standard.md#rust-046), [RUST-045](rust-code-standard.md#rust-045).

**External references:** [Technical context](https://doc.rust-lang.org/std/io/trait.Write.html).

#### Local examples

**Contextual prevention example:**

```rust
progress += writer.write(&payload[progress..])?;
```

**Failure fragment or claim (do not execute):**

```text
writer.write(payload)?;
return Ok(()); // Ignores a short write.
```

---

<a id="rpit-036"></a>

### RPIT-036: Confusing flush with crash durability

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A success response follows an in-memory flush before required persistent synchronization.

**Failure mechanism:** A crash can lose or partially publish an update the caller believed durable.

**Prevention:** Use a platform-specific write/sync/rename or journal protocol with a recovery design.

**Verification design:** Crash at each persistence stage and verify recovered invariants.

**Prevention controls:** [RUST-046](rust-code-standard.md#rust-046).

**External references:** [Technical context](https://doc.rust-lang.org/std/io/trait.Write.html).

#### Local examples

**Contextual prevention example:**

```rust
file.write_all(payload)?;
file.sync_all()?; // Remaining rename/directory rules belong to the platform.
```

**Failure fragment or claim (do not execute):**

```text
buffered.flush()?; // Claimed to guarantee durable transaction commit.
```

---

<a id="rpit-037"></a>

### RPIT-037: Path validation separated from use

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A path is checked, then an attacker replaces a symlink before the file opens.

**Failure mechanism:** The authorized spelling and the opened object can differ.

**Prevention:** Use an authority-aware open protocol and validate the actual object under platform guarantees.

**Verification design:** Exercise replacement races and traversal variants in an isolated directory fixture.

**Prevention controls:** [RUST-048](rust-code-standard.md#rust-048).

**External references:** [Technical context](https://anssi-fr.github.io/rust-guide/).

#### Local examples

**Contextual prevention example:**

```rust
let file = directory_capability.open_authorized(relative_path)?;
```

**Failure fragment or claim (do not execute):**

```text
if path.exists() {
    File::open(path)?; // Checked object can change before open.
}
```

---

<a id="rpit-038"></a>

### RPIT-038: Secret disclosure through derived formatting

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A secret-bearing type derives Debug and enters an error chain or log.

**Failure mechanism:** A harmless-looking diagnostic exposes credentials or key material.

**Prevention:** Provide redacted formatting and minimize retained secret copies; include nested error sources.

**Verification design:** Render success/failure diagnostics with a canary secret and assert its absence.

**Prevention controls:** [RUST-050](rust-code-standard.md#rust-050), [RUST-004](rust-code-standard.md#rust-004).

**External references:** [Technical
context](https://microsoft.github.io/rust-guidelines/guidelines/universal/index.html).

#### Local examples

**Contextual prevention example:**

```rust
formatter.write_str("Credentials([redacted])")
```

**Failure fragment or claim (do not execute):**

```text
write!(formatter, "Credentials({:?})", self.secret)
```

---

<a id="rpit-039"></a>

### RPIT-039: Feature unification masks an unsupported build

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** Workspace tests pass only because a sibling enables a dependency feature.

**Failure mechanism:** An external consumer with fewer features fails or receives different behavior.

**Prevention:** Test each supported feature set and a clean consumer of the packaged crate.

**Verification design:** Build default, no-default and supported combinations independently.

**Prevention controls:** [RUST-053](rust-code-standard.md#rust-053), [RUST-055](rust-code-standard.md#rust-055).

**External references:** [Technical context](https://doc.rust-lang.org/cargo/reference/features.html).

#### Local examples

**Contextual prevention example:**

```text
// Build the packaged leaf in a clean consumer with default features off.
```

**Failure fragment or claim (do not execute):**

```text
// Workspace all-features succeeds, so every leaf feature set is supported.
```

---

<a id="rpit-040"></a>

### RPIT-040: no_std mistaken for no allocation or no panic

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A crate uses alloc or a panic-capable operation while claiming a bounded core.

**Failure mechanism:** Removing std does not enforce the claimed resource or termination contract.

**Prevention:** Declare CORE, ALLOC and REALTIME properties separately and audit dependencies.

**Verification design:** Compile the actual target without default features; measure allocations and inspect panic
paths.

**Prevention controls:** [RUST-043](rust-code-standard.md#rust-043), [RUST-025](rust-code-standard.md#rust-025).

**External references:** [Technical context](https://doc.rust-lang.org/embedded-book/).

#### Local examples

**Contextual prevention example:**

```rust
#![no_std]
// Separately check dependencies, panic paths and allocation budget.
```

**Failure fragment or claim (do not execute):**

```text
#![no_std]
extern crate alloc; // Claimed as a no-heap guarantee.
```

---

<a id="rpit-041"></a>

### RPIT-041: Uncontrolled build-time code execution

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** An added dependency runs build.rs or a procedural macro with CI credentials available.

**Failure mechanism:** Compilation executes code on the host before any runtime sandbox applies.

**Prevention:** Review provenance and build authority; isolate untrusted builds and pin dependency resolution.

**Verification design:** Inspect build dependencies, environment access and clean-build network behavior.

**Prevention controls:** [RUST-052](rust-code-standard.md#rust-052), [RUST-054](rust-code-standard.md#rust-054).

**External references:** [Technical context](https://microsoft.github.io/rust-guidelines/guidelines/project/index.html).

#### Local examples

**Contextual prevention example:**

```text
// Build untrusted dependencies in a credential-free isolated environment.
```

**Failure fragment or claim (do not execute):**

```text
// Run dependency build.rs with release-signing credentials available.
```

---

<a id="rpit-042"></a>

### RPIT-042: MSRV or edition inferred from one compiler run

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A new API compiles on the developer toolchain but exceeds the declared MSRV.

**Failure mechanism:** Consumers on a supported compiler cannot build, even if the edition is unchanged.

**Prevention:** Test the declared MSRV and record edition/style edition separately.

**Verification design:** Compile a clean package consumer on the minimum and pinned compilers.

**Prevention controls:** [RUST-055](rust-code-standard.md#rust-055).

**External references:** [Technical context](https://doc.rust-lang.org/edition-guide/rust-2024/index.html).

#### Local examples

**Contextual prevention example:**

```text
// Test the declared rust-version and the pinned release compiler.
```

**Failure fragment or claim (do not execute):**

```text
// One latest-toolchain run establishes compatibility with every edition.
```

---

<a id="rpit-043"></a>

### RPIT-043: A green all-features build treated as full coverage

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** CI runs all features on one host and reports all targets qualified.

**Failure mechanism:** Disabled code, minimal features, other target triples and runtime paths remain untested.

**Prevention:** Maintain an explicit product matrix and separate compile/link/execute evidence.

**Verification design:** Audit the selected jobs against target triples and feature absence as well as presence.

**Prevention controls:** [RUST-053](rust-code-standard.md#rust-053), [RUST-059](rust-code-standard.md#rust-059).

**External references:** [Technical context](https://doc.rust-lang.org/cargo/reference/features.html).

#### Local examples

**Contextual prevention example:**

```text
// Matrix row = target triple + feature set + compiler + execution mode.
```

**Failure fragment or claim (do not execute):**

```text
cargo test --all-features // Claimed to execute on all CPU architectures.
```

---

<a id="rpit-044"></a>

### RPIT-044: Miri success presented as a soundness proof

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A small Miri test is used to approve all safe callers of an unsafe abstraction.

**Failure mechanism:** The run explores only its executed paths and supported operations under its model.

**Prevention:** Combine invariant review, adversarial safe-client tests and complementary verification.

**Verification design:** Record model/toolchain, seeds, unsupported FFI and remaining coverage gaps.

**Prevention controls:** [RUST-010](rust-code-standard.md#rust-010), [RUST-058](rust-code-standard.md#rust-058),
[RUST-059](rust-code-standard.md#rust-059).

**External references:** [Technical context](https://github.com/rust-lang/miri).

#### Local examples

**Contextual prevention example:**

```text
// Record Miri paths, assumptions and unsupported native calls.
```

**Failure fragment or claim (do not execute):**

```text
// One clean Miri run proves the abstraction for all safe callers.
```

---

<a id="rpit-045"></a>

### RPIT-045: Unsupported ISA reached by dispatch

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A specialized function executes before CPU and OS capability checks.

**Failure mechanism:** Unsupported target-feature execution can violate the platform contract.

**Prevention:** Centralize detection and safe fallback; do not use build-host features as deployment facts.

**Verification design:** Force each supported backend and simulate feature absence without executing forbidden
instructions.

**Prevention controls:** [RUST-059](rust-code-standard.md#rust-059).

**External references:** [Technical context](https://doc.rust-lang.org/reference/behavior-considered-undefined.html).

#### Local examples

**Contextual prevention example:**

```text
// Detection precedes target_feature entry; tests observe backend identity.
```

**Failure fragment or claim (do not execute):**

```text
// Compile with target-cpu=native and ship to unknown processors.
```

---

<a id="rpit-046"></a>

### RPIT-046: Allocator logging recursively allocates

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A GlobalAlloc implementation formats a message with heap-backed logging.

**Failure mechanism:** Allocator entry reenters itself or an internal lock, causing recursion or deadlock.

**Prevention:** Use a proven nonallocating diagnostic path or collect bounded counters outside the allocator.

**Verification design:** Instrument entry depth and test failure reporting and lazy initialization.

**Prevention controls:** [RUST-056](rust-code-standard.md#rust-056).

**External references:** [Technical context](https://doc.rust-lang.org/std/alloc/trait.GlobalAlloc.html).

#### Local examples

**Contextual prevention example:**

```text
// Count through a reviewed nonallocating path; format outside allocation.
```

**Failure fragment or claim (do not execute):**

```text
let message = format!("allocation size={size}");
```

---

<a id="rpit-047"></a>

### RPIT-047: Benchmark eliminates or excludes required work

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** The measured result is unused, or setup, cloning and destruction move outside the claimed operation.

**Failure mechanism:** The optimizer may remove work or the experiment measures only a cheaper sub-operation.

**Prevention:** Consume results, separate kernel and lifecycle measurements and preserve reference checks.

**Verification design:** Inspect optimized code and compare end-to-end results and costs.

**Prevention controls:** [RUST-009](rust-code-standard.md#rust-009), [RUST-059](rust-code-standard.md#rust-059).

**External references:** [Technical context](https://nnethercote.github.io/perf-book/profiling.html).

#### Local examples

**Contextual prevention example:**

```rust
let output = std::hint::black_box(candidate(std::hint::black_box(input)));
check_output(output);
```

**Failure fragment or claim (do not execute):**

```text
candidate(input); // Unused result in an isolated benchmark.
```

---

<a id="rpit-048"></a>

### RPIT-048: Leaked owner makes a safe abstraction unsound

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A wrapper relies on its Drop to revoke a borrowed pointer handed to a longer-lived subsystem.

**Failure mechanism:** Safe mem::forget can bypass Drop, leaving another safe operation able to use invalid
storage.

**Prevention:** Make lifetime safety survive leaked values; use a borrow or a retained owner enforced by the API.

**Verification design:** Review deliberate forget/leak scenarios without executing UB; use compile-fail ownership tests.

**Prevention controls:** [RUST-008](rust-code-standard.md#rust-008), [RUST-026](rust-code-standard.md#rust-026).

**External references:** [Technical context](https://doc.rust-lang.org/reference/behavior-considered-undefined.html).

#### Local examples

**Contextual prevention example:**

```text
// Retain owned backing storage until the subsystem releases its access.
```

**Failure fragment or claim (do not execute):**

```text
// Drop revokes access, so forgetting the guard cannot affect soundness.
```

---

<a id="rpit-049"></a>

### RPIT-049: Old backend survives cache invalidation

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A dispatch cache keeps a code pointer after a plugin reload or topology/configuration change.

**Failure mechanism:** The cached capability or code lifetime no longer matches the selected operation.

**Prevention:** Give invalidation and reclamation one synchronized owner and a complete cache key.

**Verification design:** Test replacement with active users and assert generation/backend identity.

**Prevention controls:** [RUST-051](rust-code-standard.md#rust-051).

**External references:** [Technical
context](https://microsoft.github.io/rust-guidelines/guidelines/universal/index.html).

#### Local examples

**Contextual prevention example:**

```text
// Hold a generation lease through the call and retire after draining users.
```

**Failure fragment or claim (do not execute):**

```text
cached_function(); // Code library was unloaded after cache lookup.
```

---

<a id="rpit-050"></a>

### RPIT-050: Documentation examples bypass verification

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** Markdown contains plausible Rust snippets that no Cargo target or rustdoc test discovers.

**Failure mechanism:** The code can drift while the repository tests remain green.

**Prevention:** Label complete files, contextual fragments and negative cases; extract/run complete examples
separately.

**Verification design:** Verify the extracted file inventory and retained compiler/formatter/test results.

**Prevention controls:** [RUST-004](rust-code-standard.md#rust-004), [RUST-058](rust-code-standard.md#rust-058),
[RUST-059](rust-code-standard.md#rust-059).

**External references:** [Technical
context](https://doc.rust-lang.org/rustdoc/write-documentation/documentation-tests.html).

#### Local examples

**Contextual prevention example:**

```text
// Extract named complete fences, then compile, lint and execute them.
```

**Failure fragment or claim (do not execute):**

```text
// cargo test discovers every Markdown fence in docs automatically.
```

---

<a id="complete-raw-input-boundary-example"></a>

## Appendix A. Complete raw-input boundary example

Save the following library as `raw_input.rs`. The wrapper permits a null pointer for empty input and rejects
null for nonempty input. It cannot validate the lifetime or accessibility of an arbitrary foreign address;
those facts remain caller obligations, so the function stays unsafe. The maximum admitted length also bounds
the byte sum, avoiding overflow without unbounded work.

<!-- example-file: raw_input.rs -->
```rust
#![deny(unsafe_op_in_unsafe_fn)]

use std::slice;

const MAX_INPUT_BYTES: usize = 4096;

#[derive(Debug, PartialEq, Eq)]
pub enum InputError {
    Limit,
    Null,
}

/// Sums at most 4096 bytes without retaining the input.
///
/// # Errors
/// Returns `Limit` if the length exceeds the budget, and `Null` for a null
/// pointer with a nonzero admitted length. Empty input returns zero.
///
/// # Safety
/// If `data` is non-null and `len` is in 1..=4096, `data` must refer to
/// `len` initialized bytes in one live allocation. The bytes must remain
/// readable and must not be mutated for this call, including by foreign
/// threads or a device. No pointer validity obligation applies to inputs
/// that this function rejects before reading, or to empty input.
///
/// # Examples
/// ```
/// use raw_input::sum_raw;
///
/// let bytes = [1_u8, 2, 3];
/// // SAFETY: The array remains live and immutable throughout the call.
/// let result = unsafe { sum_raw(bytes.as_ptr(), bytes.len()) };
/// assert_eq!(result, Ok(6));
/// ```
pub unsafe fn sum_raw(data: *const u8, len: usize) -> Result<u64, InputError> {
    if len > MAX_INPUT_BYTES {
        return Err(InputError::Limit);
    }
    if len == 0 {
        return Ok(0);
    }
    if data.is_null() {
        return Err(InputError::Null);
    }

    // SAFETY: The checks establish a non-null pointer and a bounded nonzero
    // length below isize::MAX. u8 has alignment 1. The caller guarantees one
    // live allocation, initialized readable bytes and no mutation during
    // this call. The slice stays within this call and is not retained.
    let bytes = unsafe { slice::from_raw_parts(data, len) };
    Ok(bytes.iter().map(|byte| u64::from(*byte)).sum())
}

#[cfg(test)]
mod tests {
    use super::{InputError, MAX_INPUT_BYTES, sum_raw};
    use std::ptr;

    #[test]
    fn null_empty_is_accepted() {
        // SAFETY: Empty input imposes no pointer validity obligation.
        assert_eq!(unsafe { sum_raw(ptr::null(), 0) }, Ok(0));
    }

    #[test]
    fn null_nonempty_is_rejected() {
        // SAFETY: Null input is rejected before any reference or read.
        assert_eq!(unsafe { sum_raw(ptr::null(), 1) }, Err(InputError::Null));
    }

    #[test]
    fn oversized_input_is_rejected_before_pointer_use() {
        // SAFETY: The length rejection precedes any pointer use.
        let result = unsafe { sum_raw(ptr::null(), MAX_INPUT_BYTES + 1) };
        assert_eq!(result, Err(InputError::Limit));
    }

    #[test]
    fn admitted_boundary_has_a_bounded_sum() {
        let bytes = [255_u8; MAX_INPUT_BYTES];
        // SAFETY: This live immutable array contains the full admitted range.
        let result = unsafe { sum_raw(bytes.as_ptr(), bytes.len()) };
        assert_eq!(result, Ok(1_044_480));
    }
}

// EOF
```

This example demonstrates an unsafe Rust boundary, not a complete C export. A C-facing adapter must define
calling convention, result representation and symbol ownership separately. Tests only call the function
within its documented safety contract; they do not pass dangling or fabricated non-null pointers.

For an independent negative lifetime test, the following complete snippet must fail with a diagnostic about
returning a value that references local storage. Check that diagnostic in the harness. Any unrelated parser
or missing-import error is a failed test setup, not a successful lifetime check.

```compile_fail
fn escaped_slice() -> &'static [u8] {
    let bytes = [1_u8, 2, 3];
    &bytes
}

fn main() {
    let _ = escaped_slice();
}
```

---

## Additional boundary failure scenarios

---

<a id="rpit-051"></a>

### RPIT-051: Reconstructing a vector with a borrowed-view layout

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** An adapter receives a pointer and length, then adopts them as an owned vector.

**Failure mechanism:** The view lacks allocation capacity, allocator identity and exclusive destruction authority.
Even readable initialized bytes cannot establish a matching deallocation layout.

**Prevention controls and source context:** [RUST-085](rust-code-standard.md#rust-085).
The linked control identifies the primary API contract and applicability profile.

**Verification design:** Round-trip only valid owned vectors with spare capacity, empty storage and zero-sized elements.
Review the native allocation/release pair independently; never probe invalid reconstruction as a normal unit test.

**Contextual prevention contract (not executable):**

```text
owned transfer includes original capacity and element layout; destructor stays with allocation owner
```

**Failure fragment or claim (do not execute):**

```text
Vec::from_raw_parts(foreign_borrowed_ptr, byte_count, byte_count)
```

---

<a id="rpit-052"></a>

### RPIT-052: Publishing uninitialized elements before a callback finishes

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A bulk builder raises length before invoking constructors that can fail.

**Failure mechanism:** Unwinding drops slots declared initialized by length, although some never contained valid values.
Keeping length unchanged avoids that invalid drop but still needs ownership for successfully constructed elements.

**Prevention controls and source context:** [RUST-086](rust-code-standard.md#rust-086).
The linked control identifies the primary API contract and applicability profile.

**Verification design:** Inject constructor failure at every position and count drops for the initialized prefix.
Use the standard's allocation fixture as the safe construction reference before considering an unsafe optimization.

**Contextual prevention contract (not executable):**

```text
construct one value -> push into owner -> next construction
```

**Failure fragment or claim (do not execute):**

```text
reserve -> set_len(total) -> run fallible constructors
```

---

<a id="rpit-053"></a>

### RPIT-053: Losing readiness between inspection and waker registration

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A consumer observes not-ready, then a producer completes before the waiter is registered.

**Failure mechanism:** A notification can occur while no waiter exists;
the subsequent `Pending` may have no future event to wake it.

**Prevention controls and source context:** [RUST-087](rust-code-standard.md#rust-087).
The linked control identifies the primary API contract and applicability profile.

**Verification design:** Schedule completion on both sides of registration, then replace the polling waker.
Check readiness and delivery, not merely whether any historical waker was called.

**Contextual prevention contract (not executable):**

```text
register current waker -> decisive readiness check under the protocol
```

**Failure fragment or claim (do not execute):**

```text
check once -> producer completes -> register -> Pending forever
```

---

<a id="rpit-054"></a>

### RPIT-054: Reading payload on an unsynchronized failed exchange

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A failed compare-and-exchange returns an observed state used to access shared payload.

**Failure mechanism:** The failure path only loads. Its ordering may not establish the required happens-before relation
even though the success path would acquire or release correctly.

**Prevention controls and source context:** [RUST-088](rust-code-standard.md#rust-088).
The linked control identifies the primary API contract and applicability profile.

**Verification design:** Identify the writer and matching observation for each read in the failure branch.
Model a failed exchange and reclamation independently; do not execute a deliberate data race.

**Contextual prevention contract (not executable):**

```text
failed CAS -> explicit payload synchronization proof -> bounded use under a live owner
```

**Failure fragment or claim (do not execute):**

```text
success ordering is AcqRel, therefore every failure also acquires payload
```

---

<a id="rpit-055"></a>

### RPIT-055: Checking a null function pointer after creating it

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A foreign optional callback is represented as a non-optional Rust function pointer.

**Failure mechanism:** The Rust value is already invalid when null is materialized; a later branch cannot repair that construction.

**Prevention controls and source context:** [RUST-089](rust-code-standard.md#rust-089).
The linked control identifies the primary API contract and applicability profile.

**Verification design:** Use a native consumer to send an absent and a present callback through the declared ABI.
For retained calls, add shutdown and in-flight delivery cases.

**Contextual prevention contract (not executable):**

```text
Option<extern "C" fn(u32)>: None for absent, Some(callback) for present
```

**Failure fragment or claim (do not execute):**

```text
zeroed::<extern "C" fn(u32)>() followed by a null check
```

---

<a id="rpit-056"></a>

### RPIT-056: Letting workspace features hide a broken library consumer

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** Workspace tests enable a dependency capability absent from the minimal public dependency.

**Failure mechanism:** The selected workspace graph differs from the graph resolved by an external consumer.
Passing all-features tests does not exercise feature absence or prove the declared MSRV.

**Prevention controls and source context:** [RUST-090](rust-code-standard.md#rust-090).
The linked control identifies the primary API contract and applicability profile.

**Verification design:** Compile a separate minimal consumer for each promised target/MSRV combination.
Retain its feature graph and package inputs; report missing configurations explicitly.

**Contextual prevention contract (not executable):**

```text
packaged library -> minimal consumer graph -> promised compiler and target
```

**Failure fragment or claim (do not execute):**

```text
workspace all-features success -> claim every consumer configuration supported
```

---

<a id="references"></a>

## Links and references

Use the [source register](rust-code-standard.md#sources-and-revision-policy) for revision and scope.
The following primary API references support the particularly sensitive boundary cases:

| Entries | Technical reference |
| --- | --- |
| RPIT-008, RPIT-026, RPIT-034 | [Pointer safety and provenance](https://doc.rust-lang.org/std/ptr/index.html). |
| RPIT-010, RPIT-029 | [MaybeUninit initialization and drop contracts](https://doc.rust-lang.org/std/mem/union.MaybeUninit.html). |
| RPIT-011, RPIT-028 | [Raw slice construction](https://doc.rust-lang.org/std/slice/fn.from_raw_parts.html). |
| RPIT-012, RPIT-030 | [Type representation](https://doc.rust-lang.org/reference/type-layout.html). |
| RPIT-015, RPIT-033 | [Send and Sync](https://doc.rust-lang.org/nomicon/send-and-sync.html). |
| RPIT-017 | [Pin and structural pinning](https://doc.rust-lang.org/std/pin/index.html). |
| RPIT-003 | [Tokio shared state](https://tokio.rs/tokio/tutorial/shared-state). |
| RPIT-004 | [Mutex poisoning](https://doc.rust-lang.org/std/sync/struct.Mutex.html). |
| RPIT-018 | [Tokio select cancellation safety](https://docs.rs/tokio/latest/tokio/macro.select.html). |
| RPIT-020 | [Atomic ordering](https://doc.rust-lang.org/std/sync/atomic/enum.Ordering.html). |
| RPIT-035 | [Partial Write behavior](https://doc.rust-lang.org/std/io/trait.Write.html). |
| RPIT-039 | [Cargo feature unification](https://doc.rust-lang.org/cargo/reference/features.html). |
| RPIT-044 | [Miri scope and limitations](https://github.com/rust-lang/miri). |
| RPIT-046 | [GlobalAlloc safety](https://doc.rust-lang.org/std/alloc/trait.GlobalAlloc.html). |

<!-- EOF -->


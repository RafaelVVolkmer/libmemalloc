<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Lua performance and JIT

Use this guide to find expensive Lua operations, test an optimization and explain
its tradeoffs. It covers interpreted Lua and a separately qualified LuaJIT profile.
Apply the [performance controls](lua-code-standard.md#performance-controls) when
recording results and the [layout guide](lua-comments.md) when presenting code.

<details>
<summary><strong>On this page</strong></summary>

<details>
<summary>Resource lifecycle measurements</summary>

- [Retention and callback churn](#retention-and-callback-churn-experiments)

</details>

- [Runtime profiles](#runtime-profiles)
- [Measurement procedure](#measurement-procedure)
- [Sampling and trace diagnostics](#sampling-and-trace-diagnostics)
- [How traces affect optimization](#how-traces-affect-optimization)
- [Hot-loop design](#hot-loop-design)
- [Allocation, strings and collection](#allocation-strings-and-collection)
- [Data layout and FFI](#data-layout-and-ffi)
- [Optimization acceptance record](#optimization-acceptance-record)

</details>

---

## Runtime profiles

The repository selects Lua 5.5.1, with separate parser and analyzer settings in the
[effective profile](lua-code-standard.md#repository-profile). Run baseline code
with those tools. A JIT experiment needs its own runtime identity, compatibility
checks and execution results.

LuaJIT 2.1 implements the Lua 5.1 API and ABI with selected later extensions.
Compatibility flags affect some library results and metamethod behavior. Its
`goto` extension supports the normal output-label convention, but accepting that
syntax does not establish support for a whole Lua 5.4/5.5 program. Check integer
arithmetic, bit operations, library names and close semantics in each target.
See the [LuaJIT extension reference](https://luajit.org/extensions.html).

| Execution profile | Purpose | Required evidence |
| --- | --- | --- |
| Locked Lua interpreter | Repository compatibility and baseline cost. | Canonical checks and workload results. |
| LuaJIT with `-joff` | Cost in LuaJIT's interpreter. | Same input, output and library configuration. |
| LuaJIT with JIT enabled | Startup, compilation and sustained throughput. | Correctness, warm-up and trace evidence. |

Comparing LuaJIT with its own interpreter helps isolate compilation effects.
Comparing it with another Lua implementation also changes the VM, libraries and
possibly numeric behavior. Label those measurements separately.

Record the LuaJIT build commit, build flags, executable digest, native libraries,
OS and CPU. Also record `jit.version`, `jit.os`, `jit.arch` and the results of
`jit.status()`. An enabled compiler does not establish that a particular loop
compiled. Shared modules must not change global JIT settings while loading.
The application or experiment owner controls `jit.opt.start`, `jit.off` and
`jit.flush`, with scope and a reason in the experiment record. Flushing compiled
code inside timed work changes what the benchmark measures.
See the [JIT control API](https://luajit.org/ext_jit.html).

---

## Measurement procedure

1. Define the operation and its accepted outputs, failure behavior and resource
    limits. Select representative sizes, branch frequencies and invalid inputs.
2. Save a reference result before editing. Check ordering, status tuples and
    numeric tolerances as well as the main output.
3. Measure startup in fresh processes, including imports and initialization.
    Short CLI runs may finish before compilation pays for its cost.
4. For sustained workloads, warm up with representative inputs. Record the number
    of iterations and the observed stability of timings and traces; do not assume
    that one fixed warm-up count works for every program.
5. Measure repeated batches with the same input distribution and consume their
    results. Keep logging, fixture construction and verification outside the timed
    region unless they belong to the production operation.
6. Alternate reference and candidate runs across fresh processes. Save raw samples,
    completed work counts, collection policy and machine conditions.
7. Compare throughput, latency distribution, startup and retained memory. Investigate
    a faster mean that comes with worse tail latency or a larger memory footprint.

Use a monotonic elapsed-time source supplied by the qualified host for latency.
Document its resolution and units. Standard `os.clock()` measures CPU time; it
cannot substitute for elapsed request time when the operation waits for I/O.
Choose batches long enough to exceed timer noise. A percentile needs enough
samples to describe its tail; the largest observed value is not a proven bound.

Keep correctness assertions active around the experiment. A checksum makes output
observable but cannot by itself prove equivalence. Exercise empty inputs, boundary
sizes, skewed distributions and failure paths outside the timed region too.

---

## Sampling and trace diagnostics

First locate where execution time goes. The LuaJIT sampling profiler can attribute
samples to functions or lines and split them by VM state: interpreted code, compiled
code, native calls, GC or the compiler. Inlining can make source attribution less
obvious. Sampling has platform-dependent precision and needs enough observations.
Use the [profiler documentation](https://luajit.org/ext_profiler.html) to interpret
its options and output.

For an existing, trusted workload saved as `workload.lua`, these are separate
experiments. The workload must implement its own warm-up and output validation.
The commands illustrate a procedure; this repository does not supply that file.

> ```sh
> mkdir -p .cache/tests/luajit
> luajit -joff workload.lua
> luajit workload.lua
> luajit -jp=vf,.cache/tests/luajit/profile.txt workload.lua
> luajit -jv workload.lua 2> .cache/tests/luajit/traces.log
> luajit -jdump workload.lua > .cache/tests/luajit/dump.log 2>&1
> ```

Use `-jv` for compilation events and `-jdump` for compiler representations and
machine code. Consult the diagnostic modules shipped with the exact build for
format and options. Run timing trials without these diagnostics. Start with the
default optimizer settings; lowering `hotloop` or raising trace limits changes
compilation and memory costs and needs workload evidence.
See [LuaJIT command-line options](https://luajit.org/running.html).

| Observation | Investigation | Candidate change to measure |
| --- | --- | --- |
| GC consumes many samples | Temporary objects, retained references and pool size. | Reduce intermediate data or bound reuse. |
| A hot operation stays interpreted | Its trace events and actual runtime support. | Isolate the unsupported operation if semantics permit. |
| Repeated aborts at one location | Abort reason and the inputs reaching it. | Simplify that path or keep it outside the hot loop. |
| Many side traces or exits | Input type and branch distribution. | Normalize validated input or separate common cases. |
| Native calls dominate | Call frequency, copying and conversion cost. | Batch bounded work through the adapter. |
| The compiler dominates a short run | Startup and useful work per process. | Reduce startup work; reassess whether JIT helps. |

---

## How traces affect optimization

LuaJIT observes frequently executed paths and records operations for compilation.
A trace specializes those operations under assumptions checked by guards. A guard
failure leaves that path; a frequently taken exit may acquire a side trace. Such
exits are part of normal execution. A recording abort means the attempted trace
did not compile, so inspect its reason and whether the location matters to runtime.
The upstream [verbose trace module](https://github.com/LuaJIT/LuaJIT/blob/v2.1/src/jit/v.lua)
explains trace events and their diagnostic notation.

The optimizer can remove repeated calculations, move invariant work out of loops
and sink some allocations. Allocation sinking delays or removes materialization
of a temporary object on a compiled path; it does not mean that the source can
promise zero allocation on other paths. Inspect the generated representation when
an optimization depends on that behavior. Floating-point transformations may alter
results; preserve the declared tolerance and ordering requirements.
See the [optimizer options](https://luajit.org/running.html).

Treat stable operand types and predictable common paths as hypotheses to test.
A branch is not inherently slow, and a side trace is not inherently a defect.
Use profiles to connect compiler events to expensive application work. Recheck
after a runtime upgrade, since supported recording paths vary by build and target;
the [LuaJIT status page](https://luajit.org/status.html) describes implementation limits.

---

## Hot-loop design

Validate external records before repeatedly processing them when the ownership
contract prevents mutation between validation and use. Give a hot numeric operation
numbers in the documented range. Do not turn invalid text into zero merely to make
a loop easier to compile. If callers can mutate the data, retain the needed checks
or take an owned snapshot and account for its cost.

For a dense, immutable sequence of validated numbers, a contextual kernel is:

> ```lua
> local function batch_sum(values, value_count)
>    local ret = 0
>
>    for index = 1, value_count do
>       ret = ret + values[index]
>    end
>
>    ::function_output::
>    return ret
> end
> ```

Here `value_count` is an integer from zero through the validated sequence length;
the sum must stay within the caller's numeric contract. The numeric `for` expresses
the iteration domain. It does not establish a universal speed advantage over
`ipairs`. If the source table permits holes, define missing-value behavior before
choosing traversal. Do not replace ordered processing with `pairs`.

Move invariant parsing, pattern construction and configuration work outside repeated
processing when their inputs and effects remain unchanged. Preserve exceptions,
yield points and callback order when splitting loops. Use bounded batches to reduce
boundary overhead without creating unacceptable latency or retaining unbounded data.
Do not manually unroll loops or replace clear branches without measured benefit.

A local alias binds the current function value. It can change behavior if the
library entry changes later. LuaJIT can optimize many table lookups, so localizing
names alone is not a reliable speedup. Measure aliases under the actual runtime
and dependency replacement contract.
See the [LuaJIT lookup discussion](https://luajit.org/ext_ffi_tutorial.html#cache).

---

## Allocation, strings and collection

Start with the amount of work: repeated scanning or sorting can outweigh any
lookup optimization. For many string fragments, collect bounded pieces and join
them once with `table.concat`; repeated concatenation can repeatedly copy the
accumulated prefix. Include piece storage and the final string in peak-memory
measurements. Streaming bounded chunks may suit a consumer that accepts partial
output; document its failure behavior before switching from atomic output.

Reuse a scratch table only with an owner and a maximum retained size. Clear stale
entries and references before the next use, including entries beyond the new
logical length. Do not return a borrowed scratch table to a caller that expects an
independent result. Give concurrent or reentrant operations separate scratch state.
A pool can save allocations while retaining more memory than short-lived objects.

Move closure creation out of repeated work only when capture and lifetime remain
correct. A closure can keep an entire request graph reachable. A weak cache can
lose entries after collection; recomputation must remain correct and bounded.

Keep normal collection enabled in representative measurements. A test with GC
stopped measures a different memory and latency contract. Lua-managed heap counts
do not cover all native allocations or total process memory. Record both when a
native adapter matters. Apply runtime-specific GC tuning only through its owner
and remeasure startup, sustained load and tails after the change.

---

## Data layout and FFI

Choose table organization from access patterns. An array of records is convenient
for operations that consume whole records. Separate dense arrays can avoid touching
unused fields during a column-wise pass, but introduce synchronization and indexing
obligations. Benchmark construction, traversal and updates, including metadata and
retained memory. Ordinary Lua tables provide no portable contiguous-record,
alignment or cache-line guarantee.

Use FFI only in a named LuaJIT adapter with validated sizes, ownership and ABI
contracts. `cdata` is an FFI value with a declared native type. Reuse a named type
or a cached `ffi.typeof` constructor: repeatedly declaring an anonymous structure
can create distinct types and extra traces. Check element counts before allocating
or indexing arrays. Explicit close must coordinate with any finalizer to avoid
releasing the same allocation twice.
See the [FFI API](https://luajit.org/ext_ffi_api.html).

Keep a library namespace from `ffi.load` in a local binding and access its functions
through that namespace. Caching individual FFI functions can turn optimized direct
calls into indirect calls. This differs from ordinary Lua function aliasing.
See the [FFI tutorial](https://luajit.org/ext_ffi_tutorial.html#cache).

Retain backing allocations for as long as native pointers may use them. Validate
integer conversions; converting 64-bit integer cdata to a Lua number can lose
precision. Define length and encoding when copying bytes into Lua strings.

Callbacks require separate treatment. An FFI call from compiled code back into Lua
can produce a `bad callback` panic; qualify the surrounding call path and use a
scoped `jit.off` when that path requires it. Retain and release explicit callbacks
only after native users stop calling them. Prefer bounded pull or batch interfaces
when a native API permits them. Test callback errors and shutdown as well as normal
results. The [FFI semantics](https://luajit.org/ext_ffi_semantics.html) explain these
lifetime, conversion and callback constraints.

---

## Retention and callback churn experiments

Apply [LSTYLE-076](lua-code-standard.md#lstyle-076), [LSTYLE-077](lua-code-standard.md#lstyle-077)
and [LPERF-009](lua-code-standard.md#lperf-009) before accepting an FFI optimization. A faster submission
loop can still retain unbounded native requests, callback entries or backing arrays.

Run a bounded sequence of submit, complete, cancel and drain cycles. Record peak outstanding requests,
rooted Lua owners, callback registrations, native bytes and process memory alongside latency. Separate
steady-state retention from temporary construction. Continue through repeated shutdown/startup cycles if
that lifecycle is supported; a fresh process per iteration can hide retention in reusable workers.

| Experiment | Observation | Interpretation limit |
| --- | --- | --- |
| Delayed completion | Backing owners stay alive and outstanding work reaches a declared admission bound. | Does not validate an arbitrary foreign pointer. |
| Repeated callback registration | Active registrations return to baseline after unregister and drain. | Heap size alone does not count callback resources. |
| Collection between lifecycle stages | Results and owner lifetimes remain correct. | Forced collection distorts representative latency. |
| Rare callback after warm-up | Native-to-Lua path remains valid under the selected JIT policy. | A throughput run may never exercise that path. |

Keep collection stress in the correctness experiment and use the normal collector configuration in the
performance experiment. Compare both against the same workload contract. Lua heap counters cannot stand
in for the native provider's allocation counters. A leak-free short run establishes only its measured scope.

**Sources:** [LuaJIT cdata and callback semantics](https://luajit.org/ext_ffi_semantics.html),
[FFI allocation and finalizer API](https://luajit.org/ext_ffi_api.html).
No LuaJIT benchmark is claimed for the baseline PUC-Lua repository profile.

---

## Optimization acceptance record

Keep profiles, dumps, input descriptions and raw samples under
`.cache/tests/luajit/`. Commit the relevant source and a concise review record;
disposable cache contents do not replace retained release evidence.

| Record | What to include |
| --- | --- |
| Claim | Operation, workload, expected improvement and allowed regressions. |
| Identity | Source commit, runtime build, libraries, CPU, OS and runtime settings. |
| Method | Clock, batch sizes, warm-up, sample count, ordering and GC policy. |
| Correctness | Reference results, numeric tolerance and failure-path checks. |
| Findings | Raw-sample location, startup, throughput, tails and memory. |
| Explanation | Profile or trace evidence that connects the edit to its benefit. |
| Decision | Accepted change or rejection, owner and conditions for remeasurement. |

Reject an optimization that violates contracts or exceeds a resource limit.
Keep the readable implementation when differences remain within measurement noise.
Run baseline compatibility checks even when the intended improvement concerns JIT.
The commands and examples above describe experiments; they make no performance
claim about the existing repository scripts.

<!-- EOF -->


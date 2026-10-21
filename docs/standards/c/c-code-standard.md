<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# C Code Standard

Use this standard when writing or reviewing C code for reusable modules. It defines naming,
formatting, control flow, ownership, error handling, concurrency, and the evidence required for
performance changes.

Start with the language and target contract, then use the index to find a rule. Each control states
its requirement and provides examples or review guidance. The appendices collect restricted APIs and
complete implementation examples.

Read [C Module Architecture][c-module-architecture] for module boundaries and build composition. Use
[Common C Pitfalls][c-common-pitfalls] to connect a failure scenario with prevention controls,
verification designs, and sources.

Use [C Compliance and Assurance](c-compliance.md) for assessment and release claims.
Follow [C Formal Verification](test/c-tests-formal.md) for proof campaigns and their
assumptions, source mapping, and acceptance criteria.

<a id="rule-index"></a>

<details>
<summary><strong>On this page</strong></summary>

- [Scope, precedence, and review records][scope-precedence-and-review-records]
- [Language Model, Target Profiles, and Control-Flow
  Discipline][language-model-target-profiles-and-control-flow-discipline]
- [Implementation controls][implementation-controls]
- [Performance and microarchitecture: CPERF
  controls][performance-and-microarchitecture-cperf-controls]
- [Appendix A. Canonical CBAN register][appendix-a-canonical-cban-register]
- [Appendix B. Complete local-contract example][appendix-b-complete-local-contract-example]
- [Appendix C. Maintained reference and candidate][appendix-c-maintained-reference-and-candidate]
- [Appendix D. Examples for every CBAN entry][appendix-d-examples-for-every-cban-entry]
- [Links and references][links-and-references]

<details>
<summary>Naming and project structure</summary>

- [CSTYLE-001: Naming and Project Structure][cstyle-001]
- [CSTYLE-002: Variables][cstyle-002]
- [CSTYLE-003: Functions][cstyle-003]
- [CSTYLE-004: Types][cstyle-004]
- [CSTYLE-005: Struct and Enum Tags][cstyle-005]
- [CSTYLE-006: Enum Constants][cstyle-006]
- [CSTYLE-007: Enum Sequence Rules][cstyle-007]
- [CSTYLE-008: Labels][cstyle-008]
- [CSTYLE-009: Macros and Defines][cstyle-009]
- [CSTYLE-010: Macro Arguments][cstyle-010]
- [CSTYLE-011: File Names][cstyle-011]
- [CSTYLE-012: Directory Names][cstyle-012]
- [CSTYLE-013: Repository Name][cstyle-013]
- [CSTYLE-169: Function Lifecycle Verb Semantics][cstyle-169]

</details>

<details>
<summary>Formatting and source text</summary>

- [CSTYLE-014: Formatting and Local Code Style][cstyle-014]
- [CSTYLE-015: Line Length][cstyle-015]
- [CSTYLE-016: Long Line Breaking][cstyle-016]
- [CSTYLE-017: Continued-Line Indentation][cstyle-017]
- [CSTYLE-018: Long Strings][cstyle-018]
- [CSTYLE-019: Brace Style][cstyle-019]
- [CSTYLE-020: Spaces Around Operators][cstyle-020]
- [CSTYLE-021: Parentheses in Expressions][cstyle-021]
- [CSTYLE-022: Single-Line `if` and Loop Bodies][cstyle-022]
- [CSTYLE-279: Blank Lines and Logical Groups][cstyle-279]
- [CSTYLE-280: Function Calls, Result Checks, and Returns][cstyle-280]
- [CSTYLE-023: Pointer Position][cstyle-023]
- [CSTYLE-024: Const Correctness][cstyle-024]
- [CSTYLE-138: One Declarator per Declaration][cstyle-138]
- [CSTYLE-139: Assignments Are Standalone Statements][cstyle-139]
- [CSTYLE-140: Increment and Decrement Isolation][cstyle-140]
- [CSTYLE-170: Source Text, Unicode, and Bidirectional Controls][cstyle-170]

</details>

<details>
<summary>Headers and visibility</summary>

- [CSTYLE-025: Header Inclusion and Visibility][cstyle-025]
- [CSTYLE-026: Header Inclusion Policy][cstyle-026]
- [CSTYLE-027: Advantages of Include Guards][cstyle-027]
- [CSTYLE-028: Include Order][cstyle-028]
- [CSTYLE-029: External Dependency Wrappers][cstyle-029]
- [CSTYLE-030: Header Content and Interface Boundaries][cstyle-030]
- [CSTYLE-031: File Size][cstyle-031]
- [CSTYLE-032: Module Cohesion][cstyle-032]
- [CSTYLE-033: Header Content Rules][cstyle-033]
- [CSTYLE-034: Self-Contained Headers][cstyle-034]

</details>

<details>
<summary>Types, representation, and data layout</summary>

- [CSTYLE-035: Data Layout and ABI][cstyle-035]
- [CSTYLE-036: Explicit Integer Types][cstyle-036]
- [CSTYLE-037: Enum vs Macro Constants][cstyle-037]
- [CSTYLE-038: Struct Serialization][cstyle-038]
- [CSTYLE-039: Struct Layout Awareness][cstyle-039]
- [CSTYLE-040: Struct Comparison][cstyle-040]
- [CSTYLE-041: Public Struct ABI][cstyle-041]
- [CSTYLE-127: Bit-Field Usage][cstyle-127]
- [CSTYLE-128: Plain `char` Semantics][cstyle-128]
- [CSTYLE-129: Union Active-Member Discipline][cstyle-129]
- [CSTYLE-130: Flexible Array Members][cstyle-130]
- [CSTYLE-141: Pointer Typedefs][cstyle-141]
- [CSTYLE-142: Non-Zero Aggregate Initialization Uses Designators][cstyle-142]
- [CSTYLE-143: Translation-Time Invariants][cstyle-143]
- [CSTYLE-144: String Literal Immutability][cstyle-144]
- [CSTYLE-161: Anonymous Structs and Unions][cstyle-161]
- [CSTYLE-166: Convert Byte Order at the Boundary][cstyle-166]
- [CSTYLE-167: Decode Potentially Unaligned Storage Through Byte-Safe Helpers][cstyle-167]
- [CSTYLE-171: External Text Has an Encoding Contract][cstyle-171]

</details>

<details>
<summary>Macros and preprocessing</summary>

- [CSTYLE-042: Macro Definition Style][cstyle-042]
- [CSTYLE-043: Macro Literal and Structure Rules][cstyle-043]
- [CSTYLE-044: Multi-Statement Macros][cstyle-044]
- [CSTYLE-045: Preprocessor Restrictions][cstyle-045]
- [CSTYLE-046: Magic Numbers][cstyle-046]
- [CSTYLE-047: Token Pasting and Stringification][cstyle-047]
- [CSTYLE-048: No Side Effects in Macro Arguments][cstyle-048]
- [CSTYLE-049: Conditional Compilation][cstyle-049]
- [CSTYLE-050: Preprocessor Conditionals][cstyle-050]
- [CSTYLE-051: Macro Redefinition and `#undef`][cstyle-051]
- [CSTYLE-052: Compiler Extensions][cstyle-052]
- [CSTYLE-145: `_Generic` Policy][cstyle-145]
- [CSTYLE-162: Inline Assembly][cstyle-162]

</details>

<details>
<summary>Functions and control flow</summary>

- [CSTYLE-053: Function Design and Control Flow][cstyle-053]
- [CSTYLE-054: Function Size and Complexity][cstyle-054]
- [CSTYLE-055: Cyclomatic Complexity][cstyle-055]
- [CSTYLE-056: Cognitive Complexity][cstyle-056]
- [CSTYLE-057: Parameter Count][cstyle-057]
- [CSTYLE-058: Argument Validation][cstyle-058]
- [CSTYLE-059: Untrusted Input Validation][cstyle-059]
- [CSTYLE-060: Enum Range Validation][cstyle-060]
- [CSTYLE-061: No Side Effects in Conditions][cstyle-061]
- [CSTYLE-062: Const Parameters][cstyle-062]
- [CSTYLE-063: Output Buffer Contracts][cstyle-063]
- [CSTYLE-064: Return Convention][cstyle-064]
- [CSTYLE-065: Error Code Namespace][cstyle-065]
- [CSTYLE-066: Error Propagation][cstyle-066]
- [CSTYLE-067: Logging and Assertions][cstyle-067]
- [CSTYLE-068: Format String Safety][cstyle-068]
- [CSTYLE-069: Analyzability][cstyle-069]
- [CSTYLE-070: Module-Specific Return Types][cstyle-070]
- [CSTYLE-071: Callback Contracts][cstyle-071]
- [CSTYLE-072: Boolean Expression Simplification][cstyle-072]
- [CSTYLE-073: Boolean Naming Semantics][cstyle-073]
- [CSTYLE-074: Loop Control][cstyle-074]
- [CSTYLE-075: Switch Statements][cstyle-075]
- [CSTYLE-116: Function Argument Evaluation Order][cstyle-116]
- [CSTYLE-117: Output Parameter Initialization Contracts][cstyle-117]
- [CSTYLE-131: Array Parameter Notation][cstyle-131]
- [CSTYLE-132: Variadic Function Policy][cstyle-132]
- [CSTYLE-133: Conditional Operator][cstyle-133]
- [CSTYLE-134: Comma Operator][cstyle-134]
- [CSTYLE-135: `errno` Handling][cstyle-135]
- [CSTYLE-146: Action and Predicate Semantics][cstyle-146]
- [CSTYLE-147: Callback Validation Before Invocation][cstyle-147]
- [CSTYLE-148: Recursion Policy][cstyle-148]
- [CSTYLE-149: Nonlocal Control Flow][cstyle-149]
- [CSTYLE-150: Compiler Assumptions and Unreachable Paths][cstyle-150]
- [CSTYLE-151: Must-Check Fallible Results][cstyle-151]
- [CSTYLE-163: Partial and Interrupted I/O][cstyle-163]
- [CSTYLE-168: Durations and Deadlines Use a Monotonic Time Domain][cstyle-168]
- [CSTYLE-172: Descriptor and Handle Ownership Includes Inheritance][cstyle-172]
- [CSTYLE-173: Persistent Multi-Write Updates Need Crash Consistency][cstyle-173]

</details>

<details>
<summary>Memory and ownership</summary>

- [CSTYLE-076: Memory Management][cstyle-076]
- [CSTYLE-077: Allocation Rules][cstyle-077]
- [CSTYLE-078: Cast `void *` Return Values][cstyle-078]
- [CSTYLE-079: Allocation Size Safety][cstyle-079]
- [CSTYLE-080: `realloc` Safety][cstyle-080]
- [CSTYLE-081: No Hidden Allocations][cstyle-081]
- [CSTYLE-082: Ownership Rules][cstyle-082]
- [CSTYLE-083: Caller-Owned DTOs][cstyle-083]
- [CSTYLE-084: Local Memory Lifetime][cstyle-084]
- [CSTYLE-118: Allocator Family Rules][cstyle-118]
- [CSTYLE-119: Ownership Transfer Rules][cstyle-119]
- [CSTYLE-120: Resource Acquisition and Cleanup][cstyle-120]
- [CSTYLE-136: `sizeof` and Object-Size Rules][cstyle-136]
- [CSTYLE-152: Semantic Object Copy Rules][cstyle-152]
- [CSTYLE-153: Compound Literal Lifetime][cstyle-153]
- [CSTYLE-154: Trust-Aware Allocation Failure Policy][cstyle-154]
- [CSTYLE-164: Automatic Storage and Stack Budget][cstyle-164]

</details>

<details>
<summary>Library APIs and text</summary>

- [CSTYLE-085: Unsafe Language and Standard Library APIs][cstyle-085]
- [CSTYLE-086: Standard Library Policy][cstyle-086]
- [CSTYLE-087: String Handling][cstyle-087]
- [CSTYLE-165: Counted Text and Byte Views][cstyle-165]

</details>

<details>
<summary>Shared state and synchronization</summary>

- [CSTYLE-088: State Visibility][cstyle-088]
- [CSTYLE-089: Volatile Rules][cstyle-089]
- [CSTYLE-090: Thread Safety Documentation][cstyle-090]
- [CSTYLE-091: Thread Lifecycle and Cleanup][cstyle-091]
- [CSTYLE-092: Synchronization Rules][cstyle-092]
- [CSTYLE-093: Concurrency Hazard Map][cstyle-093]
- [CSTYLE-094: Atomic and Interrupt Shared State][cstyle-094]
- [CSTYLE-095: Signal Handler Safety][cstyle-095]

</details>

<details>
<summary>Conversions and pointer contracts</summary>

- [CSTYLE-096: Cast Rules][cstyle-096]
- [CSTYLE-155: Never Cast Away `const`][cstyle-155]
- [CSTYLE-097: Numeric Conversion Rules][cstyle-097]
- [CSTYLE-098: Pointer Aliasing and Provenance Rules][cstyle-098]
- [CSTYLE-121: Pointer Dereference Preconditions][cstyle-121]
- [CSTYLE-122: Pointer Dereference Chain Rules][cstyle-122]
- [CSTYLE-123: Pointer Validity Across Calls][cstyle-123]
- [CSTYLE-124: Alias-Safe Mutation][cstyle-124]
- [CSTYLE-125: Array Bounds and Pointer Arithmetic][cstyle-125]
- [CSTYLE-126: Pointer Member Ownership Semantics][cstyle-126]
- [CSTYLE-156: Typed Access to Raw Storage][cstyle-156]
- [CSTYLE-157: `offsetof` and Enclosing-Object Recovery][cstyle-157]
- [CSTYLE-158: Pointer Sequence Extent Contracts][cstyle-158]

</details>

<details>
<summary>Concurrent lifetime and scheduling</summary>

- [CSTYLE-174: Concurrent Object Lifetime Requires a Retention Protocol][cstyle-174]
- [CSTYLE-175: One-Time Initialization Includes Publication Ordering][cstyle-175]
- [CSTYLE-176: Thread Cancellation Must Preserve Ownership and Locks][cstyle-176]
- [CSTYLE-177: Fork After Threads Uses a Restricted Child Path][cstyle-177]
- [CSTYLE-178: Real-Time Locks Need a Blocking and Priority-Inversion Contract][cstyle-178]

</details>

<details>
<summary>Arithmetic and defined behavior</summary>

- [CSTYLE-099: Undefined Behavior Avoidance][cstyle-099]
- [CSTYLE-100: C Behavior Categories][cstyle-100]
- [CSTYLE-101: Integer Overflow and Shift Safety][cstyle-101]
- [CSTYLE-102: Checked Integer Arithmetic][cstyle-102]
- [CSTYLE-103: Division and Remainder Safety][cstyle-103]
- [CSTYLE-104: Bitwise and Mask Rules][cstyle-104]
- [CSTYLE-105: Hardware Register Read-Modify-Write Rules][cstyle-105]
- [CSTYLE-106: Floating Point][cstyle-106]
- [CSTYLE-159: Boolean Domain Rules][cstyle-159]
- [CSTYLE-160: Logical and Bitwise Operator Separation][cstyle-160]

</details>

<details>
<summary>Initialization</summary>

- [CSTYLE-107: Variable Initialization][cstyle-107]
- [CSTYLE-108: Array Initialization][cstyle-108]
- [CSTYLE-137: Object Zeroing and `memset`][cstyle-137]

</details>

<details>
<summary>External trust boundaries</summary>

- [CSTYLE-109: Downstream Interpreter Boundaries][cstyle-109]
- [CSTYLE-110: Authentication and Authorization Gates][cstyle-110]
- [CSTYLE-111: Untrusted Structured Input and File Ingress][cstyle-111]
- [CSTYLE-112: Outbound Request Destination Validation][cstyle-112]
- [CSTYLE-113: Resource Budgets and Throttling][cstyle-113]
- [CSTYLE-114: Security Exception and Fail-Closed Behavior][cstyle-114]
- [CSTYLE-115: Loader and Search-Path Safety][cstyle-115]

</details>

<details>
<summary>Documentation, portability, and generated source</summary>

- [CSTYLE-243: Comments Explain Contracts, Reasons, and Non-Obvious Constraints][cstyle-243]
- [CSTYLE-244: Commented-Out Production Code Is Prohibited][cstyle-244]
- [CSTYLE-245: Searchable Diagnostics Stay Textually Stable][cstyle-245]
- [CSTYLE-246: Source Files Do Not Configure the Developer's Editor][cstyle-246]
- [CSTYLE-247: Public Headers May Use a Stricter Language Baseline][cstyle-247]
- [CSTYLE-248: Implementation-Defined Dependencies Are Documented][cstyle-248]
- [CSTYLE-249: Linker and Assembly Symbols Have an Explicit Representation Contract][cstyle-249]
- [CSTYLE-250: Newer Language and Compiler Features Need a Portability Path][cstyle-250]
- [CSTYLE-251: Warning Suppression Does Not Repair Incorrect Code][cstyle-251]
- [CSTYLE-252: Generated Source Has Provenance and Is Not Hand-Patched][cstyle-252]

</details>

<details>
<summary>State, storage, and synchronization contracts</summary>

- [CSTYLE-253: Validate Rejectable Preconditions Before Committing State][cstyle-253]
- [CSTYLE-254: Library and Core Code Do Not Own Standard Streams][cstyle-254]
- [CSTYLE-255: Secure Erasure Uses a Non-Elidable Primitive][cstyle-255]
- [CSTYLE-256: Large Growable Objects Need a Fragmentation and Relocation Policy][cstyle-256]
- [CSTYLE-257: Scoped and Arena Allocations Do Not Escape Their Owner][cstyle-257]
- [CSTYLE-258: Text and Binary Buffers Have Different Contracts][cstyle-258]
- [CSTYLE-259: Lockless Shared Access Uses an Approved One-Time Access Primitive][cstyle-259]
- [CSTYLE-260: Raw Atomics Stay Behind a Synchronization Abstraction][cstyle-260]
- [CSTYLE-261: Memory Barriers Require a Pairing and Rationale Comment][cstyle-261]
- [CSTYLE-262: Use the Weakest Proven Memory Ordering Contract][cstyle-262]
- [CSTYLE-263: Lock-State Preconditions Are Visible in the API Contract][cstyle-263]

</details>

<details>
<summary>Hardware and fault resistance</summary>

- [CSTYLE-264: Floating-Point Exceptional-Value Policy][cstyle-264]
- [CSTYLE-265: Raw MMIO Access Is Confined to the MMIO Owner][cstyle-265]
- [CSTYLE-266: Fault-Resistant Encoded Security State][cstyle-266]
- [CSTYLE-267: Redundant Fault Checks Must Survive Compilation][cstyle-267]
- [CSTYLE-268: Critical Side-Effect Sequences Can Be Verified][cstyle-268]
- [CSTYLE-269: Secret Equality and Fault-Resistant Memory Operations Use Dedicated
  Primitives][cstyle-269]

</details>

<details>
<summary>Verification and maintenance</summary>

- [CSTYLE-270: Public APIs and Non-Obvious Internal Contracts Are Documented][cstyle-270]
- [CSTYLE-271: Requirements and Safety-Critical Controls Are Traceable to Verification][cstyle-271]
- [CSTYLE-272: Automated Checkers Are Enforcement Tools, Not the Definition of the Rule][cstyle-272]
- [CSTYLE-273: Supported Configuration Matrix Is Part of Correctness][cstyle-273]
- [CSTYLE-274: Supported Builds Are Warning-Clean Under the Project Warning Policy][cstyle-274]
- [CSTYLE-275: Imported Upstream Code Keeps a Deliberate Synchronization Strategy][cstyle-275]
- [CSTYLE-276: Specialized Verification Profiles May Use a Stricter C Subset][cstyle-276]
- [CSTYLE-277: Textual Documentation Is Checked Like Source][cstyle-277]
- [CSTYLE-278: Diagnostics State the Failed Contract and Useful Context][cstyle-278]

</details>

<details>
<summary>Measured implementation performance</summary>

- [CSTYLE-201: Performance Optimizations Require Target-Specific Evidence][cstyle-201]
- [CSTYLE-202: Cache-Line Ownership Is Explicit for Write-Hot Shared State][cstyle-202]
- [CSTYLE-203: One Cache Line of Padding May Not Defeat Adjacent-Line Prefetch][cstyle-203]
- [CSTYLE-204: Prefer CPU-Local Ownership Before Shared Atomic Mutation][cstyle-204]
- [CSTYLE-205: Batch Size Is a Measured Synchronization Parameter][cstyle-205]
- [CSTYLE-206: Avoid Needless Shared Writes][cstyle-206]
- [CSTYLE-207: Read-Mostly Data Structures Minimize Reader Writes][cstyle-207]
- [CSTYLE-208: Rare Runtime Features May Use Patchable or Static Branches Only Behind an
  Adapter][cstyle-208]
- [CSTYLE-209: Forced Inline Requires Evidence or a Machine-Level Constraint][cstyle-209]
- [CSTYLE-210: Hot Code Footprint Is a Resource][cstyle-210]
- [CSTYLE-211: Branch Versus Branchless Selection Is Measured][cstyle-211]
- [CSTYLE-212: Branch Probability Hints Need Profile Evidence][cstyle-212]
- [CSTYLE-213: Software Prefetch Has a Distance and Pollution Contract][cstyle-213]
- [CSTYLE-214: Pipeline Independent Work Around Long-Latency Misses][cstyle-214]
- [CSTYLE-215: Hot Wide Loads and Stores Avoid Split Boundaries][cstyle-215]
- [CSTYLE-216: Locked and Atomic Operands Must Not Form Split Locks][cstyle-216]
- [CSTYLE-217: Store-to-Load Forwarding Geometry Is Measured][cstyle-217]
- [CSTYLE-218: 4 KiB Alias Stalls Are a Target-Specific Diagnostic][cstyle-218]
- [CSTYLE-219: NUMA Placement Couples CPU, Memory, IRQ, and Device Locality][cstyle-219]
- [CSTYLE-220: TLB Invalidation Uses the Smallest Correct Scope][cstyle-220]
- [CSTYLE-221: Translation Locality Is Measured Separately From Data-Cache Locality][cstyle-221]
- [CSTYLE-222: Cache-Set Conflicts and Page Coloring Are Allocator-Level Optimizations][cstyle-222]
- [CSTYLE-223: Non-Temporal Stores Require Demonstrated Streaming Behavior][cstyle-223]
- [CSTYLE-224: Write-Combining Paths Prefer Complete Cache-Line Streams][cstyle-224]
- [CSTYLE-225: Data-Plane Library Calls Need a Hot-Path Policy][cstyle-225]
- [CSTYLE-226: Optimized Implementations Keep an Independent Portable Reference][cstyle-226]
- [CSTYLE-227: Specialized Implementations Are Differentially Tested][cstyle-227]
- [CSTYLE-228: Runtime ISA Dispatch Is Centralized][cstyle-228]
- [CSTYLE-229: Variable Vector-Length Backends Are Tested Across Supported Lengths][cstyle-229]
- [CSTYLE-230: Specialized Cached Code Requires Exact Invalidation][cstyle-230]
- [CSTYLE-231: Rare Complex Paths Need Not Inflate Generated Hot Code][cstyle-231]
- [CSTYLE-232: Indirect Dispatch Pressure Is Profile-Gated][cstyle-232]
- [CSTYLE-233: Deep Call Chains Are Reviewed When Return Prediction Is a Bottleneck][cstyle-233]
- [CSTYLE-234: Performance Baselines Record Speculation-Mitigation State][cstyle-234]
- [CSTYLE-235: Profile-Guided Layout Uses Representative Profiles][cstyle-235]
- [CSTYLE-236: Large Contiguous Collections May Use Segmented Storage in Hot Services][cstyle-236]
- [CSTYLE-237: Store-Buffer Pressure Is a Measured Throughput Limit][cstyle-237]
- [CSTYLE-238: Hardware Prefetchers Are Part of the Performance Experiment][cstyle-238]
- [CSTYLE-239: DMA and Device Streaming Layouts Prefer Complete Cache-Line Transactions][cstyle-239]
- [CSTYLE-240: Independent Hot Locks Avoid Coherence Coupling][cstyle-240]
- [CSTYLE-241: Code Alignment and Runtime Patch Geometry Are Profile-Gated][cstyle-241]
- [CSTYLE-242: Atomic Cost Includes Coherence Topology][cstyle-242]

</details>

<details>
<summary>Performance evidence and specialization</summary>

- [CPERF-001: Performance Changes Require Reproducible Evidence][cperf-001]
- [CPERF-002: Baselines Record the Effective Machine Policy][cperf-002]
- [CPERF-003: Profiles Must Represent the Deployment Workload][cperf-003]
- [CPERF-004: Performance Claims Preserve Correctness Evidence][cperf-004]
- [CPERF-005: Keep an Independent Portable Reference][cperf-005]
- [CPERF-006: Differential-Test Every Specialized Backend][cperf-006]
- [CPERF-007: Dispatch Is Explicit and Verifiable][cperf-007]
- [CPERF-008: Specialization Requires Exact Invalidation][cperf-008]
- [CPERF-009: Rare Complex Operations May Stay Out of Line][cperf-009]

</details>

<details>
<summary>Cache ownership and sharing</summary>

- [CPERF-010: Assign Ownership to Write-Hot Cache Lines][cperf-010]
- [CPERF-011: Prove and Isolate Harmful False Sharing][cperf-011]
- [CPERF-012: Contended Locks Have an Independent Layout Decision][cperf-012]
- [CPERF-013: Prefer Owner-Local State and Deferred Aggregation][cperf-013]
- [CPERF-014: Minimize Needless Shared Writes][cperf-014]
- [CPERF-015: Remote Writes to Owner-Local State Are Exceptional][cperf-015]
- [CPERF-044: Compact Flags Do Not Share a Coherence Unit Accidentally][cperf-044]
- [CPERF-045: Cross-Owner Freeing Is a Synchronization Path][cperf-045]

</details>

<details>
<summary>Memory access and locality</summary>

- [CPERF-016: Hot Dependent Accesses Respect Store-Forwarding Geometry][cperf-016]
- [CPERF-017: Investigate False 4 KiB Aliasing Only With Evidence][cperf-017]
- [CPERF-018: Avoid Store-Buffer Pressure From Unobservable Stores][cperf-018]
- [CPERF-019: Hot Wide Accesses Avoid Split Boundaries][cperf-019]
- [CPERF-020: Treat CPU, Memory, IRQ, and Device Locality as One Plan][cperf-020]
- [CPERF-021: Measure Translation Working Set Separately From Data Cache][cperf-021]
- [CPERF-022: Scope TLB Invalidation to the Smallest Correct Domain][cperf-022]
- [CPERF-023: Cache-Set Placement Is an Allocator-Level Experiment][cperf-023]
- [CPERF-043: Deterministic Hot Paths Define Page-Residency Policy][cperf-043]

</details>

<details>
<summary>Atomic operations and contention</summary>

- [CPERF-024: Amortize Global Atomic Operations][cperf-024]
- [CPERF-025: Hide Raw Atomics Behind Semantic Operations][cperf-025]
- [CPERF-026: Use Reader-Optimized Schemes Only for Matching Workloads][cperf-026]
- [CPERF-027: Lockless Accesses Constrain Compiler Transformation][cperf-027]
- [CPERF-046: Contention Needs an Explicit Wait and Wake Policy][cperf-046]

</details>

<details>
<summary>Code layout and dispatch</summary>

- [CPERF-028: Treat Hot-Code Footprint as a Resource][cperf-028]
- [CPERF-029: Forced Inlining Requires Evidence][cperf-029]
- [CPERF-030: Branchless Code Is Not Automatically Faster][cperf-030]
- [CPERF-031: Branch Hints Need Profile Validation][cperf-031]
- [CPERF-032: Patchable Static Branches Suit Stable Rare Features][cperf-032]
- [CPERF-033: Stable Indirect Targets May Bind Outside the Inner Loop][cperf-033]
- [CPERF-034: Code Placement and Alignment Are Profile-Gated][cperf-034]

</details>

<details>
<summary>Prefetch and streaming</summary>

- [CPERF-035: Software Prefetch Has a Distance Contract][cperf-035]
- [CPERF-036: DMA Layout Accounts for Cache-Line Transactions][cperf-036]
- [CPERF-037: Non-Temporal Stores Require Streaming Reuse Evidence][cperf-037]
- [CPERF-038: Complete Streaming Cache Lines When Practical][cperf-038]
- [CPERF-047: Hardware Prefetchers Are Part of the Experiment][cperf-047]

</details>

<details>
<summary>Performance review and regression gates</summary>

- [CPERF-039: Performance Review Record][cperf-039]
- [CPERF-040: CI Proves Backend Selection and Equivalence][cperf-040]
- [CPERF-041: Benchmark Regressions Use Stable Thresholds][cperf-041]
- [CPERF-042: Static Tools Report Evidence, Not Policy][cperf-042]

</details>

</details>

---

<a id="governance"></a>

## Scope, precedence, and review records

These three guides define project policy for reusable C modules. Supporting sources and their scope
appear in the research record in [Common C Pitfalls][c-common-pitfalls-research-record]. The policy
is not a replacement for the C implementation contract or for a product's hazard and threat
analyses.

The documents have distinct owners:

| Document                                       | Owns                                                                                                                                  | Does not own                                     |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| [C Code Standard][c-code-standard]             | Local C rules, API contracts, memory, concurrency, arithmetic, the CBAN register, and evidence-gated optimization                     | The module graph or product certification        |
| [C Module Architecture][c-module-architecture] | Module ownership, callback boundaries, approved lower-layer exceptions, adapters, builds, linking, exports, and lifecycle composition | A second copy of local C or vulnerability rules  |
| [Common C Pitfalls][c-common-pitfalls]         | Failure scenarios, review/test designs, control mapping, and external source/evidence records                                         | Additional hidden normative implementation rules |

Use the stable `CSTYLE-*`, `CMOD-*`, `CPIT-*`, `CPERF-*`, and `CBAN-*` identifiers in reviews and
verification records. Record the repository commit when an audit needs the exact wording of a rule.
Existing short and full-ID anchors preserve links when section titles change.

A **must** or an imperative instruction is a project requirement. **Should** is an expected default
that needs a recorded rationale when not followed. **May** is permission. Classification is
independent of obligation: a style violation and a use-after-free are not equivalent risks even when
both violate a must-rule.

| Class         | Scope                                                                     |
| ------------- | ------------------------------------------------------------------------- |
| CORRECTNESS   | Defined operations and satisfied functional contracts                     |
| SAFETY        | Predictable failure/timing/state behavior under a product hazard model    |
| SECURITY      | Protection of trust boundaries, secrets, authority, and executable inputs |
| ARCHITECTURE  | Ownership, permitted dependencies, interfaces, and lifecycle boundaries   |
| PORTABILITY   | Explicit dialect, representation, implementation, and ABI assumptions     |
| ANALYZABILITY | Checkable requirements and reproducible review/test evidence              |
| PROJECT_STYLE | Naming and presentation choices, not language guarantees                  |

When requirements conflict, first honor the selected language and platform semantics, then the
approved product safety/security constraints, then this set, then documented local style. Do not
silently resolve a conflict by choosing the more convenient document. Correct the rule or obtain an
approved deviation. No local rule can make undefined behavior defined.

A deviation record contains the rule and repository commit, affected paths/variants, reason,
alternatives considered, risk, compensating controls, tests/evidence, owner, independent approver
where required, and review/expiry condition. A linter suppression must reference that record.
Approval is scoped; it does not rewrite the global policy. Revisit it after changes to compiler,
ABI, dependencies, concurrency, or threat/hazard assumptions.

---

## Language Model, Target Profiles, and Control-Flow Discipline

This standard treats C as an imperative systems language with compile-time typing and weak checks.
Execution proceeds through statements that change state by assignment, function calls, selection,
iteration, and object-lifetime operations. Code must make state transitions, side effects, ownership
transfers, and failure paths visible to reviewers, compilers, static analyzers, and tests.

C assigns types during translation but permits implicit arithmetic conversions, explicit casts,
pointer arithmetic, manual storage management, and direct access to object representations. Its
execution model also distinguishes implementation-defined, unspecified, and undefined behavior. The
project therefore constrains pointers, conversions, macros, control flow, object lifetime, storage
duration, and standard-library use. Target-dependent assumptions must be explicit rather than
inferred from behavior observed on one machine.

The coding vocabulary draws on the structured C tradition described in the second edition of
[Kernighan and Ritchie's _The C Programming Language_][kernighan-ritchie-c], which covers ANSI C.
The current language baseline is [ISO/IEC 9899:2024 / C23][iso-iec-9899-c23]. [MISRA C][misra-c],
[SEI CERT C][sei-cert-c], and [ISO/IEC TS 17961][iso-iec-ts-17961] inform the project's safety and
security controls. These references serve different purposes: the language standard defines C
semantics, while this document establishes the implementation practices required by the project.

---

### Language and target contract

New qualified targets must use an explicitly selected **C23** dialect. A compatibility profile must
identify its language version, supported features, and restrictions; it must not silently downgrade
the language baseline or imply support for features that the toolchain does not implement. Builds
requiring unsupported features must be rejected.

Each target profile must record the compiler, C library or available runtime, linker, architecture,
compilation and linking flags, integer widths, byte size, alignment requirements, endianness, and
ABI options. These declarations define the environment in which the implementation is built and
evaluated.

The worked sources use a **C17-compatible subset** so the same implementation can also be compiled
and tested under a declared C17 compatibility profile. This compatibility applies to those sources
and the stated profile. It does not establish complete C23 support for the toolchain.

---

### Structured control flow

The project requires **Single Entry, Single Exit (SESE)** at function level. Functions must use one
entry point, a visible `ret` variable, one normal exit label named `function_output`, and one return
path. Resource cleanup and error propagation must converge on that exit. Hidden exits, early
returns, uncontrolled jumps, and ad hoc cleanup paths are prohibited.

This convention gives reviewers a consistent location to inspect resource release and the final
result of an operation. State changes and ownership transitions must remain explicit along every
path leading to `function_output`; a shared exit does not replace argument validation, lifetime
reasoning, or correct cleanup conditions.

The theoretical background includes [Böhm and Jacopini's structured-flow
work][bohm-jacopini-structured-programming], [Dijkstra's argument against unrestricted
`goto`][dijkstra-goto-harmful], the treatment of single-entry/single-exit regions in [Ferrante,
Ottenstein, and Warren's program-dependence-graph work][ferrante-pdg-sese], and subsequent
[program-structure-tree research][johnson-pst-sese]. The specific `ret` and `function_output`
convention is the project's implementation policy.

---

### Execution profiles

Each execution profile must define the facilities it provides and the restrictions that apply to
them. A **freestanding or RTOS profile** must identify its actual runtime facilities. A
**hard-real-time profile** must prohibit hidden allocation, unbounded waits, and recursion in
critical paths and require target-specific timing and stack evidence. A **security-boundary
profile** must include the applicable interpreter, authentication, and update controls. A
**host-test profile** may permit controlled fault injection and fatal test assertions; its negative
tests must exercise defined error paths rather than execute undefined behavior.

The worked example uses a hosted **Linux/ELF** profile with eight-bit bytes, ASCII decimal input,
and available `uint8_t` and `uint32_t` types. Heap allocation occurs through injected allocator
ports, and module instances require external synchronization.

In that example profile, debug builds deliberately abort when an internal invariant assertion fails.
Release builds remove those assertions while retaining runtime validation of external inputs and
handling of recoverable errors. Deliberate debug or test termination is a declared profile behavior,
not an alternative recoverable error path under the SESE convention.

The example implements no network service, authentication system, cryptography, ISR, DMA, garbage
collector, or concurrent reclamation algorithm. Rules governing those facilities remain part of the
standard, but the example does not provide implementation evidence for them.

---

### Verification scope and local rules

Compiler diagnostics, tests, static analysis, and sanitizers provide evidence within the scope of
the selected profile and the checks performed. Passing results do not establish MISRA compliance,
complete CERT coverage, ISO 26262 approval, absence of vulnerabilities, a real-time bound, or a
formal proof. Verification records must distinguish the behavior examined from requirements
that remain outside the example or test scope.

Follow this standard unless a module defines a stricter local rule. A local rule may strengthen the
requirements; it must not silently relax the language baseline, control-flow discipline, ownership
contracts, or execution-profile restrictions.

---

<a id="example-policy"></a>

### How to read the examples

Contextual examples illustrate one contract within a larger implementation. Apply the enclosing
function's declarations, validation, ownership, cleanup, and execution-profile requirements before
using a fragment. Layout and diagnostic blocks describe structure or expected output; they are not
executable C.

C fences display indentation with spaces at the repository's eight-column tab stops. The example
checker compares this display form with clang-format output before compiling the extracted files.

Examples marked **noncompliant** or **do not copy** demonstrate a failure. Keep them out of
executable tests when they invoke undefined behavior. The complete sources in the appendices provide
the surrounding implementation. Verification records must identify which sources and configurations
a check ran.

---

## Implementation controls

---

<a id="11-naming-and-project-structure"></a> <a id="cstyle-001-naming-and-project-structure"></a>
<a id="cstyle-001"></a>

<a id="cstyle-001-1-1-naming-and-project-structure"></a>

### CSTYLE-001: Naming and Project Structure

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use one naming vocabulary throughout public headers, implementations, tests, and generated project
interfaces. The rules in this section are project style, except where a rule also identifies an
implementation-reserved namespace. A naming convention does not establish symbol visibility or
ownership.

#### Local examples

**Layout example (not executable):**

```text
src/network/network_client.c
include/network/network_client.h
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
src/Thing/DoStuff.C
include/misc.h
```

---

<a id="111-variables"></a> <a id="cstyle-002-variables"></a> <a id="cstyle-002"></a>

<a id="cstyle-002-1-1-1-variables"></a>

### CSTYLE-002: Variables

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use `snake_case`. Use explicit unit suffixes when the variable stores a measurable quantity.

- `_ms`
- `_us`
- `_ns`
- `_bytes`
- `_count`
- `_idx`
- `_pct`

#### Local examples

**Contextual C example:**

```c
int    my_variable       = 0;
size_t user_count        = 0u;
size_t buffer_size_bytes = 0u;

uint32_t timeout_ms    = 0u;
size_t   payload_bytes = 0u;
```

---

<a id="112-functions"></a> <a id="cstyle-003-functions"></a> <a id="cstyle-003"></a>

<a id="cstyle-003-1-1-2-functions"></a>

### CSTYLE-003: Functions

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use `MODULE_lowerCamelCase` for public functions and `module_lowerCamelCase` for module-internal or
private functions. Private functions also require `static`; spelling does not determine linkage or
exports. Hosted `main` and externally prescribed entry points retain the name required by their
environment. In application `main.c`, every helper and state object is private; use `static` for
file-scope helpers and objects, while `main` retains its required non-static entry linkage.
Record other naming exceptions at the owning adapter.

#### Local examples

**Contextual C example:**

```c
static int        module_parseValue(int my_arg);
static inline int util_parseString(int my_arg);
int               NETWORK_sendPacket(int my_arg);
```

---

<a id="113-types"></a> <a id="cstyle-004-types"></a> <a id="cstyle-004"></a>

<a id="cstyle-004-1-1-3-types"></a>

### CSTYLE-004: Types

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use descriptive `snake_case` typedef names with the project or module prefix. The inherited `_t`
suffix is a project convention, not an ISO C requirement. A strict platform namespace profile may
replace that suffix consistently before publishing a new API. Do not rename an existing ABI without
migration review. Do not hide an owning pointer behind a typedef that conceals its pointer nature;
opaque object types and explicit callback typedefs are allowed.

#### Local examples

**Contextual C example:**

```c
typedef enum MemoryStateMachine
{
        MEM_STATE_STOP  = 0u,
        MEM_STATE_START = 1u,
        MEM_STATE_IDLE  = 2u,
        MEM_STATE_MAX   = 3u
} mem_state_t;

typedef struct IntWrapper
{
        int value;
} int_wrapper_t;

typedef void (*callback_fn_t)(int_wrapper_t *item);
```

---

<a id="114-struct-and-enum-tags"></a> <a id="cstyle-005-struct-and-enum-tags"></a>
<a id="cstyle-005"></a>

<a id="cstyle-005-1-1-4-struct-and-enum-tags"></a>

### CSTYLE-005: Struct and Enum Tags

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use `UpperCamelCase` for struct and enum tags.

#### Local examples

**Contextual C example:**

```c
typedef struct IntWrapper
{
        int value;
} int_wrapper_t;

typedef enum UserStatus
{
        USER_ACTIVE   = 0u,
        USER_INACTIVE = 1u,
        USER_MAX      = 2u
} user_status_t;
```

---

<a id="115-enum-constants"></a> <a id="cstyle-006-enum-constants"></a> <a id="cstyle-006"></a>

<a id="cstyle-006-1-1-5-enum-constants"></a>

### CSTYLE-006: Enum Constants

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use `SCREAMING_CASE` with a module prefix.

#### Local examples

**Contextual C example:**

```c
typedef enum MemoryStateMachine
{
        MEM_STATE_STOP  = 0u,
        MEM_STATE_START = 1u,
        MEM_STATE_IDLE  = 2u,
        MEM_STATE_MAX   = 3u
} mem_state_t;
```

---

<a id="116-enum-sequence-rules"></a> <a id="cstyle-007-enum-sequence-rules"></a>
<a id="cstyle-007"></a>

<a id="cstyle-007-1-1-6-enum-sequence-rules"></a>

### CSTYLE-007: Enum Sequence Rules

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use explicit values for protocol enums. A sequential enum that is used as an array index may end in
`*_MAX` as a count, provided the sequence starts at zero and has no gaps. The sentinel is not a
valid runtime value. Sparse enums and bitmasks need membership or allowed-bit validation instead of
a count check. An unsigned literal suffix does not by itself fix an enum's underlying type or binary
layout. Use a specified representation at a wire or stable ABI boundary.

#### Local examples

**Contextual C example:**

```c
typedef enum MemoryStateMachine
{
        MEM_STATE_STOP  = 0u,
        MEM_STATE_START = 1u,
        MEM_STATE_IDLE  = 2u,
        MEM_STATE_SLEEP = 3u,

        /* element count */
        MEM_STATE_MAX = 4u
} mem_state_t;
```

---

<a id="117-labels"></a> <a id="cstyle-008-labels"></a> <a id="cstyle-008"></a>

<a id="cstyle-008-1-1-7-labels"></a>

### CSTYLE-008: Labels

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use `snake_case`.

#### Local examples

**Contextual C example:**

```c
goto function_output;

function_output : return ret;
```

---

<a id="118-macros-and-defines"></a> <a id="cstyle-009-macros-and-defines"></a>
<a id="cstyle-009"></a>

<a id="cstyle-009-1-1-8-macros-and-defines"></a>

### CSTYLE-009: Macros and Defines

**Class:** PORTABILITY / PROJECT_STYLE. **Obligation:** project requirement.

Use `SCREAMING_CASE` for macros. Do not define identifiers reserved to the C implementation,
including leading double underscores and an underscore followed by an uppercase letter. Avoid
leading underscores in all project names. Compiler-provided tokens may appear in compiler adapters.
A trailing `__` is the inherited marker for project portability macros; it does not make such a
macro portable or suitable for a strict C++ namespace profile.

#### Local examples

**Contextual C example:**

```c
#define MAX_LEN         ((size_t)(10U))
#define BUFFER_ALIGN    ((size_t)(8U))
#define VERSION_CHECK__ ((uint32_t)(100U))
```

---

<a id="119-macro-arguments"></a> <a id="cstyle-010-macro-arguments"></a> <a id="cstyle-010"></a>

<a id="cstyle-010-1-1-9-macro-arguments"></a>

### CSTYLE-010: Macro Arguments

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use `snake_case` and end with `_`.

#### Local examples

**Contextual C example:**

```c
#define STRINGIFY_TOKEN(token_) #token_
```

---

<a id="1110-file-names"></a> <a id="cstyle-011-file-names"></a> <a id="cstyle-011"></a>

<a id="cstyle-011-1-1-10-file-names"></a>

### CSTYLE-011: File Names

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use `snake_case` for `.c` and `.h` file names.

- consistent with variable naming in C
- common in Unix-style projects
- easy to read
- avoids confusion on case-sensitive file systems

#### Local examples

**Layout example (not executable):**

```text
memory_manager.c
memory_manager.h
network_socket.c
network_socket.h
packet_parser.c
```

---

<a id="1111-directory-names"></a> <a id="cstyle-012-directory-names"></a> <a id="cstyle-012"></a>

<a id="cstyle-012-1-1-11-directory-names"></a>

### CSTYLE-012: Directory Names

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Prefer `snake_case` for directory names. This keeps module structure consistent with file naming and
makes paths more predictable.

Short directory names such as `src`, `net`, `mem`, or `util` are also acceptable when they are
already well understood in the project context.

#### Local examples

**Layout example (not executable):**

```text
.
├── src/
├── include/
├── memory_manager/
├── network_layer/
└── file_system/
```

---

<a id="1112-repository-name"></a> <a id="cstyle-013-repository-name"></a> <a id="cstyle-013"></a>

<a id="cstyle-013-1-1-12-repository-name"></a>

### CSTYLE-013: Repository Name

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

For repository names, prefer one of these patterns:

- `snake_case`
- `kebab-case`
- a single lowercase word

For this project family, prefer `snake_case` unless an external hosting or distribution convention
requires a different style.

#### Local examples

**Layout example (not executable):**

```text
packet_router
memory_manager
network_stack
packet-router
memory-manager
network-stack
sqlite
redis
systemd
```

---

<a id="1113-function-lifecycle-verb-semantics"></a> <a id="cstyle-169"></a>

<a id="cstyle-169-1-1-13-function-lifecycle-verb-semantics"></a>

### CSTYLE-169: Function Lifecycle Verb Semantics

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-160: Lifecycle verb hides the real object transition][c-common-pitfalls-cpit-160]

Lifecycle verbs carry project-wide meaning. A public API must use the verb that matches the resource
transition performed by the function.

- `create` acquires or creates an object lifetime and returns ownership through the documented
  output contract.
- `init` initializes caller-owned storage whose lifetime already exists.
- `bind` or `register` establishes a dependency, callback, or association.
- `start` begins operation without creating a new object lifetime.
- `stop` ends operation while keeping the object valid.
- `reset` returns an existing object to a documented state without silently replacing its identity.
- `deinit` reverses `init` for caller-owned storage.
- `destroy` ends object lifetime and releases resources owned by that object.
- `get` reads a value or transfers a documented retained reference.
- `set` changes one named property or a narrow documented property group.

Use `configure`, `commit`, `submit`, `load`, or another specific verb when an operation does more
than a setter. This rule extends the action and predicate semantics in `CSTYLE-146`.

#### Local examples

**Contextual C example:**

```c
int DEVICE_create(device_t **device);
int DEVICE_init(device_t *device, const device_config_t *config);
int DEVICE_bind(device_t *device, const device_port_t *port);
int DEVICE_start(device_t *device);
int DEVICE_stop(device_t *device);
int DEVICE_reset(device_t *device);
int DEVICE_deinit(device_t *device);

void DEVICE_destroy(device_t **device);
int  DEVICE_getState(const device_t *device, device_state_t *state);
int  DEVICE_setMode(device_t *device, device_mode_t mode);
```

**Noncompliant fragment (do not copy):**

```c
int DEVICE_init(device_t **device);       /* allocates a new object */
int DEVICE_stop(device_t **device);       /* frees the object */
int DEVICE_setState(device_t *device);    /* performs a full reconfiguration */
```

---

<a id="12-formatting-and-local-code-style"></a>
<a id="cstyle-014-formatting-and-local-code-style"></a> <a id="cstyle-014"></a>

<a id="cstyle-014-1-2-formatting-and-local-code-style"></a>

### CSTYLE-014: Formatting and Local Code Style

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Apply the source-format rules in this section consistently. Automate formatting where possible
without changing semantics.

#### Local examples

**Contextual C example:**

```c
if (is_ready)
        value = next_value;
```

**Noncompliant fragment (do not copy):**

```c
if(is_ready){value=next_value;}
```

---

<a id="121-line-length"></a> <a id="cstyle-015-line-length"></a> <a id="cstyle-015"></a>

<a id="cstyle-015-1-2-1-line-length"></a>

### CSTYLE-015: Line Length

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Keep maintained C source and header lines within 80 columns. Do not shorten identifiers or hide
checks merely to meet this limit. Generated code, reference URLs, Markdown tables, tool output, and
verbatim external declarations are not subject to this source-format rule. Record a local exception
when a source line cannot be split without changing meaning.

#### Local examples

**Contextual C example:**

```c
ret = NETWORK_sendPacket(packet, packet_size_bytes, timeout_ms);
```

**Noncompliant fragment (do not copy):**

```c
ret = NETWORK_sendPacket(packet, packet_size_bytes, timeout_ms, retry_count, diagnostics, context, allocator);
```

---

<a id="122-long-line-breaking"></a> <a id="cstyle-016-long-line-breaking"></a>
<a id="cstyle-016"></a>

<a id="cstyle-016-1-2-2-long-line-breaking"></a>

### CSTYLE-016: Long Line Breaking

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Break long lines at logical boundaries:

- function parameters
- function calls
- long expressions
- struct initializers
- array initializers

#### Local examples

**Contextual C example:**

```c
int ret = EXIT_SUCCESS;

ret = EX_performComplexCalculation(input_value_a, input_value_b, input_value_c,
                                   config_ptr);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="123-continued-line-indentation"></a> <a id="cstyle-017-continued-line-indentation"></a>
<a id="cstyle-017"></a>

<a id="cstyle-017-1-2-3-continued-line-indentation"></a>

### CSTYLE-017: Continued-Line Indentation

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Indent continuation lines consistently.

- alignment with the opening expression, or
- one additional indentation level

#### Local examples

**Contextual C example:**

```c
bool is_ready = false;

is_ready = has_input && has_capacity && is_initialized;
```

---

<a id="124-long-strings"></a> <a id="cstyle-018-long-strings"></a> <a id="cstyle-018"></a>

<a id="cstyle-018-1-2-4-long-strings"></a>

### CSTYLE-018: Long Strings

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Split long string literals with explicit concatenation.

#### Local examples

**Contextual C example:**

```c
const char *msg = "This is a very long error message "
                  "that needs to be split across multiple lines.";
```

**Contextual C example:**

```c
LOG_error("firmware image signature verification failed");
```

---

<a id="125-brace-style"></a> <a id="cstyle-019-brace-style"></a> <a id="cstyle-019"></a>

<a id="cstyle-019-1-2-5-brace-style"></a>

### CSTYLE-019: Brace Style

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use Allman braces for C functions and compound statement bodies required by CSTYLE-022.
A compound literal may place its opening
brace after a line break. Preprocessor definitions and initializer lists are formatted according to
their own syntax. This is a formatting choice; it is not a claim of stronger memory safety.

#### Local examples

**Contextual C example:**

```c
int EX_example(void)
{
        int ret = EXIT_SUCCESS;

        if (condition)
        {
                EX_doSomething();
                EX_doSomething();
        }
        else
        {
                EX_doSomethingElse();
                EX_doSomethingElse();
        }

function_output:
        return ret;
}
```

**Noncompliant fragment (do not copy):**

```c
int EX_example(void) {
    int ret = EXIT_SUCCESS;

    if (condition) {
        EX_doSomething();
        EX_doSomething();
    } else {
        EX_doSomethingElse();
        EX_doSomethingElse();
    }

function_output:
    return ret;
}
```

---

<a id="126-spaces-around-operators"></a> <a id="cstyle-020-spaces-around-operators"></a>
<a id="cstyle-020"></a>

<a id="cstyle-020-1-2-6-spaces-around-operators"></a>

### CSTYLE-020: Spaces Around Operators

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Put spaces around binary and assignment operators and after commas. Keep unary operators with their
operands and member access without surrounding spaces. Format pointer declarators consistently.
These spacing rules do not change operator precedence, evaluation order, or the declaration's type.

#### Local examples

**Contextual C example:**

```c
#define EX_DEFAULT_VALUE ((int)(10U))

bool is_equal = false;
bool is_ready = false;

is_equal = (value_a == value_b);
is_ready = is_enabled && has_input;

if (value == EX_DEFAULT_VALUE)
        EX_doSomething();
```

**Noncompliant fragment (do not copy):**

```c
#define EX_DEFAULT_VALUE  ((int)(10U))

int sum=a+b;
int product=x*y;

if(value==EX_DEFAULT_VALUE)
    EX_doSomething();
```

---

<a id="127-parentheses-in-expressions"></a> <a id="cstyle-021-parentheses-in-expressions"></a>
<a id="cstyle-021"></a>

<a id="cstyle-021-1-2-7-parentheses-in-expressions"></a>

### CSTYLE-021: Parentheses in Expressions

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Parenthesize mixed logical or arithmetic expressions where it clarifies precedence. Do not add casts
or parentheses that conceal an overflow, evaluation order, or type-conversion issue. Simple
assignments, comparisons, and a single arithmetic operation do not need redundant outer parentheses.

#### Local examples

**Contextual C example:**

```c
#define EX_VALUE_A ((uint32_t)(1U))
#define EX_VALUE_B ((uint32_t)(2U))
#define EX_VALUE_C ((uint32_t)(3U))
#define EX_VALUE_D ((uint32_t)(1U))

uint32_t total = 0u;

total = ((EX_VALUE_A + EX_VALUE_B) * (EX_VALUE_C - EX_VALUE_D));

if ((value_x > value_y) && (value_y != 0))
        EX_doSomething();
```

**Noncompliant fragment (do not copy):**

```c
int total = value_a + value_b * value_c - value_d;

if (value_x > value_y && value_y != 0)
    EX_doSomething();
```

---

<a id="128-single-line-if-and-loop-bodies"></a>
<a id="cstyle-022-single-line-if-and-loop-bodies"></a> <a id="cstyle-022"></a>

<a id="cstyle-022-1-2-8-single-line-if-and-loop-bodies"></a>

### CSTYLE-022: Single-Line `if` and Loop Bodies

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

An `if` body containing one simple statement on one physical line must omit braces. Put that
statement on the next line, indented eight columns. Never put it on the condition's line.
Apply the same rule to a simple `else` body. An `else if` chain is allowed.

Use braces when a branch has multiple statements, a wrapped statement, a declaration, or nested
control flow. Keep braces around nested conditionals to prevent a dangling `else`. Comments that
describe a simple body belong above its condition; a comment does not justify misleading indentation.
Every `for`, `while`, and `do` body keeps braces, even for one statement. Do not remove braces that
establish a required scope or lifetime. Macros and conditional compilation require separate review.

This is an approved libmemalloc adaptation of the imported Coil rule. Clang formatting preserves
braces; clang-tidy and policy fixtures check required braces. Review checks unnecessary braces in
simple branches and logical grouping; a formatter cannot decide whether operations are related.

#### Local examples

**Contextual C example:**

```c
size_t index = 0u;

if (flag)
        EX_doSomething();

for (index = 0u; index < count; index++)
{
        flags[index] = false;
}

if (flag)
{
        EX_doFirst();
        EX_doSecond();
}
```

**Noncompliant fragment (do not copy):**

```c
#define EX_ERROR_VALUE  (-EINVAL)

size_t index = 0u;

if (flag) return EX_ERROR_VALUE;

for (index = 0u; index < count; index++) sum += array[index];

if (flag)
    EX_doFirst();
    EX_doSecond();
```

---

<a id="cstyle-279"></a>

### CSTYLE-279: Blank Lines and Logical Groups

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Use exactly one empty line at each logical boundary. Do not use consecutive empty lines or
whitespace-only lines. Keep related operations together rather than separating every statement.

- Separate consecutive function definitions with one empty line. A function's documentation belongs
  to that function, with the separator before its documentation.
- Keep the declarations at the start of their permitted scope, with the result variable first.
  Separate the declaration group from the first executable statement with one empty line.
  Do not insert an empty line directly after an opening brace or before a closing brace.
- Separate an `if`, `for`, `while`, `do`, or `switch` group from unrelated surrounding work with one
  empty line. Do not separate a condition from its body, `else` from its preceding branch, or the
  closing `while` from a `do` body. Nested blocks follow the same rule within their own scope.
- Group assignments and operations that establish one state or invariant. Insert one empty line
  before work on an unrelated state, resource, or computation. Source order remains part of the
  program's contract; whitespace is not permission to reorder side effects.
- Separate the final cleanup/return group from preceding work with one empty line. Keep
  `function_output:` adjacent to its first cleanup statement or `return ret;`. Do not put an empty
  line between a function's final return and its closing brace.

Clang formatting enforces function separation and limits retained empty lines. Review must verify
declaration boundaries and semantic groups. See CSTYLE-280 for the call/check exception.

#### Local examples

**Contextual C example:**

```c
int    ret   = 0;
size_t index = 0u;

request.count = count;
request.flags = flags;

statistics.last_count = count;

for (index = 0u; index < count; index++)
{
        items[index].ready = false;
}

function_output : return ret;
```

---

<a id="cstyle-280"></a>

### CSTYLE-280: Function Calls, Result Checks, and Returns

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

When a function result requires validation, store it and start its test on the very next physical
line after the complete call. Do not insert an empty line, a comment, another call, or unrelated
work between the call and its test. For a wrapped call, the test follows the line that closes the
call. Do not embed the assignment in the condition or delay validation until after using an output.

Treat the call, its test, and its failure handling as one unit. Separate successive call/check units
with exactly one empty line. Separate the completed unit from unrelated successful-path work with
one empty line. Keep multiple assignments inside one failure handler together when they implement
the same recovery action. A one-line `goto` body omits braces under CSTYLE-022.

Use the result convention required by the API: negative error, null pointer, boolean, or documented
status. This rule does not invent a failure result for a `void` function. It does not permit extra
early returns: preserve the single normal return through `function_output` required by CSTYLE-064.
Separate the final return group as required by CSTYLE-279. Mandatory checks remain governed by
CSTYLE-066 and CSTYLE-151; call/check adjacency and semantic grouping require review.

#### Local examples

**Contextual C example:**

```c
int ret = 0;

ret = EX_prepareRequest(&request);
if (ret < 0)
        goto function_output;

ret = EX_submitRequest(&request);
if (ret < 0)
        goto function_output;

statistics.completed++;

function_output : return ret;
```

**Noncompliant fragment (do not copy):**

```c
ret = EX_prepareRequest(&request);

statistics.completed++;
if (ret < 0) goto function_output;
ret = EX_submitRequest(&request);
if (ret < 0)
{
        goto function_output;
}
```

---

<a id="129-pointer-position"></a> <a id="cstyle-023-pointer-position"></a> <a id="cstyle-023"></a>

<a id="cstyle-023-1-2-9-pointer-position"></a>

### CSTYLE-023: Pointer Position

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Keep `*` attached to the variable name.

#### Local examples

**Contextual C example:**

```c
int  data = 0;
int *ptr1 = (int *)(NULL);
int *ptr2 = (int *)(NULL);

char      *buffer = (char *)(NULL);
int *const ptr    = &data;
```

**Noncompliant fragment (do not copy):**

```c
int* ptr1, ptr2;
int * ptr1, * ptr2;
int* const ptr = NULL;
```

---

<a id="1210-const-correctness"></a> <a id="cstyle-024-const-correctness"></a>
<a id="cstyle-024"></a>

<a id="cstyle-024-1-2-10-const-correctness"></a>

### CSTYLE-024: Const Correctness

**Class:** CORRECTNESS. **Obligation:** project requirement.

Use pointed-data `const` for read-only inputs and preserve qualifiers through adapters. A const
pointer does not freeze its pointee, and a pointer to const does not prevent another valid alias
from modifying the object. Do not cast away constness to write an object defined as const.

Apply CSTYLE-107 to automatic declarations. Use named constants or immutable file-scope tables for
nonzero constant data rather than introducing a late local declaration or attempting to assign to a
const object after validation.

#### Local examples

**Contextual example:**

File-scope immutable definitions, not automatic declarations. They demonstrate pointed-to const and
pointer const without violating the zero-like automatic-initialization rule. Mutable automatic
pointers still start as typed NULL.

```c
#define EX_READ_ONLY_VALUE ((int)(20U))

static const int        read_only_value = EX_READ_ONLY_VALUE;
static const int *const fixed_ptr       = &read_only_value;
```

---

<a id="1211-one-declarator-per-declaration"></a> <a id="cstyle-138"></a>

<a id="cstyle-138-1-2-11-one-declarator-per-declaration"></a>

### CSTYLE-138: One Declarator per Declaration

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

Declare exactly one object or function per declaration. A declaration must not mix pointer and
non-pointer declarators or hide distinct initialization state in one statement.

This rule applies to local objects, file-scope objects, parameters declared in old-style
definitions, and declarations in a `for` initializer.

#### Local examples

**Noncompliant fragment (do not copy):**

```c
int *buffer = (int *)(NULL), count = 0;
```

**Contextual C example:**

```c
int *buffer = (int *)(NULL);
int  count  = 0;
```

---

<a id="1212-assignments-are-standalone-statements"></a> <a id="cstyle-139"></a>

<a id="cstyle-139-1-2-12-standalone-assignments"></a>

### CSTYLE-139: Assignments Are Standalone Statements

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

An assignment must be the primary operation of its statement. Do not place an assignment inside a
function argument, subscript, condition, return expression, initializer expression, or another
assignment.

**Related pitfalls:**

- [CPIT-130: Control flow hidden in an expression][c-common-pitfalls-cpit-130]

Do not chain assignments. Repeat the state transition as separate statements when several objects
intentionally receive the same value.

#### Local examples

**Noncompliant fragment (do not copy):**

```c
ret = EX_process(value = EX_readValue());
```

**Contextual C example:**

```c
value = EX_readValue();
ret   = EX_process(value);
```

---

<a id="1213-increment-and-decrement-isolation"></a> <a id="cstyle-140"></a>

<a id="cstyle-140-1-2-13-increment-decrement-isolation"></a>

### CSTYLE-140: Increment and Decrement Isolation

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

An increment or decrement operator must be the primary operation of a standalone statement or the
update expression of a simple `for` loop. It must not participate in a larger expression.

The `for` update expression may contain one increment or decrement operation. A loop that advances
several objects must use explicit statements in the loop body.

#### Local examples

**Noncompliant fragment (do not copy):**

```c
value = items[index++];
```

**Contextual C example:**

```c
value = items[index];
index++;
```

---

<a id="1214-source-text-unicode-and-bidirectional-controls"></a> <a id="cstyle-170"></a>

<a id="cstyle-170-1-2-14-source-text-unicode-bidi-controls"></a>

### CSTYLE-170: Source Text, Unicode, and Bidirectional Controls

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-162: Bidirectional or confusable source text changes review
  meaning][c-common-pitfalls-cpit-162]

Project identifiers, labels, macro names, file names, and directory names use ASCII unless a
documented external interface requires another form. Comments and string literals may contain UTF-8
text when their consumer expects UTF-8.

Raw Unicode bidirectional formatting controls are prohibited in source text. Tests that need those
code points must encode them with byte escapes or a project Unicode helper. CI should enable the
strongest available compiler or text-linter diagnostic for bidirectional controls, such as GCC
`-Wbidi-chars=any,ucn`.[gcc-bidi-chars][gcc-bidi-chars] Unicode documents the spoofing risk of
bidirectional text.[unicode-security][unicode-security]

#### Local examples

**Contextual C example:**

```c
const char *message   = "Operation complete: \u2713";
const char *bidi_test = "\xe2\x80\xae";
```

**Noncompliant fragment (do not copy):**

```c
int \u03B1 = 0;
/* A raw bidirectional formatting character appears in this source line. */
```

---

<a id="21-header-inclusion-and-visibility"></a>
<a id="cstyle-025-header-inclusion-and-visibility"></a> <a id="cstyle-025"></a>

<a id="cstyle-025-2-1-header-inclusion-and-visibility"></a>

### CSTYLE-025: Header Inclusion and Visibility

**Class:** CORRECTNESS. **Obligation:** project requirement.

Keep interfaces self-contained and owned. Use the following header and representation controls
together with the module architecture.

#### Local examples

**Contextual C example:**

```c
#include <stddef.h>
#include <stdint.h>

#include "module.h"
```

**Noncompliant fragment (do not copy):**

```c
#include "../peer/src/private.h"
#include "everything.h"
```

---

<a id="211-header-inclusion-policy"></a> <a id="cstyle-026-header-inclusion-policy"></a>
<a id="cstyle-026"></a>

<a id="cstyle-026-2-1-1-header-inclusion-policy"></a>

### CSTYLE-026: Header Inclusion Policy

**Class:** CORRECTNESS. **Obligation:** project requirement.

Use unique, project-prefixed include guards in public and internal headers. Use `#if !defined(NAME)`
followed by `#define NAME` and a closing `#endif`. Headers must supply the declarations of the types
they expose without depending on an earlier include. Nonstandard `#pragma once` is not the portable
baseline. Every project C header intended for C++ inclusion also owns the conditional C-linkage
block in [CMOD-019](c-module-architecture.md#cmod-019), inside its include guard. Keep any permitted
dependency includes outside the linkage block.

#### Local examples

**Contextual C example:**

```c
#if !defined(APP_CONFIG_H)
  #define APP_CONFIG_H

  #include <stdint.h>

typedef struct AppConfig
{
        uint32_t id;
} app_config_t;

#endif
```

---

<a id="212-advantages-of-include-guards"></a> <a id="cstyle-027-advantages-of-include-guards"></a>
<a id="cstyle-027"></a>

<a id="cstyle-027-2-1-2-advantages-of-include-guards"></a>

### CSTYLE-027: Advantages of Include Guards

**Class:** CORRECTNESS. **Obligation:** project requirement.

Use include guards to make repeated inclusion well-defined for the header. The guard name must not
collide with another project, generated, third-party, or platform header. Guards prevent repeated
processing; they do not fix circular interfaces, missing prerequisites, or incorrect declaration
ownership.

#### Local examples

**Noncompliant fragment (do not copy):**

```c
#pragma once

#include <stdint.h>

typedef struct AppConfig
{
    uint32_t id;
} app_config_t;
```

---

<a id="213-include-order"></a> <a id="cstyle-028-include-order"></a> <a id="cstyle-028"></a>

<a id="cstyle-028-2-1-3-include-order"></a>

### CSTYLE-028: Include Order

**Class:** CORRECTNESS. **Obligation:** project requirement.

In a module implementation, include its own public header first, then C standard headers,
third-party headers where the adapter is their owner, and other directly used project headers.
Separate and alphabetize each group. An application entry point without a matching header starts
with its standard headers. Application `main.c` may directly include any needed standard, platform,
third-party, module public/internal, contract, or adapter header under CMOD-021. Its own declarations
remain private, except for the required hosted entry point. A source file is not an includable
header and must not have an include guard. Include order must never be an ABI or compilation
prerequisite.

#### Local examples

**Contextual C example:**

```c
#include <errno.h>
#include <stdlib.h>
#include <string.h>

#include <openssl/ssl.h>

#include "memory_manager.h"
#include "network_socket.h"
#include "packet_parser.h"
```

**Noncompliant fragment (do not copy):**

```c
#include <stdlib.h>
#include "packet_parser.h"
#include "network_socket.h"
#include <string.h>
#include "memory_manager.h"
```

---

<a id="214-external-dependency-wrappers"></a> <a id="cstyle-029-external-dependency-wrappers"></a>
<a id="cstyle-029"></a>

<a id="cstyle-029-2-1-4-external-dependency-wrappers"></a>

### CSTYLE-029: External Dependency Wrappers

**Class:** CORRECTNESS. **Obligation:** project requirement.

Concentrate version-sensitive third-party calls in a named adapter. Give the adapter a project-owned
contract for ownership, errors, capacity, and lifetime; a macro that merely renames a library call
is not such a contract. Ordinary modules use the adapter's approved interface or an injected port,
according to CMOD-003 and CMOD-050. Do not require wrappers for every ISO C operation. Dependency
trust, pinning, and updates belong to CMOD-084.

**Failure scenarios:** [CPIT-093][c-common-pitfalls-cpit-093],
[CPIT-099][c-common-pitfalls-cpit-099].

**Source context:** [supply-chain][c-common-pitfalls-ref-supply-chain].

#### Local examples

**Contextual C example:**

```c
#if !defined(SSL_WRAPPER_H)
  #define SSL_WRAPPER_H

  #include <errno.h>
  #include <stdlib.h>

  #include <openssl/ssl.h>

static inline int SSL_WRAP_ctxNew(SSL_CTX **ctx_out)
{
        int ret = EXIT_SUCCESS;

        SSL_CTX *ctx = (SSL_CTX *)(NULL);

        if (ctx_out == (SSL_CTX **)(NULL))
        {
                ret = -EINVAL;
                goto function_output;
        }

        if (*ctx_out != (SSL_CTX *)(NULL))
        {
                ret = -EINVAL;
                goto function_output;
        }

        ctx = SSL_CTX_new(TLS_client_method());
        if (ctx == (SSL_CTX *)(NULL))
        {
                ret = -EIO;
                goto function_output;
        }

        *ctx_out = ctx;

function_output:
        return ret;
}

static inline int SSL_WRAP_ctxFree(SSL_CTX **ctx)
{
        int ret = EXIT_SUCCESS;

        if ((ctx != (SSL_CTX **)(NULL)) && (*ctx != (SSL_CTX *)(NULL)))
        {
                SSL_CTX_free(*ctx);
                *ctx = (SSL_CTX *)(NULL);
        }

function_output:
        return ret;
}

#endif
```

**Contextual C example:**

```c
#include <stdlib.h>

#include "ssl_wrapper.h"

int APP_main(void)
{
        int ret         = EXIT_SUCCESS;
        int cleanup_ret = EXIT_SUCCESS;

        SSL_CTX *ctx = (SSL_CTX *)(NULL);

        ret = SSL_WRAP_ctxNew(&ctx);
        if (ret != EXIT_SUCCESS)
                goto function_output;

function_output:
        cleanup_ret = SSL_WRAP_ctxFree(&ctx);
        if ((ret == EXIT_SUCCESS) && (cleanup_ret != EXIT_SUCCESS))
                ret = cleanup_ret;

        return ret;
}
```

---

<a id="22-header-content-and-interface-boundaries"></a>
<a id="cstyle-030-header-content-and-interface-boundaries"></a> <a id="cstyle-030"></a>

<a id="cstyle-030-2-2-header-content-and-interface-boundaries"></a>

### CSTYLE-030: Header Content and Interface Boundaries

**Class:** CORRECTNESS. **Obligation:** project requirement.

Define a public contract only for supported behavior, not to expose implementation convenience.

#### Local examples

**Contextual C example:**

```c
#if !defined(MODULE_H)
  #define MODULE_H

typedef struct Module module_t;
int                   MODULE_start(module_t *module);

#endif
```

**Noncompliant fragment (do not copy):**

```c
#if !defined(MODULE_H)
#define MODULE_H

static int internal_state = 0;
int module_privateHelper(void);

#endif
```

---

<a id="221-file-size"></a> <a id="cstyle-031-file-size"></a> <a id="cstyle-031"></a>

<a id="cstyle-031-2-2-1-file-size"></a>

### CSTYLE-031: File Size

**Class:** PROJECT_STYLE. **Obligation:** review trigger.

Review a source file above 1,000 lines or a header above 500 lines for weak cohesion and accidental
public surface. These inherited thresholds are review triggers, not measurements of correctness.
Split by responsibility, not by arbitrary line count. Record the review outcome when retaining a
larger file.

#### Local examples

**Layout example (not executable):**

```text
parser.c: parsing only
serializer.c: serialization only
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
protocol.c: parsing + TLS + storage + CLI + metrics + database
```

---

<a id="222-module-cohesion"></a> <a id="cstyle-032-module-cohesion"></a> <a id="cstyle-032"></a>

<a id="cstyle-032-2-2-2-module-cohesion"></a>

### CSTYLE-032: Module Cohesion

**Class:** ARCHITECTURE / CORRECTNESS. **Obligation:** project requirement.

Each module should have one clear responsibility.

- a module must group closely related behavior, data, and interfaces
- avoid "god modules" that mix unrelated domains
- if a module starts handling unrelated responsibilities, split it into smaller focused modules
- file splitting must follow responsibility boundaries, not arbitrary naming

- cohesive modules are easier to review, test, and replace
- clear boundaries reduce hidden coupling between unrelated features
- smaller focused modules improve long-term maintainability

#### Local examples

**Layout example (not executable):**

```text
module/storage/: owns storage state and storage operations
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
module/utils/: owns unrelated storage, networking, crypto, and UI logic
```

---

<a id="223-header-content-rules"></a> <a id="cstyle-033-header-content-rules"></a>
<a id="cstyle-033"></a>

<a id="cstyle-033-2-2-3-header-content-rules"></a>

### CSTYLE-033: Header Content Rules

**Class:** ARCHITECTURE / CORRECTNESS. **Obligation:** project requirement.

Public headers contain the module contract: declarations, opaque types, required value DTOs,
callback types, constants, and export annotations. They must not define mutable externally linked
objects or expose private representation. Internal headers may contain the module's complete private
types and cross-TU prototypes. An approved foundation header may contain a small `static inline`
helper. Including a header does not authorize access to another module's state.

#### Local examples

**Noncompliant fragment (do not copy):**

```c
static int global_value = 0;
```

---

<a id="224-self-contained-headers"></a> <a id="cstyle-034-self-contained-headers"></a>
<a id="cstyle-034"></a>

<a id="cstyle-034-2-2-4-self-contained-headers"></a>

### CSTYLE-034: Self-Contained Headers

**Class:** CORRECTNESS. **Obligation:** project requirement.

A header must provide the types and declarations needed to parse its own interface. Compile it as
the first include in a probe without prerequisite headers. A macro-only header may be followed by a
harmless probe declaration to avoid an empty-translation-unit diagnostic; the probe must not supply
a missing dependency. Test each supported public macro/ABI variant. Do not rely on an unrelated
header having been included first.

#### Local examples

**Contextual C example:**

```c
#include "my_header.h"

int main(void)
{
        int ret = 0;

function_output:
        return ret;
}
```

---

<a id="23-data-layout-and-abi"></a> <a id="cstyle-035-data-layout-and-abi"></a>
<a id="cstyle-035"></a>

<a id="cstyle-035-2-3-data-layout-and-abi"></a>

### CSTYLE-035: Data Layout and ABI

**Class:** CORRECTNESS. **Obligation:** project requirement.

State the representation assumptions of public data and serialized values. Use the specific controls
below.

#### Local examples

**Contextual C example:**

```c
typedef struct WireHeader
{
        uint8_t  version;
        uint8_t  flags;
        uint16_t payload_size_le;
} wire_header_t;
```

**Noncompliant fragment (do not copy):**

```c
typedef struct WireHeader
{
    long version;
    void *payload;
} wire_header_t;
```

---

<a id="231-explicit-integer-types"></a> <a id="cstyle-036-explicit-integer-types"></a>
<a id="cstyle-036"></a>

<a id="cstyle-036-2-3-1-explicit-integer-types"></a>

### CSTYLE-036: Explicit Integer Types

**Class:** PORTABILITY / CORRECTNESS. **Obligation:** project requirement.

Use `size_t` for object sizes and capacities, `ptrdiff_t` for representable pointer differences, and
fixed-width integer types when a specified width is part of the contract. Exact-width types are not
guaranteed on every C target. A target profile must declare required integer widths, `CHAR_BIT`,
alignment, byte order, and relevant ABI options. Check narrowing before conversion. Use project
status values or map platform errors explicitly; do not assume all platforms assign the same numeric
values to error names.

#### Local examples

**Contextual C example:**

```c
uint32_t register_value = 0u;
uint16_t wire_length    = 0u;
```

**Noncompliant fragment (do not copy):**

```c
unsigned long register_value = 0ul;
int wire_length = 0;
```

---

<a id="232-enum-vs-macro-constants"></a> <a id="cstyle-037-enum-vs-macro-constants"></a>
<a id="cstyle-037"></a>

<a id="cstyle-037-2-3-2-enum-vs-macro-constants"></a>

### CSTYLE-037: Enum vs Macro Constants

**Class:** CORRECTNESS. **Obligation:** project requirement.

Prefer an enum for a closed set of related states, commands, or modes. Use a macro or another
qualified constant form when preprocessing, a bitmask, or a specified integer representation
requires it. An enum documents a value domain but does not validate externally supplied integers.
Use a count sentinel only for the zero-based contiguous case described in CSTYLE-007.

#### Local examples

**Contextual C example:**

```c
typedef enum DeviceState
{
        DEVICE_STATE_OFF  = 0u,
        DEVICE_STATE_INIT = 1u,
        DEVICE_STATE_RUN  = 2u,

        /*< Enum max value >*/
        DEVICE_STATE_MAX = 3u
} device_state_t;
```

**Noncompliant fragment (do not copy):**

```c
#define DEVICE_STATE_OFF   (0u)
#define DEVICE_STATE_INIT  (1u)
#define DEVICE_STATE_RUN   (2u)
```

---

<a id="233-struct-serialization"></a> <a id="cstyle-038-struct-serialization"></a>
<a id="cstyle-038"></a>

<a id="cstyle-038-2-3-3-struct-serialization"></a>

### CSTYLE-038: Struct Serialization

**Class:** PORTABILITY / CORRECTNESS. **Obligation:** project requirement.

Encode wire and persistent data field by field. Specify version, byte order, field widths, permitted
values, lengths, reserved bits, and integrity policy. Do not write or deserialize a raw C struct,
pointer, enum representation, or padding as a portable format. Fixed-width members do not remove
struct padding or byte-order dependence. Decode into validated local values before committing
runtime state. See the complete checked codec in the worked example.

**Failure scenarios:** [CPIT-028][c-common-pitfalls-cpit-028].

**Complete example:** [worked sources][c-code-standard-worked-example].

#### Local examples

**Noncompliant fragment (do not copy):**

```c
typedef struct Packet
{
    uint32_t id;
    uint16_t size;
} packet_t;

memcpy(packet_buffer, &packet, sizeof(packet));
```

**Contextual C example:**

```c
#define PACKET_SERIALIZED_SIZE_BYTES ((size_t)(6U))

int PACKET_serialize(const packet_t *packet, uint8_t buffer[],
                     size_t buffer_size)
{
        int ret = EXIT_SUCCESS;

        size_t offset = 0u;

        if ((packet == (const packet_t *)(NULL)) ||
            (buffer == (uint8_t *)(NULL)))
        {
                ret = -EINVAL;
                goto function_output;
        }

        if (buffer_size < PACKET_SERIALIZED_SIZE_BYTES)
        {
                ret = -ENOSPC;
                goto function_output;
        }

        ret = BYTE_writeU32Be(buffer, buffer_size, &offset, packet->id);
        if (ret != EXIT_SUCCESS)
                goto function_output;

        ret = BYTE_writeU16Be(buffer, buffer_size, &offset, packet->size);
        if (ret != EXIT_SUCCESS)
                goto function_output;

function_output:
        return ret;
}
```

**Contextual C example:**

```c
int PACKET_serialize(const packet_t *packet, uint8_t buffer[]);
```

---

<a id="234-struct-layout-awareness"></a> <a id="cstyle-039-struct-layout-awareness"></a>
<a id="cstyle-039"></a>

<a id="cstyle-039-2-3-4-struct-layout-awareness"></a>

### CSTYLE-039: Struct Layout Awareness

**Class:** PORTABILITY / CORRECTNESS. **Obligation:** project requirement.

Treat size, alignment, packing, enum representation, and calling conventions as ABI properties when
objects cross a binary boundary. Measure padding when optimizing storage; do not reorder fields of
an existing ABI casually. Do not use packed overlays for unaligned network data. Validate ABI layout
with target checks where it is fixed. Field order alone is not an optimization or
compatibility guarantee.

#### Local examples

**Contextual C example:**

```c
typedef struct Example
{
        uint64_t timestamp;
        uint32_t id;
        uint16_t size;
        uint8_t  flags;
} example_t;
```

**Contextual C example:**

```c
typedef struct Data
{
        uint8_t  flag;
        uint8_t  pad[3];
        uint32_t value;
} data_t;
```

---

<a id="235-struct-comparison"></a> <a id="cstyle-040-struct-comparison"></a> <a id="cstyle-040"></a>

<a id="cstyle-040-2-3-5-struct-comparison"></a>

### CSTYLE-040: Struct Comparison

**Class:** PORTABILITY / CORRECTNESS. **Obligation:** project requirement.

Compare semantic fields, not entire struct object representations. Padding can make representation
comparison differ from value comparison. `memcmp` is allowed for valid, non-secret byte sequences of
the stated length; it is not a constant-time secret comparator. Do not replace ordered integer
comparisons with subtraction that may overflow.

#### Local examples

**Contextual C example:**

```c
bool is_equal = false;

is_equal = (data_a.flag == data_b.flag) && (data_a.value == data_b.value);
```

---

<a id="236-public-struct-abi"></a> <a id="cstyle-041-public-struct-abi"></a> <a id="cstyle-041"></a>

<a id="cstyle-041-2-3-6-public-struct-abi"></a>

### CSTYLE-041: Public Struct ABI

**Class:** ARCHITECTURE / CORRECTNESS. **Obligation:** project requirement.

Use an incomplete public object type when consumers do not need its layout. A constructor/destructor
pair must specify allocator family and failure behavior. Caller-supplied opaque storage needs
documented size, alignment, effective-type, and initialization rules; a byte array cast is not
automatically valid storage. For stable binary APIs, define compatibility, struct-size negotiation,
and feature/version rules. Do not infer ABI stability from source compatibility.

#### Local examples

**Contextual C example:**

```c
typedef struct Config config_t;

int CONFIG_create(config_t **cfg_out);
int CONFIG_destroy(config_t *cfg);
```

**Contextual C example:**

```c
struct Config
{
        int timeout;
        int retries;
        int flags;
};
```

---

<a id="237-bit-field-usage"></a> <a id="cstyle-127"></a>

<a id="cstyle-127-2-3-7-bit-field-usage"></a>

### CSTYLE-127: Bit-Field Usage

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-126: Bit-field layout used as an external representation][c-common-pitfalls-cpit-126]
- [CPIT-084: Reserved register bits clobbered][c-common-pitfalls-cpit-084]

Bit-fields must not represent MMIO registers, serialized data, network protocols, persistent
formats, or public ABI. Allocation order, alignment, packing, and the treatment of storage units
depend on the implementation.

Every numeric bit-field width must use the lowercase unsigned suffix `u`, as required for enum
values. Write `: 1u`, `: 2u`, or `: 3u`; never write an integer width without a suffix or use
uppercase `U`.

Avoid mapping a register directly:

Use a fixed-width register value and named masks:

A purely internal structure may use bit-fields only with a documented justification. Such code must
not depend on byte layout, bit allocation order, or raw copying, and the object must remain inside
one compiler and ABI domain.

#### Local examples

**Noncompliant fragment (do not copy):**

```c
typedef struct Register
{
    uint32_t enable : 1u;
    uint32_t mode   : 3u;
    uint32_t status : 4u;
} register_t;
```

**Contextual C example:**

```c
#define REG_ENABLE_MASK ((uint32_t)(1U << 0U))
#define REG_MODE_MAX    ((uint32_t)(7U))
#define REG_MODE_MASK   ((uint32_t)(7U << 1U))
#define REG_STATUS_MASK ((uint32_t)(15U << 4U))

uint32_t reg_value = 0u;

if (requested_mode <= REG_MODE_MAX)
{
        reg_value  = MMIO_read32(REG_CTRL_ADDRESS);
        reg_value &= ~REG_MODE_MASK;
        reg_value |= (requested_mode << 1u) & REG_MODE_MASK;
        MMIO_write32(REG_CTRL_ADDRESS, reg_value);
}
```

---

<a id="238-plain-char-semantics"></a> <a id="cstyle-128"></a>

<a id="cstyle-128-2-3-8-plain-char-semantics"></a>

### CSTYLE-128: Plain `char` Semantics

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-127: Plain `char` used as binary numeric storage][c-common-pitfalls-cpit-127]
- [CPIT-063: `ctype.h` negative `char`][c-common-pitfalls-cpit-063]

Use character types according to the data contract:

- `char` represents text, a character, or a NUL-terminated string element
- `signed char` represents an explicitly signed small integer only when the domain requires that
  type
- `unsigned char` represents an object representation or raw byte storage
- `uint8_t` represents an exact-width 8-bit integer or protocol octet when the implementation
  provides it

Whether plain `char` is signed must not affect numeric logic, range checks, shifts, indexing,
checksums, measurements, or protocol values.

Avoid ambiguous binary declarations:

Prefer types that state the domain:

#### Local examples

**Noncompliant fragment (do not copy):**

```c
char raw_data[256];
char checksum;
char temperature;
```

**Contextual C example:**

```c
char    text[256];
uint8_t raw_data[256];
uint8_t checksum            = 0u;
int16_t temperature_celsius = 0;
```

---

<a id="239-union-active-member-discipline"></a> <a id="cstyle-129"></a>

<a id="cstyle-129-2-3-9-union-active-member-discipline"></a>

### CSTYLE-129: Union Active-Member Discipline

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-028: Union pointer confusion][c-common-pitfalls-cpit-028]
- [CPIT-022: Strict aliasing violation][c-common-pitfalls-cpit-022]
- [CPIT-135: Inactive union member read][c-common-pitfalls-cpit-135]

A union that represents alternative semantic values must have an explicit discriminator. Code may
read only the member selected by that discriminator, and every state transition must update the
member and discriminator together.

Prefer a tagged union:

Do not use a union to reinterpret an object representation:

Use `memcpy()` when code needs the bytes of a representation:

#### Local examples

**Contextual C example:**

```c
typedef enum ValueType
{
        VALUE_TYPE_INT = 0u,
        VALUE_TYPE_PTR = 1u,

        /* element count */
        VALUE_TYPE_MAX = 2u
} value_type_t;

typedef struct Value
{
        value_type_t type;

        union
        {
                int32_t int_value;
                void   *ptr_value;
        } data;
} value_t;
```

**Noncompliant fragment (do not copy):**

```c
union
{
    float float_value;
    uint32_t bits;
} value;

value.float_value = input;
bits = value.bits;
```

**Contextual C example:**

```c
uint32_t bits = 0u;

static_assert(sizeof(input) == sizeof(bits));
memcpy(&bits, &input, sizeof(bits));
```

---

<a id="2310-flexible-array-members"></a> <a id="cstyle-130"></a>

<a id="cstyle-130-2-3-10-flexible-array-members"></a>

### CSTYLE-130: Flexible Array Members

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-128: Flexible-array capacity mismatch][c-common-pitfalls-cpit-128]
- [CPIT-047: Allocation multiplication overflow][c-common-pitfalls-cpit-047]
- [CPIT-049: Offset plus size overflow][c-common-pitfalls-cpit-049]

Flexible array members are prohibited in public ABI, MMIO mappings, serialized layouts, and
persistent formats. Safety-critical core code requires a documented deviation before using one.

An approved internal flexible-array object must:

- keep recorded length and capacity in the owning object
- calculate `sizeof(header) + payload_capacity` with checked arithmetic
- document ownership and the matching allocator family
- validate every index against the recorded capacity of the same allocation
- use an explicit total byte count when copying; `sizeof(struct_type)` copies only the fixed header

Prefer an explicit capacity contract:

Do not allocate or copy only the fixed header when payload storage is needed.

#### Local examples

**Contextual C example:**

```c
typedef struct Packet
{
        size_t length;
        size_t capacity;

        uint8_t data[];
} packet_t;

packet_t *packet     = (packet_t *)(NULL);
size_t    alloc_size = 0u;

bool has_overflow = false;

has_overflow = ARITH_addSize(sizeof(*packet), payload_capacity, &alloc_size);
if (has_overflow)
{
        ret = -ENOMEM;
        goto function_output;
}

packet = (packet_t *)MEM_alloc(alloc_size);
if (packet == (packet_t *)(NULL))
{
        ret = -ENOMEM;
        goto function_output;
}

packet->length   = 0u;
packet->capacity = payload_capacity;
```

---

<a id="2311-pointer-typedefs"></a> <a id="cstyle-141"></a>

<a id="cstyle-141-2-3-11-pointer-typedef-policy"></a>

### CSTYLE-141: Pointer Typedefs

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

Do not hide ordinary object pointers behind a typedef. Pointer typedefs obscure qualification and
make declarations such as `const buffer_t` appear to protect the pointed bytes when they only
qualify the pointer alias.

Prefer a typedef for the object type and spell the pointer explicitly:

An opaque handle may use a pointer typedef only at a reviewed external ABI boundary that cannot
expose the pointed type. Project-owned module APIs prefer an incomplete object type and an explicit
pointer.

#### Local examples

**Noncompliant fragment (do not copy):**

```c
typedef uint8_t *buffer_t;

const buffer_t buffer = (buffer_t)(NULL);
```

**Contextual C example:**

```c
typedef uint8_t byte_t;

const byte_t *buffer = (const byte_t *)(NULL);
```

---

<a id="2312-non-zero-aggregate-initialization-uses-designators"></a> <a id="cstyle-142"></a>

<a id="cstyle-142-2-3-12-designated-aggregate-initialization"></a>

### CSTYLE-142: Non-Zero Aggregate Initialization Uses Designators

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

An aggregate initializer containing a non-zero semantic value must name each initialized member.
Positional aggregate initialization is permitted only for the all-zero initializer required by
`CSTYLE-107`.

Designators make the source independent of unrelated member insertion and make the semantic mapping
visible during ABI and configuration review.

#### Local examples

**Noncompliant fragment (do not copy):**

```c
static const config_t g_default_config = {1000u, 3u, true};
```

**Contextual C example:**

```c
static const config_t g_default_config = {
        .timeout_ms  = 1000u,
        .retry_count = 3u,
        .is_enabled  = true,
};
```

---

<a id="2313-translation-time-invariants"></a> <a id="cstyle-143"></a>

<a id="cstyle-143-2-3-13-translation-time-invariants"></a>

### CSTYLE-143: Translation-Time Invariants

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

An invariant knowable during translation must be checked with `static_assert` or a project
compatibility wrapper. Do not rely only on a comment or a runtime branch for a translation-time
property.

Use translation-time checks for public layout, wire-format bounds, array counts, alignment,
power-of-two parameters, enum sentinels, and assumptions shared with assembly or linker scripts. The
expression must not depend on a side effect.

#### Local examples

**Contextual C example:**

```c
static_assert(sizeof(uint32_t) == 4u);
static_assert(MEM_BLOCK_ALIGNMENT >= alignof(max_align_t));
static_assert((MEM_BLOCK_ALIGNMENT & (MEM_BLOCK_ALIGNMENT - 1u)) == 0u);
```

---

<a id="2314-string-literal-immutability"></a> <a id="cstyle-144"></a>

<a id="cstyle-144-2-3-14-string-literal-constness"></a>

### CSTYLE-144: String Literal Immutability

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-139: String literal modification][c-common-pitfalls-cpit-139]

A string literal must be referenced only through a pointer-to-const character type. Code must not
cast away that qualification or attempt to modify literal storage.

Use a writable array when mutation is required:

#### Local examples

**Contextual C example:**

```c
const char *message = "operation failed";
```

**Contextual C example:**

```c
char message[] = "operation failed";

message[0] = 'O';
```

---

<a id="2315-anonymous-structs-and-unions"></a> <a id="cstyle-161"></a>

<a id="cstyle-161-2-3-15-named-aggregate-members"></a>

### CSTYLE-161: Anonymous Structs and Unions

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

Do not use anonymous struct or union members in project interfaces or ordinary production code. Give
the aggregate type and containing member explicit names so ownership, active-member state,
debugging, generated bindings, ABI review, and static analysis can refer to them unambiguously.

An external hardware or compiler adapter may mirror an unavoidable anonymous layout only under the
compiler-extension and external-dependency boundary rules.

#### Local examples

**Contextual C example:**

```c
typedef union ValueData
{
        uint32_t u32;
        float    f32;
} value_data_t;
```

**Noncompliant fragment (do not copy):**

```c
struct Packet
{
    union
    {
        uint32_t u32;
        float f32;
    };
};
```

---

<a id="241-convert-byte-order-at-the-boundary"></a> <a id="cstyle-166"></a>

<a id="cstyle-166-2-4-1-byte-order-boundary"></a>

### CSTYLE-166: Convert Byte Order at the Boundary

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-149: Host byte order leaks into an external representation][c-common-pitfalls-cpit-149]

Wire, file, persistent, shared-memory, DMA, and hardware formats must state the byte order of every
multi-byte integer. Convert between external and host order at the owning boundary. Internal
semantic values use host order and must not be converted repeatedly as they cross ordinary helper
functions.

Do not infer byte order from the build host, a union view, a cast, or the order of structure
members. Use project conversion helpers whose names identify both width and direction. A conversion
helper must define behavior for every supported host byte order and must be covered by big-endian
and little-endian tests or equivalent byte-exact vectors.

#### Local examples

**Contextual C example:**

```c
length = WIRE_readU32Le(input);
```

**Noncompliant fragment (do not copy):**

```c
memcpy(&length, input, sizeof(length)); /* native endian assumed */
```

---

<a id="242-decode-potentially-unaligned-storage-through-byte-safe-helpers"></a>
<a id="cstyle-167"></a>

<a id="cstyle-167-2-4-2-unaligned-external-access"></a>

### CSTYLE-167: Decode Potentially Unaligned Storage Through Byte-Safe Helpers

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-024: Invalid alignment][c-common-pitfalls-cpit-024]
- [CPIT-150: Unaligned external data is accessed as a typed object][c-common-pitfalls-cpit-150]

A byte buffer does not acquire the alignment, effective type, lifetime, or provenance of an integer
or structure merely because it contains enough bytes. Potentially unaligned external storage must be
decoded with a project load/store helper or `memcpy()` into a properly aligned typed object,
followed by the required byte-order conversion.

Do not cast a packet, mapped file, packed field, device buffer, or arbitrary offset in raw storage
to a wider pointer and dereference it. Linux documents that unaligned access can be transparent but
slow, fault and require an expensive fixup, fault without recovery, or silently access different
data on different architectures.[linux-unaligned-access][linux-unaligned-access]

#### Local examples

**Contextual example:**

Include <string.h>. `native_value` is a uint32_t declared at entry; `source_bytes` has at least
sizeof(`native_value`) readable bytes. Decode the agreed byte order separately; `memcpy` fixes
alignment/aliasing access, not endianness.

```c
memcpy(&native_value, source_bytes, sizeof(native_value));
```

---

<a id="243-external-text-has-an-encoding-contract"></a> <a id="cstyle-171"></a>

<a id="cstyle-171-2-4-3-external-text-encoding-contract"></a>

### CSTYLE-171: External Text Has an Encoding Contract

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-161: External text crosses a boundary without an encoding
  contract][c-common-pitfalls-cpit-161]

Every external text boundary must name its encoding and malformed-input policy. A UTF-8 boundary
must validate well-formed UTF-8 before code interprets bytes as characters. Unicode requires a
conforming process to treat ill-formed encoding sequences as an error condition rather than
interpreting them as characters. [unicode-standard][unicode-standard]

The boundary contract must state:

- encoding form;
- whether a BOM is accepted, rejected, or consumed;
- behavior for malformed input;
- whether identity comparisons require normalization and which normalization form applies;
- whether a length counts bytes, code points, or another unit;
- maximum encoded length and maximum decoded length;
- whether embedded NUL code points are allowed.

Do not infer encoding from the current locale, platform code page, or `char` signedness.

Compliant boundary:

The API contract for `CONFIG_parseName` states UTF-8, rejects malformed input, and defines
`input_bytes` as encoded bytes.

Noncompliant boundary:

#### Local examples

**Contextual C example:**

```c
int CONFIG_parseName(const uint8_t *input, size_t input_bytes,
                     text_view_t *name);
```

**Noncompliant fragment (do not copy):**

```c
int CONFIG_parseName(
    const uint8_t *input,
    size_t input_bytes,
    text_view_t *name
); /* encoding and malformed-input behavior are unspecified */
```

---

<a id="31-macro-definition-style"></a> <a id="cstyle-042-macro-definition-style"></a>
<a id="cstyle-042"></a>

<a id="cstyle-042-3-1-macro-definition-style"></a>

### CSTYLE-042: Macro Definition Style

**Class:** CORRECTNESS. **Obligation:** project requirement.

Keep preprocessor behavior explicit and reviewable. Feature logic and compiler adaptation must not
silently change an ABI.

#### Local examples

**Contextual C example:**

```c
#define TIMEOUT_MS ((uint32_t)(100U))
#define MASK(bit_) ((uint32_t)(1U) << (bit_))
```

**Noncompliant fragment (do not copy):**

```c
#define TIMEOUT_MS 100
#define MASK(bit) 1 << bit
```

---

<a id="311-macro-literal-and-structure-rules"></a>
<a id="cstyle-043-macro-literal-and-structure-rules"></a> <a id="cstyle-043"></a>

<a id="cstyle-043-3-1-1-macro-literal-and-structure-rules"></a>

### CSTYLE-043: Macro Literal and Structure Rules

**Class:** CORRECTNESS. **Obligation:** project requirement.

Parenthesize macro expressions and their value arguments. Use an explicit integer constant macro
such as `UINT32_C`, or a checked, appropriate type when width matters. Do not force every literal
through a narrowing cast. Literal suffix capitalization is a formatting convention, not a
type-safety mechanism. `sizeof`, array bounds, and enum constants have distinct constant-expression
requirements; test macros in the contexts where they are used.

#### Local examples

**Contextual C example:**

```c
#define MAX_COUNT   ((size_t)(100U))
#define LARGE_VALUE ((uint64_t)(1000ULL))
#define PI_APPROX   ((float)(3.14F))
#define BUFFER_SIZE ((size_t)(256U))
```

---

<a id="312-multi-statement-macros"></a> <a id="cstyle-044-multi-statement-macros"></a>
<a id="cstyle-044"></a>

<a id="cstyle-044-3-1-2-multi-statement-macros"></a>

### CSTYLE-044: Multi-Statement Macros

**Class:** CORRECTNESS. **Obligation:** project requirement.

Prefer functions or small approved `static inline` helpers for executable behavior. A statement
macro must use the `do { ... } while (0)` pattern, must not evaluate a value argument more than
once, and must not hide `return`, `goto`, locking, allocation, or ownership transfer. A caller must
be able to review its side effects. GNU statement expressions are adapter-only extensions.

#### Local examples

**Contextual C example:**

```c
#define APP_ASSIGN_PAIR(first_ptr_, first_value_, second_ptr_, second_value_) \
        do                                                                    \
        {                                                                     \
                *(first_ptr_)  = (first_value_);                              \
                *(second_ptr_) = (second_value_);                             \
        }                                                                     \
        while (0)
```

**Contextual C example:**

```c
#define MIN_VALUE__(value_a_, value_b_)                                  \
        ({                                                               \
                typeof(value_a_) value_a_tmp = (value_a_);               \
                typeof(value_b_) value_b_tmp = (value_b_);               \
                (value_a_tmp < value_b_tmp) ? value_a_tmp : value_b_tmp; \
        })
```

---

<a id="313-preprocessor-restrictions"></a> <a id="cstyle-045-preprocessor-restrictions"></a>
<a id="cstyle-045"></a>

<a id="cstyle-045-3-1-3-preprocessor-restrictions"></a>

### CSTYLE-045: Preprocessor Restrictions

**Class:** CORRECTNESS. **Obligation:** project requirement.

Keep feature selection explicit and bounded. Do not redefine C keywords, standard identifiers, or
public functions as unrelated operations. Do not build include filenames from untrusted or implicit
macro state. A macro that changes public layout or calling convention is an ABI input and must be
included in the profile and compatibility tests. Generate only project-prefixed identifiers.

#### Local examples

**Noncompliant fragment (do not copy):**

```c
#define malloc(size_)  MEM_malloc(size_)
#define INCLUDE_FILE(name_)  <name_>
#include INCLUDE_FILE(config.h)
```

**Contextual C example:**

```c
#if !defined(MEM_FEATURE_STATS)
  #define MEM_FEATURE_STATS ((int)(0))
#endif
```

---

<a id="314-magic-numbers"></a> <a id="cstyle-046-magic-numbers"></a> <a id="cstyle-046"></a>

<a id="cstyle-046-3-1-4-magic-numbers"></a>

### CSTYLE-046: Magic Numbers

**Class:** CORRECTNESS. **Obligation:** project requirement.

Name domain limits, timeouts, units, protocol masks, and repeated constants. Zero, one, and plainly
explained representation operations may remain literals. Test vectors may state their concrete
values directly. Do not create meaningless names such as `VALUE_8` merely to avoid a literal; name
the protocol width or quantity instead.

#### Local examples

**Contextual C example:**

```c
static const uint32_t g_retry_limit       = 3u;
static const int32_t  g_temperature_max_c = 85;

if (retry_count >= g_retry_limit)
        EX_handleError();

if (temperature > g_temperature_max_c)
        EX_shutdownOutput();
```

**Noncompliant fragment (do not copy):**

```c
if (retry_count >= 3U)
{
    EX_handleError();
}

if (temperature > 85)
{
    EX_shutdownOutput();
}
```

---

<a id="315-token-pasting-and-stringification"></a>
<a id="cstyle-047-token-pasting-and-stringification"></a> <a id="cstyle-047"></a>

<a id="cstyle-047-3-1-5-token-pasting-and-stringification"></a>

### CSTYLE-047: Token Pasting and Stringification

**Class:** CORRECTNESS. **Obligation:** project requirement.

Use token pasting (`##`) only for controlled boilerplate generation. The `##` operator concatenates
preprocessor tokens. It does not create strings; it creates code tokens.

- always prefix generated symbols with a module or adapter namespace
- use only programmer-controlled tokens
- do not generate identifiers from external or runtime data
- keep generated names meaningful and domain-specific
- do not use token pasting to hide complex logic
- prefer `static inline`, arrays, structs, or normal functions when the macro becomes hard to read

- namespaced generated symbols reduce collision risk
- controlled token generation keeps the produced identifiers valid and reviewable
- combining `##` with `#` can help debug generated symbols
- excessive token pasting harms readability and makes macro debugging harder

#### Local examples

**Contextual C example:**

```c
#define MAKE_VAR(name_) int module_##name_

MAKE_VAR(foo);
```

**Contextual C example:**

```c
int module_foo;
```

**Contextual C example:**

```c
#define APP_DECLARE_FLAG(name_, bit_)             \
        enum                                      \
        {                                         \
                APP_FLAG_##name_ = (1U << (bit_)) \
        }

APP_DECLARE_FLAG(READ, 0U);
APP_DECLARE_FLAG(WRITE, 1U);
```

---

<a id="316-no-side-effects-in-macro-arguments"></a>
<a id="cstyle-048-no-side-effects-in-macro-arguments"></a> <a id="cstyle-048"></a>

<a id="cstyle-048-3-1-6-no-side-effects-in-macro-arguments"></a>

### CSTYLE-048: No Side Effects in Macro Arguments

**Class:** CORRECTNESS. **Obligation:** project requirement.

Do not pass assignments, increments, decrements, or state-changing calls as arguments to project
function-like macros. Compute the value first. The standard assertion facility must likewise receive
a side-effect-free expression. This restriction does not prohibit ordinary function calls with
evaluated arguments; those remain subject to sequencing and order-of-evaluation rules.

#### Local examples

**Noncompliant fragment (do not copy):**

```c
result = MAX(value_a++, value_b);
flags = SET_MASK(register_value, get_mask());
```

**Contextual C example:**

```c
uint32_t mask        = 0u;
uint32_t value_a_tmp = 0u;

value_a_tmp = value_a;
mask        = MASK_getCurrent();

result = UTIL_MAX(value_a_tmp, value_b);
flags  = REG_SET_MASK(register_value, mask);
```

---

<a id="32-conditional-compilation"></a> <a id="cstyle-049-conditional-compilation"></a>
<a id="cstyle-049"></a>

<a id="cstyle-049-3-2-conditional-compilation"></a>

### CSTYLE-049: Conditional Compilation

**Class:** CORRECTNESS. **Obligation:** project requirement.

Qualify every shipped feature variant and document feature defaults. Dead branches are not validated
by compiling a different variant.

#### Local examples

**Contextual C example:**

```c
#if defined(PLATFORM_HAS_DMA)
ret = DMA_copy(dst, src, size_bytes);
#else
ret = CPU_copy(dst, src, size_bytes);
#endif
```

**Noncompliant fragment (do not copy):**

```c
#if defined(DEBUG)
authorization_required = false;
#endif
```

---

<a id="321-preprocessor-conditionals"></a> <a id="cstyle-050-preprocessor-conditionals"></a>
<a id="cstyle-050"></a>

<a id="cstyle-050-3-2-1-preprocessor-conditionals"></a>

### CSTYLE-050: Preprocessor Conditionals

**Class:** CORRECTNESS. **Obligation:** project requirement.

Use explicit `#if defined(NAME)` tests for presence and `#if !defined(NAME)` for absence. Use
numeric `#if NAME` only for a documented numeric feature macro. An `#else` is allowed for the
exhaustively documented fallback. Unknown targets or missing mandatory capabilities must fail with a
diagnostic, not silently select a permissive or ABI-incompatible implementation.

**Source context:** [gcc-dialect][c-common-pitfalls-ref-gcc-dialect].

#### Local examples

**Contextual C example:**

```c
#if defined(CONFIG_FEATURE_X)
  #define APP_FEATURE_X_ENABLED ((int)(1))
#elif !defined(CONFIG_FEATURE_X)
  #define APP_FEATURE_X_ENABLED ((int)(0))
#endif
```

**Noncompliant fragment (do not copy):**

```c
#ifdef CONFIG_FEATURE_X
int feature_value = 1;
#else
int feature_value = 0;
#endif
```

---

<a id="322-macro-redefinition-and-undef"></a> <a id="cstyle-051-macro-redefinition-and-undef"></a>
<a id="cstyle-051"></a>

<a id="cstyle-051-3-2-2-macro-redefinition-and-undef"></a>

### CSTYLE-051: Macro Redefinition and `#undef`

**Class:** CORRECTNESS. **Obligation:** project requirement.

Do not silently redefine an existing macro. Use `#undef` only for a bounded, owned adaptation such
as an X-macro pass, a test fixture, or foreign-header containment. Record why it is needed and where
its effect ends. Do not use macro redefinition to change another module's API or implementation
behavior.

#### Local examples

**Contextual C example:**

```c
#if !defined(APP_BUFFER_SIZE)
  #define APP_BUFFER_SIZE ((size_t)(256U))
#endif
```

**Noncompliant fragment (do not copy):**

```c
#undef APP_BUFFER_SIZE
#define APP_BUFFER_SIZE  ((size_t)(256U))
```

---

<a id="33-compiler-extensions"></a> <a id="cstyle-052-compiler-extensions"></a>
<a id="cstyle-052"></a>

<a id="cstyle-052-3-3-compiler-extensions"></a>

### CSTYLE-052: Compiler Extensions

**Class:** PORTABILITY / CORRECTNESS. **Obligation:** project requirement.

Keep compiler-specific attributes, builtins, and pragmas in named compiler or platform adapters.
Require a tested fallback or an explicit unsupported-target error. ISO C23 `typeof` and
`typeof_unqual` are language features; GNU statement expressions and older-dialect uses of compiler
`typeof` spellings are extensions. The C17 compatibility profile cannot assume C23 syntax. A
successful compiler flag probe does not certify support for every feature of that C edition.

**Related controls:** [CSTYLE-026][c-code-standard-cstyle-026].

**Source context:** [gcc-dialect][c-common-pitfalls-ref-gcc-dialect].

#### Local examples

**Contextual C example:**

```c
#define MEM_ATTR_PRINTF__(fmt_idx_, arg_idx_) \
        __attribute__((format(printf, fmt_idx_, arg_idx_)))
```

**Noncompliant fragment (do not copy):**

```c
#define MEM_MAX(a_, b_) \
    ({ typeof(a_) a_tmp = (a_); typeof(b_) b_tmp = (b_); \
       (a_tmp > b_tmp) ? a_tmp : b_tmp; })
```

---

<a id="34-_generic-policy"></a> <a id="cstyle-145"></a>

<a id="cstyle-145-3-4-generic-selection-policy"></a>

### CSTYLE-145: `_Generic` Policy

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

Use `_Generic` only in a project utility header to implement a documented type-safe adapter or
compile-time dispatch. A generic selection must not hide business logic, runtime state changes,
ownership transfer, allocation, or control-flow side effects.

Every association expression must satisfy the same public contract, and the controlling expression
must not depend on evaluation for a side effect. Prefer a normal typed function when callers do not
require compile-time type selection.

#### Local examples

**Contextual C example:**

```c
#define TYPE_WIDTH(x_) _Generic((x_), uint32_t: 32u, uint64_t: 64u)
```

**Noncompliant fragment (do not copy):**

```c
#define PROCESS(x_) _Generic((x_), request_t: processRequest, response_t: processResponse)(x_) /* business dispatch hidden in macro */
```

---

<a id="35-inline-assembly"></a> <a id="cstyle-162"></a>

<a id="cstyle-162-3-5-inline-assembly-contract"></a>

### CSTYLE-162: Inline Assembly

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-146: Inline assembly has an incomplete machine contract][c-common-pitfalls-cpit-146]

Inline assembly is prohibited in ordinary module logic. A reviewed platform, compiler,
synchronization, or cryptographic adapter may use it only when a standard C construct, compiler
intrinsic, or separately compiled assembly implementation cannot express the required semantic or
measured behavior.

Every permitted block must document and encode:

- supported architecture, ABI, compiler, and optimization modes;
- all inputs, outputs, early clobbers, registers, flags, and memory effects;
- alignment, object-lifetime, provenance, and ordering preconditions;
- whether the block may trap, block, access MMIO, or change control flow;
- a portable or platform fallback when the product supports another target;
- generated-code inspection and focused tests for the claimed property.

`volatile` on an assembly statement does not describe a memory barrier or an unknown memory effect.
Declare the exact compiler and machine contract. Common assembly fragments belong behind named
helpers; Linux similarly recommends using inline assembly only when necessary and wrapping common
fragments in helpers.[linux-coding-style][linux-coding-style]

#### Local examples

**Contextual C example:**

```c
ret = PLATFORM_crc32(input, size_bytes, &crc);
```

**Noncompliant fragment (do not copy):**

```c
crc = __builtin_ia32_crc32si(crc, value); /* ISA intrinsic leaked into portable core */
```

---

<a id="41-function-design-and-control-flow"></a>
<a id="cstyle-053-function-design-and-control-flow"></a> <a id="cstyle-053"></a>

<a id="cstyle-053-4-1-function-design-and-control-flow"></a>

### CSTYLE-053: Function Design and Control Flow

**Class:** CORRECTNESS. **Obligation:** project requirement.

Describe operations, side effects, failures, and ownership before selecting their control-flow
shape.

**Failure scenarios:** [CPIT-034][c-common-pitfalls-cpit-034],
[CPIT-043][c-common-pitfalls-cpit-043], [CPIT-105][c-common-pitfalls-cpit-105].

#### Local examples

**Contextual C example:**

```c
int MODULE_run(module_t *module)
{
        int ret = EXIT_SUCCESS;

        if (module == (module_t *)(NULL))
        {
                ret = -EINVAL;
                goto function_output;
        }

function_output:
        return ret;
}
```

**Noncompliant fragment (do not copy):**

```c
int MODULE_run(module_t *module)
{
    if (module == NULL) return -1;
    if (!module->ready) return -2;
    return do_work(module);
}
```

---

<a id="411-function-size-and-complexity"></a> <a id="cstyle-054-function-size-and-complexity"></a>
<a id="cstyle-054"></a>

<a id="cstyle-054-4-1-1-function-size-and-complexity"></a>

### CSTYLE-054: Function Size and Complexity

**Class:** PROJECT_STYLE. **Obligation:** review trigger.

Keep each function responsible for one operation and its failure handling. Split a function when
independent responsibilities obscure ownership or state transitions. Do not split solely to satisfy
a line-count metric if doing so hides an invariant. A public operation must describe its
preconditions, postconditions, side effects, and failure-state guarantee.

**Failure scenarios:** [CPIT-034][c-common-pitfalls-cpit-034],
[CPIT-045][c-common-pitfalls-cpit-045].

#### Local examples

**Layout example (not executable):**

```text
parse_header()
parse_payload()
validate_crc()
PROCESS_frame() composes the three focused steps
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
PROCESS_frame() is 600 lines and parses, validates, allocates, logs, retries,
and writes storage
```

---

<a id="cyclomatic-complexity"></a> <a id="cstyle-055"></a>

<a id="cstyle-055-cyclomatic-complexity"></a>

### CSTYLE-055: Cyclomatic Complexity

**Class:** ANALYZABILITY. **Obligation:** review trigger.

Use cyclomatic complexity 10 as a review trigger for production functions. Record the tool and
counting convention. A result above the threshold requires review, not an automatic claim that the
function is unsafe. Generated code and bounded host tests may use a documented profile exception.
Code metrics cannot replace tests or ownership analysis.

#### Local examples

**Contextual example:**

Small function definition with <errno.h>, <stdlib.h> and its own declaring header. Complexity
thresholds are review triggers, not a mathematical proof that the function is correct.

```c
int SAMPLE_validatePair(int left, int right)
{
        int ret = EXIT_SUCCESS;

        if ((left < 0) || (right < 0))
        {
                ret = -EINVAL;
                goto function_output;
        }

function_output:
        return ret;
}
```

---

<a id="cognitive-complexity"></a> <a id="cstyle-056"></a>

<a id="cstyle-056-cognitive-complexity"></a>

### CSTYLE-056: Cognitive Complexity

**Class:** ANALYZABILITY. **Obligation:** review trigger.

Use cognitive complexity 15 as an inherited review trigger only when the selected analyzer defines
and reports that metric. Record its version and configuration. Do not equate a score with human
comprehension or correctness. Prefer eliminating hidden state and unnecessary nesting over
metric-driven refactoring that merely moves complexity to callees.

#### Local examples

**Contextual C example:**

```c
#define EX_ARRAY_MIN ((int)(0U))
#define EX_ARRAY_MAX ((int)(100U))

int EX_complexFunction(int array[], size_t size, int flag)
{
        int ret = EXIT_SUCCESS;

        size_t index_i = 0u;
        size_t index_j = 0u;

        if (array == (int *)(NULL))
        {
                ret = -EINVAL;
                goto function_output;
        }

        for (index_i = 0u; index_i < size; index_i++)
        {
                if (array[index_i] < EX_ARRAY_MIN)
                        array[index_i] = EX_ARRAY_MIN;
                else if (flag != 0)
                {
                        for (index_j = 0u; index_j < size; index_j++)
                        {
                                if ((index_i != index_j) &&
                                    (array[index_j] > EX_ARRAY_MAX))
                                {
                                        array[index_i] = EX_ARRAY_MAX;
                                }
                        }
                }
        }

function_output:
        return ret;
}
```

---

<a id="412-parameter-count"></a> <a id="cstyle-057-parameter-count"></a> <a id="cstyle-057"></a>

<a id="cstyle-057-4-1-2-parameter-count"></a>

### CSTYLE-057: Parameter Count

**Class:** PROJECT_STYLE. **Obligation:** review trigger.

Prefer no more than `5` parameters.

#### Local examples

**Contextual C example:**

```c
int EX_calculateSum(int value_a, int value_b, int value_c);
```

**Noncompliant fragment (do not copy):**

```c
int EX_processData(int value_a,
                   int value_b,
                   int value_c,
                   int value_d,
                   int value_e,
                   int value_f);
```

---

<a id="413-argument-validation"></a> <a id="cstyle-058-argument-validation"></a>
<a id="cstyle-058"></a>

<a id="cstyle-058-4-1-3-argument-validation"></a>

### CSTYLE-058: Argument Validation

**Class:** CORRECTNESS. **Obligation:** project requirement.

Validate nullability, sizes, ranges, and domain constraints required by each API. Zero length is not
universally invalid: document empty-buffer behavior. A NULL check cannot prove lifetime, alignment,
capacity, or provenance; those are caller obligations unless a validated handle system enforces
them. Never dereference an output-handle pointer before checking the pointer itself. If the function
reads `*out`, its contract must require initialized storage.

**Failure scenarios:** [CPIT-011][c-common-pitfalls-cpit-011],
[CPIT-055][c-common-pitfalls-cpit-055], [CPIT-057][c-common-pitfalls-cpit-057],
[CPIT-083][c-common-pitfalls-cpit-083], [CPIT-090][c-common-pitfalls-cpit-090].

**Complete example:** [worked sources][c-code-standard-worked-example].

#### Local examples

**Contextual C example:**

```c
int EX_processItem(int *item, size_t size)
{
        int ret = EXIT_SUCCESS;

        if (item == (int *)(NULL))
        {
                ret = -EINVAL;
                goto function_output;
        }

        if (size == 0u)
        {
                ret = -EINVAL;
                goto function_output;
        }

function_output:
        return ret;
}
```

---

<a id="untrusted-input-validation"></a> <a id="cstyle-059"></a>

<a id="cstyle-059-untrusted-input-validation"></a>

### CSTYLE-059: Untrusted Input Validation

**Class:** CORRECTNESS. **Obligation:** project requirement.

Argument validation checks whether an API contract was respected. Untrusted input validation checks
whether data from outside the trust boundary is safe to use. Any value from file, network, IPC,
environment variables, command line, persistent storage, fuzzers, firmware blobs, corrupted
metadata, or external modules is untrusted. Validate untrusted values before:

- allocation
- indexing
- pointer arithmetic
- casting
- enum conversion
- state-machine transition
- arithmetic used to derive sizes, offsets, or capacities

**Failure scenarios:** [CPIT-042][c-common-pitfalls-cpit-042],
[CPIT-055][c-common-pitfalls-cpit-055], [CPIT-067][c-common-pitfalls-cpit-067],
[CPIT-083][c-common-pitfalls-cpit-083], [CPIT-089][c-common-pitfalls-cpit-089],
[CPIT-091][c-common-pitfalls-cpit-091], [CPIT-092][c-common-pitfalls-cpit-092],
[CPIT-093][c-common-pitfalls-cpit-093], [CPIT-094][c-common-pitfalls-cpit-094],
[CPIT-101][c-common-pitfalls-cpit-101], [CPIT-102][c-common-pitfalls-cpit-102],
[CPIT-104][c-common-pitfalls-cpit-104].

#### Local examples

**Contextual C example:**

```c
if (payload_size > MEM_PAYLOAD_MAX)
{
        ret = -EINVAL;
        goto function_output;
}
```

---

<a id="enum-range-validation"></a> <a id="cstyle-060"></a>

<a id="cstyle-060-enum-range-validation"></a>

### CSTYLE-060: Enum Range Validation

**Class:** CORRECTNESS. **Obligation:** project requirement.

Validate integer input against the actual allowed enum members before conversion. A range check
suffices only for a documented contiguous domain. Reject sentinel values, unknown flag bits, and
reserved protocol values. An enum object can carry values outside the intended business domain; its
C type is not an input-validation mechanism.

**Failure scenarios:** [CPIT-046][c-common-pitfalls-cpit-046],
[CPIT-054][c-common-pitfalls-cpit-054].

#### Local examples

**Noncompliant fragment (do not copy):**

```c
state = (mem_state_t)raw_value;
table[state]();
```

**Contextual C example:**

```c
if ((raw_value < 0) || (raw_value >= (int)MEM_STATE_MAX))
{
        ret = -EINVAL;
        goto function_output;
}

state = (mem_state_t)raw_value;
```

---

<a id="414-no-side-effects-in-conditions"></a> <a id="cstyle-061-no-side-effects-in-conditions"></a>
<a id="cstyle-061"></a>

<a id="cstyle-061-4-1-4-no-side-effects-in-conditions"></a>

### CSTYLE-061: No Side Effects in Conditions

**Class:** CORRECTNESS. **Obligation:** project requirement.

Keep assignments, increments, and state-changing calls out of `if` and loop conditions. Pure
predicates are allowed when their contract has no observable mutation. The initialization and
iteration clauses of `for` may assign and advance an index declared at function entry; they must not
declare a new one. Short-circuit guards may protect later reads. Do not separate a check and use in
a way that creates a concurrent race.

**Failure scenarios:** [CPIT-034][c-common-pitfalls-cpit-034],
[CPIT-035][c-common-pitfalls-cpit-035].

#### Local examples

**Noncompliant fragment (do not copy):**

```c
if ((ret = FILE_read(buffer, size)) != EXIT_SUCCESS)
{
    goto function_output;
}

while (index++ < size)
{
    EX_doSomething();
}
```

**Contextual C example:**

```c
ret = FILE_read(buffer, size);
if (ret != EXIT_SUCCESS)
        goto function_output;

while (index < size)
{
        EX_doSomething();
        index++;
}
```

---

<a id="415-const-parameters"></a> <a id="cstyle-062-const-parameters"></a> <a id="cstyle-062"></a>

<a id="cstyle-062-4-1-5-const-parameters"></a>

### CSTYLE-062: Const Parameters

**Class:** CORRECTNESS. **Obligation:** project requirement.

Use `const` on input parameters whenever the function does not modify the provided data.

- pointer parameters used only for reading must be declared with pointed-data `const`
- scalar parameters may be declared `const` when it improves local clarity
- do not omit `const` from read-only inputs without reason

- it makes the function contract explicit
- it prevents accidental writes to caller-owned input data
- it improves compiler diagnostics and review clarity

#### Local examples

**Contextual C example:**

```c
int FILE_writeBuffer(const uint8_t buffer[], size_t size);
int JSON_parse(const char input[], json_object_t *out);
```

---

<a id="416-output-buffer-contracts"></a> <a id="cstyle-063-output-buffer-contracts"></a>
<a id="cstyle-063"></a>

<a id="cstyle-063-4-1-6-output-buffer-contracts"></a>

### CSTYLE-063: Output Buffer Contracts

**Class:** CORRECTNESS. **Obligation:** project requirement.

A writable variable-length output needs a pointer and a declared capacity, passed as parameters or
as a specified span. Define bytes versus elements, written versus required length, termination,
overlap, and failure behavior. Check integer ranges before forming destination pointers. An output
pointer to one typed scalar or a fixed-layout DTO does not need a redundant byte capacity. A
documented size-zero/NULL no-op must avoid even zero-length libc calls with invalid pointers.

**Failure scenarios:** [CPIT-013][c-common-pitfalls-cpit-013],
[CPIT-029][c-common-pitfalls-cpit-029].

**Complete example:** [worked sources][c-code-standard-worked-example].

#### Local examples

**Contextual C example:**

```c
int PATH_build(char path[], size_t path_size);
int FRAME_encode(uint8_t buffer[], size_t buffer_size);
```

**Noncompliant fragment (do not copy):**

```c
int PATH_build(char path[]);
int FRAME_encode(uint8_t buffer[]);
```

---

<a id="417-return-convention"></a> <a id="cstyle-064-return-convention"></a> <a id="cstyle-064"></a>

<a id="cstyle-064-4-1-7-return-convention"></a>

### CSTYLE-064: Return Convention

**Class:** CORRECTNESS / ANALYZABILITY / PROJECT_STYLE. **Obligation:** project requirement.

Fallible project operations normally return `int`, with zero for success and a documented negative
errno-style error domain. Use out parameters for results. Declare `ret` first, initialize it to the
success value, and return it only at the final `function_output` label. Validation failures set
`ret` and jump to that label. Guard returns and other early returns are forbidden, including before
resource acquisition.

Use the same exit for cleanup. Initialize every resource variable before validation so cleanup can
distinguish acquired resources from empty handles. Release only acquired resources and preserve the
primary failure if cleanup also fails. Do not declare cleanup variables after the label.

Callbacks, interrupt handlers, and infallible accessors or predicates retain the return type
required by their contract. Value-returning functions use a `ret` variable of that type and the same
single normal exit. A void function ends with one `return;` under `function_output`; it does not
need a fictitious status. The return-type exception does not authorize early returns or hidden
failures. A function without another jump uses an explicit final `goto function_output` so the
common label is used. Fatal assertions in the declared host-test/debug profile are not normal
returns and are not a recoverable error mechanism.

**Source context:** [linux-style][c-common-pitfalls-ref-linux-style].

**Complete example:** [worked sources][c-code-standard-worked-example].

#### Local examples

**Contextual example:**

Function definition. Include <stddef.h>, <errno.h> and <stdlib.h>; declare the public function in
its own header. A nonzero count is the complete input contract.

```c
int SAMPLE_validateCount(size_t count)
{
        int ret = EXIT_SUCCESS;

        if (count == 0u)
        {
                ret = -EINVAL;
                goto function_output;
        }

function_output:
        return ret;
}
```

---

<a id="418-error-code-namespace"></a> <a id="cstyle-065-error-code-namespace"></a>
<a id="cstyle-065"></a>

<a id="cstyle-065-4-1-8-error-code-namespace"></a>

### CSTYLE-065: Error Code Namespace

**Class:** CORRECTNESS. **Obligation:** project requirement.

Give every error value a documented meaning and scope. Negative POSIX-style names may be used in a
POSIX adapter, but do not assume their numeric values are a portable serialized or cross-platform
contract. The example uses its own fixed negative status values. Map foreign errors once at an
adapter boundary. Do not use global `errno` as the implicit error channel of a reusable project API.

**Complete example:** [worked sources][c-code-standard-worked-example].

#### Local examples

**Contextual C example:**

```c
typedef enum NetRet
{
        NET_RET_SUCCESS        = (int)(EXIT_SUCCESS),
        NET_RET_INVALID_ARG    = (int)(-EINVAL),
        NET_RET_IO             = (int)(-EIO),
        NET_RET_BACKEND_FAILED = (int)(-EFAULT)
} net_ret_t;
```

---

<a id="419-error-propagation"></a> <a id="cstyle-066-error-propagation"></a> <a id="cstyle-066"></a>

<a id="cstyle-066-4-1-9-error-propagation"></a>

### CSTYLE-066: Error Propagation

**Class:** CORRECTNESS. **Obligation:** project requirement.

Check fallible results before using outputs or committing state. Preserve the primary operation
error when cleanup also fails; retain the cleanup error in diagnostics when needed. Define
partial-write and retry behavior explicitly. Ignoring a result requires a stated reason, such as
best-effort diagnostics on an already fatal host-test path. Never discard a security decision's
result.

**Failure scenarios:** [CPIT-055][c-common-pitfalls-cpit-055],
[CPIT-068][c-common-pitfalls-cpit-068], [CPIT-083][c-common-pitfalls-cpit-083],
[CPIT-087][c-common-pitfalls-cpit-087].

**Source context:** [linux-style][c-common-pitfalls-ref-linux-style].

**Complete example:** [worked sources][c-code-standard-worked-example].

#### Local examples

**Contextual C example:**

```c
ret = NETWORK_sendPacket(packet);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

**Noncompliant fragment (do not copy):**

```c
NETWORK_sendPacket(packet);
```

---

<a id="4110-logging-and-assertions"></a> <a id="cstyle-067-logging-and-assertions"></a>
<a id="cstyle-067"></a>

<a id="cstyle-067-4-1-10-logging-and-assertions"></a>

### CSTYLE-067: Logging and Assertions

**Class:** SECURITY. **Obligation:** project requirement.

Use runtime validation for external input and recoverable operational failures. Assertions document
internal invariants and must have no side effects; they may be removed by a release build. A library
must not terminate the process unless its documented fatal policy explicitly permits it. Logs must
preserve useful error identity without exposing secrets, uninitialized bytes, or private addresses.
Host-test termination is a separate, explicit test profile.

**Failure scenarios:** [CPIT-093][c-common-pitfalls-cpit-093],
[CPIT-097][c-common-pitfalls-cpit-097], [CPIT-105][c-common-pitfalls-cpit-105],
[CPIT-119][c-common-pitfalls-cpit-119].

**Source context:** [logging][c-common-pitfalls-ref-logging].

#### Local examples

**Contextual C example:**

```c
assert(buffer != (uint8_t *)(NULL));

ret = STORAGE_read(block_id, data);
if (ret != EXIT_SUCCESS)
{
        LOG_ERROR("STORAGE_read failed: block_id=%u ret=%d", block_id, ret);
        goto function_output;
}
```

**Noncompliant fragment (do not copy):**

```c
assert(STORAGE_read(block_id, data) == EXIT_SUCCESS);
```

---

<a id="format-string-safety"></a> <a id="cstyle-068"></a>

<a id="cstyle-068-format-string-safety"></a>

### CSTYLE-068: Format String Safety

**Class:** SECURITY. **Obligation:** project requirement.

Keep format strings trusted and match every variadic argument to its required type. Use the standard
integer format macros where appropriate and `%zu` for `size_t`. For bounded formatting, handle
negative status separately from output that would not fit. A size parameter does not guarantee a
complete result. Configure compiler format checking for wrappers when the toolchain supports it.

**Failure scenarios:** [CPIT-055][c-common-pitfalls-cpit-055],
[CPIT-061][c-common-pitfalls-cpit-061], [CPIT-062][c-common-pitfalls-cpit-062],
[CPIT-093][c-common-pitfalls-cpit-093], [CPIT-095][c-common-pitfalls-cpit-095].

**Source context:** [logging][c-common-pitfalls-ref-logging].

#### Local examples

**Noncompliant fragment (do not copy):**

```c
printf(user_input);
MEM_log(level, user_input);
```

**Contextual C example:**

```c
if (user_input == (const char *)(NULL))
{
        ret = -EINVAL;
        goto function_output;
}

ret = MEM_log(level, "%s", user_input);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

**Contextual C example:**

```c
MEM_ATTR_PRINTF__(2, 3)
int MEM_log(mem_log_level_t level, const char format[], ...);
```

---

<a id="analyzability"></a> <a id="cstyle-069"></a>

<a id="cstyle-069-analyzability"></a>

### CSTYLE-069: Analyzability

**Class:** ANALYZABILITY. **Obligation:** project requirement.

Write a control in terms a reviewer or tool can evaluate: scope, precondition, required action, and
failure outcome. Identify checks that need human reasoning. A token search is evidence only for the
syntax it recognizes; it is not proof of ownership, authorization, lifetime, or race freedom. Record
what the test or analyzer exercised instead of marking all related controls verified.

**Failure scenarios:** [CPIT-030][c-common-pitfalls-cpit-030].

**Source context:** [asan][c-common-pitfalls-ref-asan]; [ubsan][c-common-pitfalls-ref-ubsan].

#### Local examples

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Use good judgment with pointers.
```

**Layout example (not executable):**

```text
Every public function that writes to a caller-provided buffer shall receive
a non-NULL buffer pointer and a size parameter.
```

---

<a id="4111-module-specific-return-types"></a> <a id="cstyle-070-module-specific-return-types"></a>
<a id="cstyle-070"></a>

<a id="cstyle-070-4-1-11-module-specific-return-types"></a>

### CSTYLE-070: Module-Specific Return Types

**Class:** CORRECTNESS. **Obligation:** project requirement.

A module-specific status typedef includes `ret` in its name and keeps the zero-success,
negative-error convention. Its implementation declares `ret` of that type first and returns it
through `function_output`.

Callbacks, interrupt handlers, and infallible accessors or predicates may use the exact return type
required by their contract under CSTYLE-064. This changes the result type, not the single-exit
discipline. Do not cast a function pointer to evade signature compatibility.

#### Local examples

**Contextual C example:**

```c
typedef enum FileOpRet
{
        FILE_OP_RET_SUCCESS      = (int)(EXIT_SUCCESS),
        FILE_OP_RET_INVALID_PATH = (int)(-EINVAL),
        FILE_OP_RET_IO_ERROR     = (int)(-EIO)
} file_op_ret_t;

file_op_ret_t FILE_openFile(const char path[])
{
        file_op_ret_t ret = FILE_OP_RET_SUCCESS;

        if (path == (const char *)(NULL))
        {
                ret = FILE_OP_RET_INVALID_PATH;
                goto function_output;
        }

function_output:
        return ret;
}
```

---

<a id="4112-callback-contracts"></a> <a id="cstyle-071-callback-contracts"></a>
<a id="cstyle-071"></a>

<a id="cstyle-071-4-1-12-callback-contracts"></a>

### CSTYLE-071: Callback Contracts

**Class:** ARCHITECTURE / CORRECTNESS. **Obligation:** project requirement.

A callback contract specifies its exact signature, context owner, invocation thread, lifetime,
nullability, borrowed arguments, output capacities, allocation, blocking, reentrancy, errors,
partial side effects, cancellation, and teardown. The table may be copied while its context remains
borrowed. Unbinding does not release context until new invocations are excluded and in-flight calls
finish. Runtime replacement requires synchronization. Do not hold an internal lock across unknown
callback code without a reviewed locking contract.

**Failure scenarios:** [CPIT-026][c-common-pitfalls-cpit-026],
[CPIT-032][c-common-pitfalls-cpit-032].

#### Local examples

**Contextual C example:**

```c
typedef int (*send_cb_t)(void *context, const uint8_t *data, size_t size_bytes);
/* Contract documents ownership, blocking, and reentrancy. */
```

**Noncompliant fragment (do not copy):**

```c
typedef void (*cb_t)(); /* argument types and error contract unspecified */
```

---

<a id="4113-boolean-expression-simplification"></a>
<a id="cstyle-072-boolean-expression-simplification"></a> <a id="cstyle-072"></a>

<a id="cstyle-072-4-1-13-boolean-expression-simplification"></a>

### CSTYLE-072: Boolean Expression Simplification

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

To reduce cognitive complexity, simplify boolean conditions whenever doing so improves clarity.

- apply De Morgan’s laws when helpful
- remove double negations
- eliminate redundant terms
- factor common terms
- prefer readable intermediate booleans for long expressions

#### Local examples

**Contextual C example:**

```c
if ((!is_ready) || (!is_valid))
        EX_handleError();

if (flag)
        EX_doSomething();

if (is_enabled && (has_input || has_backup_input))
        EX_doSomething();
```

---

<a id="4114-boolean-naming-semantics"></a> <a id="cstyle-073-boolean-naming-semantics"></a>
<a id="cstyle-073"></a>

<a id="cstyle-073-4-1-14-boolean-naming-semantics"></a>

### CSTYLE-073: Boolean Naming Semantics

**Class:** PROJECT_STYLE. **Obligation:** project requirement.

Prefer boolean names that describe the active or allowed condition directly.

- prefer positive boolean names such as `is_running`, `is_valid`, and `can_process`
- avoid negative names that force readers to mentally invert the condition
- avoid double-negation style logic in `if` and `while` when a positive form is available
- do not mix positive and negative boolean semantics in the same condition unless there is a strong
  reason

- positive boolean names are easier to read in control flow
- they reduce mental inversion during reviews
- they help prevent mistakes when conditions become larger over time

#### Local examples

**Contextual example:**

Function-body fragment. ret is declared first, `is_running` at entry. The injected step callback
must obey the execution budget and eventually clear `is_running` or fail; the name alone does not
establish progress.

```c
bool is_running = false;

/* After validating the operation and its bounded execution budget. */
is_running = true;
while (is_running)
{
        ret = step(step_context, &is_running);
        if (ret != EXIT_SUCCESS)
                goto function_output;
}
```

---

<a id="4115-loop-control"></a> <a id="cstyle-074-loop-control"></a> <a id="cstyle-074"></a>

<a id="cstyle-074-4-1-15-loop-control"></a>

### CSTYLE-074: Loop Control

**Class:** CORRECTNESS / ANALYZABILITY / PROJECT_STYLE. **Obligation:** project requirement.

Do not use `break` or `continue` to alter iteration control. Express normal termination and
iteration selection through the loop condition and explicit state. Declare loop variables at
function entry. A failure may jump forward to `function_output`, which remains the function's only
normal return path. `break` is permitted to terminate a `switch` case; that is not an exception for
breaking out of an enclosing loop.

Every finite operation needs a bound or a progress argument. A service loop may run indefinitely
only with a documented shutdown and scheduling policy. Safety-critical and externally driven loops
need work/time budgets and a defined response when the budget is exhausted. Recursion requires an
applicable profile and a justified maximum depth; it is forbidden in the hard-real-time profile.

**Related controls:** [CSTYLE-075][c-code-standard-cstyle-075].

**Failure scenarios:** [CPIT-016][c-common-pitfalls-cpit-016],
[CPIT-034][c-common-pitfalls-cpit-034], [CPIT-046][c-common-pitfalls-cpit-046],
[CPIT-068][c-common-pitfalls-cpit-068], [CPIT-083][c-common-pitfalls-cpit-083].

#### Local examples

**Contextual example:**

Function-body fragment. All declarations are at function entry; matches is an injected infallible
predicate. The loop uses its condition, not break or continue, to stop.

```c
size_t index = 0u;

bool keep_searching = false;

/* After validating items, size, and the required predicate callback. */
keep_searching = true;
for (index = 0u; (index < item_count) && keep_searching; index++)
{
        keep_searching = !matches(match_context, &items[index]);
}
```

---

<a id="4116-switch-statements"></a> <a id="cstyle-075-switch-statements"></a>
<a id="cstyle-075"></a>

<a id="cstyle-075-4-1-16-switch-statements"></a>

### CSTYLE-075: Switch Statements

**Class:** CORRECTNESS. **Obligation:** project requirement.

Handle every valid state and reject invalid states. Use a `default` for untrusted or extensible
inputs; enable an enum-exhaustiveness diagnostic as well where supported. Each nonempty case
terminates explicitly unless deliberate fallthrough is documented with the selected dialect's
supported annotation. Do not use `default` to hide newly added enum states from review.

#### Local examples

**Contextual C example:**

```c
switch (state)
{
case STATE_IDLE:
        break;

case STATE_RUNNING:
        break;

default:
        ret = -EINVAL;
        goto function_output;
}
```

**Noncompliant fragment (do not copy):**

```c
switch (state)
{
case STATE_IDLE:
    EX_prepareState();

case STATE_RUNNING:
    EX_runState();
    break;
}
```

---

<a id="4117-function-argument-evaluation-order"></a> <a id="cstyle-116"></a>

<a id="cstyle-116-4-1-17-function-argument-evaluation-order"></a>

### CSTYLE-116: Function Argument Evaluation Order

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-035: Unsequenced modification][c-common-pitfalls-cpit-035]

Function arguments must not depend on their evaluation order. A function call must not modify an
object in one argument and read or modify the same object in another argument.

Prefer separate statements whose order is visible:

#### Local examples

**Noncompliant fragment (do not copy):**

```c
EX_useValues(index++, index);
EX_processItems(items[index++], items[index]);
```

**Contextual C example:**

```c
size_t current_index = 0u;

current_index = index;
index++;

EX_useValues(current_index, index);
```

---

<a id="4118-output-parameter-initialization-contracts"></a> <a id="cstyle-117"></a>

<a id="cstyle-117-4-1-18-output-parameter-initialization-contracts"></a>

### CSTYLE-117: Output Parameter Initialization Contracts

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-036: Indeterminate value read][c-common-pitfalls-cpit-036]
- [CPIT-012: Uninitialized pointer][c-common-pitfalls-cpit-012]

Every out-parameter contract must state whether the function defines the output on every return or
only on success. Unless an API requires another sentinel, initialize pointer outputs to typed `NULL`
immediately after validating the out-parameter itself.

Avoid an output whose value after failure is unspecified:

#### Local examples

**Contextual C example:**

```c
int ITEM_create(item_t **item_out)
{
        int ret = EXIT_SUCCESS;

        item_t *item = (item_t *)(NULL);

        if (item_out == (item_t **)(NULL))
        {
                ret = -EINVAL;
                goto function_output;
        }

        *item_out = (item_t *)(NULL);

        item = (item_t *)malloc(sizeof(*item));
        if (item == (item_t *)(NULL))
        {
                ret = -ENOMEM;
                goto function_output;
        }

        *item     = (item_t){ 0 };
        *item_out = item;
        item      = (item_t *)(NULL);

function_output:
        free(item);

        return ret;
}
```

**Noncompliant fragment (do not copy):**

```c
int ITEM_find(item_t **item_out, item_t *item, bool is_found)
{
    int ret = EXIT_SUCCESS;

    if (item_out == (item_t **)(NULL))
    {
        ret = -EINVAL;
        goto function_output;
    }

    if (is_found)
    {
        *item_out = item;
    }
    else
    {
        ret = -EINVAL;
    }

function_output:
    return ret;
}
```

---

<a id="4119-array-parameter-notation"></a> <a id="cstyle-131"></a>

<a id="cstyle-131-4-1-19-array-parameter-notation"></a>

### CSTYLE-131: Array Parameter Notation

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-029: Array-to-pointer decay][c-common-pitfalls-cpit-029]
- [CPIT-013: Out-of-bounds write][c-common-pitfalls-cpit-013]
- [CPIT-014: Out-of-bounds read][c-common-pitfalls-cpit-014]

A parameter that represents the first element of an array must use array notation. Use pointer
notation for a pointer to one object, an optional object, an opaque handle, or another contract that
is not an array.

Avoid hiding an array contract behind pointer notation:

In a function parameter, `type array[]` still adjusts to a pointer type. Array notation communicates
intent but does not carry capacity; the function must also receive the element count, byte size, or
an explicitly sized array type.

#### Local examples

**Contextual C example:**

```c
int EX_sumValues(const int values[], size_t value_count);
int EX_updateValue(int *value);
```

**Noncompliant fragment (do not copy):**

```c
int EX_sumValues(const int *values, size_t value_count);
```

---

<a id="4120-variadic-function-policy"></a> <a id="cstyle-132"></a>

<a id="cstyle-132-4-1-20-variadic-function-policy"></a>

### CSTYLE-132: Variadic Function Policy

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-129: Variadic argument contract mismatch][c-common-pitfalls-cpit-129]
- [CPIT-095: Format string injection][c-common-pitfalls-cpit-095]
- [CPIT-061: `printf` external format string][c-common-pitfalls-cpit-061]

Variadic functions are prohibited in ordinary module APIs. A controlled formatting, logging,
tracing, or foreign-interface adapter may use `...` when a fixed typed API cannot express the
required contract.

An approved variadic function must:

- call `va_start()` before reading arguments and `va_end()` on every path
- use `va_copy()` before duplicating or independently traversing a `va_list`
- define how the callee determines every argument's promoted type
- apply a compiler format attribute when the arguments follow a format string
- reject external input as a format string
- transfer no ownership implicitly and retain no variadic pointer argument

Prefer a small wrapper around a typed `va_list` adapter:

Do not use `...` as a general optional-argument or type-dispatch mechanism.

#### Local examples

**Contextual C example:**

```c
MEM_ATTR_PRINTF__(2, 3)

int MEM_log(mem_log_level_t level, const char format[], ...)
{
        int ret = EXIT_SUCCESS;

        va_list args;

        if (format == (const char *)(NULL))
        {
                ret = -EINVAL;
                goto function_output;
        }

        va_start(args, format);
        ret = MEM_logV(level, format, args);
        va_end(args);

function_output:
        return ret;
}
```

---

<a id="4121-conditional-operator"></a> <a id="cstyle-133"></a>

<a id="cstyle-133-4-1-21-conditional-operator"></a>

### CSTYLE-133: Conditional Operator

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-130: Control flow hidden in an expression][c-common-pitfalls-cpit-130]
- [CPIT-035: Unsequenced modification][c-common-pitfalls-cpit-035]

The conditional operator may select a value. Its condition and result operands must have no side
effects, and neither result operand may contain another conditional operator.

Prefer a compact value selection:

Use an `if` statement when either path performs work:

#### Local examples

**Contextual C example:**

```c
maximum = (value_a > value_b) ? value_a : value_b;
```

**Contextual C example:**

```c
result = is_ready     ? EX_processItem(item)
         : use_backup ? EX_processBackup(item)
                      : -EINVAL;
```

---

<a id="4122-comma-operator"></a> <a id="cstyle-134"></a>

<a id="cstyle-134-4-1-22-comma-operator"></a>

### CSTYLE-134: Comma Operator

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-130: Control flow hidden in an expression][c-common-pitfalls-cpit-130]
- [CPIT-035: Unsequenced modification][c-common-pitfalls-cpit-035]

The comma operator is prohibited, including in a `for` iteration expression. This rule does not
prohibit commas that separate function arguments, declarations, initialization elements, or enum
constants.

Use separate statements and one explicit loop-control variable.

#### Local examples

**Noncompliant fragment (do not copy):**

```c
value = (EX_prepare(), EX_readValue());

for (index = 0u; index < count; index++, output_index++)
{
    output[output_index] = input[index];
}
```

---

<a id="4123-errno-handling"></a> <a id="cstyle-135"></a>

<a id="cstyle-135-4-1-23-errno-handling"></a>

### CSTYLE-135: `errno` Handling

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-131: Stale or overwritten `errno`][c-common-pitfalls-cpit-131]
- [CPIT-068: Ignored return value][c-common-pitfalls-cpit-068]

Read `errno` only after an API reports failure through its documented return value. Capture it
immediately, before logging, cleanup, allocation, or another library call can change it.

Rules:

- do not assume `errno == 0` after success
- do not treat `errno` as a failure indicator without first checking the API result
- reset `errno` before a call only when that API's contract requires it to distinguish a valid
  result from failure
- convert the captured value to the module's error domain at the external dependency boundary
- preserve the captured value when cleanup or logging must run first

#### Local examples

**Contextual C example:**

```c
FILE *file        = (FILE *)(NULL);
int   saved_errno = 0;

file = fopen(path, "rb");
if (file == (FILE *)(NULL))
{
        saved_errno = errno;
        ret         = ERRNO_toFileRet(saved_errno);
        goto function_output;
}
```

---

<a id="4124-action-and-predicate-semantics"></a> <a id="cstyle-146"></a>

<a id="cstyle-146-4-1-24-action-predicate-semantics"></a>

### CSTYLE-146: Action and Predicate Semantics

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

A function name and return type must express the same semantic category.

- an action or command such as `MODULE_start`, `MODULE_write`, or `MODULE_reset` returns the module
  status or documented result value
- a predicate such as `MODULE_isReady`, `MODULE_hasData`, or `MODULE_canWrite` returns `bool`
- a status-returning action must not use `bool` to collapse distinct failures
- a predicate must not perform an externally visible state transition

Do not name a fallible action as if it were a query or return an error code from a name that callers
naturally use as a condition.

#### Local examples

**Contextual C example:**

```c
int DEVICE_start(device_t *device);

bool DEVICE_isReady(const device_t *device);
```

**Noncompliant fragment (do not copy):**

```c
bool DEVICE_start(device_t *device);
int DEVICE_isReady(const device_t *device);
```

---

<a id="4125-callback-validation-before-invocation"></a> <a id="cstyle-147"></a>

<a id="cstyle-147-4-1-25-callback-validation-before-invocation"></a>

### CSTYLE-147: Callback Validation Before Invocation

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-138: Invalid callback invocation][c-common-pitfalls-cpit-138]
- [CPIT-026: Function pointer type mismatch][c-common-pitfalls-cpit-026]

Validate a function or callback pointer before invocation. Prefer validating all mandatory callbacks
once at create or bind time, then record the invariant that a successfully bound object contains
valid mandatory operations.

At a nullable invocation boundary, name and validate the callback explicitly:

The callback contract must also satisfy `CSTYLE-071` and the lifetime, reentrancy, blocking,
ownership, and error rules of the owning port.

#### Local examples

**Contextual C example:**

```c
send_cb_t send = (send_cb_t)(NULL);

if (callbacks == (const callbacks_t *)(NULL))
{
        ret = -EINVAL;
        goto function_output;
}

send = callbacks->send;
if (send == (send_cb_t)(NULL))
{
        ret = -EINVAL;
        goto function_output;
}

ret = send(callbacks->context, data, data_size);
```

---

<a id="4126-recursion-policy"></a> <a id="cstyle-148"></a>

<a id="cstyle-148-4-1-26-recursion-policy"></a>

### CSTYLE-148: Recursion Policy

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-045: Recursive function without bound][c-common-pitfalls-cpit-045]
- [CPIT-115: Unbounded resource consumption][c-common-pitfalls-cpit-115]

Recursion is prohibited by default in production code. An approved deviation must prove and
document:

- a finite maximum call depth for every accepted input;
- termination and cycle handling;
- stack bytes per level and total stack budget;
- worst-case execution-time effect;
- behavior when the depth limit is reached.

Use an explicit bounded worklist or loop when it makes stack and progress state visible. Tests and
host tools may use recursion only under the same resource budget discipline.

#### Local examples

**Contextual C example:**

```c
while (node != (node_t *)(NULL))
{
        node = node->next;
}
```

**Noncompliant fragment (do not copy):**

```c
int walk(node_t *node)
{
    return node == NULL ? 0 : walk(node->next); /* no static depth bound */
}
```

---

<a id="4127-nonlocal-control-flow"></a> <a id="cstyle-149"></a>

<a id="cstyle-149-4-1-27-nonlocal-control-flow"></a>

### CSTYLE-149: Nonlocal Control Flow

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-043: `longjmp` into dead frame][c-common-pitfalls-cpit-043]
- [CPIT-044: Modified non-volatile local after `setjmp`][c-common-pitfalls-cpit-044]

`setjmp` and `longjmp` are prohibited in ordinary project code. They bypass visible cleanup,
ownership transfer, SESE, local-lifetime reasoning, and normal error propagation.

An external dependency that requires nonlocal control flow must be isolated in an adapter. The
adapter must not jump across a project-owned frame and must translate control back into the module
error domain before returning.

#### Local examples

**Contextual C example:**

```c
ret = operation();
if (ret != EXIT_SUCCESS)
        goto function_output;
```

**Noncompliant fragment (do not copy):**

```c
if (setjmp(env) == 0)
{
    run();
}
/* longjmp may bypass cleanup */
```

---

<a id="4128-compiler-assumptions-and-unreachable-paths"></a> <a id="cstyle-150"></a>

<a id="cstyle-150-4-1-28-compiler-assumption-safety"></a>

### CSTYLE-150: Compiler Assumptions and Unreachable Paths

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-140: Unproved compiler assumption][c-common-pitfalls-cpit-140]
- [CPIT-120: Fail-open or sensitive error disclosure][c-common-pitfalls-cpit-120]

A compiler assumption, unreachable marker, or equivalent portability macro may encode only a
previously proved internal invariant. It must not:

- validate file, network, hardware, guest, user, or other external input;
- replace a recoverable error path;
- suppress a warning without a semantic proof;
- assert a state that concurrent execution can invalidate;
- make a safety or security check disappear in release builds.

LLVM distinguishes unreachable internal bugs from conditions caused by user input, which require
recoverable error handling.[llvm-coding-standards][llvm-coding-standards]

#### Local examples

**Contextual C example:**

```c
if (state >= STATE_MAX)
{
        ret = -EINVAL;
        goto function_output;
}

PROJECT_ASSUME__(state < STATE_MAX);
```

**Noncompliant fragment (do not copy):**

```c
if (state >= STATE_MAX)
{
    __builtin_unreachable(); /* state came from the network */
}
```

---

<a id="4129-must-check-fallible-results"></a> <a id="cstyle-151"></a>

<a id="cstyle-151-4-1-29-must-check-fallible-results"></a>

### CSTYLE-151: Must-Check Fallible Results

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

Mark a result with the project compiler adapter's must-check annotation when silently ignoring it
can lose ownership, integrity, authentication, persistence, or an essential state transition.

Typical candidates include allocation, persistent writes, transaction commits, security checks,
firmware update operations, fallible lock acquisition, and resource transfer. Do not annotate every
integer-returning function; the marker must communicate a material obligation.

The annotation supplements normal review and error propagation. A cast to `void` must not silence a
must-check result without an approved, documented reason.

#### Local examples

**Contextual C example:**

```c
APP_MUST_CHECK__
int STORAGE_commit(storage_t *storage);
```

---

<a id="421-partial-and-interrupted-io"></a> <a id="cstyle-163"></a>

<a id="cstyle-163-4-2-1-partial-and-interrupted-io"></a>

### CSTYLE-163: Partial and Interrupted I/O

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-147: Partial I/O is treated as complete][c-common-pitfalls-cpit-147]
- [CPIT-148: Interrupted I/O loses progress or retry policy][c-common-pitfalls-cpit-148]

An I/O call that accepts a byte count must have an explicit completion contract. Code must
distinguish full progress, partial progress, end of input, temporary unavailability, interruption
before progress, permanent failure, and cancellation or deadline expiry when those outcomes exist.

Rules:

- advance the buffer and remaining extent only by the reported positive count;
- never assume that one successful call transferred the requested extent;
- retry `EINTR` only when the API contract permits it and no cancellation or deadline policy has
  superseded the operation;
- preserve progress already reported before an interruption or later failure;
- treat a zero result according to the exact API and object type, not as a universal retry signal;
- keep retry, readiness, cancellation, and timeout policy inside the owning I/O adapter rather than
  duplicating loops at call sites.

POSIX explicitly permits partial writes and defines interruption behavior that can return either
transferred bytes or `EINTR` before progress.[posix-write][posix-write] [posix-read][posix-read]

#### Local examples

**Contextual example:**

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

<a id="422-durations-and-deadlines-use-a-monotonic-time-domain"></a> <a id="cstyle-168"></a>

<a id="cstyle-168-4-2-2-monotonic-duration-deadline"></a>

### CSTYLE-168: Durations and Deadlines Use a Monotonic Time Domain

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-151: Wall-clock changes corrupt duration or deadline logic][c-common-pitfalls-cpit-151]

Elapsed-time measurement, retry budgets, leases, watchdog windows, and relative deadlines must use a
project monotonic-clock abstraction. Calendar time may be used for timestamps and externally
specified civil-time events, but must not be subtracted to enforce a duration.

The time contract must state units, resolution, wrap behavior, maximum interval, comparison method,
and whether suspend time is included. Deadline arithmetic must use checked or wrap-safe helpers for
the represented clock domain. Do not mix values from wall-clock, monotonic, CPU-time, device, or
simulation clocks.

POSIX defines the monotonic clock so clock setting cannot move its origin and notes that interval
measurements using it are not affected by wall-clock
updates.[posix-monotonic-clock][posix-monotonic-clock]

#### Local examples

**Contextual example:**

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

<a id="423-descriptor-and-handle-ownership-includes-inheritance"></a> <a id="cstyle-172"></a>

<a id="cstyle-172-4-2-3-descriptor-handle-ownership-inheritance"></a>

### CSTYLE-172: Descriptor and Handle Ownership Includes Inheritance

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-168: Descriptor or handle leaks across an execution boundary][c-common-pitfalls-cpit-168]

A platform profile that exposes file descriptors, sockets, pipes, process handles, or equivalent
kernel resources must define one owner, one close path, and one inheritance policy for each handle.
A handle intended only for the current process must receive its close-on-exec or non-inheritable
property in the same operation that creates the handle when the platform provides an atomic creation
flag.

On Linux and POSIX profiles, use `O_CLOEXEC`, `SOCK_CLOEXEC`, `pipe2()` or the corresponding
creation-time mechanism instead of a later `fcntl()` step when a concurrent `fork()` and `execve()`
can occur. Linux documents the race created by setting `FD_CLOEXEC` in a separate
operation.[linux-open-cloexec][linux-open-cloexec]

A platform adapter may use the native API:

Noncompliant creation sequence:

The second sequence exposes a window in which another thread can fork and exec with the descriptor
still inheritable.

#### Local examples

**Contextual example:**

Linux platform-adapter function: include <fcntl.h>, <errno.h>, <stdlib.h> and the owning internal
header. PLATFORM_errorFromErrno must return a nonzero project error for this failure. Success
transfers the descriptor to the caller; no later operation in this function can fail. On error,
`fd_out` is unchanged. No zero-valued descriptor is closed during failed validation.

```c
static int platform_openConfig(const char *path, int *fd_out)
{
        int ret = EXIT_SUCCESS;
        int fd  = 0;

        if ((path == (const char *)(NULL)) || (fd_out == (int *)(NULL)))
        {
                ret = -EINVAL;
                goto function_output;
        }

        fd = open(path, O_RDONLY | O_CLOEXEC);
        if (fd < 0)
        {
                ret = PLATFORM_errorFromErrno(errno);
                goto function_output;
        }

        *fd_out = fd;

function_output:
        return ret;
}
```

---

<a id="424-persistent-multi-write-updates-need-crash-consistency"></a> <a id="cstyle-173"></a>

<a id="cstyle-173-4-2-4-persistent-crash-consistency"></a>

### CSTYLE-173: Persistent Multi-Write Updates Need Crash Consistency

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-169: Power loss exposes a partially committed persistent update][c-common-pitfalls-cpit-169]

A persistent state transition that spans more than one storage write must define its atomicity,
durability, and recovery protocol. The owner must account for power loss, reset, short writes,
reordered writes, failed flushes, and torn storage units supported by the medium.

The protocol must identify the commit point and recovery rule. Approved designs may use A/B slots, a
journal, write-ahead logging, copy-on-write state, a commit marker, or another mechanism with
equivalent evidence. SQLite tests atomic commit by injecting incomplete, reordered, and corrupted
writes around simulated power loss.[sqlite-atomic-commit][sqlite-atomic-commit]

Compliant transaction shape:

Noncompliant in-place update:

A reset between those writes can expose a state that never existed as a valid configuration.

#### Local examples

**Contextual C example:**

```c
int CONFIG_commit(const config_image_t *image)
{
        int ret = EXIT_SUCCESS;

        uint32_t generation = 0u;

        if (image == (const config_image_t *)(NULL))
        {
                ret = -EINVAL;
                goto function_output;
        }

        ret = STORAGE_nextGeneration(&generation);
        if (ret != EXIT_SUCCESS)
                goto function_output;

        ret = STORAGE_writeStagingImage(image, generation);
        if (ret != EXIT_SUCCESS)
                goto function_output;

        ret = STORAGE_flushStagingImage();
        if (ret != EXIT_SUCCESS)
                goto function_output;

        ret = STORAGE_writeCommitRecord(generation);
        if (ret != EXIT_SUCCESS)
                goto function_output;

        ret = STORAGE_flushCommitRecord();

function_output:
        return ret;
}
```

**Noncompliant fragment (do not copy):**

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

<a id="51-memory-management"></a> <a id="cstyle-076-memory-management"></a> <a id="cstyle-076"></a>

<a id="cstyle-076-5-1-memory-management"></a>

### CSTYLE-076: Memory Management

**Class:** CORRECTNESS. **Obligation:** project requirement.

Apply allocation, bounds, lifetime, and ownership controls as one contract; none substitutes for the
others.

**Complete example:** [worked sources][c-code-standard-worked-example].

#### Local examples

**Contextual C example:**

```c
buffer = (uint8_t *)malloc(size_bytes);
if (buffer == (uint8_t *)(NULL))
{
        ret = -ENOMEM;
        goto function_output;
}

/* owner and cleanup path are explicit */
```

**Noncompliant fragment (do not copy):**

```c
buffer = (uint8_t *)malloc(size_bytes);
buffer[0] = 0u; /* allocation and ownership unchecked */
```

---

<a id="511-allocation-rules"></a> <a id="cstyle-077-allocation-rules"></a> <a id="cstyle-077"></a>

<a id="cstyle-077-5-1-1-allocation-rules"></a>

### CSTYLE-077: Allocation Rules

**Class:** CORRECTNESS. **Obligation:** project requirement.

Check every allocation result and establish exactly one ownership protocol. State whether allocation
is permitted, which family supplies it, what budget applies, and whether failure leaves prior state
unchanged. Initialization paths must unwind partially acquired resources. `calloc` supplies zero
bits, not a portable constructor for every pointer, floating value, or resource handle. Use semantic
initialization for such members.

**Failure scenarios:** [CPIT-004][c-common-pitfalls-cpit-004],
[CPIT-007][c-common-pitfalls-cpit-007].

**Source context:** [c23][c-common-pitfalls-ref-c23].

**Complete example:** [worked sources][c-code-standard-worked-example].

#### Local examples

**Contextual C example:**

```c
int *buffer = (int *)(NULL);

size_t alloc_size = 0u;

bool has_overflow = false;

has_overflow = ARITH_mulSize(count, sizeof(*buffer), &alloc_size);
if (has_overflow)
{
        ret = -ENOMEM;
        goto function_output;
}

buffer = (int *)malloc(alloc_size);
if (buffer == (int *)(NULL))
{
        ret = -ENOMEM;
        goto function_output;
}
```

---

<a id="512-cast-void--return-values"></a> <a id="cstyle-078-cast-void-pointer-return-values"></a>
<a id="cstyle-078"></a>

<a id="cstyle-078-5-1-2-cast-void-return-values"></a>

### CSTYLE-078: Cast `void *` Return Values

**Class:** PROJECT_STYLE / PORTABILITY / CORRECTNESS. **Obligation:** project requirement.

When a function returns `void *`, cast the result explicitly to the destination pointer type. This
applies to allocation functions and injected allocator callbacks. Conversions from an opaque
`void *` context to its concrete object-pointer type must also be explicit and remain inside the
adapter or callback implementation that owns the context contract.

For every explicit `NULL` initializer, assignment, comparison, argument, or pointer result, use the
corresponding pointer cast, such as `(buffer_t *)(NULL)` or `(const uint8_t *)(NULL)`. A null
callback uses its function-pointer typedef. Aggregate zero initialization under CSTYLE-107 does not
need one literal `NULL` per member.

These are mandatory project conventions. The cast does not establish alignment, lifetime, ownership,
or allocation size. Include the correct function prototype; never use a cast to hide a diagnostic.
`T **` is not interchangeable with `void **`, and object-pointer casts do not permit
function-pointer conversions.

**Source context:** [c23][c-common-pitfalls-ref-c23].

**Complete example:** [worked sources][c-code-standard-worked-example].

#### Local examples

**Contextual example:**

Function-body fragment. ret is declared first; declarations shown belong at function entry.
`allocation_bytes` is a validated nonzero allocation size. The owner releases buffer on every
required exit path; this fragment only illustrates the required conversion.

```c
int   *buffer           = (int *)(NULL);
size_t allocation_bytes = 0u;

/* After argument validation and checked size calculation. */
buffer = (int *)malloc(allocation_bytes);
if (buffer == (int *)(NULL))
{
        ret = -ENOMEM;
        goto function_output;
}
```

---

<a id="513-allocation-size-safety"></a> <a id="cstyle-079-allocation-size-safety"></a>
<a id="cstyle-079"></a>

<a id="cstyle-079-5-1-3-allocation-size-safety"></a>

### CSTYLE-079: Allocation Size Safety

**Class:** CORRECTNESS. **Obligation:** project requirement.

Derive allocation sizes with checked arithmetic before calling the allocator. Use `sizeof(*pointer)`
for the object or element, and include header, padding, alignment, and terminator costs where
applicable. Apply the product's budget after representability checks. Specify zero-count behavior. A
mathematically representable allocation can still be unaffordable or violate a real-time bound.

**Related controls:** [CSTYLE-052][c-code-standard-cstyle-052].

**Source context:** [c23][c-common-pitfalls-ref-c23].

**Complete example:** [worked sources][c-code-standard-worked-example].

#### Local examples

**Contextual C example:**

```c
item_t *ptr = (item_t *)(NULL);

size_t alloc_size = 0u;

bool has_overflow = false;

has_overflow = ARITH_mulSize(count, sizeof(*ptr), &alloc_size);
if (has_overflow)
{
        ret = -ENOMEM;
        goto function_output;
}

ptr = (item_t *)malloc(alloc_size);
if (ptr == (item_t *)(NULL))
{
        ret = -ENOMEM;
        goto function_output;
}
```

**Noncompliant fragment (do not copy):**

```c
ptr = malloc(sizeof(int) * count);
```

---

<a id="514-realloc-safety"></a> <a id="cstyle-080-realloc-safety"></a> <a id="cstyle-080"></a>

<a id="cstyle-080-5-1-4-realloc-safety"></a>

### CSTYLE-080: `realloc` Safety

**Class:** CORRECTNESS. **Obligation:** project requirement.

Handle zero size before any `realloc` call: either reject it or explicitly free and reset the owner,
as the API contract specifies. For positive sizes, store the result in a temporary and update
ownership only on success. Failure preserves the old allocation under the allocator contract. After
success, use only the returned base and newly derived aliases, even when its numeric address matches
the old one. Update size/capacity metadata only with the successful ownership transition. The
example fault-injects this path.

**Failure scenarios:** [CPIT-008][c-common-pitfalls-cpit-008].

**Source context:** [c23][c-common-pitfalls-ref-c23].

**Complete example:** [worked sources][c-code-standard-worked-example].

#### Local examples

**Contextual example:**

Function-body fragment. ret, buffer, replacement and `allocation_bytes` are declared at entry;
buffer already holds the owning base pointer after validation. `checked_size` is an approved
checked-multiplication callback. The zero-size branch intentionally implements release; a different
API may reject zero before calling `realloc`. On `realloc` failure the old allocation remains owned;
successful relocation invalidates prior aliases.

```c
int   *replacement      = (int *)(NULL);
size_t allocation_bytes = 0u;

/* After validating ownership and new_count. */
if (new_count == 0u)
{
        free(buffer);
        buffer = (int *)(NULL);
        goto function_output;
}

ret = checked_size(checked_context, new_count, sizeof(*buffer),
                   &allocation_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
replacement = (int *)realloc(buffer, allocation_bytes);
if (replacement == (int *)(NULL))
{
        ret = -ENOMEM;
        goto function_output;
}

buffer = replacement;
```

---

<a id="515-no-hidden-allocations"></a> <a id="cstyle-081-no-hidden-allocations"></a>
<a id="cstyle-081"></a>

<a id="cstyle-081-5-1-5-no-hidden-allocations"></a>

### CSTYLE-081: No Hidden Allocations

**Class:** CORRECTNESS. **Obligation:** project requirement.

Document allocation performed by an operation and by any callback it invokes. Caller-provided result
storage is preferred where it makes budgets predictable. An out parameter does not prove that a
parser or callback makes no allocations. A no-allocation profile must inspect the transitive call
path and measure or instrument the implementation; a function name or signature is insufficient.

**Failure scenarios:** [CPIT-083][c-common-pitfalls-cpit-083],
[CPIT-093][c-common-pitfalls-cpit-093].

**Complete example:** [worked sources][c-code-standard-worked-example].

#### Local examples

**Contextual C example:**

```c
int JSON_parse(const char input[], json_object_t *out);
```

**Noncompliant fragment (do not copy):**

```c
json_object_t *JSON_parse(const char input[]);
```

---

<a id="516-ownership-rules"></a> <a id="cstyle-082-ownership-rules"></a> <a id="cstyle-082"></a>

<a id="cstyle-082-5-1-6-ownership-rules"></a>

### CSTYLE-082: Ownership Rules

**Class:** ARCHITECTURE / CORRECTNESS. **Obligation:** project requirement.

Document the owner, allocator family, release authority, validity interval, nullability, and
aliasing rules of every exposed pointer. Distinguish borrowing from transfer. A copied pointer is
not a copied object or an ownership transfer. Refcount, arena, pool, and GC lifetimes require their
own protocols. Clearing one released handle is useful hygiene but does not invalidate or repair
other aliases. Moveable objects need registered references or a supported pinning contract.

**Failure scenarios:** [CPIT-002][c-common-pitfalls-cpit-002],
[CPIT-003][c-common-pitfalls-cpit-003], [CPIT-005][c-common-pitfalls-cpit-005],
[CPIT-009][c-common-pitfalls-cpit-009], [CPIT-031][c-common-pitfalls-cpit-031].

**Complete example:** [worked sources][c-code-standard-worked-example].

#### Local examples

**Contextual C example:**

```c
/*
 * On success, the caller owns *buffer_out and must free it.
 */
int UTIL_createBuffer(size_t size, char **buffer_out);

/*
 * The buffer is owned by the module and must not be freed.
 */
const char *CONFIG_getPath(void);
```

---

<a id="517-caller-owned-dtos"></a> <a id="cstyle-083-caller-owned-dtos"></a> <a id="cstyle-083"></a>

<a id="cstyle-083-5-1-7-caller-owned-dtos"></a>

### CSTYLE-083: Caller-Owned DTOs

**Class:** ARCHITECTURE / CORRECTNESS. **Obligation:** project requirement.

Let the operation owner supply result DTOs and buffers when that makes capacity and lifetime
explicit. Do not force every internal temporary into the highest caller; keep transient working
state near its use. Publicly shareable DTO layout is an intentional value contract, not permission
to expose or embed a peer module's private context. Distinguish in-process and wire DTOs.

**Complete example:** [worked sources][c-code-standard-worked-example].

#### Local examples

**Contextual C example:**

```c
reply_t reply = { 0 };
ret           = SERVICE_call(request, &reply);
```

**Noncompliant fragment (do not copy):**

```c
reply_t *reply = SERVICE_call(request); /* ownership/allocation hidden */
```

---

<a id="518-local-memory-lifetime"></a> <a id="cstyle-084-local-memory-lifetime"></a>
<a id="cstyle-084"></a>

<a id="cstyle-084-5-1-8-local-memory-lifetime"></a>

### CSTYLE-084: Local Memory Lifetime

**Class:** CORRECTNESS. **Obligation:** project requirement.

Keep automatic objects within their lifetime and prevent references to them from escaping that
interval. A heap object may borrow an automatic object only when its use ends before that object's
lifetime ends and the contract permits it. For longer retention, copy the data or retain a
separately owned object.

Automatic variables are declared at function entry under CSTYLE-107. Narrow resource use through
explicit ownership and smaller functions, not declarations inside a nested block or loop. Initialize
every cleanup-owned resource before validation and never read an object whose initialization could
be bypassed.

**Failure scenarios:** [CPIT-001][c-common-pitfalls-cpit-001],
[CPIT-033][c-common-pitfalls-cpit-033].

**Source context:** [c23][c-common-pitfalls-ref-c23].

**Complete example:** [worked sources][c-code-standard-worked-example].

#### Local examples

**Noncompliant fragment (do not copy):**

```c
char *UTIL_getBuffer(void)
{
    char *ret = (char *)(NULL);
    char buffer[128] = { 0 };

    ret = buffer;

function_output:
    return ret;
}
```

**Contextual C example:**

```c
int UTIL_getBuffer(char buffer[], size_t size);
```

**Contextual C example:**

```c
int UTIL_getBuffer(char **buffer_out);
```

**Noncompliant fragment (do not copy):**

```c
int EX_badStoreLocal(context_t *context)
{
    int ret = EXIT_SUCCESS;

    callback_data_t callback_data = { 0 };

    if (context != (context_t *)(NULL))
    {
        context->callback_data = &callback_data;
    }

function_output:
    return ret;
}
```

---

<a id="519-allocator-family-rules"></a> <a id="cstyle-118"></a>

<a id="cstyle-118-5-1-9-allocator-family-rules"></a>

### CSTYLE-118: Allocator Family Rules

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-007: Mismatched allocator][c-common-pitfalls-cpit-007]
- [CPIT-006: Invalid free][c-common-pitfalls-cpit-006]

Each object must be released by the allocator family that created it. The ownership contract must
identify the matching release function when an API does not use the standard `malloc()` and `free()`
pair.

Prefer matching pairs:

Do not pass stack objects, static objects, interior pointers, or foreign allocator blocks to a
release function.

#### Local examples

**Noncompliant fragment (do not copy):**

```c
buffer = (uint8_t *)malloc(buffer_size);
if (buffer == (uint8_t *)(NULL))
{
    ret = -ENOMEM;
    goto function_output;
}

MEM_free(buffer);
```

**Contextual C example:**

```c
buffer = (uint8_t *)MEM_alloc(buffer_size);
if (buffer == (uint8_t *)(NULL))
{
        ret = -ENOMEM;
        goto function_output;
}

MEM_free(buffer);
buffer = (uint8_t *)(NULL);
```

---

<a id="5110-ownership-transfer-rules"></a> <a id="cstyle-119"></a>

<a id="cstyle-119-5-1-10-ownership-transfer-rules"></a>

### CSTYLE-119: Ownership Transfer Rules

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-002: Use-after-free][c-common-pitfalls-cpit-002]
- [CPIT-005: Ambiguous ownership][c-common-pitfalls-cpit-005]

An API that takes ownership must state the exact transfer point, including what happens on failure.
After a successful transfer, the caller must not read, write, release, or derive another pointer
from the transferred object.

Finish caller-owned work before the transfer and clear the caller's pointer after success:

#### Local examples

**Noncompliant fragment (do not copy):**

```c
if ((queue == (queue_t *)(NULL)) ||
    (item == (item_t *)(NULL)))
{
    ret = -EINVAL;
    goto function_output;
}

ret = QUEUE_push(queue, item);
if (ret != EXIT_SUCCESS)
{
    goto function_output;
}

item->state = ITEM_STATE_READY;
```

**Contextual C example:**

```c
if ((queue == (queue_t *)(NULL)) || (item == (item_t *)(NULL)))
{
        ret = -EINVAL;
        goto function_output;
}

item->state = ITEM_STATE_READY;

ret = QUEUE_push(queue, item);
if (ret != EXIT_SUCCESS)
        goto function_output;

item = (item_t *)(NULL);
```

---

<a id="5111-resource-acquisition-and-cleanup"></a> <a id="cstyle-120"></a>

<a id="cstyle-120-5-1-11-resource-acquisition-and-cleanup"></a>

### CSTYLE-120: Resource Acquisition and Cleanup

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-004: Memory leak][c-common-pitfalls-cpit-004]

Every acquired resource must have one visible, deterministic release path. Functions that acquire
more than one resource must use the project's normal `function_output` path or another structured
cleanup region. Release resources in reverse acquisition order and make cleanup safe after partial
acquisition.

Release functions used this way must accept typed `NULL` as a no-op. When a release API does not,
guard that call with an explicit validity check.

#### Local examples

**Contextual C example:**

```c
int EX_processFile(const char path[])
{
        int ret = EXIT_SUCCESS;

        file_t  *file   = (file_t *)(NULL);
        uint8_t *buffer = (uint8_t *)(NULL);

        if (path == (const char *)(NULL))
        {
                ret = -EINVAL;
                goto function_output;
        }

        file = FILE_open(path);
        if (file == (file_t *)(NULL))
        {
                ret = -EIO;
                goto function_output;
        }

        buffer = (uint8_t *)MEM_alloc(EX_BUFFER_SIZE);
        if (buffer == (uint8_t *)(NULL))
        {
                ret = -ENOMEM;
                goto function_output;
        }

        ret = EX_processBuffer(file, buffer, EX_BUFFER_SIZE);

function_output:
        MEM_free(buffer);
        FILE_close(file);

        return ret;
}
```

---

<a id="5112-sizeof-and-object-size-rules"></a> <a id="cstyle-136"></a>

<a id="cstyle-136-5-1-12-sizeof-and-object-size-rules"></a>

### CSTYLE-136: `sizeof` and Object-Size Rules

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-132: Pointer size mistaken for object capacity][c-common-pitfalls-cpit-132]
- [CPIT-029: Array-to-pointer decay][c-common-pitfalls-cpit-029]
- [CPIT-013: Out-of-bounds write][c-common-pitfalls-cpit-013]

Use `sizeof` according to the actual type of the operand:

- `sizeof(array)` gives the complete array size only where `array` still has array type
- `sizeof(*ptr)` gives the size of the pointed type and is the required form for allocation tied to
  a destination pointer
- `sizeof(ptr)` gives the size of the pointer itself and may be used only when that
  pointer-representation size is the intended value

`sizeof(pointer)` must never supply the capacity of pointed storage. Array parameter notation does
not preserve array size because C adjusts the parameter to a pointer.

Pass the storage size with the pointer:

#### Local examples

**Noncompliant fragment (do not copy):**

```c
int EX_clearBuffer(uint8_t buffer[], size_t buffer_size)
{
    int ret = EXIT_SUCCESS;

    if ((buffer == (uint8_t *)(NULL)) ||
        (buffer_size == 0u))
    {
        ret = -EINVAL;
        goto function_output;
    }

    memset(buffer, 0, sizeof(buffer));

function_output:
    return ret;
}
```

**Contextual C example:**

```c
int EX_clearBuffer(uint8_t buffer[], size_t buffer_size)
{
        int ret = EXIT_SUCCESS;

        if ((buffer == (uint8_t *)(NULL)) || (buffer_size == 0u))
        {
                ret = -EINVAL;
                goto function_output;
        }

        memset(buffer, 0, buffer_size);

function_output:
        return ret;
}
```

---

<a id="5113-semantic-object-copy-rules"></a> <a id="cstyle-152"></a>

<a id="cstyle-152-5-1-13-semantic-object-copy"></a>

### CSTYLE-152: Semantic Object Copy Rules

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-136: Semantic object copied as bytes][c-common-pitfalls-cpit-136]
- [CPIT-005: Ambiguous ownership][c-common-pitfalls-cpit-005]

Classify a structure as a value object or an identity/resource object before allowing whole-object
copy.

| Object category        | Struct assignment or bytewise copy                                |
| ---------------------- | ----------------------------------------------------------------- |
| value object           | permitted when its contract declares the representation copyable  |
| identity object        | prohibited unless a named clone operation defines new identity    |
| resource object        | prohibited unless a named duplication operation defines ownership |
| synchronization object | prohibited                                                        |

Objects containing owned pointers, mutexes, atomics, file descriptors, device handles, reference
counts, intrusive links, callbacks, or registration state must not be copied with `memcpy` or plain
struct assignment unless the type's contract explicitly declares that operation safe.

Use a named copy, clone, retain, duplicate, or move operation that defines failure behavior and
ownership of every member.

#### Local examples

**Contextual C example:**

```c
DEVICE_cloneConfig(&dst_config, &src_config); /* value object copy API */
```

**Noncompliant fragment (do not copy):**

```c
dst_device = src_device; /* copies lock, handle, identity, ownership */
```

---

<a id="5114-compound-literal-lifetime"></a> <a id="cstyle-153"></a>

<a id="cstyle-153-5-1-14-compound-literal-lifetime"></a>

### CSTYLE-153: Compound Literal Lifetime

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-032: Borrowed pointer stored beyond lifetime][c-common-pitfalls-cpit-032]

A pointer to a block-scope compound literal must not escape the containing scope. Production code
should prefer a named object whenever a callee accepts a pointer, because the name makes lifetime
and post-call inspection explicit.

Tests may use compound literals for immediate non-retaining calls when the API contract explicitly
says that it does not store the pointer.

#### Local examples

**Contextual C example:**

```c
config_t config = { 0 };

config.timeout_ms  = 100u;
config.retry_count = 0u;
config.is_enabled  = true;

ret = MODULE_configure(module, &config);
```

---

<a id="5115-trust-aware-allocation-failure-policy"></a> <a id="cstyle-154"></a>

<a id="cstyle-154-5-1-15-trust-aware-allocation-failure"></a>

### CSTYLE-154: Trust-Aware Allocation Failure Policy

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-094: Tainted size trusted][c-common-pitfalls-cpit-094]
- [CPIT-115: Unbounded resource consumption][c-common-pitfalls-cpit-115]
- [CPIT-141: Untrusted input reaches fatal allocation][c-common-pitfalls-cpit-141]

Untrusted or externally influenced input must not select the size of an allocation whose failure
policy terminates the process or system.

Such an allocation path must:

- validate a hard product limit before allocation;
- use checked size arithmetic;
- call a recoverable allocator;
- preserve the prior valid state on failure;
- convert the failure into the owning module's error domain.

A fatal allocator may be permitted only for a small, internally bounded allocation when termination
is already the documented system policy. The module must not infer trust merely because a parser
converted text into an integer.

#### Local examples

**Contextual C example:**

```c
if (request_size > REQUEST_MAX_BYTES)
{
        ret = -E2BIG;
        goto function_output;
}

buffer = (uint8_t *)try_alloc(request_size);
```

**Noncompliant fragment (do not copy):**

```c
buffer = (uint8_t *)fatal_alloc(request->size_bytes); /* attacker controls fatal allocation */
```

---

<a id="5116-automatic-storage-and-stack-budget"></a> <a id="cstyle-164"></a>

<a id="cstyle-164-5-1-16-automatic-storage-stack-budget"></a>

### CSTYLE-164: Automatic Storage and Stack Budget

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-045: Recursive unbounded call chain][c-common-pitfalls-cpit-045]
- [CPIT-152: Automatic storage exceeds the stack budget][c-common-pitfalls-cpit-152]

Every execution context with a bounded stack must have a documented stack budget. A function on that
context must not introduce a large automatic object, hidden temporary, inlined expansion, recursion
depth, or call chain that can exceed the verified budget.

Rules:

- variable-length arrays and `alloca` remain prohibited;
- large fixed arrays and aggregate temporaries belong in owned static storage, a caller-provided
  workspace, or a bounded allocator chosen by the module;
- callback, ISR, signal, thread, and task stacks require separate worst-case analysis;
- stack analysis must use the release toolchain and configuration, including inlining and
  instrumentation modes relevant to deployment;
- a configured review threshold is a diagnostic trigger, not proof of safety;
- CI should retain compiler stack-usage output or an equivalent call-graph report for bounded-stack
  profiles.

The Linux submission checklist uses `checkstack` and treats functions with more than 512 bytes of
stack as candidates for change; this project records its own target-specific limit rather than
adopting that heuristic as a universal budget.[linux-submit-checklist][linux-submit-checklist]

#### Local examples

**Contextual C example:**

```c
uint8_t scratch[128] = { 0 }; /* included in reviewed stack budget */
```

**Noncompliant fragment (do not copy):**

```c
uint8_t scratch[65536] = { 0 }; /* hidden large automatic allocation */
```

---

<a id="52-unsafe-language-and-standard-library-apis"></a>
<a id="cstyle-085-unsafe-language-and-standard-library-apis"></a> <a id="cstyle-085"></a>

<a id="cstyle-085-5-2-unsafe-language-and-standard-library-apis"></a>

### CSTYLE-085: Unsafe Language and Standard Library APIs

**Class:** SECURITY. **Obligation:** project requirement.

Apply the canonical API policy in CSTYLE-086 to direct calls and equivalent custom wrappers. Scope
it to APIs available in the selected platform. A restricted API is not automatically
vulnerable in every use, and an allowed API is not automatically safe. Its preconditions and product
threat model still apply. Do not copy platform-specific replacements into portable modules.

**Source context:** [cwe][c-common-pitfalls-ref-cwe].

#### Local examples

**Contextual C example:**

```c
ret = STR_copy(dst, dst_capacity, src);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

**Noncompliant fragment (do not copy):**

```c
strcpy(dst, src); /* banned/unbounded API */
```

---

<a id="521-standard-library-policy"></a> <a id="cstyle-086"></a>

<a id="cstyle-086-standard-library-policy"></a>

### CSTYLE-086: Standard Library Policy

**Class:** SECURITY. **Obligation:** project requirement.

The CBAN register below is the canonical API restriction list. `ban` is a project prohibition on the
named use; `ban-pattern` prohibits the unsafe condition, not every call to the API; `review`
requires recorded preconditions and a suitable test. These are project controls, not a claim that
ISO C or CERT universally bans every listed API. A replacement wrapper must enforce the stated
bounds, error, ownership, encoding, and platform contract. A `_s` suffix alone is not approval. The
table retains all 140 existing CBAN identities.

**Failure scenarios:** [CPIT-006][c-common-pitfalls-cpit-006],
[CPIT-055][c-common-pitfalls-cpit-055], [CPIT-056][c-common-pitfalls-cpit-056],
[CPIT-059][c-common-pitfalls-cpit-059], [CPIT-064][c-common-pitfalls-cpit-064],
[CPIT-065][c-common-pitfalls-cpit-065], [CPIT-066][c-common-pitfalls-cpit-066],
[CPIT-093][c-common-pitfalls-cpit-093], [CPIT-096][c-common-pitfalls-cpit-096],
[CPIT-098][c-common-pitfalls-cpit-098], [CPIT-100][c-common-pitfalls-cpit-100],
[CPIT-103][c-common-pitfalls-cpit-103].

**Source context:** [cwe][c-common-pitfalls-ref-cwe].

#### Local examples

**Contextual C example:**

```c
ret = STR_parseU32(input, &value);
```

**Noncompliant fragment (do not copy):**

```c
value = (uint32_t)atoi(input);
```

---

<a id="53-string-handling"></a> <a id="cstyle-087-string-handling"></a> <a id="cstyle-087"></a>

<a id="cstyle-087-5-3-string-handling"></a>

### CSTYLE-087: String Handling

**Class:** CORRECTNESS. **Obligation:** project requirement.

String operations must preserve bounds and termination explicitly.

- every writable string buffer must have a known size
- prefer `snprintf` for formatted output into buffers
- always check truncation behavior when using bounded formatting
- ensure destination strings remain NUL-terminated
- avoid repeated ad hoc pointer arithmetic for string assembly

- strings are a frequent source of silent memory corruption in C
- explicit size handling makes failures diagnosable and reviewable

**Failure scenarios:** [CPIT-055][c-common-pitfalls-cpit-055],
[CPIT-058][c-common-pitfalls-cpit-058], [CPIT-060][c-common-pitfalls-cpit-060].

#### Local examples

**Contextual C example:**

```c
int written = 0;

if ((path == (char *)(NULL)) || (dir_path == (const char *)(NULL)) ||
    (file_name == (const char *)(NULL)) || (path_size == 0u))
{
        ret = -EINVAL;
        goto function_output;
}

written = snprintf(path, path_size, "%s/%s", dir_path, file_name);
if ((written < 0) || ((size_t)written >= path_size))
{
        ret = -ENOSPC;
        goto function_output;
}
```

---

<a id="531-counted-text-and-byte-views"></a> <a id="cstyle-165"></a>

<a id="cstyle-165-5-3-1-counted-text-and-byte-views"></a>

### CSTYLE-165: Counted Text and Byte Views

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-058: `strlen` on unterminated data][c-common-pitfalls-cpit-058]
- [CPIT-153: Counted data is treated as a NUL-terminated string][c-common-pitfalls-cpit-153]

A pointer-plus-length view is not implicitly a C string. Its contract must state whether the bytes
are text or opaque data, whether embedded NUL bytes are valid, whether a terminator is present
inside or after the extent, the encoding, and the owner of the storage.

Do not pass a counted view to `strlen`, `%s`, or another terminator-scanning API until a checked
conversion establishes a terminated destination. Conversely, do not infer the usable extent of a C
string from an unrelated buffer capacity. Prefer project span/view types or an explicit pointer and
extent. nginx's core string type similarly carries `len` and `data`, and the data need not be
NUL-terminated.[nginx-development-guide][nginx-development-guide]

#### Local examples

**Contextual C example:**

```c
text_span_t span = { .data = input, .length = input_length };
ret              = TEXT_parseSpan(&span);
```

**Noncompliant fragment (do not copy):**

```c
printf("%s", input); /* input has a length but no NUL-termination contract */
```

---

<a id="61-state-visibility"></a> <a id="cstyle-088-state-visibility"></a> <a id="cstyle-088"></a>

<a id="cstyle-088-6-1-state-visibility"></a>

### CSTYLE-088: State Visibility

**Class:** ARCHITECTURE / CORRECTNESS. **Obligation:** project requirement.

Prefer explicit module-instance state. A necessary file-scope mutable object requires a named owner,
lifetime, synchronization, initialization, and shutdown contract; keep it private with `static` and
a `g_` prefix. Avoid function-static mutable state. Immutable file-scope tables may use
`static const`.

Do not create cross-translation-unit variables or publish another module's objects by name.
The only explicit `extern` allowed in project-authored C interfaces is the `__cplusplus`-guarded
`extern "C"` compatibility block required by CMOD-019 for C++ compatible headers. Do not use it as
a storage class on objects, prototypes, or inline definitions. Follow CMOD-017 through CMOD-019
for ownership, ordinary function prototypes, and header-owned compatibility blocks. Application
`main.c` keeps its own helpers and state private under CMOD-021.

#### Local examples

**Contextual C example:**

```c
typedef struct ExampleState
{
        uint32_t counter;
        bool     is_initialized;
} example_state_t;

int EX_increment(example_state_t *state)
{
        int ret = EXIT_SUCCESS;

        if (state == (example_state_t *)(NULL))
        {
                ret = -EINVAL;
                goto function_output;
        }

        if (state->counter == UINT32_MAX)
        {
                ret = -ERANGE;
                goto function_output;
        }

        state->counter++;

function_output:
        return ret;
}
```

**Noncompliant fragment (do not copy):**

```c
int global_counter = 0;
bool is_initialized = false;

int EX_increment(void)
{
    int ret = EXIT_SUCCESS;

    static int counter = 0;

    counter++;

function_output:
    return ret;
}
```

---

<a id="62-volatile-rules"></a> <a id="cstyle-089-volatile-rules"></a> <a id="cstyle-089"></a>

<a id="cstyle-089-6-2-volatile-rules"></a>

### CSTYLE-089: Volatile Rules

**Class:** CORRECTNESS / SAFETY. **Obligation:** project requirement.

Use volatile accesses only where the implementation/platform contract needs them, such as documented
MMIO or supported signal state. Volatile is not a mutex, thread publication protocol, atomic
read-modify-write, DMA cache operation, or general memory barrier. Do not introduce it to disguise a
data race or suppress optimization symptoms. Isolate hardware access semantics in the target
adapter.

**Failure scenarios:** [CPIT-068][c-common-pitfalls-cpit-068],
[CPIT-075][c-common-pitfalls-cpit-075], [CPIT-083][c-common-pitfalls-cpit-083],
[CPIT-086][c-common-pitfalls-cpit-086].

#### Local examples

**Contextual C example:**

```c
uint32_t reg_status = 0u;

reg_status = MMIO_read32(REG_STATUS_ADDRESS);
```

---

<a id="63-thread-safety-documentation"></a> <a id="cstyle-090-thread-safety-documentation"></a>
<a id="cstyle-090"></a>

<a id="cstyle-090-6-3-thread-safety-documentation"></a>

### CSTYLE-090: Thread Safety Documentation

**Class:** CORRECTNESS / SAFETY. **Obligation:** project requirement.

Classify concurrency per operation and per instance: thread-safe, externally synchronized, or
confined to a thread. Also document reentrancy, blocking, allocation, ISR/signal restrictions, and
concurrent destruction. Independent instances are not necessarily independent when they share
allocator contexts or other mutable dependencies. A thread-safe operation can still be unbounded.

#### Local examples

**Contextual C example:**

```c
/*
 * Thread-safe.
 */
int CACHE_getItem(int key, item_t *out);
```

---

<a id="64-thread-lifecycle-and-cleanup"></a> <a id="cstyle-091-thread-lifecycle-and-cleanup"></a>
<a id="cstyle-091"></a>

<a id="cstyle-091-6-4-thread-lifecycle-and-cleanup"></a>

### CSTYLE-091: Thread Lifecycle and Cleanup

**Class:** CORRECTNESS / SAFETY. **Obligation:** project requirement.

Name the owner of thread creation, registration, thread-local storage, exit, and join. Stop new
work, wake blocked workers as needed, wait for in-flight work, and only then destroy synchronization
and storage. Define allocator behavior while workers exit. Prefer cooperative cancellation. A
detached thread still needs a proved lifetime protocol for every object it can access.

**Failure scenarios:** [CPIT-068][c-common-pitfalls-cpit-068],
[CPIT-073][c-common-pitfalls-cpit-073], [CPIT-080][c-common-pitfalls-cpit-080].

#### Local examples

**Contextual C example:**

```c
int cleanup_ret = EXIT_SUCCESS;

ret = MEM_threadRegister(thread_ctx);
if (ret != EXIT_SUCCESS)
        goto function_output;

/* Thread work. */

cleanup_ret = MEM_threadDeregister(thread_ctx);
if ((ret == EXIT_SUCCESS) && (cleanup_ret != EXIT_SUCCESS))
        ret = cleanup_ret;

function_output : return ret;
```

---

<a id="65-synchronization-rules"></a> <a id="cstyle-092-synchronization-rules"></a>
<a id="cstyle-092"></a>

<a id="cstyle-092-6-5-synchronization-rules"></a>

### CSTYLE-092: Synchronization Rules

**Class:** CORRECTNESS / SAFETY. **Obligation:** project requirement.

Name the protected state for each lock and establish a global lock-order rule. Recheck
condition-variable predicates in a loop while holding the required lock. Do not destroy reachable or
locked synchronization objects. Use the weakest atomic ordering only after documenting the needed
happens-before relationship; start with a simple proved protocol, not automatic relaxed operations.
Release/acquire publication requires the acquiring operation to observe the corresponding release or
its valid release sequence. Reclamation is a separate obligation from publication. Avoid unknown
callbacks while holding locks.

**Failure scenarios:** [CPIT-068][c-common-pitfalls-cpit-068],
[CPIT-069][c-common-pitfalls-cpit-069], [CPIT-070][c-common-pitfalls-cpit-070],
[CPIT-071][c-common-pitfalls-cpit-071], [CPIT-072][c-common-pitfalls-cpit-072],
[CPIT-074][c-common-pitfalls-cpit-074], [CPIT-078][c-common-pitfalls-cpit-078],
[CPIT-079][c-common-pitfalls-cpit-079], [CPIT-082][c-common-pitfalls-cpit-082].

#### Local examples

**Contextual C example:**

```c
bool is_locked  = false;
int  unlock_ret = EXIT_SUCCESS;

ret = THREAD_mutexLock(&queue_mutex);
if (ret != EXIT_SUCCESS)
        goto function_output;

is_locked = true;

while (queue_is_empty)
{
        ret = THREAD_condWait(&queue_cond, &queue_mutex);
        if (ret != EXIT_SUCCESS)
                goto function_output;
}

function_output : if (is_locked)
{
        unlock_ret = THREAD_mutexUnlock(&queue_mutex);
        if ((ret == EXIT_SUCCESS) && (unlock_ret != EXIT_SUCCESS))
                ret = unlock_ret;
}

return ret;
```

**Contextual C example:**

```c
atomic_store_explicit(&is_ready, true, memory_order_release);
ready = atomic_load_explicit(&is_ready, memory_order_acquire);
```

---

<a id="651-concurrency-hazard-map"></a> <a id="cstyle-093-concurrency-hazard-map"></a>
<a id="cstyle-093"></a>

<a id="cstyle-093-6-5-1-concurrency-hazard-map"></a>

### CSTYLE-093: Concurrency Hazard Map

**Class:** CORRECTNESS / SAFETY. **Obligation:** project requirement.

For allocator caches, pools, refcounts, free lists, and GC metadata, review publication, concurrent
mutation, reclamation, ABA, counter overflow, teardown, lock ordering, and bounded progress
separately. Hazard pointers and epochs can protect lifetime only under their complete protocols;
they do not repair every logical ABA problem. A stress test is evidence of exercised schedules, not
a proof that all schedules are safe. Use simpler locking when no proved lock-free protocol is
justified.

#### Local examples

**Layout example (not executable):**

```text
Concurrency review records: shared object, writer contexts, reader contexts,
lock/atomic primitive, ordering, lifetime, blocking rules
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Shared queue is called “thread-safe” but nobody records which fields race, who
writes them, or which lock/order protects them
```

---

<a id="66-atomic-and-interrupt-shared-state"></a>
<a id="cstyle-094-atomic-and-interrupt-shared-state"></a> <a id="cstyle-094"></a>

<a id="cstyle-094-6-6-atomic-and-interrupt-shared-state"></a>

### CSTYLE-094: Atomic and Interrupt Shared State

**Class:** CORRECTNESS / SAFETY. **Obligation:** project requirement.

Document objects shared with interrupt context and the target's access and nesting rules. Use a
supported critical section or proven lock-free atomic protocol; a library atomic may internally lock
and therefore be unsuitable in an ISR. Masking local interrupts does not synchronize another CPU or
a DMA engine. Include compiler ordering, CPU barriers, cache maintenance, and device ownership
transfers when required by the hardware manual.

**Failure scenarios:** [CPIT-068][c-common-pitfalls-cpit-068],
[CPIT-076][c-common-pitfalls-cpit-076].

#### Local examples

**Contextual C example:**

```c
static volatile uint32_t g_event_flags = 0u;

/* The platform ISR ABI requires void. */
/* This adapter has a documented deviation. */
void ISR_onEvent(void)
{
        ISR_ATOMIC_fetchOrU32(&g_event_flags, EVENT_FLAG_RX);
}
```

---

<a id="67-signal-handler-safety"></a> <a id="cstyle-095-signal-handler-safety"></a>
<a id="cstyle-095"></a>

<a id="cstyle-095-6-7-signal-handler-safety"></a>

### CSTYLE-095: Signal Handler Safety

**Class:** PORTABILITY / CORRECTNESS. **Obligation:** project requirement.

A signal handler may use only operations permitted by the selected C/POSIX and runtime contract. Do
not call allocation, stdio logging, or ordinary mutex operations from it. Keep shared handler state
in the specifically permitted signal-safe or lock-free atomic form. An ISR and a POSIX signal
handler are different execution models; do not transfer assumptions between them.

**Failure scenarios:** [CPIT-068][c-common-pitfalls-cpit-068],
[CPIT-077][c-common-pitfalls-cpit-077].

#### Local examples

**Contextual C example:**

```c
static volatile sig_atomic_t g_stop = 0;

void onSignal(int sig)
{
        g_stop = 1;
}
```

**Noncompliant fragment (do not copy):**

```c
void onSignal(int sig)
{
    printf("stop\n");
    malloc(16u);
}
```

---

<a id="68-cast-rules"></a> <a id="cstyle-096-cast-rules"></a> <a id="cstyle-096"></a>

<a id="cstyle-096-6-8-cast-rules"></a>

### CSTYLE-096: Cast Rules

**Class:** PORTABILITY / CORRECTNESS. **Obligation:** project requirement.

Use the explicit pointer casts required by CSTYLE-078 and CSTYLE-107. Otherwise, a cast must express
an intentional conversion, not suppress a type diagnostic. Narrow only after checking the source
value's range. Preserve qualifiers and match callback types exactly. Pointer/integer and
representation conversions belong to qualified low-level adapters with stated width, alignment,
effective-type, lifetime, and provenance assumptions. Explain non-obvious adapter casts at the
conversion or in its referenced contract.

**Failure scenarios:** [CPIT-010][c-common-pitfalls-cpit-010],
[CPIT-024][c-common-pitfalls-cpit-024], [CPIT-027][c-common-pitfalls-cpit-027].

**Source context:** [c23][c-common-pitfalls-ref-c23].

#### Local examples

**Contextual C example:**

```c
uint8_t *buffer_ptr = (uint8_t *)(NULL);

uint32_t value_u32     = 0u;
uint64_t checked_value = 0u;

if (raw_value < 0)
{
        ret = -ERANGE;
        goto function_output;
}

checked_value = (uint64_t)raw_value;
if (checked_value > (uint64_t)UINT32_MAX)
{
        ret = -ERANGE;
        goto function_output;
}

value_u32  = (uint32_t)checked_value;
buffer_ptr = (uint8_t *)base_ptr;
```

**Noncompliant fragment (do not copy):**

```c
value_u32 = (uint32_t)ptr_value;
```

**Contextual C example:**

```c
/* Platform adapter: the MCU defines this address as a 32-bit MMIO object. */
reg_ptr = (volatile uint32_t *)register_base;
```

---

<a id="681-never-cast-away-const"></a> <a id="cstyle-155"></a>

<a id="cstyle-155-6-8-1-never-cast-away-const"></a>

### CSTYLE-155: Never Cast Away `const`

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-137: Discarded `const` qualification][c-common-pitfalls-cpit-137]
- [CPIT-139: String literal modification][c-common-pitfalls-cpit-139]

A project cast must not remove `const` qualification. If an external API has an incorrect mutable
parameter for data it does not modify, isolate that call in a reviewed adapter and document the
external contract. The adapter must not permit the callee to modify a genuinely const object.

Change the callee contract or make a validated mutable copy when modification is required. Casting
away the qualifier does not make a const object writable.

#### Local examples

**Noncompliant fragment (do not copy):**

```c
mutable_config = (config_t *)config;
```

---

<a id="69-numeric-conversion-rules"></a> <a id="cstyle-097-numeric-conversion-rules"></a>
<a id="cstyle-097"></a>

<a id="cstyle-097-6-9-numeric-conversion-rules"></a>

### CSTYLE-097: Numeric Conversion Rules

**Class:** CORRECTNESS. **Obligation:** project requirement.

Numeric conversions must preserve value and meaning.

- narrowing conversions require explicit range checks
- conversions from signed to unsigned must reject negative values first
- conversions from wider to narrower integer types must check upper bounds
- signed/unsigned comparisons must be avoided or normalized to one domain
- casts must not be used to silence warnings
- enum/integer conversions require validation
- pointer/integer conversions are forbidden outside low-level modules

**Failure scenarios:** [CPIT-025][c-common-pitfalls-cpit-025],
[CPIT-046][c-common-pitfalls-cpit-046], [CPIT-052][c-common-pitfalls-cpit-052],
[CPIT-053][c-common-pitfalls-cpit-053], [CPIT-055][c-common-pitfalls-cpit-055],
[CPIT-063][c-common-pitfalls-cpit-063].

**Source context:** [c23][c-common-pitfalls-ref-c23].

**Complete example:** [worked sources][c-code-standard-worked-example].

#### Local examples

**Contextual C example:**

```c
uint16_t value_u16 = 0u;
uint32_t value_u32 = 0u;

if (value < 0)
{
        ret = -ERANGE;
        goto function_output;
}

value_u32 = (uint32_t)value;
if (value_u32 > (uint32_t)UINT16_MAX)
{
        ret = -ERANGE;
        goto function_output;
}

value_u16 = (uint16_t)value_u32;
```

**Noncompliant fragment (do not copy):**

```c
value_u16 = (uint16_t)value;
```

---

<a id="610-pointer-aliasing-and-provenance-rules"></a>
<a id="cstyle-098-pointer-aliasing-and-provenance-rules"></a> <a id="cstyle-098"></a>

<a id="cstyle-098-6-10-pointer-aliasing-and-provenance-rules"></a>

### CSTYLE-098: Pointer Aliasing and Provenance Rules

**Class:** PORTABILITY / CORRECTNESS. **Obligation:** project requirement.

Access objects only through types permitted by the selected C edition's effective-type and aliasing
rules. Character-type access may inspect object representation; prefer `unsigned char` for byte
values. A representation copy using `memcpy` still needs valid storage, sufficient size, and an
appropriate result representation. It does not perform byte-order conversion. Use `restrict` only
under a proved contract for the relevant execution. Keep base owners distinct from cursors. Do not
reconstruct usable ordinary pointers from persisted or untrusted integers. Target-specific allocator
address handling needs documented provenance assumptions and toolchain tests.

**Failure scenarios:** [CPIT-021][c-common-pitfalls-cpit-021],
[CPIT-022][c-common-pitfalls-cpit-022], [CPIT-023][c-common-pitfalls-cpit-023].

**Source context:** [c23][c-common-pitfalls-ref-c23].

#### Local examples

**Contextual C example:**

```c
memcpy(&value_u32, bytes, sizeof(value_u32));
```

**Noncompliant fragment (do not copy):**

```c
value_u32 = *((uint32_t *)bytes);
```

---

<a id="611-pointer-dereference-preconditions"></a> <a id="cstyle-121"></a>

<a id="cstyle-121-6-11-pointer-dereference-preconditions"></a>

### CSTYLE-121: Pointer Dereference Preconditions

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-001: Dangling pointer][c-common-pitfalls-cpit-001]
- [CPIT-002: Use-after-free][c-common-pitfalls-cpit-002]
- [CPIT-011: NULL pointer dereference][c-common-pitfalls-cpit-011]

Before any dereference, the current control-flow path must establish that the pointer has valid
provenance, suitable alignment, an active lifetime, and permission for the requested access. A
nullable pointer must also be proven non-`NULL`.

Prefer an explicit precondition:

An API boundary check, a successful lookup, a documented required-pointer contract, or a dominating
branch may establish validity. A stale check from a different path does not.

#### Local examples

**Noncompliant fragment (do not copy):**

```c
value = ptr->value;
```

**Contextual C example:**

```c
if (ptr != (const item_t *)(NULL))
        value = ptr->value;
```

---

<a id="612-pointer-dereference-chain-rules"></a> <a id="cstyle-122"></a>

<a id="cstyle-122-6-12-pointer-dereference-chain-rules"></a>

### CSTYLE-122: Pointer Dereference Chain Rules

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-123: Chained pointer dereference][c-common-pitfalls-cpit-123]
- [CPIT-011: NULL pointer dereference][c-common-pitfalls-cpit-011]

No more than one pointer dereference may occur in one member-access expression. Store each
pointer-valued member in a named local, establish its validity, and only then dereference it.

The rule counts pointer dereference operations, not member-access tokens. Access through an embedded
object does not introduce another pointer dereference.

| Form                        | Status     | Reason                                      |
| --------------------------- | ---------- | ------------------------------------------- |
| `object->field`             | permitted  | one pointer dereference                     |
| `object->embedded.field`    | permitted  | one pointer dereference, then object access |
| `object->embedded.subfield` | permitted  | one pointer dereference, then object access |
| `object->ptr->field`        | prohibited | two pointer dereference operations          |
| `(object->ptr)->field`      | prohibited | two explicit pointer dereference operations |
| `object->ptr->ptr->field`   | prohibited | three pointer dereference operations        |

If an approved deviation must retain a chain, parentheses must expose every additional dereference
boundary. Write `(aux->prev)->next`, not `aux->prev->next`; for a longer chain, name or parenthesize
each intermediate pointer in the same manner. The deviation must document how each pointer's
validity and lifetime were established.

#### Local examples

**Noncompliant fragment (do not copy):**

```c
(aux->prev)->next = aux->next;
(context->owner)->callback(context);
```

**Contextual C example:**

```c
node_t *prev = (node_t *)(NULL);
node_t *next = (node_t *)(NULL);

if (aux != (node_t *)(NULL))
{
        prev = aux->prev;
        next = aux->next;
}

if (prev != (node_t *)(NULL))
        prev->next = next;
```

---

<a id="613-pointer-validity-across-calls"></a> <a id="cstyle-123"></a>

<a id="cstyle-123-6-13-pointer-validity-across-calls"></a>

### CSTYLE-123: Pointer Validity Across Calls

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-124: Stale validity after a mutating call][c-common-pitfalls-cpit-124]
- [CPIT-002: Use-after-free][c-common-pitfalls-cpit-002]

A call that may change ownership, lifetime, allocation, container structure, or object identity
invalidates earlier pointer-validity evidence. Re-establish validity after the call before
dereferencing the pointer. Only an explicit callee contract may preserve the earlier guarantee.

Prefer reacquiring the object through a stable key:

#### Local examples

**Noncompliant fragment (do not copy):**

```c
if (node != (node_t *)(NULL))
{
    LIST_remove(list, node);
    node->flags = 0u;
}
```

**Contextual C example:**

```c
if (node != (node_t *)(NULL))
{
        node_id = node->id;
        LIST_remove(list, node);
        node = LIST_find(list, node_id);
}

if (node != (node_t *)(NULL))
        node->flags = 0u;
```

---

<a id="614-alias-safe-mutation"></a> <a id="cstyle-124"></a>

<a id="cstyle-124-6-14-alias-safe-mutation"></a>

### CSTYLE-124: Alias-Safe Mutation

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-125: Interleaved mutation through aliases][c-common-pitfalls-cpit-125]
- [CPIT-023: Invalid `restrict` aliasing][c-common-pitfalls-cpit-023]

Do not perform interleaved read-modify-write operations through pointers that may name the same
object. Prove that the objects do not overlap, or select one canonical pointer and perform the state
transition through it.

Prefer an explicit non-aliasing precondition:

#### Local examples

**Noncompliant fragment (do not copy):**

```c
first->value += delta;
second->value = first->value;
```

**Contextual C example:**

```c
if ((first == (item_t *)(NULL)) || (second == (item_t *)(NULL)) ||
    (first == second))
{
        ret = -EINVAL;
        goto function_output;
}

first->value  += delta;
second->value  = first->value;
```

---

<a id="615-array-bounds-and-pointer-arithmetic"></a> <a id="cstyle-125"></a>

<a id="cstyle-125-6-15-array-bounds-and-pointer-arithmetic"></a>

### CSTYLE-125: Array Bounds and Pointer Arithmetic

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-013: Out-of-bounds write][c-common-pitfalls-cpit-013]
- [CPIT-014: Out-of-bounds read][c-common-pitfalls-cpit-014]
- [CPIT-017: One-past-end dereference][c-common-pitfalls-cpit-017]
- [CPIT-018: Invalid pointer arithmetic][c-common-pitfalls-cpit-018]

Before indexing an array, prove that the index is within the bounds of that same array object. A
global maximum, unrelated capacity, or different buffer's length does not establish the bound.

Pointer arithmetic is permitted only within one array object. Code may form a one-past pointer for
comparison or iteration, but it must not dereference that pointer.

Prefer pointer-and-count contracts that travel together:

Avoid checking an unrelated limit:

#### Local examples

**Contextual C example:**

```c
if ((items != (item_t *)(NULL)) && (index < item_count))
        item = &items[index];
```

**Noncompliant fragment (do not copy):**

```c
if (index < ITEM_MAX)
{
    item = &items[index];
}
```

---

<a id="616-pointer-member-ownership-semantics"></a> <a id="cstyle-126"></a>

<a id="cstyle-126-6-16-pointer-member-ownership-semantics"></a>

### CSTYLE-126: Pointer Member Ownership Semantics

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-005: Ambiguous ownership][c-common-pitfalls-cpit-005]
- [CPIT-032: Borrowed pointer stored beyond lifetime][c-common-pitfalls-cpit-032]
- [CPIT-033: Heap object points to stack memory][c-common-pitfalls-cpit-033]

For every pointer member, the type or API contract must state whether the member is owned, borrowed,
optional, required, or a weak reference. It must also state the lifetime and allocator family when
either affects use or release.

Embedded objects and pointer members have different access and ownership semantics:

After `context` validity is established, `context->config.timeout_ms` performs one pointer
dereference. Accessing the device requires a separate local pointer and validity proof under
`CSTYLE-122`.

#### Local examples

**Contextual C example:**

```c
typedef struct Context
{
        config_t config; /* Embedded; owned by this context. */

        /* Borrowed and optional; the device owner retains lifetime control. */
        device_t *device;
} context_t;
```

---

<a id="617-typed-access-to-raw-storage"></a> <a id="cstyle-156"></a>

<a id="cstyle-156-6-17-typed-access-to-raw-storage"></a>

### CSTYLE-156: Typed Access to Raw Storage

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-024: Invalid alignment][c-common-pitfalls-cpit-024]
- [CPIT-021: Pointer provenance violation][c-common-pitfalls-cpit-021]
- [CPIT-041: Invalid effective type access][c-common-pitfalls-cpit-041]

Converting raw, arena, packet, DMA, shared, or byte-array storage to a typed object pointer requires
a documented proof of:

- at least `sizeof(type)` accessible bytes;
- an address satisfying `alignof(type)`;
- a valid object lifetime and effective type for the intended access;
- provenance that permits formation and use of the typed pointer;
- platform cache and coherency requirements when a device shares the storage.

Use `alignof(type)` and `alignas(type)` through the project portability layer instead of copying a
numeric alignment assumption.

The byte copy above establishes a representation copy. It does not create permission to retain an
arbitrary `record_t *` into storage after the storage lifetime ends.

#### Local examples

**Contextual C example:**

```c
alignas(record_t) uint8_t storage[sizeof(record_t)] = { 0 };
record_t record                                     = { 0 };

record.value = input_value;
memcpy(storage, &record, sizeof(record));
```

---

<a id="618-offsetof-and-enclosing-object-recovery"></a> <a id="cstyle-157"></a>

<a id="cstyle-157-6-18-offsetof-and-enclosing-object-recovery"></a>

### CSTYLE-157: `offsetof` and Enclosing-Object Recovery

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

Standard `offsetof` may verify a layout contract. Recovering an enclosing object from an interior
member pointer is prohibited outside one reviewed intrusive- container or platform adapter.

That adapter must document the containing type, member, alignment, complete- object lifetime,
provenance model, and null behavior. Application modules must not open-code pointer subtraction with
`offsetof`.

#### Local examples

**Contextual C example:**

```c
node_t *node = CONTAINER_FROM_LINK(link, node_t, link);
```

**Noncompliant fragment (do not copy):**

```c
node_t *node = (node_t *)((uint8_t *)link - offsetof(node_t, link)); /* open-coded everywhere */
```

---

<a id="619-pointer-sequence-extent-contracts"></a> <a id="cstyle-158"></a>

<a id="cstyle-158-6-19-pointer-sequence-extent-contracts"></a>

### CSTYLE-158: Pointer Sequence Extent Contracts

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-029: Array-to-pointer decay][c-common-pitfalls-cpit-029]
- [CPIT-132: Pointer size mistaken for object capacity][c-common-pitfalls-cpit-132]
- [CPIT-142: Sequence pointer without extent][c-common-pitfalls-cpit-142]

Every pointer that represents a sequence must travel with an explicit extent contract. The extent
may be an element count, byte count, capacity, begin/end pair, or fixed compile-time contract. The
unit and nullable/empty semantics must be part of the API.

Do not use `sizeof` on an array parameter to infer the caller's extent. Within the function, the
parameter has pointer type regardless of its bracket spelling.

#### Local examples

**Contextual C example:**

```c
int PROCESS_samples(const uint16_t *samples, size_t sample_count);
```

---

<a id="620-concurrent-object-lifetime-requires-a-retention-protocol"></a> <a id="cstyle-174"></a>

<a id="cstyle-174-6-20-concurrent-object-lifetime-retention"></a>

### CSTYLE-174: Concurrent Object Lifetime Requires a Retention Protocol

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-163: Shared object is destroyed while another context acquires
  it][c-common-pitfalls-cpit-163]

An object that one execution context can discover while another context can remove or destroy it
must have one documented lifetime-retention protocol. Approved protocols include ownership transfer,
a lock that protects lookup and lifetime, a checked reference-count acquisition, RCU/epoch
reclamation, or an approved hazard-pointer scheme.

A pointer lookup and a later reference increment do not form a safe protocol unless the object
cannot reach its terminal state between those operations. Linux `kref` rules require serialization
when code obtains a reference without already holding a valid reference.[linux-kref][linux-kref]

#### Local examples

**Contextual C example:**

```c
int SESSION_useById(session_id_t id)
{
        int ret = EXIT_SUCCESS;

        session_t *session = (session_t *)(NULL);

        ret = SESSION_lookupRetained(id, &session);
        if (ret != EXIT_SUCCESS)
                goto function_output;

        ret = SESSION_process(session);

function_output:
        SESSION_release(&session);

        return ret;
}
```

**Noncompliant fragment (do not copy):**

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

<a id="621-one-time-initialization-includes-publication-ordering"></a> <a id="cstyle-175"></a>

<a id="cstyle-175-6-21-once-initialization-publication"></a>

### CSTYLE-175: One-Time Initialization Includes Publication Ordering

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-164: Concurrent one-time initialization publishes partial state][c-common-pitfalls-cpit-164]

Process-wide or module-wide one-time initialization must use the project once primitive or another
reviewed synchronization protocol. The protocol must make all initialized state visible before
another execution context observes the initialized condition.

Do not implement concurrent initialization with an unsynchronized boolean or a hand-written
double-checked pattern.

#### Local examples

**Contextual C example:**

```c
int LIBRARY_initialize(void)
{
        int ret = EXIT_SUCCESS;

        ret = ONCE_execute(&g_library_once, library_initializeOnce,
                           (void *)(NULL));

function_output:
        return ret;
}
```

**Noncompliant fragment (do not copy):**

```c
if (!g_initialized)
{
    LIBRARY_buildTables();
    g_initialized = true;
}
```

---

<a id="622-thread-cancellation-must-preserve-ownership-and-locks"></a> <a id="cstyle-176"></a>

<a id="cstyle-176-6-22-thread-cancellation-cleanup"></a>

### CSTYLE-176: Thread Cancellation Must Preserve Ownership and Locks

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-165: Thread cancellation bypasses cleanup][c-common-pitfalls-cpit-165]

A profile that supports asynchronous or deferred thread cancellation must state where cancellation
can occur. Code that owns a lock, allocation, descriptor, transaction, or registered callback at a
cancellation point must install a cleanup action or disable cancellation for the bounded critical
region.

Ordinary modules should consume a project cancellation abstraction instead of scattering native
cleanup macros. POSIX cleanup handlers run when cancellation unwinds a thread and can release locks
or other resources.[pthread-cleanup][pthread-cleanup]

#### Local examples

**Contextual C example:**

```c
int WORKER_update(worker_t *worker)
{
        int ret = EXIT_SUCCESS;

        cancel_state_t cancel_state = { 0 };

        ret = THREAD_cancelDisable(&cancel_state);
        if (ret != EXIT_SUCCESS)
                goto function_output;

        ret = WORKER_updateCritical(worker);
        THREAD_cancelRestore(&cancel_state);

function_output:
        return ret;
}
```

**Noncompliant fragment (do not copy):**

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

<a id="623-fork-after-threads-uses-a-restricted-child-path"></a> <a id="cstyle-177"></a>

<a id="cstyle-177-6-23-fork-after-threads-child-path"></a>

### CSTYLE-177: Fork After Threads Uses a Restricted Child Path

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-166: Forked child calls unsafe code from a multithreaded
  process][c-common-pitfalls-cpit-166]

A POSIX profile should prefer the project process-spawn abstraction. If an owner uses `fork()` after
the process has created threads, the child may execute only async-signal-safe operations until
`execve()` or `_exit()`. The child must not allocate memory, take inherited application locks, call
the logger, invoke module callbacks, or touch state that another parent thread could have held
mid-update. Linux documents that only the calling thread survives in the child and restricts the
child to async-signal-safe calls until `execve()`.[linux-fork-threaded][linux-fork-threaded]

#### Local examples

**Contextual C example:**

```c
int JOB_launch(const process_spec_t *spec)
{
        int ret = EXIT_SUCCESS;

        ret = PROCESS_spawn(spec);

function_output:
        return ret;
}
```

**Noncompliant fragment (do not copy):**

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

<a id="624-real-time-locks-need-a-blocking-and-priority-inversion-contract"></a>
<a id="cstyle-178"></a>

<a id="cstyle-178-6-24-real-time-lock-blocking-priority-inversion"></a>

### CSTYLE-178: Real-Time Locks Need a Blocking and Priority-Inversion Contract

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-167: Priority inversion breaks a bounded real-time path][c-common-pitfalls-cpit-167]

A real-time or bounded-latency profile must document the maximum hold time and maximum wait time for
every lock reachable from the critical path. If a higher- priority task can block on a resource
owned by a lower-priority task, the owner must select a protocol such as priority inheritance,
priority ceiling, ownership partitioning, or a lock-free handoff that preserves the timing
requirement.

Do not call unbounded external code, blocking I/O, allocation, or arbitrary callbacks while holding
a real-time lock. Linux RT mutexes use priority inheritance to bound the classic unbounded
priority-inversion case. [linux-rt-mutex][linux-rt-mutex]

#### Local examples

**Contextual C example:**

```c
int CONTROL_update(control_t *control, const control_input_t *input)
{
        int ret = EXIT_SUCCESS;

        ret = RT_MUTEX_lock(&control->lock);
        if (ret != EXIT_SUCCESS)
                goto function_output;

        control_updateStateLocked(control, input);
        RT_MUTEX_unlock(&control->lock);

function_output:
        return ret;
}
```

**Noncompliant fragment (do not copy):**

```c
ret = MUTEX_lock(&control->lock);
if (ret != EXIT_SUCCESS)
{
    goto function_output;
}

ret = NETWORK_waitForReply(control->socket);
if (ret == EXIT_SUCCESS)
{
    ret = control->callbacks->notify(control->callbacks->context);
}

MUTEX_unlock(&control->lock);

function_output:
    return ret;
```

---

<a id="71-undefined-behavior-avoidance"></a> <a id="cstyle-099-undefined-behavior-avoidance"></a>
<a id="cstyle-099"></a>

<a id="cstyle-099-7-1-undefined-behavior-avoidance"></a>

### CSTYLE-099: Undefined Behavior Avoidance

**Class:** CORRECTNESS. **Obligation:** project requirement.

Prevent undefined behavior before evaluating the affected expression. Check bounds before forming
out-of-range pointers, and check arithmetic before an overflowing operation. Require initialized
values and live objects. A successful NULL check, passing test, or low optimization level does not
make an invalid access defined. Sanitizers complement review but do not detect every undefined
behavior on every executed path.

**Failure scenarios:** [CPIT-014][c-common-pitfalls-cpit-014],
[CPIT-015][c-common-pitfalls-cpit-015], [CPIT-017][c-common-pitfalls-cpit-017].

**Source context:** [asan][c-common-pitfalls-ref-asan]; [ubsan][c-common-pitfalls-ref-ubsan].

#### Local examples

**Failure fragment (do not execute):**

Function-body fragment. index and `item_count` are `size_t`; items refers to a validated array
containing `item_count` elements. Pointer validity and lifetime are preconditions, not inferred from
a non-NULL value.

```c
value = items[item_count];
```

**Contextual example:**

Function-body fragment. index and `item_count` are `size_t`; items refers to a validated array
containing `item_count` elements. Pointer validity and lifetime are preconditions, not inferred from
a non-NULL value.

```c
if (index >= item_count)
{
        ret = -ERANGE;
        goto function_output;
}

value = items[index];
```

---

<a id="72-c-behavior-categories"></a> <a id="cstyle-100-c-behavior-categories"></a>
<a id="cstyle-100"></a>

<a id="cstyle-100-7-2-c-behavior-categories"></a>

### CSTYLE-100: C Behavior Categories

**Class:** PORTABILITY / CORRECTNESS. **Obligation:** project requirement.

Distinguish undefined behavior, implementation-defined behavior, unspecified behavior, and a defined
operation that violates the product contract. Do not rely on undefined behavior. Record
implementation-defined choices in the target profile. Do not depend on one evaluation order when C
leaves it unspecified. Defined unsigned wraparound may still violate a size, deadline, or security
invariant and must be justified at the use site.

**Failure scenarios:** [CPIT-019][c-common-pitfalls-cpit-019],
[CPIT-020][c-common-pitfalls-cpit-020], [CPIT-034][c-common-pitfalls-cpit-034],
[CPIT-037][c-common-pitfalls-cpit-037], [CPIT-041][c-common-pitfalls-cpit-041],
[CPIT-044][c-common-pitfalls-cpit-044].

**Source context:** [c23][c-common-pitfalls-ref-c23].

#### Local examples

**Layout example (not executable):**

```text
Target assumption file classifies each relied-on behavior as defined,
implementation-defined, unspecified, or prohibited UB and ties
implementation-defined choices to toolchain evidence
```

**Noncompliant fragment (do not copy):**

Layout, diagnostic, or contract example. This block is not executable C.

```text
Code relies on signed overflow, object representation, or shift behavior
because “it works with our current compiler” without classifying the C
behavior
```

---

<a id="73-integer-overflow-and-shift-safety"></a>
<a id="cstyle-101-integer-overflow-and-shift-safety"></a> <a id="cstyle-101"></a>

<a id="cstyle-101-7-3-integer-overflow-and-shift-safety"></a>

### CSTYLE-101: Integer Overflow and Shift Safety

**Class:** CORRECTNESS. **Obligation:** project requirement.

Check signed arithmetic before overflow and unsigned size arithmetic before unintended wraparound.
Shift counts must be nonnegative and below the width of the promoted left operand. Use suitable
unsigned operands for masks and avoid assuming narrow integer operands remain narrow after
promotion. Distinguish intentional modular arithmetic from bounds calculations. The target profile
must define any relied-on signed-shift behavior.

**Failure scenarios:** [CPIT-034][c-common-pitfalls-cpit-034],
[CPIT-038][c-common-pitfalls-cpit-038], [CPIT-039][c-common-pitfalls-cpit-039].

**Source context:** [c23][c-common-pitfalls-ref-c23].

**Complete example:** [worked sources][c-code-standard-worked-example].

#### Local examples

**Contextual example:**

Function-body fragment after validating shift as a nonnegative uint32_t count. Include <stdint.h>
and the error header. ret is first at function entry. The fixed width belongs to the uint32_t
operand, not to an assumed width of int.

```c
uint32_t result_u32 = 0u;
uint32_t value_u32  = 0u;

if (shift >= 32u)
{
        ret = -ERANGE;
        goto function_output;
}

value_u32  = 1u;
result_u32 = value_u32 << shift;
```

---

<a id="74-checked-integer-arithmetic"></a> <a id="cstyle-102-checked-integer-arithmetic"></a>
<a id="cstyle-102"></a>

<a id="cstyle-102-7-4-checked-integer-arithmetic"></a>

### CSTYLE-102: Checked Integer Arithmetic

**Class:** CORRECTNESS. **Obligation:** project requirement.

Use a checked arithmetic foundation API with a documented overflow result and output-state
guarantee. C23 `<stdckdint.h>` is an option when the qualified toolchain provides it. Compiler
builtins belong in an adapter; portable bounds checks are a supported fallback. Do not test overflow
by first computing a signed overflowing result. Test zero, exact limits, and one beyond each limit.

**Failure scenarios:** [CPIT-018][c-common-pitfalls-cpit-018],
[CPIT-046][c-common-pitfalls-cpit-046], [CPIT-047][c-common-pitfalls-cpit-047],
[CPIT-048][c-common-pitfalls-cpit-048], [CPIT-049][c-common-pitfalls-cpit-049],
[CPIT-050][c-common-pitfalls-cpit-050], [CPIT-068][c-common-pitfalls-cpit-068],
[CPIT-081][c-common-pitfalls-cpit-081].

**Source context:** [c23][c-common-pitfalls-ref-c23].

**Complete example:** [worked sources][c-code-standard-worked-example].

#### Local examples

**Contextual C example:**

```c
size_t total_size = 0u;

bool has_overflow = false;

has_overflow = ARITH_addSize(header_size, payload_size, &total_size);
if (has_overflow)
{
        ret = -ENOMEM;
        goto function_output;
}
```

**Contextual C example:**

```c
size_t alignment_adjustment = 0u;

bool has_overflow = false;

if ((align == 0u) || ((align & (align - 1u)) != 0u))
{
        ret = -EINVAL;
        goto function_output;
}

alignment_adjustment = align - 1u;
has_overflow         = ARITH_addSize(size, alignment_adjustment, &rounded_size);
if (has_overflow)
{
        ret = -ENOMEM;
        goto function_output;
}

rounded_size &= ~alignment_adjustment;
```

---

<a id="75-division-and-remainder-safety"></a> <a id="cstyle-103-division-and-remainder-safety"></a>
<a id="cstyle-103"></a>

<a id="cstyle-103-7-5-division-and-remainder-safety"></a>

### CSTYLE-103: Division and Remainder Safety

**Class:** CORRECTNESS. **Obligation:** project requirement.

Reject a zero divisor before `/` or `%`. For signed types, also reject the minimum representable
value divided or reduced modulo negative one when the mathematical quotient cannot be represented.
Validate externally derived divisors and intermediate results. Do not assume a processor exception
supplies the required C or product error behavior.

**Failure scenarios:** [CPIT-034][c-common-pitfalls-cpit-034],
[CPIT-040][c-common-pitfalls-cpit-040], [CPIT-046][c-common-pitfalls-cpit-046],
[CPIT-051][c-common-pitfalls-cpit-051].

**Source context:** [c23][c-common-pitfalls-ref-c23].

#### Local examples

**Contextual C example:**

```c
if (divisor == 0)
{
        ret = -EDOM;
        goto function_output;
}

if ((dividend == INT_MIN) && (divisor == -1))
{
        ret = -ERANGE;
        goto function_output;
}

quotient  = dividend / divisor;
remainder = dividend % divisor;
```

---

<a id="76-bitwise-and-mask-rules"></a> <a id="cstyle-104-bitwise-and-mask-rules"></a>
<a id="cstyle-104"></a>

<a id="cstyle-104-7-6-bitwise-and-mask-rules"></a>

### CSTYLE-104: Bitwise and Mask Rules

**Class:** CORRECTNESS. **Obligation:** project requirement.

Use named protocol or register masks and a suitable unsigned integer domain. Validate shift counts
and unknown bits. A bitmask field is not necessarily a sequential enum. State which bits the module
may modify and how reserved bits are handled. Avoid using a native C bitfield layout as a portable
wire format.

#### Local examples

**Contextual C example:**

```c
#define PERM_FLAG_READ  ((uint32_t)(1U << 0U)) /* bit 0 */
#define PERM_FLAG_WRITE ((uint32_t)(1U << 1U)) /* bit 1 */
#define PERM_FLAG_EXEC  ((uint32_t)(1U << 2U)) /* bit 2 */

uint32_t permissions = 0u;

permissions = PERM_FLAG_READ | PERM_FLAG_WRITE;

if ((permissions & PERM_FLAG_EXEC) != 0u)
        EX_runExecutable();
```

**Noncompliant fragment (do not copy):**

```c
if ((permissions & 0x05u) != 0u)
    EX_runExecutable();
```

---

<a id="77-hardware-register-read-modify-write-rules"></a>
<a id="cstyle-105-hardware-register-read-modify-write-rules"></a> <a id="cstyle-105"></a>

<a id="cstyle-105-7-7-hardware-register-read-modify-write-rules"></a>

### CSTYLE-105: Hardware Register Read-Modify-Write Rules

**Class:** CORRECTNESS / SAFETY. **Obligation:** project requirement.

Follow the device manual for access width, alignment, ordering, and read/write side effects.
Read-clear, write-one-to-clear, write-only, and set/clear alias registers cannot be handled by a
generic read-modify-write recipe. Reserved bits must receive the manual's required values, which are
not always their old values. Handle competing writers and interrupt/DMA interaction through the
target protocol. A volatile pointer alone does not supply these guarantees.

**Failure scenarios:** [CPIT-034][c-common-pitfalls-cpit-034],
[CPIT-083][c-common-pitfalls-cpit-083], [CPIT-084][c-common-pitfalls-cpit-084],
[CPIT-085][c-common-pitfalls-cpit-085].

#### Local examples

**Contextual C example:**

```c
#define REG_CTRL_ENABLE_MASK ((uint32_t)(1U << 0U))
#define REG_CTRL_MODE_MASK   ((uint32_t)(3U << 4U))

uint32_t reg_value = 0u;

/* REG_CTRL is documented as ordinary read/write; RMW is permitted. */
reg_value  = MMIO_read32(REG_CTRL_ADDRESS);
reg_value &= ~REG_CTRL_MODE_MASK;
reg_value |= REG_CTRL_ENABLE_MASK;
MMIO_write32(REG_CTRL_ADDRESS, reg_value);
```

---

<a id="78-floating-point"></a> <a id="cstyle-106-floating-point"></a> <a id="cstyle-106"></a>

<a id="cstyle-106-7-8-floating-point"></a>

### CSTYLE-106: Floating Point

**Class:** CORRECTNESS / SAFETY. **Obligation:** project requirement.

Do not use floating point for allocator-core addresses, capacities, alignment, or metadata sizing.
This is a project restriction aimed at exact integer invariants, not a claim that every
floating-point operation is undefined or nondeterministic. Non-core tools may use floating point
under a documented precision, rounding, exceptional-value, and target policy.

**Failure scenarios:** [CPIT-046][c-common-pitfalls-cpit-046],
[CPIT-055][c-common-pitfalls-cpit-055].

#### Local examples

**Contextual C example:**

```c
if (!isfinite(sensor_value))
{
        ret = -ERANGE;
        goto function_output;
}
```

---

<a id="79-boolean-domain-rules"></a> <a id="cstyle-159"></a>

<a id="cstyle-159-7-9-boolean-domain-rules"></a>

### CSTYLE-159: Boolean Domain Rules

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-145: Boolean collapses a multi-state result][c-common-pitfalls-cpit-145]

`bool` represents a logical predicate, not a numeric, error, count, flag word, or multi-state
domain. Do not rely on implicit conversion of a status, byte count, descriptor, or enum into a
boolean result.

Use a status type for fallible actions and an enum for three or more states. Do not use boolean
arithmetic such as adding a predicate directly to a counter; make the conditional state transition
explicit.

#### Local examples

**Contextual C example:**

```c
bool   is_ready = false;
mode_t mode     = MODE_IDLE;
```

**Noncompliant fragment (do not copy):**

```c
bool state = 2; /* multi-state domain forced into bool */
```

---

<a id="710-logical-and-bitwise-operator-separation"></a> <a id="cstyle-160"></a>

<a id="cstyle-160-7-10-logical-bitwise-operator-separation"></a>

### CSTYLE-160: Logical and Bitwise Operator Separation

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-144: Logical and bitwise operator confusion][c-common-pitfalls-cpit-144]

Use `&&`, `||`, and `!` for logical state. Use `&`, `|`, `^`, and `~` for documented bit patterns. A
bit-mask test must compare the masked value explicitly with zero or the expected mask.

Do not substitute bitwise operators for logical operators merely to remove a branch. Constant-time
code uses a reviewed security primitive with a separate contract.

#### Local examples

**Contextual C example:**

```c
if (is_ready && is_enabled)
        ret = EX_start();

if ((flags & FLAG_READY) != 0u)
        ready_count++;
```

---

<a id="81-variable-initialization"></a> <a id="cstyle-107-variable-initialization"></a>
<a id="cstyle-107"></a>

<a id="cstyle-107-8-1-variable-initialization"></a>

### CSTYLE-107: Variable Initialization

**Class:** PROJECT_STYLE / CORRECTNESS / ANALYZABILITY. **Obligation:** project requirement.

Declare and initialize all automatic variables at the beginning of the function, before argument
validation or other executable statements. Do not declare or initialize variables inside a loop or a
scope smaller than the function. Assignments after declaration are allowed; they are not new
declarations.

The return variable comes first: normally `int ret` initialized to success, or the contract-required
result type permitted by CSTYLE-064. Group remaining declarations as arrays, structs, enums,
pointers, and common scalar variables. Within a category use this order where applicable: `void *`,
module-specific types, other custom types, char variants, double variants, float variants, `size_t`,
`uintptr_t`/`intptr_t`, fixed-width unsigned integers, and int variants.

Pointers start as typed `NULL`. Arrays and structs use semantic aggregate initialization such as
`{ 0 }`; enums use their documented initial value; numeric scalars start from a zero-like literal
with the appropriate suffix. Booleans start as `false`. Assign required nonzero operational values
only after argument validation. Read-only constants may be macros or immutable file-scope tables,
outside this automatic-variable rule.

A zero-like initializer is bookkeeping, not permission to use an invalid object or activate
hardware. Establish the required safe operating state before the first effect or publication. A
descriptor with zero as a valid resource needs a separate acquired flag or a validated sentinel
assignment before cleanup could release it. Do not replace semantic initialization with `memset` for
arbitrary pointer or floating-point members.

Use the corresponding pointer cast for every explicit `NULL`, as required by CSTYLE-078. Cleanup
variables also belong at function entry; no declaration may appear after `function_output`.

**Failure scenarios:** [CPIT-012][c-common-pitfalls-cpit-012],
[CPIT-034][c-common-pitfalls-cpit-034], [CPIT-036][c-common-pitfalls-cpit-036],
[CPIT-083][c-common-pitfalls-cpit-083], [CPIT-088][c-common-pitfalls-cpit-088].

**Complete example:** [worked sources][c-code-standard-worked-example].

#### Local examples

**Contextual example:**

Function definition. Include <stdint.h>, <stdlib.h>, <errno.h> and its own declaring header. Both
pointers must refer to live correctly aligned uint32_t objects. This does not validate arbitrary
non-NULL addresses.

```c
int SAMPLE_readValue(const uint32_t *source, uint32_t *value_out)
{
        int ret = EXIT_SUCCESS;

        uint32_t value = 0u;

        if ((source == (const uint32_t *)(NULL)) ||
            (value_out == (uint32_t *)(NULL)))
        {
                ret = -EINVAL;
                goto function_output;
        }

        value      = *source;
        *value_out = value;

function_output:
        return ret;
}
```

---

<a id="82-array-initialization"></a> <a id="cstyle-108-array-initialization"></a>
<a id="cstyle-108"></a>

<a id="cstyle-108-8-2-array-initialization"></a>

### CSTYLE-108: Array Initialization

**Class:** PORTABILITY / CORRECTNESS. **Obligation:** project requirement.

Use bounded arrays with compile-time constant extents in the portable project profile. VLAs and
`alloca` are prohibited. Use `{ 0 }` or designated initializers for semantic initialization; do not
assume `memset` is equivalent for arbitrary object types. C23 empty initialization is permitted only
in a qualified C23 profile. GNU range designators remain an extension. Account for stack usage and
task/interrupt nesting, not only an individual array's size. Automatic declarations still follow
CSTYLE-107: initial aggregate values are zero-like at function entry; operational member/element
assignments follow validation. Nonzero immutable fixture tables in the example have file scope.

**Related controls:** [CSTYLE-001][c-code-standard-cstyle-001],
[CSTYLE-108][c-code-standard-cstyle-108].

**Failure scenarios:** [CPIT-034][c-common-pitfalls-cpit-034],
[CPIT-042][c-common-pitfalls-cpit-042].

**Source context:** [c23][c-common-pitfalls-ref-c23].

**Complete example:** [worked sources][c-code-standard-worked-example].

#### Local examples

**Contextual C example:**

```c
int arr[MAX_LEN] = { 0 };
```

**Contextual C example:**

```c
typedef enum Status
{
        STATUS_OFF = 0u,
        STATUS_ON  = 1u,
        STATUS_MAX = 2u
} status_t;

status_t status_array[STATUS_MAX] = {
        [STATUS_OFF] = STATUS_ON,
        [STATUS_ON]  = STATUS_OFF,
};
```

---

<a id="83-object-zeroing-and-memset"></a> <a id="cstyle-137"></a>

<a id="cstyle-137-8-3-object-zeroing-and-memset"></a>

### CSTYLE-137: Object Zeroing and `memset`

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-133: Representation zeroing mistaken for semantic
  initialization][c-common-pitfalls-cpit-133]
- [CPIT-057: `memcpy`/`memset` invalid pointer][c-common-pitfalls-cpit-057]
- [CPIT-098: Missing secure erase][c-common-pitfalls-cpit-098]

Use C initialization syntax to establish the semantic default value of a typed object. Writing zero
bytes with `memset()` may establish that value only when the type's documented representation
contract defines all-bits-zero as its semantic default.

Avoid treating an arbitrary representation as a semantic value:

`memset()` remains appropriate for raw byte buffers and types with an explicit all-bits-zero
contract. It is not a secure-erasure primitive; secret clearing must use the project secure-zero
wrapper required by the standard-library policy.

#### Local examples

**Contextual C example:**

```c
config_t config = { 0 };
```

**Noncompliant fragment (do not copy):**

```c
config_t config;

memset(&config, 0, sizeof(config));
```

---

<a id="91-downstream-interpreter-boundaries"></a>
<a id="cstyle-109-downstream-interpreter-boundaries"></a> <a id="cstyle-109"></a>

<a id="cstyle-109-9-1-downstream-interpreter-boundaries"></a>

### CSTYLE-109: Downstream Interpreter Boundaries

**Class:** SECURITY. **Obligation:** project requirement.

Untrusted data must remain data when passed to another interpreter or language.

- do not build SQL by concatenating or formatting untrusted values
- bind SQL values through the database driver's parameter interface
- do not build shell command strings from untrusted values
- when process launch is required, use a fixed executable and structured argv
- encode browser output for its exact HTML, attribute, URL, CSS, or script context
- do not pass untrusted text to dynamic evaluators, expression engines, or JITs unless that
  interpreter is an explicit isolated product feature
- format strings remain literals or otherwise trusted program data
- input validation does not replace interpreter-specific parameterization or output encoding The
  same value can be safe in one context and unsafe in another. Validate the value's domain first,
  then use the destination API that preserves the data/code boundary.

**Failure scenarios:** [CPIT-093][c-common-pitfalls-cpit-093],
[CPIT-095][c-common-pitfalls-cpit-095], [CPIT-103][c-common-pitfalls-cpit-103],
[CPIT-105][c-common-pitfalls-cpit-105], [CPIT-106][c-common-pitfalls-cpit-106],
[CPIT-107][c-common-pitfalls-cpit-107], [CPIT-109][c-common-pitfalls-cpit-109].

**Source context:** [sql][c-common-pitfalls-ref-sql]; [xss][c-common-pitfalls-ref-xss].

#### Local examples

**Contextual C example:**

```c
ret = DB_queryPrepared(db, "SELECT * FROM account WHERE id=?", account_id);
```

**Noncompliant fragment (do not copy):**

```c
snprintf(query, sizeof(query), "SELECT * FROM account WHERE id=%s", user_input);
```

---

<a id="92-authentication-and-authorization-gates"></a>
<a id="cstyle-110-authentication-and-authorization-gates"></a> <a id="cstyle-110"></a>

<a id="cstyle-110-9-2-authentication-and-authorization-gates"></a>

### CSTYLE-110: Authentication and Authorization Gates

**Class:** SECURITY. **Obligation:** project requirement.

Critical operations must authenticate and authorize at the trusted boundary.

- authentication establishes caller identity; authorization is a separate check
- deny privileged operations by default when required context is missing
- check the requested object/resource as well as the requested operation
- a valid user-controlled object ID does not prove authority over that object
- debug, factory, diagnostic, calibration, update, and secret-management paths follow the same
  authorization model as normal privileged APIs
- do not rely on UI visibility, network location, symbol hiding, or a magic value as the
  authorization decision
- state-changing cookie-authenticated web operations must use the project's approved
  request-intent/anti-CSRF mechanism
- authorization failure must leave protected state unchanged Prefer narrow capability/context inputs
  over global implicit privilege state.

**Failure scenarios:** [CPIT-093][c-common-pitfalls-cpit-093],
[CPIT-105][c-common-pitfalls-cpit-105], [CPIT-108][c-common-pitfalls-cpit-108],
[CPIT-112][c-common-pitfalls-cpit-112], [CPIT-113][c-common-pitfalls-cpit-113].

**Source context:** [authorization][c-common-pitfalls-ref-authorization].

#### Local examples

**Contextual C example:**

```c
ret = AUTH_requireCapability(session, CAP_WRITE_CONFIG);
if (ret != EXIT_SUCCESS)
        goto function_output;
ret = CONFIG_write(request);
```

**Noncompliant fragment (do not copy):**

```c
CONFIG_write(request); /* possession of object_id treated as authority */
```

---

<a id="93-untrusted-structured-input-and-file-ingress"></a>
<a id="cstyle-111-untrusted-structured-input-and-file-ingress"></a> <a id="cstyle-111"></a>

<a id="cstyle-111-9-3-untrusted-structured-input-and-file-ingress"></a>

### CSTYLE-111: Untrusted Structured Input and File Ingress

**Class:** SECURITY. **Obligation:** project requirement.

Decode untrusted structured input into explicit semantic data before it can become runtime state.

- enforce a total byte limit before parsing
- enforce field lengths, collection counts, nesting depth, and recursion limits
- validate schema/protocol version before constructing runtime objects
- decode into initialized DTOs; do not deserialize raw C object representations
- never restore pointers, function pointers, allocator metadata, or privileged state directly from
  untrusted bytes
- uploaded files need a content/format allowlist, size limit, generated storage name, and a
  non-executable/non-search-path destination
- do not trust client-supplied filename extensions or MIME labels as proof of content type
- disable XML external entities, DTD entity expansion, and network/file entity resolution unless the
  protocol explicitly requires and constrains them
- validate semantic relationships after syntactic parsing succeeds A parser success status does not
  by itself make decoded data trusted.

**Failure scenarios:** [CPIT-094][c-common-pitfalls-cpit-094],
[CPIT-105][c-common-pitfalls-cpit-105], [CPIT-110][c-common-pitfalls-cpit-110],
[CPIT-111][c-common-pitfalls-cpit-111], [CPIT-122][c-common-pitfalls-cpit-122].

**Source context:** [validation][c-common-pitfalls-ref-validation];
[upload][c-common-pitfalls-ref-upload]; [xxe][c-common-pitfalls-ref-xxe].

#### Local examples

**Contextual C example:**

```c
ret = PARSER_decodeBounded(input, input_size, &dto);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

**Noncompliant fragment (do not copy):**

```c
runtime_object = *((runtime_object_t *)input); /* raw bytes become privileged runtime object */
```

---

<a id="94-outbound-request-destination-validation"></a>
<a id="cstyle-112-outbound-request-destination-validation"></a> <a id="cstyle-112"></a>

<a id="cstyle-112-9-4-outbound-request-destination-validation"></a>

### CSTYLE-112: Outbound Request Destination Validation

**Class:** SECURITY. **Obligation:** project requirement.

Apply an explicit outbound destination policy to schemes, ports, resolved addresses, redirects,
proxies, and credentials. Validate the actual connection destination so that a second DNS resolution
cannot bypass the decision. Bound redirects, response size, work, and connection/read time. Restrict
network egress where the deployment permits it. A syntactically valid URL is not an authorized
destination. See the SSRF source and the product's service policy.

**Failure scenarios:** [CPIT-105][c-common-pitfalls-cpit-105],
[CPIT-114][c-common-pitfalls-cpit-114].

**Source context:** [ssrf][c-common-pitfalls-ref-ssrf].

#### Local examples

**Contextual C example:**

```c
ret = NET_validateDestination(url, &approved_endpoint);
if (ret == EXIT_SUCCESS)
        ret = HTTP_get(&approved_endpoint, reply);
```

**Noncompliant fragment (do not copy):**

```c
ret = HTTP_get(request->url, reply); /* attacker controls SSRF destination */
```

---

<a id="95-resource-budgets-and-throttling"></a>
<a id="cstyle-113-resource-budgets-and-throttling"></a> <a id="cstyle-113"></a>

<a id="cstyle-113-9-5-resource-budgets-and-throttling"></a>

### CSTYLE-113: Resource Budgets and Throttling

**Class:** SECURITY. **Obligation:** project requirement.

Every externally influenced resource needs a hard engineering budget. Budget as applicable:

- input and output bytes
- allocation size and total live allocation
- object, element, and file counts
- parser nesting and recursion depth
- queue depth and outstanding requests
- thread/task/process count
- retries and redirects
- open file/socket/handle count
- CPU/work units and wall-clock time Checking arithmetic overflow is necessary but not sufficient. A
  mathematically valid size can still exceed the product's safe resource budget.

**Failure scenarios:** [CPIT-045][c-common-pitfalls-cpit-045],
[CPIT-046][c-common-pitfalls-cpit-046], [CPIT-083][c-common-pitfalls-cpit-083],
[CPIT-093][c-common-pitfalls-cpit-093], [CPIT-105][c-common-pitfalls-cpit-105],
[CPIT-115][c-common-pitfalls-cpit-115].

**Source context:** [validation][c-common-pitfalls-ref-validation].

#### Local examples

**Contextual C example:**

```c
if (request->item_count > REQUEST_MAX_ITEMS)
{
        ret = -E2BIG;
        goto function_output;
}
```

**Noncompliant fragment (do not copy):**

```c
for (i = 0u; i < request->item_count; i++)
{
    allocateItem();
} /* unbounded external work */
```

---

<a id="96-security-exception-and-fail-closed-behavior"></a>
<a id="cstyle-114-security-exception-and-fail-closed-behavior"></a> <a id="cstyle-114"></a>

<a id="cstyle-114-9-6-security-exception-and-fail-closed-behavior"></a>

### CSTYLE-114: Security Exception and Fail-Closed Behavior

**Class:** SECURITY. **Obligation:** project requirement.

Deny the protected operation after failed authentication, authorization, integrity, freshness,
configuration, or policy checks. Do not let missing data, timeouts, parse errors, or storage errors
select a more permissive branch. Use stable external errors and retain approved internal diagnostics
without secrets. If denying an operation conflicts with physical safety, the hazard analysis must
define the safe degraded state; neither a blanket shutdown nor continued operation is universally
safe.

**Failure scenarios:** [CPIT-068][c-common-pitfalls-cpit-068],
[CPIT-088][c-common-pitfalls-cpit-088], [CPIT-105][c-common-pitfalls-cpit-105],
[CPIT-120][c-common-pitfalls-cpit-120].

**Source context:** [authorization][c-common-pitfalls-ref-authorization].

#### Local examples

**Contextual C example:**

```c
if (security_config_valid)
        authorization_required = true;
else
        ret = -EACCES;
```

**Noncompliant fragment (do not copy):**

```c
if (!security_config_valid)
{
    authorization_required = false; /* permissive fallback */
}
```

---

<a id="97-loader-and-search-path-safety"></a> <a id="cstyle-115-loader-and-search-path-safety"></a>
<a id="cstyle-115"></a>

<a id="cstyle-115-9-7-loader-and-search-path-safety"></a>

### CSTYLE-115: Loader and Search-Path Safety

**Class:** SECURITY. **Obligation:** project requirement.

Runtime code and privileged tools must not let untrusted search state choose executable content.

- use absolute or application-controlled locations for shared libraries, plugins, helpers,
  configuration, and executable resources
- do not search the current working directory for privileged/runtime components
- sanitize or ignore inherited loader/search environment variables when the security model does not
  trust the launching environment
- allowlist plugin/component identities and versions
- verify signatures, hashes, or another approved authenticity/integrity property before loading when
  required by the product threat model
- do not make a writable data/upload directory an executable/plugin search path
- keep loader policy centralized behind one adapter rather than scattered calls See the [C Module
  Architecture][c-module-architecture] for dependency, artifact, and runtime-plugin boundary
  ownership.

**Failure scenarios:** [CPIT-105][c-common-pitfalls-cpit-105],
[CPIT-118][c-common-pitfalls-cpit-118], [CPIT-121][c-common-pitfalls-cpit-121].

**Source context:** [supply-chain][c-common-pitfalls-ref-supply-chain].

#### Local examples

**Contextual C example:**

```c
ret = LOADER_openApproved("/usr/lib/project/plugin.so", &plugin);
```

**Noncompliant fragment (do not copy):**

```c
plugin = dlopen(getenv("PLUGIN_PATH"), RTLD_NOW);
```

---

<a id="cstyle-243"></a>

<a id="cstyle-243-comment-intent-and-constraints"></a>

### CSTYLE-243: Comments Explain Contracts, Reasons, and Non-Obvious Constraints

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

Comments shall add information that the executable statements cannot express cleanly: ownership,
ordering, hardware behavior, protocol constraints, invariants, workarounds, proof assumptions, or
the reason an apparently simpler implementation is wrong. Do not narrate straightforward syntax line
by line.

A comment attached to a workaround must name the constraint that keeps the workaround necessary. A
copied or moved block must carry only comments that remain true at the new location.

Use the [C Documentation Standard](c-documentation.md) to construct the file and entity comment
blocks in source order, select required/optional fields, and validate Doxygen output.

#### Local examples

**Contextual example:**

Contract-header excerpt; include <stddef.h>. The comment states the lifetime that the signature
cannot encode.

```c
/* The callback borrows input only until it returns. */
typedef int (*sink_write_cb_t)(void *context, const unsigned char *input,
                               size_t input_size_bytes);
```

---

<a id="cstyle-244"></a>

<a id="cstyle-244-no-commented-out-code"></a>

### CSTYLE-244: Commented-Out Production Code Is Prohibited

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

Do not keep disabled implementation code in comments. Version control owns source history. Temporary
diagnostic code belongs in a local change or an explicit debug build feature with an owner and
removal policy.

Comments may contain short pseudo-code or examples when they document an algorithm; they must not
function as an alternate implementation waiting to be uncommented.

#### Local examples

**Contextual example:**

Public declaration for the maintained implementation. Removed implementations remain in version
control, not as commented-out alternate code.

```c
int MODULE_process(module_t *module);
```

---

<a id="cstyle-245"></a>

<a id="cstyle-245-searchable-diagnostic-strings"></a>

### CSTYLE-245: Searchable Diagnostics Stay Textually Stable

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-119: Log injection or insufficient security logging][c-common-pitfalls-cpit-119]

Do not split a stable diagnostic, assertion message, panic string, protocol token, or other text
that engineers are expected to search literally merely to satisfy the line-length limit. Keep the
exception narrow; ordinary prose and long user text still follow the existing line-breaking rules.

Linux, FreeBSD, PostgreSQL, and OpenSSL all preserve grep-friendly diagnostics for this reason.

#### Local examples

**Contextual example:**

Adapter-only logging fragment. `log_context` and `frame_id` are validated; the wrapper owns `printf`
compatibility. Keep this diagnostic phrase intact for searching.

```c
LOG_error(log_context, "frame checksum mismatch: id=%u", frame_id);
```

---

<a id="cstyle-246"></a>

<a id="cstyle-246-no-editor-modelines"></a>

### CSTYLE-246: Source Files Do Not Configure the Developer's Editor

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

Source files shall not contain Vim modelines, Emacs local-variable blocks, or other file-local
directives that silently alter editor execution or developer settings. Repository-owned formatter,
`.editorconfig`, lint, and CI configuration may define project behavior in reviewable files.

#### Local examples

**Contextual example:**

Header excerpt. Editor configuration belongs in repository tooling, not per-file modelines.

```c
#if !defined(SAMPLE_PACKET_H)
  #define SAMPLE_PACKET_H

  #include <stddef.h>

int PACKET_validateSize(size_t packet_size_bytes);

#endif
```

---

<a id="cstyle-247"></a>

<a id="cstyle-247-public-header-language-baseline"></a>

### CSTYLE-247: Public Headers May Use a Stricter Language Baseline

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

A public ABI header may target an older or narrower C language subset than private implementation
files. The supported public baseline must be named in the build and compatibility policy, and public
declarations shall not force consumers to enable a newer language mode merely because the
implementation uses it.

FFmpeg keeps public headers at C99 while implementation code uses C11; systemd uses a similarly
conservative public surface. This project may choose a different pair of baselines, but the
distinction must be explicit and tested.

#### Local examples

**Contextual example:**

The public header uses the approved common language subset; CI compiles it with every supported
consumer dialect.

```c
#if !defined(SAMPLE_PUBLIC_H)
  #define SAMPLE_PUBLIC_H

  #include <stddef.h>

typedef struct Sample sample_t;
int SAMPLE_capacity(const sample_t *sample, size_t *capacity_bytes);

#endif
```

---

<a id="cstyle-248"></a>

<a id="cstyle-248-implementation-defined-dependencies"></a>

### CSTYLE-248: Implementation-Defined Dependencies Are Documented

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-197: Undocumented implementation-defined dependency][c-common-pitfalls-cpit-197]

If correct output depends on implementation-defined behavior, document the exact assumption and bind
it to a supported target or toolchain contract. Examples include plain-`char` signedness, integer
widths not guaranteed by the selected type, object alignment extensions, bit-field layout,
arithmetic right shift of negative signed values, and ABI calling conventions.

Build or startup assertions should check assumptions that can be checked. Zephyr's coding guidelines
make this traceability requirement explicit.

#### Local examples

**Contextual example:**

Translation-unit scope, after <limits.h>. Reject the unsupported representation rather than silently
changing the protocol.

```c
_Static_assert(CHAR_BIT == 8, "This wire profile requires eight-bit bytes");
```

---

<a id="cstyle-249"></a>

<a id="cstyle-249-linker-assembly-symbol-contract"></a>

### CSTYLE-249: Linker and Assembly Symbols Have an Explicit Representation Contract

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

A symbol provided by a linker script or assembly file is not an ordinary C object unless the
producer defines it as one. A low-level boundary adapter must document whether the symbol denotes an
address, a byte range, a size/value, or actual storage.

When the platform boundary exposes linker information to C, use a normal function prototype backed
by an accessor implemented for that platform, including assembly when necessary. Document its C
calling convention and result representation. Do not add an explicit `extern` object declaration,
even in an adapter, or replace it with a tentative definition that allocates unrelated storage.
The sole explicit `extern` exception remains the guarded C++ linkage block in CMOD-019.

#### Local examples

**Contextual example:**

Platform accessor declaration; include <stddef.h> where this interface's profile permits it.
The implementation owns access to the raw platform symbols.

```c
int PLATFORM_firmwareRange(const unsigned char **begin_out,
                           size_t               *size_bytes_out);
```

---

<a id="cstyle-250"></a>

<a id="cstyle-250-feature-probes-and-portable-fallbacks"></a>

### CSTYLE-250: Newer Language and Compiler Features Need a Portability Path

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

A language feature or compiler extension outside the project's minimum supported baseline requires
either a compile-time feature probe plus a behaviorally equivalent fallback, or an explicit
target/profile restriction. Version-number guessing alone is not sufficient when the toolchain
offers feature-test facilities.

PostgreSQL, Git, FFmpeg, systemd, HAProxy, and other portable projects use this pattern to gain
newer compiler facilities without silently shrinking their supported platform set.

#### Local examples

**Contextual example:**

Compiler-adapter header, not ordinary module code. Both private implementations preserve the same
overflow/output contract.

```c
#if defined(PROJECT_HAS_CHECKED_ARITHMETIC)
  #include "checked_native.h"
#else
  #include "checked_portable.h"
#endif
```

---

<a id="cstyle-251"></a>

<a id="cstyle-251-warning-suppression-policy"></a>

### CSTYLE-251: Warning Suppression Does Not Repair Incorrect Code

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

Treat compiler and static-analysis warnings as defects until review establishes that the construct
is correct. When a warning is a repeatable false positive for an approved construct, suppress it at
the narrowest practical scope and record the tool, diagnostic identifier, reason, and applicable
configuration.

Do not add meaningless casts, dead assignments, unreachable branches, or performance regressions
solely to silence a tool. Project-wide suppressions require an owner and periodic review.

#### Local examples

**Contextual example:**

Function-body fragment. `source_value` is uint32_t; `narrow_value` and ret are declared at entry. No
warning suppression replaces this check.

```c
if (source_value > UINT16_MAX)
{
        ret = -ERANGE;
        goto function_output;
}

narrow_value = (uint16_t)source_value;
```

---

<a id="cstyle-252"></a>

<a id="cstyle-252-generated-source-provenance"></a>

### CSTYLE-252: Generated Source Has Provenance and Is Not Hand-Patched

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

Generated C, headers, tables, decoder code, or register definitions must identify the generator and
input source in a reproducible way. Do not hand-edit generated output unless the generation workflow
explicitly designates an editable region.

CI should regenerate deterministic outputs and fail when committed generated files are stale. A
generated file does not bypass the public ABI, unsafe-API, or security rules that apply to the
artifact it becomes.

#### Local examples

**Contextual example:**

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

<a id="cstyle-253"></a>

<a id="cstyle-253-validate-before-state-mutation"></a>

### CSTYLE-253: Validate Rejectable Preconditions Before Committing State

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-143: Partial mutation before validation failure][c-common-pitfalls-cpit-143]

When an operation can be structured transactionally, evaluate rejectable input, range, permission,
state, capacity, and resource preconditions before the first externally visible mutation. seL4's
decode-then-invoke structure is a strong version of the same discipline.

If validation itself must mutate state or reserve a resource, document the rollback or one-way
transition explicitly. Do not leave a half-applied operation because a check that could have run
earlier failed later.

#### Local examples

**Contextual example:**

Both callbacks are bound and validated before this fragment. The commit contract must define failure
atomicity and exclude changes between validation and commit.

```c
ret = validate_request(validation_context, request);
if (ret != EXIT_SUCCESS)
        goto function_output;
ret = commit_validated(commit_context, request);
```

---

<a id="cstyle-254"></a>

<a id="cstyle-254-library-standard-stream-ownership"></a>

### CSTYLE-254: Library and Core Code Do Not Own Standard Streams

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

Core modules and reusable libraries shall not write directly to `stdout` or `stderr` and shall not
read interactive input from `stdin` unless their public contract is specifically a console
interface. Route diagnostics through the project logging or callback port and return errors through
the normal status contract.

This keeps libraries usable in firmware, daemons, GUIs, tests, services, and embedded hosts without
an accidental process-global I/O policy.

#### Local examples

**Contextual example:**

Consumer-owned callback. No process-wide stdout/stderr ownership or hidden formatting allocation;
the logger binder states blocking/reentrancy and secret-redaction policy.

```c
typedef int (*module_log_cb_t)(void *context, uint32_t event_id,
                               int operation_result);
```

---

<a id="cstyle-255"></a>

<a id="cstyle-255-secure-erasure-primitive"></a>

### CSTYLE-255: Secure Erasure Uses a Non-Elidable Primitive

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-098: Missing secure erase][c-common-pitfalls-cpit-098]

Secrets that require erasure shall be cleared with a project primitive whose contract prevents the
compiler from deleting the write as dead storage on supported toolchains. Plain
`memset(secret, 0, size)` is not sufficient evidence when the object is dead immediately afterward.

Document which secret classes require erasure and the limits of software wiping for copies held in
registers, caches, swap, crash dumps, DMA buffers, or other components.

#### Local examples

**Contextual example:**

security-owned primitive; its adapter must provide and verify a non-elidable erase on the selected
compiler/target. A callback name alone provides no erase guarantee.

```c
ret = wipe_secret(security_context, secret, secret_size_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cstyle-256"></a>

<a id="cstyle-256-large-growable-container-policy"></a>

### CSTYLE-256: Large Growable Objects Need a Fragmentation and Relocation Policy

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-207: Monolithic growth causes allocator or latency failure][c-common-pitfalls-cpit-207]

A container or buffer expected to grow to a large size shall document whether growth requires
relocating one contiguous allocation. In memory-constrained, latency- sensitive, or highly
concurrent systems, consider segmented/chunked storage, bounded blocks, arenas, or another
representation that avoids repeated large reallocations.

This is a representation decision, not a universal ban on contiguous arrays. Redpanda uses chunked
containers for very large collections to avoid pathological contiguous growth; the same
allocator-level concern applies to C containers.

#### Local examples

**Contextual example:**

Private layout excerpt. Allocation, directory growth, lifetime and checked index translation remain
owner contracts; this declaration does not implement a growable collection.

```c
typedef struct SegmentDirectory
{
        unsigned char **segments;
        size_t          segment_capacity_bytes;
        size_t          segment_count;
        size_t          directory_capacity;
} segment_directory_t;
```

---

<a id="cstyle-257"></a>

<a id="cstyle-257-scoped-arena-allocation-lifetime"></a>

### CSTYLE-257: Scoped and Arena Allocations Do Not Escape Their Owner

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-001: Dangling pointer][c-common-pitfalls-cpit-001]
- [CPIT-002: Use-after-free][c-common-pitfalls-cpit-002]
- [CPIT-032: Borrowed pointer stored beyond lifetime][c-common-pitfalls-cpit-032]

Memory obtained from a request, packet, arena, pool, region, scratch allocator, or other scope-bound
allocator shall not be retained beyond that allocator's documented lifetime. A pointer copied out of
the scope remains borrowed; copying the pointer does not extend the allocation lifetime.

When data must survive the scope, copy the semantic value into storage owned by the longer-lived
object or transfer ownership through an API that explicitly supports the operation. Wireshark's
scoped `wmem` allocators are a mature example of binding bulk allocation lifetime to packet/file
processing phases.

#### Local examples

**Contextual example:**

The callback completes before arena reset and retains no pointer. Lifetime ends on the explicit
reset even when the same address is later reused.

```c
ret = consume_in_scope(consumer_context, &borrowed_view);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cstyle-258"></a>

<a id="cstyle-258-text-versus-binary-buffer-semantics"></a>

### CSTYLE-258: Text and Binary Buffers Have Different Contracts

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

A buffer API shall state whether its extent is measured in bytes, code units, characters, or
elements; whether embedded zero bytes are valid; and whether a terminator is required, optional, or
forbidden. Do not reuse a text API for arbitrary binary data merely because both happen to use
`char *` at the ABI level.

#### Local examples

**Contextual example:**

Contract header with <stddef.h>. A ByteView does not promise a NUL terminator or text encoding.

```c
typedef struct ByteView
{
        const unsigned char *data;
        size_t               size_bytes;
} byte_view_t;
```

---

<a id="cstyle-259"></a>

<a id="cstyle-259-one-time-lockless-access-primitive"></a>

### CSTYLE-259: Lockless Shared Access Uses an Approved One-Time Access Primitive

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-069: Data race][c-common-pitfalls-cpit-069]
- [CPIT-200: Compiler transformation breaks a lockless access protocol][c-common-pitfalls-cpit-200]

A lockless protocol that requires one source-level load or store to remain one observable access
shall use the project's reviewed `READ_ONCE__`/`WRITE_ONCE__`-style primitive or a C atomic
operation with the required semantics. Plain access and `volatile` are not interchangeable
substitutes for a concurrency contract.

The primitive must document size/alignment limits and what compiler transformations it prevents. It
does not by itself provide ordering between separate accesses. Linux's `READ_ONCE`/`WRITE_ONCE`
model motivates this separation.

#### Local examples

**Contextual example:**

Inside the synchronization owner. published is initialized `atomic_bool`; a matching release
publication establishes the intended visibility. Do not imitate kernel READ_ONCE with a plain
non-atomic C object.

```c
observed = atomic_load_explicit(&state->published, memory_order_acquire);
```

---

<a id="cstyle-260"></a>

<a id="cstyle-260-raw-atomics-behind-abstractions"></a>

### CSTYLE-260: Raw Atomics Stay Behind a Synchronization Abstraction

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-074: Incorrect atomic memory order][c-common-pitfalls-cpit-074]
- [CPIT-201: Ad hoc atomic protocol lacks one invariant owner][c-common-pitfalls-cpit-201]

Ordinary business/module logic should call a named synchronization operation such as
`QUEUE_tryPush`, `STATE_publish`, or `REF_tryAcquire` instead of constructing a multi-operation
atomic protocol ad hoc at each call site. Low-level atomics remain appropriate inside the owner of
that protocol.

QEMU follows a similar rule: locking and higher-level primitives are the default; bare atomics and
barriers are reserved for reviewed performance-sensitive protocols.

#### Local examples

**Contextual example:**

Consumer-owned port declaration. Its owner defines full/closed states, memory ordering, lifetime and
bounded execution. The consumer does not invent an atomic protocol at the call site.

```c
typedef int (*queue_try_push_cb_t)(void *context, const unsigned char *data,
                                   size_t size_bytes);
```

---

<a id="cstyle-261"></a>

<a id="cstyle-261-memory-barrier-rationale"></a>

### CSTYLE-261: Memory Barriers Require a Pairing and Rationale Comment

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-074: Incorrect atomic memory order][c-common-pitfalls-cpit-074]
- [CPIT-202: Unpaired or unjustified memory barrier][c-common-pitfalls-cpit-202]

Every standalone memory barrier/fence shall have a nearby comment that states what accesses it
orders, which observer matters, and the operation on the other side that completes the ordering
argument. “Required for ordering” is not enough.

Prefer synchronization primitives that embed the ordering when they express the contract. Linux
requires source rationale for memory barriers in submitted patches.

#### Local examples

**Contextual example:**

Synchronization-owner fragment. The one-shot payload is initialized before this store and not
rewritten until a separate reuse protocol grants ownership.

```c
/* Pairs with the consumer acquire-load before reading the payload. */
atomic_store_explicit(&slot->ready, true, memory_order_release);
```

---

<a id="cstyle-262"></a>

<a id="cstyle-262-weakest-proven-memory-ordering"></a>

### CSTYLE-262: Use the Weakest Proven Memory Ordering Contract

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

Do not default every atomic operation to a full fence merely to avoid reasoning about ordering.
Choose the weakest ordering that has a written invariant and passes the project's supported
architecture tests; when that proof does not exist, use the approved conservative primitive rather
than inventing a weaker one locally.

Any relaxed operation in a nontrivial protocol needs a comment or design reference that explains why
relaxed ordering is sufficient.

#### Local examples

**Contextual example:**

Synchronization-owner fragment: this statistic is not a publication signal and wraparound is
explicitly acceptable or excluded by the counter contract. No unrelated data is synchronized.

```c
atomic_fetch_add_explicit(&stats->completed, 1u, memory_order_relaxed);
```

---

<a id="cstyle-263"></a>

<a id="cstyle-263-lock-state-preconditions"></a>

### CSTYLE-263: Lock-State Preconditions Are Visible in the API Contract

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-070: Improper locking][c-common-pitfalls-cpit-070]
- [CPIT-159: Lock-state precondition mismatch][c-common-pitfalls-cpit-159]

A function that requires the caller to hold a specific lock must state that precondition in its
declaration documentation and use the project's naming convention for locked helpers when one
exists, for example `cache_removeLocked`. A wrapper that acquires the lock and a helper that assumes
it is held must not share an ambiguous name. When the supported compiler/toolchain provides
lock-requirement annotations, apply them as an additional machine-checkable contract; Open vSwitch
uses this pattern for mutex and `rwlock` requirements.

QEMU uses `_locked` for this distinction; the exact suffix here remains governed by the project's
naming rules.

#### Local examples

**Contextual example:**

Internal-header declaration. The selected locking annotation, where supported, is provided by a
compiler adapter; the suffix does not itself enforce locking.

```c
/* Caller holds the cache lock for the complete operation. */
static int cache_removeLocked(cache_t *cache, uint32_t key);
```

---

<a id="cstyle-264"></a>

<a id="cstyle-264-floating-point-exceptional-values"></a>

### CSTYLE-264: Floating-Point Exceptional-Value Policy

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-198: Non-finite floating input enters a finite-value algorithm][c-common-pitfalls-cpit-198]

A floating value crossing a trust, file, network, sensor, or hardware boundary must have an explicit
policy for NaN, positive/negative infinity, signed zero, and, where relevant, subnormal values.
Validate with `isfinite`, `isnan`, or an equivalent project primitive before a finite-only physical
or financial range check.

Do not use an ordinary numeric comparison as proof that a NaN has been rejected.

#### Local examples

**Contextual example:**

Non-allocator module with <math.h>. ret and measurement are declared at entry. The target profile
preserves the checks; do not combine this contract with flags that assume all inputs are finite.

```c
if (!isfinite(measurement))
{
        ret = -ERANGE;
        goto function_output;
}
```

---

<a id="cstyle-265"></a>

<a id="cstyle-265-mmio-access-encapsulation"></a>

### CSTYLE-265: Raw MMIO Access Is Confined to the MMIO Owner

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-034: MMIO/DMA pointer treated as ordinary heap][c-common-pitfalls-cpit-034]
- [CPIT-203: Raw MMIO access bypasses the platform register contract][c-common-pitfalls-cpit-203]

The existing `volatile` rule describes the semantics required inside a direct hardware-access
implementation. Ordinary modules shall not scatter raw `volatile T *` register dereferences through
business logic. Route register access through the platform/MMIO owner so width, ordering,
read-clear/W1C behavior, reserved bits, trace hooks, fault injection, and test substitution have one
contract.

OpenTitan's `abs_mmio`/`sec_mmio` split is a strong example of this boundary.

#### Local examples

**Contextual example:**

Module-body fragment. The injected MMIO adapter owns register width, side effects, barriers and any
volatile access.

```c
ret = read_status(mmio_context, &status);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cstyle-266"></a>

<a id="cstyle-266-fault-resistant-encoded-security-state"></a>

### CSTYLE-266: Fault-Resistant Encoded Security State

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-204: Single fault flips a security-critical decision][c-common-pitfalls-cpit-204]

When the physical threat model includes voltage, clock, electromagnetic, laser, or other fault
injection, a security-critical state such as boot verification, debug unlock, lifecycle, or
authorization may require an encoded representation with a deliberate Hamming-distance property
instead of ordinary `bool`/small consecutive enum values.

Use a reviewed hardened-state abstraction; do not invent ad hoc magic constants in application code.
This rule is profile-specific and does not replace ordinary boolean semantics outside the
fault-resistance boundary. OpenTitan's hardened boolean/state primitives provide a concrete
reference pattern. See CWE-1332 and CAPEC-624.

#### Local examples

**Contextual example:**

Security-owned adapter with a declared fault model and invalid-codeword handling. Do not infer fault
resistance from a larger enum or arbitrary hex constants.

```c
ret = decode_hardened_state(security_context, encoded_state,
                            &authorization_state);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cstyle-267"></a>

<a id="cstyle-267-compiler-aware-redundant-security-checks"></a>

### CSTYLE-267: Redundant Fault Checks Must Survive Compilation

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-204: Single fault flips a security-critical decision][c-common-pitfalls-cpit-204]
- [CPIT-205: Compiler removes intended fault-detection redundancy][c-common-pitfalls-cpit-205]

Writing the same C condition twice does not prove two independent machine-level checks exist.
Redundant security checks intended to resist instruction skip or data faults shall use project
hardening primitives that account for compiler optimization and shall be verified in the generated
code for the supported hardened build.

Record the threat model and the failure response. Do not apply redundant-check patterns to ordinary
code where they only add noise.

#### Local examples

**Contextual example:**

The security adapter must verify generated-code properties of its redundant checks; merely repeating
an if statement is not the implementation.

```c
ret = verify_hardened_decision(security_context, decision);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cstyle-268"></a>

<a id="cstyle-268-critical-side-effect-sequence-verification"></a>

### CSTYLE-268: Critical Side-Effect Sequences Can Be Verified

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-206: Fault-sensitive critical action sequence is only end-state
  checked][c-common-pitfalls-cpit-206]

For a fault-sensitive sequence whose order or number of writes is security relevant, verify the
expected sequence or side-effect count when the platform provides a credible mechanism. Checking
only the final register value may miss an instruction skip, duplicate write, or omitted lock/unlock
transition.

Keep the mechanism in the hardware/security owner. OpenTitan `sec_mmio` is a reference for this
style of counted critical access.

#### Local examples

**Contextual example:**

The hardware/security owner verifies required write count and order for its explicit fault model,
not just final register values.

```c
ret = verify_write_sequence(mmio_context, expected_sequence_id);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cstyle-269"></a>

<a id="cstyle-269-hardened-secret-memory-primitives"></a>

### CSTYLE-269: Secret Equality and Fault-Resistant Memory Operations Use Dedicated Primitives

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-199: Secret comparison leaks through timing][c-common-pitfalls-cpit-199]
- [CPIT-098: Missing secure erase][c-common-pitfalls-cpit-098]

Do not use ordinary `memcmp` as a cryptographic equality primitive when timing or early-exit
behavior is observable. Use reviewed constant-time equality, hardened copy, and secure-erasure
primitives whose compiler and fault behavior form part of the contract.

The primitive still needs length, bounds, alignment, and ownership validation before it executes.

#### Local examples

**Contextual example:**

The constant-time primitive is supplied by a qualified security adapter. Inputs have validated
lengths and lifetimes; this fragment makes no timing claim.

```c
ret = compare_secret(security_context, left, right, size_bytes, &is_equal);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cstyle-270"></a>

<a id="cstyle-270-api-and-contract-documentation"></a>

### CSTYLE-270: Public APIs and Non-Obvious Internal Contracts Are Documented

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

Every public API declaration needs enough documentation to use it without inspecting its
implementation. Document units, nullability, ownership, lifetime, thread/ISR context, blocking
behavior, error results, retained pointers, buffer extents, and any required call order that is not
already obvious from the type system.

Non-obvious internal functions that depend on a lock state, hardware sequence, protocol phase, proof
assumption, or unusual lifetime need the same contract at the point of declaration. Zephyr, seL4,
OpenSSL, and HAProxy all treat API/contract comments as part of maintainability rather than optional
decoration.

#### Local examples

**Contextual example:**

Public contract excerpt. The documented guarantee must agree with all implementations and tests.

```c
/* On failure, *read_bytes is zero and the buffer is unchanged. */
int STORAGE_read(storage_t *storage, unsigned char *buffer,
                 size_t capacity_bytes, size_t *read_bytes);
```

---

<a id="cstyle-271"></a>

<a id="cstyle-271-requirement-to-verification-traceability"></a>

### CSTYLE-271: Requirements and Safety-Critical Controls Are Traceable to Verification

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

For a profile that claims safety, security, protocol, or externally specified behavior, each
normative requirement shall have a stable identifier and an evidence path to one or more reviews,
static checks, unit/integration tests, analysis results, or proof artifacts. Generated traceability
must fail when a referenced control or verification artifact disappears.

SQLite's requirement/test extraction and seL4's configuration-specific proofs show two different but
useful implementations of the same principle.

#### Local examples

**Contextual example:**

Metadata shape. Every evidence path must name an actual executed or reviewed artifact and its
configuration.

```c
typedef struct VerificationLink
{
        const char *requirement_id;
        const char *control_id;
        const char *test_id;
        const char *evidence_artifact;
} verification_link_t;
```

---

<a id="cstyle-272"></a>

<a id="cstyle-272-checker-versus-rule-authority"></a>

### CSTYLE-272: Automated Checkers Are Enforcement Tools, Not the Definition of the Rule

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

A lint, style, static-analysis, spelling, or prose checker implements a project rule; it does not
silently redefine that rule. A heuristic diagnostic may be overridden by a reviewed deviation that
names the control, tool diagnostic, rationale, scope, and owner. A checker false positive is fixed
in configuration or suppression policy, not by distorting correct C merely to make the warning
disappear.

Linux `checkpatch` explicitly expects maintainers to justify remaining exceptions.

#### Local examples

**Contextual example:**

A diagnostic is resolved by fixing the code or by a scoped approved deviation. An empty deviation
field does not itself grant permission.

```c
typedef struct DiagnosticDisposition
{
        const char *rule_id;
        const char *tool_version;
        const char *diagnostic_id;
        const char *evidence_path;
        const char *approved_deviation_id;
} diagnostic_disposition_t;
```

---

<a id="cstyle-273"></a>

<a id="cstyle-273-supported-configuration-matrix"></a>

### CSTYLE-273: Supported Configuration Matrix Is Part of Correctness

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

Code controlled by feature macros, architecture options, optional dependencies, word size,
endianness, compiler family, sanitizer mode, or library backend shall be built and tested across the
supported combinations that can change semantics. At minimum, test the configurations touched by a
change and representative opposite values for new boolean feature switches.

Linux tests configuration combinations and multiple architectures; SQLite exercises multiple
compilers/platforms; mature portable projects such as Git, FFmpeg, curl, PostgreSQL, and HAProxy
keep compatibility paths buildable instead of assuming one developer workstation represents the
product.

#### Local examples

**Contextual example:**

Shell commands for the included example; repeat under the other approved configuration dimensions.

```sh
cmake -S examples -B build-c17 -DCMAKE_C_STANDARD=17
cmake --build build-c17
ctest --test-dir build-c17 --output-on-failure
```

---

<a id="cstyle-274"></a>

<a id="cstyle-274-warning-clean-supported-builds"></a>

### CSTYLE-274: Supported Builds Are Warning-Clean Under the Project Warning Policy

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

A supported build configuration must not introduce compiler or linker warnings that are not covered
by a documented deviation. CI should test more than one compiler family when the supported platform
set includes them. Warnings in generated code or third-party imports need an owned suppression
boundary rather than a global disable.

#### Local examples

**Contextual example:**

CMake excerpt for the declared GCC/Clang hosted profile. Other toolchains need reviewed equivalent
warning sets.

```cmake
target_compile_options(sample_policy INTERFACE
    -Wall -Wextra -Wpedantic -Werror
    -Wdeclaration-after-statement)
```

---

<a id="cstyle-275"></a>

<a id="cstyle-275-upstream-code-synchronization-policy"></a>

### CSTYLE-275: Imported Upstream Code Keeps a Deliberate Synchronization Strategy

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

Code copied or vendored from another maintained project must record its upstream origin and update
strategy. Avoid gratuitous local reformatting or semantic forks that make future security and
bug-fix synchronization harder. If local rules require a wrapper or quarantine boundary, keep the
imported implementation intact where practical and adapt it outside that boundary.

U-Boot explicitly preserves foreign subsystem style in selected imported code; nginx warns that
copying private implementations can strand later security fixes.

#### Local examples

**Contextual example:**

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

<a id="cstyle-276"></a>

<a id="cstyle-276-specialized-verification-profiles"></a>

### CSTYLE-276: Specialized Verification Profiles May Use a Stricter C Subset

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

The project may define named profiles such as `general`, `analyzable`, `safety-critical`, `kernel`,
or `formally-verified` that prohibit constructs otherwise permitted by the base standard. A profile
must list its additional restrictions and toolchain assumptions without changing the meaning of the
base rules.

seL4 separates general, kernel, user-level, and verification-specific C constraints; FreeRTOS
records project-wide and inline MISRA deviations for constraints that conflict with its embedded
performance/footprint goals.

#### Local examples

**Contextual example:**

Profile record, not a proof. A stricter verification profile does not silently redefine ordinary
project C.

```c
typedef struct VerificationProfile
{
        const char *compiler_revision;
        const char *language_subset;
        const char *object_model;
        const char *proof_artifact;
} verification_profile_t;
```

---

<a id="cstyle-277"></a>

<a id="cstyle-277-textual-documentation-quality-gate"></a>

### CSTYLE-277: Textual Documentation Is Checked Like Source

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

Normative Markdown and source comments are build inputs. CI shall check, as applicable, spelling,
project acronyms, prose rules, malformed Markdown, unbalanced code fences, broken local anchors,
duplicate control IDs, missing cross-document controls, trailing whitespace, and stale generated
tables.

The checker configuration may allow technical vocabulary, identifiers, API names, standards names,
CVE/CWE identifiers, and compact table cells without disabling the checks for the rest of the
document. This follows the project's COIL-style textual validation model.

#### Local examples

**Contextual example:**

Command entry point for the included validation tooling. Documentation examples and source files are
cross-checked separately from compiler tests.

```sh
python3 examples/tools/validate.py --help
```

---

<a id="cstyle-278"></a>

<a id="cstyle-278-actionable-diagnostics"></a>

### CSTYLE-278: Diagnostics State the Failed Contract and Useful Context

**Class:** PROJECT_POLICY. Apply the scope and requirement words below.

A user-facing error should identify the failed operation or constraint and the minimum safe context
needed to fix it. Prefer “compression level must be 1 through 9” over “invalid argument” when the
caller can act on that information. Do not reveal secrets or internal security state merely to make
a message verbose.

HAProxy treats actionable user-facing diagnostics as a core quality property; the same rule improves
firmware serviceability and incident response.

#### Local examples

**Contextual example:**

Injected diagnostic port. Inputs are non-secret structured values; its failure must not overwrite
the original operation error during cleanup.

```c
ret = report_failure(log_context, operation_id, object_id, failure_code);
```

---

<a id="cstyle-201"></a>

<a id="cstyle-201-performance-evidence"></a>

### CSTYLE-201: Performance Optimizations Require Target-Specific Evidence

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-188: Nonrepresentative performance profile][c-common-pitfalls-cpit-188]

A microarchitectural optimization shall record the target CPU/microarchitecture, compiler and
relevant flags, representative workload, baseline, measurement method, and before/after result. When
the claim concerns cache, TLB, branch, frontend, or memory-order behavior, include the relevant
PMU/perf counters when available.

Do not accept source-level intuition as the only evidence for branchless code, prefetch, padding,
forced inline, non-temporal stores, NUMA placement, or a custom atomic protocol.

**Performance companion:** [CPERF-001][c-code-standard-cperf-001]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

The harness fills every field from the run. This declaration contains no measured result.

```c
typedef struct PerfRunIdentity
{
        const char *source_revision;
        const char *compiler_version;
        const char *compiler_flags;
        const char *target_cpu;
        const char *workload_digest;
        const char *raw_results_path;
} perf_run_identity_t;
```

---

<a id="cstyle-202"></a>

<a id="cstyle-202-cache-line-ownership"></a>

### CSTYLE-202: Cache-Line Ownership Is Explicit for Write-Hot Shared State

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-174: False sharing on write-hot state][c-common-pitfalls-cpit-174]

Frequently modified state owned by different CPUs/threads should not share a cache line when
profiling identifies coherence traffic as a limit. Separate read-mostly fields from write-hot fields
and consider isolating a contended lock from unrelated mutable data.

Padding uses the target cache geometry, not an assumed universal constant. Linux false-sharing
guidance and DPDK data-plane practice motivate this rule.

**Performance companion:** [CPERF-010][c-code-standard-cperf-010]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Private per-owner state, including <stdint.h>. Only its owning thread writes it. Readers use a
synchronized snapshot; this declaration alone provides no synchronization. The placement decision
must also account for adjacent owner objects.

```c
typedef struct OwnerCounters
{
        uint64_t completed_count;
        uint64_t failed_count;
} owner_counters_t;
```

---

<a id="cstyle-203"></a>

<a id="cstyle-203-adjacent-line-prefetch-guard"></a>

### CSTYLE-203: One Cache Line of Padding May Not Defeat Adjacent-Line Prefetch

**Class:** PERFORMANCE. Apply the scope and requirement words below.

When two independent writers remain coupled after nominal cache-line separation, measure whether
adjacent-line or spatial prefetch behavior still brings the neighbor line into the same cache
hierarchy. Additional guard space is permitted only with measured benefit; do not blindly double
every padding region.

**Performance companion:** [CPERF-011][c-code-standard-cperf-011]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Illustrative private target profile with a 64-byte coherence unit, not a universal constant. Include
<stdalign.h>, <stddef.h>, <stdint.h>. Storage must satisfy alignof(owner_slot_t); ordinary malloc is
not assumed to provide this extended alignment. No remote unsynchronized reads/writes.

```c
#define OPT_PROFILE_CACHE_LINE_BYTES ((size_t)(64U))

typedef struct OwnerSlot
{
        alignas(OPT_PROFILE_CACHE_LINE_BYTES) uint64_t completed_count;
} owner_slot_t;

_Static_assert(sizeof(owner_slot_t) % OPT_PROFILE_CACHE_LINE_BYTES == 0u,
               "array stride must preserve the measured isolation");
```

---

<a id="cstyle-204"></a>

<a id="cstyle-204-cpu-local-hot-state-ownership"></a>

### CSTYLE-204: Prefer CPU-Local Ownership Before Shared Atomic Mutation

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Write-hot counters, queues, caches, and statistics should be partitioned per CPU/ thread/lcore when
the algorithm permits it, then aggregated at a lower frequency. Remote writes into another CPU's hot
per-CPU state are discouraged because they can invalidate the owner's cache line and increase
wake-up or service latency.

**Performance companion:** [CPERF-013][c-code-standard-cperf-013]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Owning-thread fragment. `local_count` is retained in owner state; ret is local. flush is a validated
injected callback; failure must mean no batch committed, otherwise retain explicit partial progress.
Flush at deadline and shutdown too; batch size is not the only latency bound.

```c
if (local_count == UINT64_MAX)
{
        ret = -ERANGE;
        goto function_output;
}

local_count++;
if (local_count >= flush_threshold)
{
        ret = flush(owner_context, local_count);
        if (ret != EXIT_SUCCESS)
                goto function_output;
        local_count = 0u;
}
```

---

<a id="cstyle-205"></a>

<a id="cstyle-205-batching-and-atomic-amortization"></a>

### CSTYLE-205: Batch Size Is a Measured Synchronization Parameter

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Amortize locks, atomics, queue publication, allocator metadata updates, and I/O doorbell operations
across a batch when throughput matters and the latency budget permits it. Batch size is part of the
performance contract and must be benchmarked; it is not an arbitrary constant copied from another
system.

**Performance companion:** [CPERF-024][c-code-standard-cperf-024]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Owning-thread body. `flush_batch` must define one commit point and all-or-nothing failure here.
Counters/queues define shutdown flush, maximum delay, overflow and fairness separately. A
partial-success transport needs a progress field instead of this reset.

```c
ret = flush_batch(owner_context, pending_count);
if (ret != EXIT_SUCCESS)
        goto function_output;
pending_count = 0u;
```

---

<a id="cstyle-206"></a>

<a id="cstyle-206-avoid-needless-shared-writes"></a>

### CSTYLE-206: Avoid Needless Shared Writes

**Class:** PERFORMANCE. Apply the scope and requirement words below.

On a measured coherence-bound path, avoid storing a shared value that is already in the desired
state when a cheap read/test can prevent an ownership transition. The optimization must preserve
atomicity and race semantics; a read-before-write is not a general substitute for synchronization.

**Performance companion:** [CPERF-014][c-code-standard-cperf-014]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Inside a synchronization owner with exactly one writer. state is an initialized atomic telemetry
value, not a publication flag and not a compare-and-swap transaction. observed is declared before
validation. Do not apply this form where a repeated release store publishes new payload data.

```c
observed = atomic_load_explicit(state, memory_order_relaxed);
if (observed != requested)
        atomic_store_explicit(state, requested, memory_order_relaxed);
```

---

<a id="cstyle-207"></a>

<a id="cstyle-207-read-mostly-reader-write-minimization"></a>

### CSTYLE-207: Read-Mostly Data Structures Minimize Reader Writes

**Class:** PERFORMANCE. Apply the scope and requirement words below.

For read-dominated structures, evaluate RCU, sequence counters, immutable snapshots, epoch/hazard
schemes, or another design that keeps the common reader path from writing shared cache lines. A
reference count on every read can turn a logically read-only workload into a coherence bottleneck.

Sequence counters are not valid for data containing pointers that a writer can invalidate unless a
separate lifetime scheme makes those pointers safe.

**Performance companion:** [CPERF-026][c-code-standard-cperf-026]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Function-tail fragment. ret and snapshot are declared and initialized at entry. Validated callbacks
implement retention/reclamation, and `release_snapshot` is infallible. A retry counter or read-only
access alone does not protect pointed-to objects.

```c
ret = acquire_snapshot(snapshot_context, &snapshot);
if (ret != EXIT_SUCCESS)
        goto function_output;
ret = lookup(snapshot_context, snapshot, key, out);
function_output : if (snapshot != (const snapshot_t *)(NULL))
{
        release_snapshot(snapshot_context, snapshot);
}

return ret;
```

---

<a id="cstyle-208"></a>

<a id="cstyle-208-static-branch-policy"></a>

### CSTYLE-208: Rare Runtime Features May Use Patchable or Static Branches Only Behind an Adapter

**Class:** PERFORMANCE. Apply the scope and requirement words below.

A feature that is almost always disabled on a critical hot path may use a platform
static-key/patchable-branch facility when the update frequency is low and the target supports it.
Keep runtime text modification, instruction-cache synchronization, and cross-CPU update costs inside
a platform adapter and benchmark both steady-state and toggle cost.

**Performance companion:** [CPERF-032][c-code-standard-cperf-032]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

`feature_is_enabled` is an infallible read-only predicate from a bound port. A platform
implementation may use a static key only under its approved patching, lifetime and I-cache
synchronization contract. The ordinary module performs no text patching.

```c
if (feature_is_enabled(feature_context))
{
        ret = trace(trace_context, event);
        if (ret != EXIT_SUCCESS)
                goto function_output;
}
```

---

<a id="cstyle-209"></a>

<a id="cstyle-209-forced-inline-policy"></a>

### CSTYLE-209: Forced Inline Requires Evidence or a Machine-Level Constraint

**Class:** PERFORMANCE. Apply the scope and requirement words below.

`always_inline`/forced-inline annotations are prohibited by default. Permit them when required by a
low-level ABI/instruction constraint, when compile-time constants remove most of the body, or when
profiling shows a repeatable benefit. Include I-cache and uop-cache/code-size effects in the review;
fewer calls can still execute slower code.

This does not change the existing allowance for small `static inline` type-safe wrappers in headers.

**Performance companion:** [CPERF-029][c-code-standard-cperf-029]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Small module-local helper using <stddef.h>. The infallible accessor return-type exception permits
`size_t` ret but not extra exits. No forced-inline attribute is used; inspect code size and target
results before adding one.

```c
static inline size_t opt_minSize(size_t left, size_t right)
{
        size_t ret = 0u;

        ret = left < right ? left : right;
        goto function_output;

function_output:
        return ret;
}
```

---

<a id="cstyle-210"></a>

<a id="cstyle-210-hot-code-footprint"></a>

### CSTYLE-210: Hot Code Footprint Is a Resource

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-187: Frontend footprint and predictor pressure][c-common-pitfalls-cpit-187]

Loop unrolling, template-like macro expansion, duplicated specialization, and manual inlining shall
be evaluated for instruction-cache and decoded-uop-cache footprint, not only dynamic instruction
count. Split genuinely cold error paths out of a hot region when profiles show frontend pressure.

**Performance companion:** [CPERF-028][c-code-standard-cperf-028]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Run on the produced executable, together with the representative workload and target front-end
events. Byte count alone is not a throughput measurement.

```sh
size build-release/tests_static
objdump -d build-release/tests_static > tests-static.disassembly.txt
```

---

<a id="cstyle-211"></a>

<a id="cstyle-211-branch-versus-branchless-selection"></a>

### CSTYLE-211: Branch Versus Branchless Selection Is Measured

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Do not replace a predictable branch with conditional moves, mask arithmetic, or branchless table
logic by default. Branchless code can lengthen dependency chains and execute work that speculation
would have skipped. Use branchless forms when profile data shows the branch is sufficiently
unpredictable and the transformed work is cheaper on the target.

**Performance companion:** [CPERF-030][c-code-standard-cperf-030]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Function-body fragment with validated inputs and entry-declared selected. Compare it with selected =
left < right ? left : right under the same contract. Neither C syntax guarantees branch or cmov
machine code.

```c
if (left < right)
        selected = left;
else
        selected = right;
```

---

<a id="cstyle-212"></a>

<a id="cstyle-212-branch-hint-policy"></a>

### CSTYLE-212: Branch Probability Hints Need Profile Evidence

**Class:** PERFORMANCE. Apply the scope and requirement words below.

`likely`/`unlikely`, hot/cold attributes, and equivalent compiler hints need a stable probability
assumption or profile evidence. Review the generated layout because the main effect may be code
placement and I-cache behavior rather than dynamic predictor accuracy.

**Performance companion:** [CPERF-031][c-code-standard-cperf-031]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

`OPT_UNLIKELY__` is a project compiler-adapter macro with a plain-expression fallback and single
evaluation. Use only for a measured stable rare path; the probability is not guessed from the name.
ret was assigned outside the condition.

```c
if (OPT_UNLIKELY__(ret != EXIT_SUCCESS))
        goto function_output;
```

---

<a id="cstyle-213"></a>

<a id="cstyle-213-software-prefetch-contract"></a>

### CSTYLE-213: Software Prefetch Has a Distance and Pollution Contract

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-182: Software prefetch distance or usefulness failure][c-common-pitfalls-cpit-182]

A manual prefetch shall identify the target data, prefetch distance, expected reuse, and independent
work between prefetch and demand use. Measure cache pollution, MSHR/ fill-buffer pressure,
TLB/page-walk pressure, and memory bandwidth. Remove a prefetch that arrives too late, evicts useful
data, or adds traffic to an already bandwidth- bound workload.

Compiler movement of prefetch instructions can change the result; compare generated code when
compiler/version is part of the measured dependency.

**Performance companion:** [CPERF-035][c-code-standard-cperf-035]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Entry-declared index/distance/ret; validated callbacks and full array extent. prefetch is infallible
and must not retain the pointer. distance is selected by a measured profile; subtraction is safe
because index < `item_count`. Measure pollution and bandwidth, not just demand misses.

```c
for (index = 0u; index < item_count; index++)
{
        if (distance < item_count - index)
                prefetch(prefetch_context, &items[index + distance]);
        ret = consume(consume_context, &items[index]);
        if (ret != EXIT_SUCCESS)
                goto function_output;
}
```

---

<a id="cstyle-214"></a>

<a id="cstyle-214-memory-latency-pipelining"></a>

### CSTYLE-214: Pipeline Independent Work Around Long-Latency Misses

**Class:** PERFORMANCE. Apply the scope and requirement words below.

When a hot loop is latency-bound and has independent items, overlap demand/prefetch latency with
useful work on other items rather than immediately consuming a just- prefetched address. DPDK packet
pipelines use this pattern extensively.

**Performance companion:** [CPERF-035][c-code-standard-cperf-035]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Entry-declared index/distance/ret; validated callbacks and full array extent. prefetch is infallible
and must not retain the pointer. distance is selected by a measured profile; subtraction is safe
because index < `item_count`. Measure pollution and bandwidth, not just demand misses.

```c
for (index = 0u; index < item_count; index++)
{
        if (distance < item_count - index)
                prefetch(prefetch_context, &items[index + distance]);
        ret = consume(consume_context, &items[index]);
        if (ret != EXIT_SUCCESS)
                goto function_output;
}
```

---

<a id="cstyle-215"></a>

<a id="cstyle-215-hot-wide-access-alignment"></a>

### CSTYLE-215: Hot Wide Loads and Stores Avoid Split Boundaries

**Class:** PERFORMANCE. Apply the scope and requirement words below.

For measured hot wide accesses, align data so the common load/store does not straddle the target's
costly cache-line or vector boundary. Do not add large alignment to all objects without measuring
the memory-footprint tradeoff.

**Performance companion:** [CPERF-019][c-code-standard-cperf-019]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Target-profile declaration. The vector alignment comes from the selected backend and allocation
contract. Capacity 256 is an illustrative private block size, not a performance claim. Tail handling
must remain within the real object extent.

```c
typedef struct PrivateVectorBlock
{
        alignas(OPT_PROFILE_VECTOR_ALIGNMENT) unsigned char bytes[256];
} private_vector_block_t;
```

---

<a id="cstyle-216"></a>

<a id="cstyle-216-split-lock-prohibition"></a>

### CSTYLE-216: Locked and Atomic Operands Must Not Form Split Locks

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-179: Split-lock or cross-line atomic operand][c-common-pitfalls-cpit-179]

An atomic/locked operand shall not intentionally straddle a hardware cache-line boundary on targets
where that can become a split lock or bus lock. Assert or encode alignment in the owning type when
the primitive requires it.

**Performance companion:** [CPERF-012][c-code-standard-cperf-012]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Private target-specific declaration using <stdatomic.h> and <stdalign.h>.
OPT_PROFILE_CACHE_LINE_BYTES is supplied by an approved measured profile. Initialize atomic flags
before publication; alignment, fairness and wait policy remain separate obligations.

```c
typedef struct PrivateLockLayout
{
        alignas(OPT_PROFILE_CACHE_LINE_BYTES) atomic_flag first_lock;
        alignas(OPT_PROFILE_CACHE_LINE_BYTES) atomic_flag second_lock;
} private_lock_layout_t;
```

---

<a id="cstyle-217"></a>

<a id="cstyle-217-store-to-load-forwarding-geometry"></a>

### CSTYLE-217: Store-to-Load Forwarding Geometry Is Measured

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-177: Store-to-load forwarding stall][c-common-pitfalls-cpit-177]

When PMU data reports store-forwarding stalls, inspect preceding stores before modifying the
dependent load. Small stores followed immediately by wider or partially overlapping loads,
mismatched alignment, or non-contained regions can defeat forwarding on common out-of-order CPUs.

Do not contort portable code around one microarchitecture without a specialized implementation and
benchmark evidence.

**Performance companion:** [CPERF-016][c-code-standard-cperf-016]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Local representation example: include <stdint.h>/<string.h>; uint32_t word is declared at function
entry. bytes is valid disjoint storage for sizeof(word) bytes, replacement is uint8_t, and the
intended operation changes the least-significant eight value bits in native representation. Inspect
generated code; this is not portable external byte-order decoding and it does not promise a
forwarding improvement.

```c
memcpy(&word, bytes, sizeof(word));
word = (word & UINT32_C(0xFFFFFF00)) | (uint32_t)replacement;
memcpy(bytes, &word, sizeof(word));
```

---

<a id="cstyle-218"></a>

<a id="cstyle-218-4k-alias-awareness"></a>

### CSTYLE-218: 4 KiB Alias Stalls Are a Target-Specific Diagnostic

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-178: False 4 KiB memory dependency][c-common-pitfalls-cpit-178]

When memory-disambiguation counters show false dependencies, inspect independent hot load/store
addresses with identical page offsets. Adjust allocation/layout only after proving a 4 KiB alias
effect on the target; equal low address bits are not a general C bug.

**Performance companion:** [CPERF-017][c-code-standard-cperf-017]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Harness callbacks collect real addresses/layout on a declared platform. Pointer ordering or
subtraction between unrelated objects is not used. Compare equal/different low page offsets only
inside the platform measurement adapter.

```c
/* Read actual layout and PMU events; do not change buffer alignment blindly. */
ret = record_layout(layout_context, source, destination, size_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
ret = run_variant(benchmark_context, source, destination, size_bytes);
```

---

<a id="cstyle-219"></a>

<a id="cstyle-219-numa-placement-contract"></a>

### CSTYLE-219: NUMA Placement Couples CPU, Memory, IRQ, and Device Locality

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-175: NUMA-remote hot-state placement][c-common-pitfalls-cpit-175]

A NUMA-sensitive hot path should treat thread/CPU affinity, memory placement, IRQ routing, device
locality, and write-hot ownership as one placement problem. Do not move execution to a remote node
while leaving its dominant memory or device traffic behind without measuring remote-access cost.

**Performance companion:** [CPERF-020][c-code-standard-cperf-020]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

In-process DTO using <stdint.h>. A single runtime/platform owner applies and verifies the plan. The
IDs are platform identifiers; equal numeric IDs across the fields do not imply locality.

```c
typedef struct PlacementPlan
{
        uint32_t cpu_id;
        uint32_t memory_node_id;
        uint32_t irq_cpu_id;
        uint32_t device_node_id;
} placement_plan_t;
```

---

<a id="cstyle-220"></a>

<a id="cstyle-220-tlb-shootdown-scope"></a>

### CSTYLE-220: TLB Invalidation Uses the Smallest Correct Scope

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-180: TLB shootdown or page-walk pressure][c-common-pitfalls-cpit-180]

Kernel/runtime code that owns mappings shall invalidate the smallest correct virtual range and CPU
set supported by the platform. Avoid high-frequency map/unmap or protection churn in hot algorithms
when stable mappings satisfy the same security and lifetime contract.

**Performance companion:** [CPERF-022][c-code-standard-cperf-022]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Privileged platform-owner fragment with a validated callback. The adapter computes the complete
required CPU set and address range and supplies architecture-required barriers. Ordinary module code
never omits a required remote invalidation for speed.

```c
ret = invalidate_range(address_space_context, start_page, page_count,
                       participating_cpu_set);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cstyle-221"></a>

<a id="cstyle-221-tlb-working-set-awareness"></a>

### CSTYLE-221: Translation Locality Is Measured Separately From Data-Cache Locality

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-180: TLB shootdown or page-walk pressure][c-common-pitfalls-cpit-180]

When page-walk/DTLB counters dominate, reduce translation working set, improve page locality, or
evaluate larger pages according to the OS/target policy. Good L1/L2 data locality does not prove the
address-translation path is efficient.

**Performance companion:** [CPERF-021][c-code-standard-cperf-021]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Harness record using <stddef.h>/<stdint.h>. Populate with target-defined PMU events and measured
elapsed time. A missing PMU capability is recorded as unavailable, not as a zero result.

```c
typedef struct TranslationEvidence
{
        size_t page_size_bytes;
        size_t mapped_bytes;

        uint64_t page_walk_count;
        uint64_t tlb_miss_count;
        uint64_t elapsed_ns;
} translation_evidence_t;
```

---

<a id="cstyle-222"></a>

<a id="cstyle-222-cache-set-conflict-analysis"></a>

### CSTYLE-222: Cache-Set Conflicts and Page Coloring Are Allocator-Level Optimizations

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-181: Cache-set conflict mistaken for capacity pressure][c-common-pitfalls-cpit-181]

When LLC/cache conflict misses remain high despite adequate nominal capacity, an allocator or OS
profile may investigate cache-set placement, coloring, or equivalent mapping controls. Do not expose
page coloring to ordinary modules or assume one cache indexing function across processors.

**Performance companion:** [CPERF-023][c-code-standard-cperf-023]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

An allocator-level experiment record. Physical placement or cache hashing must not be inferred from
portable pointer bits. Keep a baseline, working set and byte consumption comparable.

```c
typedef struct PlacementExperiment
{
        size_t allocation_stride_bytes;
        size_t working_set_bytes;

        uint32_t    allocator_variant_id;
        const char *cache_event_record;
} placement_experiment_t;
```

---

<a id="cstyle-223"></a>

<a id="cstyle-223-non-temporal-store-policy"></a>

### CSTYLE-223: Non-Temporal Stores Require Demonstrated Streaming Behavior

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-184: Non-temporal store misuse][c-common-pitfalls-cpit-184]

Use non-temporal/write-combining stores only for measured large streaming writes with little
near-term reuse where cache pollution is harmful. Keep a normal-store fallback and benchmark
crossover sizes. Before publishing completion to another CPU or device, apply the
architecture-defined ordering/fence required for the non-temporal path.

**Performance companion:** [CPERF-037][c-code-standard-cperf-037]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Platform-owner sequence through validated callbacks. `complete_stores` supplies target/device
completion and ordering, not merely a compiler barrier. Do not publish on either preceding failure.
The backend defines aliasing, alignment, profitable-size threshold and cached fallback.

```c
ret = stream_copy(stream_context, destination, source, size_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
ret = complete_stores(stream_context);
if (ret != EXIT_SUCCESS)
        goto function_output;
ret = publish_ready(publication_context);
```

---

<a id="cstyle-224"></a>

<a id="cstyle-224-write-combining-line-completion"></a>

### CSTYLE-224: Write-Combining Paths Prefer Complete Cache-Line Streams

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Where the hardware write-combining model and algorithm permit it, complete a full cache-line stream
before interleaving many partially written lines. Partial WC buffers can increase transactions or
force read-modify-write behavior. This rule is strictly target/profile gated.

**Performance companion:** [CPERF-038][c-code-standard-cperf-038]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Entry declarations and validation precede this body; `line_bytes` is nonzero and cursor names the
remaining span. Callbacks must not overrun it. Tail code must not round the logical length up into
unowned bytes. Publication follows the platform completion protocol.

```c
while (remaining_bytes >= line_bytes)
{
        ret = write_line(stream_context, cursor, line_bytes);
        if (ret != EXIT_SUCCESS)
                goto function_output;
        cursor          += line_bytes;
        remaining_bytes -= line_bytes;
}

if (remaining_bytes != 0u)
        ret = write_tail(stream_context, cursor, remaining_bytes);
```

---

<a id="cstyle-225"></a>

<a id="cstyle-225-data-plane-library-call-policy"></a>

### CSTYLE-225: Data-Plane Library Calls Need a Hot-Path Policy

**Class:** PERFORMANCE. Apply the scope and requirement words below.

A data-plane/ISR/ultra-low-latency profile may prohibit general-purpose libc routines in its hot
path when measured implementations have unsuitable latency, code size, or branch behavior. DPDK
specifically warns against general libc `memcpy`/`strcpy` in its data plane. Such a profile must
provide reviewed replacements and correctness tests; it does not change the standard-library policy
for ordinary code.

**Performance companion:** [CPERF-025][c-code-standard-cperf-025]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Consumer-owned port declaration. Its owner defines full/closed states, memory ordering, lifetime and
bounded execution. The consumer does not invent an atomic protocol at the call site.

```c
typedef int (*queue_try_push_cb_t)(void *context, const unsigned char *data,
                                   size_t size_bytes);
```

---

<a id="cstyle-226"></a>

<a id="cstyle-226-portable-reference-for-optimized-code"></a>

### CSTYLE-226: Optimized Implementations Keep an Independent Portable Reference

**Class:** PERFORMANCE. Apply the scope and requirement words below.

When an algorithm has handwritten SIMD, assembly, JIT, intrinsic, or other target- specific
implementation, keep an independent portable C implementation when practical. The portable version
is the semantic oracle, debugging fallback, and unsupported-target implementation; do not let the
optimized implementation define its own expected result.

FFmpeg `checkasm` and OpenSSL processor-specific code follow this model.

**Performance companion:** [CPERF-005][c-code-standard-cperf-005]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Include <stddef.h>, <stdlib.h>, <errno.h> and an own header declaring the function. data names
`size_bytes` readable bytes; `count_out` is disjoint writable storage. No ownership transfer. Zero
length requires a valid pointer. This is a scalar reference, not an optimized backend.

```c
int OPT_countByteReference(const unsigned char *data, size_t size_bytes,
                           unsigned char needle, size_t *count_out)
{
        int    ret   = EXIT_SUCCESS;
        size_t count = 0u;
        size_t index = 0u;

        if ((data == (const unsigned char *)(NULL)) ||
            (count_out == (size_t *)(NULL)))
        {
                ret = -EINVAL;
                goto function_output;
        }

        for (index = 0u; index < size_bytes; index++)
        {
                if (data[index] == needle)
                        count++;
        }

        *count_out = count;

function_output:
        return ret;
}
```

---

<a id="cstyle-227"></a>

<a id="cstyle-227-differential-optimized-implementation-tests"></a>

### CSTYLE-227: Specialized Implementations Are Differentially Tested

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Compare every specialized backend against the reference across boundary values, misalignment
permitted by contract, random/fuzz inputs, error cases, and supported ISA feature levels. The test
shall also prove that the intended backend executed; a correct result from an accidental
fallback is not coverage of the optimized path.

**Performance companion:** [CPERF-006][c-code-standard-cperf-006]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Test-body fragment. Declare ret, expected and actual at entry; validate both callbacks and their
contexts. Repeat over the allowed length, alignment and aliasing matrix. Matching one output does
not prove general equivalence.

```c
ret = reference(reference_context, data, size_bytes, &expected);
if (ret != EXIT_SUCCESS)
        goto function_output;
ret = candidate(candidate_context, data, size_bytes, &actual);
if (ret != EXIT_SUCCESS)
        goto function_output;
if (actual != expected)
{
        ret = -EDOM;
        goto function_output;
}
```

---

<a id="cstyle-228"></a>

<a id="cstyle-228-runtime-isa-dispatch"></a>

### CSTYLE-228: Runtime ISA Dispatch Is Centralized

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Detect CPU/ISA features in one owned dispatch layer, bind a function table or stable operation
pointer, and keep feature tests out of the inner algorithm loop. Callers consume the semantic
operation contract, not AVX/NEON/SVE/RVV-specific names.

**Performance companion:** [CPERF-007][c-code-standard-cperf-007]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Consumer-owned in-process port. Include <stddef.h> and <stdint.h>. The composition owner validates
ISA/OS prerequisites and publishes a complete table; the table and context remain stable during
calls.

```c
typedef int (*opt_count_cb_t)(void *context, const unsigned char *data,
                              size_t size_bytes, size_t *count_out);

typedef struct OptDispatch
{
        void          *context;
        opt_count_cb_t count;
        uint32_t       selected_backend_id;
} opt_dispatch_t;
```

---

<a id="cstyle-229"></a>

<a id="cstyle-229-vector-length-coverage"></a>

### CSTYLE-229: Variable Vector-Length Backends Are Tested Across Supported Lengths

**Class:** PERFORMANCE. Apply the scope and requirement words below.

SVE, RVV, or another variable-vector-length implementation shall be tested at multiple supported
vector lengths, including the minimum and representative larger lengths. Passing on one processor
does not prove a vector-length-agnostic algorithm.

**Performance companion:** [CPERF-040][c-code-standard-cperf-040]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Harness fragment with entry-declared IDs and ret. `selected_backend` reports the implementation that
will execute; unsupported hardware is not silently counted as passing the optimized test.

```c
ret = selected_backend(dispatch_context, &actual_backend_id);
if (ret != EXIT_SUCCESS)
        goto function_output;
if (actual_backend_id != requested_backend_id)
{
        ret = -ENOTSUP;
        goto function_output;
}

ret = differential_test(test_context);
```

---

<a id="cstyle-230"></a>

<a id="cstyle-230-specialization-invalidation-contract"></a>

### CSTYLE-230: Specialized Cached Code Requires Exact Invalidation

**Class:** PERFORMANCE. Apply the scope and requirement words below.

If a JIT, translation block, cached execution plan, or specialized hot path removes a runtime check
because configuration is treated as invariant, the owner shall define which state changes invalidate
that specialization and how invalidation is synchronized. QEMU TCG is a mature example: translated
code is specialized against CPU/code state and invalidated when the underlying assumption changes.

**Performance companion:** [CPERF-008][c-code-standard-cperf-008]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

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

<a id="cstyle-231"></a>

<a id="cstyle-231-rare-complex-path-outlining"></a>

### CSTYLE-231: Rare Complex Paths Need Not Inflate Generated Hot Code

**Class:** PERFORMANCE. Apply the scope and requirement words below.

In JIT/code-generation or aggressively specialized paths, prefer an out-of-line helper for rare
complex operations when inlining would materially increase generated code, translation time, or
frontend footprint. QEMU TCG explicitly recommends helpers for seldom-used instructions whose inline
IR becomes large; the exact crossover remains a measurement, not a fixed project constant.

**Performance companion:** [CPERF-009][c-code-standard-cperf-009]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Function-body fragment after validation. Both operations are bound callbacks or helpers owned by
this module. Moving the uncommon operation out of line requires generated-code and workload
evidence.

```c
if (has_exceptional_opcode)
{
        ret = cold_operation(operation_context, request, reply);
        goto function_output;
}

ret = common_operation(operation_context, request, reply);
```

---

<a id="cstyle-232"></a>

<a id="cstyle-232-indirect-dispatch-and-btb-awareness"></a>

### CSTYLE-232: Indirect Dispatch Pressure Is Profile-Gated

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-187: Frontend footprint and predictor pressure][c-common-pitfalls-cpit-187]

When a hot loop is limited by indirect-branch/BTB behavior, stabilize dispatch targets outside the
inner loop where the semantics permit it. Do not manually devirtualize or cache a callback target if
binding can change concurrently without an invalidation or synchronization contract.

**Performance companion:** [CPERF-033][c-code-standard-cperf-033]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Declare process, `process_context`, index and ret at entry, with typed NULL for pointers. Validate
the table, mandatory callback and item extent before this fragment. The binder prevents
replacement/unload for the entire loop. This is not permission to bypass callback instrumentation.

```c
process         = callbacks->process;
process_context = callbacks->process_context;
for (index = 0u; index < item_count; index++)
{
        ret = process(process_context, &items[index]);
        if (ret != EXIT_SUCCESS)
                goto function_output;
}
```

---

<a id="cstyle-233"></a>

<a id="cstyle-233-return-prediction-awareness"></a>

### CSTYLE-233: Deep Call Chains Are Reviewed When Return Prediction Is a Bottleneck

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-187: Frontend footprint and predictor pressure][c-common-pitfalls-cpit-187]

RSB/return-prediction pressure is a profiling diagnosis, not a source-level recursion limit. If a
frontend-bound hot path shows return misprediction or excessive tiny call chains, evaluate
outlining/inlining with generated-code and stack measurements rather than imposing a universal
call-depth threshold.

**Performance companion:** [CPERF-028][c-code-standard-cperf-028]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Run on the produced executable, together with the representative workload and target front-end
events. Byte count alone is not a throughput measurement.

```sh
size build-release/tests_static
objdump -d build-release/tests_static > tests-static.disassembly.txt
```

---

<a id="cstyle-234"></a>

<a id="cstyle-234-speculation-mitigation-baseline"></a>

### CSTYLE-234: Performance Baselines Record Speculation-Mitigation State

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Kernel/hypervisor benchmarks shall record relevant speculation mitigations, firmware/ microcode
level, and security mode when those settings can alter indirect branches, returns, barriers, or
cross-domain transitions. Results collected with materially different mitigation state are not
directly comparable without that qualification.

**Performance companion:** [CPERF-002][c-code-standard-cperf-002]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Record the effective settings, not only the intended launch options. Include <stdbool.h>.

```c
typedef struct PerfMachinePolicy
{
        const char *kernel_release;
        const char *cpu_affinity;
        const char *numa_policy;
        const char *governor;
        const char *mitigation_state;
        const char *hardware_prefetch_policy;
        bool        smt_enabled;
} perf_machine_policy_t;
```

---

<a id="cstyle-235"></a>

<a id="cstyle-235-profile-guided-layout-evidence"></a>

### CSTYLE-235: Profile-Guided Layout Uses Representative Profiles

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-188: Nonrepresentative performance profile][c-common-pitfalls-cpit-188]

AutoFDO, Propeller, PGO, basic-block reordering, hot/cold partitioning, or manual code layout shall
use a profile representative of the deployment workload. Record profile provenance and verify that
the optimized binary improves the intended workload without regressing mandatory latency or safety
tests.

**Performance companion:** [CPERF-003][c-code-standard-cperf-003]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Keep training and independent evaluation inputs distinct. The fields are metadata, not evidence that
a profile is representative.

```c
typedef struct PerfProfileIdentity
{
        const char *training_input_digest;
        const char *deployment_workload_class;
        const char *compiler_build_id;
        const char *profile_digest;
        const char *refresh_trigger;
} perf_profile_identity_t;
```

---

<a id="cstyle-236"></a>

<a id="cstyle-236-segmented-large-collection-policy"></a>

### CSTYLE-236: Large Contiguous Collections May Use Segmented Storage in Hot Services

**Class:** PERFORMANCE. Apply the scope and requirement words below.

For very large growable collections in long-lived services, benchmark segmented or chunked storage
when contiguous reallocation, allocator fragmentation, or latency spikes dominate. Keep the
representation behind the owning container API so ordinary callers do not depend on segmentation.
Redpanda's `chunked_vector`/ `chunked_hash_map` policy is a useful systems-scale example, even
though Redpanda is C++ rather than C.

**Performance companion:** [CPERF-023][c-code-standard-cperf-023]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Private storage-layout excerpt with <stddef.h>. The owner checks segment and offset arithmetic,
manages directory growth, and documents pointer stability. Compare this layout to contiguous storage
under the actual workload; it does not prove a performance gain.

```c
typedef struct SegmentedBytes
{
        unsigned char **segments;
        size_t          segment_size_bytes;
        size_t          segment_count;
        size_t          directory_capacity;
} segmented_bytes_t;
```

---

<a id="cstyle-237"></a>

<a id="cstyle-237-store-buffer-pressure"></a>

### CSTYLE-237: Store-Buffer Pressure Is a Measured Throughput Limit

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-176: Store-buffer saturation][c-common-pitfalls-cpit-176]

On an out-of-order target, a hot loop that retires many stores can become limited by store-buffer
occupancy, ownership traffic, or delayed writeback even when the stored values are not on the
arithmetic critical path. Remove stores that do not change observable state, aggregate updates when
the latency contract permits it, and confirm the diagnosis with target PMU counters rather than
source-level store counts alone.

**Performance companion:** [CPERF-018][c-code-standard-cperf-018]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Owner-local accumulation before one output write. sum and index are entry declarations.
`checked_add` is a validated callback with in-place output permitted. No observer may require an
intermediate store, and out must not overlap unread samples.

```c
for (index = 0u; index < sample_count; index++)
{
        ret = checked_add(sum, samples[index], &sum);
        if (ret != EXIT_SUCCESS)
                goto function_output;
}

*out = sum;
```

---

<a id="cstyle-238"></a>

<a id="cstyle-238-hardware-prefetcher-interaction"></a>

### CSTYLE-238: Hardware Prefetchers Are Part of the Performance Experiment

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-183: Hardware prefetch pollution][c-common-pitfalls-cpit-183]

A performance change that alters stride, adjacency, page traversal, or software prefetch shall
account for the target's hardware prefetchers. Adjacent-line and next-page behavior can fetch data
or translations that the program never consumes, while a useful hardware stream can make an added
software prefetch redundant. Measure cache pollution, bandwidth, TLB/page-walk activity, and miss
latency with the relevant prefetch configuration when the platform exposes it.

Prefetching a miss path or otherwise fetching data that may not be consumed is allowed only when
measurement shows that smoother control flow or latency hiding outweighs the extra traffic.

**Performance companion:** [CPERF-047][c-code-standard-cperf-047]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

An actual A/B measurement record supplied by the target owner. Never change system-wide prefetch
policy from ordinary library code or claim unsupported PMU counters are zero.

```c
typedef struct PrefetchExperiment
{
        const char *effective_hardware_policy;
        size_t      software_distance_items;

        const char *cache_events;
        const char *translation_events;
        const char *bandwidth_events;
} prefetch_experiment_t;
```

---

<a id="cstyle-239"></a>

<a id="cstyle-239-dma-full-cache-line-transaction-policy"></a>

### CSTYLE-239: DMA and Device Streaming Layouts Prefer Complete Cache-Line Transactions

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-190: Partial-line DMA or device streaming transaction][c-common-pitfalls-cpit-190]

When a DMA engine, PCIe device, DDIO path, or write-combining interface benefits from full-line
transfers, organize measured streaming buffers so common writes complete the target cache line
instead of repeatedly touching partial lines. This rule applies only when the device/cache-coherency
contract documents the relevant transaction geometry; it does not authorize padding or writing bytes
outside the owned buffer.

**Performance companion:** [CPERF-036][c-code-standard-cperf-036]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

A platform-owner descriptor, not a wire format. Include <stddef.h>/<stdint.h>. The mapping contract
defines actual alignment, coherency, cache maintenance, permitted cache-line rounding and ownership
handover. `used_bytes` never authorizes stores into adjacent allocations.

```c
typedef struct DmaBufferView
{
        unsigned char *data;
        size_t         capacity_bytes;
        size_t         used_bytes;

        uint32_t mapping_id;
} dma_buffer_view_t;
```

---

<a id="cstyle-240"></a>

<a id="cstyle-240-independent-hot-lock-isolation"></a>

### CSTYLE-240: Independent Hot Locks Avoid Coherence Coupling

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-191: Independent locks share a cache line][c-common-pitfalls-cpit-191]

Independent locks or atomic state machines that are acquired by different CPUs shall not be
deliberately packed into one word or cache line when profiling shows coherence contention. Logical
independence is not enough: bit-packing several locks can force unrelated CPUs to exchange ownership
of the same line. Isolate the measured hot locks without turning cache-line padding into a global
structure-layout rule.

**Performance companion:** [CPERF-012][c-code-standard-cperf-012]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Private target-specific declaration using <stdatomic.h> and <stdalign.h>.
OPT_PROFILE_CACHE_LINE_BYTES is supplied by an approved measured profile. Initialize atomic flags
before publication; alignment, fairness and wait policy remain separate obligations.

```c
typedef struct PrivateLockLayout
{
        alignas(OPT_PROFILE_CACHE_LINE_BYTES) atomic_flag first_lock;
        alignas(OPT_PROFILE_CACHE_LINE_BYTES) atomic_flag second_lock;
} private_lock_layout_t;
```

---

<a id="cstyle-241"></a>

<a id="cstyle-241-code-alignment-and-patch-geometry"></a>

### CSTYLE-241: Code Alignment and Runtime Patch Geometry Are Profile-Gated

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-208: Unjustified code alignment or patch geometry][c-common-pitfalls-cpit-208]

Manual function, loop, basic-block, or patch-site alignment requires a target-specific reason and
generated-code evidence. Frontend fetch/decode boundaries, decoded-uop caches, branch errata, and
runtime text patching can make placement matter, but the useful boundary varies by CPU. A patchable
instruction sequence shall also satisfy the platform's atomicity and instruction-cache
synchronization contract and shall not straddle a forbidden patch boundary.

**Performance companion:** [CPERF-034][c-code-standard-cperf-034]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Commands on a built ELF test binary. A target owner may compare PGO/layout variants, but no
arbitrary alignment threshold is asserted here.

```sh
# Inspect the final text layout for the actual optimized build.
readelf -S build-release/tests_static
objdump -d build-release/tests_static > final-layout.txt
```

---

<a id="cstyle-242"></a>

<a id="cstyle-242-atomic-coherence-topology-cost"></a>

### CSTYLE-242: Atomic Cost Includes Coherence Topology

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-186: Topology-blind atomic hotspot][c-common-pitfalls-cpit-186]

Do not treat a compare-and-swap, fetch-add, or locked RMW as having one architecture-wide constant
cost. Its latency and throughput depend on cache-line ownership, socket/NUMA placement, contenders,
memory ordering, and interconnect topology. Benchmark the operation under the intended sharing
pattern; prefer ownership partitioning or batching before introducing a more elaborate global atomic
protocol.

**Performance companion:** [CPERF-024][c-code-standard-cperf-024]. Apply each control within its
stated scope.

#### Local examples

**Contextual example:**

Owning-thread body. `flush_batch` must define one commit point and all-or-nothing failure here.
Counters/queues define shutdown flush, maximum delay, overflow and fairness separately. A
partial-success transport needs a progress field instead of this reset.

```c
ret = flush_batch(owner_context, pending_count);
if (ret != EXIT_SUCCESS)
        goto function_output;
pending_count = 0u;
```

---

<a id="performance"></a>

## Performance and microarchitecture: CPERF controls

These recovered controls are kept distinct from local C syntax and safety rules. The original file
name was `c_performance.md`; its contents are integrated here so the delivered set remains three
normative/reference documents. CPERF IDs retain their meanings. CSTYLE-201 through CSTYLE-242 above
preserve the earlier performance branch and link to the corresponding later CPERF controls.

MUST applies in the rule's stated scope. SHOULD needs a measured reason when a technique is
relevant. MAY permits an experiment. Profile-gated techniques require a named target and
representative measured workload; they are not enabled merely because this document includes an
example. Correctness, ownership and the selected project conventions take precedence.

- [CPERF-001: Performance Changes Require Reproducible Evidence][cperf-001]
- [CPERF-002: Baselines Record the Effective Machine Policy][cperf-002]
- [CPERF-003: Profiles Must Represent the Deployment Workload][cperf-003]
- [CPERF-004: Performance Claims Preserve Correctness Evidence][cperf-004]
- [CPERF-005: Keep an Independent Portable Reference][cperf-005]
- [CPERF-006: Differential-Test Every Specialized Backend][cperf-006]
- [CPERF-007: Dispatch Is Explicit and Verifiable][cperf-007]
- [CPERF-008: Specialization Requires Exact Invalidation][cperf-008]
- [CPERF-009: Rare Complex Operations May Stay Out of Line][cperf-009]
- [CPERF-010: Assign Ownership to Write-Hot Cache Lines][cperf-010]
- [CPERF-011: Prove and Isolate Harmful False Sharing][cperf-011]
- [CPERF-012: Contended Locks Have an Independent Layout Decision][cperf-012]
- [CPERF-013: Prefer Owner-Local State and Deferred Aggregation][cperf-013]
- [CPERF-014: Minimize Needless Shared Writes][cperf-014]
- [CPERF-015: Remote Writes to Owner-Local State Are Exceptional][cperf-015]
- [CPERF-044: Compact Flags Do Not Share a Coherence Unit Accidentally][cperf-044]
- [CPERF-045: Cross-Owner Freeing Is a Synchronization Path][cperf-045]
- [CPERF-016: Hot Dependent Accesses Respect Store-Forwarding Geometry][cperf-016]
- [CPERF-017: Investigate False 4 KiB Aliasing Only With Evidence][cperf-017]
- [CPERF-018: Avoid Store-Buffer Pressure From Unobservable Stores][cperf-018]
- [CPERF-019: Hot Wide Accesses Avoid Split Boundaries][cperf-019]
- [CPERF-020: Treat CPU, Memory, IRQ, and Device Locality as One Plan][cperf-020]
- [CPERF-021: Measure Translation Working Set Separately From Data Cache][cperf-021]
- [CPERF-022: Scope TLB Invalidation to the Smallest Correct Domain][cperf-022]
- [CPERF-023: Cache-Set Placement Is an Allocator-Level Experiment][cperf-023]
- [CPERF-043: Deterministic Hot Paths Define Page-Residency Policy][cperf-043]
- [CPERF-024: Amortize Global Atomic Operations][cperf-024]
- [CPERF-025: Hide Raw Atomics Behind Semantic Operations][cperf-025]
- [CPERF-026: Use Reader-Optimized Schemes Only for Matching Workloads][cperf-026]
- [CPERF-027: Lockless Accesses Constrain Compiler Transformation][cperf-027]
- [CPERF-046: Contention Needs an Explicit Wait and Wake Policy][cperf-046]
- [CPERF-028: Treat Hot-Code Footprint as a Resource][cperf-028]
- [CPERF-029: Forced Inlining Requires Evidence][cperf-029]
- [CPERF-030: Branchless Code Is Not Automatically Faster][cperf-030]
- [CPERF-031: Branch Hints Need Profile Validation][cperf-031]
- [CPERF-032: Patchable Static Branches Suit Stable Rare Features][cperf-032]
- [CPERF-033: Stable Indirect Targets May Bind Outside the Inner Loop][cperf-033]
- [CPERF-034: Code Placement and Alignment Are Profile-Gated][cperf-034]
- [CPERF-035: Software Prefetch Has a Distance Contract][cperf-035]
- [CPERF-036: DMA Layout Accounts for Cache-Line Transactions][cperf-036]
- [CPERF-037: Non-Temporal Stores Require Streaming Reuse Evidence][cperf-037]
- [CPERF-038: Complete Streaming Cache Lines When Practical][cperf-038]
- [CPERF-047: Hardware Prefetchers Are Part of the Experiment][cperf-047]
- [CPERF-039: Performance Review Record][cperf-039]
- [CPERF-040: CI Proves Backend Selection and Equivalence][cperf-040]
- [CPERF-041: Benchmark Regressions Use Stable Thresholds][cperf-041]
- [CPERF-042: Static Tools Report Evidence, Not Policy][cperf-042]

---

<a id="cperf-001"></a>

<a id="cperf-001-1-1-reproducible-evidence"></a>

### CPERF-001: Performance Changes Require Reproducible Evidence

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-188][c-common-pitfalls-cpit-188]

A microarchitectural optimization must identify:

- the CPU model, stepping, topology, and relevant firmware configuration;
- the operating system, kernel, scheduler, and affinity configuration;
- the compiler, version, target flags, optimization flags, and link mode;
- the representative input, concurrency level, warm-up, and sample count;
- before and after distributions, not only one best result;
- the PMU counters or other observations that support the causal explanation;
- energy, memory, latency-tail, code-size, and correctness regressions when relevant.

The change must state the hypothesis before interpreting the measurements. Wall-clock improvement
without a reproducible workload does not establish a microarchitectural rule.

#### Local examples

**Contextual example:**

The harness fills every field from the run. This declaration contains no measured result.

```c
typedef struct PerfRunIdentity
{
        const char *source_revision;
        const char *compiler_version;
        const char *compiler_flags;
        const char *target_cpu;
        const char *workload_digest;
        const char *raw_results_path;
} perf_run_identity_t;
```

---

<a id="cperf-002"></a>

<a id="cperf-002-1-2-effective-machine-policy"></a>

### CPERF-002: Baselines Record the Effective Machine Policy

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Performance baselines must record machine policy that changes execution cost, including applicable
speculation mitigations, simultaneous multithreading, frequency policy, NUMA policy, transparent
huge pages, page size, and interrupt placement. Results produced under different policies must not
be compared as if they came from the same configuration.

#### Local examples

**Contextual example:**

Record the effective settings, not only the intended launch options. Include <stdbool.h>.

```c
typedef struct PerfMachinePolicy
{
        const char *kernel_release;
        const char *cpu_affinity;
        const char *numa_policy;
        const char *governor;
        const char *mitigation_state;
        const char *hardware_prefetch_policy;
        bool        smt_enabled;
} perf_machine_policy_t;
```

---

<a id="cperf-003"></a>

<a id="cperf-003-1-3-representative-profile"></a>

### CPERF-003: Profiles Must Represent the Deployment Workload

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-188][c-common-pitfalls-cpit-188]

Profile-guided optimization, hot/cold layout, and branch-frequency controls must use profiles
representative of the deployment workload. The profile artifact must have an owner, generation
recipe, input description, compiler compatibility policy, and refresh trigger.

LLVM documents PGO as optimization based on how a program runs. A profile produced by a
different workload is evidence for that workload, not for the intended
deployment.[llvm-pgo][llvm-pgo]

#### Local examples

**Contextual example:**

Keep training and independent evaluation inputs distinct. The fields are metadata, not evidence that
a profile is representative.

```c
typedef struct PerfProfileIdentity
{
        const char *training_input_digest;
        const char *deployment_workload_class;
        const char *compiler_build_id;
        const char *profile_digest;
        const char *refresh_trigger;
} perf_profile_identity_t;
```

---

<a id="cperf-004"></a>

<a id="cperf-004-1-4-correctness-before-speed"></a>

### CPERF-004: Performance Claims Preserve Correctness Evidence

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Benchmark success must not replace:

- unit, integration, sanitizer, and static-analysis results;
- concurrency-model validation;
- boundary and resource-budget tests;
- equivalence tests for specialized implementations;
- applicable constant-time or safety timing evidence.

An optimization that makes a defect harder to reproduce is not a correction.

#### Local examples

**Contextual example:**

Inside the review harness: ret and flags are declared at function entry. `review_measurements` is an
injected callback, validated before this fragment; it does not create correctness evidence.

```c
if (!correctness_passed || !backend_equivalence_passed)
{
        ret = -EINVAL;
        goto function_output;
}

ret = review_measurements(review_context, measurements);
```

---

<a id="cperf-005"></a>

<a id="cperf-005-2-1-portable-reference-implementation"></a>

### CPERF-005: Keep an Independent Portable Reference

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Every architecture-specific or generated optimized implementation should retain an independent
portable C reference when practical. The reference defines observable behavior and edge cases; the
optimized implementation does not act as its own oracle.

The reference must not share the same low-level algorithm fragment when that sharing could reproduce
the same defect in both implementations.

#### Local examples

**Contextual example:**

Include <stddef.h>, <stdlib.h>, <errno.h> and an own header declaring the function. data names
`size_bytes` readable bytes; `count_out` is disjoint writable storage. No ownership transfer. Zero
length requires a valid pointer. This is a scalar reference, not an optimized backend.

```c
int OPT_countByteReference(const unsigned char *data, size_t size_bytes,
                           unsigned char needle, size_t *count_out)
{
        int    ret   = EXIT_SUCCESS;
        size_t count = 0u;
        size_t index = 0u;

        if ((data == (const unsigned char *)(NULL)) ||
            (count_out == (size_t *)(NULL)))
        {
                ret = -EINVAL;
                goto function_output;
        }

        for (index = 0u; index < size_bytes; index++)
        {
                if (data[index] == needle)
                        count++;
        }

        *count_out = count;

function_output:
        return ret;
}
```

---

<a id="cperf-006"></a>

<a id="cperf-006-2-2-differential-backend-tests"></a>

### CPERF-006: Differential-Test Every Specialized Backend

**Class:** PERFORMANCE. Apply the scope and requirement words below.

SIMD, assembly, accelerator, JIT, and architecture-tuned implementations must be differential-tested
against the portable reference across:

- boundary sizes and alignments;
- zero, minimum, maximum, and non-multiple vector lengths;
- aliasing combinations allowed by the contract;
- each supported ISA feature level;
- each supported scalable-vector-length regime;
- randomized and adversarial inputs.

FFmpeg's `checkasm` infrastructure exposes CPU-feature selection and compares optimized functions
under controlled CPU flags.[ffmpeg-checkasm][ffmpeg-checkasm]

#### Local examples

**Contextual example:**

Test-body fragment. Declare ret, expected and actual at entry; validate both callbacks and their
contexts. Repeat over the allowed length, alignment and aliasing matrix. Matching one output does
not prove general equivalence.

```c
ret = reference(reference_context, data, size_bytes, &expected);
if (ret != EXIT_SUCCESS)
        goto function_output;
ret = candidate(candidate_context, data, size_bytes, &actual);
if (ret != EXIT_SUCCESS)
        goto function_output;
if (actual != expected)
{
        ret = -EDOM;
        goto function_output;
}
```

---

<a id="cperf-007"></a>

<a id="cperf-007-2-3-explicit-runtime-dispatch"></a>

### CPERF-007: Dispatch Is Explicit and Verifiable

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Callers must use one algorithm contract. A dedicated dispatch layer selects the portable or
specialized backend after validating CPU, operating-system, device, alignment, and feature
prerequisites.

Dispatch tests must prove which backend executed. Correct output alone does not prove that the
intended implementation was selected.

#### Local examples

**Contextual example:**

Consumer-owned in-process port. Include <stddef.h> and <stdint.h>. The composition owner validates
ISA/OS prerequisites and publishes a complete table; the table and context remain stable during
calls.

```c
typedef int (*opt_count_cb_t)(void *context, const unsigned char *data,
                              size_t size_bytes, size_t *count_out);

typedef struct OptDispatch
{
        void          *context;
        opt_count_cb_t count;
        uint32_t       selected_backend_id;
} opt_dispatch_t;
```

---

<a id="cperf-008"></a>

<a id="cperf-008-2-4-specialization-invalidation-contract"></a>

### CPERF-008: Specialization Requires Exact Invalidation

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-192][c-common-pitfalls-cpit-192]

Cached code, execution plans, or function bindings may omit repeated checks only when their assumed
state has an explicit invalidation contract. The contract must identify:

- the specialized invariant;
- every event that can change it;
- the owner that invalidates or rebinds the artifact;
- the synchronization that prevents stale execution;
- the fallback after invalidation.

QEMU records CPU state in a Translation Block and stops reusing that block when the state no longer
matches.[qemu-tcg][qemu-tcg]

#### Local examples

**Contextual example:**

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

<a id="cperf-009"></a>

<a id="cperf-009-2-5-rare-complex-operation-helper"></a>

### CPERF-009: Rare Complex Operations May Stay Out of Line

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Rare or complex functionality should not inflate a hot generated-code or inner dispatch path merely
to avoid a call. QEMU recommends C helpers for complicated or seldom-used guest instructions and
documents an approximate historical threshold rather than treating expansion as automatically
faster.[qemu-ops][qemu-ops]

The project must choose the boundary through measurement; no fixed instruction count applies to all
targets.

#### Local examples

**Contextual example:**

Function-body fragment after validation. Both operations are bound callbacks or helpers owned by
this module. Moving the uncommon operation out of line requires generated-code and workload
evidence.

```c
if (has_exceptional_opcode)
{
        ret = cold_operation(operation_context, request, reply);
        goto function_output;
}

ret = common_operation(operation_context, request, reply);
```

---

<a id="cperf-010"></a>

<a id="cperf-010-3-1-write-hot-cache-line-ownership"></a>

### CPERF-010: Assign Ownership to Write-Hot Cache Lines

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Frequently modified state should have one CPU, thread, shard, or device owner when the architecture
permits it. Other execution contexts should send work to that owner or update separate local state
instead of repeatedly transferring exclusive ownership of one cache line.

#### Local examples

**Contextual example:**

Private per-owner state, including <stdint.h>. Only its owning thread writes it. Readers use a
synchronized snapshot; this declaration alone provides no synchronization. The placement decision
must also account for adjacent owner objects.

```c
typedef struct OwnerCounters
{
        uint64_t completed_count;
        uint64_t failed_count;
} owner_counters_t;
```

---

<a id="cperf-011"></a>

<a id="cperf-011-3-2-false-sharing-isolation"></a>

### CPERF-011: Prove and Isolate Harmful False Sharing

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-174][c-common-pitfalls-cpit-174]

Fields written by independent execution contexts should not share a cache line after `perf c2c`, an
equivalent coherence profiler, or target counters prove harmful false sharing. Layout review should:

- group fields that are read together;
- group fields written by the same owner;
- separate read-mostly state from write-hot state;
- inspect the final binary layout with a tool such as `pahole`;
- measure memory and TLB cost added by padding.

Linux documents these patterns and recommends evidence-based balancing of speed, complexity, and
space.[linux-false-sharing][linux-false-sharing]

One cache line of separation is not a portable constant. Adjacent-line prefetchers and different
cache geometries can require a target-specific guard.

#### Local examples

**Contextual example:**

Illustrative private target profile with a 64-byte coherence unit, not a universal constant. Include
<stdalign.h>, <stddef.h>, <stdint.h>. Storage must satisfy alignof(owner_slot_t); ordinary malloc is
not assumed to provide this extended alignment. No remote unsynchronized reads/writes.

```c
#define OPT_PROFILE_CACHE_LINE_BYTES ((size_t)(64U))

typedef struct OwnerSlot
{
        alignas(OPT_PROFILE_CACHE_LINE_BYTES) uint64_t completed_count;
} owner_slot_t;

_Static_assert(sizeof(owner_slot_t) % OPT_PROFILE_CACHE_LINE_BYTES == 0u,
               "array stride must preserve the measured isolation");
```

---

<a id="cperf-012"></a>

<a id="cperf-012-3-3-contended-lock-layout"></a>

### CPERF-012: Contended Locks Have an Independent Layout Decision

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-191][c-common-pitfalls-cpit-191]

A lock must not automatically share a cache line with the data it protects. If many waiters poll or
modify the lock while the owner writes protected data, the combined layout can increase coherence
traffic. Lock placement requires the same measurement and ownership analysis as other write-hot
state.

Do not pack logically independent hot locks into bits of one word or into one cache line merely to
save memory.

#### Local examples

**Contextual example:**

Private target-specific declaration using <stdatomic.h> and <stdalign.h>.
OPT_PROFILE_CACHE_LINE_BYTES is supplied by an approved measured profile. Initialize atomic flags
before publication; alignment, fairness and wait policy remain separate obligations.

```c
typedef struct PrivateLockLayout
{
        alignas(OPT_PROFILE_CACHE_LINE_BYTES) atomic_flag first_lock;
        alignas(OPT_PROFILE_CACHE_LINE_BYTES) atomic_flag second_lock;
} private_lock_layout_t;
```

---

<a id="cperf-013"></a>

<a id="cperf-013-3-4-owner-local-aggregation"></a>

### CPERF-013: Prefer Owner-Local State and Deferred Aggregation

**Class:** PERFORMANCE. Apply the scope and requirement words below.

High-frequency counters and statistics should consider per-CPU, per-thread, or per-shard
accumulation with an explicit consolidation operation. The contract must define:

- acceptable staleness;
- overflow behavior;
- aggregation frequency and batch size;
- hot-plug or owner-lifecycle behavior;
- snapshot consistency.

Linux `this_cpu` operations avoid synchronized cross-CPU cache-line updates and explicitly
discourage remote writes to per-CPU data.[linux-this-cpu][linux-this-cpu]

#### Local examples

**Contextual example:**

Owning-thread fragment. `local_count` is retained in owner state; ret is local. flush is a validated
injected callback; failure must mean no batch committed, otherwise retain explicit partial progress.
Flush at deadline and shutdown too; batch size is not the only latency bound.

```c
if (local_count == UINT64_MAX)
{
        ret = -ERANGE;
        goto function_output;
}

local_count++;
if (local_count >= flush_threshold)
{
        ret = flush(owner_context, local_count);
        if (ret != EXIT_SUCCESS)
                goto function_output;
        local_count = 0u;
}
```

---

<a id="cperf-014"></a>

<a id="cperf-014-3-5-needless-shared-write-minimization"></a>

### CPERF-014: Minimize Needless Shared Writes

**Class:** PERFORMANCE. Apply the scope and requirement words below.

A hot shared update may test whether the desired state already exists before performing a write
when:

- the protocol remains race-safe;
- the read is cheaper than ownership transfer;
- skipping the write preserves required ordering and wake-up semantics;
- measurement demonstrates reduced coherence traffic.

This technique must not replace a required atomic read-modify-write or turn a correct
synchronization protocol into a check-then-act race.

#### Local examples

**Contextual example:**

Inside a synchronization owner with exactly one writer. state is an initialized atomic telemetry
value, not a publication flag and not a compare-and-swap transaction. observed is declared before
validation. Do not apply this form where a repeated release store publishes new payload data.

```c
observed = atomic_load_explicit(state, memory_order_relaxed);
if (observed != requested)
        atomic_store_explicit(state, requested, memory_order_relaxed);
```

---

<a id="cperf-015"></a>

<a id="cperf-015-3-6-no-remote-write-to-owner-local-state"></a>

### CPERF-015: Remote Writes to Owner-Local State Are Exceptional

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Code must not remotely modify write-hot per-owner state unless the protocol explicitly synchronizes
that access and measurement justifies it. Even a rare remote write can evict the cache line needed
when the owning CPU wakes. Linux recommends asking the remote CPU to perform the update when
practical.[linux-this-cpu][linux-this-cpu]

#### Local examples

**Contextual example:**

Cross-owner request. `enqueue_update` is an injected callback whose success copies or explicitly
retains update. It must not retain an automatic DTO borrowed only for the call. No direct write
through a remote owner-state pointer.

```c
ret = enqueue_update(queue_context, owner_id, &update);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cperf-044"></a>

<a id="cperf-044-3-7-compact-flag-coherence-contract"></a>

### CPERF-044: Compact Flags Do Not Share a Coherence Unit Accidentally

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-191][c-common-pitfalls-cpit-191]

Do not pack independently modified hot flags, counters, or locks into one word or cache line merely
to reduce object size. Bit packing can force unrelated writers through the same read-modify-write
location; compact fields can also increase false sharing and make independent atomic updates
impossible.

Conversely, do not expand every boolean blindly. When layout matters, use an explicit fixed-width
representation and verify the final object and cache-line layout on every target profile. Linux
notes that the size and alignment of `bool` vary with architecture and advises against it where
cache-line layout or value size matters.[linux-bool-layout][linux-bool-layout]

#### Local examples

**Contextual example:**

Profile-specific private layout using <stdatomic.h>/<stdalign.h>. Compare space/TLB cost before
adoption; atomic init and matching acquire/release protocol are still required. Do not pack
unrelated writers just because each value is a boolean.

```c
typedef struct PrivateOwnerFlags
{
        alignas(OPT_PROFILE_CACHE_LINE_BYTES) atomic_bool producer_ready;
        alignas(OPT_PROFILE_CACHE_LINE_BYTES) atomic_bool consumer_ready;
} private_owner_flags_t;
```

---

<a id="cperf-045"></a>

<a id="cperf-045-3-8-cross-owner-free-path"></a>

### CPERF-045: Cross-Owner Freeing Is a Synchronization Path

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-185][c-common-pitfalls-cpit-185]

An object allocated by one CPU, thread, shard, heap, or NUMA node and released by another crosses an
ownership boundary even when the allocator API makes the operation legal. A hot design must measure
remote-free frequency, atomic traffic, reclamation delay, memory growth, and owner shutdown
behavior.

Prefer owner-local reclamation or a bounded deferred-free queue when it improves the measured
workload and preserves the lifetime contract. Do not add a global free list as the default remedy.
mimalloc separates thread-local and concurrent free lists so the common local path avoids the
coordination needed by remote freeing.[mimalloc-design][mimalloc-design]

#### Local examples

**Contextual example:**

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

<a id="cperf-016"></a>

<a id="cperf-016-4-1-store-forwarding-geometry"></a>

### CPERF-016: Hot Dependent Accesses Respect Store-Forwarding Geometry

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-177][c-common-pitfalls-cpit-177]

A hot store followed immediately by an overlapping dependent load should use a size, start address,
and containment geometry supported by the target's store-forwarding rules. If PMU events identify
forwarding stalls, first reshape the producer store or eliminate the immediate round trip through
memory.

Code must still satisfy effective-type, alignment, bounds, and provenance rules; performance
evidence never authorizes type-punning through a pointer cast.

#### Local examples

**Contextual example:**

Local representation example: include <stdint.h>/<string.h>; uint32_t word is declared at function
entry. bytes is valid disjoint storage for sizeof(word) bytes, replacement is uint8_t, and the
intended operation changes the least-significant eight value bits in native representation. Inspect
generated code; this is not portable external byte-order decoding and it does not promise a
forwarding improvement.

```c
memcpy(&word, bytes, sizeof(word));
word = (word & UINT32_C(0xFFFFFF00)) | (uint32_t)replacement;
memcpy(bytes, &word, sizeof(word));
```

---

<a id="cperf-017"></a>

<a id="cperf-017-4-2-false-4k-aliasing"></a>

### CPERF-017: Investigate False 4 KiB Aliasing Only With Evidence

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-178][c-common-pitfalls-cpit-178]

Independent hot load and store streams may be placed so their low address bits differ when target
counters prove false dependency caused by 4 KiB aliasing. Intel documents the condition as a store
followed by a load to a different location separated by a 4 KiB
offset.[intel-optimization][intel-optimization]

Padding or allocator changes for this purpose must record page size, cache geometry, memory
overhead, and the exact affected target.

#### Local examples

**Contextual example:**

Harness callbacks collect real addresses/layout on a declared platform. Pointer ordering or
subtraction between unrelated objects is not used. Compare equal/different low page offsets only
inside the platform measurement adapter.

```c
/* Read actual layout and PMU events; do not change buffer alignment blindly. */
ret = record_layout(layout_context, source, destination, size_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
ret = run_variant(benchmark_context, source, destination, size_bytes);
```

---

<a id="cperf-018"></a>

<a id="cperf-018-4-3-store-buffer-pressure"></a>

### CPERF-018: Avoid Store-Buffer Pressure From Unobservable Stores

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-176][c-common-pitfalls-cpit-176]

Hot loops should remove stores that do not change required observable state. Review redundant
zeroing, repeated state publication, write-only temporary objects, and read-modify-write sequences
whose result is discarded.

The removal must preserve secure-erasure, MMIO, atomic, persistence, and diagnostic contracts. A
store required by those contracts is observable even if ordinary C logic never reads it.

#### Local examples

**Contextual example:**

Owner-local accumulation before one output write. sum and index are entry declarations.
`checked_add` is a validated callback with in-place output permitted. No observer may require an
intermediate store, and out must not overlap unread samples.

```c
for (index = 0u; index < sample_count; index++)
{
        ret = checked_add(sum, samples[index], &sum);
        if (ret != EXIT_SUCCESS)
                goto function_output;
}

*out = sum;
```

---

<a id="cperf-019"></a>

<a id="cperf-019-4-4-hot-wide-access-boundaries"></a>

### CPERF-019: Hot Wide Accesses Avoid Split Boundaries

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-179][c-common-pitfalls-cpit-179]

Hot scalar and vector accesses should not cross the target's expensive cache-line or page boundary
when layout control is practical. The implementation must use `alignof`, `alignas`, or a project
layout abstraction rather than repeat an unexplained numeric alignment.

An atomic or locked operand must never intentionally straddle a cache-line boundary. Target hardware
detection for split locks should remain enabled in test and deployment profiles when available.

#### Local examples

**Contextual example:**

Target-profile declaration. The vector alignment comes from the selected backend and allocation
contract. Capacity 256 is an illustrative private block size, not a performance claim. Tail handling
must remain within the real object extent.

```c
typedef struct PrivateVectorBlock
{
        alignas(OPT_PROFILE_VECTOR_ALIGNMENT) unsigned char bytes[256];
} private_vector_block_t;
```

---

<a id="cperf-020"></a>

<a id="cperf-020-5-1-numa-locality-plan"></a>

### CPERF-020: Treat CPU, Memory, IRQ, and Device Locality as One Plan

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-175][c-common-pitfalls-cpit-175]

A performance-critical thread, its mutable working set, its producer or consumer, device queues, and
relevant interrupts should have one documented NUMA-locality plan. CPU affinity must not change
independently of memory placement without measuring remote-memory cost.

Linux page migration exists to reduce access latency by moving pages nearer the processor that uses
them.[linux-page-migration][linux-page-migration] NUMA policy must remain a deployment decision;
portable module logic consumes an adapter-owned policy.

#### Local examples

**Contextual example:**

In-process DTO using <stdint.h>. A single runtime/platform owner applies and verifies the plan. The
IDs are platform identifiers; equal numeric IDs across the fields do not imply locality.

```c
typedef struct PlacementPlan
{
        uint32_t cpu_id;
        uint32_t memory_node_id;
        uint32_t irq_cpu_id;
        uint32_t device_node_id;
} placement_plan_t;
```

---

<a id="cperf-021"></a>

<a id="cperf-021-5-2-tlb-working-set"></a>

### CPERF-021: Measure Translation Working Set Separately From Data Cache

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-180][c-common-pitfalls-cpit-180]

When PMU evidence shows TLB misses or page walks, evaluate page locality, working-set size, mapping
stability, and supported larger page sizes. Do not infer translation locality from a good L1 or LLC
hit rate.

Transparent huge pages can map more memory with one TLB entry, but they also change fault, clearing,
fragmentation, latency, and memory behavior. Their use requires workload evidence and a fallback
policy.[linux-thp][linux-thp]

#### Local examples

**Contextual example:**

Harness record using <stddef.h>/<stdint.h>. Populate with target-defined PMU events and measured
elapsed time. A missing PMU capability is recorded as unavailable, not as a zero result.

```c
typedef struct TranslationEvidence
{
        size_t page_size_bytes;
        size_t mapped_bytes;

        uint64_t page_walk_count;
        uint64_t tlb_miss_count;
        uint64_t elapsed_ns;
} translation_evidence_t;
```

---

<a id="cperf-022"></a>

<a id="cperf-022-5-3-tlb-invalidation-scope"></a>

### CPERF-022: Scope TLB Invalidation to the Smallest Correct Domain

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-180][c-common-pitfalls-cpit-180]

Kernel, runtime, and memory-manager code must target the smallest correct CPU set and
virtual-address range when invalidating translations. Hot algorithms should avoid frequent mapping,
unmapping, or protection changes when stable mappings provide equivalent isolation.

Linux distinguishes global, address-space, range, and page invalidation and notes that a CPU which
never ran an address space need not receive its flush.[linux-cachetlb][linux-cachetlb]

#### Local examples

**Contextual example:**

Privileged platform-owner fragment with a validated callback. The adapter computes the complete
required CPU set and address range and supplies architecture-required barriers. Ordinary module code
never omits a required remote invalidation for speed.

```c
ret = invalidate_range(address_space_context, start_page, page_count,
                       participating_cpu_set);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cperf-023"></a>

<a id="cperf-023-5-4-cache-set-conflict-analysis"></a>

### CPERF-023: Cache-Set Placement Is an Allocator-Level Experiment

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-181][c-common-pitfalls-cpit-181]

When a workload has unexplained conflict misses despite adequate nominal cache capacity, allocator
or kernel owners may investigate cache-set placement and page coloring. Application code must not
encode undocumented physical-address assumptions.

The experiment must record the physical-index information available to the software, the target
cache geometry, page migration behavior, and the memory fragmentation tradeoff.

#### Local examples

**Contextual example:**

An allocator-level experiment record. Physical placement or cache hashing must not be inferred from
portable pointer bits. Keep a baseline, working set and byte consumption comparable.

```c
typedef struct PlacementExperiment
{
        size_t allocation_stride_bytes;
        size_t working_set_bytes;

        uint32_t    allocator_variant_id;
        const char *cache_event_record;
} placement_experiment_t;
```

---

<a id="cperf-043"></a>

<a id="cperf-043-5-5-hot-page-residency-policy"></a>

### CPERF-043: Deterministic Hot Paths Define Page-Residency Policy

**Class:** PERFORMANCE. Apply the scope and requirement words below.

A latency-critical path that cannot tolerate major faults, first-touch allocation, lazy commitment,
or page-table construction must define when its working set is allocated, touched, committed, and
released. Pre-faulting or locking memory is permitted only for a bounded set with an explicit
resource limit, privilege/failure policy, NUMA placement, and measurement of system-wide impact.

Do not call `mlockall`, touch arbitrary process memory, or disable paging as a generic speed
optimization. DPDK documents memory locking as one option for avoiding page faults in deterministic
data-plane execution, while also making NUMA and huge-page placement part of the
design.[dpdk-performance][dpdk-performance]

#### Local examples

**Contextual example:**

Lifecycle-owner fragment, before the bounded phase starts. The platform callback defines
prefault/locking rights, resource limits and failure behavior. This does not claim that a hosted OS
becomes hard real time.

```c
ret = prepare_resident_pages(memory_context, buffer, capacity_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
ret = enter_bounded_phase(runtime_context);
```

---

<a id="cperf-024"></a>

<a id="cperf-024-6-1-atomic-operation-amortization"></a>

### CPERF-024: Amortize Global Atomic Operations

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-186][c-common-pitfalls-cpit-186]

Hot item-by-item processing should consider paying one global atomic operation per validated batch
rather than per item. The batch contract must preserve capacity, overflow, failure atomicity,
fairness, and bounded latency.

DPDK documents improved performance from bulk operations because a burst can share bookkeeping and
expensive atomic work.[dpdk-performance][dpdk-performance]

#### Local examples

**Contextual example:**

Owning-thread body. `flush_batch` must define one commit point and all-or-nothing failure here.
Counters/queues define shutdown flush, maximum delay, overflow and fairness separately. A
partial-success transport needs a progress field instead of this reset.

```c
ret = flush_batch(owner_context, pending_count);
if (ret != EXIT_SUCCESS)
        goto function_output;
pending_count = 0u;
```

---

<a id="cperf-025"></a>

<a id="cperf-025-6-2-semantic-synchronization-abstraction"></a>

### CPERF-025: Hide Raw Atomics Behind Semantic Operations

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Ordinary module logic should call semantic operations such as queue publication, reference
acquisition, or snapshot reading. Raw memory orders and fences belong inside a small reviewed
synchronization abstraction.

The abstraction must document the weakest sufficient ordering and its matching operation. Stronger
ordering must not be emitted merely because the protocol was not analyzed.

#### Local examples

**Contextual example:**

Consumer-owned port declaration. Its owner defines full/closed states, memory ordering, lifetime and
bounded execution. The consumer does not invent an atomic protocol at the call site.

```c
typedef int (*queue_try_push_cb_t)(void *context, const unsigned char *data,
                                   size_t size_bytes);
```

---

<a id="cperf-026"></a>

<a id="cperf-026-6-3-read-mostly-synchronization-selection"></a>

### CPERF-026: Use Reader-Optimized Schemes Only for Matching Workloads

**Class:** PERFORMANCE. Apply the scope and requirement words below.

RCU, sequence counters, immutable snapshots, and copy-on-write structures are specialized
synchronization schemes, not generic replacements for locks.

- RCU primarily serves read-mostly structures and makes update-side lifetime management
  explicit.[linux-rcu][linux-rcu]
- sequence counters serve rarely written consistent snapshots whose readers can retry; protected
  pointer lifetime requires a separate mechanism.[linux-seqcount][linux-seqcount]
- a reference count can destroy read scalability by making every reader write shared state.

Selection must document reader/writer ratio, retry bounds, reclamation, pointer lifetime,
preemption, real-time behavior, and writer serialization.

#### Local examples

**Contextual example:**

Function-tail fragment. ret and snapshot are declared and initialized at entry. Validated callbacks
implement retention/reclamation, and `release_snapshot` is infallible. A retry counter or read-only
access alone does not protect pointed-to objects.

```c
ret = acquire_snapshot(snapshot_context, &snapshot);
if (ret != EXIT_SUCCESS)
        goto function_output;
ret = lookup(snapshot_context, snapshot, key, out);
function_output : if (snapshot != (const snapshot_t *)(NULL))
{
        release_snapshot(snapshot_context, snapshot);
}

return ret;
```

---

<a id="cperf-027"></a>

<a id="cperf-027-6-4-single-access-compiler-contract"></a>

### CPERF-027: Lockless Accesses Constrain Compiler Transformation

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Lockless shared-memory protocols must not assume that one source-level read or write becomes one
machine access unless an approved access primitive establishes that property. Use the project's
atomic or single-access wrapper; do not use a raw `volatile` object as a concurrency primitive.

Linux documents that `READ_ONCE()` and `WRITE_ONCE()` prevent transformations such as merged,
invented, or torn accesses, while not acting as general CPU memory
barriers.[linux-memory-barriers][linux-memory-barriers]

#### Local examples

**Contextual example:**

Synchronization-owner fragment after validating `shared_value` and its lifetime. Include
<stdatomic.h>. The matching publication is specified by the protocol; this ISO C example does not
implement Linux READ_ONCE or guarantee a particular single machine instruction.

```c
value = atomic_load_explicit(shared_value, memory_order_acquire);
```

---

<a id="cperf-046"></a>

<a id="cperf-046-6-5-contention-wait-wake-policy"></a>

### CPERF-046: Contention Needs an Explicit Wait and Wake Policy

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-189: Contention policy creates a spin storm or thundering herd][c-common-pitfalls-cpit-189]

A contended synchronization path must define when a waiter spins, yields, parks, or sleeps, and how
a releaser chooses wake-one, wake-many, or requeue behavior. The policy must match the expected
critical-section duration, CPU count, oversubscription, scheduler class, and latency target.

Do not use an unbounded spin loop as the default fallback. Do not wake every waiter when only one
can make progress unless measurement proves that the extra wakeups help the workload. Linux futex
documentation describes a fast uncontended user-space path and kernel arbitration for contention;
futex requeue operations exist in part to avoid thundering-herd wakeups.[linux-futex][linux-futex]

#### Local examples

**Contextual example:**

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

<a id="cperf-028"></a>

<a id="cperf-028-7-1-hot-code-footprint"></a>

### CPERF-028: Treat Hot-Code Footprint as a Resource

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-187][c-common-pitfalls-cpit-187]

Inlining, unrolling, duplicated specialization, error handling, tracing, and instrumentation must be
evaluated for instruction-cache and decoded-instruction footprint when the workload is front-end
bound. Executed instruction count alone does not describe front-end pressure.

Cold diagnostics and rare fallback paths should remain out of line when profile evidence shows that
their placement expands the hot working set.

#### Local examples

**Contextual example:**

Run on the produced executable, together with the representative workload and target front-end
events. Byte count alone is not a throughput measurement.

```sh
size build-release/tests_static
objdump -d build-release/tests_static > tests-static.disassembly.txt
```

---

<a id="cperf-029"></a>

<a id="cperf-029-7-2-forced-inline-policy"></a>

### CPERF-029: Forced Inlining Requires Evidence

**Class:** PERFORMANCE. Apply the scope and requirement words below.

`static inline` may express a small header-local or type-safe wrapper. A forced inline or
compiler-specific always-inline attribute requires one of:

- a low-level semantic requirement documented by the adapter;
- benchmark and profile evidence for the named target;
- compile-time specialization that removes most of the function body.

Forced inlining must not serve as a generic performance annotation.

#### Local examples

**Contextual example:**

Small module-local helper using <stddef.h>. The infallible accessor return-type exception permits
`size_t` ret but not extra exits. No forced-inline attribute is used; inspect code size and target
results before adding one.

```c
static inline size_t opt_minSize(size_t left, size_t right)
{
        size_t ret = 0u;

        ret = left < right ? left : right;
        goto function_output;

function_output:
        return ret;
}
```

---

<a id="cperf-030"></a>

<a id="cperf-030-7-3-branch-versus-branchless-selection"></a>

### CPERF-030: Branchless Code Is Not Automatically Faster

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-187][c-common-pitfalls-cpit-187]

A conditional branch should become a conditional move, mask operation, or other branchless sequence
only after evaluating predictability, both operand costs, dependency-chain length, side-channel
requirements, and the target cost model.

LLVM's branch-versus-conditional-move work models prediction and critical-path cost separately;
neither form wins universally.[llvm-cmov][llvm-cmov]

Language-level conditional-operator restrictions in `CSTYLE-133` still apply.

#### Local examples

**Contextual example:**

Function-body fragment with validated inputs and entry-declared selected. Compare it with selected =
left < right ? left : right under the same contract. Neither C syntax guarantees branch or cmov
machine code.

```c
if (left < right)
        selected = left;
else
        selected = right;
```

---

<a id="cperf-031"></a>

<a id="cperf-031-7-4-branch-hint-evidence"></a>

### CPERF-031: Branch Hints Need Profile Validation

**Class:** PERFORMANCE. Apply the scope and requirement words below.

`likely`, `unlikely`, compiler expectation intrinsics, and branch-weight metadata must reflect a
measured deployment profile. CI should diagnose stale hints when tooling supports it. LLVM's
MisExpect diagnostics compare expected and observed profile weights.[llvm-misexpect][llvm-misexpect]

#### Local examples

**Contextual example:**

`OPT_UNLIKELY__` is a project compiler-adapter macro with a plain-expression fallback and single
evaluation. Use only for a measured stable rare path; the probability is not guessed from the name.
ret was assigned outside the condition.

```c
if (OPT_UNLIKELY__(ret != EXIT_SUCCESS))
        goto function_output;
```

---

<a id="cperf-032"></a>

<a id="cperf-032-7-5-static-branch-policy"></a>

### CPERF-032: Patchable Static Branches Suit Stable Rare Features

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Runtime code patching or static-key mechanisms may remove a repeated hot-path test when the default
state is overwhelmingly stable and updates are rare. The patching abstraction must own instruction
atomicity, synchronization, architecture support, writable-code policy, cache maintenance, and
fallback.

Linux static keys replace the recurring path with architecture-supported jump label patching and
fall back to a normal load/test/branch sequence when support is
absent.[linux-static-keys][linux-static-keys]

#### Local examples

**Contextual example:**

`feature_is_enabled` is an infallible read-only predicate from a bound port. A platform
implementation may use a static key only under its approved patching, lifetime and I-cache
synchronization contract. The ordinary module performs no text patching.

```c
if (feature_is_enabled(feature_context))
{
        ret = trace(trace_context, event);
        if (ret != EXIT_SUCCESS)
                goto function_output;
}
```

---

<a id="cperf-033"></a>

<a id="cperf-033-7-6-stable-indirect-target-binding"></a>

### CPERF-033: Stable Indirect Targets May Bind Outside the Inner Loop

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-187][c-common-pitfalls-cpit-187]

When a function target cannot change during a hot loop, the dispatch owner may bind it once outside
the loop. The binding must preserve lifetime, callback validation, synchronization, instrumentation,
and hot-update behavior.

This technique is profile-gated; it must not cache a callback across a point that can mutate or
invalidate the callback table.

#### Local examples

**Contextual example:**

Declare process, `process_context`, index and ret at entry, with typed NULL for pointers. Validate
the table, mandatory callback and item extent before this fragment. The binder prevents
replacement/unload for the entire loop. This is not permission to bypass callback instrumentation.

```c
process         = callbacks->process;
process_context = callbacks->process_context;
for (index = 0u; index < item_count; index++)
{
        ret = process(process_context, &items[index]);
        if (ret != EXIT_SUCCESS)
                goto function_output;
}
```

---

<a id="cperf-034"></a>

<a id="cperf-034-7-7-profile-guided-code-placement"></a>

### CPERF-034: Code Placement and Alignment Are Profile-Gated

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Manual function, loop, or basic-block alignment must not be applied globally. Use PGO, linker
layout, or target-specific placement only after front-end events identify a placement problem.
Record code-size growth and effects on other hot regions.

Deep tiny-call chains or recursion in a front-end-bound path may be investigated for
return-prediction pressure, but no fixed call-depth limit can be inferred from one CPU generation.

#### Local examples

**Contextual example:**

Commands on a built ELF test binary. A target owner may compare PGO/layout variants, but no
arbitrary alignment threshold is asserted here.

```sh
# Inspect the final text layout for the actual optimized build.
readelf -S build-release/tests_static
objdump -d build-release/tests_static > final-layout.txt
```

---

<a id="cperf-035"></a>

<a id="cperf-035-8-1-prefetch-distance-contract"></a>

### CPERF-035: Software Prefetch Has a Distance Contract

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-182][c-common-pitfalls-cpit-182]

Software prefetch requires:

- a measured miss stream not already hidden by hardware prefetch;
- a target-specific distance between request and consumption;
- independent work available during that distance;
- safe address formation that does not cross an invalid mapping;
- measurement of cache pollution, miss-status resource pressure, page walks, memory bandwidth, and
  compiler placement.

Do not add software prefetch to a workload already limited by memory bandwidth. Pipeline several
independent objects when that provides useful work between prefetch and consumption.

#### Local examples

**Contextual example:**

Entry-declared index/distance/ret; validated callbacks and full array extent. prefetch is infallible
and must not retain the pointer. distance is selected by a measured profile; subtraction is safe
because index < `item_count`. Measure pollution and bandwidth, not just demand misses.

```c
for (index = 0u; index < item_count; index++)
{
        if (distance < item_count - index)
                prefetch(prefetch_context, &items[index + distance]);
        ret = consume(consume_context, &items[index]);
        if (ret != EXIT_SUCCESS)
                goto function_output;
}
```

---

<a id="cperf-036"></a>

<a id="cperf-036-8-2-dma-cache-line-layout"></a>

### CPERF-036: DMA Layout Accounts for Cache-Line Transactions

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-190][c-common-pitfalls-cpit-190]

DMA descriptors, producer/consumer flags, and payload placement must follow the platform coherency
contract. Where the device and memory subsystem benefit from it, burst structures should permit
complete cache-line DMA writes instead of repeated partial-line writes. DPDK documents lower cost
for full cache-line PCI DMA writes.[dpdk-performance][dpdk-performance]

Padding must not place independently written CPU and DMA ownership fields in the same coherence
unit.

#### Local examples

**Contextual example:**

A platform-owner descriptor, not a wire format. Include <stddef.h>/<stdint.h>. The mapping contract
defines actual alignment, coherency, cache maintenance, permitted cache-line rounding and ownership
handover. `used_bytes` never authorizes stores into adjacent allocations.

```c
typedef struct DmaBufferView
{
        unsigned char *data;
        size_t         capacity_bytes;
        size_t         used_bytes;

        uint32_t mapping_id;
} dma_buffer_view_t;
```

---

<a id="cperf-037"></a>

<a id="cperf-037-8-3-non-temporal-store-policy"></a>

### CPERF-037: Non-Temporal Stores Require Streaming Reuse Evidence

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-184][c-common-pitfalls-cpit-184]

Non-temporal or write-combining stores may be used only when measurement shows a large write stream
with little near-term CPU reuse and harmful cache pollution. They must not become the default
implementation of a large copy.

The adapter contract must define alignment, minimum profitable size, fallback, ordering, completion,
and publication. Before another CPU or device receives a ready flag, the implementation must issue
the architecture-defined ordering or completion operation for preceding streaming stores.

#### Local examples

**Contextual example:**

Platform-owner sequence through validated callbacks. `complete_stores` supplies target/device
completion and ordering, not merely a compiler barrier. Do not publish on either preceding failure.
The backend defines aliasing, alignment, profitable-size threshold and cached fallback.

```c
ret = stream_copy(stream_context, destination, source, size_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
ret = complete_stores(stream_context);
if (ret != EXIT_SUCCESS)
        goto function_output;
ret = publish_ready(publication_context);
```

---

<a id="cperf-038"></a>

<a id="cperf-038-8-4-full-line-streaming-completion"></a>

### CPERF-038: Complete Streaming Cache Lines When Practical

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-190][c-common-pitfalls-cpit-190]

When a measured write-combining path permits it, complete one cache line before interleaving partial
writes to many lines. The implementation must use the platform cache-line abstraction and must
retain a correct tail path for partial final data.

This rule does not authorize writing bytes outside the destination capacity.

#### Local examples

**Contextual example:**

Entry declarations and validation precede this body; `line_bytes` is nonzero and cursor names the
remaining span. Callbacks must not overrun it. Tail code must not round the logical length up into
unowned bytes. Publication follows the platform completion protocol.

```c
while (remaining_bytes >= line_bytes)
{
        ret = write_line(stream_context, cursor, line_bytes);
        if (ret != EXIT_SUCCESS)
                goto function_output;
        cursor          += line_bytes;
        remaining_bytes -= line_bytes;
}

if (remaining_bytes != 0u)
        ret = write_tail(stream_context, cursor, remaining_bytes);
```

---

<a id="cperf-047"></a>

<a id="cperf-047-8-5-hardware-prefetcher-interaction"></a>

### CPERF-047: Hardware Prefetchers Are Part of the Experiment

**Class:** PERFORMANCE. Apply the scope and requirement words below.

**Related pitfalls:**

- [CPIT-183: Hardware prefetch increases pollution or bandwidth
  pressure][c-common-pitfalls-cpit-183]

A memory-latency experiment must account for the target hardware prefetchers. Regular streams may
already benefit from stride or adjacent-line behavior; extra software prefetch can duplicate work,
consume miss-handling resources, or pollute caches. Intel recommends favoring automatic hardware
prefetch for long, regular patterns and warns that excessive software prefetch consumes machine and
bus resources.[intel-optimization][intel-optimization]

If the platform exposes a supported way to change prefetcher policy, compare the same workload under
the relevant states before attributing a gain to layout or software prefetch. Record the effective
policy with the benchmark baseline.

#### Local examples

**Contextual example:**

An actual A/B measurement record supplied by the target owner. Never change system-wide prefetch
policy from ordinary library code or claim unsupported PMU counters are zero.

```c
typedef struct PrefetchExperiment
{
        const char *effective_hardware_policy;
        size_t      software_distance_items;

        const char *cache_events;
        const char *translation_events;
        const char *bandwidth_events;
} prefetch_experiment_t;
```

---

<a id="cperf-039"></a>

<a id="cperf-039-9-1-performance-review-record"></a>

### CPERF-039: Performance Review Record

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Every accepted microarchitectural optimization must retain a review record with:

- governing `CPERF-*`, `CSTYLE-*`, and `CMOD-*` controls;
- benchmark command and input artifact;
- raw result location and statistical summary;
- PMU event names and their target-specific interpretation;
- generated-code or layout evidence when relevant;
- correctness and differential-test results;
- regression threshold and rollback trigger;
- owner and targets for which the optimization is enabled.

#### Local examples

**Contextual example:**

Evidence paths must resolve to actual run artifacts. This type is not a completed approval record.

```c
typedef struct OptimizationReview
{
        const char *rule_ids;
        const char *baseline_record;
        const char *candidate_record;
        const char *correctness_log;
        const char *regression_policy;
        const char *rollback_trigger;
        const char *owner;
} optimization_review_t;
```

---

<a id="cperf-040"></a>

<a id="cperf-040-9-2-specialized-backend-ci"></a>

### CPERF-040: CI Proves Backend Selection and Equivalence

**Class:** PERFORMANCE. Apply the scope and requirement words below.

CI for each specialized backend must:

1. force or emulate the intended feature set;
2. prove that dispatch selected the backend under test;
3. compare outputs and required side effects with the reference;
4. exercise boundary alignment and length cases;
5. reject execution on unsupported hardware instead of silently weakening the test.

#### Local examples

**Contextual example:**

Harness fragment with entry-declared IDs and ret. `selected_backend` reports the implementation that
will execute; unsupported hardware is not silently counted as passing the optimized test.

```c
ret = selected_backend(dispatch_context, &actual_backend_id);
if (ret != EXIT_SUCCESS)
        goto function_output;
if (actual_backend_id != requested_backend_id)
{
        ret = -ENOTSUP;
        goto function_output;
}

ret = differential_test(test_context);
```

---

<a id="cperf-041"></a>

<a id="cperf-041-9-3-benchmark-regression-policy"></a>

### CPERF-041: Benchmark Regressions Use Stable Thresholds

**Class:** PERFORMANCE. Apply the scope and requirement words below.

Automated performance gates must define noise handling, sample count, confidence or robust summary,
machine isolation, retry policy, and escalation threshold. One noisy run must not rewrite a
target-wide rule.

#### Local examples

**Contextual example:**

Populate from an approved benchmark policy; no arbitrary threshold or claimed speedup is supplied.
Include <stddef.h>/<stdint.h>. Record variability and bytes/latency as well as throughput.

```c
typedef struct RegressionPolicy
{
        size_t warmup_count;
        size_t sample_count;

        uint32_t    allowed_regression_ppm;
        uint32_t    maximum_retries;
        const char *summary_method;
} regression_policy_t;
```

---

<a id="cperf-042"></a>

<a id="cperf-042-9-4-tool-diagnostic-authority"></a>

### CPERF-042: Static Tools Report Evidence, Not Policy

**Class:** PERFORMANCE. Apply the scope and requirement words below.

A checker, compiler remark, profiler, or cost model reports evidence. It does not redefine the
governing control. A documented human review may reject a heuristic diagnostic, but it must preserve
the measurement and rationale for later audit.

#### Local examples

**Contextual example:**

A diagnostic is resolved by fixing the code or by a scoped approved deviation. An empty deviation
field does not itself grant permission.

```c
typedef struct DiagnosticDisposition
{
        const char *rule_id;
        const char *tool_version;
        const char *diagnostic_id;
        const char *evidence_path;
        const char *approved_deviation_id;
} diagnostic_disposition_t;
```

---

## Appendix A. Canonical CBAN register

These restrictions apply to the named platform/API when present. Absence of an API from this table
is not approval. Review actions require evidence of bounds, ownership, error checking, execution
context, and the replacement's semantics. The API family name does not prove a wrapper safe. A
proposed review exception must name the corresponding CSTYLE control and the selected execution
profile.

Restrictions on ctype/strlen uses depend on their invalid preconditions, not solely on whether data
originated outside the module. Untrusted executable loading without validation is a banned pattern.
A secure erase or comparison requires a qualified primitive, not just a generic optimization
barrier.

| ID                            | API or condition                                    | Action                  | Required alternative or review evidence                                                                     |
| ----------------------------- | --------------------------------------------------- | ----------------------- | ----------------------------------------------------------------------------------------------------------- |
| <a id="cban-001"></a>CBAN-001 | `gets`                                              | ban                     | bounded line-input wrapper with explicit capacity and status                                                |
| <a id="cban-002"></a>CBAN-002 | `_getts`                                            | ban                     | bounded text-input wrapper with explicit capacity                                                           |
| <a id="cban-003"></a>CBAN-003 | `strcpy`                                            | ban                     | project copy wrapper with destination capacity and status                                                   |
| <a id="cban-004"></a>CBAN-004 | `wcscpy`                                            | ban                     | wide-string copy wrapper with destination capacity and status                                               |
| <a id="cban-005"></a>CBAN-005 | `_tcscpy`                                           | ban                     | platform text wrapper with destination capacity and status                                                  |
| <a id="cban-006"></a>CBAN-006 | `_mbscpy`                                           | ban                     | encoding-aware bounded copy wrapper                                                                         |
| <a id="cban-007"></a>CBAN-007 | `lstrcpy`                                           | ban                     | platform bounded-copy wrapper                                                                               |
| <a id="cban-008"></a>CBAN-008 | `StrCpy`                                            | ban                     | platform bounded-copy wrapper                                                                               |
| <a id="cban-009"></a>CBAN-009 | `strncpy`                                           | review                  | project copy wrapper with explicit truncation status                                                        |
| <a id="cban-010"></a>CBAN-010 | `wcsncpy`                                           | review                  | wide-string wrapper with explicit truncation status                                                         |
| <a id="cban-011"></a>CBAN-011 | `_tcsncpy`                                          | review                  | platform wrapper with explicit status                                                                       |
| <a id="cban-012"></a>CBAN-012 | `_mbsncpy`                                          | review                  | encoding-aware wrapper with explicit status                                                                 |
| <a id="cban-013"></a>CBAN-013 | `strcat`                                            | ban                     | project append wrapper with remaining capacity and status                                                   |
| <a id="cban-014"></a>CBAN-014 | `wcscat`                                            | ban                     | wide-string append wrapper with remaining capacity                                                          |
| <a id="cban-015"></a>CBAN-015 | `_tcscat`                                           | ban                     | platform append wrapper with remaining capacity                                                             |
| <a id="cban-016"></a>CBAN-016 | `_mbscat`                                           | ban                     | encoding-aware bounded append wrapper                                                                       |
| <a id="cban-017"></a>CBAN-017 | `lstrcat`                                           | ban                     | platform bounded-append wrapper                                                                             |
| <a id="cban-018"></a>CBAN-018 | `StrCat`                                            | ban                     | platform bounded-append wrapper                                                                             |
| <a id="cban-019"></a>CBAN-019 | `strncat`                                           | review                  | project append wrapper taking total destination capacity                                                    |
| <a id="cban-020"></a>CBAN-020 | `wcsncat`                                           | review                  | wide append wrapper taking total destination capacity                                                       |
| <a id="cban-021"></a>CBAN-021 | `sprintf`                                           | ban                     | project formatter with explicit capacity and checked result                                                 |
| <a id="cban-022"></a>CBAN-022 | `vsprintf`                                          | ban                     | project variadic formatter with explicit capacity and checked result                                        |
| <a id="cban-023"></a>CBAN-023 | Legacy platform `swprintf` form without a capacity  | ban-pattern             | Do not confuse the legacy signature with ISO C swprintf, which has a size parameter.                        |
| <a id="cban-024"></a>CBAN-024 | `wsprintf`                                          | ban                     | platform formatter with explicit capacity and checked result                                                |
| <a id="cban-025"></a>CBAN-025 | `wvsprintf`                                         | ban                     | platform variadic formatter with explicit capacity and checked result                                       |
| <a id="cban-026"></a>CBAN-026 | `snprintf` unchecked result                         | ban-pattern             | project formatter requiring result validation                                                               |
| <a id="cban-027"></a>CBAN-027 | `vsnprintf` unchecked result                        | ban-pattern             | project variadic formatter requiring result validation                                                      |
| <a id="cban-028"></a>CBAN-028 | `printf` with nonliteral format                     | ban-pattern             | literal format through project logging wrapper                                                              |
| <a id="cban-029"></a>CBAN-029 | `fprintf` with nonliteral format                    | ban-pattern             | literal format through project logging wrapper                                                              |
| <a id="cban-030"></a>CBAN-030 | `syslog` with nonliteral format                     | ban-pattern             | literal format through project logging wrapper                                                              |
| <a id="cban-031"></a>CBAN-031 | `err` with nonliteral format                        | ban-pattern             | literal format through project logging wrapper                                                              |
| <a id="cban-032"></a>CBAN-032 | `warn` with nonliteral format                       | ban-pattern             | literal format through project logging wrapper                                                              |
| <a id="cban-033"></a>CBAN-033 | format strings containing `%n`                      | ban-pattern             | do not use write-through formatting directives                                                              |
| <a id="cban-034"></a>CBAN-034 | `scanf`                                             | ban                     | line-input wrapper plus checked conversion parser                                                           |
| <a id="cban-035"></a>CBAN-035 | `vscanf`                                            | ban                     | line-input wrapper plus checked conversion parser                                                           |
| <a id="cban-036"></a>CBAN-036 | `fscanf`                                            | review                  | line-input wrapper plus checked conversion parser                                                           |
| <a id="cban-037"></a>CBAN-037 | `vfscanf`                                           | review                  | line-input wrapper plus checked conversion parser                                                           |
| <a id="cban-038"></a>CBAN-038 | `sscanf`                                            | review                  | checked parser with explicit ranges                                                                         |
| <a id="cban-039"></a>CBAN-039 | `vsscanf`                                           | review                  | checked parser with explicit ranges                                                                         |
| <a id="cban-040"></a>CBAN-040 | `atoi`                                              | ban                     | checked integer parser with end-pointer, range, and domain validation                                       |
| <a id="cban-041"></a>CBAN-041 | `atol`                                              | ban                     | checked integer parser with end-pointer, range, and domain validation                                       |
| <a id="cban-042"></a>CBAN-042 | `atoll`                                             | ban                     | checked integer parser with end-pointer, range, and domain validation                                       |
| <a id="cban-043"></a>CBAN-043 | `atof`                                              | ban                     | checked floating parser with end-pointer, range, and domain validation                                      |
| <a id="cban-044"></a>CBAN-044 | `itoa`                                              | review                  | project formatter with explicit capacity and checked result                                                 |
| <a id="cban-045"></a>CBAN-045 | `_itoa`                                             | review                  | project formatter with explicit capacity and checked result                                                 |
| <a id="cban-046"></a>CBAN-046 | `ltoa`                                              | review                  | project formatter with explicit capacity and checked result                                                 |
| <a id="cban-047"></a>CBAN-047 | `_ltoa`                                             | review                  | project formatter with explicit capacity and checked result                                                 |
| <a id="cban-048"></a>CBAN-048 | `ultoa`                                             | review                  | project formatter with explicit capacity and checked result                                                 |
| <a id="cban-049"></a>CBAN-049 | `_ultoa`                                            | review                  | project formatter with explicit capacity and checked result                                                 |
| <a id="cban-050"></a>CBAN-050 | `strtok`                                            | ban                     | explicit parser state wrapper                                                                               |
| <a id="cban-051"></a>CBAN-051 | `strtok_r`                                          | review                  | explicit parser wrapper with documented ownership                                                           |
| <a id="cban-052"></a>CBAN-052 | `strsep`                                            | review                  | explicit parser wrapper with documented semantics                                                           |
| <a id="cban-053"></a>CBAN-053 | `strlen` without established termination            | ban-pattern             | Use tracked length or establish a terminator within the readable extent before scanning.                    |
| <a id="cban-054"></a>CBAN-054 | `wcslen` without established termination            | ban-pattern             | Use tracked length or establish a terminator within the readable extent before scanning.                    |
| <a id="cban-055"></a>CBAN-055 | `memcpy` with possible overlap                      | ban-pattern             | Use `memmove` for intentionally overlapping validated byte ranges, or prove that the ranges do not overlap. |
| <a id="cban-056"></a>CBAN-056 | `memcpy` with unvalidated size                      | ban-pattern             | validated range-copy wrapper                                                                                |
| <a id="cban-057"></a>CBAN-057 | `memmove` with unvalidated size                     | ban-pattern             | validated range-move wrapper                                                                                |
| <a id="cban-058"></a>CBAN-058 | `memset` for secret clearing                        | ban-pattern             | Use a qualified explicit-erasure primitive; account for copies and compiler/runtime behavior.               |
| <a id="cban-059"></a>CBAN-059 | `bzero`                                             | review                  | project zeroing or secure-zero wrapper                                                                      |
| <a id="cban-060"></a>CBAN-060 | `memcmp` for secret comparison                      | ban-pattern             | Use a reviewed constant-time primitive for the stated equal-length secret contract.                         |
| <a id="cban-061"></a>CBAN-061 | `memcmp` on structs                                 | ban-pattern             | field-by-field comparison                                                                                   |
| <a id="cban-062"></a>CBAN-062 | `bcopy`                                             | ban                     | validated range-copy or range-move wrapper                                                                  |
| <a id="cban-063"></a>CBAN-063 | `bcmp`                                              | ban                     | field or byte comparison wrapper as appropriate                                                             |
| <a id="cban-064"></a>CBAN-064 | `alloca`                                            | ban                     | bounded automatic storage or project allocation policy                                                      |
| <a id="cban-065"></a>CBAN-065 | `_alloca`                                           | ban                     | bounded automatic storage or project allocation policy                                                      |
| <a id="cban-066"></a>CBAN-066 | `malloc` in critical path                           | review                  | preallocated storage, pool, arena, or explicit failure policy                                               |
| <a id="cban-067"></a>CBAN-067 | `calloc` in critical path                           | review                  | preallocated storage, pool, arena, or explicit failure policy                                               |
| <a id="cban-068"></a>CBAN-068 | `realloc`                                           | review                  | Handle zero explicitly; positive-size failure preserves the owner; invalidate aliases on success.           |
| <a id="cban-069"></a>CBAN-069 | `free` outside owner API                            | ban-pattern             | project ownership/release API                                                                               |
| <a id="cban-070"></a>CBAN-070 | `system`                                            | ban                     | fixed argument-vector process wrapper                                                                       |
| <a id="cban-071"></a>CBAN-071 | `popen`                                             | review                  | fixed argument-vector process wrapper                                                                       |
| <a id="cban-072"></a>CBAN-072 | `execlp`                                            | review                  | absolute-path execution wrapper with controlled environment                                                 |
| <a id="cban-073"></a>CBAN-073 | `execvp`                                            | review                  | absolute-path execution wrapper with controlled environment                                                 |
| <a id="cban-074"></a>CBAN-074 | `CreateProcess` with command-line string assembly   | review                  | Use documented Windows argument quoting, executable identity, environment, and handle inheritance rules.    |
| <a id="cban-075"></a>CBAN-075 | `dlopen` on untrusted path                          | ban-pattern             | Authorize the actual loaded object, path, ABI, provenance, and lifetime through the loader owner.           |
| <a id="cban-076"></a>CBAN-076 | `LoadLibrary` on untrusted path                     | ban-pattern             | Authorize the actual loaded object, path, ABI, provenance, and lifetime through the loader owner.           |
| <a id="cban-077"></a>CBAN-077 | `tmpnam`                                            | ban                     | secure temporary-file wrapper                                                                               |
| <a id="cban-078"></a>CBAN-078 | `tempnam`                                           | ban                     | secure temporary-file wrapper                                                                               |
| <a id="cban-079"></a>CBAN-079 | `mktemp`                                            | ban                     | secure temporary-file wrapper                                                                               |
| <a id="cban-080"></a>CBAN-080 | `_mktemp`                                           | ban                     | secure temporary-file wrapper                                                                               |
| <a id="cban-081"></a>CBAN-081 | `fopen` with external path                          | review                  | project path wrapper with root and mode policy                                                              |
| <a id="cban-082"></a>CBAN-082 | `open` with external path                           | review                  | project path wrapper with descriptor-based workflow                                                         |
| <a id="cban-083"></a>CBAN-083 | `access` before use                                 | review                  | attempt operation directly and handle failure                                                               |
| <a id="cban-084"></a>CBAN-084 | `stat` before use                                   | review                  | descriptor-based validation workflow                                                                        |
| <a id="cban-085"></a>CBAN-085 | `chmod` with external path                          | review                  | project permission wrapper with allowlist                                                                   |
| <a id="cban-086"></a>CBAN-086 | `chown` with external path                          | review                  | project ownership wrapper with allowlist                                                                    |
| <a id="cban-087"></a>CBAN-087 | `recv` unchecked result                             | ban-pattern             | checked I/O wrapper                                                                                         |
| <a id="cban-088"></a>CBAN-088 | `read` unchecked result                             | ban-pattern             | checked I/O wrapper                                                                                         |
| <a id="cban-089"></a>CBAN-089 | `write` unchecked result                            | ban-pattern             | checked write wrapper                                                                                       |
| <a id="cban-090"></a>CBAN-090 | `fread` unchecked result                            | ban-pattern             | checked read wrapper                                                                                        |
| <a id="cban-091"></a>CBAN-091 | `fwrite` unchecked result                           | ban-pattern             | checked write wrapper                                                                                       |
| <a id="cban-092"></a>CBAN-092 | `rand` for security                                 | ban-pattern             | project cryptographic-random wrapper                                                                        |
| <a id="cban-093"></a>CBAN-093 | `srand` for security                                | ban-pattern             | project cryptographic-random wrapper                                                                        |
| <a id="cban-094"></a>CBAN-094 | `random` for security                               | ban-pattern             | project cryptographic-random wrapper                                                                        |
| <a id="cban-095"></a>CBAN-095 | `drand48` family for security                       | ban-pattern             | project cryptographic-random wrapper                                                                        |
| <a id="cban-096"></a>CBAN-096 | `time` as randomness seed                           | ban-pattern             | project cryptographic-random wrapper                                                                        |
| <a id="cban-097"></a>CBAN-097 | `getenv` in privileged or security-sensitive code   | review                  | validated configuration wrapper                                                                             |
| <a id="cban-098"></a>CBAN-098 | `putenv`                                            | review                  | project environment wrapper                                                                                 |
| <a id="cban-099"></a>CBAN-099 | `setenv` in library code                            | review                  | project environment wrapper                                                                                 |
| <a id="cban-100"></a>CBAN-100 | `unsetenv` in library code                          | review                  | project environment wrapper                                                                                 |
| <a id="cban-101"></a>CBAN-101 | `chdir` in library code                             | review                  | absolute-path workflow                                                                                      |
| <a id="cban-102"></a>CBAN-102 | `umask` in library code                             | review                  | project file-creation wrapper                                                                               |
| <a id="cban-103"></a>CBAN-103 | `signal`                                            | review                  | project signal wrapper using defined handler policy                                                         |
| <a id="cban-104"></a>CBAN-104 | `longjmp` across unsafe context                     | review                  | structured error propagation                                                                                |
| <a id="cban-105"></a>CBAN-105 | `fork` in multithreaded code                        | review                  | project process-spawn wrapper                                                                               |
| <a id="cban-106"></a>CBAN-106 | `pthread_cancel`                                    | review                  | cooperative cancellation                                                                                    |
| <a id="cban-107"></a>CBAN-107 | `crypt`                                             | ban (new security code) | approved password-hashing wrapper                                                                           |
| <a id="cban-108"></a>CBAN-108 | `MD5` APIs for security                             | ban-pattern             | approved cryptographic digest wrapper                                                                       |
| <a id="cban-109"></a>CBAN-109 | `SHA1` APIs for signatures or integrity security    | ban-pattern             | approved cryptographic digest wrapper                                                                       |
| <a id="cban-110"></a>CBAN-110 | `DES` APIs                                          | ban (new security code) | approved cipher wrapper                                                                                     |
| <a id="cban-111"></a>CBAN-111 | `3DES` APIs                                         | ban (new security code) | approved cipher wrapper                                                                                     |
| <a id="cban-112"></a>CBAN-112 | Unauthenticated ECB encryption for application data | ban                     | Use an approved authenticated-encryption construction and its complete nonce/key protocol.                  |
| <a id="cban-113"></a>CBAN-113 | `isalpha` outside EOF/unsigned-char domain          | ban-pattern             | Preserve EOF; convert a byte through unsigned char before promotion.                                        |
| <a id="cban-114"></a>CBAN-114 | `isdigit` outside EOF/unsigned-char domain          | ban-pattern             | Preserve EOF; convert a byte through unsigned char before promotion.                                        |
| <a id="cban-115"></a>CBAN-115 | `tolower` outside EOF/unsigned-char domain          | ban-pattern             | Preserve EOF; convert a byte through unsigned char before promotion.                                        |
| <a id="cban-116"></a>CBAN-116 | `toupper` outside EOF/unsigned-char domain          | ban-pattern             | Preserve EOF; convert a byte through unsigned char before promotion.                                        |
| <a id="cban-117"></a>CBAN-117 | Overflow-prone subtraction comparator for `qsort`   | ban-pattern             | Compare relationally and return negative/zero/positive without overflowing subtraction.                     |
| <a id="cban-118"></a>CBAN-118 | `assert` for external input validation              | ban-pattern             | runtime validation with explicit error path                                                                 |
| <a id="cban-119"></a>CBAN-119 | `abort` in library code                             | review                  | error propagation or configured fatal policy                                                                |
| <a id="cban-120"></a>CBAN-120 | `exit` in library code                              | review                  | error propagation or configured fatal policy                                                                |
| <a id="cban-121"></a>CBAN-121 | `perror` in library code                            | review                  | project logging/error API                                                                                   |
| <a id="cban-122"></a>CBAN-122 | `strerror`                                          | review                  | project error-string wrapper                                                                                |
| <a id="cban-123"></a>CBAN-123 | `asctime`                                           | ban                     | project time-format wrapper                                                                                 |
| <a id="cban-124"></a>CBAN-124 | `ctime`                                             | ban                     | project time-format wrapper                                                                                 |
| <a id="cban-125"></a>CBAN-125 | `localtime`                                         | review                  | project time wrapper                                                                                        |
| <a id="cban-126"></a>CBAN-126 | `gmtime`                                            | review                  | project time wrapper                                                                                        |
| <a id="cban-127"></a>CBAN-127 | `realpath` with unchecked external path             | review                  | Validate the object actually opened; canonicalization alone does not prevent link/check-use races.          |
| <a id="cban-128"></a>CBAN-128 | `IsBadReadPtr`                                      | ban                     | ownership, bounds, and API contract validation                                                              |
| <a id="cban-129"></a>CBAN-129 | `IsBadWritePtr`                                     | ban                     | ownership, bounds, and API contract validation                                                              |
| <a id="cban-130"></a>CBAN-130 | `_splitpath`                                        | review                  | project path wrapper with explicit capacities                                                               |
| <a id="cban-131"></a>CBAN-131 | `_makepath`                                         | review                  | project path wrapper with explicit capacities                                                               |
| <a id="cban-132"></a>CBAN-132 | `_fullpath`                                         | review                  | project path wrapper with explicit capacities                                                               |
| <a id="cban-133"></a>CBAN-133 | `gets`-like custom project wrapper                  | ban                     | bounded line-input wrapper                                                                                  |
| <a id="cban-134"></a>CBAN-134 | `strcpy`-like custom project wrapper                | ban                     | bounded copy wrapper with capacity and status                                                               |
| <a id="cban-135"></a>CBAN-135 | `sprintf`-like custom project wrapper               | ban                     | bounded formatting wrapper with checked result                                                              |
| <a id="cban-136"></a>CBAN-136 | unchecked allocation result                         | ban-pattern             | checked allocation wrapper or explicit error path                                                           |
| <a id="cban-137"></a>CBAN-137 | unchecked multiplication before allocation          | ban-pattern             | checked multiplication helper                                                                               |
| <a id="cban-138"></a>CBAN-138 | unchecked addition before buffer operation          | ban-pattern             | checked addition helper                                                                                     |
| <a id="cban-139"></a>CBAN-139 | unchecked narrowing conversion before size use      | ban-pattern             | checked conversion helper                                                                                   |
| <a id="cban-140"></a>CBAN-140 | ignored return from security-sensitive API          | ban-pattern             | check the return value and handle failure explicitly                                                        |

---

<a id="worked-example"></a>

## Appendix B. Complete local-contract example

The following files are complete source files, not independent fragments. They compile together with
the emitter, compiler adapter, composition, and CMake files in [the architecture
example][c-module-architecture-worked-example]. The [test program][c-common-pitfalls-worked-example]
checks the same interfaces.

The buffer owns a control object and its byte allocation. A caller-supplied allocator family
supplies and releases both; its context is borrowed. All operations require external
synchronization. Resize is transactional on failure, zero size frees payload storage without calling
`realloc`, and growth exposes only initialized bytes. Append requires an independent borrowed input
span. The API does not export an internal data pointer. Copy states its capacity and output count
behavior explicitly. The payload budget excludes the control object's fixed overhead, which a
system-wide memory budget must also account for.

`CHECKED_*` is an approved stateless foundation, not a peer. Its helpers perform bounds checks
before arithmetic and keep outputs unchanged on failure. The four-octet codec demonstrates a
specified wire representation independently of C struct layout. The decimal parser has an explicit
ten-digit work limit.

---

<a id="example-foundation-inc-project_status-h"></a>

### `foundation/inc/project_status.h`

<!-- example-file: foundation/inc/project_status.h -->

```c
/*
 * SPDX-FileCopyrightText: 2026 Rafael V. Volkmer
 * SPDX-License-Identifier: GPL-3.0-only
 */

#if !defined(SAMPLE_PROJECT_STATUS_H)
  #define SAMPLE_PROJECT_STATUS_H

/* Project values, not POSIX errno numbers. Zero means success. */
enum ProjectStatus
{
        PROJECT_OK           = 0,
        PROJECT_ERR_INVALID  = -1,
        PROJECT_ERR_RANGE    = -2,
        PROJECT_ERR_MEMORY   = -3,
        PROJECT_ERR_CAPACITY = -4,
        PROJECT_ERR_BUSY     = -5,
        PROJECT_ERR_IO       = -6
};

#endif
```

---

<a id="example-foundation-inc-memory_port-h"></a>

### `foundation/inc/memory_port.h`

<!-- example-file: foundation/inc/memory_port.h -->

```c
/*
 * SPDX-FileCopyrightText: 2026 Rafael V. Volkmer
 * SPDX-License-Identifier: GPL-3.0-only
 */

#if !defined(SAMPLE_MEMORY_PORT_H)
  #define SAMPLE_MEMORY_PORT_H

  #include <stddef.h>

/*
 * alloc: positive size; suitable alignment for fundamental object types.
 * resize: non-NULL owned base and positive size. NULL preserves the old
 * allocation. Success invalidates the old pointer and all its aliases.
 * release: accepts NULL; otherwise requires this family's owned base.
 * Calls may allocate or block; not ISR/signal-safe in this host profile.
 * None of these callbacks re-enters the consuming module or fails nonlocally.
 * The binder keeps context and callback code alive through module destruction.
 * The table is copied; context is borrowed. These are in-process contracts.
 */
typedef void *(*memory_alloc_fn_t)(void *context, size_t size_bytes);
typedef void *(*memory_resize_fn_t)(void *context, void *base,
                                    size_t size_bytes);
typedef void (*memory_release_fn_t)(void *context, void *base);

typedef struct MemoryPort
{
        void               *context;
        memory_alloc_fn_t   alloc;
        memory_resize_fn_t  resize;
        memory_release_fn_t release;
} memory_port_t;

#endif
```

---

<a id="example-foundation-inc-checked-h"></a>

### `foundation/inc/checked.h`

<!-- example-file: foundation/inc/checked.h -->

```c
/*
 * SPDX-FileCopyrightText: 2026 Rafael V. Volkmer
 * SPDX-License-Identifier: GPL-3.0-only
 */

#if !defined(SAMPLE_CHECKED_H)
  #define SAMPLE_CHECKED_H

  #include <stddef.h>
  #include <stdint.h>

/*
 * Thread-safe for disjoint outputs. No allocation or retained pointers.
 * out must name a writable object of its declared type. On error it is
 * unchanged. NULL is rejected. Input/output objects must not overlap.
 */
int CHECKED_addSize(size_t left, size_t right, size_t *out);
int CHECKED_mulSize(size_t left, size_t right, size_t *out);

/* Accept 1..10 ASCII decimal digits, no sign, space, NUL, or suffix. */
int CHECKED_parseU32(const char *text, size_t length, uint32_t *out);

/* Four-octet big-endian representation. Require CHAR_BIT == 8. */
int CHECKED_encodeU32(uint32_t value, uint8_t *out, size_t capacity);
int CHECKED_decodeU32(const uint8_t *data, size_t length, uint32_t *out);

#endif
```

---

<a id="example-foundation-src-checked-c"></a>

### `foundation/src/checked.c`

<!-- example-file: foundation/src/checked.c -->

```c
/*
 * SPDX-FileCopyrightText: 2026 Rafael V. Volkmer
 * SPDX-License-Identifier: GPL-3.0-only
 */

#include "checked.h"

#include <limits.h>
#include <stddef.h>
#include <stdint.h>

#include "project_status.h"

#define CHECKED_U32_OCTETS         ((size_t)4u)
#define CHECKED_BITS_PER_OCTET     ((size_t)8u)
#define CHECKED_DECIMAL_DIGITS_MAX ((size_t)10u)
#define CHECKED_DECIMAL_BASE       UINT32_C(10)
#define CHECKED_OCTET_MASK         UINT32_C(255)

#define CHECKED_ASCII_ZERO 0x30
#define CHECKED_ASCII_NINE 0x39

_Static_assert(CHAR_BIT == CHECKED_BITS_PER_OCTET,
               "The sample wire format uses octets");
_Static_assert('0' == CHECKED_ASCII_ZERO, "ASCII zero required");
_Static_assert('9' == CHECKED_ASCII_NINE, "ASCII nine required");

int CHECKED_addSize(size_t left, size_t right, size_t *out)
{
        int ret = PROJECT_OK;

        if (out == (size_t *)(NULL))
        {
                ret = PROJECT_ERR_INVALID;
                goto function_output;
        }

        if (left > SIZE_MAX - right)
        {
                ret = PROJECT_ERR_RANGE;
                goto function_output;
        }

        *out = left + right;

function_output:
        return ret;
}

int CHECKED_mulSize(size_t left, size_t right, size_t *out)
{
        int ret = PROJECT_OK;

        if (out == (size_t *)(NULL))
        {
                ret = PROJECT_ERR_INVALID;
                goto function_output;
        }

        if ((right != 0u) && (left > SIZE_MAX / right))
        {
                ret = PROJECT_ERR_RANGE;
                goto function_output;
        }

        *out = left * right;

function_output:
        return ret;
}

int CHECKED_parseU32(const char *text, size_t length, uint32_t *out)
{
        int ret = PROJECT_OK;

        unsigned char ch    = 0u;
        size_t        index = 0u;

        uint32_t value = 0u;
        uint32_t digit = 0u;

        if ((text == (const char *)(NULL)) || (out == (uint32_t *)(NULL)))
        {
                ret = PROJECT_ERR_INVALID;
                goto function_output;
        }

        if ((length == 0u) || (length > CHECKED_DECIMAL_DIGITS_MAX))
        {
                ret = PROJECT_ERR_RANGE;
                goto function_output;
        }

        for (index = 0u; index < length; index++)
        {
                ch = (unsigned char)text[index];
                if ((ch < (unsigned char)'0') || (ch > (unsigned char)'9'))
                {
                        ret = PROJECT_ERR_INVALID;
                        goto function_output;
                }

                digit = (uint32_t)(ch - (unsigned char)'0');
                if (value > (UINT32_MAX - digit) / CHECKED_DECIMAL_BASE)
                {
                        ret = PROJECT_ERR_RANGE;
                        goto function_output;
                }

                value = (value * CHECKED_DECIMAL_BASE) + digit;
        }

        *out = value;

function_output:
        return ret;
}

int CHECKED_encodeU32(uint32_t value, uint8_t *out, size_t capacity)
{
        int ret = PROJECT_OK;

        size_t       index = 0u;
        unsigned int shift = 0u;

        if (out == (uint8_t *)(NULL))
        {
                ret = PROJECT_ERR_INVALID;
                goto function_output;
        }

        if (capacity < CHECKED_U32_OCTETS)
        {
                ret = PROJECT_ERR_CAPACITY;
                goto function_output;
        }

        for (index = 0u; index < CHECKED_U32_OCTETS; index++)
        {
                shift      = (unsigned int)((CHECKED_U32_OCTETS - 1u - index) *
                                            CHECKED_BITS_PER_OCTET);
                out[index] = (uint8_t)((value >> shift) & CHECKED_OCTET_MASK);
        }

function_output:
        return ret;
}

int CHECKED_decodeU32(const uint8_t *data, size_t length, uint32_t *out)
{
        int ret = PROJECT_OK;

        size_t index = 0u;

        uint32_t value = 0u;

        if ((data == (const uint8_t *)(NULL)) || (out == (uint32_t *)(NULL)))
        {
                ret = PROJECT_ERR_INVALID;
                goto function_output;
        }

        if (length != CHECKED_U32_OCTETS)
        {
                ret = PROJECT_ERR_RANGE;
                goto function_output;
        }

        for (index = 0u; index < CHECKED_U32_OCTETS; index++)
        {
                value = (value << CHECKED_BITS_PER_OCTET) |
                        (uint32_t)data[index];
        }

        *out = value;

function_output:
        return ret;
}
```

---

<a id="example-modules-buffer-inc-buffer-h"></a>

### `modules/buffer/inc/buffer.h`

<!-- example-file: modules/buffer/inc/buffer.h -->

```c
/*
 * SPDX-FileCopyrightText: 2026 Rafael V. Volkmer
 * SPDX-License-Identifier: GPL-3.0-only
 */

#if !defined(SAMPLE_BUFFER_H)
  #define SAMPLE_BUFFER_H

  #include <stddef.h>
  #include <stdint.h>

  #include "compiler_api.h"
  #include "memory_port.h"

/*
 * Opaque, non-copyable. All operations require external synchronization.
 * The host profile provides no ISR/signal-safety or real-time guarantee.
 * Debug invariant failure follows the sample profile's abort policy.
 */
typedef struct Buffer buffer_t;

/*
 * out points to an initialized NULL handle; unchanged on failure.
 * memory is copied. Its borrowed context/code outlives the buffer.
 * max_size_bytes > 0 is a payload budget; the control object is additional.
 * create allocates only the control object, using the supplied family.
 */
BUFFER_API int BUFFER_create(buffer_t **out, const memory_port_t *memory,
                             size_t max_size_bytes);

/*
 * May allocate. Failure leaves size and contents unchanged.
 * Growth zeroes newly exposed bytes. Zero releases payload storage without
 * invoking resize with zero. All internal aliases expire after success.
 */
BUFFER_API int BUFFER_resize(buffer_t *buffer, size_t size_bytes);

/*
 * May allocate. data is borrowed for this call and readable for size_bytes.
 * NULL data is allowed only for zero bytes. data must not refer to the buffer
 * control object or its storage. Failure leaves contents/size unchanged.
 */
BUFFER_API int BUFFER_append(buffer_t *buffer, const uint8_t *data,
                             size_t size_bytes);

/*
 * No allocation. written is required and receives zero on failure.
 * out may be NULL only with capacity zero. Success copies the whole payload.
 * All writable outputs must be disjoint from each other and buffer storage.
 * A non-NULL out must name at least capacity writable bytes.
 */
BUFFER_API int BUFFER_copy(const buffer_t *buffer, uint8_t *out,
                           size_t capacity, size_t *written);

/* handle is required; *handle may be NULL. Success releases and clears it. */
BUFFER_API int BUFFER_destroy(buffer_t **handle);

#endif
```

---

<a id="example-modules-buffer-src-buffer-c"></a>

### `modules/buffer/src/buffer.c`

<!-- example-file: modules/buffer/src/buffer.c -->

```c
/*
 * SPDX-FileCopyrightText: 2026 Rafael V. Volkmer
 * SPDX-License-Identifier: GPL-3.0-only
 */

#include "buffer.h"

#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include "checked.h"
#include "memory_port.h"
#include "project_status.h"

struct Buffer
{
        memory_port_t memory;
        uint8_t      *data;
        size_t        size_bytes;
        size_t        max_size_bytes;
};

int BUFFER_create(buffer_t **out, const memory_port_t *memory,
                  size_t max_size_bytes)
{
        int ret = PROJECT_OK;

        buffer_t *buffer = (buffer_t *)(NULL);

        if ((out == (buffer_t **)(NULL)) ||
            (memory == (const memory_port_t *)(NULL)) || (max_size_bytes == 0u))
        {
                ret = PROJECT_ERR_INVALID;
                goto function_output;
        }

        if ((*out != (buffer_t *)(NULL)) ||
            (memory->alloc == (memory_alloc_fn_t)(NULL)) ||
            (memory->resize == (memory_resize_fn_t)(NULL)) ||
            (memory->release == (memory_release_fn_t)(NULL)))
        {
                ret = PROJECT_ERR_INVALID;
                goto function_output;
        }

        buffer = (buffer_t *)memory->alloc(memory->context, sizeof(*buffer));
        if (buffer == (buffer_t *)(NULL))
        {
                ret = PROJECT_ERR_MEMORY;
                goto function_output;
        }

        *buffer = (buffer_t){ .memory         = *memory,
                              .data           = (uint8_t *)(NULL),
                              .size_bytes     = 0u,
                              .max_size_bytes = max_size_bytes };
        *out    = buffer;

function_output:
        return ret;
}

int BUFFER_resize(buffer_t *buffer, size_t size_bytes)
{
        int ret = PROJECT_OK;

        uint8_t *replacement = (uint8_t *)(NULL);

        if (buffer == (buffer_t *)(NULL))
        {
                ret = PROJECT_ERR_INVALID;
                goto function_output;
        }

        if (size_bytes > buffer->max_size_bytes)
        {
                ret = PROJECT_ERR_CAPACITY;
                goto function_output;
        }

        if (size_bytes == buffer->size_bytes)
                goto function_output;
        if (size_bytes == 0u)
        {
                buffer->memory.release(buffer->memory.context, buffer->data);
                buffer->data       = (uint8_t *)(NULL);
                buffer->size_bytes = 0u;
                goto function_output;
        }

        if (buffer->data == (uint8_t *)(NULL))
        {
                replacement =
                        (uint8_t *)buffer->memory.alloc(buffer->memory.context,
                                                        size_bytes);
        }
        else
        {
                replacement =
                        (uint8_t *)buffer->memory.resize(buffer->memory.context,
                                                         buffer->data,
                                                         size_bytes);
        }

        if (replacement == (uint8_t *)(NULL))
        {
                ret = PROJECT_ERR_MEMORY;
                goto function_output;
        }

        if (size_bytes > buffer->size_bytes)
        {
                /* CSTYLE-066: return value repeats the validated destination.
                 */
                // NOLINTNEXTLINE(bugprone-unused-return-value)
                memset(replacement + buffer->size_bytes, 0,
                       size_bytes - buffer->size_bytes);
        }

        buffer->data       = replacement;
        buffer->size_bytes = size_bytes;

function_output:
        return ret;
}

int BUFFER_append(buffer_t *buffer, const uint8_t *data, size_t size_bytes)
{
        int ret = PROJECT_OK;

        size_t old_size = 0u;
        size_t new_size = 0u;

        if ((buffer == (buffer_t *)(NULL)) ||
            ((data == (const uint8_t *)(NULL)) && (size_bytes != 0u)))
        {
                ret = PROJECT_ERR_INVALID;
                goto function_output;
        }

        if (size_bytes == 0u)
                goto function_output;
        old_size = buffer->size_bytes;
        ret      = CHECKED_addSize(old_size, size_bytes, &new_size);
        if (ret != PROJECT_OK)
                goto function_output;
        /* Checked addition with a positive addend strictly increases the size.
         */
        if (new_size <= old_size)
        {
                ret = PROJECT_ERR_RANGE;
                goto function_output;
        }

        ret = BUFFER_resize(buffer, new_size);
        if (ret != PROJECT_OK)
                goto function_output;
        /* Input is independent of owned storage by the public contract. */
        /* CSTYLE-066: return value repeats the validated destination. */
        // NOLINTNEXTLINE(bugprone-unused-return-value)
        memcpy(buffer->data + old_size, data, size_bytes);

function_output:
        return ret;
}

int BUFFER_copy(const buffer_t *buffer, uint8_t *out, size_t capacity,
                size_t *written)
{
        int ret = PROJECT_OK;

        if (written == (size_t *)(NULL))
        {
                ret = PROJECT_ERR_INVALID;
                goto function_output;
        }

        *written = 0u;
        if ((buffer == (const buffer_t *)(NULL)) ||
            ((out == (uint8_t *)(NULL)) && (capacity != 0u)))
        {
                ret = PROJECT_ERR_INVALID;
                goto function_output;
        }

        if (capacity < buffer->size_bytes)
        {
                ret = PROJECT_ERR_CAPACITY;
                goto function_output;
        }

        if (buffer->size_bytes != 0u)
        {
                /* CSTYLE-066: return value repeats the validated destination.
                 */
                // NOLINTNEXTLINE(bugprone-unused-return-value)
                memcpy(out, buffer->data, buffer->size_bytes);
        }

        *written = buffer->size_bytes;

function_output:
        return ret;
}

int BUFFER_destroy(buffer_t **handle)
{
        int ret = PROJECT_OK;

        memory_port_t memory = { 0 };
        buffer_t     *buffer = (buffer_t *)(NULL);

        if (handle == (buffer_t **)(NULL))
        {
                ret = PROJECT_ERR_INVALID;
                goto function_output;
        }

        if (*handle == (buffer_t *)(NULL))
                goto function_output;
        buffer = *handle;
        memory = buffer->memory;
        memory.release(memory.context, buffer->data);
        memory.release(memory.context, buffer);
        *handle = (buffer_t *)(NULL);

function_output:
        return ret;
}
```

---

<a id="optimization-worked-example"></a>

## Appendix C. Maintained reference and candidate

The portable reference is compared with a four-byte chunked candidate. Both implementations use byte
accesses and reject the same invalid pointers. The test varies offset, length and search byte,
including empty inputs and chunk tails. This is a correctness example; it does not claim that
chunking is faster. No SIMD, hardware prefetch, NUMA or special store instructions are executed.

---

### `performance/optimization_examples.h`

<!-- example-file: performance/optimization_examples.h -->

```c
#if !defined(SAMPLE_OPTIMIZATION_EXAMPLES_H)
  #define SAMPLE_OPTIMIZATION_EXAMPLES_H

  #include <stddef.h>

/* Inputs are borrowed; count_out is disjoint writable storage.
 * Zero length still requires a non-NULL data pointer. On failure,
 * count_out is unchanged. No allocation or ownership transfer occurs.
 */
int OPT_countByteReference(const unsigned char *data, size_t size_bytes,
                           unsigned char needle, size_t *count_out);
int OPT_countByteChunked(const unsigned char *data, size_t size_bytes,
                         unsigned char needle, size_t *count_out);

#endif
```

---

### `performance/optimization_examples.c`

<!-- example-file: performance/optimization_examples.c -->

```c
#include "optimization_examples.h"

#include <stddef.h>
#include <stdlib.h>

#include "project_status.h"

#define OPT_CHUNK_BYTES ((size_t)4u)
#define OPT_THIRD_BYTE  ((size_t)2u)
#define OPT_FOURTH_BYTE ((size_t)3u)

/* CSTYLE-057: counted-buffer API; length and search byte have distinct roles.
 */
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
int OPT_countByteReference(const unsigned char *data, size_t size_bytes,
                           unsigned char needle, size_t *count_out)
{
        int    ret   = EXIT_SUCCESS;
        size_t count = 0u;
        size_t index = 0u;

        if ((data == (const unsigned char *)(NULL)) ||
            (count_out == (size_t *)(NULL)))
        {
                ret = PROJECT_ERR_INVALID;
                goto function_output;
        }

        for (index = 0u; index < size_bytes; index++)
        {
                if (data[index] == needle)
                        count++;
        }

        *count_out = count;

function_output:
        return ret;
}

/* This candidate exercises a four-byte chunk and a scalar tail.
 * It makes no target-specific speed claim and uses no wide loads.
 */
/* CSTYLE-057: counted-buffer API; length and search byte have distinct roles.
 */
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
int OPT_countByteChunked(const unsigned char *data, size_t size_bytes,
                         unsigned char needle, size_t *count_out)
{
        int    ret   = EXIT_SUCCESS;
        size_t count = 0u;
        size_t index = 0u;

        if ((data == (const unsigned char *)(NULL)) ||
            (count_out == (size_t *)(NULL)))
        {
                ret = PROJECT_ERR_INVALID;
                goto function_output;
        }
        while ((size_bytes - index) >= OPT_CHUNK_BYTES)
        {
                count += (size_t)(data[index] == needle);
                count += (size_t)(data[index + 1u] == needle);
                count += (size_t)(data[index + OPT_THIRD_BYTE] == needle);
                count += (size_t)(data[index + OPT_FOURTH_BYTE] == needle);
                index += OPT_CHUNK_BYTES;
        }

        for (; index < size_bytes; index++)
        {
                if (data[index] == needle)
                        count++;
        }

        *count_out = count;

function_output:
        return ret;
}
```

---

<a id="cban-local-examples"></a>

## Appendix D. Examples for every CBAN entry

The table remains the canonical ban/review decision. These local C excerpts show the required
boundary or precondition for each entry, including platform aliases. Calls with lower-case names are
injected and validated ports in the enclosing operation. Their implementation contracts must be
supplied by the owner; these fragments are not claimed to be standalone wrappers or tested native
API adapters. All locals belong at function entry, with ret first and the required initial values.
The final output label and cleanup are supplied by that enclosing function. Do not change a review
action into a ban, or a ban into permission, based only on an illustrative wrapper name.

---

<a id="cban-001-example"></a>

### CBAN-001: `gets`

**Action:** ban. [Canonical entry][cban-001].

bounded line-input wrapper with explicit capacity and status

Injected bounded-input port: `capacity_chars` includes any required terminator. Its contract
distinguishes EOF, truncation and I/O failure, uses the selected character/encoding domain, and
never writes past capacity. Declarations and required callback validation precede this body
fragment.

```c
ret = read_line(input_context, buffer, capacity_chars, &length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-002-example"></a>

### CBAN-002: `_getts`

**Action:** ban. [Canonical entry][cban-002].

bounded text-input wrapper with explicit capacity

Injected bounded-input port: `capacity_chars` includes any required terminator. Its contract
distinguishes EOF, truncation and I/O failure, uses the selected character/encoding domain, and
never writes past capacity. Declarations and required callback validation precede this body
fragment.

```c
ret = read_line(input_context, buffer, capacity_chars, &length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-003-example"></a>

### CBAN-003: `strcpy`

**Action:** ban. [Canonical entry][cban-003].

project copy wrapper with destination capacity and status

Injected copy port: the actual signature uses the selected char, `wchar_t` or platform character
type. Capacity units and termination/truncation semantics are explicit; validate the readable source
extent. A renamed unbounded strcpy is not an acceptable implementation.

```c
ret = copy_text(copy_context, destination, destination_capacity_chars, source,
                source_length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-004-example"></a>

### CBAN-004: `wcscpy`

**Action:** ban. [Canonical entry][cban-004].

wide-string copy wrapper with destination capacity and status

Injected copy port: the actual signature uses the selected char, `wchar_t` or platform character
type. Capacity units and termination/truncation semantics are explicit; validate the readable source
extent. A renamed unbounded strcpy is not an acceptable implementation.

```c
ret = copy_text(copy_context, destination, destination_capacity_chars, source,
                source_length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-005-example"></a>

### CBAN-005: `_tcscpy`

**Action:** ban. [Canonical entry][cban-005].

platform text wrapper with destination capacity and status

Injected copy port: the actual signature uses the selected char, `wchar_t` or platform character
type. Capacity units and termination/truncation semantics are explicit; validate the readable source
extent. A renamed unbounded strcpy is not an acceptable implementation.

```c
ret = copy_text(copy_context, destination, destination_capacity_chars, source,
                source_length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-006-example"></a>

### CBAN-006: `_mbscpy`

**Action:** ban. [Canonical entry][cban-006].

encoding-aware bounded copy wrapper

Injected copy port: the actual signature uses the selected char, `wchar_t` or platform character
type. Capacity units and termination/truncation semantics are explicit; validate the readable source
extent. A renamed unbounded strcpy is not an acceptable implementation.

```c
ret = copy_text(copy_context, destination, destination_capacity_chars, source,
                source_length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-007-example"></a>

### CBAN-007: `lstrcpy`

**Action:** ban. [Canonical entry][cban-007].

platform bounded-copy wrapper

Injected copy port: the actual signature uses the selected char, `wchar_t` or platform character
type. Capacity units and termination/truncation semantics are explicit; validate the readable source
extent. A renamed unbounded strcpy is not an acceptable implementation.

```c
ret = copy_text(copy_context, destination, destination_capacity_chars, source,
                source_length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-008-example"></a>

### CBAN-008: `StrCpy`

**Action:** ban. [Canonical entry][cban-008].

platform bounded-copy wrapper

Injected copy port: the actual signature uses the selected char, `wchar_t` or platform character
type. Capacity units and termination/truncation semantics are explicit; validate the readable source
extent. A renamed unbounded strcpy is not an acceptable implementation.

```c
ret = copy_text(copy_context, destination, destination_capacity_chars, source,
                source_length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-009-example"></a>

### CBAN-009: `strncpy`

**Action:** review. [Canonical entry][cban-009].

project copy wrapper with explicit truncation status

Injected copy port: the actual signature uses the selected char, `wchar_t` or platform character
type. Capacity units and termination/truncation semantics are explicit; validate the readable source
extent. A renamed unbounded strcpy is not an acceptable implementation.

```c
ret = copy_text(copy_context, destination, destination_capacity_chars, source,
                source_length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-010-example"></a>

### CBAN-010: `wcsncpy`

**Action:** review. [Canonical entry][cban-010].

wide-string wrapper with explicit truncation status

Injected copy port: the actual signature uses the selected char, `wchar_t` or platform character
type. Capacity units and termination/truncation semantics are explicit; validate the readable source
extent. A renamed unbounded strcpy is not an acceptable implementation.

```c
ret = copy_text(copy_context, destination, destination_capacity_chars, source,
                source_length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-011-example"></a>

### CBAN-011: `_tcsncpy`

**Action:** review. [Canonical entry][cban-011].

platform wrapper with explicit status

Injected copy port: the actual signature uses the selected char, `wchar_t` or platform character
type. Capacity units and termination/truncation semantics are explicit; validate the readable source
extent. A renamed unbounded strcpy is not an acceptable implementation.

```c
ret = copy_text(copy_context, destination, destination_capacity_chars, source,
                source_length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-012-example"></a>

### CBAN-012: `_mbsncpy`

**Action:** review. [Canonical entry][cban-012].

encoding-aware wrapper with explicit status

Injected copy port: the actual signature uses the selected char, `wchar_t` or platform character
type. Capacity units and termination/truncation semantics are explicit; validate the readable source
extent. A renamed unbounded strcpy is not an acceptable implementation.

```c
ret = copy_text(copy_context, destination, destination_capacity_chars, source,
                source_length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-013-example"></a>

### CBAN-013: `strcat`

**Action:** ban. [Canonical entry][cban-013].

project append wrapper with remaining capacity and status

Injected append port receives total capacity and current valid length, validates addition and
termination space, and documents output state on failure. Use the correct character/encoding unit
for the platform API.

```c
ret = append_text(append_context, destination, destination_capacity_chars,
                  &used_chars, source, source_length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-014-example"></a>

### CBAN-014: `wcscat`

**Action:** ban. [Canonical entry][cban-014].

wide-string append wrapper with remaining capacity

Injected append port receives total capacity and current valid length, validates addition and
termination space, and documents output state on failure. Use the correct character/encoding unit
for the platform API.

```c
ret = append_text(append_context, destination, destination_capacity_chars,
                  &used_chars, source, source_length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-015-example"></a>

### CBAN-015: `_tcscat`

**Action:** ban. [Canonical entry][cban-015].

platform append wrapper with remaining capacity

Injected append port receives total capacity and current valid length, validates addition and
termination space, and documents output state on failure. Use the correct character/encoding unit
for the platform API.

```c
ret = append_text(append_context, destination, destination_capacity_chars,
                  &used_chars, source, source_length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-016-example"></a>

### CBAN-016: `_mbscat`

**Action:** ban. [Canonical entry][cban-016].

encoding-aware bounded append wrapper

Injected append port receives total capacity and current valid length, validates addition and
termination space, and documents output state on failure. Use the correct character/encoding unit
for the platform API.

```c
ret = append_text(append_context, destination, destination_capacity_chars,
                  &used_chars, source, source_length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-017-example"></a>

### CBAN-017: `lstrcat`

**Action:** ban. [Canonical entry][cban-017].

platform bounded-append wrapper

Injected append port receives total capacity and current valid length, validates addition and
termination space, and documents output state on failure. Use the correct character/encoding unit
for the platform API.

```c
ret = append_text(append_context, destination, destination_capacity_chars,
                  &used_chars, source, source_length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-018-example"></a>

### CBAN-018: `StrCat`

**Action:** ban. [Canonical entry][cban-018].

platform bounded-append wrapper

Injected append port receives total capacity and current valid length, validates addition and
termination space, and documents output state on failure. Use the correct character/encoding unit
for the platform API.

```c
ret = append_text(append_context, destination, destination_capacity_chars,
                  &used_chars, source, source_length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-019-example"></a>

### CBAN-019: `strncat`

**Action:** review. [Canonical entry][cban-019].

project append wrapper taking total destination capacity

Injected append port receives total capacity and current valid length, validates addition and
termination space, and documents output state on failure. Use the correct character/encoding unit
for the platform API.

```c
ret = append_text(append_context, destination, destination_capacity_chars,
                  &used_chars, source, source_length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-020-example"></a>

### CBAN-020: `wcsncat`

**Action:** review. [Canonical entry][cban-020].

wide append wrapper taking total destination capacity

Injected append port receives total capacity and current valid length, validates addition and
termination space, and documents output state on failure. Use the correct character/encoding unit
for the platform API.

```c
ret = append_text(append_context, destination, destination_capacity_chars,
                  &used_chars, source, source_length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-021-example"></a>

### CBAN-021: `sprintf`

**Action:** ban. [Canonical entry][cban-021].

project formatter with explicit capacity and checked result

Injected bounded formatter: its implementation must check native formatting failure and truncation
and handle `va_list` copies when applicable. ISO swprintf and legacy platform swprintf signatures
must not be confused. Output units and termination are part of this port, not guessed from the
native API name.

```c
ret = format_value(format_context, destination, destination_capacity_chars,
                   value, &written_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-022-example"></a>

### CBAN-022: `vsprintf`

**Action:** ban. [Canonical entry][cban-022].

project variadic formatter with explicit capacity and checked result

Injected bounded formatter: its implementation must check native formatting failure and truncation
and handle `va_list` copies when applicable. ISO swprintf and legacy platform swprintf signatures
must not be confused. Output units and termination are part of this port, not guessed from the
native API name.

```c
ret = format_value(format_context, destination, destination_capacity_chars,
                   value, &written_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-023-example"></a>

### CBAN-023: Legacy platform `swprintf` form without a capacity

**Action:** ban-pattern. [Canonical entry][cban-023].

Do not confuse the legacy signature with ISO C swprintf, which has a size parameter.

Injected bounded formatter: its implementation must check native formatting failure and truncation
and handle `va_list` copies when applicable. ISO swprintf and legacy platform swprintf signatures
must not be confused. Output units and termination are part of this port, not guessed from the
native API name.

```c
ret = format_value(format_context, destination, destination_capacity_chars,
                   value, &written_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-024-example"></a>

### CBAN-024: `wsprintf`

**Action:** ban. [Canonical entry][cban-024].

platform formatter with explicit capacity and checked result

Injected bounded formatter: its implementation must check native formatting failure and truncation
and handle `va_list` copies when applicable. ISO swprintf and legacy platform swprintf signatures
must not be confused. Output units and termination are part of this port, not guessed from the
native API name.

```c
ret = format_value(format_context, destination, destination_capacity_chars,
                   value, &written_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-025-example"></a>

### CBAN-025: `wvsprintf`

**Action:** ban. [Canonical entry][cban-025].

platform variadic formatter with explicit capacity and checked result

Injected bounded formatter: its implementation must check native formatting failure and truncation
and handle `va_list` copies when applicable. ISO swprintf and legacy platform swprintf signatures
must not be confused. Output units and termination are part of this port, not guessed from the
native API name.

```c
ret = format_value(format_context, destination, destination_capacity_chars,
                   value, &written_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-026-example"></a>

### CBAN-026: `snprintf` unchecked result

**Action:** ban-pattern. [Canonical entry][cban-026].

project formatter requiring result validation

Injected bounded formatter: its implementation must check native formatting failure and truncation
and handle `va_list` copies when applicable. ISO swprintf and legacy platform swprintf signatures
must not be confused. Output units and termination are part of this port, not guessed from the
native API name.

```c
ret = format_value(format_context, destination, destination_capacity_chars,
                   value, &written_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-027-example"></a>

### CBAN-027: `vsnprintf` unchecked result

**Action:** ban-pattern. [Canonical entry][cban-027].

project variadic formatter requiring result validation

Injected bounded formatter: its implementation must check native formatting failure and truncation
and handle `va_list` copies when applicable. ISO swprintf and legacy platform swprintf signatures
must not be confused. Output units and termination are part of this port, not guessed from the
native API name.

```c
ret = format_value(format_context, destination, destination_capacity_chars,
                   value, &written_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-028-example"></a>

### CBAN-028: `printf` with nonliteral format

**Action:** ban-pattern. [Canonical entry][cban-028].

literal format through project logging wrapper

Counted-text logging port: message is data, never a format string. The adapter uses a literal format
or a byte-output API, excludes %n, and applies redaction and record-injection policy. A failed log
must not replace the original operation failure.

```c
ret = log_text(log_context, message, message_length_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-029-example"></a>

### CBAN-029: `fprintf` with nonliteral format

**Action:** ban-pattern. [Canonical entry][cban-029].

literal format through project logging wrapper

Counted-text logging port: message is data, never a format string. The adapter uses a literal format
or a byte-output API, excludes %n, and applies redaction and record-injection policy. A failed log
must not replace the original operation failure.

```c
ret = log_text(log_context, message, message_length_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-030-example"></a>

### CBAN-030: `syslog` with nonliteral format

**Action:** ban-pattern. [Canonical entry][cban-030].

literal format through project logging wrapper

Counted-text logging port: message is data, never a format string. The adapter uses a literal format
or a byte-output API, excludes %n, and applies redaction and record-injection policy. A failed log
must not replace the original operation failure.

```c
ret = log_text(log_context, message, message_length_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-031-example"></a>

### CBAN-031: `err` with nonliteral format

**Action:** ban-pattern. [Canonical entry][cban-031].

literal format through project logging wrapper

Counted-text logging port: message is data, never a format string. The adapter uses a literal format
or a byte-output API, excludes %n, and applies redaction and record-injection policy. A failed log
must not replace the original operation failure.

```c
ret = log_text(log_context, message, message_length_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-032-example"></a>

### CBAN-032: `warn` with nonliteral format

**Action:** ban-pattern. [Canonical entry][cban-032].

literal format through project logging wrapper

Counted-text logging port: message is data, never a format string. The adapter uses a literal format
or a byte-output API, excludes %n, and applies redaction and record-injection policy. A failed log
must not replace the original operation failure.

```c
ret = log_text(log_context, message, message_length_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-033-example"></a>

### CBAN-033: format strings containing `%n`

**Action:** ban-pattern. [Canonical entry][cban-033].

do not use write-through formatting directives

Counted-text logging port: message is data, never a format string. The adapter uses a literal format
or a byte-output API, excludes %n, and applies redaction and record-injection policy. A failed log
must not replace the original operation failure.

```c
ret = log_text(log_context, message, message_length_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-034-example"></a>

### CBAN-034: `scanf`

**Action:** ban. [Canonical entry][cban-034].

line-input wrapper plus checked conversion parser

Injected bounded-input port: `capacity_chars` includes any required terminator. Its contract
distinguishes EOF, truncation and I/O failure, uses the selected character/encoding domain, and
never writes past capacity. Declarations and required callback validation precede this body
fragment.

```c
ret = read_line(input_context, buffer, capacity_chars, &length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-035-example"></a>

### CBAN-035: `vscanf`

**Action:** ban. [Canonical entry][cban-035].

line-input wrapper plus checked conversion parser

Injected bounded-input port: `capacity_chars` includes any required terminator. Its contract
distinguishes EOF, truncation and I/O failure, uses the selected character/encoding domain, and
never writes past capacity. Declarations and required callback validation precede this body
fragment.

```c
ret = read_line(input_context, buffer, capacity_chars, &length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-036-example"></a>

### CBAN-036: `fscanf`

**Action:** review. [Canonical entry][cban-036].

line-input wrapper plus checked conversion parser

Injected bounded-input port: `capacity_chars` includes any required terminator. Its contract
distinguishes EOF, truncation and I/O failure, uses the selected character/encoding domain, and
never writes past capacity. Declarations and required callback validation precede this body
fragment.

```c
ret = read_line(input_context, buffer, capacity_chars, &length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-037-example"></a>

### CBAN-037: `vfscanf`

**Action:** review. [Canonical entry][cban-037].

line-input wrapper plus checked conversion parser

Injected bounded-input port: `capacity_chars` includes any required terminator. Its contract
distinguishes EOF, truncation and I/O failure, uses the selected character/encoding domain, and
never writes past capacity. Declarations and required callback validation precede this body
fragment.

```c
ret = read_line(input_context, buffer, capacity_chars, &length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-038-example"></a>

### CBAN-038: `sscanf`

**Action:** review. [Canonical entry][cban-038].

checked parser with explicit ranges

Checked parser port: validate the requested numeric domain and upper/lower bounds. Floating parsing
additionally specifies NaN, infinity, locale and range behavior. The destination type follows the
port contract; consumption alone does not prove range validity.

```c
ret = parse_number(parser_context, text, text_length_bytes, &parsed_value,
                   &consumed_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
if (consumed_bytes != text_length_bytes)
{
        ret = -EINVAL;
        goto function_output;
}
```

---

<a id="cban-039-example"></a>

### CBAN-039: `vsscanf`

**Action:** review. [Canonical entry][cban-039].

checked parser with explicit ranges

Checked parser port: validate the requested numeric domain and upper/lower bounds. Floating parsing
additionally specifies NaN, infinity, locale and range behavior. The destination type follows the
port contract; consumption alone does not prove range validity.

```c
ret = parse_number(parser_context, text, text_length_bytes, &parsed_value,
                   &consumed_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
if (consumed_bytes != text_length_bytes)
{
        ret = -EINVAL;
        goto function_output;
}
```

---

<a id="cban-040-example"></a>

### CBAN-040: `atoi`

**Action:** ban. [Canonical entry][cban-040].

checked integer parser with end-pointer, range, and domain validation

Checked parser port: validate the requested numeric domain and upper/lower bounds. Floating parsing
additionally specifies NaN, infinity, locale and range behavior. The destination type follows the
port contract; consumption alone does not prove range validity.

```c
ret = parse_number(parser_context, text, text_length_bytes, &parsed_value,
                   &consumed_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
if (consumed_bytes != text_length_bytes)
{
        ret = -EINVAL;
        goto function_output;
}
```

---

<a id="cban-041-example"></a>

### CBAN-041: `atol`

**Action:** ban. [Canonical entry][cban-041].

checked integer parser with end-pointer, range, and domain validation

Checked parser port: validate the requested numeric domain and upper/lower bounds. Floating parsing
additionally specifies NaN, infinity, locale and range behavior. The destination type follows the
port contract; consumption alone does not prove range validity.

```c
ret = parse_number(parser_context, text, text_length_bytes, &parsed_value,
                   &consumed_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
if (consumed_bytes != text_length_bytes)
{
        ret = -EINVAL;
        goto function_output;
}
```

---

<a id="cban-042-example"></a>

### CBAN-042: `atoll`

**Action:** ban. [Canonical entry][cban-042].

checked integer parser with end-pointer, range, and domain validation

Checked parser port: validate the requested numeric domain and upper/lower bounds. Floating parsing
additionally specifies NaN, infinity, locale and range behavior. The destination type follows the
port contract; consumption alone does not prove range validity.

```c
ret = parse_number(parser_context, text, text_length_bytes, &parsed_value,
                   &consumed_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
if (consumed_bytes != text_length_bytes)
{
        ret = -EINVAL;
        goto function_output;
}
```

---

<a id="cban-043-example"></a>

### CBAN-043: `atof`

**Action:** ban. [Canonical entry][cban-043].

checked floating parser with end-pointer, range, and domain validation

Checked parser port: validate the requested numeric domain and upper/lower bounds. Floating parsing
additionally specifies NaN, infinity, locale and range behavior. The destination type follows the
port contract; consumption alone does not prove range validity.

```c
ret = parse_number(parser_context, text, text_length_bytes, &parsed_value,
                   &consumed_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
if (consumed_bytes != text_length_bytes)
{
        ret = -EINVAL;
        goto function_output;
}
```

---

<a id="cban-044-example"></a>

### CBAN-044: `itoa`

**Action:** review. [Canonical entry][cban-044].

project formatter with explicit capacity and checked result

Injected bounded formatter: its implementation must check native formatting failure and truncation
and handle `va_list` copies when applicable. ISO swprintf and legacy platform swprintf signatures
must not be confused. Output units and termination are part of this port, not guessed from the
native API name.

```c
ret = format_value(format_context, destination, destination_capacity_chars,
                   value, &written_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-045-example"></a>

### CBAN-045: `_itoa`

**Action:** review. [Canonical entry][cban-045].

project formatter with explicit capacity and checked result

Injected bounded formatter: its implementation must check native formatting failure and truncation
and handle `va_list` copies when applicable. ISO swprintf and legacy platform swprintf signatures
must not be confused. Output units and termination are part of this port, not guessed from the
native API name.

```c
ret = format_value(format_context, destination, destination_capacity_chars,
                   value, &written_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-046-example"></a>

### CBAN-046: `ltoa`

**Action:** review. [Canonical entry][cban-046].

project formatter with explicit capacity and checked result

Injected bounded formatter: its implementation must check native formatting failure and truncation
and handle `va_list` copies when applicable. ISO swprintf and legacy platform swprintf signatures
must not be confused. Output units and termination are part of this port, not guessed from the
native API name.

```c
ret = format_value(format_context, destination, destination_capacity_chars,
                   value, &written_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-047-example"></a>

### CBAN-047: `_ltoa`

**Action:** review. [Canonical entry][cban-047].

project formatter with explicit capacity and checked result

Injected bounded formatter: its implementation must check native formatting failure and truncation
and handle `va_list` copies when applicable. ISO swprintf and legacy platform swprintf signatures
must not be confused. Output units and termination are part of this port, not guessed from the
native API name.

```c
ret = format_value(format_context, destination, destination_capacity_chars,
                   value, &written_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-048-example"></a>

### CBAN-048: `ultoa`

**Action:** review. [Canonical entry][cban-048].

project formatter with explicit capacity and checked result

Injected bounded formatter: its implementation must check native formatting failure and truncation
and handle `va_list` copies when applicable. ISO swprintf and legacy platform swprintf signatures
must not be confused. Output units and termination are part of this port, not guessed from the
native API name.

```c
ret = format_value(format_context, destination, destination_capacity_chars,
                   value, &written_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-049-example"></a>

### CBAN-049: `_ultoa`

**Action:** review. [Canonical entry][cban-049].

project formatter with explicit capacity and checked result

Injected bounded formatter: its implementation must check native formatting failure and truncation
and handle `va_list` copies when applicable. ISO swprintf and legacy platform swprintf signatures
must not be confused. Output units and termination are part of this port, not guessed from the
native API name.

```c
ret = format_value(format_context, destination, destination_capacity_chars,
                   value, &written_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-050-example"></a>

### CBAN-050: `strtok`

**Action:** ban. [Canonical entry][cban-050].

explicit parser state wrapper

Parser-owned explicit state; `input_end` and cursor belong to the same validated array. Specify
empty-token handling, mutation and token lifetime. No hidden shared strtok cursor is permitted.

```c
ret = next_token(parser_context, &cursor, input_end, &token_begin,
                 &token_size_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-051-example"></a>

### CBAN-051: `strtok_r`

**Action:** review. [Canonical entry][cban-051].

explicit parser wrapper with documented ownership

Parser-owned explicit state; `input_end` and cursor belong to the same validated array. Specify
empty-token handling, mutation and token lifetime. No hidden shared strtok cursor is permitted.

```c
ret = next_token(parser_context, &cursor, input_end, &token_begin,
                 &token_size_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-052-example"></a>

### CBAN-052: `strsep`

**Action:** review. [Canonical entry][cban-052].

explicit parser wrapper with documented semantics

Parser-owned explicit state; `input_end` and cursor belong to the same validated array. Specify
empty-token handling, mutation and token lifetime. No hidden shared strtok cursor is permitted.

```c
ret = next_token(parser_context, &cursor, input_end, &token_begin,
                 &token_size_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-053-example"></a>

### CBAN-053: `strlen` without established termination

**Action:** ban-pattern. [Canonical entry][cban-053].

Use tracked length or establish a terminator within the readable extent before scanning.

The port searches only the known readable extent and fails when no terminator exists. Use byte or
wide-character units as appropriate; a capacity argument does not by itself prove the pointer has
that extent.

```c
ret = bounded_length(text_context, text, readable_capacity_chars,
                     &length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-054-example"></a>

### CBAN-054: `wcslen` without established termination

**Action:** ban-pattern. [Canonical entry][cban-054].

Use tracked length or establish a terminator within the readable extent before scanning.

The port searches only the known readable extent and fails when no terminator exists. Use byte or
wide-character units as appropriate; a capacity argument does not by itself prove the pointer has
that extent.

```c
ret = bounded_length(text_context, text, readable_capacity_chars,
                     &length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-055-example"></a>

### CBAN-055: `memcpy` with possible overlap

**Action:** ban-pattern. [Canonical entry][cban-055].

Use `memmove` for intentionally overlapping validated byte ranges, or prove that the ranges do not
overlap.

Body fragment after validating live source/destination objects and their extents. `memmove` supports
permitted overlap. This snippet does not permit using arbitrary non-NULL pointers or impose
string-termination semantics on a byte copy.

```c
if ((copy_size_bytes > destination_capacity_bytes) ||
    (copy_size_bytes > source_size_bytes))
{
        ret = -ERANGE;
        goto function_output;
}

if (copy_size_bytes != 0u)
        memmove(destination, source, copy_size_bytes);
```

---

<a id="cban-056-example"></a>

### CBAN-056: `memcpy` with unvalidated size

**Action:** ban-pattern. [Canonical entry][cban-056].

validated range-copy wrapper

Body fragment after validating live source/destination objects and their extents. `memmove` supports
permitted overlap. This snippet does not permit using arbitrary non-NULL pointers or impose
string-termination semantics on a byte copy.

```c
if ((copy_size_bytes > destination_capacity_bytes) ||
    (copy_size_bytes > source_size_bytes))
{
        ret = -ERANGE;
        goto function_output;
}

if (copy_size_bytes != 0u)
        memmove(destination, source, copy_size_bytes);
```

---

<a id="cban-057-example"></a>

### CBAN-057: `memmove` with unvalidated size

**Action:** ban-pattern. [Canonical entry][cban-057].

validated range-move wrapper

Body fragment after validating live source/destination objects and their extents. `memmove` supports
permitted overlap. This snippet does not permit using arbitrary non-NULL pointers or impose
string-termination semantics on a byte copy.

```c
if ((copy_size_bytes > destination_capacity_bytes) ||
    (copy_size_bytes > source_size_bytes))
{
        ret = -ERANGE;
        goto function_output;
}

if (copy_size_bytes != 0u)
        memmove(destination, source, copy_size_bytes);
```

---

<a id="cban-058-example"></a>

### CBAN-058: `memset` for secret clearing

**Action:** ban-pattern. [Canonical entry][cban-058].

Use a qualified explicit-erasure primitive; account for copies and compiler/runtime behavior.

A qualified security primitive must prevent removal of the erase on the named toolchain and cover
relevant copies. The injected call documents the boundary; this declaration is not a constant-time
or erase implementation.

```c
ret = erase_secret(security_context, secret, secret_size_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-059-example"></a>

### CBAN-059: `bzero`

**Action:** review. [Canonical entry][cban-059].

project zeroing or secure-zero wrapper

Ordinary byte initialization after validating the writable extent, not secret erasure and not
semantic initialization of arbitrary pointer/floating objects. Use semantic aggregate initialization
for such objects.

```c
if (size_bytes != 0u)
        memset(byte_buffer, 0, size_bytes);
```

---

<a id="cban-060-example"></a>

### CBAN-060: `memcmp` for secret comparison

**Action:** ban-pattern. [Canonical entry][cban-060].

Use a reviewed constant-time primitive for the stated equal-length secret contract.

Equal-length secret buffers and their extents are validated before the call. The security adapter
owns the constant-time contract; ordinary memcmp or a guessed loop is not substituted for that
evidence.

```c
ret = equal_secret(security_context, left, right, size_bytes, &is_equal);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-061-example"></a>

### CBAN-061: `memcmp` on structs

**Action:** ban-pattern. [Canonical entry][cban-061].

field-by-field comparison

Both validated records have value semantics for these fields. Compare every meaningful field
explicitly; do not compare struct padding, locks, pointer ownership or resource identity as raw
bytes.

```c
is_equal =
        (left->object_id == right->object_id) && (left->state == right->state);
```

---

<a id="cban-062-example"></a>

### CBAN-062: `bcopy`

**Action:** ban. [Canonical entry][cban-062].

validated range-copy or range-move wrapper

Body fragment after validating live source/destination objects and their extents. `memmove` supports
permitted overlap. This snippet does not permit using arbitrary non-NULL pointers or impose
string-termination semantics on a byte copy.

```c
if ((copy_size_bytes > destination_capacity_bytes) ||
    (copy_size_bytes > source_size_bytes))
{
        ret = -ERANGE;
        goto function_output;
}

if (copy_size_bytes != 0u)
        memmove(destination, source, copy_size_bytes);
```

---

<a id="cban-063-example"></a>

### CBAN-063: `bcmp`

**Action:** ban. [Canonical entry][cban-063].

field or byte comparison wrapper as appropriate

Non-secret byte comparison with validated extents. ret and all variables are declared at function
entry. Early loop termination is expressed in the condition. This is deliberately not a
constant-time secret comparison.

```c
is_equal = true;
for (index = 0u; (index < size_bytes) && is_equal; index++)
{
        is_equal = (left[index] == right[index]);
}
```

---

<a id="cban-064-example"></a>

### CBAN-064: `alloca`

**Action:** ban. [Canonical entry][cban-064].

bounded automatic storage or project allocation policy

scratch belongs at function entry and the selected profile must budget its 256 bytes. The number is
an illustrative fixed capacity, not a universal stack allowance. Variable alloca/VLA storage is not
introduced.

```c
unsigned char scratch[256] = { 0 };

if (requested_bytes > sizeof(scratch))
{
        ret = -ENOSPC;
        goto function_output;
}
```

---

<a id="cban-065-example"></a>

### CBAN-065: `_alloca`

**Action:** ban. [Canonical entry][cban-065].

bounded automatic storage or project allocation policy

scratch belongs at function entry and the selected profile must budget its 256 bytes. The number is
an illustrative fixed capacity, not a universal stack allowance. Variable alloca/VLA storage is not
introduced.

```c
unsigned char scratch[256] = { 0 };

if (requested_bytes > sizeof(scratch))
{
        ret = -ENOSPC;
        goto function_output;
}
```

---

<a id="cban-066-example"></a>

### CBAN-066: `malloc` in critical path

**Action:** review. [Canonical entry][cban-066].

preallocated storage, pool, arena, or explicit failure policy

Explicit bounded pool port: initialization precedes the critical phase, exhaustion is defined, and
worst-case latency/stack evidence is target-specific. The callback name does not prove that its
implementation avoids heap allocation.

```c
ret = acquire_slot(pool_context, &slot);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-067-example"></a>

### CBAN-067: `calloc` in critical path

**Action:** review. [Canonical entry][cban-067].

preallocated storage, pool, arena, or explicit failure policy

Explicit bounded pool port: initialization precedes the critical phase, exhaustion is defined, and
worst-case latency/stack evidence is target-specific. The callback name does not prove that its
implementation avoids heap allocation.

```c
ret = acquire_slot(pool_context, &slot);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-068-example"></a>

### CBAN-068: `realloc`

**Action:** review. [Canonical entry][cban-068].

Handle zero explicitly; positive-size failure preserves the owner; invalidate aliases on success.

Owned-allocation fragment. Validate size and allocator family first; declarations are at function
entry. The resize contract preserves the old allocation on positive-size failure. On success all old
aliases are invalid. The API explicitly chooses release-on-zero rather than calling native `realloc`
with zero.

```c
if (new_size_bytes == 0u)
{
        release_owned(memory_context, allocation);
        allocation = (unsigned char *)(NULL);
        goto function_output;
}

replacement = (unsigned char *)resize_owned(memory_context, allocation,
                                            new_size_bytes);
if (replacement == (unsigned char *)(NULL))
{
        ret = -ENOMEM;
        goto function_output;
}

allocation = replacement;
```

---

<a id="cban-069-example"></a>

### CBAN-069: `free` outside owner API

**Action:** ban-pattern. [Canonical entry][cban-069].

project ownership/release API

Only the allocator/owner whose release contract owns this base pointer may release it. Nulling this
variable does not clear aliases or solve concurrent reclamation.

```c
release_owned(memory_context, allocation);
allocation = (unsigned char *)(NULL);
```

---

<a id="cban-070-example"></a>

### CBAN-070: `system`

**Action:** ban. [Canonical entry][cban-070].

fixed argument-vector process wrapper

Approved process adapter maps an authorized executable identity to its actual path and constructs
platform arguments without a shell. Windows quoting, controlled environment and handle inheritance
need their own implementation contract. Validation includes who may invoke this operation.

```c
ret = spawn_process(process_context, executable_id, arguments, argument_count,
                    environment_id, &process_handle);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-071-example"></a>

### CBAN-071: `popen`

**Action:** review. [Canonical entry][cban-071].

fixed argument-vector process wrapper

Approved process adapter maps an authorized executable identity to its actual path and constructs
platform arguments without a shell. Windows quoting, controlled environment and handle inheritance
need their own implementation contract. Validation includes who may invoke this operation.

```c
ret = spawn_process(process_context, executable_id, arguments, argument_count,
                    environment_id, &process_handle);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-072-example"></a>

### CBAN-072: `execlp`

**Action:** review. [Canonical entry][cban-072].

absolute-path execution wrapper with controlled environment

Approved process adapter maps an authorized executable identity to its actual path and constructs
platform arguments without a shell. Windows quoting, controlled environment and handle inheritance
need their own implementation contract. Validation includes who may invoke this operation.

```c
ret = spawn_process(process_context, executable_id, arguments, argument_count,
                    environment_id, &process_handle);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-073-example"></a>

### CBAN-073: `execvp`

**Action:** review. [Canonical entry][cban-073].

absolute-path execution wrapper with controlled environment

Approved process adapter maps an authorized executable identity to its actual path and constructs
platform arguments without a shell. Windows quoting, controlled environment and handle inheritance
need their own implementation contract. Validation includes who may invoke this operation.

```c
ret = spawn_process(process_context, executable_id, arguments, argument_count,
                    environment_id, &process_handle);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-074-example"></a>

### CBAN-074: `CreateProcess` with command-line string assembly

**Action:** review. [Canonical entry][cban-074].

Use documented Windows argument quoting, executable identity, environment, and handle inheritance
rules.

Approved process adapter maps an authorized executable identity to its actual path and constructs
platform arguments without a shell. Windows quoting, controlled environment and handle inheritance
need their own implementation contract. Validation includes who may invoke this operation.

```c
ret = spawn_process(process_context, executable_id, arguments, argument_count,
                    environment_id, &process_handle);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-075-example"></a>

### CBAN-075: `dlopen` on untrusted path

**Action:** ban-pattern. [Canonical entry][cban-075].

Authorize the actual loaded object, path, ABI, provenance, and lifetime through the loader owner.

Loader owner verifies the actual artifact, search-path policy, authenticity where required, ABI and
lifetime. An authorized pathname string alone does not close path-replacement races or make loaded
native code isolated.

```c
ret = load_authorized(loader_context, artifact_id, expected_abi,
                      &module_handle);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-076-example"></a>

### CBAN-076: `LoadLibrary` on untrusted path

**Action:** ban-pattern. [Canonical entry][cban-076].

Authorize the actual loaded object, path, ABI, provenance, and lifetime through the loader owner.

Loader owner verifies the actual artifact, search-path policy, authenticity where required, ABI and
lifetime. An authorized pathname string alone does not close path-replacement races or make loaded
native code isolated.

```c
ret = load_authorized(loader_context, artifact_id, expected_abi,
                      &module_handle);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-077-example"></a>

### CBAN-077: `tmpnam`

**Action:** ban. [Canonical entry][cban-077].

secure temporary-file wrapper

Adapter creates and opens the object atomically with restrictive permissions and explicit
cleanup/inheritance policy. Returning a supposedly unique name before opening is not sufficient.

```c
ret = create_temporary(file_context, approved_directory_id, &owned_file_handle);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-078-example"></a>

### CBAN-078: `tempnam`

**Action:** ban. [Canonical entry][cban-078].

secure temporary-file wrapper

Adapter creates and opens the object atomically with restrictive permissions and explicit
cleanup/inheritance policy. Returning a supposedly unique name before opening is not sufficient.

```c
ret = create_temporary(file_context, approved_directory_id, &owned_file_handle);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-079-example"></a>

### CBAN-079: `mktemp`

**Action:** ban. [Canonical entry][cban-079].

secure temporary-file wrapper

Adapter creates and opens the object atomically with restrictive permissions and explicit
cleanup/inheritance policy. Returning a supposedly unique name before opening is not sufficient.

```c
ret = create_temporary(file_context, approved_directory_id, &owned_file_handle);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-080-example"></a>

### CBAN-080: `_mktemp`

**Action:** ban. [Canonical entry][cban-080].

secure temporary-file wrapper

Adapter creates and opens the object atomically with restrictive permissions and explicit
cleanup/inheritance policy. Returning a supposedly unique name before opening is not sufficient.

```c
ret = create_temporary(file_context, approved_directory_id, &owned_file_handle);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-081-example"></a>

### CBAN-081: `fopen` with external path

**Action:** review. [Canonical entry][cban-081].

project path wrapper with root and mode policy

File adapter validates the object opened using the platform root/descriptor and
link-resolution policy. Do not authorize with access/stat/realpath and assume a later pathname use
refers to the same object. Permission/ownership changes need the operation-specific authorization.

```c
ret = open_authorized(file_context, root_handle, relative_path,
                      operation_policy, &owned_file_handle);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-082-example"></a>

### CBAN-082: `open` with external path

**Action:** review. [Canonical entry][cban-082].

project path wrapper with descriptor-based workflow

File adapter validates the object opened using the platform root/descriptor and
link-resolution policy. Do not authorize with access/stat/realpath and assume a later pathname use
refers to the same object. Permission/ownership changes need the operation-specific authorization.

```c
ret = open_authorized(file_context, root_handle, relative_path,
                      operation_policy, &owned_file_handle);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-083-example"></a>

### CBAN-083: `access` before use

**Action:** review. [Canonical entry][cban-083].

attempt operation directly and handle failure

File adapter validates the object opened using the platform root/descriptor and
link-resolution policy. Do not authorize with access/stat/realpath and assume a later pathname use
refers to the same object. Permission/ownership changes need the operation-specific authorization.

```c
ret = open_authorized(file_context, root_handle, relative_path,
                      operation_policy, &owned_file_handle);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-084-example"></a>

### CBAN-084: `stat` before use

**Action:** review. [Canonical entry][cban-084].

descriptor-based validation workflow

File adapter validates the object opened using the platform root/descriptor and
link-resolution policy. Do not authorize with access/stat/realpath and assume a later pathname use
refers to the same object. Permission/ownership changes need the operation-specific authorization.

```c
ret = open_authorized(file_context, root_handle, relative_path,
                      operation_policy, &owned_file_handle);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-085-example"></a>

### CBAN-085: `chmod` with external path

**Action:** review. [Canonical entry][cban-085].

project permission wrapper with allowlist

File adapter validates the object opened using the platform root/descriptor and
link-resolution policy. Do not authorize with access/stat/realpath and assume a later pathname use
refers to the same object. Permission/ownership changes need the operation-specific authorization.

```c
ret = open_authorized(file_context, root_handle, relative_path,
                      operation_policy, &owned_file_handle);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-086-example"></a>

### CBAN-086: `chown` with external path

**Action:** review. [Canonical entry][cban-086].

project ownership wrapper with allowlist

File adapter validates the object opened using the platform root/descriptor and
link-resolution policy. Do not authorize with access/stat/realpath and assume a later pathname use
refers to the same object. Permission/ownership changes need the operation-specific authorization.

```c
ret = open_authorized(file_context, root_handle, relative_path,
                      operation_policy, &owned_file_handle);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-087-example"></a>

### CBAN-087: `recv` unchecked result

**Action:** ban-pattern. [Canonical entry][cban-087].

checked I/O wrapper

I/O port specifies read versus write, partial completion, interruption, EOF, zero progress and
bounded retry. Preserve completed progress on errors where the contract permits it; never assume
`requested_bytes` were transferred.

```c
ret = transfer(io_context, buffer, requested_bytes, &completed_bytes);
if (completed_bytes > requested_bytes)
{
        ret = -EIO;
        goto function_output;
}

if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-088-example"></a>

### CBAN-088: `read` unchecked result

**Action:** ban-pattern. [Canonical entry][cban-088].

checked I/O wrapper

I/O port specifies read versus write, partial completion, interruption, EOF, zero progress and
bounded retry. Preserve completed progress on errors where the contract permits it; never assume
`requested_bytes` were transferred.

```c
ret = transfer(io_context, buffer, requested_bytes, &completed_bytes);
if (completed_bytes > requested_bytes)
{
        ret = -EIO;
        goto function_output;
}

if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-089-example"></a>

### CBAN-089: `write` unchecked result

**Action:** ban-pattern. [Canonical entry][cban-089].

checked write wrapper

I/O port specifies read versus write, partial completion, interruption, EOF, zero progress and
bounded retry. Preserve completed progress on errors where the contract permits it; never assume
`requested_bytes` were transferred.

```c
ret = transfer(io_context, buffer, requested_bytes, &completed_bytes);
if (completed_bytes > requested_bytes)
{
        ret = -EIO;
        goto function_output;
}

if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-090-example"></a>

### CBAN-090: `fread` unchecked result

**Action:** ban-pattern. [Canonical entry][cban-090].

checked read wrapper

I/O port specifies read versus write, partial completion, interruption, EOF, zero progress and
bounded retry. Preserve completed progress on errors where the contract permits it; never assume
`requested_bytes` were transferred.

```c
ret = transfer(io_context, buffer, requested_bytes, &completed_bytes);
if (completed_bytes > requested_bytes)
{
        ret = -EIO;
        goto function_output;
}

if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-091-example"></a>

### CBAN-091: `fwrite` unchecked result

**Action:** ban-pattern. [Canonical entry][cban-091].

checked write wrapper

I/O port specifies read versus write, partial completion, interruption, EOF, zero progress and
bounded retry. Preserve completed progress on errors where the contract permits it; never assume
`requested_bytes` were transferred.

```c
ret = transfer(io_context, buffer, requested_bytes, &completed_bytes);
if (completed_bytes > requested_bytes)
{
        ret = -EIO;
        goto function_output;
}

if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-092-example"></a>

### CBAN-092: `rand` for security

**Action:** ban-pattern. [Canonical entry][cban-092].

project cryptographic-random wrapper

Qualified cryptographic-random provider, including startup, entropy readiness and failure policy. No
predictable time seed or ordinary PRNG fallback is allowed for security output.

```c
ret = random_bytes(random_context, destination, size_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-093-example"></a>

### CBAN-093: `srand` for security

**Action:** ban-pattern. [Canonical entry][cban-093].

project cryptographic-random wrapper

Qualified cryptographic-random provider, including startup, entropy readiness and failure policy. No
predictable time seed or ordinary PRNG fallback is allowed for security output.

```c
ret = random_bytes(random_context, destination, size_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-094-example"></a>

### CBAN-094: `random` for security

**Action:** ban-pattern. [Canonical entry][cban-094].

project cryptographic-random wrapper

Qualified cryptographic-random provider, including startup, entropy readiness and failure policy. No
predictable time seed or ordinary PRNG fallback is allowed for security output.

```c
ret = random_bytes(random_context, destination, size_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-095-example"></a>

### CBAN-095: `drand48` family for security

**Action:** ban-pattern. [Canonical entry][cban-095].

project cryptographic-random wrapper

Qualified cryptographic-random provider, including startup, entropy readiness and failure policy. No
predictable time seed or ordinary PRNG fallback is allowed for security output.

```c
ret = random_bytes(random_context, destination, size_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-096-example"></a>

### CBAN-096: `time` as randomness seed

**Action:** ban-pattern. [Canonical entry][cban-096].

project cryptographic-random wrapper

Qualified cryptographic-random provider, including startup, entropy readiness and failure policy. No
predictable time seed or ordinary PRNG fallback is allowed for security output.

```c
ret = random_bytes(random_context, destination, size_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-097-example"></a>

### CBAN-097: `getenv` in privileged or security-sensitive code

**Action:** review. [Canonical entry][cban-097].

validated configuration wrapper

Composition owns environment, working directory and process-wide defaults. Ordinary libraries
consume validated explicit configuration instead of changing global process state. File-creation
permissions belong in the file adapter.

```c
ret = read_configuration(config_context, setting_id, &setting);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-098-example"></a>

### CBAN-098: `putenv`

**Action:** review. [Canonical entry][cban-098].

project environment wrapper

Composition owns environment, working directory and process-wide defaults. Ordinary libraries
consume validated explicit configuration instead of changing global process state. File-creation
permissions belong in the file adapter.

```c
ret = read_configuration(config_context, setting_id, &setting);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-099-example"></a>

### CBAN-099: `setenv` in library code

**Action:** review. [Canonical entry][cban-099].

project environment wrapper

Composition owns environment, working directory and process-wide defaults. Ordinary libraries
consume validated explicit configuration instead of changing global process state. File-creation
permissions belong in the file adapter.

```c
ret = read_configuration(config_context, setting_id, &setting);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-100-example"></a>

### CBAN-100: `unsetenv` in library code

**Action:** review. [Canonical entry][cban-100].

project environment wrapper

Composition owns environment, working directory and process-wide defaults. Ordinary libraries
consume validated explicit configuration instead of changing global process state. File-creation
permissions belong in the file adapter.

```c
ret = read_configuration(config_context, setting_id, &setting);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-101-example"></a>

### CBAN-101: `chdir` in library code

**Action:** review. [Canonical entry][cban-101].

absolute-path workflow

Composition owns environment, working directory and process-wide defaults. Ordinary libraries
consume validated explicit configuration instead of changing global process state. File-creation
permissions belong in the file adapter.

```c
ret = read_configuration(config_context, setting_id, &setting);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-102-example"></a>

### CBAN-102: `umask` in library code

**Action:** review. [Canonical entry][cban-102].

project file-creation wrapper

Composition owns environment, working directory and process-wide defaults. Ordinary libraries
consume validated explicit configuration instead of changing global process state. File-creation
permissions belong in the file adapter.

```c
ret = read_configuration(config_context, setting_id, &setting);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-103-example"></a>

### CBAN-103: `signal`

**Action:** review. [Canonical entry][cban-103].

project signal wrapper using defined handler policy

Platform adapter owns handler registration and its restricted execution contract. Handler bodies use
only permitted signal-safe operations; this registration snippet is not a handler.

```c
ret = install_signal_policy(signal_context, policy_id);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-104-example"></a>

### CBAN-104: `longjmp` across unsafe context

**Action:** review. [Canonical entry][cban-104].

structured error propagation

Normal module failure returns through its cleanup path. A platform-approved fatal policy must be
explicit and confined to its stated scope; nonlocal jumps do not bypass resource cleanup.

```c
if (operation_failed)
{
        ret = -EIO;
        goto function_output;
}
```

---

<a id="cban-105-example"></a>

### CBAN-105: `fork` in multithreaded code

**Action:** review. [Canonical entry][cban-105].

project process-spawn wrapper

Approved process adapter maps an authorized executable identity to its actual path and constructs
platform arguments without a shell. Windows quoting, controlled environment and handle inheritance
need their own implementation contract. Validation includes who may invoke this operation. The
process owner handles multithreaded fork restrictions and the child path before exec.

```c
ret = spawn_process(process_context, executable_id, arguments, argument_count,
                    environment_id, &process_handle);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-106-example"></a>

### CBAN-106: `pthread_cancel`

**Action:** review. [Canonical entry][cban-106].

cooperative cancellation

Cooperative stop at an invariant-preserving point; `function_output` releases only acquired
resources. This must not abandon locks, transferred objects or a partially committed transaction.

```c
ret = stop_requested(control_context, &is_stopping);
if (ret != EXIT_SUCCESS)
        goto function_output;
if (is_stopping)
        goto function_output;
```

---

<a id="cban-107-example"></a>

### CBAN-107: `crypt`

**Action:** ban (new security code). [Canonical entry][cban-107].

approved password-hashing wrapper

Qualified password-hashing adapter owns algorithm, salt, cost parameters, encoding and migration
policy. A legacy crypt alias is not approved merely because it sits behind this port.

```c
ret = hash_password(security_context, password, password_size_bytes, policy_id,
                    output, output_capacity_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-108-example"></a>

### CBAN-108: `MD5` APIs for security

**Action:** ban-pattern. [Canonical entry][cban-108].

approved cryptographic digest wrapper

Security policy chooses the digest for the actual use case; non-security checksums have a different
contract. The adapter verifies output capacity and reports failure explicitly.

```c
ret = digest_message(security_context, approved_algorithm_id, input,
                     input_size_bytes, digest, digest_capacity_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-109-example"></a>

### CBAN-109: `SHA1` APIs for signatures or integrity security

**Action:** ban-pattern. [Canonical entry][cban-109].

approved cryptographic digest wrapper

Security policy chooses the digest for the actual use case; non-security checksums have a different
contract. The adapter verifies output capacity and reports failure explicitly.

```c
ret = digest_message(security_context, approved_algorithm_id, input,
                     input_size_bytes, digest, digest_capacity_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-110-example"></a>

### CBAN-110: `DES` APIs

**Action:** ban (new security code). [Canonical entry][cban-110].

approved cipher wrapper

Approved authenticated-encryption adapter owns nonce uniqueness, key lifecycle, tag handling and
output sizes. This call is not a cryptographic implementation or permission to reuse a nonce.

```c
ret = seal_message(security_context, key_id, nonce, plaintext,
                   plaintext_size_bytes, associated_data,
                   associated_data_size_bytes, output, output_capacity_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-111-example"></a>

### CBAN-111: `3DES` APIs

**Action:** ban (new security code). [Canonical entry][cban-111].

approved cipher wrapper

Approved authenticated-encryption adapter owns nonce uniqueness, key lifecycle, tag handling and
output sizes. This call is not a cryptographic implementation or permission to reuse a nonce.

```c
ret = seal_message(security_context, key_id, nonce, plaintext,
                   plaintext_size_bytes, associated_data,
                   associated_data_size_bytes, output, output_capacity_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-112-example"></a>

### CBAN-112: Unauthenticated ECB encryption for application data

**Action:** ban. [Canonical entry][cban-112].

Use an approved authenticated-encryption construction and its complete nonce/key protocol.

Approved authenticated-encryption adapter owns nonce uniqueness, key lifecycle, tag handling and
output sizes. This call is not a cryptographic implementation or permission to reuse a nonce.

```c
ret = seal_message(security_context, key_id, nonce, plaintext,
                   plaintext_size_bytes, associated_data,
                   associated_data_size_bytes, output, output_capacity_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-113-example"></a>

### CBAN-113: `isalpha` outside EOF/unsigned-char domain

**Action:** ban-pattern. [Canonical entry][cban-113].

Preserve EOF; convert a byte through unsigned char before promotion.

`input_character` is an int from a byte-input API, preserving EOF; result is declared at function
entry. Include <ctype.h> and <stdio.h>. A separate encoding/locale policy determines the intended
classification or conversion.

```c
if (input_character != EOF)
        result = isalpha((unsigned char)input_character);
```

---

<a id="cban-114-example"></a>

### CBAN-114: `isdigit` outside EOF/unsigned-char domain

**Action:** ban-pattern. [Canonical entry][cban-114].

Preserve EOF; convert a byte through unsigned char before promotion.

`input_character` is an int from a byte-input API, preserving EOF; result is declared at function
entry. Include <ctype.h> and <stdio.h>. A separate encoding/locale policy determines the intended
classification or conversion.

```c
if (input_character != EOF)
        result = isdigit((unsigned char)input_character);
```

---

<a id="cban-115-example"></a>

### CBAN-115: `tolower` outside EOF/unsigned-char domain

**Action:** ban-pattern. [Canonical entry][cban-115].

Preserve EOF; convert a byte through unsigned char before promotion.

`input_character` is an int from a byte-input API, preserving EOF; result is declared at function
entry. Include <ctype.h> and <stdio.h>. A separate encoding/locale policy determines the intended
classification or conversion.

```c
if (input_character != EOF)
        result = tolower((unsigned char)input_character);
```

---

<a id="cban-116-example"></a>

### CBAN-116: `toupper` outside EOF/unsigned-char domain

**Action:** ban-pattern. [Canonical entry][cban-116].

Preserve EOF; convert a byte through unsigned char before promotion.

`input_character` is an int from a byte-input API, preserving EOF; result is declared at function
entry. Include <ctype.h> and <stdio.h>. A separate encoding/locale policy determines the intended
classification or conversion.

```c
if (input_character != EOF)
        result = toupper((unsigned char)input_character);
```

---

<a id="cban-117-example"></a>

### CBAN-117: Overflow-prone subtraction comparator for `qsort`

**Action:** ban-pattern. [Canonical entry][cban-117].

Compare relationally and return negative/zero/positive without overflowing subtraction.

Comparator-body fragment after accessing valid values. ret is the comparator result under its
required domain contract; the final `function_output` returns ret. Relational comparison avoids
overflow from subtracting the two values.

```c
if (left_value < right_value)
        ret = -1;
else if (left_value > right_value)
{
        ret = 1;
}
else
        ret = 0;
goto function_output;
```

---

<a id="cban-118-example"></a>

### CBAN-118: `assert` for external input validation

**Action:** ban-pattern. [Canonical entry][cban-118].

runtime validation with explicit error path

Runtime validation of externally influenced length. Assertions may still check internal invariants
but cannot replace this rejection in release builds.

```c
if (length_bytes > capacity_bytes)
{
        ret = -ERANGE;
        goto function_output;
}
```

---

<a id="cban-119-example"></a>

### CBAN-119: `abort` in library code

**Action:** review. [Canonical entry][cban-119].

error propagation or configured fatal policy

Normal module failure returns through its cleanup path. A platform-approved fatal policy must be
explicit and confined to its stated scope; nonlocal jumps do not bypass resource cleanup.

```c
if (operation_failed)
{
        ret = -EIO;
        goto function_output;
}
```

---

<a id="cban-120-example"></a>

### CBAN-120: `exit` in library code

**Action:** review. [Canonical entry][cban-120].

error propagation or configured fatal policy

Normal module failure returns through its cleanup path. A platform-approved fatal policy must be
explicit and confined to its stated scope; nonlocal jumps do not bypass resource cleanup.

```c
if (operation_failed)
{
        ret = -EIO;
        goto function_output;
}
```

---

<a id="cban-121-example"></a>

### CBAN-121: `perror` in library code

**Action:** review. [Canonical entry][cban-121].

project logging/error API

Explicit error-description port with bounded caller storage and thread/locale policy. Report through
the configured diagnostic owner; do not silently print to standard streams.

```c
ret = describe_error(error_context, error_code, buffer, buffer_capacity_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-122-example"></a>

### CBAN-122: `strerror`

**Action:** review. [Canonical entry][cban-122].

project error-string wrapper

Explicit error-description port with bounded caller storage and thread/locale policy. Report through
the configured diagnostic owner; do not silently print to standard streams.

```c
ret = describe_error(error_context, error_code, buffer, buffer_capacity_bytes);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-123-example"></a>

### CBAN-123: `asctime`

**Action:** ban. [Canonical entry][cban-123].

project time-format wrapper

Time adapter owns timezone, locale, range and thread-safe storage. It does not expose native shared
static result buffers; durations use a separate monotonic domain.

```c
ret = format_time(time_context, timestamp, time_policy_id, buffer,
                  buffer_capacity_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-124-example"></a>

### CBAN-124: `ctime`

**Action:** ban. [Canonical entry][cban-124].

project time-format wrapper

Time adapter owns timezone, locale, range and thread-safe storage. It does not expose native shared
static result buffers; durations use a separate monotonic domain.

```c
ret = format_time(time_context, timestamp, time_policy_id, buffer,
                  buffer_capacity_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-125-example"></a>

### CBAN-125: `localtime`

**Action:** review. [Canonical entry][cban-125].

project time wrapper

Time adapter owns timezone, locale, range and thread-safe storage. It does not expose native shared
static result buffers; durations use a separate monotonic domain.

```c
ret = format_time(time_context, timestamp, time_policy_id, buffer,
                  buffer_capacity_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-126-example"></a>

### CBAN-126: `gmtime`

**Action:** review. [Canonical entry][cban-126].

project time wrapper

Time adapter owns timezone, locale, range and thread-safe storage. It does not expose native shared
static result buffers; durations use a separate monotonic domain.

```c
ret = format_time(time_context, timestamp, time_policy_id, buffer,
                  buffer_capacity_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-127-example"></a>

### CBAN-127: `realpath` with unchecked external path

**Action:** review. [Canonical entry][cban-127].

Validate the object opened; canonicalization alone does not prevent link/check-use races.

File adapter validates the object opened using the platform root/descriptor and
link-resolution policy. Do not authorize with access/stat/realpath and assume a later pathname use
refers to the same object. Permission/ownership changes need the operation-specific authorization.

```c
ret = open_authorized(file_context, root_handle, relative_path,
                      operation_policy, &owned_file_handle);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-128-example"></a>

### CBAN-128: `IsBadReadPtr`

**Action:** ban. [Canonical entry][cban-128].

ownership, bounds, and API contract validation

The base object must already have a proven live lifetime, extent and access permission under its
owner contract. Range checks do not validate arbitrary pointers; probing readability/writability is
not an ownership proof.

```c
if (offset_bytes > capacity_bytes)
{
        ret = -ERANGE;
        goto function_output;
}

if (length_bytes > (capacity_bytes - offset_bytes))
{
        ret = -ERANGE;
        goto function_output;
}
```

---

<a id="cban-129-example"></a>

### CBAN-129: `IsBadWritePtr`

**Action:** ban. [Canonical entry][cban-129].

ownership, bounds, and API contract validation

The base object must already have a proven live lifetime, extent and access permission under its
owner contract. Range checks do not validate arbitrary pointers; probing readability/writability is
not an ownership proof.

```c
if (offset_bytes > capacity_bytes)
{
        ret = -ERANGE;
        goto function_output;
}

if (length_bytes > (capacity_bytes - offset_bytes))
{
        ret = -ERANGE;
        goto function_output;
}
```

---

<a id="cban-130-example"></a>

### CBAN-130: `_splitpath`

**Action:** review. [Canonical entry][cban-130].

project path wrapper with explicit capacities

Bounded path construction/parsing with explicit capacities and encoding. Constructing a path does
not authorize opening it; the actual-object access policy remains separate.

```c
ret = build_path(path_context, path_components, component_count, output,
                 output_capacity_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-131-example"></a>

### CBAN-131: `_makepath`

**Action:** review. [Canonical entry][cban-131].

project path wrapper with explicit capacities

Bounded path construction/parsing with explicit capacities and encoding. Constructing a path does
not authorize opening it; the actual-object access policy remains separate.

```c
ret = build_path(path_context, path_components, component_count, output,
                 output_capacity_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-132-example"></a>

### CBAN-132: `_fullpath`

**Action:** review. [Canonical entry][cban-132].

project path wrapper with explicit capacities

Bounded path construction/parsing with explicit capacities and encoding. Constructing a path does
not authorize opening it; the actual-object access policy remains separate.

```c
ret = build_path(path_context, path_components, component_count, output,
                 output_capacity_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-133-example"></a>

### CBAN-133: `gets`-like custom project wrapper

**Action:** ban. [Canonical entry][cban-133].

bounded line-input wrapper

Injected bounded-input port: `capacity_chars` includes any required terminator. Its contract
distinguishes EOF, truncation and I/O failure, uses the selected character/encoding domain, and
never writes past capacity. Declarations and required callback validation precede this body
fragment.

```c
ret = read_line(input_context, buffer, capacity_chars, &length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-134-example"></a>

### CBAN-134: `strcpy`-like custom project wrapper

**Action:** ban. [Canonical entry][cban-134].

bounded copy wrapper with capacity and status

Injected copy port: the actual signature uses the selected char, `wchar_t` or platform character
type. Capacity units and termination/truncation semantics are explicit; validate the readable source
extent. A renamed unbounded strcpy is not an acceptable implementation.

```c
ret = copy_text(copy_context, destination, destination_capacity_chars, source,
                source_length_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-135-example"></a>

### CBAN-135: `sprintf`-like custom project wrapper

**Action:** ban. [Canonical entry][cban-135].

bounded formatting wrapper with checked result

Injected bounded formatter: its implementation must check native formatting failure and truncation
and handle `va_list` copies when applicable. ISO swprintf and legacy platform swprintf signatures
must not be confused. Output units and termination are part of this port, not guessed from the
native API name.

```c
ret = format_value(format_context, destination, destination_capacity_chars,
                   value, &written_chars);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

<a id="cban-136-example"></a>

### CBAN-136: unchecked allocation result

**Action:** ban-pattern. [Canonical entry][cban-136].

checked allocation wrapper or explicit error path

`size_bytes` is a validated nonzero size under the allocator contract. allocation is declared as a
typed NULL at function entry; release through the same allocator family.

```c
allocation = (unsigned char *)allocate(memory_context, size_bytes);
if (allocation == (unsigned char *)(NULL))
{
        ret = -ENOMEM;
        goto function_output;
}
```

---

<a id="cban-137-example"></a>

### CBAN-137: unchecked multiplication before allocation

**Action:** ban-pattern. [Canonical entry][cban-137].

checked multiplication helper

Inside the approved checked-arithmetic implementation, with `size_t` operands and <stdint.h>.
Ordinary modules use the approved helper/port. The result still needs the API zero-size and
maximum-budget policy.

```c
if ((element_size_bytes != 0u) &&
    (element_count > (SIZE_MAX / element_size_bytes)))
{
        ret = -ERANGE;
        goto function_output;
}

allocation_bytes = element_count * element_size_bytes;
```

---

<a id="cban-138-example"></a>

### CBAN-138: unchecked addition before buffer operation

**Action:** ban-pattern. [Canonical entry][cban-138].

checked addition helper

Inside the checked-arithmetic owner. The capacity comparison follows the checked sum; arithmetic
correctness does not imply enough writable storage.

```c
if (append_bytes > (SIZE_MAX - used_bytes))
{
        ret = -ERANGE;
        goto function_output;
}

required_bytes = used_bytes + append_bytes;
```

---

<a id="cban-139-example"></a>

### CBAN-139: unchecked narrowing conversion before size use

**Action:** ban-pattern. [Canonical entry][cban-139].

checked conversion helper

`wide_count` is uint32_t; `narrow_count` is initialized to zero at function entry. Signed inputs
also require a negative-value check before unsigned conversion.

```c
if (wide_count > UINT16_MAX)
{
        ret = -ERANGE;
        goto function_output;
}

narrow_count = (uint16_t)wide_count;
```

---

<a id="cban-140-example"></a>

### CBAN-140: ignored return from security-sensitive API

**Action:** ban-pattern. [Canonical entry][cban-140].

check the return value and handle failure explicitly

The configured security port has an explicit deny/failure contract. Mutate protected state only
after success, under the same object/state consistency contract.

```c
ret = authorize(security_context, principal, operation, object_id);
if (ret != EXIT_SUCCESS)
        goto function_output;
```

---

## Links and references

The three guides share one policy and use stable rule identifiers for cross-references.

- [C Code Standard][c-code-standard]: implementation rules and API restrictions.
- [C Module Architecture][c-module-architecture]: ownership, composition, and builds.
- [Common C Pitfalls][c-common-pitfalls]: failure scenarios and verification designs.
- [Research and link record][c-common-pitfalls-research-record]: source scope and access evidence.

<!-- Document navigation -->

[appendix-a-canonical-cban-register]: #appendix-a-canonical-cban-register
[appendix-b-complete-local-contract-example]: #appendix-b-complete-local-contract-example
[appendix-c-maintained-reference-and-candidate]: #appendix-c-maintained-reference-and-candidate
[appendix-d-examples-for-every-cban-entry]: #appendix-d-examples-for-every-cban-entry
[cban-001]: #cban-001
[cban-002]: #cban-002
[cban-003]: #cban-003
[cban-004]: #cban-004
[cban-005]: #cban-005
[cban-006]: #cban-006
[cban-007]: #cban-007
[cban-008]: #cban-008
[cban-009]: #cban-009
[cban-010]: #cban-010
[cban-011]: #cban-011
[cban-012]: #cban-012
[cban-013]: #cban-013
[cban-014]: #cban-014
[cban-015]: #cban-015
[cban-016]: #cban-016
[cban-017]: #cban-017
[cban-018]: #cban-018
[cban-019]: #cban-019
[cban-020]: #cban-020
[cban-021]: #cban-021
[cban-022]: #cban-022
[cban-023]: #cban-023
[cban-024]: #cban-024
[cban-025]: #cban-025
[cban-026]: #cban-026
[cban-027]: #cban-027
[cban-028]: #cban-028
[cban-029]: #cban-029
[cban-030]: #cban-030
[cban-031]: #cban-031
[cban-032]: #cban-032
[cban-033]: #cban-033
[cban-034]: #cban-034
[cban-035]: #cban-035
[cban-036]: #cban-036
[cban-037]: #cban-037
[cban-038]: #cban-038
[cban-039]: #cban-039
[cban-040]: #cban-040
[cban-041]: #cban-041
[cban-042]: #cban-042
[cban-043]: #cban-043
[cban-044]: #cban-044
[cban-045]: #cban-045
[cban-046]: #cban-046
[cban-047]: #cban-047
[cban-048]: #cban-048
[cban-049]: #cban-049
[cban-050]: #cban-050
[cban-051]: #cban-051
[cban-052]: #cban-052
[cban-053]: #cban-053
[cban-054]: #cban-054
[cban-055]: #cban-055
[cban-056]: #cban-056
[cban-057]: #cban-057
[cban-058]: #cban-058
[cban-059]: #cban-059
[cban-060]: #cban-060
[cban-061]: #cban-061
[cban-062]: #cban-062
[cban-063]: #cban-063
[cban-064]: #cban-064
[cban-065]: #cban-065
[cban-066]: #cban-066
[cban-067]: #cban-067
[cban-068]: #cban-068
[cban-069]: #cban-069
[cban-070]: #cban-070
[cban-071]: #cban-071
[cban-072]: #cban-072
[cban-073]: #cban-073
[cban-074]: #cban-074
[cban-075]: #cban-075
[cban-076]: #cban-076
[cban-077]: #cban-077
[cban-078]: #cban-078
[cban-079]: #cban-079
[cban-080]: #cban-080
[cban-081]: #cban-081
[cban-082]: #cban-082
[cban-083]: #cban-083
[cban-084]: #cban-084
[cban-085]: #cban-085
[cban-086]: #cban-086
[cban-087]: #cban-087
[cban-088]: #cban-088
[cban-089]: #cban-089
[cban-090]: #cban-090
[cban-091]: #cban-091
[cban-092]: #cban-092
[cban-093]: #cban-093
[cban-094]: #cban-094
[cban-095]: #cban-095
[cban-096]: #cban-096
[cban-097]: #cban-097
[cban-098]: #cban-098
[cban-099]: #cban-099
[cban-100]: #cban-100
[cban-101]: #cban-101
[cban-102]: #cban-102
[cban-103]: #cban-103
[cban-104]: #cban-104
[cban-105]: #cban-105
[cban-106]: #cban-106
[cban-107]: #cban-107
[cban-108]: #cban-108
[cban-109]: #cban-109
[cban-110]: #cban-110
[cban-111]: #cban-111
[cban-112]: #cban-112
[cban-113]: #cban-113
[cban-114]: #cban-114
[cban-115]: #cban-115
[cban-116]: #cban-116
[cban-117]: #cban-117
[cban-118]: #cban-118
[cban-119]: #cban-119
[cban-120]: #cban-120
[cban-121]: #cban-121
[cban-122]: #cban-122
[cban-123]: #cban-123
[cban-124]: #cban-124
[cban-125]: #cban-125
[cban-126]: #cban-126
[cban-127]: #cban-127
[cban-128]: #cban-128
[cban-129]: #cban-129
[cban-130]: #cban-130
[cban-131]: #cban-131
[cban-132]: #cban-132
[cban-133]: #cban-133
[cban-134]: #cban-134
[cban-135]: #cban-135
[cban-136]: #cban-136
[cban-137]: #cban-137
[cban-138]: #cban-138
[cban-139]: #cban-139
[cban-140]: #cban-140
[cperf-001]: #cperf-001
[cperf-002]: #cperf-002
[cperf-003]: #cperf-003
[cperf-004]: #cperf-004
[cperf-005]: #cperf-005
[cperf-006]: #cperf-006
[cperf-007]: #cperf-007
[cperf-008]: #cperf-008
[cperf-009]: #cperf-009
[cperf-010]: #cperf-010
[cperf-011]: #cperf-011
[cperf-012]: #cperf-012
[cperf-013]: #cperf-013
[cperf-014]: #cperf-014
[cperf-015]: #cperf-015
[cperf-016]: #cperf-016
[cperf-017]: #cperf-017
[cperf-018]: #cperf-018
[cperf-019]: #cperf-019
[cperf-020]: #cperf-020
[cperf-021]: #cperf-021
[cperf-022]: #cperf-022
[cperf-023]: #cperf-023
[cperf-024]: #cperf-024
[cperf-025]: #cperf-025
[cperf-026]: #cperf-026
[cperf-027]: #cperf-027
[cperf-028]: #cperf-028
[cperf-029]: #cperf-029
[cperf-030]: #cperf-030
[cperf-031]: #cperf-031
[cperf-032]: #cperf-032
[cperf-033]: #cperf-033
[cperf-034]: #cperf-034
[cperf-035]: #cperf-035
[cperf-036]: #cperf-036
[cperf-037]: #cperf-037
[cperf-038]: #cperf-038
[cperf-039]: #cperf-039
[cperf-040]: #cperf-040
[cperf-041]: #cperf-041
[cperf-042]: #cperf-042
[cperf-043]: #cperf-043
[cperf-044]: #cperf-044
[cperf-045]: #cperf-045
[cperf-046]: #cperf-046
[cperf-047]: #cperf-047
[cstyle-001]: #cstyle-001
[cstyle-002]: #cstyle-002
[cstyle-003]: #cstyle-003
[cstyle-004]: #cstyle-004
[cstyle-005]: #cstyle-005
[cstyle-006]: #cstyle-006
[cstyle-007]: #cstyle-007
[cstyle-008]: #cstyle-008
[cstyle-009]: #cstyle-009
[cstyle-010]: #cstyle-010
[cstyle-011]: #cstyle-011
[cstyle-012]: #cstyle-012
[cstyle-013]: #cstyle-013
[cstyle-014]: #cstyle-014
[cstyle-015]: #cstyle-015
[cstyle-016]: #cstyle-016
[cstyle-017]: #cstyle-017
[cstyle-018]: #cstyle-018
[cstyle-019]: #cstyle-019
[cstyle-020]: #cstyle-020
[cstyle-021]: #cstyle-021
[cstyle-022]: #cstyle-022
[cstyle-023]: #cstyle-023
[cstyle-024]: #cstyle-024
[cstyle-025]: #cstyle-025
[cstyle-026]: #cstyle-026
[cstyle-027]: #cstyle-027
[cstyle-028]: #cstyle-028
[cstyle-029]: #cstyle-029
[cstyle-030]: #cstyle-030
[cstyle-031]: #cstyle-031
[cstyle-032]: #cstyle-032
[cstyle-033]: #cstyle-033
[cstyle-034]: #cstyle-034
[cstyle-035]: #cstyle-035
[cstyle-036]: #cstyle-036
[cstyle-037]: #cstyle-037
[cstyle-038]: #cstyle-038
[cstyle-039]: #cstyle-039
[cstyle-040]: #cstyle-040
[cstyle-041]: #cstyle-041
[cstyle-042]: #cstyle-042
[cstyle-043]: #cstyle-043
[cstyle-044]: #cstyle-044
[cstyle-045]: #cstyle-045
[cstyle-046]: #cstyle-046
[cstyle-047]: #cstyle-047
[cstyle-048]: #cstyle-048
[cstyle-049]: #cstyle-049
[cstyle-050]: #cstyle-050
[cstyle-051]: #cstyle-051
[cstyle-052]: #cstyle-052
[cstyle-053]: #cstyle-053
[cstyle-054]: #cstyle-054
[cstyle-055]: #cstyle-055
[cstyle-056]: #cstyle-056
[cstyle-057]: #cstyle-057
[cstyle-058]: #cstyle-058
[cstyle-059]: #cstyle-059
[cstyle-060]: #cstyle-060
[cstyle-061]: #cstyle-061
[cstyle-062]: #cstyle-062
[cstyle-063]: #cstyle-063
[cstyle-064]: #cstyle-064
[cstyle-065]: #cstyle-065
[cstyle-066]: #cstyle-066
[cstyle-067]: #cstyle-067
[cstyle-068]: #cstyle-068
[cstyle-069]: #cstyle-069
[cstyle-070]: #cstyle-070
[cstyle-071]: #cstyle-071
[cstyle-072]: #cstyle-072
[cstyle-073]: #cstyle-073
[cstyle-074]: #cstyle-074
[cstyle-075]: #cstyle-075
[cstyle-076]: #cstyle-076
[cstyle-077]: #cstyle-077
[cstyle-078]: #cstyle-078
[cstyle-079]: #cstyle-079
[cstyle-080]: #cstyle-080
[cstyle-081]: #cstyle-081
[cstyle-082]: #cstyle-082
[cstyle-083]: #cstyle-083
[cstyle-084]: #cstyle-084
[cstyle-085]: #cstyle-085
[cstyle-086]: #cstyle-086
[cstyle-087]: #cstyle-087
[cstyle-088]: #cstyle-088
[cstyle-089]: #cstyle-089
[cstyle-090]: #cstyle-090
[cstyle-091]: #cstyle-091
[cstyle-092]: #cstyle-092
[cstyle-093]: #cstyle-093
[cstyle-094]: #cstyle-094
[cstyle-095]: #cstyle-095
[cstyle-096]: #cstyle-096
[cstyle-097]: #cstyle-097
[cstyle-098]: #cstyle-098
[cstyle-099]: #cstyle-099
[cstyle-100]: #cstyle-100
[cstyle-101]: #cstyle-101
[cstyle-102]: #cstyle-102
[cstyle-103]: #cstyle-103
[cstyle-104]: #cstyle-104
[cstyle-105]: #cstyle-105
[cstyle-106]: #cstyle-106
[cstyle-107]: #cstyle-107
[cstyle-108]: #cstyle-108
[cstyle-109]: #cstyle-109
[cstyle-110]: #cstyle-110
[cstyle-111]: #cstyle-111
[cstyle-112]: #cstyle-112
[cstyle-113]: #cstyle-113
[cstyle-114]: #cstyle-114
[cstyle-115]: #cstyle-115
[cstyle-116]: #cstyle-116
[cstyle-117]: #cstyle-117
[cstyle-118]: #cstyle-118
[cstyle-119]: #cstyle-119
[cstyle-120]: #cstyle-120
[cstyle-121]: #cstyle-121
[cstyle-122]: #cstyle-122
[cstyle-123]: #cstyle-123
[cstyle-124]: #cstyle-124
[cstyle-125]: #cstyle-125
[cstyle-126]: #cstyle-126
[cstyle-127]: #cstyle-127
[cstyle-128]: #cstyle-128
[cstyle-129]: #cstyle-129
[cstyle-130]: #cstyle-130
[cstyle-131]: #cstyle-131
[cstyle-132]: #cstyle-132
[cstyle-133]: #cstyle-133
[cstyle-134]: #cstyle-134
[cstyle-135]: #cstyle-135
[cstyle-136]: #cstyle-136
[cstyle-137]: #cstyle-137
[cstyle-138]: #cstyle-138
[cstyle-139]: #cstyle-139
[cstyle-140]: #cstyle-140
[cstyle-141]: #cstyle-141
[cstyle-142]: #cstyle-142
[cstyle-143]: #cstyle-143
[cstyle-144]: #cstyle-144
[cstyle-145]: #cstyle-145
[cstyle-146]: #cstyle-146
[cstyle-147]: #cstyle-147
[cstyle-148]: #cstyle-148
[cstyle-149]: #cstyle-149
[cstyle-150]: #cstyle-150
[cstyle-151]: #cstyle-151
[cstyle-152]: #cstyle-152
[cstyle-153]: #cstyle-153
[cstyle-154]: #cstyle-154
[cstyle-155]: #cstyle-155
[cstyle-156]: #cstyle-156
[cstyle-157]: #cstyle-157
[cstyle-158]: #cstyle-158
[cstyle-159]: #cstyle-159
[cstyle-160]: #cstyle-160
[cstyle-161]: #cstyle-161
[cstyle-162]: #cstyle-162
[cstyle-163]: #cstyle-163
[cstyle-164]: #cstyle-164
[cstyle-165]: #cstyle-165
[cstyle-166]: #cstyle-166
[cstyle-167]: #cstyle-167
[cstyle-168]: #cstyle-168
[cstyle-169]: #cstyle-169
[cstyle-170]: #cstyle-170
[cstyle-171]: #cstyle-171
[cstyle-172]: #cstyle-172
[cstyle-173]: #cstyle-173
[cstyle-174]: #cstyle-174
[cstyle-175]: #cstyle-175
[cstyle-176]: #cstyle-176
[cstyle-177]: #cstyle-177
[cstyle-178]: #cstyle-178
[cstyle-201]: #cstyle-201
[cstyle-202]: #cstyle-202
[cstyle-203]: #cstyle-203
[cstyle-204]: #cstyle-204
[cstyle-205]: #cstyle-205
[cstyle-206]: #cstyle-206
[cstyle-207]: #cstyle-207
[cstyle-208]: #cstyle-208
[cstyle-209]: #cstyle-209
[cstyle-210]: #cstyle-210
[cstyle-211]: #cstyle-211
[cstyle-212]: #cstyle-212
[cstyle-213]: #cstyle-213
[cstyle-214]: #cstyle-214
[cstyle-215]: #cstyle-215
[cstyle-216]: #cstyle-216
[cstyle-217]: #cstyle-217
[cstyle-218]: #cstyle-218
[cstyle-219]: #cstyle-219
[cstyle-220]: #cstyle-220
[cstyle-221]: #cstyle-221
[cstyle-222]: #cstyle-222
[cstyle-223]: #cstyle-223
[cstyle-224]: #cstyle-224
[cstyle-225]: #cstyle-225
[cstyle-226]: #cstyle-226
[cstyle-227]: #cstyle-227
[cstyle-228]: #cstyle-228
[cstyle-229]: #cstyle-229
[cstyle-230]: #cstyle-230
[cstyle-231]: #cstyle-231
[cstyle-232]: #cstyle-232
[cstyle-233]: #cstyle-233
[cstyle-234]: #cstyle-234
[cstyle-235]: #cstyle-235
[cstyle-236]: #cstyle-236
[cstyle-237]: #cstyle-237
[cstyle-238]: #cstyle-238
[cstyle-239]: #cstyle-239
[cstyle-240]: #cstyle-240
[cstyle-241]: #cstyle-241
[cstyle-242]: #cstyle-242
[cstyle-243]: #cstyle-243
[cstyle-244]: #cstyle-244
[cstyle-245]: #cstyle-245
[cstyle-246]: #cstyle-246
[cstyle-247]: #cstyle-247
[cstyle-248]: #cstyle-248
[cstyle-249]: #cstyle-249
[cstyle-250]: #cstyle-250
[cstyle-251]: #cstyle-251
[cstyle-252]: #cstyle-252
[cstyle-253]: #cstyle-253
[cstyle-254]: #cstyle-254
[cstyle-255]: #cstyle-255
[cstyle-256]: #cstyle-256
[cstyle-257]: #cstyle-257
[cstyle-258]: #cstyle-258
[cstyle-259]: #cstyle-259
[cstyle-260]: #cstyle-260
[cstyle-261]: #cstyle-261
[cstyle-262]: #cstyle-262
[cstyle-263]: #cstyle-263
[cstyle-264]: #cstyle-264
[cstyle-265]: #cstyle-265
[cstyle-266]: #cstyle-266
[cstyle-267]: #cstyle-267
[cstyle-268]: #cstyle-268
[cstyle-269]: #cstyle-269
[cstyle-270]: #cstyle-270
[cstyle-271]: #cstyle-271
[cstyle-272]: #cstyle-272
[cstyle-273]: #cstyle-273
[cstyle-274]: #cstyle-274
[cstyle-275]: #cstyle-275
[cstyle-276]: #cstyle-276
[cstyle-277]: #cstyle-277
[cstyle-278]: #cstyle-278
[cstyle-279]: #cstyle-279
[cstyle-280]: #cstyle-280
[implementation-controls]: #implementation-controls
[language-model-target-profiles-and-control-flow-discipline]:
  #language-model-target-profiles-and-control-flow-discipline
[links-and-references]: #links-and-references
[performance-and-microarchitecture-cperf-controls]:
  #performance-and-microarchitecture-cperf-controls
[scope-precedence-and-review-records]: #scope-precedence-and-review-records

<!-- Companion guides and controls -->

[c-code-standard]: c-code-standard.md
[c-code-standard-cperf-001]: c-code-standard.md#cperf-001
[c-code-standard-cperf-002]: c-code-standard.md#cperf-002
[c-code-standard-cperf-003]: c-code-standard.md#cperf-003
[c-code-standard-cperf-005]: c-code-standard.md#cperf-005
[c-code-standard-cperf-006]: c-code-standard.md#cperf-006
[c-code-standard-cperf-007]: c-code-standard.md#cperf-007
[c-code-standard-cperf-008]: c-code-standard.md#cperf-008
[c-code-standard-cperf-009]: c-code-standard.md#cperf-009
[c-code-standard-cperf-010]: c-code-standard.md#cperf-010
[c-code-standard-cperf-011]: c-code-standard.md#cperf-011
[c-code-standard-cperf-012]: c-code-standard.md#cperf-012
[c-code-standard-cperf-013]: c-code-standard.md#cperf-013
[c-code-standard-cperf-014]: c-code-standard.md#cperf-014
[c-code-standard-cperf-016]: c-code-standard.md#cperf-016
[c-code-standard-cperf-017]: c-code-standard.md#cperf-017
[c-code-standard-cperf-018]: c-code-standard.md#cperf-018
[c-code-standard-cperf-019]: c-code-standard.md#cperf-019
[c-code-standard-cperf-020]: c-code-standard.md#cperf-020
[c-code-standard-cperf-021]: c-code-standard.md#cperf-021
[c-code-standard-cperf-022]: c-code-standard.md#cperf-022
[c-code-standard-cperf-023]: c-code-standard.md#cperf-023
[c-code-standard-cperf-024]: c-code-standard.md#cperf-024
[c-code-standard-cperf-025]: c-code-standard.md#cperf-025
[c-code-standard-cperf-026]: c-code-standard.md#cperf-026
[c-code-standard-cperf-028]: c-code-standard.md#cperf-028
[c-code-standard-cperf-029]: c-code-standard.md#cperf-029
[c-code-standard-cperf-030]: c-code-standard.md#cperf-030
[c-code-standard-cperf-031]: c-code-standard.md#cperf-031
[c-code-standard-cperf-032]: c-code-standard.md#cperf-032
[c-code-standard-cperf-033]: c-code-standard.md#cperf-033
[c-code-standard-cperf-034]: c-code-standard.md#cperf-034
[c-code-standard-cperf-035]: c-code-standard.md#cperf-035
[c-code-standard-cperf-036]: c-code-standard.md#cperf-036
[c-code-standard-cperf-037]: c-code-standard.md#cperf-037
[c-code-standard-cperf-038]: c-code-standard.md#cperf-038
[c-code-standard-cperf-040]: c-code-standard.md#cperf-040
[c-code-standard-cperf-047]: c-code-standard.md#cperf-047
[c-code-standard-cstyle-001]: c-code-standard.md#cstyle-001
[c-code-standard-cstyle-026]: c-code-standard.md#cstyle-026
[c-code-standard-cstyle-052]: c-code-standard.md#cstyle-052
[c-code-standard-cstyle-075]: c-code-standard.md#cstyle-075
[c-code-standard-cstyle-108]: c-code-standard.md#cstyle-108
[c-code-standard-worked-example]: c-code-standard.md#worked-example
[c-common-pitfalls]: c-common-pitfalls.md
[c-common-pitfalls-cpit-001]: c-common-pitfalls.md#cpit-001
[c-common-pitfalls-cpit-002]: c-common-pitfalls.md#cpit-002
[c-common-pitfalls-cpit-003]: c-common-pitfalls.md#cpit-003
[c-common-pitfalls-cpit-004]: c-common-pitfalls.md#cpit-004
[c-common-pitfalls-cpit-005]: c-common-pitfalls.md#cpit-005
[c-common-pitfalls-cpit-006]: c-common-pitfalls.md#cpit-006
[c-common-pitfalls-cpit-007]: c-common-pitfalls.md#cpit-007
[c-common-pitfalls-cpit-008]: c-common-pitfalls.md#cpit-008
[c-common-pitfalls-cpit-009]: c-common-pitfalls.md#cpit-009
[c-common-pitfalls-cpit-010]: c-common-pitfalls.md#cpit-010
[c-common-pitfalls-cpit-011]: c-common-pitfalls.md#cpit-011
[c-common-pitfalls-cpit-012]: c-common-pitfalls.md#cpit-012
[c-common-pitfalls-cpit-013]: c-common-pitfalls.md#cpit-013
[c-common-pitfalls-cpit-014]: c-common-pitfalls.md#cpit-014
[c-common-pitfalls-cpit-015]: c-common-pitfalls.md#cpit-015
[c-common-pitfalls-cpit-016]: c-common-pitfalls.md#cpit-016
[c-common-pitfalls-cpit-017]: c-common-pitfalls.md#cpit-017
[c-common-pitfalls-cpit-018]: c-common-pitfalls.md#cpit-018
[c-common-pitfalls-cpit-019]: c-common-pitfalls.md#cpit-019
[c-common-pitfalls-cpit-020]: c-common-pitfalls.md#cpit-020
[c-common-pitfalls-cpit-021]: c-common-pitfalls.md#cpit-021
[c-common-pitfalls-cpit-022]: c-common-pitfalls.md#cpit-022
[c-common-pitfalls-cpit-023]: c-common-pitfalls.md#cpit-023
[c-common-pitfalls-cpit-024]: c-common-pitfalls.md#cpit-024
[c-common-pitfalls-cpit-025]: c-common-pitfalls.md#cpit-025
[c-common-pitfalls-cpit-026]: c-common-pitfalls.md#cpit-026
[c-common-pitfalls-cpit-027]: c-common-pitfalls.md#cpit-027
[c-common-pitfalls-cpit-028]: c-common-pitfalls.md#cpit-028
[c-common-pitfalls-cpit-029]: c-common-pitfalls.md#cpit-029
[c-common-pitfalls-cpit-030]: c-common-pitfalls.md#cpit-030
[c-common-pitfalls-cpit-031]: c-common-pitfalls.md#cpit-031
[c-common-pitfalls-cpit-032]: c-common-pitfalls.md#cpit-032
[c-common-pitfalls-cpit-033]: c-common-pitfalls.md#cpit-033
[c-common-pitfalls-cpit-034]: c-common-pitfalls.md#cpit-034
[c-common-pitfalls-cpit-035]: c-common-pitfalls.md#cpit-035
[c-common-pitfalls-cpit-036]: c-common-pitfalls.md#cpit-036
[c-common-pitfalls-cpit-037]: c-common-pitfalls.md#cpit-037
[c-common-pitfalls-cpit-038]: c-common-pitfalls.md#cpit-038
[c-common-pitfalls-cpit-039]: c-common-pitfalls.md#cpit-039
[c-common-pitfalls-cpit-040]: c-common-pitfalls.md#cpit-040
[c-common-pitfalls-cpit-041]: c-common-pitfalls.md#cpit-041
[c-common-pitfalls-cpit-042]: c-common-pitfalls.md#cpit-042
[c-common-pitfalls-cpit-043]: c-common-pitfalls.md#cpit-043
[c-common-pitfalls-cpit-044]: c-common-pitfalls.md#cpit-044
[c-common-pitfalls-cpit-045]: c-common-pitfalls.md#cpit-045
[c-common-pitfalls-cpit-046]: c-common-pitfalls.md#cpit-046
[c-common-pitfalls-cpit-047]: c-common-pitfalls.md#cpit-047
[c-common-pitfalls-cpit-048]: c-common-pitfalls.md#cpit-048
[c-common-pitfalls-cpit-049]: c-common-pitfalls.md#cpit-049
[c-common-pitfalls-cpit-050]: c-common-pitfalls.md#cpit-050
[c-common-pitfalls-cpit-051]: c-common-pitfalls.md#cpit-051
[c-common-pitfalls-cpit-052]: c-common-pitfalls.md#cpit-052
[c-common-pitfalls-cpit-053]: c-common-pitfalls.md#cpit-053
[c-common-pitfalls-cpit-054]: c-common-pitfalls.md#cpit-054
[c-common-pitfalls-cpit-055]: c-common-pitfalls.md#cpit-055
[c-common-pitfalls-cpit-056]: c-common-pitfalls.md#cpit-056
[c-common-pitfalls-cpit-057]: c-common-pitfalls.md#cpit-057
[c-common-pitfalls-cpit-058]: c-common-pitfalls.md#cpit-058
[c-common-pitfalls-cpit-059]: c-common-pitfalls.md#cpit-059
[c-common-pitfalls-cpit-060]: c-common-pitfalls.md#cpit-060
[c-common-pitfalls-cpit-061]: c-common-pitfalls.md#cpit-061
[c-common-pitfalls-cpit-062]: c-common-pitfalls.md#cpit-062
[c-common-pitfalls-cpit-063]: c-common-pitfalls.md#cpit-063
[c-common-pitfalls-cpit-064]: c-common-pitfalls.md#cpit-064
[c-common-pitfalls-cpit-065]: c-common-pitfalls.md#cpit-065
[c-common-pitfalls-cpit-066]: c-common-pitfalls.md#cpit-066
[c-common-pitfalls-cpit-067]: c-common-pitfalls.md#cpit-067
[c-common-pitfalls-cpit-068]: c-common-pitfalls.md#cpit-068
[c-common-pitfalls-cpit-069]: c-common-pitfalls.md#cpit-069
[c-common-pitfalls-cpit-070]: c-common-pitfalls.md#cpit-070
[c-common-pitfalls-cpit-071]: c-common-pitfalls.md#cpit-071
[c-common-pitfalls-cpit-072]: c-common-pitfalls.md#cpit-072
[c-common-pitfalls-cpit-073]: c-common-pitfalls.md#cpit-073
[c-common-pitfalls-cpit-074]: c-common-pitfalls.md#cpit-074
[c-common-pitfalls-cpit-075]: c-common-pitfalls.md#cpit-075
[c-common-pitfalls-cpit-076]: c-common-pitfalls.md#cpit-076
[c-common-pitfalls-cpit-077]: c-common-pitfalls.md#cpit-077
[c-common-pitfalls-cpit-078]: c-common-pitfalls.md#cpit-078
[c-common-pitfalls-cpit-079]: c-common-pitfalls.md#cpit-079
[c-common-pitfalls-cpit-080]: c-common-pitfalls.md#cpit-080
[c-common-pitfalls-cpit-081]: c-common-pitfalls.md#cpit-081
[c-common-pitfalls-cpit-082]: c-common-pitfalls.md#cpit-082
[c-common-pitfalls-cpit-083]: c-common-pitfalls.md#cpit-083
[c-common-pitfalls-cpit-084]: c-common-pitfalls.md#cpit-084
[c-common-pitfalls-cpit-085]: c-common-pitfalls.md#cpit-085
[c-common-pitfalls-cpit-086]: c-common-pitfalls.md#cpit-086
[c-common-pitfalls-cpit-087]: c-common-pitfalls.md#cpit-087
[c-common-pitfalls-cpit-088]: c-common-pitfalls.md#cpit-088
[c-common-pitfalls-cpit-089]: c-common-pitfalls.md#cpit-089
[c-common-pitfalls-cpit-090]: c-common-pitfalls.md#cpit-090
[c-common-pitfalls-cpit-091]: c-common-pitfalls.md#cpit-091
[c-common-pitfalls-cpit-092]: c-common-pitfalls.md#cpit-092
[c-common-pitfalls-cpit-093]: c-common-pitfalls.md#cpit-093
[c-common-pitfalls-cpit-094]: c-common-pitfalls.md#cpit-094
[c-common-pitfalls-cpit-095]: c-common-pitfalls.md#cpit-095
[c-common-pitfalls-cpit-096]: c-common-pitfalls.md#cpit-096
[c-common-pitfalls-cpit-097]: c-common-pitfalls.md#cpit-097
[c-common-pitfalls-cpit-098]: c-common-pitfalls.md#cpit-098
[c-common-pitfalls-cpit-099]: c-common-pitfalls.md#cpit-099
[c-common-pitfalls-cpit-100]: c-common-pitfalls.md#cpit-100
[c-common-pitfalls-cpit-101]: c-common-pitfalls.md#cpit-101
[c-common-pitfalls-cpit-102]: c-common-pitfalls.md#cpit-102
[c-common-pitfalls-cpit-103]: c-common-pitfalls.md#cpit-103
[c-common-pitfalls-cpit-104]: c-common-pitfalls.md#cpit-104
[c-common-pitfalls-cpit-105]: c-common-pitfalls.md#cpit-105
[c-common-pitfalls-cpit-106]: c-common-pitfalls.md#cpit-106
[c-common-pitfalls-cpit-107]: c-common-pitfalls.md#cpit-107
[c-common-pitfalls-cpit-108]: c-common-pitfalls.md#cpit-108
[c-common-pitfalls-cpit-109]: c-common-pitfalls.md#cpit-109
[c-common-pitfalls-cpit-110]: c-common-pitfalls.md#cpit-110
[c-common-pitfalls-cpit-111]: c-common-pitfalls.md#cpit-111
[c-common-pitfalls-cpit-112]: c-common-pitfalls.md#cpit-112
[c-common-pitfalls-cpit-113]: c-common-pitfalls.md#cpit-113
[c-common-pitfalls-cpit-114]: c-common-pitfalls.md#cpit-114
[c-common-pitfalls-cpit-115]: c-common-pitfalls.md#cpit-115
[c-common-pitfalls-cpit-118]: c-common-pitfalls.md#cpit-118
[c-common-pitfalls-cpit-119]: c-common-pitfalls.md#cpit-119
[c-common-pitfalls-cpit-120]: c-common-pitfalls.md#cpit-120
[c-common-pitfalls-cpit-121]: c-common-pitfalls.md#cpit-121
[c-common-pitfalls-cpit-122]: c-common-pitfalls.md#cpit-122
[c-common-pitfalls-cpit-123]: c-common-pitfalls.md#cpit-123
[c-common-pitfalls-cpit-124]: c-common-pitfalls.md#cpit-124
[c-common-pitfalls-cpit-125]: c-common-pitfalls.md#cpit-125
[c-common-pitfalls-cpit-126]: c-common-pitfalls.md#cpit-126
[c-common-pitfalls-cpit-127]: c-common-pitfalls.md#cpit-127
[c-common-pitfalls-cpit-128]: c-common-pitfalls.md#cpit-128
[c-common-pitfalls-cpit-129]: c-common-pitfalls.md#cpit-129
[c-common-pitfalls-cpit-130]: c-common-pitfalls.md#cpit-130
[c-common-pitfalls-cpit-131]: c-common-pitfalls.md#cpit-131
[c-common-pitfalls-cpit-132]: c-common-pitfalls.md#cpit-132
[c-common-pitfalls-cpit-133]: c-common-pitfalls.md#cpit-133
[c-common-pitfalls-cpit-135]: c-common-pitfalls.md#cpit-135
[c-common-pitfalls-cpit-136]: c-common-pitfalls.md#cpit-136
[c-common-pitfalls-cpit-137]: c-common-pitfalls.md#cpit-137
[c-common-pitfalls-cpit-138]: c-common-pitfalls.md#cpit-138
[c-common-pitfalls-cpit-139]: c-common-pitfalls.md#cpit-139
[c-common-pitfalls-cpit-140]: c-common-pitfalls.md#cpit-140
[c-common-pitfalls-cpit-141]: c-common-pitfalls.md#cpit-141
[c-common-pitfalls-cpit-142]: c-common-pitfalls.md#cpit-142
[c-common-pitfalls-cpit-143]: c-common-pitfalls.md#cpit-143
[c-common-pitfalls-cpit-144]: c-common-pitfalls.md#cpit-144
[c-common-pitfalls-cpit-145]: c-common-pitfalls.md#cpit-145
[c-common-pitfalls-cpit-146]: c-common-pitfalls.md#cpit-146
[c-common-pitfalls-cpit-147]: c-common-pitfalls.md#cpit-147
[c-common-pitfalls-cpit-148]: c-common-pitfalls.md#cpit-148
[c-common-pitfalls-cpit-149]: c-common-pitfalls.md#cpit-149
[c-common-pitfalls-cpit-150]: c-common-pitfalls.md#cpit-150
[c-common-pitfalls-cpit-151]: c-common-pitfalls.md#cpit-151
[c-common-pitfalls-cpit-152]: c-common-pitfalls.md#cpit-152
[c-common-pitfalls-cpit-153]: c-common-pitfalls.md#cpit-153
[c-common-pitfalls-cpit-159]: c-common-pitfalls.md#cpit-159
[c-common-pitfalls-cpit-160]: c-common-pitfalls.md#cpit-160
[c-common-pitfalls-cpit-161]: c-common-pitfalls.md#cpit-161
[c-common-pitfalls-cpit-162]: c-common-pitfalls.md#cpit-162
[c-common-pitfalls-cpit-163]: c-common-pitfalls.md#cpit-163
[c-common-pitfalls-cpit-164]: c-common-pitfalls.md#cpit-164
[c-common-pitfalls-cpit-165]: c-common-pitfalls.md#cpit-165
[c-common-pitfalls-cpit-166]: c-common-pitfalls.md#cpit-166
[c-common-pitfalls-cpit-167]: c-common-pitfalls.md#cpit-167
[c-common-pitfalls-cpit-168]: c-common-pitfalls.md#cpit-168
[c-common-pitfalls-cpit-169]: c-common-pitfalls.md#cpit-169
[c-common-pitfalls-cpit-174]: c-common-pitfalls.md#cpit-174
[c-common-pitfalls-cpit-175]: c-common-pitfalls.md#cpit-175
[c-common-pitfalls-cpit-176]: c-common-pitfalls.md#cpit-176
[c-common-pitfalls-cpit-177]: c-common-pitfalls.md#cpit-177
[c-common-pitfalls-cpit-178]: c-common-pitfalls.md#cpit-178
[c-common-pitfalls-cpit-179]: c-common-pitfalls.md#cpit-179
[c-common-pitfalls-cpit-180]: c-common-pitfalls.md#cpit-180
[c-common-pitfalls-cpit-181]: c-common-pitfalls.md#cpit-181
[c-common-pitfalls-cpit-182]: c-common-pitfalls.md#cpit-182
[c-common-pitfalls-cpit-183]: c-common-pitfalls.md#cpit-183
[c-common-pitfalls-cpit-184]: c-common-pitfalls.md#cpit-184
[c-common-pitfalls-cpit-185]: c-common-pitfalls.md#cpit-185
[c-common-pitfalls-cpit-186]: c-common-pitfalls.md#cpit-186
[c-common-pitfalls-cpit-187]: c-common-pitfalls.md#cpit-187
[c-common-pitfalls-cpit-188]: c-common-pitfalls.md#cpit-188
[c-common-pitfalls-cpit-189]: c-common-pitfalls.md#cpit-189
[c-common-pitfalls-cpit-190]: c-common-pitfalls.md#cpit-190
[c-common-pitfalls-cpit-191]: c-common-pitfalls.md#cpit-191
[c-common-pitfalls-cpit-192]: c-common-pitfalls.md#cpit-192
[c-common-pitfalls-cpit-197]: c-common-pitfalls.md#cpit-197
[c-common-pitfalls-cpit-198]: c-common-pitfalls.md#cpit-198
[c-common-pitfalls-cpit-199]: c-common-pitfalls.md#cpit-199
[c-common-pitfalls-cpit-200]: c-common-pitfalls.md#cpit-200
[c-common-pitfalls-cpit-201]: c-common-pitfalls.md#cpit-201
[c-common-pitfalls-cpit-202]: c-common-pitfalls.md#cpit-202
[c-common-pitfalls-cpit-203]: c-common-pitfalls.md#cpit-203
[c-common-pitfalls-cpit-204]: c-common-pitfalls.md#cpit-204
[c-common-pitfalls-cpit-205]: c-common-pitfalls.md#cpit-205
[c-common-pitfalls-cpit-206]: c-common-pitfalls.md#cpit-206
[c-common-pitfalls-cpit-207]: c-common-pitfalls.md#cpit-207
[c-common-pitfalls-cpit-208]: c-common-pitfalls.md#cpit-208
[c-common-pitfalls-ref-asan]: c-common-pitfalls.md#ref-asan
[c-common-pitfalls-ref-authorization]: c-common-pitfalls.md#ref-authorization
[c-common-pitfalls-ref-c23]: c-common-pitfalls.md#ref-c23
[c-common-pitfalls-ref-cwe]: c-common-pitfalls.md#ref-cwe
[c-common-pitfalls-ref-gcc-dialect]: c-common-pitfalls.md#ref-gcc-dialect
[c-common-pitfalls-ref-linux-style]: c-common-pitfalls.md#ref-linux-style
[c-common-pitfalls-ref-logging]: c-common-pitfalls.md#ref-logging
[c-common-pitfalls-ref-sql]: c-common-pitfalls.md#ref-sql
[c-common-pitfalls-ref-ssrf]: c-common-pitfalls.md#ref-ssrf
[c-common-pitfalls-ref-supply-chain]: c-common-pitfalls.md#ref-supply-chain
[c-common-pitfalls-ref-ubsan]: c-common-pitfalls.md#ref-ubsan
[c-common-pitfalls-ref-upload]: c-common-pitfalls.md#ref-upload
[c-common-pitfalls-ref-validation]: c-common-pitfalls.md#ref-validation
[c-common-pitfalls-ref-xss]: c-common-pitfalls.md#ref-xss
[c-common-pitfalls-ref-xxe]: c-common-pitfalls.md#ref-xxe
[c-common-pitfalls-research-record]: c-common-pitfalls.md#research-record
[c-common-pitfalls-worked-example]: c-common-pitfalls.md#worked-example
[c-module-architecture]: c-module-architecture.md
[c-module-architecture-worked-example]: c-module-architecture.md#worked-example

<!-- External sources -->

[bohm-jacopini-structured-programming]: https://www.cs.unibo.it/~martini/PP/bohm-jac.pdf
[dijkstra-goto-harmful]: https://www.cs.utexas.edu/~EWD/transcriptions/EWD02xx/EWD215.html
[dpdk-performance]: https://doc.dpdk.org/guides-18.05/prog_guide/writing_efficient_code.html
[ferrante-pdg-sese]: https://www.cs.utexas.edu/~pingali/CS395T/2009fa/papers/ferrante87.pdf
[ffmpeg-checkasm]:
  https://www.ffmpeg.org/doxygen/trunk/ext_2include_2checkasm_2checkasm_8h_source.html
[gcc-bidi-chars]: https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html
[intel-optimization]:
  https://cdrdv2-public.intel.com/821612/248966-Optimization-Reference-Manual-V1-050.pdf
[iso-iec-9899-c23]: https://www.iso.org/standard/82075.html
[iso-iec-ts-17961]: https://www.iso.org/standard/61134.html
[johnson-pst-sese]: https://www.cs.cornell.edu/Info/Projects/Bernoulli/
[kernighan-ritchie-c]: https://www.cs.princeton.edu/~bwk/cbook.html
[linux-bool-layout]: https://www.kernel.org/doc/html/latest/process/coding-style.html#using-bool
[linux-cachetlb]: https://www.kernel.org/doc/html/latest/core-api/cachetlb.html
[linux-coding-style]: https://www.kernel.org/doc/html/latest/process/coding-style.html
[linux-false-sharing]: https://www.kernel.org/doc/html/latest/kernel-hacking/false-sharing.html
[linux-fork-threaded]: https://man7.org/linux/man-pages/man2/fork.2.html
[linux-futex]: https://man7.org/linux/man-pages/man7/futex.7.html
[linux-kref]: https://docs.kernel.org/core-api/kref.html
[linux-memory-barriers]:
  https://www.kernel.org/doc/html/latest/core-api/wrappers/memory-barriers.html
[linux-open-cloexec]: https://man7.org/linux/man-pages/man2/open.2.html
[linux-page-migration]: https://www.kernel.org/doc/html/latest/mm/page_migration.html
[linux-rcu]: https://www.kernel.org/doc/html/latest/RCU/Design/Requirements/Requirements.html
[linux-rt-mutex]: https://docs.kernel.org/locking/rt-mutex-design.html
[linux-seqcount]: https://www.kernel.org/doc/html/next/locking/seqlock.html
[linux-static-keys]: https://www.kernel.org/doc/html/latest/staging/static-keys.html
[linux-submit-checklist]: https://www.kernel.org/doc/html/latest/process/submit-checklist.html
[linux-this-cpu]: https://www.kernel.org/doc/html/latest/core-api/this_cpu_ops.html
[linux-thp]: https://docs.kernel.org/admin-guide/mm/transhuge.html
[linux-unaligned-access]: https://docs.kernel.org/core-api/unaligned-memory-access.html
[llvm-cmov]: https://discourse.llvm.org/t/rfc-cmov-vs-branch-optimization/6040
[llvm-coding-standards]: https://llvm.org/docs/CodingStandards.html
[llvm-misexpect]: https://www.llvm.org/docs/MisExpect.html
[llvm-pgo]: https://llvm.org/docs/HowToBuildWithPGO.html
[mimalloc-design]: https://microsoft.github.io/mimalloc/
[misra-c]: https://misra.org.uk/
[nginx-development-guide]: https://nginx.org/en/docs/dev/development_guide.html
[posix-monotonic-clock]:
  https://pubs.opengroup.org/onlinepubs/9799919799/functions/clock_getres.html
[posix-read]: https://pubs.opengroup.org/onlinepubs/9799919799/functions/read.html
[posix-write]: https://pubs.opengroup.org/onlinepubs/9799919799/functions/write.html
[pthread-cleanup]: https://man7.org/linux/man-pages/man3/pthread_cleanup_push.3.html
[qemu-ops]: https://www.qemu.org/docs/master/devel/tcg-ops.html
[qemu-tcg]: https://www.qemu.org/docs/master/devel/tcg.html
[sei-cert-c]:
  https://www.sei.cmu.edu/library/sei-cert-c-coding-standard-rules-for-developing-safe-reliable-and-secure-systems-2016-edition/
[sqlite-atomic-commit]: https://sqlite.org/atomiccommit.html
[unicode-security]: https://www.unicode.org/reports/tr36/
[unicode-standard]: https://www.unicode.org/versions/Unicode17.0.0/core-spec/chapter-3/

<!-- EOF -->


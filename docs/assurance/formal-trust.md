<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Formal verification trust boundary

The `lean-ir` profile proves a claim about the imported program and declared
semantics. It does not prove source-to-IR preservation or compiled binary
correctness. CN, preprocessing, layout admission and the AIL adapter remain
trusted boundaries.

Allowed Lean axioms are `propext`, `Quot.sound` and `Classical.choice`.
The auditor rejects custom axioms and unfinished proofs transitively.
Kernel replay checks exported theorem closures independently.

Liquid Haskell verifies declared arithmetic and access-permission primitives.
Its compiler, plugin and solver form a separate trust boundary. The complete
Haskell engine is not refinement-proved.

The campaign currently proves only mock. General memory, translation and
finite-certificate libraries are foundations, not evidence of an implemented
allocator or garbage collector.

Linux uses verified cgroup limits and a shared resource slice. Windows uses
Job Objects. macOS samples process-group memory and count and throttles CPU;
short overshoots and detached children are limitations. These controls serve
cooperative builds and are not a hostile-code sandbox.
The formal toolchain currently requires Linux x86-64.

<!-- EOF -->


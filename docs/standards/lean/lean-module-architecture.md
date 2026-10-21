<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Lean Module Architecture

Keep model definitions reusable, audit code explicit and proof roots inventoried. The
[code standard's governance](lean-code-standard.md#governance) defines rule levels and exceptions.

<details>
<summary><strong>On this page</strong></summary>

- [Current library map](#current-library-map)
- [Architecture controls](#architecture-controls)
- [Maintenance](#maintenance)

</details>

---

## Current library map

| Root or directory | Responsibility |
| --- | --- |
| `LibMemAlloc.lean` | Public model import root |
| `LibMemAllocImp/MemoryAllocator/` | Allocator definitions and theorems |
| `LibMemAllocImp/GarbageCollector/` | Managed-object and collection models |
| `LibMemAllocTests.lean` | Named model regressions |
| `LibMemAllocAudit/` | Environment inspection, witness coverage, export and contract snapshots |

Lake's default targets are the model and tests. The full source check also builds the audit. Keep this
distinction visible: `lake check` exports the default targets, while the audit uses metaprogramming
infrastructure that should not become an accidental model dependency.

---

## Architecture controls

<a id="lmod-001"></a>

### LMOD-001: Keep the model independent of audit and tests

**MUST · import graph.** Model modules may import model dependencies and admitted bundled libraries.
They must not import tests or audit modules. Audit and test code may depend on the model; review any
test/audit support relationship for cycles and exported scope.

**Rationale and examples:** A model import is valid; importing environment inspection into a scalar model is not.

```lean
-- Conforming model dependency.
import LibMemAllocImp.MemoryAllocator.Arithmetic
```

```lean
-- Nonconforming in a model module.
import LibMemAllocAudit.Support
```

**Verification and limits:** The local style checker enforces the model boundary and local import existence.
It does not prove semantic independence or establish minimal imports.

<a id="lmod-002"></a>

### LMOD-002: Connect each module to an audited root

**MUST · new source files.** Add model/test modules to their library import graph. Include delivered theorem
roots in the contract and axiom inventories. Preserve stable `Allocator.*` identities during file moves.

**Rationale:** An unimported file can escape the build that reviewers treat as complete.

```lean
-- Conforming: add the real module to the owning root.
import LibMemAllocImp.MemoryAllocator.Reservation
```

```text
Nonconforming: add NewProof.lean to disk without an import-root or audit-inventory change.
```

**Verification and limits:** Inspect `modules.tsv`, build the audit and check contract snapshots. A connected
module can still contain a theorem outside the namespace-based audit; reviewers must check declaration coverage.

<a id="lmod-003"></a>

### LMOD-003: Separate representations from proof interfaces

**MUST · reusable model APIs.** Put a representation, its invariant and basic operation lemmas together.
Let higher-level proofs use those lemmas. Keep concrete C widths, object contracts and importer assumptions
in named boundary definitions rather than silently embedding them in generic arithmetic.

**Rationale:** A representation change must expose the proofs and assumptions it invalidates.

```lean
-- Conforming interface use.
exact Nat.le_of_lt hBound
```

```text
Nonconforming: copy the entire representation into each consumer and prove against those private copies.
```

**Verification and limits:** Review dependency direction and affected elaborated definitions. The kernel does
not determine whether two independently maintained definitions were intended to describe the same operation.

<a id="lmod-004"></a>

### LMOD-004: Give generators and dependencies explicit owners

**MUST · generated files and package dependencies.** Mark generated sources with their generator, inputs and
regeneration command. Review generated changes. Add mathlib or another dependency only through a separate
versioned dependency decision; using its naming conventions requires no package installation.

**Rationale:** Generated code and imported libraries expand the reviewed source and trust boundary.

```text
Conforming: LibMemAllocAudit/Coverage.lean identifies the catalog generator and remains versioned.
Nonconforming: hand-edit the witness array to hide a missing requirement mapping.
```

**Verification and limits:** Check reproducible generation and the Lake manifest. A generated file can compile
while omitting an intended result; compare its inventory to the specification catalog.

---

## Maintenance

When moving a module, review import paths, declaration names, witness roots, snapshots and documentation links.
When changing a global instance or simp lemma, rebuild dependent modules and measure search cost. Preserve a
deprecated name long enough for a reviewed migration when external users depend on it; local contract roots
require coordinated inventory changes. The [Growing Mathlib paper, v1](https://arxiv.org/html/2508.21593v1)
provides maintenance examples involving deprecation, linting and review. Those examples inform these local
controls; they do not establish that mathlib's automation runs here.

<!-- EOF -->


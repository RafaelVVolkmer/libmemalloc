<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Lean development guides

Use these guides for definitions, proofs, audit metaprograms and executable models. Mathlib's style, naming
and documentation conventions supply the editorial base. The Lean 4.35.0 reference defines semantics;
local controls define accepted evidence. See the [source register](lean-code-standard.md#sources).

The code standard requires a
[mathematical statement immediately above every theorem](lean-code-standard.md#lstyle-math-001),
including existing, private, auxiliary and generated results. The comment must give domains, quantifiers,
hypotheses and conclusion. Review its agreement with the Lean proposition separately from proof validity.

| Guide | Responsibility |
| --- | --- |
| [Lean code standard](lean-code-standard.md) | Names, declarations, proof structure, arithmetic, axioms and trust |
| [Lean documentation](lean-documentation.md) | Module summaries, definitions, theorems, hypotheses and examples |
| [Common Lean pitfalls](lean-common-pitfalls.md) | Proof, specification and execution failures with conditional CWE mappings |
| [Lean module architecture](lean-module-architecture.md) | Model, tests, audit, imports and maintenance |
| [Lean compliance and assurance](lean-compliance.md) | Profiles, actual tool coverage, deviations and acceptance |
| [Lean proof validation](test/lean-tests-formal.md) | Statement review, transitive audit, replay and negative controls |
| [C–Haskell–Lean integration](../formal-integration.md) | Correspondence obligations beyond a checked theorem |

The current workspace uses Lean 4.35.0 and its bundled libraries. Adopting mathlib conventions does not add
mathlib as a dependency. The FlexibleLinter is a review reference; it is not installed in this workspace.
The [existing audit](../../../verification/theorems/LibMemAllocAudit/Support.lean) permits only `propext`,
`Quot.sound` and `Classical.choice`, and checks theorem dependencies transitively.

Run `lua scripts/verification/check.lua` and, from `verification/theorems`, `lake check` using the pinned tools.
The [verification commands](../../../docs/runbooks/formal-verification.md) explain their different guarantees.
For these guides, use the [documentation checks](../../getting-started/documentation.md#validation).

<!-- EOF -->


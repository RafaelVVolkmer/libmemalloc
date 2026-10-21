<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Formal engine contract

The only current C verification target is `core/mock.c` with `core/mock.h`.
This fixture is not a final allocator component. Production operations require
their own reviewed specifications, contracts and evidence.

## LMA-ENGINE-INPUT-001: Explicit inputs

The engine consumes actual C, headers, a target and a declarative translation
contract. Contracts select a symbol, layout, mutable cells and Lean predicates.
They cannot replace the source body or supply an expected IR.
The admitted target is Linux x86-64 LP64. Unsupported syntax fails admission.

## LMA-ENGINE-EVIDENCE-001: Required evidence

The campaign builds the Lean semantics, audits transitive axioms and replays
proofs in an isolated kernel. It builds Haskell with Liquid Haskell, checks
refined arithmetic and permissions, and rejects incorrect refinements.
The parser, protocol and supervision regressions must pass.

For mock, CN supplies AIL frontend output. Haskell imports the actual body,
checks its branches and constructs a certificate. The trusted driver
reconstructs the expected claim from the same inputs. Lean checks the program
theorem, coverage and scalar refinement; the kernel replays their closures.
CN import success alone is not proof acceptance.

## LMA-ENGINE-MOCK-001: Mock behavior

`MOCK_identity(void)` returns zero. It accesses no shared state and allocates
no memory. Its predicates are `Allocator.C.Scalar.pre` and
`Allocator.C.Scalar.zero`. Existing native build and consumer checks remain
independent evidence. This proof makes no allocator correctness claim.

## LMA-ENGINE-RESULT-001: Result classification

`PASS` requires every declared stage and unchanged inputs. `REFUTED` requires
an accepted counterexample theorem. Failed proof search is inconclusive;
timeout, missing tools, interruption and malformed evidence cannot pass.
Reports retain source identity, tool identity, command logs and limitations.
Technical evidence does not approve a feature or close its issue.

## LMA-ENGINE-WORKFLOW-001: Extension order

A new operation follows specification, linked issue, mathematical model,
Haskell obligations, C implementation, verification and review.
Its contract, adequacy controls and native tests derive from the specification.
Adding a file or obtaining a successful parser result does not close obligations.

<!-- EOF -->


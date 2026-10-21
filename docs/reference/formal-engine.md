<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Formal verification engines

Haskell imports the supported C fragment into a typed IR and constructs
certificates. Lean defines semantics and checks program derivations.
The campaign verifies only the repository mock. See the
[contract](../specs/formal-engine.md) and
[runbook](../runbooks/formal-verification.md).

The IR supports scalar reads, writes, unsigned arithmetic, comparisons,
branches and terminal returns. Layouts and write permissions are explicit
inputs. Loops, calls, casts, arbitrary pointer arithmetic and concurrent
operations are unsupported. Unknown versions, syntax and layouts fail closed.

`verification/engine` contains the Cabal package. `verification/theorems`
contains semantics, certificate rules and the axiom auditor.
`verification/contracts/mock.json` binds the fixture to its predicates.
Parser fixtures and negative controls test the engines themselves.

The campaign stages are `start`, `prepare`, `lean`, `haskell`, `proof`, `tests`
and `check`. Each stage retains receipts and verifies its predecessor and
input identity. A kernel lease prevents competing campaigns. Changed inputs
require a new run identity.

The generic C driver accepts an explicit source, contract and run identity.
It independently reconstructs producer evidence, audits required theorems and
replays their closures. Its result covers imported IR under admitted scalar
semantics. The frontend remains a trust boundary.

<!-- EOF -->


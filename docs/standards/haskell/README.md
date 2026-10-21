<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Haskell development guides

Use these guides for the state engine, protocol readers, certificate producers and execution adapters.
Kowainik supplies the editorial base; the Haskell 2010 Report and GHC 9.4.7 manual define language behavior.
Local controls govern acceptance. The [source register](haskell-code-standard.md#sources) records precedence
and revisions. These guides do not establish conformance of the existing implementation.

The code standard requires [Liquid Haskell auditing of every owned function](haskell-code-standard.md#hstyle-liquid-001)
and a [mathematical statement above each theorem or formal-property function](haskell-code-standard.md#hstyle-math-001).
These requirements include existing, private, local and generated code. The current `Refined.hs` coverage is
partial and does not meet the whole-tree requirement.

| Guide | Responsibility |
| --- | --- |
| [Haskell code standard](haskell-code-standard.md) | Language profile, interfaces, evaluation, failures, arithmetic and foreign calls |
| [Haskell documentation](haskell-documentation.md) | Haddock modules, declarations, contracts and examples |
| [Common Haskell pitfalls](haskell-common-pitfalls.md) | Failure scenarios, prevention, regression designs and conditional CWE mappings |
| [Haskell module architecture](haskell-module-architecture.md) | Pure model, import pipeline, execution and dependency boundaries |
| [Haskell compliance and assurance](haskell-compliance.md) | Rule evidence, tool coverage, exceptions and acceptance |
| [Haskell testing and formal evidence](test/haskell-tests-formal.md) | Properties, state machines, refinements and proof-producing execution |
| [C–Haskell–Lean integration](../formal-integration.md) | Representation relations, arithmetic, operation binding and evidence limits |

The current package declares Haskell2010, with `CPP` in the refinement module. Fourmolu 0.21.0.0 and HLint
3.10 have repository configurations. QuickCheck and Hedgehog are design references, not installed test
dependencies. The current C boundary uses processes and artifacts; the foreign function interface (FFI)
rules apply when a direct binding is introduced.

Run `lua scripts/verification/check-haskell.lua` after preparing tools through the
[engine commands](../../../docs/runbooks/formal-verification.md). Documentation checks follow the
[authoring guide](../../getting-started/documentation.md); source lint does not check Markdown examples.

<!-- EOF -->


<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Rust development guides

| Guide | Content |
| --- | --- |
| [Rust Code Standard](rust-code-standard.md) | Naming, formatting, errors, ownership, unsafe, security, performance, and verification. |
| [Common Rust Pitfalls](rust-common-pitfalls.md) | 56 failure scenarios with prevention controls, external references, and local examples. |
| [Rust Module Architecture](rust-module-architecture.md) | Crate boundaries, ports, lifecycle, ABI, build, and release examples. |

Start with the language and profile contract in the standard. Use the grouped rule indexes to locate
requirements, examples and related failure scenarios. Each guide supplies its own Rust explanations;
shared engineering topics do not require consulting another language's standard.

The standard contains 90 implementation and source-presentation controls, 18 performance controls and
18 restricted-facility entries. The [naming and source presentation
section](rust-code-standard.md#naming-and-source-presentation-controls)
details naming by construct, acronyms, units, API verbs, test names, column budgets, blank lines, indentation,
line breaks, imports, comments, literals and file organization. Each control includes local examples.
The architecture guide contains 34 controls. Complete named examples cover bounded allocation, composition,
raw-input safety and reference/candidate comparison. Contextual and failure fragments are labeled and must
not be treated as standalone executable tests.

The [allocation, scheduling and configuration controls](rust-code-standard.md#rust-085) deepen raw vector
ownership, partial initialization, wake registration, atomic outcomes, nullable callbacks and Cargo resolution.
Each has a failure scenario and a verification design. The [allocation regression](rust-code-standard.md#allocation-regression)
provides six host tests and explicitly identifies native, concurrency and unsafe-tool evidence still required.

The checked-in repository has no Rust Cargo workspace or Rust CI runner. The guides define the
required profiles and distinguish documented recipes from implemented checks. See the standard's
[example validation record](rust-code-standard.md#example-validation-record) for the checks performed on
extracted examples and their limitations.

<!-- EOF -->


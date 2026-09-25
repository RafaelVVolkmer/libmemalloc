<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# C development guides

| Guide | Content |
| --- | --- |
| [C Code Standard](c-code-standard.md) | Naming, control flow, ownership, APIs, and review rules. |
| [C Documentation Standard](c-documentation.md) | Complete, annotated construction of private.c, internal.h, public.h, and main.c, with every documentation field. |
| [Common C Pitfalls](c-common-pitfalls.md) | 208 pitfalls with external references and mitigations. |
| [C Module Architecture](c-module-architecture.md) | Module boundaries, public headers, ABI, and build examples. |
| [C Compliance and Assurance](c-compliance.md) | Assessment boundaries, lifecycle evidence, and release acceptance. |
| [C Formal Verification](test/c-tests-formal.md) | Campaign layout, contracts, state and memory models, and proof acceptance. |

The code standard, common pitfalls, and module architecture guides derive from
[Coil's C language guides](https://github.com/frostlanguage/coil/tree/main/docs/code_style/c_language).
Their copyright and GPL-3.0-only identifiers are preserved. The CI scripts and
Clang configurations were adapted with them. Local rules update
CSTYLE-022 for simple branches and add [blank-line grouping](c-code-standard.md#cstyle-279)
and [call/check adjacency](c-code-standard.md#cstyle-280). Positive examples follow
these local rules; explicitly noncompliant examples retain their teaching purpose.

The local architecture also defines [application `main.c` scope](c-module-architecture.md#cmod-021):
its own helpers and state are private, its includes may name any needed dependency, and hosted
`main` retains its required entry linkage. [C++ compatible headers](c-module-architecture.md#cmod-019)
own the guarded `extern "C"` block; it is the only permitted explicit `extern` in project-authored
C interfaces. These local rules replace the inherited prohibition of linkage blocks in core headers.

CI validates the documented complete examples with GCC, Clang, and sanitizers.
It also checks Clang policy fixtures and the pitfall reference inventory.
Fragments that illustrate invalid C are not compiled as complete programs.
Semantic module checking uses the repository's compiler-backed architecture checker
by default. `LIBMEMALLOC_MODULE_CHECKER` selects an external checker instead.
These checks cover a declared subset of the rules. See the
[CI guide](../../reference/automation.md) for current coverage.

<!-- EOF -->


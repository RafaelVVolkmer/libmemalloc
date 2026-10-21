<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Lua development guides

These guides define Lua development in this repository: syntax, naming, layout,
spacing, contracts, modules, testing and optimization. Start with the standard,
then use the topic guides for explanations and examples. No C guide is required.

| Guide | Responsibility |
| --- | --- |
| [Lua code standard](lua-code-standard.md) | Names, structure, errors, ownership, performance, and runtime profiles |
| [Lua comments and readable layout](lua-comments.md) | LDoc contracts, blank lines, EOF markers, and source organization |
| [Lua performance and JIT](lua-performance.md) | Profiling, traces, hot loops, allocation, FFI, and benchmarks |
| [Lua module architecture](lua-module-architecture.md) | Dependency direction, interfaces, lifecycle, and composition |
| [Common Lua pitfalls](lua-common-pitfalls.md) | Failure scenarios and regression-test design |

Run installed tools from the repository root through `lua scripts/workspace/with_tools.lua`.
Use `scripts/check/lua.lua` for syntax, formatting, Selene, LuaLS and the
[measured complexity gate](../../reference/lua-quality.md);
use `scripts/check/eof.lua` for the terminal comment and blank lines.
The [cache guide](../../reference/cache.md) defines disposable output paths.

The standard has 78 implementation controls, alongside performance and restricted-facility registers;
the architecture guide has 44 controls and the pitfalls catalogue has 60 scenarios. The
[native boundary controls](lua-code-standard.md#lstyle-073) cover stack and registry ownership, continuations,
coroutine cleanup, LuaJIT allocation/callback lifetimes and syntax qualification. Their linked failure scenarios
give concrete regression designs. The [coroutine fixture](lua-code-standard.md#coroutine-regression) supplies
five executable cleanup cases with separate operation and close errors.
Its authoring record identifies the current Selene catalogue limitation for `coroutine.close`;
runtime execution alone does not qualify that API for checked-in repository Lua.

Formatting does not prove full naming, SESE, or module-boundary conformance.
Review those contracts and preserve regression evidence when migrating an API.

<!-- EOF -->


<!-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com> -->
<!-- SPDX-License-Identifier: GPL-3.0-only -->

# C analysis configuration

Run `lua scripts/workspace/cache.lua lua scripts/check/c.lua` from the repository root.
The same driver runs in the C job of `_lint.yml`. It checks indexed C files;
new files must enter the index before a normal full-repository run includes them.
The Doxygen stage instead inventories the implementation roots in `scripts/documentation/config.lua`, initially `core/`,
including untracked files. It evaluates documentation before the code analyzers run.

The [C campaign matrix](../../../../docs/runbooks/c-analysis.md) adds independent
semantic engines and artifact checks through `_c-analysis.yml`. ClangFormat stays
in formatting; clang-tidy disables `clang-analyzer-*` because the dedicated CSA
campaign owns those path checks.

| Tool | Configuration | Failure policy |
| --- | --- | --- |
| ClangFormat | `.clang-format` | Formatting differences fail. |
| Clang-Tidy | `.clang-tidy` | Configured diagnostics and policy fixtures gate the job. |
| Cppcheck | `scanners.lua` | Warning, style, performance, portability, and error findings fail. |
| Flawfinder | `scanners.lua` | Report level 1 and above; fail at risk level 3 and above. |
| Doxygen | `doxygen/config/Doxyfile` and `scripts/documentation/config.lua` | Documentation warnings or failed generation fail. |

The Lua driver checks clean and defective fixtures for both security analyzers.
Flawfinder scans source text and flags risky APIs; it does not prove a memory
error. Cppcheck performs static analysis under its configured C dialect and
platform assumptions. Its current native profile is not cross-target coverage.
Review lower-risk Flawfinder findings and qualify target-specific include paths,
defines, and compile databases before extending the production build matrix.
See the [Cppcheck manual](https://cppcheck.sourceforge.io/manual.html) and
[Flawfinder documentation](https://dwheeler.com/flawfinder/).

`tools/toolchain/lock.toml` owns executable versions and archive digests.
The `setup-c-scanners` action downloads verified artifacts and calls the Lua
installer. Third-party Flawfinder uses its upstream Python runtime; the repository
does not add an authored Python check. Cppcheck compilation and analyzer caches
stay under `.cache/tools/`; fixtures stay under `.cache/tests/`.

Use `LIBMEMALLOC_CPPCHECK` and `LIBMEMALLOC_FLAWFINDER` to select installed binaries.
Use `LIBMEMALLOC_DOXYGEN` for the locked Doxygen executable. CI downloads its verified official archive.
Run `lua scripts/check/c.lua --doxygen-only` to evaluate documentation independently, or
`lua scripts/documentation/main.lua build` to generate the themed site. See the
[Doxygen guide](../../../../doxygen/README.md) for pages, images and implementation selection.
Neither analyzer establishes a formal proof or compliance certification. Follow
[C Formal Verification](../../../../docs/standards/c/test/c-tests-formal.md)
for campaign and proof requirements.

C comment text is owned by [Doxygen](../../../../doxygen/README.md). ClangFormat preserves comment
contents and trailing alignment; clang-tidy disables comment-only and documentation diagnostics. Spelling
and prose tools exclude C comments, including documentation comments inside Markdown C fences. This does
not disable identifier, expression, lifetime, API, or other code checks. Unterminated comments remain compiler
errors because they change the token stream.

<!-- EOF -->


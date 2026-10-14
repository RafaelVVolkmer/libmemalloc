<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# C analysis campaigns

The current source inventory contains the distribution mock and its consumer:
`core/mock.c` and `core/main.c`. These campaigns qualify tools against that code
and deliberate defects. They do not establish allocator correctness. Adding a
translation unit requires updating and reviewing `tools/analysis/c/profile.lua`.

<details>
<summary><strong>On this page</strong></summary>

- [Execution matrix](#execution-matrix)
- [Distinct responsibilities](#distinct-responsibilities)
- [Reports and tool identity](#reports-and-tool-identity)
- [Local execution](#local-execution)
- [Further qualification](#further-qualification)

</details>

---

## Execution matrix

| Campaign | Selected pull request | Integration and nightly | Evidence and scope |
| --- | --- | --- | --- |
| clang-format | Yes | Yes | Formatting only; existing C job. |
| clang-tidy, Cppcheck, Flawfinder | Yes | Yes | Existing policy and defect checks; `clang-analyzer-*` is disabled in clang-tidy. |
| GCC analyzer | Yes | Yes | GCC 14 path analysis, JSON diagnostics, separate complexity-limit reporting. |
| CSA through CodeChecker | Yes | Yes | Clang 18 path analysis, checker inventory, per-file success and failure records. |
| CSA with CTU | No | Yes | Explicit CTU, including a cross-file divide-by-zero regression fixture. |
| MSVC analysis | Yes | Yes | Windows x64, selected MSVC tools and SDK, SARIF including suppressed diagnostics. |
| Architecture | Yes | Yes | Compiler-resolved includes, public include directories, AST references, callback casts. |
| Sparse | No | Yes | Restricted-type fixture and current sources; production annotations remain future work. |
| Numeric quality and CMake | Yes | Yes | [Manifest gates](../reference/build-quality.md), CMake lint and executable regressions. |
| Formal executor | Yes | Yes | CBMC probes and source dispositions; current product campaigns are empty. |
| CodeQL | No | Separate workflow | Manual build on default-branch pushes, weekly, dispatch and release; SARIF upload. |

Integration means merge queues, manual validation, release events, tags and the
default branch. `c-analysis-nightly.yml` also runs the integration profile daily.
These are representative profiles, independent of the build matrix.

The reusable `_c-analysis.yml` workflow contributes to `CI gate` when C inputs
change. A rule, model, header, build configuration or analysis script change
selects the campaign again. Analysis covers the full selected source inventory;
it is not restricted to edited lines. New findings fail the campaign;
there is no baseline suppression or PR-only diagnostic filter. CodeChecker
exports every review status.

---

## Distinct responsibilities

CodeChecker runs and exports CSA results; it is not an additional analysis engine.
The [CTU documentation][ctu] describes the cross-file mechanism. Both ordinary
CSA and CTU require every expected source to appear in successful analysis records.
Skipped inputs, failed parsing, timeouts and missing result files fail the job.
The CTU fixture requires a diagnostic that depends on the imported definition.

GCC runs `-fanalyzer`, `-Wanalyzer-too-complex` and
`-Wanalyzer-symbol-too-complex`. Complexity diagnostics make the report
`INCOMPLETE` and fail the gate; other findings make it `FAIL`.
This follows the [GCC analyzer's discovery-oriented scope][gcc].

Architecture checks use compiler dependency output after preprocessing and
canonical path resolution. The manifest assigns headers to modules and declares
public headers. CMake's file API supplies the consumer's effective include paths.
AST references detect forbidden functions even through aliases; compiler type
diagnostics reject incompatible callback casts. The checks enforce the tested CMOD subset; the remaining
architecture controls require separate review. `scripts/check/modules.lua` uses it
by default; `LIBMEMALLOC_MODULE_CHECKER` remains an external checker override.

---

## Reports and tool identity

Each invocation requires a fresh output directory under `.cache/ci/`. Linux
reports contain expected and analyzed files, exclusions, tool versions and
executable digests, commands, exit codes, log digests, findings and limitations.
`ERROR` means the invocation or evidence validation failed. `PASS` applies only
to the stated campaign. Hosted jobs preserve evidence even after failure.

`inputs.json` hashes sources, headers, build configuration, scripts, rules,
fixtures and the lock; it also records the profile, target and captured compilation
database when applicable. The report contains its SHA-256 identity. Absolute
build paths make that identity conservative across output directories.
No report is restored from a cache, and compilation objects never count as
analysis evidence. The fixed GCC profile uses explicit flags matching the mock
configuration; it is not a general compilation-database replay adapter.

Tool versions live in `tools/toolchain/lock.toml`. Compiler majors and
specialist upstream versions are checked at runtime; distribution patch versions and
binary digests are recorded. Python tool versions are pinned, and the installer
preserves the resolved dependency set. Transitive Python packages and apt package
revisions are not checksum-locked.

Windows retains its SDK, compiler version, include paths, commands and SARIF. The
[Microsoft analysis switches][msvc] enable analyzed-file and configuration
evidence. The hosted Windows campaign and CodeQL need execution on GitHub before
their operational status can be claimed. Linux validation does not substitute
for those runs.

CodeQL initializes before a clean, explicit CMake build. Both mock translation
units must appear in the compilation database. Its [manual build mode][codeql]
captures the build selected by this workflow. Private repositories must enable
GitHub Code Security and set `LIBMEMALLOC_CODEQL_ENABLED=true`; the variable alone
does not grant service access. CodeQL upload reports findings to code scanning;
repository code-scanning protection determines whether alerts block merging.

---

## Local execution

With the locked tools available, run from the repository root:

```sh
lua tests/automation/analysis/analysis_test.lua
lua scripts/workspace/cache.lua lua scripts/analysis/run.lua --group=rules
lua scripts/workspace/cache.lua lua scripts/check/c_analysis.lua --campaign=csa
lua scripts/workspace/cache.lua lua scripts/check/c_analysis.lua --campaign=csa-ctu
lua scripts/workspace/cache.lua lua scripts/analysis/run.lua --group=extended
```

For repeat runs, `scripts/check/c_analysis.lua` and
`scripts/check/c_architecture.lua` accept `--output` with a new directory.
`scripts/toolchain/install/c_analysis.lua --group=rules`, `csa` or `extended`
installs the corresponding tools on Ubuntu 24.04 and requires apt privileges.
It adds tool paths through `GITHUB_PATH` in CI; local callers must add the
created directories to `PATH`. Executable overrides are
`LIBMEMALLOC_GCC_ANALYZER`, `LIBMEMALLOC_CLANG_ANALYZER`,
`LIBMEMALLOC_CODECHECKER` and `LIBMEMALLOC_SPARSE`.

---

## Further qualification

The mock-specific ABI and CBMC campaigns have been removed. General compilation,
compatibility and installation tests remain active. No formal property is currently
claimed by this campaign set. Future allocator campaigns need live-block
non-overlap, region bounds, size/alignment overflow and free-list invariants,
with operation and heap bounds stated explicitly. Keep implementation analysis
separate from consumer analysis using API models; never replace an implementation
by the contract being verified.

| Candidate | Required next evidence |
| --- | --- |
| Sparse production contracts | Address-space, representation and lock annotations tied to actual low-level interfaces. |
| Goblint | Real shared state and a supported synchronization model; no empty atomic or lock stubs. |
| Infer/Pulse | Memory/resource cases that add useful results beyond the existing engines. |
| Smatch | Qualified project build and state/relation diagnostics absent from current campaigns. |
| IKOS | Isolated LLVM/Clang 14 toolchain per its [documented dependency][ikos], numerical invariants and complementary results. |
| Frama-C | Named goals and models for Eva, WP or RTE; the documentation portfolio alone is not an executed campaign. |
| ESBMC and CPAchecker | Selected properties and comparison against established bounded campaigns. |
| PVS-Studio, ECLAIR, Polyspace | A defined support, coverage or qualification need and evaluation against real project cases. |

These candidates have no placeholder success jobs. Add them after the relevant
code and models exist, retaining positive and negative fixtures so tool updates
cannot silently remove the expected detection.

[gcc]: https://gcc.gnu.org/onlinedocs/gcc/Static-Analyzer-Options.html
[ctu]: https://clang.llvm.org/docs/analyzer/user-docs/CrossTranslationUnit.html
[msvc]: https://learn.microsoft.com/en-us/cpp/build/reference/analyze-code-analysis?view=msvc-170
[codeql]: https://docs.github.com/en/code-security/reference/code-scanning/workflow-configuration-options
[ikos]: https://github.com/NASA-SW-VnV/ikos

<!-- EOF -->


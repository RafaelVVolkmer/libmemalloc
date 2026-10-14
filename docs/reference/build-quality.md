<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Build quality and publication

This reference defines the numeric C analysis gates, compilation metadata and artifact-based Pages deployment.

<details>
<summary><strong>On this page</strong></summary>

- [Numeric gates](#numeric-gates).
- [Formal scope](#formal-scope).
- [Compilation metadata](#compilation-metadata).
- [Compatibility consumers](#compatibility-consumers).
- [Pages deployment](#pages-deployment).

</details>

---

## Numeric gates

The [manifest](../../tools/analysis/c/gates.json) sets the owned source roots and thresholds.
The [quality controller](../../scripts/analysis/quality.lua) preserves reports under `.cache/ci/c-analysis/`.
It executes independent gates and returns failure if any gate fails or cannot run.

| Measure | Engine | Limit |
| --- | --- | --- |
| Cyclomatic complexity | Lizard, per function | 10 |
| Cognitive complexity | Clang-Tidy, per function | 15 |
| Duplicate blocks | Lizard token-normalized clones | 0 |
| Clone detection minimum | Lizard token window | 70 tokens |

Zero duplicate blocks applies to the declared source inventory and detection threshold. It does not claim
that repeated syntax or shorter fragments cannot exist. Renamed-clone and excessive-complexity fixtures
exercise the engines before source assessment. Third-party and generated code are outside the owned roots.
Maintainers review threshold changes as policy changes; tools must not silently raise limits to pass.

The same C analysis job runs CMake lint/format checks over owned `CMakeLists.txt` and `.cmake` files,
then executes the multi-config CMake regressions. CMake changes select the C analysis workflow.
Install the Python graph with
`lua scripts/toolchain/python.lua --groups=quality --directory=.cache/tools/c-quality`.
The Python manifest under `tools/python/` selects dependencies; `tools/python/uv.lock` fixes their versions
and artifact hashes.
Set `LIBMEMALLOC_QUALITY_PYTHON`, `LIBMEMALLOC_CLANG_TIDY`, `LIBMEMALLOC_CBMC`,
`LIBMEMALLOC_CMAKE_LINT` and `LIBMEMALLOC_CMAKE_FORMAT` when tools are outside `PATH`.

```sh
ansible-playbook playbook.yml -e lma_task=analysis -e '{"lma_arguments":["--group=quality"]}'
lua scripts/analysis/quality.lua
lua scripts/check/cmake.lua
```

---

## Formal scope

The [formal controller](../../scripts/analysis/formal.lua) executes CBMC with pointer, bounds, signed-overflow
and unwinding assertions. Positive and negative executor probes must produce actual property results.
The manifest declares campaign sources, harnesses, unwind bounds and timeouts. New C sources need a
campaign or a documented exclusion. An incomplete inventory fails the gate.

The current product campaign list is empty: the two distribution-fixture sources have explicit exclusions.
The executor can pass while `product_state` remains `NOT_APPLICABLE`. No allocator proof follows from
these probes. Add reviewed product harnesses under `tests/formal/` before claiming product verification.
Each campaign has `id`, `sources` and `harness` fields. The controller requires a successful result for each
reported property, including unwinding assertions.

---

## Compilation metadata

`LMA_BUILD_METADATA=ON` emits readable JSON through the `build-metadata` target during a normal build.
The original `compile_commands.json` remains in the build root for IDEs and analyzers. The distributed copy
lives in `metadata/<Config>/`, with `build.json` binding its SHA-256 to the built library SHA-256.
Installation includes both files under `share/libmemalloc/metadata`; change `LMA_METADATA_INSTALL_DIR`
to select another package location.

The distributed database uses `/libmemalloc/source` and `/libmemalloc/build` as virtual roots. Map them
to your actual checkout and build directories before replay. This avoids publishing temporary host paths
and preserves independent-rebuild comparisons. The raw multi-config database describes the generator's complete
configuration set. Each distributed database retains only this project's commands for the selected
configuration; `build.json` identifies that binary configuration.

Ninja and Makefiles support this database. Other generators require an explicit `LMA_BUILD_METADATA=OFF`.
Metadata is evidence for the selected toolchain, not a claim that foreign-language drivers emit CMake entries.

---

## Compatibility consumers

[CMake compatibility](../../cmake/compatibility.cmake) accepts `LMA_COMPATIBILITY_LANGUAGES` with
`c`, `cpp`, `rust`, `zig`, `c3`, `wasm` and `baremetal`. Each requested compiler is required; missing tools fail
configuration. Templates live under `tests/fixtures/compatibility/ffi/`, alongside the existing C/C++ dialect tests.
Rust, Zig and C3 consumers link the native static C library. These checks establish interoperability with the
current distribution symbol; they do not establish an allocator implementation.

```sh
cmake --preset interop
cmake --build --preset interop
ctest --preset interop
cmake --preset wasm
cmake --build --preset wasm
ctest --preset wasm
cmake --preset baremetal
cmake --build --preset baremetal
```

The `interop` preset selects C, C++ and Rust. Select `zig;c3` explicitly to exercise those consumers with their
installed toolchains. WebAssembly uses Clang and Node.js to execute the exported C entry point. The bare-metal
AArch64 profile builds freestanding objects; board startup, linker scripts, emulator and hardware execution
remain platform responsibilities. It has no runtime passing claim.

---

## Pages deployment

[Documentation Actions](../../.github/workflows/documentation.yml) validates prose, builds Doxygen and
uploads the accepted HTML through `upload-pages-artifact`. The deploy job consumes that artifact through
`deploy-pages`; it has no checkout or rebuild step. Only this job receives `pages: write` and `id-token: write`.

The temporary publication branch is `feature/libmemalloc-refactor`. On migration to `master`, update the push
branch and both artifact/deploy ref conditions as noted beside the deploy job. The
[workflow checker](../../scripts/check/workflows.lua) rejects inconsistent values across these locations;
run it after a migration edit. Pull requests validate only.
In repository Settings, select **Pages > Build and deployment > GitHub Actions** and allow the publication
branch in the `github-pages` environment deployment policy. These repository settings are separate from YAML.
No generated-content branch is required.

External HTTP links open a new browser tab with `noopener noreferrer`. Links within the publication root
retain normal same-tab navigation. Another project on the same GitHub Pages domain counts as external.
The click handler also covers links inserted after page load; mail links keep their native behavior.

<!-- EOF -->


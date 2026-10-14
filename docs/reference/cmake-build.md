<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# CMake build profiles and evidence

The root [CMakeLists.txt](../../CMakeLists.txt) coordinates modules under `cmake/`. CMake 3.28 is the
compatibility floor; policies are reviewed through 4.4 and the provisioned version is 4.4.3. The default
public language baseline remains C99. Set `CMAKE_C_STANDARD` for a newer dialect or use the language matrix.
CMake models C++98 and C++03 with the same C++98 standard property.
The current library is a distribution fixture, with no allocator implementation or production qualification.

<details>
<summary><strong>On this page</strong></summary>

- [Module ownership](#module-ownership).
- [Profiles and compiler policy](#profiles-and-compiler-policy).
- [Local commands](#local-commands).
- [Reconstruction and assurance](#reconstruction-and-assurance).
- [Portability and verification](#portability-and-verification).
- [Build reports and command outcomes](#build-reports-and-command-outcomes).

</details>

---

## Module ownership

| Module | Responsibility |
| --- | --- |
| [options.cmake](../../cmake/options.cmake) | Cache options, configuration defaults, target architecture checks and output paths. |
| [compiler-flags.cmake](../../cmake/compiler-flags.cmake) | Compiler probes, warnings, path mapping, stack defenses and configuration-specific flags. |
| [linker-flags.cmake](../../cmake/linker-flags.cmake) | Link probes, explicit instrumentation, IPO, executable PIE and format-specific defenses. |
| [targets.cmake](../../cmake/targets.cmake) | Library, public exports, optional executable tests, documentation and coverage targets. |
| [install.cmake](../../cmake/install.cmake) | Headers, libraries, package configuration, license and pkg-config metadata. |
| [LanguageProfiles.cmake](../../cmake/LanguageProfiles.cmake) | Optional language/ABI matrix: profile checks, C/C++ consumers, CTest cases and campaign inventories. |
| [LanguageDialects.cmake](../../cmake/LanguageDialects.cmake) | C++ dialect flags and expected feature-macro values used by the language matrix. |
| [compatibility.cmake](../../cmake/compatibility.cmake) | Explicit foreign-language consumers and their compile, link and execution boundaries. |
| [metadata.cmake](../../cmake/metadata.cmake) | Build and install compilation evidence for the selected configuration. |
| [write-metadata.cmake](../../cmake/write-metadata.cmake) | Filter and normalize compilation commands, then bind their digest to the binary. |
| [summary.cmake](../../cmake/summary.cmake) | Compiler/target summary and declared execution environment. |

`LMA_BUILD_MATRIX` enables `LanguageProfiles.cmake`; requested C++ profiles additionally load
`LanguageDialects.cmake`. Both modules serve the existing compatibility campaign. The dialect table
is separated from target creation for review, but CMake does not require two files. Removing either
without updating its caller breaks the corresponding campaign. The default C build does not enable
this matrix or require a C++ compiler.

Compiler policy applies privately to owned targets. Instrumented libraries expose their required sanitizer
or coverage link option to consumers; ordinary installed consumers receive no project warning policy.
Build artifacts stay in each build tree under `lib/<Config>` and `bin/<Config>`. Matrix campaigns retain
their existing artifact layout and evidence contract.

Consumers can include `<libmemalloc/mock.h>` with either `add_subdirectory` and `LMA::memalloc`, or an
installed `find_package(libmemalloc CONFIG REQUIRED)` package. Compilation metadata reads the outer build's
database and retains this project's object entries. Parent-project targets are excluded.
The relocatable pkg-config prefix supports `lib`, `lib64` and multiarch library directories. Explicit absolute
installation directories remain absolute.

---

## Profiles and compiler policy

[CMakePresets.json](../../CMakePresets.json) provides configure, build and test presets. Workflow presets
combine those steps for `debug`, `release`, `release-shared`, `relwithdebinfo`, `minsize`, `asan-ubsan`,
`coverage`, `gcc-analyzer` and `clang-release`. The `multi` preset configures Ninja Multi-Config; use
`multi-debug` or `multi-release` for its build and test steps. Native Windows presets require a prepared
compiler environment. The `clang-release` preset selects LLVM's linker and requires CMake 3.29 or newer.

| Control | Policy |
| --- | --- |
| Diagnostics | Broad GCC/Clang warning sets or MSVC `/W4`, with errors enabled for owned sources. Optional flags are compile-tested. |
| Debug | Debug information and frame pointers; no implicit sanitizers or stripping. |
| Release | Compiler's speed optimization, probed IPO for linked targets, hidden internal visibility and minimal debug metadata. |
| MinSizeRel | Compiler's size optimization with the same applicable release defenses. |
| RelWithDebInfo | Optimized code with debug information and frame pointers. |
| Hardening | Probed stack protection, zero initialization, flexible-array diagnostics and applicable platform controls. |
| ELF links | RELRO, immediate binding, non-executable stack, separate code, defined symbols and build IDs where supported. |
| MSVC links | ASLR, DEP, control-flow guard and deterministic link options where supported. |
| CPU controls | CET or AArch64 branch code generation from the target architecture; no `-march=native` or guessed QEMU detection. |
| Instrumentation | `LMA_SANITIZERS` or `LMA_ENABLE_COVERAGE`; incompatible requests fail and IPO is disabled. |

`LMA_IPO=AUTO` preserves portable static archives. `ON` requires a successful IPO probe and permits
compiler-specific archives; `OFF` disables it. `LMA_CET` and `LMA_AARCH64_HARDEN` accept `AUTO`, `ON` and
`OFF`. Explicit unsupported requests fail. These flags do not prove hardware or operating-system enforcement.

Release removes local symbols from ELF linked outputs while preserving public dynamic exports. Static archives
retain symbols needed by downstream linkers. Debug and instrumented builds retain diagnostic evidence.
This is symbol and metadata reduction, not complete obfuscation or confidentiality. No supported GCC, Clang
or MSVC profile can guarantee that a delivered binary conceals its algorithms. Conflicting optimization modes,
unsafe floating-point transformations and ABI-changing layout flags are excluded.

---

## Local commands

A direct preset workflow configures, builds and tests one tree:

```sh
cmake --workflow --preset release-shared
cmake --preset multi
cmake --build --preset multi-debug
ctest --preset multi-debug
```

The [Lua controller](../../scripts/build/local.lua) adds isolated reconstruction, installation checks and
retained evidence. Use the prepared Lua/luv environment or invoke the registered task through native Ansible:

```sh
ansible-playbook playbook.yml -e lma_task=build \
  -e '{"lma_arguments":["--profile=release","--os=linux","--arch=x86_64","--lld=dynamic"]}'
```

The equivalent domain command is:

```sh
lua scripts/build/local.lua --profile=release --os=linux --arch=x86_64 --lld=dynamic \
  --output=.cache/build/review-001
```

`--lld=static` selects a static library; `--lld=dynamic` selects a shared library. This requested CLI spelling
does not select LLVM LLD. Use `--linker=LLD` for that, or another CMake linker type supported by the toolchain.
Other controls are `--compiler`, `--toolchain`, `--jobs`, `--sanitizers`, `--coverage` and `--assurance`.
The Lua controller accepts `debug` and `release`; CMake presets expose the additional diagnostic profiles.

`LIBMEMALLOC_CMAKE` and `LIBMEMALLOC_LUA` select prepared executables. Without overrides the controller uses
`PATH`. Native Ansible uses the repository's prepared Lua runtime. Outputs must be fresh directories beneath
`.cache`; no existing evidence is overwritten. Compiler, Ninja, Lua/luv, Git, jq and SHA-256 tools are prerequisites.
The build command performs no dependency installation or remote assessment.

---

## Reconstruction and assurance

The controller snapshots declared source bytes twice, freezes `SOURCE_DATE_EPOCH`, disables compiler cache
launchers and builds in different paths. It runs native target tests, installs both builds, then compiles and
executes an external CMake consumer against each installed package. Cross builds require `--toolchain`;
configuration checks the target name and compiler architecture/OS macros. Cross-target execution is recorded
as unperformed by this controller, rather than counted as a passing native test.

Installed-tree comparison requires identical file sets, bytes, modes and sibling symlink targets. Timestamps
are outside that comparison scope. Each attempt retains configure/build commands, separate output streams,
CTest JUnit results, source/tool hashes and installation inventories. Failures retain partial evidence. Each child
has a three-minute deadline. This two-path experiment complements the separate
[reproducible-build campaign](../assurance/reproducible-builds.md); it does not replace its environment variations.

The local OpenSSF policy gate runs after reconstruction. The report lists every registered OpenSSF adapter
as unperformed or blocked, with its qualification boundary. `--assurance=local` can pass the scoped build while
`assurance.complete` and `product_qualified` remain false. `--assurance=full` fails because full qualification
is unavailable in this repository. It cannot silently downgrade to local success.

Use the existing [OpenSSF assessment workflow](../assurance/openssf.md) and signed release process for their
separate criteria, inventories and attestations. A successful compilation or byte comparison establishes
neither a badge level nor SLSA conformance. Production controls still require implementation, trusted builders,
security assessments and accountable human decisions.

---

## Portability and verification

The Lua controller currently runs on POSIX hosts. CMake retains GNU, Clang, AppleClang and MSVC branches;
platform support needs evidence from the declared host matrix. Linux tests do not establish Windows or macOS
qualification. CMake's cross-compilation and emulator declarations describe execution; virtualization guesses
do not disable requested instrumentation.

The [CMake integration test](../../tests/automation/build/cmake_test.lua) executes Debug and Release from one
multi-config build, requires each metadata database to contain only its selected configuration and rejects
invalid policies. The
[consumer integration test](../../tests/automation/build/consumer_test.lua) uses the same public source through
a parent project, relocated CMake packages and pkg-config in three library layouts, for static and shared builds.
The installed pkg-config file propagates `LMA_SHARED_LIBRARY` for shared builds, including Windows DLL imports.
The [Windows cross-link test](../../tests/automation/build/windows_pkgconfig_test.lua) checks the import symbol
and links a PE executable with MinGW; it does not execute Windows code. MinGW is provisioned by the CI rules group.
The [README regression](../../tests/automation/build/readme_test.lua) executes the documented configure, build
and CTest commands in an isolated directory. The
[tree comparison test](../../tests/automation/reproducible/trees_test.lua) challenges byte, permission, file-set
and symlink changes. Both run through the automation suite.

See [build quality and publication](build-quality.md) for numeric gates, compatibility consumers,
compilation metadata and the Pages artifact deployment policy.

---

## Build reports and command outcomes

Matrix reports use schema 2 and retain profile-relative CTest evidence. The
aggregator recomputes each test report digest, checks test names and semantic
output, and writes a failing summary even when a profile report is invalid.
Reports live under `.cache/ci/build-reports`; compilation trees live under
`.cache/ci/build-work`. CI uploads reports routinely and failed build trees as
separate diagnostic artifacts with shorter retention.

Commands retain their actual exit code or termination description. Configure,
build and test stages have separate deadlines, supervised through CMake on each
host. Compiler warning probes run in groups and split rejected groups until the
unsupported flags are identified; results remain local to each configuration.
The Zig toolchain disables linker-generated dependency files because the pinned
Zig driver rejects that linker option. Compiler dependency files and CMake target
dependencies remain enabled.

<!-- EOF -->


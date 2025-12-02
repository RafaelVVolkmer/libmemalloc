<!--
SPDX-FileCopyrightText: 2024-2025 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: MIT
-->

<a id="readme-top"></a>

<div align="center">

  [![Contributors][contributors-shield]][contributors-url]
  [![Forks][forks-shield]][forks-url]
  [![Stargazers][stars-shield]][stars-url]
  [![Issues][issues-shield]][issues-url]
  [![ULicense][license-shield]][license-url]
  [![LinkedIn][linkedin-shield]][linkedin-url]
  
</div>

##

<p align="center">
  <img src="readme/libmemalloc.svg" alt="libmemalloc logo" width="55%"/>
</p>

##

<div align="center">
  by: Rafael V. Volkmer - @RafaelVVolkmer - rafael.v.volkmer@gmail.com
</div>

---

# 🚀 Project Description

> 📚 Library documentation: **[libmemalloc Docs](https://rafaelvvolkmer.github.io/libmemalloc/)**

`libmemalloc` is a lightweight C library that replaces the standard allocator with a fully introspectable, high-performance heap manager.

Highlights:

- Multiple allocation strategies:
  - **First-Fit**, **Next-Fit**, **Best-Fit**
- Segregated free lists for (amortized) **O(1)** operations  
- Large-block optimization via `mmap(2)`  
- Dynamic heap growth/shrink using `sbrk(2)`  
- Optional background **mark-and-sweep GC**  
- Custom `MEM_memset` / `MEM_memcpy` with prefetch hints  
- Thread-safety via internal locking  
- Valgrind integration for detailed leak reports  
- Configurable logging and colored diagnostics  
- Exported API is versioned via a linker script (e.g. `MEMALLOC_2.0`), keeping the public surface tight and stable

The public API is intentionally compact and lives under the `MEM_` prefix:

- Core allocation:
  - `MEM_alloc`
  - `MEM_calloc`
  - `MEM_free`
  - `MEM_realloc`
- Custom memory operations:
  - `MEM_memcpy`
  - `MEM_memset`
- Strategy-specific helpers:
  - `MEM_allocFirstFit`
  - `MEM_allocNextFit`
  - `MEM_allocBestFit`

You link the `.a` or `.so`, include `libmemalloc.h`, and use these functions directly instead of `malloc`/`free` & friends.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

# 🗂️ Repository Layout

```text
libmemalloc/                              # Root of the project
├── .github/                                # GitHub configuration (issues, CI, contributing)
│   ├── ISSUE_TEMPLATE/                       # Predefined issue templates
│   │   ├── config.yml                          # Global config for issue templates
│   │   ├── bug_repot.md                        # Template for bug reports
│   │   ├── doc_issue.md                        # Template for documentation issues
│   │   ├── feature_request.md                  # Template for feature requests
│   │   └── question_help.md                    # Template for questions / support
│   ├── workflows/                            # GitHub Actions workflows
│   │   ├── c-build.yml                         # CI: build and test C project
│   │   ├── c-code-style-check.yml              # CI: clang-tidy / format / style checks
│   │   ├── docker-image.yml                    # CI: build and push Docker image
│   │   └── page.yml                            # CI: publish docs / GitHub Pages
│   ├── CONTRIBUTING.md                       # Guidelines for contributors
│   ├── CODEOWNERS                            # Default reviewers / owners by path
│   └── pull_request_template.md              # Boilerplate text for new PRs
├── bin/                                    # Build artifacts (libraries, test binaries)
│   ├── Release/                              # Release builds (optimized, hardened)
│   └── Debug/                                # Debug builds (symbols, extra checks)
├── build/                                  # CMake build tree (generated)
├── docs/                                   # Generated documentation site (Doxygen export)
├── doxygen/                                # Doxygen configuration & customization
│   ├── coverage_link/                        # Coverage badge/link integration
│   │   ├── coverage-link.js                    # JS to inject coverage link into docs
│   │   ├── coverage-pill.css                   # Styles for coverage pill/badge
│   │   └── footer.html                         # Custom footer fragment for Doxygen pages
│   ├── CMakeLists.txt                        # CMake rules to drive Doxygen
│   ├── Doxyfile.in                           # Template Doxyfile configured by CMake
│   └── doxygen.md                            # Extra doc pages / introduction
├── inc/                                    # Public and shared headers
│   ├── libmemalloc.h                         # Main public API (MEM_* allocator functions)
│   ├── logs.h                                # Logging macros / configuration
│   └── memalloc_util.h                       # Internal/shared utility declarations
├── LICENSES/                               # REUSE/SPDX-compatible license texts
│   └── MIT.txt                               # MIT license text used by the project
├── readme/                                 # Assets used in README / docs
│   └── libmemalloc.svg                       # Project logo
├── scripts/                                # Dev helper scripts
│   ├── bootstrap.sh                          # Environment / dependency check & setup
│   ├── build.sh                              # One-touch build + tests + docs (local/Docker)
│   ├── security_check.sh                     # ELF hardening / security audit for artifacts
│   └── style_check.sh                        # Style pipeline (clang-tidy/format, typos, reuse)
├── src/                                    # Library implementation
│   ├── CMakeLists.txt                        # Build rules for libmemalloc library
│   └── libmemalloc.c                         # Core allocator implementation
├── tests/                                  # Unit / integration tests
│   ├── CMakeLists.txt                        # Build rules for tests
│   └── test_*.c                              # Individual test sources (behaviour/coverage)
├── .clang-format                           # Source formatting rules
├── .clang-tidy                             # Static analysis configuration
├── .gitattributes                          # Git attributes (EOL, linguist, etc.)
├── .gitignore                              # Files/directories ignored by Git
├── CMakeLists.txt                          # Top-level CMake entry point
├── CMakePresets.json                       # Saved CMake configure/build presets
├── Dockerfile                              # Containerized build/test environment
├── .dockerignore                           # Files ignored when building Docker images
├── REUSE.toml                              # REUSE / SPDX compliance configuration
├── typos.toml                              # Configuration for typos (spell checker)
├── README.md                               # Main project documentation
├── LICENSE                                 # Project license reference
├── CHANGELOG.md                            # Human-readable change log
├── SECURITY.md                             # Security policy and reporting instructions
└── CODE_OF_CONDUCT.md                      # Community code of conduct
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

# 🧭 Recommended Workflow

Typical flow to work with `libmemalloc`:

1. **Check and prepare the environment** (toolchain, linters, optional tools)  
2. **Build the library**
   - locally (default), or
   - via Docker (if you prefer not to install the toolchain)  
3. **Run style checks** (optional but recommended)  
4. **Run security / hardening checks** on the produced binaries  

## 1. Clone the repository

```bash
git clone https://github.com/RafaelVVolkmer/libmemalloc.git libmemalloc
cd libmemalloc
```

## 2. Check dependencies

Use `bootstrap.sh` to detect the tools used in the project:

```bash
chmod +x scripts/*.sh      # first time only

# Only check tools / versions, do not install anything
./scripts/bootstrap.sh --check-only
```

`bootstrap.sh` will:

- detect OS and package manager,
- probe versions of `cmake`, `gcc`/`clang`, `gcov`, `valgrind`, `docker`, etc.,
- check for Rust toolchain (`rustc`, `cargo`),
- check for optional tools:
  - `typos` (spell checker),
  - `reuse` (SPDX/REUSE compliance),
  - `gh` (GitHub CLI).

In a dev machine you control, you can run it **without** `--check-only` to let it attempt installing missing tools (when supported).

## 3. Build the project

All builds are driven by `scripts/build.sh`.

### 3.1 Local build (default)

```bash
# Release build (default)
./scripts/build.sh release

# Debug build
./scripts/build.sh debug
```

In local mode, `build.sh`:

- configures CMake under `./build/`,
- builds the library and tests,
- runs the test suite via `ctest`,
- for **Release**:
  - builds the Doxygen documentation,
  - moves the generated site into `./docs/`.

Resulting binaries:

- `./bin/Release/` – Release artifacts (library + tests)  
- `./bin/Debug/` – Debug artifacts  

### 3.2 Docker build (no local toolchain)

If you prefer not to install compilers / CMake locally:

```bash
# Release build inside Docker
./scripts/build.sh --docker release

# Debug build inside Docker
./scripts/build.sh --docker debug
```

In Docker mode, `build.sh`:

- builds a Docker image using the project `Dockerfile`,
- uses `docker buildx` to allow multi-arch builds (`--platform`),
- runs the CMake targets inside the container,
- copies artifacts back to your working tree:
  - libraries to `./bin/<mode>/`,
  - docs (Release) to `./docs/`.

Example with explicit platform:

```bash
./scripts/build.sh --docker --platform linux/amd64 release
```

### 3.3 Cleaning

```bash
./scripts/build.sh --clear
```

This removes `bin/`, `build/`, `docs/` and `doxygen/doxygen-awesome`, giving you a clean slate.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

# 🛠️ Helper Scripts

## `scripts/bootstrap.sh`

Environment / dependency helper. It:

- detects OS and package manager,
- checks for tool versions (CMake, compilers, gcov, Docker, Rust, etc.),
- can optionally try to install missing tools when supported.

Typical usage:

- **Check-only mode** (safe on any machine):

```bash
./scripts/bootstrap.sh --check-only
```

- **Install mode** (on a dev box you control):

```bash
./scripts/bootstrap.sh
```

## `scripts/build.sh`

One-touch build / test / docs helper.

Capabilities:

- Local or Docker build
- **Release** or **Debug** modes
- Runs `ctest`
- Generates Doxygen docs (Release only)
- Optional verbose mode for Doxygen output

Examples:

- Local Release (default path):

```bash
./scripts/build.sh release
```

- Local Debug:

```bash
./scripts/build.sh debug
```

- Docker Release:

```bash
./scripts/build.sh --docker release
```

- Docker Debug:

```bash
./scripts/build.sh --docker debug
```

- Clear build artifacts:

```bash
./scripts/build.sh --clear
```

## `scripts/style_check.sh`

Style and consistency pipeline. It runs:

- `clang-tidy` (according to `.clang-tidy`),
- `clang-format` (`--dry-run --Werror`, using `.clang-format`),
- `typos` (spell checker via `typos.toml`),
- `reuse lint` (SPDX/REUSE compliance).

Usage:

```bash
./scripts/style_check.sh
```

The script fails if:

- any required tool is missing, or  
- any of the checks report issues.

It is a good candidate for CI or pre-push hooks.

## `scripts/security_check.sh`

ELF hardening / security audit helper. It can inspect multiple targets in one go, for example:

```bash
./scripts/security_check.sh ./bin/Release/libmemalloc.a ./bin/Release/libmemalloc.so
```

Main checks include:

- **PIE** (Position Independent Executable),
- **RELRO** (`-z relro`, `-z now`),
- **NX** (`GNU_STACK` non-executable),
- **Stack protector** (`__stack_chk_*`),
- **FORTIFY_SOURCE** (`*_chk` symbols),
- **RPATH / RUNPATH**,
- **TEXTREL**,
- **Build-ID**,
- **CET / BTI** (when applicable),
- **W^X** (no RWX segments),
- SONAME presence (shared libraries),
- excessive exports,
- references to banned libc APIs (`gets`, `strcpy`, `sprintf`, ...),
- presence of debug sections in release builds.

For `.a` and `.so` targets, the script also builds a small **FORTIFY probe executable** that links against the library and audits both the probe and the library itself.

Extra options:

- Verbose + strict (treat WARN as FAIL):

```bash
./scripts/security_check.sh --verbose --strict ./bin/Release/libmemalloc.so
```

At the end it prints a summary, e.g.:

    Summary: 18 PASS, 2 WARN, 0 FAIL

In CI, `--strict` is recommended.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

# 📦 Using libmemalloc in Your Code

Below is a minimal example of using the new API (`MEM_alloc` / `MEM_free` etc.).  
There is **no explicit allocator init** – the library manages its internal state.

C example:

```C
    #include <stdio.h>
    #include "libmemalloc.h"

    int main(void)
    {
        /* Allocate an array of 10 ints with libmemalloc. */
        int *values = MEM_alloc(10 * sizeof *values);
        if (values == NULL) {
            fprintf(stderr, "allocation failed\n");
            return 1;
        }

        /* Use the memory as usual. */
        for (int i = 0; i < 10; ++i) {
            values[i] = i * 42;
        }

        printf("values[3] = %d\n", values[3]);

        /* Reallocate to a larger buffer. */
        int *more = MEM_realloc(values, 20 * sizeof *more);
        if (more == NULL) {
            fprintf(stderr, "realloc failed\n");
            MEM_free(values);
            return 1;
        }

        /* Clean up. */
        MEM_free(more);

        return 0;
    }
```

Linking (gcc/clang):

```bash
    gcc -Iinc -o my_app my_app.c -Lbin/Release -lmemalloc
```

The exact semantics and configuration options of the API are documented in the Doxygen site linked at the top of this README.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

# 💻 Tech Stack and Environment

| **Category**              | **Technologies and Tools**                                                                                                                                                                                                 |
|---------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Programming Languages** | C                                                                                                                                                                                                                           |
| **Build System**          | CMake                                                                                                                                                                                                                       |
| **Version Control**       | Git, GitHub                                                                                                                                                                                                                |
| **Documentation**         | Doxygen, Markdown                                                                                                                                                                                                          |
| **Support Tools**         | Docker                                                                                                                                                                                                                     |
| **Operating System**      | Ubuntu (tested), generic UNIX-like environments                                                                                                                                                                            |
| **Editor / IDE**          | Neovim (author’s setup), but any C toolchain-friendly editor works                                                                                                                                                         |

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

# 📚 References

| Title                                                                      | Author / Year               |
|----------------------------------------------------------------------------|-----------------------------|
| Understanding and Using C Pointers: Core Techniques for Memory Management  | Richard M. Reese, 2013      |
| The Garbage Collection Handbook: The Art of Automatic Memory Management    | Anthony Hosking et al., 2011|
| C++ Pointers and Dynamic Memory Management                                 | Michael C. Daconta, 1993    |
| Efficient Memory Programming                                               | David Loshin, 1999          |
| Memory Management                                                          | Bill Blunden, 2002          |

<p align="right">(<a href="#readme-top">back to top</a>)</p>

[maintainability-shield]: https://qlty.sh/gh/RafaelVVolkmer/projects/libmemalloc/badges/maintainability.svg?style=flat-square
[maintainability-url]:   https://qlty.sh/gh/RafaelVVolkmer/projects/libmemalloc
[stars-shield]: https://img.shields.io/github/stars/RafaelVVolkmer/libmemalloc.svg?style=flat-square
[stars-url]: https://github.com/RafaelVVolkmer/libmemalloc/stargazers
[contributors-shield]: https://img.shields.io/github/contributors/RafaelVVolkmer/libmemalloc.svg?style=flat-square
[contributors-url]: https://github.com/RafaelVVolkmer/libmemalloc/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/RafaelVVolkmer/libmemalloc.svg?style=flat-square
[forks-url]: https://github.com/RafaelVVolkmer/libmemalloc/network/members
[issues-shield]: https://img.shields.io/github/issues/RafaelVVolkmer/libmemalloc.svg?style=flat-square
[issues-url]: https://github.com/RafaelVVolkmer/libmemalloc/issues
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=flat-square&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/rafaelvvolkmer
[license-shield]: https://img.shields.io/github/license/RafaelVVolkmer/libmemalloc.svg?style=flat-square
[license-url]: https://github.com/RafaelVVolkmer/libmemalloc/blob/main/LICENSE.txt

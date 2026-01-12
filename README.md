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
  [![CI][ci-all-shield]][ci-all-url]
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
- Exported API is versioned via a linker script (e.g. `MEMALLOC_3.5`), keeping the public surface tight and stable

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

# 🪝 Local Git hooks

This repository ships a set of local Git hooks under `.githooks/` to keep
commits, style and security checks consistent during development.

Enabling them is a one-time setup per clone:

```bash
# 1) Make sure all hook scripts are executable
chmod +x .githooks/*

# 2) Tell Git to use .githooks/ as the hooks directory for this repo
git config core.hooksPath .githooks
```

From that point on, Git will automatically run the hooks in .githooks/ instead
of .git/hooks/

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

# 💻 Tech Stack and Environment

| **Category**              | **Technologies and Tools**                                                                                                                                                                                                 |
|---------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Programming Languages** |  [![C](https://img.shields.io/badge/C-white?style=for-the-badge&logo=c&logoColor=%23A8B9CC&labelColor=rgba(0,0,0,0)&color=rgba(0,0,0,0))](https://en.cppreference.com/w/c/language.html) |
| **Build System**          | [![CMake](https://img.shields.io/badge/CMake-white?style=for-the-badge&logo=cmake&logoColor=%23064F8C&labelColor=rgba(0,0,0,0)&color=rgba(0,0,0,0)&cacheSeconds=3600)](https://cmake.org) |
| **Version Control**       | [![Git](https://img.shields.io/badge/Git-white?style=for-the-badge&logo=git&logoColor=%23F05032&logoSize=32&labelColor=rgba(0,0,0,0)&color=rgba(0,0,0,0)&cacheSeconds=3600)](https://git-scm.com) [![GitHub](https://img.shields.io/badge/GitHub-white?style=for-the-badge&logo=github&logoColor=%23181717&logoSize=32&labelColor=rgba(0,0,0,0)&color=rgba(0,0,0,0)&cacheSeconds=3600)](https://github.com) |
| **Documentation**         | [![Markdown](https://img.shields.io/badge/Markdown-white.svg?style=for-the-badge&logo=markdown&logoColor=%23000000&logoSize=32&labelColor=rgba(0,0,0,0)&color=rgba(0,0,0,0)&cacheSeconds=3600)](https://www.markdownguide.org) [![Doxygen](https://img.shields.io/badge/Doxygen-white?style=for-the-badge&logo=doxygen&logoColor=%232C4AA8&logoSize=32&labelColor=rgba(0,0,0,0)&color=rgba(0,0,0,0)&cacheSeconds=3600)](https://doxygen.nl) |
| **Support Tools**         | [![Docker](https://img.shields.io/badge/Docker-white?style=for-the-badge&logo=docker&logoColor=%232496ED&logoSize=32&labelColor=rgba(0,0,0,0)&color=rgba(0,0,0,0)&cacheSeconds=3600)](https://www.docker.com) |
| **Operating System**      |  [![Arch Linux](https://img.shields.io/badge/Arch_Linux-white?style=for-the-badge&logo=archlinux&logoColor=%231793D1&logoSize=32&labelColor=rgba(0,0,0,0)&color=rgba(0,0,0,0)&cacheSeconds=3600)](https://archlinux.org) |
| **Editor / IDE**          | [![Neovim](https://img.shields.io/badge/Neovim-white?style=for-the-badge&logo=neovim&logoColor=%2357A143&logoSize=32&labelColor=rgba(0,0,0,0)&color=rgba(0,0,0,0)&cacheSeconds=3600)](https://neovim.io) |

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
| Modern Operating Systems                                                   | Andrew S. Tanenbaum, 2014   |

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

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
[ci-all-shield]: https://img.shields.io/github/check-runs/RafaelVVolkmer/libmemalloc/develop?style=flat-square&logo=github&label=CI
[ci-all-url]: https://github.com/RafaelVVolkmer/libmemalloc/actions
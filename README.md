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

##
# - Project Description

[libmemalloc Documentation](https://rafaelvvolkmer.github.io/libmemalloc/)

`libmemalloc` is a lightweight C library that replaces the standard allocator with a fully introspectable, high-performance heap manager. It features multiple allocation strategies (First-Fit, Next-Fit, Best-Fit), segregated free lists for O(1) operations, large-block optimization via `mmap`, and dynamic heap growth/shrinkage using `sbrk`. Advanced capabilities include background mark-and-sweep garbage collection, custom `MEM_memset`/`MEM_memcpy` accelerated by prefetch hints, thread safety with internal locking, Valgrind integration for detailed leak reports, and configurable logging levels. Simply link against the provided `.a` or `.so`, include `libmemalloc.h`, and swap your `malloc`/`free` calls for `MEM_*` APIs to transform memory management into a robust, self-healing subsystem.


<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

# - Repository tree

```python
/libmemalloc
├── /bin
│   ├── libmemalloc.a
│   └── libmemalloc.so
├── /inc
│   ├── logs.h
│   └── libmemalloc.h
├── /src
│   ├── CMakeLists.txt
│   └── libmemalloc.c
├── /test
│   └── tests.c
├── /readme
│    └── libmemalloc.svg
├── Dockerfile
├── .dockerignore
├── build.sh
├── CMakeLists.txt
├── .gitattributes
├── .gitignore
├── LICENSE
└── README.md
```
The libmemalloc repository is organized to keep everything modular, discoverable and easy to extend:

* **Public API vs. Implementation**

  All user-facing headers live in `inc/` (e.g. `libmemalloc.h`, `logs.h`), while the actual allocator logic and build rules for that module reside under `src/`. This clear separation makes it trivial to browse the API without wading through implementation details.

* **Build Artifacts**

  Compiled outputs (both static `.a` and shared `.so` libraries) are deposited in `bin/`, preventing accidental commits of large binaries and keeping the source tree clean.

* **Test Suite**
  
  The `test/` directory contains unit- and integration-tests (`tests.c`) that exercise every allocation strategy and GC sweep.  These tests are wired into CTest and invoked automatically by `build.sh` for both Debug and Release modes.

* **Documentation Assets**
  
  Visual assets—project logo, diagrams, screenshots—are housed in `readme/`.  This keeps non-code files out of the root and lets you reference them consistently in your Markdown documentation.

* **Top-Level Build Orchestration**

  * **`CMakeLists.txt`** at the project root defines cross-platform build targets, dependency checks, and install rules.
  * **`build.sh`** wraps CMake and CTest in a simple Bash interface (Release vs. Debug).  A `chmod +x` step ensures it runs everywhere.

* **Containerized Builds**

  * **`Dockerfile`** uses a multi-stage build: an Alpine-based builder with GCC 13.3, CMake and Valgrind, then a minimal runtime image.
  * **`.dockerignore`** excludes temporary files, build folders and VCS metadata to speed up Docker builds and reduce image size.

* **Version Control Configuration**

  * **`.gitignore`** filters out binaries, build directories, editor backups and OS-specific cruft.
  * **`.gitattributes`** enforces consistent line endings, export settings and diff behaviors across platforms.

* **License & Contribution Guidance**

  * **`LICENSE`** contains the full text of your chosen open-source license.
  * **`README.md`** doubles as a quickstart guide, covering build instructions, usage examples, directory layout and contribution pointers (e.g. code style conventions, how to run tests).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

# - Build and Use

### Clone the repository

```bash
# Clone the project and enter the folder
git clone https://github.com/RafaelVVolkmer/libmemalloc.git libmemalloc
cd libmemalloc
```

### Local build

```bash
# Make the build script executable
chmod +x build.sh

# Build in Release mode (default)
./build.sh release

# Or build in Debug mode
./build.sh debug
```

### Build with Docker

```bash
# Release (latest)
docker build \
  --platform linux/amd64 \
  --file Dockerfile \
  --build-arg BUILD_MODE=Release \
  --target runtime \
  -t libmemalloc:latest \
  .

# Debug
docker build \
  --platform linux/amd64 \
  --file Dockerfile \
  --build-arg BUILD_MODE=Debug \
  --target runtime \
  -t libmemalloc:debug \
  .
```

### Export Libraries (.a/.so)

```bash
# Release (latest)
docker build \
  --platform linux/amd64 \
  --file Dockerfile \
  --build-arg BUILD_MODE=Release \
  --target export \
  --output ./artifacts/release \
  .

# Debug
docker build \
  --platform linux/amd64 \
  --file Dockerfile \
  --build-arg BUILD_MODE=Debug \
  --target export \
  --output ./artifacts/debug \
  .
```

###  Container Run

```bash
# Release (latest)
docker run --rm libmemalloc:latest

# Debug
docker run --rm libmemalloc:debug
```

<p align="right">(<a href="#readme-top">Back to Top</a>)</p>

---

# - Tech Stack and Environment Settings

| **Category**               | **Technologies and Tools**                                                                                                                                                                                                                                  |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Programming Languages**  | ![C](https://img.shields.io/badge/c-%2300599C.svg?style=for-the-badge&logo=c&logoColor=white)                                                                                                                                                                |
| **Build System**           | ![CMake](https://img.shields.io/badge/CMake-%23008FBA.svg?style=for-the-badge&logo=cmake&logoColor=white)                                                                                                                                                      |
| **Version Control**        | ![Git](https://img.shields.io/badge/git-%23F05033.svg?style=for-the-badge&logo=git&logoColor=white) ![GitHub](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)                                            |
| **Documentation**          | ![Doxygen](https://img.shields.io/badge/doxygen-2C4AA8?style=for-the-badge&logo=doxygen&logoColor=white) ![Markdown](https://img.shields.io/badge/markdown-%23000000.svg?style=for-the-badge&logo=markdown&logoColor=white)                                       |
| **Support Tools**          | ![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)                                                                                                                                                    |
| **Operating System**       | ![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)                                                                                                                                                           |
| **IDE**                    | ![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)                                                                                                                                                     |

<p align="right">(<a href="#readme-top">Back to Top</a>)</p>

---

# - References

| Title                                                                   | Author / Year                  |
| ------------------------------------------------------------------------ | ---------------------------- |
| **Understanding and Using C Pointers: Core Techniques for Memory Management** | by: Richard M. Reese, 2013  |
| **The Garbage Collection Handbook: The art of automatic memory management**    | by: Anthony Hosking, 2011   |
| **C++ pointers and dynamic memory management**                           | by: Michael C. Daconta, 1993 |
| **Efficient memory programming**                                        | by: David Loshin, 1999       |
| **Memory Management**                                                   | by: Bill Blunden, 2002       |

<p align="right">(<a href="#readme-top">back to top</a>)</p>

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

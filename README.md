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

**`v4.0.00`**

`libmemalloc` is a lightweight, plug-and-play C library that gives you complete control and visibility over your program’s heap.  In addition to offering multiple allocation strategies and real-time tracking, it includes the following advanced features:

* **Architecture-specific stack allocation**
  
  A custom `alloca-style` mechanism captures the current thread’s stack bounds and lets you carve out stack-based allocations when low-latency, automatic cleanup is desired.

* **Background garbage collection (mark & sweep)**
  
  A dedicated GC thread periodically scans both the heap and mmap’d regions, marks live blocks by walking the stack, then reclaims unreachable blocks—no manual free required if you enable GC.

* **Multiple allocation strategies**
  
  First-Fit, Next-Fit (with “last allocated” pointer), and Best-Fit algorithms let you tune for allocation speed, fragmentation, or memory footprint on a per-call basis.

* **Segregated free lists & size classes**
  
  Maintains a configurable number of size “bins” (default 10, each 128 B) for O(1) inserts/removals and reduced fragmentation.

* **Large-block optimization via `mmap`**
  
  Requests ≥ 128 KiB bypass `sbrk` in favor of `mmap`, reducing heap fragmentation for big allocations and automatically tracking them in a separate list.

* **Dynamic heap growth & shrinkage**
  
  Uses `sbrk` under the hood to expand or contract the program break, automatically returning memory to the OS when the top chunk is freed.

* **High-performance memory ops**
  
  Custom `MEM_memset` and `MEM_memcpy` implementations use alignment checks, 64-bit prefetch‐aligned writes, and `__builtin_prefetch` hints for maximum throughput.

* **Thread-safety & Valgrind integration**

  * Internal locks around every allocation/free call ensure safe use in multi-threaded programs.
  * When built under Valgrind, creates and annotates a MemPool for fine-grained leak reporting.

* **Configurable logging & diagnostics**
  
  Compile-time `LOG_LEVEL` switches control verbosity (ERROR, WARN, INFO, DEBUG).  The API can dump a live allocation map, query individual blocks by address or call site (file, line, variable name), and produce fragmentation or leak reports on demand.

* **Seamless integration**
  
  Link against a static (`.a`) or shared (`.so`) library; include `libmemalloc.h` and replace your `malloc`, `free`, etc., calls with the `MEM_alloc*` and `MEM_free` wrappers—no source changes required.

With this feature set, `libmemalloc` not only replaces your standard allocator, but also transforms it into a fully introspectable, self-healing subsystem—ideal for debugging leaks, hardening safety-critical systems, or squeezing every last cycle out of your memory operations.


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
# Build the Docker image (defaults to Release)
docker build --platform linux/amd64 -t libmemalloc:latest .

# To build a Debug image:
docker build \
  --platform linux/amd64 \
  --build-arg BUILD_MODE=Debug \
  -t libmemalloc:debug .
```

### Run the Docker container

```bash
# Run the default Release container
docker run --rm libmemalloc:latest

# Or run the Debug container
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

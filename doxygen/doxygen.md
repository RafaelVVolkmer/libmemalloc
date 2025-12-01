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

---

<div align="center">
  <img src="libmemalloc.svg" alt="libmemalloc logo" width="55%"/>
</div>

---

<div align="center">
  by: Rafael V. Volkmer - @RafaelVVolkmer - rafael.v.volkmer@gmail.com
</div>

---

# - Library Description

libmemalloc is a comprehensive, drop-in C memory management library that elevates your application’s heap to a fully introspectable, high-performance subsystem. It offers three tunable allocation strategies—First-Fit, Next-Fit (with optional “last allocated” pointer tracking), and Best-Fit—enabling you to balance speed, fragmentation, or memory footprint on each call. Small allocations are serviced via segregated free lists organized into configurable size classes for constant-time inserts and removals, while large requests (≥ 128 KiB) automatically bypass sbrk in favor of mmap to minimize fragmentation and leverage OS paging efficiencies. An optional background mark-and-sweep garbage collector can be activated to transparently reclaim unreachable blocks, eliminating manual free() calls in scenarios where automatic cleanup is preferred. Every block is protected by magic numbers and footer canaries to detect header corruption or buffer overflows at runtime. Internal locking guarantees thread safety in multithreaded environments, and seamless Valgrind integration annotates a dedicated MemPool for precise leak and fragmentation reporting. With configurable log verbosity (ERROR, WARN, INFO, DEBUG), live allocation maps, fragmentation metrics, and on-demand diagnostics, libmemalloc gives you unparalleled visibility into your program’s memory behavior. Integration couldn’t be simpler: link against the provided static (.a) or shared (.so) library, include libmemalloc.h, and replace your standard malloc/free calls with the intuitive MEM_* API to transform your heap—no other source modifications required.

---
# - C Example

```c
#include "libmemalloc.h"

int main(void)
{
  int ret = EXIT_SUCESS;

  mem_allocator_t allocator;

  ret = MEM_allocatorInit(&allocator);
  if (ret != EXIT_SUCESS)
    return ret;

  void *buf1 = MEM_allocMallocFirstFit(&allocator, 1024, "buffer1");
  if (!buf1)
    return ret;

  MEM_allocFree(&allocator, buf1, "buffer1");

  void *buf2 = MEM_allocMallocBestFit(&allocator, 2048, "buffer2");
  if (!buf2)
    return ret;

  MEM_allocFree(&allocator, buf2, "buffer2");

  void *buf3 = MEM_allocMallocNextFit(&allocator, 512, "buffer3");
  if (!buf3)
    return ret;

  MEM_allocFree(&allocator, buf3, "buffer3");

  MEM_enableGc(&allocator);

  void *gc_buf = MEM_allocCalloc(&allocator, 4096, "gc_buffer", FIRST_FIT);
  gc_buff = NULL;

  MEM_disableGc(&allocator);

  return ret;
}
```
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

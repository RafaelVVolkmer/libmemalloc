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

# 🚀 Library Description

`libmemalloc` is a focused, drop-in replacement for the standard C allocator that turns your heap into a high-visibility, high-reliability subsystem.

Instead of opaque `malloc`/`free` calls, you get a small, well-defined API under the `MEM_` prefix:

- Core allocation:
  - `MEM_alloc`
  - `MEM_calloc`
  - `MEM_realloc`
  - `MEM_free`
- Custom memory operations:
  - `MEM_memcpy`
  - `MEM_memset`
- Strategy-specific helpers:
  - `MEM_allocFirstFit`
  - `MEM_allocNextFit`
  - `MEM_allocBestFit`

Under the hood, the allocator uses:

- **Segregated free lists** organized into size classes for (amortized) O(1) insert/remove.
- Automatic promotion of large blocks to **`mmap(2)`** regions to reduce fragmentation.
- Dynamic heap growth / shrink using **`sbrk(2)`** for regular blocks.
- Optional background **mark-and-sweep GC** mode to reclaim unreachable memory in GC-friendly workloads.
- **Magic values and canaries** around each block to detect overruns and header corruption.
- **Internal locking** to remain safe in multithreaded programs.
- Integration points for tools like Valgrind and external profilers.

The public surface is kept small and stable, and the shared library is exported through a linker version script (`MEMALLOC_3.5`) so that only the intended symbols are visible to consumers.

To use it, you simply link the `.a` or `.so`, include `libmemalloc.h`, and swap your `malloc`/`free` calls for `MEM_*` equivalents.

---

# 📦 C Example

A minimal example using the current public API (no explicit allocator struct or init):

```c
#include <stdio.h>
#include <string.h>         /* only for printf formats, not memcpy/memset */
#include "libmemalloc.h"    /* provides MEM_* declarations */

int main(void)
{
    /* 1) Default allocation using MEM_alloc */
    int *values = MEM_alloc(10 * sizeof *values);
    if (values == NULL) {
        fprintf(stderr, "MEM_alloc failed\n");
        return 1;
    }

    /* 2) Zero-initialized array with MEM_calloc */
    int *zeros = MEM_calloc(5, sizeof *zeros);
    if (zeros == NULL) {
        fprintf(stderr, "MEM_calloc failed\n");
        MEM_free(values);
        return 1;
    }

    /* 3) Initialize memory using MEM_memset */
    /*    Set all 'values' entries to 42 in two steps:
     *    - fill with zero
     *    - then write the contents explicitly
     */
    MEM_memset(values, 0, 10 * sizeof *values);
    for (int i = 0; i < 10; ++i)
        values[i] = 42 + i;

    /* 4) Copy memory with MEM_memcpy */
    int *copy = MEM_alloc(10 * sizeof *copy);
    if (copy == NULL) {
        fprintf(stderr, "MEM_alloc for copy failed\n");
        MEM_free(zeros);
        MEM_free(values);
        return 1;
    }
    MEM_memcpy(copy, values, 10 * sizeof *copy);

    printf("copy[3] = %d\n", copy[3]);

    /* 5) Strategy-specific allocations */
    char *buf_ff = MEM_allocFirstFit(1024);   /* fast, simple placement */
    char *buf_nf = MEM_allocNextFit(512);     /* reuse last search position */
    char *buf_bf = MEM_allocBestFit(2048);    /* reduce fragmentation */

    if (!buf_ff || !buf_nf || !buf_bf) {
        fprintf(stderr, "strategy-specific allocation failed\n");
        MEM_free(copy);
        MEM_free(zeros);
        MEM_free(values);
        MEM_free(buf_ff);
        MEM_free(buf_nf);
        MEM_free(buf_bf);
        return 1;
    }

    /* Use MEM_memset on these buffers as well */
    MEM_memset(buf_ff, 0xAA, 1024);
    MEM_memset(buf_nf, 0xBB, 512);
    MEM_memset(buf_bf, 0xCC, 2048);

    /* 6) Resize an allocation with MEM_realloc */
    char *buf_bigger = MEM_realloc(buf_bf, 4096);
    if (buf_bigger == NULL) {
        fprintf(stderr, "MEM_realloc failed, keeping original buffer\n");
        /* In this case buf_bf is still valid and must be freed */
        MEM_free(buf_bf);
    } else {
        buf_bf = buf_bigger;
    }

    /* 7) Clean up everything with MEM_free */
    MEM_free(buf_ff);
    MEM_free(buf_nf);
    MEM_free(buf_bf);
    MEM_free(copy);
    MEM_free(zeros);
    MEM_free(values);

    return 0;
}
```
Typical compile/link invocation (adjust include/library paths to your tree):

```Bash
gcc -Iinc -o example example.c -Lbin/Release -lmemalloc
```

This example touches all nine symbols from the version script:

`MEM_alloc` / `MEM_calloc` / `MEM_realloc` / `MEM_free`

`MEM_memcpy` / `MEM_memset`

`MEM_allocFirstFit` / `MEM_allocNextFit` / `MEM_allocBestFit`

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

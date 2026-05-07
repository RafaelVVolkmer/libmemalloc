<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->
<div align="center">

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![License][license-shield]][license-url]
[![Release][release-shield]][release-url]

</div>

---

<div align="center">

<img
    src="./readme/images/libmemalloc_logo.svg"
    alt="libmemalloc logo"
    width="50%"
  />

  <p>
    <strong>Proving that dynamic memory allocation is not that kind of magic.</strong>
  </p>

  <p>
    Designed as research-friendly systems software for low-level memory-management
    experiments, emphasizing security, portability across multiple systems and
    architectures, and high efficiency.
  </p>

  <p>
    <a href="https://www.linkedin.com/in/rafaelvvolkmer">Rafael V. Volkmer</a>
    ·
    <a href="mailto:rafael.v.volkmer@gmail.com">rafael.v.volkmer@gmail.com</a>
  </p>

</div>

---

## Status

> [!IMPORTANT]
> **WIP Refactor:** this repository is currently being reorganized.
> Public APIs, internal layout, documentation, and build workflows may still change.

---

## Overview

`libmemalloc` is a portable, inspectable, and research-oriented memory
management library for C projects, designed to support both low-level systems
software and application-layer workloads.

It is built on decades of allocator and garbage-collection research, combining
modern security-oriented allocation techniques with the strong foundations of
classic memory-management literature. The library aims to provide configurable
heap strategies, strong portability across systems and architectures, advanced
logging and debugging systems, compliance-aware metadata, intuitive
documentation, and efficient allocation behavior suitable for comparison with
modern allocators.

Optional garbage collector support is part of the broader runtime architecture,
allowing projects to choose between manual allocation strategies and automatic
memory-management models when appropriate.

The project is being shaped around a set of design goals aligned with its
research-oriented memory-management architecture:

| Area                            | Goal                                                                                                                                                                                                                                                          |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Research Foundation**         | Build allocator and GC decisions on decades of memory-management literature, combining modern techniques with strong classic foundations.                                                                                                                     |
| **Portability**                 | Isolate compiler, platform, ABI, operating-system, and architecture details behind explicit environment and compatibility layers.                                                                                                                             |
| **Security**                    | Support modern allocation-hardening techniques, defensive APIs, deterministic diagnostics, and auditable metadata.                                                                                                                                            |
| **Efficiency**                  | Prioritize fast, cache-conscious, low-overhead algorithms for allocation, deallocation, heap management, diagnostics, and runtime services, while keeping the allocator suitable for benchmarking and optimization against modern general-purpose allocators. |
| **Configurability**             | Support selectable heap strategies, benchmarking-oriented development, and optional garbage collector integration.                                                                                                                                            |
| **Diagnostics & Documentation** | Provide structured logging, debugging support, generated API documentation, implementation notes, and project metadata that make the library easier to inspect, test, audit, and maintain.     |

---

## Repository Stats

| Metric              | Badge                                                    | Meaning                                                       |
| ------------------- | -------------------------------------------------------- | ------------------------------------------------------------- |
| **Repository Size** | [![Repo Size][repo-size-shield]][repo-size-url]          | Shows the total repository size reported by GitHub.           |
| **Code Size**       | [![Code Size][code-size-shield]][code-size-url]          | Shows the total source-code size reported by GitHub Linguist. |
| **Top Language**    | [![Top Language][top-language-shield]][top-language-url] | Shows the dominant language detected in the repository.       |

---

## Repository Tree

```text
WIP
```

---

## Getting Started

> [!NOTE]
> Build and installation instructions will be finalized after the current
> project-wide cleanup stabilizes the directory layout and public API.

For now, clone the repository and inspect the active development branch:

```bash
git clone https://github.com/RafaelVVolkmer/libmemalloc.git
cd libmemalloc
```

</div>

---
<!-- ======================================================================= -->
<!-- Project Badges                                                         -->
<!-- ======================================================================= -->

[contributors-shield]: https://img.shields.io/github/contributors/RafaelVVolkmer/libmemalloc.svg?style=flat-square&logo=changedetection&logoColor=white&label=Contributors&labelColor=1F2328&color=2F81F7
[contributors-url]: https://github.com/RafaelVVolkmer/libmemalloc/graphs/contributors

[forks-shield]: https://img.shields.io/github/forks/RafaelVVolkmer/libmemalloc.svg?style=flat-square&logo=forgejo&logoColor=white&label=Forks&labelColor=1F2328&color=F78166
[forks-url]: https://github.com/RafaelVVolkmer/libmemalloc/network/members

[stars-shield]: https://img.shields.io/github/stars/RafaelVVolkmer/libmemalloc.svg?style=flat-square&logo=riseup&logoColor=white&label=Stars&labelColor=1F2328&color=E3B341
[stars-url]: https://github.com/RafaelVVolkmer/libmemalloc/stargazers

[issues-shield]: https://img.shields.io/github/issues/RafaelVVolkmer/libmemalloc.svg?style=flat-square&logo=sentry&logoColor=white&label=Issues&labelColor=1F2328&color=DA3633
[issues-url]: https://github.com/RafaelVVolkmer/libmemalloc/issues

[license-shield]: https://img.shields.io/github/license/RafaelVVolkmer/libmemalloc.svg?style=flat-square&logo=libreofficeimpress&logoColor=white&label=License&labelColor=1F2328&color=3FB950
[license-url]: https://github.com/RafaelVVolkmer/libmemalloc/blob/main/LICENSE

[release-shield]: https://img.shields.io/github/v/release/RafaelVVolkmer/libmemalloc?include_prereleases&style=flat-square&logo=github&logoColor=white&label=Release&labelColor=1F2328&color=8957E5
[release-url]: https://github.com/RafaelVVolkmer/libmemalloc/releases

<!-- ======================================================================= -->
<!-- Repository Stats Badges                                                -->
<!-- ======================================================================= -->

[repo-size-shield]: https://img.shields.io/github/repo-size/RafaelVVolkmer/libmemalloc?style=flat-square&logo=github&logoColor=white&label=Repo%20size&labelColor=1F2328&color=6E7681
[repo-size-url]: https://github.com/RafaelVVolkmer/libmemalloc

[code-size-shield]: https://img.shields.io/github/languages/code-size/RafaelVVolkmer/libmemalloc?style=flat-square&logo=files&logoColor=white&label=Code%20size&labelColor=1F2328&color=6E7681
[code-size-url]: https://github.com/RafaelVVolkmer/libmemalloc

[top-language-shield]: https://img.shields.io/github/languages/top/RafaelVVolkmer/libmemalloc?style=flat-square&logo=c&logoColor=white&label=Top%20language&labelColor=1F2328&color=A8B9CC
[top-language-url]: https://github.com/RafaelVVolkmer/libmemalloc

<!-- EOF -->

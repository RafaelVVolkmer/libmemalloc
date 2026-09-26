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
    src="./assets/images/libmemalloc_logo.svg"
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
    <a href="https://github.com/RafaelVVolkmer">Rafael V. Volkmer</a>
    ·
    <a href="mailto:rafael.v.volkmer@gmail.com">rafael.v.volkmer@gmail.com</a>
  </p>

</div>

---

## Overview

`libmemalloc` is a C memory allocator being designed for systems programming and
memory-management research, with an optional, separately linked garbage collector.
Its production core targets **no C standard library dependency (stdlib/libc)**,
**zero allocations through the host heap** and a runtime owned by the project.
That includes avoiding external `malloc`, `calloc`, `realloc`, `free` and equivalent
allocation services during bootstrap, metadata management and normal operation.

The allocator still needs backing memory and internal storage. The design provides
`reserved_only`, using storage supplied before execution, and `owned_growth`,
obtaining regions directly through a platform backend. Resource limits, ownership
and failure behavior are explicit in the
[core runtime contract](docs/specs/libmemalloc-core-implementation-SDD.md#lma-core-042).
Security, portability and measured performance guide the
[SDDs](docs/specs/README.md) and [delivery roadmap](ROADMAP.md).

---

## Status

> [!IMPORTANT]
> **WIP Refactor:** this repository is currently being reorganized.
> Public APIs, internal layout, documentation, and build workflows may still change.
> The executable C code is a distribution fixture. The allocator and optional GC
> are specified but unimplemented; passing fixture checks does not qualify them.

---

## Quickstart: build the fixture

Requires Git, CMake 3.28 or newer, a C99 compiler and a build tool (Make or Ninja).
Clone the repository and enter its root first:

```sh
git clone https://github.com/RafaelVVolkmer/libmemalloc.git
cd libmemalloc
```

Build and test the current fixture with CMake:

```bash
cmake -S . -B .cache/build/example -D LMA_BUILD_MOCK=ON -D LMA_BUILD_TESTS=ON
cmake --build .cache/build/example
ctest --test-dir .cache/build/example --output-on-failure --no-tests=error
```

Expected result: the library and consumer compile, and CTest reports `build-interface` passing.
This fixture performs no allocation; it checks compilation and linkage.
The contributor setup below prepares the additional tools for repository checks.

See [CMake build profiles](docs/reference/cmake-build.md) for options and installed consumers. The
[documentation index](docs/README.md) covers development, qualification and release procedures.

---

## Getting Started

Contributor setup has four steps: install host packages, prepare Python and Ansible,
initialize the checkout, then select a task. Tool downloads and generated files live
under `.cache/`. These development tools are separate from the planned allocator runtime.

### 1. Host dependencies

Automation currently targets **Linux x86_64** and **macOS arm64/x86_64** with Python 3.12.
Ubuntu 24.04 has been validated locally. Other setup paths require native validation;
their presence here is not a product portability qualification.

| Host | Package setup |
| --- | --- |
| Debian 12/13, Ubuntu 24.04 | Commands below |
| Arch Linux | [Native packages](docs/getting-started/development.md#arch-linux) |
| Fedora | [Native packages](docs/getting-started/development.md#fedora) |
| Windows x86_64 | [Ubuntu under WSL 2](docs/getting-started/development.md#windows) |
| macOS | [Command Line Tools and Homebrew](docs/getting-started/development.md#macos) |

For **Debian 12/13 or Ubuntu 24.04**, install the host tools and an isolated `uv`:

```sh
sudo apt update
sudo apt install git lua5.4 build-essential cmake python3-venv pipx \
  ca-certificates curl tar unzip coreutils util-linux cargo jq
pipx install uv
pipx ensurepath
```

Open a new terminal before step 2. [Debian 12](https://packages.debian.org/bookworm/python3)
and [Debian 13](https://packages.debian.org/trixie/python3) ship different Python defaults;
the next step selects the project's Python 3.12 without replacing `/usr/bin/python3`.
For other hosts, follow the linked package instructions, then return here.

### 2. Python and Ansible

Install the development interpreter and controller once per user:

```sh
uv python install 3.12
uv tool install --python 3.12 'ansible-core>=2.16,<2.22'
uv python update-shell
uv tool update-shell
```

Open a new terminal, then verify:

```sh
python3.12 -c 'import ensurepip, sys; assert sys.version_info[:2] == (3, 12)'
ansible-playbook --version
```

The playbook selects `python3.12` on `PATH`; no virtual-environment activation is needed.
See [uv's Python installation guide](https://docs.astral.sh/uv/guides/install-python/)
and the [controller requirements](docs/getting-started/workspace.md#root-commands).

### 3. Repository setup

If you already cloned the quickstart, use that checkout. Otherwise:

```sh
git clone https://github.com/RafaelVVolkmer/libmemalloc.git
cd libmemalloc
```

From the repository root, list tasks and check the specifications:

```sh
ansible-playbook playbook.yml
ansible-playbook playbook.yml -e lma_task=sdd-check
```

The first run prepares Lua and luv in `.cache/tools/`. Later tasks install their
locked tools as needed and reuse verified installations. Development tasks also
activate the [repository Git configuration](docs/getting-started/workspace.md#git-setup).
The playbook reports missing system packages; it does not install them automatically.

### 4. Daily commands

| Task | Command |
| --- | --- |
| Diagnose the workspace | `ansible-playbook playbook.yml -e lma_task=doctor` |
| Check Lua | `ansible-playbook playbook.yml -e lma_task=lua-check` |
| Run automation tests | `ansible-playbook playbook.yml -e lma_task=tests` |
| Build the documentation | `ansible-playbook playbook.yml -e lma_task=docs-build` |
| Build and test the C fixture | `ansible-playbook playbook.yml -e lma_task=build` |
| Run local verification | `ansible-playbook playbook.yml -e lma_task=checks` |

Use the playbook build when the system CMake is older than the quickstart requirement;
it prepares the locked build tools. Logs live under `.cache/logs/tasks/`. Build and
full-check runs require a fresh output directory for each retained execution.
See the [playbook](docs/playbook.md) for task options and
[cleanup scopes](docs/playbook.md#clean-disposable-state), the
[workspace guide](docs/getting-started/workspace.md) for setup diagnostics, or
[Nix](docs/getting-started/nix.md) for the alternative tool environment.

---

## Repository Stats

| Metric              | Badge                                                    | Meaning                                                       |
| ------------------- | -------------------------------------------------------- | ------------------------------------------------------------- |
| **Repository Size** | [![Repo Size][repo-size-shield]][repo-size-url]          | Shows the total repository size reported by GitHub.           |
| **Code Size**       | [![Code Size][code-size-shield]][code-size-url]          | Shows the total source-code size reported by GitHub Linguist. |
| **Top Language**    | [![Top Language][top-language-shield]][top-language-url] | Shows the dominant language detected in the repository.       |

---

## Repository Tree

| Directory | Responsibility |
| --- | --- |
| `core/` | Distribution fixture |
| `cmake/` | Build, installation and consumer contracts |
| `scripts/` | Lua automation and verification |
| `tests/` | Executable engineering tests and fixtures |
| `docs/specs/` | Planned product contracts |
| `tools/` | Tool identities and verification policies |

---
<!-- ======================================================================= -->
<!-- Project Badges                                                         -->
<!-- ======================================================================= -->

[contributors-shield]: https://img.shields.io/github/contributors/RafaelVVolkmer/libmemalloc.svg?style=flat-square&logo=changedetection&logoColor=white&label=Contributors&labelColor=1F2328&color=2F81F7
[contributors-url]: https://github.com/RafaelVVolkmer/libmemalloc/graphs/contributors

[forks-shield]: https://img.shields.io/github/forks/RafaelVVolkmer/libmemalloc.svg?style=flat-square&logo=forgejo&logoColor=white&label=Forks&labelColor=1F2328&color=F78166
[forks-url]: https://github.com/RafaelVVolkmer/libmemalloc/network/members

[stars-shield]: https://img.shields.io/github/stars/RafaelVVolkmer/libmemalloc.svg?style=flat-square&logo=riseup&logoColor=white&label=Stars&labelColor=1F2328&color=E3B341
[stars-url]: https://github.com/RafaelVVolkmer/libmemalloc

[issues-shield]: https://img.shields.io/github/issues/RafaelVVolkmer/libmemalloc.svg?style=flat-square&logo=sentry&logoColor=white&label=Issues&labelColor=1F2328&color=DA3633
[issues-url]: https://github.com/RafaelVVolkmer/libmemalloc/issues

[license-shield]: https://img.shields.io/github/license/RafaelVVolkmer/libmemalloc.svg?style=flat-square&logo=libreofficeimpress&logoColor=white&label=License&labelColor=1F2328&color=3FB950
[license-url]: LICENSE

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


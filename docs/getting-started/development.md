<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Development setup

The current C implementation is a mock used to exercise engineering and distribution workflows.
Read the [specifications](../specs/README.md) for planned product behavior.

<details>
<summary><strong>On this page</strong></summary>

- [Host packages](#host-packages)
- [Verify the checkout](#verify-the-checkout)

</details>

---

## Host packages

Start with [the four setup steps](../../README.md#getting-started). Install the packages
for your host below, then use the shared Python 3.12 and Ansible instructions in the README.
Automation supports Linux x86_64 and native macOS arm64/x86_64; other product targets
have separate build and qualification requirements.

### Debian and Ubuntu

Use the [Debian 12/13 and Ubuntu 24.04 package commands](../../README.md#1-host-dependencies).
`pipx` installs `uv` in isolation, and `uv` provides Python 3.12 alongside the system Python.
Debian publishes `pipx` for both [Debian 12](https://packages.debian.org/bookworm/pipx)
and [Debian 13](https://packages.debian.org/trixie/pipx).
The playbook's missing-package hints currently use Ubuntu names; on Debian, complete
this setup rather than assuming `python3.12-venv` is a distribution package.

### Arch Linux

```sh
sudo pacman -Syu --needed base-devel git lua54 cmake curl tar unzip \
  coreutils util-linux rust jq uv
```

`rust` supplies Cargo. Use the project's Python 3.12 setup rather than the distribution's
current Python. The official package catalogs list
[Lua](https://archlinux.org/packages/extra/x86_64/lua54/) and
[uv](https://archlinux.org/packages/extra/x86_64/uv/).

### Fedora

```sh
sudo dnf install git lua gcc gcc-c++ make cmake curl tar unzip \
  coreutils util-linux cargo jq uv
```

Continue with Python 3.12 and Ansible in the README. Fedora provides
[uv](https://packages.fedoraproject.org/pkgs/uv/uv/) and
[Lua](https://packages.fedoraproject.org/pkgs/lua/lua/) in its package repositories.

### Windows

Use WSL 2 on an x86_64 machine. From an Administrator PowerShell:

```powershell
wsl --install -d Ubuntu-24.04
```

Restart if requested, launch Ubuntu and create its Linux user. Run the README's Ubuntu
setup inside that terminal and keep the checkout in the Linux home directory. To reopen it:

```powershell
wsl -d Ubuntu-24.04
```

This path builds Linux artifacts; native Windows qualification is separate. Windows on ARM
is outside the current bootstrap targets. See
[Microsoft's installation guide](https://learn.microsoft.com/en-us/windows/wsl/install).

### macOS

Install Apple's Command Line Tools and complete the installer:

```sh
xcode-select --install
```

Install [Homebrew](https://docs.brew.sh/Installation), apply its shell configuration, then run:

```sh
brew install git lua python@3.12 uv cmake coreutils curl rust jq gnupg graphviz \
  bison flex openssl@3 pkgconf
```

Return to the README's Python and Ansible step. The playbook selects native tool paths
on Apple Silicon and Intel; no VM, container or Rosetta is required. Intel Ansible setup
may compile `cryptography` with Rust and OpenSSL. Doxygen builds from verified source,
using `bison` and `flex`. Cleanup uses Python's native kernel locking.
See Homebrew's [Python 3.12](https://formulae.brew.sh/formula/python@3.12) and
[GNU utilities](https://formulae.brew.sh/formula/coreutils) packages.

---

## Verify the checkout

1. Work from the repository root and initialize its declared submodules:

   ```sh
   git submodule update --init --recursive
   ```

2. Read the [toolchain authority](../reference/toolchain.md). Use the campaign's installer or existing host setup
   action for its required tools. A Lua interpreter alone does not provide the full checking environment.
3. Prepare [documentation dependencies](documentation.md) when editing pages or examples.
4. Review the working-file inventory, including new and renamed sources. Stage only the intended commit;
   source checks and commit hooks have different input boundaries.
5. Run the applicable [local checks](../runbooks/local-checks.md), then the affected campaigns from the
   [workflow catalog](../reference/workflow-catalog.md).

Use the [change procedure](../procedures/change.md) for requirement and review records.
Run `ansible-playbook playbook.yml` for local tasks and follow the [workspace setup](workspace.md) to activate Git hooks.
The [playbook](../playbook.md) links recurring tasks to their execution guides.

<!-- EOF -->


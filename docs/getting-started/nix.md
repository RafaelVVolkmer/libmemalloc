<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Nix development environments

The [flake](../../tools/nix/flake.nix) provides Linux x86_64 development shells. Tool selection lives in
[tools/nix/packages.toml](../../tools/nix/packages.toml); [environment.nix](../../tools/nix/environment.nix)
composes those packages and reads the repository toolchain and Python manifests.

<details>
<summary><strong>On this page</strong></summary>

- [Enter an environment](#enter-an-environment).
- [Prepare Python and Ansible](#prepare-python-and-ansible).
- [Version boundaries](#version-boundaries).

</details>

---

## Enter an environment

Enable `nix-command` and `flakes` in your Nix installation, then run from the checkout:

```sh
nix develop ./tools/nix
nix develop ./tools/nix#build
nix develop ./tools/nix#docs
```

The default shell includes build, documentation, analysis, lint and release tools. The smaller shells
select the corresponding catalog groups plus common host prerequisites. Lua includes `luv`.
Native C/C++, Rust, Zig, C3 and WebAssembly tools are included; bare-metal compilation still requires an
explicit target and toolchain configuration. External service credentials remain separate prerequisites.

Entering the shell does not install Python dependencies or change Git settings. Nix downloads and realizes
its package closure through its normal store. Repository caches remain below `.cache/`.

---

## Prepare Python and Ansible

When the workspace controller is already available, prepare the Nix environment through the playbook:

```sh
ansible-playbook playbook.yml -e lma_task=nix-setup
```

The task skips hosts without `nix`. On Nix hosts it realizes the default development shell, retains a
profile at `.cache/tools/nix/profile`, and synchronizes the `automation`, `quality` and `python-lint`
groups. It enables flakes for that invocation and refuses to update the committed flake lock. It does
not edit user or system Nix configuration, and it does not change the parent terminal's environment.

For the first setup, before Ansible is available, invoke the same registered task with system Lua:

```sh
lua scripts/process/playbook.lua --direct nix-setup
nix develop ./tools/nix
lua scripts/workspace/bootstrap.lua
```

The Python installer uses [the manifest](../../tools/python/pyproject.toml) and
[its lock](../../tools/python/uv.lock), with an explicit project directory. It requires CPython 3.12,
accepts binary wheels only for these groups, and refuses to rewrite an outdated lock. Bootstrap records
the Lua and luv paths used by native Ansible. See [workspace setup](workspace.md) for controller paths.

The playbook activates Git defaults only in this repository. Repeated runs retain the existing include;
`--check` leaves it untouched. The shell exposes the synchronized Python tools on `PATH`.
Documentation's npm dependencies still use their own reviewed package lock and setup procedure.

---

## Version boundaries

[tools/nix/flake.lock](../../tools/nix/flake.lock) fixes Nixpkgs and its content hash. The uv derivation
reads its version and
archive hash from [the toolchain lock](../../tools/toolchain/lock.toml). Other Nix tools use the selected
Nixpkgs host prerequisite versions. Lua and luv are built from the repository
lock. Install the shared quality profile explicitly to use the same validator
versions as CI; the shell puts its executable directory before host tools.
Inspect the host catalog and qualification pins with:

```sh
nix build ./tools/nix#tool-versions
cat result
```

A shell provides development prerequisites; it does not establish that every qualification campaign uses
its required compiler identity. Keep those campaign checks enabled. Edit `tools.nixpkgs.revision` in the
central toolchain lock, run
`lua scripts/toolchain/sync.lua`, then run `nix flake lock ./tools/nix`. Review the resulting input hash.
See [toolchain maintenance](../reference/toolchain.md#updating-tool-versions) for the complete update flow.
The Nix catalog is versioned by that single Nixpkgs revision; its package versions are not independently
editable pins. Nix flakes in Git use tracked source files, so include newly added files in the change
before evaluating the moved flake.

The design follows [Nix flakes](https://nix.dev/concepts/flakes.html) and
[uv locking and synchronization](https://docs.astral.sh/uv/concepts/projects/sync/).

<!-- EOF -->


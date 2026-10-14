<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Workspace automation and Git hooks

Use the native [root Ansible playbook](../../playbook.yml) to select a task from the
[engineering playbook](../playbook.md). Lua modules implement the registered tasks.

<details>
<summary><strong>On this page</strong></summary>

- [Root commands](#root-commands).
- [Git setup](#git-setup).
- [Hook policy](#hook-policy).
- [Ansible and temporary state](#ansible-and-temporary-state).
- [Validation](#validation).

</details>

---

## Root commands

Use Ansible directly from the checkout root. There is no root executable or `AP` variable:

```sh
ansible-playbook playbook.yml
ansible-playbook playbook.yml -e lma_task=check-eof
ansible-playbook playbook.yml -e lma_task=lua-check
ansible-playbook playbook.yml --check -e lma_task=clean
ansible-playbook playbook.yml -e lma_task=build \
  -e '{"lma_arguments":["--profile=debug","--jobs=4"]}'
```

Install Ansible once on the machine. On Ubuntu 24.04:

```sh
sudo apt install ansible-core
```

The native playbook accepts ansible-core 2.16 through 2.21; CI keeps its exact controller pin in the central
lock. Compatibility is exercised locally with 2.16.14 and the pinned controller. The installed controller
stays on `PATH` across shells: there is no per-repository environment activation or versioned executable path.
Ansible installation options are described in the
[official installation guide](https://docs.ansible.com/projects/ansible/latest/installation_guide/intro_installation.html).

After cloning, run `ansible-playbook playbook.yml`. Before preparing a missing runtime, the playbook checks
the host and lists missing packages. See the [platform setup](../../README.md#getting-started) for Debian,
Ubuntu, Arch, Fedora, Windows/WSL and native macOS. The Ubuntu host prerequisites are:

```sh
sudo apt install lua5.4 python3.12-venv build-essential cmake git curl tar unzip coreutils util-linux cargo jq
```

System packages are not installed automatically. Runtime preparation installs Lua and luv locally; it does not
replace or install another Ansible controller. Missing, broken or incorrectly versioned runtimes are
repaired before task execution.
Cargo is needed only for profiles that build Rust validators. On normal runs, task preparation follows the
canonical command, so aliases select the same tools:

| Tasks | Automatic preparation |
| --- | --- |
| `lua-check`, `check-lua` | Lua format, analysis and complexity tools |
| `check-spelling`, `check-links` | Spelling and link tools |
| `build` | Locked CMake, Ninja and C tools; host compiler remains a prerequisite |
| `checks`, `tests`, `docs-build`, `docs-eval` | Full quality profile; missing documentation theme |
| `check-c`, `check-cmake`, `check-mermaid`, `check-web` | Full quality profile |
| Other tasks | Validate declared host dependencies; domain prerequisites remain in their runbooks |

The task list and `--check` plans show the selected preparation profile. Downloads use the existing reviewed
locks. Input receipts, executable hashes and Python probes control reuse and repair. Documentation assets are
initialized at the recorded submodule revision only when absent; existing checkouts are preserved.
Use `-e lma_prepare_tools=false` to execute with an already prepared environment without automatic task-tool
installation. This does not disable runtime bootstrap. The full local verification command is:

```sh
ansible-playbook playbook.yml -e lma_task=checks -e '{"lma_arguments":["--offline"]}'
```

Here `--offline` controls link checking; initial tool provisioning still needs network access. For a fully
offline run, prepare the tools beforehand and pass `-e lma_prepare_tools=false`.
`--check` installs no tools and executes no domain operation. A missing or broken runtime causes an explanation
to run the playbook normally first. A domain option named `--check` belongs in `lma_arguments`:

```sh
ansible-playbook playbook.yml -e lma_task=toolchain-sync -e '{"lma_arguments":["--check"]}'
```

For CI or an explicitly pinned local controller, the standalone bootstrap remains available:

```sh
lua scripts/workspace/bootstrap.lua
```

Direct bootstrap inherits the caller's `PATH`; on macOS use the playbook to select Homebrew paths automatically.

The bootstrap supports Linux x86_64 and macOS arm64/x86_64 with CPython 3.12. Host prerequisites are Lua,
Python with virtual-environment support, a C compiler, Make, CMake, Git, curl, tar, SHA-256 utilities,
GNU timeout and, on Linux, util-linux `flock`. The playbook discovers Homebrew Python and GNU utilities
on macOS; its workspace lease uses Python `fcntl.flock`. Native archive hashes are recorded per architecture.
It verifies Lua and luv source archives and installs Ansible dependencies from the Python lock.
On macOS Intel, `cryptography` is compiled from its locked source archive using the locked `crypto-build`
backends and Homebrew OpenSSL; other Ansible dependencies must have matching wheels.
The Python graph comes from `tools/python/pyproject.toml` and `tools/python/uv.lock`; bootstrap synchronizes
the `automation` group.
Tools live separately under `.cache/tools/lua/`, `.cache/tools/luv/` and `.cache/tools/ansible/`.
Each bootstrap stage has a 15-minute deadline and its own log under `.cache/logs/bootstrap/`.
Installed tools are reused when their input receipt, recorded product hashes and runtime probes agree.
Changed inputs, missing products or failed probes rebuild the affected component; unchanged runs avoid
downloads, extraction and compilation. Python inputs include the native manifest and lock. Failed repairs
invalidate their receipt so the next invocation retries them.
A hash mismatch fails before extraction or installation; inspect and remove a corrupt cached archive before retrying.

The standalone bootstrap installs the pinned controller under `.cache/tools/ansible/` for CI and explicit
reproduction. Normal native playbook use keeps the machine's Ansible controller. The generated
`.cache/tools/automation.yml` supplies Lua and luv paths. Moving a checkout causes the runtime probe to fail
and triggers repair when the old paths no longer exist; explicit bootstrap regenerates paths in all cases.

```sh
ansible-playbook playbook.yml
ansible-playbook playbook.yml -e lma_task=doctor
ansible-playbook playbook.yml -e lma_task=docs-check
ansible-playbook playbook.yml --check -e lma_task=docs-build
ansible-playbook playbook.yml -e lma_task=tests
```

Without a task, the playbook displays the catalog. `--check` displays the selected command, dependencies,
effects and timeout without running the task. Campaign prerequisites remain in their domain runbooks;
bootstrap installs the automation runtime, while Doxygen, compilers and security services have separate setup.

Pass domain arguments as an ordered list:

```sh
ansible-playbook playbook.yml \
  -e '{"lma_task":"build-plan","lma_arguments":["--campaign=pr","--profile=linux-gcc13","--output=.cache/build-plan.json"]}'
```

For literal text containing Jinja syntax, use an extra-vars YAML file with `!unsafe` scalar values and pass
`-e @arguments.yml`. Ansible otherwise interprets templates according to its normal variable rules.
Relative domain paths refer to the checkout. Run these examples from its root; the playbook selects localhost
and its Python interpreter explicitly, so it does not require a root configuration file.

---

## Git setup

Each normal playbook invocation activates [`.gitconfig`](../../.gitconfig) in this repository before
running the selected task. The first invocation reports that change; subsequent invocations preserve the
existing include. `--check` leaves Git settings untouched. Explicit maintenance commands remain available:

```sh
ansible-playbook playbook.yml -e lma_task=setup
ansible-playbook playbook.yml -e lma_task=status
ansible-playbook playbook.yml -e lma_task=setup-repair
ansible-playbook playbook.yml -e lma_task=setup-uninstall
```

Git does not load the versioned file on clone. Setup includes its absolute path once and records ownership
in `libmemalloc.managedConfig`. Repair removes only that owned stale include and installs the current path.
Uninstall removes the owned include and a legacy local `.githooks` setting. Custom hooks, other includes,
identity and signing keys are preserved. A custom effective or local hooks path prevents installation.
For recovery before bootstrap, use `lua scripts/workspace/hooks.lua repair` or `uninstall`.
Linked worktrees share common Git configuration unless worktree-specific configuration is enabled.

The configuration selects `.githooks`, the commit template, editor-comment cleanup, OpenPGP signing,
fast-forward pulls, simple pushes, pruning, histogram diffs and recorded conflict resolution without
automatic staging. Configure your key using the [signature guide](../standards/versioning/signature-guide.md).
The Git hook shebang still needs Lua on `PATH`; Ansible runtime discovery does not change the Git interpreter.

---

## Hook policy

| Hook | Checks |
| --- | --- |
| `pre-commit` | Gitflow branch, OpenPGP setup, staged whitespace and installed Gitleaks. |
| `commit-msg` | Canonical CI message grammar and installed prose tools for ordinary commits. |
| `pre-push` | Destination names, immutable release tags, annotated tag signatures, commit signatures and messages. |

The [hook modules](../../scripts/workspace/lib/hooks.lua) inspect the staged index without changing it.
Missing optional prose tools or Gitleaks produce a warning; failure from an installed tool blocks the operation.
The grammar retains the 70-character Unicode limit, optional scope/body and final DCO trailer paragraph.
Only actual merges are exempt from message grammar: stored commits must have multiple parents, and an
editable merge must have `MERGE_HEAD`. A subject beginning with `Merge` grants no exemption.
CI includes merge objects in its selected range; its configured signature policy still applies to them.

For an existing destination, pre-push checks `old..new`. For a new destination, it queries that remote's
advertisement, selects its symbolic default branch, verifies that exact baseline object locally, and checks
`baseline..new`. Set `git config --local libmemalloc.baselineRef refs/heads/develop` to select another reviewed
branch on that destination. Set the repository variable `LIBMEMALLOC_BASELINE_REF` to the same ref
for first-push CI selection; both default to the destination default branch. A missing advertised object
requires an explicit fetch. Missing or unrelated
baselines fail; only an empty remote causes the complete reachable history to be checked. Other remotes'
tracking refs never exempt commits. Repeated outgoing commits are checked once.

Prose checks run at commit time. Pre-push verifies stored structure and signatures, including actual merges,
without rerunning prose tools across history. CI remains necessary because local hooks can be bypassed.

---

## Ansible and temporary state

[The optional configuration](../../infra/ansible/ansible.cfg) lives outside the root. Ansible does not discover
configuration files in subdirectories automatically. The root playbook works without this file and places
module temporary files in `.cache/ansible/remote`; Ansible uses its default controller temporary directory.
To also keep controller temporary files in `.cache/ansible/local` and load the explicit inventory, opt in:

```sh
ANSIBLE_CONFIG=infra/ansible/ansible.cfg ansible-playbook playbook.yml -e lma_task=doctor
```

The inventory path is relative to the configuration directory. The playbook checks controller compatibility,
validates the task and ordered
string arguments, and disables command-module environment expansion. Check mode validates the command's
arguments and displays its complete execution plan. Verification tasks report `changed=0` after the initial
Git setup. Mutating tasks report observed changes through the structured task result, independently of their
declared effects; repeated setup and cleanup can report `changed=0`.

The internal Lua supervisor bounds execution time and captured output. Each attempt retains `stdout.log`,
`stderr.log`, `result.json` and `junit.xml` under a private `.cache/logs/tasks/TASK-ATTEMPT/` directory.
Timeout, spawn failure, output limits and child errors produce failed results. Logs are disposable until
retained by CI or copied to an approved evidence store. Failed or interrupted controllers may leave temporary
state; inspect the corresponding cache directory before removing it.
Use the playbook's [`clean` task](../playbook.md#clean-disposable-state) for scoped cleanup of generated
metadata, tool download caches and temporary files while retaining installed tools and the active task result.

---

## Validation

Run `ansible-playbook playbook.yml -e lma_task=ansible-setup-test` for first-run setup, cached quality tools,
runtime repair, all preparation profiles, simulation and operation with or without the optional configuration.
Run `ansible-playbook playbook.yml -e lma_task=ansible-test` for native controller tests and
`-e lma_task=hooks-test` for actual Git integration. These tests create disposable repositories; signing tests
use an ephemeral keyring and local bare remotes. No contributor key is needed. The reusable lint workflow
runs both integrations with read-only repository permissions and retains diagnostics after failures.

The `tests` task covers self-contained suites, including process evidence tampering. Release and independent
rebuild campaigns keep their explicit inputs in the [test catalog](../../tests/README.md). The Lua gate includes
extensionless Git hooks. Language formatters remain responsible for indentation inside code literals.

<!-- EOF -->


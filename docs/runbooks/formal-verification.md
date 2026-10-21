<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Run formal verification

## Prepare tools

Use Linux x86-64, Lua 5.5 with libuv, jq, a C compiler,
a systemd user manager and the bootstrap prerequisites.
The official executor limits resources and retains logs from launch.

```sh
lua scripts/process/playbook.lua --direct formal-bootstrap
```

## Haskell quality checks

```sh
lua scripts/process/playbook.lua --direct check-haskell
```

## Lean and engine checks

```sh
lua scripts/process/playbook.lua --direct check-lean
lua scripts/process/playbook.lua --direct check-lean --kernel
lua scripts/process/playbook.lua --direct check-lean --engine
```

The full campaign verifies only `core/mock.c`, the engines and their negative
controls. Success is not acceptance of a final allocator implementation.

## Staged Ansible campaign

For staged execution, use one fresh run identity:

```sh
lua scripts/process/playbook.lua --direct formal-start --run-id=review-001
lua scripts/process/playbook.lua --direct formal-prepare --run-id=review-001
lua scripts/process/playbook.lua --direct formal-lean --run-id=review-001
lua scripts/process/playbook.lua --direct formal-haskell --run-id=review-001
lua scripts/process/playbook.lua --direct formal-proof --run-id=review-001
lua scripts/process/playbook.lua --direct formal-tests --run-id=review-001
lua scripts/process/playbook.lua --direct formal-check --run-id=review-001
```

The Ansible playbook executes the same stages:

```sh
ansible-playbook infra/ansible/playbooks/formal-verification.yml -e lma_run_id=review-002
```

Task logs are in `.cache/logs/tasks/`. Campaign receipts are in
`.cache/verification/attempts/<run-id>/report.json`; mock proofs and kernel
exports are in `.cache/verification/generic/<run-id>/`.
Interrupted runs retain incomplete receipts. Use a new identity after changing
inputs. A partial run is not PASS.

Run `formal-resources-test`, `formal-executor-test` and `native-resources-test`
through the same executor to exercise containment. Native resource CI covers
Linux, macOS and Windows; formal proofs run on Linux.

New targets must follow the [specification workflow](../specs/formal-engine.md).
Their explicit contracts, models and tests arrive with the operation.

<!-- EOF -->


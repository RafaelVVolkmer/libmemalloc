<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Lua quality gate

The Lua gate checks every owned `.lua` file and executable Lua hook returned by
the working Git inventory. It includes untracked additions, tests and configuration
factories, and excludes deleted files and ignored dependency caches. It checks
syntax, function boundaries, Selene diagnostics, StyLua formatting, LuaLS analysis,
measured function complexity and adjacent function contracts. No inspected Lua source is executed by the
complexity analyzer.

Run the same task used by CI after installing the locked tools:

```sh
lua scripts/process/playbook.lua quality-setup
lua scripts/workspace/with_tools.lua lua scripts/process/playbook.lua lua-check
```

The native Ansible equivalent is `ansible-playbook playbook.yml -e lma_task=lua-check`
with the quality tools available on its environment. `LIBMEMALLOC_QUALITY_PYTHON`
selects the locked Python environment; `with_tools.lua` sets it automatically.
CI installs the `quality` dependency group from `tools/python/uv.lock` and invokes the same
Lua gate through the playbook registry.

<details>
<summary><strong>On this page</strong></summary>

- [Limits and evidence](#limits-and-evidence)
- [Function contracts](#function-contracts)
- [Cyclomatic convention](#cyclomatic-convention)
- [Cognitive convention](#cognitive-convention)
- [Reviewing refactors](#reviewing-refactors)

</details>

---

## Limits and evidence

The limit authority is [the shared C quality policy](../../tools/analysis/c/gates.json):
cyclomatic complexity must not exceed 10, and cognitive complexity must not exceed
15. These limits apply to every function, including factories, nested helpers,
callbacks and test fixtures. There is no baseline exemption. C-specific clone
and compiler checks remain in the C gate.

The [analysis adapter](../../tools/analysis/lua/metrics.py) writes
`.cache/ci/lua-quality/report.json` before returning a failing status. The report
contains tool versions, metric convention identifiers, the policy digest, source
digests, all function locations and scores, complexity violations, contract violations and parser errors. CI
retains this report separately from build outputs. Parsing errors fail the gate;
they cannot silently remove a file from the measured inventory.

The optional `--report-only` analysis flag supports investigation. It still
returns failure for parser errors. The mandatory Lua gate never uses that flag.

---

## Function contracts

Every owned function, including nested helpers, callbacks and hooks, requires an adjacent `---` purpose,
one `@param` tag for each explicit parameter and a `@return` tag. A function with no arguments needs no
parameter tag. Document operations with no returned values explicitly. The existing AST analyzer checks
these tags together with complexity and records omissions under `contract_violations`.

These checks establish presence and parameter coverage. They do not infer ownership, prove the stated
types or validate semantic correctness of prose; those remain review obligations under the
[comment guide](../standards/lua/lua-comments.md). The analyzer ignores functions embedded in string
fixtures and checks actual Lua function nodes without running the source.

---

## Cyclomatic convention

`lua-ast-lizard-v1` uses the locked `luaparser` AST to establish function boundaries
and the locked Lizard decision counter to measure each isolated body. The count
starts at one and adds one for each `if`, `elseif`, `for`, `while`, `until`, `and`
and `or`. Strings, comments and nested function bodies do not add decisions to
the enclosing function. A nested function receives its own record. `else`,
`goto`, `break`, `return`, `pcall` and `xpcall` add no cyclomatic decision.

This adapter avoids scope errors in Lizard's general Lua reader around nested
functions and embedded language text. Its reported convention is explicit; it
does not claim identical output to the standalone Lizard CLI. Lua compiler
validation remains authoritative for the selected Lua runtime; unsupported
parser syntax fails analysis and requires a reviewed parser update.

---

## Cognitive convention

`lua-cognitive-v1` is the repository's Lua metric. It is not a SonarQube score.
The AST traversal applies these rules independently within each function:

- `if` and loops add one plus their enclosing decision nesting depth.
- `elseif` and `else` add one without a nesting bonus. Their bodies increase depth.
- A boolean expression adds one for its first `and` or `or` sequence and for
  each change between operators, including grouped expressions.
- `goto` and `break` add one. Plain returns and protected calls add nothing.
- A direct self-call by the function's lexical name adds one once per function.
  Dynamic dispatch and indirect recursion are not inferred.

The [analyzer tests](../../tests/automation/analysis/lua_metrics_test.py) check
exact scores, nested scopes, methods, callbacks, all loop forms, recursion,
Unicode, long strings, comment traps, Git inventory and failing CLI outcomes.
They execute before repository measurement so a regression in the analyzer
cannot masquerade as a passing source report.

---

## Reviewing refactors

Inspect `.cache/ci/lua-quality/report.json` for measured functions, rule violations and analyzer errors.

Extract a coherent operation with a useful name and contract. Keep validation
near its fallible operation, and separate declarations, processing stages and
function definitions with blank lines. A helper may capture the operation's
state when that keeps ownership clear. Do not add a forwarding function solely
to hide decisions or move code into callbacks to claim improved readability.

Use the [Lua code standard](../standards/lua/lua-code-standard.md) and
[comment standard](../standards/lua/lua-comments.md) alongside the metrics.
Behavioral tests remain necessary for command arguments, exit status, cleanup,
evidence validation and Git policy. Passing complexity limits does not prove
those contracts or replace their review.

<!-- EOF -->


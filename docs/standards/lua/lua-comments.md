<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Lua comments and readable layout

Use this guide to document Lua contracts and separate the steps readers need to follow.

<details>
<summary><strong>On this page</strong></summary>

<details>
<summary>Boundary contracts</summary>

- [Suspension and native ownership](#suspension-and-native-ownership-contracts)

</details>

- [Scope](#scope)
- [Source layout](#source-layout)
- [Function contracts](#function-contracts)
- [Spacing and control flow](#spacing-and-control-flow)
- [Runtime and JIT profiles](#runtime-and-jit-profiles)
- [End-of-file convention](#end-of-file-convention)
- [Verification](#verification)
- [References](#references)

</details>

---

## Scope

Apply this guide to repository-owned Lua. Keep three-space indentation and the
80-column formatter limit. Separate declarations, effects, checks, cleanup and
output so that readers can follow each operation and its failure path. Write
`if ... then ... end`, `for ... do ... end` and `while ... do ... end` bodies
on multiple lines, including bodies with one statement.

The [Lua standard](lua-code-standard.md) defines language and module contracts.
This guide adds layout and comment requirements. Comments explain contracts,
failure handling, units, ownership, and trust boundaries. Remove comments that
repeat an assignment or narrate a loop.

---

## Source layout

Use UTF-8 text, LF line endings and spaces. Indent block contents by three spaces;
align `else`, `elseif` and the closing `end` with the opening statement. Keep
statements within 80 columns and prose within 120 columns. Let the configured
StyLua formatter choose continuation indentation when an expression wraps.

Place imports, state, helpers and export assembly inside the named initialization function required by
the [module boundary](lua-module-architecture.md#repository-script-initialization-boundary).
Read the following order inside that boundary; the outer chunk contains the initializer and its returned call.

Organize a reusable module in this order:

1. License header and a short description of the module's responsibility.
2. Imports, the local export table, constants and private module state.
3. Local helper functions before the operations that use them.
4. Public operation implementations, with contracts next to each declaration.
5. Explicit export assignments, the module return and the EOF marker.

Keep request-specific state in parameters or instance closures. A module-level
local persists across callers of the cached module. Avoid opening files or
starting work while `require` loads a reusable module; the entry point owns those
effects. Entry-point scripts group imports and declarations first, then argument
validation, execution, cleanup and exit-status handling.

For mutually recursive local functions, declare the bindings before assigning
function values. A later `local function` is not visible to an earlier function's
body unless its local binding was already in scope. Review whether that recursion
needs separate functions and a documented depth limit.

### Spaces, delimiters and wrapping

| Construct | Convention | Example |
| --- | --- | --- |
| Assignment and binary operators | One space on each side. | `size_bytes = size_bytes + chunk_bytes` |
| Commas | One following space on one line. | `send(context, payload)` |
| Calls and indexing | No padding inside parentheses or brackets. | `decode(data[index])` |
| Field or method access | No spaces around `.` or `:`. | `stream:read(limit_bytes)` |
| Unary operators | Space after `not`; none after `#` or unary minus. | `not is_closed`, `#payload`, `-1` |
| Empty table | No interior space. | `{}` |
| Small record | Spaces inside braces. | `{ size_bytes = 0 }` |
| Multiline record | One field per line; trailing comma. | See the example below. |
| Strings | StyLua `AutoPreferDouble`; preserve escaped bytes. | `"ready"` |

Do not align assignments with runs of padding spaces. Changes to a variable name
should not require reformatting unrelated lines. Use parentheses to clarify mixed
operators; preserve result arity when wrapping a call, since `(call())` keeps only
its first result. `object:method(value)` passes `object` as an implicit first
argument, whereas `object.method(value)` does not.

**Contextual Lua fragment:**

> ```lua
> local limits = {
>    max_payload_bytes = 4096,
>    max_pending_count = 16,
> }
> local is_acceptable = false
>
> if
>    payload_bytes <= limits.max_payload_bytes
>    and pending_count < limits.max_pending_count
> then
>    is_acceptable = true
> end
> ```

Break long calls between arguments and long conditions between operands. Preserve
short-circuit order: moving a validation call past a field access can turn rejected
input into an exception. Split long text only at boundaries that preserve its
bytes. For multiline literals, account for indentation and embedded newlines in
the resulting string; visual alignment is not permission to change a protocol.

---

## Function contracts

Follow the LuaRocks convention: start documentation with `---`, continue with
`--`, and describe parameters and returned values using LDoc tags. Document
public functions and internal functions whose effects or failure modes need an
explanation. Use ordinary `--` comments for implementation constraints.

> ```lua
> --- Test whether a configuration value contains at least one byte.
> -- @param value any: caller-supplied value; no coercion takes place.
> -- @return boolean: true for a nonempty string, including whitespace.
> local function config_isNonemptyString(value)
>    local ret = false
>
>    if type(value) == "string" then
>       ret = #value > 0
>    end
>
>    ::function_output::
>    return ret
> end
> ```

For resource operations, document read, write, and close failures and the owner
of cleanup. Use LuaLS annotations where they add analyzer-visible types. Keep them
consistent with the LDoc contract; neither format supplies runtime validation.

Use `TODO(owner, issue)` for planned work and `FIXME(owner, issue)` for a known
defect. Name the missing behavior and its acceptance test. Security comments
should identify the boundary and the check, not claim immunity to an attack.

---

## Suspension and native ownership contracts

Apply [LSTYLE-065](lua-code-standard.md#lstyle-065) and the
[native boundary controls](lua-code-standard.md#lstyle-073) to adapters. An annotation's type does not
describe retention, yield or cleanup by itself. Put these facts next to the operation, and link to the
provider contract rather than guessing its behavior from its name.

| Contract field | Question the comment must answer |
| --- | --- |
| Input view | Bytes or text, embedded NUL support, length unit and maximum extent? |
| Ownership | Borrowed until return, retained until acknowledgement, or transferred? |
| Suspension | May the call yield, and which owner keeps each captured value alive? |
| Callback | Permitted calling thread, reentry, number of deliveries and last-delivery condition? |
| Failure | Returned status, raised error or both; what state and progress remain visible? |
| Cancellation | Request only or acknowledged completion; who drains native activity? |
| Cleanup | Who releases registry references, backing storage and callbacks; can release fail? |

**Contract example (not executable):**

```text
submit(bytes): borrows immutable bytes until completion acknowledgement;
may suspend; cancellation stops admission but retains backing storage until drain;
reports operation failure separately from cleanup failure; callback runs on owner thread.
```

**Review evidence:** Compare the comment against the lifecycle tests and the adapter's retained-reference
record. A comment saying “async-safe” or “memory-safe” without those obligations is not sufficient.

---

## Spacing and control flow

- Put one blank line between adjacent function definitions.
- Group related declarations; put one blank line before the first operation.
- Separate independent assignments and independent call/check groups.
- Put a fallible call on its own line. Check its returned status on the next
  physical line, with no intervening blank line or unrelated operation.
- Put one blank line after a completed `if`, loop, or call/check group before
  the next independent operation. Keep `else` and `elseif` with their branch.
- Put one blank line before `::function_output::`. When cleanup is unnecessary,
  keep the label adjacent to its return. When cleanup is necessary, place it
  between the label and return, then separate the return with one blank line.
  Do not add a blank line before `end`.
- Keep one statement per line. Expand conditional bodies and anonymous
  functions; do not use semicolons to pack statements together.
- Keep documentation adjacent to its declaration. Do not place a blank line
  between an annotation block and the function it documents.

The following complete function shows a call/check group and cleanup at the common
output. Its injected ports return a project status first: zero means success.
`open` returns a handle only on success; `write` and `close` return a status. The
ports must not throw or yield in this example. Protect throwing providers at the
owning boundary before using this normal-flow pattern.

> ```lua
> --- Write a payload and close the acquired stream.
> -- @param ports table: nonthrowing open, write and close operations.
> -- @param path string: destination already validated by the caller.
> -- @param payload string: bounded bytes to write.
> -- @return number: operation failure, or close failure after success.
> local function OUTPUT_write(ports, path, payload)
>    local ret = -1
>    local stream = nil
>    local close_ret = 0
>
>    ret, stream = ports.open(path)
>    if ret ~= 0 then
>       goto function_output
>    end
>
>    ret = ports.write(stream, payload)
>    if ret ~= 0 then
>       goto function_output
>    end
>
>    ::function_output::
>    if stream ~= nil then
>       close_ret = ports.close(stream)
>       if ret == 0 then
>          ret = close_ret
>       end
>    end
>
>    return ret
> end
> ```

Keep a call and its check together even when separating surrounding transactions.
A blank line identifies a change of purpose; it does not belong between every
assignment. Keep related record initialization together. Avoid consecutive blank
lines, decorative comment banners and comments that repeat the next statement.

Preserve external JSON keys, command flags, and third-party API names. A style
change must not rename serialized fields or change failure behavior.

---

## Runtime and JIT profiles

Use [Lua performance and JIT](lua-performance.md) for the runtime matrix, sampling
profiler, trace diagnostics, hot-loop transformations, FFI rules and measurement
procedure. That guide explains each step and the evidence needed to accept an
optimization. Whitespace and comments organize source; use runtime measurements
to justify performance claims.

---

## End-of-file convention

Finish comment-capable source and configuration files with a blank line, an
`EOF` comment in that file's syntax, and a final blank line. For Lua, the last
bytes are `\n\n-- EOF\n\n`. The marker follows a module's final `return`.

Use `# EOF` for YAML, TOML, shell, CMake, and the native Conan recipe;
`/* EOF */` for C; and `<!-- EOF -->` for Markdown. Strict JSON, lockfile formats
without comments, license texts, binary files, and signed/generated evidence
must retain their required formats. Never append comments to those files.

---

## Verification

Run syntax, StyLua, Selene, LuaLS, and the Lua tests after a layout change.
Run `scripts/check/eof.lua` for the terminal-marker contract. Review grouping
and call/check adjacency as semantic requirements; a formatter cannot determine
whether two operations belong to the same transaction.

The existing tooling APIs still contain snake_case names and early-return
contracts. Formatting does not establish full naming or SESE conformance.
Migrate those interfaces with their callers and regression tests, without
claiming that the formatter enforces the entire standard.

---

## References

- [LuaRocks style guide](https://github.com/luarocks/lua-style-guide)
- [LDoc manual](https://lunarmodules.github.io/ldoc/manual/manual.md.html)
- [Lua code standard](lua-code-standard.md)
- [Lua performance and JIT](lua-performance.md)

<!-- EOF -->


<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Common Lua Pitfalls

Use this catalogue when reviewing a failure path, designing a regression test or challenging an assumption
behind a Lua implementation. It covers values, tables, text, numeric domains, normal control flow,
exceptions, resources, modules, authority and performance evidence.

Each scenario links to normative prevention controls in the [Lua standard](lua-code-standard.md) and [module
architecture](lua-module-architecture.md). The catalogue adds no competing normative rules. The
[governance](lua-code-standard.md#governance) and [example policy](lua-code-standard.md#example-policy)
apply throughout.

The Lua guides define their own conventions, explanations and verification requirements. Read the
[guide index](README.md) for source layout, documentation, runtime optimization and module design.
Distinguish project conventions from language semantics and tool capabilities. Review source and tool
configuration changes against these requirements; documentation alone does not establish conformance.

<a id="rule-index"></a>

<details>
<summary><strong>On this page</strong></summary>

<details>
<summary>Additional boundary failure scenarios</summary>

- [LPIT-055: Confusing a native address with a Lua root](#lpit-055)
- [LPIT-056: Resuming through an expired native stack frame](#lpit-056)
- [LPIT-057: Discarding a coroutine without observing close failure](#lpit-057)
- [LPIT-058: Retaining a pointer while collecting its backing cdata](#lpit-058)
- [LPIT-059: Freeing a callback before unregister has drained it](#lpit-059)
- [LPIT-060: Treating a runtime upgrade as a parser upgrade](#lpit-060)

</details>

- [Evidence model](#evidence-model)
- [Failure scenarios](#catalogue)
- [Complete semantic regression](#semantic-regression)
- [Complete resource-failure regression](#resource-regression)
- [Research and evidence record](#research-record)

<details>
<summary>Values and expressions</summary>

- [LPIT-001: Treating zero as false](#lpit-001)
- [LPIT-002: Replacing a valid false value with a default](#lpit-002)
- [LPIT-003: Using and/or as a general ternary operator](#lpit-003)
- [LPIT-004: Accidental global state](#lpit-004)
- [LPIT-005: Shadowing the intended local during initialization](#lpit-005)
- [LPIT-006: Dropping extra results with parentheses](#lpit-006)
- [LPIT-007: Losing nil-bearing tuple arity](#lpit-007)
- [LPIT-008: Confusing method and ordinary function calls](#lpit-008)

</details>

<details>
<summary>Tables and aliases</summary>

- [LPIT-009: Using length as the count of a sparse table](#lpit-009)
- [LPIT-010: Truncating iteration with ipairs](#lpit-010)
- [LPIT-011: Depending on pairs order](#lpit-011)
- [LPIT-012: Mutating traversal structure](#lpit-012)
- [LPIT-013: Mistaking reference assignment for copying](#lpit-013)
- [LPIT-014: Assuming a shallow copy breaks nested aliases](#lpit-014)
- [LPIT-015: Believing uppercase or const freezes a table](#lpit-015)
- [LPIT-016: Hidden effects during validation](#lpit-016)

</details>

<details>
<summary>Text and numbers</summary>

- [LPIT-017: Confusing byte length with character count](#lpit-017)
- [LPIT-018: Interpreting external text as a Lua pattern](#lpit-018)
- [LPIT-019: Allowing uncontrolled replacement syntax](#lpit-019)
- [LPIT-020: Using external format strings](#lpit-020)
- [LPIT-021: Accepting coercion as validation](#lpit-021)
- [LPIT-022: Missing NaN and infinity behavior](#lpit-022)
- [LPIT-023: Losing exact integer identity](#lpit-023)
- [LPIT-024: Checking capacity after addition](#lpit-024)
- [LPIT-025: Importing C arithmetic assumptions](#lpit-025)
- [LPIT-026: Using an implicit native serialization layout](#lpit-026)

</details>

<details>
<summary>Control flow and errors</summary>

- [LPIT-027: Bypassing cleanup through an early return](#lpit-027)
- [LPIT-028: Jumping into the scope of a new local](#lpit-028)
- [LPIT-029: Mistaking a shared label for exception safety](#lpit-029)
- [LPIT-030: Confusing pcall success with domain success](#lpit-030)
- [LPIT-031: Calling tostring on a hostile error object](#lpit-031)
- [LPIT-032: Overwriting the primary error during cleanup](#lpit-032)
- [LPIT-033: Publishing output after failure](#lpit-033)
- [LPIT-034: Treating assertions like removed C debug checks](#lpit-034)

</details>

<details>
<summary>Resources and execution</summary>

- [LPIT-035: Closing a borrowed handle](#lpit-035)
- [LPIT-036: Relying on GC for timely resource release](#lpit-036)
- [LPIT-037: Reassigning a to-be-closed local](#lpit-037)
- [LPIT-038: Assuming pcall makes a callback non-yielding](#lpit-038)
- [LPIT-039: Treating a yielded result as completed work](#lpit-039)
- [LPIT-040: Leaving busy state set after an exception](#lpit-040)
- [LPIT-041: Using a busy Boolean as a cross-thread lock](#lpit-041)
- [LPIT-042: Retaining a closed provider through a closure](#lpit-042)

</details>

<details>
<summary>Modules and security</summary>

- [LPIT-043: Sharing accidental singleton state through require](#lpit-043)
- [LPIT-044: Loading a peer during contract initialization](#lpit-044)
- [LPIT-045: Treating package.loaded reset as unloading](#lpit-045)
- [LPIT-046: Allowing search-path hijacking](#lpit-046)
- [LPIT-047: Treating executable Lua as configuration data](#lpit-047)
- [LPIT-048: Building shell commands from arguments](#lpit-048)
- [LPIT-049: Trusting a textual path prefix as filesystem authority](#lpit-049)
- [LPIT-050: Logging secrets or expecting secure string erasure](#lpit-050)

</details>

<details>
<summary>Verification and performance</summary>

- [LPIT-051: Calling syntax acceptance full qualification](#lpit-051)
- [LPIT-052: Assuming Markdown fences are discovered by CI](#lpit-052)
- [LPIT-053: Hiding costs outside the benchmark window](#lpit-053)
- [LPIT-054: Declaring tails or coverage a proof](#lpit-054)

</details>

</details>

---

<a id="evidence-model"></a>

## Evidence model

A failure scenario states a trigger, mechanism, affected contract and verification design. It is not proof
that every occurrence of a token is a vulnerability. Distinguish a language-semantic error, a project-policy
violation and a risk that depends on a trust boundary or execution profile.

The [Lua 5.5 manual][lua55] is the semantic reference for the locked execution target; the [Lua 5.4
manual][lua54] is a supplementary source for the configured source grammar. Repository configuration and the
toolchain snapshot in the [standard](lua-code-standard.md#repository-profile) bound what is actually
supported. Each entry explains the Lua mechanism, prevention rule and observable failure. Native
extensions also need explicit memory, ABI and resource contracts at their Lua boundary.

Tests should inspect state and resource obligations after failure, not only the returned value. Use bounded,
deterministic fault injection. Do not execute shell-injection, deletion, arbitrary bytecode or uncontrolled
exhaustion fragments. Example snippets are contextual unless explicitly named as a complete program. A
detected failure needs its applicability and root cause reviewed; passing a test does not establish an
unmeasured global property.

---

<a id="catalogue"></a>

## Failure scenarios

---

<a id="lpit-001"></a>

### LPIT-001: Treating zero as false

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A status-first operation returns zero on success, and the caller uses it directly as an if
condition.

**Failure mechanism:** Only nil and false are false values in Lua. Zero and an empty string are true values,
unlike common C condition idioms.

**Prevention controls:** [LSTYLE-029](lua-code-standard.md#lstyle-029),
[LSTYLE-043](lua-code-standard.md#lstyle-043), [LSTYLE-044](lua-code-standard.md#lstyle-044).

**Verification design:** Exercise zero, negative status, nil, false and an unexpected status type; assert
the selected branch.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> if operation_status then
>    -- Incorrectly interpreted as failure or success by a C-style assumption.
> end
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local has_succeeded = operation_status == 0
> ```

---

<a id="lpit-002"></a>

### LPIT-002: Replacing a valid false value with a default

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A Boolean configuration uses option or default_value to apply a default.

**Failure mechanism:** The or expression selects its right operand for both nil and false. A deliberate
false setting can disappear.

**Prevention controls:** [LSTYLE-029](lua-code-standard.md#lstyle-029),
[LSTYLE-030](lua-code-standard.md#lstyle-030).

**Verification design:** Pass nil, false and true separately and verify only nil selects the default.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> local is_enabled = config.is_enabled or true
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local is_enabled = config.is_enabled
>
> if is_enabled == nil then
>    is_enabled = true
> end
> ```

---

<a id="lpit-003"></a>

### LPIT-003: Using and/or as a general ternary operator

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** The selected true-branch result can be false or nil.

**Failure mechanism:** condition and left or right then chooses right even when condition was true. Logical
operators return operands, not normalized Boolean values.

**Prevention controls:** [LSTYLE-030](lua-code-standard.md#lstyle-030).

**Verification design:** Use false, nil, zero and an empty string as candidate branch results.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> local chosen = is_selected and false or true
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local chosen = true
>
> if is_selected then
>    chosen = false
> end
> ```

---

<a id="lpit-004"></a>

### LPIT-004: Accidental global state

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** An assignment omits local inside an ordinary module.

**Failure mechanism:** The assignment targets the applicable environment rather than a new lexical local and
can couple otherwise independent callers.

**Prevention controls:** [LSTYLE-008](lua-code-standard.md#lstyle-008),
[LSTYLE-018](lua-code-standard.md#lstyle-018), [LMOD-009](lua-module-architecture.md#lmod-009).

**Verification design:** Load the module in an isolated fixture and compare environment keys before and
after its operations.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> current_packet = packet
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local current_packet = packet
> ```

---

<a id="lpit-005"></a>

### LPIT-005: Shadowing the intended local during initialization

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A new local uses the same name as an outer variable or function.

**Failure mechanism:** The new local scope starts after its declaration; the initializer can refer to an
outer binding and make intent unclear.

**Prevention controls:** [LSTYLE-017](lua-code-standard.md#lstyle-017),
[LSTYLE-018](lua-code-standard.md#lstyle-018).

**Verification design:** Review shadow warnings and add tests with different outer and inner values.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> local value = value or 10
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local configured_value = input_value
>
> if configured_value == nil then
>    configured_value = 10
> end
> ```

---

<a id="lpit-006"></a>

### LPIT-006: Dropping extra results with parentheses

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A caller adds parentheses around a function call in a multi-result assignment.

**Failure mechanism:** An expression in parentheses is adjusted to one result. The status may survive while
the payload disappears.

**Prevention controls:** [LSTYLE-035](lua-code-standard.md#lstyle-035),
[LSTYLE-043](lua-code-standard.md#lstyle-043).

**Verification design:** Test success with payload, failure with nil, and a valid false payload.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> local ret, payload = (codec.CODEC_decode(input))
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local ret, payload = codec.CODEC_decode(input)
> ```

---

<a id="lpit-007"></a>

### LPIT-007: Losing nil-bearing tuple arity

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** Results or varargs are stored in a table and later recovered with # or an implicit unpack
range.

**Failure mechanism:** Nil entries are absent keys and the length of a non-sequence does not preserve the
original argument count.

**Prevention controls:** [LSTYLE-031](lua-code-standard.md#lstyle-031),
[LSTYLE-035](lua-code-standard.md#lstyle-035).

**Verification design:** Round-trip tuples containing middle nil values and a trailing nil with a separately
recorded count.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> local values = { first, nil, third }
> local count = #values
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local values = { first, nil, third }
> local value_count = 3
> ```

---

<a id="lpit-008"></a>

### LPIT-008: Confusing method and ordinary function calls

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A caller changes dot invocation to colon or the reverse without changing the contract.

**Failure mechanism:** Colon syntax supplies the receiver as the first argument; a positional callback can
receive shifted arguments.

**Prevention controls:** [LSTYLE-022](lua-code-standard.md#lstyle-022),
[LSTYLE-065](lua-code-standard.md#lstyle-065), [LMOD-012](lua-module-architecture.md#lmod-012).

**Verification design:** Call through the documented shape and use a mock that validates every argument
identity.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> sink:SINK_write(context, payload) -- Wrong for a two-argument function port.
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local ret = sink.SINK_write(context, payload)
> ```

---

<a id="lpit-009"></a>

### LPIT-009: Using length as the count of a sparse table

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A table contains holes, non-sequential integer keys or map keys.

**Failure mechanism:** # identifies a border according to the language rules; it is not a general key
counter. Different valid borders must not be treated as corruption.

**Prevention controls:** [LSTYLE-031](lua-code-standard.md#lstyle-031).

**Verification design:** Test dense sequences, an early hole and a map. Do not assert one specific # result
for a table with multiple borders.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> local items = { [1] = "a", [3] = "c" }
> local item_count = #items
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local items = { "a", "b", "c" }
> local item_count = 3
> ```

---

<a id="lpit-010"></a>

### LPIT-010: Truncating iteration with ipairs

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** An intended sequence contains a nil entry before later valid elements.

**Failure mechanism:** ipairs stops at the first absent integer entry. Later data can be silently omitted
from validation or output.

**Prevention controls:** [LSTYLE-031](lua-code-standard.md#lstyle-031),
[LSTYLE-032](lua-code-standard.md#lstyle-032).

**Verification design:** Place a hole at the first, middle and last positions and verify the declared
sequence contract rejects it or uses explicit indexing.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> for _, value in ipairs(sparse_values) do
>    -- Later values can be missed.
> end
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> for value_idx = 1, value_count do
>    local value = values[value_idx]
>    -- Validate presence according to the explicit sequence contract.
> end
> ```

---

<a id="lpit-011"></a>

### LPIT-011: Depending on pairs order

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A serializer, snapshot or test expects pairs to emit keys in a stable order.

**Failure mechanism:** Table traversal order is not a portable sorting contract. Stable output needs an
explicit ordering scheme.

**Prevention controls:** [LSTYLE-032](lua-code-standard.md#lstyle-032),
[LSTYLE-042](lua-code-standard.md#lstyle-042).

**Verification design:** Create equal maps through different insertion histories and compare canonical
output.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> for key, value in pairs(record) do
>    -- Appending here does not establish canonical order.
> end
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local ordered_keys = { "id", "length", "state" }
>
> for _, key in ipairs(ordered_keys) do
>    local value = record[key]
>    -- Encode this field through the boundary codec.
> end
> ```

---

<a id="lpit-012"></a>

### LPIT-012: Mutating traversal structure

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A loop adds previously absent keys while traversing the same table.

**Failure mechanism:** This is outside the traversal guarantees normally relied on for next/pairs. Even
allowed value updates or clearing keys need an explicit algorithm.

**Prevention controls:** [LSTYLE-032](lua-code-standard.md#lstyle-032).

**Verification design:** Test insertion, deletion and value-only updates separately using the documented
algorithm.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> for key in pairs(record) do
>    record[key .. "_copy"] = record[key]
> end
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local updates = {}
>
> for key, value in pairs(record) do
>    updates[key .. "_copy"] = value
> end
> ```

---

<a id="lpit-013"></a>

### LPIT-013: Mistaking reference assignment for copying

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A module stores a caller-owned configuration table directly and expects an immutable snapshot.

**Failure mechanism:** Both references identify the same table; later caller mutation changes module
behavior.

**Prevention controls:** [LSTYLE-033](lua-code-standard.md#lstyle-033),
[LMOD-010](lua-module-architecture.md#lmod-010).

**Verification design:** Mutate the input after construction and check whether behavior matches the
published retention contract.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> local private_config = caller_config
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local private_config = {
>    capacity_bytes = caller_config.capacity_bytes,
>    is_enabled = caller_config.is_enabled,
> }
> ```

---

<a id="lpit-014"></a>

### LPIT-014: Assuming a shallow copy breaks nested aliases

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** Top-level fields are copied but one field is a mutable nested table.

**Failure mechanism:** The copied field still references the same nested object. Recursive copying also
needs cycle, depth and identity rules.

**Prevention controls:** [LSTYLE-033](lua-code-standard.md#lstyle-033),
[LSTYLE-050](lua-code-standard.md#lstyle-050), [LMOD-010](lua-module-architecture.md#lmod-010).

**Verification design:** Mutate a nested field, introduce a shared subtree and test the selected copy
policy.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> local snapshot = { limits = caller_config.limits }
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local snapshot = {
>    max_payload_bytes = caller_config.limits.max_payload_bytes,
> }
> ```

---

<a id="lpit-015"></a>

### LPIT-015: Believing uppercase or const freezes a table

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A table is named as a constant or assigned to a non-reassignable local.

**Failure mechanism:** Naming does not prevent field mutation; a binding restriction is not deep
immutability.

**Prevention controls:** [LSTYLE-010](lua-code-standard.md#lstyle-010),
[LSTYLE-034](lua-code-standard.md#lstyle-034), [LSTYLE-052](lua-code-standard.md#lstyle-052).

**Verification design:** Review all aliases and mutation sites and verify the public API does not leak the
mutable policy table.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> local LIMITS = { count = 4 }
> LIMITS.count = 100
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local LIMITS_COUNT = 4
> ```

---

<a id="lpit-016"></a>

### LPIT-016: Hidden effects during validation

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A boundary accepts an arbitrary table with metatable-controlled field access.

**Failure mechanism:** Indexing, length, conversion or other operations can execute metamethod code, throw
or mutate state during what appears to be a pure check.

**Prevention controls:** [LSTYLE-028](lua-code-standard.md#lstyle-028),
[LSTYLE-052](lua-code-standard.md#lstyle-052), [LSTYLE-057](lua-code-standard.md#lstyle-057).

**Verification design:** Use metatables that count or reject field access; enforce the declared plain-record
or adapter contract.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> local capacity_bytes = request.capacity_bytes
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local is_plain_record = type(request) == "table"
>    and getmetatable(request) == nil
> ```

---

<a id="lpit-017"></a>

### LPIT-017: Confusing byte length with character count

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A text operation uses # or string.sub indices as if they were Unicode character positions.

**Failure mechanism:** Lua strings hold bytes. A multibyte character can be split or counted as several
bytes.

**Prevention controls:** [LSTYLE-036](lua-code-standard.md#lstyle-036).

**Verification design:** Test ASCII, multibyte UTF-8, embedded NUL and malformed byte sequences with the
selected contract.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> local first_character = string.sub(text, 1, 1)
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local text_size_bytes = #text
> local codepoint_count, invalid_byte_idx = utf8.len(text)
> ```

---

<a id="lpit-018"></a>

### LPIT-018: Interpreting external text as a Lua pattern

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A literal search uses string.find without plain=true.

**Failure mechanism:** Pattern metacharacters change the search and malformed patterns may raise errors.

**Prevention controls:** [LSTYLE-037](lua-code-standard.md#lstyle-037),
[LSTYLE-046](lua-code-standard.md#lstyle-046).

**Verification design:** Search for literal dots, brackets, percent signs and an empty needle according to
the API contract.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> local start_idx = string.find(haystack, needle)
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local start_idx = string.find(haystack, needle, 1, true)
> ```

---

<a id="lpit-019"></a>

### LPIT-019: Allowing uncontrolled replacement syntax

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** External replacement data is used as the replacement template in gsub.

**Failure mechanism:** Percent sequences in a replacement string have special meaning. Literal external data
needs a reviewed replacement strategy.

**Prevention controls:** [LSTYLE-038](lua-code-standard.md#lstyle-038).

**Verification design:** Exercise percent characters and capture-like sequences and assert exact output
bytes.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> local output = string.gsub(input, pattern, replacement)
> ```

**Contextual source fragment (requires an enclosing scope):**

> ```text
> Use a validated replacement callback that returns literal data, or a
> reviewed escaping adapter with exact-byte tests.
> ```

---

<a id="lpit-020"></a>

### LPIT-020: Using external format strings

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A diagnostic or serializer treats externally supplied text as a string.format template.

**Failure mechanism:** Format directives can change required arguments and trigger errors or excessive
output.

**Prevention controls:** [LSTYLE-038](lua-code-standard.md#lstyle-038),
[LSTYLE-050](lua-code-standard.md#lstyle-050), [LSTYLE-061](lua-code-standard.md#lstyle-061).

**Verification design:** Test percent sequences, unsupported directives and oversized field widths without
allocating uncontrolled output.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> local output = string.format(user_template, value)
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local output = string.format("value=%s", validated_text)
> ```

---

<a id="lpit-021"></a>

### LPIT-021: Accepting coercion as validation

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A numeric boundary silently applies tonumber or arithmetic coercion to arbitrary input.

**Failure mechanism:** Conversion can accept representations outside the protocol grammar and does not
establish integer, finite or bounded domains.

**Prevention controls:** [LSTYLE-028](lua-code-standard.md#lstyle-028),
[LSTYLE-039](lua-code-standard.md#lstyle-039).

**Verification design:** Exercise whitespace, fractions, exponent notation, empty strings and non-finite
values under the stated input grammar.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> local size_bytes = tonumber(input) or 0
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local is_valid = type(value) == "number"
>    and value == value
>    and value >= 0
>    and value <= 4096
>    and value % 1 == 0
> ```

---

<a id="lpit-022"></a>

### LPIT-022: Missing NaN and infinity behavior

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A check only compares a number against a lower bound or only checks its type.

**Failure mechanism:** A number can be non-finite in the selected numeric model. NaN is unequal to itself
and ordinary comparisons do not behave like a total order.

**Prevention controls:** [LSTYLE-039](lua-code-standard.md#lstyle-039).

**Verification design:** Include NaN, both infinities, negative zero and boundary finite values where the
profile supports them.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> local is_valid = type(value) == "number"
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local is_valid = type(value) == "number"
>    and value == value
>    and value >= 0
>    and value <= 4096
> ```

---

<a id="lpit-023"></a>

### LPIT-023: Losing exact integer identity

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A large external identifier is represented through a floating-point conversion.

**Failure mechanism:** The representable exact-integer range depends on the numeric model. Distinct external
identifiers can collapse to one numeric value.

**Prevention controls:** [LSTYLE-039](lua-code-standard.md#lstyle-039),
[LSTYLE-042](lua-code-standard.md#lstyle-042), [LSTYLE-062](lua-code-standard.md#lstyle-062).

**Verification design:** Round-trip values around the profile exactness limit using the specified external
representation.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> local external_id = tonumber(decimal_identifier)
> ```

**Contextual source fragment (requires an enclosing scope):**

> ```text
> Keep identifiers as validated strings when numeric operations are not
> required; otherwise enforce the selected exact integer domain.
> ```

---

<a id="lpit-024"></a>

### LPIT-024: Checking capacity after addition

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** The code computes offset+length before proving both operands fit the accepted domain.

**Failure mechanism:** Integer wrap or a loss of numeric precision can make the later bound comparison
meaningless for the intended contract.

**Prevention controls:** [LSTYLE-039](lua-code-standard.md#lstyle-039),
[LSTYLE-040](lua-code-standard.md#lstyle-040).

**Verification design:** Test zero, full capacity, near-capacity inputs and out-of-domain values before
computing the sum.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> local fits = offset_bytes + length_bytes <= capacity_bytes
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local fits = offset_bytes >= 0
>    and offset_bytes <= capacity_bytes
>    and length_bytes >= 0
>    and length_bytes <= capacity_bytes - offset_bytes
> ```

---

<a id="lpit-025"></a>

### LPIT-025: Importing C arithmetic assumptions

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A Lua algorithm assumes C truncating division, C remainder signs or a fixed-width C bit-shift
model.

**Failure mechanism:** Lua operators have their own division, modulo, integer and bitwise semantics; the
selected runtime manual is authoritative.

**Prevention controls:** [LSTYLE-004](lua-code-standard.md#lstyle-004),
[LSTYLE-039](lua-code-standard.md#lstyle-039), [LSTYLE-041](lua-code-standard.md#lstyle-041).

**Verification design:** Test negative operands, zero divisors and shift boundaries under each claimed
runtime.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> Assume -3 // 2 has the same truncation contract as C integer division.
> ```

**Contextual source fragment (requires an enclosing scope):**

> ```text
> State quotient/remainder conventions and test negative operands before
> using the result as an index or protocol field.
> ```

---

<a id="lpit-026"></a>

### LPIT-026: Using an implicit native serialization layout

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A wire format inherits native sizes, alignment or byte order from a packing operation or native
binding.

**Failure mechanism:** The data ceases to have a stable cross-platform representation. Packing APIs also
need checker-profile support.

**Prevention controls:** [LSTYLE-042](lua-code-standard.md#lstyle-042),
[LSTYLE-062](lua-code-standard.md#lstyle-062).

**Verification design:** Compare known byte vectors on supported targets and reject truncation, trailing
data and length mismatch.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> Serialize the native in-memory table or C object layout directly.
> ```

**Contextual source fragment (requires an enclosing scope):**

> ```text
> Use an explicit byte order, field widths, encoding and total byte count;
> keep the codec at the serialization boundary.
> ```

---

<a id="lpit-027"></a>

### LPIT-027: Bypassing cleanup through an early return

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A function acquires a resource and returns directly from an intermediate failure branch.

**Failure mechanism:** The function no longer has the common cleanup point required by project SESE policy.

**Prevention controls:** [LSTYLE-023](lua-code-standard.md#lstyle-023),
[LSTYLE-047](lua-code-standard.md#lstyle-047).

**Verification design:** Fail each step after acquisition and verify every acquired resource receives
exactly one release attempt.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> if has_failed then
>    return ERROR_CODE
> end
> ```

**Contextual source fragment (requires an enclosing scope):**

> ```text
> ret = ERROR_CODE
> goto function_output
> ```

---

<a id="lpit-028"></a>

### LPIT-028: Jumping into the scope of a new local

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A forward goto crosses a local declaration and targets a label where that local is still in
scope.

**Failure mechanism:** Lua rejects a goto that enters the scope of a local variable. Copying a C cleanup
shape mechanically can create a syntax error.

**Prevention controls:** [LSTYLE-017](lua-code-standard.md#lstyle-017),
[LSTYLE-024](lua-code-standard.md#lstyle-024).

**Verification design:** Compile the complete enclosing function, not a disconnected branch fragment.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> goto function_output
> local result = 1
> ::function_output::
> return result
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local ret = 0
> local result = nil
>
> -- All forward exits occur after these declarations.
>
> ::function_output::
> return ret, result
> ```

---

<a id="lpit-029"></a>

### LPIT-029: Mistaking a shared label for exception safety

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** An operation between acquisition and the label raises an unprotected Lua error.

**Failure mechanism:** An error unwinds control rather than executing a goto to the label. Source-level
normal SESE alone cannot guarantee cleanup.

**Prevention controls:** [LSTYLE-023](lua-code-standard.md#lstyle-023),
[LSTYLE-046](lua-code-standard.md#lstyle-046), [LSTYLE-047](lua-code-standard.md#lstyle-047).

**Verification design:** Inject exceptions at every fallible callback and verify cleanup through the
protection owner.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> local ret = port.WORK_run(context)
> -- Assuming every raised error reaches function_output is incorrect.
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local has_completed, operation_ret = pcall(port.WORK_run, context)
> ```

---

<a id="lpit-030"></a>

### LPIT-030: Confusing pcall success with domain success

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** The protected function returns a negative status without raising an error.

**Failure mechanism:** pcall returns true because execution completed normally; the operation can still have
failed.

**Prevention controls:** [LSTYLE-043](lua-code-standard.md#lstyle-043),
[LSTYLE-044](lua-code-standard.md#lstyle-044), [LSTYLE-046](lua-code-standard.md#lstyle-046).

**Verification design:** Return zero and a negative status from the same callback, then throw an error in a
separate case.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> local is_success = pcall(port.WORK_run, context)
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local has_completed, operation_ret = pcall(port.WORK_run, context)
> local has_succeeded = has_completed and operation_ret == 0
> ```

---

<a id="lpit-031"></a>

### LPIT-031: Calling tostring on a hostile error object

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A catch boundary receives an arbitrary table or userdata and formats it with tostring.

**Failure mechanism:** A conversion metamethod can raise another error or expose unintended information
while handling the first error.

**Prevention controls:** [LSTYLE-046](lua-code-standard.md#lstyle-046),
[LSTYLE-061](lua-code-standard.md#lstyle-061).

**Verification design:** Throw a table with a failing __tostring handler and verify a bounded generic
diagnostic is used.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> local diagnostic = tostring(error_value)
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local diagnostic = "callback failed"
>
> if type(error_value) == "string" then
>    diagnostic = string.sub(error_value, 1, 160)
> end
> ```

---

<a id="lpit-032"></a>

### LPIT-032: Overwriting the primary error during cleanup

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** The cleanup status is assigned directly to ret after an earlier failure.

**Failure mechanism:** The original operation failure can disappear or be replaced by an unrelated close
result.

**Prevention controls:** [LSTYLE-047](lua-code-standard.md#lstyle-047),
[LMOD-023](lua-module-architecture.md#lmod-023).

**Verification design:** Combine a failed operation with successful close and with failed close; assert the
precedence policy.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> ret = resource.RESOURCE_close(context, handle)
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> if ret == 0 and close_ret ~= 0 then
>    ret = close_ret
> end
> ```

---

<a id="lpit-033"></a>

### LPIT-033: Publishing output after failure

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A partially built object or stale payload is returned alongside a failure status.

**Failure mechanism:** Callers can accidentally observe invalid state or treat old data as a new result.

**Prevention controls:** [LSTYLE-035](lua-code-standard.md#lstyle-035),
[LSTYLE-043](lua-code-standard.md#lstyle-043), [LSTYLE-049](lua-code-standard.md#lstyle-049).

**Verification design:** Fail before and after each mutation and verify output=nil on every failed return.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> return ret, partially_initialized_object
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> if ret ~= 0 then
>    output = nil
> end
>
> -- The single final return follows the shared output label.
> ```

---

<a id="lpit-034"></a>

### LPIT-034: Treating assertions like removed C debug checks

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** An implementation puts required behavior inside assert and expects a release build to remove
it.

**Failure mechanism:** Lua assert is an ordinary runtime function call; the C debug/release assertion policy
does not transfer automatically.

**Prevention controls:** [LSTYLE-045](lua-code-standard.md#lstyle-045).

**Verification design:** Run the same invalid external inputs under the deployment invocation and verify
explicit status handling.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> assert(port.WRITE_commit(context))
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local ret = port.WRITE_commit(context)
>
> if ret ~= 0 then
>    -- Propagate through the operation common output.
> end
> ```

---

<a id="lpit-035"></a>

### LPIT-035: Closing a borrowed handle

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** Cleanup indiscriminately closes every handle referenced by a module.

**Failure mechanism:** Reachability does not grant ownership, and another component may still own and need
that handle.

**Prevention controls:** [LSTYLE-047](lua-code-standard.md#lstyle-047),
[LMOD-018](lua-module-architecture.md#lmod-018).

**Verification design:** Give the module an owner-marked borrowed mock and verify zero close calls.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> borrowed_file:close()
> ```

**Contextual source fragment (requires an enclosing scope):**

> ```text
> The contract records OWNED or BORROWED. Only the owner closes a borrowed
> resource; an explicit transfer changes ownership on success.
> ```

---

<a id="lpit-036"></a>

### LPIT-036: Relying on GC for timely resource release

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A file or native resource is left reachable or abandoned until collection happens.

**Failure mechanism:** Resource availability and semantic completion cannot depend on an assumed collection
schedule.

**Prevention controls:** [LSTYLE-047](lua-code-standard.md#lstyle-047),
[LSTYLE-056](lua-code-standard.md#lstyle-056), [LMOD-024](lua-module-architecture.md#lmod-024).

**Verification design:** Repeat the lifecycle without forcing GC and count open handles and explicit
releases.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> file = nil
> collectgarbage("collect") -- Used as the normal close protocol.
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local close_ret = resource.RESOURCE_close(context, handle)
> ```

---

<a id="lpit-037"></a>

### LPIT-037: Reassigning a to-be-closed local

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** Code declares local `resource <close>` and later assigns nil to it as if transferring ordinary
ownership.

**Failure mechanism:** A to-be-closed variable has restrictions different from an ordinary mutable local.
Manual cleanup and the close metamethod also risk duplicate release.

**Prevention controls:** [LSTYLE-048](lua-code-standard.md#lstyle-048),
[LMOD-024](lua-module-architecture.md#lmod-024).

**Verification design:** Compile and test only within the explicitly qualified close-enabled profile; test
normal and error unwinding.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> local resource <close> = acquire()
> resource = nil
> ```

**Contextual source fragment (requires an enclosing scope):**

> ```text
> Choose manual owned-handle cleanup or a qualified to-be-closed scope.
> Do not mix both protocols for the same resource.
> ```

---

<a id="lpit-038"></a>

### LPIT-038: Assuming pcall makes a callback non-yielding

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A synchronous port uses pcall and then assumes the callback cannot suspend.

**Failure mechanism:** Protection against errors and permission to yield are separate aspects of the runtime
and host API.

**Prevention controls:** [LSTYLE-054](lua-code-standard.md#lstyle-054),
[LMOD-025](lua-module-architecture.md#lmod-025).

**Verification design:** Use a callback that attempts to yield in each supported calling context and verify
the enforced contract.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> pcall(callback, context) -- Assumed to enforce a non-yielding boundary.
> ```

**Contextual source fragment (requires an enclosing scope):**

> ```text
> Document and enforce the yield policy at the host/adapter; test it
> separately from exception handling.
> ```

---

<a id="lpit-039"></a>

### LPIT-039: Treating a yielded result as completed work

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A coroutine.resume result is processed as the final operation result without checking lifecycle
state.

**Failure mechanism:** A successful resume can represent suspension rather than completion. Resources may
still be in use.

**Prevention controls:** [LSTYLE-054](lua-code-standard.md#lstyle-054),
[LMOD-022](lua-module-architecture.md#lmod-022).

**Verification design:** Exercise created, suspended, completed and failed coroutines and all supported
shutdown transitions.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> local has_succeeded, result = coroutine.resume(worker)
> -- The coroutine may only have yielded.
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local worker_state = coroutine.status(worker)
> -- Interpret resume values under the operation state machine.
> ```

---

<a id="lpit-040"></a>

### LPIT-040: Leaving busy state set after an exception

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** An operation marks the instance busy and the callback raises before busy is cleared.

**Failure mechanism:** All later calls can fail permanently unless error handling converges on state
restoration.

**Prevention controls:** [LSTYLE-046](lua-code-standard.md#lstyle-046),
[LSTYLE-055](lua-code-standard.md#lstyle-055), [LMOD-016](lua-module-architecture.md#lmod-016).

**Verification design:** Throw from the callback, then issue a valid operation and verify the instance is
usable.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> is_busy = true
> callback(context)
> is_busy = false
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> is_busy = true
> has_completed, callback_ret = pcall(callback, context)
> is_busy = false
> ```

---

<a id="lpit-041"></a>

### LPIT-041: Using a busy Boolean as a cross-thread lock

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** Native threads can enter a Lua state or object concurrently.

**Failure mechanism:** An ordinary Lua field or upvalue does not establish a host synchronization or
memory-ordering protocol.

**Prevention controls:** [LSTYLE-055](lua-code-standard.md#lstyle-055),
[LSTYLE-062](lua-code-standard.md#lstyle-062), [LMOD-026](lua-module-architecture.md#lmod-026).

**Verification design:** Review the host state-access discipline and use target-appropriate native
concurrency tests.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> if not is_busy then
>    is_busy = true
>    -- Assumed safe between native threads.
> end
> ```

**Contextual source fragment (requires an enclosing scope):**

> ```text
> The host owns exclusive state access or a qualified synchronization
> protocol; the Lua busy flag only detects synchronous reentry.
> ```

---

<a id="lpit-042"></a>

### LPIT-042: Retaining a closed provider through a closure

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A callback closure keeps a provider wrapper reachable after provider shutdown.

**Failure mechanism:** The wrapper remains in memory but the external resource is no longer semantically
valid.

**Prevention controls:** [LSTYLE-053](lua-code-standard.md#lstyle-053),
[LMOD-017](lua-module-architecture.md#lmod-017), [LMOD-022](lua-module-architecture.md#lmod-022).

**Verification design:** Retain callbacks across provider close and verify shutdown ordering prevents their
invocation.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> Keep a callback forever because its captured table cannot be collected.
> ```

**Contextual source fragment (requires an enclosing scope):**

> ```text
> Stop and drain the consumer, release callbacks, then close the provider.
> ```

---

<a id="lpit-043"></a>

### LPIT-043: Sharing accidental singleton state through require

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** The module export table carries mutable per-request or per-client state.

**Failure mechanism:** require normally reuses the loaded module value, so independent users can share the
same mutable state.

**Prevention controls:** [LSTYLE-008](lua-code-standard.md#lstyle-008),
[LMOD-009](lua-module-architecture.md#lmod-009).

**Verification design:** Create two clients through the supported API and interleave distinct workloads.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> module.current_request = request
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local instance_state = { current_request = nil }
> -- Created separately for each public instance.
> ```

---

<a id="lpit-044"></a>

### LPIT-044: Loading a peer during contract initialization

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A contract file imports an implementation or a peer directly requires another peer.

**Failure mechanism:** The apparent interface dependency becomes a runtime implementation dependency and
violates project architecture.

**Prevention controls:** [LMOD-003](lua-module-architecture.md#lmod-003),
[LMOD-005](lua-module-architecture.md#lmod-005), [LMOD-031](lua-module-architecture.md#lmod-031).

**Verification design:** Remove peer implementations from the isolated test tree and load the contract and
consumer.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> local sink = require("peer_storage") -- Inside the reusable consumer.
> ```

**Contextual source fragment (requires an enclosing scope):**

> ```text
> The composition root injects a consumer-owned sink function and context.
> ```

---

<a id="lpit-045"></a>

### LPIT-045: Treating package.loaded reset as unloading

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** An application clears a cache entry to reset or replace a module in use.

**Failure mechanism:** Existing tables, closures, native references and suspended work may still refer to
the old implementation.

**Prevention controls:** [LSTYLE-058](lua-code-standard.md#lstyle-058),
[LMOD-029](lua-module-architecture.md#lmod-029).

**Verification design:** Retain an old instance and callback while attempting reload; verify the explicit
migration/quiescence protocol.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> package.loaded["provider"] = nil
> ```

**Contextual source fragment (requires an enclosing scope):**

> ```text
> Reload is a separately reviewed lifecycle, not a normal reset operation.
> ```

---

<a id="lpit-046"></a>

### LPIT-046: Allowing search-path hijacking

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** Startup resolves trusted code through an attacker-controlled current directory or path.

**Failure mechanism:** The logical module name can select a different implementation with the program
authority.

**Prevention controls:** [LSTYLE-058](lua-code-standard.md#lstyle-058),
[LMOD-028](lua-module-architecture.md#lmod-028).

**Verification design:** Start from a disposable unrelated directory with a harmless colliding module and
verify it cannot be selected.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> package.path = user_directory .. "/?.lua;" .. package.path
> ```

**Contextual source fragment (requires an enclosing scope):**

> ```text
> Resolve a verified root and use approved module names and loading paths.
> ```

---

<a id="lpit-047"></a>

### LPIT-047: Treating executable Lua as configuration data

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** An input file is loaded and executed to recover a configuration table.

**Failure mechanism:** Returning a table does not make the preceding code non-executable or limit its
authority and cost.

**Prevention controls:** [LSTYLE-057](lua-code-standard.md#lstyle-057),
[LSTYLE-060](lua-code-standard.md#lstyle-060), [LBAN-001](lua-code-standard.md#lban-001).

**Verification design:** Use a non-executable data parser and test schema, byte, element and depth limits.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> local config = dofile(user_selected_path)
> ```

**Contextual source fragment (requires an enclosing scope):**

> ```text
> Decode bounded data and validate the resulting plain record.
> ```

---

<a id="lpit-048"></a>

### LPIT-048: Building shell commands from arguments

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A program concatenates paths, branch names or payload text into a command string.

**Failure mechanism:** The downstream shell may interpret metacharacters, expansion and quoting differently
from the caller intent.

**Prevention controls:** [LSTYLE-059](lua-code-standard.md#lstyle-059),
[LBAN-006](lua-code-standard.md#lban-006), [LMOD-027](lua-module-architecture.md#lmod-027).

**Verification design:** Use harmless arguments containing spaces, quotes, newlines and metacharacters;
verify exact argv in a mock.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> os.execute("tool " .. user_value)
> ```

**Contextual Lua fragment (requires its enclosing contract):**

> ```lua
> local ret = process.PROCESS_run({ "tool", user_value })
> ```

---

<a id="lpit-049"></a>

### LPIT-049: Trusting a textual path prefix as filesystem authority

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** An input path passes a string prefix check before privileged file access.

**Failure mechanism:** Traversal, platform path rules, symbolic links and races can make the resolved object
different from the checked string.

**Prevention controls:** [LSTYLE-060](lua-code-standard.md#lstyle-060),
[LMOD-027](lua-module-architecture.md#lmod-027).

**Verification design:** Test traversal and symlink behavior through the actual platform adapter in a
disposable fixture.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> local is_allowed = string.sub(path, 1, #root) == root
> ```

**Contextual source fragment (requires an enclosing scope):**

> ```text
> Use the approved filesystem boundary and its resolution/authority
> contract, not a generic Lua prefix helper.
> ```

---

<a id="lpit-050"></a>

### LPIT-050: Logging secrets or expecting secure string erasure

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A diagnostic includes credentials, or code assigns nil to a secret string and calls this secure
erasure.

**Failure mechanism:** Copies, immutable strings, logs and runtime-managed storage can retain the data
beyond that assignment.

**Prevention controls:** [LSTYLE-061](lua-code-standard.md#lstyle-061).

**Verification design:** Inspect diagnostics and fault paths with synthetic secrets and verify redaction
without claiming memory erasure.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> print("token=" .. token)
> token = nil -- Incorrectly claimed as secure zeroization.
> ```

**Contextual source fragment (requires an enclosing scope):**

> ```text
> Emit a bounded event identifier; keep secret-handling guarantees in
> the qualified security boundary.
> ```

---

<a id="lpit-051"></a>

### LPIT-051: Calling syntax acceptance full qualification

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A source passes one runtime parser or linter and the entire repository profile is declared
supported.

**Failure mechanism:** The runtime, Lua54 formatter grammar, custom Selene API catalogue and LuaLS model are
separate constraints.

**Prevention controls:** [LSTYLE-001](lua-code-standard.md#lstyle-001),
[LSTYLE-064](lua-code-standard.md#lstyle-064), [LSTYLE-066](lua-code-standard.md#lstyle-066).

**Verification design:** Record each configured tool stage independently and fail when a mandatory tool is
missing.

**Source context:** [Repository runner][check-lua]; [Toolchain lock][toolchain].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> luac -p passed; therefore every repository check passed.
> ```

**Contextual source fragment (requires an enclosing scope):**

> ```text
> parser + dictionary + Selene + StyLua + LuaLS + required project tests
> ```

---

<a id="lpit-052"></a>

### LPIT-052: Assuming Markdown fences are discovered by CI

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** Only the three Markdown documents are added, and their Lua examples are never extracted.

**Failure mechanism:** The current Lua runner does not extract Markdown fences, so its result supplies no
direct example execution evidence.

**Prevention controls:** [LSTYLE-005](lua-code-standard.md#lstyle-005),
[LSTYLE-067](lua-code-standard.md#lstyle-067).

**Verification design:** Extract named complete examples, check syntax, run tests and report actual tool
versions.

**Source context:** [Repository runner][check-lua].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> The Markdown check passed, therefore all embedded programs were tested.
> ```

**Contextual source fragment (requires an enclosing scope):**

> ```text
> Documentation validation and extracted Lua program validation are
> separate records.
> ```

---

<a id="lpit-053"></a>

### LPIT-053: Hiding costs outside the benchmark window

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** An experiment excludes startup, validation, collection or cleanup without reporting the
exclusion.

**Failure mechanism:** The measured improvement may only shift necessary work to another phase or increase
memory retention.

**Prevention controls:** [LPERF-001](lua-code-standard.md#lperf-001),
[LPERF-003](lua-code-standard.md#lperf-003), [LPERF-014](lua-code-standard.md#lperf-014).

**Verification design:** Measure a complete lifecycle and report separate cold and steady-state results.
For JIT workloads, follow the [measurement procedure](lua-performance.md#measurement-procedure),
record trace behavior and compare with the same runtime in interpreter mode.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> Disable GC, time only the loop and report universal latency improvement.
> ```

**Contextual source fragment (requires an enclosing scope):**

> ```text
> Measure the public operation and full workload with recorded GC policy.
> ```

---

<a id="lpit-054"></a>

### LPIT-054: Declaring tails or coverage a proof

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A percentile, observed maximum or coverage report is treated as a correctness or worst-case
guarantee.

**Failure mechanism:** Those measurements have finite scope and do not establish untested paths, future
scheduling or all admissible inputs.

**Prevention controls:** [LSTYLE-069](lua-code-standard.md#lstyle-069),
[LPERF-004](lua-code-standard.md#lperf-004).

**Verification design:** Record samples, estimator, coverage type, denominator and exclusions, then state
the limited claim supported.

**Source context:** [Lua 5.5 reference manual][lua55].

#### Local examples

**Noncompliant fragment or assumption (do not execute):**

> ```text
> P99 proves the deadline; 100 percent statements proves all paths.
> ```

**Contextual source fragment (requires an enclosing scope):**

> ```text
> Report measured distributions and named coverage metrics separately
> from safety, correctness and worst-case timing arguments.
> ```

---

<a id="semantic-regression"></a>

## Appendix A. Complete semantic regression

Save the next block as `semantic_regression.lua` and run it with the selected interpreter. It uses only a
host test profile. The NaN fixture is a controlled floating-point expression for the selected runtime; it is
not an example of unchecked production arithmetic. Table length on a hole-containing table is intentionally
not asserted, because a specific border is not the contract under test.

The program checks truthiness, defaults, multiple-result adjustment, aliases, explicit snapshots, literal
search, sequence traversal and bounded arithmetic. Assertions are test-runner failures with messages;
production external-input handling still uses the normal status path.

### `semantic_regression.lua`

**Complete named source file:**

> ```lua
> -- SPDX-License-Identifier: GPL-3.0-only
> -- Host-only language regressions: no filesystem or native resource effects.
>
> local function sample_getPair()
>    local ret = 0
>    local output = false
>
>    ::function_output::
>    return ret, output
> end
>
> local function sample_isCount(value)
>    local ret = false
>
>    ret = type(value) == "number"
>       and value == value
>       and value >= 0
>       and value <= 4096
>       and value % 1 == 0
>
>    ::function_output::
>    return ret
> end
>
> local function sample_fits(offset_bytes, length_bytes, capacity_bytes)
>    local ret = false
>    local is_valid_offset = false
>    local is_valid_length = false
>    local is_valid_capacity = false
>
>    is_valid_offset = sample_isCount(offset_bytes)
>    is_valid_length = sample_isCount(length_bytes)
>    is_valid_capacity = sample_isCount(capacity_bytes)
>    if not is_valid_offset or not is_valid_length or not is_valid_capacity then
>       goto function_output
>    end
>
>    ret = offset_bytes <= capacity_bytes
>       and length_bytes <= capacity_bytes - offset_bytes
>
>    ::function_output::
>    return ret
> end
>
> local ret, output = sample_getPair()
> local adjusted_pair = { (sample_getPair()) }
> local config = { is_enabled = false }
> local is_enabled = config.is_enabled
> local shared = { count = 1 }
> local alias = shared
> local snapshot = { count = shared.count }
> local first_idx = string.find("a.b", ".", 1, true)
> local sparse = { [1] = "first", [3] = "third" }
> local visited_count = 0
> local is_integer = sample_isCount(4096)
> local is_fraction = sample_isCount(0.5)
> local is_nan = sample_isCount(0 / 0)
> local has_room = sample_fits(4095, 1, 4096)
> local has_overflow = sample_fits(4095, 2, 4096)
> local has_bad_type = sample_fits("0", 1, 4096)
>
> if is_enabled == nil then
>    is_enabled = true
> end
> alias.count = 2
> for _ in ipairs(sparse) do
>    visited_count = visited_count + 1
> end
>
> assert(not not 0, "zero is a true value")
> assert(not not "", "empty string is a true value")
> assert(is_enabled == false, "a false setting must survive")
> assert(ret == 0 and output == false, "false payload lost")
> assert(adjusted_pair[1] == 0, "parenthesized first result changed")
> assert(adjusted_pair[2] == nil, "parentheses must adjust to one result")
> assert(shared.count == 2, "assignment must retain the table alias")
> assert(snapshot.count == 1, "explicit scalar snapshot changed")
> assert(first_idx == 2, "literal search interpreted a pattern")
> assert(visited_count == 1, "ipairs must stop at the hole")
> assert(is_integer and not is_fraction and not is_nan, "count domain failed")
> assert(has_room and not has_overflow and not has_bad_type, "bounds failed")
> print("semantic regression: 12 assertions passed")
> ```

---

<a id="resource-regression"></a>

## Appendix B. Complete resource-failure regression

Save the next block as `resource_regression.lua`, next to `bounded_resource.lua` from [the standard
appendix](lua-code-standard.md#resource-example). The tuple-shaped case fixture has five explicit positions;
nil payload entries are not recovered with a length operator. The outer case collection is a dense sequence.
Deliberate callback exceptions and invalid status/payload values are controlled negative tests, not approved
production callback behavior.

The test verifies the primary status, payload, cleanup status and exact number of close attempts. It
includes a valid false payload and combined work/close failure. A close attempt is not a proof that a real
failed native close released its resource. These mocks have no real external handles.

For a clean standalone run, the fixture directory must be the current working directory and the selected
interpreter must resolve the local module through a controlled package path. The repository runner does not
discover these files while they remain embedded in Markdown.

### `resource_regression.lua`

**Complete named source file:**

> ```lua
> -- SPDX-License-Identifier: GPL-3.0-only
> -- Complete host regression. Deliberate mock exceptions are caught by the API.
>
> local resource = require("bounded_resource")
> local cases = {
>    { "success", 0, "payload", 0, 1 },
>    { "false_payload", 0, false, 0, 1 },
>    { "empty_payload", 0, "", 0, 1 },
>    { "open_fail", -2, nil, 0, 0 },
>    { "open_throw", -5, nil, 0, 0 },
>    { "work_fail", -3, nil, 0, 1 },
>    { "work_throw", -5, nil, 0, 1 },
>    { "work_bad_status", -5, nil, 0, 1 },
>    { "work_bad_payload", -5, nil, 0, 1 },
>    { "close_fail", -4, nil, -4, 1 },
>    { "close_throw", -5, nil, -5, 1 },
>    { "both_fail", -3, nil, -4, 1 },
> }
> local case_count = 0
>
> local function mock_open(context)
>    local ret = 0
>    local handle = nil
>
>    assert(context.mode ~= "open_throw", "injected open exception")
>    if context.mode == "open_fail" then
>       ret = -2
>       goto function_output
>    end
>    handle = { owner = context }
>
>    ::function_output::
>    return ret, handle
> end
>
> local function mock_work(context, handle)
>    local ret = 0
>    local output = "payload"
>
>    assert(handle.owner == context, "unexpected resource owner")
>    assert(context.mode ~= "work_throw", "injected work exception")
>    if context.mode == "work_fail" or context.mode == "both_fail" then
>       ret = -3
>    elseif context.mode == "work_bad_status" then
>       ret = "invalid"
>    elseif context.mode == "work_bad_payload" then
>       output = {}
>    elseif context.mode == "false_payload" then
>       output = false
>    elseif context.mode == "empty_payload" then
>       output = ""
>    end
>
>    ::function_output::
>    return ret, output
> end
>
> local function mock_close(context, handle)
>    local ret = 0
>
>    assert(handle.owner == context, "unexpected close owner")
>    context.close_count = context.close_count + 1
>    assert(context.mode ~= "close_throw", "injected close exception")
>    if context.mode == "close_fail" or context.mode == "both_fail" then
>       ret = -4
>    end
>
>    ::function_output::
>    return ret
> end
>
> local ports = {
>    open_fn = mock_open,
>    work_fn = mock_work,
>    close_fn = mock_close,
> }
>
> for _, case in ipairs(cases) do
>    local context = { mode = case[1], close_count = 0 }
>    local ret, output, cleanup_ret = resource.RESOURCE_run(ports, context)
>
>    assert(ret == case[2], "wrong primary result: " .. case[1])
>    assert(output == case[3], "wrong output: " .. case[1])
>    assert(cleanup_ret == case[4], "wrong cleanup result: " .. case[1])
>    assert(context.close_count == case[5], "wrong close count: " .. case[1])
>    case_count = case_count + 1
> end
>
> assert(case_count == 12, "incomplete resource regression")
> print("resource regression: 12 cases passed")
> ```

---

<a id="research-record"></a>

## Appendix C. Research and evidence record

Resolve the repository profile from the [standard](lua-code-standard.md#repository-profile)
and the checked-in tool configurations. External references explain their own
language and tool contracts; repository rules define the adopted subset.

| Source | Contribution | Evidence limit |
| --- | --- | --- |
| [Lua manuals][lua55] | Values, scope, calls, errors and resources. | Not project coding conventions. |
| [LuaRocks guide][luarocks] | Readable Lua, scope, style and modules. | Not the libmemalloc public-name or SESE authority. |
| [Kong guide][kong] | Production implementation and review considerations. | Its runtime/formatting profile differs. |
| [Roblox guide][roblox] | Organization and documentation. | Luau and Roblox facilities are not baseline Lua. |
| [Olivine guide][olivine] | Conventions and testing discussions. | Review legacy constructs before adoption. |
| [Hisham module article][modules] | Lexical structure and exports. | Not an isolation or security proof. |
| [StyLua][stylua] | Formatting tool behavior. | Repository configuration narrows use. |
| [Selene][selene] | Static analysis and custom standards. | Catalogue coverage is not runtime support. |
| [LuaLS][luals] | Type annotations and language analysis. | Comments do not enforce runtime types. |

No claim is made that this is an exhaustive list of Lua defects or all product-specific threats. The
catalogue supplies concrete review/test designs and traceability for the covered controls. See the
[authoring validation record](lua-code-standard.md#repository-checks) for exactly which local checks ran and
which pinned repository gates did not run.

---

## Additional boundary failure scenarios

---

<a id="lpit-055"></a>

### LPIT-055: Confusing a native address with a Lua root

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** An adapter stores a string address or relative stack index for later use.

**Failure mechanism:** Later stack changes can change the indexed slot; collection can reclaim a value with no Lua root.
Converting an index to absolute addresses only the first problem.

**Prevention controls and source context:** [LSTYLE-073](lua-code-standard.md#lstyle-073).
The linked control identifies the primary API contract and applicability profile.

**Verification design:** Push temporary values between lookup and use, then force collection before delayed native delivery.
Check registry reference counts on success, failed registration and shutdown.

**Contextual prevention contract (not executable):**

```text
stable stack slot for immediate access; registry owner for retained access
```

**Failure fragment or claim (do not execute):**

```text
saved C address -> remove all Lua references -> assume value is retained
```

---

<a id="lpit-056"></a>

### LPIT-056: Resuming through an expired native stack frame

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** An embedding adapter expects a yielding Lua call to continue at the next C statement.

**Failure mechanism:** A continuation-aware boundary resumes through its continuation contract. A borrowed local
from the abandoned native frame cannot serve as persistent operation state.

**Prevention controls and source context:** [LSTYLE-074](lua-code-standard.md#lstyle-074).
The linked control identifies the primary API contract and applicability profile.

**Verification design:** Drive a yielding callback through a native harness, resume with several result counts,
and cancel before completion. Check cleanup and operation-record lifetime on each path.

**Contextual prevention contract (not executable):**

```text
continuation owns persistent state and handles status, results and release
```

**Failure fragment or claim (do not execute):**

```text
pointer to C local passed as continuation context across suspension
```

---

<a id="lpit-057"></a>

### LPIT-057: Discarding a coroutine without observing close failure

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A scheduler removes a failed or suspended worker and reports successful cleanup.

**Failure mechanism:** The scheduler has not established that pending resources closed; close itself can report an error.
Replacing the original operation error with that result can also lose the primary diagnosis.

**Prevention controls and source context:** [LSTYLE-075](lua-code-standard.md#lstyle-075).
The linked control identifies the primary API contract and applicability profile.

**Verification design:** Run the standard's coroutine fixture for completion, abandonment, body error and closer error.
Assert release counts and both result channels; do not infer prompt cleanup from heap reachability.

**Contextual prevention contract (not executable):**

```text
preserve resume result -> close eligible worker -> retain separate cleanup result
```

**Failure fragment or claim (do not execute):**

```text
workers[id] = nil; report cleanup success
```

---

<a id="lpit-058"></a>

### LPIT-058: Retaining a pointer while collecting its backing cdata

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A LuaJIT request stores a pointer into a temporary cdata array.

**Failure mechanism:** A pointer field does not create the collector edge needed to retain that backing array.
The native request can outlive the only Lua owner of the storage.

**Prevention controls and source context:** [LSTYLE-076](lua-code-standard.md#lstyle-076).
The linked control identifies the primary API contract and applicability profile.

**Verification design:** Keep an explicit backing owner in the valid test fixture and collect between submission and completion.
Inspect the ownership path; ordinary success without collection is weak evidence.

**Contextual prevention contract (not executable):**

```text
request record contains backing array and handle until completion acknowledgement
```

**Failure fragment or claim (do not execute):**

```text
native request stores address; Lua retains only pointer cdata
```

---

<a id="lpit-059"></a>

### LPIT-059: Freeing a callback before unregister has drained it

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** A LuaJIT adapter frees its callback immediately after a native unregister request.

**Failure mechanism:** The provider can still have a callback in flight. Releasing the executable entry point or captured
state before acknowledgement breaks the registration lifetime.

**Prevention controls and source context:** [LSTYLE-077](lua-code-standard.md#lstyle-077).
The linked control identifies the primary API contract and applicability profile.

**Verification design:** Use a controllable native provider to delay unregister acknowledgement
and finish an in-flight call.
Repeat registration cycles to verify bounded callback retention.

**Contextual prevention contract (not executable):**

```text
unregister acknowledgement + no active calls -> free callback and captured state
```

**Failure fragment or claim (do not execute):**

```text
request_unregister(); callback:free(); assume no late delivery
```

---

<a id="lpit-060"></a>

### LPIT-060: Treating a runtime upgrade as a parser upgrade

**Class:** FAILURE_SCENARIO. This entry adds no independent implementation requirement.

**Trigger:** Code uses newly accepted runtime syntax while a static analyzer still targets an older grammar.

**Failure mechanism:** The runtime and analyzer are different parsers. Excluding the file to obtain a green report
removes evidence instead of qualifying the new syntax.

**Prevention controls and source context:** [LSTYLE-078](lua-code-standard.md#lstyle-078).
The linked control identifies the primary API contract and applicability profile.

**Verification design:** Run a minimal syntax fixture through each locked parser; retain tool identity and intended diagnostic.
Keep the feature unavailable in production source until all required tools can process it.

**Contextual prevention contract (not executable):**

```text
runtime, formatter and analyzers each receive a compatibility result
```

**Failure fragment or claim (do not execute):**

```text
luac passes, so skip files that the complexity parser rejects
```

---

<a id="links-and-references"></a>

## Links and references

[check-lua]: ../../../scripts/check/lua.lua
[kong]: https://github.com/Kong/kong/blob/master/CONTRIBUTING.md
[lua54]: https://www.lua.org/manual/5.4/manual.html
[lua55]: https://www.lua.org/manual/5.5/manual.html
[luals]: https://luals.github.io/wiki/annotations/
[luarocks]: https://github.com/luarocks/lua-style-guide
[modules]: https://hisham.hm/2014/01/02/how-to-write-lua-modules-in-a-post-module-world/
[olivine]: https://github.com/Olivine-Labs/lua-style-guide
[roblox]: https://roblox.github.io/lua-style-guide/
[selene]: https://kampfkarren.github.io/selene/usage/configuration.html
[stylua]: https://github.com/JohnnyMorganz/StyLua
[toolchain]: ../../../tools/toolchain/lock.toml

<!-- EOF -->


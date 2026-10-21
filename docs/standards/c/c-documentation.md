<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# C Documentation Standard

This guide constructs four complete documentation templates in source order: `private.c`, `internal.h`,
`public.h`, and `main.c`. Each numbered construction step contains the actual text to append, including the
entire section banner, entity documentation, declarations, and closing markers. The explanation immediately
following the block describes its fields and whether the section applies to that file.

Within each chapter, concatenate its C blocks to obtain that file's expanded template. Do not copy
the Markdown headings, explanations, or tables. Every category that the file may need is demonstrated; a real
file keeps only the applicable categories. No instruction to “use the previous pattern” replaces a code block.
The bodies of every function definition remain exactly `/* ... */`.

<details>
<summary><strong>On this page</strong></summary>

- [Reading and filling the templates](#reading-the-templates)
- [1. Construct `private.c`](#private-c)
- [2. Construct `internal.h`](#internal-h)
- [3. Construct `public.h`](#public-h)
- [4. Construct `main.c`](#main-c)
- [Doxygen commands and field semantics](#doxygen-fields)
- [Completion and Doxygen validation](#completion)

<a id="reading-the-templates"></a>

</details>

---

## Reading and filling the templates

Use the [C Code Standard](c-code-standard.md) for naming, declarations, indentation, and return conventions,
and [C Module Architecture](c-module-architecture.md) for ownership and visibility. In particular:

| Topic | Owning rule |
| --- | --- |
| Meaning of public, internal, and private | [CMOD-006](c-module-architecture.md#cmod-006) |
| Placement of declarations and complete types | [CMOD-074](c-module-architecture.md#cmod-074), [CMOD-075](c-module-architecture.md#cmod-075) |
| Header contents | [CSTYLE-033](c-code-standard.md#cstyle-033) |
| C++ compatibility and the sole `extern` exception | [CMOD-017](c-module-architecture.md#cmod-017), [CMOD-019](c-module-architecture.md#cmod-019) |
| Application-private definitions and unrestricted includes | [CMOD-021](c-module-architecture.md#cmod-021) |
| Public contract ownership | [CMOD-110](c-module-architecture.md#cmod-110), [CSTYLE-270](c-code-standard.md#cstyle-270) |
| Useful comments, line length, and blank lines | [CSTYLE-243](c-code-standard.md#cstyle-243), [CSTYLE-015](c-code-standard.md#cstyle-015), [CSTYLE-279](c-code-standard.md#cstyle-279) |
| Review and evidence | [C Compliance and Assurance](c-compliance.md#workflow) |
| Specification and proof consistency | [C Formal Verification](test/c-tests-formal.md#cfv-004-keep-one-authoritative-specification) |
| Failure cases to cover in contracts | [Common C Pitfalls](c-common-pitfalls.md) |

The concrete `MODULE_`, `module_`, `Module`, `APPLICATION_`, and `application_` identifiers demonstrate the
naming convention. Rename identifiers consistently across the four files. `<...>` is a field to fill, not
literal documentation to publish. An entity command such as `@def <MODULE_NAME>_TIMEOUT_MS` must resolve to
the actual definition after substitution; the bracketed text is never part of the C identifier.

Every banner uses the supplied documentation form: `/**` followed by the delimiter, the spaced uppercase
section name, an explanatory subtitle where present, and the closing delimiter. Preserve the banner as well
as the entity blocks beneath it. Do not replace it with a shortened ordinary comment. Section banners are
source organization; they do not change visibility or prove an architectural property. The Doxygen input
filter removes decorative banners
and delimiter bars while preserving documentation commands and source line numbers.

| Obligation | How to apply it |
| --- | --- |
| Required | Keep the construct and complete its information in this kind of file. |
| Conditional | Keep it when its entity, guarantee, dependency, or execution constraint exists. |
| Optional | Keep it when it adds maintained information; the expanded template still shows its full form. |
| Not permitted here | Do not add it merely to fill out the template. |

The file contract, SPDX block, applicable grouping, function contract, and balanced file ending are required.
A type/macro/object section is conditional on owning such an entity. Version, date, author, related-symbol
references, notices, and generated graphs are optional unless the project profile requires them. The templates
show all of these fields explicitly so their placement is unambiguous. Remove an inapplicable field; do not
leave an empty label or invent behavior to fill it. Ownership, Reentrancy, Thread Safety, Blocking, Side
Effects, Complexity, Startup, Failure Recovery, and
Shutdown are optional paragraphs: retain them when applicable and useful, and omit them otherwise.
Their absence does not remove the behavioral obligations defined by the code and architecture standards;
necessary caller obligations and guarantees still belong in the operation's contract.

Public and internal headers may include the minimum dependencies permitted by
[CMOD-009](c-module-architecture.md#cmod-009) and [CMOD-010](c-module-architecture.md#cmod-010).
The header constructions below show necessary standard type includes and explain approved leaf-contract
exceptions. `public.h` has opaque structure declarations only; `internal.h` may contain complete representations
shared by owning source files. Headers define neither storage objects nor function bodies.
`private.c` contains private implementation details and the definitions of the module's internal/public
operations. `main.c` owns application-private declarations and may include any required dependency.

Source files have no include guard or blanket C++ linkage block. Each compatible header owns its guarded
`extern "C"` opening and closing. Hosted `main` is the required non-static entry-point exception; other
file-scope application functions and objects use `static`.

The four constructions describe code and documentation layout. They are not runnable implementations and are
validated through filled temporary copies; literal placeholders are not production Doxygen input. Complete the
fields and implementations separately before product validation.

### Whitespace and diagnostic ownership

Follow [`.editorconfig`](../../../.editorconfig): UTF-8, LF, no trailing whitespace, eight-column tabs for
C indentation, and an 80-column display width. Use tabs for the enclosing C indentation and spaces for
alignment inside a comment, including the leading asterisk and the command/description columns. A tab rule does
not mean inserting tabs between every Doxygen command and its text. Keep one blank line between source
sections and a blank comment line containing an asterisk between logical fields.

Indent every `@retval` line one additional eight-column level relative to `@return`; its description wraps
at the same text column. This is visual nesting of individual outcomes under the general return convention.
Keep adjacent `@retval` entries together. Apply the same spacing to callbacks, declarations, definitions,
and the application entry point.

Doxygen owns diagnostics about C comment contents and documentation markup. The repository's C formatter
preserves comments; clang-tidy comment checks and spelling/prose checks for C comments are disabled.
Code formatting, identifier checks, compiler errors, and static analysis remain enabled. An unterminated
comment is still a C lexical error. The EOF marker check validates the physical file boundary, not prose.

---

<a id="private-c"></a>

## 1. Construct `private.c`

This chapter appends every part of the module implementation in order. It shows private declarations and
objects first, then private helper definitions, internal function definitions, and public function definitions.
Its definitions match the headers constructed in the later chapters. This source owns complete private layouts,
but it must not duplicate complete representations owned by `internal.h`.

### 1.1. License

**Required.** These are the first lines of this file.

<!-- REUSE-IgnoreStart -->

```c
/*
 * SPDX-FileCopyrightText: <year> <name> <e-mail>
 * SPDX-License-Identifier: <license>
 */
```

<!-- REUSE-IgnoreEnd -->

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `SPDX-FileCopyrightText` | Required | Fill the actual year, rights-holder name, and e-mail. Preserve imported provenance where applicable. |
| `SPDX-License-Identifier` | Required | Fill the applicable SPDX license expression; this is not a prose license summary. |

### 1.2. File documentation

**Required block.** All file fields are shown; complete or remove optional fields according to the table below.

```c
/** ============================================================================
 *  @file       <file_name.c>
 *  @ingroup    <MODULE_NAME>
 *
 *  @brief      <Describe the responsibility of this translation unit.>
 *
 *  @details    <Describe its scope, implementation boundaries, and
 *              assumptions.>
 *
 *  @par Direct Module Dependencies
 *    @li @ref <DEPENDENCY_MODULE>
 *        <Explain the approved dependency and the interface consumed.>
 *
 *  @par Used By
 *    @li @ref <CONSUMER_MODULE>
 *        <Identify the consumer and explain the permitted dependency.>
 *
 *  @par Provided Interfaces
 *    @li @ref <public_header.h>
 *        <Describe the public interface implemented by this file.>
 *    @li @ref <internal_header.h>
 *        <Describe the interface shared within the owning module.>
 *
 *  @par Consumed Runtime Ports
 *    @li @ref <provider_port_t>
 *        <Describe the callback contract, binding, and provider lifetime.>
 *
 *  @version    <vX.X.XX>
 *  @date       <DD.MM.YYYY>
 *  @author     <name> <e-mail>
 * ========================================================================== */
```

Keep the blank lines between the summary, detail, relationship lists, and revision fields. A file reference
identifies an actual interface; a group reference identifies its documentation owner. Each following list
entry has a target line and an explanatory line. Do not leave an unresolved `<...>` target in published output.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@file` | Required | Use the real file name and extension. For this chapter use the file kind named in its heading. |
| `@ingroup` | Required | Name the owning module/application group. It must exist in the Doxygen input. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@par Direct Module Dependencies` | Conditional | List actual architectural/direct dependencies, not all headers reachable transitively. Explain the role of each `@ref` target. |
| `@li @ref <DEPENDENCY_MODULE>` | Conditional on the containing list | Fill a resolvable reference target and explain the relationship on the following line. |
| `@par Used By` | Conditional | Identify approved consumers or owning source files and explain their allowed use. |
| `@li @ref <CONSUMER_MODULE>` | Conditional on the containing list | Fill a resolvable reference target and explain the relationship on the following line. |
| `@par Provided Interfaces` | Conditional | List the public/internal interfaces declared or implemented by this file. |
| `@li @ref <public_header.h>` | Conditional on the containing list | Fill a resolvable reference target and explain the relationship on the following line. |
| `@li @ref <internal_header.h>` | Conditional on the containing list | Fill a resolvable reference target and explain the relationship on the following line. |
| `@par Consumed Runtime Ports` | Conditional | Describe injected services, callback contracts, binding, and provider/context lifetime. |
| `@li @ref <provider_port_t>` | Conditional on the containing list | Fill a resolvable reference target and explain the relationship on the following line. |
| `@version` | Optional/profile-dependent | Record the maintained file/interface version, such as the specified vX.X.XX form; do not invent release metadata. |
| `@date` | Optional/profile-dependent | Fill the relevant maintained date in DD.MM.YYYY form; define what event that date represents. |
| `@author` | Optional/profile-dependent | Fill attribution with the actual name and e-mail. This does not replace provenance or review ownership. |

### 1.3. Private / Includes

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *                     P R I V A T E - I N C L U D E S
 * ========================================================================== */

/* Module Public Header */
#include "public.h"

/* Standard Library Header Files */
#include <stddef.h>
#include <stdint.h>

/* Third-Party Header Files */

/* Module Internal Header */
#include "internal.h"

/* External Module Header Files */
```

Keep the entire includes banner and the five category labels shown. Select actual dependencies for the
file. In a module source, the public header comes first; standard, third-party, internal, and external module
headers follow in the illustrated categories. The module architecture still controls which external dependencies
are allowed. In `main.c`, the same private section can contain any needed application dependency. Empty labels
are template slots; omit a category from a completed file if it has no entries.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| Include categories | Conditional | Keep only categories with direct dependencies in the completed source. |
| Module public header first | Required for module implementations | Follow CMOD-016; main.c has the composition exception in CMOD-021. |

### 1.4. Open the private implementation group

```c
/**
 * @addtogroup <MODULE_NAME>_CORE_IMPL
 * @{
 */
```

**Required for this populated region.** This is a separate grouping block, placed after the includes or
preceding group's closing block and before the next section banner. `<MODULE_NAME>_CORE_IMPL` selects the documentation
level for the declarations and definitions that follow. The banner remains a separate comment.

Replace the bracketed owner and use the same group identity in its owned documentation. `@{` opens
membership; a later `@}` closes it. These markers organize Doxygen output; C linkage and module visibility
still come from declarations and the architecture. Do not merge this block into an include or function comment.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@addtogroup` | Required | Fill the module/application owner; preserve the indicated level suffix. |
| `@{` | Required | Open this group and keep its matching closing block before the next level or file ending. |

### 1.5. Private / Defines

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *                       P R I V A T E - D E F I N E S
 *     Object-like macros used as private constants or local configuration.
 * ========================================================================== */

/** ============================================================================
 *  @def         <MODULE_NAME>_TIMEOUT_MS
 *
 *  @brief      <Describe the constant's purpose.>
 *  @details    <Specify its unit, type, permitted range, and value rationale.>
 *
 *  @note       <Describe configuration constraints and visibility.>
 *
 *  @see        <related_symbol>
 * ========================================================================== */
#define MODULE_TIMEOUT_MS ((uint32_t)(100U))

/** ============================================================================
 *  @def         <MODULE_NAME>_MAX_ITEMS
 *
 *  @brief      <Describe the capacity represented by this constant.>
 *  @details    <Explain how the limit is derived and where it applies.>
 *
 *  @warning    <Describe the resource and compatibility impact of changes.>
 * ========================================================================== */
#define MODULE_MAX_ITEMS ((size_t)(16U))
```

The banner introduces object-like macros, not function-like macros or allocated objects. Every shown macro
has its own complete block. Match `@def` to the actual name, explain the unit and value rationale, and preserve
the typed constant spelling required by the C standard. Source-local definitions are PRIVATE, same-module
shared definitions INTERNAL, and published constants PUBLIC. A cast-bearing macro is not automatically valid
inside a preprocessor `#if` expression.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@def` | Required in this displayed pattern | Replace the bracketed module prefix and match the macro name and argument spelling exactly. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@note` | Optional | Add a specific scope, configuration, or lifetime clarification that belongs to this entity. |
| `@see` | Optional | Replace each target with an existing related operation, type, or document anchor. |
| `@warning` | Conditional on a hazard | Explain a concrete hazard or restriction and its consequence; do not use a generic warning as a substitute for a contract. |

### 1.6. Private / Macros

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *                        P R I V A T E - M A C R O S
 *         Function-like macros, when justified by the coding standard.
 * ========================================================================== */

/** ============================================================================
 *  @def        <MODULE_NAME>_STRINGIFY(token_)
 *
 *  @brief      <Describe the preprocessing operation.>
 *  @details    <Explain why preprocessing is required instead of a function.>
 *
 *  @param[in]  token_ <Describe accepted tokens and expansion behavior.>
 *
 *  @return     <Describe the resulting string literal.>
 *
 *  @warning    <Document argument expansion and evaluation constraints.>
 * ========================================================================== */
#define MODULE_STRINGIFY(token_) #token_

/** ============================================================================
 *  @def         <MODULE_NAME>_UPDATE(in_, out_, in_out_)
 *
 *  @brief      <Describe the statement macro's responsibility.>
 *  @details    <Justify a macro instead of a typed static inline function.>
 *
 *  @param[in]     in_     <Describe the input type, range, and unit.>
 *  @param[out]    out_    <Describe the writable destination and failure
 *              state.>
 *  @param[in,out] in_out_ <Describe the initial and resulting state.>
 *
 *  @pre        <Specify valid lvalues, aliasing, and arithmetic constraints.>
 *  @post       <Describe output and state guarantees.>
 *
 *  @warning    <Specify evaluation counts and forbidden side effects.>
 * ========================================================================== */
#define MODULE_UPDATE(in_, out_, in_out_) \
	do                                \
	{                                 \
		/* ... */                 \
	}                                 \
	while (0)
```

The banner introduces function-like macros. Keep the documentation for preprocessing behavior and every
argument. A stringification macro and a statement macro have different contracts: explain expansion for the
former and lvalues, evaluation counts, aliasing, and side effects for the latter. The statement scaffold retains
`do`, braces, continuations, `while (0)`, and `/* ... */`; it is not a working implementation. A macro requires
justification under [CSTYLE-042/044](c-code-standard.md#cstyle-042).

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@def` | Required in this displayed pattern | Replace the bracketed module prefix and match the macro name and argument spelling exactly. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@param[in] token_` | Required for this parameter | Input: meaning, range, unit, and readable lifetime; do not imply pointer retention. The name must match the declaration. |
| `@return` | Conditional on a result | Describe the result convention and domain. Omit for void; do not use only “Integer” as its meaning. |
| `@warning` | Conditional on a hazard | Explain a concrete hazard or restriction and its consequence; do not use a generic warning as a substitute for a contract. |
| `@param[in] in_` | Required for this parameter | Input: meaning, range, unit, and readable lifetime; do not imply pointer retention. The name must match the declaration. |
| `@param[out] out_` | Required for this parameter | Output: writable storage, extent, nullability, and success/failure contents. The name must match the declaration. |
| `@param[in,out] in_out_` | Required for this parameter | Input/output: accepted initial state, mutations, ownership, and state after failure. The name must match the declaration. |
| `@pre` | Conditional on caller obligations | Specify valid storage, bounds, aliasing, initialization, lock state, and binding requirements relevant to this operation. |
| `@post` | Conditional on guarantees | Specify output and state on success and failure, including partial work and unchanged state where guaranteed. |

### 1.7. Private / Enums

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *                         P R I V A T E - E N U M S
 *              Enumerations used only by this translation unit.
 * ========================================================================== */

/** ============================================================================
 *  @enum       <ModuleName>State
 *
 *  @brief      <Describe the states represented by this enumeration.>
 *  @details    <Specify valid transitions and value validation rules.>
 *
 *  @par Values
 *    @li @b MODULE_STATE_IDLE
 *        <Describe the meaning and permitted transitions of this state.>
 *    @li @b MODULE_STATE_RUNNING
 *        <Describe the meaning and permitted transitions of this state.>
 *    @li @b MODULE_STATE_ERROR
 *        <Describe the meaning and recovery conditions of this state.>
 * ========================================================================== */
typedef enum ModuleState
{
	MODULE_STATE_IDLE    = ((uint8_t)(0u)),
	MODULE_STATE_RUNNING = ((uint8_t)(1u)),
	MODULE_STATE_ERROR   = ((uint8_t)(2u)),

	/*< Enum max value >*/
	MODULE_STATE_MAX = ((uint8_t)(3u))
} module_state_t; /**< <Type alias.> */
```

Preserve the full enum banner, the type contract, the Values list, the declaration, and its alias. Each
`@li @b` names an actual enumerator. Explicit values and the casts shown illustrate this project's source
convention; they do not fix the underlying enum size. Document the count sentinel when present and keep its
name distinct from capacity macros. Remove a sentinel that has no count/indexing purpose.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@enum` | Required in this displayed pattern | Name the enum tag, including the suffix shown, rather than confusing it with its typedef alias. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@par Values` | Required for the shown enum pattern | Keep the full @li @b list. Explain the meaning and transitions of each named enumerator. |
| `@li @b MODULE_STATE_IDLE` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@li @b MODULE_STATE_RUNNING` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@li @b MODULE_STATE_ERROR` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `Enum max value / *_MAX` | Conditional | This names a count only for a zero-based contiguous enum that needs one. It is not a valid runtime state or an ABI-width declaration. |

### 1.8. Private / Structs / Definitions

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *            P R I V A T E - S T R U C T S - D E F I N I T I O N S
 *    Struct and union representations used only by this translation unit.
 * ========================================================================== */

/** ============================================================================
 *  @struct     <ModuleName>
 *
 *  @brief      <Describe the private representation of the opaque object.>
 *  @details    <Specify initialization and invariants hidden from consumers.>
 *
 *  @par Fields
 *    @li @b timeout_ms
 *        <Specify milliseconds, bounds, and the meaning of zero.>
 *    @li @b mode
 *        <Specify accepted modes and their configuration dependencies.>
 *
 *  @invariant  <Describe invariants maintained throughout the object lifetime.>
 *
 *  @par Ownership
 *              <Specify module allocation, lifetime, and matching destruction.>
 *  @par Representation
 *              <Describe layout choices confined to this translation unit.>
 *
 *  @see        <opaque_public_type>
 * ========================================================================== */
struct Module
{
	unsigned int  timeout_ms; /**< <Timeout and special values.> */
	module_mode_t mode; /**< <Mode and constraints.> */
};

/** ============================================================================
 *  @struct    <ModuleName>Context
 *
 *  @brief      <Describe the state represented by this structure.>
 *  @details    <Describe ownership, lifetime, initialization, and layout
 *              scope.>
 *
 *  @par Fields
 *    @li @b state
 *        <Describe valid states and the initialization state.>
 *    @li @b operation_count
 *        <Describe what is counted and the overflow policy.>
 *    @li @b last_value
 *        <Describe the value's meaning and when it is valid.>
 *
 *  @invariant  <State the relationships that must hold between fields.>
 * ========================================================================== */
typedef struct ModuleContext
{
	module_state_t state; /**< <State invariant.> */

	uint32_t operation_count; /**< <Count and bounds.> */
	uint32_t last_value; /**< <Value and validity.> */
} module_context_t; /**< <Type alias.> */

/** ============================================================================
 *  @union       <ModuleName>Value
 *
 *  @brief      <Describe the mutually exclusive value representations.>
 *  @details    <Identify the external tag or contract selecting the member.>
 *
 *  @par Fields
 *    @li @b u32
 *        <Describe when the unsigned member is active.>
 *    @li @b s32
 *        <Describe when the signed member is active.>
 *
 *  @invariant  <Specify how writes and reads preserve the active member.>
 * ========================================================================== */
typedef union ModuleValue
{
	uint32_t u32; /**< <Unsigned value range and unit.> */
	int32_t  s32; /**< <Signed value range and unit.> */
} module_value_t; /**< <Type alias.> */
```

Keep the entire representation banner and every per-type block. `@struct` and `@union` identify tags;
`@par Fields` explains members and relationships; trailing `/**< ... */` comments remain beside the declarations.
A union's active-member rule is mandatory information. An internal complete type is shared by owning source
files; a private complete type is owned by one translation unit. Do not duplicate its definition in both.
There is no corresponding complete-structure section in `public.h`.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@struct` | Required in this displayed pattern | Name the struct tag whose complete representation follows. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@par Fields` | Required for the shown complete-type pattern | Keep the full @li @b list. Explain units, bounds, valid states, and relationships for each named member. |
| `@li @b timeout_ms` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@li @b mode` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@invariant` | Conditional on representation/state constraints | State relationships maintained by all valid states or mutations. This is documentation, not an executable proof. |
| `@par Ownership` | Optional when applicable | State allocation, borrowing, transfer, retention, allocator pairing, and cleanup responsibilities. |
| `@par Representation` | Conditional on a representation boundary | Identify where the complete type is owned and which layout decisions remain private. |
| `@see` | Optional | Replace each target with an existing related operation, type, or document anchor. |
| `@li @b state` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@li @b operation_count` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@li @b last_value` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@union` | Required in this displayed pattern | Name the union tag and retain the active-member contract beneath it. |
| `@li @b u32` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@li @b s32` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `/**< <...> */` | Required for the shown member pattern | Keep the trailing comment beside its field. Fill the short local meaning; the Fields list explains relationships and constraints. |

### 1.9. Private / Typedefs

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *                      P R I V A T E - T Y P E D E F S
 *       Other aliases and callback types private to this translation unit.
 * ========================================================================== */

/** ============================================================================
 *  @typedef     <ModuleName>_index_t
 *
 *  @brief      <Describe the semantic purpose of this alias.>
 *  @details    <Specify units, bounds, and any reserved sentinel values.>
 * ========================================================================== */
typedef size_t module_index_t;

/** ============================================================================
 *  @typedef     <ModuleName>_action_fn_t
 *
 *  @brief      <Describe the callback's responsibility.>
 *  @details    <Describe the behavior, boundaries, and relevant design
 *              choices.>
 *
 *  @param[in]     input   <Describe the accepted input, range, and unit.>
 *  @param[out]    output  <Describe storage, nullability, and failure state.>
 *  @param[in,out] context <Describe the context type, lifetime, and mutations.>
 *
 *  @return     <Specify the status convention and error domain.>
 *          @retval     <success_code> <Describe the successful outcome.>
 *          @retval     <error_code> <Describe the corresponding failure
 *                      condition.>
 *
 *  @pre        <Specify pointer validity, aliasing, and binding requirements.>
 *  @post       <Specify output and context guarantees on success and failure.>
 *
 *  @par Ownership
 *              <Specify borrowing, transfer, retention, and cleanup duties.>
 *  @par Reentrancy
 *              <Specify whether the callback may re-enter the owning module.>
 *  @par Thread Safety
 *              <Specify concurrency and synchronization requirements.>
 *  @par Blocking
 *              <Specify waits, timeouts, and allowed execution contexts.>
 *  @par Side Effects
 *              <List observable effects or explicitly state none.>
 *  @par Complexity
 *              <Specify time and space bounds and the variables involved.>
 *
 *  @see        <related_symbol>
 *  @showrefby
 * ========================================================================== */
typedef int (*module_action_fn_t)(const uint32_t input, uint32_t *const output,
                                  void *const context);
```

The banner covers aliases and callback signatures. Each alias explains a semantic domain; each callback
has the full callable contract shown, including argument directions, outcomes, state guarantees, ownership,
reentrancy, thread safety, blocking, effects, and cost. A void context pointer is not permission to expose a
provider's layout. Shared peer ports follow [CMOD-013](c-module-architecture.md#cmod-013); this section is not an
implicit dependency on another module.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@typedef` | Required in this displayed pattern | Name the alias or callback typedef exactly; preserve the project lowercase alias convention. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@param[in] input` | Required for this parameter | Input: meaning, range, unit, and readable lifetime; do not imply pointer retention. The name must match the declaration. |
| `@param[out] output` | Required for this parameter | Output: writable storage, extent, nullability, and success/failure contents. The name must match the declaration. |
| `@param[in,out] context` | Required for this parameter | Input/output: accepted initial state, mutations, ownership, and state after failure. The name must match the declaration. |
| `@return` | Conditional on a result | Describe the result convention and domain. Omit for void; do not use only “Integer” as its meaning. |
| `@retval` | Conditional on distinct outcomes | Replace the status placeholder with an actual result and explain its condition. Repeat for each distinct contractual outcome. |
| `@pre` | Conditional on caller obligations | Specify valid storage, bounds, aliasing, initialization, lock state, and binding requirements relevant to this operation. |
| `@post` | Conditional on guarantees | Specify output and state on success and failure, including partial work and unchanged state where guaranteed. |
| `@par Ownership` | Optional when applicable | State allocation, borrowing, transfer, retention, allocator pairing, and cleanup responsibilities. |
| `@par Reentrancy` | Optional when applicable | State whether entry can recur before an earlier call finishes, including through a callback. |
| `@par Thread Safety` | Optional when applicable | Specify permitted callers, confinement, locks, and synchronization ownership. |
| `@par Blocking` | Optional when applicable | State waits, timeouts, allowed execution contexts, and whether callback behavior affects the bound. |
| `@par Side Effects` | Optional when applicable | List mutation, allocation, callbacks, I/O, and external changes, or explicitly state their absence. |
| `@par Complexity` | Optional when applicable | Define time/storage costs and their variables, and identify the assumptions behind the claimed bound. |
| `@see` | Optional | Replace each target with an existing related operation, type, or document anchor. |
| `@showrefby` | Optional | Request the generated Referenced by view; it is not proof that all indirect callers have been found. |

### 1.10. Private / Constants

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *                     P R I V A T E - C O N S T A N T S
 *         File-scope constant objects with internal linkage.
 * ========================================================================== */

/** ============================================================================
 *  @var        g_default_value
 *
 *  @brief      <Describe the immutable object's purpose.>
 *  @details    <Specify its unit, valid range, and initialization rationale.>
 *
 *  @note       <Describe lifetime and representation constraints.>
 * ========================================================================== */
static const uint32_t g_default_value = UINT32_C(10);
```

This source-only banner introduces immutable storage objects. Preserve `static const`, the object name,
its typed initializer, and its complete `@var` block. Explain lifetime, value range, and intended use; do not
confuse a constant object with a preprocessor define. No counterpart belongs in the two header templates.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@var` | Required in this displayed pattern | Identify the source-local object. Its documentation must agree with mutability and storage duration. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@note` | Optional | Add a specific scope, configuration, or lifetime clarification that belongs to this entity. |

### 1.11. Private / Variables

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *                      P R I V A T E - V A R I A B L E S
 *       Justified file-scope state. Prefer explicit instance-owned state.
 * ========================================================================== */

/** ============================================================================
 *  @var        g_context
 *
 *  @brief      <Describe the mutable object's purpose.>
 *  @details    <Justify file-scope state instead of an explicit instance.>
 *
 *  @par Lifecycle
 *              <Specify initialization, ownership, reset, and teardown.>
 *  @par Synchronization
 *              <Identify the lock or access discipline for every mutation.>
 *
 *  @warning    <Describe concurrency restrictions and unsupported access.>
 * ========================================================================== */
static module_context_t g_context = {
	.state           = MODULE_STATE_IDLE,
	.operation_count = UINT32_C(0),
	.last_value      = UINT32_C(0),
};
```

This source-only banner introduces justified private mutable storage. Preserve the complete `@var` block,
lifecycle and synchronization fields, the `static` declaration, and designated initializer. The template does
not require global state in a real design. Instance-owned state remains preferred; document why this object
needs file scope and how every access preserves its invariants. Do not place such an object in a header.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@var` | Required in this displayed pattern | Identify the source-local object. Its documentation must agree with mutability and storage duration. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@par Lifecycle` | Conditional on owned state/resources | Document initialization, reset, shutdown, and ownership across those transitions. |
| `@par Synchronization` | Conditional on mutable/shared state | Name the actual lock, confinement, publication, or access discipline for all affected fields. |
| `@warning` | Conditional on a hazard | Explain a concrete hazard or restriction and its consequence; do not use a generic warning as a substitute for a contract. |

### 1.12. Private / Functions / Prototypes

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *          P R I V A T E - F U N C T I O N S - P R O T O T Y P E S
 *                       Prototypes of static functions.
 * ========================================================================== */

static int module_validateInput(const uint32_t value);

static int module_transformValue(const uint32_t input, uint32_t *const output);
```

Preserve the entire prototypes banner and every declaration. Private helpers use `static`; internal and
public prototypes use their respective naming conventions without an explicit `extern` storage class. Private
prototypes can be bare when the complete block appears at the definition below. Header prototypes carry the
full contract because their consumers must not inspect implementation bodies to learn the interface.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

### 1.13. Private / Functions / Definitions

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *         P R I V A T E - F U N C T I O N S - D E F I N I T I O N S
 *                       Definitions of static functions.
 * ========================================================================== */

/** ============================================================================
 *  @brief      <Describe the validation performed by this function.>
 *  @details    <Describe the behavior, boundaries, and relevant design
 *              choices.>
 *
 *  @param[in]  value <Describe the input, unit, and accepted range.>
 *
 *  @return     <Specify the status convention and error domain.>
 *          @retval     <success_code> <Describe the successful outcome.>
 *          @retval     <error_code> <Describe the corresponding failure
 *                      condition.>
 *
 *  @pre        <Specify pointer validity, aliasing, and binding requirements.>
 *  @post       <Specify output and context guarantees on success and failure.>
 *
 *  @par Ownership
 *              <Specify borrowing, transfer, retention, and cleanup duties.>
 *  @par Reentrancy
 *              <Specify whether the callback may re-enter the owning module.>
 *  @par Thread Safety
 *              <Specify concurrency and synchronization requirements.>
 *  @par Blocking
 *              <Specify waits, timeouts, and allowed execution contexts.>
 *  @par Side Effects
 *              <List observable effects or explicitly state none.>
 *  @par Complexity
 *              <Specify time and space bounds and the variables involved.>
 *
 *  @see        <related_symbol>
 *  @showrefby
 * ========================================================================== */
static int module_validateInput(const uint32_t value)
{
	/* ... */
}

/** ============================================================================
 *  @brief      <Describe the validation performed by this function.>
 *  @details    <Describe the behavior, boundaries, and relevant design
 *              choices.>
 *
 *  @param[in]  input  <Describe the input, unit, and accepted range.>
 *  @param[out] output <Describe storage, nullability, and failure state.>
 *
 *  @return     <Specify the status convention and error domain.>
 *          @retval     <success_code> <Describe the successful outcome.>
 *          @retval     <error_code> <Describe the corresponding failure
 *                      condition.>
 *
 *  @pre        <Specify pointer validity, aliasing, and binding requirements.>
 *  @post       <Specify output and context guarantees on success and failure.>
 *
 *  @par Ownership
 *              <Specify borrowing, transfer, retention, and cleanup duties.>
 *  @par Reentrancy
 *              <Specify whether the callback may re-enter the owning module.>
 *  @par Thread Safety
 *              <Specify concurrency and synchronization requirements.>
 *  @par Blocking
 *              <Specify waits, timeouts, and allowed execution contexts.>
 *  @par Side Effects
 *              <List observable effects or explicitly state none.>
 *  @par Complexity
 *              <Specify time and space bounds and the variables involved.>
 *
 *  @see        <related_symbol>
 *  @showrefby
 * ========================================================================== */
static int module_transformValue(const uint32_t input, uint32_t *const output)
{
	/* ... */
}
```

Preserve the entire definitions banner and a complete documentation block for every function, including
all six named operational sections shown. Do not substitute an ordinary one-line comment, a reference to another
pattern, or a shortened `@copydoc` block. Each body is only `/* ... */`. Private definitions are `static`;
internal and public definitions match the corresponding header declarations. When the contract appears at both
declaration and definition, maintain them together; the header remains the authoritative caller contract.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@param[in] value` | Required for this parameter | Input: meaning, range, unit, and readable lifetime; do not imply pointer retention. The name must match the declaration. |
| `@return` | Conditional on a result | Describe the result convention and domain. Omit for void; do not use only “Integer” as its meaning. |
| `@retval` | Conditional on distinct outcomes | Replace the status placeholder with an actual result and explain its condition. Repeat for each distinct contractual outcome. |
| `@pre` | Conditional on caller obligations | Specify valid storage, bounds, aliasing, initialization, lock state, and binding requirements relevant to this operation. |
| `@post` | Conditional on guarantees | Specify output and state on success and failure, including partial work and unchanged state where guaranteed. |
| `@par Ownership` | Optional when applicable | State allocation, borrowing, transfer, retention, allocator pairing, and cleanup responsibilities. |
| `@par Reentrancy` | Optional when applicable | State whether entry can recur before an earlier call finishes, including through a callback. |
| `@par Thread Safety` | Optional when applicable | Specify permitted callers, confinement, locks, and synchronization ownership. |
| `@par Blocking` | Optional when applicable | State waits, timeouts, allowed execution contexts, and whether callback behavior affects the bound. |
| `@par Side Effects` | Optional when applicable | List mutation, allocation, callbacks, I/O, and external changes, or explicitly state their absence. |
| `@par Complexity` | Optional when applicable | Define time/storage costs and their variables, and identify the assumptions behind the claimed bound. |
| `@see` | Optional | Replace each target with an existing related operation, type, or document anchor. |
| `@showrefby` | Optional | Request the generated Referenced by view; it is not proof that all indirect callers have been found. |
| `@param[in] input` | Required for this parameter | Input: meaning, range, unit, and readable lifetime; do not imply pointer retention. The name must match the declaration. |
| `@param[out] output` | Required for this parameter | Output: writable storage, extent, nullability, and success/failure contents. The name must match the declaration. |

### 1.14. Close the private implementation group

```c
/** @} */
```

**Required for the preceding opening.** End `<MODULE_NAME>_CORE_IMPL` after its last entity and before opening
another level or closing the file. This standalone block is not part of the preceding function contract.
Keep a blank line on each side so the boundary remains visible.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@}` | Required | Close exactly the group opened for this region; do not cross or leave unmatched group boundaries. |

### 1.15. Open the internal interface group

```c
/**
 * @addtogroup <MODULE_NAME>_CORE_INTERNAL
 * @{
 */
```

**Required for this populated region.** This is a separate grouping block, placed after the includes or
preceding group's closing block and before the next section banner. `<MODULE_NAME>_CORE_INTERNAL` selects the
documentation
level for the declarations and definitions that follow. The banner remains a separate comment.

Replace the bracketed owner and use the same group identity in its owned documentation. `@{` opens
membership; a later `@}` closes it. These markers organize Doxygen output; C linkage and module visibility
still come from declarations and the architecture. Do not merge this block into an include or function comment.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@addtogroup` | Required | Fill the module/application owner; preserve the indicated level suffix. |
| `@{` | Required | Open this group and keep its matching closing block before the next level or file ending. |

### 1.16. Internal / Functions / Definitions

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *        I N T E R N A L - F U N C T I O N S - D E F I N I T I O N S
 *      Definitions of functions declared in module-internal headers.
 * ========================================================================== */

/** ============================================================================
 *  @brief      <Describe the operation provided within the owning module.>
 *  @details    <Describe behavior, boundaries, and design choices.>
 *
 *  @param[out]    operation_count <Describe storage, unit, and bounds.>
 *
 *  @return     <Specify zero success and the negative errno-style domain.>
 *          @retval     <success_code> <Describe the successful outcome.>
 *          @retval     <error_code> <Describe each failure condition.>
 *
 *  @pre        <Specify initialization, validity, and aliasing rules.>
 *  @post       <Describe outputs and state on success and failure.>
 *
 *  @par Visibility
 *              <Identify the owning translation units and permitted tests.>
 *  @par Ownership
 *              <Specify borrowing, transfer, retention, and cleanup duties.>
 *  @par Reentrancy
 *              <Specify whether recursive or callback-driven entry is allowed.>
 *  @par Thread Safety
 *              <Specify concurrency and synchronization requirements.>
 *  @par Blocking
 *              <Specify waits, timeouts, and allowed execution contexts.>
 *  @par Side Effects
 *              <List state changes, callbacks, allocation, and external I/O.>
 *  @par Complexity
 *              <Specify time and space bounds and the variables involved.>
 *
 *  @see        <related_symbol>
 *  @showrefs
 *  @showrefby
 * ========================================================================== */
int module_getCounter(unsigned int *const operation_count)
{
	/* ... */
}
```

Preserve the entire definitions banner and a complete documentation block for every function, including
all six named operational sections shown. Do not substitute an ordinary one-line comment, a reference to another
pattern, or a shortened `@copydoc` block. Each body is only `/* ... */`. Private definitions are `static`;
internal and public definitions match the corresponding header declarations. When the contract appears at both
declaration and definition, maintain them together; the header remains the authoritative caller contract.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@param[out] operation_count` | Required for this parameter | Output: writable storage, extent, nullability, and success/failure contents. The name must match the declaration. |
| `@return` | Conditional on a result | Describe the result convention and domain. Omit for void; do not use only “Integer” as its meaning. |
| `@retval` | Conditional on distinct outcomes | Replace the status placeholder with an actual result and explain its condition. Repeat for each distinct contractual outcome. |
| `@pre` | Conditional on caller obligations | Specify valid storage, bounds, aliasing, initialization, lock state, and binding requirements relevant to this operation. |
| `@post` | Conditional on guarantees | Specify output and state on success and failure, including partial work and unchanged state where guaranteed. |
| `@par Ownership` | Optional when applicable | State allocation, borrowing, transfer, retention, allocator pairing, and cleanup responsibilities. |
| `@par Reentrancy` | Optional when applicable | State whether entry can recur before an earlier call finishes, including through a callback. |
| `@par Thread Safety` | Optional when applicable | Specify permitted callers, confinement, locks, and synchronization ownership. |
| `@par Blocking` | Optional when applicable | State waits, timeouts, allowed execution contexts, and whether callback behavior affects the bound. |
| `@par Side Effects` | Optional when applicable | List mutation, allocation, callbacks, I/O, and external changes, or explicitly state their absence. |
| `@par Complexity` | Optional when applicable | Define time/storage costs and their variables, and identify the assumptions behind the claimed bound. |
| `@see` | Optional | Replace each target with an existing related operation, type, or document anchor. |
| `@showrefby` | Optional | Request the generated Referenced by view; it is not proof that all indirect callers have been found. |

### 1.17. Close the internal interface group

```c
/** @} */
```

**Required for the preceding opening.** End `<MODULE_NAME>_CORE_INTERNAL` after its last entity and before opening
another level or closing the file. This standalone block is not part of the preceding function contract.
Keep a blank line on each side so the boundary remains visible.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@}` | Required | Close exactly the group opened for this region; do not cross or leave unmatched group boundaries. |

### 1.18. Open the public interface group

```c
/**
 * @addtogroup <MODULE_NAME>_CORE_API
 * @{
 */
```

**Required for this populated region.** This is a separate grouping block, placed after the includes or
preceding group's closing block and before the next section banner. `<MODULE_NAME>_CORE_API` selects the documentation
level for the declarations and definitions that follow. The banner remains a separate comment.

Replace the bracketed owner and use the same group identity in its owned documentation. `@{` opens
membership; a later `@}` closes it. These markers organize Doxygen output; C linkage and module visibility
still come from declarations and the architecture. Do not merge this block into an include or function comment.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@addtogroup` | Required | Fill the module/application owner; preserve the indicated level suffix. |
| `@{` | Required | Open this group and keep its matching closing block before the next level or file ending. |

### 1.19. Public / Functions / Definitions

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *          P U B L I C - F U N C T I O N S - D E F I N I T I O N S
 *        Definitions of functions declared in the module public header.
 * ========================================================================== */

/** ============================================================================
 *  @brief      <Describe creation of a new module object.>
 *  @details    <Describe configuration validation and resource acquisition.>
 *
 *  @param[in]  timeout_ms <Describe timeout bounds and special values.>
 *  @param[in]  mode       <Describe accepted operation modes.>
 *  @param[out] instance   <Describe ownership and output state on failure.>
 *
 *  @return     <Specify zero success and the negative errno-style domain.>
 *          @retval     <success_code> <Describe the created object's initial
 *                      state.>
 *          @retval     <error_code> <Describe validation and allocation
 *                      failures.>
 *
 *  @pre        <Specify storage validity and output aliasing constraints.>
 *  @post       <Specify ownership on success and cleanup on failure.>
 *
 *  @par Ownership
 *              <Identify the allocator family and matching destroy operation.>
 *  @par Reentrancy
 *              <Specify whether callbacks may re-enter during creation.>
 *  @par Thread Safety
 *              <Specify synchronization and publication requirements.>
 *  @par Blocking
 *              <Specify allocation, waits, and permitted execution contexts.>
 *  @par Side Effects
 *              <List allocated resources and externally observable changes.>
 *  @par Complexity
 *              <Specify time and storage bounds for object creation.>
 *
 *  @see        <destroy_function>
 *  @showrefs
 *  @showrefby
 * ========================================================================== */
int MODULE_create(const unsigned int timeout_ms, const module_mode_t mode,
                  module_t **const instance)
{
	/* ... */
}

/** ============================================================================
 *  @brief      <Describe destruction and release of an owned module object.>
 *  @details    <Specify quiescence, teardown order, and outstanding borrows.>
 *
 *  @param[in,out] instance <Describe the handle before and after destruction.>
 *
 *  @return     <Specify zero success and the negative errno-style domain.>
 *          @retval     <success_code> <Describe resource release and handle
 *                      clearing.>
 *          @retval     <error_code> <Describe failures and the remaining
 *                      ownership.>
 *
 *  @pre        <Specify creation provenance, nullability, and quiescence.>
 *  @post       <Specify lifetime termination and handle state on each outcome.>
 *
 *  @par Ownership
 *              <Specify matching deallocation and invalidation of all aliases.>
 *  @par Reentrancy
 *              <Specify re-entry restrictions during resource release.>
 *  @par Thread Safety
 *              <Specify exclusion of concurrent users and callbacks.>
 *  @par Blocking
 *              <Specify waits and permitted teardown contexts.>
 *  @par Side Effects
 *              <List released resources and externally observable changes.>
 *  @par Complexity
 *              <Specify time and storage bounds for object destruction.>
 *
 *  @see        <create_function>
 *  @showrefs
 *  @showrefby
 * ========================================================================== */
int MODULE_destroy(module_t **const instance)
{
	/* ... */
}

/** ============================================================================
 *  @brief      <Describe the observable operation provided to the caller.>
 *  @details    <Describe behavior, boundaries, and design choices.>
 *
 *  @param[in]     input           <Specify range and unit.>
 *  @param[out]    output          <Describe storage and nullability.>
 *
 *  @return     <Specify zero success and the negative errno-style domain.>
 *          @retval     <success_code> <Describe the successful outcome.>
 *          @retval     <error_code> <Describe each failure condition.>
 *
 *  @pre        <Specify initialization, validity, and aliasing rules.>
 *  @post       <Describe outputs and state on success and failure.>
 *
 *  @par Visibility
 *              <Identify supported consumers and the export policy.>
 *  @par Ownership
 *              <Specify borrowing, transfer, retention, and cleanup duties.>
 *  @par Reentrancy
 *              <Specify whether recursive or callback-driven entry is allowed.>
 *  @par Thread Safety
 *              <Specify concurrency and synchronization requirements.>
 *  @par Blocking
 *              <Specify waits, timeouts, and allowed execution contexts.>
 *  @par Side Effects
 *              <List state changes, callbacks, allocation, and external I/O.>
 *  @par Complexity
 *              <Specify time and space bounds and the variables involved.>
 *
 *  @see        <related_symbol>
 *  @showrefs
 *  @showrefby
 * ========================================================================== */
int MODULE_process(const unsigned int input, unsigned int *const output)
{
	/* ... */
}
```

Preserve the entire definitions banner and a complete documentation block for every function, including
all six named operational sections shown. Do not substitute an ordinary one-line comment, a reference to another
pattern, or a shortened `@copydoc` block. Each body is only `/* ... */`. Private definitions are `static`;
internal and public definitions match the corresponding header declarations. When the contract appears at both
declaration and definition, maintain them together; the header remains the authoritative caller contract.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@param[in] timeout_ms` | Required for this parameter | Input: meaning, range, unit, and readable lifetime; do not imply pointer retention. The name must match the declaration. |
| `@param[in] mode` | Required for this parameter | Input: meaning, range, unit, and readable lifetime; do not imply pointer retention. The name must match the declaration. |
| `@param[out] instance` | Required for this parameter | Output: writable storage, extent, nullability, and success/failure contents. The name must match the declaration. |
| `@return` | Conditional on a result | Describe the result convention and domain. Omit for void; do not use only “Integer” as its meaning. |
| `@retval` | Conditional on distinct outcomes | Replace the status placeholder with an actual result and explain its condition. Repeat for each distinct contractual outcome. |
| `@pre` | Conditional on caller obligations | Specify valid storage, bounds, aliasing, initialization, lock state, and binding requirements relevant to this operation. |
| `@post` | Conditional on guarantees | Specify output and state on success and failure, including partial work and unchanged state where guaranteed. |
| `@par Ownership` | Optional when applicable | State allocation, borrowing, transfer, retention, allocator pairing, and cleanup responsibilities. |
| `@par Reentrancy` | Optional when applicable | State whether entry can recur before an earlier call finishes, including through a callback. |
| `@par Thread Safety` | Optional when applicable | Specify permitted callers, confinement, locks, and synchronization ownership. |
| `@par Blocking` | Optional when applicable | State waits, timeouts, allowed execution contexts, and whether callback behavior affects the bound. |
| `@par Side Effects` | Optional when applicable | List mutation, allocation, callbacks, I/O, and external changes, or explicitly state their absence. |
| `@par Complexity` | Optional when applicable | Define time/storage costs and their variables, and identify the assumptions behind the claimed bound. |
| `@see` | Optional | Replace each target with an existing related operation, type, or document anchor. |
| `@showrefs` | Optional | Request the generated References view. Its accuracy depends on source analysis and configuration. |
| `@showrefby` | Optional | Request the generated Referenced by view; it is not proof that all indirect callers have been found. |
| `@param[in,out] instance` | Required for this parameter | Input/output: accepted initial state, mutations, ownership, and state after failure. The name must match the declaration. |
| `@param[in] input` | Required for this parameter | Input: meaning, range, unit, and readable lifetime; do not imply pointer retention. The name must match the declaration. |
| `@param[out] output` | Required for this parameter | Output: writable storage, extent, nullability, and success/failure contents. The name must match the declaration. |

### 1.20. Close the public interface group

```c
/** @} */
```

**Required for the preceding opening.** End `<MODULE_NAME>_CORE_API` after its last entity and before opening
another level or closing the file. This standalone block is not part of the preceding function contract.
Keep a blank line on each side so the boundary remains visible.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@}` | Required | Close exactly the group opened for this region; do not cross or leave unmatched group boundaries. |

### 1.21. End of file

```c
/* EOF */
```

**Required.** Place the literal marker after all group and preprocessor closures. Keep one blank line
before and one after it in the physical file; the Markdown fence does not display the final empty line.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `/* EOF */` | Required | Preserve the marker and the surrounding blank lines. |

---

<a id="internal-h"></a>

## 2. Construct `internal.h`

This chapter appends every permitted internal category in order. The header may share defines, macros,
enums, incomplete types, complete structs/unions, semantic aliases, callback types, and ordinary prototypes among
owning translation units and approved internal tests. Application `main.c` may consume it under
[CMOD-015](c-module-architecture.md#cmod-015) and [CMOD-021](c-module-architecture.md#cmod-021).
It may include required standard types and approved leaf contracts, but contains no storage objects or function
bodies. Its complete types are not public API layouts.

### 2.1. License

**Required.** These are the first lines of this file.

<!-- REUSE-IgnoreStart -->

```c
/*
 * SPDX-FileCopyrightText: <year> <name> <e-mail>
 * SPDX-License-Identifier: <license>
 */
```

<!-- REUSE-IgnoreEnd -->

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `SPDX-FileCopyrightText` | Required | Fill the actual year, rights-holder name, and e-mail. Preserve imported provenance where applicable. |
| `SPDX-License-Identifier` | Required | Fill the applicable SPDX license expression; this is not a prose license summary. |

### 2.2. File documentation

**Required block.** All file fields are shown; complete or remove optional fields according to the table below.

```c
/** ============================================================================
 *  @file       <internal_header.h>
 *  @ingroup    <MODULE_NAME>
 *
 *  @brief      <Describe the interface shared within the owning module.>
 *  @details    <Define internal responsibilities and visibility boundaries.>
 *
 *  @par Direct Module Dependencies
 *    @li @ref <LEAF_CONTRACT>
 *        <Justify each required type or approved leaf-contract dependency.>
 *
 *  @par Used By
 *    @li @ref <module_implementation.c>
 *        <Identify an owning translation unit or an approved internal test.>
 *
 *  @par Provided Interfaces
 *    @li @ref <MODULE_NAME>_CORE_INTERNAL
 *        <Describe operations shared by the module's translation units.>
 *
 *  @par Consumed Runtime Ports
 *    @li @ref <callback_contract_header.h>
 *        <Identify required ports and their approved leaf contracts, if any.>
 *
 *  @par Visibility
 *              <Specify permitted consumers and build/export restrictions.>
 *  @par Invariants
 *              <Describe shared invariants maintained by every consumer.>
 *
 *  @includedbygraph
 *
 *  @version    <vX.X.XX>
 *  @date       <DD.MM.YYYY>
 *  @author     <name> <e-mail>
 * ========================================================================== */
```

Keep the blank lines between the summary, detail, relationship lists, and revision fields. A file reference
identifies an actual interface; a group reference identifies its documentation owner. Each following list
entry has a target line and an explanatory line. Do not leave an unresolved `<...>` target in published output.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@file` | Required | Use the real file name and extension. For this chapter use the file kind named in its heading. |
| `@ingroup` | Required | Name the owning module/application group. It must exist in the Doxygen input. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@par Direct Module Dependencies` | Conditional | List actual architectural/direct dependencies, not all headers reachable transitively. Explain the role of each `@ref` target. |
| `@li @ref <LEAF_CONTRACT>` | Conditional on the containing list | Fill a resolvable reference target and explain the relationship on the following line. |
| `@par Used By` | Conditional | Identify approved consumers or owning source files and explain their allowed use. |
| `@li @ref <module_implementation.c>` | Conditional on the containing list | Fill a resolvable reference target and explain the relationship on the following line. |
| `@par Provided Interfaces` | Conditional | List the public/internal interfaces declared or implemented by this file. |
| `@li @ref <MODULE_NAME>_CORE_INTERNAL` | Conditional on the containing list | Fill a resolvable reference target and explain the relationship on the following line. |
| `@par Consumed Runtime Ports` | Conditional | Describe injected services, callback contracts, binding, and provider/context lifetime. |
| `@li @ref <callback_contract_header.h>` | Conditional on the containing list | Fill a resolvable reference target and explain the relationship on the following line. |
| `@par Visibility` | Required for a header; conditional for an entity | Identify permitted consumers and symbol/export scope. Names and comments do not enforce linker visibility. |
| `@par Invariants` | Conditional | Describe constraints shared by the owning consumers and who maintains them. |
| `@includedbygraph` | Optional | Request the reverse include graph for a header when graph extraction is configured. |
| `@version` | Optional/profile-dependent | Record the maintained file/interface version, such as the specified vX.X.XX form; do not invent release metadata. |
| `@date` | Optional/profile-dependent | Fill the relevant maintained date in DD.MM.YYYY form; define what event that date represents. |
| `@author` | Optional/profile-dependent | Fill attribution with the actual name and e-mail. This does not replace provenance or review ownership. |

### 2.3. Open the include guard

```c
/* Include Guard */
#if !defined(LMA_MODULE_INTERNAL_H)
  #define LMA_MODULE_INTERNAL_H
```

**Required.** Use a unique project-prefixed guard under [CSTYLE-026](c-code-standard.md#cstyle-026).
Public and internal guard names differ. The guard begins before dependency includes and ends after the
C++ compatibility closing block. It prevents repeated declarations; it does not synchronize runtime access.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `#if !defined(...)` | Required | Use the unique guard for this header. |
| `#define` | Required | Define exactly the same guard inside the conditional. |

### 2.4. Internal / Includes

```c
/** ============================================================================
 *                     I N T E R N A L - I N C L U D E S
 *       Minimum type and approved leaf-contract dependencies.
 * ========================================================================== */

/* Required Standard Type Headers */
  #include <stddef.h>

/* Approved Leaf Contract Headers */
```

**Conditional section; required for the types used below.** This header directly includes
`<stddef.h>` because it declares `size_t` in `module_work_index_t`. Place this section after the include guard and
before C++ compatibility and the documentation group. Preserve the full banner. The leaf-contract label is
an optional slot: add an include only when the declared interface needs an approved leaf; remove the
empty label from a completed header.

[CMOD-009](c-module-architecture.md#cmod-009) requires minimum dependencies and forward declarations when
pointers to incomplete types suffice. [CMOD-010](c-module-architecture.md#cmod-010) permits necessary
standard ABI type headers and approved leaf contracts with a documented type-completeness or ABI-spelling
reason. It does not permit convenience aggregation or another peer module's public/internal header.

| Possible dependency | Condition and owning rule |
| --- | --- |
| Required C standard type header | Include the header declaring the types this interface uses, as above; do not rely on an includer's order. [CMOD-010](c-module-architecture.md#cmod-010). |
| `"types.h"` | Only an approved scalar/value foundation leaf with its minimum standard dependencies; no service API, callbacks, or state. Do not introduce it just to replace a direct standard include. [CMOD-011](c-module-architecture.md#cmod-011). |
| An approved DTO contract header | Include only for a needed contract with no peer implementation dependencies. Document extents, units, ownership, and lifetime; the leaf exception does not publish private object layouts. [CMOD-012](c-module-architecture.md#cmod-012). |
| An approved callback contract header | Include a necessary consumer-owned port independent of its concrete provider, with only required DTO/standard leaves. [CMOD-013](c-module-architecture.md#cmod-013). |
| An explicitly approved ABI-annotation leaf | Its exact macros-only scope must be approved for the platform profile; a foundation path alone grants no permission. [CMOD-010](c-module-architecture.md#cmod-010). |

Explain each actual dependency in the file's `Direct Module Dependencies` list. A forward declaration must
be a valid declaration of the owned type; do not hand-declare a standard typedef or copy another interface.
Compile headers independently with their documented usage requirements under
[CMOD-014](c-module-architecture.md#cmod-014) and [CSTYLE-034](c-code-standard.md#cstyle-034).
A source file still includes its own direct dependencies under [CMOD-016](c-module-architecture.md#cmod-016).

This internal header remains in the module's private include path. Its permitted consumers and the `main.c`
exception are defined by [CMOD-015](c-module-architecture.md#cmod-015); an allowed leaf include does not
turn this header into a public interface.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| Section banner | Conditional | Retain the full visibility/category banner when includes are needed. |
| Required Standard Type Headers | Conditional | Include the exact standard owner of each required type. |
| Approved Leaf Contract Headers | Conditional | Add only approved, necessary leaves; document the reason and remove an unused slot. |

### 2.5. Open C++ compatibility

```c
  /*< C++ Compatibility >*/
  #ifdef __cplusplus
extern "C"
{
  #endif
```

**Required when this header supports C++ inclusion.** Preserve the exact marker and `__cplusplus`
conditional. Each compatible header owns both halves of its linkage block under
[CMOD-019](c-module-architecture.md#cmod-019). The guarded `extern "C"` opening is the sole permitted
project-authored `extern` construct under [CMOD-017](c-module-architecture.md#cmod-017).

Place required includes before this opening, inside the include guard. Dependencies own their linkage
requirements; the block encloses this header's declarations. In C, the conditional omits the linkage syntax.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `/*< C++ Compatibility >*/` | Required | Keep the marker verbatim on both halves. |
| `#ifdef __cplusplus` / `#endif` | Required | Condition the linkage syntax, not the C declarations. |
| `extern "C"` / `{` | Required for C++ | Match the opening and closing braces across this header only. |

### 2.6. Open the internal interface group

```c
/**
 * @addtogroup <MODULE_NAME>_CORE_INTERNAL
 * @{
 */
```

**Required for this populated region.** This is a separate grouping block, placed after the includes or
preceding group's closing block and before the next section banner. `<MODULE_NAME>_CORE_INTERNAL` selects the
documentation
level for the declarations and definitions that follow. The banner remains a separate comment.

Replace the bracketed owner and use the same group identity in its owned documentation. `@{` opens
membership; a later `@}` closes it. These markers organize Doxygen output; C linkage and module visibility
still come from declarations and the architecture. Do not merge this block into an include or function comment.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@addtogroup` | Required | Fill the module/application owner; preserve the indicated level suffix. |
| `@{` | Required | Open this group and keep its matching closing block before the next level or file ending. |

### 2.7. Internal / Defines

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *                     I N T E R N A L - D E F I N E S
 *             Constants shared by the owning module's source files.
 * ========================================================================== */

/** ============================================================================
 *  @def        <MODULE_NAME>_INTERNAL_MAX_ITEMS
 *
 *  @brief      <Describe the capacity shared by internal operations.>
 *  @details    <Specify the unit, type, bounds, and capacity rationale.>
 *
 *  @par Used By
 *              <Identify the owning translation units that require this limit.>
 *  @warning    <Describe the storage and validation impact of limit changes.>
 * ========================================================================== */
  #define MODULE_INTERNAL_MAX_ITEMS ((unsigned int)(16U))
```

The banner introduces object-like macros, not function-like macros or allocated objects. Every shown macro
has its own complete block. Match `@def` to the actual name, explain the unit and value rationale, and preserve
the typed constant spelling required by the C standard. Source-local definitions are PRIVATE, same-module
shared definitions INTERNAL, and published constants PUBLIC. A cast-bearing macro is not automatically valid
inside a preprocessor `#if` expression.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@def` | Required in this displayed pattern | Replace the bracketed module prefix and match the macro name and argument spelling exactly. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@par Used By` | Conditional | Identify approved consumers or owning source files and explain their allowed use. |
| `@warning` | Conditional on a hazard | Explain a concrete hazard or restriction and its consequence; do not use a generic warning as a substitute for a contract. |

### 2.8. Internal / Macros

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *                       I N T E R N A L - M A C R O S
 *            Preprocessing operations shared within the owning module.
 * ========================================================================== */

/** ============================================================================
 *  @def        <MODULE_NAME>_INTERNAL_STRINGIFY(token_)
 *
 *  @brief      <Describe the internal token-to-string operation.>
 *  @details    <Justify preprocessing instead of a typed function.>
 *
 *  @param[in]  token_ <Specify accepted tokens and expansion requirements.>
 *
 *  @return     <Describe the resulting string literal and its intended use.>
 *  @warning    <Specify direct stringification without prior macro expansion.>
 * ========================================================================== */
  #define MODULE_INTERNAL_STRINGIFY(token_) #token_
```

The banner introduces function-like macros. Keep the documentation for preprocessing behavior and every
argument. A stringification macro and a statement macro have different contracts: explain expansion for the
former and lvalues, evaluation counts, aliasing, and side effects for the latter. The statement scaffold retains
`do`, braces, continuations, `while (0)`, and `/* ... */`; it is not a working implementation. A macro requires
justification under [CSTYLE-042/044](c-code-standard.md#cstyle-042).

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@def` | Required in this displayed pattern | Replace the bracketed module prefix and match the macro name and argument spelling exactly. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@param[in] token_` | Required for this parameter | Input: meaning, range, unit, and readable lifetime; do not imply pointer retention. The name must match the declaration. |
| `@return` | Conditional on a result | Describe the result convention and domain. Omit for void; do not use only “Integer” as its meaning. |
| `@warning` | Conditional on a hazard | Explain a concrete hazard or restriction and its consequence; do not use a generic warning as a substitute for a contract. |

### 2.9. Internal / Enums

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *                        I N T E R N A L - E N U M S
 *                Value domains shared within the owning module.
 * ========================================================================== */

/** ============================================================================
 *  @enum       <ModuleName>WorkState
 *
 *  @brief      <Describe the internal work lifecycle.>
 *  @details    <Specify valid transitions and which component owns each one.>
 *
 *  @par Values
 *    @li @b MODULE_WORK_PENDING
 *        <Describe the pending state and its entry requirements.>
 *    @li @b MODULE_WORK_COMPLETE
 *        <Describe successful completion and its output guarantees.>
 *    @li @b MODULE_WORK_FAILED
 *        <Describe failure and the permitted recovery transitions.>
 *
 *  @invariant  <Specify valid runtime values and transition constraints.>
 * ========================================================================== */
typedef enum ModuleWorkState
{
	MODULE_WORK_PENDING  = ((unsigned int)(0u)),
	MODULE_WORK_COMPLETE = ((unsigned int)(1u)),
	MODULE_WORK_FAILED   = ((unsigned int)(2u)),

	/*< Enum max value >*/
	MODULE_WORK_MAX = ((unsigned int)(3u))
} module_work_state_t; /**< <Type alias.> */

/** ============================================================================
 *  @enum       <ModuleName>ValueKind
 *
 *  @brief      <Describe the discriminator for an internal value.>
 *  @details    <Specify how the discriminator selects the active union member.>
 *
 *  @par Values
 *    @li @b MODULE_VALUE_UNSIGNED
 *        <Identify the unsigned member and its valid domain.>
 *    @li @b MODULE_VALUE_SIGNED
 *        <Identify the signed member and its valid domain.>
 * ========================================================================== */
typedef enum ModuleValueKind
{
	MODULE_VALUE_UNSIGNED = ((unsigned int)(0u)),
	MODULE_VALUE_SIGNED   = ((unsigned int)(1u)),

	/*< Enum max value >*/
	MODULE_VALUE_MAX = ((unsigned int)(3u))
} module_value_kind_t; /**< <Type alias.> */
```

Preserve the full enum banner, the type contract, the Values list, the declaration, and its alias. Each
`@li @b` names an actual enumerator. Explicit values and the casts shown illustrate this project's source
convention; they do not fix the underlying enum size. Document the count sentinel when present and keep its
name distinct from capacity macros. Remove a sentinel that has no count/indexing purpose.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@enum` | Required in this displayed pattern | Name the enum tag, including the suffix shown, rather than confusing it with its typedef alias. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@par Values` | Required for the shown enum pattern | Keep the full @li @b list. Explain the meaning and transitions of each named enumerator. |
| `@li @b MODULE_WORK_PENDING` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@li @b MODULE_WORK_COMPLETE` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@li @b MODULE_WORK_FAILED` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@invariant` | Conditional on representation/state constraints | State relationships maintained by all valid states or mutations. This is documentation, not an executable proof. |
| `@li @b MODULE_VALUE_UNSIGNED` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@li @b MODULE_VALUE_SIGNED` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `Enum max value / *_MAX` | Conditional | This names a count only for a zero-based contiguous enum that needs one. It is not a valid runtime state or an ABI-width declaration. |

### 2.10. Internal / Opaque / Types

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *                 I N T E R N A L - O P A Q U E - T Y P E S
 *       Incomplete types shared by identity within the owning module.
 * ========================================================================== */

/** ============================================================================
 *  @typedef    <module_name>_cursor_t
 *
 *  @brief      <Describe the internal object shared only through pointers.>
 *  @details    <Identify the owning source that defines its representation.>
 *
 *  @par Ownership
 *              <Specify creation, borrowing, and destruction within the
 *              module.>
 *  @par Lifetime
 *              <Specify validity and invalidation of cursor aliases.>
 *
 *  @see        <internal_cursor_operation>
 * ========================================================================== */
typedef struct ModuleCursor module_cursor_t;
```

The banner contains forward declarations only. The struct tag identifies the incomplete type; the alias
provides the module-owned spelling. Explain object identity, ownership, and lifetime without listing hidden
fields or promising `sizeof`. Complete the type once at its owning implementation scope. An opaque cursor used
only by the owning module can be declared internally without becoming a public handle.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@typedef` | Required in this displayed pattern | Name the alias or callback typedef exactly; preserve the project lowercase alias convention. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@par Ownership` | Optional when applicable | State allocation, borrowing, transfer, retention, allocator pairing, and cleanup responsibilities. |
| `@par Lifetime` | Conditional; required for handles/borrows | Specify creation, destruction, alias validity, and invalidation events. |
| `@see` | Optional | Replace each target with an existing related operation, type, or document anchor. |

### 2.11. Internal / Structs / Definitions

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *        I N T E R N A L - S T R U C T S - D E F I N I T I O N S
 *          Complete representations shared within the owning module.
 * ========================================================================== */

/** ============================================================================
 *  @union      <ModuleName>WorkValue
 *
 *  @brief      <Describe alternative representations of an internal value.>
 *  @details    <Specify how the containing object's tag selects the member.>
 *
 *  @par Fields
 *    @li @b unsigned_value
 *        <Specify the unsigned value's range and unit.>
 *    @li @b signed_value
 *        <Specify the signed value's range and unit.>
 *
 *  @invariant  <Require reads to match the tag and the last member written.>
 * ========================================================================== */
typedef union ModuleWorkValue
{
	unsigned int unsigned_value; /**< <Unsigned value and unit.> */
	int          signed_value; /**< <Signed value and unit.> */
} module_work_value_t; /**< <Type alias.> */

/** ============================================================================
 *  @struct     <ModuleName>Work
 *
 *  @brief      <Describe work shared by the module's implementation files.>
 *  @details    <Identify the files that need this layout and their duties.>
 *
 *  @par Fields
 *    @li @b state
 *        <Specify initialization and permitted lifecycle transitions.>
 *    @li @b kind
 *        <Specify which value member is active.>
 *    @li @b value
 *        <Specify the stored value's meaning and validity in each state.>
 *
 *  @invariant  <Relate the state, discriminator, and active value member.>
 *
 *  @par Ownership
 *              <Specify allocation, borrowing, lifetime, and cleanup duties.>
 *  @par Synchronization
 *              <Specify exclusive access and publication of state changes.>
 *  @par Representation
 *              <State why the layout is shared internally and not exported.>
 * ========================================================================== */
typedef struct ModuleWork
{
	module_work_state_t state; /**< <Current work state.> */
	module_value_kind_t kind; /**< <Active value discriminator.> */
	module_work_value_t value; /**< <Value selected by kind.> */
} module_work_t; /**< <Type alias.> */

/** ============================================================================
 *  @struct     <ModuleName>WorkBatch
 *
 *  @brief      <Describe bounded storage for a group of internal work items.>
 *  @details    <Specify initialization and the files that share this layout.>
 *
 *  @par Fields
 *    @li @b item_count
 *        <Specify the number of initialized items and the capacity bound.>
 *    @li @b items
 *        <Specify item ownership, ordering, and the valid index interval.>
 *
 *  @invariant  <Require item_count not to exceed the internal capacity.>
 *
 *  @par Ownership
 *              <Specify batch lifetime and invalidation of borrowed items.>
 *  @par Synchronization
 *              <Specify who may read or mutate the batch and its items.>
 * ========================================================================== */
typedef struct ModuleWorkBatch
{
	unsigned int item_count; /**< <Initialized item count.> */

	/** <Work storage; only initialized elements may be read.> */
	module_work_t items[MODULE_INTERNAL_MAX_ITEMS];
} module_work_batch_t; /**< <Type alias.> */
```

Keep the entire representation banner and every per-type block. `@struct` and `@union` identify tags;
`@par Fields` explains members and relationships; trailing `/**< ... */` comments remain beside the declarations.
A union's active-member rule is mandatory information. An internal complete type is shared by owning source
files; a private complete type is owned by one translation unit. Do not duplicate its definition in both.
There is no corresponding complete-structure section in `public.h`.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@union` | Required in this displayed pattern | Name the union tag and retain the active-member contract beneath it. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@par Fields` | Required for the shown complete-type pattern | Keep the full @li @b list. Explain units, bounds, valid states, and relationships for each named member. |
| `@li @b unsigned_value` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@li @b signed_value` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@invariant` | Conditional on representation/state constraints | State relationships maintained by all valid states or mutations. This is documentation, not an executable proof. |
| `@struct` | Required in this displayed pattern | Name the struct tag whose complete representation follows. |
| `@li @b state` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@li @b kind` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@li @b value` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@par Ownership` | Optional when applicable | State allocation, borrowing, transfer, retention, allocator pairing, and cleanup responsibilities. |
| `@par Synchronization` | Conditional on mutable/shared state | Name the actual lock, confinement, publication, or access discipline for all affected fields. |
| `@par Representation` | Conditional on a representation boundary | Identify where the complete type is owned and which layout decisions remain private. |
| `@li @b item_count` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@li @b items` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `/**< <...> */` | Required for the shown member pattern | Keep the trailing comment beside its field. Fill the short local meaning; the Fields list explains relationships and constraints. |

### 2.12. Internal / Typedefs

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *                     I N T E R N A L - T Y P E D E F S
 *             Scalar aliases and callbacks shared within the module.
 * ========================================================================== */

/** ============================================================================
 *  @typedef    <module_name>_work_index_t
 *
 *  @brief      <Describe the internal index domain.>
 *  @details    <Specify bounds relative to item_count and reserved values.>
 * ========================================================================== */
typedef size_t module_work_index_t;

/** ============================================================================
 *  @typedef    <module_name>_visit_fn_t
 *
 *  @brief      <Describe the callback used by internal work traversal.>
 *  @details    <Specify invocation order and how callback errors propagate.>
 *
 *  @param[in]     work    <Describe the borrowed item and its valid state.>
 *  @param[in,out] context <Describe callback-owned state and nullability.>
 *
 *  @return     <Specify zero success and the negative errno-style domain.>
 *          @retval     <success_code> <Describe successful item processing.>
 *          @retval     <error_code> <Describe failure and traversal
 *                      termination.>
 *
 *  @pre        <Specify callback binding and validity of both arguments.>
 *  @post       <Specify work and context guarantees on every outcome.>
 *
 *  @par Ownership
 *              <Specify borrowing duration, retention, and context lifetime.>
 *  @par Reentrancy
 *              <Specify whether the callback may re-enter the traversal.>
 *  @par Thread Safety
 *              <Specify synchronization of work and callback state.>
 *  @par Blocking
 *              <Specify whether callback execution may block.>
 *  @par Side Effects
 *              <List allowed mutations and external effects.>
 *  @par Complexity
 *              <Specify callback time and additional storage bounds.>
 * ========================================================================== */
typedef int (*module_visit_fn_t)(const module_work_t *work,
                                 void *const          context);
```

The banner covers aliases and callback signatures. Each alias explains a semantic domain; each callback
has the full callable contract shown, including argument directions, outcomes, state guarantees, ownership,
reentrancy, thread safety, blocking, effects, and cost. A void context pointer is not permission to expose a
provider's layout. Shared peer ports follow [CMOD-013](c-module-architecture.md#cmod-013); this section is not an
implicit dependency on another module.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@typedef` | Required in this displayed pattern | Name the alias or callback typedef exactly; preserve the project lowercase alias convention. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@param[in] work` | Required for this parameter | Input: meaning, range, unit, and readable lifetime; do not imply pointer retention. The name must match the declaration. |
| `@param[in,out] context` | Required for this parameter | Input/output: accepted initial state, mutations, ownership, and state after failure. The name must match the declaration. |
| `@return` | Conditional on a result | Describe the result convention and domain. Omit for void; do not use only “Integer” as its meaning. |
| `@retval` | Conditional on distinct outcomes | Replace the status placeholder with an actual result and explain its condition. Repeat for each distinct contractual outcome. |
| `@pre` | Conditional on caller obligations | Specify valid storage, bounds, aliasing, initialization, lock state, and binding requirements relevant to this operation. |
| `@post` | Conditional on guarantees | Specify output and state on success and failure, including partial work and unchanged state where guaranteed. |
| `@par Ownership` | Optional when applicable | State allocation, borrowing, transfer, retention, allocator pairing, and cleanup responsibilities. |
| `@par Reentrancy` | Optional when applicable | State whether entry can recur before an earlier call finishes, including through a callback. |
| `@par Thread Safety` | Optional when applicable | Specify permitted callers, confinement, locks, and synchronization ownership. |
| `@par Blocking` | Optional when applicable | State waits, timeouts, allowed execution contexts, and whether callback behavior affects the bound. |
| `@par Side Effects` | Optional when applicable | List mutation, allocation, callbacks, I/O, and external changes, or explicitly state their absence. |
| `@par Complexity` | Optional when applicable | Define time/storage costs and their variables, and identify the assumptions behind the claimed bound. |

### 2.13. Internal / Functions / Prototypes

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *         I N T E R N A L - F U N C T I O N S - P R O T O T Y P E S
 *               Declarations shared only by the owning module.
 * ========================================================================== */

/** ============================================================================
 *  @brief      <Describe the operation provided within the owning module.>
 *  @details    <Describe behavior, boundaries, and design choices.>
 *
 *  @param[out]    operation_count <Describe storage, unit, and bounds.>
 *
 *  @return     <Specify zero success and the negative errno-style domain.>
 *          @retval     <success_code> <Describe the successful outcome.>
 *          @retval     <error_code> <Describe each failure condition.>
 *
 *  @pre        <Specify initialization, validity, and aliasing rules.>
 *  @post       <Describe outputs and state on success and failure.>
 *
 *  @par Visibility
 *              <Identify the owning translation units and permitted tests.>
 *  @par Ownership
 *              <Specify borrowing, transfer, retention, and cleanup duties.>
 *  @par Reentrancy
 *              <Specify whether recursive or callback-driven entry is allowed.>
 *  @par Thread Safety
 *              <Specify concurrency and synchronization requirements.>
 *  @par Blocking
 *              <Specify waits, timeouts, and allowed execution contexts.>
 *  @par Side Effects
 *              <List state changes, callbacks, allocation, and external I/O.>
 *  @par Complexity
 *              <Specify time and space bounds and the variables involved.>
 *
 *  @see        <related_symbol>
 *  @showrefs
 *  @showrefby
 * ========================================================================== */
int module_getCounter(unsigned int *const operation_count);

/** ============================================================================
 *  @brief      <Describe traversal of the initialized items in a work batch.>
 *  @details    <Specify ordering, callback selection, and early termination.>
 *
 *  @param[in]     batch   <Describe batch validity and the initialized range.>
 *  @param[in]     visit   <Describe the callback and nullability constraints.>
 *  @param[in,out] context <Describe callback state and required lifetime.>
 *
 *  @return     <Specify zero success and the negative errno-style domain.>
 *          @retval     <success_code> <Describe completion of the selected
 *                      traversal.>
 *          @retval     <error_code> <Describe validation and callback
 *                      failures.>
 *
 *  @pre        <Specify count bounds, item invariants, and callback validity.>
 *  @post       <Specify completed work and partial effects after failure.>
 *
 *  @par Visibility
 *              <Identify owning source files and approved internal tests.>
 *  @par Ownership
 *              <Specify borrowing and forbid retention beyond valid lifetimes.>
 *  @par Reentrancy
 *              <Specify restrictions on recursive traversal and mutation.>
 *  @par Thread Safety
 *              <Specify batch stability and synchronization of callback state.>
 *  @par Blocking
 *              <Specify blocking inherited from the callback contract.>
 *  @par Side Effects
 *              <Describe callback effects and guarantees for the batch.>
 *  @par Complexity
 *              <Specify bounds in item_count and callback execution cost.>
 *
 *  @see        <internal_callback_type>
 *  @showrefs
 *  @showrefby
 * ========================================================================== */
int module_visitWork(const module_work_batch_t *const batch,
                     const module_visit_fn_t visit, void *const context);
```

Preserve the entire prototypes banner and every declaration. Private helpers use `static`; internal and
public prototypes use their respective naming conventions without an explicit `extern` storage class. Private
prototypes can be bare when the complete block appears at the definition below. Header prototypes carry the
full contract because their consumers must not inspect implementation bodies to learn the interface.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@param[out] operation_count` | Required for this parameter | Output: writable storage, extent, nullability, and success/failure contents. The name must match the declaration. |
| `@return` | Conditional on a result | Describe the result convention and domain. Omit for void; do not use only “Integer” as its meaning. |
| `@retval` | Conditional on distinct outcomes | Replace the status placeholder with an actual result and explain its condition. Repeat for each distinct contractual outcome. |
| `@pre` | Conditional on caller obligations | Specify valid storage, bounds, aliasing, initialization, lock state, and binding requirements relevant to this operation. |
| `@post` | Conditional on guarantees | Specify output and state on success and failure, including partial work and unchanged state where guaranteed. |
| `@par Visibility` | Required for a header; conditional for an entity | Identify permitted consumers and symbol/export scope. Names and comments do not enforce linker visibility. |
| `@par Ownership` | Optional when applicable | State allocation, borrowing, transfer, retention, allocator pairing, and cleanup responsibilities. |
| `@par Reentrancy` | Optional when applicable | State whether entry can recur before an earlier call finishes, including through a callback. |
| `@par Thread Safety` | Optional when applicable | Specify permitted callers, confinement, locks, and synchronization ownership. |
| `@par Blocking` | Optional when applicable | State waits, timeouts, allowed execution contexts, and whether callback behavior affects the bound. |
| `@par Side Effects` | Optional when applicable | List mutation, allocation, callbacks, I/O, and external changes, or explicitly state their absence. |
| `@par Complexity` | Optional when applicable | Define time/storage costs and their variables, and identify the assumptions behind the claimed bound. |
| `@see` | Optional | Replace each target with an existing related operation, type, or document anchor. |
| `@showrefs` | Optional | Request the generated References view. Its accuracy depends on source analysis and configuration. |
| `@showrefby` | Optional | Request the generated Referenced by view; it is not proof that all indirect callers have been found. |
| `@param[in] batch` | Required for this parameter | Input: meaning, range, unit, and readable lifetime; do not imply pointer retention. The name must match the declaration. |
| `@param[in] visit` | Required for this parameter | Input: meaning, range, unit, and readable lifetime; do not imply pointer retention. The name must match the declaration. |
| `@param[in,out] context` | Required for this parameter | Input/output: accepted initial state, mutations, ownership, and state after failure. The name must match the declaration. |

**Categories omitted by rule:** there are no constants/variables that allocate storage, function-definition
sections, or application entry point. Complete internal type declarations above do not allocate global objects.

### 2.14. Close the internal interface group

```c
/** @} */
```

**Required for the preceding opening.** End `<MODULE_NAME>_CORE_INTERNAL` after its last entity and before opening
another level or closing the file. This standalone block is not part of the preceding function contract.
Keep a blank line on each side so the boundary remains visible.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@}` | Required | Close exactly the group opened for this region; do not cross or leave unmatched group boundaries. |

### 2.15. Close C++ compatibility

```c
  /*< C++ Compatibility >*/
  #ifdef __cplusplus
}
  #endif
```

**Required when this header supports C++ inclusion.** Preserve the exact marker and `__cplusplus`
conditional. Each compatible header owns both halves of its linkage block under
[CMOD-019](c-module-architecture.md#cmod-019). The guarded `extern "C"` opening is the sole permitted
project-authored `extern` construct under [CMOD-017](c-module-architecture.md#cmod-017).

Close the visibility group first, then this linkage block, and finally the include guard.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `/*< C++ Compatibility >*/` | Required | Keep the marker verbatim on both halves. |
| `#ifdef __cplusplus` / `#endif` | Required | Condition the linkage syntax, not the C declarations. |
| `}` | Required for C++ | Match the opening and closing braces across this header only. |

### 2.16. Close the include guard

```c
#endif /* LMA_MODULE_INTERNAL_H */
```

**Required.** Close the guard after the group and C++ compatibility blocks. Match its opening name.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `#endif /* ... */` | Required | Preserve the exact opening guard identifier in the closing comment. |

### 2.17. End of file

```c
/* EOF */
```

**Required.** Place the literal marker after all group and preprocessor closures. Keep one blank line
before and one after it in the physical file; the Markdown fence does not display the final empty line.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `/* EOF */` | Required | Preserve the marker and the surrounding blank lines. |

---

<a id="public-h"></a>

## 3. Construct `public.h`

This chapter appends every public category in order: defines, justified function-like macros, enums,
opaque declarations, semantic aliases, callback declarations, and public function prototypes. Structures remain
incomplete. Required standard types and approved leaf contracts may be included under the rules explained
below. There are no complete struct/union definitions, objects, private helpers, or function bodies.
The compatibility blocks belong to this header, not to each includer.

### 3.1. License

**Required.** These are the first lines of this file.

<!-- REUSE-IgnoreStart -->

```c
/*
 * SPDX-FileCopyrightText: <year> <name> <e-mail>
 * SPDX-License-Identifier: <license>
 */
```

<!-- REUSE-IgnoreEnd -->

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `SPDX-FileCopyrightText` | Required | Fill the actual year, rights-holder name, and e-mail. Preserve imported provenance where applicable. |
| `SPDX-License-Identifier` | Required | Fill the applicable SPDX license expression; this is not a prose license summary. |

### 3.2. File documentation

**Required block.** All file fields are shown; complete or remove optional fields according to the table below.

```c
/** ============================================================================
 *  @file       <public_header.h>
 *  @ingroup    <MODULE_NAME>
 *
 *  @brief      <Describe the supported public interface of the module.>
 *  @details    <Define its scope, consumers, and compatibility guarantees.>
 *
 *  @par Direct Module Dependencies
 *    @li @ref <LEAF_CONTRACT>
 *        <Justify each required type or approved leaf-contract dependency.>
 *
 *  @par Used By
 *    @li @ref <CONSUMER_MODULE>
 *        <Describe the consumer's permitted use of this public interface.>
 *
 *  @par Provided Interfaces
 *    @li @ref <MODULE_NAME>_CORE_API
 *        <Describe supported operations and their observable behavior.>
 *
 *  @par Consumed Runtime Ports
 *    @li @ref <callback_contract_header.h>
 *        <Identify required ports and their approved leaf contracts, if any.>
 *
 *  @par Compatibility
 *              <Specify language baseline, ABI profile, and evolution policy.>
 *
 *  @includedbygraph
 *
 *  @version    <vX.X.XX>
 *  @date       <DD.MM.YYYY>
 *  @author     <name> <e-mail>
 * ========================================================================== */
```

Keep the blank lines between the summary, detail, relationship lists, and revision fields. A file reference
identifies an actual interface; a group reference identifies its documentation owner. Each following list
entry has a target line and an explanatory line. Do not leave an unresolved `<...>` target in published output.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@file` | Required | Use the real file name and extension. For this chapter use the file kind named in its heading. |
| `@ingroup` | Required | Name the owning module/application group. It must exist in the Doxygen input. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@par Direct Module Dependencies` | Conditional | List actual architectural/direct dependencies, not all headers reachable transitively. Explain the role of each `@ref` target. |
| `@li @ref <LEAF_CONTRACT>` | Conditional on the containing list | Fill a resolvable reference target and explain the relationship on the following line. |
| `@par Used By` | Conditional | Identify approved consumers or owning source files and explain their allowed use. |
| `@li @ref <CONSUMER_MODULE>` | Conditional on the containing list | Fill a resolvable reference target and explain the relationship on the following line. |
| `@par Provided Interfaces` | Conditional | List the public/internal interfaces declared or implemented by this file. |
| `@li @ref <MODULE_NAME>_CORE_API` | Conditional on the containing list | Fill a resolvable reference target and explain the relationship on the following line. |
| `@par Consumed Runtime Ports` | Conditional | Describe injected services, callback contracts, binding, and provider/context lifetime. |
| `@li @ref <callback_contract_header.h>` | Conditional on the containing list | Fill a resolvable reference target and explain the relationship on the following line. |
| `@par Compatibility` | Conditional on a promise | Specify language and ABI profiles and evolution assumptions without claiming enum width or layout portability. |
| `@includedbygraph` | Optional | Request the reverse include graph for a header when graph extraction is configured. |
| `@version` | Optional/profile-dependent | Record the maintained file/interface version, such as the specified vX.X.XX form; do not invent release metadata. |
| `@date` | Optional/profile-dependent | Fill the relevant maintained date in DD.MM.YYYY form; define what event that date represents. |
| `@author` | Optional/profile-dependent | Fill attribution with the actual name and e-mail. This does not replace provenance or review ownership. |

### 3.3. Open the include guard

```c
/* Include Guard */
#if !defined(LMA_MODULE_PUBLIC_H)
  #define LMA_MODULE_PUBLIC_H
```

**Required.** Use a unique project-prefixed guard under [CSTYLE-026](c-code-standard.md#cstyle-026).
Public and internal guard names differ. The guard begins before dependency includes and ends after the
C++ compatibility closing block. It prevents repeated declarations; it does not synchronize runtime access.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `#if !defined(...)` | Required | Use the unique guard for this header. |
| `#define` | Required | Define exactly the same guard inside the conditional. |

### 3.4. Public / Includes

```c
/** ============================================================================
 *                       P U B L I C - I N C L U D E S
 *       Minimum type and approved leaf-contract dependencies.
 * ========================================================================== */

/* Required Standard Type Headers */
  #include <stdint.h>

/* Approved Leaf Contract Headers */
```

**Conditional section; required for the types used below.** This header directly includes
`<stdint.h>` because it declares `uint32_t` in `module_request_id_t`. Place this section after the include guard and
before C++ compatibility and the documentation group. Preserve the full banner. The leaf-contract label is
an optional slot: add an include only when the declared interface needs an approved leaf; remove the
empty label from a completed header.
The supported target profile must provide `uint32_t`; choose the actual contractual width deliberately.

[CMOD-009](c-module-architecture.md#cmod-009) requires minimum dependencies and forward declarations when
pointers to incomplete types suffice. [CMOD-010](c-module-architecture.md#cmod-010) permits necessary
standard ABI type headers and approved leaf contracts with a documented type-completeness or ABI-spelling
reason. It does not permit convenience aggregation or another peer module's public/internal header.

| Possible dependency | Condition and owning rule |
| --- | --- |
| Required C standard type header | Include the header declaring the types this interface uses, as above; do not rely on an includer's order. [CMOD-010](c-module-architecture.md#cmod-010). |
| `"types.h"` | Only an approved scalar/value foundation leaf with its minimum standard dependencies; no service API, callbacks, or state. Do not introduce it just to replace a direct standard include. [CMOD-011](c-module-architecture.md#cmod-011). |
| An approved DTO contract header | Include only for a needed contract with no peer implementation dependencies. Document extents, units, ownership, and lifetime; the leaf exception does not publish private object layouts. [CMOD-012](c-module-architecture.md#cmod-012). |
| An approved callback contract header | Include a necessary consumer-owned port independent of its concrete provider, with only required DTO/standard leaves. [CMOD-013](c-module-architecture.md#cmod-013). |
| An explicitly approved ABI-annotation leaf | Its exact macros-only scope must be approved for the platform profile; a foundation path alone grants no permission. [CMOD-010](c-module-architecture.md#cmod-010). |

Explain each actual dependency in the file's `Direct Module Dependencies` list. A forward declaration must
be a valid declaration of the owned type; do not hand-declare a standard typedef or copy another interface.
Compile headers independently with their documented usage requirements under
[CMOD-014](c-module-architecture.md#cmod-014) and [CSTYLE-034](c-code-standard.md#cstyle-034).
A source file still includes its own direct dependencies under [CMOD-016](c-module-architecture.md#cmod-016).

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| Section banner | Conditional | Retain the full visibility/category banner when includes are needed. |
| Required Standard Type Headers | Conditional | Include the exact standard owner of each required type. |
| Approved Leaf Contract Headers | Conditional | Add only approved, necessary leaves; document the reason and remove an unused slot. |

### 3.5. Open C++ compatibility

```c
  /*< C++ Compatibility >*/
  #ifdef __cplusplus
extern "C"
{
  #endif
```

**Required when this header supports C++ inclusion.** Preserve the exact marker and `__cplusplus`
conditional. Each compatible header owns both halves of its linkage block under
[CMOD-019](c-module-architecture.md#cmod-019). The guarded `extern "C"` opening is the sole permitted
project-authored `extern` construct under [CMOD-017](c-module-architecture.md#cmod-017).

Place required includes before this opening, inside the include guard. Dependencies own their linkage
requirements; the block encloses this header's declarations. In C, the conditional omits the linkage syntax.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `/*< C++ Compatibility >*/` | Required | Keep the marker verbatim on both halves. |
| `#ifdef __cplusplus` / `#endif` | Required | Condition the linkage syntax, not the C declarations. |
| `extern "C"` / `{` | Required for C++ | Match the opening and closing braces across this header only. |

### 3.6. Open the public interface group

```c
/**
 * @addtogroup <MODULE_NAME>_CORE_API
 * @{
 */
```

**Required for this populated region.** This is a separate grouping block, placed after the includes or
preceding group's closing block and before the next section banner. `<MODULE_NAME>_CORE_API` selects the documentation
level for the declarations and definitions that follow. The banner remains a separate comment.

Replace the bracketed owner and use the same group identity in its owned documentation. `@{` opens
membership; a later `@}` closes it. These markers organize Doxygen output; C linkage and module visibility
still come from declarations and the architecture. Do not merge this block into an include or function comment.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@addtogroup` | Required | Fill the module/application owner; preserve the indicated level suffix. |
| `@{` | Required | Open this group and keep its matching closing block before the next level or file ending. |

### 3.7. Public / Defines

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *                        P U B L I C - D E F I N E S
 *         Constants forming part of the supported public contract.
 * ========================================================================== */

/** ============================================================================
 *  @def        <MODULE_NAME>_API_VERSION
 *
 *  @brief      <Describe the source interface version identifier.>
 *  @details    <Specify version checks and incompatible change policy.>
 *
 *  @warning    <Distinguish source compatibility from binary compatibility.>
 * ========================================================================== */
  #define MODULE_API_VERSION ((unsigned int)(1U))

/** ============================================================================
 *  @def        <MODULE_NAME>_DEFAULT_TIMEOUT_MS
 *
 *  @brief      <Describe the default timeout exposed to consumers.>
 *  @details    <Specify the unit, range, and meaning of special values.>
 *
 *  @note       <Explain how callers override the configured default.>
 * ========================================================================== */
  #define MODULE_DEFAULT_TIMEOUT_MS ((unsigned int)(100U))
```

The banner introduces object-like macros, not function-like macros or allocated objects. Every shown macro
has its own complete block. Match `@def` to the actual name, explain the unit and value rationale, and preserve
the typed constant spelling required by the C standard. Source-local definitions are PRIVATE, same-module
shared definitions INTERNAL, and published constants PUBLIC. A cast-bearing macro is not automatically valid
inside a preprocessor `#if` expression.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@def` | Required in this displayed pattern | Replace the bracketed module prefix and match the macro name and argument spelling exactly. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@warning` | Conditional on a hazard | Explain a concrete hazard or restriction and its consequence; do not use a generic warning as a substitute for a contract. |
| `@note` | Optional | Add a specific scope, configuration, or lifetime clarification that belongs to this entity. |

### 3.8. Public / Macros

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *                         P U B L I C - M A C R O S
 *      Function-like macros belonging to the supported public contract.
 * ========================================================================== */

/** ============================================================================
 *  @def        <MODULE_NAME>_API_STRINGIFY(token_)
 *
 *  @brief      <Describe the public preprocessing operation.>
 *  @details    <Explain why preprocessing is required instead of a function.>
 *
 *  @param[in]  token_ <Describe accepted tokens and expansion behavior.>
 *
 *  @return     <Describe the resulting string literal.>
 *
 *  @warning    <Specify direct stringification and argument constraints.>
 * ========================================================================== */
  #define MODULE_API_STRINGIFY(token_) #token_
```

The banner introduces function-like macros. Keep the documentation for preprocessing behavior and every
argument. A stringification macro and a statement macro have different contracts: explain expansion for the
former and lvalues, evaluation counts, aliasing, and side effects for the latter. The statement scaffold retains
`do`, braces, continuations, `while (0)`, and `/* ... */`; it is not a working implementation. A macro requires
justification under [CSTYLE-042/044](c-code-standard.md#cstyle-042).

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@def` | Required in this displayed pattern | Replace the bracketed module prefix and match the macro name and argument spelling exactly. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@param[in] token_` | Required for this parameter | Input: meaning, range, unit, and readable lifetime; do not imply pointer retention. The name must match the declaration. |
| `@return` | Conditional on a result | Describe the result convention and domain. Omit for void; do not use only “Integer” as its meaning. |
| `@warning` | Conditional on a hazard | Explain a concrete hazard or restriction and its consequence; do not use a generic warning as a substitute for a contract. |

### 3.9. Public / Enums

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *                         P U B L I C - E N U M S
 *              Closed sets of values accepted by the public API.
 * ========================================================================== */

/** ============================================================================
 *  @enum       <ModuleName>Mode
 *
 *  @brief      <Describe the operation modes available to consumers.>
 *  @details    <Specify supported values and validation of external integers.>
 *
 *  @par Values
 *    @li @b MODULE_MODE_BASIC
 *        <Describe the basic mode and its constraints.>
 *    @li @b MODULE_MODE_EXTENDED
 *        <Describe the extended mode and its constraints.>
 *
 *  @par Compatibility
 *              <Specify enum ABI assumptions and the policy for new values.>
 * ========================================================================== */
typedef enum ModuleMode
{
	MODULE_MODE_BASIC    = ((unsigned int)(0u)),
	MODULE_MODE_EXTENDED = ((unsigned int)(1u)),

	/*< Enum max value >*/
	MODULE_MODE_MAX = ((unsigned int)(2u)),
} module_mode_t; /**< <Type alias.> */
```

Preserve the full enum banner, the type contract, the Values list, the declaration, and its alias. Each
`@li @b` names an actual enumerator. Explicit values and the casts shown illustrate this project's source
convention; they do not fix the underlying enum size. Document the count sentinel when present and keep its
name distinct from capacity macros. Remove a sentinel that has no count/indexing purpose.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@enum` | Required in this displayed pattern | Name the enum tag, including the suffix shown, rather than confusing it with its typedef alias. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@par Values` | Required for the shown enum pattern | Keep the full @li @b list. Explain the meaning and transitions of each named enumerator. |
| `@li @b MODULE_MODE_BASIC` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@li @b MODULE_MODE_EXTENDED` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@par Compatibility` | Conditional on a promise | Specify language and ABI profiles and evolution assumptions without claiming enum width or layout portability. |
| `Enum max value / *_MAX` | Conditional | This names a count only for a zero-based contiguous enum that needs one. It is not a valid runtime state or an ABI-width declaration. |

### 3.10. Public / Opaque / Types

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *                     P U B L I C - O P A Q U E - T Y P E S
 *        Incomplete object types whose representation stays private.
 * ========================================================================== */

/** ============================================================================
 *  @typedef    <module_name>_t
 *
 *  @brief      <Describe the module-owned object represented by this type.>
 *  @details    <Describe object identity and the supported lifecycle.>
 *
 *  @par Ownership
 *              <Specify who creates, borrows, and destroys the object.>
 *  @par Representation
 *              <Identify the owning implementation of the complete type.>
 *  @par Lifetime
 *              <Specify validity of handles and invalidation of borrowed data.>
 *
 *  @see        <create_function>
 *  @see        <destroy_function>
 * ========================================================================== */
typedef struct Module module_t;
```

The banner contains forward declarations only. The struct tag identifies the incomplete type; the alias
provides the module-owned spelling. Explain object identity, ownership, and lifetime without listing hidden
fields or promising `sizeof`. Complete the type once at its owning implementation scope. An opaque cursor used
only by the owning module can be declared internally without becoming a public handle.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@typedef` | Required in this displayed pattern | Name the alias or callback typedef exactly; preserve the project lowercase alias convention. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@par Ownership` | Optional when applicable | State allocation, borrowing, transfer, retention, allocator pairing, and cleanup responsibilities. |
| `@par Representation` | Conditional on a representation boundary | Identify where the complete type is owned and which layout decisions remain private. |
| `@par Lifetime` | Conditional; required for handles/borrows | Specify creation, destruction, alias validity, and invalidation events. |
| `@see` | Optional | Replace each target with an existing related operation, type, or document anchor. |

### 3.11. Public / Typedefs

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *                       P U B L I C - T Y P E D E F S
 *  Semantic aliases and callback contracts exposed to supported consumers.
 * ========================================================================== */

/** ============================================================================
 *  @typedef    <module_name>_request_id_t
 *
 *  @brief      <Describe the public request identifier.>
 *  @details    <Specify its domain, lifetime, and reserved values.>
 * ========================================================================== */
typedef uint32_t module_request_id_t;

/** ============================================================================
 *  @typedef    <module_name>_notify_fn_t
 *
 *  @brief      <Describe the notification expected from a callback provider.>
 *  @details    <Specify invocation order and propagation of callback errors.>
 *
 *  @param[in]     request_id <Specify the request identity and validity.>
 *  @param[in,out] context    <Specify provider state and nullability.>
 *
 *  @return     <Specify the status convention and error domain.>
 *          @retval     <success_code> <Describe successful notification.>
 *          @retval     <error_code> <Describe each failure and its
 *                      propagation.>
 *
 *  @pre        <Specify binding, initialization, and context validity.>
 *  @post       <Specify effects on success and failure.>
 *
 *  @par Ownership
 *              <Specify borrowed state, retention, and context lifetime.>
 *  @par Reentrancy
 *              <Specify whether the callback may re-enter the consumer.>
 *  @par Thread Safety
 *              <Specify calling threads and synchronization requirements.>
 *  @par Blocking
 *              <Specify permitted waits and execution contexts.>
 *  @par Side Effects
 *              <List allowed mutations and externally visible effects.>
 *  @par Complexity
 *              <Specify time and storage bounds imposed by the consumer.>
 *
 *  @see        <registration_function>
 *  @showrefby
 * ========================================================================== */
typedef int (*module_notify_fn_t)(const module_request_id_t request_id,
                                  void *const               context);
```

The banner covers aliases and callback signatures. Each alias explains a semantic domain; each callback
has the full callable contract shown, including argument directions, outcomes, state guarantees, ownership,
reentrancy, thread safety, blocking, effects, and cost. A void context pointer is not permission to expose a
provider's layout. Shared peer ports follow [CMOD-013](c-module-architecture.md#cmod-013); this section is not an
implicit dependency on another module.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@typedef` | Required in this displayed pattern | Name the alias or callback typedef exactly; preserve the project lowercase alias convention. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@param[in] request_id` | Required for this parameter | Input: meaning, range, unit, and readable lifetime; do not imply pointer retention. The name must match the declaration. |
| `@param[in,out] context` | Required for this parameter | Input/output: accepted initial state, mutations, ownership, and state after failure. The name must match the declaration. |
| `@return` | Conditional on a result | Describe the result convention and domain. Omit for void; do not use only “Integer” as its meaning. |
| `@retval` | Conditional on distinct outcomes | Replace the status placeholder with an actual result and explain its condition. Repeat for each distinct contractual outcome. |
| `@pre` | Conditional on caller obligations | Specify valid storage, bounds, aliasing, initialization, lock state, and binding requirements relevant to this operation. |
| `@post` | Conditional on guarantees | Specify output and state on success and failure, including partial work and unchanged state where guaranteed. |
| `@par Ownership` | Optional when applicable | State allocation, borrowing, transfer, retention, allocator pairing, and cleanup responsibilities. |
| `@par Reentrancy` | Optional when applicable | State whether entry can recur before an earlier call finishes, including through a callback. |
| `@par Thread Safety` | Optional when applicable | Specify permitted callers, confinement, locks, and synchronization ownership. |
| `@par Blocking` | Optional when applicable | State waits, timeouts, allowed execution contexts, and whether callback behavior affects the bound. |
| `@par Side Effects` | Optional when applicable | List mutation, allocation, callbacks, I/O, and external changes, or explicitly state their absence. |
| `@par Complexity` | Optional when applicable | Define time/storage costs and their variables, and identify the assumptions behind the claimed bound. |
| `@see` | Optional | Replace each target with an existing related operation, type, or document anchor. |
| `@showrefby` | Optional | Request the generated Referenced by view; it is not proof that all indirect callers have been found. |

### 3.12. Public / Functions / Prototypes

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *           P U B L I C - F U N C T I O N S - P R O T O T Y P E S
 *            Declarations forming the supported public interface.
 * ========================================================================== */

/** ============================================================================
 *  @brief      <Describe creation of a new module object.>
 *  @details    <Describe configuration validation and resource acquisition.>
 *
 *  @param[in]  timeout_ms <Describe timeout bounds and special values.>
 *  @param[in]  mode       <Describe accepted operation modes.>
 *  @param[out] instance   <Describe ownership and output state on failure.>
 *
 *  @return     <Specify zero success and the negative errno-style domain.>
 *          @retval     <success_code> <Describe the created object's initial
 *                      state.>
 *          @retval     <error_code> <Describe validation and allocation
 *                      failures.>
 *
 *  @pre        <Specify storage validity and output aliasing constraints.>
 *  @post       <Specify ownership on success and cleanup on failure.>
 *
 *  @par Ownership
 *              <Identify the allocator family and matching destroy operation.>
 *  @par Reentrancy
 *              <Specify whether callbacks may re-enter during creation.>
 *  @par Thread Safety
 *              <Specify synchronization and publication requirements.>
 *  @par Blocking
 *              <Specify allocation, waits, and permitted execution contexts.>
 *  @par Side Effects
 *              <List allocated resources and externally observable changes.>
 *  @par Complexity
 *              <Specify time and storage bounds for object creation.>
 *
 *  @see        <destroy_function>
 *  @showrefs
 *  @showrefby
 * ========================================================================== */
int MODULE_create(const unsigned int timeout_ms, const module_mode_t mode,
                  module_t **const instance);

/** ============================================================================
 *  @brief      <Describe destruction and release of an owned module object.>
 *  @details    <Specify quiescence, teardown order, and outstanding borrows.>
 *
 *  @param[in,out] instance <Describe the handle before and after destruction.>
 *
 *  @return     <Specify zero success and the negative errno-style domain.>
 *          @retval     <success_code> <Describe resource release and handle
 *                      clearing.>
 *          @retval     <error_code> <Describe failures and the remaining
 *                      ownership.>
 *
 *  @pre        <Specify creation provenance, nullability, and quiescence.>
 *  @post       <Specify lifetime termination and handle state on each outcome.>
 *
 *  @par Ownership
 *              <Specify matching deallocation and invalidation of all aliases.>
 *  @par Reentrancy
 *              <Specify re-entry restrictions during resource release.>
 *  @par Thread Safety
 *              <Specify exclusion of concurrent users and callbacks.>
 *  @par Blocking
 *              <Specify waits and permitted teardown contexts.>
 *  @par Side Effects
 *              <List released resources and externally observable changes.>
 *  @par Complexity
 *              <Specify time and storage bounds for object destruction.>
 *
 *  @see        <create_function>
 *  @showrefs
 *  @showrefby
 * ========================================================================== */
int MODULE_destroy(module_t **const instance);

/** ============================================================================
 *  @brief      <Describe the observable operation provided to the caller.>
 *  @details    <Describe behavior, boundaries, and design choices.>
 *
 *  @param[in]     input           <Specify range and unit.>
 *  @param[out]    output          <Describe storage and nullability.>
 *
 *  @return     <Specify zero success and the negative errno-style domain.>
 *          @retval     <success_code> <Describe the successful outcome.>
 *          @retval     <error_code> <Describe each failure condition.>
 *
 *  @pre        <Specify initialization, validity, and aliasing rules.>
 *  @post       <Describe outputs and state on success and failure.>
 *
 *  @par Visibility
 *              <Identify supported consumers and the export policy.>
 *  @par Ownership
 *              <Specify borrowing, transfer, retention, and cleanup duties.>
 *  @par Reentrancy
 *              <Specify whether recursive or callback-driven entry is allowed.>
 *  @par Thread Safety
 *              <Specify concurrency and synchronization requirements.>
 *  @par Blocking
 *              <Specify waits, timeouts, and allowed execution contexts.>
 *  @par Side Effects
 *              <List state changes, callbacks, allocation, and external I/O.>
 *  @par Complexity
 *              <Specify time and space bounds and the variables involved.>
 *
 *  @see        <related_symbol>
 *  @showrefs
 *  @showrefby
 * ========================================================================== */
int MODULE_process(const unsigned int input, unsigned int *const output);
```

Preserve the entire prototypes banner and every declaration. Private helpers use `static`; internal and
public prototypes use their respective naming conventions without an explicit `extern` storage class. Private
prototypes can be bare when the complete block appears at the definition below. Header prototypes carry the
full contract because their consumers must not inspect implementation bodies to learn the interface.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@param[in] timeout_ms` | Required for this parameter | Input: meaning, range, unit, and readable lifetime; do not imply pointer retention. The name must match the declaration. |
| `@param[in] mode` | Required for this parameter | Input: meaning, range, unit, and readable lifetime; do not imply pointer retention. The name must match the declaration. |
| `@param[out] instance` | Required for this parameter | Output: writable storage, extent, nullability, and success/failure contents. The name must match the declaration. |
| `@return` | Conditional on a result | Describe the result convention and domain. Omit for void; do not use only “Integer” as its meaning. |
| `@retval` | Conditional on distinct outcomes | Replace the status placeholder with an actual result and explain its condition. Repeat for each distinct contractual outcome. |
| `@pre` | Conditional on caller obligations | Specify valid storage, bounds, aliasing, initialization, lock state, and binding requirements relevant to this operation. |
| `@post` | Conditional on guarantees | Specify output and state on success and failure, including partial work and unchanged state where guaranteed. |
| `@par Ownership` | Optional when applicable | State allocation, borrowing, transfer, retention, allocator pairing, and cleanup responsibilities. |
| `@par Reentrancy` | Optional when applicable | State whether entry can recur before an earlier call finishes, including through a callback. |
| `@par Thread Safety` | Optional when applicable | Specify permitted callers, confinement, locks, and synchronization ownership. |
| `@par Blocking` | Optional when applicable | State waits, timeouts, allowed execution contexts, and whether callback behavior affects the bound. |
| `@par Side Effects` | Optional when applicable | List mutation, allocation, callbacks, I/O, and external changes, or explicitly state their absence. |
| `@par Complexity` | Optional when applicable | Define time/storage costs and their variables, and identify the assumptions behind the claimed bound. |
| `@see` | Optional | Replace each target with an existing related operation, type, or document anchor. |
| `@showrefs` | Optional | Request the generated References view. Its accuracy depends on source analysis and configuration. |
| `@showrefby` | Optional | Request the generated Referenced by view; it is not proof that all indirect callers have been found. |
| `@param[in,out] instance` | Required for this parameter | Input/output: accepted initial state, mutations, ownership, and state after failure. The name must match the declaration. |
| `@param[in] input` | Required for this parameter | Input: meaning, range, unit, and readable lifetime; do not imply pointer retention. The name must match the declaration. |
| `@param[out] output` | Required for this parameter | Output: writable storage, extent, nullability, and success/failure contents. The name must match the declaration. |
| `@par Visibility` | Required for a header; conditional for an entity | Identify permitted consumers and symbol/export scope. Names and comments do not enforce linker visibility. |

**Categories omitted by rule:** there are no constants/variables that allocate storage, function-definition
sections, or application entry point. Complete structure and union layouts remain outside this public header.

### 3.13. Close the public interface group

```c
/** @} */
```

**Required for the preceding opening.** End `<MODULE_NAME>_CORE_API` after its last entity and before opening
another level or closing the file. This standalone block is not part of the preceding function contract.
Keep a blank line on each side so the boundary remains visible.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@}` | Required | Close exactly the group opened for this region; do not cross or leave unmatched group boundaries. |

### 3.14. Close C++ compatibility

```c
  /*< C++ Compatibility >*/
  #ifdef __cplusplus
}
  #endif
```

**Required when this header supports C++ inclusion.** Preserve the exact marker and `__cplusplus`
conditional. Each compatible header owns both halves of its linkage block under
[CMOD-019](c-module-architecture.md#cmod-019). The guarded `extern "C"` opening is the sole permitted
project-authored `extern` construct under [CMOD-017](c-module-architecture.md#cmod-017).

Close the visibility group first, then this linkage block, and finally the include guard.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `/*< C++ Compatibility >*/` | Required | Keep the marker verbatim on both halves. |
| `#ifdef __cplusplus` / `#endif` | Required | Condition the linkage syntax, not the C declarations. |
| `}` | Required for C++ | Match the opening and closing braces across this header only. |

### 3.15. Close the include guard

```c
#endif /* LMA_MODULE_PUBLIC_H */
```

**Required.** Close the guard after the group and C++ compatibility blocks. Match its opening name.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `#endif /* ... */` | Required | Preserve the exact opening guard identifier in the closing comment. |

### 3.16. End of file

```c
/* EOF */
```

**Required.** Place the literal marker after all group and preprocessor closures. Keep one blank line
before and one after it in the physical file; the Markdown fence does not display the final empty line.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `/* EOF */` | Required | Preserve the marker and the surrounding blank lines. |

---

<a id="main-c"></a>

## 4. Construct `main.c`

This chapter appends all application-private categories, including those a small application may not need.
The complete construction includes defines, macros, enums, structures/unions, aliases/callbacks, constants,
justified state, helper prototypes, helper definitions, and the hosted entry point. All application-owned
entities remain private; only `main` has the externally required entry linkage. The include section may name any
needed application dependency, including module internal headers.

### 4.1. License

**Required.** These are the first lines of this file.

<!-- REUSE-IgnoreStart -->

```c
/*
 * SPDX-FileCopyrightText: <year> <name> <e-mail>
 * SPDX-License-Identifier: <license>
 */
```

<!-- REUSE-IgnoreEnd -->

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `SPDX-FileCopyrightText` | Required | Fill the actual year, rights-holder name, and e-mail. Preserve imported provenance where applicable. |
| `SPDX-License-Identifier` | Required | Fill the applicable SPDX license expression; this is not a prose license summary. |

### 4.2. File documentation

**Required block.** All file fields are shown; complete or remove optional fields according to the table below.

```c
/** ============================================================================
 *  @file       <main.c>
 *  @ingroup    <APPLICATION_NAME>
 *
 *  @brief      <Describe the application entry point and composition scope.>
 *  @details    <Describe supported execution modes and runtime assumptions.>
 *
 *  @par Direct Module Dependencies
 *    @li @ref <MODULE_NAME>
 *        <Identify public, internal, platform, and third-party dependencies.>
 *
 *  @par Used By
 *    @li @ref <host_environment>
 *        <Describe invocation, command-line syntax, and deployment context.>
 *
 *  @par Provided Interfaces
 *    @li @ref <entry_point>
 *        <Describe process arguments, diagnostics, and exit status.>
 *
 *  @par Consumed Runtime Ports
 *    @li @ref <provider_port_t>
 *        <Identify provider selection, context ownership, and binding order.>
 *
 *  @par Visibility
 *              <Describe private helpers, types, and state owned by this file.>
 *  @par Include Scope
 *              <List direct dependencies and application-private search paths.>
 *  @par Lifecycle
 *              <Specify startup, partial failure, quiescence, and shutdown.>
 *
 *  @version    <vX.X.XX>
 *  @date       <DD.MM.YYYY>
 *  @author     <name> <e-mail>
 * ========================================================================== */
```

Keep the blank lines between the summary, detail, relationship lists, and revision fields. A file reference
identifies an actual interface; a group reference identifies its documentation owner. Each following list
entry has a target line and an explanatory line. Do not leave an unresolved `<...>` target in published output.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@file` | Required | Use the real file name and extension. For this chapter use the file kind named in its heading. |
| `@ingroup` | Required | Name the owning module/application group. It must exist in the Doxygen input. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@par Direct Module Dependencies` | Conditional | List actual architectural/direct dependencies, not all headers reachable transitively. Explain the role of each `@ref` target. |
| `@li @ref <MODULE_NAME>` | Conditional on the containing list | Fill a resolvable reference target and explain the relationship on the following line. |
| `@par Used By` | Conditional | Identify approved consumers or owning source files and explain their allowed use. |
| `@li @ref <host_environment>` | Conditional on the containing list | Fill a resolvable reference target and explain the relationship on the following line. |
| `@par Provided Interfaces` | Conditional | List the public/internal interfaces declared or implemented by this file. |
| `@li @ref <entry_point>` | Conditional on the containing list | Fill a resolvable reference target and explain the relationship on the following line. |
| `@par Consumed Runtime Ports` | Conditional | Describe injected services, callback contracts, binding, and provider/context lifetime. |
| `@li @ref <provider_port_t>` | Conditional on the containing list | Fill a resolvable reference target and explain the relationship on the following line. |
| `@par Visibility` | Required for a header; conditional for an entity | Identify permitted consumers and symbol/export scope. Names and comments do not enforce linker visibility. |
| `@par Include Scope` | Conditional; application composition | Describe selected direct dependencies and application-private include paths; this is not permission inherited by peers. |
| `@par Lifecycle` | Conditional on owned state/resources | Document initialization, reset, shutdown, and ownership across those transitions. |
| `@version` | Optional/profile-dependent | Record the maintained file/interface version, such as the specified vX.X.XX form; do not invent release metadata. |
| `@date` | Optional/profile-dependent | Fill the relevant maintained date in DD.MM.YYYY form; define what event that date represents. |
| `@author` | Optional/profile-dependent | Fill attribution with the actual name and e-mail. This does not replace provenance or review ownership. |

### 4.3. Private / Includes

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *                     P R I V A T E - I N C L U D E S
 * ========================================================================== */

/* Standard Library Header Files */
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

/* Third-Party Header Files */

/* Module Public Header Files */
#include "public.h"

/* Module Internal Header Files */
#include "internal.h"

/* External Module Header Files */
```

Keep the entire includes banner and the five category labels shown. Select actual dependencies for the
file. In a module source, the public header comes first; standard, third-party, internal, and external module
headers follow in the illustrated categories. The module architecture still controls which external dependencies
are allowed. In `main.c`, the same private section can contain any needed application dependency. Empty labels
are template slots; omit a category from a completed file if it has no entries.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| Include categories | Conditional | Keep only categories with direct dependencies in the completed source. |
| Module public header first | Required for module implementations | Follow CMOD-016; main.c has the composition exception in CMOD-021. |

### 4.4. Open the private implementation group

```c
/**
 * @addtogroup <APPLICATION_NAME>_CORE_IMPL
 * @{
 */
```

**Required for this populated region.** This is a separate grouping block, placed after the includes or
preceding group's closing block and before the next section banner. `<APPLICATION_NAME>_CORE_IMPL` selects the
documentation
level for the declarations and definitions that follow. The banner remains a separate comment.

Replace the bracketed owner and use the same group identity in its owned documentation. `@{` opens
membership; a later `@}` closes it. These markers organize Doxygen output; C linkage and module visibility
still come from declarations and the architecture. Do not merge this block into an include or function comment.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@addtogroup` | Required | Fill the module/application owner; preserve the indicated level suffix. |
| `@{` | Required | Open this group and keep its matching closing block before the next level or file ending. |

### 4.5. Private / Defines

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *                       P R I V A T E - D E F I N E S
 *     Object-like macros used as private constants or local configuration.
 * ========================================================================== */

/** ============================================================================
 *  @def         <APPLICATION_NAME>_TIMEOUT_MS
 *
 *  @brief      <Describe the constant's purpose.>
 *  @details    <Specify its unit, type, permitted range, and value rationale.>
 *
 *  @note       <Describe configuration constraints and visibility.>
 *
 *  @see        <related_symbol>
 * ========================================================================== */
#define APPLICATION_TIMEOUT_MS ((uint32_t)(100U))

/** ============================================================================
 *  @def         <APPLICATION_NAME>_MAX_ITEMS
 *
 *  @brief      <Describe the capacity represented by this constant.>
 *  @details    <Explain how the limit is derived and where it applies.>
 *
 *  @warning    <Describe the resource and compatibility impact of changes.>
 * ========================================================================== */
#define APPLICATION_MAX_ITEMS ((size_t)(16U))
```

The banner introduces object-like macros, not function-like macros or allocated objects. Every shown macro
has its own complete block. Match `@def` to the actual name, explain the unit and value rationale, and preserve
the typed constant spelling required by the C standard. Source-local definitions are PRIVATE, same-module
shared definitions INTERNAL, and published constants PUBLIC. A cast-bearing macro is not automatically valid
inside a preprocessor `#if` expression.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@def` | Required in this displayed pattern | Replace the bracketed module prefix and match the macro name and argument spelling exactly. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@note` | Optional | Add a specific scope, configuration, or lifetime clarification that belongs to this entity. |
| `@see` | Optional | Replace each target with an existing related operation, type, or document anchor. |
| `@warning` | Conditional on a hazard | Explain a concrete hazard or restriction and its consequence; do not use a generic warning as a substitute for a contract. |

### 4.6. Private / Macros

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *                        P R I V A T E - M A C R O S
 *         Function-like macros, when justified by the coding standard.
 * ========================================================================== */

/** ============================================================================
 *  @def        <APPLICATION_NAME>_STRINGIFY(token_)
 *
 *  @brief      <Describe the preprocessing operation.>
 *  @details    <Explain why preprocessing is required instead of a function.>
 *
 *  @param[in]  token_ <Describe accepted tokens and expansion behavior.>
 *
 *  @return     <Describe the resulting string literal.>
 *
 *  @warning    <Document argument expansion and evaluation constraints.>
 * ========================================================================== */
#define APPLICATION_STRINGIFY(token_) #token_

/** ============================================================================
 *  @def         <APPLICATION_NAME>_UPDATE(in_, out_, in_out_)
 *
 *  @brief      <Describe the statement macro's responsibility.>
 *  @details    <Justify a macro instead of a typed static inline function.>
 *
 *  @param[in]     in_     <Describe the input type, range, and unit.>
 *  @param[out]    out_    <Describe the writable destination and failure
 *              state.>
 *  @param[in,out] in_out_ <Describe the initial and resulting state.>
 *
 *  @pre        <Specify valid lvalues, aliasing, and arithmetic constraints.>
 *  @post       <Describe output and state guarantees.>
 *
 *  @warning    <Specify evaluation counts and forbidden side effects.>
 * ========================================================================== */
#define APPLICATION_UPDATE(in_, out_, in_out_) \
	do                                     \
	{                                      \
		/* ... */                      \
	}                                      \
	while (0)
```

The banner introduces function-like macros. Keep the documentation for preprocessing behavior and every
argument. A stringification macro and a statement macro have different contracts: explain expansion for the
former and lvalues, evaluation counts, aliasing, and side effects for the latter. The statement scaffold retains
`do`, braces, continuations, `while (0)`, and `/* ... */`; it is not a working implementation. A macro requires
justification under [CSTYLE-042/044](c-code-standard.md#cstyle-042).

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@def` | Required in this displayed pattern | Replace the bracketed module prefix and match the macro name and argument spelling exactly. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@param[in] token_` | Required for this parameter | Input: meaning, range, unit, and readable lifetime; do not imply pointer retention. The name must match the declaration. |
| `@return` | Conditional on a result | Describe the result convention and domain. Omit for void; do not use only “Integer” as its meaning. |
| `@warning` | Conditional on a hazard | Explain a concrete hazard or restriction and its consequence; do not use a generic warning as a substitute for a contract. |
| `@param[in] in_` | Required for this parameter | Input: meaning, range, unit, and readable lifetime; do not imply pointer retention. The name must match the declaration. |
| `@param[out] out_` | Required for this parameter | Output: writable storage, extent, nullability, and success/failure contents. The name must match the declaration. |
| `@param[in,out] in_out_` | Required for this parameter | Input/output: accepted initial state, mutations, ownership, and state after failure. The name must match the declaration. |
| `@pre` | Conditional on caller obligations | Specify valid storage, bounds, aliasing, initialization, lock state, and binding requirements relevant to this operation. |
| `@post` | Conditional on guarantees | Specify output and state on success and failure, including partial work and unchanged state where guaranteed. |

### 4.7. Private / Enums

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *                         P R I V A T E - E N U M S
 *              Enumerations used only by this translation unit.
 * ========================================================================== */

/** ============================================================================
 *  @enum       <ApplicationName>State
 *
 *  @brief      <Describe the states represented by this enumeration.>
 *  @details    <Specify valid transitions and value validation rules.>
 *
 *  @par Values
 *    @li @b APPLICATION_STATE_IDLE
 *        <Describe the meaning and permitted transitions of this state.>
 *    @li @b APPLICATION_STATE_RUNNING
 *        <Describe the meaning and permitted transitions of this state.>
 *    @li @b APPLICATION_STATE_ERROR
 *        <Describe the meaning and recovery conditions of this state.>
 * ========================================================================== */
typedef enum ApplicationState
{
	APPLICATION_STATE_IDLE    = ((uint8_t)(0u)),
	APPLICATION_STATE_RUNNING = ((uint8_t)(1u)),
	APPLICATION_STATE_ERROR   = ((uint8_t)(2u)),

	/*< Enum max value >*/
	APPLICATION_STATE_MAX = ((uint8_t)(3u))
} application_state_t; /**< <Type alias.> */
```

Preserve the full enum banner, the type contract, the Values list, the declaration, and its alias. Each
`@li @b` names an actual enumerator. Explicit values and the casts shown illustrate this project's source
convention; they do not fix the underlying enum size. Document the count sentinel when present and keep its
name distinct from capacity macros. Remove a sentinel that has no count/indexing purpose.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@enum` | Required in this displayed pattern | Name the enum tag, including the suffix shown, rather than confusing it with its typedef alias. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@par Values` | Required for the shown enum pattern | Keep the full @li @b list. Explain the meaning and transitions of each named enumerator. |
| `@li @b APPLICATION_STATE_IDLE` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@li @b APPLICATION_STATE_RUNNING` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@li @b APPLICATION_STATE_ERROR` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `Enum max value / *_MAX` | Conditional | This names a count only for a zero-based contiguous enum that needs one. It is not a valid runtime state or an ABI-width declaration. |

### 4.8. Private / Structs / Definitions

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *           P R I V A T E - S T R U C T S - D E F I N I T I O N S
 *     Application-owned configuration private to this translation unit.
 * ========================================================================== */

/** ============================================================================
 *  @struct     <ApplicationName>Options
 *
 *  @brief      <Describe the validated application configuration.>
 *  @details    <Specify defaults, argument mapping, and validation rules.>
 *
 *  @par Fields
 *    @li @b input_value
 *        <Describe the value supplied to the module and its accepted range.>
 *
 *  @invariant  <Specify conditions established before invoking module APIs.>
 * ========================================================================== */
typedef struct ApplicationOptions
{
	uint32_t input_value; /**< <Value, unit, and accepted range.> */
} application_options_t; /**< <Type alias.> */

/** ============================================================================
 *  @struct    <ApplicationName>Context
 *
 *  @brief      <Describe the state represented by this structure.>
 *  @details    <Describe ownership, lifetime, initialization, and layout
 *              scope.>
 *
 *  @par Fields
 *    @li @b state
 *        <Describe valid states and the initialization state.>
 *    @li @b operation_count
 *        <Describe what is counted and the overflow policy.>
 *    @li @b last_value
 *        <Describe the value's meaning and when it is valid.>
 *
 *  @invariant  <State the relationships that must hold between fields.>
 * ========================================================================== */
typedef struct ApplicationContext
{
	application_state_t state; /**< <State invariant.> */

	uint32_t operation_count; /**< <Count and bounds.> */
	uint32_t last_value; /**< <Value and validity.> */
} application_context_t; /**< <Type alias.> */

/** ============================================================================
 *  @union       <ApplicationName>Value
 *
 *  @brief      <Describe the mutually exclusive value representations.>
 *  @details    <Identify the external tag or contract selecting the member.>
 *
 *  @par Fields
 *    @li @b u32
 *        <Describe when the unsigned member is active.>
 *    @li @b s32
 *        <Describe when the signed member is active.>
 *
 *  @invariant  <Specify how writes and reads preserve the active member.>
 * ========================================================================== */
typedef union ApplicationValue
{
	uint32_t u32; /**< <Unsigned value range and unit.> */
	int32_t  s32; /**< <Signed value range and unit.> */
} application_value_t; /**< <Type alias.> */
```

Keep the entire representation banner and every per-type block. `@struct` and `@union` identify tags;
`@par Fields` explains members and relationships; trailing `/**< ... */` comments remain beside the declarations.
A union's active-member rule is mandatory information. An internal complete type is shared by owning source
files; a private complete type is owned by one translation unit. Do not duplicate its definition in both.
There is no corresponding complete-structure section in `public.h`.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@struct` | Required in this displayed pattern | Name the struct tag whose complete representation follows. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@par Fields` | Required for the shown complete-type pattern | Keep the full @li @b list. Explain units, bounds, valid states, and relationships for each named member. |
| `@li @b input_value` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@invariant` | Conditional on representation/state constraints | State relationships maintained by all valid states or mutations. This is documentation, not an executable proof. |
| `@li @b state` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@li @b operation_count` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@li @b last_value` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@union` | Required in this displayed pattern | Name the union tag and retain the active-member contract beneath it. |
| `@li @b u32` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `@li @b s32` | Conditional on the containing list | Keep this exact member/enumerator name synchronized with the declaration and describe its meaning below it. |
| `/**< <...> */` | Required for the shown member pattern | Keep the trailing comment beside its field. Fill the short local meaning; the Fields list explains relationships and constraints. |

### 4.9. Private / Typedefs

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *                      P R I V A T E - T Y P E D E F S
 *       Other aliases and callback types private to this translation unit.
 * ========================================================================== */

/** ============================================================================
 *  @typedef     <ApplicationName>_index_t
 *
 *  @brief      <Describe the semantic purpose of this alias.>
 *  @details    <Specify units, bounds, and any reserved sentinel values.>
 * ========================================================================== */
typedef size_t application_index_t;

/** ============================================================================
 *  @typedef     <ApplicationName>_action_fn_t
 *
 *  @brief      <Describe the callback's responsibility.>
 *  @details    <Describe the behavior, boundaries, and relevant design
 *              choices.>
 *
 *  @param[in]     input   <Describe the accepted input, range, and unit.>
 *  @param[out]    output  <Describe storage, nullability, and failure state.>
 *  @param[in,out] context <Describe the context type, lifetime, and mutations.>
 *
 *  @return     <Specify the status convention and error domain.>
 *          @retval     <success_code> <Describe the successful outcome.>
 *          @retval     <error_code> <Describe the corresponding failure
 *                      condition.>
 *
 *  @pre        <Specify pointer validity, aliasing, and binding requirements.>
 *  @post       <Specify output and context guarantees on success and failure.>
 *
 *  @par Ownership
 *              <Specify borrowing, transfer, retention, and cleanup duties.>
 *  @par Reentrancy
 *              <Specify whether the callback may re-enter the owning module.>
 *  @par Thread Safety
 *              <Specify concurrency and synchronization requirements.>
 *  @par Blocking
 *              <Specify waits, timeouts, and allowed execution contexts.>
 *  @par Side Effects
 *              <List observable effects or explicitly state none.>
 *  @par Complexity
 *              <Specify time and space bounds and the variables involved.>
 *
 *  @see        <related_symbol>
 *  @showrefby
 * ========================================================================== */
typedef int (*application_action_fn_t)(const uint32_t  input,
                                       uint32_t *const output,
                                       void *const     context);
```

The banner covers aliases and callback signatures. Each alias explains a semantic domain; each callback
has the full callable contract shown, including argument directions, outcomes, state guarantees, ownership,
reentrancy, thread safety, blocking, effects, and cost. A void context pointer is not permission to expose a
provider's layout. Shared peer ports follow [CMOD-013](c-module-architecture.md#cmod-013); this section is not an
implicit dependency on another module.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@typedef` | Required in this displayed pattern | Name the alias or callback typedef exactly; preserve the project lowercase alias convention. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@param[in] input` | Required for this parameter | Input: meaning, range, unit, and readable lifetime; do not imply pointer retention. The name must match the declaration. |
| `@param[out] output` | Required for this parameter | Output: writable storage, extent, nullability, and success/failure contents. The name must match the declaration. |
| `@param[in,out] context` | Required for this parameter | Input/output: accepted initial state, mutations, ownership, and state after failure. The name must match the declaration. |
| `@return` | Conditional on a result | Describe the result convention and domain. Omit for void; do not use only “Integer” as its meaning. |
| `@retval` | Conditional on distinct outcomes | Replace the status placeholder with an actual result and explain its condition. Repeat for each distinct contractual outcome. |
| `@pre` | Conditional on caller obligations | Specify valid storage, bounds, aliasing, initialization, lock state, and binding requirements relevant to this operation. |
| `@post` | Conditional on guarantees | Specify output and state on success and failure, including partial work and unchanged state where guaranteed. |
| `@par Ownership` | Optional when applicable | State allocation, borrowing, transfer, retention, allocator pairing, and cleanup responsibilities. |
| `@par Reentrancy` | Optional when applicable | State whether entry can recur before an earlier call finishes, including through a callback. |
| `@par Thread Safety` | Optional when applicable | Specify permitted callers, confinement, locks, and synchronization ownership. |
| `@par Blocking` | Optional when applicable | State waits, timeouts, allowed execution contexts, and whether callback behavior affects the bound. |
| `@par Side Effects` | Optional when applicable | List mutation, allocation, callbacks, I/O, and external changes, or explicitly state their absence. |
| `@par Complexity` | Optional when applicable | Define time/storage costs and their variables, and identify the assumptions behind the claimed bound. |
| `@see` | Optional | Replace each target with an existing related operation, type, or document anchor. |
| `@showrefby` | Optional | Request the generated Referenced by view; it is not proof that all indirect callers have been found. |

### 4.10. Private / Constants

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *                     P R I V A T E - C O N S T A N T S
 *         File-scope constant objects with internal linkage.
 * ========================================================================== */

/** ============================================================================
 *  @var        g_default_value
 *
 *  @brief      <Describe the immutable object's purpose.>
 *  @details    <Specify its unit, valid range, and initialization rationale.>
 *
 *  @note       <Describe lifetime and representation constraints.>
 * ========================================================================== */
static const uint32_t g_default_value = UINT32_C(10);
```

This source-only banner introduces immutable storage objects. Preserve `static const`, the object name,
its typed initializer, and its complete `@var` block. Explain lifetime, value range, and intended use; do not
confuse a constant object with a preprocessor define. No counterpart belongs in the two header templates.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@var` | Required in this displayed pattern | Identify the source-local object. Its documentation must agree with mutability and storage duration. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@note` | Optional | Add a specific scope, configuration, or lifetime clarification that belongs to this entity. |

### 4.11. Private / Variables

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *                      P R I V A T E - V A R I A B L E S
 *       Justified file-scope state. Prefer explicit instance-owned state.
 * ========================================================================== */

/** ============================================================================
 *  @var        g_context
 *
 *  @brief      <Describe the mutable object's purpose.>
 *  @details    <Justify file-scope state instead of an explicit instance.>
 *
 *  @par Lifecycle
 *              <Specify initialization, ownership, reset, and teardown.>
 *  @par Synchronization
 *              <Identify the lock or access discipline for every mutation.>
 *
 *  @warning    <Describe concurrency restrictions and unsupported access.>
 * ========================================================================== */
static application_context_t g_context = {
	.state           = APPLICATION_STATE_IDLE,
	.operation_count = UINT32_C(0),
	.last_value      = UINT32_C(0),
};
```

This source-only banner introduces justified private mutable storage. Preserve the complete `@var` block,
lifecycle and synchronization fields, the `static` declaration, and designated initializer. The template does
not require global state in a real design. Instance-owned state remains preferred; document why this object
needs file scope and how every access preserves its invariants. Do not place such an object in a header.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@var` | Required in this displayed pattern | Identify the source-local object. Its documentation must agree with mutability and storage duration. |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@par Lifecycle` | Conditional on owned state/resources | Document initialization, reset, shutdown, and ownership across those transitions. |
| `@par Synchronization` | Conditional on mutable/shared state | Name the actual lock, confinement, publication, or access discipline for all affected fields. |
| `@warning` | Conditional on a hazard | Explain a concrete hazard or restriction and its consequence; do not use a generic warning as a substitute for a contract. |

### 4.12. Private / Functions / Prototypes

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *          P R I V A T E - F U N C T I O N S - P R O T O T Y P E S
 *                 Prototypes of static application helpers.
 * ========================================================================== */

static int application_parseArguments(const int argc, char *const argv[],
                                      application_options_t *const options);

static int application_run(const application_options_t *const options);
```

Preserve the entire prototypes banner and every declaration. Private helpers use `static`; internal and
public prototypes use their respective naming conventions without an explicit `extern` storage class. Private
prototypes can be bare when the complete block appears at the definition below. Header prototypes carry the
full contract because their consumers must not inspect implementation bodies to learn the interface.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

### 4.13. Private / Functions / Definitions

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *         P R I V A T E - F U N C T I O N S - D E F I N I T I O N S
 *                 Definitions of static application helpers.
 * ========================================================================== */

/** ============================================================================
 *  @brief      <Describe command-line parsing and configuration validation.>
 *  @details    <Describe behavior, boundaries, and design choices.>
 *
 *  @param[in]     argc            <Describe the argument count.>
 *  @param[in]     argv            <Describe syntax and encoding.>
 *  @param[out]    options         <Describe storage and failure state.>
 *
 *  @return     <Specify zero success and the negative errno-style domain.>
 *          @retval     <success_code> <Describe the successful outcome.>
 *          @retval     <error_code> <Describe each failure condition.>
 *
 *  @pre        <Specify initialization, validity, and aliasing rules.>
 *  @post       <Describe outputs and state on success and failure.>
 *
 *  @par Ownership
 *              <Specify borrowing, transfer, retention, and cleanup duties.>
 *  @par Reentrancy
 *              <Specify whether recursive or callback-driven entry is allowed.>
 *  @par Thread Safety
 *              <Specify concurrency and synchronization requirements.>
 *  @par Blocking
 *              <Specify waits, timeouts, and allowed execution contexts.>
 *  @par Side Effects
 *              <List state changes, callbacks, allocation, and external I/O.>
 *  @par Complexity
 *              <Specify time and space bounds and the variables involved.>
 *
 *  @see        <related_symbol>
 *  @showrefs
 *  @showrefby
 * ========================================================================== */
static int application_parseArguments(const int argc, char *const argv[],
                                      application_options_t *const options)
{
	/* ... */
}

/** ============================================================================
 *  @brief      <Describe application execution using validated options.>
 *  @details    <Describe behavior, boundaries, and design choices.>
 *
 *  @param[in]     options         <Describe validated configuration.>
 *
 *  @return     <Specify zero success and the negative errno-style domain.>
 *          @retval     <success_code> <Describe the successful outcome.>
 *          @retval     <error_code> <Describe each failure condition.>
 *
 *  @pre        <Specify initialization, validity, and aliasing rules.>
 *  @post       <Describe outputs and state on success and failure.>
 *
 *  @par Ownership
 *              <Specify borrowing, transfer, retention, and cleanup duties.>
 *  @par Reentrancy
 *              <Specify whether recursive or callback-driven entry is allowed.>
 *  @par Thread Safety
 *              <Specify concurrency and synchronization requirements.>
 *  @par Blocking
 *              <Specify waits, timeouts, and allowed execution contexts.>
 *  @par Side Effects
 *              <List state changes, callbacks, allocation, and external I/O.>
 *  @par Complexity
 *              <Specify time and space bounds and the variables involved.>
 *
 *  @see        <related_symbol>
 *  @showrefs
 *  @showrefby
 * ========================================================================== */
static int application_run(const application_options_t *const options)
{
	/* ... */
}
```

Preserve the entire definitions banner and a complete documentation block for every function, including
all six named operational sections shown. Do not substitute an ordinary one-line comment, a reference to another
pattern, or a shortened `@copydoc` block. Each body is only `/* ... */`. Private definitions are `static`;
internal and public definitions match the corresponding header declarations. When the contract appears at both
declaration and definition, maintain them together; the header remains the authoritative caller contract.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@param[in] argc` | Required for this parameter | Input: meaning, range, unit, and readable lifetime; do not imply pointer retention. The name must match the declaration. |
| `@param[in] argv` | Required for this parameter | Input: meaning, range, unit, and readable lifetime; do not imply pointer retention. The name must match the declaration. |
| `@param[out] options` | Required for this parameter | Output: writable storage, extent, nullability, and success/failure contents. The name must match the declaration. |
| `@return` | Conditional on a result | Describe the result convention and domain. Omit for void; do not use only “Integer” as its meaning. |
| `@retval` | Conditional on distinct outcomes | Replace the status placeholder with an actual result and explain its condition. Repeat for each distinct contractual outcome. |
| `@pre` | Conditional on caller obligations | Specify valid storage, bounds, aliasing, initialization, lock state, and binding requirements relevant to this operation. |
| `@post` | Conditional on guarantees | Specify output and state on success and failure, including partial work and unchanged state where guaranteed. |
| `@par Ownership` | Optional when applicable | State allocation, borrowing, transfer, retention, allocator pairing, and cleanup responsibilities. |
| `@par Reentrancy` | Optional when applicable | State whether entry can recur before an earlier call finishes, including through a callback. |
| `@par Thread Safety` | Optional when applicable | Specify permitted callers, confinement, locks, and synchronization ownership. |
| `@par Blocking` | Optional when applicable | State waits, timeouts, allowed execution contexts, and whether callback behavior affects the bound. |
| `@par Side Effects` | Optional when applicable | List mutation, allocation, callbacks, I/O, and external changes, or explicitly state their absence. |
| `@par Complexity` | Optional when applicable | Define time/storage costs and their variables, and identify the assumptions behind the claimed bound. |
| `@see` | Optional | Replace each target with an existing related operation, type, or document anchor. |
| `@showrefs` | Optional | Request the generated References view. Its accuracy depends on source analysis and configuration. |
| `@showrefby` | Optional | Request the generated Referenced by view; it is not proof that all indirect callers have been found. |
| `@param[in] options` | Required for this parameter | Input: meaning, range, unit, and readable lifetime; do not imply pointer retention. The name must match the declaration. |

### 4.14. Close the private implementation group

```c
/** @} */
```

**Required for the preceding opening.** End `<APPLICATION_NAME>_CORE_IMPL` after its last entity and before opening
another level or closing the file. This standalone block is not part of the preceding function contract.
Keep a blank line on each side so the boundary remains visible.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@}` | Required | Close exactly the group opened for this region; do not cross or leave unmatched group boundaries. |

### 4.15. Open the application entry point group

```c
/**
 * @addtogroup <APPLICATION_NAME>_CORE_ENTRY
 * @{
 */
```

**Required for this populated region.** This is a separate grouping block, placed after the includes or
preceding group's closing block and before the next section banner. `<APPLICATION_NAME>_CORE_ENTRY` selects
the documentation
level for the declarations and definitions that follow. The banner remains a separate comment.

Replace the bracketed owner and use the same group identity in its owned documentation. `@{` opens
membership; a later `@}` closes it. These markers organize Doxygen output; C linkage and module visibility
still come from declarations and the architecture. Do not merge this block into an include or function comment.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@addtogroup` | Required | Fill the module/application owner; preserve the indicated level suffix. |
| `@{` | Required | Open this group and keep its matching closing block before the next level or file ending. |

### 4.16. Application / Entry / Point

**Conditional section.** Include it when this file owns the category shown. Preserve its entire banner and the
full blocks for retained entities.

```c
/** ============================================================================
 *               A P P L I C A T I O N - E N T R Y - P O I N T
 *     Hosted C entry point; retain the name and signature required by C.
 * ========================================================================== */

/** ============================================================================
 *  @brief      <Describe application startup, execution, and termination.>
 *  @details    <Describe behavior, boundaries, and design choices.>
 *
 *  @param[in]     argc            <Describe the hosted argument count.>
 *  @param[in]     argv            <Describe borrowed argument strings.>
 *
 *  @return     <Specify process exit status and diagnostic conventions.>
 *          @retval     <success_code> <Describe the successful outcome.>
 *          @retval     <error_code> <Describe each failure condition.>
 *
 *  @pre        <Specify initialization, validity, and aliasing rules.>
 *  @post       <Describe outputs and state on success and failure.>
 *
 *  @par Ownership
 *              <Specify borrowing, transfer, retention, and cleanup duties.>
 *  @par Reentrancy
 *              <Specify whether recursive or callback-driven entry is allowed.>
 *  @par Thread Safety
 *              <Specify concurrency and synchronization requirements.>
 *  @par Blocking
 *              <Specify waits, timeouts, and allowed execution contexts.>
 *  @par Side Effects
 *              <List state changes, callbacks, allocation, and external I/O.>
 *  @par Complexity
 *              <Specify time and space bounds and the variables involved.>
 *  @par Startup
 *              <Specify configuration, instance creation, and port binding.>
 *  @par Failure Recovery
 *              <Specify cleanup of acquired resources after partial startup.>
 *  @par Shutdown
 *              <Specify quiescence and reverse dependency teardown order.>
 *  @par Exit Status
 *              <Map internal errors to EXIT_SUCCESS or EXIT_FAILURE.>
 *
 *  @see        <related_symbol>
 *  @showrefs
 *  @showrefby
 * ========================================================================== */
int main(int argc, char *argv[])
{
	/* ... */
}
```

This is the application's hosted entry point. Keep its full contract, parameters, outcomes, startup,
recovery, shutdown, and exit-status sections. The application-owned helpers and state above are private, while
`main` keeps the non-static signature required by C. The include permission of composition does not export its
own declarations or create an application public header.

The first three/four lines are the complete section banner: opening delimiter, spaced visibility/category
name, optional explanatory subtitle, and closing delimiter. The banner itself contains no fill-in identifier.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@brief` | Required | State the responsibility of this entity. Keep it distinct from the longer explanation. |
| `@details` | Conditional; shown in full | Explain scope, behavior, design constraints, or assumptions beyond the brief summary. |
| `@param[in] argc` | Required for this parameter | Input: meaning, range, unit, and readable lifetime; do not imply pointer retention. The name must match the declaration. |
| `@param[in] argv` | Required for this parameter | Input: meaning, range, unit, and readable lifetime; do not imply pointer retention. The name must match the declaration. |
| `@return` | Conditional on a result | Describe the result convention and domain. Omit for void; do not use only “Integer” as its meaning. |
| `@retval` | Conditional on distinct outcomes | Replace the status placeholder with an actual result and explain its condition. Repeat for each distinct contractual outcome. |
| `@pre` | Conditional on caller obligations | Specify valid storage, bounds, aliasing, initialization, lock state, and binding requirements relevant to this operation. |
| `@post` | Conditional on guarantees | Specify output and state on success and failure, including partial work and unchanged state where guaranteed. |
| `@par Ownership` | Optional when applicable | State allocation, borrowing, transfer, retention, allocator pairing, and cleanup responsibilities. |
| `@par Reentrancy` | Optional when applicable | State whether entry can recur before an earlier call finishes, including through a callback. |
| `@par Thread Safety` | Optional when applicable | Specify permitted callers, confinement, locks, and synchronization ownership. |
| `@par Blocking` | Optional when applicable | State waits, timeouts, allowed execution contexts, and whether callback behavior affects the bound. |
| `@par Side Effects` | Optional when applicable | List mutation, allocation, callbacks, I/O, and external changes, or explicitly state their absence. |
| `@par Complexity` | Optional when applicable | Define time/storage costs and their variables, and identify the assumptions behind the claimed bound. |
| `@par Startup` | Optional when applicable | Document configuration, instance creation, and callback binding in dependency order. |
| `@par Failure Recovery` | Optional when applicable | Describe cleanup of only the resources acquired, and what remains valid after failure. |
| `@par Shutdown` | Optional when applicable | Describe quiescence, outstanding work, and reverse dependency teardown. |
| `@par Exit Status` | Required for the hosted entry | Map internal errors to process-level success/failure values instead of leaking an unexplained negative library status. |
| `@see` | Optional | Replace each target with an existing related operation, type, or document anchor. |
| `@showrefs` | Optional | Request the generated References view. Its accuracy depends on source analysis and configuration. |
| `@showrefby` | Optional | Request the generated Referenced by view; it is not proof that all indirect callers have been found. |

### 4.17. Close the application entry point group

```c
/** @} */
```

**Required for the preceding opening.** End `<APPLICATION_NAME>_CORE_ENTRY` after its last entity and before opening
another level or closing the file. This standalone block is not part of the preceding function contract.
Keep a blank line on each side so the boundary remains visible.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `@}` | Required | Close exactly the group opened for this region; do not cross or leave unmatched group boundaries. |

### 4.18. End of file

```c
/* EOF */
```

**Required.** Place the literal marker after all group and preprocessor closures. Keep one blank line
before and one after it in the physical file; the Markdown fence does not display the final empty line.

| Field or construct | Obligation | What to fill or preserve |
| --- | --- | --- |
| `/* EOF */` | Required | Preserve the marker and the surrounding blank lines. |

---

<a id="doxygen-fields"></a>

## Doxygen commands and field semantics

The construction chapters above are the literal source patterns. This lookup section explains the commands;
it does not replace a banner or entity block with an abbreviated alternative.

| Construct | Meaning and completion rule |
| --- | --- |
| `/** ... */` | Documentation block. Preserve this form for the displayed banners and entity contracts. |
| `/* ... */` | Ordinary source explanation or the literal unimplemented function body. |
| `/**< ... */` | Documentation attached to the preceding member. Keep its marker distinct from a fill-in `<...>` value. |
| `@file` | File identity. Replace the placeholder with the actual filename. |
| `@def`, `@enum`, `@struct`, `@union`, `@typedef`, `@var` | Entity identity. Match the name to the corresponding declaration rather than treating these tags as interchangeable. |
| `@brief`, `@details` | Responsibility and additional explanation, in the order shown. |
| `@par` | A named project documentation paragraph, not a new custom Doxygen command. |
| `@li`, `@ref`, `@b` | List entry, reference target, and emphasized identifier. Preserve all lines of each shown list entry. |
| `@param[in]` | Input value or borrowed readable data, with range, unit, and validity. |
| `@param[out]` | Writable destination, extent, nullability, and state after success/failure. |
| `@param[in,out]` | Accepted initial state plus permitted mutations and resulting state. |
| `@return`, `@retval` | Overall result convention followed by each distinct outcome. |
| `@pre`, `@post`, `@invariant` | Caller obligations, outcome guarantees, and maintained relationships. |
| `@note`, `@warning` | Specific clarification or hazard; optional unless needed to communicate a real restriction. |
| `@see` | An existing related entity or documented operation. |
| `@showrefs`, `@showrefby` | Generated reference and reverse-reference views. |
| `@includedbygraph` | Reverse include graph for a header, when graph generation is configured. |
| `@addtogroup`, `@ingroup`, `@{`, `@}` | Documentation membership and balanced regions. They do not set C linkage or linker exports. |
| `@version`, `@date`, `@author` | Maintained metadata; keep their positions at the end of the file contract. |

Doxygen accepts the command spellings used here; see its
[command manual](https://www.doxygen.nl/manual/commands.html) and
[comment-block manual](https://www.doxygen.nl/manual/docblocks.html). The instructions inside angle brackets
are not published prose. Raw angle-bracket text can be interpreted as markup; complete it before rendering.
When a published document intentionally describes a literal placeholder, use appropriate escaping or a code span.

`@invariant` does not create a formal proof, `[in]` does not implement `const`, and a Thread Safety paragraph
cannot supply synchronization missing from the code. Align each claim with the
[C Code Standard](c-code-standard.md#cstyle-270), the
[architecture contract rules](c-module-architecture.md#cmod-110), and the corresponding
[verification specification](test/c-tests-formal.md#cfv-004-keep-one-authoritative-specification).

Ownership, Reentrancy, Thread Safety, Blocking, Side Effects, Complexity, Startup, Failure Recovery, and
Shutdown are optional when applicable. The expanded patterns show their positions; keeping every paragraph
is not a requirement. Retain separate paragraphs when they explain relevant behavior and omit inapplicable
ones rather than publishing empty labels. Required preconditions, results, and guarantees still follow the
code and architecture contracts. For a void result, omit return/status fields and document relevant effects.

The complete source definition blocks are retained even when a header also documents the operation. Keep the
declaration and definition contract blocks identical and update them together; do not replace the source block
with a generic one-line comment. Do not use
`@copydoc` targeting the function itself as a shortcut between its declaration and definition. Doxygen merges
identical blocks; differing repeated parameter/status
sections can produce duplicate-documentation diagnostics. Keep implementation rationale in a separate ordinary
comment when it is not part of the shared contract.

---

<a id="completion"></a>

## Completion and Doxygen validation

The first acceptance check is fidelity to the source layout: all applicable banners, every documented field,
all declarations, group boundaries, compatibility blocks, and closing markers must appear in the order shown.
The optionality tables govern actual applicability; they do not turn the full pattern into a short summary.

Before running Doxygen:

1. Complete every `<...>` value, including structural entity names, reference targets, and return codes.
2. Define each referenced group once with `@defgroup` in the owned module/application documentation.
3. Check parameters, enum lists, field lists, aliases, and prototypes against their declarations.
4. Keep public layouts opaque, complete internal layouts owned once, and storage objects in source files.
5. Keep every retained function contract complete and synchronize it with the authoritative header contract.
6. Verify unique header guards, balanced compatibility blocks, group boundaries, and the final blank line.
7. Validate source columns, indentation, and logical spacing using the [C formatting
rules](c-code-standard.md#cstyle-014).
8. Verify that the four assembled files use consistent illustrative names and supported C/C++ signatures.

Use [the repository Doxyfile](../../../doxygen/config/Doxyfile) and
[its execution and validation instructions](../../../doxygen/README.md). The profile pins Doxygen 1.18.0,
uses eight-column tabs, retains documentation warnings, and filters section titles and delimiter bars before
parsing. The [configuration manual](https://www.doxygen.nl/manual/config.html) describes the options. A
successful run cannot
prove the documented behavior; preserve the distinction between formatting, parsing, rendering, and semantic
review required by [CSTYLE-277](c-code-standard.md#cstyle-277) and
[CMOD-115](c-module-architecture.md#cmod-115).

Inspect the generated file, group, type, callback, and function pages. In particular, check banner attachment,
entity tags versus typedef aliases, trailing member comments, duplicate declaration/definition paragraphs,
parameter directions, status values, reference targets, and graph direction. An explicit `@enum` or `@struct`
can identify a different entity from its typedef alias; verify the selected extraction profile's treatment of
both. The trailing `/**< <Type alias.> */` on an aggregate typedef documents its alias separately
from its tag. Do not silently replace the prescribed source layout merely to hide a diagnostic.

Review the behavior claimed by the completed text against the tests and specifications. Record any required
change or deviation through [C Compliance and Assurance](c-compliance.md#workflow). These literal templates
do not establish runtime behavior or public ABI compatibility. The validation command records Doxygen
results for the explicitly completed fixture copies, not for unfinished placeholders.

<!-- EOF -->


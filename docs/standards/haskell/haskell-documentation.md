<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Haskell Documentation Standard

Document contracts through Haddock. Apply the rule levels, example policy and exception route from the
[code standard](haskell-code-standard.md#governance). Documentation review covers meaning as well as markup.

<details>
<summary><strong>On this page</strong></summary>

- [Contract controls](#contract-controls)
- [Complete module](#complete-module)
- [Rendering and sources](#rendering-and-sources)

</details>

---

## Contract controls

<a id="hdoc-001"></a>

### HDOC-001: Describe the caller's contract

**MUST · exported declarations.** State units, admitted inputs, result meaning, expected errors, post-state
and evaluation requirements. For effectful APIs, also state ownership, cleanup, cancellation and concurrency.
Link specification clauses and distinguish proved properties from tested behavior.

**Reason and examples:** Conforming: “Rejects a negative request; failure preserves the input cursor.”
Nonconforming: “Reserves memory safely.” The latter omits both the domain and failure behavior.

**Verification and limit:** Compare rendered docs with branches and tests. Haddock can render a false contract;
neither it nor GHC proves the prose. Use [HCOMP-003](haskell-compliance.md#hcomp-003) for exceptions.

<a id="hdoc-002"></a>

### HDOC-002: Explain the module boundary

**MUST · library modules.** Put a module summary before the module declaration, followed by grouped exports.
Describe the represented state, dependency direction, trusted inputs and limitations. Explain why a helper
belongs in the core or an adapter. Keep implementation history in version control.

**Reason and examples:** Conforming: describe a scalar reservation model and its missing pointer semantics.
Nonconforming: call the module a complete allocator verifier because it constructs certificates.

**Verification and limit:** Review the summary against exposed modules, imports and the trust model.
Documentation coverage counts cannot establish correctness or appropriate module boundaries.

<a id="hdoc-003"></a>

### HDOC-003: Use native markup and executable examples

**MUST · source documentation.** Use `-- |` for a declaration, `-- ^` for a following annotation, quoted
identifier references and `@code@` literals. Use export headings for API groups. State the required extensions
and imports for examples, and mark deliberate failures outside the positive example set.

**Reason and examples:** Conforming: a `>>> reserve ...` example with a checked expected result.
Nonconforming: a Doxygen `@param` block or a displayed example described as executed solely because Haddock rendered
it.

**Verification and limit:** Render links and compile complete examples with GHC 9.4.7. Execute expected results
in a test harness; Haddock rendering does not run doctests. No doctest runner is configured in current CI.

<a id="hdoc-004"></a>

### HDOC-004: Attach a mathematical statement to each formal property

**MUST · every owned Haskell theorem, lemma and dedicated formal-property function.** Apply
[HSTYLE-MATH-001](haskell-code-standard.md#hstyle-math-001) to public, private, local and generated declarations.
Write the mathematical comment above the Liquid Haskell annotation; keep the annotation, Haskell signature
and equations in the same declaration group. Use `-- |` for a named declaration and `--` for a local binding.
Keep the mathematical statement in that comment even when another document explains the theorem.

Use `Mathematical statement:` followed by the quantified proposition. Give the variable domains, assumptions
and conclusion; explain units, arithmetic and the mapping from mathematical symbols to function parameters.
For a witness function, state which proposition the returned value witnesses. Identify conditional assumptions
at an external boundary. A title, theorem name, refinement annotation or prose such as “proves safety” alone
does not satisfy the mathematical-comment requirement.

**Reason and examples:** The [code-standard example](haskell-code-standard.md#hstyle-math-001) states
`∀ a, b ∈ ℤ, (0 ≤ a ∧ 0 ≤ b) ⇒ 0 ≤ a + b` above the witness contract. Omitting the nonnegative hypotheses
would misstate the theorem. Putting them only in the module summary would leave the declaration undocumented.

**Verification and limit:** Review each statement against its refinement and implementation, and retain the
matching Liquid Haskell result required by [HSTYLE-LIQUID-001](haskell-code-standard.md#hstyle-liquid-001).
Update the comment when domains, hypotheses or the conclusion change. Haddock, formatting and comment counts
cannot establish mathematical agreement; reviewers must record it separately from the checker result.

---

## Complete module

This standalone Haskell2010 module documents a mathematical cursor. It has no FFI or allocation effect.
Every `Left` preserves the caller's immutable input. The nonnegative integer checks define the admitted domain;
they do not bound runtime memory use for arbitrarily large integers.
This example demonstrates Haddock and ordinary compilation. It does not provide the Liquid Haskell contracts
or audit evidence required for whole-module conformance under
[HSTYLE-LIQUID-001](haskell-code-standard.md#hstyle-liquid-001).

```haskell
-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

-- | Checked reservation in a mathematical cursor.
--
-- The caller owns the immutable cursor. This module models scalar bounds;
-- it makes no claim about C pointers, storage or concurrent access.
module GuideReservation (
  -- * State and failures
  Cursor,
  ReserveError (..),

  -- * Construction and transitions
  mkCursor,
  usedBytes,
  reserve,
) where

-- | Capacity and usage in bytes, with @0 <= used <= capacity@.
data Cursor = Cursor !Integer !Integer
  deriving (Eq, Show)

-- | Expected failures; no transition occurs on rejection.
data ReserveError = InvalidCursor | NegativeRequest | CapacityExceeded
  deriving (Eq, Show)

-- | Validate capacity and usage before constructing a 'Cursor'.
mkCursor :: Integer -> Integer -> Either ReserveError Cursor
mkCursor capacity used
  | capacity < 0 || used < 0 || used > capacity = Left InvalidCursor
  | otherwise = Right (Cursor capacity used)

-- | Return the number of bytes already reserved.
usedBytes :: Cursor -> Integer
usedBytes (Cursor _ used) = used

-- | Reserve bytes when they fit; zero leaves the cursor unchanged.
--
-- Failure preserves the input. The result must be demanded by the caller.
--
-- >>> fmap usedBytes (mkCursor 8 3 >>= \cursor -> reserve cursor 5)
-- Right 8
reserve :: Cursor -> Integer -> Either ReserveError Cursor
reserve (Cursor capacity used) requested
  | requested < 0 = Left NegativeRequest
  | requested > capacity - used = Left CapacityExceeded
  | otherwise = Right (Cursor capacity (used + requested))

-- EOF
```

---

## Rendering and sources

For the standalone module saved under `.cache/docs/haskell/GuideReservation.hs`, use the prepared toolchain:

```sh
.cache/tools/formal/bin/ghc -XHaskell2010 -Wall -Wcompat -Wincomplete-uni-patterns \
  -Werror -fno-code .cache/docs/haskell/GuideReservation.hs
.cache/tools/formal/bin/haddock --html --odir=.cache/docs/haskell/html \
  .cache/docs/haskell/GuideReservation.hs
```

The current source checker does not extract this block. A documentation author must save and validate it
when changing the example. Haddock may warn about missing dependency links when no base interface is supplied;
review local declaration coverage separately.

The markup reference is [Haddock, Documentation and
Markup](https://haskell-haddock.readthedocs.io/latest/markup.html),
sections Documentation annotations, Module descriptions, Hyperlinked identifiers and Examples, consulted
2026-10-15. For the adopted compiler, use the
[Haddock 2.27.0 source manual](https://github.com/haskell/haddock/blob/haddock-2.27.0-release/doc/markup.rst).
The newer website's version-specific features do not extend the local renderer capabilities.

<!-- EOF -->


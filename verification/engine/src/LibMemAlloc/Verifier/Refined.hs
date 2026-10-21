-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

-- | Arithmetic used by the interpreter. Integer avoids host-word overflow.
-- The mandatory verification build enables Liquid Haskell for every component.
module LibMemAlloc.Verifier.Refined (addWithin, subtractWithin, canRead, canWrite) where

-- 0 = expired, 1 = live borrowed read-only, 2 = live exclusively owned.

-- | Mathematical statement: ∀ p ∈ ℤ, 0 ≤ p ≤ 2 ⇒ (canRead(p) ⇔ p > 0).

{-@ canRead :: phase:{Integer | 0 <= phase && phase <= 2}
            -> {allowed:Bool | allowed <=> phase > 0} @-}
canRead :: Integer -> Bool
canRead phase = phase > 0

-- | Mathematical statement: ∀ p ∈ ℤ, 0 ≤ p ≤ 2 ⇒ (canWrite(p) ⇔ p = 2).

{-@ canWrite :: phase:{Integer | 0 <= phase && phase <= 2}
             -> {allowed:Bool | allowed <=> phase == 2} @-}
canWrite :: Integer -> Bool
canWrite phase = phase == 2

-- | Mathematical statement: ∀ L, a, b ∈ ℤ, 0 ≤ a ≤ L ∧ 0 ≤ b ≤ L − a
-- ⇒ addWithin(L, a, b) = a + b ∧ 0 ≤ a + b ≤ L.

{-@ addWithin :: limit:{Integer | 0 <= limit}
              -> left:{Integer | 0 <= left && left <= limit}
              -> right:{Integer | 0 <= right && right <= limit - left}
              -> {result:Integer | result == left + right && result <= limit && 0 <= result}
  @-}
addWithin :: Integer -> Integer -> Integer -> Integer
addWithin _ left right = left + right

-- | Mathematical statement: ∀ a, b ∈ ℤ, 0 ≤ b ≤ a
-- ⇒ subtractWithin(a, b) = a − b ∧ 0 ≤ a − b ≤ a.

{-@ subtractWithin :: left:{Integer | 0 <= left}
                   -> right:{Integer | 0 <= right && right <= left}
                   -> {result:Integer | result == left - right && 0 <= result && result <= left}
  @-}
subtractWithin :: Integer -> Integer -> Integer
subtractWithin left right = left - right

-- EOF


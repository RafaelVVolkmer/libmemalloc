-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

-- | Explicit C-to-cell representation, independent of allocator operations.
module LibMemAlloc.Verifier.Layout (
  Parameter (..),
  Layout (..),
  signature,
  bindings,
  validateLayout,
) where

import Data.Char (isAlpha, isAlphaNum)
import Data.List (intercalate, nub)

data Parameter = Scalar String Int | Object String String [(String, Int)]
  deriving (Eq, Show)

{-@ parameters :: Layout -> [Parameter] @-}
{-@ booleanReturn :: Layout -> Bool @-}
{-@ localBase :: Layout -> Int @-}

data Layout = Layout
  { parameters :: [Parameter]
  , booleanReturn :: Bool
  , localBase :: Int
  }
  deriving (Eq, Show)

{-@ signature :: Layout -> String @-}
signature :: Layout -> String
signature layout =
  "function ("
    ++ intercalate ", " (map kind (parameters layout))
    ++ ") returning "
    ++ if booleanReturn layout then "signed int" else "unsigned long"
 where
  kind (Scalar _ _) = "unsigned long"
  kind (Object _ tag _) = "pointer to struct " ++ tag

{-@ bindings :: Layout -> [(String, Int)] @-}
bindings :: Layout -> [(String, Int)]
bindings layout = concatMap cells (parameters layout)
 where
  cells (Scalar name cell) = [(name, cell)]
  cells (Object name _ fields) = [(name ++ "." ++ field, cell) | (field, cell) <- fields]

{-@ validateLayout :: Layout -> Either String () @-}
validateLayout :: Layout -> Either String ()
validateLayout layout
  | not (all identifier names) = Left "invalid C binding name"
  | length names /= length (nub names) = Left "duplicate C parameter"
  | length cells /= length (nub cells) = Left "aliased scalar cells in layout"
  | any (\cell -> cell < 0 || cell >= localBase layout) cells = Left "cell outside entry layout"
  | localBase layout < 0 || localBase layout > 4096 = Left "layout exceeds cell limit"
  | any invalidObject (parameters layout) = Left "invalid object fields"
  | otherwise = Right ()
 where
  names = [case p of Scalar name _ -> name; Object name _ _ -> name | p <- parameters layout]
  cells = map snd (bindings layout)
  identifier [] = False
  identifier (c : cs) = (isAlpha c || c == '_') && all (\x -> isAlphaNum x || x == '_') cs
  invalidObject (Scalar _ _) = False
  invalidObject (Object _ tag fields) =
    not (identifier tag)
      || null fields
      || not (all (identifier . fst) fields)
      || length fields /= length (nub (map fst fields))

-- EOF


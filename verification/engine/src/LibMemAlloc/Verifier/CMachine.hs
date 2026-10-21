-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

-- | Structural abstract interpretation of the imported C body, on every path.
-- Object validity and exclusive access on entry are external preconditions.
-- This fragment has no allocation/free instruction; such C is unsupported.
module LibMemAlloc.Verifier.CMachine (
  Phase (..),
  Policy (..),
  analyzeWith,
) where

import Control.Monad (unless)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import LibMemAlloc.Verifier.IR
import qualified LibMemAlloc.Verifier.IR as IR
import LibMemAlloc.Verifier.Protocol (JSON (..), decimal)
import LibMemAlloc.Verifier.Refined (canRead, canWrite)

data Phase = Expired | Borrowed | Owned deriving (Eq, Show)

{-@ entryCells :: Policy -> [Int] @-}
{-@ objectCells :: Policy -> [Int] @-}
{-@ mutableCells :: Policy -> [Int] @-}
{-@ localCells :: Policy -> [Int] @-}
{-@ booleanResult :: Policy -> Bool @-}

data Policy = Policy
  { entryCells :: [Int]
  , objectCells :: [Int]
  , mutableCells :: [Int]
  , localCells :: [Int]
  , booleanResult :: Bool
  }
  deriving (Eq, Show)

data Scalar = Word64 | BooleanInt deriving (Eq, Show)
type Initialized = Map.Map Int Scalar

-- | Mathematical statement: ∀ p ∈ Phase, phaseNumber(p) ∈ {0, 1, 2}.

{-@ phaseNumber :: Phase -> {n:Integer | 0 <= n && n <= 2} @-}
phaseNumber :: Phase -> Integer
phaseNumber Expired = 0
phaseNumber Borrowed = 1
phaseNumber Owned = 2

{-@ analyzeWith :: Policy -> Phase -> Program -> Either String JSON @-}
analyzeWith :: Policy -> Phase -> Program -> Either String JSON
analyzeWith policy phase program = do
  unless
    ( Set.null
        ( Set.intersection
            (Set.fromList (entryCells policy))
            (Set.fromList (localCells policy))
        )
    )
    (Left "entry and local cells overlap")
  (readCount, writes, returns) <-
    walk (Map.fromList [(cell, Word64) | cell <- entryCells policy]) program
  pure
    ( JObject
        [ ("status", JString "checked")
        , ("reads", decimal readCount)
        , ("writes", decimal writes)
        , ("return_paths", decimal returns)
        , ("entry_object", JString (show phase))
        , ("exit_object", JString (show phase))
        ,
          ( "entry_assumption"
          , JString "caller supplies initialized entry cells and the declared object permissions"
          )
        , ("scope", JString "all imported branches; types, initialization and access permissions")
        ]
    )
 where
  readCell initialized cell = do
    kind <- maybe (Left "read of uninitialized scalar") Right (Map.lookup cell initialized)
    unless
      (cell `notElem` objectCells policy || canRead (phaseNumber phase))
      (Left "read of expired object")
    pure kind
  {-@ expr :: Initialized -> e:Expr -> Either String (Scalar, Integer) / [IR.exprSize e, 0] @-}
  expr :: Initialized -> IR.Expr -> Either String (Scalar, Integer)
  expr initialized expression = case expression of
    Literal n ->
      if n >= 0 && n <= wordLimit
        then Right (if n <= 1 then BooleanInt else Word64, 0)
        else Left "literal outside machine range"
    Read cell -> do kind <- readCell initialized cell; pure (kind, 1)
    Add a b -> arithmetic initialized a b
    Sub a b -> arithmetic initialized a b
    Mod a b -> arithmetic initialized a b
  {-@ arithmetic :: Initialized -> a:Expr -> b:Expr -> Either String (Scalar, Integer)
                 / [IR.exprSize a + IR.exprSize b, 1] @-}
  arithmetic :: Initialized -> Expr -> Expr -> Either String (Scalar, Integer)
  arithmetic initialized a b = do
    (_, ra) <- expr initialized a
    (_, rb) <- expr initialized b
    -- Arithmetic bounds are path-dependent proof obligations discharged by
    -- the generated Lean proof, not assumed from the scalar type.
    pure (Word64, ra + rb)
  guardReads initialized condition = case condition of
    Gt a b -> snd <$> arithmetic initialized a b
    Equal a b -> snd <$> arithmetic initialized a b
  {-@
    walk :: Initialized -> body:Program -> Either String (Integer, Integer, Integer) /
      [IR.programSize body]
  @-}
  walk :: Initialized -> Program -> Either String (Integer, Integer, Integer)
  walk initialized body = case body of
    Return value -> do
      (kind, readCount) <- expr initialized value
      unless (not (booleanResult policy) || kind == BooleanInt) (Left "return is not a boolean int")
      pure (readCount, 0, 1)
    Write cell value next -> do
      (kind, readCount) <- expr initialized value
      unless
        (cell `elem` mutableCells policy || cell `elem` localCells policy)
        (Left "write outside the declared mutable footprint")
      unless
        (cell `notElem` objectCells policy || canWrite (phaseNumber phase))
        (Left "write without live exclusive ownership")
      (r, w, n) <- walk (Map.insert cell kind initialized) next
      pure (readCount + r, w + 1, n)
    Branch condition yes no -> do
      readCount <- guardReads initialized condition
      (ry, wy, ny) <- walk initialized yes
      (rn, wn, nn) <- walk initialized no
      pure (readCount + ry + rn, wy + wn, ny + nn)

-- EOF


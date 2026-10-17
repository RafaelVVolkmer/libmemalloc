-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

-- | Mirror of the declared portable IR; Lean checks the resulting program theorem.
module LibMemAlloc.Verifier.IR (
  Expr (..),
  Cond (..),
  Program (..),
  exprSize,
  programSize,
  Store,
  load,
  wordLimit,
  eval,
  run,
  programJSON,
  parseProgram,
  expressionJSON,
  leanProgram,
  leanExpr,
) where

import qualified Data.Map.Strict as Map
import LibMemAlloc.Verifier.Protocol (JSON (..), decimal, natural)
import LibMemAlloc.Verifier.Refined (addWithin, subtractWithin)

{-@ data Expr [exprSize] @-}
data Expr = Literal Integer | Read Int | Add Expr Expr | Sub Expr Expr | Mod Expr Expr
  deriving (Eq, Show)
data Cond = Gt Expr Expr | Equal Expr Expr deriving (Eq, Show)

{-@ data Program [programSize] @-}
data Program = Return Expr | Write Int Expr Program | Branch Cond Program Program
  deriving (Eq, Show)
type Store = Map.Map Int Integer

-- | Mathematical statement: exprSize(e) is positive and strictly greater
-- than the size of either immediate arithmetic operand.

{-@ measure exprSize @-}
{-@ exprSize :: Expr -> Nat @-}
exprSize :: Expr -> Int
exprSize (Literal _) = 1
exprSize (Read _) = 1
exprSize (Add a b) = 1 + exprSize a + exprSize b
exprSize (Sub a b) = 1 + exprSize a + exprSize b
exprSize (Mod a b) = 1 + exprSize a + exprSize b

-- | Mathematical statement: programSize(p) is positive and decreases along
-- every successor of the loop-free IR.

{-@ measure programSize @-}
{-@ programSize :: Program -> Nat @-}
programSize :: Program -> Int
programSize (Return _) = 1
programSize (Write _ _ next) = 1 + programSize next
programSize (Branch _ yes no) = 1 + programSize yes + programSize no

{-@ load :: Store -> Int -> Integer @-}
load :: Store -> Int -> Integer
load state cell = Map.findWithDefault 0 cell state

{-@ wordLimit :: Integer @-}
wordLimit :: Integer
wordLimit = 2 ^ (64 :: Int) - 1

{-@ bounded :: limit:Integer -> n:Integer
            -> Either String {r:Integer | r == n && 0 <= r && r <= limit} @-}
bounded :: Integer -> Integer -> Either String Integer
bounded limit n
  | 0 <= n && n <= limit = Right n
  | otherwise = Left "word bound violated"

-- | Mathematical statement: ∀ L ∈ ℤ, s ∈ Store, e ∈ Expr,
-- eval(L, s, e) = Right r ⇒ 0 ≤ r ≤ L. Failure is represented by Left.

{-@ eval :: limit:Integer -> Store -> Expr
         -> Either String {r:Integer | 0 <= r && r <= limit} @-}
eval :: Integer -> Store -> Expr -> Either String Integer
eval limit state expression = case expression of
  Literal n -> bounded limit n
  Read cell -> maybe (Left "read of uninitialized scalar") (bounded limit) (Map.lookup cell state)
  Add left right -> do
    a <- eval limit state left
    b <- eval limit state right
    if b <= limit - a then pure (addWithin limit a b) else Left "unsigned addition would wrap"
  Sub left right -> do
    a <- eval limit state left
    b <- eval limit state right
    if b <= a then pure (subtractWithin a b) else Left "unsigned subtraction would wrap"
  Mod left right -> do
    a <- eval limit state left
    b <- eval limit state right
    if b > 0 then pure (a `mod` b) else Left "division by zero"

{-@ run :: Integer -> program:Program -> Store -> Either String (Integer, Store)
        / [programSize program] @-}
run :: Integer -> Program -> Store -> Either String (Integer, Store)
run limit program state = case program of
  Return expression -> do result <- eval limit state expression; pure (result, state)
  Write cell expression next -> do
    value <- eval limit state expression
    run limit next (Map.insert cell value state)
  Branch condition yes no -> do
    selected <- case condition of
      Gt left right -> (>) <$> eval limit state left <*> eval limit state right
      Equal left right -> (==) <$> eval limit state left <*> eval limit state right
    run limit (if selected then yes else no) state

{-@ expressionJSON :: Expr -> JSON @-}
expressionJSON :: Expr -> JSON
expressionJSON expression = JArray $ case expression of
  Literal n -> [JString "literal", decimal n]
  Read cell -> [JString "read", decimal (toInteger cell)]
  Add a b -> [JString "add", expressionJSON a, expressionJSON b]
  Sub a b -> [JString "sub", expressionJSON a, expressionJSON b]
  Mod a b -> [JString "mod", expressionJSON a, expressionJSON b]

{-@ conditionJSON :: Cond -> JSON @-}
conditionJSON :: Cond -> JSON
conditionJSON (Gt a b) = JArray [JString "gt", expressionJSON a, expressionJSON b]
conditionJSON (Equal a b) = JArray [JString "eq", expressionJSON a, expressionJSON b]

{-@ programJSON :: Program -> JSON @-}
programJSON :: Program -> JSON
programJSON (Return value) = JArray [JString "return", expressionJSON value]
programJSON (Write cell value next) =
  JArray
    [JString "write", decimal (toInteger cell), expressionJSON value, programJSON next]
programJSON (Branch condition yes no) =
  JArray
    [JString "branch", conditionJSON condition, programJSON yes, programJSON no]

{-@ parseCell :: JSON -> Either String Int @-}
parseCell :: JSON -> Either String Int
parseCell json = do
  value <- natural json
  if value < 4352 then pure (fromInteger value) else Left "unsupported scalar cell"

{-@ parseExpr :: JSON -> Either String Expr @-}
parseExpr :: JSON -> Either String Expr
parseExpr (JArray [JString "literal", n]) = Literal <$> natural n
parseExpr (JArray [JString "read", n]) = Read <$> parseCell n
parseExpr (JArray [JString tag, a, b]) = do
  constructor <- case tag of
    "add" -> Right Add
    "sub" -> Right Sub
    "mod" -> Right Mod
    _ -> Left "unsupported expression"
  constructor <$> parseExpr a <*> parseExpr b
parseExpr _ = Left "invalid expression"

{-@ parseCond :: JSON -> Either String Cond @-}
parseCond :: JSON -> Either String Cond
parseCond (JArray [JString "gt", a, b]) = Gt <$> parseExpr a <*> parseExpr b
parseCond (JArray [JString "eq", a, b]) = Equal <$> parseExpr a <*> parseExpr b
parseCond _ = Left "unsupported condition"

{-@ parseProgram :: JSON -> Either String Program @-}
parseProgram :: JSON -> Either String Program
parseProgram (JArray [JString "return", value]) = Return <$> parseExpr value
parseProgram (JArray [JString "write", cell, value, next]) =
  Write <$> parseCell cell <*> parseExpr value <*> parseProgram next
parseProgram (JArray [JString "branch", condition, yes, no]) =
  Branch <$> parseCond condition <*> parseProgram yes <*> parseProgram no
parseProgram _ = Left "unsupported program constructor"

{-@ leanExpr :: Expr -> String @-}
leanExpr :: Expr -> String
leanExpr expression = case expression of
  Literal n -> "(.literal " ++ show n ++ ")"
  Read cell -> "(.read " ++ show cell ++ ")"
  Add a b -> binary "add" (leanExpr a) (leanExpr b)
  Sub a b -> binary "sub" (leanExpr a) (leanExpr b)
  Mod a b -> binary "mod" (leanExpr a) (leanExpr b)
 where
  binary tag a b = "(." ++ tag ++ " " ++ a ++ " " ++ b ++ ")"

{-@ leanCond :: Cond -> String @-}
leanCond :: Cond -> String
leanCond (Gt a b) = "(.gt " ++ leanExpr a ++ " " ++ leanExpr b ++ ")"
leanCond (Equal a b) = "(.eq " ++ leanExpr a ++ " " ++ leanExpr b ++ ")"

{-@ leanProgram :: Program -> String @-}
leanProgram :: Program -> String
leanProgram (Return expression) = "(.ret " ++ leanExpr expression ++ ")"
leanProgram (Write cell expression next) =
  "(.write " ++ show cell ++ " " ++ leanExpr expression ++ " " ++ leanProgram next ++ ")"
leanProgram (Branch condition yes no) =
  "(.branch " ++ leanCond condition ++ " " ++ leanProgram yes ++ " " ++ leanProgram no ++ ")"

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

-- | Symbolic execution retains both branch successors. Conditions and store effects
-- are proof candidates; the final proof uses Lean's wp computed from the whole IR.
module LibMemAlloc.Verifier.Symbolic (
  Path (..),
  paths,
  pathJSON,
  coverageJSON,
  coverageLean,
  nodeCount,
  substitute,
) where

import qualified Data.Map.Strict as Map
import LibMemAlloc.Verifier.IR
import LibMemAlloc.Verifier.Protocol (JSON (..), decimal)

type Environment = Map.Map Int Expr

data Path = Path [(Cond, Bool)] Expr [(Int, Expr)] deriving (Eq, Show)

{-@ substitute :: Environment -> Expr -> Expr @-}
substitute :: Environment -> Expr -> Expr
substitute environment expression = case expression of
  Literal _ -> expression
  Read cell -> Map.findWithDefault expression cell environment
  Add a b -> Add (substitute environment a) (substitute environment b)
  Sub a b -> Sub (substitute environment a) (substitute environment b)
  Mod a b -> Mod (substitute environment a) (substitute environment b)

{-@ substituteCondition :: Environment -> Cond -> Cond @-}
substituteCondition :: Environment -> Cond -> Cond
substituteCondition environment (Gt a b) = Gt (substitute environment a) (substitute environment b)
substituteCondition environment (Equal a b) =
  Equal (substitute environment a) (substitute environment b)

{-@ paths :: Program -> [Path] @-}
paths :: Program -> [Path]
paths = visit Map.empty []
 where
  {-@
    visit :: Environment -> [(Cond, Bool)] -> body:Program -> [Path] /
      [LibMemAlloc.Verifier.IR.programSize body]
  @-}
  visit :: Environment -> [(Cond, Bool)] -> Program -> [Path]
  visit environment guards (Return expression) =
    [Path guards (substitute environment expression) (Map.toAscList environment)]
  visit environment guards (Write cell expression next) =
    visit (Map.insert cell (substitute environment expression) environment) guards next
  visit environment guards (Branch condition yes no) =
    let condition' = substituteCondition environment condition
     in visit environment (guards ++ [(condition', True)]) yes
          ++ visit environment (guards ++ [(condition', False)]) no

{-@ pathJSON :: Path -> JSON @-}
pathJSON :: Path -> JSON
pathJSON (Path guards result effects) =
  JObject
    [ ("guards", JArray (map guardJSON guards))
    , ("result", expressionJSON result)
    ,
      ( "effects"
      , JArray
          [ JArray [decimal (toInteger cell), expressionJSON expression]
          | (cell, expression) <- effects
          ]
      )
    ]
 where
  guardJSON (condition, polarity) = JArray [conditionJSON condition, JBool polarity]
  conditionJSON (Gt a b) = JArray [JString "gt", expressionJSON a, expressionJSON b]
  conditionJSON (Equal a b) = JArray [JString "eq", expressionJSON a, expressionJSON b]

{-@ coverageJSON :: Program -> JSON @-}
coverageJSON :: Program -> JSON
coverageJSON (Return _) = JArray [JString "return"]
coverageJSON (Write _ _ next) = JArray [JString "write", coverageJSON next]
coverageJSON (Branch _ yes no) = JArray [JString "branch", coverageJSON yes, coverageJSON no]

{-@ coverageLean :: Program -> String @-}
coverageLean :: Program -> String
coverageLean (Return _) = ".ret"
coverageLean (Write _ _ next) = "(.write " ++ coverageLean next ++ ")"
coverageLean (Branch _ yes no) = "(.branch " ++ coverageLean yes ++ " " ++ coverageLean no ++ ")"

{-@ nodeCount :: Program -> Integer @-}
nodeCount :: Program -> Integer
nodeCount (Return _) = 1
nodeCount (Write _ _ next) = 1 + nodeCount next
nodeCount (Branch _ yes no) = 1 + nodeCount yes + nodeCount no

-- EOF


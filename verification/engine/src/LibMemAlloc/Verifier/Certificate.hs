-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

-- | Operation-independent proof obligations. Recipes remain untrusted Lean input.
module LibMemAlloc.Verifier.Certificate (Contract (..), expectedSource, proofSource) where

import qualified Data.Map.Strict as Map
import LibMemAlloc.Verifier.IR
import LibMemAlloc.Verifier.Symbolic (coverageLean, substitute)

type Environment = Map.Map Int Expr

{-@ contractModule :: Contract -> String @-}
{-@ precondition :: Contract -> String @-}
{-@ postcondition :: Contract -> String @-}

data Contract = Contract
  { contractModule :: String
  , precondition :: String
  , postcondition :: String
  }
  deriving (Eq, Show)

{-@ expectedSource :: Integer -> Contract -> Program -> String @-}
expectedSource :: Integer -> Contract -> Program -> String
expectedSource limit contract program =
  unlines
    [ "import " ++ contractModule contract
    , "import LibMemAllocImp.Certificates.Hoare"
    , "namespace Expected"
    , "def program : Allocator.IR.Program := " ++ leanProgram program
    , "def Claim := Allocator.IR.Satisfies "
        ++ show limit
        ++ " program "
        ++ precondition contract
        ++ " "
        ++ postcondition contract
    , "end Expected"
    ]

{-@ proofSource :: Contract -> Program -> String @-}
proofSource :: Contract -> Program -> String
proofSource contract program =
  unlines
    [ "import Expected"
    , "import LibMemAllocImp.C.Unsigned"
    , "import LibMemAllocImp.Certificates.Program"
    , "namespace Generated"
    , "set_option linter.unusedSimpArgs false"
    , "def coverage : Allocator.Certificates.Coverage := " ++ coverageLean program
    , "/-- Mathematical statement:"
    , "Allocator.Certificates.checkCoverage Expected.program coverage = true. -/"
    , "theorem coverageAccepted :"
    , "    Allocator.Certificates.checkCoverage Expected.program coverage = true := by decide"
    , "/-- Mathematical statement: Expected.Claim, the Hoare contract defined in Expected. -/"
    , "theorem verified : Expected.Claim := by"
    , "  unfold Expected.Claim"
    , "  apply Allocator.IR.satisfies_of_wp"
    , "  intro s h"
    , unlines (obligations contract Map.empty "s" 0 "  " program)
    , "/-- Mathematical statement: the modular unsigned machine refines the checked IR,"
    , "with identical results and scalar effects and unchanged backing bytes. -/"
    , "theorem unsignedRefinement :"
    , "    Allocator.Translation.Refines 18446744073709551615 Expected.program"
    , "      (fun s : Allocator.C.Unsigned.State => " ++ precondition contract ++ " s.cells)"
    , "      Allocator.C.Unsigned.State.cells"
    , "      (Allocator.C.Unsigned.Executes 18446744073709551615 Expected.program)"
    , "      (Allocator.C.Unsigned.Safe 18446744073709551615 Expected.program) :="
    , "  Allocator.C.Unsigned.refines _ _ _ _ verified"
    , "end Generated"
    ]

-- | Mathematical statement: each generated evaluation equality and branch
-- obligation is checked by Lean before applying wp soundness. Symbolic
-- substitution is a proposal, never a trusted evaluation rule.

{-@ obligations :: Contract -> Environment -> String -> Int -> String -> program:Program -> [String]
                / [programSize program] @-}
obligations :: Contract -> Environment -> String -> Int -> String -> Program -> [String]
obligations contract environment state depth indent program =
  ( indent
      ++ "change Allocator.IR.wp 18446744073709551615 "
      ++ leanProgram program
      ++ " ("
      ++ postcondition contract
      ++ " s) "
      ++ state
  )
    : case program of
      Return value ->
        evaluation "value" value
          ++ [ indent ++ "rw [Allocator.IR.wp, " ++ name "value" ++ "]"
             , indent
                 ++ "change "
                 ++ postcondition contract
                 ++ " s "
                 ++ symbolic value
                 ++ " "
                 ++ state
             , indent ++ "repeat' first"
             , indent
                 ++ "  | simp_all ["
                 ++ precondition contract
                 ++ ", "
                 ++ postcondition contract
                 ++ ", Allocator.IR.update]"
             , indent ++ "  | intro _"
             , indent ++ "  | constructor"
             , indent ++ "  | split"
             , indent ++ "all_goals omega"
             ]
      Write cell value next ->
        evaluation "value" value
          ++ [indent ++ "rw [Allocator.IR.wp, " ++ name "value" ++ "]"]
          ++ obligations
            contract
            (Map.insert cell (substitute environment value) environment)
            ("(Allocator.IR.update " ++ state ++ " " ++ show cell ++ " " ++ symbolic value ++ ")")
            (depth + 1)
            indent
            next
      Branch condition yes no ->
        let (a, b, comparison) = case condition of
              Gt left right -> (left, right, " > ")
              Equal left right -> (left, right, " = ")
            guard = symbolic a ++ comparison ++ symbolic b
            branch polarity continuation =
              [ indent
                  ++ "· -- Mathematical statement: the evaluated condition selects this\
                     \ branch."
              , indent
                  ++ "  have "
                  ++ name "condition"
                  ++ " : Allocator.IR.test 18446744073709551615 "
                  ++ state
                  ++ " "
                  ++ conditionLean condition
                  ++ " = some "
                  ++ polarity
                  ++ " := by"
              , indent
                  ++ "    rw [Allocator.IR.test, "
                  ++ name "left"
                  ++ ", "
                  ++ name "right"
                  ++ "]"
              , indent ++ "    simp [" ++ name "branch" ++ "] <;> omega"
              , indent ++ "  rw [Allocator.IR.wp, " ++ name "condition" ++ "]"
              ]
                ++ continuation
         in evaluation "left" a
              ++ evaluation "right" b
              ++ [indent ++ "by_cases " ++ name "branch" ++ " : " ++ guard]
              ++ branch
                "true"
                (obligations contract environment state (depth + 1) (indent ++ "  ") yes)
              ++ branch
                "false"
                (obligations contract environment state (depth + 1) (indent ++ "  ") no)
 where
  name prefix = prefix ++ show depth
  symbolic value = naturalExpr (substitute environment value)
  evaluation prefix value =
    [ indent
        ++ "-- Mathematical statement: this C expression evaluates without \
           \wrap or undefined division."
    , indent
        ++ "have "
        ++ name prefix
        ++ " : Allocator.IR.eval 18446744073709551615 "
        ++ state
        ++ " "
        ++ leanExpr value
        ++ " = some "
        ++ symbolic value
        ++ " := by"
    , indent
        ++ "  simp_all ["
        ++ precondition contract
        ++ ", Allocator.IR.eval, Allocator.IR.bounded, Allocator.IR.update] <;> omega"
    ]
  conditionLean (Gt a b) = "(.gt " ++ leanExpr a ++ " " ++ leanExpr b ++ ")"
  conditionLean (Equal a b) = "(.eq " ++ leanExpr a ++ " " ++ leanExpr b ++ ")"

{-@ naturalExpr :: Expr -> String @-}
naturalExpr :: Expr -> String
naturalExpr expression = case expression of
  Literal n -> show n
  Read cell -> "(s " ++ show cell ++ ")"
  Add a b -> binary "+" (naturalExpr a) (naturalExpr b)
  Sub a b -> binary "-" (naturalExpr a) (naturalExpr b)
  Mod a b -> binary "%" (naturalExpr a) (naturalExpr b)
 where
  binary operation a b = "(" ++ a ++ " " ++ operation ++ " " ++ b ++ ")"

-- EOF


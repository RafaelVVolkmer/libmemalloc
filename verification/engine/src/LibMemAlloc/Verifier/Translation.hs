-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

-- | Versioned translation admission. The frontend and state abstraction remain trusted.
module LibMemAlloc.Verifier.Translation (
  Binding (..),
  parseBinding,
  produceGeneric,
  replayGeneric,
  evaluateGeneric,
  refuteGeneric,
) where

import Control.Monad (unless)
import Data.Char (isAlpha, isAlphaNum)
import qualified Data.Map.Strict as Map
import LibMemAlloc.Verifier.CMachine (Phase (Owned), Policy (..), analyzeWith)
import LibMemAlloc.Verifier.Certificate (Contract (..), expectedSource, proofSource)
import LibMemAlloc.Verifier.IR
import LibMemAlloc.Verifier.Import.CN (importFunction)
import LibMemAlloc.Verifier.Layout (Layout (..), Parameter (..), bindings, validateLayout)
import LibMemAlloc.Verifier.Protocol
import LibMemAlloc.Verifier.Symbolic (coverageJSON)

{-@ symbol :: Binding -> String @-}
{-@ layout :: Binding -> Layout @-}
{-@ mutable :: Binding -> [Int] @-}
{-@ contract :: Binding -> Contract @-}

data Binding = Binding
  { symbol :: String
  , layout :: Layout
  , mutable :: [Int]
  , contract :: Contract
  }
  deriving (Eq, Show)

{-@ identifier :: String -> Bool @-}
identifier :: String -> Bool
identifier [] = False
identifier (c : cs) = (isAlpha c || c == '_') && all (\x -> isAlphaNum x || x `elem` "_.") cs

{-@ parseBinding :: JSON -> Either String Binding @-}
parseBinding :: JSON -> Either String Binding
parseBinding json = do
  fields <-
    object ["schema", "target", "symbol", "parameters", "return", "mutable", "contract"] json
  schema <- field "schema" fields >>= string
  target <- field "target" fields >>= string
  unless
    (schema == "lma-translation/v1" && target == "x86_64-linux-gnu-lp64")
    (Left "unsupported translation version or target")
  name <- field "symbol" fields >>= string
  unless (identifier name && '.' `notElem` name) (Left "invalid symbol")
  params <- field "parameters" fields >>= array >>= mapM parameter
  result <- field "return" fields >>= string
  unless (result `elem` ["bool-int", "word"]) (Left "unsupported return type")
  let representation = Layout params (result == "bool-int") 4096
  validateLayout representation
  writes <- field "mutable" fields >>= array >>= mapM cell
  unless (all (`elem` map snd (bindings representation)) writes) (Left "unknown mutable cell")
  predicates <- field "contract" fields >>= object ["module", "pre", "post"]
  mdl <- field "module" predicates >>= string
  pre <- field "pre" predicates >>= string
  post <- field "post" predicates >>= string
  unless (all identifier [mdl, pre, post]) (Left "invalid Lean contract name")
  pure (Binding name representation writes (Contract mdl pre post))
 where
  cell value = do
    n <- natural value
    if n < 4096 then pure (fromInteger n) else Left "entry cell exceeds limit"
  parameter value = do
    pairs <- case value of JObject pairs -> pure pairs; _ -> Left "expected parameter object"
    kind <- field "kind" pairs >>= string
    case kind of
      "word" -> do
        fs <- object ["kind", "name", "cell"] value
        Scalar <$> (field "name" fs >>= string) <*> (field "cell" fs >>= cell)
      "object" -> do
        fs <- object ["kind", "name", "tag", "fields"] value
        name <- field "name" fs >>= string
        tag <- field "tag" fs >>= string
        members <- field "fields" fs >>= array >>= mapM member
        pure (Object name tag members)
      _ -> Left "unsupported parameter kind"
  member value = do
    fs <- object ["name", "cell"] value
    (,) <$> (field "name" fs >>= string) <*> (field "cell" fs >>= cell)

{-@
  produceGeneric :: String -> String -> String -> Either String (JSON, String, String, Program)
@-}
produceGeneric :: String -> String -> String -> Either String (JSON, String, String, Program)
produceGeneric identity bindingText ail = do
  unless
    (length identity == 64 && all (`elem` "0123456789abcdef") identity)
    (Left "invalid input identity")
  unless (length ail <= 4 * 1024 * 1024) (Left "AIL input exceeds limit")
  bindingJSON <- decode bindingText
  binding <- parseBinding bindingJSON
  let shape = layout binding
      objectIndices = [index | Object _ _ fields <- parameters shape, (_, index) <- fields]
      policy =
        Policy
          (map snd (bindings shape))
          objectIndices
          (mutable binding)
          [4096 .. 4351]
          (booleanReturn shape)
  program <- importFunction shape (symbol binding) ail
  machine <- analyzeWith policy Owned program
  let envelope =
        JObject
          [ ("schema", JString "lma-ir/v1")
          , ("semantics", JString "bounded-naturals-no-wrap/v1")
          , ("word_bits", JString "64")
          , ("program", programJSON program)
          ]
      certificate =
        JObject
          [ ("schema", JString "lma-generic-certificate/v1")
          , ("input_identity", JString identity)
          , ("translation", bindingJSON)
          , ("ir", envelope)
          , ("machine_analysis", machine)
          , ("coverage", coverageJSON program)
          ]
  pure
    ( certificate
    , expectedSource wordLimit (contract binding) program
    , proofSource (contract binding) program
    , program
    )

replayGeneric ::
  String -> String -> String -> String -> Either String (JSON, String, String, Program)
replayGeneric identity bindingText ail certificateText = do
  supplied <- decode certificateText
  result@(expected, _, _, _) <- produceGeneric identity bindingText ail
  if supplied == expected
    then pure result
    else Left "certificate does not match current translation"

{-@ evaluateGeneric :: String -> String -> String -> Either String JSON @-}
evaluateGeneric :: String -> String -> String -> Either String JSON
evaluateGeneric bindingText ail inputsText = do
  binding <- decode bindingText >>= parseBinding
  (_, _, _, program) <- produceGeneric (replicate 64 '0') bindingText ail
  values <- decode inputsText >>= array >>= mapM natural
  let cells = map snd (bindings (layout binding))
  unless (length values == length cells) (Left "incorrect input arity")
  (result, final) <- run wordLimit program (Map.fromList (zip cells values))
  pure
    ( JObject
        [ ("result", decimal result)
        ,
          ( "cells"
          , JArray
              [ JArray [decimal (toInteger cell), decimal (load final cell)]
              | cell <- cells
              ]
          )
        ]
    )

-- | Construct a kernel-checkable counterexample, never infer refutation from a
-- failed proof search. A bad witness makes elaboration fail, not REFUTED.

{-@ refuteGeneric :: String -> String -> String -> String -> Either String (String, String) @-}
refuteGeneric :: String -> String -> String -> String -> Either String (String, String)
refuteGeneric identity bindingText ail inputsText = do
  binding <- decode bindingText >>= parseBinding
  (_, expected, _, _) <- produceGeneric identity bindingText ail
  values <- decode inputsText >>= array >>= mapM natural
  let cells = map snd (bindings (layout binding))
      claim = contract binding
  unless
    ( length values == length cells
        && all (<= wordLimit) values
    )
    (Left "invalid witness inputs")
  let initial =
        foldr
          ( \(cell, value) rest ->
              "if cell = " ++ show cell ++ " then " ++ show value ++ " else " ++ rest
          )
          "0"
          (zip cells values)
      proof =
        unlines
          [ "import Expected"
          , "namespace Generated"
          , "set_option linter.unusedSimpArgs false"
          , "def initial : Allocator.IR.Store := fun cell => " ++ initial
          , "/-- Mathematical statement: the counterexample satisfies the entry contract. -/"
          , "theorem admitted : " ++ precondition claim ++ " initial := by"
          , "  simp [" ++ precondition claim ++ ", initial]"
          , "/-- Mathematical statement: this admitted execution violates the required contract. -/"
          , "theorem violates : ¬ (∃ r f, Allocator.IR.run 18446744073709551615"
          , "    Expected.program initial = some (r, f) ∧ "
              ++ postcondition claim
              ++ " initial r f) := by"
          , "  simp [Expected.program, Allocator.IR.run, Allocator.IR.eval, Allocator.IR.test,"
          , "    Allocator.IR.bounded, Allocator.IR.update, initial, " ++ postcondition claim ++ "]"
          , "/-- Mathematical statement: Expected.Claim is false, witnessed by initial. -/"
          , "theorem refuted : ¬ Expected.Claim := by"
          , "  intro verified"
          , "  exact violates (verified initial admitted)"
          , "end Generated"
          ]
  pure (expected, proof)

-- EOF


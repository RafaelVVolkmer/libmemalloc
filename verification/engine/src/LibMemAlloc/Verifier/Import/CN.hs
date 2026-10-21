-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

-- | Import the typed AIL tree printed by the pinned CN frontend. This adapter is
-- deliberately strict: an unknown node, type, lvalue or control transfer fails.
-- Source line numbers are diagnostic metadata and do not determine semantics.
module LibMemAlloc.Verifier.Import.CN (importFunction) where

import Data.Char (isSpace)
import Data.List (findIndex, isInfixOf, isPrefixOf, tails)
import qualified Data.Map.Strict as Map
import Data.Maybe (isNothing)
import LibMemAlloc.Verifier.IR
import LibMemAlloc.Verifier.Layout (
  Layout (..),
  Parameter (..),
  bindings,
  signature,
  validateLayout,
 )
import LibMemAlloc.Verifier.Protocol (JSON (JString), natural)

data Node = Node String [Node] deriving (Show)
data Statement = Assign Int Expr | If Cond [Statement] [Statement] | Exit Expr | Jump | Skip
  deriving (Show)
data CType = Int32 | ULong64 deriving (Eq, Show)
type Names = Map.Map String (Int, CType)

{-@ label :: Node -> String @-}
label :: Node -> String
label (Node name _) = name

{-@ children :: Node -> [Node] @-}
children :: Node -> [Node]
children (Node _ nodes) = nodes

{-@ trim :: String -> String @-}
trim :: String -> String
trim = reverse . dropWhile isSpace . reverse . dropWhile isSpace

-- Decorations include source spans and C-standard citations; neither is code.
{-@ undecorate :: String -> String @-}
undecorate :: String -> String
undecorate [] = []
undecorate ('<' : rest) = undecorate (drop 1 (dropWhile (/= '>') rest))
undecorate ('[' : rest) = undecorate (drop 1 (dropWhile (/= ']') rest))
undecorate (c : rest) = c : undecorate rest

{-@ row :: String -> Maybe (Int, String) @-}
row :: String -> Maybe (Int, String)
row line = do
  offset <- findIndex (\suffix -> "|-" `isPrefixOf` suffix || "`-" `isPrefixOf` suffix) (tails line)
  if all (`elem` " |`") (take offset line) && even offset
    then Just (offset `div` 2, trim (undecorate (drop (offset + 2) line)))
    else Nothing

{-@
  forest :: fuel:Nat -> Int -> [(Int, String)] -> Either String ([Node], [(Int, String)]) / [fuel]
@-}
forest :: Int -> Int -> [(Int, String)] -> Either String ([Node], [(Int, String)])
forest _ _ [] = Right ([], [])
forest fuel parent rows@((depth, name) : rest)
  | fuel <= 0 = Left "AIL parser budget exceeded"
  | depth <= parent = Right ([], rows)
  | depth /= parent + 1 = Left "malformed AIL indentation"
  | otherwise = do
      (nested, after) <- forest (fuel - 1) depth rest
      (siblings, remaining) <- forest (fuel - 1) parent after
      pure (Node name nested : siblings, remaining)

{-@ one :: String -> [a] -> Either String a @-}
one :: String -> [a] -> Either String a
one _ [value] = Right value
one context _ = Left ("expected one " ++ context)

{-@ tag :: String -> Node -> Bool @-}
tag :: String -> Node -> Bool
tag name node = label node == name || (name ++ " ") `isPrefixOf` label node

{-@ select :: String -> [Node] -> Either String Node @-}
select :: String -> [Node] -> Either String Node
select name = one name . filter (tag name)

{-@ lastWord :: Node -> Either String String @-}
lastWord :: Node -> Either String String
lastWord node = case words (label node) of
  [] -> Left "empty AIL node"
  values -> Right (last values)

{-@ importFunction :: Layout -> String -> String -> Either String Program @-}
importFunction :: Layout -> String -> String -> Either String Program
importFunction layout symbol source = do
  validateLayout layout
  let inputLines = joinSignature (lines source)
  if "AilSigma" `elem` inputLines then pure () else Left "missing CN AIL tree"
  let tree =
        takeWhile
          (/= "`-AilCNpredicates EMPTY")
          (drop 1 (dropWhile (/= "AilSigma") inputLines))
          ++ ["`-AilCNpredicates EMPTY"]
  if "`-AilCNpredicates EMPTY" `elem` inputLines && length tree <= 2048
    then pure ()
    else Left "unsupported or oversized AIL tree"
  rows <- mapM (maybe (Left "unrecognized AIL row") Right . row) tree
  (roots, remaining) <- forest 4096 (-1) rows
  if null remaining then pure () else Left "trailing AIL tree"
  mapM_ checkRoot roots
  definitions <- children <$> select "AilFunctionDefinitions" roots
  definition <-
    one "selected C body" [node | node <- definitions, lastWord node == Right symbol]
  selectedName <- lastWord definition
  if selectedName == symbol then pure () else Left "unexpected C body"
  declarations <- children <$> select "AilDeclarations" roots
  declaration <-
    one
      "selected C declaration"
      [node | node <- declarations, ("Decl_function " ++ symbol ++ " ") `isPrefixOf` label node]
  if ("'" ++ signature layout ++ "'") `isInfixOf` label declaration
    then pure ()
    else Left "unsupported C signature or scalar types"
  structures <- children <$> select "AilTagDefinitions" roots
  mapM_ (checkObject structures) (parameters layout)
  body <- select "AilSblock" (children definition)
  localBindings <- select "Bindings" (children body)
  locals <- mapM local (children localBindings)
  let entries = [(name, (index, ULong64)) | (name, index) <- bindings layout]
      localEntries =
        [ (name, (index, boolean))
        | ((name, boolean), index) <- zip locals [localBase layout ..]
        ]
      names = Map.fromList (entries ++ localEntries)
  if Map.size names == length entries + length localEntries && length locals <= 256
    then pure ()
    else Left "duplicate or excessive local bindings"
  statements <- mapM (statement 4096 names) (filter (not . tag "Bindings") (children body))
  let labels = [node | node <- children body, tag "AilSlabel" node]
  finalLabel <- one "terminal output label" labels
  if label finalLabel == "AilSlabel function_output"
    && case reverse (children body) of
      final : _ -> label final == label finalLabel
      [] -> False
    then pure ()
    else Left "only a terminal function_output label is supported"
  exit <- one "output return" (children finalLabel) >>= statement 4096 names
  case exit of
    Exit value -> fst <$> compile 4096 value statements
    _ -> Left "output label must return a scalar"
 where
  -- Join pretty-printer continuation lines without discarding tree nodes.
  joinSignature (a : b : rest)
    | "Decl_function " `isInfixOf` a && isNothing (row b) = joinSignature ((a ++ " " ++ b) : rest)
    | otherwise = a : joinSignature (b : rest)
  joinSignature rest = rest
  checkObject _ (Scalar _ _) = Right ()
  checkObject structures (Object _ name fields) = do
    structure <- one "bound structure" [node | node <- structures, lastWord node == Right name]
    if map label (children structure) == [field ++ " 'unsigned long' EMPTY" | (field, _) <- fields]
      then pure ()
      else Left "unsupported object layout"
  checkRoot node
    | tag "AilObjectDefinitions" node && label node /= "AilObjectDefinitions EMPTY" =
        Left "global objects are unsupported"
    | any
        (`tag` node)
        [ "AilTypedefAttributes"
        , "AilDeclarations"
        , "AilTagDefinitions"
        , "AilObjectDefinitions"
        , "AilFunctionDefinitions"
        , "AilStaticAssertions"
        , "AilCNpredicates"
        ] =
        Right ()
    | otherwise = Left ("unsupported AIL root: " ++ label node)
  local node = case words (label node) of
    [name, "automatic", "'signed", "int'"] -> Right (name, Int32)
    [name, "automatic", "'unsigned", "long'"] -> Right (name, ULong64)
    _ -> Left ("unsupported local type: " ++ label node)

{-@ cell :: Names -> Node -> Either String Int @-}
cell :: Names -> Node -> Either String Int
cell names node
  | tag "AilEident" node = lastWord node >>= lookupCell
  | tag "AilEmemberofptr" node = do
      pointer <- one "object pointer" (children node) >>= pointerName 2048
      field <- lastWord node
      lookupCell (pointer ++ "." ++ field)
  | otherwise = Left ("unsupported lvalue: " ++ label node)
 where
  lookupCell name = maybe (Left ("unknown scalar: " ++ name)) (Right . fst) (Map.lookup name names)
  {-@ pointerName :: fuel:Nat -> Node -> Either String String / [fuel] @-}
  pointerName :: Int -> Node -> Either String String
  pointerName fuel pointer
    | fuel <= 0 = Left "pointer expression budget exceeded"
    | tag "AilErvalue" pointer = one "pointer value" (children pointer) >>= pointerName (fuel - 1)
    | tag "AilEident" pointer = lastWord pointer
    | otherwise = Left "unsupported pointer expression"

{-@ expression :: Names -> Node -> Either String Expr @-}
expression :: Names -> Node -> Either String Expr
expression names node = snd <$> typedExpression 2048 names node

-- | Keep the C type through every intermediate expression. The destination of
-- an assignment cannot retroactively change the type of a signed addition.
-- Only unsigned-long arithmetic is admitted; nonnegative int literals and
-- boolean locals may undergo the usual conversion to unsigned long.

{-@ typedExpression :: fuel:Nat -> Names -> Node -> Either String (CType, Expr) / [fuel] @-}
typedExpression :: Int -> Names -> Node -> Either String (CType, Expr)
typedExpression fuel names node
  | fuel <= 0 = Left "expression budget exceeded"
  | tag "AilErvalue" node = one "rvalue" (children node) >>= typedExpression (fuel - 1) names
  | tag "AilEconst" node = do
      value <- lastWord node
      let (digits, suffix) = span (`elem` ['0' .. '9']) value
      if null digits || length digits > 20 || (case digits of '0' : _ : _ -> True; _ -> False)
        then Left "unsupported C constant"
        else do
          n <- natural (JString digits)
          kind <- case suffix of
            "" | n <= 2147483647 -> Right Int32
            "UL" | n <= 18446744073709551615 -> Right ULong64
            "ul" | n <= 18446744073709551615 -> Right ULong64
            _ -> Left "unsupported C constant type"
          pure (kind, Literal n)
  | tag "AilEident" node || tag "AilEmemberofptr" node = do
      index <- cell names node
      kind <- one "scalar type" [kind | (target, kind) <- Map.elems names, target == index]
      pure (kind, Read index)
  | tag "AilEbinary" node = do
      operation <- lastWord node
      constructor <- case operation of
        "'+'" -> Right Add
        "'-'" -> Right Sub
        "'%'" -> Right Mod
        _ -> Left ("unsupported arithmetic: " ++ operation)
      case children node of
        [left, right] -> do
          (leftType, a) <- typedExpression (fuel - 1) names left
          (rightType, b) <- typedExpression (fuel - 1) names right
          if leftType == ULong64 || rightType == ULong64
            then pure (ULong64, constructor a b)
            else Left "unsupported signed arithmetic: requires unsigned long operands"
        _ -> Left "invalid binary expression"
  | otherwise = Left ("unsupported expression: " ++ label node)

{-@ condition :: Names -> Node -> Either String Cond @-}
condition :: Names -> Node -> Either String Cond
condition names node
  | tag "AilEbinary" node = do
      operation <- lastWord node
      constructor <- case operation of
        "'>'" -> Right Gt
        "'=='" -> Right Equal
        _ -> Left ("unsupported branch comparison: " ++ operation)
      case children node of
        [left, right] -> constructor <$> expression names left <*> expression names right
        _ -> Left "invalid branch expression"
  | otherwise = Left "unsupported branch condition"

{-@ statement :: fuel:Nat -> Names -> Node -> Either String Statement / [fuel] @-}
statement :: Int -> Names -> Node -> Either String Statement
statement fuel names node
  | fuel <= 0 = Left "statement budget exceeded"
  | tag "AilSskip" node = Right Skip
  | label node == "AilSgoto function_output EMPTY" = Right Jump
  | tag "AilSreturn" node = Exit <$> (one "return expression" (children node) >>= expression names)
  | tag "AilSlabel" node = one "labeled statement" (children node) >>= statement (fuel - 1) names
  | tag "AilSmarker" node = do
      if all (\n -> tag "Attributes" n || label n == "AilSskip EMPTY") (children node)
        then pure Skip
        else Left "executable ghost marker is unsupported"
  | tag "AilSdeclaration" node = do
      declaration <- one "declaration" (children node)
      name <- lastWord declaration
      target <- maybe (Left "undeclared local") (Right . fst) (Map.lookup name names)
      value <- one "initializer" (children declaration) >>= expression names
      checkIntAssignment names target value
      pure (Assign target value)
  | tag "AilSexpr" node = do
      assignment <- one "assignment" (children node)
      case children assignment of
        [left, right] -> do
          target <- cell names left
          value <- expression names right
          if tag "AilEassign" assignment
            then do
              checkIntAssignment names target value
              pure (Assign target value)
            else
              if tag "AilEcompoundAssign" assignment
                && lastWord assignment == Right "'+'"
                && not (isBoolean names target)
                then pure (Assign target (Add (Read target) value))
                else Left "unsupported assignment"
        _ -> Left "invalid assignment"
  | tag "AilSif" node = case children node of
      [guardNode, yes, no] ->
        If
          <$> condition names guardNode
          <*> block (fuel - 1) names yes
          <*> block (fuel - 1) names no
      _ -> Left "invalid conditional"
  | otherwise = Left ("unsupported statement: " ++ label node)

{-@ isBoolean :: Names -> Int -> Bool @-}
isBoolean :: Names -> Int -> Bool
isBoolean names target = any (\(index, kind) -> index == target && kind == Int32) (Map.elems names)

{-@ checkIntAssignment :: Names -> Int -> Expr -> Either String () @-}
checkIntAssignment :: Names -> Int -> Expr -> Either String ()
checkIntAssignment names target value
  | not (isBoolean names target) = Right ()
  | value == Literal 0 || value == Literal 1 = Right ()
  | otherwise = Left "int temporary only admits boolean literals"

{-@ block :: fuel:Nat -> Names -> Node -> Either String [Statement] / [fuel] @-}
block :: Int -> Names -> Node -> Either String [Statement]
block fuel names node
  | fuel <= 0 = Left "block budget exceeded"
  | tag "AilSblock" node = do
      let bindingNodes = filter (tag "Bindings") (children node)
      if all ((== "Bindings EMPTY") . label) bindingNodes
        then pure ()
        else Left "nested local scope is unsupported"
      mapM (statement (fuel - 1) names) (filter (not . tag "Bindings") (children node))
  | otherwise = (: []) <$> statement (fuel - 1) names node

-- The budget counts all visited statements, including duplicated continuations.
-- Returning the unused budget prevents each branch from spending it again.
{-@
  compile :: fuel:Nat -> Expr -> [Statement]
    -> Either String (Program, {remaining:Nat | remaining < fuel}) / [fuel]
@-}
compile :: Int -> Expr -> [Statement] -> Either String (Program, Int)
compile _ _ [] = Left "C body falls through without a return"
compile fuel output (stmt : rest)
  | fuel <= 0 = Left "control flow budget exceeded"
  | otherwise = case stmt of
      Skip -> compile (fuel - 1) output rest
      Jump -> Right (Return output, fuel - 1)
      Exit value -> Right (Return value, fuel - 1)
      Assign target value -> do
        (next, remaining) <- compile (fuel - 1) output rest
        pure (Write target value next, remaining)
      If guardNode yes no -> do
        (yesProgram, afterYes) <- compile (fuel - 1) output (yes ++ rest)
        (noProgram, remaining) <- compile afterYes output (no ++ rest)
        pure (Branch guardNode yesProgram noProgram, remaining)

-- EOF


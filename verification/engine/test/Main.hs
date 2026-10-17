-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

module Main (main) where

import Control.Monad (unless)
import Data.Either (isLeft)
import Data.List (isInfixOf)
import qualified Data.Map.Strict as Map
import LibMemAlloc.Verifier.CMachine (Phase (..), Policy (..), analyzeWith)
import LibMemAlloc.Verifier.IR
import LibMemAlloc.Verifier.Import.CN (importFunction)
import LibMemAlloc.Verifier.Layout (Layout (..), Parameter (..), validateLayout)
import LibMemAlloc.Verifier.Protocol
import LibMemAlloc.Verifier.Symbolic (paths)
import LibMemAlloc.Verifier.Translation (produceGeneric, replayGeneric)
import System.Exit (die)

{-@ check :: String -> Bool -> IO () @-}
check :: String -> Bool -> IO ()
check name condition = unless condition (die ("FAILED: " ++ name))

-- | Fixtures must serialize successfully before testing their consumer.

{-@ serialize :: JSON -> IO String @-}
serialize :: JSON -> IO String
serialize = either die pure . encode

{-@ main :: IO () @-}
main :: IO ()
main = do
  let layout = Layout [] True 4096
      importAIL = importFunction layout
      initialStore a b c = Map.fromList [(0, a), (1, b), (2, c)]
      analyzeFrom = analyzeWith (Policy [0, 1, 2] [0, 1] [0] [4] True)
      analyze = analyzeFrom Owned
  mapM_
    (\input -> check ("invalid JSON " ++ take 60 input) (isLeft (decode input)))
    [ "{\"a\":\"1\",\"a\":\"2\"}"
    , "1"
    , "[1]"
    , "{} true"
    , "\"\\uD800\""
    , replicate 140 '[' ++ replicate 140 ']'
    , "[true,]"
    , "{\"key\":null,}"
    , "{\"key\" null}"
    , "[true false]"
    , "truefalse"
    , "\"unterminated"
    , "\"\\q\""
    , "\"\\u00GG\""
    , "{\"a\":null,\"\\u0061\":true}"
    , "\"raw\nnewline\""
    ]
  mapM_
    (check "noncanonical natural" . isLeft . natural . JString)
    ["-1", "01", "1.0", "", "１２"]
  let sample = JObject [("version", JString "1"), ("nested", JArray [JBool True, JNull])]
  check "protocol round trip" ((encode sample >>= decode) == Right sample)
  check
    "protocol whitespace"
    ( decode " \n { \"key\" : [ true , null ] } \t"
        == Right (JObject [("key", JArray [JBool True, JNull])])
    )
  check "protocol escaped ASCII" (decode "\"\\u007f\\b\\f\\/\"" == Right (JString "\DEL\b\f/"))
  check
    "protocol wide container"
    ((encode (JArray (replicate 1000 sample)) >>= decode) == Right (JArray (replicate 1000 sample)))
  let nested = foldr (\_ item -> JArray [item]) JNull ([1 .. 128] :: [Int])
  check "protocol nesting boundary" ((encode nested >>= decode) == Right nested)
  check
    "protocol excessive nesting"
    (isLeft (decode (replicate 129 '[' ++ "null" ++ replicate 129 ']')))
  check "protocol oversized output" (isLeft (encode (JString (replicate (4 * 1024 * 1024) 'a'))))
  check "protocol excessive output nesting" (isLeft (encode (JArray [nested])))
  check "protocol size boundary" (isLeft (decode (replicate (4 * 1024 * 1024 + 1) ' ')))
  let s = initialStore 4 8 5
  check "overflow rejected" (isLeft (eval 8 s (Add (Read 0) (Read 2))))
  check "underflow rejected" (isLeft (eval 8 s (Sub (Read 0) (Read 2))))
  check "division by zero rejected" (isLeft (eval 8 s (Mod (Read 1) (Literal 0))))
  check "negative literal rejected" (isLeft (eval 8 s (Literal (-1))))
  check "unknown IR rejected" (isLeft (parseProgram (JArray [JString "call"])))
  check "AIL is required" (isLeft (importAIL "f" "int f(void) { return 1; }"))
  let branch = Branch (Gt (Read 0) (Read 1)) (Return (Literal 0)) (Return (Literal 1))
  check "symbolic coverage retains both branches" (length (paths branch) == 2)
  check "IR round trip" (parseProgram (programJSON branch) == Right branch)
  check "uninitialized local" (isLeft (analyze (Return (Read 4))))
  check
    "uninitialized local in one branch"
    ( isLeft
        ( analyze
            (Branch (Equal (Read 2) (Literal 0)) (Return (Literal 0)) (Return (Read 4)))
        )
    )
  let access = Write 0 (Read 2) (Return (Literal 1))
  check "expired object write" (isLeft (analyzeFrom Expired access))
  check "borrowed object write" (isLeft (analyzeFrom Borrowed access))
  check "expired object read" (isLeft (analyzeFrom Expired branch))
  check "exclusive object write" (not (isLeft (analyze access)))
  check "capacity footprint" (isLeft (analyze (Write 1 (Literal 0) (Return (Literal 1)))))
  let identity = replicate 64 'a'
  mock <- readFile "test/fixtures/mock.ail"
  binding <- readFile "test/fixtures/scalar.json"
  (generic, expected, proof, _) <- either die pure (produceGeneric identity binding mock)
  genericText <- serialize generic
  check
    "generic proof has no reservation dependency"
    (not ("Reservation" `isInfixOf` (expected ++ proof)))
  check
    "generic replay"
    ( replayGeneric identity binding mock genericText
        == produceGeneric identity binding mock
    )
  check
    "generic stale identity"
    (isLeft (replayGeneric (replicate 64 'b') binding mock genericText))
  check
    "layout alias rejection"
    (isLeft (validateLayout (Layout [Scalar "a" 0, Scalar "b" 0] False 4)))
  check
    "layout duplicate parameter"
    (isLeft (validateLayout (Layout [Scalar "a" 0, Scalar "a" 1] False 4)))
  check
    "layout local overlap"
    (isLeft (validateLayout (Layout [Scalar "a" 4] False 4)))
  check "missing store cell is an error" (isLeft (eval 8 s (Read 3)))
  case generic of
    JObject fields ->
      mapM_
        ( \key -> do
            missingText <- serialize (JObject (filter ((/= key) . fst) fields))
            check
              ("generic omitted " ++ key)
              ( isLeft
                  ( replayGeneric
                      identity
                      binding
                      mock
                      missingText
                  )
              )
        )
        ["translation", "ir", "coverage", "machine_analysis"]
    _ -> die "generic certificate must be an object"
  putStrLn "engine parser, arithmetic, generic translation and path controls passed"

-- EOF


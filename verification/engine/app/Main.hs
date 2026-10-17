-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

-- The pinned refinement plugin resolves imported measures through visible types.
module Main (main, Expr, Cond, Program, exprSize, programSize) where

import Control.Monad (when)
import LibMemAlloc.Verifier.IR (Cond, Expr, Program, exprSize, programSize)
import LibMemAlloc.Verifier.Protocol (encode)
import LibMemAlloc.Verifier.Translation (
  evaluateGeneric,
  produceGeneric,
  refuteGeneric,
  replayGeneric,
 )
import System.Directory (createDirectoryIfMissing)
import System.Environment (getArgs)
import System.Exit (die)
import System.FilePath ((</>))
import System.IO (IOMode (ReadMode), hFileSize, hGetContents, withFile)

{-@ boundedRead :: FilePath -> IO String @-}
boundedRead :: FilePath -> IO String
boundedRead path = withFile path ReadMode $ \handle -> do
  size <- hFileSize handle
  when (size > 4 * 1024 * 1024) (die "input exceeds 4 MiB")
  bytes <- hGetContents handle
  length bytes `seq` pure bytes

{-@ usage :: IO () @-}
usage :: IO ()
usage =
  die
    "usage: libmemalloc-verifier COMMAND ARGS; commands: refute-generic, evaluate-generic, produce-generic, replay-generic"

{-@ runRefuteGeneric :: [String] -> IO () @-}
runRefuteGeneric :: [String] -> IO ()
runRefuteGeneric arguments = case arguments of
  [identity, bindingPath, ailPath, inputsPath, output] -> do
    bindingText <- boundedRead bindingPath
    ailText <- boundedRead ailPath
    inputsText <- boundedRead inputsPath
    case refuteGeneric identity bindingText ailText inputsText of
      Left failure -> die ("refutation incomplete: " ++ failure)
      Right (expected, proof) -> do
        createDirectoryIfMissing False output
        writeFile (output </> "Expected.lean") expected
        writeFile (output </> "Generated.lean") proof
  _ -> usage

{-@ runEvaluateGeneric :: [String] -> IO () @-}
runEvaluateGeneric :: [String] -> IO ()
runEvaluateGeneric arguments = case arguments of
  [bindingPath, ailPath, inputsPath] -> do
    bindingText <- boundedRead bindingPath
    ailText <- boundedRead ailPath
    inputsText <- boundedRead inputsPath
    either die putStrLn (evaluateGeneric bindingText ailText inputsText >>= encode)
  _ -> usage

{-@ runProduceGeneric :: [String] -> IO () @-}
runProduceGeneric :: [String] -> IO ()
runProduceGeneric arguments = case arguments of
  [identity, bindingPath, ailPath, output] -> do
    bindingText <- boundedRead bindingPath
    ailText <- boundedRead ailPath
    case produceGeneric identity bindingText ailText of
      Left failure -> die ("verification incomplete: " ++ failure)
      Right (cert, expected, proof, _) -> do
        certificate <- either die pure (encode cert)
        createDirectoryIfMissing False output
        writeFile (output </> "certificate.json") (certificate ++ "\n")
        writeFile (output </> "Expected.lean") expected
        writeFile (output </> "Generated.lean") proof
  _ -> usage

{-@ runReplayGeneric :: [String] -> IO () @-}
runReplayGeneric :: [String] -> IO ()
runReplayGeneric arguments = case arguments of
  [identity, bindingPath, ailPath, certPath, output] -> do
    bindingText <- boundedRead bindingPath
    ailText <- boundedRead ailPath
    certificateText <- boundedRead certPath
    case replayGeneric identity bindingText ailText certificateText of
      Left failure -> die ("certificate rejected: " ++ failure)
      Right (_, expected, proof, _) -> do
        createDirectoryIfMissing False output
        writeFile (output </> "Expected.lean") expected
        writeFile (output </> "Generated.lean") proof
  _ -> usage

{-@ main :: IO () @-}
main :: IO ()
main = do
  arguments <- getArgs
  case arguments of
    command : rest ->
      case lookup command handlers of
        Just handler -> handler rest
        Nothing -> usage
    [] -> usage
 where
  handlers =
    [ ("refute-generic", runRefuteGeneric)
    , ("evaluate-generic", runEvaluateGeneric)
    , ("produce-generic", runProduceGeneric)
    , ("replay-generic", runReplayGeneric)
    ]

-- EOF


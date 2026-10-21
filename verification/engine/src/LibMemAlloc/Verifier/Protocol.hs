-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

-- | A strict, bounded JSON subset. Protocol numbers use canonical decimal strings.
-- Duplicate object keys, numeric literals and unknown fields are rejected.
module LibMemAlloc.Verifier.Protocol (
  JSON (..),
  decode,
  encode,
  object,
  field,
  string,
  array,
  natural,
  decimal,
) where

import Data.Char (chr, isSpace, ord)
import Data.List (intercalate, nub, sort)

data JSON = JObject [(String, JSON)] | JArray [JSON] | JString String | JBool Bool | JNull
  deriving (Eq, Show)

-- | Parse one complete document with bounded size and nesting. Fuel bounds
-- each recursive parser independently of any inferred consumption property.

{-@ decode :: String -> Either String JSON @-}
decode :: String -> Either String JSON
decode source
  | length source > 4 * 1024 * 1024 = Left "protocol input exceeds 4 MiB"
  | otherwise = do
      (result, rest) <- value (2 * length source + 2) 129 source
      if all isSpace rest then Right result else Left "trailing protocol input"

{-@ value :: fuel:Nat -> depth:Nat -> String -> Either String (JSON, String) / [fuel] @-}
value :: Int -> Int -> String -> Either String (JSON, String)
value fuel depth source
  | fuel <= 0 || depth <= 0 = Left "protocol nesting or parser budget exceeded"
  | otherwise = case dropWhile isSpace source of
      '\"' : rest -> do
        (text, after) <- quoted rest
        Right (JString text, after)
      't' : 'r' : 'u' : 'e' : rest -> Right (JBool True, rest)
      'f' : 'a' : 'l' : 's' : 'e' : rest -> Right (JBool False, rest)
      'n' : 'u' : 'l' : 'l' : rest -> Right (JNull, rest)
      '[' : rest -> do
        (entries, after) <- items (fuel - 1) ']' (value (fuel - 1) (depth - 1)) rest
        Right (JArray entries, after)
      '{' : rest -> do
        (entries, after) <- items (fuel - 1) '}' (pair (value (fuel - 1) (depth - 1))) rest
        if length (map fst entries) == length (nub (map fst entries))
          then Right (JObject entries, after)
          else Left "duplicate protocol key"
      _ -> Left "invalid protocol JSON value"

{-@ pair :: (String -> Either String (JSON, String)) -> String
         -> Either String ((String, JSON), String) @-}
pair :: (String -> Either String (JSON, String)) -> String -> Either String ((String, JSON), String)
pair parseValue source = case dropWhile isSpace source of
  '\"' : rest -> do
    (key, afterKey) <- quoted rest
    case dropWhile isSpace afterKey of
      ':' : afterColon -> do
        (item, after) <- parseValue afterColon
        Right ((key, item), after)
      _ -> Left "missing protocol colon"
  _ -> Left "expected protocol object key"

{-@ items :: fuel:Nat -> Char -> (String -> Either String (a, String))
          -> String -> Either String ([a], String) / [fuel] @-}
items ::
  Int -> Char -> (String -> Either String (a, String)) -> String -> Either String ([a], String)
items fuel closing parseItem source = case dropWhile isSpace source of
  c : rest | c == closing -> Right ([], rest)
  rest -> nonemptyItems fuel closing parseItem rest

{-@ nonemptyItems :: fuel:Nat -> Char -> (String -> Either String (a, String))
                  -> String -> Either String ([a], String) / [fuel] @-}
nonemptyItems ::
  Int -> Char -> (String -> Either String (a, String)) -> String -> Either String ([a], String)
nonemptyItems fuel closing parseItem source
  | fuel <= 0 = Left "protocol parser budget exceeded"
  | otherwise = do
      (item, rest) <- parseItem source
      case dropWhile isSpace rest of
        c : after | c == closing -> Right ([item], after)
        ',' : after -> do
          (more, remaining) <- nonemptyItems (fuel - 1) closing parseItem after
          Right (item : more, remaining)
        _ -> Left "missing protocol delimiter"

{-@ quoted :: String -> Either String (String, String) @-}
quoted :: String -> Either String (String, String)
quoted [] = Left "unterminated protocol string"
quoted ('\"' : rest) = Right ([], rest)
quoted ('\\' : 'u' : a : b : c : d : rest)
  | all (`elem` ("0123456789abcdefABCDEF" :: String)) [a, b, c, d] =
      let n = foldl (\x digit -> x * 16 + hex digit) 0 [a, b, c, d]
       in if 0 <= n && n < 128
            then do
              (text, after) <- quoted rest
              Right (chr n : text, after)
            else Left "unsupported protocol Unicode escape"
quoted ('\\' : escape : rest) = do
  c <- case escape of
    '\"' -> Right '\"'
    '\\' -> Right '\\'
    '/' -> Right '/'
    'n' -> Right '\n'
    'r' -> Right '\r'
    't' -> Right '\t'
    'b' -> Right '\b'
    'f' -> Right '\f'
    _ -> Left "unsupported protocol escape"
  (text, after) <- quoted rest
  Right (c : text, after)
quoted (c : rest)
  | c /= '\\' && ord c >= 32 = do
      (text, after) <- quoted rest
      Right (c : text, after)
  | otherwise = Left "invalid protocol string character"

{-@ hex :: Char -> Int @-}
hex :: Char -> Int
hex c
  | c `elem` ['0' .. '9'] = ord c - ord '0'
  | c >= 'a' && c <= 'f' = 10 + ord c - ord 'a'
  | otherwise = 10 + ord c - ord 'A'

-- | Refuse oversized or deeply nested output instead of emitting a truncated
-- certificate. Encoding and decoding share the same protocol limits.

{-@ encode :: JSON -> Either String String @-}
encode :: JSON -> Either String String
encode json = do
  text <- encodeValue 129 json
  if length text <= 4 * 1024 * 1024
    then Right text
    else Left "protocol output exceeds 4 MiB"

{-@ encodeValue :: fuel:Nat -> JSON -> Either String String / [fuel] @-}
encodeValue :: Int -> JSON -> Either String String
encodeValue fuel json
  | fuel <= 0 = Left "protocol output nesting exceeded"
  | otherwise = case json of
      JObject entries -> do
        parts <-
          mapM
            ( \(key, item) -> do
                text <- encodeValue (fuel - 1) item
                Right (quote key ++ ":" ++ text)
            )
            entries
        Right ("{" ++ intercalate "," parts ++ "}")
      JArray entries -> do
        parts <- mapM (encodeValue (fuel - 1)) entries
        Right ("[" ++ intercalate "," parts ++ "]")
      JString text -> Right (quote text)
      JBool True -> Right "true"
      JBool False -> Right "false"
      JNull -> Right "null"

{-@ quote :: String -> String @-}
quote :: String -> String
quote text = '"' : concatMap escape text ++ "\""
 where
  escape '"' = "\\\""
  escape '\\' = "\\\\"
  escape '\n' = "\\n"
  escape '\r' = "\\r"
  escape '\t' = "\\t"
  escape c | ord c < 32 = "\\u00" ++ [digit (ord c `div` 16), digit (ord c `mod` 16)]
  escape c = [c]
  digit n = case drop n "0123456789abcdef" of
    c : _ -> c
    [] -> 'f'

{-@ object :: [String] -> JSON -> Either String [(String, JSON)] @-}
object :: [String] -> JSON -> Either String [(String, JSON)]
object keys (JObject fields)
  | sort keys == sort (map fst fields) = Right fields
  | otherwise = Left "missing or unknown object field"
object _ _ = Left "expected object"

{-@ field :: String -> [(String, JSON)] -> Either String JSON @-}
field :: String -> [(String, JSON)] -> Either String JSON
field key fields = maybe (Left ("missing field: " ++ key)) Right (lookup key fields)

{-@ string :: JSON -> Either String String @-}
string :: JSON -> Either String String
string (JString result) = Right result
string _ = Left "expected string"

{-@ array :: JSON -> Either String [JSON] @-}
array :: JSON -> Either String [JSON]
array (JArray values) = Right values
array _ = Left "expected array"

-- | Mathematical statement: ∀ j ∈ JSON, natural(j) = Right n ⇒ n ∈ ℤ ∧ n ≥ 0.

{-@ natural :: JSON -> Either String {n:Integer | 0 <= n} @-}
natural :: JSON -> Either String Integer
natural (JString text@(first : rest))
  | length text <= 128
      && all (`elem` ['0' .. '9']) text
      && (null rest || first /= '0') =
      Right (foldl (\n c -> 10 * n + decimalDigit c) 0 text)
natural _ = Left "expected canonical nonnegative decimal string"

-- | Mathematical statement: ∀ c ∈ Char, 0 ≤ decimalDigit(c) ≤ 9;
-- for ASCII digits c, decimalDigit(c) = ord(c) − ord('0').

{-@ decimalDigit :: Char -> {n:Integer | 0 <= n && n <= 9} @-}
decimalDigit :: Char -> Integer
decimalDigit c
  | n >= 0 && n <= 9 = n
  | otherwise = 0
 where
  n = toInteger (ord c - ord '0')

{-@ decimal :: Integer -> JSON @-}
decimal :: Integer -> JSON
decimal = JString . show

-- EOF


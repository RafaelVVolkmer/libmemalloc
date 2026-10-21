-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Check mathematical comment placement; Lean still checks each proposition.
-- @return table: source-policy operations.
local function MATH_COMMENTS_loadModule()
   --- Skip a nested Lean block comment, rejecting a truncated input.
   -- @param source string: source bytes.
   -- @param offset number: opening delimiter position.
   -- @return number: first position after the comment.
   local function skipBlock(source, offset)
      local depth = 1
      offset = offset + 2
      while depth > 0 and offset <= #source do
         local pair = source:sub(offset, offset + 1)
         if pair == "/-" then
            depth, offset = depth + 1, offset + 2
         elseif pair == "-/" then
            depth, offset = depth - 1, offset + 2
         else
            offset = offset + 1
         end
      end
      assert(depth == 0, "unterminated Lean comment")
      return offset
   end

   --- Skip one string while respecting escaped characters.
   -- @param source string: source bytes.
   -- @param offset number: opening quote position.
   -- @return number: first position after the string.
   local function skipString(source, offset)
      offset = offset + 1
      while offset <= #source do
         local char = source:sub(offset, offset)
         offset = offset + (char == "\\" and 2 or 1)
         if char == '"' then
            break
         end
      end
      return offset
   end

   --- Find the token before a balanced declaration attribute.
   -- @param stream table: token sequence.
   -- @param previous number: closing bracket position.
   -- @return number: position before the opening bracket.
   local function skipAttribute(stream, previous)
      local depth = 1
      previous = previous - 1
      while previous > 0 and depth > 0 do
         local value = stream[previous].value
         depth = depth + (value == "]" and 1 or value == "[" and -1 or 0)
         previous = previous - 1
      end
      return previous
   end

   --- Find the comment preceding declaration modifiers and attributes.
   -- @param stream table: token sequence.
   -- @param previous number: token before the declaration.
   -- @return number: preceding comment or code token position.
   local function preceding(stream, previous)
      local modifiers = {
         private = true,
         protected = true,
         noncomputable = true,
         ["·"] = true,
      }
      while previous > 0 do
         local value = stream[previous].value
         if modifiers[value] then
            previous = previous - 1
         elseif value == "]" then
            previous = skipAttribute(stream, previous)
            if previous > 0 and stream[previous].value == "@" then
               previous = previous - 1
            else
               break
            end
         else
            break
         end
      end
      return previous
   end

   --- Read the permitted documentation immediately before a declaration.
   -- @param stream table: token sequence.
   -- @param previous number: preceding token position.
   -- @param declaration string: declaration keyword.
   -- @return string: comment text, or an empty string.
   local function documentation(stream, previous, declaration)
      local kind = previous > 0 and stream[previous].kind
      if kind == "doc" then
         return stream[previous].value
      end
      local comment = ""
      if kind == "line" and declaration ~= "theorem" then
         while previous > 0 and stream[previous].kind == "line" do
            comment = stream[previous].value .. "\n" .. comment
            previous = previous - 1
         end
      end
      return comment
   end

   --- Skip one identifier or UTF-8 code character.
   -- @param source string: source bytes.
   -- @param offset number: token start.
   -- @return number: next token position.
   local function skipCode(source, offset)
      local word = source:match("^[%a_][%w_']*", offset)
      return word and offset + #word
         or (utf8.offset(source, 2, offset) or #source + 1)
   end

   --- Tokenize Lean comments, strings and identifiers without interpreting
   -- proofs.
   -- @param source string: source bytes.
   -- @return table: tokens retaining comment kind and source line.
   local function tokens(source)
      local result, offset, line = {}, 1, 1
      while offset <= #source do
         local start, kind = offset, "code"
         local pair = source:sub(offset, offset + 1)
         if pair == "--" then
            kind = "line"
            offset = source:find("\n", offset, true) or (#source + 1)
         elseif pair == "/-" then
            kind = source:sub(offset, offset + 2) == "/--" and "doc" or "block"
            offset = skipBlock(source, offset)
         elseif source:sub(offset, offset) == '"' then
            kind, offset = "string", skipString(source, offset)
         else
            offset = skipCode(source, offset)
         end
         local value = source:sub(start, offset - 1)
         if not value:match("^%s+$") then
            result[#result + 1] = { value = value, kind = kind, line = line }
         end
         local _, newlines = value:gsub("\n", "")
         line = line + newlines
      end
      return result
   end

   --- Require a nearby mathematical statement for each theorem and local lemma.
   -- @param source string: owned or generated Lean source.
   -- @param path string: diagnostic source name.
   -- @return number: number of documented proof declarations.
   local function checkLean(source, path)
      local stream, count = tokens(source), 0
      for index, token in ipairs(stream) do
         if
            token.kind == "code"
            and (
               token.value == "theorem"
               or token.value == "have"
               or token.value == "example"
            )
         then
            local previous = preceding(stream, index - 1)
            local comment = documentation(stream, previous, token.value)
            local statement = comment:match("Mathematical statement:%s*(.+)")
            assert(
               statement and statement:gsub("%-%/", ""):match("%S"),
               path
                  .. ":"
                  .. token.line
                  .. ": missing mathematical statement before "
                  .. token.value
            )
            count = count + 1
         end
      end
      return count
   end
   return { lean = checkLean }
end

return MATH_COMMENTS_loadModule()

-- EOF


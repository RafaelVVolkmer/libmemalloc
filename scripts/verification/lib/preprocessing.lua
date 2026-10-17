-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Preserve native preprocessing while admitting only scalar-irrelevant
-- metadata.
-- @return table: compiler arguments and frontend normalization.
local function PREPROCESSING_loadModule()
   --- Use native predefined macros and the declared C99 source profile.
   -- @param source string: translation unit path.
   -- @return table: literal compiler arguments.
   local function command(source)
      return {
         "cc",
         "-std=c99",
         "-x",
         "c",
         "-E",
         "-P",
         "-nostdinc",
         "-Icore",
         source,
      }
   end

   --- Find the end of one token without interpreting quoted contents.
   -- @param source string: preprocessed C text.
   -- @param position number: first byte of the token.
   -- @return number: first byte after the token.
   local function tokenEnd(source, position)
      local character = source:sub(position, position)
      if character == '"' or character == "'" then
         position = position + 1
         while
            position <= #source
            and source:sub(position, position) ~= character
         do
            position = position
               + (source:sub(position, position) == "\\" and 2 or 1)
         end
         assert(position <= #source, "unterminated literal")
         position = position + 1
      elseif character:match("[%w_]") then
         position = source:find("[^%w_]", position) or (#source + 1)
      else
         position = position + 1
      end
      return position
   end

   --- Tokenize without interpreting text inside comments or quoted literals.
   -- @param source string: preprocessed C text.
   -- @return table: tokens with inclusive byte positions.
   local function tokens(source)
      local result, position = {}, 1
      while position <= #source do
         local start, character = position, source:sub(position, position)
         local pair = source:sub(position, position + 1)
         if character:match("%s") then
            position = position + 1
         elseif pair == "/*" then
            position = assert(
               source:find("*/", position + 2, true),
               "unterminated comment"
            ) + 2
         elseif pair == "//" then
            position = source:find("\n", position + 2, true) or (#source + 1)
         else
            position = tokenEnd(source, position)
            result[#result + 1] = {
               text = source:sub(start, position - 1),
               first = start,
               last = position - 1,
            }
         end
      end
      return result
   end

   --- Remove only default symbol visibility, which has no scalar-body
   -- semantics.
   -- @param source string: native compiler preprocessing output.
   -- @return string, number: frontend input and number of removed attributes.
   local function normalize(source)
      local stream = tokens(source)
      local allowed = {
         "__attribute__",
         "(",
         "(",
         "visibility",
         "(",
         '"default"',
         ")",
         ")",
         ")",
      }
      local pieces, cursor, removed, index = {}, 1, 0, 1
      while index <= #stream do
         if stream[index].text == "__attribute__" then
            for offset, expected in ipairs(allowed) do
               local token = stream[index + offset - 1]
               assert(
                  token and token.text == expected,
                  "unsupported GNU attribute in scalar frontend"
               )
            end
            local first, last =
               stream[index].first, stream[index + #allowed - 1].last
            pieces[#pieces + 1] = source:sub(cursor, first - 1)
            pieces[#pieces + 1] = source:sub(first, last):gsub("[^\n]", " ")
            cursor, removed, index = last + 1, removed + 1, index + #allowed
         else
            index = index + 1
         end
      end
      pieces[#pieces + 1] = source:sub(cursor)
      return table.concat(pieces), removed
   end
   return { command = command, normalize = normalize }
end

return PREPROCESSING_loadModule()

-- EOF


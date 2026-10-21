-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Locate C/C++ comments without interpreting comment markers inside literals.
-- Part of Doxygen generation and authored-document validation.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_documentation_lib_c_comments_loadModule()
   local C_COMMENTS_RAW_DELIMITER_MAX = 16
   local C_COMMENTS_RAW_OPENING_BYTES = 3

   local exports = {}

   --- Skip a quoted literal, including escaped delimiters and line endings.
   -- @return integer: first byte after the literal, or beyond an unfinished
   -- one.
   -- @param source string: source supplied to this operation.
   -- @param index number: one-based position in the current sequence.
   -- @param delimiter any: delimiter supplied to this operation.
   local function c_comments_skipQuoted(source, index, delimiter)
      local closed = false

      index = index + 1
      while index <= #source and not closed do
         local current = source:sub(index, index)

         index = index + 1
         if current == "\\" then
            index = index + 1
         else
            closed = current == delimiter
         end
      end

      return index
   end

   --- Find the first byte after a C++ raw string with a valid delimiter.
   -- @return integer|nil: end position, or nil when this is not a raw string.
   -- @param source string: source supplied to this operation.
   -- @param index number: one-based position in the current sequence.
   local function c_comments_skipRaw(source, index)
      local delimiter = source
         :sub(
            index,
            index
               + C_COMMENTS_RAW_DELIMITER_MAX
               + C_COMMENTS_RAW_OPENING_BYTES
               - 1
         )
         :match('^R"([^%s()\\]*)%(')
      local next_index

      if delimiter and #delimiter <= C_COMMENTS_RAW_DELIMITER_MAX then
         local _, finish = source:find(
            ")" .. delimiter .. '"',
            index + C_COMMENTS_RAW_OPENING_BYTES + #delimiter,
            true
         )

         next_index = finish and finish + 1 or #source + 1
      end

      return next_index
   end

   --- Include continued line comments without looping past end of input.
   -- @param source string: source supplied to this operation.
   -- @param index number: one-based position in the current sequence.
   -- @return any: include continued line comments without looping past end of
   -- input.
   local function c_comments_lineEnd(source, index)
      local finish = source:find("\n", index + 2, true) or #source + 1

      while finish <= #source and source:sub(finish - 1, finish - 1) == "\\" do
         finish = source:find("\n", finish + 1, true) or #source + 1
      end

      return finish
   end

   --- Advance one lexical token and record only complete comments.
   -- Malformed comments remain the compiler or Doxygen's responsibility.
   -- @param source string: source supplied to this operation.
   -- @param index number: one-based position in the current sequence.
   -- @param ranges table: ranges supplied to this operation.
   -- @return any: advance one lexical token and record only complete comments.
   local function c_comments_advance(source, index, ranges)
      local pair = source:sub(index, index + 1)
      local character = source:sub(index, index)
      local raw_end = c_comments_skipRaw(source, index)
      local next_index = index + 1

      if raw_end then
         next_index = raw_end
      elseif character == '"' or character == "'" then
         next_index = c_comments_skipQuoted(source, index, character)
      elseif pair == "/*" then
         local _, finish = source:find("*/", index + 2, true)

         next_index = #source + 1
         if finish then
            ranges[#ranges + 1] = { index, finish, "block" }
            next_index = finish + 1
         end
      elseif pair == "//" then
         next_index = c_comments_lineEnd(source, index)
         ranges[#ranges + 1] = { index, next_index - 1, "line" }
      end

      return next_index
   end

   --- Return byte ranges of block and line comments in source order.
   -- @param source any: source value inspected by this operation.
   -- @return table: byte ranges of block and line comments in source order.
   local function DOCUMENTATION_C_COMMENTS_ranges(source)
      local ranges, index = {}, 1

      while index <= #source do
         index = c_comments_advance(source, index, ranges)
      end

      return ranges
   end

   exports.ranges = DOCUMENTATION_C_COMMENTS_ranges

   --- Remove only decorative documentation, preserving source line numbers.
   -- @param source string: source supplied to this operation.
   -- @return any: remove only decorative documentation, preserving source line
   -- numbers.
   local function DOCUMENTATION_C_COMMENTS_doxygen(source)
      local result, previous = {}, 1

      for _, range in ipairs(exports.ranges(source)) do
         local start, finish = range[1], range[2]
         local comment = source:sub(start, finish)

         result[#result + 1] = source:sub(previous, start - 1)
         if comment:match("^/%*%*%s*=+\n") then
            local title = comment:match("\n%s*%*%s*([^\n]+)")

            if
               title
               and title:match("^[A-Z][A-Z %%-]+$")
               and title:find(" - ", 1, true)
               and not comment:find("[@\\][%a{}]")
            then
               comment = comment:gsub("[^\r\n]", " ")
            else
               comment = comment:gsub("^(/%*%*)[ \t]*=+[ \t]*", "%1")
               comment = comment:gsub("([ \t]*%*)[ \t]*=+[ \t]*%*/$", "%1/")
            end
         end

         result[#result + 1] = comment
         previous = finish + 1
      end

      result[#result + 1] = source:sub(previous)

      return table.concat(result)
   end

   exports.doxygen = DOCUMENTATION_C_COMMENTS_doxygen

   return exports
end

return scripts_documentation_lib_c_comments_loadModule()

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer
-- <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Generate tool-specific spelling adapters from the categorized vocabulary.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tools_lint_spell_dictionary_generate_main()
   local check_only = arg[1] == "--check"

   if arg[1] and not check_only then
      io.stderr:write(
         "usage: lua tools/lint/spell/dictionary/generate.lua [--check]\n"
      )
      os.exit(2)
   end

   local script_path = arg[0]:gsub("\\", "/")
   local spell_root = script_path:match("^(.*)/dictionary/generate%.lua$")

   if not spell_root then
      io.stderr:write(
         "error: run the generator by its repository-relative path\n"
      )
      os.exit(2)
   end

   local dictionary_root = spell_root .. "/dictionary"
   local categories = {
      "acronyms.txt",
      "c-api.txt",
      "c-terms.txt",
      "project.txt",
      "proper-names.txt",
   }

   --- Read an entire file as binary data.
   -- @param path string: Path to the file.
   -- @return string or nil: File contents when successful.
   -- @return string or nil: Error message when reading fails.

   --- Read file bytes and reject open failures.
   -- @param path string: filesystem path selected by the caller.
   -- @return any, any: file bytes and reject open failures.
   local function read_file(path)
      local file, error_message = io.open(path, "rb")

      if not file then
         return nil, error_message
      end

      local content = file:read("*a")

      file:close()

      return content, nil
   end

   --- Write an entire file as binary data.
   -- @param path string: Path to the file.
   -- @param content string: Complete file contents.
   -- @return boolean or nil: True when successful.
   -- @return string or nil: Error message when writing fails.

   --- Write generated dictionary bytes and verify the write.
   -- @param path string: filesystem path selected by the caller.
   -- @param content string: input bytes to process.
   -- @return boolean|nil, any: write generated dictionary bytes and verify the
   -- write.
   local function write_file(path, content)
      local file, error_message = io.open(path, "wb")

      if not file then
         return nil, error_message
      end

      file:write(content)
      file:close()

      return true, nil
   end

   --- Sort words in case-insensitive lexical order.
   -- @param words table: Mutable list of words.

   --- Sort and deduplicate dictionary entries deterministically.
   -- @param words any: words supplied to this operation.
   -- @return nil: no values.
   local function sort_words(words)
      --- Order case-insensitively, then use original bytes to break ties.
      -- @param left string: left supplied to this operation.
      -- @param right string: right supplied to this operation.
      -- @return boolean: order case-insensitively, then use original bytes to
      -- break ties.
      table.sort(words, function(left, right)
         local lower_left = left:lower()
         local lower_right = right:lower()

         if lower_left == lower_right then
            return left < right
         end

         return lower_left < lower_right
      end)
   end

   local words = {}
   local acronyms = {}
   local seen = {}

   --- Validate and merge one authored dictionary category.
   -- @param category any: category supplied to this operation.
   -- @return nil: no values.
   local function dictionary_collectCategory(category)
      local path = dictionary_root .. "/" .. category
      local content, error_message = read_file(path)

      if not content then
         error("cannot read " .. path .. ": " .. error_message)
      end

      if content:sub(-1) ~= "\n" then
         error(path .. ": missing final newline")
      end

      local category_words = {}

      for line in content:gmatch("([^\r\n]+)") do
         if line:match("^%s") or line:match("%s$") then
            error(
               path
                  .. ": surrounding whitespace in entry "
                  .. string.format("%q", line)
            )
         end

         if seen[line] then
            error(
               path
                  .. ": duplicate entry "
                  .. string.format("%q", line)
                  .. " (also in "
                  .. seen[line]
                  .. ")"
            )
         end

         seen[line] = category
         table.insert(category_words, line)
         table.insert(words, line)
      end

      local sorted_category_words = {}

      for index, word in ipairs(category_words) do
         sorted_category_words[index] = word
      end

      sort_words(sorted_category_words)

      local expected = table.concat(sorted_category_words, "\n") .. "\n"

      if content ~= expected then
         error(path .. ": entries must use case-insensitive lexical order")
      end

      if category == "acronyms.txt" then
         acronyms = category_words
      end
   end

   for _, category in ipairs(categories) do
      dictionary_collectCategory(category)
   end

   sort_words(words)
   sort_words(acronyms)

   local stale = false

   --- Write generated content or check that the current file matches it.
   -- @param path string: Generated file path.
   -- @param content string: Expected complete file contents.

   --- Emit the selected dictionary section.
   -- @param path string: filesystem path selected by the caller.
   -- @param content string: input bytes to process.
   -- @return nil: no values.
   local function emit(path, content)
      if check_only then
         local current, error_message = read_file(path)

         if not current then
            error("cannot read " .. path .. ": " .. error_message)
         end

         if current ~= content then
            io.stderr:write(
               "error: generated spelling adapter is stale: " .. path .. "\n"
            )
            stale = true
         end

         return
      end

      local written, error_message = write_file(path, content)

      if not written then
         error("cannot write " .. path .. ": " .. error_message)
      end
   end

   --- Replace a marker-delimited generated section in a file.
   -- @param path string: File containing the generated section.
   -- @param start_marker string: Opening marker retained in the file.
   -- @param end_marker string: Closing marker retained in the file.
   -- @param generated_lines table: Lines inserted between the markers.

   --- Replace only the marked generated dictionary section.
   -- @param path string: filesystem path selected by the caller.
   -- @param start_marker any: start marker supplied to this operation.
   -- @param end_marker any: end marker supplied to this operation.
   -- @param generated_lines any: generated lines supplied to this operation.
   -- @return nil: no values.
   local function replace_generated_section(
      path,
      start_marker,
      end_marker,
      generated_lines
   )
      local current, error_message = read_file(path)

      if not current then
         error("cannot read " .. path .. ": " .. error_message)
      end

      local start_position = current:find(start_marker, 1, true)
      local end_position = current:find(end_marker, 1, true)

      if
         not start_position
         or not end_position
         or end_position <= start_position
      then
         error(path .. ": generated-section markers are missing or invalid")
      end

      local prefix_end = start_position + #start_marker - 1
      local replacement = current:sub(1, prefix_end)
         .. "\n"
         .. table.concat(generated_lines, "\n")
         .. "\n"
         .. current:sub(end_position)

      emit(path, replacement)
   end

   emit(
      dictionary_root .. "/libmemalloc-words.txt",
      table.concat(words, "\n") .. "\n"
   )
   emit(
      spell_root .. "/vale/styles/config/vocabularies/Libmemalloc/accept.txt",
      table.concat(words, "\n") .. "\n"
   )

   local toml_words = {}

   for _, word in ipairs(words) do
      local escaped = word:gsub("\\", "\\\\"):gsub('"', '\\"')

      table.insert(toml_words, '"' .. escaped .. '" = "' .. escaped .. '"')
   end

   replace_generated_section(
      spell_root .. "/typos/typos.toml",
      "# BEGIN GENERATED WORDS",
      "# END GENERATED WORDS",
      toml_words
   )

   local yaml_acronyms = {}

   for _, acronym in ipairs(acronyms) do
      table.insert(yaml_acronyms, "  - " .. acronym)
   end

   replace_generated_section(
      spell_root .. "/vale/styles/Libmemalloc/Acronyms.yml",
      "# BEGIN GENERATED ACRONYMS",
      "# END GENERATED ACRONYMS",
      yaml_acronyms
   )

   replace_generated_section(
      spell_root .. "/vale/styles/LibmemallocSpelling/Acronyms.yml",
      "# BEGIN GENERATED ACRONYMS",
      "# END GENERATED ACRONYMS",
      yaml_acronyms
   )

   if stale then
      os.exit(1)
   end

   if not check_only then
      print(
         "Generated spelling adapters from " .. #words .. " canonical terms."
      )
   end
end

return tools_lint_spell_dictionary_generate_main()

-- EOF


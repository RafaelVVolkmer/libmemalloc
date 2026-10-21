-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer
-- <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Check references and the explicitly named complete C example files.
-- Deliberately invalid failure fragments are never compiled or executed.
-- Part of local and CI verification gates.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_check_doc_examples_main()
   local DOC_EXAMPLES_PITFALL_COUNT = 208
   local DOC_EXAMPLES_TAB_COLUMNS = 8
   local DOC_EXAMPLES_CASE_COUNT = 24
   local DOC_EXAMPLES_SOURCE_COUNT = 9

   local platform = dofile("scripts/lib/platform.lua")
   local documents = {
      "c-code-standard.md",
      "c-module-architecture.md",
      "c-common-pitfalls.md",
   }

   local formatter = assert(
      platform.resolve_tool("LIBMEMALLOC_CLANG_FORMAT", "clang-format"),
      "clang-format is required"
   )

   local tidy = assert(
      platform.resolve_tool("LIBMEMALLOC_CLANG_TIDY", "clang-tidy"),
      "clang-tidy is required"
   )

   --- Read a complete guide or example file and close its input handle.
   -- @param path string: filesystem path selected by the caller.
   -- @return any: a complete guide or example file and close its input handle.
   local function check_doc_examples_read(path)
      local handle = assert(io.open(path, "rb"))
      local source = handle:read("*a")

      assert(handle:close())

      return source
   end

   --- Write an extracted example file and reject write or close failures.
   -- @param path string: filesystem path selected by the caller.
   -- @param content string: input bytes to process.
   -- @return nil: no values.
   local function check_doc_examples_write(path, content)
      local handle = assert(io.open(path, "wb"))

      assert(handle:write(content))
      assert(handle:close())
   end

   --- Require each C pitfall to resolve at least one declared HTTPS source.
   -- @param source string: source supplied to this operation.
   -- @return nil: no values.
   local function check_doc_examples_references(source)
      local definitions = {}

      for key, url in source:gmatch("%[([^%]]+)%]:%s+(https://%S+)") do
         definitions[key] = url
      end

      local count = 0

      for section in source:gmatch("### CPIT%-%d+:([^#]+)") do
         local context = assert(
            section:match("%*%*External references:%*%*(.-)\n\n"),
            "Each pitfall must have an external reference"
         )

         local found = false

         for key in context:gmatch("%]%[([^%]]+)%]") do
            assert(definitions[key], "Missing external reference: " .. key)

            found = true
         end

         assert(found, "External references must resolve to HTTPS sources")

         count = count + 1
      end

      assert(
         count == DOC_EXAMPLES_PITFALL_COUNT,
         "Review the complete pitfall inventory"
      )

      print(string.format("References: %d pitfalls passed.", count))
   end

   -- This executable example explicitly qualifies Linux ELF, Clang and GCC.
   assert(
      not platform.is_windows,
      "The documented example profile is Linux ELF"
   )

   local temporary = platform.temporary_directory()
   local success, failure = xpcall(
      --- Extract, format, compile and execute the complete documented C
      -- examples.
      -- @return nil: no values.
      function()
         local directory = temporary .. "/examples"
         local sources = {}
         local seen = {}
         local count = 0

         for _, name in ipairs(documents) do
            local source = check_doc_examples_read("docs/standards/c/" .. name)

            if name == "c-common-pitfalls.md" then
               check_doc_examples_references(source)
            end

            for relative, language, code in
               source:gmatch(
                  (
                     "<!%-%- example%-file: ([^\n]+) "
                     .. "%-%->%s*```([^\n]+)\n(.-)\n```"
                  )
               )
            do
               -- CWE-22: markers cannot escape or overwrite another named
               -- example.
               assert(relative:match("^[%w_./-]+$"), "Invalid example path")
               assert(not relative:match("^/"), "Absolute example path")
               assert(not relative:find("..", 1, true), "Parent example path")
               assert(not seen[relative], "Duplicate example path")

               seen[relative] = true
               count = count + 1

               local path = directory .. "/" .. relative
               local parent = assert(path:match("^(.*)/[^/]+$"))

               platform.run({ "mkdir", "-p", "--", parent })

               check_doc_examples_write(path, code .. "\n")
               if language == "c" then
                  local formatted = assert(platform.command_output({
                     formatter,
                     "--style=file:tools/lint/code/c/.clang-format",
                     path,
                  }))

                  local display = formatted:gsub(
                     "\t",
                     string.rep(" ", DOC_EXAMPLES_TAB_COLUMNS)
                  )

                  assert(
                     display == code .. "\n",
                     "C formatting drift: " .. path
                  )

                  check_doc_examples_write(path, formatted)
                  if relative:match("%.c$") then
                     sources[#sources + 1] = path
                  end
               end
            end
         end

         assert(
            count == DOC_EXAMPLES_CASE_COUNT
               and #sources == DOC_EXAMPLES_SOURCE_COUNT,
            "Review the example file inventory"
         )

         -- Small fixtures share one runner; each build uses bounded parallel
         -- jobs.
         local profiles = {
            { "clang", "OFF" },
            { "gcc", "OFF" },
            { "clang", "ON" },
         }

         for index, profile in ipairs(profiles) do
            local build = temporary .. "/build-" .. index

            platform.run({
               "cmake",
               "-S",
               directory,
               "-B",
               build,
               "-DCMAKE_C_COMPILER=" .. profile[1],
               "-DCMAKE_BUILD_TYPE=Release",
               "-DSAMPLE_SANITIZE=" .. profile[2],
            })

            platform.run({ "cmake", "--build", build, "--parallel", "2" })

            platform.run({
               "ctest",
               "--test-dir",
               build,
               "--output-on-failure",
               "--timeout",
               "30",
            })
         end

         local arguments = {
            tidy,
            "--experimental-custom-checks",
            "--config-file=tools/lint/code/c/.clang-tidy",
            "-p",
            temporary .. "/build-1",
         }

         for _, source in ipairs(sources) do
            arguments[#arguments + 1] = source
         end

         platform.run(arguments)

         print(
            "Complete C examples passed formatting, builds, tests and analysis."
         )
      end,
      debug.traceback
   )

   platform.remove_temporary_directory(temporary)
   assert(success, failure)
end

return scripts_check_doc_examples_main()

-- EOF


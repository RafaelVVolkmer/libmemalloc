-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Validate the four assembled documentation patterns with real Doxygen.
-- Filled descriptions are test data, not claims about allocator behavior.
-- Part of local and CI verification gates.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_check_c_documentation_main()
   local C_DOCUMENTATION_MIN_CASES = 72

   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local doxygen = os.getenv("LIBMEMALLOC_DOXYGEN") or "doxygen"
   local version = artifact_io.output({ doxygen, "--version" })

   assert(version:match("^1%.18%.0[%s%(]"), "Doxygen 1.18.0 is required")

   local root = ".cache/docs/doxygen-validation"

   artifact_io.mkdir(root)

   dofile("tests/automation/documentation/filter_test.lua")

   --- Require each supported Doxygen option exactly once in the profile.
   -- @return any: require each supported Doxygen option exactly once in the
   -- profile.
   local function check_c_validateDoxygenOptions()
      -- Every generated option must remain present exactly once in the profile.
      local defaults = artifact_io.output({ doxygen, "-s", "-g", "-" })
      local config = artifact_io.read("doxygen/config/Doxyfile")
      local expected, actual = {}, {}

      for key in defaults:gmatch("\n([A-Z][A-Z0-9_]+)%s*=") do
         expected[key] = true
      end

      for key in config:gmatch("\n([A-Z][A-Z0-9_]+)%s*=") do
         assert(expected[key], "Unsupported Doxygen option: " .. key)
         assert(not actual[key], "Duplicate Doxygen option: " .. key)

         actual[key] = true
      end

      local option_count = 0

      for key in pairs(expected) do
         assert(actual[key], "Missing Doxygen option: " .. key)

         option_count = option_count + 1
      end

      return option_count
   end

   local option_count = check_c_validateDoxygenOptions()

   local guide = artifact_io.read("docs/standards/c/c-documentation.md")
   local names = { "private.c", "internal.h", "public.h", "main.c" }
   local count = 0

   --- Construct documentation evidence for one standards chapter.
   -- @param chapter any: chapter supplied to this operation.
   -- @param name string: entry or operation name to resolve.
   -- @return nil: no values.
   local function check_c_documentChapter(chapter, name)
      local heading = "## " .. chapter .. ". Construct `" .. name .. "`"
      local start = assert(guide:find(heading, 1, true))
      local finish = guide:find("\n## ", start + #heading, true) or #guide + 1
      local section = guide:sub(start, finish - 1)
      local blocks = {}

      for code in section:gmatch("```c\n(.-)\n```") do
         blocks[#blocks + 1] = code
         count = count + 1
      end

      assert(#blocks > 0, "No C blocks for " .. name)

      local source = table.concat(blocks, "\n\n") .. "\n\n"

      artifact_io.write(root .. "/literal/" .. name, source)

      -- Resolve structural tags against their declarations, never filter
      -- warnings.
      local filled = source:gsub(
         "()(/%*%*.-%*/)()",
         --- Attach explicit Doxygen declarations to the following C definition.
         -- @param _ any: callback argument intentionally unused.
         -- @param doc string: doc supplied to this operation.
         -- @param comment_end any: comment end supplied to this operation.
         -- @return any: attach explicit Doxygen declarations to the following C
         -- definition.
         function(_, doc, comment_end)
            local code = source:sub(comment_end):match("^[^/]*") or ""

            doc = doc:gsub("^/%*%*<", "/**__TRAILING__")

            local tags = {
               def = code:match("#define%s+([%w_]+)"),
               enum = code:match("enum%s+([%w_]+)"),
               struct = code:match("struct%s+([%w_]+)"),
               union = code:match("union%s+([%w_]+)"),
               typedef = code:match("%(%*([%w_]+)%)")
                  or code:match("typedef[^;]+%s([%w_]+);"),
               var = code:match("(g_[%w_]+)%s*="),
            }

            doc = doc:gsub("@file%s+[^\n]+", "@file " .. name)
            for tag, identifier in pairs(tags) do
               doc = doc:gsub(
                  "@" .. tag .. "%s+[^\n]+",
                  "@" .. tag .. " " .. identifier
               )
            end

            doc = doc:gsub("<MODULE_NAME>", "MODULE")
            doc = doc:gsub("<APPLICATION_NAME>", "APPLICATION")
            doc = doc:gsub("@ref%s+<[^>]+>", "@ref MODULE")
            doc = doc:gsub("@see%s+<[^>]+>", "@see MODULE")
            doc = doc:gsub("<success_code>", "0")
            doc = doc:gsub("<error_code>", "1")
            doc = doc:gsub("<[^>]+>", "Filled field.")

            return (doc:gsub("^/%*%*__TRAILING__", "/**<"))
         end
      )

      artifact_io.write(root .. "/filled/" .. name, filled)
   end

   for chapter, name in ipairs(names) do
      check_c_documentChapter(chapter, name)
   end

   assert(
      count >= C_DOCUMENTATION_MIN_CASES,
      "The complete four construction chapters are required"
   )

   -- Syntax-only checks: placeholder bodies intentionally have no return
   -- statement.
   for _, compiler in ipairs({ "gcc", "clang" }) do
      for _, name in ipairs({ "private.c", "main.c" }) do
         artifact_io.run({
            compiler,
            "-std=c17",
            "-Wno-return-type",
            "-pedantic-errors",
            "-fsyntax-only",
            "-I" .. root .. "/literal",
            root .. "/literal/" .. name,
         })
      end
   end

   for _, profile in ipairs({
      { "gcc", "c99", "c" },
      { "clang", "c17", "c" },
      { "g++", "c++11", "cpp" },
      { "clang++", "c++17", "cpp" },
   }) do
      for _, header in ipairs({ "public.h", "internal.h" }) do
         local probe = root .. "/probe." .. profile[3]

         artifact_io.write(
            probe,
            '#include "' .. header .. '"\n#include "' .. header .. '"\n'
         )

         artifact_io.run({
            profile[1],
            "-std=" .. profile[2],
            "-Wall",
            "-Wextra",
            "-Werror",
            "-pedantic-errors",
            "-fsyntax-only",
            "-I" .. root .. "/literal",
            probe,
         })
      end
   end

   local groups = {}

   for _, owner in ipairs({ "MODULE", "APPLICATION" }) do
      groups[#groups + 1] = "/** @defgroup " .. owner .. " " .. owner .. " */"
      for _, level in ipairs({ "IMPL", "INTERNAL", "API", "ENTRY" }) do
         groups[#groups + 1] = "/** @defgroup "
            .. owner
            .. "_CORE_"
            .. level
            .. " "
            .. level
            .. "\n * @ingroup "
            .. owner
            .. "\n */"
      end
   end

   artifact_io.write(
      root .. "/filled/groups.dox",
      table.concat(groups, "\n") .. "\n"
   )

   --- Generate one Doxygen profile with the requested source visibility
   -- settings.
   -- @param name string: entry or operation name to resolve.
   -- @param extras any: extras supplied to this operation.
   -- @return string, string: one Doxygen profile with the requested source
   -- visibility settings.
   local function check_c_documentation_profile(name, extras)
      local output = root .. "/" .. name

      artifact_io.mkdir(output)

      local path = output .. "/Doxyfile"

      artifact_io.write(
         path,
         (
            "@INCLUDE = doxygen/config/Doxyfile\nEXCLUDE_PATTERNS"
            .. " =\nUSE_MDFILE_AS_MAINPAGE =\n"
         )
            .. 'OUTPUT_DIRECTORY = "'
            .. output
            .. '"\n'
            .. 'WARN_LOGFILE = "'
            .. output
            .. '/warnings.log"\n'
            .. 'GENERATE_TAGFILE = "'
            .. output
            .. '/libmemalloc.tag"\n'
            .. extras
            .. "\n"
      )

      return path, output
   end

   local path, output = check_c_documentation_profile(
      "templates",
      'INPUT = "'
         .. root
         .. '/filled"\n'
         .. 'INCLUDE_PATH = "'
         .. root
         .. '/filled"'
   )

   artifact_io.run({ doxygen, path })
   assert(
      artifact_io.read(output .. "/warnings.log") == "",
      "Doxygen warnings found"
   )

   local xml = artifact_io.read(output .. "/xml/index.xml")

   for _, identifier in ipairs({
      "MODULE_CORE_IMPL",
      "MODULE_CORE_INTERNAL",
      "MODULE_CORE_API",
      "APPLICATION_CORE_ENTRY",
      "MODULE_create",
      "module_getCounter",
      "main",
      "ModuleWork",
      "module_notify_fn_t",
      "MODULE_API_VERSION",
   }) do
      assert(
         xml:find(identifier, 1, true),
         "Missing documented entity: " .. identifier
      )
   end

   assert(not xml:find("P R I V A T E", 1, true), "Decorative title leaked")

   -- A malformed parameter must fail; the filter may not hide documentation
   -- errors.
   artifact_io.write(
      root .. "/negative/bad.h",
      [[/** @file bad.h */
/** ============================================================================
 * @brief Deliberately invalid parameter documentation.
 * @param missing This parameter is absent from the declaration.
 * @return Status.
 * ========================================================================== */
int broken(int present);
]]
   )

   local negative, rejected = check_c_documentation_profile(
      "negative-result",
      'INPUT = "' .. root .. '/negative"\nGENERATE_HTML = NO\nGENERATE_XML = NO'
   )
   local ok = pcall(artifact_io.run, { doxygen, negative })

   assert(not ok, "Invalid parameter documentation was accepted")
   assert(
      artifact_io.read(rejected .. "/warnings.log"):find("missing", 1, true)
   )

   print(
      string.format(
         (
            "C documentation: %d blocks, %d Doxygen "
            .. "options, positive and negative runs passed."
         ),
         count,
         option_count
      )
   )
end

return scripts_check_c_documentation_main()

-- EOF


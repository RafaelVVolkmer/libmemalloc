-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Convert a source file to the input format expected by Doxygen.
-- Part of documentation generation: C comments and Markdown retain separate
-- transformations while sharing argument validation and input reading.
-- Part of Doxygen generation and authored-document validation.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_documentation_filter_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local comments = dofile("scripts/documentation/lib/c_comments.lua")
   local markdown = dofile("scripts/documentation/lib/markdown.lua")
   local path = assert(arg[1], "Doxygen must supply an input filename")

   assert(not arg[2], "expected exactly one input filename")

   local root = artifacts.output({ "pwd" }) .. "/"
   local source = artifacts.read(path)
   local result

   if path:sub(1, #root) == root then
      path = path:sub(#root + 1)
   end

   if path:match("%.md$") or path:match("%.markdown$") then
      result = markdown.filter(source, path)
   else
      result = comments.doxygen(source)
   end

   assert(io.write(result))
end

return scripts_documentation_filter_main()

-- EOF


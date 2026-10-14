-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Reject file-scope Lua work without executing any inspected fixture.
-- Compiler listings preserve strings and comments as data, unlike text
-- matching.

--- Compile positive and negative sources in an isolated temporary directory.
-- @return nil: no values.
local function LUA_STRUCTURE_TEST_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local structure = dofile("scripts/check/lib/lua_structure.lua")
   local compiler = os.getenv("LIBMEMALLOC_LUAC") or "luac"
   local directory = artifacts.platform.temporary_directory("tmp")
   local fixtures = {
      {
         source = "local function main() print('work') end return main()",
         valid = true,
      },
      {
         source = (
            "local function factory(...) return ... "
            .. "end return factory(...)"
         ),
         valid = true,
      },
      {
         source = (
            "local function factory() local t={} "
            .. "return t end return factory()"
         ),
         valid = true,
      },
      { source = "print('must not execute')", valid = false },
      {
         source = "local value = dofile('missing.lua') return value",
         valid = false,
      },
      {
         source = (
            "local constant = 42; local function "
            .. "main() return constant end return main()"
         ),
         valid = false,
      },
      {
         source = "local function main() end main() return main()",
         valid = false,
      },
      {
         source = "local function main() end _G.changed = true return main()",
         valid = false,
      },
   }

   --- Retain cleanup even if compilation or an assertion fails.
   -- @return nil: no values.
   local success, diagnostic = pcall(function()
      for index, fixture in ipairs(fixtures) do
         local path = directory .. "/" .. index .. ".lua"

         artifacts.write(path, fixture.source)

         local listing = artifacts.output({ compiler, "-l", "-p", path })

         assert(
            structure.validate(listing) == fixture.valid,
            "boundary fixture " .. index
         )
      end
   end)

   artifacts.platform.remove_temporary_directory(directory)
   assert(success, diagnostic)

   print(
      "Lua boundaries: "
         .. #fixtures
         .. " non-executing compiler fixtures passed."
   )
end

return LUA_STRUCTURE_TEST_main()

-- EOF


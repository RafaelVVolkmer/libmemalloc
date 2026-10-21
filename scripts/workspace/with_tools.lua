-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Execute a local command with the shared locked quality and Lua runtimes.
-- Explicit setup owns installation; this launcher only selects existing tools.

--- Keep host Python settings from contaminating reviewed tool environments.
-- @return nil: no values.
local function WITH_TOOLS_main()
   assert(#arg > 0, "provide a command after with_tools.lua")
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local runtime = dofile("scripts/workspace/lib/runtime.lua")
   local root = artifacts.output({ "git", "rev-parse", "--show-toplevel" })
   local prefix = root .. "/.cache/tools/quality"
   local lua = assert(runtime.resolve("lua", "LIBMEMALLOC_LUA", "lua"))
   local lua_directory =
      assert(lua:match("^(.*)/[^/]+$"), "bootstrap the locked Lua first")

   assert(
      artifacts.exists(prefix .. "/bin/node"),
      "install the quality profile first"
   )
   local command = {
      "env",
      "-u",
      "PYTHONHOME",
      "-u",
      "PYTHONPATH",
      "PATH=" .. prefix .. "/bin:" .. lua_directory .. ":" .. assert(
         os.getenv("PATH")
      ),
      "LIBMEMALLOC_LUA=" .. lua,
      "LIBMEMALLOC_LUAC=" .. lua_directory .. "/luac",
      "LUA_CPATH=" .. (os.getenv("LUA_CPATH") or runtime.paths.luv .. ";;"),
      "LIBMEMALLOC_QUALITY_PYTHON=" .. prefix .. "/python-all/bin/python",
   }

   for _, name in ipairs({
      "NODE",
      "CLANG_FORMAT",
      "CLANG_TIDY",
      "CPPCHECK",
      "FLAWFINDER",
      "DOXYGEN",
      "SELENE",
      "STYLUA",
      "LUALS",
      "CMAKE_LINT",
      "CMAKE_FORMAT",
   }) do
      local executable = name:lower():gsub("_", "-")

      if name == "LUALS" then
         executable = "lua-language-server"
      end

      command[#command + 1] = "LIBMEMALLOC_"
         .. name
         .. "="
         .. prefix
         .. "/bin/"
         .. executable
   end

   for _, value in ipairs(arg) do
      command[#command + 1] = value
   end

   artifacts.run(command)
end

return WITH_TOOLS_main()

-- EOF


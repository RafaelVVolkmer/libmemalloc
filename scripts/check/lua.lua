-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer
-- <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Run the repository Lua quality policy locally or in CI.
-- Tool paths may be overridden through LIBMEMALLOC_* environment variables.
-- Part of local and CI verification gates.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_check_lua_main()
   local LUA_ARGV_BATCH_SIZE = 64

   --- Resolve the repository and helper roots from this command path.
   -- @return string, string: repository root and its shared Lua library root.
   local function check_lua_roots()
      local raw_script = tostring(arg[0] or ""):gsub("\\", "/")
      local script_dir = raw_script:match("^(.*)/[^/]+$") or "scripts/check"
      local scripts_root = script_dir:match("^(.*)/check$") or "scripts"
      local repo_root = scripts_root:match("^(.*)/scripts$") or "."
      local library_root = scripts_root .. "/lib"

      return repo_root, library_root
   end

   local repo_root, library_root = check_lua_roots()
   local paths = dofile(library_root .. "/paths.lua")
   local platform = dofile(paths.join(library_root, "platform.lua"))
   local git_module = dofile(paths.join(library_root, "git.lua"))
   local git = git_module.new(platform, repo_root)

   --- Print a fatal diagnostic and terminate.
   -- @param message string: diagnostic text.
   -- @return nil: no values.
   local function check_lua_fail(message)
      io.stderr:write("libmemalloc check-lua: error: " .. message .. "\n")

      os.exit(1)
   end

   --- Read the first line of a file.
   -- @param path string: file path.
   -- @return string: first line or an empty string.
   local function check_lua_firstLine(path)
      local file = io.open(paths.join(repo_root, path), "rb")

      if not file then
         return ""
      end

      local line = file:read("*l") or ""

      file:close()

      return line
   end

   --- Check whether a tracked file contains Lua source.
   -- @param path string: repository-relative path.
   -- @return boolean: true for Lua source files and Lua shebang programs.
   local function check_lua_isLuaSource(path)
      if paths.ends_with(path, ".lua") then
         return true
      end

      local line = check_lua_firstLine(path)

      return line:match("^#!.*[/%s]lua%s*$") ~= nil
   end

   --- Resolve one required executable.
   -- @param variable string: environment variable override.
   -- @param default_name string: default executable name.
   -- @return string: executable to invoke.
   local function check_lua_tool(variable, default_name)
      local executable = platform.resolve_tool(variable, default_name)

      if not executable then
         check_lua_fail(
            "required tool '"
               .. default_name
               .. "' is unavailable; set "
               .. variable
               .. "."
         )
      end

      return executable
   end

   --- Execute one command and convert library errors into stable diagnostics.
   -- @param arguments table: command arguments.
   -- @return nil: no values.
   local function check_lua_run(arguments)
      local ok, message = pcall(platform.run_in_directory, repo_root, arguments)

      if not ok then
         check_lua_fail(message)
      end
   end

   --- Run one command over files in bounded argv batches.
   -- @param prefix table: command and fixed arguments.
   -- @param files table: paths to append.
   -- @return nil: no values.
   local function check_lua_runBatched(prefix, files)
      local ok, message = pcall(
         platform.run_batched_in_directory,
         repo_root,
         prefix,
         files,
         LUA_ARGV_BATCH_SIZE
      )

      if not ok then
         check_lua_fail(message)
      end
   end

   local tracked = git.working_files()

   if type(tracked) ~= "table" then
      check_lua_fail("git ls-files failed.")
   end

   local files = {}

   assert(type(tracked) == "table", "git ls-files must return a table.")

   for _, path in ipairs(tracked) do
      if check_lua_isLuaSource(path) then
         files[#files + 1] = path
      end
   end

   if #files == 0 then
      print("No tracked Lua sources found.")

      os.exit(0)
   end

   local lua = check_lua_tool("LIBMEMALLOC_LUA", "lua")
   local luac = check_lua_tool("LIBMEMALLOC_LUAC", "luac")
   local selene = check_lua_tool("LIBMEMALLOC_SELENE", "selene")
   local stylua = check_lua_tool("LIBMEMALLOC_STYLUA", "stylua")
   local luals = check_lua_tool("LIBMEMALLOC_LUALS", "lua-language-server")
   local root = git.root()

   if not root then
      check_lua_fail("cannot resolve the repository root.")
   end

   print(string.format("Checking %d Lua source file(s).", #files))

   check_lua_runBatched({ luac, "-p" }, files)

   local structure = dofile("scripts/check/lib/lua_structure.lua")

   for _, path in ipairs(files) do
      local listing = assert(
         platform.command_output_in_directory(
            repo_root,
            { luac, "-l", "-p", path }
         )
      )

      if not structure.validate(listing) then
         check_lua_fail(path .. ": move initialization into a named function.")
      end
   end

   check_lua_run({ lua, "tests/automation/check/lua_structure_test.lua" })

   local python = check_lua_tool("LIBMEMALLOC_QUALITY_PYTHON", "python3")

   check_lua_run({ python, "tests/automation/analysis/lua_metrics_test.py" })
   check_lua_run({ python, "tools/analysis/lua/metrics.py" })

   check_lua_run({
      lua,
      "tools/lint/spell/dictionary/generate.lua",
      "--check",
   })

   check_lua_runBatched({
      selene,
      "--config",
      "tools/lint/code/lua/selene.toml",
   }, files)

   check_lua_runBatched({
      lua,
      "scripts/check/format.lua",
      "lua",
      stylua,
   }, files)

   check_lua_run({
      luals,
      "--configpath=tools/lint/code/lua/luals.json",
      "--check=" .. root,
      "--checklevel=Warning",
      "--logpath=" .. root .. "/.cache/logs/luals",
   })
end

return scripts_check_lua_main()

-- EOF


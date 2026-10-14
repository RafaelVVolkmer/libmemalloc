-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer
-- <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Local entrypoint for Libmemalloc module-architecture validation.
-- The mock has a compiler-backed subset; product profiles require
-- qualification.
-- Part of local and CI verification gates.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_check_modules_main()
   --- Resolve the repository and helper roots from this command path.
   -- @return string, string: repository root and its shared Lua library root.
   local function check_modules_roots()
      local raw_script = tostring(arg[0] or ""):gsub("\\", "/")
      local script_dir = raw_script:match("^(.*)/[^/]+$") or "scripts/check"
      local scripts_root = script_dir:match("^(.*)/check$") or "scripts"
      local repo_root = scripts_root:match("^(.*)/scripts$") or "."
      local library_root = scripts_root .. "/lib"

      return repo_root, library_root
   end

   local repo_root, library_root = check_modules_roots()
   local paths = dofile(library_root .. "/paths.lua")
   local platform = dofile(paths.join(library_root, "platform.lua"))
   local git_module = dofile(paths.join(library_root, "git.lua"))
   local git = git_module.new(platform, repo_root)

   local architecture_policy = "docs/standards/c/c-module-architecture.md"

   --- Print a fatal diagnostic and terminate.
   -- @param message string: diagnostic text.
   -- @return nil: no values.
   local function check_modules_fail(message)
      io.stderr:write("libmemalloc check-modules: error: " .. message .. "\n")

      os.exit(1)
   end

   local policy_file = io.open(paths.join(repo_root, architecture_policy), "rb")

   if policy_file == nil then
      check_modules_fail(
         "module architecture policy is missing: " .. architecture_policy
      )
   else
      policy_file:close()
   end

   local tracked = git.working_files()

   if type(tracked) ~= "table" then
      check_modules_fail("git ls-files failed.")
   end

   local translation_units = {}

   assert(type(tracked) == "table", "git ls-files must return a table.")

   --- Collect one source for the architecture boundary checks.
   -- @param path string: filesystem path selected by the caller.
   -- @return nil: no values.
   local function check_modules_collectSource(path)
      if paths.ends_with(path, ".c") or paths.ends_with(path, ".i") then
         translation_units[#translation_units + 1] = path
      end
   end

   for _, path in ipairs(tracked) do
      check_modules_collectSource(path)
   end

   if #translation_units == 0 then
      print(
         "No tracked C translation units found; module "
            .. "policy entrypoint is ready."
      )

      os.exit(0)
   end

   local checker = os.getenv("LIBMEMALLOC_MODULE_CHECKER")

   --- Run the architecture checker with a fresh private report directory.
   -- @return nil: no values.
   local function check_modules_runArchitecture()
      if not checker or checker == "" then
         local lua = assert(platform.resolve_tool("LIBMEMALLOC_LUA", "lua"))

         local directory = platform.temporary_directory("ci")
         local relative = assert(
            directory:match("(/%.cache/.*)$"),
            "module evidence must remain in the repository cache"
         ):sub(2)

         platform.run_in_directory(repo_root, {
            lua,
            "scripts/check/c_architecture.lua",
            "--output=" .. relative .. "/architecture",
         })

         os.exit(0)
      end
   end

   check_modules_runArchitecture()

   local arguments = { checker }

   for _, source in ipairs(translation_units) do
      arguments[#arguments + 1] = source
   end

   local ok, message = pcall(platform.run_in_directory, repo_root, arguments)

   if not ok then
      check_modules_fail(message)
   end
end

return scripts_check_modules_main()

-- EOF


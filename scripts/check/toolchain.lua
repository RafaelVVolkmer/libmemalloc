-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer
-- <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Reject duplicated tool identities outside toolchain.lock.toml.
-- Part of local and CI verification gates.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_check_toolchain_main()
   local raw_script = tostring(arg[0] or ""):gsub("\\", "/")
   local script_dir = raw_script:match("^(.*)/[^/]+$") or "scripts/check"
   local scripts_root = script_dir:match("^(.*)/check$") or "scripts"
   local repo_root = scripts_root:match("^(.*)/scripts$") or "."
   local library_root = scripts_root .. "/lib"
   local paths = dofile(library_root .. "/paths.lua")
   local platform = dofile(paths.join(library_root, "platform.lua"))
   local git_module = dofile(paths.join(library_root, "git.lua"))
   local git = git_module.new(platform, repo_root)

   --- Print a fatal diagnostic and terminate.
   -- @param message string: diagnostic text.
   -- @return nil: no values.
   local function check_toolchain_fail(message)
      io.stderr:write("libmemalloc check-toolchain: error: " .. message .. "\n")

      os.exit(1)
   end

   --- Read one repository-relative UTF-8 text file.
   -- @param path string: repository-relative path.
   -- @return string: file contents.
   local function check_toolchain_readFile(path)
      local handle = io.open(paths.join(repo_root, path), "rb")

      if handle == nil then
         check_toolchain_fail("cannot open tracked file '" .. path .. "'.")
      end

      assert(handle ~= nil, "tracked file must be open.")

      local content = handle:read("*a")

      handle:close()

      if content == nil then
         check_toolchain_fail("cannot read tracked file '" .. path .. "'.")
      end

      return content
   end

   --- Check whether a workflow line defines a tool identity directly.
   -- @param line string: YAML source line.
   -- @return boolean: true when the line is a forbidden hardcoded identity.
   local function check_toolchain_hardcodedIdentity(line)
      local key, value = line:match("^%s+([A-Z][A-Z0-9_]+):%s*(.+)$")

      if key == nil or value == nil then
         return false
      end

      local identity = key:match("_VERSION$") ~= nil
         or key:match("_SHA256$") ~= nil
         or key:match("_REVISION$") ~= nil

      if not identity then
         return false
      end

      value = value:match("^%s*(.-)%s*$") or value

      if value:find("${{", 1, true) ~= nil then
         return false
      end

      if value:find("${", 1, true) == 1 then
         return false
      end

      return true
   end

   local tracked = git.working_files()

   if type(tracked) ~= "table" then
      check_toolchain_fail("git ls-files failed.")
   end

   local violations = {}
   local locked_tools =
      dofile(paths.join(scripts_root, "toolchain/lib/lock.lua")).load()

   --- Reject manual edits to generated manifests and all external Action pins.
   -- @return nil: no values.
   local function check_toolchain_projections()
      local manifests = dofile("scripts/toolchain/lib/manifests.lua")
      local outputs =
         manifests.outputs(locked_tools, check_toolchain_readFile, tracked)

      for path, expected in pairs(outputs) do
         if check_toolchain_readFile(path) ~= expected then
            violations[#violations + 1] = path
               .. ": run lua scripts/toolchain/sync.lua"
         end
      end
   end

   check_toolchain_projections()

   --- Check direct Python resolutions; uv sync also validates the whole graph.
   -- @return nil: no values.
   local function check_toolchain_pythonLock()
      local manifest = check_toolchain_readFile("tools/python/pyproject.toml")
      local source = check_toolchain_readFile("tools/python/uv.lock")
      local resolved = {}

      for name, version in
         source:gmatch('%[%[package%]%]\nname = "([^"]+)"\nversion = "([^"]+)"')
      do
         assert(not resolved[name], "ambiguous Python resolution: " .. name)
         resolved[name] = version
      end

      for name, version in manifest:gmatch('"([%w%-]+)==([^"]+)"') do
         if resolved[name] ~= version then
            violations[#violations + 1] = "tools/python/uv.lock differs: "
               .. name
         end
      end
   end

   check_toolchain_pythonLock()

   --- Verify both the requested and resolved Nixpkgs revisions natively.
   -- @return nil: no values.
   local function check_toolchain_nixLock()
      local artifacts = dofile("scripts/lib/artifacts.lua")
      local expected = locked_tools.nixpkgs.revision

      for _, field in ipairs({ "locked", "original" }) do
         local actual = artifacts.query(
            "tools/nix/flake.lock",
            ".nodes.nixpkgs." .. field .. ".rev"
         )
         if actual ~= expected then
            violations[#violations + 1] = "tools/nix/flake.lock differs: "
               .. field
         end
      end
   end

   check_toolchain_nixLock()

   local forbidden_scripts = {
      py = true,
      js = true,
      mjs = true,
      cjs = true,
      jsx = true,
      ts = true,
      tsx = true,
      sh = true,
      bash = true,
      zsh = true,
      fish = true,
      ps1 = true,
      nu = true,
   }

   --- Reject tool identities outside the reviewed lock authority.
   -- @param path string: filesystem path selected by the caller.
   -- @return nil: no values.
   local function check_toolchain_validateSource(path)
      local extension = (path:match("%.([^./]+)$") or ""):lower()

      if path:match("^scripts/") and forbidden_scripts[extension] then
         violations[#violations + 1] = path .. ": script sources must use Lua"
      end

      local workflow = path:match("^%.github/") ~= nil
         and (paths.ends_with(path, ".yml") or paths.ends_with(path, ".yaml"))

      --- Check workflow actions and declared tool identities against the lock.
      -- @return nil: no values.
      local function check_toolchain_validateWorkflow()
         if workflow then
            local content = check_toolchain_readFile(path)
            local line_number = 0

            for line in (content .. "\n"):gmatch("(.-)\n") do
               line_number = line_number + 1

               if check_toolchain_hardcodedIdentity(line) then
                  violations[#violations + 1] = string.format(
                     "%s:%d: %s",
                     path,
                     line_number,
                     line:match("^%s*(.-)%s*$") or line
                  )
               end
            end
         end
      end

      check_toolchain_validateWorkflow()
   end

   for _, path in ipairs(tracked) do
      -- Repository script sources stay in Lua; TOML metadata remains data.
      check_toolchain_validateSource(path)
   end

   if #violations > 0 then
      io.stderr:write("toolchain lock authority violations:\n")

      for _, violation in ipairs(violations) do
         io.stderr:write("  " .. violation .. "\n")
      end

      os.exit(1)
   end

   print("Tool manifests and Actions match tools/toolchain/lock.toml.")
end

return scripts_check_toolchain_main()

-- EOF


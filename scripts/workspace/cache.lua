-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Run a local command with repository-owned disposable state.
-- Usage: lua scripts/workspace/cache.lua COMMAND [ARGUMENT ...].
-- The child inherits credentials; this wrapper never prints its environment.
-- Part of repository state, cache placement and change selection.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_workspace_cache_main()
   local release = dofile("scripts/lib/artifacts.lua")
   local root = release.output({ "git", "rev-parse", "--show-toplevel" })
   local cache_root = root .. "/.cache"
   local locations = {
      LIBMEMALLOC_CACHE_ROOT = "",
      TMPDIR = "/tmp",
      TMP = "/tmp",
      TEMP = "/tmp",
      XDG_CACHE_HOME = "/tools/xdg",
      XDG_CONFIG_HOME = "/tools/config",
      XDG_DATA_HOME = "/tools/data",
      npm_config_cache = "/tools/npm",
      PIP_CACHE_DIR = "/tools/pip",
      CONAN_HOME = "/tools/conan",
      GOPATH = "/tools/go",
      GOCACHE = "/tools/go-build",
      CARGO_HOME = "/tools/cargo",
      RUFF_CACHE_DIR = "/ruff",
      PYTHONPYCACHEPREFIX = "/tools/python",
   }

   local command = { "env" }

   assert(arg[1], "supply a command after cache.lua")

   local names = {}

   for name in pairs(locations) do
      names[#names + 1] = name
   end

   table.sort(names)

   for _, name in ipairs(names) do
      local suffix = locations[name]

      release.mkdir(cache_root .. suffix)

      command[#command + 1] = name .. "=" .. cache_root .. suffix
   end

   for _, directory in ipairs({ "build", "logs", "tests", "ci", "cd" }) do
      release.mkdir(cache_root .. "/" .. directory)
   end

   for _, value in ipairs(arg) do
      command[#command + 1] = value
   end

   release.run(command)
end

return scripts_workspace_cache_main()

-- EOF


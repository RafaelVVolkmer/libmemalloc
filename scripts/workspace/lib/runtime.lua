-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Resolve automation tools from overrides, managed installs and host PATH.
-- Shared by root dispatch, diagnostics and the Ansible transport.

--- Construct runtime discovery without installing or downloading anything.
-- @return table: public operations constructed by this module.
local function RUNTIME_loadModule()
   local platform = dofile("scripts/lib/platform.lua")
   local lock = dofile("scripts/toolchain/lib/lock.lua").load()
   local exports = {}
   local root = assert(
      platform.command_output({ "git", "rev-parse", "--show-toplevel" })
   ):gsub("[\r\n]+$", "")

   exports.paths = {
      lua = root .. "/.cache/tools/lua/" .. lock.lua.version .. "/src/lua",
      luv = root .. "/.cache/tools/luv/" .. lock.luv.version .. "/build/?.so",
      ansible = root
         .. "/.cache/tools/ansible/"
         .. lock.ansible_core.version
         .. "/bin/ansible-playbook",
   }

   --- Prefer explicit executable choices, then a managed binary, then PATH.
   -- @param name string: entry or operation name to resolve.
   -- @param variable string: environment variable naming an executable
   -- override.
   -- @param fallback string: default executable used when no override applies.
   -- @return any: prefer explicit executable choices, then a managed binary,
   -- then PATH.
   local function RUNTIME_resolve(name, variable, fallback)
      local selected = os.getenv(variable)

      if selected then
         return platform.command_exists(selected) and selected or nil
      end

      local managed = exports.paths[name]

      if managed and platform.command_exists(managed) then
         return managed
      end

      return platform.resolve_tool(variable, fallback)
   end

   exports.resolve = RUNTIME_resolve

   return exports
end

return RUNTIME_loadModule()

-- EOF


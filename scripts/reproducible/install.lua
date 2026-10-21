-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Install explicit Ubuntu package versions on the disposable Actions runner.
-- Part of independent reconstruction and byte-comparison campaigns.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_reproducible_install_main()
   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local tools = dofile("scripts/toolchain/lib/lock.lua").load()
   local policy = dofile("tools/reproducible/policy.lua")
   local options = artifact_io.options(arg, { ["build-only"] = true })
   local packages = { policy.compiler }

   for _, package in ipairs(policy.build_dependencies) do
      packages[#packages + 1] = package
   end

   if not options["build-only"] then
      for key, package in pairs(policy.apt) do
         packages[#packages + 1] = package .. "=" .. assert(tools[key]).version
      end
   end

   table.sort(packages)

   dofile("scripts/toolchain/lib/apt.lua").install(artifact_io, packages)
end

return scripts_reproducible_install_main()

-- EOF


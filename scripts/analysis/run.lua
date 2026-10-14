-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Execute independent campaigns even when an earlier campaign fails.
-- Part of compiler analysis and module-boundary evidence.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_analysis_run_main()
   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local options = artifact_io.options(arg, { group = true })
   local groups = {
      rules = {
         { "scripts/check/c_analysis.lua", "--campaign=gcc" },
         { "scripts/check/c_architecture.lua" },
         { "scripts/analysis/quality.lua" },
      },
      quality = { { "scripts/analysis/quality.lua" } },
      extended = {
         { "scripts/check/c_analysis.lua", "--campaign=sparse" },
      },
   }

   local group = assert(groups[options.group], "unknown campaign group")
   local failures = 0

   for _, arguments in ipairs(group) do
      local command = { os.getenv("LIBMEMALLOC_LUA") or "lua" }

      for _, argument in ipairs(arguments) do
         command[#command + 1] = argument
      end

      if not artifact_io.platform.command_succeeded(command) then
         failures = failures + 1
      end
   end

   assert(
      failures == 0,
      tostring(failures) .. " C campaigns failed; inspect .cache/ci/c-analysis"
   )
end

return scripts_analysis_run_main()

-- EOF


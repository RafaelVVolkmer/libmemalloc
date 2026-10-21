-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Execute one phase of the local engineering evidence pilot.
-- Part of process automation: plan, run, gate and report share one engine.
-- Invoke from the repository root; each phase owns a fresh evidence record.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_process_main_main()
   local engine = dofile("scripts/process/lib/engine.lua")
   local PROCESS_PHASES =
      { plan = true, run = true, gate = true, report = true, campaign = true }
   local mode = table.remove(arg, 1)

   assert(
      PROCESS_PHASES[mode],
      "usage: lua scripts/process/main.lua "
         .. "plan|run|gate|report|campaign [options]"
   )

   engine.main(mode, arg)
end

return scripts_process_main_main()

-- EOF


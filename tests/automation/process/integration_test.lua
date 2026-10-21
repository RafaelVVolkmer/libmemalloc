-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Run process contracts under the prepared Lua and native process runtime.

--- Keep native dependencies in the Ansible integration worker.
-- @return nil: no values.
local function PROCESS_INTEGRATION_main()
   local platform = dofile("scripts/lib/platform.lua")
   local interpreter = os.getenv("LIBMEMALLOC_LUA") or arg[-1] or "lua"
   local suites = { "policy", "traceability", "campaign", "evidence" }

   for _, suite in ipairs(suites) do
      platform.run({
         interpreter,
         "tests/automation/process/" .. suite .. "_test.lua",
      })
   end
end

return PROCESS_INTEGRATION_main()

-- EOF


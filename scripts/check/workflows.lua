-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Fail before publication when workflow migration is incomplete.
-- @return nil: prints the checked branch or raises a consistency error.
local function WORKFLOWS_CHECK_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local policy = dofile("scripts/check/lib/workflows.lua")
   local source = artifacts.read(".github/workflows/documentation.yml")
   local branch = policy.documentation(source)

   print("Documentation publication guards agree: " .. branch)
end

return WORKFLOWS_CHECK_main()

-- EOF


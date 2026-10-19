-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Reject partial Pages migrations and attempts to weaken publication guards.
-- @return nil: raises if any invalid workflow is accepted.
local function WORKFLOWS_TEST_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local policy = dofile("scripts/check/lib/workflows.lua")
   local source = artifacts.read(".github/workflows/documentation.yml")
   local branch = policy.documentation(source)
   local escaped = "%f[%w_.%-]"
      .. branch:gsub("([^%w])", "%%%1")
      .. "%f[^%w_./%-]"
   local migrated, count = source:gsub(escaped, "migration-target")

   assert(count == 3, "unexpected number of branch policy sites")
   assert(
      policy.documentation(migrated) == "migration-target",
      "complete migration was rejected"
   )

   for target = 1, count do
      local ordinal = 0
      local mutant = source:gsub(
         escaped,
         --- Mutate one migration site while retaining the other boundaries.
         -- @return string: substituted or original branch.
         function()
            ordinal = ordinal + 1

            return ordinal == target and "other-branch" or branch
         end
      )

      assert(
         not pcall(policy.documentation, mutant),
         "partial migration passed"
      )
   end

   local weaker = source:gsub("github%.event_name == 'push'", "true", 1)
   local detached = source:gsub("needs: %[%s*validate%s*%]", "needs: []")

   assert(not pcall(policy.documentation, weaker), "weaker event guard passed")
   assert(
      not pcall(policy.documentation, detached),
      "detached deployment passed"
   )
   print("Workflow publication: migration and guard mutations passed.")
end

return WORKFLOWS_TEST_main()

-- EOF


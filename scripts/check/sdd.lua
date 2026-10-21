-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Check the plan without asserting any product implementation evidence.
-- @return nil: no values.
local function SDD_CHECK_main()
   local policy = dofile("scripts/check/lib/sdd.lua")
   local documents = {}

   for _, path in ipairs(dofile("tools/specs/catalog.lua")) do
      local file = assert(io.open(path, "rb"))

      documents[path] = assert(file:read("a"))
      assert(file:close())
   end

   local failures, counts =
      policy.check(documents, dofile("tools/specs/ids.lua"))

   for _, failure in ipairs(failures) do
      io.stderr:write(failure .. "\n")
   end

   print(
      string.format(
         "SDD plan: %d controls, %d requirements, %d cases; %d failures.",
         counts.controls,
         counts.requirements,
         counts.cases,
         #failures
      )
   )
   print(
      string.format(
         "Requirement allocation: %d scenario; %d review only. "
            .. "Product execution is not evaluated.",
         counts.coverage.scenario,
         counts.coverage.review_only
      )
   )
   assert(#failures == 0, "SDD plan validation failed")
end

return SDD_CHECK_main()

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Download each producer package once for all consumers assigned to this job.
-- Part of planned qualification tasks and producer/consumer evidence.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_qualification_dependencies_main()
   local evidence_io = dofile("scripts/qualification/lib/io.lua")
   local execution = dofile("scripts/qualification/lib/execution.lua")
   local plan = evidence_io.open(".cache/qualification/plan.json")
   local batch = execution.batch(plan, assert(os.getenv("QUALIFICATION_BATCH")))
   local attempt = assert(os.getenv("GITHUB_RUN_ATTEMPT"))

   assert(attempt:match("^%d+$"), "unsafe attempt identity")

   local names = {}

   for _, dependency in ipairs(batch.dependencies) do
      names[#names + 1] = "qualification-batch-" .. dependency .. "-" .. attempt
   end

   local pattern = #names == 1 and names[1]
      or ("@(" .. table.concat(names, "|") .. ")")
   local output = assert(io.open(assert(os.getenv("GITHUB_OUTPUT")), "a"))

   assert(output:write("required=" .. tostring(#names > 0) .. "\n"))
   assert(output:write("pattern=" .. pattern .. "\n"))
   assert(output:close())
end

return scripts_qualification_dependencies_main()

-- EOF


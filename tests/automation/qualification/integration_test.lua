-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Local batches share a host. Actions separates execution jobs and A/B
-- replicas.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_qualification_integration_test_suite_main()
   local I = dofile("scripts/qualification/lib/io.lua")
   local B, R = I.B, I.R
   local options = R.options(arg, { campaign = true, output = true })
   local campaign = options.campaign or "pr"
   local root = options.output
      or (".cache/qualification/local-" .. tostring(os.time()))

   R.safe_path(root)
   assert(
      root:match("^%.cache/") and not R.exists(root),
      "choose a fresh .cache output"
   )

   local plan_path = root .. "/plan.json"
   local evidence = root .. "/evidence"

   R.run({
      "lua",
      "scripts/qualification/plan.lua",
      "--campaign=" .. campaign,
      "--output=" .. plan_path,
   })

   local plan, identity = I.open(plan_path)

   for _, stage in ipairs(I.catalog.stages) do
      for _, batch in ipairs(plan.execution.stages[stage]) do
         R.run({
            "lua",
            "scripts/qualification/batch.lua",
            "--batch=" .. batch.id,
            "--plan=" .. plan_path,
            "--input=" .. evidence,
            "--output=" .. root,
         })
      end
   end

   R.run({
      "lua",
      "scripts/qualification/report.lua",
      "--plan=" .. plan_path,
      "--input=" .. evidence,
      "--output=" .. root .. "/summary.json",
   })

   local task = plan.run[1]
   local path = evidence .. "/" .. task.id .. "/trace.log"
   local original = B.read(path)

   B.write(path, original .. "corruption\n")

   local accepted = pcall(I.verify, evidence, task, identity)

   B.write(path, original)
   assert(not accepted, "corrupt trace accepted")

   local manifest = evidence .. "/" .. task.id .. "/report.json"

   assert(os.rename(manifest, manifest .. ".held"))

   accepted = pcall(I.verify, evidence, task, identity)
   assert(os.rename(manifest .. ".held", manifest))
   assert(not accepted, "absent report accepted")

   print(
      (
         "Full graph passed; corruption and missing reports "
         .. "rejected. Local rebuilds share a host."
      )
   )
end

return tests_qualification_integration_test_suite_main()

-- EOF


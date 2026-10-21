-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Validate qualification graphs, dependencies and evidence acceptance.
-- Part of repository automation regression tests; run from the root.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_qualification_policy_test_suite_main()
   local Q = dofile("scripts/qualification/lib/model.lua")
   local catalog = dofile("tools/build/qualification.lua")
   local pr_plan = Q.plan(catalog, "pr")
   local full_plan = Q.plan(catalog, "nightly")

   assert(
      #pr_plan.tasks == 668 and #full_plan.tasks == 3556,
      "qualification campaign size changed without review"
   )
   local full_ids = {}

   for _, task in ipairs(full_plan.tasks) do
      full_ids[task.id] = true
   end

   for _, task in ipairs(pr_plan.tasks) do
      assert(full_ids[task.id], "PR task absent from the broad campaign")
   end

   local identity = {
      plan_sha256 = "plan",
      source_sha256 = "source",
      campaign_id = "campaign",
      attempt_id = "1",
   }

   --- Challenge qualification planning for one supported campaign.
   -- @param campaign any: campaign supplied to this operation.
   -- @return nil: no values.
   local function qualification_policy_test_campaign(campaign)
      local plan = Q.plan(catalog, campaign)
      local records = {}

      --- Verify pinned compiler identities before evaluating the plan.
      -- @param compiler table: compiler supplied to this operation.
      -- @return nil: no values.
      local function qualification_policy_test_assertCompiler(compiler)
         for _, dialect in ipairs(compiler.dialects) do
            for _, mode in
               ipairs(catalog.campaigns[campaign].modes or catalog.modes)
            do
               Q.task(
                  plan,
                  compiler.id .. "-c" .. dialect .. "-" .. mode .. "-a"
               )
            end
         end
      end

      for _, compiler in ipairs(catalog.compilers) do
         qualification_policy_test_assertCompiler(compiler)
      end

      --- Require training, diagnostic and consumer products for the campaign.
      -- @return nil: no values.
      local function qualification_test_checkProducts()
         assert(catalog.primary_dialect == "23", "PGO must use C23")
         for _, task in ipairs(plan.instrument) do
            assert(task.dialect == "23", "training dialect regressed")
         end

         for _, task in ipairs(plan.build) do
            Q.task(plan, task.cell .. "-diagnostic-build")
         end

         for _, consumer in ipairs(Q.consumers(catalog)) do
            Q.task(plan, plan.build[1].cell .. "-" .. consumer.id)
         end
      end

      qualification_test_checkProducts()

      local E = dofile("scripts/qualification/lib/execution.lua")
      local seen = {}

      --- Verify bounded batch membership and task isolation.
      -- @param batch table: batch supplied to this operation.
      -- @return nil: no values.
      local function qualification_policy_test_assertBatch(batch)
         for _, id in ipairs(batch.tasks) do
            assert(not seen[id], "execution plan duplicated a task")

            seen[id] = batch.id
            assert(
               Q.task(plan, id).stage == batch.stage,
               "mixed stage assignment"
            )
         end

         local record =
            { id = batch.id, stage = batch.stage, status = "PASS", tasks = {} }

         for key, value in pairs(identity) do
            record[key] = value
         end

         for _, id in ipairs(batch.tasks) do
            record.tasks[#record.tasks + 1] = { id = id, status = "PASS" }
         end

         E.accept(batch, record, identity)

         record.tasks[#record.tasks] = nil
         assert(
            not pcall(E.accept, batch, record, identity),
            "incomplete batch accepted"
         )
      end

      for _, batch in ipairs(plan.execution.batches) do
         qualification_policy_test_assertBatch(batch)
      end

      --- Check producer dependencies and optimization flag compatibility.
      -- @param task table: task supplied to this operation.
      -- @return nil: no values.
      local function qualification_policy_test_assertProducer(task)
         assert(seen[task.id], "execution plan omitted a task")
         if
            task.producer
            and (task.stage == "run" or task.stage == "diagnostic_run")
         then
            for _, other in ipairs(plan[task.stage]) do
               if other.producer == task.producer then
                  assert(
                     seen[task.id] == seen[other.id],
                     "producer affinity lost"
                  )
               end
            end
         end
      end

      for _, task in ipairs(plan.tasks) do
         qualification_policy_test_assertProducer(task)
      end

      for _, pair in ipairs(plan.comparisons) do
         assert(
            seen[pair.first] ~= seen[pair.second],
            "A/B shared an execution job"
         )
      end

      assert(#plan.execution.batches < 50, "execution job budget exceeded")

      for _, task in ipairs(plan.tasks) do
         local record =
            { id = task.id, stage = task.stage, status = "PASS", files = 1 }

         for key, value in pairs(identity) do
            record[key] = value
         end

         records[#records + 1] = record
      end

      assert(Q.gate(plan, records, identity))

      local last = table.remove(records)

      assert(not Q.gate(plan, records, identity), "missing test accepted")

      records[#records + 1] = last
      records[#records + 1] = last
      assert(not Q.gate(plan, records, identity), "duplicate attempt accepted")

      table.remove(records)

      for _, status in ipairs({
         "FAIL",
         "UNSUPPORTED",
         "NOT_APPLICABLE",
         "INCONCLUSIVE",
         "INFRA_ERROR",
         "unknown",
      }) do
         last.status = status
         assert(
            not Q.gate(plan, records, identity),
            "required non-PASS accepted"
         )
      end

      last.status = "PASS"

      for key in pairs(identity) do
         local previous = last[key]

         last[key] = "foreign"
         assert(
            not Q.gate(plan, records, identity),
            "foreign evidence accepted: " .. key
         )

         last[key] = previous
      end

      last.files = 0
      assert(not Q.gate(plan, records, identity), "empty evidence accepted")

      last.files = 1
      last.id = "unexpected"
      assert(not Q.gate(plan, records, identity), "unplanned evidence accepted")
   end

   for _, campaign in ipairs({ "pr", "nightly", "release" }) do
      qualification_policy_test_campaign(campaign)
   end

   assert(not pcall(Q.plan, catalog, "unknown"), "unknown campaign accepted")

   -- Renaming and extending declared inputs must change the evidence contract.
   local alternate = dofile("tools/build/qualification.lua")

   alternate.compilers[1].id = "gcc-next"
   alternate.shards = {
      { id = "small", operations = 20, weight = 2 },
      { id = "large", operations = 50, weight = 3 },
      { id = "concurrent", operations = 80, weight = 1 },
   }

   alternate.fixture.shared = "libfixture.so"
   alternate.fixture.static = "libfixture.a"
   alternate.cases = { "custom-consumer" }
   alternate.case_profiles =
      { ["custom-consumer"] = { indirect = false, static = true } }

   local alternate_plan = Q.plan(alternate, "pr")
   local inventory = Q.artifacts(alternate_plan.build[1], alternate)
   local joined = table.concat(inventory, "\n")

   assert(joined:find("libfixture.so", 1, true), "fixture library ignored")
   assert(
      joined:find("gcc-next-custom-consumer", 1, true),
      "consumer catalog ignored"
   )
   assert(
      not joined:find("gcc-c-direct", 1, true),
      "hardcoded consumer retained"
   )
   assert(#alternate_plan.train == 6, "planner fixed the training shard count")

   local training = Q.artifacts(alternate_plan.instrument[1], alternate)

   assert(
      table.concat(training, "\n"):find("train-concurrent", 1, true),
      "shard inventory ignored"
   )

   print(
      (
         "Qualification rejects missing, duplicate, stale, "
         .. "unsupported and foreign evidence."
      )
   )
end

return tests_qualification_policy_test_suite_main()

-- EOF


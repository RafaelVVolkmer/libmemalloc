-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Aggregate worker evidence and compare independently reconstructed artifacts.
-- Part of planned qualification tasks and producer/consumer evidence.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_qualification_report_main()
   local evidence_io = dofile("scripts/qualification/lib/io.lua")
   local build_io, artifact_io = evidence_io.B, evidence_io.R
   local execution_api = dofile("scripts/qualification/lib/execution.lua")
   local options =
      artifact_io.options(arg, { plan = true, input = true, output = true })
   local input = options.input or ".cache/qualification/evidence"
   local output = options.output or ".cache/qualification/summary.json"

   artifact_io.safe_path(input)

   artifact_io.safe_path(output)
   assert(output:match("^%.cache/"), "output must stay in .cache")

   local opened, plan, identity, catalog =
      pcall(evidence_io.open, options.plan or ".cache/qualification/plan.json")

   if not opened then
      build_io.json(output, {
         schema = 1,
         status = "INFRA_ERROR",
         product_qualified = false,
         failures = artifact_io.array({ tostring(plan) }),
      })

      error(plan)
   end

   local summary = {
      schema = 1,
      contract = catalog.contract,
      product_qualified = false,
      status = "FAIL",
      failures = artifact_io.array(),
      results = artifact_io.array(),
      batches = artifact_io.array(),
      comparisons = artifact_io.array(),
      pending = artifact_io.array(catalog.pending),
   }

   for key, value in pairs(identity) do
      summary[key] = value
   end

   build_io.json(output, summary)

   local execution_root = assert(
      input:match("^(.*)/evidence$"),
      "evidence directory must belong to an execution root"
   )

   --- Verify every planned batch and retain missing or invalid evidence.
   -- @return table: verify every planned batch and retain missing or invalid
   -- evidence.
   local function qualification_report_verifyBatches()
      local expected_batches = {}

      for _, batch in ipairs(plan.execution.batches) do
         expected_batches[batch.id .. ".json"] = true

         local ok, record = pcall(
            execution_api.verify,
            build_io,
            execution_root,
            batch,
            identity
         )

         if ok then
            summary.batches[#summary.batches + 1] = {
               id = batch.id,
               status = "PASS",
               cases = #batch.tasks,
            }
         else
            summary.failures[#summary.failures + 1] = batch.id
               .. ": "
               .. tostring(record)
         end
      end

      return expected_batches
   end

   local expected_batches = qualification_report_verifyBatches()

   --- Reject unexpected retained batch reports outside the planned graph.
   -- @return nil: no values.
   local function qualification_report_checkBatchInventory()
      if artifact_io.exists(execution_root .. "/batches") then
         local files = artifact_io.files(execution_root .. "/batches")

         for _, file in ipairs(files) do
            if not expected_batches[file] then
               local message = "unexpected execution batch: " .. file

               summary.failures[#summary.failures + 1] = message
            end
         end
      end
   end

   qualification_report_checkBatchInventory()

   local accepted, expected = {}, {}

   --- Verify sealed task evidence and preserve every individual failure.
   -- @param task table: task supplied to this operation.
   -- @return nil: no values.
   local function qualification_report_verifyTask(task)
      expected[task.id] = true

      local ok, result = pcall(
         --- Verify a producer and its dependencies before accepting campaign
         -- evidence.
         -- @return any: verify a producer and its dependencies before accepting
         -- campaign evidence.
         function()
            local directory, record = evidence_io.verify(input, task, identity)

            accepted[task.id] = directory

            -- Bind every dependency to the exact accepted producer manifest.
            local report = directory .. "/report.json"
            local count =
               tonumber(build_io.query(report, ".dependencies | length"))
            local dependencies = evidence_io.Q.dependencies(task, catalog)

            assert(count == #dependencies, "missing or extra dependency")
            if count > 0 then
               local seen = {}

               for line in
                  build_io
                     .query(report, ".dependencies[] | [.id, .sha256] | @tsv")
                     :gmatch("[^\n]+")
               do
                  local id, digest = line:match("^([^\t]+)\t(%x+)$")

                  evidence_io.Q.task(plan, id)
                  assert(not seen[id], "duplicate dependency")

                  seen[id] = true
                  assert(
                     build_io.digest(input .. "/" .. id .. "/report.json")
                        == digest,
                     "dependency substitution"
                  )
               end

               for _, id in ipairs(dependencies) do
                  assert(seen[id], "wrong producer dependency")
               end
            end

            if task.stage == "run" then
               assert(
                  build_io.read(directory .. "/trace.log")
                     == evidence_io.trace(catalog.validation_operations),
                  "semantic mismatch"
               )
            end

            return record
         end
      )

      if ok then
         summary.results[#summary.results + 1] = result
      else
         summary.failures[#summary.failures + 1] = task.id
            .. ": "
            .. tostring(result):gsub("[\128-\255]", "?")
      end
   end

   for _, task in ipairs(plan.tasks) do
      qualification_report_verifyTask(task)
   end

   --- Reject unexpected task artifacts outside the planned graph.
   -- @return nil: no values.
   local function qualification_report_checkTaskInventory()
      if artifact_io.exists(input) then
         for _, file in ipairs(artifact_io.files(input)) do
            if not expected[file:match("^([^/]+)/")] then
               summary.failures[#summary.failures + 1] = "unexpected evidence: "
                  .. file
            end
         end
      end
   end

   qualification_report_checkTaskInventory()

   --- Compare independent build artifacts after requiring identical tool
   -- inputs.
   -- @param pair table: captured hexadecimal byte pair.
   -- @return nil: no values.
   local function qualification_report_compareBuilds(pair)
      local ok, failure = pcall(
         --- Compare two independent builds only after matching their tool
         -- identities.
         -- @return nil: no values.
         function()
            local first, second =
               assert(accepted[pair.first], "first build missing"),
               assert(accepted[pair.second], "second build missing")

            assert(
               build_io.digest(first .. "/tools.json")
                  == build_io.digest(second .. "/tools.json"),
               "independent builders have different tools"
            )

            local names = { evidence_io.catalog.fixture.shared }
            local first_task = evidence_io.Q.task(plan, pair.first)

            if first_task.mode ~= "pgo" and first_task.mode ~= "O3-lto" then
               names[#names + 1] = evidence_io.catalog.fixture.static
            end

            for _, consumer in ipairs(evidence_io.Q.consumers(catalog)) do
               names[#names + 1] = consumer.id
            end

            for _, name in ipairs(names) do
               local a, b =
                  build_io.digest(first .. "/" .. name),
                  build_io.digest(second .. "/" .. name)

               summary.comparisons[#summary.comparisons + 1] = {
                  first = pair.first,
                  second = pair.second,
                  artifact = name,
                  first_sha256 = a,
                  second_sha256 = b,
                  status = a == b and "PASS" or "FAIL",
               }

               assert(a == b, "independent rebuild differs: " .. name)
            end
         end
      )

      if not ok then
         summary.failures[#summary.failures + 1] = pair.first
            .. ": "
            .. tostring(failure)
      end
   end

   for _, pair in ipairs(plan.comparisons) do
      qualification_report_compareBuilds(pair)
   end

   summary.status = #summary.failures == 0 and "PASS" or "FAIL"
   build_io.json(output, summary)

   print(
      string.format(
         "%d/%d tasks accepted; %s; scope: distribution mock",
         #summary.results,
         #plan.tasks,
         summary.status
      )
   )
   assert(summary.status == "PASS", "qualification failed; inspect " .. output)
end

return scripts_qualification_report_main()

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Expand a campaign into tasks, dependencies and workflow matrices.
-- Part of planned qualification tasks and producer/consumer evidence.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_qualification_plan_main()
   local build_io = dofile("scripts/build/lib/io.lua")
   local qualification_model = dofile("scripts/qualification/lib/model.lua")
   local artifact_io = build_io.release
   local options = artifact_io.options(arg, { campaign = true, output = true })
   local catalog = dofile("tools/build/qualification.lua")
   local plan = qualification_model.plan(catalog, options.campaign or "pr")

   plan.source_inputs = build_io.inputs()

   -- Qualification sources and workflow definitions are inputs too.
   local listed = build_io.output({
      "git",
      "ls-files",
      "--cached",
      "--others",
      "--exclude-standard",
      "--",
      "tests/automation/qualification",
      "tests/fixtures/qualification",
      ".github/workflows",
      ".github/actions/setup-qualification",
   })

   for _, path in ipairs(build_io.lines(listed)) do
      -- Removed workflow definitions are absent from the new working tree.
      if artifact_io.exists(path) then
         plan.source_inputs[#plan.source_inputs + 1] =
            { path = path, sha256 = build_io.digest(path) }
      end
   end

   plan.campaign_id = os.getenv("GITHUB_RUN_ID") or "local"
   plan.attempt_id = os.getenv("GITHUB_RUN_ATTEMPT") or "1"
   plan.source_revision = build_io.output({ "git", "rev-parse", "HEAD" })
   plan.source_date_epoch =
      build_io.output({ "git", "show", "-s", "--format=%ct", "HEAD" })

   local output = options.output or ".cache/qualification/plan.json"

   artifact_io.safe_path(output)
   assert(output:match("^%.cache/"), "plan must stay in .cache")

   --- Mark sequence values for JSON serialization while preserving object
   -- fields.
   -- @param value any: input value; validation belongs to this operation’s
   -- contract.
   -- @return nil: no values.
   local function qualification_plan_arrays(value)
      for _, item in pairs(value) do
         if type(item) == "table" then
            qualification_plan_arrays(item)
         end
      end

      if #value > 0 then
         artifact_io.array(value)
      end
   end

   qualification_plan_arrays(plan)
   for _, batch in ipairs(plan.execution.batches) do
      artifact_io.array(batch.dependencies)
   end

   build_io.json(output, plan)

   local github = os.getenv("GITHUB_OUTPUT")

   --- Expose the selected stage matrices through GitHub outputs.
   -- @return nil: no values.
   local function qualification_plan_emitOutputs()
      if github then
         local file = assert(io.open(github, "a"))

         for _, stage in ipairs(catalog.stages) do
            local matrix = artifact_io.array()

            for _, batch in ipairs(plan.execution.stages[stage]) do
               matrix[#matrix + 1] = { id = batch.id }
            end

            assert(
               file:write(
                  stage .. "=" .. artifact_io.json({ include = matrix }) .. "\n"
               )
            )
         end

         assert(file:close())
      end
   end

   qualification_plan_emitOutputs()

   local summary = os.getenv("GITHUB_STEP_SUMMARY")

   if summary then
      local file = assert(io.open(summary, "a"))

      assert(
         file:write(
            string.format(
               (
                  "**%d logical tasks; %d worker jobs; "
                  .. "%d total qualification jobs.**\n\n"
               ),
               #plan.tasks,
               #plan.execution.batches,
               #plan.execution.batches + 2
            )
         )
      )
      assert(file:write("| Stage | Cases | Jobs |\n| --- | ---: | ---: |\n"))
      for _, stage in ipairs(catalog.stages) do
         assert(
            file:write(
               string.format(
                  "| %s | %d | %d |\n",
                  stage,
                  #plan[stage],
                  #plan.execution.stages[stage]
               )
            )
         )
      end

      assert(file:close())
   end

   print(
      string.format(
         "%d logical tasks in %d execution jobs; contract %s",
         #plan.tasks,
         #plan.execution.batches,
         plan.contract
      )
   )
end

return scripts_qualification_plan_main()

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Aggregate against the planner, never against the subset that happened to
-- return.
-- Part of build-matrix planning, execution and retained results.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_build_report_main()
   local build_io = dofile("scripts/build/lib/io.lua")
   local artifact_io = build_io.release
   local exports = dofile("scripts/build/lib/matrix.lua")
   local evidence = dofile("scripts/build/lib/evidence.lua")
   local options = artifact_io.options(arg, {
      campaign = true,
      plan = true,
      input = true,
      output = true,
      profile = true,
   })

   local campaign = options.campaign or "pr"
   local plan =
      exports.plan(dofile("tools/build/matrix.lua"), campaign, options.profile)
   local input = options.input or ".cache/ci/build-reports"
   local records, missing, errors = {}, {}, {}
   local plan_digest = options.plan and build_io.digest(options.plan)

   --- Read one profile report and retain any validation failure.
   -- @param group table: group supplied to this operation.
   -- @return nil: no values.
   local function build_report_collectGroup(group)
      local path = input .. "/" .. group.profile .. "/report.json"
      local handle = io.open(path, "rb")

      if not handle then
         missing[#missing + 1] = group.profile
      else
         handle:close()
         local valid, cells = pcall(
            evidence.group,
            build_io,
            input .. "/" .. group.profile,
            group.profile,
            campaign,
            plan_digest
         )

         if valid then
            for _, cell in ipairs(cells) do
               records[#records + 1] = cell
            end
         else
            errors[#errors + 1] = group.profile .. ": " .. tostring(cells)
         end
      end
   end

   for _, group in ipairs(plan.groups) do
      build_report_collectGroup(group)
   end

   local evaluated, ok, failures, experiments =
      pcall(exports.gate, plan.cells, records)

   if not evaluated then
      errors[#errors + 1] = tostring(ok)
      ok, failures, experiments = false, {}, {}
   end

   ok = ok and #errors == 0
   for _, failure in ipairs(errors) do
      failures[#failures + 1] = failure
   end

   local output = options.output or ".cache/ci/build-summary.json"

   for _, record in ipairs(records) do
      artifact_io.array(record.tests)

      artifact_io.array(record.unsupported_tests)
   end

   build_io.json(output, {
      schema = 1,
      campaign = campaign,
      required_passed = ok,
      cells = artifact_io.array(records),
      failures = artifact_io.array(failures),
      missing_groups = artifact_io.array(missing),
      experimental_results = artifact_io.array(experiments),
      scope = (
         "executed distribution mock configurations; "
         .. "unsigned engineering evidence"
      ),
   })

   print(
      string.format(
         "%d/%d cells reported; required gate: %s",
         #records,
         #plan.cells,
         tostring(ok)
      )
   )
   assert(ok, "build matrix incomplete or failed")
end

return scripts_build_report_main()

-- EOF


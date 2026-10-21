-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Run the plan operation under its declared inputs and evidence contract.
-- Part of build-matrix planning, execution and retained results.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_build_plan_main()
   local exports = dofile("scripts/build/lib/matrix.lua")
   local build_io = dofile("scripts/build/lib/io.lua")
   local artifact_io = build_io.release
   local options = artifact_io.options(
      arg,
      { campaign = true, profile = true, output = true }
   )
   local plan = exports.plan(
      dofile("tools/build/matrix.lua"),
      options.campaign or "pr",
      options.profile
   )

   for _, cell in ipairs(plan.cells) do
      artifact_io.array(cell.tests)

      artifact_io.array(cell.optional_tests)
      if cell.flags then
         artifact_io.array(cell.flags)

         artifact_io.array(cell.link_flags)
      end
   end

   artifact_io.array(plan.cells)

   artifact_io.array(plan.groups)

   artifact_io.array(plan.unavailable)

   plan.source_inputs = build_io.inputs()

   local output = options.output or ".cache/ci/build-plan.json"

   artifact_io.safe_path(output)
   assert(output:match("^%.cache/"), "plan must stay in .cache")

   build_io.json(output, plan)

   local github = os.getenv("GITHUB_OUTPUT")

   if github then
      local file = assert(io.open(github, "a"))

      assert(
         file:write(
            "matrix=" .. artifact_io.json({ include = plan.groups }) .. "\n"
         )
      )
      assert(file:close())
   end

   print(
      string.format(
         "%d groups, %d cells; %s",
         #plan.groups,
         #plan.cells,
         output
      )
   )
end

return scripts_build_plan_main()

-- EOF


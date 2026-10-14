-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Test every selection and failure against the actual hosted gate contract.
-- @return nil: no values.
local function CI_GATE_TEST_main()
   local gate = dofile("scripts/check/lib/ci_gate.lua")
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local checks = 0

   --- Challenge every outcome for one detector selection.
   -- @param bits any: bits supplied to this operation.
   -- @return nil: no values.
   local function outcomes(bits)
      local values = {
         ENGINEERING_CHANGED = tostring(bits & 1 ~= 0),
         C_CHANGED = tostring(bits & 2 ~= 0),
         SPELLING_CHANGED = tostring(bits & 4 ~= 0),
      }

      for _, rule in ipairs(gate.rules) do
         values[rule.env] = rule.selection
               and values[rule.selection] == "false"
               and "skipped"
            or "success"
      end

      assert(gate.validate(values))
      checks = checks + 1
      for _, rule in ipairs(gate.rules) do
         local original = values[rule.env]

         for _, outcome in ipairs({
            "failure",
            "cancelled",
            "",
            "neutral",
            "skipped",
         }) do
            values[rule.env] = outcome
            local valid = pcall(gate.validate, values)

            assert(
               valid == (outcome == "skipped" and original == "skipped"),
               "gate accepted an unexpected outcome for " .. rule.job
            )
            checks = checks + 1
         end

         values[rule.env] = original
      end

      values.ENGINEERING_CHANGED = ""
      assert(not pcall(gate.validate, values), "empty detector output passed")
   end

   for bits = 0, 7 do
      outcomes(bits)
   end

   --- Check the actual needs and environment bindings, not another job list.
   -- @return nil: no values.
   local function ci_gate_test_bindings()
      local source = artifacts.read(".github/workflows/ci.yml")
      local block =
         assert(source:match("\n  ci%-gate:\n(.-)\n  release%-checks:"))

      assert(
         block:find("if: always()", 1, true),
         "gate no longer runs after failure"
      )
      assert(
         block:find(
            "scripts/process/playbook.lua --direct check-ci-gate",
            1,
            true
         )
      )
      local needs = assert(block:match("    needs:\n(.-)    runs%-on:"))
      local jobs = {}

      for name in needs:gmatch("%- ([%w%-]+)") do
         jobs[name] = true
      end

      for _, rule in ipairs(gate.rules) do
         assert(jobs[rule.job], "gate cannot observe " .. rule.job)
         jobs[rule.job] = nil
         assert(
            block:find(
               rule.env .. ": ${{ needs." .. rule.job .. ".result }}",
               1,
               true
            ),
            "misbound job outcome"
         )
         if rule.selection then
            local area = rule.selection:lower():gsub("_changed$", "")

            assert(
               block:find(
                  rule.selection
                     .. ": ${{ needs.changes.outputs."
                     .. area
                     .. " }}",
                  1,
                  true
               ),
               "misbound selection"
            )
         end
      end

      assert(not next(jobs), "gate ignores a declared dependency")
      local doc = artifacts.read("docs/reference/workflow-catalog.md")

      assert(
         doc:find(gate.markdown(), 1, true),
         "workflow catalog differs from executable gate"
      )
   end

   ci_gate_test_bindings()
   print(
      "CI gate: "
         .. checks
         .. " outcome cases and workflow/documentation bindings passed."
   )
end

return CI_GATE_TEST_main()

-- EOF


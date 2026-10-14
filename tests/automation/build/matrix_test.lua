-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Validate build profile selection and planned campaign coverage.
-- Part of repository automation regression tests; run from the root.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_build_matrix_test_suite_main()
   local M = dofile("scripts/build/lib/matrix.lua")
   local C = dofile("scripts/build/lib/cache.lua")
   local catalog = dofile("tools/build/matrix.lua")
   local plan = M.plan(catalog, "exhaustive")

   assert(
      #plan.groups == 13 and #plan.cells > 400,
      "catalog change needs contract review"
   )

   local pr = M.plan(catalog, "pr")

   assert(#pr.cells == 81, "PR selection changed without review")
   for _, cell in ipairs(plan.cells) do
      assert(cell.support == "required", "flags downgraded a supported cell")
   end

   local trial_catalog = dofile("tools/build/matrix.lua")

   trial_catalog.optimizations[1].support = "experimental"
   local trial_plan = M.plan(trial_catalog, "exhaustive", "linux-gcc13")

   for _, cell in ipairs(trial_plan.cells) do
      if cell.id:match("%-O0$") then
         assert(
            cell.support == "experimental",
            "explicit experiment was ignored"
         )
      end
   end

   local selected = {}

   for _, group in ipairs(pr.groups) do
      selected[group.profile] = true
   end

   assert(
      selected["linux-zig-musl"] and selected["wasm-emscripten"],
      "SDK coverage was omitted from pull requests"
   )
   for _, cell in ipairs(plan.cells) do
      if not cell.flags then
         assert(
            #cell.tests == #catalog.cpp_requested + 2,
            "a C dialect lost its C++ consumers"
         )
      end
   end

   local first_tests = plan.cells[1].tests
   local second_tests = plan.cells[2].tests
   local retained = second_tests[1]
   first_tests[1] = "changed-in-one-cell"
   assert(second_tests[1] == retained, "test lists alias across cells")
   assert(
      plan.cells[1].optional_tests ~= plan.cells[2].optional_tests,
      "optional test lists alias across cells"
   )

   local expected = {
      { id = "required", support = "required", tests = { "one" } },
      { id = "trial", support = "experimental", tests = { "one" } },
   }

   local required = {
      id = "required",
      support = "required",
      tests = { "one" },
      artifacts = 1,
      status = "tests-passed",
   }

   local trial = {
      id = "trial",
      support = "experimental",
      tests = {},
      artifacts = 0,
      status = "unsupported",
   }

   assert(M.gate(expected, { required, trial }))
   assert(
      not M.gate(expected, { required }),
      "missing experimental record was hidden"
   )
   assert(not M.gate(expected, { trial }), "missing required record was hidden")

   for _, state in ipairs({
      "unsupported",
      "build-passed",
      "failed",
      "infrastructure-error",
      "experimental",
   }) do
      required.status = state
      assert(
         not M.gate(expected, { required, trial }),
         "unexecuted required cell approved: " .. state
      )
   end

   -- Capability probes can omit optional modes, never required or unknown
   -- tests.
   local optional = {
      {
         id = "optional",
         support = "required",
         tests = { "base", "cpp-26" },
         optional_tests = { "cpp-26" },
      },
   }
   local recorded = {
      {
         id = "optional",
         support = "required",
         status = "tests-passed",
         tests = { "base" },
         unsupported_tests = { "cpp-26" },
         artifacts = 1,
      },
   }

   assert(M.gate(optional, recorded))

   recorded[1].unsupported_tests = { "base", "cpp-26" }
   assert(not pcall(M.gate, optional, recorded), "required test was downgraded")

   recorded[1].unsupported_tests = { "cpp-26", "unknown" }
   assert(
      not pcall(M.gate, optional, recorded),
      "unknown capability was accepted"
   )

   required.status = "tests-passed"
   required.tests = {}
   assert(
      not pcall(M.gate, expected, { required, trial }),
      "omitted test accepted"
   )

   required.tests = { "one" }
   assert(
      not pcall(M.gate, expected, { required, required, trial }),
      "duplicate cell accepted"
   )

   required.support = "experimental"
   assert(
      not pcall(M.gate, expected, { required, trial }),
      "support downgrade accepted"
   )
   assert(
      not C.trusted("pull_request", "main", "main"),
      "PR may write trusted cache"
   )
   assert(
      not C.trusted("workflow_dispatch", "feature", "main"),
      "feature dispatch may write trusted cache"
   )
   assert(
      C.trusted("push", "main", "main"),
      "trusted cache publication rejected"
   )
   assert(
      not pcall(M.plan, catalog, "exhaustive", "missing"),
      "unknown profile accepted"
   )

   print(
      (
         "Build matrix: missing cells, missing tests, false "
         .. "successes, downgrade and cache trust rejected."
      )
   )
end

return tests_build_matrix_test_suite_main()

-- EOF


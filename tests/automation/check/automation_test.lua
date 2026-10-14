-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Exercise suite continuation, native timeout and web dependency blocking.
-- @return nil: raises on lost outcomes or execution of blocked work.
local function AUTOMATION_TEST_main()
   local runner = dofile("scripts/check/lib/automation.lua")
   local executor = dofile("scripts/process/lib/exec.lua")
   local uv = require("luv")
   local AUTOMATION_TEST_TIMEOUT_MS = 20
   local AUTOMATION_TEST_PROCESS_MS = 1000
   local AUTOMATION_TEST_MAX_BYTES = 128
   local results = {}
   local plan = {
      lua = {
         {
            name = "timeout",
            argv = { "sleep", "5" },
            timeout_ms = AUTOMATION_TEST_TIMEOUT_MS,
         },
         {
            name = "failure",
            argv = { "false" },
            timeout_ms = AUTOMATION_TEST_PROCESS_MS,
         },
         {
            name = "missing",
            argv = { "/missing/libmemalloc-test" },
            timeout_ms = AUTOMATION_TEST_PROCESS_MS,
         },
         {
            name = "output",
            argv = { "yes" },
            timeout_ms = AUTOMATION_TEST_PROCESS_MS,
         },
         {
            name = "after-failure",
            argv = { "printf", "%s", "preserved" },
            timeout_ms = AUTOMATION_TEST_PROCESS_MS,
         },
      },
      compiler = {
         name = "compiler",
         argv = { "false" },
         timeout_ms = AUTOMATION_TEST_PROCESS_MS,
      },
      node = {
         {
            name = "stale-web",
            argv = { "true" },
            timeout_ms = AUTOMATION_TEST_PROCESS_MS,
         },
      },
   }

   --- Retain results for independent ordering and diagnostic assertions.
   -- @param row table: process result or dependency-blocked row.
   -- @return nil: appends the borrowed row without changing it.
   local function automation_test_record(row)
      results[#results + 1] = row
   end

   local report = runner.run(plan, {
      run = executor.run,
      clock = uv.hrtime,
      record = automation_test_record,
   }, AUTOMATION_TEST_MAX_BYTES)

   assert(
      report.state == "FAIL" and #report.failures == 5,
      "failure summary lost process outcomes"
   )
   assert(
      results[1].state == "TIMEOUT" and results[1].duration_ms > 0,
      "timeout lost its state or duration"
   )
   assert(
      results[2].exit_code ~= 0 and results[2].state == "FAIL",
      "nonzero exit was accepted"
   )
   assert(
      results[3].state == "INFRA_ERROR",
      "spawn failure lost infrastructure status"
   )
   assert(results[4].state == "OUTPUT_LIMIT", "output limit was not enforced")
   assert(
      #results[4].stdout + #results[4].stderr <= AUTOMATION_TEST_MAX_BYTES,
      "captured output exceeded its bound"
   )
   assert(
      results[5].state == "PASS" and results[5].stdout == "preserved",
      "independent suite did not run after failure"
   )
   assert(
      results[7].state == "BLOCKED" and results[7].exit_code == nil,
      "blocked suite acquired a false execution result"
   )
   assert(report.blocked[1] == "stale-web", "blocked suite name was lost")

   plan.lua = {}
   plan.compiler.argv = { "true" }
   results = {}
   report = runner.run(plan, {
      run = executor.run,
      clock = uv.hrtime,
      record = automation_test_record,
   }, AUTOMATION_TEST_MAX_BYTES)
   assert(
      report.state == "PASS" and results[2].state == "PASS",
      "web suite did not run after successful compilation"
   )

   --- Simulate an adapter exception without suppressing subsequent reporting.
   -- @return nil: raises the injected infrastructure failure.
   local function automation_test_throw()
      error("injected adapter failure")
   end

   results = {}
   report = runner.run(plan, {
      run = automation_test_throw,
      clock = uv.hrtime,
      record = automation_test_record,
   }, AUTOMATION_TEST_MAX_BYTES)
   assert(
      report.state == "FAIL" and results[1].state == "INFRA_ERROR",
      "adapter exception escaped reporting"
   )
   assert(results[1].stderr:find("injected adapter failure", 1, true))
   assert(results[2].state == "BLOCKED", "web suite ran after adapter failure")

   print(
      "Automation runner: timeout, output bounds, failure continuation"
         .. " and web dependencies passed."
   )
end

return AUTOMATION_TEST_main()

-- EOF


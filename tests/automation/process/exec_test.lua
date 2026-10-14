-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Verify literal argv, bounded output, timeouts and spawn failures.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_process_exec_test_suite_main()
   local E = dofile("scripts/process/lib/exec.lua")
   local literal = "spaces ; $(touch SHOULD_NOT_EXIST) `id` $HOME"
   local r = E.run({ "printf", "%s", literal })

   assert(
      r.state == "PASS" and r.stdout == literal,
      "literal argv was interpreted or changed"
   )

   local failed = E.run({ "false" })

   assert(
      failed.state == "FAIL" and failed.exit_code ~= 0,
      "nonzero child exit was accepted"
   )

   local missing = E.run({ "/definitely/missing/lma-executable" })

   assert(
      missing.state == "INFRA_ERROR",
      "spawn failure lost its infrastructure status"
   )

   local timed = E.run({ "sleep", "5" }, { timeout_ms = 20 })

   assert(timed.state == "TIMEOUT", "deadline did not stop the child")

   local bounded = E.run({ "yes" }, { max_bytes = 64 })

   assert(
      bounded.state == "OUTPUT_LIMIT" and #bounded.stdout <= 64,
      "output exceeded the declared bound"
   )

   local env = E.run({ "env" }, { env = { "LMA_EXPLICIT=value" } })

   assert(
      env.stdout == "LMA_EXPLICIT=value\n",
      "explicit environment inherited extra values"
   )

   for _, invalid in ipairs({ 0, -1, 0.5, math.huge, 0 / 0, false, "20" }) do
      assert(
         not pcall(E.run, { "true" }, { timeout_ms = invalid }),
         "invalid timeout reached the native runtime"
      )
      assert(
         not pcall(E.run, { "true" }, { max_bytes = invalid }),
         "invalid output bound reached the native runtime"
      )
   end

   for _, invalid in ipairs({
      {},
      { "" },
      { "true\0ignored" },
      { "true", "argument\0ignored" },
      { [1] = "true", extra = "ignored" },
   }) do
      assert(not pcall(E.run, invalid), "malformed argv was accepted")
   end

   print("Native process adapter: execution and input-boundary cases passed.")
end

return tests_process_exec_test_suite_main()

-- EOF


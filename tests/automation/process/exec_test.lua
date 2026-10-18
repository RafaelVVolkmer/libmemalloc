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

   local streamed = ""
   local live = E.run({ "printf", "%s", literal }, {
      --- Observe the same accepted bytes returned by the bounded capture.
      -- @param stream string: captured stream name.
      -- @param chunk string: accepted output bytes.
      -- @return nil: no values.
      on_output = function(stream, chunk)
         assert(stream == "stdout", "unexpected output stream")
         streamed = streamed .. chunk
      end,
   })
   assert(
      live.stdout == streamed and streamed == literal,
      "live output differs from retained bytes"
   )
   local binary = "LF\nCRLF\r\n" .. string.char(0, 26, 128, 255)
   local forwarded = E.run({
      require("luv").exepath(),
      "-e",
      "local e=dofile('scripts/process/lib/exec.lua'); "
         .. "local bytes='LF\\nCRLF\\r\\n'..string.char(0,26,128,255); "
         .. "e.forward_output('stdout',bytes); "
         .. "e.forward_output('stderr',bytes)",
   })
   assert(
      forwarded.state == "PASS"
         and forwarded.stdout == binary
         and forwarded.stderr == binary,
      "forwarding changed binary output"
   )
   local broken = E.run({ "yes" }, {
      timeout_ms = 1000,
      --- Simulate failure of a retained log sink.
      -- @return nil: no values.
      on_output = function()
         error("log sink unavailable")
      end,
   })
   assert(
      broken.state == "INFRA_ERROR" and broken.output_error,
      "log failure was not retained"
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


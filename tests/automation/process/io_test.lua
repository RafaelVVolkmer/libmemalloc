-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- JSON transport preserves types and treats strings as inert data.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_process_io_test_suite_main()
   local I = dofile("scripts/process/lib/io.lua")
   local count = 0
   local samples = {
      "{}",
      "[]",
      '{"a":[]}',
      '{"a":false,"b":true}',
      '{"number":-12}',
      '{"a/b:c%": "tab\\tline\\n"}',
      '{"source":"return os.execute(\\"id\\")"}',
      '{"unicode":"\\u0041","nested":[{},[1,2]]}',
   }

   for _, sample in ipairs(samples) do
      count = count + 1

      local value = I.decode(sample)

      assert(
         I.json(value) == I.json(I.decode(I.json(value))),
         "JSON round trip changed canonical bytes"
      )
   end

   for _, sample in ipairs({
      "",
      "{",
      "{}\n{}",
      '{"a":null}',
      "null",
      "1.5",
      "1e999",
      '"\\u03bb"',
   }) do
      count = count + 1
      assert(not pcall(I.decode, sample), "invalid JSON accepted")
   end

   assert(
      not pcall(I.decode, string.rep(" ", 4194305)),
      "oversized input accepted"
   )

   print("Process JSON transport: " .. (count + 1) .. " cases passed.")
end

return tests_process_io_test_suite_main()

-- EOF


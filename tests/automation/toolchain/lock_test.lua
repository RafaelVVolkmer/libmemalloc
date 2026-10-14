-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Verify version parsing and reject incomplete or conflicting tool locks.
-- Part of repository automation regression tests; run from the root.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_lint_toolchain_test_suite_main()
   local parser = dofile("scripts/toolchain/lib/lock.lua")
   local valid = 'schema_version = 1\n[tools.lua]\nversion = "5.5.1"\n'

   assert(
      parser.json(parser.parse(valid)) == '{"lua":{"version":"5.5.1"}}',
      "valid lock did not round-trip"
   )

   for _, invalid in ipairs({
      valid .. 'version = "5.4.0"\n',
      valid .. '[tools.lua]\nversion = "5.4.0"\n',
      valid .. 'sha256 = "invalid"\n',
      valid .. 'version = "$(id)"\n',
      valid .. 'unknown = "1"\n',
      '[tools.lua]\nversion = "5.5.1"\n',
      "schema_version = 1\n[tools.lua]\n",
      valid .. "schema_version = 1\n",
   }) do
      assert(not pcall(parser.parse, invalid), "invalid lock accepted")
   end

   print("Toolchain: valid lock and 8 invalid lock cases passed.")
end

return tests_lint_toolchain_test_suite_main()

-- EOF


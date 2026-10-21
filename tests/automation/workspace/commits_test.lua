-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Check accepted commit messages and policy rejection diagnostics.
-- Part of repository automation regression tests; run from the root.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_lint_commit_policy_test_suite_main()
   local policy = dofile("scripts/workspace/lib/commit_message.lua")
   local dco = "\n\nSigned-off-by: Test User <test@example.org>\n"
   local cases = {
      { "fix: handle allocation failure" .. dco, true },
      { "feat(api)!: change allocation contract" .. dco, true },
      { "docs(c): explain ownership\n\nOptional body." .. dco, true },
      { "fix: " .. string.rep("é", 65) .. dco, true },
      { "fix: " .. string.rep("a", 66) .. dco, false },
      { "unknown: add allocation" .. dco, false },
      { "fix(): add allocation" .. dco, false },
      { "fix: " .. dco, false },
      { "fix: handle allocation failure", false },
      { "fix: handle allocation failure\nbody" .. dco, false },
      { "fix: handle allocation failure" .. dco .. "\nBody.", false },
      { "fix: handle failure\n\nSigned-off-by: invalid\n", false },
   }

   for index, case in ipairs(cases) do
      assert((#policy.validate(case[1]) == 0) == case[2], "case " .. index)
   end

   print(string.format("Commit policy: %d cases passed.", #cases))
end

return tests_lint_commit_policy_test_suite_main()

-- EOF


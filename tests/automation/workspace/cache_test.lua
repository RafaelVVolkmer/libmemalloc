-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Check owned temporary paths, cleanup restrictions, and repository containment.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_lint_cache_test_suite_main()
   local release = dofile("scripts/lib/artifacts.lua")
   local platform = release.platform
   local repository = release.output({ "git", "rev-parse", "--show-toplevel" })
   local count = 0

   for _, category in ipairs({
      "build",
      "tests",
      "tools",
      "logs",
      "ci",
      "cd",
      "tmp",
   }) do
      local directory = platform.temporary_directory(category)
      local prefix = repository .. "/.cache/" .. category .. "/"

      assert(
         directory:sub(1, #prefix) == prefix,
         "temporary directory escaped its category"
      )
      assert(release.exists(directory), "temporary directory was not allocated")

      platform.remove_temporary_directory(directory)
      assert(not release.exists(directory), "owned directory was not cleaned")

      count = count + 2
   end

   assert(
      not pcall(platform.temporary_directory, "../escape"),
      "traversal accepted"
   )
   assert(
      not pcall(platform.remove_temporary_directory, repository),
      "unowned cleanup accepted"
   )

   print(string.format("Cache policy: %d assertions passed.", count + 2))
end

return tests_lint_cache_test_suite_main()

-- EOF


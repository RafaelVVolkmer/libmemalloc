-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Positive and negative contracts for documentation task inventories.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_docs_policy_test_suite_main()
   local P = dofile("scripts/documentation/lib/policy.lua")
   local count = 0

   --- Compare document acceptance and diagnostics with the expected policy.
   -- @param path string: filesystem path selected by the caller.
   -- @param source any: source value inspected by this operation.
   -- @param accepted any: accepted supplied to this operation.
   -- @param diagnostic any: diagnostic supplied to this operation.
   -- @return nil: no values.
   local function check(path, source, accepted, diagnostic)
      local failures = P.check(path, source)

      assert((#failures == 0) == accepted, table.concat(failures, "; "))
      if diagnostic then
         assert(table.concat(failures, "; "):find(diagnostic, 1, true))
      end

      count = count + 1
   end

   check("docs/reference/example.md", "# Reference\n\nA contract.\n", true)
   check("docs/guide.md", "## Objective\n\nExplain the task.\n", true)
   check(
      "docs/guide.md",
      "# Guide\n\n- [ ] Review it.\n",
      false,
      "task inventory"
   )
   check("docs/guide.md", "```text\n[x] Done.\n```", false, "task inventory")
   check(
      ".github/PULL_REQUEST_TEMPLATE.md",
      "* [X] Done.\n",
      false,
      "task inventory"
   )
   check(
      "docs/guide.md",
      "## Review Checklist\n\nReview it.\n",
      false,
      "checklist section"
   )
   check("docs/specs/README.md", "- [ ] Review it.\n", false, "task inventory")
   check(
      "docs/specs/product-SDD.md",
      "## Checklist\n\n- [ ] Review it.\n",
      true
   )
   check(
      "docs/guide.md",
      "[External guidance](https://example.org/checklist.html)\n",
      true
   )

   print(
      string.format("Documentation policy: %d contract cases passed.", count)
   )
end

return tests_docs_policy_test_suite_main()

-- EOF


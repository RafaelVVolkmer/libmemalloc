-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Adversarial tests for compiler-dependency parsing and module boundaries.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_analysis_analysis_test_suite_main()
   local A = dofile("scripts/analysis/lib/architecture.lua")
   local values = A.dependencies(
      "deps: core/main.c \\\n core/a\\ b.h core/back\\\\slash.h\n"
   )

   assert(
      #values == 3
         and values[2] == "core/a b.h"
         and values[3] == "core/back\\slash.h",
      "dependency escapes were not decoded"
   )
   assert(
      not pcall(A.dependencies, "other: input.c"),
      "unexpected target accepted"
   )
   assert(not pcall(A.dependencies, "deps: "), "empty dependencies accepted")
   assert(
      not pcall(A.dependencies, "deps: broken\\"),
      "truncated escape accepted"
   )

   local modules = {
      {
         name = "alpha",
         root = "a/",
         public = { "a/api.h" },
         public_include = "a/include/",
      },
      {
         name = "beta",
         root = "b/",
         public = { "b/include/api.h" },
         public_include = "b/include/",
      },
   }

   assert(A.check("a/main.c", { "a/private.h", "b/include/api.h" }, modules))
   assert(
      not pcall(A.check, "a/main.c", { "b/private.h" }, modules),
      "private dependency accepted"
   )
   assert(
      not pcall(A.check, "unowned/main.c", {}, modules),
      "unowned source accepted"
   )
   assert(A.public_headers({ "b/include/api.h" }, modules))
   assert(
      not pcall(A.public_headers, { "b/include/private.h" }, modules),
      "private public-path header accepted"
   )

   print("Analysis policy: 9 parser and boundary assertions passed.")
end

return tests_analysis_analysis_test_suite_main()

-- EOF


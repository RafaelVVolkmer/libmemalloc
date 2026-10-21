-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Compare raw packages first; retain deep diagnostics without accepting drift.
-- Part of independent reconstruction and byte-comparison campaigns.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_reproducible_compare_main()
   local COMPARISON_MAX_REPORT_BYTES = 2000000

   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local tools = dofile("scripts/reproducible/lib/context.lua")
   local policy = dofile("tools/reproducible/policy.lua")
   local options =
      artifact_io.options(arg, { first = true, second = true, output = true })
   local first = assert(options.first, "--first is required")
   local second = assert(options.second, "--second is required")
   local output = assert(options.output, "--output is required")

   for _, path in ipairs({ first, second, output }) do
      artifact_io.safe_path(path)
      assert(path:match("^%.cache/"), "paths must stay in .cache")
   end

   assert(not artifact_io.exists(output), "comparison output must be fresh")

   artifact_io.mkdir(output)

   local expected = {}

   for _, build_type in ipairs(policy.build_types) do
      for _, linkage in ipairs(policy.linkages) do
         expected[#expected + 1] = build_type:lower()
            .. "-"
            .. linkage
            .. ".tar.gz"
      end
   end

   table.sort(expected)

   local result = {
      schema = policy.schema,
      scope = policy.scope,
      product_qualified = false,
      state = "FAIL",
      comparisons = artifact_io.array(),
   }
   local success, message = xpcall(
      --- Compare the complete declared file sets and retain byte-level
      -- differences.
      -- @return nil: no values.
      function()
         result.diffoscope = artifact_io.output({ "diffoscope", "--version" })
         for _, directory in ipairs({ first, second }) do
            assert(
               table.concat(artifact_io.files(directory), "\n")
                  == table.concat(expected, "\n"),
               "package inventory differs from the declared contract"
            )
         end

         local identical = true

         for _, name in ipairs(expected) do
            local a, b = first .. "/" .. name, second .. "/" .. name
            local first_hash, second_hash =
               artifact_io.digest(a), artifact_io.digest(b)
            local same = first_hash == second_hash

            result.comparisons[#result.comparisons + 1] = {
               artifact = name,
               first = first_hash,
               second = second_hash,
               state = same and "PASS" or "FAIL",
            }
            identical = identical and same

            local command = {
               "diffoscope",
               "--text",
               output .. "/" .. name .. ".txt",
               "--html",
               output .. "/" .. name .. ".html",
               "--max-report-size",
               tostring(COMPARISON_MAX_REPORT_BYTES),
               a,
               b,
            }
            local status =
               tools.status(command, output .. "/" .. name .. ".log")

            assert(
               status == 0 or status == 1,
               "diffoscope did not complete its comparison"
            )

            -- Some format comparators omit metadata; raw hashes remain
            -- authoritative.
            assert(
               not same or status == 0,
               "diffoscope rejected identical bytes"
            )
         end

         assert(
            identical,
            "raw package bytes differ; normalization cannot waive this"
         )
      end,
      debug.traceback
   )

   result.state = success and "PASS" or "FAIL"
   result.detail = success and "Every original package is byte-identical."
      or message
   artifact_io.document(output .. "/result.json", result)
   assert(success, message)

   print("Raw package comparison: PASS")
end

return scripts_reproducible_compare_main()

-- EOF


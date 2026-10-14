-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Reject missing packages, unexpected files and metadata-only byte drift.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_reproducible_comparison_test_suite_main()
   local R = dofile("scripts/lib/artifacts.lua")
   local T = dofile("scripts/reproducible/lib/context.lua")
   local options = R.options(arg, { input = true })
   local input = assert(options.input, "--input is required")

   R.safe_path(input)

   local directory = R.platform.temporary_directory("tests")
   local relative = directory:sub(#R.output({ "pwd" }) + 2)
   local copy = relative .. "/copy"

   --- Exercise independent rebuild comparisons before fixture cleanup.
   -- @return nil: no values.
   local success, message = xpcall(function()
      R.run({ "cp", "-a", input, copy })

      --- Require comparison to reject the selected inconsistent replica.
      -- @param id string: stable identity used to match the requested entry.
      -- @return nil: no values.
      local function rejected(id)
         local output = relative .. "/" .. id
         local code = T.status({
            "lua",
            "scripts/reproducible/compare.lua",
            "--first=" .. input,
            "--second=" .. copy,
            "--output=" .. output,
         }, directory .. "/" .. id .. ".log")

         assert(code ~= 0, "invalid package set accepted")
         assert(
            R.query(output .. "/result.json", ".state") == "FAIL",
            "invalid package set did not retain a failure report"
         )
      end

      local name = assert(R.files(input)[1], "missing comparison fixture")
      local file = copy .. "/" .. name
      local bytes = R.read(file)

      assert(bytes:sub(1, 2) == string.char(31, 139), "fixture is not gzip")

      -- Gzip's mtime is outside the compressed payload and its content
      -- checksum.
      local timestamp_byte = (bytes:byte(5) + 1) % 256

      R.write(
         file,
         bytes:sub(1, 4) .. string.char(timestamp_byte) .. bytes:sub(6)
      )
      rejected("metadata-drift")
      R.write(file, bytes)

      assert(os.rename(file, relative .. "/held.gz"))

      rejected("missing-package")
      assert(os.rename(relative .. "/held.gz", file))

      R.write(copy .. "/unexpected.txt", "unplanned output\n")
      rejected("unexpected-package")
   end, debug.traceback)

   R.platform.remove_temporary_directory(directory)
   assert(success, message)

   print(
      "Comparison rejects metadata drift and incomplete package inventories."
   )
end

return tests_reproducible_comparison_test_suite_main()

-- EOF


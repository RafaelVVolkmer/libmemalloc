-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Prove that the comparator rejects drift and the normalizer preserves data.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_reproducible_tools_test_suite_main()
   local R = dofile("scripts/lib/artifacts.lua")
   local tools = dofile("scripts/reproducible/lib/context.lua")
   local root = R.platform.temporary_directory("tests")

   --- Normalize archive metadata through the pinned tool adapter.
   -- @param path string: filesystem path selected by the caller.
   -- @return nil: no values.
   local function normalize(path)
      R.run({ "strip-nondeterminism", "--type=gzip", "--timestamp=1", path })
   end

   --- Compare archive bytes and content before removing temporary inputs.
   -- @return nil: no values.
   local success, message = xpcall(function()
      for _, id in ipairs({ "a", "b" }) do
         local path = root .. "/" .. id .. "/sample"

         R.write(path, "same package content\n")
         R.run({ "touch", "-d", id == "a" and "@100" or "@200", path })
         R.run({ "gzip", path })
      end

      local a, b = root .. "/a/sample.gz", root .. "/b/sample.gz"

      assert(
         R.digest(a) ~= R.digest(b),
         "negative fixture is unexpectedly equal"
      )

      local changed = root .. "/changed/sample"

      R.write(changed, "different package content\n")
      R.run({ "gzip", changed })

      local command = {
         "diffoscope",
         "--text",
         root .. "/difference.txt",
         a,
         changed .. ".gz",
      }
      local code = tools.status(command, root .. "/diffoscope.log")

      assert(code == 1, "diffoscope failed to detect changed content")

      normalize(a)
      normalize(b)
      assert(R.digest(a) == R.digest(b), "gzip timestamps were not normalized")
      assert(
         R.output({ "gzip", "-cd", a }) == "same package content",
         "normalization changed decompressed content"
      )

      local digest = R.digest(a)

      normalize(a)
      assert(R.digest(a) == digest, "normalization is not idempotent")
   end, debug.traceback)

   R.platform.remove_temporary_directory(root)
   assert(success, message)

   print("diffoscope detects drift; strip-nondeterminism preserves content.")
end

return tests_reproducible_tools_test_suite_main()

-- EOF


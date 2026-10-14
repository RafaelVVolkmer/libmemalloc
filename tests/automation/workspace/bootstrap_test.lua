-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Challenge bootstrap reuse with changed inputs, tampering and failed repairs.
-- @return nil: no values.
local function BOOTSTRAP_TEST_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local state = dofile("scripts/workspace/lib/bootstrap.lua")
   local root = artifacts.platform.temporary_directory("tests")
   local receipt = root .. "/receipt"
   local product = root .. "/product"
   local installs, healthy = 0, true

   --- Model a successful installer with an independently checked runtime.
   -- @return nil: no values.
   local function install()
      installs = installs + 1
      healthy = true
      artifacts.write(product, "reviewed runtime\n")
   end

   --- Exercise the real persisted receipt rather than mocked cache decisions.
   -- @param identity table: declared source, tool or artifact identity.
   -- @return any: exercise the real persisted receipt rather than mocked cache
   -- decisions.
   local function ensure(identity)
      --- Return the controlled runtime health used by receipt validation.
      -- @return any: the controlled runtime health used by receipt validation.
      return state.ensure(receipt, identity, { product }, function()
         return healthy
      end, install)
   end

   assert(
      ensure("inputs-1") and installs == 1,
      "first bootstrap did not install"
   )
   assert(not ensure("inputs-1") and installs == 1, "valid tool was rebuilt")
   assert(ensure("inputs-2") and installs == 2, "changed inputs were ignored")
   artifacts.write(product, "tampered\n")
   assert(ensure("inputs-2") and installs == 3, "altered tool was reused")
   assert(os.remove(product))
   assert(ensure("inputs-2") and installs == 4, "missing tool was reused")
   healthy = false
   assert(ensure("inputs-2") and installs == 5, "broken runtime was reused")
   --- Model a successful runtime probe before an interrupted installation.
   -- @return boolean: model a successful runtime probe before an interrupted
   -- installation.
   assert(not pcall(state.ensure, receipt, "inputs-3", { product }, function()
      return true
      --- Interrupt repair before the receipt may be published.
      -- @return nil: no values.
   end, function()
      error("interrupted installer")
   end), "interrupted installation succeeded")
   assert(not artifacts.exists(receipt), "failed repair retained its receipt")
   assert(
      ensure("inputs-3") and installs == 6,
      "interrupted installation was not retried"
   )
   artifacts.platform.remove_temporary_directory(root)
   print(
      "Bootstrap reuse: identity, byte integrity, runtime "
         .. "and interrupted repair passed."
   )
end

return BOOTSTRAP_TEST_main()

-- EOF


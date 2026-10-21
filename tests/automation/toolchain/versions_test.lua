-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Verify the isolated behavior owned by this suite.
-- @return nil: no values.
local function VERSIONS_TEST_main()
   local versions = dofile("scripts/toolchain/lib/versions.lua")

   assert(versions.matches("tool v1.2.3\n", "1.2.3"))
   assert(
      not versions.matches("tool 1.2.30", "1.2.3"),
      "version prefix accepted"
   )
   assert(
      not versions.matches("tool 1.2.3-beta", "1.2.3"),
      "prerelease accepted"
   )
   assert(not versions.matches(nil, "1.2.3"), "missing version accepted")
   print("Tool version matching passed.")
end

return VERSIONS_TEST_main()

-- EOF


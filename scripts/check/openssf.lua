-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Validate evidence relationships. Governance claims require external
-- evidence.
-- Part of local and CI verification gates.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_check_openssf_main()
   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local options = artifact_io.options(arg, { root = true, production = true })

   artifact_io.query(
      "tools/release/policy.json",
      (
         ".schema == 1 and (.production_ready | type == "
         .. '"boolean") and (.required_tests | length > 0)'
      )
   )
   if options.root then
      artifact_io.verify(options.root)

      dofile("scripts/release/lib/evidence.lua").validate(options.root)
   end

   if options.production then
      assert(options.root, "production checks require a release root")
      assert(
         artifact_io.query(
            "tools/release/policy.json",
            ".production_ready | tostring"
         ) == "true",
         "production release is not qualified"
      )
      assert(
         artifact_io.query(
            options.root .. "/identity/build-id.json",
            ".mock | tostring"
         ) == "false",
         "mock publication is forbidden"
      )

      error(
         (
            "production builder, scanner policy, and platform "
            .. "provenance qualification are required"
         )
      )
   end

   print(
      (
         "OpenSSF evidence checks passed for the mock "
         .. "profile; Gold and SLSA levels remain unqualified."
      )
   )
end

return scripts_check_openssf_main()

-- EOF


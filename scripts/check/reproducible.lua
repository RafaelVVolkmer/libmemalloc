-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Verify the recorded byte comparisons against the current release payloads.
-- Part of local and CI verification gates.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_check_reproducible_main()
   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local options = artifact_io.options(arg, { root = true })
   local root = assert(options.root, "--root is required")

   artifact_io.verify(root)

   dofile("scripts/release/lib/evidence.lua").reproducible(root)

   print(
      (
         "Ten mock payloads match both clean builds; "
         .. "independent-builder qualification remains pending."
      )
   )
end

return scripts_check_reproducible_main()

-- EOF


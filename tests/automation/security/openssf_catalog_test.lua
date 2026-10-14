-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Verify the isolated behavior owned by this suite.
-- @return nil: no values.
local function OPENSSF_CATALOG_TEST_main()
   local projects = dofile("tools/security/openssf/projects.lua")
   local project_count = 0

   for _, project in pairs(projects) do
      project_count = project_count + 1

      if project.mode == "blocked" then
         assert(
            type(project.reason) == "string" and #project.reason > 20,
            "blocked adapter must explain its prerequisite"
         )
      end

      if project.module then
         assert(
            project.version:match("^v%d+%.%d+%.%d+$"),
            "unversioned Go tool"
         )
      end
   end

   assert(project_count == 20, "OpenSSF project catalog is incomplete")

   print("OpenSSF catalog: 20 entries inspected.")
end

return OPENSSF_CATALOG_TEST_main()

-- EOF


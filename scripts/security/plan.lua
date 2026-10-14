-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Use the adapter catalog as the only authority for the assessment matrix.
-- Part of security-adapter planning, execution and evidence reports.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_security_plan_main()
   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local projects = dofile("tools/security/openssf/projects.lua")
   local names = artifact_io.array()

   for name in pairs(projects) do
      names[#names + 1] = name
   end

   table.sort(names)

   local matrix = artifact_io.json({ project = names })
   local output = os.getenv("GITHUB_OUTPUT")

   if output then
      local file = assert(io.open(output, "a"))

      assert(file:write("matrix=" .. matrix .. "\n"))
      assert(file:close())
   end

   print(matrix)
end

return scripts_security_plan_main()

-- EOF


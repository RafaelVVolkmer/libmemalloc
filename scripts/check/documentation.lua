-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Enforce the document policy and scope of task inventories.
-- Part of local and CI verification gates.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_check_documentation_main()
   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local policy = dofile("scripts/documentation/lib/policy.lua")
   local git = dofile("scripts/lib/git.lua").new(artifact_io.platform, ".")
   local paths = assert(git.working_files(), "cannot list working sources")
   local seen, checked, failed = {}, 0, 0

   for _, path in ipairs(paths) do
      if
         (path:match("%.md$") or path:match("%.markdown$"))
         and not seen[path]
         and artifact_io.exists(path)
      then
         seen[path] = true
         checked = checked + 1
         for _, failure in ipairs(policy.check(path, artifact_io.read(path))) do
            io.stderr:write(path .. ": " .. failure .. "\n")

            failed = failed + 1
         end
      end
   end

   assert(checked > 0, "no authored Markdown documents found")

   print(
      string.format(
         "Documentation policy: %d files; %d failures.",
         checked,
         failed
      )
   )
   assert(failed == 0, "documentation policy failed")
end

return scripts_check_documentation_main()

-- EOF


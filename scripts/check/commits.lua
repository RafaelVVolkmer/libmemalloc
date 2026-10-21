-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Validate the selected commit range against the repository message policy.
-- Part of local and CI verification gates.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_check_commits_main()
   local platform = dofile("scripts/lib/platform.lua")
   local policy = dofile("scripts/workspace/lib/commit_message.lua")
   local revision = assert(arg[1], "expected SHA or --message-file PATH")
   local message
   local merge = false

   if revision == "--message-file" then
      assert(#arg == 2, "--message-file requires one path")

      local file = assert(io.open(arg[2], "rb"))

      message = assert(file:read("*a"))
      assert(file:close())

      revision = arg[2]
   else
      assert(
         #arg == 1 and revision:match("^%x+$"),
         "expected a hexadecimal commit ID"
      )

      local parents = assert(platform.command_output({
         "git",
         "show",
         "--no-patch",
         "--format=%P",
         revision,
         "--",
      }))

      merge = policy.is_merge(parents)

      message = assert(platform.command_output({
         "git",
         "show",
         "--no-patch",
         "--format=%B",
         revision,
         "--",
      }))
   end

   local errors = policy.validate(message, merge)

   for _, diagnostic in ipairs(errors) do
      io.stderr:write(revision .. ": " .. diagnostic .. "\n")
   end

   os.exit(#errors == 0 and 0 or 1)
end

return scripts_check_commits_main()

-- EOF


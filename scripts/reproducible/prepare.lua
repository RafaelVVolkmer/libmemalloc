-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Freeze only declared build inputs, including uncommitted review changes.
-- Part of independent reconstruction and byte-comparison campaigns.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_reproducible_prepare_main()
   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local policy = dofile("tools/reproducible/policy.lua")
   local options = artifact_io.options(arg, { output = true })
   local output = assert(options.output, "--output is required")

   artifact_io.safe_path(output)
   assert(output:match("^%.cache/"), "staging must stay in .cache")
   assert(not artifact_io.exists(output), "staging must be fresh")

   artifact_io.mkdir(output)

   local command = {
      "git",
      "ls-files",
      "-z",
      "--cached",
      "--others",
      "--exclude-standard",
      "--",
   }

   for _, path in ipairs(policy.source_paths) do
      artifact_io.safe_path(path)

      command[#command + 1] = path
   end

   local listed = artifact_io.output(command)

   assert(listed ~= "", "no declared build sources found")
   for path in listed:gmatch("([^%z]+)%z") do
      artifact_io.safe_path(path)
      assert(not artifact_io.platform.command_succeeded_silent({
         "test",
         "-L",
         path,
      }), "source symlinks require a separate input policy")

      artifact_io.mkdir(output .. "/" .. (path:match("^(.*)/") or "."))

      artifact_io.run({ "cp", "-p", "--", path, output .. "/" .. path })
   end

   local epoch =
      artifact_io.output({ "git", "show", "-s", "--format=%ct", "HEAD" })

   artifact_io.write(output .. "/source-epoch.txt", epoch .. "\n")

   print("Prepared declared mock inputs at " .. output)
end

return scripts_reproducible_prepare_main()

-- EOF


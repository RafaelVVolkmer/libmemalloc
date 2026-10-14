-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Check tracked Markdown while keeping Lychee's fixed-name cache out of
-- sources.
-- Part of local and CI verification gates.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_check_links_main()
   local release = dofile("scripts/lib/artifacts.lua")
   local options = release.options(arg, { offline = true, tool = true })
   local root = release.output({ "git", "rev-parse", "--show-toplevel" })
   local directory = root .. "/.cache/ci/lychee"
   local command = {
      options.tool or "lychee",
      "--config",
      root .. "/tools/lint/spell/lychee/lychee.toml",
      "--cache",
      "--root-dir",
      root,
   }

   local git = dofile("scripts/lib/git.lua").new(release.platform, root)
   local files = assert(git.working_files(), "cannot discover source inputs")
   local checked = 0

   release.mkdir(directory)

   if options.offline then
      command[#command + 1] = "--offline"
   end

   for _, path in ipairs(files) do
      if path:match("%.md$") or path:match("%.markdown$") then
         command[#command + 1] = root .. "/" .. path
         checked = checked + 1
      end
   end

   assert(checked > 0, "no Markdown inputs")

   release.platform.run_in_directory(directory, command)
end

return scripts_check_links_main()

-- EOF


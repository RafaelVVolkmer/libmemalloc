-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Run from the repository root; build and eval never download dependencies.
-- Part of Doxygen generation and authored-document validation.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_documentation_main_main()
   if arg[1] == "--help" then
      print([[
Usage: lua scripts/documentation/main.lua [build|eval] [options]
  --source=PATH     Replace implementation roots; repeat for multiple folders.
  --page=PATH       Add a Markdown/Doxygen page or a directory of pages.
  --images=PATH     Add an image file or a recursively searched directory.
  --mainpage=PATH   Select a Markdown landing page.
  --output=PATH     Write below .cache/ (default: .cache/docs/doxygen-MODE).
  --config=PATH     Load trusted project settings.
                    Default: scripts/documentation/config.lua.
Default implementations: core/. Paths may start with ./.
LIBMEMALLOC_DOXYGEN and LIBMEMALLOC_LUA select the executables.
]])

      return
   end

   local documentation = dofile("scripts/documentation/lib/driver.lua")

   documentation.run(documentation.options(arg))
end

return scripts_documentation_main_main()

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Explicit native C analysis policy; no blanket finding suppressions.

--- Construct this module within its own initialization scope.
-- @return table: this module within its own initialization scope.
local function tools_lint_code_c_scanners_loadModule()
   return {
      cppcheck = {
         "--enable=warning,style,performance,portability",
         "--error-exitcode=1",
         "--check-level=exhaustive",
         "--std=c23",
         "--language=c",
         "--library=std",
         "--template=gcc",
         "-I.",
      },
      flawfinder = {
         "--quiet",
         "--dataonly",
         "--columns",
         "--minlevel=1",
         "--error-level=3",
         "--neverignore",
      },
   }
end

return tools_lint_code_c_scanners_loadModule()

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Initial module boundary; extend this inventory with real production modules.

--- Construct this module within its own initialization scope.
-- @return table: this module within its own initialization scope.
local function tools_analysis_c_modules_loadModule()
   return {
      build_interface = {
         include = "include",
         paths = { "include", "include/libmemalloc" },
         headers = { ["libmemalloc/mock.h"] = "core/mock.h" },
      },
      modules = {
         {
            name = "mock",
            root = "core/",
            public = { "core/mock.h" },
         },
      },
      forbidden_references = {
         "malloc",
         "calloc",
         "realloc",
         "free",
         "system",
         "exit",
      },
   }
end

return tools_analysis_c_modules_loadModule()

-- EOF


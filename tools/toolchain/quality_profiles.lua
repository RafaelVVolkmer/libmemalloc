-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Share quality installation profiles with automatic task preparation.
-- @return table: share quality installation profiles with automatic task
-- preparation.
local function QUALITY_PROFILES_loadModule()
   local catalog = dofile("tools/toolchain/quality.lua")

   return {
      all = {
         archives = catalog,
         python = "quality,python-lint,lint",
         probe = "import lizard, luaparser, cmakelang, yaml, reuse, bandit",
         commands = {
            "codespell",
            "yamllint",
            "reuse",
            "cmake",
            "ctest",
            "cpack",
            "ninja",
            "clang-format",
            "clang-tidy",
            "flawfinder",
            "ruff",
            "bandit",
            "conan",
            "cmake-format",
            "cmake-lint",
            "lizard",
         },
         node = { "md", "web", "quality" },
         rust = { "selene", "taplo" },
      },
      build = {
         archives = {},
         python = "c-tools",
         probe = "import cmake, ninja",
         commands = {
            "cmake",
            "ctest",
            "cpack",
            "ninja",
            "clang-format",
            "clang-tidy",
            "flawfinder",
         },
         node = {},
         rust = {},
      },
      spelling = {
         archives = { node = true, vale = true, lychee = true, typos = true },
         python = "spelling",
         probe = "import codespell_lib",
         commands = { "codespell" },
         node = { "quality" },
         rust = {},
      },
      lua = {
         archives = { stylua = true, lua_language_server = true },
         python = "quality",
         probe = "import lizard, luaparser, cmakelang",
         commands = { "lizard" },
         node = {},
         rust = { "selene" },
      },
   }
end

return QUALITY_PROFILES_loadModule()

-- EOF


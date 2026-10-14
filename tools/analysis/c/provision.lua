-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Analysis groups select packages; the installer implements package transport.

--- Construct this module within its own initialization scope.
-- @return table: this module within its own initialization scope.
local function tools_analysis_c_provision_loadModule()
   return {
      directory_prefix = ".cache/tools/c-analysis-",
      groups = {
         rules = {
            packages = {
               { name = "gcc-", lock = "gcc_analyzer" },
               { name = "gcc-mingw-w64-x86-64" },
               { name = "clang-", lock = "clang_analyzer" },
            },
            python = {},
         },
         csa = {
            packages = {
               { name = "clang-", lock = "clang_analyzer" },
               { name = "clang-tools-", lock = "clang_analyzer" },
               { name = "llvm-", lock = "clang_analyzer" },
            },
            python = { "codechecker" },
         },
         extended = {
            packages = { { name = "sparse" } },
            python = {},
         },
      },
   }
end

return tools_analysis_c_provision_loadModule()

-- EOF


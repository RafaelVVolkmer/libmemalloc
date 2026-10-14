-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Declare automatic preparation by canonical command, including aliases.
-- @return table: declare automatic preparation by canonical command, including
-- aliases.
local function PREPARATION_POLICY_loadModule()
   return {
      ["scripts/check/lua.lua"] = "lua",
      ["scripts/check/spelling.lua"] = "spelling",
      ["scripts/check/links.lua"] = "spelling",
      ["tests/automation/workspace/commit_links_test.lua"] = "spelling",
      ["scripts/check/all.lua"] = "all",
      ["scripts/check/automation.lua"] = "all",
      ["scripts/check/c.lua"] = "all",
      ["scripts/check/cmake.lua"] = "all",
      ["scripts/check/mermaid.lua"] = "all",
      ["scripts/check/web.lua"] = "all",
      ["scripts/documentation/main.lua"] = "all",
      ["scripts/build/local.lua"] = "build",
   }
end

return PREPARATION_POLICY_loadModule()

-- EOF


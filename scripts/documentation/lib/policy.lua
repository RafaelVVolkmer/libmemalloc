-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Structural rules for authored Markdown and product task inventories.
-- Part of Doxygen generation and authored-document validation.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_documentation_lib_policy_loadModule()
   local exports = {}

   --- Confine task inventories to product specifications.
   -- @param path string: filesystem path selected by the caller.
   -- @param source string: source supplied to this operation.
   -- @return table: confine task inventories to product specifications.
   local function DOCUMENTATION_POLICY_check(path, source)
      local failures = {}
      local sdd = path:match("^docs/specs/[^/]+%-SDD%.md$")
      local visible = source:gsub("<!%-%-.-%-%->", "")

      for line in (visible .. "\n"):gmatch("(.-)\n") do
         if not sdd then
            if line:match("^%s*[-*+]?%s*%[[ xX]%]%s+") then
               failures[#failures + 1] = "task inventory outside a product SDD"
            end

            if line:lower():match("^#+%s+.*checklist") then
               failures[#failures + 1] =
                  "checklist section outside a product SDD"
            end
         end
      end

      return failures
   end

   exports.check = DOCUMENTATION_POLICY_check

   return exports
end

return scripts_documentation_lib_policy_loadModule()

-- EOF


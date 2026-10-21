-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Qualified source inventory for the distribution fixture, not an allocator.

--- Construct this module within its own initialization scope.
-- @return table: this module within its own initialization scope.
local function tools_analysis_c_profile_loadModule()
   local inventory = dofile("scripts/build/lib/sources.lua")
   local sources = {}
   for _, list in ipairs({
      inventory.LMA_LIBRARY_SOURCES,
      inventory.LMA_CONSUMER_SOURCES,
   }) do
      for _, path in ipairs(list) do
         sources[#sources + 1] = path
      end
   end
   table.sort(sources)
   return {
      name = "hosted-lp64",
      sources = sources,
      headers = inventory.LMA_CORE_HEADERS,
      dialect = "c99",
      csa_checkers = { "core", "unix", "deadcode", "prefix:security" },
      limitations = {
         "The mock has no allocator, atomic operations, or concurrent state.",
         "No production allocator property is established by these campaigns.",
         (
            "System tool patch versions and executable "
            .. "digests are recorded per run."
         ),
      },
   }
end

return tools_analysis_c_profile_loadModule()

-- EOF


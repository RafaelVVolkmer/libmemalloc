-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Qualified source inventory for the distribution fixture, not an allocator.

--- Construct this module within its own initialization scope.
-- @return table: this module within its own initialization scope.
local function tools_analysis_c_profile_loadModule()
   return {
      name = "hosted-lp64",
      sources = { "core/main.c", "core/mock.c" },
      headers = { "core/mock.h" },
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


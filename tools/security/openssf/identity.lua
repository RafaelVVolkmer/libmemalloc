-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Public assessment identity; no credential belongs in this catalog.

--- Construct this module within its own initialization scope.
-- @return table: this module within its own initialization scope.
local function tools_security_openssf_identity_loadModule()
   return {
      repository = "RafaelVVolkmer/libmemalloc",
      badge_project = "12710",
      license = "GPL-3.0-only",
   }
end

return tools_security_openssf_identity_loadModule()

-- EOF


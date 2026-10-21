-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Trusted project inputs; source roots are recursive implementation folders.
-- Part of Doxygen generation and authored-document validation.

--- Construct this module within its own initialization scope.
-- @return table: this module within its own initialization scope.
local function scripts_documentation_config_loadModule()
   return {
      implementations = { "core" },
      pages = { "doxygen/pages/index.dox", "docs" },
      references = {
         { title = "GOVERNANCE", path = "GOVERNANCE.md" },
         { title = "MAINTAINERS", path = "MAINTAINERS.md" },
         { title = "REVIEWING", path = "REVIEWING.md" },
         { title = "ROADMAP", path = "ROADMAP.md" },
         { title = "SECURITY", path = "SECURITY.md" },
         { title = "SUPPORT", path = "SUPPORT.md" },
         { title = "CHANGELOG", path = "CHANGELOG.md" },
         { title = "CODE_OF_CONDUCT", path = "CODE_OF_CONDUCT.md" },
         {
            title = "LICENSE",
            path = "doxygen/pages/license.dox",
            target = "project_license",
         },
         { title = "CONTRIBUTING", path = ".github/CONTRIBUTING.md" },
      },
      mainpage = "README.md",
      -- Existing roots are searched recursively; missing optional roots are OK.
      images = { "assets/images", "doc", "docs" },
      logo = "assets/images/libmemalloc_logo.svg",
      -- Bounds of the mascot layer, padded to a square for the favicon/header.
      logo_viewbox = "-28 28 720 720",
      theme = "doxygen/vendor/doxygen-awesome-css",
   }
end

return scripts_documentation_config_loadModule()

-- EOF


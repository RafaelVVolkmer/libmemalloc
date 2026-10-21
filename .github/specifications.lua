-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Define maintainer-owned specification labels and their SDD boundaries.
-- GitHub issue automation and local validation share this catalog.

--- Return a fresh catalog for each caller.
-- @return table: a fresh catalog for each caller.
local function SPECIFICATIONS_loadModule()
   return {
      maintainers = { RafaelVVolkmer = true },
      labels = {
         {
            name = "spec",
            color = "5319e7",
            description = "Maintainer-approved SDD work",
         },
         {
            name = "compilation",
            color = "0052cc",
            description = "SDD: compilation and delivery",
         },
         {
            name = "core-implementation",
            color = "0052cc",
            description = "SDD: manual allocation core",
         },
         {
            name = "distribution",
            color = "0052cc",
            description = "SDD: distribution and packaging",
         },
         {
            name = "gc-implementation",
            color = "0052cc",
            description = "SDD: optional garbage collector",
         },
         {
            name = "security",
            color = "b60205",
            description = "SDD: security requirements",
         },
         {
            name = "tests",
            color = "0052cc",
            description = "SDD: tests and evidence",
         },
      },
      specification_directory = "docs/specs/",
      specification_prefix = "libmemalloc-",
      specification_suffix = "-SDD.md",
   }
end

return SPECIFICATIONS_loadModule()

-- EOF


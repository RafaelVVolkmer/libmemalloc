-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Authoritative specification inventory; no directory-order dependency.
-- @return table: authoritative specification inventory; no directory-order
-- dependency.
local function SDD_CATALOG_loadModule()
   return {
      "docs/specs/libmemalloc-core-implementation-SDD.md",
      "docs/specs/libmemalloc-gc-implementation-SDD.md",
      "docs/specs/libmemalloc-compilation-SDD.md",
      "docs/specs/libmemalloc-security-SDD.md",
      "docs/specs/libmemalloc-tests-SDD.md",
      "docs/specs/libmemalloc-distribution-SDD.md",
   }
end

return SDD_CATALOG_loadModule()

-- EOF


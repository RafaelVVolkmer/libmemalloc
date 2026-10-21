-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Inputs, transformations and environment variations for the mock packages.

--- Construct this module within its own initialization scope.
-- @return table: this module within its own initialization scope.
local function tools_reproducible_policy_loadModule()
   return {
      schema = 1,
      scope = "distribution-mock",
      compiler = "gcc-13",
      compiler_lock = "build_gcc13",
      build_types = { "Debug", "Release" },
      linkages = { "static", "shared" },
      source_paths = {
         "CMakeLists.txt",
         "LICENSE",
         "core",
         "cmake",
         "packaging",
         "scripts/reproducible/build.lua",
         "scripts/process",
         "scripts/verification/lib/files.lua",
         "scripts/verification/lib/resources.lua",
         "scripts/workspace/lib/runtime.lua",
         "scripts/lib/artifacts.lua",
         "scripts/lib/platform.lua",
         "scripts/toolchain/lib/lock.lua",
         "scripts/workspace/lib/lock.lua",
         "scripts/workspace/lib/lease.lua",
         "tools/process",
         "tools/workspace/preparation.lua",
         "tools/toolchain/lock.toml",
         "tools/reproducible/policy.lua",
      },
      build_dependencies = {
         "build-essential",
         "pkg-config",
         "libselinux1-dev",
      },
      apt = {
         reprotest = "reprotest",
         diffoscope = "diffoscope-minimal",
         disorderfs = "disorderfs",
         strip_nondeterminism = "strip-nondeterminism",
         faketime = "faketime",
      },
      variations = {
         environment = table.concat({
            "-all",
            "environment",
            "build_path",
            "locales.locale=C.UTF-8",
            "num_cpus",
            "time",
            "timezone",
            "umask",
         }, ","),
         filesystem = "-all,fileordering",
      },
   }
end

return tools_reproducible_policy_loadModule()

-- EOF


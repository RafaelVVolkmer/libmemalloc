-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Validate owned CMake modules and executable multi-configuration regressions.
-- Part of the C analysis gate; generated and vendored files are outside scope.

--- Discover repository inputs and run both CMake validators before tests.
-- @return nil: no values.
local function CMAKE_CHECK_main()
   local CMAKE_ARGV_BATCH_SIZE = 64

   local io_tools = dofile("scripts/lib/artifacts.lua")
   local lint = os.getenv("LIBMEMALLOC_CMAKE_LINT") or "cmake-lint"
   local format = os.getenv("LIBMEMALLOC_CMAKE_FORMAT") or "cmake-format"
   local lua = os.getenv("LIBMEMALLOC_LUA") or "lua"
   local config = "tools/lint/code/cmake/config.json"
   local files = {}
   local git = dofile("scripts/lib/git.lua").new(io_tools.platform, ".")
   local inventory = assert(git.working_files(), "cannot list working sources")

   for _, path in ipairs(inventory) do
      if
         (path:match("%.cmake$") or path:match("CMakeLists%.txt$"))
         and not path:match("^doxygen/vendor/")
         and io_tools.exists(path)
      then
         files[#files + 1] = path
      end
   end

   assert(#files > 0, "CMake inventory is empty")
   io_tools.platform.run_batched(
      { lint, "-c", config, "--" },
      files,
      CMAKE_ARGV_BATCH_SIZE
   )
   io_tools.platform.run_batched({
      lua,
      "scripts/check/format.lua",
      "cmake",
      format,
   }, files, CMAKE_ARGV_BATCH_SIZE)
   io_tools.run({ lua, "tests/automation/build/cmake_test.lua" })
   io_tools.run({ lua, "tests/automation/build/consumer_test.lua" })
   io_tools.run({ lua, "tests/automation/build/readme_test.lua" })
   io_tools.run({ lua, "tests/automation/build/windows_pkgconfig_test.lua" })
end

return CMAKE_CHECK_main()

-- EOF


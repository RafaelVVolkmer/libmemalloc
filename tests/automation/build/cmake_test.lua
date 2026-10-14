-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Exercise Debug and Release in one multi-config tree and reject invalid
-- policy.
-- Part of general build integration; no allocator behavior is claimed.

--- Configure once, execute both configurations and inspect their actual
-- commands.
-- @return nil: no values.
local function CMAKE_TEST_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local execution = dofile("scripts/process/lib/exec.lua")
   local cmake = os.getenv("LIBMEMALLOC_CMAKE") or "cmake"
   local root = artifacts.platform.temporary_directory("tests")
   local build = root .. "/multi"

   --- Retain failures while avoiding command-shell argument interpretation.
   -- @param argv table: dense executable-and-arguments sequence; values remain
   -- literal.
   -- @return any: retain failures while avoiding command-shell argument
   -- interpretation.
   local function run(argv)
      local result = execution.run(argv, { timeout_ms = 180 * 1000 })

      assert(result.state == "PASS", result.stdout .. result.stderr)

      return result.stdout
   end

   run({
      cmake,
      "-S",
      ".",
      "-B",
      build,
      "-G",
      "Ninja Multi-Config",
      "-DLMA_BUILD_MOCK=ON",
      "-DLMA_BUILD_TESTS=ON",
      "-DBUILD_SHARED_LIBS=ON",
   })
   local ctest = cmake:match("^(.*)/cmake$")

   ctest = ctest and ctest .. "/ctest" or "ctest"
   for _, configuration in ipairs({ "Debug", "Release" }) do
      local output = run({
         cmake,
         "--build",
         build,
         "--config",
         configuration,
         "--verbose",
      })

      if configuration == "Release" then
         assert(
            not output:find(" -g3", 1, true),
            "debug-only flags leaked into Release"
         )
      else
         assert(
            not output:find("--strip-all", 1, true),
            "release stripping leaked into Debug"
         )
      end

      local metadata = build .. "/metadata/" .. configuration
      local database = artifacts.read(metadata .. "/compile_commands.json")

      assert(database:find("\n", 1, true), "Metadata must be readable")
      assert(not database:find(root, 1, true), "Temporary path leaked")
      for _, other in ipairs({ "Debug", "Release", "RelWithDebInfo" }) do
         if other ~= configuration then
            assert(
               not database:find(".dir/" .. other .. "/", 1, true),
               "Other configuration leaked into " .. configuration
            )
         end
      end

      assert(database:find(".dir/" .. configuration .. "/", 1, true))
      assert(
         artifacts.query(metadata .. "/build.json", ".configuration")
            == configuration,
         "Wrong metadata configuration"
      )
      local binary = artifacts.query(metadata .. "/build.json", ".binary")

      assert(
         artifacts.query(metadata .. "/build.json", ".binary_sha256")
            == artifacts.digest(
               build .. "/lib/" .. configuration .. "/" .. binary
            ),
         "Metadata binary digest differs"
      )
      run({
         ctest,
         "--test-dir",
         build,
         "-C",
         configuration,
         "--output-on-failure",
         "--no-tests=error",
      })
   end

   for index, invalid in ipairs({ "-DLMA_IPO=invalid", "-DLMA_CET=invalid" }) do
      local result = execution.run({
         cmake,
         "-S",
         ".",
         "-B",
         root .. "/invalid-" .. index,
         "-DLMA_BUILD_MOCK=ON",
         invalid,
      }, { timeout_ms = 30000 })

      assert(result.state == "FAIL", "invalid build policy accepted")
   end

   -- Rejected groups must preserve valid diagnostics and isolate invalid flags.
   local probe = root .. "/warning-probe"

   artifacts.write(
      probe .. "/CMakeLists.txt",
      "cmake_minimum_required(VERSION 3.20)\nproject(probe C)\n"
         .. "add_library(probe STATIC probe.c)\ninclude("
         .. artifacts.output({ "git", "rev-parse", "--show-toplevel" })
         .. "/cmake/compiler-flags.cmake)\n"
         .. "lma_warning_group(probe -Wall -Wlma-invalid-warning -Wextra)\n"
         .. "get_target_property(flags probe COMPILE_OPTIONS)\n"
         .. 'file(WRITE "${CMAKE_BINARY_DIR}/flags.txt" "${flags}")\n'
   )
   artifacts.write(probe .. "/probe.c", "int probe(void) { return 0; }\n")
   run({ cmake, "-S", probe, "-B", probe .. "/build" })
   local flags = artifacts.read(probe .. "/build/flags.txt")

   assert(
      flags:find("-Wall", 1, true) and flags:find("-Wextra", 1, true),
      "supported warnings were omitted"
   )
   assert(
      not flags:find("-Wlma-invalid-warning", 1, true),
      "invalid flag admitted"
   )

   artifacts.platform.remove_temporary_directory(root)
   print(
      "CMake policy: multi-config builds, executable tests "
         .. "and invalid-policy rejection passed."
   )
end

return CMAKE_TEST_main()

-- EOF


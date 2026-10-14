-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Produce scoped observations for documentation, compilation and regressions.
-- These process controls retain output in the evidence engine; none qualifies
-- allocator semantics or authorizes a release.

--- Execute a selected control and emit its exact completion marker last.
-- @return nil: no values.
local function VERIFY_main()
   local platform = dofile("scripts/lib/platform.lua")
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local matrix = dofile("tools/build/matrix.lua")
   local planner = dofile("scripts/build/lib/matrix.lua")
   local interpreter = arg[-1] or "lua"
   local selected = assert(arg[1], "missing verifier name")

   assert(#arg == 1, "unexpected verifier arguments")

   --- Apply the repository documentation policy to the current authored files.
   -- @return nil: no values.
   local function documentation()
      platform.run({ interpreter, "scripts/check/documentation.lua" })
      print("Documentation control: 1 policy gate passed.")
   end

   --- Build and execute the existing language compatibility tests from scratch.
   -- @return nil: no values.
   local function compilation()
      assert(
         artifacts.output({ "uname", "-sm" }) == "Linux x86_64",
         "compilation control requires the Linux x86_64 host profile"
      )
      local profile = assert(planner.profile(matrix, "linux-gcc13"))
      local dialect = profile.c[1]
      local directory = platform.temporary_directory("tests")

      --- Retain compiler identities and run the ordinary CMake test matrix.
      -- @return nil: no values.
      local passed, failure = xpcall(function()
         platform.run({ "cmake", "--version" })
         platform.run({ profile.cc, "--version" })
         platform.run({ profile.cxx, "--version" })
         platform.run({
            "cmake",
            "-S",
            ".",
            "-B",
            directory,
            "-DLMA_BUILD_MOCK=ON",
            "-DLMA_BUILD_MATRIX=ON",
            "-DCMAKE_BUILD_TYPE=Debug",
            "-DCMAKE_C_COMPILER=" .. profile.cc,
            "-DCMAKE_CXX_COMPILER=" .. profile.cxx,
            "-DCMAKE_C_STANDARD=" .. dialect,
            "-DLMA_C_VERSION=" .. matrix.c_versions[dialect],
            "-DLMA_POINTER_BYTES=" .. profile.pointer,
            "-DLMA_LONG_BYTES=" .. profile.long,
            "-DLMA_BIG_ENDIAN=" .. profile.endian,
            "-DLMA_ARCH=" .. profile.arch,
            "-DLMA_OS=" .. profile.os,
            "-DLMA_CPP_STANDARDS=" .. table.concat(profile.cpp, ";"),
            "-DLMA_CPP_REQUIRED=" .. table.concat(profile.cpp, ";"),
         })
         platform.run({
            "cmake",
            "--build",
            directory,
            "--parallel",
            tostring(matrix.parallel.build),
         })
         local inventory = artifacts.output({
            "ctest",
            "--test-dir",
            directory,
            "--show-only=json-v1",
         })

         artifacts.write(directory .. "/tests.json", inventory)
         local expected = { "c-api", "target-model" }

         for _, cpp in ipairs(profile.cpp) do
            expected[#expected + 1] = "cpp-" .. cpp
         end

         table.sort(expected)
         local actual = artifacts.query(
            directory .. "/tests.json",
            '[.tests[].name] | sort | join("\\n")'
         )

         assert(
            actual == table.concat(expected, "\n"),
            "compatibility test inventory differs from the selected profile"
         )
         platform.run({
            "ctest",
            "--test-dir",
            directory,
            "--output-on-failure",
            "--no-tests=error",
         })
      end, debug.traceback)

      platform.remove_temporary_directory(directory)
      assert(passed, failure)
      print("Compilation control: 1 compatibility campaign passed.")
   end

   --- Run independent policy suites without recursively invoking this engine.
   -- @return nil: no values.
   local function regressions()
      for _, path in ipairs({
         "workspace/hooks_test.lua",
         "process/playbook_test.lua",
         "process/policy_test.lua",
         "toolchain/provision_test.lua",
      }) do
         platform.run({ interpreter, "tests/automation/" .. path })
      end

      print("Regression control: 4 policy suites passed.")
   end

   local controls = {
      documentation = documentation,
      compilation = compilation,
      regressions = regressions,
   }

   assert(controls[selected], "unknown verifier")()
end

return VERIFY_main()

-- EOF


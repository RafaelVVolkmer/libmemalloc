-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Exercise one public consumer through subprojects, installation and
--- pkg-config.
-- @return nil: no values.
local function CONSUMER_TEST_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local execution = dofile("scripts/process/lib/exec.lua")
   local cmake = os.getenv("LIBMEMALLOC_CMAKE") or "cmake"
   local root = artifacts.platform.temporary_directory("tests")
   local repository =
      artifacts.output({ "git", "rev-parse", "--show-toplevel" })

   --- Run real consumer tools and retain actionable failure output.
   -- @param command table: executable and literal command arguments.
   -- @return any: run real consumer tools and retain actionable failure output.
   local function run(command)
      local result = execution.run(command, { timeout_ms = 180000 })

      assert(result.state == "PASS", result.stdout .. result.stderr)

      return result.stdout
   end

   artifacts.write(
      root .. "/parent/main.c",
      artifacts.read("tests/fixtures/install/main.c.in")
   )
   artifacts.write(
      root .. "/parent/unrelated.c",
      "int unrelated(void) { return 0; }\n"
   )
   artifacts.write(root .. "/parent/CMakeLists.txt", [[
cmake_minimum_required(VERSION 3.28)
project(parent C)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(LMA_BUILD_MOCK ON CACHE BOOL "")
set(LMA_IPO OFF CACHE STRING "")
add_library(unrelated STATIC unrelated.c)
add_subdirectory("]] .. repository .. [[" memalloc)
add_executable(consumer main.c)
target_link_libraries(consumer PRIVATE LMA::memalloc)
]])

   for index, libdir in ipairs({
      "lib",
      "lib64",
      "lib/x86_64-linux-gnu",
      "lib",
      "lib64",
      "lib/x86_64-linux-gnu",
   }) do
      local shared = index > 3
      local build = root .. "/build-" .. index
      local install = root .. "/install-" .. index
      local relocated = root .. "/relocated-" .. index
      local generator = index == 2 and "Unix Makefiles" or "Ninja"

      run({
         cmake,
         "-S",
         root .. "/parent",
         "-B",
         build,
         "-G",
         generator,
         "-DCMAKE_INSTALL_LIBDIR=" .. libdir,
         "-DCMAKE_INSTALL_PREFIX=" .. install,
         "-DBUILD_SHARED_LIBS=" .. (shared and "ON" or "OFF"),
      })
      run({ cmake, "--build", build })
      run({ build .. "/consumer" })
      local metadata = build
         .. "/memalloc/metadata/Release/compile_commands.json"
      local database = artifacts.read(metadata)

      assert(database:find("mock.c", 1, true), "library compilation missing")
      assert(
         not database:find("unrelated.c", 1, true),
         "parent source leaked into library metadata"
      )
      assert(not database:find(root, 1, true), "outer build path leaked")
      run({ cmake, "--install", build })
      run({ "mv", install, relocated })
      run({
         cmake,
         "-S",
         repository .. "/tests/fixtures/install",
         "-B",
         root .. "/consumer-" .. index,
         "-Dlibmemalloc_DIR="
            .. relocated
            .. "/"
            .. libdir
            .. "/cmake/libmemalloc",
      })
      run({ cmake, "--build", root .. "/consumer-" .. index })
      run({ root .. "/consumer-" .. index .. "/consumer" })
      local flags = run({
         "env",
         "PKG_CONFIG_LIBDIR=" .. relocated .. "/" .. libdir .. "/pkgconfig",
         "PKG_CONFIG_PATH=",
         "pkg-config",
         "--cflags",
         "--libs",
         "libmemalloc",
      })
      local command =
         { "cc", root .. "/parent/main.c", "-o", root .. "/pkg-consumer" }

      assert(
         (flags:find("-DLMA_SHARED_LIBRARY", 1, true) ~= nil) == shared,
         "pkg-config shared-library definition differs from the CMake target"
      )
      for flag in flags:gmatch("%S+") do
         command[#command + 1] = flag
      end

      run(command)
      run({
         "env",
         "LD_LIBRARY_PATH=" .. relocated .. "/" .. libdir,
         root .. "/pkg-consumer",
      })
   end

   --- Exercise both pkg-config query modes against an installed runtime
   -- profile.
   -- @param build string: output directory for the external consumer.
   -- @param prefix string: installed package prefix.
   -- @return nil: no values.
   local function check_instrumented_pkg(build, prefix)
      for _, static in ipairs({ false, true }) do
         local query = {
            "env",
            "PKG_CONFIG_PATH=",
            "PKG_CONFIG_LIBDIR=" .. prefix .. "/lib/pkgconfig",
            "pkg-config",
            "--cflags",
            "--libs",
            "libmemalloc",
         }
         if static then
            query[#query + 1] = "--static"
         end
         local flags = run(query)
         local command = {
            "cc",
            root .. "/parent/main.c",
            "-o",
            build .. "/pkg-consumer",
         }
         for flag in flags:gmatch("%S+") do
            command[#command + 1] = flag
         end
         run(command)
         run({
            "env",
            "LD_LIBRARY_PATH=" .. prefix .. "/lib",
            "DYLD_LIBRARY_PATH=" .. prefix .. "/lib",
            build .. "/pkg-consumer",
         })
      end
   end

   --- Link and execute consumers of the instrumented package contracts.
   -- @return nil: no values.
   local function check_instrumentation()
      -- Instrumented packages must carry the same runtime link flags through
      -- both APIs.
      for _, shared in ipairs({ false, true }) do
         for _, profile in ipairs({ "coverage", "undefined" }) do
            local name = profile .. (shared and "-shared" or "-static")
            local build = root .. "/" .. name
            local prefix = build .. "/install"
            run({
               cmake,
               "-S",
               ".",
               "-B",
               build,
               "-G",
               "Ninja",
               "-DLMA_BUILD_MOCK=ON",
               "-DCMAKE_BUILD_TYPE=Debug",
               "-DBUILD_SHARED_LIBS=" .. (shared and "ON" or "OFF"),
               "-DCMAKE_INSTALL_PREFIX=" .. prefix,
               "-DCMAKE_INSTALL_LIBDIR=lib",
               profile == "coverage" and "-DLMA_ENABLE_COVERAGE=ON"
                  or "-DLMA_SANITIZERS=undefined",
            })
            run({ cmake, "--build", build })
            run({ cmake, "--install", build })
            run({
               cmake,
               "-S",
               "tests/fixtures/install",
               "-B",
               build .. "/consumer",
               "-Dlibmemalloc_DIR=" .. prefix .. "/lib/cmake/libmemalloc",
            })
            run({ cmake, "--build", build .. "/consumer" })
            run({ build .. "/consumer/consumer" })
            check_instrumented_pkg(build, prefix)
         end
      end
   end

   check_instrumentation()

   artifacts.platform.remove_temporary_directory(root)
   print(
      "Consumer integration: static/shared subproject, relocated CMake "
         .. "and pkg-config passed in three layouts."
   )
end

return CONSUMER_TEST_main()

-- EOF


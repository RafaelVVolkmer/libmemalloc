-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Configure, build, test and compare two isolated CMake installations.
-- Part of local build orchestration, reproducibility and scoped OpenSSF
-- evidence.
-- The POSIX controller uses native argv execution; cross targets need a
-- toolchain.

--- Own argument validation, source snapshots, child execution and final
-- evidence.
-- @return nil: no values.
local function BUILD_LOCAL_main()
   local BUILD_LOCAL_MAX_JOBS = 256
   local BUILD_LOCAL_TIMEOUT_MS = 180 * 1000

   dofile("scripts/workspace/lib/lock.lua").guard("shared")
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local execution = dofile("scripts/process/lib/exec.lua")
   local trees = dofile("scripts/reproducible/lib/trees.lua")
   local uv = require("luv")
   local options = artifacts.options(arg, {
      profile = true,
      os = true,
      arch = true,
      lld = true,
      output = true,
      compiler = true,
      toolchain = true,
      linker = true,
      jobs = true,
      assurance = true,
      sanitizers = true,
      coverage = true,
   })
   local profiles = { release = "Release", debug = "Debug" }
   local systems = {
      linux = "Linux",
      windows = "Windows",
      macos = "Darwin",
      freebsd = "FreeBSD",
      emscripten = "Emscripten",
   }
   local aliases = {
      amd64 = "x86_64",
      AMD64 = "x86_64",
      arm64 = "aarch64",
      ARM64 = "aarch64",
      armv7l = "armv7",
      i386 = "i686",
   }
   local architectures = {
      x86_64 = true,
      aarch64 = true,
      armv7 = true,
      i686 = true,
      riscv64 = true,
      wasm32 = true,
   }

   --- Resolve the host and validate the requested build target.
   -- @return any, any, any, any, any, any, any: the host and validate the
   -- requested build target.
   local function build_local_selectTarget()
      local host = uv.os_uname()
      local host_names =
         { Linux = "linux", Darwin = "macos", FreeBSD = "freebsd" }
      local host_os = host_names[host.sysname]

      assert(
         host_os,
         "the Lua build controller currently requires a POSIX host"
      )

      local profile = options.profile or "release"
      local configuration =
         assert(profiles[profile], "--profile must be release or debug")
      local system = options.os or host_os
      local cmake_os = assert(systems[system], "unknown --os")
      local architecture = options.arch or aliases[host.machine] or host.machine

      assert(architectures[architecture], "unknown --arch")

      return host,
         host_os,
         profile,
         configuration,
         system,
         cmake_os,
         architecture
   end

   local host, host_os, profile, configuration, system, cmake_os, architecture =
      build_local_selectTarget()

   local linkage = options.lld or "static"

   --- Validate linkage, assurance and resource limits before creating output.
   -- @return any, any: validate linkage, assurance and resource limits before
   -- creating output.
   local function build_local_validatePolicy()
      assert(
         linkage == "static" or linkage == "dynamic",
         "--lld must be static or dynamic"
      )
      local assurance = options.assurance or "local"

      assert(
         assurance == "local" or assurance == "full",
         "--assurance must be local or full"
      )
      local jobs = tonumber(options.jobs or 2)

      assert(
         jobs and jobs % 1 == 0 and jobs >= 1 and jobs <= BUILD_LOCAL_MAX_JOBS,
         "--jobs must be 1..256"
      )
      assert(
         not options.coverage or options.coverage == true,
         "--coverage takes no value"
      )

      return assurance, jobs
   end

   local assurance, jobs = build_local_validatePolicy()

   local root = assert(uv.cwd())
   local output = options.output
      or (
         ".cache/build/local/"
         .. profile
         .. "-"
         .. system
         .. "-"
         .. architecture
         .. "-"
         .. linkage
      )

   artifacts.safe_path(output)
   assert(output:match("^%.cache/"), "output must stay in .cache")
   assert(
      not artifacts.exists(output),
      "build evidence must be fresh; choose --output"
   )

   --- Require explicit cross tools and validate optional linker selections.
   -- @return boolean, any: require explicit cross tools and validate optional
   -- linker selections.
   local function build_local_validateToolchain()
      local cross = system ~= host_os
         or architecture ~= (aliases[host.machine] or host.machine)

      assert(not cross or options.toolchain, "cross builds require --toolchain")
      if options.linker then
         assert(options.linker:match("^[A-Z_]+$"), "invalid linker type")
      end

      local toolchain = options.toolchain

      if toolchain then
         artifacts.safe_path(toolchain)
         assert(artifacts.exists(toolchain), "toolchain file does not exist")
      end

      return cross, toolchain
   end

   local cross, toolchain = build_local_validateToolchain()

   artifacts.mkdir(output)
   local cmake = os.getenv("LIBMEMALLOC_CMAKE") or "cmake"
   local lua = os.getenv("LIBMEMALLOC_LUA") or "lua"
   local timeout_ms = BUILD_LOCAL_TIMEOUT_MS
   local report = {
      schema = 1,
      state = "RUNNING",
      product_qualified = false,
      profile = profile,
      os = system,
      arch = architecture,
      linkage = linkage,
      commands = artifacts.array(),
      materials = artifacts.array(),
      assurance = {
         requested = assurance,
         scope = "distribution-fixture",
         complete = false,
      },
      reproducibility = {
         state = "NOT_RUN",
         scope = "installed files, modes and links",
      },
   }

   --- Persist partial evidence before and after each potentially failing phase.
   -- @return nil: no values.
   local function save()
      artifacts.document(output .. "/report.json", report)
   end

   --- Execute literal arguments with a deadline and retain separate output
   -- streams.
   -- @param label string: diagnostic or evidence label for this operation.
   -- @param command table: executable and literal command arguments.
   -- @return any: execute literal arguments with a deadline and retain separate
   -- output streams.
   local function run(label, command)
      local result = execution.run(command, { timeout_ms = timeout_ms })

      artifacts.write(output .. "/" .. label .. ".stdout.log", result.stdout)
      artifacts.write(output .. "/" .. label .. ".stderr.log", result.stderr)
      report.commands[#report.commands + 1] = {
         label = label,
         argv = artifacts.array(command),
         state = result.state,
         exit_code = result.exit_code,
         stdout_sha256 = artifacts.digest(
            output .. "/" .. label .. ".stdout.log"
         ),
         stderr_sha256 = artifacts.digest(
            output .. "/" .. label .. ".stderr.log"
         ),
      }
      save()
      assert(result.state == "PASS", label .. " failed; inspect " .. output)

      return result.stdout
   end

   --- Copy the same declared inputs into a distinct source root for each
   -- attempt.
   -- @param destination string: destination path owned by the invoking
   -- operation.
   -- @return nil: no values.
   local function snapshot(destination)
      for _, material in ipairs(report.materials) do
         artifacts.write(
            destination .. "/" .. material.path,
            artifacts.read(material.path)
         )
         assert(
            artifacts.digest(destination .. "/" .. material.path)
               == material.sha256,
            "source changed while snapshotting: " .. material.path
         )
      end
   end

   --- Build one attempt with frozen time and compiler-cache launchers disabled.
   -- @param name string: entry or operation name to resolve.
   -- @return string: one attempt with frozen time and compiler-cache launchers
   -- disabled.
   local function attempt(name)
      local base = root .. "/" .. output .. "/" .. name
      local source, build, install =
         base .. "/source", base .. "/build", base .. "/install"

      snapshot(source)
      local configure = {
         cmake,
         "-S",
         source,
         "-B",
         build,
         "-G",
         "Ninja",
         "-DLMA_BUILD_MOCK=ON",
         "-DLMA_BUILD_TESTS=" .. (cross and "OFF" or "ON"),
         "-DCMAKE_BUILD_TYPE=" .. configuration,
         "-DLMA_EXPECT_ARCH=" .. architecture,
         "-DLMA_EXPECT_OS=" .. system,
         "-DBUILD_SHARED_LIBS=" .. (linkage == "dynamic" and "ON" or "OFF"),
         "-DCMAKE_INSTALL_PREFIX=/usr",
         "-DCMAKE_INSTALL_LIBDIR=lib",
         "-DCMAKE_C_COMPILER_LAUNCHER=",
         "-DCMAKE_CXX_COMPILER_LAUNCHER=",
      }

      --- Append only explicitly requested compiler, linker and assurance
      -- options.
      -- @return nil: no values.
      local function build_local_applyOptions()
         if options.compiler then
            configure[#configure + 1] = "-DCMAKE_C_COMPILER="
               .. options.compiler
         end

         if toolchain then
            configure[#configure + 1] = "-DCMAKE_TOOLCHAIN_FILE="
               .. source
               .. "/"
               .. toolchain
         end

         if options.linker then
            configure[#configure + 1] = "-DCMAKE_LINKER_TYPE=" .. options.linker
         end

         if options.sanitizers then
            configure[#configure + 1] = "-DLMA_SANITIZERS="
               .. options.sanitizers
         end

         if options.coverage then
            configure[#configure + 1] = "-DLMA_ENABLE_COVERAGE=ON"
         end
      end

      build_local_applyOptions()

      --- Prefix one command with a reproducible environment without shell
      -- expansion.
      -- @param command table: executable and literal command arguments.
      -- @return table: prefix one command with a reproducible environment
      -- without shell expansion.
      local function frozen(command)
         local argv = {
            cmake,
            "-E",
            "env",
            "SOURCE_DATE_EPOCH=" .. report.source_date_epoch,
            "TZ=UTC",
            "LC_ALL=C",
            "CCACHE_DISABLE=1",
            "--",
         }

         for _, value in ipairs(command) do
            argv[#argv + 1] = value
         end

         return argv
      end

      run(name .. "-configure", frozen(configure))
      local actual = artifacts.read(build .. "/build-platform.txt")
      local actual_os, actual_arch = actual:match("^([^\n]+)\n([^\n]+)\n")

      assert(actual_os == cmake_os, "configured OS differs from --os")
      assert(
         (aliases[actual_arch] or actual_arch) == architecture,
         "configured architecture differs from --arch"
      )
      local tool_records = artifacts.array()
      local recorded_tools = artifacts.read(build .. "/build-tools.txt")

      for tool in recorded_tools:gmatch("[^\r\n]+") do
         tool_records[#tool_records + 1] = {
            path = tool,
            sha256 = artifacts.digest(tool),
         }
      end

      artifacts.document(output .. "/" .. name .. "-tools.json", tool_records)
      run(
         name .. "-build",
         frozen({
            cmake,
            "--build",
            build,
            "--config",
            configuration,
            "--parallel",
            tostring(jobs),
         })
      )

      --- Execute the native test suite when cross compilation permits it.
      -- @return nil: no values.
      local function build_local_runTests()
         if not cross then
            local ctest = cmake:match("^(.*)/cmake$")

            ctest = ctest and ctest .. "/ctest" or "ctest"
            run(
               name .. "-test",
               frozen({
                  ctest,
                  "--test-dir",
                  build,
                  "-C",
                  configuration,
                  "--output-on-failure",
                  "--no-tests=error",
                  "--output-junit",
                  build .. "/tests.xml",
               })
            )
         end
      end

      build_local_runTests()
      run(
         name .. "-install",
         frozen({
            cmake,
            "--install",
            build,
            "--config",
            configuration,
            "--prefix",
            install,
         })
      )

      --- Build a consumer against the relocated native installation.
      -- @return nil: no values.
      local function build_local_testRelocation()
         if not cross then
            local consumer = base .. "/consumer"
            local consumer_configure = {
               cmake,
               "-S",
               source .. "/tests/fixtures/install",
               "-B",
               consumer,
               "-G",
               "Ninja",
               "-DCMAKE_BUILD_TYPE=" .. configuration,
               "-DCMAKE_PREFIX_PATH=" .. install,
            }

            if options.compiler then
               local compiler_option = "-DCMAKE_C_COMPILER=" .. options.compiler

               consumer_configure[#consumer_configure + 1] = compiler_option
            end

            run(name .. "-consumer-configure", frozen(consumer_configure))
            run(
               name .. "-consumer-build",
               frozen({ cmake, "--build", consumer, "--config", configuration })
            )
            run(name .. "-consumer-run", frozen({ consumer .. "/consumer" }))
         end
      end

      build_local_testRelocation()

      return install
   end

   save()

   --- Retain evidence when any reconstruction or policy phase fails.
   -- @return nil: no values.
   local function execute_build()
      report.source_date_epoch =
         artifacts.output({ "git", "show", "-s", "--format=%ct", "HEAD" })
      report.revision = artifacts.output({ "git", "rev-parse", "HEAD" })
      report.host =
         { os = host.sysname, release = host.release, arch = host.machine }
      report.cmake = run("cmake-version", { cmake, "--version" })
      local listed = artifacts.output({
         "git",
         "ls-files",
         "-z",
         "--cached",
         "--others",
         "--exclude-standard",
         "--",
         "CMakeLists.txt",
         "CMakePresets.json",
         "cmake",
         "core",
         "packaging",
         "LICENSE",
         "tests/fixtures/install",
      })
      local seen = {}

      for path in listed:gmatch("([^%z]+)%z") do
         if not seen[path] then
            artifacts.safe_path(path)
            assert(
               assert(uv.fs_lstat(path)).type == "file",
               "source must be a regular file"
            )
            report.materials[#report.materials + 1] =
               { path = path, sha256 = artifacts.digest(path) }
            seen[path] = true
         end
      end

      --- Include an explicitly supplied toolchain in the source snapshot.
      -- @return nil: no values.
      local function build_local_captureToolchain()
         if toolchain and not seen[toolchain] then
            report.materials[#report.materials + 1] = {
               path = toolchain,
               sha256 = artifacts.digest(toolchain),
            }
         end
      end

      build_local_captureToolchain()

      report.controller = {
         path = "scripts/build/local.lua",
         sha256 = artifacts.digest("scripts/build/local.lua"),
      }
      --- Sort material paths so report identity is independent of discovery
      -- order.
      -- @param left table: left supplied to this operation.
      -- @param right table: right supplied to this operation.
      -- @return boolean: sort material paths so report identity is independent
      -- of discovery order.
      table.sort(report.materials, function(left, right)
         return left.path < right.path
      end)
      local first, second = attempt("first"), attempt("second")
      local identical, left, right = trees.compare(first, second)

      artifacts.document(
         output .. "/first-inventory.json",
         artifacts.array(left)
      )
      artifacts.document(
         output .. "/second-inventory.json",
         artifacts.array(right)
      )
      report.reproducibility.state = identical and "PASS" or "FAIL"
      report.execution = cross and "cross-build-only; target tests not executed"
         or "native-tests-passed"
      save()
      assert(identical, "installed trees differ; inspect retained inventories")

      run("openssf-policy", { lua, "scripts/check/openssf.lua" })
      report.assurance.policy = "PASS"
      report.assurance.projects = artifacts.array()
      local projects = dofile("tools/security/openssf/projects.lua")

      --- Configure and execute one installed consumer project.
      -- @param name string: entry or operation name to resolve.
      -- @param project table: project supplied to this operation.
      -- @return nil: no values.
      local function build_local_testConsumer(name, project)
         report.assurance.projects[#report.assurance.projects + 1] = {
            name = name,
            state = project.mode == "blocked" and "BLOCKED" or "NOT_RUN",
            reason = project.reason
               or "Separate security adapter assessment required",
         }
      end

      for name, project in pairs(projects) do
         build_local_testConsumer(name, project)
      end

      table.sort(
         report.assurance.projects,
         --- Keep adapter gaps in a stable order for independent reports.
         -- @param first_project table: first project supplied to this
         -- operation.
         -- @param second_project table: second project supplied to this
         -- operation.
         -- @return boolean: keep adapter gaps in a stable order for independent
         -- reports.
         function(first_project, second_project)
            return first_project.name < second_project.name
         end
      )
      if assurance == "full" then
         error(
            "full assurance is not qualified: "
               .. "inspect the recorded OpenSSF project gaps"
         )
      end
   end

   local success, failure = xpcall(execute_build, debug.traceback)

   report.state = success and "PASS" or "FAIL"
   local success_detail =
      "Scoped reconstruction passed; assurance is incomplete."

   report.detail = success and success_detail or tostring(failure)
   save()
   assert(success, failure)
   print("CMake build and installed-tree comparison passed: " .. output)
end

return BUILD_LOCAL_main()

-- EOF


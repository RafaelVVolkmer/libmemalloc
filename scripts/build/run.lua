-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Build each C configuration once, link its C++ consumers, and execute CTest.
-- Part of build-matrix planning, execution and retained results.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_build_run_main()
   dofile("scripts/workspace/lib/lock.lua").guard("shared")
   local build_io = dofile("scripts/build/lib/io.lua")
   local artifact_io = build_io.release
   local exports = dofile("scripts/build/lib/matrix.lua")
   local cache = dofile("scripts/build/lib/cache.lua")
   local catalog = dofile("tools/build/matrix.lua")
   local lock = dofile("scripts/toolchain/lib/lock.lua").load()
   local options = artifact_io.options(arg, {
      profile = true,
      campaign = true,
      output = true,
      plan = true,
      ["no-cache"] = true,
   })

   local profile =
      exports.profile(catalog, assert(options.profile, "--profile is required"))
   local campaign = options.campaign or "pr"
   local plan = exports.plan(catalog, campaign, profile.id)
   local output = options.output or (".cache/ci/build-reports/" .. profile.id)

   local work = options.output and output .. "-work"
      or (".cache/ci/build-work/" .. profile.id)

   artifact_io.safe_path(output)
   assert(output:match("^%.cache/"), "build evidence must stay in .cache")

   local existing = io.open(output .. "/report.json", "rb")

   if existing then
      existing:close()

      error("build report must be fresh")
   end

   build_io.mkdir(output)

   local report = {
      schema = 2,
      profile = profile.id,
      campaign = campaign,
      commands = artifact_io.array(),
      cells = artifact_io.array(),
      inputs = build_io.inputs(),
      limitations = artifact_io.array({
         "Distribution mock only; no allocator, stress or benchmark claim.",
      }),
   }

   --- Persist the build report, including outcomes from interrupted or failing
   -- cases.
   -- @return nil: no values.
   local function build_run_save()
      build_io.json(output .. "/report.json", report)
   end

   build_run_save()

   local tools, environment, identity
   local setup_ok, setup_error = xpcall(
      --- Prepare and validate the host before any profile case executes.
      -- @return nil: no values.
      function()
         local host = build_io.platform.is_windows and "Windows"
            or build_io.output({ "uname", "-s" })

         assert(host == profile.host, "build host does not match contracted OS")

         report.host = {
            os = host,
            runner_image = os.getenv("ImageVersion") or "local",
            revision = build_io.output({ "git", "rev-parse", "HEAD" }),
         }

         tools = {
            cc = build_io.tool(os.getenv("LIBMEMALLOC_BUILD_CC") or profile.cc),
            cxx = build_io.tool(
               os.getenv("LIBMEMALLOC_BUILD_CXX") or profile.cxx
            ),
            cmake = build_io.tool("cmake"),
            ninja = build_io.tool("ninja"),
         }

         report.tools = tools
         if options.plan then
            build_io.json(output .. "/source-inputs.json", report.inputs)
            assert(
               build_io.query(options.plan, ".source_inputs")
                  == build_io.query(output .. "/source-inputs.json", "."),
               "plan source identity differs from checkout"
            )

            report.plan_sha256 = build_io.digest(options.plan)
         end

         local sdk_manifest = os.getenv("LIBMEMALLOC_BUILD_SDK_MANIFEST")

         identity = {
            tools = tools,
            target = profile.arch,
            abi = profile.abi,
            compiler_lock = lock[profile.lock],
            sdk = sdk_manifest and build_io.digest(sdk_manifest)
               or "local: compiler and consumed dependencies recorded",
         }

         local identity_path = ".cache/ci/build-cache-identity-"
            .. profile.id
            .. ".json"

         build_io.json(identity_path, identity)

         report.environment_sha256 = build_io.digest(identity_path)
         environment, report.cache = cache.environment(
            build_io,
            profile,
            report.environment_sha256,
            options["no-cache"]
         )

         --- Select and validate the compiler cache before configuring cells.
         -- @return nil: no values.
         local function build_run_prepareCache()
            if profile.cache == "sccache" and not options["no-cache"] then
               tools.cache = build_io.tool("sccache")
               assert(
                  build_io.run(
                     report,
                     output,
                     "cache-version",
                     { tools.cache.path, "--version" }
                  ),
                  "missing compiler cache"
               )
               assert(
                  build_io
                     .read(output .. "/cache-version.log")
                     :find(lock.sccache.version, 1, true),
                  "sccache version drift"
               )

               -- Start the cache before parallel compiler clients can race its
               -- startup.
               assert(
                  build_io.run(report, output, "cache-start", {
                     tools.cache.path,
                     "--start-server",
                  }, environment),
                  "compiler cache server failed to start"
               )
            elseif profile.cache == "ccache" and not options["no-cache"] then
               tools.cache = build_io.tool("ccache")
            end
         end

         build_run_prepareCache()

         if profile.emulator then
            tools.emulator = build_io.tool(profile.emulator)
            assert(
               build_io.run(
                  report,
                  output,
                  "emulator-version",
                  { tools.emulator.path, "--version" }
               ),
               "emulator unavailable"
            )
            assert(
               build_io
                  .read(output .. "/emulator-version.log")
                  :find(lock.build_qemu.version, 1, true),
               "emulator version drift"
            )
         end

         --- Verify the selected SDK version against its reviewed identity.
         -- @return nil: no values.
         local function build_run_checkSdk()
            if profile.sdk_driver then
               local flag = profile.cache == "zig" and "version" or "--version"

               local sdk_command = { tools.cc.path, flag }
               local sdk_available =
                  build_io.run(report, output, "sdk-version", sdk_command)

               assert(sdk_available, "SDK driver unavailable")
               assert(
                  build_io
                     .read(output .. "/sdk-version.log")
                     :find(lock[profile.lock].version, 1, true),
                  "SDK version drift"
               )
            end
         end

         build_run_checkSdk()
      end,
      debug.traceback
   )

   --- Execute one planned cell and retain its terminal outcome.
   -- @param cell table: cell supplied to this operation.
   -- @return nil: no values.
   local function build_run_executeCell(cell)
      local result = {
         id = cell.id,
         support = cell.support,
         status = "infrastructure-error",
         tests = artifact_io.array(),
         artifacts = artifact_io.array(),
         unsupported_tests = artifact_io.array(),
      }

      report.cells[#report.cells + 1] = result

      local phase = "capabilities"
      local success, failure = xpcall(
         --- Execute one build case while retaining partial evidence on failure.
         -- @return nil: no values.
         function()
            assert(setup_ok, setup_error)

            local directory = output .. "/" .. cell.id
            local build = build_io.root .. "/" .. work .. "/" .. cell.id
            local configure = {
               "cmake",
               "-S",
               build_io.root,
               "-B",
               build,
               "-G",
               "Ninja",
               "-DLMA_BUILD_MOCK=ON",
               "-DLMA_BUILD_MATRIX=ON",
               "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
               "-DCMAKE_BUILD_TYPE=" .. cell.configuration,
               "-DCMAKE_TRY_COMPILE_CONFIGURATION=" .. cell.configuration,
               "-DCMAKE_C_STANDARD=" .. cell.dialect,
               "-DCMAKE_C_STANDARD_REQUIRED=ON",
               "-DCMAKE_C_EXTENSIONS=OFF",
               "-DCMAKE_CXX_STANDARD_REQUIRED=ON",
               "-DCMAKE_CXX_EXTENSIONS=OFF",
               "-DLMA_C_VERSION=" .. catalog.c_versions[cell.dialect],
               "-DLMA_POINTER_BYTES=" .. profile.pointer,
               "-DLMA_LONG_BYTES=" .. profile.long,
               "-DLMA_BIG_ENDIAN=" .. profile.endian,
               "-DLMA_ARCH=" .. profile.arch,
               "-DLMA_OS=" .. profile.os,
            }

            --- Set the explicit Zig toolchain and cross-target arguments.
            -- @return nil: no values.
            local function build_run_configureZig()
               if profile.cache == "zig" then
                  configure[#configure + 1] = "-DCMAKE_TOOLCHAIN_FILE="
                     .. build_io.root
                     .. "/cmake/toolchains/zig.cmake"
               else
                  configure[#configure + 1] = "-DCMAKE_C_COMPILER="
                     .. tools.cc.path
                  configure[#configure + 1] = "-DCMAKE_CXX_COMPILER="
                     .. tools.cxx.path
               end
            end

            build_run_configureZig()

            --- Set target-specific CMake inputs for the contracted platform.
            -- @return nil: no values.
            local function build_run_configurePlatform()
               if profile.os == "EMSCRIPTEN" then
                  configure[#configure + 1] = "-DCMAKE_TOOLCHAIN_FILE="
                     .. assert(
                        os.getenv("EMSDK"),
                        "activate the locked emsdk first"
                     )
                     .. (
                        "/upstream/emscripten/cmake/Modules/Platfor"
                        .. "m/Emscripten.cmake"
                     )
                  configure[#configure + 1] = "-DCMAKE_EXECUTABLE_SUFFIX=.js"
               elseif profile.cross then
                  local sysroot = os.getenv("LIBMEMALLOC_BUILD_SYSROOT")
                     or ("/usr/" .. profile.cross)

                  configure[#configure + 1] = "-DCMAKE_TOOLCHAIN_FILE="
                     .. build_io.root
                     .. "/cmake/toolchains/linux-cross.cmake"
                  configure[#configure + 1] = "-DLMA_TARGET_PROCESSOR="
                     .. profile.arch:lower()
                  configure[#configure + 1] = "-DLMA_SYSROOT=" .. sysroot
                  configure[#configure + 1] = "-DLMA_EMULATOR="
                     .. tools.emulator.path
                     .. ";-L;"
                     .. sysroot
                     .. ";-cpu;"
                     .. profile.cpu
                  result.execution = {
                     kind = "qemu-user",
                     cpu = profile.cpu,
                     sysroot = sysroot,
                     emulator = tools.emulator,
                  }
               else
                  result.execution = {
                     kind = profile.os == "EMSCRIPTEN" and "node" or "native",
                     os = profile.os,
                     architecture = profile.arch,
                  }
               end
            end

            build_run_configurePlatform()

            do
               configure[#configure + 1] = "-DLMA_CPP_STANDARDS="
                  .. table.concat(catalog.cpp_requested, ";")
               configure[#configure + 1] = "-DLMA_CPP_REQUIRED="
                  .. table.concat(profile.cpp, ";")
            end

            --- Translate the cell semantic profile into explicit compiler
            -- flags.
            -- @return nil: no values.
            local function build_run_configureFlags()
               if cell.flags then
                  for _, flag in ipairs(cell.flags) do
                     if flag == "-flto" and profile.compiler == "GNU" then
                        configure[#configure + 1] = "-DLMA_IPO=ON"
                     end
                  end

                  if cell.semantic_profile == "freestanding-core" then
                     configure[#configure + 1] = "-DLMA_CORE_FLAGS="
                        .. table.concat(cell.flags, ";")
                  else
                     configure[#configure + 1] = "-DCMAKE_C_FLAGS_RELEASE="
                        .. table.concat(cell.flags, " ")
                     configure[#configure + 1] = "-DCMAKE_CXX_FLAGS_RELEASE="
                        .. table.concat(cell.flags, " ")
                  end

                  configure[#configure + 1] = "-DCMAKE_EXE_LINKER_FLAGS="
                     .. table.concat(cell.link_flags, " ")
                     .. " "
                     .. (profile.link_flags or "")
                  configure[#configure + 1] = "-DLMA_FLAG_PROBE="
                     .. table.concat(cell.flags, " ")
                  result.semantic_profile = cell.semantic_profile
                  result.flags = artifact_io.array(cell.flags)
               end
            end

            build_run_configureFlags()

            if tools.cache then
               configure[#configure + 1] = "-DCMAKE_C_COMPILER_LAUNCHER="
                  .. tools.cache.path
               configure[#configure + 1] = "-DCMAKE_CXX_COMPILER_LAUNCHER="
                  .. tools.cache.path
            end

            local configured = build_io.run(
               report,
               directory,
               "configure",
               configure,
               environment
            )

            --- Distinguish unsupported profiles from unexpected configure
            -- failures.
            -- @return nil: no values.
            local function build_run_classifyConfigureFailure()
               if not configured then
                  local log = build_io.read(directory .. "/configure.log")

                  if
                     log:find("LMA_UNSUPPORTED_DIALECT:", 1, true)
                     or log:find("LMA_UNSUPPORTED_PROFILE:", 1, true)
                  then
                     phase = "unsupported-dialect"
                  end

                  error("configuration or compiler capability failed")
               end
            end

            build_run_classifyConfigureFailure()

            --- Remove only explicitly unsupported tests from the expected
            -- inventory.
            -- @return table: remove only explicitly unsupported tests from the
            -- expected inventory.
            local function build_run_selectTests()
               local expected_tests, omitted = {}, {}
               local unavailable =
                  build_io.lines(build_io.read(build .. "/unsupported-cpp.txt"))

               for _, dialect in ipairs(unavailable) do
                  local name = "cpp-" .. dialect

                  omitted[name] = true
                  result.unsupported_tests[#result.unsupported_tests + 1] = name
               end

               for _, name in ipairs(cell.tests) do
                  if not omitted[name] then
                     expected_tests[#expected_tests + 1] = name
                  end
               end

               return expected_tests
            end

            local expected_tests = build_run_selectTests()

            local compiler =
               build_io.lines(build_io.read(build .. "/compiler.txt"))

            assert(
               compiler[1] == profile.compiler,
               "unexpected compiler frontend"
            )

            local expected = lock[profile.lock].version

            --- Require the configured compiler to match the selected tool
            -- identity.
            -- @return nil: no values.
            local function build_run_verifyCompiler()
               if not profile.sdk_driver then
                  assert(
                     compiler[2] == expected
                        or (
                           profile.compiler == "MSVC"
                           and compiler[2]:sub(1, #expected + 1)
                              == expected .. "."
                        ),
                     "compiler version drift: " .. compiler[2]
                  )
               end
            end

            build_run_verifyCompiler()

            result.compiler =
               { id = compiler[1], version = compiler[2], path = compiler[3] }
            phase = "build"
            assert(
               build_io.run(report, directory, "build", {
                  "cmake",
                  "--build",
                  build,
                  "--parallel",
                  tostring(catalog.parallel.build),
               }, environment),
               "compilation or linkage failed"
            )

            result.status = "build-passed"

            local database = build .. "/compile_commands.json"

            local retained_database = directory .. "/compile_commands.json"

            build_io.write(retained_database, build_io.read(database))
            result.compilation_database = {
               path = cell.id .. "/compile_commands.json",
               sha256 = build_io.digest(retained_database),
            }

            local commands =
               build_io.lines(build_io.query(database, ".[ ].command"))

            local sources = dofile("scripts/build/lib/sources.lua")
            sources.check(
               build_io.lines(build_io.query(database, ".[ ].file")),
               sources.expected(build_io.root, build, expected_tests)
            )

            for _, command in ipairs(commands) do
               local count = 0

               for _ in command:gmatch("[%-/]std[:=]") do
                  count = count + 1
               end

               assert(count == 1, "missing or conflicting dialect options")
               assert(
                  not command:find("%-std=gnu"),
                  "GNU dialect substituted for ISO"
               )
            end

            assert(
               build_io.run(
                  report,
                  directory,
                  "dependencies",
                  { "ninja", "-C", build, "-t", "deps" }
               ),
               "dependency evidence unavailable"
            )

            for _, path in
               ipairs(build_io.lines(build_io.read(build .. "/artifacts.txt")))
            do
               result.artifacts[#result.artifacts + 1] =
                  { path = path, sha256 = build_io.digest(path) }
            end

            for _, name in ipairs({ "compile_commands.json", "build.json" }) do
               local metadata = build
                  .. "/metadata/"
                  .. cell.configuration
                  .. "/"
                  .. name

               build_io.write(
                  directory .. "/metadata/" .. name,
                  build_io.read(metadata)
               )
               result.artifacts[#result.artifacts + 1] = {
                  path = metadata,
                  sha256 = build_io.digest(metadata),
               }
            end

            local inventory = directory .. "/expected-tests.json"
            local command = build_io.platform.join_command({
               "ctest",
               "--test-dir",
               build,
               "--show-only=json-v1",
            }) .. " >" .. build_io.platform.shell_quote(inventory)

            assert(
               build_io.platform.command_succeeded(command),
               "CTest inventory failed"
            )

            local actual =
               build_io.lines(build_io.query(inventory, ".tests[].name"))

            table.sort(actual)
            assert(
               table.concat(actual, "\n") == table.concat(expected_tests, "\n"),
               "CTest omitted expected tests"
            )

            phase = "test"

            local junit = build_io.root .. "/" .. directory .. "/ctest.xml"

            assert(
               build_io.run(report, directory, "test", {
                  "ctest",
                  "--test-dir",
                  build,
                  "--output-on-failure",
                  "--no-tests=error",
                  "--parallel",
                  tostring(catalog.parallel.tests),
                  "--output-junit",
                  junit,
               }, environment),
               "test execution failed"
            )

            result.semantic_trace = "mock-identity-v1 operations=257 result=0"
            local validator = dofile("scripts/build/lib/junit.lua")
            local executed = validator.validate(
               build_io.read(junit),
               expected_tests,
               result.semantic_trace
            )

            result.tests = artifact_io.array(executed)
            result.test_report = {
               path = cell.id .. "/ctest.xml",
               sha256 = build_io.digest(junit),
            }
            result.status = "tests-passed"
         end,
         debug.traceback
      )

      if not success then
         result.status = phase == "unsupported-dialect" and "unsupported"
            or phase == "capabilities" and "infrastructure-error"
            or "failed"
         result.error = tostring(failure):gsub("[\128-\255]", "?")
         io.stderr:write(result.id .. ": " .. result.error .. "\n")
      end

      build_run_save()

      print(result.id .. ": " .. result.status)

      io.flush()
   end

   for _, cell in ipairs(plan.cells) do
      build_run_executeCell(cell)
   end

   --- Capture final compiler-cache statistics for the build profile.
   -- @return nil: no values.
   local function build_run_recordCache()
      if tools and tools.cache and profile.cache == "sccache" then
         build_io.run(
            report,
            output,
            "cache-statistics",
            { tools.cache.path, "--show-stats", "--stats-format=json" },
            environment
         )
      end
   end

   build_run_recordCache()

   local normalized = {}

   for _, result in ipairs(report.cells) do
      normalized[#normalized + 1] = {
         id = result.id,
         support = result.support,
         status = result.status,
         tests = result.tests,
         artifacts = #result.artifacts,
         unsupported_tests = result.unsupported_tests,
      }
   end

   local passed, failures, experiments = exports.gate(plan.cells, normalized)

   report.required_passed = passed
   report.failures = artifact_io.array(failures)
   report.experimental_results = artifact_io.array(experiments)
   build_run_save()
   assert(
      passed,
      "required build cells failed; inspect " .. output .. "/report.json"
   )
end

return scripts_build_run_main()

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Execute one logical task in its own process. Tests consume sealed binaries.
-- Part of planned qualification tasks and producer/consumer evidence.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_qualification_run_main()
   dofile("scripts/workspace/lib/lock.lua").guard("shared")
   local evidence_io = dofile("scripts/qualification/lib/io.lua")
   local Build =
      assert(loadfile("scripts/qualification/lib/build.lua"))(evidence_io)
   local build_io, artifact_io, qualification_model =
      evidence_io.B, evidence_io.R, evidence_io.Q
   local policy = evidence_io.catalog.host
   local fixture = evidence_io.catalog.fixture
   local options = artifact_io.options(
      arg,
      { task = true, plan = true, input = true, output = true }
   )
   local plan, identity, catalog =
      evidence_io.open(options.plan or ".cache/qualification/plan.json")
   local task =
      qualification_model.task(plan, assert(options.task, "--task required"))
   local input = options.input or ".cache/qualification/evidence"
   local output = options.output or ".cache/qualification/evidence"

   artifact_io.safe_path(input)

   artifact_io.safe_path(output)
   assert(output:match("^%.cache/"), "output must stay in .cache")

   local report, directory = evidence_io.result(output, task, identity)

   report.execution_batch = os.getenv("LIBMEMALLOC_QUALIFICATION_BATCH")

   local absolute = build_io.root .. "/" .. directory

   --- Verify a required producer before exposing its artifacts to the current
   -- task.
   -- @param id string: stable identity used to match the requested entry.
   -- @return any: verify a required producer before exposing its artifacts to
   -- the current task.
   local function qualification_run_dependency(id)
      return evidence_io.dependency(
         report,
         input,
         qualification_model.task(plan, id),
         identity
      )
   end

   --- Execute the qualified fixture with declared inputs and retain its
   -- observed
   -- trace.
   -- @param root string: root directory for this operation.
   -- @param executable string: selected executable path or command name.
   -- @param operations any: operations supplied to this operation.
   -- @param label string: diagnostic or evidence label for this operation.
   -- @param environment any|nil: environment supplied to this operation.
   -- @return nil: no values.
   local function qualification_run_runBinary(
      root,
      executable,
      operations,
      label,
      environment
   )
      -- Artifacts lose executable permissions during Actions upload/download.
      evidence_io.execute(
         report,
         directory,
         "chmod-" .. label,
         { "chmod", "u+x", root .. "/" .. executable }
      )

      local trace = evidence_io.execute(report, directory, label, {
         "cmake",
         "-E",
         "chdir",
         absolute,
         "timeout",
         policy.timeout.execution,
         build_io.root .. "/" .. root .. "/" .. executable,
      }, environment or { LC_ALL = "C", TZ = "UTC" })

      assert(
         trace == evidence_io.trace(operations),
         "semantic trace differs from independent mock oracle"
      )
   end

   --- Merge training profiles with the selected compiler and declared weights.
   -- @param compiler table: compiler supplied to this operation.
   -- @param roots any: roots supplied to this operation.
   -- @param destination string: destination path owned by the invoking
   -- operation.
   -- @param weights table|nil: weights supplied to this operation.
   -- @return string: merge training profiles with the selected compiler and
   -- declared weights.
   local function qualification_run_mergeProfiles(
      compiler,
      roots,
      destination,
      weights
   )
      weights = weights or { 1 }
      assert(
         #roots == #weights and #roots > 0,
         "profile weight inventory differs"
      )
      if compiler.backend == "llvm" then
         local accepted = {}

         for index, root in ipairs(roots) do
            local count = 0

            for _, file in ipairs(artifact_io.files(root)) do
               assert(file:match("%.profraw$"), "unexpected raw profile file")

               count = count + 1
               accepted[#accepted + 1] = tostring(weights[index])
                  .. ","
                  .. build_io.root
                  .. "/"
                  .. root
                  .. "/"
                  .. file
            end

            assert(count > 0, "missing shard profiles")
         end

         build_io.write(
            directory .. "/accepted-profiles.txt",
            table.concat(accepted, "\n") .. "\n"
         )

         evidence_io.execute(report, directory, "merge-profiles", {
            policy.tools.profile,
            "merge",
            "--failure-mode=any",
            "--input-files=" .. directory .. "/accepted-profiles.txt",
            "--output=" .. destination .. ".profdata",
         })

         local shown =
            evidence_io.execute(report, directory, "profile-counts", {
               policy.tools.profile,
               "show",
               "--all-functions",
               "--counts",
               destination .. ".profdata",
            })

         assert(
            shown:find(fixture.symbol, 1, true),
            "profile does not cover the library"
         )

         return build_io.root .. "/" .. destination .. ".profdata"
      end

      for _, root in ipairs(roots) do
         assert(
            table.concat(artifact_io.files(root), "\n") == fixture.gcov_data,
            "unexpected GCC profile inventory"
         )
      end

      --- Copy or combine GCC profile counters using explicit shard weights.
      -- @return nil: no values.
      local function qualification_run_reduceGcc()
         if #roots == 1 and weights[1] == 1 then
            local copy =
               { "cmake", "-E", "copy_directory", roots[1], destination }

            artifact_io.run(copy)
         else
            if #roots == 1 then
               -- A zero-weight duplicate scales one shard without counting it
               -- twice.
               roots = { roots[1], roots[1] }
               weights = { weights[1], 0 }
            end

            local accumulated = roots[1]

            --- Merge one independent replica into the aggregate profile
            -- evidence.
            -- @param index number: one-based position in the current sequence.
            -- @return nil: no values.
            local function qualification_run_mergeReplica(index)
               local output_path = index == #roots and destination
                  or destination .. "-part-" .. tostring(index)

               -- Previous reductions already include their original counter
               -- weights.
               local prior_weight = index == 2 and weights[1] or 1
               local diagnostic = evidence_io.execute(
                  report,
                  directory,
                  "merge-profiles-" .. tostring(index),
                  {
                     policy.tools.gcov_merge,
                     "merge",
                     accumulated,
                     roots[index],
                     "-w",
                     tostring(prior_weight) .. "," .. tostring(weights[index]),
                     "-o",
                     output_path,
                  }
               )

               -- gcov-tool can discard invalid inputs while returning zero.
               assert(
                  diagnostic == "",
                  "GCC merge reported rejected or incompatible data"
               )

               accumulated = output_path
            end

            for index = 2, #roots do
               qualification_run_mergeReplica(index)
            end
         end
      end

      qualification_run_reduceGcc()

      local shown = evidence_io.execute(report, directory, "profile-counts", {
         policy.tools.gcov_dump,
         "-l",
         destination .. "/" .. fixture.gcov_data,
      })

      assert(shown:find("COUNTERS", 1, true), "invalid GCC counters")

      return build_io.root .. "/" .. destination
   end

   local handlers = {}

   --- Build the ordinary qualification artifact and retain compiler evidence.
   -- @return nil: no values.
   local function QUALIFICATION_RUN_build()
      Build.tools(report, directory, catalog)

      local compiler = Build.compiler(catalog, task.compiler)

      report.status = "FAIL"
      Build.library(report, directory, compiler, task)

      Build.audit(report, directory, catalog)

      Build.consumers(report, directory, catalog, task)
   end

   handlers.build = QUALIFICATION_RUN_build

   --- Build the instrumented counterpart used by the declared training stage.
   -- @return nil: no values.
   local function QUALIFICATION_RUN_instrument()
      Build.tools(report, directory, catalog)

      local compiler = Build.compiler(catalog, task.compiler)

      report.status = "FAIL"
      Build.library(report, directory, compiler, task)

      for _, shard in ipairs(catalog.shards) do
         Build.consumer(report, directory, compiler, {
            name = "train-" .. shard.id,
            operations = shard.operations,
            indirect = false,
         })
      end

      -- Probe execution, export, processing, reconstruction and application
      -- together.
      qualification_run_runBinary(
         directory,
         "train-" .. catalog.shards[1].id,
         catalog.shards[1].operations,
         "probe-train",
         {
            LLVM_PROFILE_FILE = absolute .. "/profiles/%m-%p.profraw",
            LC_ALL = "C",
            TZ = "UTC",
         }
      )

      local profile = qualification_run_mergeProfiles(
         compiler,
         { directory .. "/profiles" },
         directory .. "/probe-profile"
      )

      local probe = directory .. "/probe"

      build_io.mkdir(probe)

      Build.library(
         report,
         probe,
         compiler,
         { mode = "pgo", dialect = catalog.primary_dialect },
         profile
      )

      Build.audit(report, probe, catalog)

      Build.consumer(report, probe, compiler, {
         name = "probe-consumer",
         operations = catalog.validation_operations,
         indirect = false,
      })

      qualification_run_runBinary(
         probe,
         "probe-consumer",
         catalog.validation_operations,
         "probe-verify"
      )

      report.library_sha256 =
         build_io.digest(directory .. "/" .. evidence_io.catalog.fixture.shared)
   end

   handlers.instrument = QUALIFICATION_RUN_instrument

   --- Run the instrumented fixture and retain profile data for the assigned
   -- workload.
   -- @return nil: no values.
   local function QUALIFICATION_RUN_train()
      local producer = qualification_run_dependency(task.producer)

      report.status = "FAIL"
      qualification_run_runBinary(
         producer,
         "train-" .. task.shard,
         task.operations,
         "train",
         {
            LLVM_PROFILE_FILE = absolute .. "/profiles/%m-%p.profraw",
            LC_ALL = "C",
            TZ = "UTC",
         }
      )
      assert(
         #artifact_io.files(directory .. "/profiles") > 0,
         "training produced no profiles"
      )

      report.producer_sha256 =
         build_io.digest(producer .. "/" .. evidence_io.catalog.fixture.shared)
      report.operations = task.operations
      report.weight = task.weight
   end

   handlers.train = QUALIFICATION_RUN_train

   --- Combine verified training outputs into the profile consumed by
   -- optimization.
   -- @return nil: no values.
   local function QUALIFICATION_RUN_merge()
      local roots, weights, accepted = {}, {}, artifact_io.array()

      for _, shard in ipairs(catalog.shards) do
         local id = task.compiler .. "-train-" .. shard.id
         local root = qualification_run_dependency(id)

         roots[#roots + 1] = root .. "/profiles"
         weights[#weights + 1] = shard.weight
         assert(
            tonumber(build_io.query(root .. "/report.json", ".operations"))
               == shard.operations,
            "training operation budget differs"
         )
         assert(
            tonumber(build_io.query(root .. "/report.json", ".weight"))
               == shard.weight,
            "training weight differs"
         )

         accepted[#accepted + 1] = {
            task = id,
            attempt_id = identity.attempt_id,
            operations = shard.operations,
            weight = shard.weight,
            report_sha256 = build_io.digest(root .. "/report.json"),
         }
      end

      report.status = "FAIL"
      build_io.json(directory .. "/accepted-attempts.json", accepted)

      qualification_run_mergeProfiles(
         Build.compiler(catalog, task.compiler),
         roots,
         directory .. "/merged",
         weights
      )
   end

   handlers.merge = QUALIFICATION_RUN_merge

   --- Build with the verified profile inputs and preserve their producer
   -- identities.
   -- @return nil: no values.
   local function QUALIFICATION_RUN_optimize()
      local merged = qualification_run_dependency(task.compiler .. "-merge")
      local producer =
         qualification_run_dependency(task.compiler .. "-instrument")

      Build.tools(report, directory, catalog)
      assert(
         report.tools_sha256
            == build_io.query(producer .. "/report.json", ".tools_sha256"),
         "training toolchain differs"
      )

      report.status = "FAIL"

      local profile = merged
         .. "/merged"
         .. (task.backend == "llvm" and ".profdata" or "")

      Build.library(
         report,
         directory,
         Build.compiler(catalog, task.compiler),
         task,
         build_io.root .. "/" .. profile
      )

      Build.audit(report, directory, catalog)

      Build.consumers(report, directory, catalog, task)
   end

   handlers.optimize = QUALIFICATION_RUN_optimize

   --- Execute the verified candidate and compare its trace to the independent
   -- expectation.
   -- @return nil: no values.
   local function QUALIFICATION_RUN_run()
      local producer = qualification_run_dependency(task.producer)

      report.status = "FAIL"
      qualification_run_runBinary(
         producer,
         task.executable,
         catalog.validation_operations,
         "trace"
      )

      report.producer_sha256 =
         build_io.digest(producer .. "/" .. evidence_io.catalog.fixture.shared)
      report.trace_sha256 = build_io.digest(directory .. "/trace.log")
      report.host = {
         kernel = build_io.output({ "uname", "-srvmo" }),
         runner_image = os.getenv("ImageVersion") or "local",
      }
   end

   handlers.run = QUALIFICATION_RUN_run

   --- Build the declared instrumented diagnostic counterpart with explicit
   -- flags.
   -- @return nil: no values.
   local function QUALIFICATION_RUN_diagnosticBuild()
      Build.tools(report, directory, catalog)

      local compiler = Build.compiler(catalog, task.compiler)

      report.status = "FAIL"

      local object = directory .. "/diagnostic-core.o"
      local flags = {
         "-g",
         "-fno-omit-frame-pointer",
         "-fsanitize=address,undefined",
         "-fno-sanitize-recover=all",
      }
      local optimization = (task.mode == "O3-lto" or task.flags) and "-O3"
         or "-" .. task.mode

      flags[#flags + 1] = optimization
      if task.mode == "O3-lto" then
         flags[#flags + 1] = "-flto"
         if compiler.backend == "llvm" then
            flags[#flags + 1] = "-fuse-ld=lld-18"
         end
      end

      for _, flag in ipairs(task.flags or {}) do
         flags[#flags + 1] = flag
      end

      local compile = {
         compiler.cc,
         "-std=c" .. task.dialect,
         "-I" .. fixture.source_root,
         "-c",
         fixture.source_root .. "/" .. fixture.source,
         "-o",
         object,
      }

      for _, flag in ipairs(flags) do
         compile[#compile + 1] = flag
      end

      evidence_io.execute(report, directory, "compile-core", compile)

      local diagnostics = qualification_model.diagnostics(catalog, task)

      --- Compile one diagnostic fixture and verify its expected outcome.
      -- @param diagnostic table: diagnostic supplied to this operation.
      -- @return nil: no values.
      local function qualification_run_checkDiagnostic(diagnostic)
         local case = diagnostic.id
         local source = directory
            .. "/"
            .. case
            .. (diagnostic.cpp_dialect and ".cpp" or ".c")

         build_io.write(source, build_io.read(diagnostic.source))

         --- Choose the diagnostic language and construct literal compiler
         -- arguments.
         -- @return table: choose the diagnostic language and construct literal
         -- compiler arguments.
         local function qualification_run_diagnosticCommand()
            local dialect = diagnostic.cpp_dialect
            local command = {
               dialect and compiler.cxx or compiler.cc,
               dialect
                     and ("-std=c++" .. (dialect == "26" and "2c" or dialect))
                  or ("-std=c" .. task.dialect),
               "-I" .. fixture.source_root,
               "-DLMA_OPERATIONS=" .. tostring(catalog.validation_operations),
               source,
               object,
               "-o",
               directory .. "/" .. case,
            }

            if dialect then
               command[#command + 1] = "-DLMA_INDIRECT=1"
            end

            return command
         end

         local command = qualification_run_diagnosticCommand()

         --- Retain diagnostic flags that are meaningful for the probe.
         -- @param flag any: flag supplied to this operation.
         -- @return nil: no values.
         local function qualification_run_selectFlag(flag)
            if flag ~= "-ffreestanding" and flag ~= "-fno-builtin" then
               command[#command + 1] = flag
            end
         end

         for _, flag in ipairs(flags) do
            qualification_run_selectFlag(flag)
         end

         --- Require a diagnostic fixture to produce its contracted result.
         -- @return nil: no values.
         local function qualification_run_checkExpectedDiagnostic()
            if diagnostic.expected then
               -- Fixed settings qualify the detector; optimized twins test the
               -- API.
               command = {
                  compiler.cc,
                  "-std=c" .. task.dialect,
                  diagnostic.optimization,
                  "-g",
                  "-fsanitize=" .. diagnostic.sanitizer,
                  "-fno-sanitize-recover=all",
                  source,
                  "-o",
                  directory .. "/" .. case,
               }
            end
         end

         qualification_run_checkExpectedDiagnostic()

         evidence_io.execute(report, directory, "compile-" .. case, command)
      end

      for _, diagnostic in ipairs(diagnostics) do
         qualification_run_checkDiagnostic(diagnostic)
      end
   end

   handlers.diagnostic_build = QUALIFICATION_RUN_diagnosticBuild

   --- Run the diagnostic counterpart and retain its failures and artifact
   -- identities.
   -- @return nil: no values.
   local function QUALIFICATION_RUN_diagnosticRun()
      local producer = qualification_run_dependency(task.producer)

      report.status = "FAIL"

      local executable = producer .. "/" .. task.case

      evidence_io.execute(
         report,
         directory,
         "chmod-diagnostic",
         { "chmod", "u+x", executable }
      )

      local ok = build_io.run(report, directory, "diagnostic", {
         "cmake",
         "-E",
         "chdir",
         absolute,
         "timeout",
         policy.timeout.execution,
         build_io.root .. "/" .. executable,
      }, {
         ASAN_OPTIONS = "detect_leaks=0:halt_on_error=1",
         UBSAN_OPTIONS = "halt_on_error=1",
         LC_ALL = "C",
         TZ = "UTC",
      })

      local log = build_io.read(directory .. "/diagnostic.log")
      local contract

      local diagnostics = qualification_model.diagnostics(catalog, task)

      for _, diagnostic in ipairs(diagnostics) do
         if diagnostic.id == task.case then
            contract = diagnostic
         end
      end

      assert(contract, "diagnostic contract missing")

      if not contract.expected then
         assert(
            ok and log == evidence_io.trace(catalog.validation_operations),
            "sanitized mock failed"
         )
      else
         assert(
            not ok and log:find(contract.expected, 1, true),
            "sanitizer failed its detection control"
         )
      end
   end

   handlers.diagnostic_run = QUALIFICATION_RUN_diagnosticRun

   local ok, failure = xpcall(
      --- Dispatch the declared qualification stage after validating the
      -- executor.
      -- @return nil: no values.
      function()
         assert(
            build_io.output({ "uname", "-sm" }) == policy.executor,
            "unqualified executor"
         )

         handlers[task.stage]()

         report.status = "PASS"
      end,
      debug.traceback
   )

   if not ok then
      report.error = tostring(failure):gsub("[\128-\255]", "?")
   end

   evidence_io.seal(report, directory)

   print(task.id .. ": " .. report.status)
   assert(ok, failure)
end

return scripts_qualification_run_main()

-- EOF


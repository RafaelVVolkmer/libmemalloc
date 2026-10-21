-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Native ELF boundary; LTO stays inside the producing toolchain.
-- Part of planned qualification tasks and producer/consumer evidence.

--- Construct this module within its own initialization scope.
-- @param ... any: chunk arguments forwarded without changing their arity.
-- @return table: public operations constructed by this module.
local function scripts_qualification_lib_build_loadModule(...)
   local evidence_io = assert(..., "qualification I/O context required")
   local build_io, artifact_io = evidence_io.B, evidence_io.R
   local policy = evidence_io.catalog.host
   local fixture = evidence_io.catalog.fixture
   local exports = {}
   local lock = dofile("scripts/toolchain/lib/lock.lua").load()

   --- Resolve one declared producer without inferring its identity from
   -- executable
   -- names.
   -- @param catalog table: qualification policy.
   -- @param name string: producer ID from the plan.
   -- @return table: compiler configuration; raises for an undeclared producer.
   local function QUALIFICATION_BUILD_compiler(catalog, name)
      for _, compiler in ipairs(catalog.compilers) do
         if compiler.id == name then
            return compiler
         end
      end

      error("unknown compiler")
   end

   exports.compiler = QUALIFICATION_BUILD_compiler

   --- Record executable identities and reject version or target drift before
   -- building.
   -- @param report table: mutable task evidence.
   -- @param directory string: task output directory.
   -- @param catalog table: qualified compiler and host policy.
   -- @return nil: no values.
   local function QUALIFICATION_BUILD_tools(report, directory, catalog)
      local identities = {}

      for _, compiler in ipairs(catalog.compilers) do
         for _, name in ipairs({ compiler.cc, compiler.cxx }) do
            local tool = build_io.tool(name)

            tool.version = evidence_io
               .execute(
                  report,
                  directory,
                  name .. "-version",
                  { tool.path, "-dumpversion" }
               )
               :gsub("%s+$", "")
            if compiler.backend == "gcc" then
               tool.version = build_io.output({ tool.path, "-dumpfullversion" })
            end

            assert(
               tool.version == lock[compiler.lock].version,
               "compiler version drift: " .. name
            )

            local target = build_io.output({ tool.path, "-dumpmachine" })
            local accepted = false

            for _, expected in ipairs(compiler.targets) do
               accepted = accepted or target == expected
            end

            assert(accepted, "unqualified target")

            identities[name] = tool
         end
      end

      for _, name in pairs(policy.tools) do
         identities[name] = build_io.tool(name)
      end

      build_io.json(directory .. "/tools.json", identities)

      report.tools_sha256 = build_io.digest(directory .. "/tools.json")
      report.host = {
         kernel = build_io.output({ "uname", "-srvmo" }),
         runner_image = os.getenv("ImageVersion") or "local",
         cpu = build_io.output({ "lscpu" }),
      }
   end

   exports.tools = QUALIFICATION_BUILD_tools

   --- Append ordered compiler arguments without modifying the source list.
   -- @param target table: target supplied to this operation.
   -- @param values table: values consumed in the operation’s declared order.
   -- @return any: append ordered compiler arguments without modifying the
   -- source list.
   local function qualification_build_append(target, values)
      for _, value in ipairs(values) do
         target[#target + 1] = value
      end

      return target
   end

   --- Build one artifact; profile data and optimization policy are explicit
   -- inputs.
   -- @param report table: mutable command and artifact evidence.
   -- @param directory string: fresh task output directory.
   -- @param compiler table: selected compiler adapter.
   -- @param task table: planned dialect, mode and flags.
   -- @param profile string|nil: accepted consolidated profile path.
   -- @return nil: no values.
   local function QUALIFICATION_BUILD_library(
      report,
      directory,
      compiler,
      task,
      profile
   )
      local absolute = build_io.root .. "/" .. directory
      local work = absolute .. "/work"

      build_io.mkdir(work)

      build_io.write(
         work .. "/" .. fixture.source,
         build_io.read(fixture.source_root .. "/" .. fixture.source)
      )

      build_io.write(
         work .. "/" .. fixture.header,
         build_io.read(fixture.source_root .. "/" .. fixture.header)
      )

      --- Select optimization mode and stable source-path mappings.
      -- @return boolean, boolean, table: optimization mode and stable
      -- source-path mappings.
      local function qualification_build_baseFlags()
         local instrument = task.mode == "instrument"
         local lto = instrument or task.mode == "pgo" or task.mode == "O3-lto"
         local flags = {
            "-std=c" .. task.dialect,
            "-" .. ((lto or task.flags) and "O3" or task.mode),
            "-ffile-prefix-map=" .. build_io.root .. "=/src",
            "-ffile-prefix-map=" .. absolute .. "=/qualification",
            "-frandom-seed=libmemalloc",
         }

         qualification_build_append(flags, policy.compiler_flags)

         qualification_build_append(flags, task.flags or {})

         return instrument, lto, flags
      end

      local instrument, lto, flags = qualification_build_baseFlags()

      report.semantic_profile = task.semantics or "strict"

      --- Reject unsupported optimization flags before compiling the fixture.
      -- @return nil: no values.
      local function qualification_build_probeFlags()
         if not instrument and not profile then
            build_io.write(
               work .. "/capability.c",
               "int main(void) { return 0; }\n"
            )

            local probe = {
               compiler.cc,
               "-Werror",
               "-std=c" .. task.dialect,
               "-" .. ((lto or task.flags) and "O3" or task.mode),
            }

            qualification_build_append(probe, task.flags or {})

            qualification_build_append(
               probe,
               { work .. "/capability.c", "-o", work .. "/capability" }
            )
            if not build_io.run(report, directory, "flag-probe", probe) then
               report.status = "UNSUPPORTED"
               error("flag profile is not supported by the pinned compiler")
            end

            evidence_io.execute(
               report,
               directory,
               "flag-probe-run",
               { "timeout", policy.timeout.probe, work .. "/capability" }
            )
         end
      end

      qualification_build_probeFlags()

      if lto then
         qualification_build_append(
            flags,
            { compiler.backend == "llvm" and "-flto=thin" or "-flto" }
         )
      end

      --- Apply instrumentation or profile-use flags for the selected backend.
      -- @return nil: no values.
      local function qualification_build_profileFlags()
         if instrument then
            qualification_build_append(
               flags,
               { "-fprofile-generate=profiles", "-fprofile-update=atomic" }
            )
         elseif profile then
            flags[#flags + 1] = "-fprofile-use=" .. profile
            if compiler.backend == "gcc" then
               qualification_build_append(flags, {
                  "-Werror=missing-profile",
                  "-Werror=coverage-mismatch",
                  "-fdump-ipa-profile-details",
               })
            else
               qualification_build_append(flags, {
                  "-Werror=profile-instr-unprofiled",
                  "-Werror=profile-instr-out-of-date",
               })
            end
         end
      end

      qualification_build_profileFlags()

      if compiler.backend == "gcc" then
         flags[#flags + 1] = "-fprofile-prefix-path=" .. work

         -- GCC otherwise embeds the absolute profiling path in DW_AT_producer.
         -- Exact argv remains in the external command evidence.
         flags[#flags + 1] = "-gno-record-gcc-switches"
      end

      local environment = {
         SOURCE_DATE_EPOCH = report.source_date_epoch,
         LC_ALL = "C",
         TZ = "UTC",
         CCACHE_DISABLE = "1",
      }

      local compile = qualification_build_append(
         { "cmake", "-E", "chdir", work, compiler.cc },
         flags
      )

      qualification_build_append(
         compile,
         { "-c", fixture.source, "-o", fixture.object }
      )

      evidence_io.execute(
         report,
         directory,
         "compile-library",
         compile,
         environment
      )

      local link = qualification_build_append(
         { "cmake", "-E", "chdir", work, compiler.cc },
         flags
      )

      if compiler.backend == "llvm" then
         link[#link + 1] = "-fuse-ld="
            .. policy.tools.llvm_linker:gsub("^ld%.", "")
      end

      qualification_build_append(link, {
         "-shared",
         policy.hardening,
         "-Wl,--build-id=sha1",
         "-Wl,-soname," .. fixture.shared,
         fixture.object,
         "-o",
         absolute .. "/" .. fixture.shared,
      })
      if not instrument then
         qualification_build_append(
            link,
            { "-nostdlib", "-nodefaultlibs", "-Wl,--no-undefined" }
         )
      end

      evidence_io.execute(report, directory, "link-library", link, environment)
      if not lto then
         evidence_io.execute(report, directory, "archive", {
            policy.tools.archive,
            "rcsD",
            absolute .. "/" .. fixture.static,
            work .. "/" .. fixture.object,
         })
      end

      --- Retain compiler-specific optimization evidence for a profile build.
      -- @return nil: no values.
      local function qualification_build_recordOptimization()
         if profile then
            if compiler.backend == "llvm" then
               local ir = qualification_build_append({ compiler.cc }, flags)

               qualification_build_append(ir, {
                  "-S",
                  "-emit-llvm",
                  work .. "/" .. fixture.source,
                  "-o",
                  absolute .. "/profile-use.ll",
               })

               evidence_io.execute(
                  report,
                  directory,
                  "profile-use",
                  ir,
                  environment
               )
               assert(
                  build_io
                     .read(absolute .. "/profile-use.ll")
                     :find("function_entry_count", 1, true),
                  "profile was not applied"
               )
            else
               local feedback = ""

               for _, file in ipairs(artifact_io.files(work)) do
                  if file:match("%.profile$") then
                     feedback = feedback .. build_io.read(work .. "/" .. file)
                  end
               end

               local marker = "Profile feedback for function is available"

               assert(feedback:find(marker, 1, true), "profile was not applied")
            end
         end
      end

      qualification_build_recordOptimization()

      report.library_sha256 = build_io.digest(absolute .. "/" .. fixture.shared)
      report.lto = lto
   end

   exports.library = QUALIFICATION_BUILD_library

   --- Check the final native binary against the selected fixture and host
   -- contracts.
   -- @param report table: mutable analysis evidence.
   -- @param directory string: directory containing the compiled library.
   -- @param catalog table: export, dependency and resource policy.
   -- @return nil: no values.
   local function QUALIFICATION_BUILD_audit(report, directory, catalog)
      local library = directory .. "/" .. fixture.shared
      local symbols = evidence_io.execute(report, directory, "exports", {
         policy.tools.symbols,
         "-D",
         "--defined-only",
         "--format=posix",
         library,
      })

      assert(symbols:match(fixture.exports_pattern), "API exports differ")
      assert(
         evidence_io.execute(
            report,
            directory,
            "imports",
            { policy.tools.symbols, "-D", "--undefined-only", library }
         ) == "",
         "core imports external helpers"
      )

      local structure = evidence_io.execute(report, directory, "binary", {
         policy.tools.object,
         "--file-headers",
         "--sections",
         "--needed-libs",
         "--symbols",
         library,
      })

      assert(
         structure:find(policy.binary_format, 1, true),
         "wrong artifact target"
      )

      for _, pattern in ipairs(policy.forbidden_sections) do
         assert(
            not structure:find(pattern, 1, true),
            "instrumentation or IR in product"
         )
      end

      local dynamic = evidence_io.execute(
         report,
         directory,
         "hardening",
         { policy.tools.elf, "-lW", "-dW", library }
      )

      assert(
         not dynamic:find("(NEEDED)", 1, true),
         "unexpected runtime dependency"
      )
      assert(
         dynamic:find("GNU_RELRO", 1, true)
            and dynamic:find("BIND_NOW", 1, true),
         "missing hardening"
      )
      assert(
         dynamic:match("GNU_STACK[^\n]+RW%s"),
         "executable or missing stack contract"
      )
      assert(
         #build_io.read(library) <= catalog.max_library_bytes,
         "artifact exceeds size budget"
      )
   end

   exports.audit = QUALIFICATION_BUILD_audit

   --- Link a consumer across the qualified native ABI boundary.
   -- Static consumers never receive a foreign compiler's LTO representation.
   -- @param report table: mutable build evidence.
   -- @param directory string: producer artifact directory.
   -- @param compiler table: consumer toolchain.
   -- @param consumer table: name, operations, indirect, optimization, static
   -- and dialect; optional choices retain the campaign defaults.
   -- @return nil: writes the consumer and records the linker invocation.
   local function QUALIFICATION_BUILD_consumer(
      report,
      directory,
      compiler,
      consumer
   )
      local name, operations = consumer.name, consumer.operations
      local indirect, optimization = consumer.indirect, consumer.optimization
      local static, dialect = consumer.static, consumer.dialect
      local absolute = build_io.root .. "/" .. directory
      local source = absolute .. "/" .. name .. (indirect and ".cpp" or ".c")

      build_io.write(source, build_io.read(fixture.consumer))

      --- Select consumer language, dialect and compile-time workload.
      -- @return table: consumer language, dialect and compile-time workload.
      local function qualification_build_consumerCommand()
         local standard = dialect == "26" and "2c"
            or (dialect or evidence_io.catalog.primary_dialect)

         local command = {
            indirect and compiler.cxx or compiler.cc,
            (indirect and "-std=c++" or "-std=c") .. standard,
            optimization or "-O2",
            "-DLMA_OPERATIONS=" .. tostring(operations),
            "-I" .. fixture.source_root,
            "-ffile-prefix-map=" .. absolute .. "=/qualification",
            source,
         }

         return command
      end

      local command = qualification_build_consumerCommand()

      qualification_build_append(command, policy.consumer_flags)

      if indirect then
         command[#command + 1] = "-DLMA_INDIRECT=1"
      end

      if static then
         command[#command + 1] = absolute .. "/" .. fixture.static
      else
         qualification_build_append(
            command,
            { "-L" .. absolute, "-l" .. fixture.library, "-Wl,-rpath,$ORIGIN" }
         )
      end

      qualification_build_append(
         command,
         { policy.hardening, "-o", absolute .. "/" .. name }
      )

      evidence_io.execute(report, directory, "link-" .. name, command, {
         LC_ALL = "C",
         TZ = "UTC",
         SOURCE_DATE_EPOCH = report.source_date_epoch,
      })
   end

   exports.consumer = QUALIFICATION_BUILD_consumer

   --- Materialize the consumers declared by the campaign before isolated
   -- execution.
   -- @param report table: mutable build evidence.
   -- @param directory string: producer output directory.
   -- @param catalog table: compiler and consumer policies.
   -- @param task table: producer mode used to choose the opposite consumer
   -- optimization.
   -- @return nil: no values.
   local function QUALIFICATION_BUILD_consumers(
      report,
      directory,
      catalog,
      task
   )
      for _, consumer in ipairs(evidence_io.Q.consumers(catalog)) do
         exports.consumer(report, directory, consumer.compiler, {
            name = consumer.id,
            operations = catalog.validation_operations,
            indirect = consumer.profile.indirect,
            optimization = task.mode == "O0" and "-O3" or "-O0",
            static = not report.lto and consumer.profile.static,
            dialect = consumer.dialect,
         })
      end
   end

   exports.consumers = QUALIFICATION_BUILD_consumers

   return exports
end

return scripts_qualification_lib_build_loadModule(...)

-- EOF


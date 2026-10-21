-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Independent engines and local structural rules, with explicit coverage.
-- Part of local and CI verification gates.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_check_c_analysis_main()
   local analysis = dofile("scripts/analysis/lib/context.lua")
   local artifact_io = analysis.release
   local tools = dofile("scripts/toolchain/lib/lock.lua").load()
   local options = artifact_io.options(arg, { campaign = true, output = true })
   local campaign = assert(options.campaign, "--campaign is required")
   local analysis_context = analysis.new(
      campaign,
      options.output or (".cache/ci/c-analysis/" .. campaign)
   )
   local report = analysis_context.report
   local adapters = {}

   --- Run GCC analyzer fixtures and require the contracted positive and
   -- negative
   -- findings.
   -- @return nil: no values.
   local function CHECK_C_ANALYSIS_gcc()
      local compiler = analysis_context:tool(
         "gcc",
         os.getenv("LIBMEMALLOC_GCC_ANALYZER")
            or ("gcc-" .. tools.gcc_analyzer.version)
      )

      assert(
         artifact_io.output({ compiler, "-dumpversion" })
            == tools.gcc_analyzer.version,
         "GCC profile mismatch"
      )

      local database = analysis_context:build(compiler)

      analysis_context:identity(database)

      --- Invoke the selected analyzer on one source and retain its diagnostic
      -- evidence.
      -- @param source any: source value inspected by this operation.
      -- @param label string: diagnostic or evidence label for this operation.
      -- @return any, any, any: invoke the selected analyzer on one source and
      -- retain its diagnostic evidence.
      local function check_c_analysis_analyze(source, label)
         local code, log = analysis_context:run(label, {
            compiler,
            "-std=" .. analysis_context.profile.dialect,
            "-Icore",
            "-O0",
            "-g",
            "-Wall",
            "-Wextra",
            "-fanalyzer",
            "-Wanalyzer-too-complex",
            "-Wanalyzer-symbol-too-complex",
            "-fdiagnostics-format=json",
            "-c",
            source,
            "-o",
            analysis_context.output .. "/" .. label .. ".o",
         })

         assert(code == 0, "GCC invocation failed; inspect " .. log)

         local limitations = tonumber(
            artifact_io.query(
               log,
               (
                  '[.[] | select(.option == "-Wanalyzer-too-complex" '
                  .. 'or .option == "-Wanalyzer-symbol-too-complex")] | '
                  .. "length"
               )
            )
         )

         local findings = tonumber(artifact_io.query(log, "length"))
            - limitations

         return findings, limitations, log
      end

      local clean = check_c_analysis_analyze(
         analysis_context:fixture("clean"),
         "fixture-clean"
      )

      assert(clean == 0, "GCC clean fixture rejected")

      local bad, _, log = check_c_analysis_analyze(
         analysis_context:fixture("null"),
         "fixture-null"
      )

      assert(
         bad > 0
            and artifact_io
               .read(log)
               :find("-Wanalyzer-null-dereference", 1, true),
         "GCC null checker lost"
      )

      for index, source in ipairs(analysis_context.profile.sources) do
         local findings, limitations =
            check_c_analysis_analyze(source, "source-" .. index)

         report.findings = report.findings + findings
         if limitations > 0 then
            report.status = "INCOMPLETE"

            local message = source .. ": analyzer complexity limit"

            table.insert(report.coverage_limitations, message)
         end

         report.analyzed[#report.analyzed + 1] = source
      end
   end

   adapters.gcc = CHECK_C_ANALYSIS_gcc

   --- Check the Sparse adapter against typed fixtures and the declared
   -- implementation.
   -- @return nil: no values.
   local function CHECK_C_ANALYSIS_sparse()
      local executable = analysis_context:tool(
         "sparse",
         os.getenv("LIBMEMALLOC_SPARSE") or "sparse"
      )

      analysis_context:identity()

      --- Scan one named fixture and retain the adapter output for acceptance
      -- checks.
      -- @param source any: source value inspected by this operation.
      -- @param label string: diagnostic or evidence label for this operation.
      -- @return any: scan one named fixture and retain the adapter output for
      -- acceptance checks.
      local function check_c_analysis_scan(source, label)
         local code, log = analysis_context:run(label, {
            executable,
            "-std=c99",
            "-Icore",
            "-Wbitwise",
            "-Wcontext",
            source,
         })

         assert(code == 0, "Sparse execution failed")

         return artifact_io.read(log)
      end

      assert(
         check_c_analysis_scan(
            analysis_context:fixture("clean"),
            "fixture-clean"
         ) == "",
         "Sparse clean fixture rejected"
      )
      assert(
         check_c_analysis_scan(
            analysis_context:fixture("sparse-types"),
            "fixture-types"
         ):find("incorrect type", 1, true),
         "Sparse restricted type checker lost"
      )

      for index, source in ipairs(analysis_context.profile.sources) do
         local log = check_c_analysis_scan(source, "source-" .. index)

         if log ~= "" then
            report.findings = report.findings + 1
         end

         report.analyzed[#report.analyzed + 1] = source
      end

      report.coverage_limitations[#report.coverage_limitations + 1] =
         "Production lock/address-space annotations are not yet present."
   end

   adapters.sparse = CHECK_C_ANALYSIS_sparse

   --- Run Clang analysis with the declared checkers, compilation database and
   -- fixture expectations.
   -- @return nil: no values.
   local function CHECK_C_ANALYSIS_csa()
      local compiler = analysis_context:tool(
         "clang",
         os.getenv("LIBMEMALLOC_CLANG_ANALYZER")
            or ("clang-" .. tools.clang_analyzer.version)
      )

      local checker = analysis_context:tool(
         "codechecker",
         os.getenv("LIBMEMALLOC_CODECHECKER") or "CodeChecker",
         "version"
      )

      local compiler_path = artifact_io.output({ "which", compiler })
      local database = analysis_context:build(compiler)

      analysis_context:identity(database)

      local ctu = campaign == "csa-ctu"

      report.ctu = ctu

      --- Invoke the selected analyzer on one source and retain its diagnostic
      -- evidence.
      -- @param input any: input selected by the caller.
      -- @param label string: diagnostic or evidence label for this operation.
      -- @param expected any: expected reference value used by this check.
      -- @return any, string: invoke the selected analyzer on one source and
      -- retain its diagnostic evidence.
      local function check_c_analysis_analyze(input, label, expected)
         local destination = analysis_context.output .. "/" .. label
         local command = {
            "env",
            "CC_ANALYZER_BIN=clangsa:" .. compiler_path,
            checker,
            "analyze",
            input,
            "--analyzers",
            "clangsa",
            "--disable-all",
            "--capture-analysis-output",
            "--timeout",
            "60",
            "--compile-uniqueing",
            "strict",
            "-j",
            "2",
            "-o",
            destination,
         }

         for _, name in ipairs(analysis_context.profile.csa_checkers) do
            command[#command + 1] = "--enable"
            command[#command + 1] = name
         end

         if ctu then
            command[#command + 1] = "--ctu"
            command[#command + 1] = "--ctu-ast-mode"
            command[#command + 1] = "parse-on-demand"
         end

         assert(
            analysis_context:run(label, command) == 0,
            "CSA invocation failed"
         )

         local metadata = destination .. "/metadata.json"

         assert(
            artifact_io.query(metadata, ".tools[0].skipped") == "0",
            "CSA skipped inputs"
         )
         assert(
            artifact_io.query(
               metadata,
               ".tools[0].analyzers.clangsa.analyzer_statistics.failed"
            ) == "0",
            "CSA failed inputs"
         )

         local successful = analysis.lines(
            artifact_io.query(
               metadata,
               (
                  ".tools[0].analyzers.clangsa.analyzer_statistics."
                  .. "successful_sources[]"
               )
            )
         )

         table.sort(successful)

         table.sort(expected)
         assert(
            table.concat(successful, "\n") == table.concat(expected, "\n"),
            "CSA coverage mismatch"
         )

         local json = destination .. "/findings.json"
         local code = analysis_context:run(label .. "-parse", {
            checker,
            "parse",
            destination,
            "--export",
            "json",
            "--output",
            json,
            "--review-status",
            "confirmed",
            "false_positive",
            "intentional",
            "suppress",
            "unreviewed",
         })

         assert(code == 0 or code == 2, "CSA result export failed")

         return tonumber(artifact_io.query(json, ".reports | length")), json
      end

      --- Create a compilation database for the named analyzer fixture.
      -- @param name string: entry or operation name to resolve.
      -- @return string, table: a compilation database for the named analyzer
      -- fixture.
      local function check_c_analysis_fixtureDatabase(name)
         local source = analysis_context.root
            .. "/"
            .. analysis_context:fixture(name)
         local input = analysis_context.output .. "/fixture-" .. name .. ".json"

         artifact_io.document(
            input,
            artifact_io.array({
               {
                  directory = analysis_context.root,
                  file = source,
                  arguments = artifact_io.array({
                     compiler_path,
                     "-std=c99",
                     "-c",
                     source,
                     "-o",
                     analysis_context.root
                        .. "/"
                        .. analysis_context.output
                        .. "/fixture.o",
                  }),
               },
            })
         )

         return input, { source }
      end

      local clean, clean_sources = check_c_analysis_fixtureDatabase("clean")

      assert(
         check_c_analysis_analyze(clean, "fixture-clean-csa", clean_sources)
            == 0,
         "CSA clean fixture rejected"
      )

      local bad, bad_sources = check_c_analysis_fixtureDatabase("null")
      local findings, json =
         check_c_analysis_analyze(bad, "fixture-null-csa", bad_sources)

      assert(
         findings > 0
            and artifact_io.read(json):find("core.NullDereference", 1, true),
         "CSA null checker lost"
      )
      if ctu then
         local caller = analysis_context.root
            .. "/"
            .. analysis_context.output
            .. "/fixtures/caller.c"
         local callee = analysis_context.root
            .. "/"
            .. analysis_context.output
            .. "/fixtures/callee.c"

         artifact_io.write(
            caller,
            "int get_zero(void);\nint main(void) { return 1 / get_zero(); }\n"
         )

         artifact_io.write(callee, "int get_zero(void) { return 0; }\n")

         local records = artifact_io.array()

         for _, source in ipairs({ caller, callee }) do
            records[#records + 1] = {
               directory = analysis_context.root,
               file = source,
               arguments = artifact_io.array({
                  compiler_path,
                  "-std=c99",
                  "-c",
                  source,
                  "-o",
                  source .. ".o",
               }),
            }
         end

         local input = analysis_context.output .. "/fixture-ctu.json"

         artifact_io.document(input, records)

         local cross_findings, cross_json = check_c_analysis_analyze(
            input,
            "fixture-cross-tu",
            { caller, callee }
         )
         local cross_detected = cross_findings > 0
            and artifact_io.read(cross_json):find("core.DivideZero", 1, true)

         assert(cross_detected, "CTU import failed its cross-file fixture")
      end

      local expected = {}

      for _, source in ipairs(analysis_context.profile.sources) do
         expected[#expected + 1] = analysis_context.root .. "/" .. source
      end

      report.findings = check_c_analysis_analyze(database, "sources", expected)
      report.analyzed = artifact_io.array(analysis_context.profile.sources)
   end

   adapters.csa = CHECK_C_ANALYSIS_csa

   adapters["csa-ctu"] = adapters.csa

   local adapter = assert(adapters[campaign], "unknown campaign")

   analysis_context:finish(
      --- Run the selected adapter after validating its declared source
      -- inventory.
      -- @return nil: no values.
      function()
         analysis_context:inventory()

         adapter()
      end
   )
end

return scripts_check_c_analysis_main()

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Enforce numeric C/C++ quality gates and retain failures for review.
-- Lizard measures cyclomatic complexity/clones; Clang-Tidy measures cognition.
-- Part of C analysis; thresholds and formal scope share a reviewed manifest.

--- Run independent gates without losing diagnostics after an earlier failure.
-- @return nil: no values.
local function QUALITY_main()
   local QUALITY_TIMEOUT_MS = 180000
   local QUALITY_CMAKE_TIMEOUT_MS = 600000
   local QUALITY_NEGATIVE_NESTING = 8

   local io_tools = dofile("scripts/lib/artifacts.lua")
   local execution = dofile("scripts/process/lib/exec.lua")
   local manifest = "tools/analysis/c/gates.json"
   local output = ".cache/ci/c-analysis/quality"
   local lua = os.getenv("LIBMEMALLOC_LUA") or "lua"
   local python = os.getenv("LIBMEMALLOC_QUALITY_PYTHON") or "python3"
   local tidy = os.getenv("LIBMEMALLOC_CLANG_TIDY") or "clang-tidy"
   local sources, units, seen = {}, {}, {}
   local report = { schema = 1, gates = io_tools.array() }
   local timeout_ms = QUALITY_TIMEOUT_MS
   local timeouts = { cmake = QUALITY_CMAKE_TIMEOUT_MS }

   --- Preserve both streams and the outcome of one bounded tool invocation.
   -- @param name string: entry or operation name to resolve.
   -- @param command table: executable and literal command arguments.
   -- @param expected_diagnostic any: expected diagnostic supplied to this
   -- operation.
   -- @return nil: no values.
   local function run(name, command, expected_diagnostic)
      local result =
         execution.run(command, { timeout_ms = timeouts[name] or timeout_ms })

      io_tools.write(
         output .. "/" .. name .. ".log",
         result.stdout .. result.stderr
      )
      local accepted = result.state == "PASS"

      if expected_diagnostic then
         accepted = result.state == "FAIL"
            and (result.stdout .. result.stderr):find(
                  expected_diagnostic,
                  1,
                  true
               )
               ~= nil
      end

      report.gates[#report.gates + 1] = {
         name = name,
         state = accepted and "PASS" or "FAIL",
         exit_code = result.exit_code,
      }
      print(name .. ": " .. (accepted and "PASS" or "FAIL"))
   end

   local inventory = io_tools.output({
      "git",
      "ls-files",
      "--cached",
      "--others",
      "--exclude-standard",
      "-z",
   })
   local roots = io_tools.query(manifest, ".source_roots[]")
   local extensions = io_tools.query(manifest, ".extensions[]")

   --- Select one owned C translation unit for quality analysis.
   -- @param path string: filesystem path selected by the caller.
   -- @return nil: no values.
   local function quality_collectUnit(path)
      --- Select translation units belonging to a declared implementation root.
      -- @param root string: root directory for this operation.
      -- @return nil: no values.
      local function quality_matchRoot(root)
         local extension = path:match("%.[^.]+$")

         if
            path:sub(1, #root + 1) == root .. "/"
            and extension
            and ("\n" .. extensions .. "\n"):find(
               "\n" .. extension .. "\n",
               1,
               true
            )
            and not seen[path]
            and io_tools.exists(path)
         then
            seen[path] = true
            sources[#sources + 1] = path
            if
               extension == ".c"
               or extension == ".cpp"
               or extension == ".cc"
               or extension == ".cxx"
            then
               units[#units + 1] = path
            end
         end
      end

      for root in roots:gmatch("[^\n]+") do
         quality_matchRoot(root)
      end
   end

   for path in inventory:gmatch("([^%z]+)%z") do
      quality_collectUnit(path)
   end

   assert(#units > 0, "Quality gate has no translation units")
   local metrics = {
      python,
      "tools/analysis/c/metrics.py",
      "--manifest",
      manifest,
      "--output",
      output .. "/metrics.json",
   }

   for _, source in ipairs(sources) do
      metrics[#metrics + 1] = source
   end

   run("engine-regressions", {
      python,
      "tests/automation/analysis/metrics_test.py",
   })
   run("lizard", metrics)

   local cognitive = tonumber(io_tools.query(manifest, ".limits.cognitive"))

   assert(cognitive and cognitive >= 0, "Invalid cognitive threshold")
   local config = io_tools.json({
      Checks = "-*,readability-function-cognitive-complexity",
      WarningsAsErrors = "*",
      HeaderFilterRegex = "(^|/)core/",
      CheckOptions = {
         ["readability-function-cognitive-complexity.Threshold"] = tostring(
            cognitive
         ),
      },
   })
   local cognitive_fixture = output .. "/cognitive-negative.c"

   io_tools.write(
      cognitive_fixture,
      "int nested(int x) { "
         .. string.rep("if (x) { ", QUALITY_NEGATIVE_NESTING)
         .. "x++;"
         .. string.rep("}", QUALITY_NEGATIVE_NESTING)
         .. "return x; }\n"
   )
   run("cognitive-regression", {
      tidy,
      "--config=" .. config,
      cognitive_fixture,
      "--",
      "-std=c99",
   }, "cognitive complexity")

   --- Run the C analyzers and retain their per-unit reports.
   -- @param index number: one-based position in the current sequence.
   -- @param source string: source supplied to this operation.
   -- @return nil: no values.
   local function quality_analyzeUnit(index, source)
      run("cognitive-" .. index, {
         tidy,
         "--config=" .. config,
         source,
         "--",
         source:match("%.c$") and "-std=c99" or "-std=c++20",
         "-Icore",
      })
   end

   for index, source in ipairs(units) do
      quality_analyzeUnit(index, source)
   end

   run("cmake", { lua, "scripts/check/cmake.lua" })
   run("formal", { lua, "scripts/analysis/formal.lua" })
   report.manifest_sha256 = io_tools.digest(manifest)
   io_tools.document(output .. "/report.json", report)
   for _, gate in ipairs(report.gates) do
      assert(gate.state == "PASS", "C quality gate failed: " .. gate.name)
   end
end

return QUALITY_main()

-- EOF


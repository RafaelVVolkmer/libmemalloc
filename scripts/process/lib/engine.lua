-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Local plan/run/gate/report composition; no promotion authority.
-- Part of local process planning and evidence assessment.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_process_lib_engine_loadModule()
   local evidence_io = dofile("scripts/process/lib/io.lua")
   local process_policy = dofile("scripts/process/lib/policy.lua")
   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local traceability = dofile("scripts/process/lib/traceability.lua")
   local exports = {}

   local PROCESS_SHA256_HEX_LENGTH = 64
   local PROCESS_RUN_ID_MAX_BYTES = 64
   local PROCESS_MILLISECONDS_PER_SECOND = 1000
   local catalog_path = "tools/process/controls.json"

   --- Reconstruct the exact registered command for execution and assessment.
   -- @param runtime table: runtime supplied to this operation.
   -- @param verifier table: verifier supplied to this operation.
   -- @return any: reconstruct the exact registered command for execution and
   -- assessment.
   local function process_engine_command(runtime, verifier)
      local command = evidence_io.array({ runtime.executable, verifier.script })

      for _, argument in ipairs(verifier.arguments or {}) do
         command[#command + 1] = argument
      end

      return command
   end

   --- Identify the interpreter, native process adapter and selected host
   -- environment.
   -- @return table: identify the interpreter, native process adapter and
   -- selected host environment.
   local function process_engine_runtime()
      local executable = evidence_io.uv.exepath()
      local system = evidence_io.uv.os_uname()
      local env = evidence_io.array({ "LANG=C", "LC_ALL=C", "TZ=UTC" })

      for _, name in ipairs({ "PATH", "LUA_PATH", "LUA_CPATH", "TMPDIR" }) do
         local value = os.getenv(name)

         if value then
            env[#env + 1] = name .. "=" .. value
         end
      end

      return {
         lua = _VERSION,
         executable = executable,
         executable_sha256 = evidence_io.digest(executable),
         libuv = evidence_io.uv.version_string(),
         system = system.sysname,
         release = system.release,
         machine = system.machine,
         environment = env,
         toolchain_qualified = false,
      }
   end

   --- Load the control catalogue only after matching its reviewed digest.
   -- @param digest any: expected content digest.
   -- @return any: the control catalogue only after matching its reviewed
   -- digest.
   local function process_engine_policy(digest)
      assert(
         type(digest) == "string"
            and #digest == PROCESS_SHA256_HEX_LENGTH
            and digest:match("^[a-f0-9]+$"),
         "supply --policy-sha256=SHA256"
      )
      assert(
         evidence_io.digest(catalog_path) == digest,
         "policy digest differs from caller expectation"
      )

      return process_policy.catalog(evidence_io.load(catalog_path))
   end

   --- Construct a process plan bound to its attempt, policy and source
   -- identities.
   -- @param run_id any: run id supplied to this operation.
   -- @param digest string: expected content digest.
   -- @return table: a process plan bound to its attempt, policy and source
   -- identities.
   local function process_engine_build(run_id, digest)
      assert(
         type(run_id) == "string"
            and #run_id <= PROCESS_RUN_ID_MAX_BYTES
            and run_id:match("^[%w][%w_-]*$"),
         "invalid run ID"
      )

      local controls, trace = process_engine_policy(digest)
      local subject = evidence_io.subject()
      local sources = {}

      for _, input in ipairs(subject.inputs) do
         sources[input.path] = input.sha256
      end

      for _, design in ipairs(trace.designs) do
         local path = design.reference:match("^([^#]+)")

         assert(
            sources[path] and sources[path] ~= "DELETED",
            "design reference is not a source input"
         )
      end

      return {
         schema_version = 2,
         scope = "automation-pilot",
         profile = "local",
         run_id = run_id,
         policy_sha256 = digest,
         subject = subject,
         runtime = process_engine_runtime(),
         controls = evidence_io.array(controls),
         traceability = trace,
      }
   end

   --- Load a plan and reject policy or source changes before consuming it.
   -- @param path string: filesystem path selected by the caller.
   -- @param digest string: expected content digest.
   -- @return any, any: a plan and reject policy or source changes before
   -- consuming it.
   local function process_engine_openPlan(path, digest)
      local plan = evidence_io.load(path)
      local expected = process_engine_build(plan.run_id, digest)

      assert(
         evidence_io.json(plan) == evidence_io.json(expected),
         "plan, source, policy or runtime changed"
      )

      return expected, evidence_io.digest(path)
   end

   --- Bind verifier output to the planned control and its expected completion
   -- marker.
   -- @param control table: control supplied to this operation.
   -- @param digest string: expected content digest.
   -- @param result table: result supplied to this operation.
   -- @return table: bind verifier output to the planned control and its
   -- expected completion marker.
   local function process_engine_observation(control, digest, result)
      local verifier = process_policy.verifiers[control.verifier]
      local observed = 0

      for line in result.stdout:gmatch("[^\r\n]+") do
         if line == verifier.completion then
            observed = observed + verifier.expected_tests
         end
      end

      local state = result.state

      if state == "PASS" and observed ~= verifier.expected_tests then
         state = "INCONCLUSIVE"
      end

      return {
         control = control.id,
         state = state,
         exit_code = result.exit_code,
         signal = result.signal,
         observed_tests = observed,
         plan_sha256 = digest,
         configuration = control.configuration,
      }
   end

   --- Create a fresh plan for the supported local automation profile.
   -- @param options table: operation settings; omitted fields use the
   -- documented defaults.
   -- @return boolean: a fresh plan for the supported local automation profile.
   local function PROCESS_ENGINE_plan(options)
      assert(options.profile == "local", "only --profile=local is implemented")

      local plan =
         process_engine_build(options["run-id"], options["policy-sha256"])

      evidence_io.document(assert(options.output, "--output required"), plan)

      print(
         "Planned "
            .. #plan.controls
            .. " automation control(s); product qualification excluded."
      )

      return true
   end

   exports.plan = PROCESS_ENGINE_plan

   --- Execute the planned verifiers and retain bounded output with per-control
   -- identities.
   -- @param options table: operation settings; omitted fields use the
   -- documented defaults.
   -- @return boolean|nil: execute the planned verifiers and retain bounded
   -- output with per-control identities.
   local function PROCESS_ENGINE_run(options)
      local plan, digest = process_engine_openPlan(
         assert(options.plan, "--plan required"),
         options["policy-sha256"]
      )
      local output = assert(options.output, "--output required")

      evidence_io.mkdir(output, true)

      -- The plan copy and initial result survive interruption. Completion is a
      -- separate immutable file; a partial attempt cannot satisfy the gate.
      evidence_io.document(output .. "/plan.json", plan)

      local records, observations, passed = evidence_io.array(), {}, true

      for _, control in ipairs(plan.controls) do
         local verifier = process_policy.verifiers[control.verifier]
         local root = output .. "/" .. control.id

         evidence_io.mkdir(root, true)

         evidence_io.document(root .. "/started.json", {
            schema_version = 1,
            plan_sha256 = digest,
            control = control.id,
            started_utc = os.date("!%Y-%m-%dT%H:%M:%SZ"),
         })

         local argv = process_engine_command(plan.runtime, verifier)
         local result = evidence_io.exec.run(argv, {
            timeout_ms = verifier.timeout_seconds
               * PROCESS_MILLISECONDS_PER_SECOND,
            env = plan.runtime.environment,
         })

         evidence_io.write(root .. "/stdout.log", result.stdout)

         evidence_io.write(root .. "/stderr.log", result.stderr)

         local record = {
            schema_version = 1,
            observation = process_engine_observation(control, digest, result),
            command = argv,
            completed_utc = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            stdout_sha256 = evidence_io.digest(root .. "/stdout.log"),
            stderr_sha256 = evidence_io.digest(root .. "/stderr.log"),
         }

         evidence_io.document(root .. "/result.json", record)

         records[#records + 1] = {
            control = control.id,
            sha256 = evidence_io.digest(root .. "/result.json"),
         }
         observations[#observations + 1] = {
            control = control.id,
            state = record.observation.state,
            sha256 = records[#records].sha256,
         }
         passed = passed and record.observation.state == "PASS"
         print(control.id .. ": " .. record.observation.state)
      end

      assert(
         evidence_io.json(plan.subject)
            == evidence_io.json(evidence_io.subject()),
         "sources changed during execution"
      )

      evidence_io.document(
         output .. "/evidence.json",
         traceability.graph(plan, digest, observations, evidence_io.array)
      )

      evidence_io.document(output .. "/manifest.json", {
         schema_version = 1,
         scope = "automation-pilot",
         plan_sha256 = digest,
         run_id = plan.run_id,
         records = records,
      })

      return passed
   end

   exports.run = PROCESS_ENGINE_run

   --- Require the evidence directory to match the complete expected file set.
   -- @param path string: filesystem path selected by the caller.
   -- @param expected any: expected reference value used by this check.
   -- @return nil: no values.
   local function process_engine_inventory(path, expected)
      evidence_io.output_path(path)

      local pending = {}

      for _, name in ipairs(expected) do
         pending[name] = true
      end

      local iterator =
         assert(evidence_io.uv.fs_scandir(path), "missing evidence directory")

      while true do
         local name = evidence_io.uv.fs_scandir_next(iterator)

         if not name then
            break
         end

         assert(pending[name], "unexpected evidence entry: " .. name)

         pending[name] = nil

         local stat = assert(evidence_io.uv.fs_lstat(path .. "/" .. name))

         assert(
            stat.type == "file" or stat.type == "directory",
            "non-regular evidence"
         )
      end

      assert(next(pending) == nil, "missing evidence entry")
   end

   --- Assess retained process evidence and expose missing, altered or foreign
   -- records.
   -- @param options table: operation settings; omitted fields use the
   -- documented defaults.
   -- @return table: assess retained process evidence and expose missing,
   -- altered or foreign records.
   local function PROCESS_ENGINE_assess(options)
      local summary = {
         schema_version = 1,
         scope = "automation-pilot",
         passed = false,
         promotion_authorized = false,
         product_qualified = false,
         failures = evidence_io.array(),
      }
      local ok, failure = pcall(
         --- Compare the retained evidence set with the exact accepted process
         -- plan.
         -- @return nil: no values.
         function()
            local plan, digest = process_engine_openPlan(
               assert(options.plan, "--plan required"),
               options["policy-sha256"]
            )
            local input = assert(options.evidence, "--evidence required")

            evidence_io.output_path(input)

            local manifest = evidence_io.load(input .. "/manifest.json")

            process_policy.fields(
               manifest,
               { "schema_version", "scope", "plan_sha256", "run_id", "records" }
            )
            assert(
               manifest.schema_version == 1
                  and manifest.scope == "automation-pilot",
               "invalid manifest scope"
            )

            local identity_matches = manifest.plan_sha256 == digest
               and manifest.run_id == plan.run_id

            assert(identity_matches, "foreign manifest")
            assert(
               evidence_io.json(evidence_io.load(input .. "/plan.json"))
                  == evidence_io.json(plan),
               "foreign plan copy"
            )
            assert(
               type(manifest.records) == "table"
                  and #manifest.records == #plan.controls,
               "incomplete result inventory"
            )

            process_policy.sequence(manifest.records)

            local entries, records, observations =
               { "manifest.json", "plan.json", "evidence.json" }, {}, {}

            for index, control in ipairs(plan.controls) do
               entries[#entries + 1] = control.id

               local reference = manifest.records[index]

               process_policy.fields(reference, { "control", "sha256" })
               assert(
                  reference.control == control.id,
                  "duplicate, unordered or foreign control"
               )

               local root = input .. "/" .. control.id

               process_engine_inventory(
                  root,
                  { "started.json", "result.json", "stdout.log", "stderr.log" }
               )

               local result_digest = evidence_io.digest(root .. "/result.json")

               assert(result_digest == reference.sha256, "altered result")

               local record = evidence_io.load(root .. "/result.json")

               process_policy.fields(record, {
                  "schema_version",
                  "observation",
                  "command",
                  "completed_utc",
                  "stdout_sha256",
                  "stderr_sha256",
               })
               assert(record.schema_version == 1, "invalid result schema")
               assert(
                  type(record.completed_utc) == "string"
                     and record.completed_utc:match(
                        "^%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%dZ$"
                     ),
                  "invalid completion time"
               )

               local started = evidence_io.load(root .. "/started.json")

               process_policy.fields(
                  started,
                  { "schema_version", "plan_sha256", "control", "started_utc" }
               )
               assert(
                  started.schema_version == 1
                     and started.plan_sha256 == digest
                     and started.control == control.id,
                  "foreign start record"
               )
               assert(
                  type(started.started_utc) == "string"
                     and started.started_utc:match(
                        "^%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%dZ$"
                     )
                     and started.started_utc <= record.completed_utc,
                  "invalid start time"
               )

               local verifier = process_policy.verifiers[control.verifier]

               assert(
                  evidence_io.json(record.command)
                     == evidence_io.json(
                        process_engine_command(plan.runtime, verifier)
                     ),
                  "foreign command"
               )

               local stdout_digest = evidence_io.digest(root .. "/stdout.log")
               local stderr_digest = evidence_io.digest(root .. "/stderr.log")

               assert(stdout_digest == record.stdout_sha256, "altered stdout")
               assert(stderr_digest == record.stderr_sha256, "altered stderr")

               local actual = process_engine_observation(control, digest, {
                  state = record.observation.state,
                  exit_code = record.observation.exit_code,
                  signal = record.observation.signal,
                  stdout = evidence_io.read(root .. "/stdout.log"),
               })

               assert(
                  evidence_io.json(actual)
                     == evidence_io.json(record.observation),
                  "observation differs from log"
               )

               records[#records + 1] = record.observation
               observations[#observations + 1] = {
                  control = control.id,
                  state = record.observation.state,
                  sha256 = result_digest,
               }
            end

            process_engine_inventory(input, entries)

            local graph =
               traceability.graph(plan, digest, observations, evidence_io.array)

            assert(
               evidence_io.json(evidence_io.load(input .. "/evidence.json"))
                  == evidence_io.json(graph),
               "altered requirement evidence graph"
            )
            local verdict = process_policy.gate(plan.controls, records, digest)

            summary.passed = verdict.passed
            summary.failures = evidence_io.array(verdict.failures)
            summary.plan_sha256 = digest
            summary.run_id = plan.run_id
         end
      )

      if not ok then
         summary.failures[#summary.failures + 1] = tostring(failure)
      end

      return summary
   end

   exports.assess = PROCESS_ENGINE_assess

   --- Persist the assessment and fail when any required automation evidence is
   -- unsatisfied.
   -- @param options table: operation settings; omitted fields use the
   -- documented defaults.
   -- @return any: persist the assessment and fail when any required automation
   -- evidence is unsatisfied.
   local function PROCESS_ENGINE_gate(options)
      local summary = exports.assess(options)

      evidence_io.document(assert(options.output, "--output required"), summary)

      print(
         summary.passed
               and "Automation checks passed; promotion remains unauthorized."
            or "BLOCKED: inspect gate evidence."
      )

      return summary.passed
   end

   exports.gate = PROCESS_ENGINE_gate

   --- Render the retained assessment without granting product or release
   -- authorization.
   -- @param options table: operation settings; omitted fields use the
   -- documented defaults.
   -- @return any: the retained assessment without granting product or release
   -- authorization.
   local function PROCESS_ENGINE_report(options)
      local summary = exports.assess(options)
      local lines = {
         "# Engineering automation report",
         "",
         (
            "Scope: automation-pilot. Product "
            .. "qualification: false. Promotion authorized: "
            .. "false."
         ),
         "",
         "Machine gate: " .. (summary.passed and "PASS" or "BLOCKED"),
         "",
      }

      for _, failure in ipairs(summary.failures) do
         lines[#lines + 1] = "- " .. failure:gsub("[\r\n<>`]", " ")
      end

      lines[#lines + 1] = ""
      lines[#lines + 1] = (
         "Human acceptance and framework assessments "
         .. "remain outside this local pilot."
      )
      lines[#lines + 1] = ""
      evidence_io.write(
         assert(options.output, "--output required"),
         table.concat(lines, "\n")
      )

      return summary.passed
   end

   exports.report = PROCESS_ENGINE_report

   --- Run one complete campaign and finalize diagnostics after phase failures.
   -- @param options table: operation settings; omitted fields use the
   -- documented defaults.
   -- @return boolean|nil: run one complete campaign and finalize diagnostics
   -- after phase failures.
   local function PROCESS_ENGINE_campaign(options)
      local root = assert(options.output, "--output required")

      evidence_io.mkdir(root, true)

      local phase_options = {
         profile = options.profile,
         ["run-id"] = options["run-id"],
         ["policy-sha256"] = options["policy-sha256"],
         plan = root .. "/plan.json",
         evidence = root .. "/evidence",
         output = root .. "/plan.json",
      }

      assert(exports.plan(phase_options), "campaign planning failed")

      local passed = true

      for _, phase in ipairs({
         { "run", root .. "/evidence" },
         { "gate", root .. "/gate.json" },
         { "report", root .. "/report.md" },
      }) do
         phase_options.output = phase[2]
         local ok, result = pcall(exports[phase[1]], phase_options)

         if not ok then
            io.stderr:write(phase[1] .. ": " .. tostring(result) .. "\n")
         end

         passed = passed and ok and result == true
      end

      return passed
   end

   exports.campaign = PROCESS_ENGINE_campaign

   --- Dispatch one supported process phase and convert failures to a nonzero
   -- exit
   -- status.
   -- @param mode any: mode supplied to this operation.
   -- @param arguments table: ordered arguments for the selected operation.
   -- @return nil: no values.
   local function PROCESS_ENGINE_main(mode, arguments)
      local options = artifact_io.options(arguments, {
         profile = true,
         ["run-id"] = true,
         ["policy-sha256"] = true,
         plan = true,
         evidence = true,
         output = true,
      })
      local ok, result = xpcall(
         --- Invoke the selected phase and retain its error at the CLI boundary.
         -- @return any: invoke the selected phase and retain its error at the
         -- CLI boundary.
         function()
            return assert(exports[mode], "unknown mode")(options)
         end,
         debug.traceback
      )

      if not ok then
         io.stderr:write(tostring(result) .. "\n")
      end

      os.exit(ok and result and 0 or 1)
   end

   exports.main = PROCESS_ENGINE_main

   return exports
end

return scripts_process_lib_engine_loadModule()

-- EOF


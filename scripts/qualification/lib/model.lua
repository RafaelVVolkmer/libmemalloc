-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Pure graph and evidence acceptance policy; missing work never means PASS.
-- Part of planned qualification tasks and producer/consumer evidence.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_qualification_lib_model_loadModule()
   local exports = {}
   local states = {
      PASS = true,
      FAIL = true,
      UNSUPPORTED = true,
      NOT_APPLICABLE = true,
      INCONCLUSIVE = true,
      INFRA_ERROR = true,
   }

   --- Expand consumer standards without rebuilding the C library for each one.
   -- @param catalog table: reviewed catalog of supported entries.
   -- @return table: expand consumer standards without rebuilding the C library
   -- for each one.
   local function QUALIFICATION_MODEL_consumers(catalog)
      local consumers = {}

      for _, compiler in ipairs(catalog.compilers) do
         for _, case in ipairs(catalog.cases) do
            local profile = catalog.case_profiles[case]
            local dialects = profile.indirect and compiler.cpp_dialects
               or compiler.dialects

            for _, dialect in ipairs(dialects) do
               consumers[#consumers + 1] = {
                  id = compiler.id
                     .. "-"
                     .. case
                     .. "-"
                     .. (profile.indirect and "cpp" or "c")
                     .. dialect,
                  compiler = compiler,
                  case = case,
                  dialect = dialect,
                  profile = profile,
               }
            end
         end
      end

      return consumers
   end

   exports.consumers = QUALIFICATION_MODEL_consumers

   --- Keep detection controls separate from the optimization under
   -- investigation.
   -- @param catalog table: reviewed catalog of supported entries.
   -- @param task table: task supplied to this operation.
   -- @return table: keep detection controls separate from the optimization
   -- under investigation.
   local function QUALIFICATION_MODEL_diagnostics(catalog, task)
      local diagnostics = {}

      for _, diagnostic in ipairs(catalog.fixture.diagnostics) do
         diagnostics[#diagnostics + 1] = diagnostic
      end

      for _, compiler in ipairs(catalog.compilers) do
         if compiler.id == task.compiler then
            for _, dialect in ipairs(compiler.cpp_dialects) do
               diagnostics[#diagnostics + 1] = {
                  id = "mock-cpp" .. dialect,
                  source = catalog.fixture.consumer,
                  sanitizer = "address,undefined",
                  cpp_dialect = dialect,
               }
            end
         end
      end

      return diagnostics
   end

   exports.diagnostics = QUALIFICATION_MODEL_diagnostics

   --- Expand the selected qualification campaign into tasks and required
   -- comparisons.
   -- @param catalog table: reviewed catalog of supported entries.
   -- @param campaign any: campaign supplied to this operation.
   -- @return table: expand the selected qualification campaign into tasks and
   -- required comparisons.
   local function QUALIFICATION_MODEL_plan(catalog, campaign)
      assert(catalog.schema == 1, "unknown qualification schema")
      assert(#catalog.shards > 0, "training requires at least one shard")

      for _, shard in ipairs(catalog.shards) do
         assert(
            shard.weight >= 1 and shard.weight % 1 == 0,
            "invalid counter weight"
         )
         assert(
            shard.operations >= 1 and shard.operations % 1 == 0,
            "invalid operation budget"
         )
      end

      local campaign_policy =
         assert(catalog.campaigns[campaign], "unknown qualification campaign")
      local plan = {
         schema = 1,
         contract = catalog.contract,
         campaign = campaign,
         tasks = {},
         build = {},
         instrument = {},
         train = {},
         merge = {},
         optimize = {},
         run = {},
         diagnostic_build = {},
         diagnostic_run = {},
         comparisons = {},
         pending = catalog.pending,
      }

      local seen = {}

      --- Register a unique task under its declared execution stage.
      -- @param stage any: stage supplied to this operation.
      -- @param task table: task supplied to this operation.
      -- @return nil: no values.
      local function qualification_model_add(stage, task)
         assert(
            task.id:match("^[a-zA-Z0-9-]+$") and not seen[task.id],
            "duplicate or unsafe task"
         )

         seen[task.id] = true
         task.stage = stage
         plan.tasks[#plan.tasks + 1] = task
         plan[stage][#plan[stage] + 1] = task
      end

      --- Construct the compiler, dialect and mode identity used to name a
      -- qualification case.
      -- @param compiler table: compiler supplied to this operation.
      -- @param dialect any: dialect supplied to this operation.
      -- @param mode any: mode supplied to this operation.
      -- @param flags any: flags supplied to this operation.
      -- @param semantics any|nil: semantics supplied to this operation.
      -- @return nil: no values.
      local function qualification_model_cell(
         compiler,
         dialect,
         mode,
         flags,
         semantics
      )
         local id = compiler.id .. "-c" .. dialect .. "-" .. mode
         local stage = mode == "pgo" and "optimize" or "build"

         for _, replica in ipairs({ "a", "b" }) do
            qualification_model_add(stage, {
               id = id .. "-" .. replica,
               cell = id,
               compiler = compiler.id,
               backend = compiler.backend,
               dialect = dialect,
               mode = mode,
               replica = replica,
               flags = flags,
               semantics = semantics
                  or (mode == "Ofast" and "relaxed-fp" or "strict"),
            })
         end

         plan.comparisons[#plan.comparisons + 1] =
            { first = id .. "-a", second = id .. "-b" }

         -- Diagnostic twins preserve the source dialect and flag profile. PGO
         -- has its own final-artifact runs; these twins do not reuse PGO
         -- profiles.
         if mode ~= "pgo" then
            local diagnostic = {
               id = id .. "-diagnostic-build",
               compiler = compiler.id,
               dialect = dialect,
               mode = mode,
               flags = flags,
            }

            qualification_model_add("diagnostic_build", diagnostic)
            for _, case in ipairs(exports.diagnostics(catalog, diagnostic)) do
               qualification_model_add("diagnostic_run", {
                  id = id .. "-diagnostic-" .. case.id,
                  compiler = compiler.id,
                  backend = compiler.backend,
                  case = case.id,
                  producer = diagnostic.id,
                  dialect = dialect,
                  mode = mode,
               })
            end
         end

         for _, consumer in ipairs(exports.consumers(catalog)) do
            qualification_model_add("run", {
               id = id .. "-" .. consumer.id,
               producer = id .. "-a",
               consumer = consumer.compiler.id,
               case = consumer.case,
               dialect = consumer.dialect,
               executable = consumer.id,
            })
         end
      end

      --- Plan qualified tasks for one reviewed compiler identity.
      -- @param compiler table: compiler supplied to this operation.
      -- @return nil: no values.
      local function qualification_model_planCompiler(compiler)
         for _, dialect in ipairs(compiler.dialects) do
            for _, mode in ipairs(campaign_policy.modes or catalog.modes) do
               qualification_model_cell(compiler, dialect, mode)
            end
         end

         if campaign_policy.flags then
            for _, flags in ipairs(catalog.flag_profiles) do
               qualification_model_cell(
                  compiler,
                  catalog.primary_dialect,
                  flags.id,
                  flags.flags,
                  flags.contract
               )
            end
         end

         qualification_model_add("instrument", {
            id = compiler.id .. "-instrument",
            compiler = compiler.id,
            backend = compiler.backend,
            dialect = catalog.primary_dialect,
            mode = "instrument",
         })

         for _, shard in ipairs(catalog.shards) do
            qualification_model_add("train", {
               id = compiler.id .. "-train-" .. shard.id,
               compiler = compiler.id,
               backend = compiler.backend,
               producer = compiler.id .. "-instrument",
               shard = shard.id,
               operations = shard.operations,
               weight = shard.weight,
            })
         end

         qualification_model_add("merge", {
            id = compiler.id .. "-merge",
            compiler = compiler.id,
            backend = compiler.backend,
         })

         qualification_model_cell(compiler, catalog.primary_dialect, "pgo")
      end

      for _, compiler in ipairs(catalog.compilers) do
         qualification_model_planCompiler(compiler)
      end

      plan.execution = dofile("scripts/qualification/lib/execution.lua").plan(
         plan,
         catalog,
         exports.dependencies
      )

      return plan
   end

   exports.plan = QUALIFICATION_MODEL_plan

   --- List the prerequisite producer tasks for a selected qualification stage.
   -- @param task table: task supplied to this operation.
   -- @param catalog table: reviewed catalog of supported entries.
   -- @return table: list the prerequisite producer tasks for a selected
   -- qualification stage.
   local function QUALIFICATION_MODEL_dependencies(task, catalog)
      if task.producer then
         return { task.producer }
      end

      if task.stage == "optimize" then
         return { task.compiler .. "-merge", task.compiler .. "-instrument" }
      end

      local result = {}

      if task.stage == "merge" then
         for _, shard in ipairs(catalog.shards) do
            result[#result + 1] = task.compiler .. "-train-" .. shard.id
         end
      end

      return result
   end

   exports.dependencies = QUALIFICATION_MODEL_dependencies

   --- Required artifacts follow the selected producers, consumers and shards.
   -- @param task table: task emitted by the planner.
   -- @param catalog table: campaign configuration used to construct the plan.
   -- @return table: relative paths that must appear in the sealed inventory.
   local function QUALIFICATION_MODEL_artifacts(task, catalog)
      local ret = {}
      local fixture = catalog.fixture

      if task.stage == "build" or task.stage == "optimize" then
         --- List library and consumer outputs required for a build task.
         -- @return nil: no values.
         local function qualification_model_buildArtifacts()
            ret = { fixture.shared, "tools.json", "binary.log" }

            for _, consumer in ipairs(exports.consumers(catalog)) do
               ret[#ret + 1] = consumer.id
            end

            if task.mode ~= "pgo" and task.mode ~= "O3-lto" then
               ret[#ret + 1] = fixture.static
            end
         end

         qualification_model_buildArtifacts()
      elseif task.stage == "instrument" then
         --- List the instrumented library and each training shard executable.
         -- @return nil: no values.
         local function qualification_model_instrumentArtifacts()
            ret = { fixture.shared, "tools.json", "probe-verify.log" }

            for _, shard in ipairs(catalog.shards) do
               ret[#ret + 1] = "train-" .. shard.id
            end
         end

         qualification_model_instrumentArtifacts()
      elseif task.stage == "train" then
         ret = { "train.log" }
      elseif task.stage == "merge" then
         --- Require the accepted shard inventory and backend-specific merged
         -- profile.
         -- @return nil: no values.
         local function qualification_model_mergeArtifacts()
            ret = {
               "accepted-attempts.json",
               "profile-counts.log",
               task.backend == "llvm" and "merged.profdata"
                  or "merged/" .. fixture.gcov_data,
            }
         end

         qualification_model_mergeArtifacts()
      elseif task.stage == "run" then
         ret = { "trace.log" }
      elseif task.stage == "diagnostic_build" then
         --- Require every declared diagnostic executable in build evidence.
         -- @return nil: no values.
         local function qualification_model_diagnosticArtifacts()
            ret = { "tools.json" }

            for _, diagnostic in ipairs(exports.diagnostics(catalog, task)) do
               ret[#ret + 1] = diagnostic.id
            end
         end

         qualification_model_diagnosticArtifacts()
      elseif task.stage == "diagnostic_run" then
         ret = { "diagnostic.log" }
      else
         error("unknown artifact contract")
      end

      ::function_output::

      return ret
   end

   exports.artifacts = QUALIFICATION_MODEL_artifacts

   --- Resolve a planned task by identifier and reject undeclared work.
   -- @param plan table: validated execution plan.
   -- @param id string: stable identity used to match the requested entry.
   -- @return any: a planned task by identifier and reject undeclared work.
   local function QUALIFICATION_MODEL_task(plan, id)
      for _, task in ipairs(plan.tasks) do
         if task.id == id then
            return task
         end
      end

      error("task is not in the plan: " .. tostring(id))
   end

   exports.task = QUALIFICATION_MODEL_task

   --- Check result identity, status and required artifact counts for one
   -- planned
   -- task.
   -- @param task table: task supplied to this operation.
   -- @param result table: result supplied to this operation.
   -- @param identity table: declared source, tool or artifact identity.
   -- @return nil: no values.
   local function QUALIFICATION_MODEL_accept(task, result, identity)
      assert(
         result.id == task.id and result.stage == task.stage,
         "task identity mismatch"
      )
      assert(
         result.plan_sha256 == identity.plan_sha256
            and result.source_sha256 == identity.source_sha256,
         "stale or foreign evidence"
      )
      assert(result.campaign_id == identity.campaign_id, "foreign campaign")
      assert(
         tostring(result.attempt_id) == tostring(identity.attempt_id),
         "unaccepted attempt"
      )
      assert(states[result.status], "unknown result state")
      assert(result.status == "PASS", "required task is " .. result.status)
      assert(result.files > 0, "empty evidence")
   end

   exports.accept = QUALIFICATION_MODEL_accept

   --- Reject missing, duplicate, foreign or unsuccessful qualification records.
   -- @param plan table: validated execution plan.
   -- @param records table: ordered records to inspect.
   -- @param identity table: declared source, tool or artifact identity.
   -- @return boolean, table: reject missing, duplicate, foreign or unsuccessful
   -- qualification records.
   local function QUALIFICATION_MODEL_gate(plan, records, identity)
      local expected, seen, failures = {}, {}, {}

      for _, task in ipairs(plan.tasks) do
         expected[task.id] = task
      end

      for _, record in ipairs(records) do
         local ok, message = pcall(
            --- Accept one expected task record and reject duplicates under
            -- error
            -- capture.
            -- @return nil: no values.
            function()
               local task = assert(expected[record.id], "unexpected result")

               assert(not seen[record.id], "duplicate result")

               seen[record.id] = true
               exports.accept(task, record, identity)
            end
         )

         if not ok then
            failures[#failures + 1] = tostring(message)
         end
      end

      for _, task in ipairs(plan.tasks) do
         if not seen[task.id] then
            failures[#failures + 1] = task.id .. ": missing"
         end
      end

      return #failures == 0, failures
   end

   exports.gate = QUALIFICATION_MODEL_gate

   return exports
end

return scripts_qualification_lib_model_loadModule()

-- EOF


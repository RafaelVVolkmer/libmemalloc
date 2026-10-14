-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Deterministic, weighted assignment without removing or duplicating cases.
-- Part of planned qualification tasks and producer/consumer evidence.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_qualification_lib_execution_loadModule()
   local EXECUTION_MAX_PARTITIONS = 256

   local exports = {}

   --- Group logical tasks into bounded worker batches while preserving stage
   -- dependencies.
   -- @param logical table: logical supplied to this operation.
   -- @param catalog table: reviewed catalog of supported entries.
   -- @param dependencies any: dependencies supplied to this operation.
   -- @return table: group logical tasks into bounded worker batches while
   -- preserving stage dependencies.
   local function QUALIFICATION_EXECUTION_plan(logical, catalog, dependencies)
      local policy = catalog.execution

      assert(policy.schema == 1, "unknown execution policy")
      assert(
         policy.processes_per_job == 1,
         "qualify concurrency before enabling it"
      )

      local execution = { batches = {}, stages = {}, assignment = {} }
      local tasks, indices = {}, {}

      for index, task in ipairs(logical.tasks) do
         tasks[task.id], indices[task.id] = task, index
      end

      --- Group one qualification stage into bounded execution batches.
      -- @param stage any: stage supplied to this operation.
      -- @return nil: no values.
      local function qualification_execution_planStage(stage)
         assert(
            policy.partitions[stage] >= 1
               and policy.partitions[stage] <= EXECUTION_MAX_PARTITIONS
               and policy.partitions[stage] % 1 == 0,
            "invalid stage partition budget"
         )
         assert(policy.weights[stage] > 0, "invalid scheduling weight")

         local pools, keys = {}, {}

         execution.stages[stage] = {}

         --- Index a logical task by its producer and execution dimensions.
         -- @param task table: task supplied to this operation.
         -- @return nil: no values.
         local function qualification_execution_indexTask(task)
            local producer = task.producer and tasks[task.producer] or task
            local compiler = task.compiler or producer.compiler
            local replica = task.replica or "shared"
            local key = compiler .. "-" .. replica

            if not pools[key] then
               pools[key] =
                  { units = {}, compiler = compiler, replica = replica }
               keys[#keys + 1] = key
            end

            -- Consumers of one producer stay together, including diagnostics.
            local unit_id = task.producer or task.id
            local pool = pools[key]

            pool.units[unit_id] = pool.units[unit_id]
               or {
                  id = unit_id,
                  tasks = {},
                  weight = 0,
               }

            local unit = pool.units[unit_id]

            unit.tasks[#unit.tasks + 1] = task.id
            unit.weight = unit.weight
               + policy.weights[stage]
                  * (policy.mode_weights[task.mode] or 1)
         end

         for _, task in ipairs(logical[stage]) do
            qualification_execution_indexTask(task)
         end

         table.sort(keys)

         --- Group compatible tasks into one isolated execution unit.
         -- @param key string: record field or catalog key to select.
         -- @return nil: no values.
         local function qualification_execution_groupTasks(key)
            local pool, units = pools[key], {}

            for _, unit in pairs(pool.units) do
               units[#units + 1] = unit
            end

            table.sort(
               units,
               --- Order heavier tasks first, breaking equal weights by stable
               -- identifier.
               -- @param a table: a supplied to this operation.
               -- @param b table: b supplied to this operation.
               -- @return boolean: order heavier tasks first, breaking equal
               -- weights by stable identifier.
               function(a, b)
                  if a.weight == b.weight then
                     return a.id < b.id
                  end

                  return a.weight > b.weight
               end
            )

            local shards = {}

            for index = 1, math.min(policy.partitions[stage], #units) do
               shards[index] = {
                  id = stage:gsub("_", "-") .. "-" .. key .. "-" .. index,
                  stage = stage,
                  compiler = pool.compiler,
                  replica = pool.replica,
                  tasks = {},
                  dependencies = {},
                  weight = 0,
               }
            end

            --- Assign a bounded execution unit to its stage batch.
            -- @param unit table: unit supplied to this operation.
            -- @return nil: no values.
            local function qualification_execution_assignBatch(unit)
               local selected = shards[1]

               for _, shard in ipairs(shards) do
                  if shard.weight < selected.weight then
                     selected = shard
                  end
               end

               selected.weight = selected.weight + unit.weight
               for _, id in ipairs(unit.tasks) do
                  assert(
                     not execution.assignment[id],
                     "duplicate task assignment"
                  )

                  selected.tasks[#selected.tasks + 1] = id
                  execution.assignment[id] = selected.id
               end
            end

            for _, unit in ipairs(units) do
               qualification_execution_assignBatch(unit)
            end

            for _, shard in ipairs(shards) do
               table.sort(
                  shard.tasks,
                  --- Restore dependency order from the declared stage indices.
                  -- @param a any: first comparison entry.
                  -- @param b any: second comparison entry.
                  -- @return boolean: restore dependency order from the declared
                  -- stage indices.
                  function(a, b)
                     return indices[a] < indices[b]
                  end
               )

               execution.batches[#execution.batches + 1] = shard
               execution.stages[stage][#execution.stages[stage] + 1] = shard
            end
         end

         for _, key in ipairs(keys) do
            qualification_execution_groupTasks(key)
         end

         assert(
            #execution.stages[stage] <= EXECUTION_MAX_PARTITIONS,
            "Actions job matrix limit exceeded"
         )
      end

      for _, stage in ipairs(catalog.stages) do
         qualification_execution_planStage(stage)
      end

      --- Bind one batch to its required predecessor batches.
      -- @param batch table: batch supplied to this operation.
      -- @return nil: no values.
      local function qualification_execution_bindDependencies(batch)
         local seen = {}

         for _, id in ipairs(batch.tasks) do
            for _, dependency in ipairs(dependencies(tasks[id], catalog)) do
               local owner = assert(
                  execution.assignment[dependency],
                  "unassigned dependency"
               )

               assert(
                  owner ~= batch.id,
                  "intra-batch dependency needs a qualified scheduler"
               )
               if not seen[owner] then
                  seen[owner] = true
                  batch.dependencies[#batch.dependencies + 1] = owner
               end
            end
         end

         table.sort(batch.dependencies)
      end

      for _, batch in ipairs(execution.batches) do
         qualification_execution_bindDependencies(batch)
      end

      for _, pair in ipairs(logical.comparisons) do
         assert(
            execution.assignment[pair.first]
               ~= execution.assignment[pair.second],
            "independent reconstructions share a job"
         )
      end

      return execution
   end

   exports.plan = QUALIFICATION_EXECUTION_plan

   --- Resolve one declared worker batch and reject unknown identifiers.
   -- @param plan table: validated execution plan.
   -- @param id string: stable identity used to match the requested entry.
   -- @return any: one declared worker batch and reject unknown identifiers.
   local function QUALIFICATION_EXECUTION_batch(plan, id)
      for _, batch in ipairs(plan.execution.batches) do
         if batch.id == id then
            return batch
         end
      end

      error("batch is not in the execution plan: " .. tostring(id))
   end

   exports.batch = QUALIFICATION_EXECUTION_batch

   --- Verify a worker record against the expected batch and campaign identity.
   -- @param batch table: batch supplied to this operation.
   -- @param record table: structured record supplied by the caller.
   -- @param identity table: declared source, tool or artifact identity.
   -- @return nil: no values.
   local function QUALIFICATION_EXECUTION_accept(batch, record, identity)
      assert(
         record.id == batch.id and record.stage == batch.stage,
         "batch identity mismatch"
      )
      for _, field in ipairs({
         "plan_sha256",
         "source_sha256",
         "campaign_id",
         "attempt_id",
      }) do
         assert(record[field] == identity[field], "foreign batch evidence")
      end

      assert(record.status == "PASS", "batch did not pass")
      assert(#record.tasks == #batch.tasks, "batch task inventory differs")
      for index, id in ipairs(batch.tasks) do
         local task = record.tasks[index]

         assert(
            task.id == id and task.status == "PASS",
            "incomplete batch task"
         )
      end
   end

   exports.accept = QUALIFICATION_EXECUTION_accept

   --- Read the execution manifest independently of the case manifests.
   -- @param build_io table: build filesystem and process operations.
   -- @param root string: root directory for this operation.
   -- @param batch table: batch supplied to this operation.
   -- @param identity table: declared source, tool or artifact identity.
   -- @return table: the execution manifest independently of the case manifests.
   local function QUALIFICATION_EXECUTION_verify(
      build_io,
      root,
      batch,
      identity
   )
      local path = root .. "/batches/" .. batch.id .. ".json"
      local record = { tasks = {} }

      for _, field in ipairs({
         "id",
         "stage",
         "status",
         "plan_sha256",
         "source_sha256",
         "campaign_id",
         "attempt_id",
      }) do
         record[field] = build_io.query(path, "." .. field)
      end

      for line in
         build_io
            .query(path, ".tasks[] | [.id, .status] | @tsv")
            :gmatch("[^\n]+")
      do
         local id, status = line:match("^([^\t]+)\t([^\t]+)$")

         record.tasks[#record.tasks + 1] = { id = id, status = status }
      end

      exports.accept(batch, record, identity)

      local logs = {}

      for line in
         build_io
            .query(path, ".logs[] | [.path, .sha256] | @tsv")
            :gmatch("[^\n]+")
      do
         local file, digest = line:match("^([^\t]+)\t(%x+)$")

         build_io.release.safe_path(assert(file, "malformed batch log entry"))
         assert(not logs[file], "duplicate batch log")

         logs[file] = true
         assert(
            build_io.digest(root .. "/" .. file) == digest,
            "batch log changed"
         )
      end

      local count = tonumber(build_io.query(path, ".logs | length"))

      assert(count == #batch.tasks, "batch log inventory differs")
      for _, id in ipairs(batch.tasks) do
         assert(
            logs["logs/" .. batch.id .. "/" .. id .. ".log"],
            "missing case log"
         )
      end

      return record
   end

   exports.verify = QUALIFICATION_EXECUTION_verify

   return exports
end

return scripts_qualification_lib_execution_loadModule()

-- EOF


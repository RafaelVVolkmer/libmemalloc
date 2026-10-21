-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Check weighted reduction and rejection through the real merge entrypoint.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_qualification_profiles_test_suite_main()
   local Q = dofile("scripts/qualification/lib/model.lua")
   local policy = dofile("tools/build/qualification.lua")
   local commands = {}
   local rejected = false
   local sealed = false
   local report = {}
   local R = {}
   local B = { root = "/fixture", release = R }
   local I = { B = B, R = R, Q = Q, catalog = policy }
   local environment = {
      assert = assert,
      ipairs = ipairs,
      pairs = pairs,
      tostring = tostring,
      string = string,
      table = table,
      debug = debug,
      xpcall = xpcall,
      tonumber = tonumber,
      error = error,
      loadfile = loadfile,
      arg = {},
      os = {
         --- Exclude host environment overrides from the merge fixture.
         -- @return nil: exclude host environment overrides from the merge
         -- fixture.
         getenv = function()
            return nil
         end,
      },
   }

   policy.compilers = { policy.compilers[1] }
   policy.shards = {
      { id = "small", operations = 10, weight = 2 },
      { id = "medium", operations = 20, weight = 3 },
      { id = "large", operations = 30, weight = 5 },
   }

   --- Select the synthetic profile merge task.
   -- @return table: the synthetic profile merge task.
   R.options = function()
      return { task = "gcc-merge" }
   end

   --- Accept fixture paths without consulting the host filesystem.
   -- @return nil: no values.
   R.safe_path = function()
      -- This port has no host effects in the recording fixture.
   end

   --- Keep injected report sequences distinct from absent values.
   -- @param value any: input value; validation belongs to this operation’s
   -- contract.
   -- @return any: keep injected report sequences distinct from absent values.
   R.array = function(value)
      return value or {}
   end

   --- Expose the expected coverage data artifact.
   -- @return table: expose the expected coverage data artifact.
   R.files = function()
      return { policy.fixture.gcov_data }
   end

   --- Keep intermediate JSON in the recording fixture.
   -- @return nil: no values.
   B.json = function()
      -- This port has no host effects in the recording fixture.
   end

   --- Supply stable identities without hashing host files.
   -- @return string: supply stable identities without hashing host files.
   B.digest = function()
      return "fixture-digest"
   end

   --- Report the configured host executor.
   -- @return any: report the configured host executor.
   B.output = function()
      return policy.host.executor
   end

   --- Recover original shard weights from dependency metadata.
   -- @param path string: filesystem path selected by the caller.
   -- @param field any: field supplied to this operation.
   -- @return any: recover original shard weights from dependency metadata.
   B.query = function(path, field)
      local ret

      for _, shard in ipairs(policy.shards) do
         if path:find("-train-" .. shard.id .. "/", 1, true) then
            ret = field == ".operations" and shard.operations or shard.weight
         end
      end

      ::function_output::

      return ret
   end

   --- Build a real plan using the reduced compiler and shard policy.
   -- @return any, table, any: a real plan using the reduced compiler and shard
   -- policy.
   I.open = function()
      return Q.plan(policy, "pr"), {}, policy
   end

   --- Retain the initial report for assertions after execution.
   -- @return table, string: retain the initial report for assertions after
   -- execution.
   I.result = function()
      report = { status = "INFRA_ERROR" }

      return report, ".cache/test-merge"
   end

   --- Resolve each dependency under the synthetic input root.
   -- @param _ any: callback argument intentionally unused.
   -- @param _ any: callback argument intentionally unused.
   -- @param task table: task supplied to this operation.
   -- @return string: each dependency under the synthetic input root.
   I.dependency = function(_, _, task)
      return ".cache/inputs/" .. task.id
   end

   --- Capture reductions and inject malformed profile output when requested.
   -- @param _ any: callback argument intentionally unused.
   -- @param _ any: callback argument intentionally unused.
   -- @param _ any: callback argument intentionally unused.
   -- @param command table: executable and literal command arguments.
   -- @return boolean|nil|string: reductions and inject malformed profile output
   -- when requested.
   I.execute = function(_, _, _, command)
      local ret = "COUNTERS"

      if command[1] == policy.host.tools.gcov_merge then
         commands[#commands + 1] = command
         ret = rejected and "invalid profile data" or ""
      end

      ::function_output::

      return ret
   end

   --- Record that the completed report was sealed.
   -- @return nil: no values.
   I.seal = function()
      sealed = true
   end

   --- Keep subject progress output out of the test result stream.
   -- @return nil: no values.
   environment.print = function()
      -- This port has no host effects in the recording fixture.
   end

   --- Inject only the qualification I/O dependency.
   -- @param path string: filesystem path selected by the caller.
   -- @return any: inject only the qualification I/O dependency.
   environment.dofile = function(path)
      if path == "scripts/workspace/lib/lock.lua" then
         --- Avoid acquiring a repository lock for the injected profile fixture.
         -- @return nil: no values.
         return { guard = function() end }
      end

      assert(
         path == "scripts/qualification/lib/io.lua",
         "unexpected entrypoint dependency"
      )

      return I
   end

   assert(
      loadfile("scripts/qualification/run.lua", "t", environment),
      "executor must compile"
   )()
   assert(#commands == 2, "three shards require two pairwise reductions")
   assert(commands[1][6] == "2,3", "first reduction lost the original weights")
   assert(
      commands[2][6] == "1,5",
      "previously weighted counters were weighted again"
   )
   assert(
      commands[2][3] == commands[1][8],
      "reduction discarded accumulated counters"
   )
   assert(report.status == "PASS" and sealed, "successful merge was not sealed")

   rejected = true
   sealed = false

   local ok = pcall(
      assert(
         loadfile("scripts/qualification/run.lua", "t", environment),
         "executor must compile"
      )
   )

   assert(
      not ok and report.status == "FAIL" and sealed,
      "invalid profile was accepted or failure evidence lost"
   )

   print(
      (
         "PGO reduction: configurable shards retain weights;"
         .. " rejected inputs retain failure evidence."
      )
   )
end

return tests_qualification_profiles_test_suite_main()

-- EOF


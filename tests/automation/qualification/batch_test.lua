-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Exercise continuation and failure propagation through the real batch driver.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_qualification_batch_test_suite_main()
   local catalog = dofile("tools/build/qualification.lua")
   local Q = dofile("scripts/qualification/lib/model.lua")
   local batch = {
      id = "test-batch",
      stage = "build",
      dependencies = {},
      tasks = { "first", "second" },
   }
   local plan = {
      tasks = {
         { id = "first", stage = "build" },
         { id = "second", stage = "build" },
      },
      execution = { batches = { batch } },
   }
   local calls, sealed, removed = 0, 0, false
   local saved
   local R = {
      --- Select the synthetic batch without parsing host arguments.
      -- @return table: the synthetic batch without parsing host arguments.
      options = function()
         return { batch = batch.id, output = ".cache/test-batch" }
      end,
      --- Accept fixture paths without touching the host filesystem.
      -- @return nil: no values.
      safe_path = function()
         -- This port has no host effects in the recording fixture.
      end,
      --- Preserve sequence values in the injected artifact port.
      -- @param value any: input value; validation belongs to this
      -- operation’s contract.
      -- @return any: preserve sequence values in the injected artifact port.
      array = function(value)
         return value or {}
      end,
      --- Model a fresh output directory for the initial run.
      -- @return boolean: model a fresh output directory for the initial run.
      exists = function()
         return false
      end,
      platform = {
         --- Provide a deterministic owned workspace for child isolation.
         -- @return string: provide a deterministic owned workspace for child
         -- isolation.
         temporary_directory = function()
            return "/fixture/.cache/tests/owned"
         end,
         --- Record that the driver released its temporary workspace.
         -- @return nil: no values.
         remove_temporary_directory = function()
            removed = true
         end,
      },
   }
   local B = {
      root = "/fixture",
      release = R,
      --- Avoid creating real directories in the recording fixture.
      -- @return nil: no values.
      mkdir = function()
         -- This port has no host effects in the recording fixture.
      end,
      --- Avoid writing reports outside the in-memory fixture.
      -- @return nil: no values.
      write = function()
         -- This port has no host effects in the recording fixture.
      end,
      --- Supply a stable artifact identity for the recorded batch.
      -- @return string: supply a stable artifact identity for the recorded
      -- batch.
      digest = function()
         return "digest"
      end,
      --- Resolve a tool name without searching the host PATH.
      -- @param name string: entry or operation name to resolve.
      -- @return table: a tool name without searching the host PATH.
      tool = function(name)
         return { path = name }
      end,
      --- Retain the report for assertions after the driver exits.
      -- @param _ any: callback argument intentionally unused.
      -- @param report any: report supplied to this operation.
      -- @return nil: no values.
      json = function(_, report)
         saved = report
      end,
      --- Check child isolation and fail the first independent task.
      -- @param _ any: callback argument intentionally unused.
      -- @param _ any: callback argument intentionally unused.
      -- @param id string: stable identity used to match the requested entry.
      -- @param command table: executable and literal command arguments.
      -- @return boolean, string: check child isolation and fail the first
      -- independent task.
      run = function(_, _, id, command)
         calls = calls + 1

         local joined = table.concat(command, " ")

         assert(
            joined:find("setsid --wait", 1, true),
            "missing process session"
         )
         assert(
            joined:find("env -i", 1, true),
            "inherited environment accepted"
         )
         assert(
            joined:find("HOME=/fixture/.cache/tests/owned/" .. id, 1, true),
            "cases share a home directory"
         )

         return calls > 1, ".cache/" .. id .. ".log"
      end,
   }
   local I = {
      B = B,
      R = R,
      Q = Q,
      --- Return the synthetic plan with its source timestamp.
      -- @return any, table, any: the synthetic plan with its source timestamp.
      open = function()
         return plan, { source_date_epoch = "1" }, catalog
      end,
      --- Accept fixture dependencies without opening real artifacts.
      -- @return nil: no values.
      verify = function()
         -- This port has no host effects in the recording fixture.
      end,
      --- Create the initial infrastructure-failure result for the driver.
      -- @return table, string: the initial infrastructure-failure result for
      -- the driver.
      result = function()
         return { status = "INFRA_ERROR" }, ".cache/missing"
      end,
      --- Record evidence sealing after task execution.
      -- @return nil: no values.
      seal = function()
         sealed = sealed + 1
      end,
   }
   local environment = {
      assert = assert,
      ipairs = ipairs,
      pairs = pairs,
      tostring = tostring,
      xpcall = xpcall,
      error = error,
      debug = debug,
      io = io,
      arg = {},
      os = {
         --- Expose only the controlled executable search path.
         -- @param name string: entry or operation name to resolve.
         -- @return boolean|nil|string: expose only the controlled executable
         -- search path.
         getenv = function(name)
            return name == "PATH" and "/tools" or nil
         end,
      },
      --- Keep subject progress output out of the test result stream.
      -- @return nil: no values.
      print = function()
         -- This port has no host effects in the recording fixture.
      end,
      --- Inject batch ports while retaining real policy modules.
      -- @param path string: filesystem path selected by the caller.
      -- @return any: inject batch ports while retaining real policy modules.
      dofile = function(path)
         if path == "scripts/workspace/lib/lock.lua" then
            --- Avoid acquiring a repository lock for this simulated batch.
            -- @return nil: no values.
            return { guard = function() end }
         end

         if path == "scripts/qualification/lib/io.lua" then
            return I
         end

         return dofile(path)
      end,
   }
   local executed = pcall(
      assert(loadfile("scripts/qualification/batch.lua", "t", environment))
   )

   assert(not executed, "failed batch exited successfully")
   assert(
      calls == 2 and saved.tasks[2].status == "PASS",
      "failure stopped independent cases"
   )
   assert(
      saved.tasks[1].status == "FAIL" and saved.status == "FAIL",
      "case failure disappeared"
   )
   assert(
      sealed == 1 and removed,
      "failure evidence or workspace cleanup missing"
   )

   -- A successful process exit cannot hide a child left in its process session.
   calls, sealed, removed = 0, 0, false

   local killed = false
   local run = B.run

   --- Model successful process exit despite an orphaned child.
   -- @param ... any: remaining arguments forwarded with their original
   -- ordering.
   -- @return boolean, any: model successful process exit despite an orphaned
   -- child.
   B.run = function(...)
      local _, log = run(...)

      return true, log
   end

   --- Expose the retained process-session identity to cleanup.
   -- @param path string: filesystem path selected by the caller.
   -- @return boolean: expose the retained process-session identity to cleanup.
   R.exists = function(path)
      return path:match("session%.pid$") ~= nil
   end

   --- Supply the simulated child process identifier.
   -- @return string: supply the simulated child process identifier.
   B.read = function()
      return "1122\n"
   end

   --- Report an orphan until the driver terminates its session.
   -- @return boolean|nil|string: report an orphan until the driver terminates
   -- its session.
   R.platform.command_output = function()
      return calls == 1 and not killed and "123456\n" or nil
   end

   --- Require cleanup to target the recorded orphan session.
   -- @param command table: executable and literal command arguments.
   -- @return boolean: require cleanup to target the recorded orphan session.
   R.platform.command_succeeded = function(command)
      if command[1] == "sleep" then
         return true
      end

      assert(
         command[1] == "kill" and command[3] == "123456",
         "wrong child cleanup"
      )

      killed = true

      return true
   end
   executed = pcall(
      assert(loadfile("scripts/qualification/batch.lua", "t", environment))
   )
   assert(not executed and killed, "orphan process was accepted or left alive")
   assert(
      calls == 2 and saved.tasks[2].status == "PASS",
      "orphan stopped later cases"
   )
   assert(removed, "orphan failure lost workspace cleanup")

   print(
      (
         "Batch execution retains failures and continues independent cases; "
         .. "environments remain isolated."
      )
   )
end

return tests_qualification_batch_test_suite_main()

-- EOF


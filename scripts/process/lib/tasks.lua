-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Supervise registered tasks with bounded execution and retained diagnostics.
-- Shared by native Ansible dispatch and automation integration tests.

--- Construct a runner that writes one JSON/JUnit result per invocation.
-- @return table: public operations constructed by this module.
local function TASKS_loadModule()
   local TASKS_DIAGNOSTIC_TAIL_BYTES = 4096

   local artifacts = dofile("scripts/lib/artifacts.lua")
   local executor = dofile("scripts/process/lib/exec.lua")
   local uv = require("luv")
   local exports = {}
   local TASKS_MILLISECONDS_PER_SECOND = 1000
   local TASKS_NANOSECONDS_PER_SECOND = 1000000000
   local display_output = { doctor = true, status = true, clean = true }
   -- POSIX 0700: logs may contain task arguments.
   local TASKS_PRIVATE_MODE = 448

   --- Keep failure previews bounded without breaking UTF-8 JSON encoding.
   -- @param value any: value supplied to this operation.
   -- @return any: keep failure previews bounded without breaking UTF-8 JSON
   -- encoding.
   local function diagnostic_tail(value)
      local tail =
         value:sub(-TASKS_DIAGNOSTIC_TAIL_BYTES):gsub("^[\128-\191]+", "")

      return utf8.len(tail) and tail
         or "[non-UTF-8 output; inspect retained log]"
   end

   --- Escape arbitrary diagnostic text for an XML attribute or text node.
   -- @param value any: input value; validation belongs to this operation’s
   -- contract.
   -- @return any: escape arbitrary diagnostic text for an XML attribute or text
   -- node.
   local function xml(value)
      return tostring(value)
         :gsub("[\0-\8\11\12\14-\31]", "?")
         :gsub("&", "&amp;")
         :gsub("<", "&lt;")
         :gsub(">", "&gt;")
         :gsub('"', "&quot;")
         :gsub("'", "&apos;")
   end

   --- Run a literal argv task, preserving failures and infrastructure states.
   -- @param name string: entry or operation name to resolve.
   -- @param task table: task supplied to this operation.
   -- @param arguments table: ordered arguments for the selected operation.
   -- @param interpreter string: Lua or host interpreter selected by the runtime
   -- owner.
   -- @param options table|nil: operation settings; omitted fields use the
   -- documented defaults.
   -- @return boolean, string: run a literal argv task, preserving failures and
   -- infrastructure states.
   local function TASKS_run(name, task, arguments, interpreter, options)
      options = options or {}
      assert(name:match("^[a-z][a-z-]+$"), "invalid task name")

      local directory = (
         name == "clean" and ".cache/cleanup/" or ".cache/logs/tasks/"
      )
         .. name
         .. "-"
         .. tostring(uv.hrtime())
         .. "-"
         .. tostring(uv.os_getpid())

      artifacts.mkdir(directory)
      assert(uv.fs_chmod(directory, TASKS_PRIVATE_MODE))

      local command = { interpreter }

      for _, value in ipairs(task.command) do
         command[#command + 1] = value
      end

      for _, value in ipairs(arguments) do
         command[#command + 1] = value
      end

      local started = uv.hrtime()

      --- Forward the environment with private paths for this task's result.
      -- @return table: forward the environment with private paths for this
      -- task's result.
      local function child_environment()
         local environment = uv.os_environ()
         local task_directory = assert(uv.cwd()) .. "/" .. directory

         environment.LIBMEMALLOC_TASK_DIRECTORY = task_directory
         environment.LIBMEMALLOC_CHANGE_FILE = task_directory .. "/changed"
         local entries = {}

         for key, value in pairs(environment) do
            entries[#entries + 1] = key .. "=" .. value
         end

         table.sort(entries)

         return entries
      end

      local result = executor.run(command, {
         timeout_ms = task.timeout_seconds * TASKS_MILLISECONDS_PER_SECOND,
         env = child_environment(),
      })
      local duration = (uv.hrtime() - started) / TASKS_NANOSECONDS_PER_SECOND

      artifacts.write(directory .. "/stdout.log", result.stdout)
      artifacts.write(directory .. "/stderr.log", result.stderr)

      --- Preserve unknown outcomes separately from confirmed no-op results.
      -- @return boolean|nil|string: preserve unknown outcomes separately from
      -- confirmed no-op results.
      local function read_change_status()
         local change_status = task.effects == "read" and "unchanged"
            or "unknown"
         local change_file = io.open(directory .. "/changed", "rb")
         if change_file then
            local value = change_file:read("*a")

            assert(change_file:close())
            assert(
               value == "true\n" or value == "false\n",
               "invalid change result"
            )
            change_status = value == "true\n" and "changed" or "unchanged"
         end

         if
            result.state ~= "PASS"
            and task.effects ~= "read"
            and change_status == "unchanged"
         then
            change_status = "unknown"
         end

         return change_status
      end

      local report = {
         schema_version = 1,
         task = name,
         state = result.state,
         exit_code = result.exit_code,
         signal = result.signal,
         timeout_seconds = task.timeout_seconds,
         duration_seconds = string.format("%.3f", duration),
         command = artifacts.array(command),
         effects = task.effects,
         change_status = read_change_status(),
         directory = directory,
      }
      if display_output[name] then
         report.output = result.stdout
      end

      if result.state ~= "PASS" then
         report.stdout_tail = diagnostic_tail(result.stdout)
         report.stderr_tail = diagnostic_tail(result.stderr)
      end

      artifacts.write(
         directory .. "/result.json",
         artifacts.text_json(report) .. "\n"
      )

      local passed = result.state == "PASS"

      --- Retain the task outcome in a JUnit envelope.
      -- @return nil: no values.
      local function write_junit()
         local failure = passed and ""
            or '<failure message="'
               .. xml(result.state)
               .. '">See stderr.log and stdout.log.</failure>'

         artifacts.write(
            directory .. "/junit.xml",
            '<?xml version="1.0" encoding="UTF-8"?>\n'
               .. '<testsuite name="automation" tests="1" failures="'
               .. (passed and "0" or "1")
               .. '"><testcase name="'
               .. xml(name)
               .. '" time="'
               .. string.format("%.3f", duration)
               .. '">'
               .. failure
               .. "</testcase></testsuite>\n"
         )
      end

      write_junit()

      --- Keep machine output parseable and human output useful.
      -- @return nil: no values.
      local function publish()
         if options.json then
            print(artifacts.text_json(report))
         else
            print("Task " .. name .. ": " .. result.state .. "; " .. directory)
            if display_output[name] then
               io.write(result.stdout)
            end
         end
      end

      publish()

      return passed, directory
   end

   exports.run = TASKS_run

   return exports
end

return TASKS_loadModule()

-- EOF


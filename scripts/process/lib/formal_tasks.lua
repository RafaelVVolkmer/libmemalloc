-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Supervise registered tasks with bounded execution and retained diagnostics.
-- Shared by native Ansible dispatch and automation integration tests.

--- Construct a runner that writes one JSON/JUnit result per invocation.
-- @return table: public operations constructed by this module.
local function TASKS_loadModule()
   local uv = require("luv")
   local TASKS_DIAGNOSTIC_TAIL_BYTES = 4096

   local artifacts = dofile("scripts/lib/artifacts.lua")
   local files = dofile("scripts/verification/lib/files.lua")
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

   --- Create a private task directory without invoking shell builtins.
   -- @param directory string: repository-local task directory.
   -- @return nil: no values.
   local function mkdir(directory)
      local parent = ""
      for part in directory:gmatch("[^/]+") do
         parent = parent == "" and part or parent .. "/" .. part
         if not uv.fs_stat(parent) then
            assert(uv.fs_mkdir(parent, TASKS_PRIVATE_MODE))
         end
      end
   end

   --- Run a literal argv task, preserving failures and infrastructure states.
   -- @param name string: entry or operation name to resolve.
   -- @param task table: task supplied to this operation.
   -- @param arguments table: ordered arguments for the selected operation.
   -- @param interpreter string: Lua or host interpreter selected by the runtime
   -- owner.
   -- @param options table|nil: operation settings; omitted fields use the
   -- documented defaults.
   -- @return boolean, string, table: run a literal argv task, preserving
   -- failures and
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

      mkdir(directory)
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

         environment.LUA_CPATH = package.cpath
         environment.LIBMEMALLOC_TASK_DIRECTORY = task_directory
         environment.LIBMEMALLOC_CHANGE_FILE = task_directory .. "/changed"
         local entries = {}

         for key, value in pairs(environment) do
            entries[#entries + 1] = key .. "=" .. value
         end

         table.sort(entries)

         return entries
      end

      local selected = dofile("scripts/process/native/resources.lua")
      --- Persist formal controller state before execution, including abrupt
      -- death.
      -- @param report table: current controller receipt.
      -- @return nil: no values.
      local function save_report(report)
         local contents = artifacts.text_json(report) .. "\n"
         files.atomic_write(directory .. "/result.json", contents)
      end
      save_report({
         schema_version = 1,
         task = name,
         state = "INCOMPLETE",
         resource_profile = task.resource_profile,
         directory = directory,
         command = artifacts.array(command),
         timeout_seconds = task.timeout_seconds,
      })
      local logs, written = {}, { stdout = 0, stderr = 0 }
      for _, stream in ipairs({ "stdout", "stderr" }) do
         logs[stream] = assert(
            uv.fs_open(
               directory .. "/" .. stream .. ".log",
               "wx",
               TASKS_PRIVATE_MODE
            )
         )
      end
      --- Persist each bounded chunk before publishing live direct output.
      -- @param stream string: stdout or stderr.
      -- @param chunk string: bytes accepted by the executor's shared output
      -- cap.
      -- @return nil: no values.
      local function retain_output(stream, chunk)
         local offset = 0
         while offset < #chunk do
            local count =
               assert(uv.fs_write(logs[stream], chunk:sub(offset + 1), -1))
            assert(count > 0, "incomplete log write")
            offset = offset + count
         end
         written[stream] = written[stream] + #chunk
         if options.direct then
            assert(io[stream]:write(chunk))
            assert(io[stream]:flush())
         end
      end
      local result = selected.run(command, {
         timeout_ms = task.timeout_seconds * TASKS_MILLISECONDS_PER_SECOND,
         env = child_environment(),
         on_output = retain_output,
         resource_profile = task.resource_profile,
      })
      local duration = (uv.hrtime() - started) / TASKS_NANOSECONDS_PER_SECOND

      for _, stream in ipairs({ "stdout", "stderr" }) do
         if #result[stream] > written[stream] then
            retain_output(stream, result[stream]:sub(written[stream] + 1))
         end
         assert(uv.fs_close(logs[stream]))
      end

      --- Preserve unknown outcomes separately from confirmed no-op results.
      -- @return boolean|nil|string: preserve unknown outcomes separately from
      -- confirmed no-op results.
      local function read_change_status()
         local change_status = task.effects == "read" and "unchanged"
            or "unknown"
         local path = directory .. "/changed"
         local stat, failure, code = uv.fs_lstat(path)
         if not stat then
            assert(code == "ENOENT", failure)
         else
            local value = files.read(path, 6)
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

      local valid_change, change_status = pcall(read_change_status)
      if not valid_change then
         result.state = "INFRA_ERROR"
         result.change_error = tostring(change_status)
         change_status = "unknown"
      end
      --- Build the final receipt after validating the mutation marker.
      -- @return table: complete task outcome and resource evidence.
      local function final_report()
         if result.resources then
            result.resources.state = result.state
         end
         local report = {
            schema_version = 1,
            task = name,
            state = result.state,
            resource_profile = task.resource_profile,
            resources = result.resources,
            exit_code = result.exit_code,
            signal = result.signal,
            timeout_seconds = task.timeout_seconds,
            duration_seconds = string.format("%.3f", duration),
            command = artifacts.array(command),
            effects = task.effects,
            change_status = change_status,
            change_error = result.change_error,
            output_error = result.output_error,
            directory = directory,
         }
         if display_output[name] then
            report.output = result.stdout
         end

         if result.state ~= "PASS" then
            report.stdout_tail = diagnostic_tail(result.stdout)
            report.stderr_tail = diagnostic_tail(result.stderr)
         end

         return report
      end
      local report = final_report()

      save_report(report)

      local passed = result.state == "PASS"

      --- Retain the task outcome in a JUnit envelope.
      -- @return nil: no values.
      local function write_junit()
         local failure = passed and ""
            or '<failure message="'
               .. xml(result.state)
               .. '">See stderr.log and stdout.log.</failure>'

         files.write(
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
         if options.direct then
            return
         end
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

      return passed, directory, report
   end

   exports.run = TASKS_run

   return exports
end

return TASKS_loadModule()

-- EOF


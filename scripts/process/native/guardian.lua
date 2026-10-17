-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Supervise descendants independently of the invoking task controller.
-- @return nil: exits with the bounded child outcome.
local function GUARDIAN_main()
   --- Execute the guardian while converting setup faults to infrastructure
   -- exits.
   -- @return nil: exits with the supervised outcome.
   local function execute()
      local uv = require("luv")
      --- Resolve guardian modules independently of the requested child
      -- directory.
      -- @return string, string: repository root and child working directory.
      local function working_directory()
         local directory = assert(uv.cwd())
         local script = arg[0]:gsub("\\", "/")
         local root = script:match("^(.*)/scripts/process/native/guardian.lua$")
            or directory
         assert(uv.chdir(root))
         return root, directory
      end
      local root, directory = working_directory()
      local exec = dofile("scripts/process/lib/exec.lua")
      local host, owner, token, unit =
         arg[1], assert(tonumber(arg[2])), arg[3], arg[4]
      local memory, timeout = assert(tonumber(arg[5])), assert(tonumber(arg[6]))
      assert(host == uv.os_uname().sysname, "guardian host mismatch")
      local command = {}
      for index = 7, #arg do
         command[#command + 1] = arg[index]
      end
      --- Load only the selected host APIs and acquire owned resource handles.
      -- @return table: platform operations used by this guardian.
      local function backend()
         local identity = host ~= "Windows_NT"
            and dofile("scripts/process/native/identity.lua")
         local windows = host == "Windows_NT"
            and dofile("scripts/process/native/windows.lua")
         local darwin = host == "Darwin"
            and dofile("scripts/process/native/darwin.lua")
         local owner_handle = windows and windows.owner(owner)
         local job = windows and windows.job(memory, 128, 2)
         local monitor = darwin and darwin.monitor(memory, timeout)
         return {
            identity = identity,
            windows = windows,
            owner = owner_handle,
            job = job,
            monitor = monitor,
         }
      end
      local selected = backend()
      local identity, windows, owner_handle =
         selected.identity, selected.windows, selected.owner
      local job, monitor = selected.job, selected.monitor
      local abandoned = false
      --- Insert the Windows launch gate before any domain process can start.
      -- @return nil: updates the guardian command in place.
      local function gate_command()
         if windows then
            local gated =
               { uv.exepath(), root .. "/scripts/process/native/gate.lua" }
            for _, value in ipairs(command) do
               gated[#gated + 1] = value
            end
            command = gated
         end
      end
      gate_command()

      --- Check owner identity and host limits before every monitoring interval.
      -- @param pid number: supervised child process identifier.
      -- @return string|nil: infrastructure failure, or nil while within policy.
      local function poll(pid)
         local alive = windows and owner_handle.alive()
            or (identity and identity.token(owner) == token)
         if not alive then
            abandoned = true
            return "INFRA_ERROR"
         end
         return monitor and monitor.poll(pid) or nil
      end

      --- Release the job or process group when execution stops for any reason.
      -- @return nil: no values.
      local function stop()
         if job then
            job.close()
         end
         if monitor then
            monitor.close()
         end
      end

      local result
      if poll(0) then
         result = { state = "INFRA_ERROR", exit_code = 125, signal = 0 }
      else
         result = exec.run(command, {
            timeout_ms = timeout * 1000,
            cwd = directory,
            detached = host ~= "Darwin",
            stdin = windows and "go\n" or nil,
            on_spawn = windows and job.assign or nil,
            on_tick = poll,
            on_stop = stop,
            --- Forward accepted output while the independent guardian is alive.
            -- @param stream string: stdout or stderr.
            -- @param data string: bytes accepted by the executor.
            -- @return nil: callback result is consumed by its owner.
            on_output = function(stream, data)
               assert(io[stream]:write(data))
               assert(io[stream]:flush())
            end,
         })
      end
      stop()
      if owner_handle then
         owner_handle.close()
      end
      if host == "Linux" and abandoned then
         exec.run(
            { "systemctl", "--user", "stop", "--no-block", unit },
            { timeout_ms = 2000 }
         )
      end
      --- Translate the child outcome without treating resource failure as
      -- rejection.
      -- @return nil: exits the guardian process.
      local function finish()
         if result.state == "TIMEOUT" then
            os.exit(124)
         end
         if result.state == "OUTPUT_LIMIT" then
            os.exit(123)
         end
         if result.state == "INFRA_ERROR" or result.signal ~= 0 then
            io.stderr:write(
               result.launch_error
                  or result.monitor_error
                  or result.stderr
                  or "Resource guardian stopped the task",
               "\n"
            )
            os.exit(125)
         end
         os.exit(result.exit_code)
      end
      finish()
   end
   local ok, failure = xpcall(execute, debug.traceback)
   if not ok then
      io.stderr:write(tostring(failure), "\n")
      os.exit(125)
   end
end

return GUARDIAN_main()

-- EOF


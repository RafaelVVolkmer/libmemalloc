-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Native argv execution across supported hosts, with bounded output and time.
-- Part of local process planning and evidence assessment.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_process_lib_exec_loadModule()
   local uv = require("luv")
   local exports = {}

   local EXEC_MAX_OUTPUT_BYTES = 8 * 1024 * 1024
   local EXEC_TIMEOUT_MS = 30 * 1000
   local EXEC_MAX_EXACT_INTEGER = 2 ^ 53 - 1
   local EXEC_OUTPUT_STREAMS = 2
   local EXEC_KILL_SIGNAL = 9 -- POSIX SIGKILL for an expired process group.

   --- Forward child bytes without applying host text-mode newline conversion.
   -- @param stream string: stdout or stderr.
   -- @param data string: exact bytes accepted by the executor.
   -- @return nil: completes every write or raises on a broken output sink.
   function exports.forward_output(stream, data)
      local descriptor =
         assert(({ stdout = 1, stderr = 2 })[stream], "invalid output stream")
      local offset = 0
      while offset < #data do
         local count = assert(uv.fs_write(descriptor, data:sub(offset + 1), -1))
         assert(count > 0, "incomplete output write")
         offset = offset + count
      end
   end

   ---@class ProcessChildHandle
   ---@field kill fun(self: ProcessChildHandle, signal: integer)
   ---@field close fun(self: ProcessChildHandle)
   ---@field is_closing fun(self: ProcessChildHandle): boolean

   --- Validate resource limits before acquiring any native handles.
   -- @param value any: requested positive finite integer limit.
   -- @return nil: no values.
   local function process_exec_validateLimit(value)
      assert(type(value) == "number", "process limit must be numeric")
      assert(
         value > 0 and value <= EXEC_MAX_EXACT_INTEGER and value % 1 == 0,
         "process limit must be a positive finite integer"
      )
   end

   --- Validate a dense literal argv before passing bytes to the native runtime.
   -- @param argv any: executable followed by zero or more arguments.
   -- @return table: validate a dense literal argv before passing bytes to the
   -- native runtime.
   local function process_exec_arguments(argv)
      assert(type(argv) == "table" and #argv > 0, "missing executable")

      local count = 0
      local args = {}

      for key, value in pairs(argv) do
         assert(type(key) == "number", "invalid argv index")
         assert(
            key >= 1 and key <= #argv and key % 1 == 0,
            "argv must be a dense sequence"
         )
         assert(
            type(value) == "string" and not value:find("\0", 1, true),
            "invalid argument"
         )
         count = count + 1
      end

      assert(
         count == #argv and #argv[1] > 0,
         "invalid executable or sparse argv"
      )

      for index = 2, count do
         args[#args + 1] = argv[index]
      end

      return args
   end

   --- Execute one child in its own process group; never invoke a command shell.
   -- @param argv table: executable and literal arguments.
   -- @param options table|nil: stdin, timeout_ms and max_bytes overrides.
   -- @return table: exit, signal, bounded streams and infrastructure status.
   local function PROCESS_EXEC_run(argv, options)
      options = options or {}
      local args = process_exec_arguments(argv)
      local timeout_ms = EXEC_TIMEOUT_MS
      local max_bytes = EXEC_MAX_OUTPUT_BYTES

      if options.timeout_ms ~= nil then
         timeout_ms = options.timeout_ms
      end

      if options.max_bytes ~= nil then
         max_bytes = options.max_bytes
      end

      process_exec_validateLimit(timeout_ms)
      process_exec_validateLimit(max_bytes)

      local result = {
         exit_code = -1,
         signal = 0,
         stdout = "",
         stderr = "",
         state = "INFRA_ERROR",
      }
      local out, err, input =
         uv.new_pipe(false), uv.new_pipe(false), uv.new_pipe(false)
      local timer = uv.new_timer()
      local poll = uv.new_timer()
      local drain = uv.new_timer()

      ---@type ProcessChildHandle?
      local handle = nil
      local pid, exited, ended = nil, false, 0
      local bytes, stopped = 0, false
      local chunks = { stdout = {}, stderr = {} }

      --- Close an owned libuv handle once its lifecycle permits closure.
      -- @param object userdata: owned libuv handle to close when still open.
      -- @return nil: no values.
      local function process_exec_close(object)
         if not object:is_closing() then
            object:close()
         end
      end

      --- Stop the child after a timeout or I/O failure and preserve the failure
      -- state.
      -- @param state any: state supplied to this operation.
      -- @return nil: no values.
      local function process_exec_stop(state)
         if not stopped then
            stopped = true
            result.state = state

            -- detached=true starts a POSIX process group; include child
            -- descendants.
            if options.on_stop then
               local ok, failure = pcall(options.on_stop)
               if not ok then
                  result.stop_error = tostring(failure)
               end
            end
            if
               uv.os_uname().sysname ~= "Windows_NT"
               and options.detached ~= false
            then
               uv.kill(-pid, EXEC_KILL_SIGNAL)
            end
            if not exited and handle then
               handle:kill(EXEC_KILL_SIGNAL)
            end
            --- Close inherited pipes after the bounded cancellation drain.
            -- @return nil: callback result is consumed by its owner.
            drain:start(2000, 0, function()
               process_exec_close(out)
               process_exec_close(err)
               process_exec_close(input)
               process_exec_close(timer)
               process_exec_close(poll)
               process_exec_close(drain)
            end)
         end
      end

      --- Finish the attempt after child exit and stream cleanup have both
      -- completed.
      -- @return nil: no values.
      local function process_exec_finish()
         if exited and ended == EXEC_OUTPUT_STREAMS then
            timer:stop()

            process_exec_close(timer)
            process_exec_close(poll)
            process_exec_close(drain)
         end
      end

      handle, pid = uv.spawn(
         argv[1],
         {
            args = args,
            stdio = { input, out, err },
            detached = options.detached ~= false,
            env = options.env,
            cwd = options.cwd,
         },
         --- Record child exit before closing its handle and checking stream
         -- completion.
         -- @param code any: code supplied to this operation.
         -- @param signal number: native signal reported when the child
         -- terminates.
         -- @return nil: no values.
         function(code, signal)
            exited = true
            result.exit_code, result.signal = code, signal
            if not stopped then
               result.state = code == 0 and signal == 0 and "PASS" or "FAIL"
            end

            process_exec_close(handle)

            process_exec_finish()
         end
      )
      if not handle then
         result.stderr = tostring(pid)
         process_exec_close(input)

         process_exec_close(out)

         process_exec_close(err)

         process_exec_close(timer)
         process_exec_close(poll)
         process_exec_close(drain)

         uv.run()

         return result
      end

      --- Read one output stream within the shared byte budget and retain read
      -- failures.
      -- @param pipe userdata: owned libuv stream; this operation manages its
      -- reads.
      -- @param name string: entry or operation name to resolve.
      -- @return nil: no values.
      local function process_exec_consume(pipe, name)
         pipe:read_start(
            --- Consume bounded stream chunks and preserve read or size-limit
            -- failures.
            -- @param read_error string|nil: native read error, or nil on
            -- successful delivery.
            -- @param data string: delivered bytes, or nil when the stream ends.
            -- @return nil: no values.
            function(read_error, data)
               if read_error then
                  process_exec_stop("INFRA_ERROR")
               end

               if data then
                  local remaining = math.max(0, max_bytes - bytes)

                  local chunk = data:sub(1, remaining)
                  if #chunk > 0 then
                     chunks[name][#chunks[name] + 1] = chunk
                     if options.on_output then
                        local ok, failure =
                           pcall(options.on_output, name, chunk)
                        if not ok then
                           result.output_error = tostring(failure)
                           process_exec_stop("INFRA_ERROR")
                        end
                     end
                  end
                  bytes = bytes + #data
                  if #data > remaining then
                     process_exec_stop("OUTPUT_LIMIT")
                  end
               else
                  ended = ended + 1
                  process_exec_close(pipe)

                  process_exec_finish()
               end
            end
         )
      end

      process_exec_consume(out, "stdout")

      process_exec_consume(err, "stderr")

      timer:start(
         timeout_ms,
         0,
         --- Terminate the child when its execution deadline expires.
         -- @return nil: no values.
         function()
            process_exec_stop("TIMEOUT")
         end
      )
      if options.on_tick then
         --- Poll resource ownership and stop on monitor failure.
         -- @return nil: callback result is consumed by its owner.
         poll:start(0, 100, function()
            if stopped then
               return
            end
            local ok, state = pcall(options.on_tick, pid)
            if not ok then
               result.monitor_error = tostring(state)
               process_exec_stop("INFRA_ERROR")
            elseif state then
               process_exec_stop(state)
            end
         end)
      end
      if options.on_spawn then
         local ok, failure = pcall(options.on_spawn, pid)
         if not ok then
            result.launch_error = tostring(failure)
            process_exec_stop("INFRA_ERROR")
         end
      end
      if options.stdin and not stopped then
         input:write(
            options.stdin,
            --- Handle input-write failure before shutting down the owned input
            -- stream.
            -- @param write_error string|nil: native write error, or nil after
            -- success.
            -- @return nil: no values.
            function(write_error)
               if write_error then
                  process_exec_stop("INFRA_ERROR")
               end

               input:shutdown(
                  --- Close the input handle after libuv completes shutdown.
                  -- @return nil: no values.
                  function()
                     process_exec_close(input)
                  end
               )
            end
         )
      else
         process_exec_close(input)
      end

      uv.run()

      result.stdout, result.stderr =
         table.concat(chunks.stdout), table.concat(chunks.stderr)

      return result
   end

   exports.run = PROCESS_EXEC_run

   return exports
end

return scripts_process_lib_exec_loadModule()

-- EOF


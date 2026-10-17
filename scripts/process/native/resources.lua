-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Select the host resource boundary for every official task.
-- @return table: bounded native execution operations.
local function NATIVE_RESOURCES_loadModule()
   local uv = require("luv")
   local exec = dofile("scripts/process/lib/exec.lua")
   local host = uv.os_uname().sysname
   local mib = 1024 * 1024
   local profiles = { standard = 2048, build = 4096, formal = 4096 }
   local exports = {}

   --- Resolve the user bus before entering the shared Linux cgroup budget.
   -- @param argv table: literal child arguments.
   -- @param options table: execution and resource settings.
   -- @return table: native process result.
   local function linux_run(argv, options)
      local runtime = uv.os_getenv("XDG_RUNTIME_DIR")
         or "/run/user/" .. string.format("%d", uv.getuid())
      uv.os_setenv("XDG_RUNTIME_DIR", runtime)
      uv.os_setenv(
         "DBUS_SESSION_BUS_ADDRESS",
         uv.os_getenv("DBUS_SESSION_BUS_ADDRESS")
            or "unix:path=" .. runtime .. "/bus"
      )
      if options.env then
         local present = {}
         for _, entry in ipairs(options.env) do
            present[entry:match("^([^=]+)=")] = true
         end
         local keys = { "XDG_RUNTIME_DIR", "DBUS_SESSION_BUS_ADDRESS" }
         for _, key in ipairs(keys) do
            if not present[key] then
               options.env[#options.env + 1] = key
                  .. "="
                  .. assert(uv.os_getenv(key))
            end
         end
      end
      return dofile("scripts/verification/lib/resources.lua").run(argv, options)
   end

   --- Bind the guardian command to this controller's process lifetime.
   -- @param argv table: literal domain command.
   -- @param options table: requested budgets.
   -- @return table: native guardian argv.
   local function guardian(argv, options)
      local token = "handle"
      if host == "Darwin" then
         token = assert(
            dofile("scripts/process/native/identity.lua").token(uv.os_getpid())
         )
      end
      local command = {
         os.getenv("LIBMEMALLOC_LUA") or uv.exepath(),
         assert(uv.cwd()) .. "/scripts/process/native/guardian.lua",
         host,
         tostring(uv.os_getpid()),
         token,
         "native",
         tostring(options.memory_bytes),
         tostring(math.ceil((options.timeout_ms or 30000) / 1000)),
      }
      for _, value in ipairs(argv) do
         command[#command + 1] = value
      end
      return command
   end

   --- Preserve resource failures across the guardian's process exit.
   -- @param result table: raw child result.
   -- @return nil: updates its state in place.
   local function classify(result)
      if
         result.state == "FAIL"
         and (result.signal ~= 0 or result.exit_code >= 125)
      then
         result.state = "INFRA_ERROR"
      end
      if result.exit_code == 124 then
         result.state = "TIMEOUT"
      end
      if result.exit_code == 123 then
         result.state = "OUTPUT_LIMIT"
      end
   end

   --- Validate a per-task memory ceiling inside the host budget.
   -- @param options table: requested profile and optional stricter ceiling.
   -- @return nil: updates the validated byte budget in place.
   local function budget(options)
      local profile = assert(
         profiles[options.resource_profile or "standard"],
         "unknown resource profile"
      )
      local memory = math.min(4096, math.floor(uv.get_total_memory() / mib / 2))
         * mib
      options.memory_bytes = options.memory_bytes
         or math.min(memory, profile * mib)
      assert(
         options.memory_bytes >= 16 * mib and options.memory_bytes <= memory,
         "invalid memory budget"
      )
   end

   --- Describe the actual native enforcement model in the result.
   -- @param result table: classified process outcome.
   -- @param options table: validated resource settings.
   -- @return nil: attaches resource metadata in place.
   local function receipt(result, options)
      result.resources = {
         backend = host == "Darwin" and "darwin-watchdog" or "windows-job",
         enforcement = host == "Darwin" and "sampled" or "kernel",
         sample_interval_ms = host == "Darwin" and 100 or nil,
         scope_memory_bytes = options.memory_bytes,
         tasks_max = 128,
         cpu_cores = 2,
         state = result.state,
      }
   end

   --- Run under verified host budgets and retain their enforcement model.
   -- @param argv table: literal executable and arguments.
   -- @param options table|nil: executor settings and resource profile.
   -- @return table: process result and resource metadata.
   function exports.run(argv, options)
      options = options or {}
      budget(options)
      if host == "Linux" then
         return linux_run(argv, options)
      end
      if host ~= "Darwin" and host ~= "Windows_NT" then
         return {
            state = "INFRA_ERROR",
            exit_code = -1,
            signal = 0,
            stdout = "",
            stderr = "Unsupported resource backend",
         }
      end
      local result = exec.run(guardian(argv, options), options)
      classify(result)
      receipt(result, options)
      return result
   end
   return exports
end

return NATIVE_RESOURCES_loadModule()

-- EOF


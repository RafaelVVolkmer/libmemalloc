-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Contain verification tools in a shared Linux memory budget.
-- @return table: bounded execution operations.
local function RESOURCES_loadModule()
   local uv = require("luv")
   local exec = dofile("scripts/process/lib/exec.lua")
   local slice = "libmemalloc-verification.slice"
   local sequence = 0
   local mib = 1024 * 1024
   local memory = math.min(4096, math.floor(uv.get_total_memory() / mib / 2))
      * mib

   --- Limit GHC itself without exporting RTS flags to dependency setup tools.
   -- @param script string: relocated wrapper from the pinned GHC package.
   -- @return string: wrapper applying the compiler's own runtime limit.
   local function compilerScript(script)
      local marker = 'exec "$executablename" -B"$libdir" ${1+"$@"}'
      local start =
         assert(script:find(marker, 1, true), "unexpected GHC wrapper")
      return script:sub(1, start - 1)
         .. 'exec env -u GHCRTS "$executablename" -B"$l'
         .. 'ibdir" ${1+"$@"} +RTS -M1536m -RTS'
         .. script:sub(start + #marker)
   end

   --- Find the actual enclosing verification scope, even with a cleared
   -- environment.
   -- @return string|nil: kernel-reported parent scope for dependency
   -- propagation.
   local function parentScope()
      local file = io.open("/proc/self/cgroup", "r")
      if not file then
         return nil
      end
      local contents = file:read("*a")
      file:close()
      return contents:match("/(libmemalloc%-verification%-[%w%-]+%.scope)\n")
   end

   --- Read an enforced limit or accounting value directly from cgroup v2.
   -- @param path string: kernel control group path.
   -- @param name string: control filename.
   -- @return string|nil: first line, absent when the group is unavailable.
   local function kernelValue(path, name)
      local file = io.open("/sys/fs/cgroup" .. path .. "/" .. name, "r")
      if not file then
         return nil
      end
      local value = file:read("*l")
      file:close()
      return value
   end

   --- Report unavailable containment without executing the requested tool.
   -- @param detail string: failed setup diagnostic.
   -- @return table: infrastructure failure compatible with the process runner.
   local function unavailable(detail)
      return {
         state = "INFRA_ERROR",
         exit_code = -1,
         signal = 0,
         stdout = "",
         stderr = "Verification resource isolation unavailable: " .. detail,
      }
   end

   --- Check the effective CPU quota and period rather than only systemd setup.
   -- @param path string: verified slice path in cgroup v2.
   -- @return boolean: whether the kernel enforces the requested CPU ratio.
   local function cpuApplied(path)
      local quota, period = (kernelValue(path, "cpu.max") or ""):match(
         "^(%d+) (%d+)$"
      )
      quota, period = tonumber(quota), tonumber(period)
      return quota ~= nil
         and period ~= nil
         and period > 0
         and quota == 2 * period
   end

   --- Configure and verify the shared kernel budget before starting a tool.
   -- @return table|nil, string|nil: failure or verified kernel group path.
   local function prepare()
      if uv.os_uname().sysname ~= "Linux" then
         return unavailable(
            "Linux cgroup v2 and a systemd user manager required"
         )
      end
      local setup = exec.run({
         "systemctl",
         "--user",
         "set-property",
         "--runtime",
         slice,
         "MemoryAccounting=yes",
         "MemoryHigh=" .. tostring(math.floor(memory * 3 / 4)),
         "MemoryMax=" .. tostring(memory),
         "MemorySwapMax=0",
         "TasksMax=128",
         "CPUQuota=200%",
      }, { timeout_ms = 10000 })
      if setup.state ~= "PASS" then
         return unavailable(setup.stderr .. setup.stdout)
      end
      local started = exec.run({ "systemctl", "--user", "start", slice })
      if started.state ~= "PASS" then
         return unavailable(started.stderr)
      end
      local group = exec.run({
         "systemctl",
         "--user",
         "show",
         slice,
         "--property=ControlGroup",
         "--value",
      })
      local path = group.stdout:match("^(/[^\n]+)\n$")
      if group.state ~= "PASS" or not path then
         return unavailable("cannot locate the verification cgroup")
      end
      for name, expected in pairs({
         ["memory.high"] = tostring(math.floor(memory * 3 / 4)),
         ["memory.max"] = tostring(memory),
         ["memory.swap.max"] = "0",
         ["pids.max"] = "128",
      }) do
         if kernelValue(path, name) ~= expected then
            return unavailable("kernel did not apply " .. name)
         end
      end
      if not cpuApplied(path) then
         return unavailable("kernel did not apply cpu.max")
      end
      return nil, path
   end

   --- Build a scope command preserving the caller's environment and directory.
   -- @param argv table: literal tool arguments.
   -- @param options table: validated execution options.
   -- @param scopeMemory number: per-command byte ceiling.
   -- @return table, string, string|nil: command, scope and enclosing scope.
   local function scopeCommand(argv, options, scopeMemory)
      sequence = sequence + 1
      local unit = string.format(
         "libmemalloc-verification-%d-%d-%d.scope",
         uv.os_getpid(),
         uv.hrtime(),
         sequence
      )
      local command = {
         "systemd-run",
         "--user",
         "--scope",
         "--quiet",
         "--unit=" .. unit,
         "--slice=" .. slice,
         "--property=MemoryMax=" .. tostring(scopeMemory),
         "--property=MemorySwapMax=0",
         "--property=OOMPolicy=kill",
         "--property=TasksMax=128",
         "--property=RuntimeMaxSec="
            .. tostring(math.ceil((options.timeout_ms or 30000) / 1000)),
         "--property=TimeoutStopSec=5s",
      }
      local parent = parentScope()
      if parent then
         -- After also orders shutdown: the child stops before its parent.
         -- BindsTo propagates timeout, explicit stop and unexpected parent
         -- death.
         command[#command + 1] = "--property=BindsTo=" .. parent
         command[#command + 1] = "--property=After=" .. parent
      end
      for _, value in ipairs({
         "--",
         "env",
         "-u",
         "GHCRTS",
         "LEAN_NUM_THREADS=2",
      }) do
         command[#command + 1] = value
      end
      local stat = assert(io.open("/proc/self/stat", "r"))
      local fields = {}
      for value in
         assert(stat:read("*l")):match("^%d+ %(.+%) (.*)$"):gmatch("%S+")
      do
         fields[#fields + 1] = value
      end
      stat:close()
      for _, value in ipairs({
         os.getenv("LIBMEMALLOC_LUA") or uv.exepath(),
         assert(uv.cwd()) .. "/scripts/process/native/guardian.lua",
         "Linux",
         tostring(uv.os_getpid()):gsub("%.0$", ""),
         assert(fields[20], "supervisor start time unavailable"),
         unit,
         tostring(scopeMemory),
         tostring(math.ceil((options.timeout_ms or 30000) / 1000)),
      }) do
         command[#command + 1] = value
      end
      for _, value in ipairs(argv) do
         command[#command + 1] = value
      end
      return command, unit, parent
   end

   --- Recognize process or resource failures without accepting negative proofs.
   -- @param result table: native process result.
   -- @param scopeResult string|nil: systemd's scope outcome.
   -- @return boolean: whether failure came from execution infrastructure.
   local function infrastructureFailure(result, scopeResult)
      if result.state ~= "FAIL" then
         return false
      end
      if
         result.signal ~= 0
         or result.exit_code == 125
         or result.exit_code == 126
         or result.exit_code == 127
         or result.exit_code == 137
         or scopeResult == "oom-kill"
      then
         return true
      end
      local output = result.stdout .. result.stderr
      for _, diagnostic in ipairs({
         "Heap exhausted",
         "heap overflow",
         "failed to create thread",
         "oom-kill",
         "Failed to connect to bus",
         "Failed to start transient",
      }) do
         if output:find(diagnostic, 1, true) then
            return true
         end
      end
      return false
   end

   --- Validate a command's ceiling against the unchanged shared budget.
   -- @param options table: requested execution options.
   -- @return number: validated byte ceiling.
   local function scopeBudget(options)
      local scopeMemory = options.memory_bytes or memory
      assert(
         type(scopeMemory) == "number"
            and scopeMemory >= 16 * mib
            and scopeMemory <= memory
            and scopeMemory % 1 == 0,
         "scope memory must be 16 MiB or more, within the shared budget"
      )
      return scopeMemory
   end

   --- Execute a tool in its own scope, beneath a shared capped slice.
   -- @param argv table: literal executable and arguments.
   -- @param options table|nil: native executor options.
   -- @return table: captured result, including resource failure diagnostics.
   local function run(argv, options)
      options = options or {}
      local scopeMemory = scopeBudget(options)
      local failure, groupPath = prepare()
      if failure then
         return failure
      end
      local command, unit, parent = scopeCommand(argv, options, scopeMemory)
      local result = exec.run(command, options)
      local accounting = exec.run({
         "systemctl",
         "--user",
         "show",
         unit,
         "--property=Result",
         "--property=MemoryPeak",
         "--property=MemorySwapPeak",
      })
      local scopeResult = accounting.stdout:match("Result=([^\n]+)")
      -- A killed launcher must not leave descendants running in its scope.
      exec.run({ "systemctl", "--user", "stop", unit }, { timeout_ms = 10000 })
      exec.run({ "systemctl", "--user", "reset-failed", unit })
      if infrastructureFailure(result, scopeResult) then
         result.state = "INFRA_ERROR"
      end
      if result.exit_code == 123 then
         result.state = "OUTPUT_LIMIT"
      end
      if scopeResult == "timeout" or result.exit_code == 124 then
         result.state = "TIMEOUT"
      end
      result.resources = {
         backend = "cgroup-v2",
         cpu_cores = 2,
         cpu_max = kernelValue(groupPath, "cpu.max"),
         tasks_max = 128,
         shared_memory_bytes = memory,
         scope_memory_bytes = scopeMemory,
         swap_bytes = 0,
         ghc_heap_mib = 1536,
         scope = unit,
         parent_scope = parent,
         scope_result = scopeResult,
         memory_peak_bytes = tonumber(
            accounting.stdout:match("MemoryPeak=(%d+)")
         ),
         shared_memory_peak_bytes = tonumber(
            kernelValue(groupPath, "memory.peak")
         ),
         state = result.state,
      }
      if result.state == "INFRA_ERROR" then
         result.stderr = result.stderr
            .. string.format(
               "\nVerification task failed inside resource isolation "
                  .. "(result=%s, signal=%d, exit=%d); scope=%s\n",
               scopeResult or "unavailable",
               result.signal,
               result.exit_code,
               unit
            )
      end
      return result
   end
   return { run = run, compiler_script = compilerScript }
end

return RESOURCES_loadModule()

-- EOF


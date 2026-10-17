-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Exercise real kernel containment with a small disposable allocation.
-- @return nil: no values.
local function RESOURCES_TEST_main()
   local resources = dofile("scripts/verification/lib/resources.lua")
   local ioTools = dofile("scripts/process/lib/io.lua")
   local files = dofile("scripts/verification/lib/files.lua")
   local verdict = dofile("scripts/verification/lib/verdict.lua")
   local directory = ".cache/logs/resource-regression"
   assert(
      ioTools.exec.run({ "mkdir", "-p", directory }).state == "PASS",
      "cannot create test logs"
   )
   local lua = os.getenv("LIBMEMALLOC_LUA") or "lua"
   local cap = 64 * 1024 * 1024
   local probe = resources.run({
      lua,
      "-e",
      [[
      assert(os.getenv("GHCRTS") == nil)
      assert(os.getenv("LEAN_NUM_THREADS") == "2")
      local file = assert(io.open("/proc/self/cgroup"))
      local group = assert(file:read("*a"):match("0::([^\n]+)"))
      file:close()
      assert(group:match("libmemalloc%-verification.*%.scope$"))
      local base = "/sys/fs/cgroup" .. group .. "/"
      for key, value in pairs({["memory.max"]="67108864", ["memory.swap.max"]="0"}) do
         file = assert(io.open(base .. key))
         assert(file:read("*l") == value)
         file:close()
      end
      assert(arg[1] == "literal $HOME ; spaces")
      print("kernel limits and literal arguments verified")
   ]],
      "--",
      "/dev/null",
      "literal $HOME ; spaces",
   }, { memory_bytes = cap })
   assert(probe.state == "PASS", probe.stderr)
   local quota, period =
      assert(probe.resources.cpu_max, "missing CPU receipt"):match(
         "^(%d+) (%d+)$"
      )
   assert(tonumber(quota) == 2 * tonumber(period), "CPU quota was not verified")
   assert(probe.resources.tasks_max == 128, "task limit receipt missing")
   files.write(directory .. "/probe.json", ioTools.json(probe))
   --- Refuse execution when the observed CPU controller is absent or incorrect.
   -- @return nil: no values.
   local function checkCpuAdmission()
      local replacement = directory .. "/cpu-max"
      --- Replace only CPU metadata while keeping real systemd setup and memory checks.
      -- @param name string: requested kernel metadata path.
      -- @param mode string: file access mode.
      -- @return file*|nil: actual file or substituted CPU metadata.
      local function openMetadata(name, mode)
         if name:match("/cpu%.max$") then
            return io.open(replacement, mode)
         end
         return io.open(name, mode)
      end
      local environment = setmetatable({ io = { open = openMetadata } }, {
         __index = {
            require = require,
            dofile = dofile,
            assert = assert,
            math = math,
            tonumber = tonumber,
            tostring = tostring,
            type = type,
            pairs = pairs,
            ipairs = ipairs,
            string = string,
         },
      })
      local isolated = assert(
         loadfile("scripts/verification/lib/resources.lua", "t", environment)
      )()
      for _, value in ipairs({ "max 100000", "100000 100000", "200000 0" }) do
         files.write(replacement, value .. "\n")
         local rejectedCpu = isolated.run({ "/bin/true" })
         assert(
            rejectedCpu.state == "INFRA_ERROR",
            "incorrect CPU quota accepted"
         )
         assert(rejectedCpu.stderr:find("cpu.max", 1, true), rejectedCpu.stderr)
      end
      assert(ioTools.uv.fs_unlink(replacement))
      local missingCpu = isolated.run({ "/bin/true" })
      assert(
         missingCpu.state == "INFRA_ERROR",
         "absent CPU controller accepted"
      )
   end
   checkCpuAdmission()

   files.write(
      directory .. "/compiler",
      '#!/bin/sh\ntest -z "${GHCRTS+x}" || exit 1\nprintf "%s\\n" "$@"\n'
   )
   assert(
      ioTools.exec.run({ "chmod", "+x", directory .. "/compiler" }).state
         == "PASS",
      "cannot prepare compiler probe"
   )
   files.write(
      directory .. "/ghc",
      resources.compiler_script(
         'executablename="'
            .. ioTools.uv.cwd()
            .. "/"
            .. directory
            .. '/compiler"\nlibdir="/probe"\nexec "$executablename" -B"$libdir" ${1+"$@"}\n'
      )
   )
   local compiler = resources.run(
      { "env", "GHCRTS=-M9G", "sh", directory .. "/ghc", "literal argument" },
      { memory_bytes = cap }
   )
   assert(
      compiler.state == "PASS"
         and compiler.stdout
            == "-B/probe\nliteral argument\n+RTS\n-M1536m\n-RTS\n",
      "compiler heap limit missing: " .. compiler.stderr
   )
   files.write(
      directory .. "/allocate.c",
      [[
#include <stdlib.h>
#include <string.h>
int main(void) {
    for (int i = 0; i < 128; ++i) {
        volatile unsigned char *p = malloc(1024 * 1024);
        if (!p) return 2;
        for (size_t j = 0; j < 1024 * 1024; j += 4096) p[j] = 1;
    }
    return 0;
}
]]
   )
   local binary = directory .. "/allocate"
   local compile =
      resources.run({ "cc", "-O0", directory .. "/allocate.c", "-o", binary })
   assert(compile.state == "PASS", compile.stderr)
   local exhausted = resources.run(
      { binary },
      { memory_bytes = cap, timeout_ms = 10000 }
   )
   files.write(directory .. "/oom.json", ioTools.json(exhausted))
   assert(exhausted.state == "INFRA_ERROR", ioTools.json(exhausted))
   assert(
      verdict.classify("produce", exhausted) == "INFRA_ERROR",
      "OOM became input rejection"
   )
   local recovered = resources.run({ "/bin/true" }, { memory_bytes = cap })
   assert(recovered.state == "PASS", recovered.stderr)
   local missing = resources.run(
      { "/nonexistent-libmemalloc-verifier" },
      { memory_bytes = cap }
   )
   assert(missing.state == "INFRA_ERROR", missing.stderr)
   assert(
      verdict.classify("produce", missing) == "INFRA_ERROR",
      "missing verifier became input rejection"
   )
   local deniedExecutable = resources.run(
      { "sh", "-c", "exit 126" },
      { memory_bytes = cap }
   )
   assert(
      deniedExecutable.state == "INFRA_ERROR",
      "execution denial became rejection"
   )
   local signaled = resources.run(
      { "sh", "-c", "kill -TERM $$" },
      { memory_bytes = cap }
   )
   assert(signaled.state == "INFRA_ERROR", "signal became an input rejection")
   local rejected = resources.run(
      { "sh", "-c", "echo 'invalid input' >&2; exit 1" },
      { memory_bytes = cap }
   )
   assert(rejected.state == "FAIL", "ordinary rejection was reclassified")
   assert(
      verdict.classify("produce", rejected) == "REJECTED_INPUT",
      "ordinary input rejection lost its classification"
   )
   local heapOverflow = resources.run({
      "sh",
      "-c",
      "printf 'panic! (the impossible happened)\\nGHC version 9.4.7:\\n\\theap overflow\\n' >&2; exit 1",
   }, { memory_bytes = cap })
   files.write(directory .. "/heap-overflow.json", ioTools.json(heapOverflow))
   assert(heapOverflow.state == "INFRA_ERROR", ioTools.json(heapOverflow))
   assert(
      verdict.classify("produce", heapOverflow) == "INFRA_ERROR",
      "GHC heap overflow became input rejection"
   )
   local expired = resources.run({ "sh", "-c", "setsid sleep 30 & wait" }, {
      memory_bytes = cap,
      timeout_ms = 200,
   })
   files.write(directory .. "/timeout.json", ioTools.json(expired))
   assert(expired.state == "TIMEOUT", ioTools.json(expired))
   local active = ioTools.exec.run({
      "systemctl",
      "--user",
      "is-active",
      expired.resources.scope,
   })
   assert(active.state ~= "PASS", "timeout left a live scope")
   -- Nested scopes must follow their actual parent, without stopping neighbors.
   local nested = directory .. "/nested.lua"
   files.write(
      nested,
      [[
local resources = dofile("scripts/verification/lib/resources.lua")
local files = dofile("scripts/verification/lib/files.lua")
local uv = require("luv")
local exec = dofile("scripts/process/lib/exec.lua")
local mode, prefix, lua = arg[1], arg[2], arg[3]
local group = assert(io.open("/proc/self/cgroup", "r"))
local scope = assert(group:read(4096):match("/(libmemalloc%-verification%-[%w%-]+%.scope)\n"))
group:close()
if mode == "timeout" or mode == "cancel" then
   files.write(prefix .. ".outer", scope)
   resources.run({lua, arg[0], "leaf", prefix, lua, mode}, {memory_bytes=67108864, timeout_ms=30000})
else
   files.write(prefix .. ".pid", tostring(uv.os_getpid()))
   files.write(prefix .. ".scope", scope)
   if arg[4] == "cancel" then
      exec.run({"systemctl", "--user", "stop", files.read(prefix .. ".outer")})
   end
   exec.run({"sh", "-c", "setsid sleep 30 & wait"}, {timeout_ms=30000})
end
]]
   )
   local neighbor = directory
      .. "/neighbor-"
      .. tostring(ioTools.uv.hrtime()):gsub("%.0$", "")
   local launcher = directory .. "/neighbor.lua"
   files.write(
      launcher,
      [[
local resources = dofile("scripts/verification/lib/resources.lua")
resources.run({arg[1], arg[2], "neighbor", arg[3], arg[1]}, {memory_bytes=67108864, timeout_ms=30000})
]]
   )
   local handle
   --- Close the independent launcher's handle after its process exits.
   -- @return nil: no values.
   local function neighborExited()
      handle:close()
   end
   handle = assert(ioTools.uv.spawn(lua, {
      args = { launcher, lua, nested, neighbor },
      stdio = { nil, nil, nil },
   }, neighborExited))
   handle:unref()
   local deadline = ioTools.uv.hrtime() + 5e9
   while
      not ioTools.uv.fs_stat(neighbor .. ".scope")
      and ioTools.uv.hrtime() < deadline
   do
      ioTools.uv.run("nowait")
      ioTools.uv.sleep(20)
   end
   local neighborScope = files.read(neighbor .. ".scope")
   --- Check cancellation propagation while an independent campaign is active.
   -- @return nil: no values.
   local function checkNestedScopes()
      for _, mode in ipairs({ "timeout", "cancel" }) do
         local prefix = directory
            .. "/"
            .. mode
            .. "-"
            .. tostring(ioTools.uv.hrtime()):gsub("%.0$", "")
         local result = resources.run({ lua, nested, mode, prefix, lua }, {
            memory_bytes = cap,
            timeout_ms = mode == "timeout" and 3000 or 10000,
         })
         files.write(prefix .. ".json", ioTools.json(result))
         assert(
            result.state == (mode == "timeout" and "TIMEOUT" or "INFRA_ERROR"),
            ioTools.json(result)
         )
         local childScope = files.read(prefix .. ".scope")
         local childActive =
            ioTools.exec.run({ "systemctl", "--user", "is-active", childScope })
         -- Clean up even if a future regression breaks propagation.
         ioTools.exec.run({ "systemctl", "--user", "stop", childScope })
         assert(childActive.state ~= "PASS", "nested child survived " .. mode)
         local childPid = tonumber(files.read(prefix .. ".pid"))
         assert(
            ioTools.uv.kill(childPid, 0) ~= 0,
            "nested process survived " .. mode
         )
         local neighborActive = ioTools.exec.run({
            "systemctl",
            "--user",
            "is-active",
            neighborScope,
         })
         assert(neighborActive.state == "PASS", "unrelated scope was stopped")
      end
   end
   local ok, failure = xpcall(checkNestedScopes, debug.traceback)
   ioTools.exec.run({ "systemctl", "--user", "stop", neighborScope })
   if not handle:is_closing() then
      handle:ref()
   end
   ioTools.uv.run()
   assert(ok, failure)
   assert(
      not pcall(resources.run, { "/bin/true" }, { memory_bytes = 2 ^ 50 }),
      "oversized budget accepted"
   )
   local bus = ioTools.uv.os_getenv("DBUS_SESSION_BUS_ADDRESS")
   local runtime = ioTools.uv.os_getenv("XDG_RUNTIME_DIR")
   ioTools.uv.os_setenv("XDG_RUNTIME_DIR", "/nonexistent-libmemalloc-runtime")
   ioTools.uv.os_setenv(
      "DBUS_SESSION_BUS_ADDRESS",
      "unix:path=/nonexistent-libmemalloc-bus"
   )
   local denied = resources.run({ "sh", "-c", "echo unprotected" })
   if bus then
      ioTools.uv.os_setenv("DBUS_SESSION_BUS_ADDRESS", bus)
   else
      ioTools.uv.os_unsetenv("DBUS_SESSION_BUS_ADDRESS")
   end
   if runtime then
      ioTools.uv.os_setenv("XDG_RUNTIME_DIR", runtime)
   else
      ioTools.uv.os_unsetenv("XDG_RUNTIME_DIR")
   end
   assert(
      denied.state == "INFRA_ERROR" and denied.stdout == "",
      "missing isolation executed the command"
   )
   files.write(directory .. "/unavailable.json", ioTools.json(denied))
   print(
      "Resource containment: kernel caps, OOM recovery, nested timeout and cancellation passed."
   )
end

return RESOURCES_TEST_main()

-- EOF


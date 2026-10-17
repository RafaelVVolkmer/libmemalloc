-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Observe macOS process groups with libproc and enforce sampled budgets.
-- @return table: owner identities and process-group monitoring.
local function DARWIN_loadModule()
   if package.loaded["lma.native.darwin"] then
      return package.loaded["lma.native.darwin"]
   end
   local ffi = require("cffi")
   local uv = require("luv")
   ffi.cdef([[
      typedef struct {
         unsigned int flags, status, xstatus, pid, ppid;
         unsigned int uid, gid, ruid, rgid, svuid, svgid, reserved;
         char command[16], name[32];
         unsigned int files, pgid, jobc, device, terminal_pgid;
         int nice;
         unsigned long long start_seconds, start_microseconds;
      } LMA_BSD_INFO;
      typedef struct {
         unsigned long long virtual_size, resident_size, total_user, total_system;
         unsigned long long threads_user, threads_system;
         int policy, faults, pageins, cow_faults, messages_sent, messages_received;
         int syscalls_mach, syscalls_unix, csw, threadnum, numrunning, priority;
      } LMA_TASK_INFO;
      typedef struct { unsigned long long current, maximum; } LMA_RLIMIT;
      int proc_pidinfo(int, int, unsigned long long, void *, int);
      int proc_listpids(unsigned int, unsigned int, void *, int);
      int setrlimit(int, const LMA_RLIMIT *);
   ]])
   local api = ffi.load("/usr/lib/libproc.dylib")
   local exports = {}

   --- Read a start timestamp and reject a vanished or zombie owner.
   -- @param pid number: process identifier.
   -- @return string|nil: stable start timestamp while alive.
   function exports.identity(pid)
      local info = ffi.new("LMA_BSD_INFO[1]")
      if
         api.proc_pidinfo(pid, 3, 0, info, ffi.sizeof(info))
            ~= ffi.sizeof(info)
         or info[0].status == 5
      then
         return nil
      end
      return tostring(tonumber(info[0].start_seconds))
         .. ":"
         .. tostring(tonumber(info[0].start_microseconds))
   end

   --- Bound a process group with RSS sampling, CPU throttling and native CPU limits.
   -- @param memory number: aggregate resident memory ceiling.
   -- @param timeout number: wall-clock deadline in seconds.
   -- @return table: sample and cleanup operations.
   function exports.monitor(memory, timeout)
      local core = ffi.new("LMA_RLIMIT[1]")
      assert(ffi.C.setrlimit(4, core) == 0, "cannot disable core dumps")
      local cpu = ffi.new("LMA_RLIMIT[1]")
      cpu[0].current, cpu[0].maximum = timeout * 2, timeout * 2
      assert(ffi.C.setrlimit(0, cpu) == 0, "cannot set CPU deadline")
      local group, started = uv.os_getpid(), uv.hrtime()
      local members = ffi.new("int[4096]")
      local tracked, consumed = {}, 0
      local exports_monitor = {}

      --- Aggregate the current group while retaining cumulative CPU accounting.
      -- @param size number: bytes returned by the process inventory API.
      -- @return number, number, table: resident bytes, population and live identities.
      local function sample(size)
         local rss, count = 0, 0
         local live = {}
         for index = 0, math.floor(size / ffi.sizeof("int")) - 1 do
            local member = tonumber(members[index])
            if member > 0 and member ~= group then
               local token = exports.identity(member)
               local info = ffi.new("LMA_TASK_INFO[1]")
               if
                  token
                  and api.proc_pidinfo(member, 4, 0, info, ffi.sizeof(info))
                     == ffi.sizeof(info)
               then
                  local key = tostring(member) .. ":" .. token
                  local spent = tonumber(
                     info[0].total_user + info[0].total_system
                  ) / 1000000000
                  consumed = consumed + math.max(0, spent - (tracked[key] or 0))
                  tracked[key], live[member] = spent, token
                  rss, count = rss + tonumber(info[0].resident_size), count + 1
               end
            end
         end
         return rss, count, live
      end

      --- Inspect the bounded group and preserve CPU spent by exited members.
      -- @param pid number: child identifier; zero denotes the prelaunch check.
      -- @return string|nil: infrastructure failure when a sampled budget is exceeded.
      function exports_monitor.poll(pid)
         if pid == 0 then
            return nil
         end
         local size = api.proc_listpids(2, group, members, ffi.sizeof(members))
         assert(
            size > 0 and size < ffi.sizeof(members),
            "cannot inventory process group"
         )
         local rss, count, live = sample(size)
         if rss > memory or count > 128 then
            return "INFRA_ERROR"
         end
         local throttle = consumed
            > 2 * ((uv.hrtime() - started) / 1000000000) + 0.1
         for member, token in pairs(live) do
            if exports.identity(member) == token then
               uv.kill(member, throttle and 17 or 19)
            end
         end
         return nil
      end

      --- Terminate group members while allowing the guardian to finish its receipt.
      -- @return nil: no values.
      function exports_monitor.close()
         local size = api.proc_listpids(2, group, members, ffi.sizeof(members))
         for index = 0, math.min(4096, math.floor(math.max(0, size) / ffi.sizeof("int"))) - 1 do
            local member = tonumber(members[index])
            if member > 0 and member ~= group then
               uv.kill(member, 9)
            end
         end
      end
      return exports_monitor
   end
   package.loaded["lma.native.darwin"] = exports
   return exports
end

return DARWIN_loadModule()

-- EOF


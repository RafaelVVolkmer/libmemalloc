-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Bind the Windows job and process APIs through the pinned Lua FFI module.
-- @return table: process ownership and verified job limits.
local function WINDOWS_loadModule()
   local ffi = require("cffi")
   local uv = require("luv")
   ffi.cdef([[
      typedef void *LMA_HANDLE;
      typedef unsigned int LMA_DWORD;
      typedef int LMA_BOOL;
      typedef struct {
         long long PerProcessUserTimeLimit, PerJobUserTimeLimit;
         LMA_DWORD LimitFlags;
         size_t MinimumWorkingSetSize, MaximumWorkingSetSize;
         LMA_DWORD ActiveProcessLimit;
         size_t Affinity;
         LMA_DWORD PriorityClass, SchedulingClass;
      } LMA_BASIC_LIMITS;
      typedef struct {
         unsigned long long ReadOperationCount, WriteOperationCount;
         unsigned long long OtherOperationCount;
         unsigned long long ReadTransferCount, WriteTransferCount;
         unsigned long long OtherTransferCount;
      } LMA_IO_COUNTERS;
      typedef struct {
         LMA_BASIC_LIMITS BasicLimitInformation;
         LMA_IO_COUNTERS IoInfo;
         size_t ProcessMemoryLimit, JobMemoryLimit;
         size_t PeakProcessMemoryUsed, PeakJobMemoryUsed;
      } LMA_EXTENDED_LIMITS;
      typedef struct { LMA_DWORD ControlFlags, CpuRate; } LMA_CPU_RATE;
      LMA_HANDLE __stdcall CreateJobObjectW(void *, const unsigned short *);
      LMA_BOOL __stdcall SetInformationJobObject(
         LMA_HANDLE, int, void *, LMA_DWORD);
      LMA_BOOL __stdcall QueryInformationJobObject(
         LMA_HANDLE, int, void *, LMA_DWORD, void *);
      LMA_BOOL __stdcall AssignProcessToJobObject(LMA_HANDLE, LMA_HANDLE);
      LMA_BOOL __stdcall CloseHandle(LMA_HANDLE);
      LMA_HANDLE __stdcall OpenProcess(LMA_DWORD, LMA_BOOL, LMA_DWORD);
      LMA_DWORD __stdcall WaitForSingleObject(LMA_HANDLE, LMA_DWORD);
      LMA_DWORD __stdcall GetLastError(void);
   ]])
   local api = ffi.load("kernel32")
   local exports = {}

   --- Reject a failed Win32 operation while retaining its native error number.
   -- @param value any: boolean or pointer returned by the native API.
   -- @return any: successful native result.
   local function checked(value)
      assert(
         value ~= ffi.nullptr and value ~= 0,
         "Windows resource API failed: "
            .. tostring(ffi.tonumber(api.GetLastError()))
      )
      return value
   end

   --- Retain a non-inheritable handle to the invoking controller's lifetime.
   -- @param pid number: invoking Lua process identifier.
   -- @return table: owner lifetime operations.
   function exports.owner(pid)
      local handle = checked(api.OpenProcess(0x100000, 0, pid))
      return {
         --- Observe the retained controller handle without waiting.
         -- @return boolean: true while the retained process is alive.
         alive = function()
            return api.WaitForSingleObject(handle, 0) == 258
         end,
         --- Release the retained controller handle.
         -- @return nil: callback result is consumed by its owner.
         close = function()
            checked(api.CloseHandle(handle))
         end,
      }
   end

   --- Install and read back memory, process and CPU ceilings before assignment.
   -- @param memory number: aggregate committed memory ceiling in bytes.
   -- @param processes number: maximum active processes in the job.
   -- @param cores number: aggregate CPU capacity available to the job.
   -- @return table: gated assignment and idempotent cleanup operations.
   function exports.job(memory, processes, cores)
      local handle = checked(api.CreateJobObjectW(nil, nil))
      local exports_job = {}
      --- Close the last job handle to terminate all members.
      -- @return nil: callback result is consumed by its owner.
      function exports_job.close()
         if handle then
            checked(api.CloseHandle(handle))
            handle = nil
         end
      end
      --- Configure and verify every required Windows job limit.
      -- @return nil: callback result is consumed by its owner.
      local ok, failure = pcall(function()
         local limit = ffi.new("LMA_EXTENDED_LIMITS[1]")
         limit[0].BasicLimitInformation.LimitFlags = 0x2000 | 0x200 | 0x8
         limit[0].BasicLimitInformation.ActiveProcessLimit = processes
         limit[0].JobMemoryLimit = memory
         checked(
            api.SetInformationJobObject(handle, 9, limit, ffi.sizeof(limit))
         )
         local cpu = ffi.new("LMA_CPU_RATE[1]")
         cpu[0].ControlFlags = 0x1 | 0x4
         cpu[0].CpuRate =
            math.min(10000, math.floor(10000 * cores / #uv.cpu_info()))
         checked(api.SetInformationJobObject(handle, 15, cpu, ffi.sizeof(cpu)))
         local actual, rate =
            ffi.new("LMA_EXTENDED_LIMITS[1]"), ffi.new("LMA_CPU_RATE[1]")
         checked(
            api.QueryInformationJobObject(
               handle,
               9,
               actual,
               ffi.sizeof(actual),
               nil
            )
         )
         checked(
            api.QueryInformationJobObject(
               handle,
               15,
               rate,
               ffi.sizeof(rate),
               nil
            )
         )
         local basic = actual[0].BasicLimitInformation
         local requested = limit[0].BasicLimitInformation
         assert(
            ffi.tonumber(actual[0].JobMemoryLimit) == memory
               and basic.ActiveProcessLimit == processes
               and basic.LimitFlags == requested.LimitFlags
               and rate[0].ControlFlags == cpu[0].ControlFlags
               and rate[0].CpuRate == cpu[0].CpuRate,
            "Windows did not apply job limits"
         )
      end)
      if not ok then
         exports_job.close()
         error(failure)
      end

      --- Assign the waiting gate before its stdin releases any task code.
      -- @param pid number: newly spawned gate process.
      -- @return nil: no values.
      function exports_job.assign(pid)
         local process = checked(api.OpenProcess(0x100 | 0x1, 0, pid))
         local assigned = api.AssignProcessToJobObject(handle, process)
         local failure_code = ffi.tonumber(api.GetLastError())
         checked(api.CloseHandle(process))
         assert(
            assigned ~= 0,
            "Windows job assignment failed: " .. tostring(failure_code)
         )
      end
      return exports_job
   end
   return exports
end

return WINDOWS_loadModule()

-- EOF


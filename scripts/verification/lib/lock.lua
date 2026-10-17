-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Serialize campaigns with a kernel lease released on process death.
-- @return table: campaign entrypoint guard.
local function FORMAL_LOCK_loadModule()
   local uv = require("luv")
   local platform = dofile("scripts/lib/platform.lua")
   local path = ".cache/formal/campaign.lock"

   --- Read bounded kernel metadata without trusting environment markers.
   -- @param name string: procfs metadata path.
   -- @return string: available metadata, or empty when the descriptor vanished.
   local function metadata(name)
      local file = io.open(name, "r")
      if not file then
         return ""
      end
      local value = file:read(4096) or ""
      file:close()
      return value
   end

   --- Require this process to hold an exclusive flock on the exact inode.
   -- @param expected table: lock file identity.
   -- @return boolean: whether a kernel-confirmed lease is already held.
   local function owned(expected)
      local scan = assert(uv.fs_scandir("/proc/self/fd"))
      while true do
         local fd = uv.fs_scandir_next(scan)
         if not fd then
            return false
         end
         local actual = uv.fs_stat("/proc/self/fd/" .. fd)
         if
            actual
            and actual.dev == expected.dev
            and actual.ino == expected.ino
         then
            local owner = metadata("/proc/self/fdinfo/" .. fd):match(
               "FLOCK%s+ADVISORY%s+WRITE%s+(%d+)%s"
            )
            if tonumber(owner) == uv.os_getpid() then
               return true
            end
         end
      end
   end

   --- Re-enter the campaign while holding a nonblocking exclusive kernel lease.
   -- @return nil: returns only in the process holding the lease.
   local function guard()
      assert(uv.os_uname().sysname == "Linux", "formal campaign requires Linux")
      assert(
         not uv.fs_lstat(".cache/formal/active"),
         "inspect legacy .cache/formal/active lock"
      )
      local previous = uv.fs_lstat(path)
      assert(
         not previous or previous.type == "file",
         "non-regular campaign lock"
      )
      if previous and owned(previous) then
         return
      end
      local command = {
         "flock",
         "--exclusive",
         "--nonblock",
         "--no-fork",
         "--conflict-exit-code",
         "75",
         path,
         os.getenv("LIBMEMALLOC_LUA") or arg[-1] or "lua",
         (assert(arg[0], "missing campaign entrypoint")),
      }
      for _, value in ipairs(arg) do
         command[#command + 1] = value
      end
      local code = platform.execute(command)
      if code == 75 then
         io.stderr:write(
            "Formal campaign already active; retry after its owner exits.\n"
         )
      end
      os.exit(code)
   end
   return { guard = guard }
end

return FORMAL_LOCK_loadModule()

-- EOF


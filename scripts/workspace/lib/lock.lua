-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Coordinate POSIX workspace commands with a kernel lock outside cleanup
--- scopes.
-- @return table: public operations constructed by this module.
local function LOCK_loadModule()
   local platform = dofile("scripts/lib/platform.lua")
   local exports = {}
   local conflict = 75

   --- Preserve shared access on other hosts without allowing unsafe cleanup.
   -- @param mode any: mode supplied to this operation.
   -- @return any: preserve shared access on other hosts without allowing unsafe
   -- cleanup.
   local function supported(mode)
      local system = platform.is_windows and "Windows\n"
         or platform.command_output({ "uname", "-s" })
      if
         platform.is_windows or (system ~= "Linux\n" and system ~= "Darwin\n")
      then
         assert(mode == "shared", "exclusive access requires Linux or macOS")

         return false
      end

      return system
   end

   --- Recognize inherited leases without allowing a shared-to-exclusive jump.
   -- @param mode any: mode supplied to this operation.
   -- @param path string: filesystem path selected by the caller.
   -- @return boolean: recognize inherited leases without allowing a
   -- shared-to-exclusive jump.
   local function inherited(mode, path)
      if os.getenv("LIBMEMALLOC_WORKSPACE_LOCK") ~= path then
         return false
      end

      local held = os.getenv("LIBMEMALLOC_WORKSPACE_LOCK_MODE")

      assert(
         held == "exclusive" or held == mode,
         "cannot upgrade an active shared workspace lock"
      )

      return true
   end

   --- Choose the host's equivalent nonblocking kernel-lock entrypoint.
   -- @param mode any: mode supplied to this operation.
   -- @param path string: filesystem path selected by the caller.
   -- @param system any: system supplied to this operation.
   -- @return any: choose the host's equivalent nonblocking kernel-lock
   -- entrypoint.
   local function lease_command(mode, path, system)
      if system == "Darwin\n" then
         return dofile("scripts/workspace/lib/lease.lua").command(mode, path)
      end

      assert(platform.command_exists("flock"), "install util-linux flock")

      return {
         "flock",
         "--" .. mode,
         "--nonblock",
         "--no-fork",
         "--conflict-exit-code",
         tostring(conflict),
         path,
      }
   end

   --- Re-execute with a lease; descendants reuse their parent's checkout lease.
   -- Shared work may overlap; cleanup and runtime replacement are exclusive.
   -- @param mode any: mode supplied to this operation.
   -- @return nil: no values.
   function exports.guard(mode)
      assert(mode == "shared" or mode == "exclusive", "invalid lock mode")
      local system = supported(mode)
      if not system then
         return
      end

      local root = assert(platform.command_output({
         "git",
         "rev-parse",
         "--show-toplevel",
      })):gsub("[\r\n]+$", "")
      local path = root .. "/.cache/locks/workspace.lock"
      if inherited(mode, path) then
         return
      end

      for _, parent in ipairs({ root .. "/.cache", root .. "/.cache/locks" }) do
         assert(
            not platform.command_succeeded({ "test", "-L", parent }),
            "workspace lock parent must not be a symlink"
         )
         platform.run({ "mkdir", "-p", "--", parent })
      end

      assert(
         not platform.command_succeeded({ "test", "-L", path }),
         "workspace lock must not be a symlink"
      )
      local command = lease_command(mode, path, system)
      local child = {
         "env",
         "LIBMEMALLOC_WORKSPACE_LOCK=" .. path,
         "LIBMEMALLOC_WORKSPACE_LOCK_MODE=" .. mode,
         arg[-1] or "lua",
         (assert(arg[0], "missing script path")),
      }

      for _, value in ipairs(child) do
         command[#command + 1] = value
      end

      for _, value in ipairs(arg) do
         command[#command + 1] = value
      end

      local code = platform.execute(command)
      if code == conflict then
         io.stderr:write(
            "Workspace busy: exclusive maintenance conflicts with a task; "
               .. "retry after it exits.\n"
         )
      end

      os.exit(code)
   end

   return exports
end

return LOCK_loadModule()

-- EOF


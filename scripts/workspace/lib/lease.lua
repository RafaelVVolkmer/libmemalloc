-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Use the POSIX kernel lease on hosts without the util-linux CLI.
-- @return table: public operations constructed by this module.
local function LEASE_loadModule()
   local exports = {}

   --- Keep the locked descriptor across exec and release it on process death.
   -- @param mode any: mode supplied to this operation.
   -- @param path string: filesystem path selected by the caller.
   -- @return table: keep the locked descriptor across exec and release it on
   -- process death.
   function exports.command(mode, path)
      assert(mode == "shared" or mode == "exclusive", "invalid lease mode")

      return {
         os.getenv("LIBMEMALLOC_PYTHON") or "python3",
         "-c",
         [[
import errno
import fcntl
import os
import stat
import sys

fd = os.open(sys.argv[1], os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
assert stat.S_ISREG(os.fstat(fd).st_mode), "lease must be a regular file"
mode = fcntl.LOCK_SH if sys.argv[2] == "shared" else fcntl.LOCK_EX
try:
    fcntl.flock(fd, mode | fcntl.LOCK_NB)
except OSError as error:
    if error.errno in (errno.EACCES, errno.EAGAIN):
        sys.exit(75)
    raise
os.set_inheritable(fd, True)
os.execvp(sys.argv[3], sys.argv[3:])
]],
         path,
         mode,
      }
   end

   return exports
end

return LEASE_loadModule()

-- EOF


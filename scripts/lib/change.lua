-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Report actual domain changes to the supervising playbook invocation.
-- @return table: public operations constructed by this module.
local function CHANGE_loadModule()
   local exports = {}

   --- Fingerprint installed entries without counting access times or following
   --- links.
   -- @param paths table: paths selected by the owning operation.
   -- @return any: fingerprint installed entries without counting access times
   -- or following links.
   function exports.snapshot(paths)
      local command = {
         "python3",
         "-S",
         "-c",
         [[
import hashlib
import os
import sys

digest = hashlib.sha256()


def visit(path):
    try:
        info = os.lstat(path)
    except FileNotFoundError:
        digest.update(repr((path, None)).encode())
        return
    digest.update(
        repr((path, info.st_mode, info.st_size, info.st_mtime_ns)).encode()
    )
    if os.path.islink(path):
        digest.update(os.readlink(path).encode())
    elif os.path.isdir(path):
        for name in sorted(os.listdir(path)):
            visit(os.path.join(path, name))


for path in sys.argv[1:]:
    visit(path)
print(digest.hexdigest())
]],
      }

      for _, path in ipairs(paths) do
         command[#command + 1] = path
      end

      return assert(dofile("scripts/lib/platform.lua").command_output(command))
   end

   --- Accumulate changes without altering a standalone command's output.
   -- @param changed any: changed supplied to this operation.
   -- @return nil: no values.
   function exports.record(changed)
      assert(type(changed) == "boolean", "change result must be boolean")
      local path = os.getenv("LIBMEMALLOC_CHANGE_FILE")
      if not path then
         return
      end

      local previous = io.open(path, "rb")
      if previous then
         changed = previous:read("*a") == "true\n" or changed
         assert(previous:close())
      end

      local output = assert(io.open(path, "wb"))

      assert(output:write(tostring(changed) .. "\n"))
      assert(output:close())
   end

   return exports
end

return CHANGE_loadModule()

-- EOF


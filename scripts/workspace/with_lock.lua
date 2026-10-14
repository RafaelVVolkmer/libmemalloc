-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Keep an external build or tool command protected from workspace cleanup.
-- @return nil: no values.
local function WITH_LOCK_main()
   assert(arg[1] == "--" and arg[2], "usage: with_lock.lua -- COMMAND [ARGS]")
   dofile("scripts/workspace/lib/lock.lua").guard("shared")
   local command = {}

   for index = 2, #arg do
      command[#command + 1] = arg[index]
   end

   os.exit(dofile("scripts/lib/platform.lua").execute(command))
end

return WITH_LOCK_main()

-- EOF


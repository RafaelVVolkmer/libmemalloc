-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Wait until Windows containment is installed before executing domain code.
-- @return nil: exits with the child outcome.
local function GATE_main()
   assert(io.read(3) == "go\n", "resource boundary was not installed")
   local command = {}
   for _, value in ipairs(arg) do
      command[#command + 1] = value
   end
   local script = arg[0]:gsub("\\", "/")
   local root = assert(script:match("^(.*)/scripts/process/native/gate.lua$"))
   local exec = dofile(root .. "/scripts/process/lib/exec.lua")
   local result = exec.run(command, {
      detached = false,
      timeout_ms = 86400000,
      on_output = exec.forward_output,
   })
   os.exit(
      result.state == "PASS" and 0
         or result.exit_code > 0 and result.exit_code
         or 125
   )
end

return GATE_main()

-- EOF


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
   local result = dofile(root .. "/scripts/process/lib/exec.lua").run(command, {
      detached = false,
      timeout_ms = 86400000,
      --- Forward accepted output from the contained child.
      -- @param stream string: stdout or stderr.
      -- @param data string: bytes accepted by the executor.
      -- @return nil: callback result is consumed by its owner.
      on_output = function(stream, data)
         assert(io[stream]:write(data))
         assert(io[stream]:flush())
      end,
   })
   os.exit(
      result.state == "PASS" and 0
         or result.exit_code > 0 and result.exit_code
         or 125
   )
end

return GATE_main()

-- EOF


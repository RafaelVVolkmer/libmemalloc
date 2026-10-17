-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Exercise Lua supervision on the actual host operating system.
-- @return nil: raises if any native regression fails.
local function NATIVE_CHECK_main()
   dofile("tests/automation/process/native_supervisor_test.lua")
end

return NATIVE_CHECK_main()

-- EOF


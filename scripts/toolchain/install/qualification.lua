-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Provision the native qualification adapter from its versioned host policy.
-- Part of versioned tool identities and host provisioning.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_toolchain_install_qualification_main()
   dofile("scripts/workspace/lib/lock.lua").guard("shared")
   local release = dofile("scripts/lib/artifacts.lua")
   local policy = dofile("tools/build/qualification-host.lua")

   -- Use the signed repository for the C23-capable GCC package; execution still
   -- rejects a frontend version that differs from the toolchain lock.
   dofile("scripts/toolchain/lib/apt.lua").install(
      release,
      policy.packages,
      policy.repository
   )
   dofile("scripts/lib/change.lua").record(true)
end

return scripts_toolchain_install_qualification_main()

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Publish locked tool identities for workflow consumers.
-- Part of versioned tool identities and host provisioning.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_toolchain_resolve_main()
   local TOOLCHAIN_SHA256_HEX_LENGTH = 64

   local toolchain = dofile("scripts/toolchain/lib/lock.lua")
   local platform = dofile("scripts/lib/platform.lua")
   local path = "tools/toolchain/lock.toml"
   local file = assert(io.open(path, "rb"))
   local raw = assert(file:read("*a"))

   assert(file:close())

   local tools = toolchain.parse(raw)

   if arg[1] == "--field" then
      local name, key = tostring(arg[2]):match("^([%w_]+)%.([%w_]+)$")

      assert(
         name and key and tools[name] and tools[name][key],
         "unknown lock field"
      )

      print(tools[name][key])

      os.exit(0)
   end

   local hash = assert(platform.command_output({ "sha256sum", path }))
   local digest = assert(hash:match("^([a-f0-9]+)"))

   assert(#digest == TOOLCHAIN_SHA256_HEX_LENGTH, "invalid lock digest")

   local output = os.getenv("GITHUB_OUTPUT")
   local handle = output and assert(io.open(output, "ab")) or io.stdout

   assert(handle:write("tools=" .. toolchain.json(tools) .. "\n"))
   assert(handle:write("digest=" .. digest .. "\n"))
   if output then
      assert(handle:close())
   end
end

return scripts_toolchain_resolve_main()

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Verify the isolated behavior owned by this suite.
-- @return nil: no values.
local function QUALITY_CATALOG_TEST_main()
   local lock = dofile("scripts/toolchain/lib/lock.lua").load()

   for name, entry in pairs(dofile("tools/toolchain/quality.lua")) do
      assert(lock[name].version and lock[name].sha256, "unlocked quality tool")
      assert(entry.url:match("^https://"), "unsafe quality origin")
   end

   local hosts = dofile("scripts/toolchain/lib/host.lua")
   local macos = dofile("tools/toolchain/quality_macos.lua")
   for _, architecture in ipairs({ "arm64", "x86_64" }) do
      local host = hosts.resolve("Darwin", architecture)
      local catalog = macos(dofile("tools/toolchain/quality.lua"), architecture)

      for name, tool in pairs(catalog) do
         local digest = hosts.digest(lock[name], host)

         assert(#digest == 64 and digest ~= lock[name].sha256, name)
         assert(not tool.url:find("linux", 1, true), "Linux URL: " .. name)
         assert(not tool.bin:find("linux", 1, true), "Linux bin: " .. name)
         for _, command in pairs(tool.commands) do
            assert(not command:find("linux", 1, true), "Linux command")
         end
      end

      assert(catalog.doxygen.archive == "source", "Doxygen is not native")
      assert(catalog.doxygen.bin == "install/bin", "Doxygen install layout")
      assert(
         catalog.stylua.url:find(
            architecture == "arm64" and "aarch64.zip" or "x86_64.zip",
            1,
            true
         )
      )
   end
   print("Native quality catalog identities passed.")
end

return QUALITY_CATALOG_TEST_main()

-- EOF


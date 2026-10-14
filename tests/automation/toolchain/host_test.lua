-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Reject mismatched native tools before downloading or executing an archive.
-- @return nil: no values.
local function HOST_TEST_main()
   local hosts = dofile("scripts/toolchain/lib/host.lua")
   local lock = dofile("scripts/toolchain/lib/lock.lua").load()
   local linux = hosts.resolve("Linux", "x86_64")

   assert(linux.target == "x86_64-unknown-linux-musl", "changed Linux target")
   assert(hosts.digest(lock.uv, linux) == lock.uv.sha256, "changed Linux hash")
   for _, architecture in ipairs({ "arm64", "x86_64" }) do
      local host = hosts.resolve("Darwin", architecture)
      local expected = architecture == "arm64" and "aarch64-apple-darwin"
         or "x86_64-apple-darwin"

      assert(host.target == expected, "incorrect native architecture")
      assert(hosts.digest(lock.uv, host) ~= lock.uv.sha256, "reused Linux hash")
      assert(
         not pcall(hosts.digest, { sha256 = lock.uv.sha256 }, host),
         "missing native digest accepted"
      )
   end

   for _, target in ipairs({
      { "Linux", "aarch64" },
      { "Darwin", "i386" },
      { "Windows", "x86_64" },
   }) do
      assert(not pcall(hosts.resolve, target[1], target[2]), "unsupported host")
   end

   print("Native tools: Linux, Apple Silicon, Intel and rejected hosts passed.")
end

return HOST_TEST_main()

-- EOF


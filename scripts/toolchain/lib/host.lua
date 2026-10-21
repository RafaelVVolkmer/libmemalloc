-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Select native tool archives without falling back to another architecture.
-- @return table: public operations constructed by this module.
local function HOST_loadModule()
   local exports = {}

   --- Honor the interpreter selected by native Ansible host preparation.
   -- @return any: honor the interpreter selected by native Ansible host
   -- preparation.
   function exports.python()
      return os.getenv("LIBMEMALLOC_PYTHON") or "python3"
   end

   --- Normalize the supported bootstrap hosts and reject unknown targets.
   -- @param system any: system supplied to this operation.
   -- @param architecture any: architecture supplied to this operation.
   -- @return table: the supported bootstrap hosts and reject unknown targets.
   function exports.resolve(system, architecture)
      if system == "Linux" and architecture == "x86_64" then
         return { key = "linux_x86_64", target = "x86_64-unknown-linux-musl" }
      end

      if system == "Darwin" then
         local cpu = ({ arm64 = "aarch64", x86_64 = "x86_64" })[architecture]

         assert(cpu, "unsupported macOS architecture: " .. architecture)

         return {
            key = "macos_" .. architecture,
            target = cpu .. "-apple-darwin",
         }
      end

      error("tool bootstrap requires Linux x86_64 or macOS arm64/x86_64")
   end

   --- Read the native process architecture, including translated shells.
   -- @return any: the native process architecture, including translated shells.
   function exports.current()
      local platform = dofile("scripts/lib/platform.lua")
      local identity = assert(platform.command_output({ "uname", "-sm" }))
      local system, architecture = identity:match("^(%S+) (%S+)")

      return exports.resolve(system, architecture)
   end

   --- Require a separately reviewed archive digest for each native host.
   -- @param identity table: declared source, tool or artifact identity.
   -- @param host table: host supplied to this operation.
   -- @return any: require a separately reviewed archive digest for each native
   -- host.
   function exports.digest(identity, host)
      local key = host.key == "linux_x86_64" and "sha256"
         or host.key .. "_sha256"

      return assert(identity[key], "missing native tool digest: " .. key)
   end

   return exports
end

return HOST_loadModule()

-- EOF


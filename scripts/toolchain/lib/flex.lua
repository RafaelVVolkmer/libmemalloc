-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Build the reviewed scanner generator independently of host package updates.
-- @return table: native generator installation operations.
local function FLEX_loadModule()
   local exports = {}

   --- Verify and build the scanner generator.
   -- @param artifacts table: filesystem and command ports.
   -- @param destination string: owned absolute tool cache directory.
   -- @param identity table: locked version and source archive digest.
   -- @return string: absolute path to the native scanner generator.
   function exports.install(artifacts, destination, identity)
      local source = destination .. "/flex-source"
      local archive = destination .. "/flex.tar.gz"
      artifacts.mkdir(source)
      artifacts.run({
         "curl",
         "--fail",
         "--location",
         "--proto",
         "=https",
         "--proto-redir",
         "=https",
         "--max-time",
         "300",
         "--retry",
         "3",
         "--output",
         archive,
         "https://github.com/westes/flex/releases/download/v"
            .. identity.version
            .. "/flex-"
            .. identity.version
            .. ".tar.gz",
      })
      assert(
         artifacts.digest(archive) == identity.sha256,
         "Flex source hash mismatch"
      )
      artifacts.run({
         "tar",
         "-xf",
         archive,
         "--strip-components=1",
         "-C",
         source,
      })
      artifacts.run({
         "sh",
         "-c",
         'cd "$1" && exec ./configure --disable-nls --disable-libfl',
         "flex-configure",
         source,
      })
      artifacts.run({ "make", "-C", source .. "/src", "-j2", "flex" })
      return source .. "/src/flex"
   end

   return exports
end

return FLEX_loadModule()

-- EOF


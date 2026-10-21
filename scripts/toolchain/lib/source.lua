-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Build native Doxygen from its reviewed source archive on macOS.
-- @return table: public operations constructed by this module.
local function SOURCE_loadModule()
   local exports = {}

   --- Verify the upstream scanner correction before modifying build sources.
   -- @param artifacts table: filesystem and command ports.
   -- @param source string: extracted source directory.
   -- @param identity table: reviewed patch revision and digest.
   -- @return nil: no values.
   local function source_patch(artifacts, source, identity)
      local patch = source .. "/scanner-fix.patch"

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
         patch,
         "https://github.com/doxygen/doxygen/commit/"
            .. identity.revision
            .. ".patch",
      })
      assert(
         artifacts.digest(patch) == identity.sha256,
         "Doxygen scanner patch hash mismatch"
      )
      artifacts.run({ "patch", "-p1", "-d", source, "-i", patch })
   end

   --- Extract already verified sources and install under the tool cache.
   -- @param artifacts table: artifact filesystem and serialization operations.
   -- @param archive any: archive supplied to this operation.
   -- @param destination string: destination path owned by the invoking
   -- operation.
   -- @param identity table: reviewed upstream scanner correction.
   -- @return nil: no values.
   function exports.install(artifacts, archive, destination, identity)
      local source, build = destination .. "/source", destination .. "/build"

      artifacts.mkdir(source)
      artifacts.run({
         "tar",
         "-xf",
         archive,
         "--strip-components=1",
         "-C",
         source,
      })
      source_patch(artifacts, source, identity)
      local configure = {
         "cmake",
         "--fresh",
         "-S",
         source,
         "-B",
         build,
         "-DCMAKE_BUILD_TYPE=Release",
         "-DCMAKE_INSTALL_PREFIX=" .. destination .. "/install",
         "-Dbuild_doc=OFF",
         "-Dbuild_wizard=OFF",
         "-Dbuild_xmlparser=OFF",
      }
      if artifacts.output({ "uname", "-s" }) == "Darwin" then
         for _, name in ipairs({ "bison", "flex" }) do
            local prefix = artifacts.output({ "brew", "--prefix", name })
            configure[#configure + 1] = "-D"
               .. name:upper()
               .. "_EXECUTABLE="
               .. prefix
               .. "/bin/"
               .. name
         end
      end
      artifacts.run(configure)
      artifacts.run({ "cmake", "--build", build, "--parallel", "2" })
      artifacts.run({ "cmake", "--install", build })
   end

   return exports
end

return SOURCE_loadModule()

-- EOF


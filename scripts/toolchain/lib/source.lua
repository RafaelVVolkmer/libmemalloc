-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Build native Doxygen from its reviewed source archive on macOS.
-- @return table: public operations constructed by this module.
local function SOURCE_loadModule()
   local exports = {}

   --- Extract already verified sources and install under the tool cache.
   -- @param artifacts table: artifact filesystem and serialization operations.
   -- @param archive any: archive supplied to this operation.
   -- @param destination string: destination path owned by the invoking
   -- operation.
   -- @return nil: no values.
   function exports.install(artifacts, archive, destination)
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
      artifacts.run({
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
      })
      artifacts.run({ "cmake", "--build", build, "--parallel", "2" })
      artifacts.run({ "cmake", "--install", build })
   end

   return exports
end

return SOURCE_loadModule()

-- EOF


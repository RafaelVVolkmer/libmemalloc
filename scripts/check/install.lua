-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Qualify a relocated installation with consumers outside the source tree.
-- Part of local and CI verification gates.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_check_install_main()
   local release = dofile("scripts/lib/artifacts.lua")
   local repository = release.output({ "git", "rev-parse", "--show-toplevel" })
   local attempt = release.platform.temporary_directory("tests")

   for _, mode in ipairs({ "Release", "Debug" }) do
      for _, shared in ipairs({ "ON", "OFF" }) do
         local directory = attempt .. "/" .. mode .. "-" .. shared
         local prefix = directory .. "/prefix"
         local relocated = directory .. "/relocated"
         local source = directory .. "/consumer-source"

         release.run({
            "cmake",
            "-S",
            repository,
            "-B",
            directory .. "/build",
            "-DLMA_BUILD_MOCK=ON",
            "-DBUILD_SHARED_LIBS=" .. shared,
            "-DCMAKE_BUILD_TYPE=" .. mode,
            "-DCMAKE_INSTALL_LIBDIR=lib",
            "-DCMAKE_INSTALL_PREFIX=" .. prefix,
         })

         release.run({ "cmake", "--build", directory .. "/build" })

         release.run({ "cmake", "--install", directory .. "/build" })

         release.run({ "mv", "--", prefix, relocated })

         release.run({ "cp", "-R", "tests/fixtures/install", source })

         release.write(
            source .. "/main.c",
            release.read(source .. "/main.c.in")
         )

         release.run({
            "cmake",
            "-S",
            source,
            "-B",
            directory .. "/consumer",
            "-DCMAKE_PREFIX_PATH=" .. relocated,
         })

         release.run({ "cmake", "--build", directory .. "/consumer" })

         release.run({ "timeout", "10", directory .. "/consumer/consumer" })

         local flags = release.output({
            "env",
            "PKG_CONFIG_LIBDIR=" .. relocated .. "/lib/pkgconfig",
            "PKG_CONFIG_PATH=",
            "pkg-config",
            "--cflags",
            "--libs",
            "libmemalloc",
         })

         local command =
            { "cc", source .. "/main.c", "-o", directory .. "/pkg-consumer" }

         -- The generated prefix has no whitespace; reject an unexpected token.
         for flag in flags:gmatch("%S+") do
            assert(
               flag:match("^%-[ILl][%w/._%-]+$")
                  or flag == "-DLMA_SHARED_LIBRARY",
               "unexpected pkg-config flag"
            )

            command[#command + 1] = flag
         end

         release.run(command)

         release.run({
            "env",
            "LD_LIBRARY_PATH=" .. relocated .. "/lib",
            "timeout",
            "10",
            directory .. "/pkg-consumer",
         })

         release.run({
            "cc",
            source .. "/main.c",
            "-I" .. relocated .. "/include",
            "-L" .. relocated .. "/lib",
            "-lmemalloc",
            "-o",
            directory .. "/direct-consumer",
         })

         release.run({
            "env",
            "LD_LIBRARY_PATH=" .. relocated .. "/lib",
            "timeout",
            "10",
            directory .. "/direct-consumer",
         })
      end
   end

   print(
      (
         "Installed consumers: four variants passed CMake, "
         .. "pkg-config, and direct linking."
      )
   )

   print("Retained installation evidence: " .. attempt)
end

return scripts_check_install_main()

-- EOF


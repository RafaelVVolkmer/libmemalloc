-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Cross-link a Windows DLL consumer using only the installed pkg-config
--- contract.
-- @return nil: no values.
local function WINDOWS_PKGCONFIG_TEST_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local executor = dofile("scripts/process/lib/exec.lua")
   local compiler = "x86_64-w64-mingw32-gcc"
   if not artifacts.platform.command_exists(compiler) then
      print("Windows pkg-config: SKIP; install the MinGW x86_64 compiler.")

      os.exit(77)
   end

   local root = artifacts.platform.temporary_directory("tests")
   local cmake = os.getenv("LIBMEMALLOC_CMAKE") or "cmake"

   --- Require each cross-tool step to finish without invoking a Windows
   --- runtime.
   -- @param argv table: dense executable-and-arguments sequence; values remain
   -- literal.
   -- @return any: require each cross-tool step to finish without invoking a
   -- Windows runtime.
   local function run(argv)
      local result = executor.run(argv, { timeout_ms = 180000 })

      assert(result.state == "PASS", result.stdout .. result.stderr)

      return result.stdout
   end

   run({
      cmake,
      "-S",
      ".",
      "-B",
      root .. "/build",
      "-G",
      "Ninja",
      "-DCMAKE_SYSTEM_NAME=Windows",
      "-DCMAKE_C_COMPILER=" .. compiler,
      "-DCMAKE_INSTALL_PREFIX=" .. root .. "/install",
      "-DCMAKE_INSTALL_LIBDIR=lib",
      "-DLMA_BUILD_MOCK=ON",
      "-DBUILD_SHARED_LIBS=ON",
      "-DLMA_IPO=OFF",
   })
   run({ cmake, "--build", root .. "/build" })
   run({ cmake, "--install", root .. "/build" })
   run({ "mv", root .. "/install", root .. "/relocated" })
   local flags = run({
      "env",
      "PKG_CONFIG_PATH=",
      "PKG_CONFIG_LIBDIR=" .. root .. "/relocated/lib/pkgconfig",
      "pkg-config",
      "--cflags",
      "--libs",
      "libmemalloc",
   })
   local source = root .. "/consumer.c"

   artifacts.write(source, artifacts.read("tests/fixtures/install/main.c.in"))
   local compile = { compiler, "-c", source, "-o", root .. "/consumer.o" }
   local link =
      { compiler, root .. "/consumer.o", "-o", root .. "/consumer.exe" }

   for flag in flags:gmatch("%S+") do
      compile[#compile + 1] = flag
      link[#link + 1] = flag
   end

   run(compile)
   local undefined =
      run({ "x86_64-w64-mingw32-nm", "-u", root .. "/consumer.o" })

   assert(
      undefined:find("__imp_MOCK_identity", 1, true),
      "consumer did not select dllimport"
   )
   run(link)
   assert(artifacts.exists(root .. "/consumer.exe"))
   artifacts.platform.remove_temporary_directory(root)
   print(
      "Windows pkg-config: relocated DLL import "
         .. "and executable cross-link passed."
   )
end

return WINDOWS_PKGCONFIG_TEST_main()

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Execute the actual README quickstart in an isolated build directory.
-- @return nil: no values.
local function README_TEST_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local executor = dofile("scripts/process/lib/exec.lua")
   local root = artifacts.platform.temporary_directory("tests")
   local cmake = os.getenv("LIBMEMALLOC_CMAKE") or "cmake"
   local bin = cmake:match("^(.*)/cmake$")
   local commands =
      { cmake = cmake, ctest = bin and bin .. "/ctest" or "ctest" }
   local example = assert(
      artifacts.read("README.md"):match(
         "Build and test the current fixture with CMake:%s+```bash\n(.-)\n```"
      ),
      "README quickstart missing"
   )
   local count = 0

   for line in example:gmatch("[^\n]+") do
      local argv = {}

      for word in line:gmatch("%S+") do
         argv[#argv + 1] = word == ".cache/build/example" and root .. "/build"
            or word
      end

      argv[1] = assert(commands[argv[1]], "unsupported quickstart command")
      local result = executor.run(argv, { timeout_ms = 180000 })

      assert(result.state == "PASS", result.stdout .. result.stderr)
      count = count + 1
   end

   assert(count == 3, "quickstart must configure, build and test")
   artifacts.platform.remove_temporary_directory(root)
   print("README quickstart: configure, build and CTest passed.")
end

return README_TEST_main()

-- EOF


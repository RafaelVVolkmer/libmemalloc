-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Run on each native host: cmd quoting failures previously stopped MSVC.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_build_platform_test_suite_main()
   local P = dofile("scripts/lib/platform.lua")
   local root =
      assert(P.command_output({ "git", "rev-parse", "--show-toplevel" }))

   assert(root:find("libmemalloc", 1, true), "repository path was not captured")
   assert(
      P.command_succeeded({ "git", "rev-parse", "--is-inside-work-tree" }),
      "quoted executable and arguments failed"
   )
   assert(not P.command_succeeded({
      "git",
      "rev-parse",
      "--verify",
      "refs/absent/test",
   }), "nonzero process exit was accepted")
   assert(
      P.command_output({ "git", "rev-parse", "--verify", "refs/absent/test" })
         == nil,
      "failed output capture was accepted"
   )

   local echoed = assert(
      P.command_output({ "git", "-c", "user.name=a b", "config", "user.name" })
   )

   assert(
      echoed:gsub("[\r\n]+$", "") == "a b",
      "quoted arguments with spaces changed"
   )

   local interpreter = os.getenv("LIBMEMALLOC_LUA") or arg[-1] or "lua"

   assert(
      P.execute({ interpreter, "-e", "os.exit(7)" }) == 7,
      "native child exit code was lost"
   )
   assert(
      P.execute({ interpreter, "-e", "os.exit(0)" }) == 0,
      "successful native child failed"
   )

   local directory = P.temporary_directory("tests")
   local path = directory .. "/file with spaces.txt"
   local handle = assert(io.open(path, "wb"))

   assert(handle:write("temporary input\n"))
   assert(handle:close())
   P.remove_temporary_directory(directory)
   assert(not io.open(path, "rb"), "temporary directory was not removed")
   assert(
      not pcall(P.remove_temporary_directory, directory),
      "cleanup accepted an unowned directory"
   )

   for _, invalid in ipairs({ 0, -1, 0.5, math.huge, "64" }) do
      assert(
         not pcall(P.run_batched, { interpreter }, {}, invalid),
         "invalid batch size was accepted"
      )
      assert(
         not pcall(
            P.run_batched_in_directory,
            ".",
            { interpreter },
            {},
            invalid
         ),
         "invalid directory batch size was accepted"
      )
   end

   print("Platform quoting, cleanup and failure propagation passed.")
end

return tests_build_platform_test_suite_main()

-- EOF


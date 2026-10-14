-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Verify retained task logs and machine reports for success and failure.
-- Uses real child processes, including a deadline exceeded by a sleeping child.

--- Require distinct reports, preserved exit codes and JUnit failure records.
-- @return nil: no values.
local function TASK_TEST_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local runner = dofile("scripts/process/lib/tasks.lua")
   local interpreter = arg[-1] or "lua"
   local cases = {
      {
         name = "supervisor-pass",
         source = "print('literal output')",
         state = "PASS",
         exit_code = 0,
      },
      {
         name = "supervisor-fail",
         source = "io.stderr:write('failure'); os.exit(7)",
         diagnostic = "failure",
         state = "FAIL",
         exit_code = 7,
      },
      {
         name = "supervisor-unicode",
         source = "io.stderr:write(string.rep(utf8.char(0x20ac), 2000)); "
            .. "os.exit(7)",
         diagnostic = string.rep(utf8.char(0x20ac), 1365),
         state = "FAIL",
         exit_code = 7,
      },
      {
         name = "supervisor-binary",
         source = "io.stderr:write(string.char(255)); os.exit(7)",
         diagnostic = "[non-UTF-8 output; inspect retained log]",
         state = "FAIL",
         exit_code = 7,
      },
      {
         name = "supervisor-timeout",
         source = "require('luv').sleep(3000)",
         state = "TIMEOUT",
      },
      {
         name = "supervisor-unknown",
         source = "print('mutation outcome unavailable')",
         state = "PASS",
         exit_code = 0,
         change_status = "unknown",
      },
      {
         name = "supervisor-partial",
         source = "dofile('scripts/lib/change.lua').record(false); os.exit(7)",
         state = "FAIL",
         exit_code = 7,
         change_status = "unknown",
      },
      {
         name = "supervisor-unchanged",
         source = "dofile('scripts/lib/change.lua').record(false)",
         state = "PASS",
         exit_code = 0,
         change_status = "unchanged",
      },
      {
         name = "supervisor-changed",
         source = "local c = dofile('scripts/lib/change.lua'); "
            .. "c.record(true); c.record(false)",
         state = "PASS",
         exit_code = 0,
         change_status = "changed",
      },
   }

   for _, case in ipairs(cases) do
      local passed, directory = runner.run(case.name, {
         command = { "-e", case.source },
         effects = case.change_status and "workspace" or "read",
         timeout_seconds = 1,
      }, {}, interpreter)

      assert(
         passed == (case.state == "PASS"),
         "task success differs from its recorded state"
      )
      assert(
         artifacts.query(directory .. "/result.json", ".state") == case.state,
         "JSON lost the execution state"
      )
      if case.exit_code then
         assert(
            tonumber(artifacts.query(directory .. "/result.json", ".exit_code"))
               == case.exit_code,
            "JSON lost the child exit code"
         )
      end

      local junit = artifacts.read(directory .. "/junit.xml")

      assert(
         (junit:find("<failure ", 1, true) ~= nil) == not passed,
         "JUnit failure disagrees with task outcome"
      )
      assert(artifacts.exists(directory .. "/stdout.log"))
      assert(artifacts.exists(directory .. "/stderr.log"))
      if case.diagnostic then
         assert(
            artifacts.query(directory .. "/result.json", ".stderr_tail")
               == case.diagnostic,
            "JSON omitted the child failure diagnostic"
         )
      end

      if case.change_status then
         assert(
            artifacts.query(directory .. "/result.json", ".change_status")
               == case.change_status,
            "reported mutation state differs"
         )
      end
   end

   --- Detect installed state changes while ignoring reads and external symlink
   --- targets.
   -- @return nil: no values.
   local function task_test_snapshot()
      local change = dofile("scripts/lib/change.lua")
      local root = artifacts.platform.temporary_directory("tests")
      local products = { root .. "/installed" }
      local empty = change.snapshot(products)

      artifacts.write(products[1] .. "/package", "version one\n")
      artifacts.write(root .. "/external", "external\n")
      assert(
         require("luv").fs_symlink(root .. "/external", products[1] .. "/link")
      )
      local before = change.snapshot(products)

      assert(before ~= empty, "installation was not detected")
      artifacts.read(products[1] .. "/package")
      artifacts.write(root .. "/external", "external target changed\n")
      assert(
         change.snapshot(products) == before,
         "read or external change counted as installation"
      )
      artifacts.write(products[1] .. "/package", "version two has changed\n")
      assert(
         change.snapshot(products) ~= before,
         "package update was not detected"
      )
      artifacts.platform.remove_temporary_directory(root)
   end

   task_test_snapshot()
   print(
      "Task supervisor: "
         .. #cases
         .. " retained-result cases and installation snapshots passed."
   )
end

return TASK_TEST_main()

-- EOF


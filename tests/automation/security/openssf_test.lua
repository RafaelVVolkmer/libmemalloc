-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Reject missing, foreign and unqualified integration reports.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_security_openssf_test_suite_main()
   local R = dofile("scripts/lib/artifacts.lua")
   local T = dofile("scripts/reproducible/lib/context.lua")
   local projects = dofile("tools/security/openssf/projects.lua")
   local directory = R.platform.temporary_directory("tests")
   local relative = directory:sub(#R.output({ "pwd" }) + 2)
   local input = relative .. "/input"
   local blocked, executable, count = nil, nil, 0

   --- Exercise security adapter evidence inside an owned temporary tree.
   -- @return nil: no values.
   local success, message = xpcall(function()
      for name, project in pairs(projects) do
         count = count + 1

         local state = project.mode == "blocked" and "BLOCKED" or "PASS"

         if state == "BLOCKED" then
            blocked = name
         else
            executable = name
         end

         R.document(input .. "/openssf-" .. name .. "/result.json", {
            project = name,
            state = state,
            detail = project.reason or "fixture",
         })
      end

      assert(blocked and executable, "fixture requires both adapter categories")

      --- Compare one adapter result with its expected project outcome.
      -- @param id string: stable identity used to match the requested entry.
      -- @param project any: project supplied to this operation.
      -- @param expected any: expected reference value used by this check.
      -- @return nil: no values.
      local function check(id, project, expected)
         local output = relative .. "/" .. id
         local code = T.status({
            "lua",
            "scripts/security/report.lua",
            "--input=" .. input,
            "--output=" .. output,
         }, directory .. "/" .. id .. ".log")

         assert(code ~= 0, "incomplete integration passed")

         local file = output .. "/coverage.json"

         assert(
            R.query(file, ".complete | tostring") == "false",
            "incomplete coverage reported completion"
         )
         assert(
            tonumber(R.query(file, ".projects | length")) == count,
            "coverage report omitted a catalog entry"
         )
         assert(
            R.query(
               file,
               '.projects[] | select(.project == "' .. project .. '") | .state'
            ) == expected,
            "coverage report used the wrong failure state"
         )
      end

      check("blocked", blocked, "BLOCKED")

      local missing = input .. "/openssf-" .. executable .. "/result.json"

      assert(os.rename(missing, missing .. ".held"))
      check("missing", executable, "INFRA_ERROR")
      assert(os.rename(missing .. ".held", missing))

      R.document(missing, { project = "foreign", state = "PASS" })
      check("foreign", executable, "INFRA_ERROR")

      R.document(input .. "/openssf-" .. blocked .. "/result.json", {
         project = blocked,
         state = "PASS",
         detail = "false success",
      })
      check("false-success", blocked, "INFRA_ERROR")
   end, debug.traceback)

   R.platform.remove_temporary_directory(directory)
   assert(success, message)

   print(
      "OpenSSF rejects blocked, missing, foreign and false-success evidence."
   )
end

return tests_security_openssf_test_suite_main()

-- EOF


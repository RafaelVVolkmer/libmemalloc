-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Run self-contained suites and retain bounded per-suite execution evidence.
-- @return nil: no values.
local function AUTOMATION_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local executor = dofile("scripts/process/lib/exec.lua")
   local runner = dofile("scripts/check/lib/automation.lua")
   local catalog = dofile("tools/testing/suites.lua")
   local uv = require("luv")
   local executable = os.getenv("LIBMEMALLOC_LUA") or arg[-1] or "lua"
   local node = os.getenv("LIBMEMALLOC_NODE") or "node"
   local AUTOMATION_SUITE_ROOT = "tests/automation/"
   local AUTOMATION_TYPESCRIPT =
      ".cache/tools/web/node_modules/typescript/bin/tsc"
   local AUTOMATION_TSC_CONFIG = "tools/lint/code/web/tsconfig.json"

   assert(#arg == 0, "tests accepts no arguments")

   --- Reject duplicate or absent suite registrations before starting execution.
   -- @return nil: no values.
   local function automation_validateInventory()
      local registered = {}

      for _, list in ipairs({ catalog.lua, catalog.node }) do
         for _, path in ipairs(list) do
            assert(not registered[path], "duplicate suite: " .. path)
            registered[path] = true
         end
      end

      for path, reason in pairs(catalog.domain) do
         assert(not registered[path] and #reason > 0, "invalid domain suite")
         registered[path] = true
      end

      local git = dofile("scripts/lib/git.lua").new(artifacts.platform, ".")

      for _, path in ipairs(assert(git.working_files())) do
         local suite = path:match("^tests/automation/(.+_test%.[%w]+)$")

         if suite then
            assert(
               registered[suite],
               "unregistered automation suite: " .. suite
            )
            registered[suite] = nil
         end
      end

      local missing = {}

      for path in pairs(registered) do
         missing[#missing + 1] = path
      end

      table.sort(missing)
      assert(
         #missing == 0,
         "registered suites missing: " .. table.concat(missing, ", ")
      )
   end

   automation_validateInventory()

   local root = artifacts.platform.temporary_directory("logs")
   local web_root = root .. "/web"
   local environment = uv.os_environ()
   local names, env = {}, {}

   environment.LIBMEMALLOC_WEB_ASSET = web_root .. "/webmcp.js"
   environment.LIBMEMALLOC_NAVIGATION_ASSET = web_root .. "/navigation.js"

   for name in pairs(environment) do
      names[#names + 1] = name
   end

   table.sort(names)

   for _, name in ipairs(names) do
      env[#env + 1] = name .. "=" .. environment[name]
   end

   local plan = {
      lua = {},
      node = {},
      compiler = {
         name = "typescript-compile",
         argv = {
            node,
            AUTOMATION_TYPESCRIPT,
            "--project",
            AUTOMATION_TSC_CONFIG,
            "--outDir",
            web_root,
         },
         timeout_ms = catalog.execution.compile_timeout_ms,
      },
   }

   --- Append catalog entries in their declared order with bounded execution.
   -- @param suites table: ordered repository-relative suite names.
   -- @param entries table: destination plan owned by this command.
   -- @param interpreter string: executable selected by the runtime owner.
   -- @param child_env table|nil: explicit environment for fresh web assets.
   -- @return nil: no values.
   local function automation_plan(suites, entries, interpreter, child_env)
      for _, suite in ipairs(suites) do
         entries[#entries + 1] = {
            name = suite,
            argv = { interpreter, AUTOMATION_SUITE_ROOT .. suite },
            timeout_ms = catalog.execution.suite_timeout_ms,
            env = child_env,
         }
      end
   end

   automation_plan(catalog.lua, plan.lua, executable)
   automation_plan(catalog.node, plan.node, node, env)

   --- Persist stdout, stderr and status before continuing to the next suite.
   -- @param row table: runner result; stream bytes are consumed here.
   -- @return nil: no values.
   local function automation_record(row)
      local prefix = root .. "/" .. artifacts.safe_path(row.name)

      if row.stdout then
         artifacts.write(prefix .. ".stdout.log", row.stdout)
         artifacts.write(prefix .. ".stderr.log", row.stderr)
         row.stdout, row.stderr = nil, nil
         row.stdout_log = prefix .. ".stdout.log"
         row.stderr_log = prefix .. ".stderr.log"
      end

      artifacts.write(prefix .. ".json", artifacts.text_json(row) .. "\n")
      print(
         string.format(
            "Automation: %s %s (%.1f ms)",
            row.state,
            row.name,
            row.duration_ms
         )
      )
   end

   print("Automation evidence: " .. root)

   local report = runner.run(plan, {
      run = executor.run,
      clock = uv.hrtime,
      record = automation_record,
   }, catalog.execution.max_output_bytes)

   report.results = artifacts.array(report.results)
   report.failures = artifacts.array(report.failures)
   report.blocked = artifacts.array(report.blocked)

   artifacts.write(root .. "/report.json", artifacts.text_json(report) .. "\n")
   print(
      string.format(
         "Automation: %d suites; %d failures; %d blocked.",
         #catalog.lua + #catalog.node,
         #report.failures,
         #report.blocked
      )
   )
   print("Failed: " .. table.concat(report.failures, ", "))
   print("Blocked: " .. table.concat(report.blocked, ", "))
   print("Report: " .. root .. "/report.json")

   os.exit(report.state == "PASS" and 0 or 1)
end

return AUTOMATION_main()

-- EOF


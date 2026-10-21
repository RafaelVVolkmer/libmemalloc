-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Exercise formal controllers through the official supervisor and dispatcher.
-- @return nil: no values.
local function FORMAL_EXECUTOR_TEST_main()
   local ioTools = dofile("scripts/process/lib/io.lua")
   local files = dofile("scripts/verification/lib/files.lua")
   local runner = dofile("scripts/process/lib/tasks.lua")
   local lua = os.getenv("LIBMEMALLOC_LUA") or arg[-1] or "lua"
   local root = ".cache/tests/formal-executor-" .. tostring(ioTools.uv.hrtime())
   local directories = { "mkdir", "-p", root, ".cache/formal" }
   assert(
      ioTools.exec.run(directories).state == "PASS",
      "cannot create executor fixtures"
   )
   local probe = root .. "/controller.lua"
   files.write(
      probe,
      [[
local resources = dofile("scripts/verification/lib/resources.lua")
local file = assert(io.open("/proc/self/cgroup"))
local own = assert(
   file:read("*a"):match("/(libmemalloc%-verification%-[%w%-]+%.scope)\n")
)
file:close()
local child = resources.run({ "/bin/true" })
assert(child.state == "PASS", child.stderr)
assert(
   child.resources.parent_scope == own,
   "child escaped controller lifecycle"
)
local directory =
   assert(os.getenv("LIBMEMALLOC_TASK_DIRECTORY"), "task environment missing")
local report =
   dofile("scripts/process/lib/io.lua").load(directory .. "/result.json")
assert(
   report.state == "INCOMPLETE" and report.resource_profile == "formal",
   "initial receipt missing"
)
print(own)
]]
   )
   local passed, directory, report = runner.run("formal-controller-probe", {
      command = { probe },
      resource_profile = "formal",
      effects = "read",
      timeout_seconds = 20,
   }, {}, lua)
   assert(passed, files.read(directory .. "/stderr.log"))
   assert(
      files.read(directory .. "/stdout.log") == report.resources.scope .. "\n",
      "controller ran outside its recorded scope"
   )
   assert(
      report.resource_profile == "formal" and report.resources.cpu_max,
      "missing resource receipt"
   )

   local lockProbe = root .. "/lease.lua"
   files.write(
      lockProbe,
      [[
local uv = require("luv")
local exec = dofile("scripts/process/lib/exec.lua")
dofile("scripts/verification/lib/lock.lua").guard()
if arg[1] == "hold" then
   local other = exec.run({ arg[-1], arg[0], "probe" })
   assert(other.exit_code == 75, other.stderr)
   print("live owner rejected competing campaign")
   io.stdout:flush()
   uv.sleep(10000)
else
   print("kernel lease acquired")
end
]]
   )
   local task = {
      command = { lockProbe },
      resource_profile = "formal",
      effects = "read",
      timeout_seconds = 2,
   }
   local held, heldDirectory, expired =
      runner.run("formal-lease-timeout", task, { "hold" }, lua)
   assert(not held and expired.state == "TIMEOUT", expired.state)
   assert(
      files
         .read(heldDirectory .. "/stdout.log")
         :find("live owner rejected", 1, true)
   )
   task.timeout_seconds = 20
   local recovered, recoveryDirectory =
      runner.run("formal-lease-recovery", task, { "probe" }, lua)
   assert(recovered, files.read(recoveryDirectory .. "/stderr.log"))
   assert(
      files
         .read(recoveryDirectory .. "/stdout.log")
         :find("kernel lease acquired", 1, true)
   )

   --- Exercise actual registered tasks in each dispatcher mode.
   -- @return nil: no values.
   local function checkDispatch()
      for index, mode in ipairs({ "normal", "--direct", "--result-json" }) do
         local id = "executor-"
            .. tostring(ioTools.uv.hrtime()):gsub("%.0$", "")
            .. "-"
            .. index
         local command = { lua, "scripts/process/playbook.lua" }
         if mode ~= "normal" then
            command[#command + 1] = mode
         end
         for _, value in ipairs({
            "formal-start",
            "--run-id=" .. id,
         }) do
            command[#command + 1] = value
         end
         local result = ioTools.exec.run(command, { timeout_ms = 30000 })
         assert(result.state == "PASS", result.stderr .. result.stdout)
         if mode == "--result-json" then
            local receipt = ioTools.decode(result.stdout)
            assert(
               receipt.state == "PASS" and receipt.resource_profile == "formal",
               "JSON dispatch lost the formal profile"
            )
            assert(
               receipt.resources.scope and receipt.resources.cpu_max,
               "JSON dispatch lost resource limits"
            )
         elseif mode == "--direct" then
            assert(result.stdout:find("Formal stage start:", 1, true))
            assert(
               not result.stdout:find("Task formal-start:", 1, true),
               "direct output contains supervisor decoration"
            )
         else
            assert(result.stdout:find("Task formal-start: PASS", 1, true))
         end
         command[#command] = "--run-id=../invalid"
         local invalid = ioTools.exec.run(command, { timeout_ms = 30000 })
         assert(
            invalid.state == "FAIL",
            "dispatcher hid invalid campaign failure"
         )
      end
   end
   checkDispatch()
   local lifecycle = ioTools.exec.run({
      "env",
      "LIBMEMALLOC_TEST_FORMAL=1",
      os.getenv("LIBMEMALLOC_LUA") or require("luv").exepath(),
      "tests/automation/process/native_supervisor_test.lua",
      "--formal-owner",
   }, { timeout_ms = 30000 })
   assert(lifecycle.state == "PASS", lifecycle.stdout .. lifecycle.stderr)
   for _, source in ipairs({
      "local "
         .. "f=assert(io.open(os.getenv('LIBMEMALLOC_CH"
         .. "ANGE_FILE'),'w')); f:write('invalid'); f:c"
         .. "lose()",
      "dofile('scripts/lib/platform.lua').execute"
         .. "({'mkfifo',os.getenv('LIBMEMALLOC_CHANGE_F"
         .. "ILE')})",
   }) do
      local valid, invalidDirectory, invalid = runner.run(
         "formal-invalid-change",
         {
            command = { "-e", source },
            resource_profile = "formal",
            effects = "workspace",
            timeout_seconds = 10,
         },
         {},
         lua
      )
      assert(
         not valid and invalid.state == "INFRA_ERROR" and invalid.change_error,
         "invalid mutation marker escaped infrastructure classification"
      )
      assert(ioTools.uv.fs_unlink(invalidDirectory .. "/changed"))
   end
   print(
      "Formal executor: controller containment, dispatch modes "
         .. "and kernel lease recovery passed."
   )
end

return FORMAL_EXECUTOR_TEST_main()

-- EOF


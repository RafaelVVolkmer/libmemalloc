-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Exercise real resource limits and supervisor death on each supported host.
-- @return nil: raises if a resource or receipt boundary fails.
local function NATIVE_TEST_main()
   local uv = require("luv")
   local files = dofile("scripts/verification/lib/files.lua")
   local runner = dofile("scripts/process/lib/tasks.lua")
   local resources = dofile("scripts/process/native/resources.lua")
   local lua = uv.exepath()
   if not uv.fs_stat(".cache/tmp") then
      assert(uv.fs_mkdir(".cache/tmp", 448))
   end
   local root = assert(uv.fs_mkdtemp(".cache/tmp/native-lua-XXXXXX"))
   local sequence = 0

   --- Execute one bounded Lua fixture through the official task runner.
   -- @param source string: fixture source text.
   -- @param timeout number|nil: task deadline in seconds.
   -- @return table: retained task report.
   local function run(source, timeout)
      sequence = sequence + 1
      local path = root .. "/fixture-" .. tostring(sequence) .. ".lua"
      files.write(path, source)
      local _, _, report = runner.run("native-probe", {
         command = { path },
         effects = "workspace",
         timeout_seconds = timeout or 10,
         resource_profile = "standard",
      }, {}, lua, { json = true })
      assert(
         uv.fs_stat(report.directory .. "/result.json"),
         "missing JSON receipt"
      )
      assert(
         uv.fs_stat(report.directory .. "/junit.xml"),
         "missing JUnit receipt"
      )
      return report
   end

   --- Wait with a deadline while allowing libuv to reap fixture processes.
   -- @param predicate function: true when the expected observation appears.
   -- @param milliseconds number: finite observation budget.
   -- @return nil: no values.
   local function wait_for(predicate, milliseconds)
      local deadline = uv.hrtime() + milliseconds * 1000000
      repeat
         uv.run("nowait")
         if predicate() then
            return
         end
         uv.sleep(10)
      until uv.hrtime() >= deadline
      error("native fixture observation timed out")
   end

   --- Kill the invoking Lua controller and require its descendants to stop.
   -- @param profile string: ordinary or formal task resource profile.
   -- @return nil: no values.
   local function owner_death(profile)
      local pulse, child, driver =
         root .. "/pulse-" .. profile,
         root .. "/pulse.lua",
         root .. "/driver.lua"
      files.write(
         child,
         "local uv=require('luv'); print('ready'); "
            .. "io.stdout:flush(); while true do local "
            .. "f=assert(io.open(arg[1],'w')); "
            .. "f:write(tostring(uv.hrtime())); f:close(); uv.sleep(40) end"
      )
      files.write(
         driver,
         string.format(
            "dofile('scripts/process/lib/tasks.lua').ru"
               .. "n('native-owner-probe',{command={%q,%q},ef"
               .. "fects='read',resource_profile=%q,timeout_s"
               .. "econds=25},{},%q)",
            child,
            pulse,
            profile,
            lua
         )
      )
      local exited = false
      local handle
      handle = assert(uv.spawn(
         lua,
         { args = { driver }, detached = true, stdio = { nil, nil, nil } },
         --- Reap the terminated fixture controller.
         -- @return nil: callback result is consumed by its owner.
         function()
            exited = true
            handle:close()
         end
      ))
      --- Check live receipts and cleanup after controller death.
      -- @return nil: callback result is consumed by its owner.
      local ok, failure = pcall(function()
         --- Wait for the fixture heartbeat without accepting early exit.
         -- @return any: observed condition, truthy when ready.
         wait_for(function()
            assert(not exited, "owner exited before pulse")
            return uv.fs_stat(pulse)
         end, 15000)
         local receipt
         local scan = assert(uv.fs_scandir(".cache/logs/tasks"))
         while true do
            local name = uv.fs_scandir_next(scan)
            if not name then
               break
            end
            if name:match("^native%-owner%-probe%-") then
               local path = ".cache/logs/tasks/" .. name .. "/result.json"
               local value = files.read(path)
               if value:find(pulse, 1, true) then
                  receipt = path
               end
            end
         end
         assert(receipt, "missing initial owner receipt")
         assert(files.read(receipt):find('"INCOMPLETE"', 1, true))
         local log = receipt:gsub("result.json$", "stdout.log")
         --- Observe live output before terminating its controller.
         -- @return any: observed condition, truthy when ready.
         wait_for(function()
            return files.read(log):find("ready", 1, true)
         end, 2000)
         handle:kill(9)
         --- Wait for the killed controller to be reaped.
         -- @return any: observed condition, truthy when ready.
         wait_for(function()
            return exited
         end, 5000)
         uv.sleep(2500)
         local before = files.read(pulse)
         uv.sleep(400)
         assert(
            files.read(pulse) == before,
            "orphan task survived controller death"
         )
         assert(
            files.read(receipt):find('"INCOMPLETE"', 1, true),
            "dead controller fabricated a final receipt"
         )
      end)
      if not exited then
         handle:kill(9)
         --- Confirm controller cleanup after a failed assertion.
         -- @return any: observed condition, truthy when ready.
         wait_for(function()
            return exited
         end, 5000)
      end
      assert(ok, failure)
   end

   if arg[1] == "--formal-owner" then
      owner_death("formal")
      return
   end
   --- Check receipts, output and mutation markers with bounded fixtures.
   -- @return nil: no values.
   local function receipt_checks()
      local passed = run("print('spaces ; $HOME `literal`')")
      assert(
         passed.state == "PASS" and passed.resources.backend,
         "missing successful resource receipt"
      )
      assert(
         files
            .read(passed.directory .. "/stdout.log")
            :find("spaces ; $HOME `literal`", 1, true)
      )
      local failed = run("io.stderr:write('failure\\n'); os.exit(7)")
      assert(
         failed.state == "FAIL"
            and failed.exit_code == 7
            and failed.stderr_tail == "failure\n",
         "ordinary failure was not preserved"
      )
      assert(
         run("require('luv').sleep(30000)", 1).state == "TIMEOUT",
         "deadline not enforced"
      )
      local output =
         run("for i=1,144 do io.stdout:write(string.rep('x',65536)) end")
      assert(output.state == "OUTPUT_LIMIT", "excess output was accepted")
      assert(
         uv.fs_stat(output.directory .. "/stdout.log").size <= 8 * 1024 * 1024,
         "retained output exceeded its cap"
      )
      --- Reject malformed or special mutation markers and accept exact
      -- booleans.
      -- @return nil: no values.
      local function markers()
         for _, value in ipairs({ "bad", "true\nignored", "" }) do
            local report = run(
               string.format(
                  "local "
                     .. "f=assert(io.open(os.getenv('LIBMEMALLOC_CH"
                     .. "ANGE_FILE'),'w'));f:write(%q);f:close()",
                  value
               )
            )
            assert(
               report.state == "INFRA_ERROR"
                  and report.change_status == "unknown",
               "invalid marker accepted"
            )
         end
         for _, value in ipairs({ "true\n", "false\n" }) do
            local report = run(
               string.format(
                  "local "
                     .. "f=assert(io.open(os.getenv('LIBMEMALLOC_CH"
                     .. "ANGE_FILE'),'w'));f:write(%q);f:close()",
                  value
               )
            )
            assert(
               report.state == "PASS"
                  and report.change_status
                     == (value == "true\n" and "changed" or "unchanged"),
               "valid change marker lost"
            )
         end
         assert(
            run(
               "assert(require('luv').fs_mkdir(os.getenv('"
                  .. "LIBMEMALLOC_CHANGE_FILE'),448))"
            ).state == "INFRA_ERROR",
            "special change marker accepted"
         )
         if uv.os_uname().sysname ~= "Windows_NT" then
            assert(
               run(
                  "dofile('scripts/lib/platform.lua').run({'m"
                     .. "kfifo',os.getenv('LIBMEMALLOC_CHANGE_FILE'"
                     .. ")})"
               ).state == "INFRA_ERROR",
               "special change marker accepted"
            )
            assert(
               run(
                  "local p=os.getenv('LIBMEMALLOC_CHANGE_FILE'); local "
                     .. "f=assert(io.open(p..'.target','w'));f:writ"
                     .. "e('true\\n');f:close();assert(require('luv"
                     .. "').fs_symlink(p..'.target',p))"
               ).state == "INFRA_ERROR",
               "special change marker accepted"
            )
         end
      end
      markers()
   end
   receipt_checks()
   local memory = resources.run({
      lua,
      "-e",
      "local x={};for i=1,128 do "
         .. "x[i]=string.rep('x',1024*1024);require('luv').sleep(20) end",
   }, { memory_bytes = 64 * 1024 * 1024, timeout_ms = 15000 })
   assert(memory.state ~= "PASS", "memory ceiling did not stop allocation")
   assert(run("print('recovered')").state == "PASS", "resource recovery failed")
   local nested = root .. "/directory with spaces"
   assert(uv.fs_mkdir(nested, 448))
   local relocated = resources.run({
      lua,
      "-e",
      "assert(require('luv').cwd():match('directory with spaces$'))",
   }, { cwd = nested, timeout_ms = 10000 })
   assert(
      relocated.state == "PASS",
      "guardian did not preserve the child working directory: "
         .. relocated.stderr
   )
   owner_death("standard")
   print(
      "Native Lua supervision: receipts, output, markers, memory, "
         .. "recovery and owner death passed."
   )
end

return NATIVE_TEST_main()

-- EOF


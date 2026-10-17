-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Verify task descriptions, argument boundaries and dispatch outcomes.
-- Inject the supervisor so no task writes files or calls external services.

--- Exercise each registered contract through the production dispatcher.
-- @return nil: no values.
local function PLAYBOOK_TEST_main()
   local tasks = dofile("tools/process/playbook.lua")
   local count = 0

   for name, task in pairs(tasks) do
      assert(loadfile(task.command[1]), "missing command: " .. name)
      assert(
         type(task.description) == "string" and #task.description > 10,
         "task lacks a useful description"
      )
      assert(
         task.effects == "read"
            or task.effects == "workspace"
            or task.effects == "remote",
         "unknown task effect"
      )
      assert(
         task.timeout_seconds > 0 and task.simulation == "plan",
         "missing deadline or simulation contract"
      )
      assert(type(task.dependencies) == "table", "missing dependency inventory")

      local captured, expected = nil, 0
      local environment = setmetatable({
         arg = {
            [1] = name,
            [2] = "--output=path with spaces",
            [-1] = "pinned-lua",
         },
         os = {
            --- Keep runtime discovery independent of the test host.
            -- @return nil: keep runtime discovery independent of the test host.
            getenv = function()
               return nil
            end,
            --- Preserve child failure status at the CLI boundary.
            -- @param code any: code supplied to this operation.
            -- @return nil: no values.
            exit = function(code)
               assert(code == expected, "dispatcher hid the child outcome")
            end,
         },
         --- Replace the executor while keeping metadata and JSON real.
         -- @param path string: filesystem path selected by the caller.
         -- @return any: replace the executor while keeping metadata and JSON
         -- real.
         dofile = function(path)
            if path == "scripts/workspace/lib/lock.lua" then
               --- Omit supervisor locking in this isolated argument fixture.
               -- @return nil: no values.
               return { guard = function() end }
            end

            if path == "scripts/process/lib/tasks.lua" then
               return {
                  --- Capture all argument boundaries and inject the outcome.
                  -- @param selected any: selected supplied to this operation.
                  -- @param record table: structured record supplied by the
                  -- caller.
                  -- @param arguments table: ordered arguments for the selected
                  -- operation.
                  -- @param interpreter string: Lua or host interpreter selected
                  -- by the runtime owner.
                  -- @return boolean: all argument boundaries and inject the
                  -- outcome.
                  run = function(selected, record, arguments, interpreter)
                     captured = { selected, record, arguments, interpreter }

                     return expected == 0
                  end,
               }
            end

            return dofile(path)
         end,
      }, {
         __index = {
            assert = assert,
            ipairs = ipairs,
            pairs = pairs,
            next = next,
            type = type,
            pcall = pcall,
            table = table,
            tostring = tostring,
            print = print,
         },
      })
      local command =
         assert(loadfile("scripts/process/playbook.lua", "t", environment))

      command()
      assert(captured, "dispatcher did not invoke the supervisor")
      assert(
         captured[1] == name and captured[2].command[1] == task.command[1],
         "dispatcher changed command identity"
      )
      assert(
         captured[3][1] == "--output=path with spaces",
         "dispatcher changed argument boundaries"
      )
      assert(captured[4] == "pinned-lua", "dispatcher ignored the interpreter")
      expected = 1
      command()
      environment.arg = { "unknown-task" }
      assert(not pcall(command), "unknown task accepted")

      --- Exercise hosted dispatch with exact argv and native failure codes.
      -- @return nil: no values.
      local function playbook_test_direct()
         local original_dofile = environment.dofile
         local literal = "--value=spaces $HOME `literal` ; & quotes'\""

         --- Intercept process ports without replacing the real serialization
         -- code.
         -- @param path string: filesystem path selected by the caller.
         -- @return any: intercept process ports without replacing the real
         -- serialization code.
         environment.dofile = function(path)
            if path == "scripts/workspace/lib/lock.lua" then
               --- Omit supervisor locking while testing literal argument
               -- forwarding.
               -- @return nil: no values.
               return { guard = function() end }
            end

            local module = original_dofile(path)

            if path == "scripts/lib/artifacts.lua" then
               --- Capture literal child arguments without running a process.
               -- @param arguments table: ordered arguments for the selected
               -- operation.
               -- @return any: literal child arguments without running a
               -- process.
               module.platform.execute = function(arguments)
                  captured = arguments

                  return expected
               end
            end

            return module
         end
         environment.arg = {
            [1] = "--direct",
            [2] = name,
            [3] = literal,
            [-1] = "pinned-lua",
         }

         for _, code in ipairs({ 0, 7 }) do
            expected, captured = code, nil
            command()
            assert(captured[1] == "pinned-lua", "direct runtime changed")

            for index, value in ipairs(task.command) do
               assert(captured[index + 1] == value, "direct prefix changed")
            end

            assert(captured[#captured] == literal, "direct argument changed")
         end

         environment.arg = { "--direct", "unknown-task" }
         assert(not pcall(command), "unknown direct task accepted")
      end

      playbook_test_direct()
      count = count + 1
   end

   --- Require hosted Lua operations to use declared playbook task names.
   -- @return nil: no values.
   local function playbook_test_workflows()
      local artifacts = dofile("scripts/lib/artifacts.lua")
      local git = dofile("scripts/lib/git.lua").new(artifacts.platform, ".")

      -- Cold runtime construction and lock reads precede the native executor.
      -- Keep exceptions bound to both the reviewed action and command path.
      local bootstrap = {
         [".github/actions/toolchain/action.yml"] = {
            ["scripts/toolchain/resolve.lua"] = true,
         },
         [".github/actions/setup-build-host/action.yml"] = {
            ["scripts/toolchain/resolve.lua"] = true,
            ["scripts/workspace/native-runtime.lua"] = true,
         },
         [".github/actions/setup-lua/action.yml"] = {
            ["scripts/workspace/native-runtime.lua"] = true,
         },
         [".github/actions/setup-msvc-analysis/action.yml"] = {
            ["scripts/workspace/native-runtime.lua"] = true,
         },
         [".github/workflows/_lint-automation.yml"] = {
            ["scripts/toolchain/resolve.lua"] = true,
         },
      }

      --- Check dispatch references without interpreting shell or YAML data.
      -- @param path string: filesystem path selected by the caller.
      -- @return nil: no values.
      local function inspect(path)
         local source = artifacts.read(path)

         for command in source:gmatch("scripts/[%w_./%-]+%.lua") do
            assert(
               command == "scripts/process/playbook.lua" or (bootstrap[path] and bootstrap[path][command]),
               "workflow bypasses playbook: " .. path .. ": " .. command
            )
         end

         for name in source:gmatch("playbook%.lua%s+%-%-direct%s+([%w%-]+)") do
            assert(tasks[name], "unregistered workflow task: " .. name)
         end

         for name in source:gmatch("lma_task=([%w%-]+)") do
            assert(tasks[name], "unregistered Ansible workflow task: " .. name)
         end
      end

      for _, path in ipairs(assert(git.working_files())) do
         if path:match("^%.github/.*%.ya?ml$") then
            inspect(path)
         end
      end

      local listing = artifacts.output({
         os.getenv("LIBMEMALLOC_LUA") or arg[-1] or "lua",
         "scripts/process/playbook.lua",
         "describe",
         "list",
      })

      assert(listing:find('"tasks":', 1, true), "Ansible discovery failed")
   end

   playbook_test_workflows()

   print("Playbook dispatch: " .. count .. " command contracts passed.")
end

return PLAYBOOK_TEST_main()

-- EOF


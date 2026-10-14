-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Describe or execute the shared engineering task registry.
-- Ansible retains bounded task logs. Hosted runners use direct dispatch with
-- native job timeouts, preserving stdout for outputs and command substitutions.

--- Resolve only reviewed tasks and preserve each literal argument boundary.
-- @return nil: no values.
local function PLAYBOOK_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local tasks = dofile("tools/process/playbook.lua")
   local preparation = dofile("tools/workspace/preparation.lua")
   local direct = arg[1] == "--direct"
   local json_result = arg[1] == "--result-json"
   local offset = (direct or json_result) and 2 or 1
   local action = arg[offset] or "list"
   local lock_modes = {
      ["scripts/workspace/clean.lua"] = "exclusive",
      ["scripts/workspace/bootstrap.lua"] = "exclusive",
      ["scripts/toolchain/install/quality.lua"] = "exclusive",
   }

   --- Copy one task contract into an inert JSON description.
   -- @param name string: registered task identity; unknown names fail closed.
   -- @return table: metadata only; this operation executes no task.
   local function playbook_describe(name)
      local task = assert(tasks[name], "unknown playbook task: " .. name)

      return {
         name = name,
         description = task.description,
         command = artifacts.array(task.command),
         dependencies = artifacts.array(task.dependencies),
         preparation = preparation[task.command[1]] or "none",
         effects = task.effects,
         simulation = task.simulation,
         timeout_seconds = task.timeout_seconds,
      }
   end

   --- Produce deterministic task discovery without installing dependencies.
   -- @return table: sorted task contracts and their aggregate read-only effect.
   local function playbook_catalog()
      local names, catalog = {}, artifacts.array()

      for name in pairs(tasks) do
         names[#names + 1] = name
      end

      table.sort(names)

      for _, name in ipairs(names) do
         catalog[#catalog + 1] = playbook_describe(name)
      end

      return { tasks = catalog, effects = "read" }
   end

   --- Execute on the host shell through the shared literal-argv adapter.
   -- @param task table: reviewed command prefix, never a caller-owned path.
   -- @param arguments table: literal arguments appended after that prefix.
   -- @param interpreter string: selected Lua runtime on this runner.
   -- @return number: native child exit code; task output is not decorated.
   local function playbook_direct(task, arguments, interpreter)
      local command = { interpreter }

      for _, value in ipairs(task.command) do
         command[#command + 1] = value
      end

      for _, value in ipairs(arguments) do
         command[#command + 1] = value
      end

      return artifacts.platform.execute(command)
   end

   --- Execute a selected task using the caller's explicit execution boundary.
   -- @return number: exit code suitable for the outer process boundary.
   local function playbook_execute()
      local task = assert(tasks[action], "unknown playbook task: " .. action)

      dofile("scripts/workspace/lib/lock.lua").guard(
         lock_modes[task.command[1]] or "shared"
      )
      local arguments = {}
      local interpreter = os.getenv("LIBMEMALLOC_LUA") or arg[-1] or "lua"
      local code = 0

      for index = offset + 1, #arg do
         arguments[#arguments + 1] = arg[index]
      end

      if direct then
         code = playbook_direct(task, arguments, interpreter)
      else
         local runner = dofile("scripts/process/lib/tasks.lua")
         local passed = runner.run(
            action,
            task,
            arguments,
            interpreter,
            { json = json_result }
         )

         code = passed and 0 or 1
      end

      return code
   end

   --- Validate and display an inert task execution plan.
   -- @return nil: no values.
   local function playbook_plan()
      local selected = assert(arg[offset + 1], "plan requires a task")
      local arguments = {}

      for index = offset + 2, #arg do
         arguments[#arguments + 1] = arg[index]
      end

      if selected == "list" then
         assert(#arguments == 0, "list accepts no arguments")
         print(artifacts.json(playbook_catalog()))
      else
         local task =
            assert(tasks[selected], "unknown playbook task: " .. selected)

         dofile("scripts/process/lib/arguments.lua").validate(task, arguments)
         local description = playbook_describe(selected)

         description.arguments = artifacts.array(arguments)
         local command = { os.getenv("LIBMEMALLOC_LUA") or arg[-1] or "lua" }

         for _, value in ipairs(task.command) do
            command[#command + 1] = value
         end

         for _, value in ipairs(arguments) do
            command[#command + 1] = value
         end

         description.argv = artifacts.array(command)
         if selected == "clean" then
            local options = artifacts.options(
               arguments,
               { scope = true, ["dry-run"] = true }
            )
            local plan =
               dofile("scripts/workspace/lib/clean.lua").repository_plan(
                  options.scope or "all"
               )

            description.paths = artifacts.array(plan.paths)
         end

         print(artifacts.text_json(description))
      end
   end

   if action == "list" then
      assert(#arg < offset + 1, "unexpected arguments")
      print(artifacts.json(playbook_catalog()))
   elseif action == "describe" then
      assert(#arg == offset + 1, "describe requires exactly one task")
      local selected = arg[offset + 1]
      local description = selected == "list" and playbook_catalog()
         or playbook_describe(selected)

      print(artifacts.json(description))
   elseif action == "plan" then
      playbook_plan()
   else
      os.exit(playbook_execute())
   end
end

return PLAYBOOK_main()

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Supervise registered tasks with bounded execution and retained diagnostics.
-- Shared by native Ansible dispatch and automation integration tests.

--- Select native supervision without loading optional bootstrap dependencies.
-- @return table: public task execution operations.
local function TASKS_selectModule()
   local runtime = dofile("scripts/workspace/lib/runtime.lua")
   package.cpath = package.cpath .. ";" .. runtime.paths.luv
   return {
      --- Select the formal or native task supervisor without bootstrap dependencies.
      -- @param name string: registered task name.
      -- @param task table: reviewed task contract.
      -- @param arguments table: literal domain arguments.
      -- @param interpreter string: selected Lua interpreter.
      -- @param options table|nil: output mode.
      -- @return boolean, string, table: success, retained directory and receipt.
      run = function(name, task, arguments, interpreter, options)
         return dofile("scripts/process/lib/formal_tasks.lua").run(
            name,
            task,
            arguments,
            interpreter,
            options
         )
      end,
   }
end

return TASKS_selectModule()

-- EOF


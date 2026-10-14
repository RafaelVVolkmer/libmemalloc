-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Runner allocation is independent of the logical coverage catalog.
-- Partitions apply per compiler and, for reconstruction, per replica.

--- Construct this module within its own initialization scope.
-- @return table: this module within its own initialization scope.
local function tools_build_qualification_execution_loadModule()
   return {
      schema = 1,
      partitions = {
         build = 2,
         instrument = 1,
         train = 1,
         merge = 1,
         optimize = 1,
         run = 6,
         diagnostic_build = 2,
         diagnostic_run = 4,
      },
      -- Relative scheduling estimates, not benchmark measurements. Update these
      -- from retained command durations without changing the logical cases.
      weights = {
         build = 10,
         instrument = 30,
         train = 1,
         merge = 2,
         optimize = 20,
         run = 1,
         diagnostic_build = 10,
         diagnostic_run = 1,
      },
      mode_weights = { ["O3-lto"] = 2, pgo = 2 },
      task_timeout_seconds = 600,
      kill_grace_seconds = 5,
      processes_per_job = 1,
      live_process_states = "D,R,S,T,t,W,I",
      cleanup_checks = 10,
      cleanup_pause_seconds = "0.1",
      isolation = "private-process-session-directory-environment",
   }
end

return tools_build_qualification_execution_loadModule()

-- EOF


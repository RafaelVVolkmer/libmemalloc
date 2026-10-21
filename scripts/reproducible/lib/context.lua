-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Retain diagnostics and distinguish detected differences from tool failures.
-- Part of independent reconstruction and byte-comparison campaigns.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_reproducible_lib_context_loadModule()
   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local exports = {}

   --- Capture the real shell exit code even on runtimes with errno ambiguity.
   -- @param command table: argument vector for the external tool.
   -- @param log string: destination for both output streams.
   -- @return number: exit code; nonnumeric output raises an error.
   local function REPRODUCIBLE_CONTEXT_status(command, log)
      local wrapper = {
         "sh",
         "-c",
         (
            'log=$1; shift; "$@" >"$log" 2>&1; '
            .. 'result=$?; printf "%s\\n" "$result"'
         ),
         "reproducible-tool",
         log,
      }

      for _, argument in ipairs(command) do
         wrapper[#wrapper + 1] = argument
      end

      return assert(
         tonumber(artifact_io.output(wrapper)),
         "missing tool exit status"
      )
   end

   exports.status = REPRODUCIBLE_CONTEXT_status

   return exports
end

return scripts_reproducible_lib_context_loadModule()

-- EOF


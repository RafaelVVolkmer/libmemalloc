-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Execute ordered suites with bounded processes and explicit dependencies.
-- @return table: injected runner API; loading starts no child processes.
local function AUTOMATION_RUNNER_loadModule()
   local exports = {}
   local AUTOMATION_NS_PER_MS = 1000000
   local AUTOMATION_UNKNOWN_EXIT = -1

   --- Retain each process result even when an earlier suite raises.
   -- @param entry table: named argv, timeout and optional environment.
   -- @param ports table: run, record and a nanosecond clock callback.
   -- @param max_bytes number: positive combined output limit.
   -- @return table: state, exit, signal, duration and captured output.
   local function automation_runEntry(entry, ports, max_bytes)
      local started = ports.clock()
      local ok, result = pcall(ports.run, entry.argv, {
         timeout_ms = entry.timeout_ms,
         max_bytes = max_bytes,
         env = entry.env,
      })

      if not ok then
         result = {
            state = "INFRA_ERROR",
            exit_code = AUTOMATION_UNKNOWN_EXIT,
            signal = 0,
            stdout = "",
            stderr = tostring(result),
         }
      end

      result.name = entry.name
      result.duration_ms =
         math.floor((ports.clock() - started) / AUTOMATION_NS_PER_MS)
      ports.record(result)

      return result
   end

   --- Execute all independent suites; block web suites after compiler failure.
   -- @param plan table: ordered lua/node entries and one compiler entry.
   -- @param ports table: process, monotonic clock and evidence operations.
   -- @param max_bytes number: combined stdout/stderr bound for each child.
   -- @return table: ordered results, failures, blocked names and overall state.
   local function AUTOMATION_RUNNER_run(plan, ports, max_bytes)
      local report =
         { results = {}, failures = {}, blocked = {}, state = "PASS" }

      --- Append evidence in catalog order and aggregate unsuccessful outcomes.
      -- @param result table: recorded process result or dependency-blocked row.
      -- @return nil: updates only the report owned by this invocation.
      local function automation_collect(result)
         report.results[#report.results + 1] = result

         if result.state == "BLOCKED" then
            report.blocked[#report.blocked + 1] = result.name
         elseif result.state ~= "PASS" then
            report.failures[#report.failures + 1] = result.name
         end
      end

      for _, entry in ipairs(plan.lua) do
         automation_collect(automation_runEntry(entry, ports, max_bytes))
      end

      local compiler = automation_runEntry(plan.compiler, ports, max_bytes)

      automation_collect(compiler)

      for _, entry in ipairs(plan.node) do
         if compiler.state == "PASS" then
            automation_collect(automation_runEntry(entry, ports, max_bytes))
         else
            local result = {
               name = entry.name,
               state = "BLOCKED",
               reason = "TypeScript compilation did not pass",
               duration_ms = 0,
            }

            ports.record(result)
            automation_collect(result)
         end
      end

      if #report.failures > 0 or #report.blocked > 0 then
         report.state = "FAIL"
      end

      return report
   end

   exports.run = AUTOMATION_RUNNER_run

   return exports
end

return AUTOMATION_RUNNER_loadModule()

-- EOF


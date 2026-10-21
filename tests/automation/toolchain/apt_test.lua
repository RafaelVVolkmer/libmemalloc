-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Reject incomplete repository indexes and recover bounded transient faults.
-- @return nil: rejects stale indexes, unbounded retries and hidden errors.
local function APT_TEST_main()
   local apt = dofile("scripts/toolchain/lib/apt.lua")

   --- Simulate failures at one package operation without touching the host.
   -- @param phase string: failing operation or none.
   -- @param failures integer: number of failed attempts before recovery.
   -- @param repository string|nil: optional compiler repository.
   -- @return table, table, boolean: operations, delays and installation result.
   local function capture(phase, failures, repository)
      local commands, delays = {}, {}
      local refreshed, failed = false, 0
      local ports = { platform = {} }

      --- Model a strict APT failure and forbid installation with stale indexes.
      -- @param command table: literal command vector.
      -- @return boolean: simulated subprocess status.
      function ports.platform.command_succeeded(command)
         local joined = table.concat(command, " ")
         local operation = "install"
         if command[2] == "add-apt-repository" then
            operation = "register"
            assert(joined:find("--no-update", 1, true), "implicit refresh")
         else
            assert(
               joined:find("APT::Update::Error-Mode=any", 1, true),
               "partial index accepted"
            )
            assert(
               joined:find("Acquire::Retries=3", 1, true),
               "missing acquisition retry"
            )
            local required = {
               "Acquire::Languages=none",
               "Acquire::AllowInsecureRepositories=false",
               "Acquire::AllowDowngradeToInsecureRepositories=false",
               "APT::Get::AllowUnauthenticated=false",
            }
            for _, option in ipairs(required) do
               assert(joined:find(option, 1, true), "missing APT policy")
            end
            if command[#command] == "update" then
               operation = "update"
            elseif command[#command] == "software-properties-common" then
               operation = "prerequisites"
            else
               assert(refreshed, "package installation used stale indexes")
            end
         end
         commands[#commands + 1] = operation
         if operation == phase and failed < failures then
            failed = failed + 1
            return false
         end
         refreshed = refreshed or operation == "update"
         return true
      end

      --- Record bounded delays without waiting in the regression suite.
      -- @param command table: retry delay command.
      -- @return nil: no values.
      function ports.run(command)
         assert(command[1] == "sleep", "unexpected host mutation")
         delays[#delays + 1] = assert(tonumber(command[2]))
      end

      local passed = pcall(apt.install, ports, { "gcc-15" }, repository)
      return commands, delays, passed
   end

   local repository = "ppa:ubuntu-toolchain-r/test"
   local phases = { "prerequisites", "register", "update", "install" }
   for _, phase in ipairs(phases) do
      local commands, delays, passed = capture(phase, 3, repository)
      assert(passed, "transient fault prevented recovery")
      assert(
         #delays == 3 and delays[1] == 5 and delays[3] == 20,
         "incorrect retry delays"
      )
      assert(commands[#commands] == "install", "recovery never installed")

      commands, delays, passed = capture(phase, 4, repository)
      assert(not passed, "persistent repository failure was accepted")
      assert(#delays == 3, "retry count is not bounded")
      assert(commands[#commands] == phase, "continued after failed phase")
   end

   local commands, delays, passed = capture("none", 0)
   assert(passed and #delays == 0, "successful operation retried")
   assert(
      table.concat(commands, ",") == "update,install",
      "distribution setup added a repository"
   )
   print("APT provisioning: transient recovery and persistent failure passed.")
end

return APT_TEST_main()

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Verify the isolated behavior owned by this suite.
-- @return nil: no values.
local function MANIFESTS_TEST_NIX_main()
   local primitives = {
      assert = assert,
      ipairs = ipairs,
      pairs = pairs,
      next = next,
      table = table,
      type = type,
      tostring = tostring,
      print = print,
      string = string,
      error = error,
   }

   --- Skip non-Nix hosts, retain explicit setup and propagate Nix failures.
   -- @return nil: no values.
   local function manifests_test_nix()
      local present, failed, calls, writes = false, false, {}, 0
      local fake = {
         platform = {
            --- Control whether the Nix executable is available to the command.
            -- @param name string: entry or operation name to resolve.
            -- @return any: control whether the Nix executable is available to
            -- the command.
            command_exists = function(name)
               assert(name == "nix", "unexpected tool probe")

               return present
            end,
         },
         --- Count creation attempts and reject writes outside the Nix cache.
         -- @param path string: filesystem path selected by the caller.
         -- @return nil: no values.
         mkdir = function(path)
            assert(path == ".cache/tools/nix", "unexpected Nix directory")
            writes = writes + 1
         end,
         --- Capture the Nix command or inject its execution failure.
         -- @param command table: executable and literal command arguments.
         -- @return nil: no values.
         run = function(command)
            assert(not failed, "simulated Nix failure")
            calls[#calls + 1] = command
         end,
      }
      local environment = setmetatable({
         arg = {},
         --- Discard progress messages from the simulated Nix setup.
         -- @return nil: no values.
         print = function() end,
         --- Reject unexpected dependencies while injecting Nix setup ports.
         -- @param path string: filesystem path selected by the caller.
         -- @return any: reject unexpected dependencies while injecting Nix
         -- setup ports.
         dofile = function(path)
            if path == "scripts/workspace/lib/lock.lua" then
               --- Omit repository locking for the simulated Nix process.
               -- @return nil: no values.
               return { guard = function() end }
            end

            if path == "scripts/lib/change.lua" then
               --- Ignore change reporting because this fixture observes
               -- commands directly.
               -- @return nil: no values.
               return { record = function() end }
            end

            assert(
               path == "scripts/lib/artifacts.lua",
               "unexpected module dependency"
            )

            return fake
         end,
      }, { __index = primitives })
      local command =
         assert(loadfile("scripts/toolchain/nix.lua", "t", environment))

      command()
      assert(#calls == 0 and writes == 0, "non-Nix setup has effects")
      present = true
      command()
      assert(#calls == 1 and writes == 1, "Nix setup did not run exactly once")
      local argv = table.concat(calls[1], "\n")

      assert(argv:find("--no-update-lock-file", 1, true))
      assert(argv:find("./tools/nix#default", 1, true))
      assert(argv:find("scripts/toolchain/python.lua", 1, true))
      failed = true
      assert(not pcall(command), "Nix failure was hidden")
      environment.arg = { "unexpected" }
      assert(not pcall(command), "invalid Nix argument accepted")
   end

   manifests_test_nix()
   print("Installer argument contracts passed.")
end

return MANIFESTS_TEST_NIX_main()

-- EOF


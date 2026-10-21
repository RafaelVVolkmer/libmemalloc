-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Verify that native source builds cannot unlock unrelated Python packages.
-- @return nil: no values.
local function PYTHON_TEST_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local lock = dofile("scripts/toolchain/lib/lock.lua").load()
   local hosts = dofile("scripts/toolchain/lib/host.lua")
   local primitives = {
      assert = assert,
      ipairs = ipairs,
      pairs = pairs,
      next = next,
      table = table,
      string = string,
   }

   --- Record installer commands against a cached, healthy uv executable.
   -- @param architecture any: architecture supplied to this operation.
   -- @param groups any: groups supplied to this operation.
   -- @return table: record installer commands against a cached, healthy uv
   -- executable.
   local function capture(architecture, groups)
      local commands = {}
      local port = {
         --- Select the requested dependency groups and an isolated install
         -- directory.
         -- @return table: the requested dependency groups and an isolated
         -- install directory.
         options = function()
            return { groups = groups, directory = ".cache/tools/test-python" }
         end,
         safe_path = artifacts.safe_path,
         --- Model an existing source tree without inspecting the host
         -- filesystem.
         -- @return boolean: model an existing source tree without inspecting
         -- the host filesystem.
         exists = function()
            return true
         end,
         --- Simulate workspace, OpenSSL and package-tool discovery outputs.
         -- @param command table: executable and literal command arguments.
         -- @return string: simulate workspace, OpenSSL and package-tool
         -- discovery outputs.
         output = function(command)
            if command[1] == "git" then
               return "/fixture"
            elseif command[1] == "brew" then
               return "/usr/local/opt/openssl@3"
            end

            return "uv " .. lock.uv.version
         end,
         read = artifacts.read,
         --- Retain exact command arguments instead of running an installer.
         -- @param command table: executable and literal command arguments.
         -- @return nil: no values.
         run = function(command)
            commands[#commands + 1] = table.concat(command, "\n")
         end,
      }
      local modules = {
         --- Omit supervisor locking for this platform selection fixture.
         -- @return nil: no values.
         ["scripts/workspace/lib/lock.lua"] = { guard = function() end },
         ["scripts/lib/artifacts.lua"] = port,
         ["scripts/toolchain/lib/host.lua"] = {
            --- Resolve the requested Darwin architecture using the real host
            -- policy.
            -- @return any: the requested Darwin architecture using the real
            -- host policy.
            current = function()
               return hosts.resolve("Darwin", architecture)
            end,
         },
         ["scripts/lib/change.lua"] = {
            --- Keep the change snapshot stable for the command-only fixture.
            -- @return string: keep the change snapshot stable for the
            -- command-only fixture.
            snapshot = function()
               return "unchanged"
            end,
            --- Discard change reporting because no installation is performed.
            -- @return nil: no values.
            record = function() end,
         },
      }
      local environment = setmetatable({
         arg = {},
         os = {
            --- Remove ambient tool overrides from this deterministic host
            -- fixture.
            -- @return nil: remove ambient tool overrides from this
            -- deterministic host fixture.
            getenv = function()
               return nil
            end,
         },
         --- Inject reviewed ports and delegate other loads to the real modules.
         -- @param path string: filesystem path selected by the caller.
         -- @return any: inject reviewed ports and delegate other loads to the
         -- real modules.
         dofile = function(path)
            return modules[path] or dofile(path)
         end,
      }, { __index = primitives })

      assert(loadfile("scripts/toolchain/python.lua", "t", environment))()

      return commands
   end

   local intel = capture("x86_64", "automation")

   assert(#intel == 2, "native source build skipped backend preparation")
   assert(intel[1]:find("--group\ncrypto-build\n--no-build", 1, true))
   assert(intel[2]:find("--no-build-isolation-package\ncryptography", 1, true))
   assert(intel[2]:find("--no-build-package\ncffi", 1, true))
   assert(
      not intel[2]:find("--no-build-package\ncryptography", 1, true),
      "native source build was forbidden"
   )
   assert(intel[2]:find("OPENSSL_DIR=/usr/local/opt/openssl@3", 1, true))
   local arm = capture("arm64", "automation")

   assert(
      #arm == 1 and arm[1]:find("--no-build\n--group\nautomation", 1, true),
      "Apple Silicon did not require wheels"
   )
   local quality = capture("x86_64", "quality")

   assert(
      #quality == 1 and not quality[1]:find("crypto-build", 1, true),
      "unrelated profile built cryptography"
   )
   local publication = capture("x86_64", "publication")

   assert(#publication == 1, "publication unexpectedly built source packages")
   assert(
      publication[1]:find("--locked", 1, true),
      "publication resolved an unlocked graph"
   )
   assert(
      publication[1]:find("--no-build\n--group\npublication", 1, true),
      "publication must use the isolated locked wheel group"
   )
   local combined = capture("x86_64", "automation,reuse")

   assert(#combined == 2, "combined profile lost its backend")
   assert(combined[2]:find("--no-build-isolation-package\nreuse", 1, true))
   assert(
      combined[2]:find("--no-build-isolation-package\ncryptography", 1, true)
   )
   print("Native Python: backend ordering, source allowlist and wheels passed.")
end

return PYTHON_TEST_main()

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Verify the isolated behavior owned by this suite.
-- @return nil: no values.
local function MANIFESTS_TEST_PYTHON_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local lock = dofile("scripts/toolchain/lib/lock.lua").load()
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

   --- Preserve project paths, interpreter selection and lock enforcement.
   -- @return nil: no values.
   local function manifests_test_python()
      local commands, reads = {}, {}
      local fake = setmetatable({}, { __index = artifacts })

      --- Return a spaced workspace path and the locked package-tool version.
      -- @param command table: executable and literal command arguments.
      -- @return boolean|nil|string: a spaced workspace path and the locked
      -- package-tool version.
      fake.output = function(command)
         return command[1] == "git" and "/workspace with spaces"
            or ("uv " .. lock.uv.version)
      end
      --- Capture argument vectors without installing any packages.
      -- @param command table: executable and literal command arguments.
      -- @return nil: no values.
      fake.run = function(command)
         commands[#commands + 1] = command
      end
      --- Record which lock inputs the environment builder actually reads.
      -- @param path string: filesystem path selected by the caller.
      -- @return any: record which lock inputs the environment builder actually
      -- reads.
      fake.read = function(path)
         reads[path] = true

         return artifacts.read(path)
      end
      local environment = setmetatable({
         arg = { "--groups=reuse", "--directory=.cache/tools/test-python" },
         os = {
            --- Expose only the interpreter and package-tool overrides under
            -- test.
            -- @param name string: entry or operation name to resolve.
            -- @return any: expose only the interpreter and package-tool
            -- overrides under test.
            getenv = function(name)
               return ({
                  LIBMEMALLOC_UV = "/pinned uv",
                  LIBMEMALLOC_PYTHON = "/python path",
               })[name]
            end,
         },
         --- Inject artifact ports while preserving the real dependency
         -- policies.
         -- @param path string: filesystem path selected by the caller.
         -- @return any: inject artifact ports while preserving the real
         -- dependency policies.
         dofile = function(path)
            if path == "scripts/workspace/lib/lock.lua" then
               --- Omit repository locking while recording preparation commands.
               -- @return nil: no values.
               return { guard = function() end }
            end

            return path == "scripts/lib/artifacts.lua" and fake or dofile(path)
         end,
      }, { __index = primitives })

      assert(loadfile("scripts/toolchain/python.lua", "t", environment))()
      assert(
         #commands == 2 and reads["tools/python/uv.lock"],
         "REUSE bootstrap lost its lock"
      )
      for _, command in ipairs(commands) do
         local flags = {}

         for index, value in ipairs(command) do
            flags[value] = command[index + 1] or true
         end

         assert(flags["--locked"], "installer permits lock changes")
         assert(
            flags["--project"] == "/workspace with spaces/tools/python",
            "Python project path changed"
         )
         assert(
            flags["--python"] == "/python path",
            "Python interpreter override changed"
         )
         assert(
            command[2]
               == (
                  "UV_PROJECT_ENVIRONMENT=/workspace with spaces/"
                  .. ".cache/tools/test-python"
               ),
            "environment path changed"
         )
      end
   end

   manifests_test_python()
   print("Installer argument contracts passed.")
end

return MANIFESTS_TEST_PYTHON_main()

-- EOF


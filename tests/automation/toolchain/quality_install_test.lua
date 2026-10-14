-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Exercise quality installation with recorded commands and no host writes.
-- @return nil: no values.
local function QUALITY_INSTALL_TEST_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local lock = dofile("scripts/toolchain/lib/lock.lua").load()
   local hosts = dofile("scripts/toolchain/lib/host.lua")

   --- Record one profile while preserving its real catalog and identities.
   -- @param profile string: selected installation profile.
   -- @param fault string|nil: injected integrity or prerequisite failure.
   -- @return table, boolean: captured command vectors and reported change.
   local function capture(profile, fault)
      local commands, changed = {}, false
      local port = setmetatable({}, { __index = artifacts })
      local platform = setmetatable({}, { __index = artifacts.platform })
      port.platform = platform

      --- Select only the requested profile.
      -- @return table: explicit installation options.
      function port.options()
         return { profile = profile }
      end

      --- Record a command without executing it.
      -- @param command table: literal command vector.
      -- @return nil: no values.
      function port.run(command)
         commands[#commands + 1] = command
      end

      --- Retain path handling for workspaces containing spaces.
      -- @return string: fixture workspace root.
      function port.output()
         return "/fixture with spaces"
      end

      --- Keep directory creation inside the recording fixture.
      -- @return nil: no values.
      function port.mkdir() end

      --- Keep generated launchers and manifests inside the recording fixture.
      -- @return nil: no values.
      function port.write() end

      --- Model already available archives and installed executable paths.
      -- @return boolean: fixture paths exist.
      function port.exists()
         return true
      end

      --- Match archive identities while allowing an integrity failure.
      -- @param path string: archive path selected by the installer.
      -- @return string: reviewed digest or injected invalid digest.
      function port.digest(path)
         local name = assert(path:match("quality/([^/]+)%-[%d]"))
         return fault == "digest" and string.rep("0", 64)
            or assert(lock[name]).sha256
      end

      --- Inject the absence of a required host executable.
      -- @return boolean: whether the prerequisite is installed.
      function platform.command_exists()
         return fault ~= "cargo"
      end

      local environment = setmetatable({ arg = {} }, {
         __index = {
            assert = assert,
            ipairs = ipairs,
            pairs = pairs,
            type = type,
            table = table,
            string = string,
            tostring = tostring,
            os = os,
            arg = {},
         },
      })

      --- Keep progress output out of the assertion log.
      -- @return nil: no values.
      function environment.print() end

      --- Replace host effects while retaining the real installation policy.
      -- @param path string: requested module path.
      -- @return table: fixture ports or the real policy module.
      function environment.dofile(path)
         local modules = {
            ["scripts/lib/artifacts.lua"] = port,
            ["scripts/workspace/lib/lock.lua"] = {
               --- Require the installer to acquire an exclusive lease.
               -- @param mode string: requested lease mode.
               -- @return nil: no values.
               guard = function(mode)
                  assert(
                     mode == "exclusive",
                     "installer lost its exclusive lease"
                  )
               end,
            },
            ["scripts/toolchain/lib/host.lua"] = {
               --- Select the supported Linux fixture host.
               -- @return table: native host identity.
               current = function()
                  return hosts.resolve("Linux", "x86_64")
               end,
               digest = hosts.digest,
            },
            ["scripts/lib/change.lua"] = {
               --- Retain the installation change result.
               -- @param value boolean: reported change status.
               -- @return nil: no values.
               record = function(value)
                  changed = value
               end,
            },
         }
         return modules[path] or dofile(path)
      end

      assert(
         loadfile("scripts/toolchain/install/quality.lua", "t", environment)
      )()
      return commands, changed
   end

   for _, profile in ipairs({ "lua", "spelling", "build", "all" }) do
      local commands, changed = capture(profile)
      local joined = {}
      for _, command in ipairs(commands) do
         joined[#joined + 1] = table.concat(command, " ")
      end
      local text = table.concat(joined, "\n")
      assert(changed, "installation change was not reported")
      assert(
         text:find(
            "--directory=.cache/tools/quality/python-" .. profile,
            1,
            true
         )
      )
      assert(not text:find("curl", 1, true), "cached archive downloaded again")
      if profile == "lua" then
         assert(text:find("selene-lib/lua54", 1, true), "Lua support omitted")
         assert(
            not text:find("npm ci", 1, true),
            "unexpected Node installation"
         )
      elseif profile == "spelling" then
         assert(text:find("--omit=dev", 1, true), "development graph installed")
         assert(
            text:find("--ignore-scripts", 1, true),
            "package scripts enabled"
         )
      end
   end
   assert(not pcall(capture, "unknown"), "unknown profile accepted")
   assert(not pcall(capture, "lua", "cargo"), "missing prerequisite accepted")
   assert(
      not pcall(capture, "lua", "digest"),
      "invalid archive digest accepted"
   )
   print(
      "Quality installation: profile boundaries and failure propagation passed."
   )
end

return QUALITY_INSTALL_TEST_main()

-- EOF


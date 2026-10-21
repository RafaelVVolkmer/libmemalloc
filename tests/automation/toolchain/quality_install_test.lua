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
   -- @param architecture string|nil: macOS architecture; defaults to Linux.
   -- @return table, boolean: captured command vectors and reported change.
   local function capture(profile, fault, architecture)
      local commands, changed = {}, false
      local host = hosts.resolve(
         architecture and "Darwin" or "Linux",
         architecture or "x86_64"
      )
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
      -- @param command table: repository or native host query.
      -- @return string: fixture workspace root.
      function port.output(command)
         if command[1] == "uname" then
            return architecture and "Darwin" or "Linux"
         elseif command[1] == "brew" then
            return "/fixture with spaces/opt/" .. command[3]
         end
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
         if path:match("scanner%-fix%.patch$") then
            return lock.doxygen_scanner_patch.sha256
         end
         local name = assert(path:match("quality/([^/]-)%-[%d]"))
         return fault == "digest" and string.rep("0", 64)
            or hosts.digest(
               assert(lock[name], "missing fixture identity"),
               host
            )
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
         if path == "tools/toolchain/quality.lua" and architecture then
            return dofile("tools/toolchain/quality_macos.lua")(
               dofile(path),
               architecture
            )
         end
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
               --- Select the requested native fixture host.
               -- @return table: native host identity.
               current = function()
                  return host
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
   for _, architecture in ipairs({ "arm64", "x86_64" }) do
      local commands = capture("all", nil, architecture)
      local installed = false
      for _, command in ipairs(commands) do
         if command[1] == "ln" and command[4]:match("/bin/doxygen$") then
            assert(
               command[3]:find(lock.doxygen_scanner_patch.sha256, 1, true),
               "patched Doxygen cache omitted the patch identity"
            )
            installed = true
         end
      end
      assert(installed, "native Doxygen was not published")
   end

   --- Reject altered scanner patches before patching or compiling sources.
   -- @return nil: no values.
   local function verify_source_integrity()
      local source = dofile("scripts/toolchain/lib/source.lua")
      local commands = {}
      local port = {}

      --- Keep extraction and downloads inside the recorded fixture.
      -- @param command table: command arguments recorded in execution order.
      -- @return nil: no values.
      function port.run(command)
         commands[#commands + 1] = command
      end

      --- Model a writable tool cache without host writes.
      -- @return nil: no values.
      function port.mkdir() end

      --- Return an invalid digest for the downloaded patch.
      -- @return string: deliberately altered patch identity.
      function port.digest()
         return string.rep("0", 64)
      end

      local ok, message = pcall(
         source.install,
         port,
         "/verified-source.tar.gz",
         "/fixture with spaces",
         lock.doxygen_scanner_patch
      )
      assert(
         not ok and tostring(message):find("patch hash mismatch", 1, true),
         "altered scanner patch was accepted"
      )
      for _, command in ipairs(commands) do
         assert(command[1] ~= "patch", "unverified patch was applied")
         assert(command[1] ~= "cmake", "unverified sources were compiled")
      end
   end

   verify_source_integrity()

   --- Check native parser selection and stop installation after build errors.
   -- @param fail_build boolean: inject a compiler failure.
   -- @return nil: no values.
   local function verify_source_build(fail_build)
      local commands, port = {}, {}

      --- Record commands and model a failed native compilation.
      -- @param command table: literal command vector.
      -- @return nil: no values.
      function port.run(command)
         commands[#commands + 1] = table.concat(command, " ")
         assert(not (fail_build and command[2] == "--build"), "build failed")
      end

      --- Keep directory creation inside the fixture.
      -- @return nil: no values.
      function port.mkdir() end

      --- Accept the reviewed scanner correction.
      -- @return string: expected patch identity.
      function port.digest()
         return lock.doxygen_scanner_patch.sha256
      end

      --- Model Homebrew tools outside the system executable directory.
      -- @param command table: requested host query.
      -- @return string: host name or package prefix containing spaces.
      function port.output(command)
         if command[1] == "uname" then
            return "Darwin"
         end
         assert(
            command[1] == "brew" and command[2] == "--prefix",
            "unexpected host query"
         )
         return "/fixture with spaces/opt/" .. command[3]
      end

      local ok, message = pcall(
         dofile("scripts/toolchain/lib/source.lua").install,
         port,
         "/verified-source.tar.gz",
         "/fixture with spaces",
         lock.doxygen_scanner_patch
      )
      assert(ok ~= fail_build, tostring(message))
      local recorded = table.concat(commands, "\n")
      for _, name in ipairs({ "bison", "flex" }) do
         assert(
            recorded:find(
               "-D"
                  .. name:upper()
                  .. "_EXECUTABLE=/fixture with spaces/opt/"
                  .. name
                  .. "/bin/"
                  .. name,
               1,
               true
            ),
            "system parser selected instead of Homebrew"
         )
      end
      assert(
         (recorded:find("cmake --install", 1, true) ~= nil) == not fail_build,
         "failed build was installed"
      )
   end

   verify_source_build(false)
   verify_source_build(true)
   print(
      "Quality installation: profile boundaries and failure propagation passed."
   )
end

return QUALITY_INSTALL_TEST_main()

-- EOF


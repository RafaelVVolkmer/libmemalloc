-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Exercise installation command construction without downloading or
-- installing.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_build_provision_test_suite_main()
   local matrix = dofile("tools/build/matrix.lua")
   local planner = dofile("scripts/build/lib/matrix.lua")
   local lock = dofile("scripts/toolchain/lib/lock.lua").load()
   local count = 0

   --- Run an installer against recording ports, preserving its real policy
   -- files.
   -- @param script string: repository entrypoint to execute.
   -- @param options table: options returned by the argument parser.
   -- @param host string: effective operating system.
   -- @return string: commands and filesystem destinations requested by the
   -- script.
   local function provision_capture(script, options, host)
      local ret = ""
      local commands = {}
      local release = {}
      local build = { root = "/fixture", release = release }
      local environment = {
         assert = assert,
         ipairs = ipairs,
         pairs = pairs,
         string = string,
         table = table,
         tostring = tostring,
         arg = {},
      }

      --- Return the requested installer profile without parsing host arguments.
      -- @return any: the requested installer profile without parsing host
      -- arguments.
      release.options = function()
         return options
      end

      --- Record installation commands instead of executing them.
      -- @param command table: executable and literal command arguments.
      -- @return nil: no values.
      release.run = function(command)
         commands[#commands + 1] = table.concat(command, " ")
      end

      --- Supply the selected host and fixture architecture.
      -- @param command table: executable and literal command arguments.
      -- @return any: supply the selected host and fixture architecture.
      release.output = function(command)
         local value = command[2] == "-s" and host or "arm64"

         return value
      end

      --- Record directory destinations without creating them.
      -- @param path string: filesystem path selected by the caller.
      -- @return nil: no values.
      release.mkdir = function(path)
         commands[#commands + 1] = "mkdir " .. path
      end

      --- Record file destinations without writing them.
      -- @param path string: filesystem path selected by the caller.
      -- @return nil: no values.
      release.write = function(path)
         commands[#commands + 1] = "write " .. path
      end

      --- Return the declared tool digest for each fixture download.
      -- @param path string: filesystem path selected by the caller.
      -- @return any: the declared tool digest for each fixture download.
      release.digest = function(path)
         local value = ""

         for _, entry in pairs(lock) do
            if
               entry.sha256
               and entry.version
               and path:find(entry.version, 1, true)
            then
               value = entry.sha256
            end
         end

         if path:find("sccache", 1, true) then
            value = host == "Windows" and lock.sccache_windows.sha256
               or (
                  host == "Darwin" and lock.sccache_macos_arm64.sha256
                  or lock.sccache.sha256
               )
         end

         return value
      end

      release.platform = {
         --- Record package commands without host package installation.
         -- @param command table: requested command vector.
         -- @return boolean: fixture commands succeed.
         command_succeeded = function(command)
            release.run(command)
            return true
         end,
      }

      build.platform = { is_windows = host == "Windows" }
      build.output = release.output
      build.mkdir = release.mkdir
      build.write = release.write
      build.digest = release.digest
      environment.os = {
         --- Exclude contributor environment settings from provisioning.
         -- @return nil: exclude contributor environment settings from
         -- provisioning.
         getenv = function()
            return nil
         end,
      }

      --- Keep installer progress out of the assertion output.
      -- @return nil: no values.
      environment.print = function()
         -- This port has no host effects in the recording fixture.
      end

      --- Inject recording ports while loading real policies and tool locks.
      -- @param path string: filesystem path selected by the caller.
      -- @return any: inject recording ports while loading real policies and
      -- tool locks.
      environment.dofile = function(path)
         if path == "scripts/workspace/lib/lock.lua" then
            --- Omit supervisor locking while the fixture records install
            -- commands.
            -- @return nil: no values.
            return { guard = function() end }
         end

         local value

         if path == "scripts/build/lib/io.lua" then
            value = build
         elseif path == "scripts/lib/artifacts.lua" then
            value = release
         else
            value = dofile(path)
         end

         return value
      end

      assert(loadfile(script, "t", environment), "installer must compile")()

      ret = table.concat(commands, "\n")

      ::function_output::

      return ret
   end

   for _, profile in ipairs(matrix.profiles) do
      local commands = provision_capture(
         "scripts/toolchain/install/build.lua",
         { profile = profile.id },
         profile.host
      )

      assert(
         commands:find("cmake==" .. lock.build_cmake.version, 1, true),
         "unpinned CMake"
      )
      assert(
         commands:find("ninja==" .. lock.build_ninja.version, 1, true),
         "unpinned Ninja"
      )

      if
         profile.host == "Linux"
         and profile.compiler == "Clang"
         and not profile.sdk_driver
      then
         assert(
            commands:find(profile.cc, 1, true),
            "compiler package was inferred from profile name"
         )
      end

      count = count + 1
   end

   for _, group in ipairs({ "rules", "csa", "extended" }) do
      local commands = provision_capture(
         "scripts/toolchain/install/c_analysis.lua",
         { group = group },
         "Linux"
      )

      assert(
         commands:find("c-analysis-" .. group, 1, true),
         "analysis group destination ignored"
      )

      count = count + 1
   end

   for _, build_only in ipairs({ true, false }) do
      local commands = provision_capture(
         "scripts/reproducible/install.lua",
         { ["build-only"] = build_only },
         "Linux"
      )
      assert(
         commands:find("gcc-13", 1, true),
         "missing reconstruction compiler"
      )
      assert(not commands:find("add-apt-repository", 1, true), "unneeded PPA")
      assert(not commands:find("gcc-15", 1, true), "unneeded compiler family")
      assert(
         (commands:find("reprotest=", 1, true) ~= nil) == not build_only,
         "incorrect reconstruction tool scope"
      )
      count = count + 1
   end

   local qualification = provision_capture(
      "scripts/toolchain/install/qualification.lua",
      {},
      "Linux"
   )
   assert(qualification:find("--no-update", 1, true), "unchecked PPA refresh")
   assert(qualification:find("gcc-15", 1, true), "missing C23 compiler")
   assert(qualification:find("clang-18", 1, true), "missing Clang compiler")
   count = count + 1

   assert(
      not pcall(
         provision_capture,
         "scripts/toolchain/install/c_analysis.lua",
         { group = "unknown" },
         "Linux"
      ),
      "unknown group accepted"
   )
   assert(planner.profile(matrix, "linux-gcc13"), "profile lookup unavailable")

   print(
      string.format(
         (
            "Provisioning: %d host/group command plans checked "
            .. "without external effects."
         ),
         count
      )
   )
end

return tests_build_provision_test_suite_main()

-- EOF


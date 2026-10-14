-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Provision a group once; individual build cells never install dependencies.
-- Part of versioned tool identities and host provisioning.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_toolchain_install_build_main()
   dofile("scripts/workspace/lib/lock.lua").guard("shared")
   local build_io = dofile("scripts/build/lib/io.lua")
   local artifact_io = build_io.release
   local exports = dofile("scripts/build/lib/matrix.lua")
   local lock = dofile("scripts/toolchain/lib/lock.lua").load()
   local policy = dofile("tools/build/provision.lua")
   local options =
      artifact_io.options(arg, { profile = true, ["cache-only"] = true })
   local profile = exports.profile(
      dofile("tools/build/matrix.lua"),
      assert(options.profile, "--profile is required")
   )

   local host = build_io.platform.is_windows and "Windows"
      or build_io.output({ "uname", "-s" })
   local paths = {}

   --- Expose a provisioned tool directory to later workflow steps.
   -- @param path string: filesystem path selected by the caller.
   -- @return nil: no values.
   local function toolchain_install_build_addPath(path)
      paths[#paths + 1] = build_io.root .. "/" .. path
   end

   if not options["cache-only"] then
      --- Install the prerequisites owned by the selected host platform.
      -- @return nil: no values.
      local function toolchain_build_installHost()
         if host == "Linux" then
            local packages = {
               "sudo",
               "apt-get",
               "install",
               "-y",
               "--no-install-recommends",
            }

            for _, package in ipairs(policy.linux_packages) do
               packages[#packages + 1] = package
            end

            if profile.cross then
               packages[#packages + 1] = "g++-"
                  .. lock[profile.lock].version:match("^%d+")
                  .. "-"
                  .. profile.cross
               packages[#packages + 1] = policy.cross_runtime
            elseif profile.compiler == "GNU" then
               packages[#packages + 1] = "g++-"
                  .. lock[profile.lock].version:match("^%d+")
            elseif profile.compiler == "Clang" and not profile.sdk_driver then
               packages[#packages + 1] = profile.cc
               if profile.link_flags then
                  packages[#packages + 1] =
                     profile.link_flags:gsub("^-fuse%-ld=", "")
               end
            end

            if profile.repository then
               artifact_io.run({
                  "sudo",
                  "apt-get",
                  "install",
                  "-y",
                  "software-properties-common",
               })

               artifact_io.run({
                  "sudo",
                  "add-apt-repository",
                  "-y",
                  profile.repository,
               })
            end

            artifact_io.run({ "sudo", "apt-get", "update", "-qq" })

            artifact_io.run(packages)
         end
      end

      toolchain_build_installHost()

      local python = host == "Windows" and "python" or "python3"
      local venv = policy.python_directory

      artifact_io.run({ python, "-m", "venv", venv })

      local bin = host == "Windows" and "/Scripts" or "/bin"

      local pip =
         { venv .. bin .. "/pip", "install", "--disable-pip-version-check" }

      for _, tool in ipairs(policy.python_tools) do
         pip[#pip + 1] = tool.package .. "==" .. lock[tool.lock].version
      end

      artifact_io.run(pip)

      toolchain_install_build_addPath(venv .. bin)

      build_io.write(
         venv .. "/dependencies.txt",
         build_io.output({ venv .. bin .. "/pip", "freeze", "--all" }) .. "\n"
      )
   end

   --- Provision the verified compiler-cache tool for the selected profile.
   -- @return nil: no values.
   local function toolchain_build_installCache()
      if profile.cache == "sccache" then
         local hosts =
            assert(policy.sccache.hosts[host], "unqualified cache host")
         local architecture = host == "Darwin"
               and build_io.output({ "uname", "-m" })
            or "default"
         local selected = hosts[architecture] or hosts.default
         local entry = lock[selected.lock]
         local name =
            string.format(policy.sccache.name, entry.version, selected.target)
         local archive = policy.download_directory .. "/" .. name .. ".tar.gz"

         build_io.mkdir(policy.download_directory)

         artifact_io.run({
            "curl",
            "-fsSL",
            "--retry",
            "3",
            string.format(policy.sccache.url, entry.version, name),
            "-o",
            archive,
         })
         assert(
            build_io.digest(archive) == entry.sha256,
            "sccache archive digest mismatch"
         )

         build_io.mkdir(policy.cache_directory)

         artifact_io.run({
            "tar",
            "-xzf",
            archive,
            "-C",
            policy.cache_directory,
         })

         toolchain_install_build_addPath(policy.cache_directory .. "/" .. name)
      elseif profile.cache == "zig" then
         local name = string.format(policy.zig.name, lock.build_zig.version)
         local archive = policy.download_directory .. "/" .. name .. ".tar.xz"

         build_io.mkdir(policy.download_directory)

         artifact_io.run({
            "curl",
            "-fsSL",
            "--retry",
            "3",
            string.format(policy.zig.url, lock.build_zig.version, name),
            "-o",
            archive,
         })
         assert(
            build_io.digest(archive) == lock.build_zig.sha256,
            "Zig archive digest mismatch"
         )

         artifact_io.run({ "tar", "-xJf", archive, "-C", policy.zig.directory })

         toolchain_install_build_addPath(policy.zig.directory .. "/" .. name)
      elseif profile.os == "EMSCRIPTEN" then
         local directory = policy.emscripten.directory

         artifact_io.run({
            "git",
            "clone",
            "--no-checkout",
            policy.emscripten.repository,
            directory,
         })

         artifact_io.run({
            "git",
            "-C",
            directory,
            "checkout",
            "--detach",
            lock.build_emscripten.revision,
         })

         artifact_io.run({
            directory .. "/emsdk",
            "install",
            lock.build_emscripten.version,
         })

         artifact_io.run({
            directory .. "/emsdk",
            "activate",
            "--embedded",
            lock.build_emscripten.version,
         })
      end
   end

   toolchain_build_installCache()

   local github = os.getenv("GITHUB_PATH")

   --- Expose verified tool paths to the following GitHub steps.
   -- @return nil: no values.
   local function toolchain_build_emitPaths()
      if github then
         local file = assert(io.open(github, "a"))

         for _, path in ipairs(paths) do
            assert(file:write(path .. "\n"))
         end

         assert(file:close())
      else
         for _, path in ipairs(paths) do
            print("Add to PATH: " .. path)
         end
      end
   end

   toolchain_build_emitPaths()

   --- Report installation writes, including explicit cache-only installs.
   -- @return nil: no values.
   local function report_changes()
      dofile("scripts/lib/change.lua").record(
         not options["cache-only"]
            or profile.cache == "sccache"
            or profile.cache == "zig"
            or profile.os == "EMSCRIPTEN"
      )
   end

   report_changes()
end

return scripts_toolchain_install_build_main()

-- EOF


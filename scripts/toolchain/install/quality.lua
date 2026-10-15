-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Install locked native quality tools for local checks and hosted CI.
-- Downloads remain hash verified; npm and Python use their reviewed lockfiles.

--- Populate one explicit tool prefix without changing the host installation.
-- @return nil: no values.
local function QUALITY_main()
   local QUALITY_GITHUB_COM_REFS_TAGS_URL =
      "https://github.com/danmar/cppcheck/archive/refs/tags/"

   dofile("scripts/workspace/lib/lock.lua").guard("exclusive")
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local lock = dofile("scripts/toolchain/lib/lock.lua").load()
   local hosts = dofile("scripts/toolchain/lib/host.lua")
   local host = hosts.current()
   local catalog = dofile("tools/toolchain/quality.lua")
   local options = artifacts.options(arg, { profile = true })
   local profile = options.profile or "all"
   local profiles = dofile("tools/toolchain/quality_profiles.lua")
   local selected = assert(profiles[profile], "unknown quality profile")
   if #selected.rust > 0 then
      assert(
         artifacts.platform.command_exists("cargo"),
         "install host prerequisite: cargo "
            .. "(required to build Selene with Lua 5.4 support)"
      )
   end

   local root = artifacts.output({ "git", "rev-parse", "--show-toplevel" })
   local prefix = root .. "/.cache/tools/quality"

   artifacts.mkdir(prefix .. "/bin")
   artifacts.mkdir(".cache/downloads/quality")

   --- Publish executable paths only after the source has been verified.
   -- @param name string: entry or operation name to resolve.
   -- @param target any: selected target configuration or path.
   -- @return nil: no values.
   local function link(name, target)
      assert(artifacts.exists(target), "missing installed tool: " .. target)
      artifacts.run({ "ln", "-sfn", target, prefix .. "/bin/" .. name })
   end

   --- Install selected, hash-verified tool archives into the local prefix.
   -- @return nil: no values.
   local function quality_installArchives()
      local names = {}

      for name in pairs(catalog) do
         if selected.archives[name] then
            names[#names + 1] = name
         end
      end

      table.sort(names)

      --- Verify and install one tool archive before exposing its commands.
      -- @param name string: entry or operation name to resolve.
      -- @return nil: no values.
      local function quality_installArchive(name)
         local tool, identity =
            catalog[name], assert(lock[name], "missing tool identity")
         local digest = hosts.digest(identity, host)

         --- Expand only the reviewed version token, never shell expressions.
         -- @param value any: value supplied to this operation.
         -- @return any: expand only the reviewed version token, never shell
         -- expressions.
         local function expand(value)
            return (
               value:gsub("{version}", identity.version):gsub(
                  "{underscored_version}",
                  (identity.version:gsub("%.", "_"))
               )
            )
         end

         local archive = ".cache/downloads/quality/"
            .. name
            .. "-"
            .. identity.version
            .. (host.key == "linux_x86_64" and "" or "-" .. host.key)

         if not artifacts.exists(archive) then
            artifacts.run({
               "curl",
               "--fail",
               "--location",
               "--proto",
               "=https",
               "--proto-redir",
               "=https",
               "--max-time",
               "300",
               "--retry",
               "3",
               "--output",
               archive,
               expand(tool.url),
            })
         end

         assert(
            artifacts.digest(archive) == digest,
            "archive hash mismatch: " .. name
         )
         local destination = prefix .. "/packages/" .. name .. "/" .. digest

         artifacts.mkdir(destination)
         if tool.archive == "zip" then
            artifacts.run({ "unzip", "-oq", archive, "-d", destination })
         else
            artifacts.run({ "tar", "-xf", archive, "-C", destination })
         end

         for key, command in pairs(tool.commands) do
            local executable = type(key) == "number" and command or key
            local target = destination
               .. "/"
               .. expand(tool.bin)
               .. "/"
               .. command

            artifacts.run({ "chmod", "u+x", target })
            if name == "lua_language_server" then
               -- LuaLS on macOS resolves its resources beside argv[0].
               -- Execute the real binary instead of exposing it by symlink.
               local launcher = destination .. "/launch-lua-language-server"

               artifacts.write(
                  launcher,
                  "#!/bin/sh\nexec "
                     .. artifacts.platform.shell_quote(target)
                     .. ' "$@"\n'
               )
               artifacts.run({ "chmod", "u+x", launcher })
               target = launcher
            end

            link(executable, target)
         end
      end

      for _, name in ipairs(names) do
         quality_installArchive(name)
      end
   end

   quality_installArchives()

   --- Synchronize the selected Python dependency group and expose its tools.
   -- @return string: synchronize the selected Python dependency group and
   -- expose its tools.
   local function quality_installPython()
      local lua = os.getenv("LIBMEMALLOC_LUA") or arg[-1] or "lua"
      local path = prefix .. "/bin:" .. assert(os.getenv("PATH"))

      artifacts.run({
         "env",
         "-u",
         "PYTHONHOME",
         "-u",
         "PYTHONPATH",
         lua,
         "scripts/toolchain/python.lua",
         "--groups=" .. selected.python,
         "--directory=.cache/tools/quality/python-" .. profile,
      })
      for _, name in ipairs(selected.commands) do
         link(name, prefix .. "/python-" .. profile .. "/bin/" .. name)
      end

      return path
   end

   local path = quality_installPython()

   --- Synchronize one npm tool group from its committed lock.
   -- @param group any: group supplied to this operation.
   -- @return nil: no values.
   local function quality_installNodeGroup(group)
      local destination = ".cache/tools/"
         .. (profile == "spelling" and "quality-spelling" or group)

      artifacts.mkdir(destination)
      for _, name in ipairs({ "package.json", "package-lock.json" }) do
         artifacts.write(
            destination .. "/" .. name,
            artifacts.read("tools/lint/code/" .. group .. "/" .. name)
         )
      end

      local install = {
         "env",
         "PATH=" .. path,
         "npm",
         "ci",
         "--prefix",
         destination,
         "--ignore-scripts",
         "--no-audit",
         "--no-fund",
      }

      if profile == "spelling" then
         install[#install + 1] = "--omit=dev"
      end

      artifacts.run(install)
   end

   for _, group in ipairs(selected.node) do
      quality_installNodeGroup(group)
   end

   --- Expose the Node commands installed for the requested profile.
   -- @return nil: no values.
   local function quality_publishNodeTools()
      if #selected.node == 0 then
         return
      end

      local node_group = profile == "spelling" and "quality-spelling"
         or "quality"
      local node_commands = profile == "spelling" and { "cspell" }
         or { "cspell", "renovate-config-validator", "pyright" }

      for _, name in ipairs(node_commands) do
         link(
            name,
            root
               .. "/.cache/tools/"
               .. node_group
               .. "/node_modules/.bin/"
               .. name
         )
      end
   end

   quality_publishNodeTools()

   --- Build the pinned Cppcheck release when the full profile needs it.
   -- @return nil: no values.
   local function quality_installCppcheck()
      if profile == "all" then
         local cppcheck = prefix .. "/cppcheck/" .. lock.cppcheck.version

         if not artifacts.exists(cppcheck .. "/bin/cppcheck") then
            local archive = ".cache/downloads/quality/cppcheck-"
               .. lock.cppcheck.version

            if not artifacts.exists(archive) then
               artifacts.run({
                  "curl",
                  "--fail",
                  "--location",
                  "--proto",
                  "=https",
                  "--proto-redir",
                  "=https",
                  "--max-time",
                  "300",
                  "--output",
                  archive,
                  QUALITY_GITHUB_COM_REFS_TAGS_URL
                     .. lock.cppcheck.version
                     .. ".tar.gz",
               })
            end

            assert(
               artifacts.digest(archive) == lock.cppcheck.sha256,
               "cppcheck hash mismatch"
            )
            artifacts.mkdir(cppcheck .. "/source")
            artifacts.run({
               "tar",
               "-xf",
               archive,
               "--strip-components=1",
               "-C",
               cppcheck .. "/source",
            })
            artifacts.run({
               "cmake",
               "-S",
               cppcheck .. "/source",
               "-B",
               cppcheck .. "/build",
               "-DCMAKE_BUILD_TYPE=Release",
               "-DBUILD_GUI=OFF",
               "-DUSE_MATCHCOMPILER=OFF",
               "-DCMAKE_INSTALL_PREFIX=" .. cppcheck,
            })
            artifacts.run({
               "cmake",
               "--build",
               cppcheck .. "/build",
               "--parallel",
               "2",
            })
            artifacts.run({ "cmake", "--install", cppcheck .. "/build" })
         end

         link("cppcheck", cppcheck .. "/bin/cppcheck")
      end
   end

   quality_installCppcheck()

   --- Expose full-profile validators after their dependencies are installed.
   -- @return nil: no values.
   local function quality_linkValidators()
      if #selected.rust > 0 then
         if profile == "all" then
            link("biome", root .. "/.cache/tools/web/node_modules/.bin/biome")
         end

         --- Build one pinned Rust validator with its required language
         -- features.
         -- @param name string: entry or operation name to resolve.
         -- @return nil: no values.
         local function quality_installRustTool(name)
            local install = {
               "cargo",
               "install",
               name == "taplo" and "taplo-cli" or name,
               "--locked",
               "--version",
               lock[name].version,
               "--root",
               prefix .. "/cargo",
            }

            if name == "selene" then
               install[#install + 1] = "--no-default-features"
               install[#install + 1] = "--features"
               install[#install + 1] = "selene-lib/lua54"
            end

            artifacts.run(install)
            link(name, prefix .. "/cargo/bin/" .. name)
         end

         for _, name in ipairs(selected.rust) do
            quality_installRustTool(name)
         end
      end
   end

   quality_linkValidators()
   print("Quality tools: " .. prefix .. "/bin")
   dofile("scripts/lib/change.lua").record(true)
end

return QUALITY_main()

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Check host prerequisites and reuse tools for a registered Ansible task.
-- @return nil: no values.
local function PREPARE_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local native = dofile("scripts/toolchain/lib/host.lua").current()
   local macos = native.key:match("^macos_") ~= nil
   local task = assert(
      dofile("tools/process/playbook.lua")[arg[1]],
      "unknown preparation task"
   )

   assert(#arg == 1, "preparation requires one registered task")
   local profile = dofile("tools/workspace/preparation.lua")[task.command[1]]
   local profiles = dofile("tools/toolchain/quality_profiles.lua")
   local selected = profile and profiles[profile]
   local host = { "git", "sha256sum", macos and "python3" or "flock" }
   local packages = {
      cc = "build-essential",
      ["c++"] = "build-essential",
      make = "build-essential",
      python3 = "python3.12-venv",
      sha256sum = "coreutils",
      timeout = "coreutils",
      flock = "util-linux",
      ninja = "ninja-build",
      gpg = "gnupg",
      gpgconf = "gnupg",
   }
   local provided = {}
   if macos then
      packages.cc, packages["c++"], packages.make =
         "Command Line Tools", "Command Line Tools", "Command Line Tools"
      packages.python3, packages.ninja = "python@3.12", "ninja"
      packages.cargo = "rust"
   end

   local prefix = ".cache/tools/quality"
   local products = {}

   --- Add a required installed executable to the integrity receipt.
   -- @param name string: entry or operation name to resolve.
   -- @return nil: no values.
   local function product(name)
      provided[name] = true
      products[#products + 1] = prefix .. "/bin/" .. name
   end

   --- Track the executable entrypoints shipped in archive profiles.
   -- @return nil: no values.
   local function collect_archives()
      for name, tool in pairs(dofile("tools/toolchain/quality.lua")) do
         if selected.archives[name] then
            for key, value in pairs(tool.commands) do
               product(type(key) == "number" and value or key)
            end
         end
      end
   end

   --- Include profile-specific tools and native package receipts.
   -- @return nil: no values.
   local function collect_extras()
      if profile == "all" then
         product("cppcheck")
         product("biome")
         product("cspell")
         product("pyright")
         product("renovate-config-validator")
         if macos then
            host[#host + 1], host[#host + 2] = "bison", "flex"
         end
      elseif profile == "spelling" then
         product("cspell")
      end

      for _, group in ipairs(selected.node) do
         local directory = profile == "spelling" and "quality-spelling" or group

         products[#products + 1] = ".cache/tools/"
            .. directory
            .. "/node_modules/.package-lock.json"
      end
   end

   --- Collect products and prerequisites from the actual installer profile.
   -- @return nil: no values.
   local function collect()
      if not selected then
         return
      end

      collect_archives()
      for _, name in ipairs(selected.commands) do
         provided[name] = true
         products[#products + 1] = prefix
            .. "/python-"
            .. profile
            .. "/bin/"
            .. name
      end

      for _, name in ipairs(selected.rust) do
         product(name)
      end

      products[#products + 1] = prefix .. "/python-" .. profile .. "/bin/python"
      local prerequisites = { "curl", "tar", "unzip", "python3", "cc", "make" }

      for _, name in ipairs(prerequisites) do
         host[#host + 1] = name
      end

      if #selected.rust > 0 then
         host[#host + 1] = "cargo"
      end

      collect_extras()
   end

   collect()

   --- Report every missing host package before installing project tools.
   -- @return nil: no values.
   local function check_host()
      for _, name in ipairs(task.dependencies) do
         if not provided[name] then
            host[#host + 1] = name
         end
      end

      local missing, seen = {}, {}

      for _, name in ipairs(host) do
         local package = packages[name] or name
         if
            not artifacts.platform.command_exists(name) and not seen[package]
         then
            missing[#missing + 1], seen[package] = package, true
         end
      end

      local installer = macos and "brew install " or "sudo apt install "

      assert(
         #missing == 0,
         "Missing host prerequisites; see README.md. "
            .. installer
            .. table.concat(missing, " ")
      )
   end

   check_host()
   if not selected then
      print("Task tools changed: false")

      return
   end

   dofile("scripts/workspace/lib/lock.lua").guard("exclusive")
   local lua = arg[-1] or "lua"

   --- Bind cached tools to the installer, central versions and native locks.
   -- @return any: bind cached tools to the installer, central versions and
   -- native locks.
   local function identity()
      local identities = { profile, lua, native.key }

      for _, file in ipairs({
         "tools/toolchain/lock.toml",
         "tools/toolchain/quality.lua",
         "tools/toolchain/quality_macos.lua",
         "scripts/toolchain/lib/host.lua",
         "scripts/toolchain/lib/source.lua",
         "tools/toolchain/quality_profiles.lua",
         "tools/python/pyproject.toml",
         "tools/python/uv.lock",
         "scripts/toolchain/install/quality.lua",
         "scripts/toolchain/python.lua",
         "scripts/workspace/prepare.lua",
      }) do
         identities[#identities + 1] = artifacts.digest(file)
      end

      for _, group in ipairs(selected.node) do
         for _, file in ipairs({ "package.json", "package-lock.json" }) do
            identities[#identities + 1] =
               artifacts.digest("tools/lint/code/" .. group .. "/" .. file)
         end
      end

      return table.concat(identities, "\n")
   end

   table.sort(products)
   local changed = dofile("scripts/workspace/lib/bootstrap.lua").ensure(
      prefix .. "/.ansible-" .. profile,
      identity(),
      products,
      --- Probe the installed interpreter and profile before reusing the
      -- receipt.
      -- @return any: probe the installed interpreter and profile before reusing
      -- the receipt.
      function()
         return artifacts.platform.command_succeeded_silent({
            prefix .. "/python-" .. profile .. "/bin/python",
            "-c",
            "import sys; assert sys.version_info[:2] == (3, 12); "
               .. selected.probe,
         })
      end,
      --- Install the selected profile before the owner records successful
      -- repair.
      -- @return nil: no values.
      function()
         artifacts.run({
            lua,
            "scripts/process/playbook.lua",
            "--result-json",
            "quality-setup",
            "--profile=" .. profile,
         })
      end
   )

   --- Initialize missing documentation assets at the recorded Git revision.
   -- @return boolean: initialize missing documentation assets at the recorded
   -- Git revision.
   local function prepare_assets()
      local commands = {
         ["scripts/documentation/main.lua"] = true,
         ["scripts/check/all.lua"] = true,
         ["scripts/check/automation.lua"] = true,
      }
      if not commands[task.command[1]] then
         return false
      end

      local theme = "doxygen/vendor/doxygen-awesome-css"
      if artifacts.exists(theme .. "/doxygen-awesome.css") then
         return false
      end

      artifacts.run({
         "git",
         "submodule",
         "update",
         "--init",
         "--recursive",
         "--",
         theme,
      })
      assert(
         artifacts.exists(theme .. "/doxygen-awesome.css"),
         "missing documentation theme"
      )

      return true
   end

   changed = prepare_assets() or changed
   print("Task tools changed: " .. tostring(changed))
end

return PREPARE_main()

-- EOF


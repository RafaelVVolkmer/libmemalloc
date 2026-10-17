-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Install the pinned automation runtime into tool-specific cache directories.
-- Explicit network operation for Linux and macOS / Python 3.12 host profiles.
-- Source archives and every Python wheel must match reviewed SHA-256 hashes.

--- Verify sources before extraction and retain bootstrap diagnostics locally.
-- @return nil: no values.
local function BOOTSTRAP_main()
   local BOOTSTRAP_WWW_LUA_ORG_FTP_LUA_URL = "https://www.lua.org/ftp/lua-"
   local BOOTSTRAP_GITHUB_COM_RELEASES_DOWNLOAD_URL =
      "https://github.com/luvit/luv/releases/download/"

   dofile("scripts/workspace/lib/lock.lua").guard("exclusive")
   assert(#arg == 0, "bootstrap accepts no arguments")

   local artifacts = dofile("scripts/lib/artifacts.lua")
   local platform = artifacts.platform
   local lock = dofile("scripts/toolchain/lib/lock.lua").load()
   local hosts = dofile("scripts/toolchain/lib/host.lua")
   local host = hosts.current()
   local python = hosts.python()
   local root = artifacts.output({ "git", "rev-parse", "--show-toplevel" })
   local managed_cmake = root .. "/.cache/tools/quality/bin/cmake"
   local cmake = artifacts.exists(managed_cmake) and managed_cmake or "cmake"
   local timeout_seconds = "900"
   local build_jobs = "2"
   local log_root = ".cache/logs/bootstrap"
   local downloads = ".cache/downloads/automation"

   assert(
      artifacts.output({
         python,
         "-c",
         "import sys; print('%d.%d' % sys.version_info[:2])",
      }) == lock.python_min.version,
      "bootstrap requires CPython "
         .. lock.python_min.version
         .. " for the reviewed wheel set"
   )

   for _, tool in ipairs({
      "cc",
      "make",
      "cmake",
      "ninja",
      "curl",
      "tar",
      "sha256sum",
      "timeout",
   }) do
      assert(
         platform.command_exists(tool),
         "install host prerequisite: " .. tool
      )
   end

   artifacts.mkdir(log_root)
   artifacts.mkdir(downloads)

   --- Bound a bootstrap stage and retain its output separately.
   -- @param name string: entry or operation name to resolve.
   -- @param command table: executable and literal command arguments.
   -- @return nil: no values.
   local function stage(name, command)
      local bounded = { "timeout", "--kill-after=5", timeout_seconds }

      for _, value in ipairs(command) do
         bounded[#bounded + 1] = value
      end

      local log = log_root .. "/" .. name .. ".log"

      print("Bootstrap: " .. name)
      assert(
         platform.command_succeeded(
            platform.join_command(bounded)
               .. " > "
               .. platform.shell_quote(log)
               .. " 2>&1"
         ),
         "bootstrap stage failed: " .. name .. "; inspect " .. log
      )
   end

   --- Recheck cached archive bytes and download only when absent.
   -- @param name string: entry or operation name to resolve.
   -- @param url string: download or reference URL selected by policy.
   -- @param digest string: expected content digest.
   -- @return string: recheck cached archive bytes and download only when
   -- absent.
   local function archive(name, url, digest)
      local path = downloads .. "/" .. name .. ".tar.gz"

      if not artifacts.exists(path) then
         stage("download-" .. name, {
            "curl",
            "--fail",
            "--location",
            "--proto",
            "=https",
            "--tlsv1.2",
            "--retry",
            "3",
            "--output",
            path,
            url,
         })
      end

      assert(
         artifacts.digest(path) == digest,
         "archive hash mismatch: " .. path
      )

      return path
   end

   local state = dofile("scripts/workspace/lib/bootstrap.lua")
   local changed = false
   local inputs = table.concat({
      root,
      host.key,
      artifacts.digest("scripts/toolchain/lib/host.lua"),
      artifacts.digest("scripts/workspace/bootstrap.lua"),
      artifacts.digest("scripts/workspace/lib/bootstrap.lua"),
      artifacts.output({ "cc", "--version" }),
      artifacts.output({ cmake, "--version" }),
      artifacts.output({ "make", "--version" }),
   }, "\n")
   local lua_root = root .. "/.cache/tools/lua/" .. lock.lua.version
   local lua = lua_root .. "/src/lua"
   local lua_identity = inputs
      .. "\n"
      .. lock.lua.version
      .. "\n"
      .. lock.lua.sha256

   --- Check the exact installed Lua version before reusing its build.
   -- @return boolean|nil: check the exact installed Lua version before reusing
   -- its build.
   local function lua_probe()
      local output = platform.command_output({ lua, "-v" })

      return output ~= nil and output:match("^Lua ([^ ]+)") == lock.lua.version
   end

   changed = state.ensure(
      lua_root .. "/.bootstrap-state",
      lua_identity,
      { lua, lua_root .. "/src/lua.h", lua_root .. "/src/luaconf.h" },
      lua_probe,
      --- Build the verified Lua archive only when its receipt needs repair.
      -- @return nil: no values.
      function()
         local source = archive(
            "lua-" .. lock.lua.version,
            BOOTSTRAP_WWW_LUA_ORG_FTP_LUA_URL .. lock.lua.version .. ".tar.gz",
            lock.lua.sha256
         )

         artifacts.mkdir(lua_root)
         stage(
            "extract-lua",
            { "tar", "-xzf", source, "--strip-components=1", "-C", lua_root }
         )
         stage("clean-lua", { "make", "-C", lua_root, "clean" })
         stage("build-lua", { "make", "-C", lua_root, "-j", build_jobs, "all" })
      end
   ) or changed

   local luv_root = root .. "/.cache/tools/luv/" .. lock.luv.version
   local luv = luv_root .. "/build/luv.so"
   local luv_identity = lua_identity
      .. "\n"
      .. artifacts.digest(lua)
      .. "\n"
      .. lock.luv.version
      .. "\n"
      .. lock.luv.sha256

   --- Load the installed module with the exact managed interpreter.
   -- @return any: the installed module with the exact managed interpreter.
   local function luv_probe()
      return platform.command_succeeded_silent({
         "env",
         "LUA_CPATH=" .. luv_root .. "/build/?.so;;",
         lua,
         "-e",
         "assert(require('luv').version())",
      })
   end

   changed = state.ensure(
      luv_root .. "/.bootstrap-state",
      luv_identity,
      { luv },
      luv_probe,
      --- Build the locked native Lua bridge after its Lua dependency is ready.
      -- @return nil: no values.
      function()
         local source = archive(
            "luv-" .. lock.luv.version,
            BOOTSTRAP_GITHUB_COM_RELEASES_DOWNLOAD_URL
               .. lock.luv.version
               .. "/luv-"
               .. lock.luv.version
               .. ".tar.gz",
            lock.luv.sha256
         )

         artifacts.mkdir(luv_root .. "/source")
         stage("extract-luv", {
            "tar",
            "-xzf",
            source,
            "--strip-components=1",
            "-C",
            luv_root .. "/source",
         })
         stage("configure-luv", {
            cmake,
            "--fresh",
            "-S",
            luv_root .. "/source",
            "-B",
            luv_root .. "/build",
            "-DWITH_LUA_ENGINE=Lua",
            "-DLUA_BUILD_TYPE=System",
            "-DLUA_INCDIR=" .. lua_root .. "/src",
            "-DLUA=" .. lua,
            "-DLUADIR=share/lua",
            "-DLIBDIR=lib",
            "-DBUILD_TESTING=OFF",
         })
         stage("build-luv", {
            cmake,
            "--build",
            luv_root .. "/build",
            "--clean-first",
            "--parallel",
            build_jobs,
         })
      end
   ) or changed

   local ansible_root = root
      .. "/.cache/tools/ansible/"
      .. lock.ansible_core.version
   local python_identity = table.concat({
      root,
      host.key,
      lock.ansible_core.version,
      artifacts.digest("tools/python/pyproject.toml"),
      artifacts.digest("tools/python/uv.lock"),
      artifacts.digest("scripts/toolchain/python.lua"),
      lock.uv.version,
      hosts.digest(lock.uv, host),
      artifacts.output({
         python,
         "-c",
         "import sys; print(sys.executable); print(sys.version)",
      }),
   }, "\n")

   --- Import Ansible and its runtime dependencies, not just its launcher.
   -- @return any: import Ansible and its runtime dependencies, not just its
   -- launcher.
   local function ansible_probe()
      return platform.command_succeeded_silent({
         ansible_root .. "/bin/python",
         "-c",
         "import ansible, jinja2, yaml, cryptography; "
            .. "assert ansible.__version__ == '"
            .. lock.ansible_core.version
            .. "'",
      }) and platform.command_succeeded_silent({
         ansible_root .. "/bin/ansible-playbook",
         "--version",
      })
   end

   local controller = ansible_root .. "/bin/ansible-playbook"
   if os.getenv("LIBMEMALLOC_BOOTSTRAP_RUNTIME_ONLY") ~= "1" then
      changed = state.ensure(
         ansible_root .. "/.bootstrap-state",
         python_identity,
         { controller, ansible_root .. "/pyvenv.cfg" },
         ansible_probe,
         --- Repair the controller environment before publishing its receipt.
         -- @return nil: no values.
         function()
            stage("install-ansible", {
               lua,
               "scripts/toolchain/python.lua",
               "--groups=automation",
               "--reinstall",
               "--directory=.cache/tools/ansible/" .. lock.ansible_core.version,
            })
         end
      ) or changed
   end

   stage(
      "native-runtime",
      { lua, "scripts/workspace/native-runtime.lua", lua_root .. "/src", lua }
   )

   local automation = "lma_managed_lua: "
      .. artifacts.text_json(lua)
      .. "\nlma_managed_luv: "
      .. artifacts.text_json(
         root
            .. "/.cache/tools/native/"
            .. lock.lua.version
            .. "/bin/?.so;"
            .. luv_root
            .. "/build/?.so"
      )
      .. "\n"
   if
      not artifacts.exists(".cache/tools/automation.yml")
      or artifacts.read(".cache/tools/automation.yml") ~= automation
   then
      artifacts.write(".cache/tools/automation.yml", automation)
      changed = true
   end

   dofile("scripts/lib/change.lua").record(changed)
   print("Bootstrap tools changed: " .. tostring(changed))

   --- Publish a pinned controller only for explicit bootstrap consumers.
   -- @return nil: no values.
   local function publish_controller()
      local github_output = os.getenv("GITHUB_OUTPUT")

      if
         github_output
         and os.getenv("LIBMEMALLOC_BOOTSTRAP_RUNTIME_ONLY") ~= "1"
      then
         local output = assert(io.open(github_output, "a"))

         assert(
            output:write(
               "ansible=" .. ansible_root .. "/bin/ansible-playbook\n"
            )
         )
         assert(output:close())
      end
   end

   publish_controller()

   print("Bootstrap complete. Run ansible-playbook playbook.yml.")
end

return BOOTSTRAP_main()

-- EOF


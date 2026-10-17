-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Build pinned native Lua modules before the resource executor is available.
-- @return nil: installs modules for the supplied Lua source and interpreter.
local function NATIVE_RUNTIME_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local platform = artifacts.platform
   local lock = dofile("scripts/toolchain/lib/lock.lua").load()
   local source, interpreter =
      assert(arg[1], "Lua source directory required"),
      assert(arg[2], "Lua executable required")
   assert(#arg == 2, "unexpected runtime arguments")
   local root = artifacts.output({ "git", "rev-parse", "--show-toplevel" })
   local destination = root .. "/.cache/tools/native/" .. lock.lua.version
   local extension = platform.is_windows and "dll" or "so"
   local python = os.getenv("LIBMEMALLOC_PYTHON")
      or (platform.is_windows and "python" or "python3")
   local bin = destination .. "/bin"

   --- Create bootstrap directories using the same portable build tool on all hosts.
   -- @param path string: destination directory.
   -- @return nil: no values.
   local function mkdir(path)
      artifacts.run({ "cmake", "-E", "make_directory", path })
   end

   --- Hash an archive using CMake's host-independent SHA-256 implementation.
   -- @param path string: downloaded source archive.
   -- @return string: lowercase digest.
   local function digest(path)
      return assert(
         artifacts
            .output({ "cmake", "-E", "sha256sum", path })
            :match("^([a-f0-9]+)")
      )
   end

   --- Verify immutable source bytes before extracting into a private build tree.
   -- @param name string: locked dependency name.
   -- @param url string: reviewed upstream archive endpoint.
   -- @param path string: extraction destination.
   -- @return nil: no values.
   local function extract(name, url, path)
      local archive = destination .. "/" .. name .. ".tar.gz"
      if
         not artifacts.exists(archive)
         or digest(archive) ~= lock[name].sha256
      then
         artifacts.run({
            "curl",
            "-fL",
            "--retry",
            "3",
            "--max-time",
            "180",
            url,
            "-o",
            archive,
         })
      end
      assert(digest(archive) == lock[name].sha256, name .. " checksum mismatch")
      mkdir(path)
      artifacts.run({
         "tar",
         "-xzf",
         archive,
         "--strip-components=1",
         "-C",
         path,
      })
   end

   --- Probe the installed ABI and publish its module path to CI.
   -- @return nil: no values.
   local function publish()
      local path = bin .. "/?." .. extension
      artifacts.run({
         interpreter,
         "-e",
         "package.cpath="
            .. string.format("%q", path .. ";")
            .. "..package.cpath;assert(require('luv').version());assert(require('cffi').sizeof('int')==4)",
      })
      local environment = os.getenv("GITHUB_ENV")
      if environment then
         assert(not path:find("[\r\n]"), "invalid native module path")
         local file = assert(io.open(environment, "a"))
         assert(file:write("LUA_CPATH=" .. path .. ";;\n"))
         assert(file:close())
      end
      print("Native Lua runtime ready: " .. path)
   end

   local receipt = destination .. "/.native-state"
   local identity = digest("tools/toolchain/lock.toml")
      .. digest("scripts/workspace/native-runtime.lua")
      .. digest(interpreter)
      .. digest(source .. "/lua.h")
      .. digest(source .. "/luaconf.h")
   --- Bind a reusable runtime to its reviewed inputs and actual product bytes.
   -- @return string|nil: receipt contents when both modules exist.
   local function state()
      local luv_module, ffi_module =
         bin .. "/luv." .. extension, bin .. "/cffi." .. extension
      if
         not artifacts.exists(luv_module) or not artifacts.exists(ffi_module)
      then
         return nil
      end
      return identity
         .. "\n"
         .. digest(luv_module)
         .. "\n"
         .. digest(ffi_module)
         .. "\n"
   end
   if artifacts.exists(receipt) and artifacts.read(receipt) == state() then
      publish()
      return
   end
   if artifacts.exists(receipt) then
      assert(os.remove(receipt))
   end

   mkdir(bin)
   --- Build the libuv binding against the selected Lua headers and library.
   -- @return nil: no values.
   local function build_luv()
      local luv = destination .. "/luv"
      extract(
         "luv",
         "https://github.com/luvit/luv/releases/download/"
            .. lock.luv.version
            .. "/luv-"
            .. lock.luv.version
            .. ".tar.gz",
         luv .. "/source"
      )
      local configure = {
         "cmake",
         "-S",
         luv .. "/source",
         "-B",
         luv .. "/build",
         "-G",
         "Ninja",
         "-DCMAKE_BUILD_TYPE=Release",
         "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
         "-DWITH_LUA_ENGINE=Lua",
         "-DLUA_BUILD_TYPE=System",
         "-DBUILD_TESTING=OFF",
         "-DLUA_INCDIR=" .. source,
         "-DLUA=" .. interpreter,
         "-DLUADIR=share/lua",
         "-DLIBDIR=lib",
      }
      if platform.is_windows then
         configure[#configure + 1] = "-DLUA_LIBDIR=" .. source
         configure[#configure + 1] = "-DLUA_LIBFILE=lua55.lib"
      end
      artifacts.run(configure)
      artifacts.run({ "cmake", "--build", luv .. "/build", "--parallel", "2" })
      artifacts.run({
         "cmake",
         "-E",
         "copy",
         luv .. "/build/luv." .. extension,
         bin,
      })
   end
   build_luv()

   --- Build the pinned FFI binding with its vendored native dependency.
   -- @return nil: no values.
   local function build_ffi()
      local cffi = destination .. "/cffi"
      extract(
         "lua_cffi",
         "https://codeload.github.com/q66/cffi-lua/tar.gz/"
            .. lock.lua_cffi.revision,
         cffi .. "/source"
      )
      extract(
         "lua_libffi",
         "https://codeload.github.com/xclaesse/libffi/tar.gz/"
            .. lock.lua_libffi.revision,
         cffi .. "/source/subprojects/libffi"
      )
      extract(
         "meson",
         "https://files.pythonhosted.org/packages/source/m/meson/meson-"
            .. lock.meson.version
            .. ".tar.gz",
         destination .. "/meson"
      )
      local deps = cffi .. "/source/deps"
      mkdir(deps .. "/include")
      for _, header in ipairs({ "lua.h", "luaconf.h", "lauxlib.h", "lualib.h" }) do
         artifacts.run({
            "cmake",
            "-E",
            "copy",
            source .. "/" .. header,
            deps .. "/include",
         })
      end
      if platform.is_windows then
         artifacts.run({ "cmake", "-E", "copy", source .. "/lua55.lib", deps })
      end
      local meson = destination .. "/meson/meson.py"
      artifacts.run({
         python,
         meson,
         "setup",
         "--reconfigure",
         cffi .. "/build",
         cffi .. "/source",
         "--wrap-mode=nodownload",
         "--force-fallback-for=libffi",
         "-Dlua_version=vendor",
         "-Dtests=false",
         "-Dbuildtype=release",
         "-Dlibffi:tests=false",
         "-Dlibffi:doc=false",
      })
      artifacts.run({
         python,
         meson,
         "compile",
         "-C",
         cffi .. "/build",
         "-j",
         "2",
      })
      artifacts.run({
         "cmake",
         "-E",
         "copy",
         cffi .. "/build/cffi." .. extension,
         bin,
      })
   end
   build_ffi()

   publish()
   local receipt_file = assert(io.open(receipt, "w"))
   assert(receipt_file:write(assert(state())))
   assert(receipt_file:close())
end

return NATIVE_RUNTIME_main()

-- EOF


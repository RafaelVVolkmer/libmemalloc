-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Installation policy; artifact versions and checksums remain in the lock.

--- Construct this module within its own initialization scope.
-- @return table: this module within its own initialization scope.
local function tools_build_provision_loadModule()
   return {
      linux_packages = { "python3-venv", "jq", "ninja-build", "ccache" },
      cross_runtime = "qemu-user",
      python_tools = {
         { package = "cmake", lock = "build_cmake" },
         { package = "ninja", lock = "build_ninja" },
      },
      python_directory = ".cache/tools/build-python",
      download_directory = ".cache/downloads",
      cache_directory = ".cache/tools/build-cache",

      sccache = {
         url = (
            "https://github.com/mozilla/sccache/releases/"
            .. "download/v%s/%s.tar.gz"
         ),
         name = "sccache-v%s-%s",
         hosts = {
            Linux = {
               default = {
                  target = "x86_64-unknown-linux-musl",
                  lock = "sccache",
               },
            },
            Windows = {
               default = {
                  target = "x86_64-pc-windows-msvc",
                  lock = "sccache_windows",
               },
            },
            Darwin = {
               arm64 = {
                  target = "aarch64-apple-darwin",
                  lock = "sccache_macos_arm64",
               },
               default = {
                  target = "x86_64-apple-darwin",
                  lock = "sccache_macos_x86_64",
               },
            },
         },
      },

      zig = {
         name = "zig-x86_64-linux-%s",
         url = "https://ziglang.org/download/%s/%s.tar.xz",
         directory = ".cache/tools",
      },

      emscripten = {
         repository = "https://github.com/emscripten-core/emsdk.git",
         directory = ".cache/tools/emsdk",
      },
   }
end

return tools_build_provision_loadModule()

-- EOF


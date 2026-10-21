-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Native qualification policy. Executors consume these values as inputs.
-- Add another host through a separate adapter and qualify its complete cycle.

--- Construct this module within its own initialization scope.
-- @return table: this module within its own initialization scope.
local function tools_build_qualification_host_loadModule()
   return {
      executor = "Linux x86_64",
      binary_format = "elf64-x86-64",
      timeout = { probe = "10", execution = "30" },
      tools = {
         linker = "ld",
         llvm_linker = "ld.lld-18",
         archive = "ar",
         symbols = "nm",
         elf = "readelf",
         profile = "llvm-profdata-18",
         object = "llvm-readobj-18",
         gcov_merge = "gcov-tool-15",
         gcov_dump = "gcov-dump-15",
      },
      repository = "http://ppa.launchpadcontent.net/"
         .. "ubuntu-toolchain-r/test/ubuntu/",
      packages = {
         "gcc-15",
         "g++-15",
         "clang-18",
         "libclang-rt-18-dev",
         "llvm-18",
         "lld-18",
         "binutils",
      },
      compiler_flags = {
         "-g",
         "-fPIC",
         "-Wall",
         "-Wextra",
         "-Werror",
         "-pedantic-errors",
         "-fno-common",
         "-Wdate-time",
      },
      consumer_flags = { "-Wall", "-Wextra", "-Werror", "-pedantic-errors" },
      hardening = "-Wl,-z,relro,-z,now,-z,noexecstack",
      forbidden_sections = {
         "__llvm_prf",
         "__llvm_profile",
         "__gcov",
         ".gnu.lto_",
      },
   }
end

return tools_build_qualification_host_loadModule()

-- EOF


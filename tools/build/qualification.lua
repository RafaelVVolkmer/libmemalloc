-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Qualification applies to the implemented distribution fixture only.

--- Construct this module within its own initialization scope.
-- @return table: this module within its own initialization scope.
local function tools_build_qualification_loadModule()
   return {
      schema = 1,
      contract = dofile("tools/build/qualification-fixture.lua").contract,
      fixture = dofile("tools/build/qualification-fixture.lua"),
      host = dofile("tools/build/qualification-host.lua"),
      primary_dialect = "23",
      execution = dofile("tools/build/qualification-execution.lua"),
      stages = {
         "build",
         "instrument",
         "train",
         "merge",
         "optimize",
         "run",
         "diagnostic_build",
         "diagnostic_run",
      },
      campaigns = {
         pr = { flags = false, modes = { "O0", "O2" } },
         nightly = { flags = true },
         release = { flags = true },
      },
      target = "x86_64-linux-gnu",
      compilers = {
         {
            id = "gcc",
            backend = "gcc",
            cc = "gcc-15",
            cxx = "g++-15",
            lock = "build_gcc15",
            targets = { "x86_64-linux-gnu" },
            dialects = { "99", "11", "17", "23" },
            cpp_dialects = { "98", "03", "11", "14", "17", "20", "23", "26" },
         },
         {
            id = "clang",
            backend = "llvm",
            cc = "clang-18",
            cxx = "clang++-18",
            lock = "build_clang18",
            targets = { "x86_64-linux-gnu", "x86_64-pc-linux-gnu" },
            dialects = { "99", "11", "17", "23" },
            cpp_dialects = { "98", "03", "11", "14", "17", "20", "23", "26" },
         },
      },
      modes = { "O0", "O1", "O2", "O3", "Ofast", "Os", "Oz", "O3-lto" },
      flag_profiles = {
         {
            id = "alias-strict",
            flags = { "-fstrict-aliasing", "-Wstrict-aliasing" },
            contract = "strict",
         },
         {
            id = "alias-conservative",
            flags = { "-fno-strict-aliasing" },
            contract = "strict",
         },
         {
            id = "wrapv",
            flags = { "-fwrapv" },
            contract = "signed-wrap-extension",
         },
         {
            id = "signed-char",
            flags = { "-fsigned-char" },
            contract = "signed-char",
         },
         {
            id = "unsigned-char",
            flags = { "-funsigned-char" },
            contract = "unsigned-char",
         },
         {
            id = "freestanding",
            flags = { "-ffreestanding", "-fno-builtin" },
            contract = "freestanding-core",
         },
         { id = "no-inline", flags = { "-fno-inline" }, contract = "strict" },
         {
            id = "no-vectorize",
            flags = { "-fno-tree-vectorize" },
            contract = "strict",
         },
         {
            id = "sections",
            flags = { "-ffunction-sections", "-fdata-sections" },
            contract = "strict",
         },
         {
            id = "stack-protector",
            flags = { "-fstack-protector-strong" },
            contract = "strict",
         },
         {
            id = "frame-pointer",
            flags = { "-fno-omit-frame-pointer" },
            contract = "strict",
         },
         {
            id = "no-red-zone",
            flags = { "-mno-red-zone" },
            contract = "x86-64",
         },
         { id = "ndebug", flags = { "-DNDEBUG" }, contract = "strict" },
         { id = "debug-info", flags = { "-g3" }, contract = "strict" },
      },
      cases = { "c-direct", "cpp-indirect" },
      case_profiles = {
         ["c-direct"] = { indirect = false, static = true },
         ["cpp-indirect"] = { indirect = true, static = false },
      },
      shards = {
         { id = "first", operations = 1000, weight = 1 },
         { id = "second", operations = 3000, weight = 1 },
      },
      validation_operations = 257,
      max_library_bytes = 65536,
      pending = {
         (
            "Allocator model, failure injection, ownership, "
            .. "alignment and fragmentation: API not implemented."
         ),
         (
            "Concurrent histories, TSan and formal allocator "
            .. "proofs: concurrent core not implemented."
         ),
         (
            "Reserved-hardware benchmarks and performance "
            .. "promotion: no allocator workload or reserved "
            .. "runner contract."
         ),
         (
            "MSVC, Zig, WASM and freestanding PGO: full "
            .. "profiling cycle not qualified."
         ),
         "Previous-release ABI comparison: no allocator release baseline.",
      },
   }
end

return tools_build_qualification_loadModule()

-- EOF


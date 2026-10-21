-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Distribution fixture contract; this does not describe an allocator API.
-- Keep expected behavior independent of the implementation being compiled.

--- Construct this module within its own initialization scope.
-- @return table: this module within its own initialization scope.
local function tools_build_qualification_fixture_loadModule()
   return {
      contract = "mock-identity-v1",
      source_root = "core",
      source = "mock.c",
      header = "mock.h",
      object = "mock.o",
      gcov_data = "mock.gcda",
      library = "memalloc",
      shared = "libmemalloc.so",
      static = "libmemalloc.a",
      symbol = "MOCK_identity",
      exports_pattern = "^MOCK_identity T [%da-f]+ [%da-f]+\n$",
      consumer = "tests/fixtures/qualification/consumer.c.in",
      trace = "mock-identity-v1 operations=%d result=0\n",
      diagnostics = {
         {
            id = "mock",
            source = "tests/fixtures/qualification/consumer.c.in",
            sanitizer = "address,undefined",
            optimization = "-O1",
         },
         {
            id = "asan-negative",
            source = "tests/fixtures/qualification/asan-negative.c.in",
            sanitizer = "address",
            -- Optimizers can remove the invalid read before instrumentation.
            optimization = "-O0",
            expected = "ERROR: AddressSanitizer: stack-buffer-overflow",
         },
         {
            id = "ubsan-negative",
            source = "tests/fixtures/qualification/ubsan-negative.c.in",
            sanitizer = "undefined",
            optimization = "-O1",
            expected = "runtime error: signed integer overflow",
         },
      },
   }
end

return tools_build_qualification_fixture_loadModule()

-- EOF


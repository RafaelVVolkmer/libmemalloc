-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Preserve consumer ABI, dialect and linkage choices across the record API.
-- @return nil: raises when a consumer command loses its selected contract.
local function CONSUMER_TEST_main()
   local commands = {}
   local CONSUMER_TEST_OPERATIONS = 17
   local context = {
      B = { root = "/fixture" },
      catalog = {
         primary_dialect = "23",
         fixture = {
            consumer = "consumer.c.in",
            source_root = "core",
            static = "libmemalloc.a",
            library = "memalloc",
         },
         host = { consumer_flags = { "-Wall" }, hardening = "-Wl,-z,relro" },
      },
   }

   --- Supply deterministic fixture bytes without reading the host filesystem.
   -- @param path string: fixture source selected by the consumer builder.
   -- @return string: C fixture bytes.
   function context.B.read(path)
      assert(path == "consumer.c.in", "unexpected fixture source")
      return "int main(void) { return 0; }\n"
   end

   --- Validate the generated path while keeping this adapter test free of I/O.
   -- @param path string: source path under the selected artifact directory.
   -- @param data string: unchanged fixture bytes.
   -- @return nil: raises for an unexpected path or empty fixture.
   function context.B.write(path, data)
      assert(path:find("/fixture/output/", 1, true) == 1, "source path changed")
      assert(#data > 0, "fixture bytes were lost")
   end

   --- Capture literal command arguments and the reproducible environment.
   -- @param report table: caller-owned build evidence.
   -- @param directory string: selected producer directory.
   -- @param label string: linker invocation identity.
   -- @param argv table: literal linker command.
   -- @param environment table: explicit locale, timezone and source epoch.
   -- @return nil: records arguments without invoking a compiler.
   function context.execute(report, directory, label, argv, environment)
      assert(directory == "output", "producer directory changed")
      assert(label:match("^link%-"), "link operation lost its identity")
      assert(
         environment.SOURCE_DATE_EPOCH == report.source_date_epoch,
         "source epoch was lost"
      )
      commands[#commands + 1] = argv
   end

   local build =
      assert(loadfile("scripts/qualification/lib/build.lua"))(context)
   local compiler = { cc = "cc", cxx = "c++" }
   local report = { source_date_epoch = "0" }

   build.consumer(report, "output", compiler, {
      name = "shared-c",
      operations = CONSUMER_TEST_OPERATIONS,
      indirect = false,
   })
   build.consumer(report, "output", compiler, {
      name = "static-cpp",
      operations = CONSUMER_TEST_OPERATIONS,
      indirect = true,
      static = true,
      dialect = "26",
      optimization = "-O0",
   })

   local shared = table.concat(commands[1], " ")
   local static = table.concat(commands[2], " ")
   assert(
      commands[1][1] == "cc" and commands[2][1] == "c++",
      "language changed"
   )

   for _, flag in ipairs({
      "-std=c23",
      "-O2",
      "-lmemalloc",
      "-Wl,-rpath,$ORIGIN",
   }) do
      assert(shared:find(flag, 1, true), "shared consumer lost " .. flag)
   end

   for _, flag in ipairs({
      "-std=c++2c",
      "-O0",
      "-DLMA_INDIRECT=1",
      "/fixture/output/libmemalloc.a",
   }) do
      assert(static:find(flag, 1, true), "static consumer lost " .. flag)
   end

   assert(
      not static:find("-lmemalloc", 1, true),
      "static consumer linked shared library"
   )
   print(
      "Consumer record: language, dialect, optimization and linkage preserved."
   )
end

return CONSUMER_TEST_main()

-- EOF


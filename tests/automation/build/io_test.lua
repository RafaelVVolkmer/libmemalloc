-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Exercise query argument boundaries and temporary-file cleanup on failures.
-- The jq port records argv; directory creation and removal use the real host.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_build_io_test_suite_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local count = 0

   --- Run one query outcome and verify its temporary file cannot outlive the
   -- call.
   -- @param failure any: failure supplied to this operation.
   -- @return nil: no values.
   local function build_io_testQuery(failure)
      local filter_path
      local query_ran = false
      local expression = '.items[] | select(.name == "a b")'
      local input_path = "input with spaces.json"
      local ports = setmetatable({}, { __index = artifacts })
      local environment = {
         assert = assert,
         dofile = dofile,
         error = error,
         ipairs = ipairs,
         next = next,
         pairs = pairs,
         pcall = pcall,
         table = table,
         io = io,
         os = os,
      }

      --- Preserve root discovery and capture the query without invoking a
      -- shell.
      -- @param argv table: dense executable-and-arguments sequence; values
      -- remain literal.
      -- @return any: preserve root discovery and capture the query without
      -- invoking a shell.
      function ports.output(argv)
         if argv[1] == "git" then
            return artifacts.output(argv)
         end

         query_ran = true
         assert(
            argv[1] == "jq" and argv[2] == "-er" and argv[3] == "-f",
            "jq filter-file arguments changed"
         )
         assert(
            #argv == 5 and argv[5] == input_path,
            "input path split into argv"
         )

         filter_path = argv[4]
         assert(
            artifacts.read(filter_path) == expression,
            "filter bytes changed"
         )
         assert(failure ~= "query", "injected query failure")

         return "selected value"
      end

      --- Inject only the artifact port and keep the real build module under
      -- test.
      -- @param path string: filesystem path selected by the caller.
      -- @return any: inject only the artifact port and keep the real build
      -- module under test.
      function environment.dofile(path)
         assert(path == "scripts/lib/artifacts.lua", "unexpected dependency")

         return ports
      end

      local build =
         assert(loadfile("scripts/build/lib/io.lua", "t", environment))()

      if failure == "write" then
         --- Simulate a partial write to prove that cleanup also covers
         -- creation.
         -- @param path string: filesystem path selected by the caller.
         -- @param value any: input value; validation belongs to this
         -- operation’s contract.
         -- @return nil: no values.
         function build.write(path, value)
            filter_path = path
            artifacts.write(path, value)
            error("injected write failure")
         end
      end

      local success, result = pcall(build.query, input_path, expression)

      assert(success == (failure == nil), "query status changed")
      assert(query_ran == (failure ~= "write"), "unexpected query execution")
      assert(filter_path, "query did not allocate its filter")
      assert(not artifacts.exists(filter_path), "temporary filter survived")
      assert(
         not artifacts.exists(assert(filter_path:match("^(.*)/[^/]+$"))),
         "temporary directory survived"
      )

      if success then
         assert(result == "selected value", "query result changed")
      else
         assert(
            tostring(result):find("injected " .. failure .. " failure", 1, true)
         )
      end

      count = count + 1
   end

   build_io_testQuery(nil)
   build_io_testQuery("query")
   build_io_testQuery("write")
   local build = dofile("scripts/build/lib/io.lua")
   local directory = build.platform.temporary_directory("tmp")
   --- Verify process diagnostics while retaining cleanup of the fixture.
   -- @return nil: no values.
   local ok, failure = xpcall(function()
      local report = { commands = {} }
      local lua = os.getenv("LIBMEMALLOC_LUA") or "lua"
      local success = build.run(report, directory, "exit-code", {
         lua,
         "-e",
         "print('partial output'); os.exit(7)",
      })

      assert(
         not success and report.commands[1].exit_code == 7,
         "real exit code was lost"
      )
      assert(
         build
            .read(directory .. "/exit-code.log")
            :find("partial output", 1, true)
      )
      assert(not build.run(report, directory, "timeout", {
         "cmake",
         "-E",
         "sleep",
         "10",
      }, nil, 0.1), "expired command succeeded")
      assert(
         report.commands[2].state == "TIMEOUT",
         "timeout became ordinary exit"
      )
      assert(
         not build.run(report, directory, "spawn", { "lma-missing-tool" }),
         "missing tool succeeded"
      )
      assert(report.commands[3].state == "ERROR", "spawn error was hidden")
      local literal = 'a; b $ENV{HOME} ]=] "quoted"'

      assert(build.run(report, directory, "literal", {
         lua,
         "-e",
         "io.write(arg[1]); os.exit(0)",
         "--",
         "fixture",
         literal,
      }))
      assert(
         build.read(directory .. "/literal.log") == literal,
         "argument was evaluated"
      )
      count = count + 4
   end, debug.traceback)

   build.platform.remove_temporary_directory(directory)
   assert(ok, failure)
   print(
      string.format("Build query I/O: %d cleanup and argv cases passed.", count)
   )
end

return tests_build_io_test_suite_main()

-- EOF


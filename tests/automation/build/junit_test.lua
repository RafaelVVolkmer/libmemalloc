-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Reject malformed XML and forged JUnit semantics, including inert markup.
-- @return nil: no values.
local function JUNIT_TEST_main()
   local junit = dofile("scripts/build/lib/junit.lua")
   local trace = "mock-identity-v1 operations=257 result=0"
   local trace_pattern = trace:gsub("(%W)", "%%%1")
   local prefix = '<testsuite tests="2" failures="0" disabled="0" skipped="0">'
   local api = '<testcase name="c-api" status="run"><properties/>'
      .. "<system-out>"
      .. trace
      .. "</system-out></testcase>"
   local model = '<testcase name="target-model" status="run"/>'
   local valid = prefix .. api .. model .. "</testsuite>"
   local expected = { "c-api", "target-model" }
   local checks = 0

   --- Count acceptance cases independently of any declared suite totals.
   -- @param source any: source value inspected by this operation.
   -- @return nil: no values.
   local function accepted(source)
      local names = junit.validate(source, expected, trace)

      assert(
         table.concat(names, ",") == "c-api,target-model",
         "JUnit test names differ"
      )
      checks = checks + 1
   end

   accepted(valid)
   accepted('<?xml version="1.0" encoding="UTF-8"?>\n' .. valid)
   accepted(valid:gsub('name="c%-api"', "name='c&#x2d;api'"))
   accepted(valid:gsub(trace_pattern, "<![CDATA[" .. trace .. "]]>"))
   accepted(
      valid:gsub(
         "<properties/>",
         '<properties><property name="a" '
            .. 'value="&lt;testcase/&gt;&amp;"/></properties>'
      )
   )
   accepted(valid .. "<!-- <failure/> -->")
   accepted(valid:gsub(trace_pattern, trace .. "&#13;\n"))

   local hostile = {
      "",
      "<!--" .. valid .. "-->",
      "<![CDATA[" .. valid .. "]]>",
      prefix .. "<!--" .. api .. "-->" .. model .. "</testsuite>",
      valid:sub(1, -13),
      valid .. "<testsuite/>",
      valid .. "trailing",
      "&#32;" .. valid,
      valid:gsub('tests="2"', 'tests="0"'),
      valid:gsub('tests="2"', 'tests="-2"'),
      valid:gsub('tests="2"', 'tests="2.0"'),
      valid:gsub('failures="0"', 'failures="1"'),
      valid:gsub('skipped="0"', 'skipped="1"'),
      valid:gsub('disabled="0"', 'disabled="1"'),
      valid:gsub('failures="0"', 'failures="0" errors="1"'),
      valid:gsub('status="run"', 'status="notrun"'),
      valid:gsub('status="run"', 'status="run" result="failed"'),
      valid:gsub(' status="run"', ""),
      valid:gsub('name="target%-model"', 'name="c-api"'),
      valid:gsub('name="target%-model"', 'name="unexpected"'),
      valid:gsub("<properties/>", "<failure/>"),
      valid:gsub("<system%-out>", '<system-out status="failed">'),
      valid:gsub("<properties/>", "<error/>"),
      valid:gsub("<properties/>", "<skipped/>"),
      valid:gsub("<properties/>", "<properties><failure/></properties>"),
      valid:gsub("<properties/>", '<testcase name="hidden" status="run"/>'),
      valid:gsub(trace_pattern, "<!--" .. trace .. "-->"),
      valid:gsub(trace_pattern, "prefix " .. trace),
      valid:gsub(trace_pattern, trace .. " suffix"),
      prefix .. api:gsub(trace_pattern, "") .. model:gsub(
         "/>",
         "><system-out>" .. trace .. "</system-out></testcase>"
      ) .. "</testsuite>",
      prefix
         .. api:gsub(trace_pattern, "")
         .. model
         .. "<system-out>"
         .. trace
         .. "</system-out></testsuite>",
      valid:gsub('tests="2"', 'tests="2" tests="2"'),
      valid:gsub('tests="2"', 'tests="2"failures="0"'),
      valid:gsub("</testcase>", "</wrong>"),
      valid:gsub("<properties/>", "<properties>"),
      valid:gsub(trace_pattern, '<testcase name="c-api"/>'),
      valid:gsub(trace_pattern, "&undefined;"),
      valid:gsub(trace_pattern, "&amp"),
      valid:gsub(trace_pattern, "&#0;"),
      valid:gsub(trace_pattern, "&#xD800;"),
      valid:gsub(trace_pattern, "&#x110000;"),
      valid:gsub(trace_pattern, "\0"),
      valid:gsub(trace_pattern, "\255"),
      valid:gsub(trace_pattern, "]]>"),
      '<!DOCTYPE testsuite [<!ENTITY x SYSTEM "file:///etc/passwd">]>' .. valid,
      "<!DOCTYPE testsuite>" .. valid,
      '<?xml version="1.1"?>' .. valid,
      '<?xml version="1.0" encoding="UTF-16"?>' .. valid,
      ' <?xml version="1.0"?>' .. valid,
      '<?xml encoding="UTF-8" version="1.0"?>' .. valid,
      "<?probe value?>" .. valid,
      valid .. "<!-- bad -- comment -->",
      valid .. "<!-- bad --->",
      valid .. "<!-- unclosed",
   }

   for index, source in ipairs(hostile) do
      assert(
         not pcall(junit.validate, source, expected, trace),
         "hostile JUnit accepted: " .. index
      )
      checks = checks + 1
   end

   --- Exercise the XML emitted by the actual host CTest, not just literals.
   -- @return nil: no values.
   local function junit_test_ctest()
      local build = dofile("scripts/build/lib/io.lua")
      local directory = build.platform.temporary_directory("tmp")
      --- Generate real CTest XML and validate it before removing the project.
      -- @return nil: no values.
      local ok, reason = xpcall(function()
         local cmake = build.tool("cmake").path
         local definition = 'add_test(c-api "'
            .. cmake
            .. '" -E echo "'
            .. trace
            .. '")\n'
            .. 'add_test(target-model "'
            .. cmake
            .. '" -E echo "model")\n'

         build.write(directory .. "/CTestTestfile.cmake", definition)
         build.release.run({
            "ctest",
            "--test-dir",
            directory,
            "--output-junit",
            "ctest.xml",
         })
         accepted(build.read(directory .. "/ctest.xml"))
      end, debug.traceback)

      build.platform.remove_temporary_directory(directory)
      assert(ok, reason)
   end

   junit_test_ctest()
   print(
      "JUnit evidence: " .. checks .. " structural and semantic cases passed."
   )
end

return JUNIT_TEST_main()

-- EOF


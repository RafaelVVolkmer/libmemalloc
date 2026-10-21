-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Reject tampered or displaced test evidence before a build cell can pass.

--- Exercise real hashing and jq transport in an isolated evidence directory.
-- @return nil: no values.
local function EVIDENCE_TEST_main()
   local build = dofile("scripts/build/lib/io.lua")
   local evidence = dofile("scripts/build/lib/evidence.lua")
   local root = build.platform.temporary_directory("tmp")
   local checks = 0
   --- Exercise evidence validation and release the fixture after any failure.
   -- @return nil: no values.
   local ok, failure = xpcall(function()
      local trace = "mock-identity-v1 operations=257 result=0"
      local xml = '<testsuite tests="1" failures="0" disabled="0" skipped="0">'
         .. '<testcase name="c-api" status="run"><system-out>'
         .. trace
         .. "</system-out></testcase></testsuite>"
      local path = root .. "/cell/ctest.xml"

      build.write(path, xml)
      local digest = build.digest(path)
      local cell = {
         id = "cell",
         support = "required",
         status = "tests-passed",
         tests = build.array({ "c-api" }),
         unsupported_tests = build.array(),
         artifacts = build.array({ { path = "mock", sha256 = digest } }),
         test_report = { path = "cell/ctest.xml", sha256 = digest },
         semantic_trace = trace,
      }
      local report = {
         schema = 2,
         profile = "fixture",
         campaign = "pr",
         plan_sha256 = digest,
         cells = build.array({ cell }),
      }

      build.json(root .. "/report.json", report)
      assert(
         #evidence.group(build, root, "fixture", "pr", digest) == 1,
         "valid cell omitted"
      )
      checks = checks + 1

      --- Reject a mutated fixture with a specific diagnostic.
      -- @param expected any: expected reference value used by this check.
      -- @return nil: no values.
      local function rejected(expected)
         build.json(root .. "/report.json", report)
         local valid, reason =
            pcall(evidence.group, build, root, "fixture", "pr", digest)

         assert(
            not valid and tostring(reason):find(expected, 1, true),
            tostring(reason)
         )
         checks = checks + 1
      end

      build.write(path, xml .. "changed")
      rejected("digest mismatch")
      build.write(path, xml)
      cell.test_report.path = "../ctest.xml"
      rejected("path mismatch")
      cell.test_report.path = "another/ctest.xml"
      rejected("path mismatch")
      cell.test_report.path = "cell/ctest.xml"
      cell.tests = build.array({ "absent" })
      rejected("inventory mismatch")
      cell.tests = build.array({ "c-api" })
      build.write(path, xml:gsub("<system%-out>", "<failure/><system-out>"))
      cell.test_report.sha256 = build.digest(path)
      rejected("unsuccessful test")
      -- Each hostile document has its own correct digest: XML validation,
      -- rather than byte integrity, must reject it.
      for _, invalid in ipairs({
         '<testsuite tests="0" failures="0" disabled="0" skipped="0">'
            .. '<!-- <testcase name="c-api" status="run"/> -->'
            .. "<system-out>"
            .. trace
            .. "</system-out></testsuite>",
         xml:gsub("</testcase></testsuite>", ""),
         xml:gsub('tests="1"', 'tests="2"'),
         xml:gsub('status="run"', 'status="notrun"'),
      }) do
         build.write(path, invalid)
         cell.test_report.sha256 = build.digest(path)
         build.json(root .. "/report.json", report)
         assert(
            not pcall(evidence.group, build, root, "fixture", "pr", digest),
            "invalid XML passed with a valid digest"
         )
         checks = checks + 1
      end

      report.plan_sha256 = string.rep("0", 64)
      rejected("another plan")
      report.plan_sha256 = digest
      report.schema = 1
      rejected("command failed")
      local profile = "linux-zig-musl"

      build.write(root .. "/" .. profile .. "/report.json", "{invalid")
      local summary = root .. "/summary.json"

      assert(not build.platform.command_succeeded_silent({
         os.getenv("LIBMEMALLOC_LUA") or "lua",
         "scripts/build/report.lua",
         "--profile=" .. profile,
         "--input=" .. root,
         "--output=" .. summary,
      }), "malformed profile passed aggregate")
      assert(
         build.query(summary, ".required_passed | tostring") == "false",
         "failed aggregate did not retain summary"
      )
      assert(
         tonumber(build.query(summary, ".failures | length")) > 0,
         "aggregate omitted failure diagnosis"
      )
      checks = checks + 1
   end, debug.traceback)

   build.platform.remove_temporary_directory(root)
   assert(ok, failure)
   print(string.format("Build evidence: %d integrity cases passed.", checks))
end

return EVIDENCE_TEST_main()

-- EOF


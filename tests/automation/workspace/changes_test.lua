-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Check selective CI categories against controlled Git changes.
-- Part of repository automation regression tests; run from the root.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_lint_changed_areas_test_suite_main()
   local platform = dofile("scripts/lib/platform.lua")
   local directory = platform.temporary_directory()
   local lua = assert(platform.resolve_tool("LIBMEMALLOC_LUA", "lua"))

   --- Capture a command inside the isolated Git repository.
   -- @param arguments table: ordered arguments for the selected operation.
   -- @return any: a command inside the isolated Git repository.
   local function command(arguments)
      return assert(platform.command_output_in_directory(directory, arguments))
   end

   --- Run Git without relying on contributor identity or hooks.
   -- @param arguments table: ordered arguments for the selected operation.
   -- @return any: run Git without relying on contributor identity or hooks.
   local function git(arguments)
      local argv = {
         "git",
         "-c",
         "user.name=CI Fixture",
         "-c",
         "user.email=fixture@example.org",
         "-c",
         "commit.gpgsign=false",
         "-c",
         "core.hooksPath=/dev/null",
      }

      for _, value in ipairs(arguments) do
         argv[#argv + 1] = value
      end

      return command(argv):gsub("%s+$", "")
   end

   --- Write one changed-file fixture into the temporary repository.
   -- @param path string: filesystem path selected by the caller.
   -- @return nil: no values.
   local function write(path)
      local file = assert(io.open(directory .. "/" .. path, "wb"))

      assert(file:write("fixture\n"))
      assert(file:close())
   end

   --- Read category decisions for a controlled revision interval.
   -- @param base any: base supplied to this operation.
   -- @param force any|nil: force supplied to this operation.
   -- @return table: category decisions for a controlled revision interval.
   local function classify(base, force)
      local output = command({
         "env",
         "-u",
         "GITHUB_OUTPUT",
         lua,
         "scripts/workspace/changes.lua",
         "--base",
         base,
         "--head",
         "HEAD",
         "--force-all",
         force or "false",
      })

      local result = {}

      for key, value in output:gmatch("([a-z]+)=([a-z]+)") do
         result[key] = value == "true"
      end

      return result
   end

   --- Exercise additions, deletions and forced validation before cleanup.
   -- @return nil: no values.
   local success, failure = xpcall(function()
      platform.run({ "cp", "-R", "scripts", directory .. "/scripts" })
      platform.run({ "mkdir", "-p", directory .. "/tools/ci" })
      platform.run({
         "cp",
         "tools/ci/changes.lua",
         directory .. "/tools/ci/changes.lua",
      })
      git({ "init", "--quiet" })
      git({ "add", "scripts", "tools" })
      git({ "commit", "--quiet", "-m", "fixture" })

      local base = git({ "rev-parse", "HEAD" })

      write("example.py")
      git({ "add", "example.py" })
      git({ "commit", "--quiet", "-m", "python fixture" })

      local changed = classify(base)

      assert(changed.python and not changed.c, "Python detection failed")
      assert(not changed.lua and not changed.actions, "unrelated jobs selected")

      base = git({ "rev-parse", "HEAD" })
      git({ "rm", "--quiet", "example.py" })
      git({ "commit", "--quiet", "-m", "delete fixture" })
      assert(classify(base).python, "deleted Python file must select Python")

      command({ "mkdir", "-p", "docs/standards/c" })

      base = git({ "rev-parse", "HEAD" })
      write("docs/standards/c/example.md")
      git({ "add", "docs" })
      git({ "commit", "--quiet", "-m", "C documentation fixture" })

      changed = classify(base)
      assert(changed.c and changed.markdown, "C documentation detection failed")
      assert(not changed.python, "documentation unexpectedly selects Python")
      assert(not changed.engineering, "prose selected release qualification")

      --- Verify all analysis inputs select their required gates.
      -- @param path string: filesystem path selected by the caller.
      -- @return nil: no values.
      local function changes_test_assertAnalysis(path)
         local parent = path:match("^(.*)/[^/]+$")

         if parent then
            command({ "mkdir", "-p", parent })
         end

         base = git({ "rev-parse", "HEAD" })
         write(path)
         git({ "add", path })
         git({ "commit", "--quiet", "-m", "analysis input fixture" })
         assert(classify(base).c, "analysis input did not select C: " .. path)
         assert(
            classify(base).engineering,
            "engineering evidence was skipped: " .. path
         )
      end

      for _, path in ipairs({
         "CMakeLists.txt",
         "scripts/check/c_analysis.lua",
         "tests/fixtures/analysis/rule.c.in",
         "tests/fixtures/compatibility/c/api.c.in",
         "tests/fixtures/qualification/consumer.c.in",
         "tests/fixtures/install/CMakeLists.txt",
         "tools/analysis/c/profile.lua",
         "tools/analysis/c/metrics.py",
         "tests/formal/manifest.yml",
      }) do
         changes_test_assertAnalysis(path)
      end

      --- Keep native adapter changes connected to both language gates.
      -- @return nil: no values.
      local function changes_test_assertLuaAdapter()
         changes_test_assertAnalysis("tools/analysis/lua/metrics.py")

         local selected = classify(base)

         assert(selected.lua and selected.python, "Lua adapter checks skipped")
      end

      changes_test_assertLuaAdapter()

      --- Check that each build input selects build validation.
      -- @param path string: filesystem path selected by the caller.
      -- @return nil: no values.
      local function changes_test_assertBuild(path)
         command({ "mkdir", "-p", assert(path:match("^(.*)/[^/]+$")) })

         base = git({ "rev-parse", "HEAD" })
         write(path)
         git({ "add", path })
         git({ "commit", "--quiet", "-m", "documentation policy fixture" })

         changed = classify(base)
         assert(
            changed.markdown and changed.ci and changed.lua,
            "documentation policy did not select its checks: " .. path
         )
      end

      for _, path in ipairs({
         "scripts/check/documentation.lua",
         "scripts/check/sdd.lua",
         "scripts/check/lib/sdd.lua",
         "tests/automation/check/sdd_test.lua",
         "tools/specs/catalog.lua",
         "scripts/documentation/lib/policy.lua",
         "tests/automation/documentation/policy_test.lua",
      }) do
         changes_test_assertBuild(path)
      end

      for _, fixture in ipairs({
         { "sample.html", "html" },
         { "sample.css", "css" },
         { "sample.js", "javascript" },
         { "sample.cjs", "javascript" },
         { "sample.ts", "typescript" },
         { "sample.tsx", "typescript" },
      }) do
         base = git({ "rev-parse", "HEAD" })
         write(fixture[1])
         git({ "add", fixture[1] })
         git({ "commit", "--quiet", "-m", "web source fixture" })

         changed = classify(base)
         assert(changed[fixture[2]], "web addition was omitted")
         assert(not changed.python, "web source selected Python")

         base = git({ "rev-parse", "HEAD" })
         git({ "rm", fixture[1] })
         git({ "commit", "--quiet", "-m", "web removal fixture" })
         assert(classify(base)[fixture[2]], "web deletion was omitted")
      end

      --- Check that toolchain changes invalidate their dependent workflows.
      -- @param path string: filesystem path selected by the caller.
      -- @return nil: no values.
      local function changes_test_assertToolchain(path)
         local parent = path:match("^(.*)/[^/]+$")

         if parent then
            command({ "mkdir", "-p", parent })
         end

         base = git({ "rev-parse", "HEAD" })
         write(path)
         git({ "add", path })
         git({ "commit", "--quiet", "-m", "dependency environment fixture" })
         for category, selected in pairs(classify(base)) do
            assert(selected, path .. " omitted " .. category)
         end
      end

      for _, path in ipairs({
         "tools/python/pyproject.toml",
         "tools/python/uv.lock",
         "tools/nix/flake.nix",
         "tools/nix/flake.lock",
         "tools/nix/packages.toml",
         "scripts/toolchain/python.lua",
      }) do
         changes_test_assertToolchain(path)
      end

      for _, input in ipairs({
         { string.rep("0", 40), "false" },
         { string.rep("a", 40), "false" },
         { base, "true" },
      }) do
         for category, selected in pairs(classify(input[1], input[2])) do
            assert(selected, "full validation omitted " .. category)
         end
      end

      print("Changed areas: additions, deletion, C docs, and full runs passed.")
   end, debug.traceback)

   platform.remove_temporary_directory(directory)
   assert(success, failure)
end

return tests_lint_changed_areas_test_suite_main()

-- EOF


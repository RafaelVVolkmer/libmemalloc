-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Check source attributes, disposable paths and Git setup idempotence.
-- Part of workspace regression tests.
-- Configuration writes use an isolated clone.

--- Inspect effective settings and exercise setup without touching this clone.
-- @return nil: no values.
local function SETTINGS_TEST_main()
   local platform = dofile("scripts/lib/platform.lua")
   local sources = {
      "playbook.yml",
      ".gitconfig",
      ".githooks/pre-push",
      "example.cjs",
      "example.mjs",
      "example.cts",
      "example.mts",
      "example.json5",
      "example.dox",
      "example.cocci",
      "example.nuon",
      "example.c.in",
      "example.cpp.in",
      "example.cmake.in",
      "example.pc.in",
      "example.txt.in",
      "example.psd1",
   }

   for _, path in ipairs(sources) do
      local output = assert(
         platform.command_output({ "git", "check-attr", "eol", "--", path })
      )

      assert(output:match(": eol: lf"), path .. " lacks explicit LF")
   end

   for _, path in ipairs({ "example.woff2", "example.ttf" }) do
      local output = assert(
         platform.command_output({ "git", "check-attr", "text", "--", path })
      )

      assert(output:match(": text: unset"), "font treated as text")
   end

   for _, path in ipairs({
      ".ansible/state",
      "attempt.retry",
      ".cache/tmp/commit-message.md",
      ".cache/logs/process-001/report.md",
      "verification/theorems/.lake/build/lib/lean/LibMemAlloc.olean",
      "verification/theorems/LibMemAlloc.olean",
      "verification/theorems/LibMemAlloc.olean.private",
      "verification/theorems/LibMemAlloc.ilean",
      "verification/engine/dist-newstyle/cache/plan.json",
      "verification/engine/.stack-work/lock",
      "verification/engine/.liquid/Refined.json",
      "verification/engine/src/LibMemAlloc/Verifier/Refined.hi",
      "verification/engine/src/LibMemAlloc/Verifier/Refined.dyn_hi",
      "verification/engine/cabal.project.local",
      "verification/engine/.ghc.environment.x86_64-linux-9.4.7",
   }) do
      assert(
         platform.command_succeeded_silent({
            "git",
            "check-ignore",
            "--no-index",
            "--",
            path,
         }),
         "temporary path is visible: " .. path
      )
   end

   for _, path in ipairs({
      "playbook.yml",
      ".gitconfig",
      ".env.example",
      "tools/example.env.example",
      "scripts/build/plan.lua",
      "tests/automation/release/release_test.lua",
      "verification/theorems/lean-toolchain",
      "verification/theorems/lake-manifest.json",
      "verification/theorems/lakefile.toml",
      "verification/theorems/LibMemAlloc.lean",
      "verification/engine/cabal.project",
      "verification/engine/cabal.project.freeze",
      "verification/engine/libmemalloc-verifier.cabal",
      "verification/engine/src/LibMemAlloc/Verifier/Refined.hs",
   }) do
      assert(not platform.command_succeeded_silent({
         "git",
         "check-ignore",
         "--no-index",
         "--",
         path,
      }), "source is ignored: " .. path)
   end

   local directory = platform.temporary_directory()
   local interpreter = assert(platform.resolve_tool("LIBMEMALLOC_LUA", "lua"))

   --- Capture one command within the fixture repository.
   -- @param command table: executable and literal command arguments.
   -- @return any: one command within the fixture repository.
   local function capture(command)
      return assert(platform.command_output_in_directory(directory, command))
   end

   --- Exercise setup twice, then confirm that custom hooks remain protected.
   -- @return nil: no values.
   local success, failure = xpcall(function()
      platform.run({ "cp", "-R", "scripts", directory .. "/scripts" })
      platform.run({ "cp", ".gitconfig", directory .. "/.gitconfig" })
      capture({ "git", "init", "--quiet" })
      capture({ interpreter, "scripts/workspace/hooks.lua", "install" })
      capture({ interpreter, "scripts/workspace/hooks.lua", "install" })

      local includes = capture({
         "git",
         "config",
         "--local",
         "--get-all",
         "include.path",
      })

      assert(
         includes == directory .. "/.gitconfig\n",
         "setup duplicated include"
      )
      assert(
         capture({ "git", "config", "--get", "core.hooksPath" })
            == ".githooks\n",
         "included hooks path is not effective"
      )

      capture({ "git", "config", "--local", "user.name", "Preserved User" })
      capture({ interpreter, "scripts/workspace/hooks.lua", "uninstall" })
      capture({ interpreter, "scripts/workspace/hooks.lua", "uninstall" })
      assert(
         capture({ "git", "config", "user.name" }) == "Preserved User\n",
         "uninstall changed contributor identity"
      )
      capture({ interpreter, "scripts/workspace/hooks.lua", "install" })

      local moved = platform.temporary_directory()

      platform.run({ "cp", "-R", directory .. "/.", moved })
      local original = directory

      directory = moved
      capture({ interpreter, "scripts/workspace/hooks.lua", "repair" })
      assert(
         capture({ "git", "config", "--local", "--get-all", "include.path" })
            == moved .. "/.gitconfig\n",
         "repair retained stale include"
      )
      platform.remove_temporary_directory(moved)
      directory = original

      capture({ "git", "config", "--local", "core.hooksPath", "custom-hooks" })
      assert(
         not platform.command_succeeded_silent_in_directory(
            directory,
            { interpreter, "scripts/workspace/hooks.lua", "install" }
         ),
         "setup replaced custom hooks"
      )
   end, debug.traceback)

   platform.remove_temporary_directory(directory)
   assert(success, failure)
   print(
      "Workspace settings: attributes, ignores and setup regressions passed."
   )
end

return SETTINGS_TEST_main()

-- EOF


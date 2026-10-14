-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Verify cleanup scope, repeatability and symlink boundaries with disposable
--- data.
-- @return nil: no values.
local function CLEAN_TEST_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local cleaner = dofile("scripts/workspace/lib/clean.lua")
   local uv = require("luv")
   local root = artifacts.platform.temporary_directory("tests")
   local checkout = root .. "/checkout"
   local keep = checkout .. "/.cache/logs/tasks/current"

   for _, path in ipairs({
      "/source.c",
      "/.cache/tools/lua/bin/lua",
      "/.cache/tools/automation.yml",
      "/.cache/ansible/local/live",
      "/.cache/tools/uv-cache/data",
      "/.cache/build/metadata/build.json",
      "/.cache/tmp/temp",
      "/.cache/tests/test",
      "/.cache/logs/old/output",
      "/.cache/logs/tasks/current/result.json",
   }) do
      artifacts.write(checkout .. path, "keep or remove by scope\n")
   end

   artifacts.write(root .. "/outside/important", "untouched\n")
   assert(uv.fs_symlink(root .. "/outside", checkout .. "/.cache/tmp/link"))
   local preview = cleaner.plan(checkout, "temporary")

   assert(#preview.paths == 2, "temporary preview must select two paths")
   assert(
      artifacts.exists(checkout .. "/.cache/tmp/temp"),
      "planning wrote files"
   )
   assert(cleaner.execute(preview) > 0, "temporary cleanup removed nothing")
   assert(
      artifacts.read(root .. "/outside/important") == "untouched\n",
      "followed a symlink"
   )
   assert(
      artifacts.exists(checkout .. "/.cache/build/metadata/build.json"),
      "scope escaped"
   )
   assert(
      cleaner.execute(cleaner.plan(checkout, "all"), keep) > 0,
      "full cleanup removed nothing"
   )
   for _, path in ipairs({
      "/source.c",
      "/.cache/tools/lua/bin/lua",
      "/.cache/tools/automation.yml",
      "/.cache/ansible/local/live",
      "/.cache/logs/tasks/current/result.json",
   }) do
      assert(
         artifacts.exists(checkout .. path),
         "removed preserved state: " .. path
      )
   end

   assert(
      cleaner.execute(cleaner.plan(checkout, "all"), keep) == 0,
      "second cleanup changed state"
   )
   assert(
      not pcall(cleaner.plan, checkout, "../tools"),
      "scope traversal accepted"
   )
   assert(
      not pcall(cleaner.execute, { root = checkout, paths = { "source.c" } }),
      "unowned target accepted"
   )
   artifacts.write(
      checkout .. "/.cache/build/keep",
      "preflight must be atomic\n"
   )
   assert(not pcall(cleaner.execute, {
      root = checkout,
      paths = { ".cache/build", "source.c" },
   }), "invalid late target accepted")
   assert(
      artifacts.exists(checkout .. "/.cache/build/keep"),
      "preflight deleted an earlier target"
   )
   artifacts.mkdir(root .. "/linked")
   assert(uv.fs_symlink(root .. "/outside", root .. "/linked/.cache"))
   assert(
      not pcall(cleaner.plan, root .. "/linked", "all"),
      "symlinked cache root accepted"
   )
   artifacts.mkdir(root .. "/linked-tools/.cache")
   assert(
      uv.fs_symlink(root .. "/outside", root .. "/linked-tools/.cache/tools")
   )
   assert(
      not pcall(cleaner.plan, root .. "/linked-tools", "cache"),
      "symlinked tools parent accepted"
   )
   artifacts.platform.remove_temporary_directory(root)
   print(
      "Cleanup: scope, preview, idempotence, preserved tools "
         .. "and symlink boundaries passed."
   )
end

return CLEAN_TEST_main()

-- EOF


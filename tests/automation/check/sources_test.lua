-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Verify snapshots include new sources but never ignored dependency trees.

--- Inspect real Git inventory and prove source links are not dereferenced.
-- @return nil: no values.
local function SOURCES_TEST_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local sources = dofile("scripts/check/lib/sources.lua")
   local directory = artifacts.platform.temporary_directory("tmp")
   local repository = directory .. "/repository"
   local snapshot = directory .. "/snapshot"
   --- Check tracked, untracked and deleted paths in an isolated repository.
   -- @return nil: no values.
   local ok, failure = xpcall(function()
      artifacts.mkdir(repository)
      artifacts.run({ "git", "init", "--quiet", repository })
      artifacts.write(repository .. "/.gitignore", ".cache/\n")
      artifacts.write(repository .. "/tracked.lua", "tracked")
      artifacts.write(repository .. "/deleted.lua", "removed")
      artifacts.run({ "git", "-C", repository, "add", "." })
      assert(os.remove(repository .. "/deleted.lua"))
      artifacts.write(repository .. "/new source.lua", "new source")
      artifacts.write(repository .. "/.cache/dependency", "ignored dependency")
      artifacts.write(directory .. "/private", "outside bytes")
      artifacts.run({
         "ln",
         "-s",
         directory .. "/private",
         repository .. "/link",
      })
      assert(sources.snapshot(repository, snapshot) == 4, "wrong source count")
      assert(
         artifacts.read(snapshot .. "/new source.lua") == "new source",
         "new file omitted"
      )
      assert(
         artifacts.read(snapshot .. "/tracked.lua") == "tracked",
         "tracked file omitted"
      )
      assert(
         artifacts.read(snapshot .. "/link") == directory .. "/private",
         "link was followed"
      )
      assert(
         not artifacts.exists(snapshot .. "/.cache"),
         "ignored cache copied"
      )
      assert(
         not artifacts.exists(snapshot .. "/deleted.lua"),
         "deletion revived"
      )
   end, debug.traceback)

   artifacts.platform.remove_temporary_directory(directory)
   assert(ok, failure)
   print(
      "Source snapshot: additions, deletions, ignored caches and links passed."
   )
end

return SOURCES_TEST_main()

-- EOF


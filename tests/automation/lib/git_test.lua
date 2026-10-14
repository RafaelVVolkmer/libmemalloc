-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Check working-tree discovery without staging files or reviving deletions.

--- Preserve NUL-delimited names and fail when either Git query fails.
-- @return nil: no values.
local function GIT_TEST_main()
   local module = dofile("scripts/lib/git.lua")
   local inventory = "tracked.md\0new file.md\0deleted.md\0tracked.md\0"
   local deleted = "deleted.md\0"
   local port = {}

   --- Require the production queries and return controlled Git output.
   -- @param argv table: dense executable-and-arguments sequence; values remain
   -- literal.
   -- @return any: require the production queries and return controlled Git
   -- output.
   function port.command_output(argv)
      assert(argv[1] == "git" and argv[2] == "ls-files", "wrong Git query")
      assert(argv[3] == "-z", "filenames must be NUL-delimited")
      if argv[4] == "--deleted" then
         return deleted
      end

      assert(argv[4] == "--cached", "tracked files omitted")
      assert(argv[5] == "--others", "new files omitted")
      assert(argv[6] == "--exclude-standard", "ignored files included")

      return inventory
   end

   local git = module.new(port)

   assert(
      table.concat(git.working_files(), ",") == "new file.md,tracked.md",
      "working-tree inventory changed names or included deletions"
   )
   inventory = nil
   assert(git.working_files() == nil, "inventory failure became empty success")
   inventory, deleted = "tracked.md\0", nil
   assert(git.working_files() == nil, "deletion query failure was ignored")
   inventory, deleted = "", ""
   assert(#git.working_files() == 0, "empty working tree gained files")
   print("Git discovery: 4 working-tree inventory cases passed.")
end

return GIT_TEST_main()

-- EOF


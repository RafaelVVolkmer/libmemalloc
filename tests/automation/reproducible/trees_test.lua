-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Reject changed installed bytes, permissions, links and file-set additions.
-- Part of reconstruction regression tests; fixtures are private and disposable.

--- Exercise comparison against filesystem mutations, including shared-library
-- links.
-- @return nil: no values.
local function TREES_TEST_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local trees = dofile("scripts/reproducible/lib/trees.lua")
   local uv = require("luv")
   local root = artifacts.platform.temporary_directory("tests")
   local first, second = root .. "/first", root .. "/second"

   artifacts.mkdir(first)
   artifacts.mkdir(second)
   assert(
      not pcall(trees.compare, first, second),
      "empty installations accepted"
   )
   artifacts.write(first .. "/lib.so.1", "original bytes\n")
   artifacts.write(second .. "/lib.so.1", "original bytes\n")
   assert(uv.fs_symlink("lib.so.1", first .. "/lib.so"))
   assert(uv.fs_symlink("lib.so.1", second .. "/lib.so"))
   assert(trees.compare(first, second), "identical installations rejected")

   artifacts.write(second .. "/lib.so.1", "changed bytes\n")
   assert(not trees.compare(first, second), "changed bytes accepted")
   artifacts.write(second .. "/lib.so.1", "original bytes\n")
   artifacts.write(second .. "/unexpected", "extra\n")
   assert(not trees.compare(first, second), "extra file accepted")
   assert(uv.fs_unlink(second .. "/unexpected"))
   assert(uv.fs_chmod(second .. "/lib.so.1", 384))
   assert(not trees.compare(first, second), "permission drift accepted")
   assert(
      uv.fs_chmod(
         second .. "/lib.so.1",
         assert(uv.fs_stat(first .. "/lib.so.1")).mode
      )
   )
   assert(uv.fs_unlink(second .. "/lib.so"))
   assert(uv.fs_symlink("../outside", second .. "/lib.so"))
   assert(not pcall(trees.compare, first, second), "escaping link accepted")
   artifacts.platform.remove_temporary_directory(root)
   print(
      "Installed tree comparisons reject byte, mode, file-set and link drift."
   )
end

return TREES_TEST_main()

-- EOF


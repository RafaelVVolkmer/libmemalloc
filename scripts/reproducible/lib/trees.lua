-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Inventory and compare installed trees, including shared-library symlinks.
-- Part of build reconstruction; timestamps are excluded, file modes are
-- retained.

--- Construct the tree comparison API without performing filesystem work.
-- @return table: public operations constructed by this module.
local function REPRODUCIBLE_TREES_load()
   local uv = require("luv")
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local exports = {}

   --- Walk one installation and record regular bytes, modes and relative links.
   -- @param root string: installation root owned by the current build.
   -- @return table: sorted records, including empty directories.
   local function REPRODUCIBLE_TREES_inventory(root)
      local entries = artifacts.array()
      local regular_files = 0

      --- Traverse one directory without following links outside the
      -- installation.
      -- @param relative any: relative supplied to this operation.
      -- @return nil: no values.
      local function visit(relative)
         local directory = relative == "" and root or root .. "/" .. relative
         local scan = assert(uv.fs_scandir(directory))

         while true do
            local name = uv.fs_scandir_next(scan)

            if not name then
               break
            end

            local path = relative == "" and name or relative .. "/" .. name
            local full = root .. "/" .. path
            local stat = assert(uv.fs_lstat(full))
            local entry = { path = path, kind = stat.type, mode = stat.mode }

            --- Record file content or validate a sibling-only symbolic link.
            -- @return nil: no values.
            local function trees_describeEntry()
               if stat.type == "file" then
                  regular_files = regular_files + 1
                  entry.sha256 = artifacts.digest(full)
                  entry.size = stat.size
               elseif stat.type == "link" then
                  entry.target = assert(uv.fs_readlink(full))
                  assert(
                     entry.target:match("^[%w_.+-]+$")
                        and entry.target ~= "."
                        and entry.target ~= "..",
                     "installation links must reference siblings"
                  )
               elseif stat.type ~= "directory" then
                  error("unsupported installed file type: " .. stat.type)
               end
            end

            trees_describeEntry()

            entries[#entries + 1] = entry
            if stat.type == "directory" then
               visit(path)
            end
         end
      end

      visit("")
      assert(regular_files > 0, "installed tree has no regular artifacts")
      --- Order entries by relative path for deterministic tree comparison.
      -- @param left table: left supplied to this operation.
      -- @param right table: right supplied to this operation.
      -- @return boolean: order entries by relative path for deterministic tree
      -- comparison.
      table.sort(entries, function(left, right)
         return left.path < right.path
      end)

      return entries
   end

   exports.inventory = REPRODUCIBLE_TREES_inventory

   --- Require matching file sets, permissions, link targets and original bytes.
   -- @return boolean, table, table: equality and both inventories for evidence.
   -- @param first any: first supplied to this operation.
   -- @param second any: second supplied to this operation.
   local function REPRODUCIBLE_TREES_compare(first, second)
      local left = REPRODUCIBLE_TREES_inventory(first)
      local right = REPRODUCIBLE_TREES_inventory(second)
      local same = artifacts.json(left) == artifacts.json(right)

      if same then
         for _, entry in ipairs(left) do
            if entry.kind == "file" then
               same = same
                  and artifacts.read(first .. "/" .. entry.path)
                     == artifacts.read(second .. "/" .. entry.path)
            end
         end
      end

      return same, left, right
   end

   exports.compare = REPRODUCIBLE_TREES_compare

   return exports
end

return REPRODUCIBLE_TREES_load()

-- EOF


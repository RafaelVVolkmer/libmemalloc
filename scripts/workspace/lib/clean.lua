-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Remove only disposable repository paths, without traversing symlinks.
-- @return table: public operations constructed by this module.
local function CLEAN_loadModule()
   local uv = require("luv")
   local exports = {}
   local groups = {
      build = {
         "build",
         "install",
         "docs",
         "metadata",
         "ci",
         "cd",
         "logs",
         "validation",
      },
      cache = {
         "downloads",
         "tools/uv-cache",
         "tools/npm",
         "tools/pip",
         "ruff",
         "tools/go-build",
         "tools/xdg",
      },
      temporary = { "tmp", "tests" },
   }

   --- Check every parent before inspecting an allowlisted cleanup target.
   -- @param root string: root directory for this operation.
   -- @param relative string: relative supplied to this operation.
   -- @return boolean: check every parent before inspecting an allowlisted
   -- cleanup target.
   local function clean_parent(root, relative)
      local current = root

      for part in relative:gmatch("([^/]+)/") do
         current = current .. "/" .. part
         local info = uv.fs_lstat(current)
         if not info then
            return false
         end

         assert(
            info.type == "directory",
            "cleanup parent is not a directory: " .. current
         )
      end

      return true
   end

   --- Build a read-only plan rooted in the actual checkout directory.
   -- @param root string: root directory for this operation.
   -- @param scope any: scope supplied to this operation.
   -- @return table: a read-only plan rooted in the actual checkout directory.
   function exports.plan(root, scope)
      assert(
         scope == "all" or groups[scope],
         "--scope must be all, build, cache or temporary"
      )
      root = assert(uv.fs_realpath(root))
      local plan = { root = root, paths = {} }

      for name, paths in pairs(groups) do
         if scope == "all" or scope == name then
            for _, path in ipairs(paths) do
               local relative = ".cache/" .. path
               if
                  clean_parent(root, relative)
                  and uv.fs_lstat(root .. "/" .. relative)
               then
                  plan.paths[#plan.paths + 1] = relative
               end
            end
         end
      end

      table.sort(plan.paths)
      exports.validate(plan)

      return plan
   end

   --- Validate the complete selection before any deletion, including nested
   --- mounts.
   -- @param plan table: validated execution plan.
   -- @return nil: no values.
   function exports.validate(plan)
      local device = assert(uv.fs_stat(plan.root)).dev
      local allowed = {}

      for _, paths in pairs(groups) do
         for _, path in ipairs(paths) do
            allowed[".cache/" .. path] = true
         end
      end

      --- Inspect directories without following links to their targets.
      -- @param path string: filesystem path selected by the caller.
      -- @return nil: no values.
      local function inspect(path)
         local info = uv.fs_lstat(path)
         if not info or info.type ~= "directory" then
            return
         end

         assert(
            info.dev == device,
            "cleanup refuses a mounted directory: " .. path
         )
         local entries = assert(uv.fs_scandir(path))

         while true do
            local name = uv.fs_scandir_next(entries)
            if not name then
               break
            end

            inspect(path .. "/" .. name)
         end
      end

      for _, relative in ipairs(plan.paths) do
         assert(allowed[relative], "unowned cleanup path")
         if clean_parent(plan.root, relative) then
            inspect(plan.root .. "/" .. relative)
         end
      end
   end

   --- Apply the same repository checks to preview and execution.
   -- @param scope any: scope supplied to this operation.
   -- @return any: apply the same repository checks to preview and execution.
   function exports.repository_plan(scope)
      local artifacts = dofile("scripts/lib/artifacts.lua")
      local root = artifacts.output({ "git", "rev-parse", "--show-toplevel" })

      assert(uv.fs_realpath(".") == root, "run clean from the repository root")
      assert(
         artifacts.output({ "git", "ls-files", "--", ".cache" }) == "",
         "cleanup refuses tracked cache files"
      )

      return exports.plan(root, scope)
   end

   --- Remove directory entries without following links or crossing mounts.
   -- @param plan table: validated execution plan.
   -- @param preserve any: preserve supplied to this operation.
   -- @return number: remove directory entries without following links or
   -- crossing mounts.
   function exports.execute(plan, preserve)
      exports.validate(plan)
      local removed = 0
      local device = assert(uv.fs_stat(plan.root)).dev

      --- Compare complete path components rather than raw string prefixes.
      -- @param path string: filesystem path selected by the caller.
      -- @param parent any: parent supplied to this operation.
      -- @return boolean|nil: compare complete path components rather than raw
      -- string prefixes.
      local function inside(path, parent)
         return path
            and parent
            and (path == parent or path:sub(1, #parent + 1) == parent .. "/")
      end

      --- Keep the current supervisor's diagnostics and its ancestor folders.
      -- @param path string: filesystem path selected by the caller.
      -- @return nil: no values.
      local function remove(path)
         if inside(path, preserve) then
            return
         end

         local info = uv.fs_lstat(path)
         if not info then
            return
         end

         if info.type == "directory" then
            assert(
               info.dev == device,
               "cleanup refuses a mounted directory: " .. path
            )
            local entries = assert(uv.fs_scandir(path))

            while true do
               local name = uv.fs_scandir_next(entries)
               if not name then
                  break
               end

               remove(path .. "/" .. name)
            end

            if inside(preserve, path) then
               return
            end

            assert(uv.fs_rmdir(path))
         else
            assert(uv.fs_unlink(path))
         end

         removed = removed + 1
      end

      for _, relative in ipairs(plan.paths) do
         if clean_parent(plan.root, relative) then
            remove(plan.root .. "/" .. relative)
         end
      end

      return removed
   end

   return exports
end

return CLEAN_loadModule()

-- EOF


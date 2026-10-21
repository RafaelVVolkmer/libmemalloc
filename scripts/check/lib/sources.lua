-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Export Git sources without following links or copying ignored caches.
-- Snapshots include untracked sources and omit working-tree deletions.

--- Construct the source snapshot boundary with native file inspection.
-- @return table: public operations constructed by this module.
local function SOURCES_loadModule()
   local uv = require("luv")
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local exports = {}

   --- Reject absolute paths and traversal before any source is inspected.
   -- @param path string: repository-relative entry from the Git inventory.
   -- @return number: reject absolute paths and traversal before any source is
   -- inspected.
   local function sources_validatePath(path)
      local ret = 0

      assert(
         path:sub(1, 1) ~= "/" and not path:find("%z"),
         "unsafe source path"
      )

      for part in path:gmatch("[^/]+") do
         assert(part ~= "." and part ~= "..", "source path traversal")
      end

      ::function_output::

      return ret
   end

   --- Read link text or a regular file contained in the canonical repository.
   -- @return string: owned bytes; filesystem and containment failures raise.
   -- @param source any: source value inspected by this operation.
   -- @param kind any: kind supplied to this operation.
   -- @param base any: base supplied to this operation.
   local function sources_readEntry(source, kind, base)
      local ret = nil

      if kind == "link" then
         ret = assert(uv.fs_readlink(source))
      else
         assert(
            assert(uv.fs_realpath(source)):sub(1, #base) == base,
            "source escapes repository through a link"
         )

         ret = artifacts.read(source)
      end

      ::function_output::

      return ret
   end

   --- Copy regular sources and link text; leave submodule directories separate.
   -- @return integer: copied entries, including recursively copied submodules.
   -- Resolve the repository root once; check individual file paths.
   -- @param repository any: repository supplied to this operation.
   -- @param destination string: destination path owned by the invoking
   -- operation.
   local function SOURCES_snapshot(repository, destination)
      local git =
         dofile("scripts/lib/git.lua").new(artifacts.platform, repository)
      local files = assert(git.working_files(), "cannot inventory Git sources")
      local base = assert(uv.fs_realpath(repository)) .. "/"
      local copied = 0

      for _, path in ipairs(files) do
         sources_validatePath(path)

         local source = repository .. "/" .. path
         local stat = assert(uv.fs_lstat(source), "missing source: " .. path)

         if stat.type == "file" or stat.type == "link" then
            local content = sources_readEntry(source, stat.type, base)

            artifacts.write(destination .. "/" .. path, content)
            copied = copied + 1
         else
            assert(
               stat.type == "directory",
               "unsupported source type: " .. path
            )
            -- A tracked directory is a submodule, never an ignored cache tree.
            copied = copied
               + exports.snapshot(source, destination .. "/" .. path)
         end
      end

      return copied
   end

   exports.snapshot = SOURCES_snapshot

   return exports
end

return SOURCES_loadModule()

-- EOF


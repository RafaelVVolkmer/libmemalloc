-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer
-- <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Generic path helpers shared by Libmemalloc Lua tooling.
-- Repository paths are normalized to forward slashes on every host OS.
-- Part of shared host, path and artifact primitives.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_lib_paths_loadModule()
   local exports = {}

   --- Normalize path separators and redundant separators.
   -- @param value string: path to normalize.
   -- @return string: normalized path.
   local function PATHS_normalize(value)
      local path = tostring(value or ""):gsub("\\", "/")
      local unc = path:sub(1, 2) == "//"

      if unc then
         path = path:sub(3)
      end

      path = path:gsub("/+", "/")

      if unc then
         path = "//" .. path
      elseif path:sub(1, 2) == "./" then
         path = path:sub(3)
      end

      local drive_root = path:match("^%a:/$") ~= nil

      if #path > 1 and path:sub(-1) == "/" and not drive_root then
         path = path:sub(1, -2)
      end

      return path
   end

   exports.normalize = PATHS_normalize

   --- Return the directory component of a path.
   -- @param value string: path to inspect.
   -- @return string: parent directory or '.'.
   local function PATHS_dirname(value)
      local path = exports.normalize(value)
      local parent = path:match("^(.*)/[^/]*$")

      if not parent or parent == "" then
         return "."
      end

      return parent
   end

   exports.dirname = PATHS_dirname

   --- Join path components with normalized separators.
   -- @param ... string: path components.
   -- @return string: joined path.
   local function PATHS_join(...)
      local parts = { ... }
      local result = ""

      for _, part in ipairs(parts) do
         local value = exports.normalize(part)

         if value ~= "" and value ~= "." then
            if result == "" then
               result = value
            else
               result = result:gsub("/$", "") .. "/" .. value:gsub("^/", "")
            end
         end
      end

      if result == "" then
         return "."
      end

      return result
   end

   exports.join = PATHS_join

   --- Check whether a path starts with a prefix.
   -- @param value string: path to inspect.
   -- @param prefix string: normalized prefix.
   -- @return boolean: true when the prefix matches.
   local function PATHS_startsWith(value, prefix)
      local path = exports.normalize(value)
      local expected = exports.normalize(prefix)

      return path:sub(1, #expected) == expected
   end

   exports.starts_with = PATHS_startsWith

   --- Check whether a string ends with a suffix.
   -- @param value string: string to inspect.
   -- @param suffix string: suffix to find.
   -- @return boolean: true when the suffix matches.
   local function PATHS_endsWith(value, suffix)
      local text = tostring(value or "")
      local expected = tostring(suffix or "")

      if expected == "" then
         return true
      end

      return text:sub(-#expected) == expected
   end

   exports.ends_with = PATHS_endsWith

   --- Resolve the repository root from one ci entrypoint path.
   -- @param script_path string: arg[0] from a CI script.
   -- @return string: path to the scripts directory.
   local function PATHS_scriptsRoot(script_path)
      local path = exports.normalize(script_path)

      return path:match("^(.*)/[^/]+/[^/]+$") or "scripts"
   end

   exports.scripts_root = PATHS_scriptsRoot

   return exports
end

return scripts_lib_paths_loadModule()

-- EOF


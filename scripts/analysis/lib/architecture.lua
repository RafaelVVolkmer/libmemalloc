-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Interpret compiler-produced dependencies; never parse source includes by
-- regex.
-- Part of compiler analysis and module-boundary evidence.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_analysis_lib_architecture_loadModule()
   local exports = {}

   --- Decode escaped compiler dependency paths; reject truncated or empty
   -- inventories.
   -- @param content string: input bytes to process.
   -- @return table: escaped compiler dependency paths; reject truncated or
   -- empty inventories.
   local function ANALYSIS_ARCHITECTURE_dependencies(content)
      local body =
         assert(content:match("^deps:%s*(.*)$"), "unexpected dependency target")

      body = body:gsub("\\\r?\n", "")

      local result, word, escaped = {}, {}, false

      for index = 1, #body do
         local character = body:sub(index, index)

         if escaped then
            word[#word + 1] = character
            escaped = false
         elseif character == "\\" then
            escaped = true
         elseif character:match("%s") then
            if #word > 0 then
               result[#result + 1] = table.concat(word)
               word = {}
            end
         else
            word[#word + 1] = character
         end
      end

      assert(not escaped, "truncated dependency escape")
      if #word > 0 then
         result[#result + 1] = table.concat(word)
      end

      assert(#result > 0, "empty dependency inventory")

      return result
   end

   exports.dependencies = ANALYSIS_ARCHITECTURE_dependencies

   --- Select the longest declared module root that contains the source path.
   -- @param path string: filesystem path selected by the caller.
   -- @param modules any: modules supplied to this operation.
   -- @return any: the longest declared module root that contains the source
   -- path.
   local function ANALYSIS_ARCHITECTURE_owner(path, modules)
      local selected

      for _, module in ipairs(modules) do
         assert(module.root:sub(-1) == "/", "module root must end with slash")
         if path:sub(1, #module.root) == module.root then
            if not selected or #module.root > #selected.root then
               selected = module
            end
         end
      end

      return selected
   end

   exports.owner = ANALYSIS_ARCHITECTURE_owner

   --- Reject dependencies that cross a module boundary through a private
   -- header.
   -- @param source any: source value inspected by this operation.
   -- @param dependencies any: dependencies supplied to this operation.
   -- @param modules any: modules supplied to this operation.
   -- @return boolean: reject dependencies that cross a module boundary through
   -- a private header.
   local function ANALYSIS_ARCHITECTURE_check(source, dependencies, modules)
      local source_owner =
         assert(exports.owner(source, modules), "source lacks module ownership")

      for _, path in ipairs(dependencies) do
         local owner = exports.owner(path, modules)

         if owner and owner.name ~= source_owner.name then
            local public = false

            for _, header in ipairs(owner.public) do
               if header == path then
                  public = true
               end
            end

            assert(public, source .. " reaches private dependency " .. path)
         end
      end

      return true
   end

   exports.check = ANALYSIS_ARCHITECTURE_check

   --- Reject undeclared headers exposed by a public include directory.
   -- @param paths table: paths selected by the owning operation.
   -- @param modules any: modules supplied to this operation.
   -- @return boolean: reject undeclared headers exposed by a public include
   -- directory.
   local function ANALYSIS_ARCHITECTURE_publicHeaders(paths, modules)
      --- Collect existing public headers for one declared module.
      -- @param module table: module supplied to this operation.
      -- @return nil: no values.
      local function analysis_architecture_collectHeaders(module)
         for _, path in ipairs(paths) do
            if
               path:sub(1, #module.public_include) == module.public_include
               and path:match("%.h$")
            then
               local public = false

               for _, header in ipairs(module.public) do
                  if path == header then
                     public = true
                  end
               end

               assert(
                  public,
                  (
                     "public include directory exposes an "
                     .. "undeclared/private header: "
                  ) .. path
               )
            end
         end
      end

      for _, module in ipairs(modules) do
         analysis_architecture_collectHeaders(module)
      end

      return true
   end

   exports.public_headers = ANALYSIS_ARCHITECTURE_publicHeaders

   return exports
end

return scripts_analysis_lib_architecture_loadModule()

-- EOF


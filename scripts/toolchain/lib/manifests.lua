-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Project central identities into native package and workflow formats.
-- @return table: public operations constructed by this module.
local function MANIFESTS_loadModule()
   local exports = {}
   local policy = dofile("tools/toolchain/manifests.lua")

   --- Expand every identity reference; missing fields fail before any writes.
   -- @param source string: source supplied to this operation.
   -- @param lock any: lock supplied to this operation.
   -- @return any: expand every identity reference; missing fields fail before
   -- any writes.
   local function MANIFESTS_render(source, lock)
      --- Resolve one template token; reject missing identities before writing.
      -- @param name string: entry or operation name to resolve.
      -- @param field any: field supplied to this operation.
      -- @return any: one template token; reject missing identities before
      -- writing.
      local rendered = source:gsub("@([%w_]+)%.([%w_]+)@", function(name, field)
         return assert(
            lock[name] and lock[name][field],
            "unknown identity: " .. name .. "." .. field
         )
      end)

      return rendered
   end

   exports.render = MANIFESTS_render

   --- Refresh literal Action references required by GitHub's workflow schema.
   -- @param source string: source supplied to this operation.
   -- @param lock any: lock supplied to this operation.
   -- @return any: refresh literal Action references required by GitHub's
   -- workflow schema.
   local function MANIFESTS_workflow(source, lock)
      for action in source:gmatch("uses:%s*[\"']?([^%s\"']+)") do
         assert(
            action:match("^%./") or action:match("^[%w_./%-]+@[%w.-]+$"),
            "Action must use a registered revision: " .. action
         )
      end

      return (
         source:gsub(
            "(uses:%s*[\"']?)([%w_./%-]+)@([%w.-]+)([^\n]*)",
            --- Preserve Action syntax while replacing its locked revision and
            -- version.
            -- @param prefix any: prefix supplied to this operation.
            -- @param action string: action supplied to this operation.
            -- @param _ any: callback argument intentionally unused.
            -- @param suffix string: suffix supplied to this operation.
            -- @return string: preserve Action syntax while replacing its locked
            -- revision and version.
            function(prefix, action, _, suffix)
               local repository = action:match("^([^/]+/[^/]+)")
               local identity = assert(
                  policy.actions[repository],
                  "unregistered Action: " .. action
               )
               local tool = assert(
                  lock[identity],
                  "missing Action identity: " .. identity
               )

               assert(
                  tool.revision and tool.version,
                  "incomplete Action identity: " .. identity
               )
               suffix = suffix:gsub("(# v)[%w.+%-]+", "%1" .. tool.version)

               return prefix .. action .. "@" .. tool.revision .. suffix
            end
         )
      )
   end

   exports.workflow = MANIFESTS_workflow

   --- Compute all expected bytes before the caller chooses check or write.
   -- @param lock any: lock supplied to this operation.
   -- @param read any: read supplied to this operation.
   -- @param files table: ordered source or artifact paths.
   -- @return table: all expected bytes before the caller chooses check or
   -- write.
   local function MANIFESTS_outputs(lock, read, files)
      local outputs = {}

      for path, template in pairs(policy.templates) do
         outputs[path] =
            exports.render(read("tools/toolchain/templates/" .. template), lock)
      end

      for _, path in ipairs(files) do
         if path:match("^%.github/.*%.ya?ml$") then
            outputs[path] = exports.workflow(read(path), lock)
         end
      end

      return outputs
   end

   exports.outputs = MANIFESTS_outputs

   return exports
end

return MANIFESTS_loadModule()

-- EOF


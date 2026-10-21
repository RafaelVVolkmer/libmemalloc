-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Parse only explicit SDD headings, anchored clauses and case fields.
-- @return table: public operations constructed by this module.
local function SDD_PARSE_loadModule()
   local M = {}

   --- Add one diagnostic with its source document.
   -- @param model table: parsed specification model and accumulated findings.
   -- @param path string: filesystem path selected by the caller.
   -- @param message string: diagnostic text retained by this operation.
   -- @return nil: no values.
   local function reject(model, path, message)
      model.failures[#model.failures + 1] = path .. ": " .. message
   end

   --- Examples and HTML comments are not authoritative definitions.
   -- @param source string: source supplied to this operation.
   -- @return any: examples and HTML comments are not authoritative definitions.
   local function visible(source)
      local lines, fence = {}, nil

      source = source:gsub("<!%-%-.-%-%->", "")
      for line in (source .. "\n"):gmatch("([^\n]*)\n") do
         local marker = line:match("^%s*(```+)") or line:match("^%s*(~~~+)")
         if marker then
            if not fence then
               fence = marker
            elseif
               marker:sub(1, 1) == fence:sub(1, 1)
               and #marker >= #fence
            then
               fence = nil
            end

            lines[#lines + 1] = ""
         elseif fence then
            lines[#lines + 1] = ""
         else
            lines[#lines + 1] = line
         end
      end

      return table.concat(lines, "\n")
   end

   --- Definitions require one matching explicit anchor in their own document.
   -- @param model table: parsed specification model and accumulated findings.
   -- @param path string: filesystem path selected by the caller.
   -- @param id string: stable identity used to match the requested entry.
   -- @param body any: body supplied to this operation.
   -- @param category any: category supplied to this operation.
   -- @return nil: no values.
   local function define(model, path, id, body, category)
      if model.definitions[id] then
         reject(model, path, "duplicate definition " .. id)

         return
      end

      local item = { id = id, path = path, body = body }

      model.definitions[id] = item
      model[category][id] = item
      model.counts[category] = model.counts[category] + 1
      if not model.anchors[path][id:lower()] then
         reject(model, path, "missing anchor for " .. id)
      end
   end

   --- Preserve heading boundaries in the visible document text.
   -- @param source any: source value inspected by this operation.
   -- @return table: preserve heading boundaries in the visible document text.
   local function headings(source)
      local result, offset = {}, 1

      for line in (source .. "\n"):gmatch("([^\n]*)\n") do
         local hashes, title = line:match("^(#+) (.+)$")
         if hashes then
            result[#result + 1] = {
               level = #hashes,
               title = title,
               offset = offset,
               body = offset + #line + 1,
            }
         end

         offset = offset + #line + 1
      end

      return result
   end

   --- Find the end of a heading's subtree.
   -- @param all table: all supplied to this operation.
   -- @param index number: one-based position in the current sequence.
   -- @param source any: source value inspected by this operation.
   -- @return any: the end of a heading's subtree.
   local function ending(all, index, source)
      for following = index + 1, #all do
         if all[following].level <= all[index].level then
            return all[following].offset - 1
         end
      end

      return #source
   end

   --- Collect IDs only from headings with the declared depth and grammar.
   -- @param model table: parsed specification model and accumulated findings.
   -- @param path string: filesystem path selected by the caller.
   -- @param source string: source supplied to this operation.
   -- @return nil: no values.
   local function sections(model, path, source)
      local all = headings(source)

      for index, heading in ipairs(all) do
         local id = heading.title:match("^(LMA%-%u+%-%d%d%d):")
         local category = "controls"
         if heading.level == 3 then
            id = heading.title:match("^(LMA%-TEST%-CASE%-%d%d%d%d)%f[%D]")
               or heading.title:match("^(LMA%-TEST%-CASE%-%d%d%d%d)$")
            category = "cases"
         elseif heading.level ~= 2 then
            id = nil
         end

         if id then
            local body = source:sub(heading.body, ending(all, index, source))

            define(model, path, id, body, category)
         end
      end
   end

   --- Anchor duplicates are invalid even when the duplicate has no heading.
   -- @param model table: parsed specification model and accumulated findings.
   -- @param path string: filesystem path selected by the caller.
   -- @param source string: source supplied to this operation.
   -- @return nil: no values.
   local function anchors(model, path, source)
      model.anchors[path] = {}
      for id in source:gmatch('<a id="([^"]+)"></a>') do
         if model.anchors[path][id] then
            reject(model, path, "duplicate anchor " .. id)
         end

         model.anchors[path][id] = true
      end
   end

   --- Parse atomic requirements and invariants independently of references.
   -- @param model table: parsed specification model and accumulated findings.
   -- @param path string: filesystem path selected by the caller.
   -- @param source string: source supplied to this operation.
   -- @return nil: no values.
   local function clauses(model, path, source)
      for id, text in
         source:gmatch("%*%*(LMA%-%u+%-%d%d%d%-[RI]%d%d)%.%*%*%s*(.-)\n\n")
      do
         define(model, path, id, text, "clauses")
         if id:match("%-R%d%d$") then
            model.requirements[id] = model.definitions[id]
            model.counts.requirements = model.counts.requirements + 1
         end
      end
   end

   --- Reject dangling identifier anchors, including malformed or mistyped IDs.
   -- @param model table: parsed specification model and accumulated findings.
   -- @return nil: no values.
   local function orphan_anchors(model)
      for path, ids in pairs(model.anchors) do
         for id in pairs(ids) do
            if id:match("^lma%-") then
               local definition = model.definitions[id:upper()]
               if not definition or definition.path ~= path then
                  reject(model, path, "orphan ID anchor " .. id)
               end
            end
         end
      end
   end

   --- Build one cross-document index; callers own loading and reporting.
   -- @param documents any: documents supplied to this operation.
   -- @return table: one cross-document index; callers own loading and
   -- reporting.
   function M.parse(documents)
      local model = {
         controls = {},
         clauses = {},
         requirements = {},
         cases = {},
         anchors = {},
         definitions = {},
         failures = {},
         coverage = {},
         counts = { controls = 0, clauses = 0, requirements = 0, cases = 0 },
      }

      for path, source in pairs(documents) do
         source = visible(source)
         anchors(model, path, source)
         sections(model, path, source)
         clauses(model, path, source)
      end

      orphan_anchors(model)

      return model
   end

   return M
end

return SDD_PARSE_loadModule()

-- EOF


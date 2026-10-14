-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Validate specification structure and planned verification allocation.
-- @return table: public operations constructed by this module.
local function SDD_loadModule()
   local SDD_MIN_FIELD_BYTES = 12
   local SDD_MIN_SCENARIO_BYTES = 24

   local M = {}
   local parser = dofile("scripts/check/lib/sdd_parse.lua")

   --- Retain all diagnostics so one edit can repair related defects.
   -- @param model table: parsed specification model and accumulated findings.
   -- @param id string: stable identity used to match the requested entry.
   -- @param message string: diagnostic text retained by this operation.
   -- @return nil: no values.
   local function reject(model, id, message)
      model.failures[#model.failures + 1] = id .. ": " .. message
   end

   --- Read a metadata paragraph, stopping before the next named field.
   -- @param body string: body supplied to this operation.
   -- @param name string: entry or operation name to resolve.
   -- @return any: a metadata paragraph, stopping before the next named field.
   local function field(body, name)
      local value = body:match("%*%*" .. name .. ":%*%*%s*(.-)\n\n")
      if value then
         return value:match("^(.-)%*%*") or value
      end

      return nil
   end

   --- Require a meaningful paragraph, not only a marker.
   -- @param model table: parsed specification model and accumulated findings.
   -- @param item table: item supplied to this operation.
   -- @param name string: entry or operation name to resolve.
   -- @return any: require a meaningful paragraph, not only a marker.
   local function require_field(model, item, name)
      local value = field(item.body .. "\n\n", name)
      if not value or #value:gsub("%s", "") < SDD_MIN_FIELD_BYTES then
         reject(model, item.id, "missing or empty " .. name)
      end

      return value or ""
   end

   --- Validate a finite metadata vocabulary.
   -- @param model table: parsed specification model and accumulated findings.
   -- @param item table: item supplied to this operation.
   -- @param name string: entry or operation name to resolve.
   -- @param accepted table: accepted supplied to this operation.
   -- @return any: validate a finite metadata vocabulary.
   local function choice(model, item, name, accepted)
      local value = item.body:match("%*%*" .. name .. ":%*%*%s*([%w_]+)")
      if not accepted[value or ""] then
         reject(model, item.id, "invalid or missing " .. name)
      end

      return value
   end

   --- A control declares scope independently of its roadmap phase.
   -- @param model table: parsed specification model and accumulated findings.
   -- @param item table: item supplied to this operation.
   -- @return nil: no values.
   local function control(model, item)
      choice(model, item, "Phase", {
         P0 = true,
         P1 = true,
         P2 = true,
         P3 = true,
         P4 = true,
         P5 = true,
      })
      choice(model, item, "Status", { PROPOSED = true })
      local membership = {
         REQUIRED = true,
         OPTIONAL = true,
         DEFERRED = true,
      }
      local manual = choice(model, item, "M0", membership)
      local managed = choice(model, item, "G0", membership)
      if manual == "REQUIRED" and managed ~= "REQUIRED" then
         reject(model, item.id, "G0 must retain required M0 controls")
      end

      if item.id:match("^LMA%-GC%-") then
         choice(model, item, "M0", { DEFERRED = true })
      end
   end

   --- Requirements and invariants belong to a real control in the same file.
   -- @param model table: parsed specification model and accumulated findings.
   -- @param item table: item supplied to this operation.
   -- @return nil: no values.
   local function ownership(model, item)
      local owner = model.controls[item.id:match("^(.-)%-[RI]%d+$")]
      if not owner or owner.path ~= item.path then
         reject(model, item.id, "missing or foreign owner control")

         return
      end

      if not owner.body:find("**" .. item.id .. ".**", 1, true) then
         reject(model, item.id, "definition outside its owner control")
      end
   end

   --- Resolve explicit Markdown links against definitions and local anchors.
   -- @param model table: parsed specification model and accumulated findings.
   -- @param item table: item supplied to this operation.
   -- @param label string: diagnostic or evidence label for this operation.
   -- @param target any: selected target configuration or path.
   -- @param definitions table: definitions supplied to this operation.
   -- @return boolean: explicit Markdown links against definitions and local
   -- anchors.
   local function linked(model, item, label, target, definitions)
      local definition = definitions[label]
      if not definition then
         reject(model, item.id, "unknown linked ID " .. label)

         return false
      end

      local expected = definition.path:match("[^/]+$") .. "#" .. label:lower()
      if target ~= expected then
         reject(model, item.id, "wrong target for " .. label)

         return false
      end

      return true
   end

   --- Keep review assertions synchronized with their normative clauses.
   -- @param model table: parsed specification model and accumulated findings.
   -- @param item table: item supplied to this operation.
   -- @param label string: diagnostic or evidence label for this operation.
   -- @return nil: no values.
   local function review_clause(model, item, label)
      local marker = "- `" .. label .. "`: "
      local first, last = item.body:find(marker, 1, true)
      if not first then
         reject(model, item.id, "missing review clause " .. label)

         return
      end

      local text = item.body:sub(last + 1)
      local ending = math.min(
         text:find("\n- ", 1, true) or #text + 1,
         text:find("\n\n", 1, true) or #text + 1
      )

      text = text:sub(1, ending - 1):gsub("%s+", " ")
      local required = model.requirements[label].body:gsub("%s+", " ")
      if text ~= required then
         reject(model, item.id, "stale review clause " .. label)
      end
   end

   --- Link cases to individual requirements, never implicitly to all clauses.
   -- @param model table: parsed specification model and accumulated findings.
   -- @param item table: item supplied to this operation.
   -- @param method any|nil: method supplied to this operation.
   -- @return nil: no values.
   local function requirements(model, item, method)
      local value = require_field(model, item, "Requirements")
      local count, seen = 0, {}

      for label, target in value:gmatch("%[([^%]]+)%]%(([^%)]+)%)") do
         if seen[label] then
            reject(model, item.id, "duplicate requirement " .. label)
         end

         seen[label] = true
         if linked(model, item, label, target, model.requirements) then
            count = count + 1
            model.coverage[label] = model.coverage[label] or {}
            model.coverage[label][method or "INVALID"] = true
            if method == "REVIEW" then
               review_clause(model, item, label)
            end
         end
      end

      if count == 0 then
         reject(model, item.id, "no valid individual requirement links")
      end
   end

   --- A case owner may differ from the control owning an exercised clause.
   -- @param model table: parsed specification model and accumulated findings.
   -- @param item table: item supplied to this operation.
   -- @return nil: no values.
   local function case_owner(model, item)
      local label, target =
         item.body:match("%*%*Control:%*%*%s*%[([^%]]+)%]%(([^%)]+)%)")
      if not label then
         reject(model, item.id, "missing Control link")

         return
      end

      linked(model, item, label, target, model.controls)
   end

   --- Keep rejected boilerplate out of acceptance criteria.
   -- @param model table: parsed specification model and accumulated findings.
   -- @param item table: item supplied to this operation.
   -- @return nil: no values.
   local function oracle(model, item)
      local text = field(item.body, "Acceptance oracle")
         or field(item.body, "Oracle and accept")
      if not text or #text:gsub("%s", "") < SDD_MIN_SCENARIO_BYTES then
         reject(model, item.id, "missing acceptance oracle")

         return
      end

      for _, phrase in ipairs({
         "requirements and invariants of linked control",
         "the properties explained in the scenario",
      }) do
         if text:find(phrase, 1, true) then
            reject(model, item.id, "generic acceptance oracle")
         end
      end
   end

   --- Planned product checks cannot acquire PASS from document validation.
   -- @param model table: parsed specification model and accumulated findings.
   -- @param item any: entry currently being inspected.
   -- @return nil: no values.
   local function case(model, item)
      choice(model, item, "Status", { PLANNED = true })
      local method = choice(model, item, "Verification", {
         SCENARIO = true,
         REVIEW = true,
      })

      case_owner(model, item)
      requirements(model, item, method)
      require_field(model, item, "Precondition/capacity")
      require_field(model, item, "Procedure")
      require_field(model, item, "Evidence")
      oracle(model, item)
   end

   --- Validate known identifiers remain present instead of silently renumbered.
   -- @param model table: parsed specification model and accumulated findings.
   -- @param id string: stable identity used to match the requested entry.
   -- @param counts table: accumulated counters indexed by category.
   -- @param known table: known supplied to this operation.
   -- @return nil: no values.
   local function stable_control(model, id, counts, known)
      known[id] = true
      if not model.controls[id] then
         reject(model, id, "published control removed")
      end

      for index, kind in ipairs({ "R", "I" }) do
         for number = 1, counts[index] do
            local key = id .. "-" .. kind .. string.format("%02d", number)

            known[key] = true
            if not model.definitions[key] then
               reject(model, key, "published clause removed")
            end
         end
      end
   end

   --- The inventory is versioned separately from document definitions.
   -- @param model table: parsed specification model and accumulated findings.
   -- @param inventory table: inventory supplied to this operation.
   -- @return nil: no values.
   local function stable_ids(model, inventory)
      local known = {}

      for id, counts in pairs(inventory.controls) do
         stable_control(model, id, counts, known)
      end

      for number = 1, inventory.cases do
         local id = string.format("LMA-TEST-CASE-%04d", number)

         known[id] = true
         if not model.cases[id] then
            reject(model, id, "published case removed")
         end
      end

      for id in pairs(model.definitions) do
         if not known[id] then
            reject(model, id, "ID missing from published inventory")
         end
      end
   end

   --- Report scenario allocation separately from review-only obligations.
   -- @param model table: parsed specification model and accumulated findings.
   -- @return table: report scenario allocation separately from review-only
   -- obligations.
   local function coverage(model)
      local counts = { scenario = 0, review_only = 0 }

      for id in pairs(model.requirements) do
         local methods = model.coverage[id] or {}
         if methods.SCENARIO then
            counts.scenario = counts.scenario + 1
         elseif methods.REVIEW then
            counts.review_only = counts.review_only + 1
         else
            reject(model, id, "requirement has no planned verification")
         end
      end

      return counts
   end

   --- Check supplied documents without filesystem or subprocess effects.
   -- @param documents any: documents supplied to this operation.
   -- @param inventory any: inventory supplied to this operation.
   -- @return any, any: check supplied documents without filesystem or
   -- subprocess effects.
   function M.check(documents, inventory)
      local model = parser.parse(documents)

      for _, item in pairs(model.controls) do
         control(model, item)
      end

      for _, item in pairs(model.clauses) do
         ownership(model, item)
      end

      for _, item in pairs(model.cases) do
         case(model, item)
      end

      if inventory then
         stable_ids(model, inventory)
      end

      model.counts.coverage = coverage(model)
      table.sort(model.failures)

      return model.failures, model.counts
   end

   return M
end

return SDD_loadModule()

-- EOF


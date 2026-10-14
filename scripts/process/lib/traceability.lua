-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Validate requirement links and derive a graph from assessed observations.
-- Catalog entries describe obligations; only execution records supply status.

--- Construct pure traceability policy and rendering operations.
-- @return table: public operations constructed by this module.
local function TRACEABILITY_loadModule()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local exports = {}

   --- Index a nonempty sequence and reject ambiguous identifiers.
   -- @param values table: values consumed in the operation’s declared order.
   -- @param fields any: fields supplied to this operation.
   -- @param pattern any: pattern supplied to this operation.
   -- @param policy table: reviewed policy controlling accepted inputs and
   -- limits.
   -- @return table: index a nonempty sequence and reject ambiguous identifiers.
   local function traceability_index(values, fields, pattern, policy)
      policy.sequence(values)
      assert(#values > 0, "empty traceability inventory")

      local indexed = {}

      for _, value in ipairs(values) do
         policy.fields(value, fields)
         assert(
            type(value.id) == "string" and value.id:match(pattern),
            "invalid traceability ID"
         )
         assert(not indexed[value.id], "duplicate traceability ID")
         indexed[value.id] = value
      end

      return indexed
   end

   --- Require nonempty, unique links to declared nodes.
   -- @param values table: values consumed in the operation’s declared order.
   -- @param indexed table: indexed supplied to this operation.
   -- @param used table: used supplied to this operation.
   -- @param policy table: reviewed policy controlling accepted inputs and
   -- limits.
   -- @return nil: no values.
   local function traceability_links(values, indexed, used, policy)
      policy.sequence(values)
      assert(#values > 0, "missing requirement links")

      local seen = {}

      for _, id in ipairs(values) do
         assert(indexed[id], "dangling traceability link")
         assert(not seen[id], "duplicate traceability link")
         seen[id], used[id] = true, true
      end
   end

   --- Reject orphan nodes and mismatched control ownership before planning.
   -- @param value any: value supplied to this operation.
   -- @param controls any: controls supplied to this operation.
   -- @param policy table: reviewed policy controlling accepted inputs and
   -- limits.
   -- @return any: reject orphan nodes and mismatched control ownership before
   -- planning.
   local function TRACEABILITY_validate(value, controls, policy)
      policy.fields(value, { "designs", "verifications", "requirements" })

      local designs = traceability_index(
         value.designs,
         { "id", "reference" },
         "^LMA%-DES%-[A-Z]+%-%d%d%d$",
         policy
      )
      local verifications = traceability_index(
         value.verifications,
         { "id", "kind", "control" },
         "^LMA%-TEST%-[A-Z]+%-%d%d%d$",
         policy
      )
      local requirements = traceability_index(
         value.requirements,
         { "id", "statement", "design", "verification" },
         "^LMA%-ENG%-%d%d%d$",
         policy
      )
      local by_control, used_controls, used_designs, used_verifications =
         {}, {}, {}, {}

      for _, control in ipairs(controls) do
         by_control[control.id] = control
      end

      for _, design in ipairs(value.designs) do
         assert(type(design.reference) == "string", "invalid design reference")
         local path = design.reference:match("^([^#]+)")

         artifacts.safe_path(assert(path, "empty design reference"))
         assert(
            path:match("^docs/.*%.md$"),
            "design must reference repository documentation"
         )
      end

      --- Validate a verification record against declared requirements.
      -- @param verification table: verification supplied to this operation.
      -- @return nil: no values.
      local function traceability_validateVerification(verification)
         assert(
            verification.kind == "unit"
               or verification.kind == "analysis"
               or verification.kind == "integration",
            "unsupported verification kind"
         )
         assert(
            by_control[verification.control],
            "unknown verification control"
         )
         assert(
            not used_controls[verification.control],
            "duplicate verification control"
         )
         used_controls[verification.control] = true
      end

      for _, verification in ipairs(value.verifications) do
         traceability_validateVerification(verification)
      end

      --- Validate one requirement and its declared verification links.
      -- @param requirement table: requirement supplied to this operation.
      -- @return nil: no values.
      local function traceability_validateRequirement(requirement)
         assert(
            type(requirement.statement) == "string"
               and requirement.statement:match("%S"),
            "missing requirement statement"
         )
         traceability_links(requirement.design, designs, used_designs, policy)
         traceability_links(
            requirement.verification,
            verifications,
            used_verifications,
            policy
         )
         for _, id in ipairs(requirement.verification) do
            assert(
               by_control[verifications[id].control].requirement
                  == requirement.id,
               "verification belongs to another requirement"
            )
         end
      end

      for _, requirement in ipairs(value.requirements) do
         traceability_validateRequirement(requirement)
      end

      for id, control in pairs(by_control) do
         assert(
            used_controls[id] and requirements[control.requirement],
            "untraced control"
         )
      end

      for id in pairs(designs) do
         assert(used_designs[id], "orphan design")
      end

      for id in pairs(verifications) do
         assert(used_verifications[id], "orphan verification")
      end

      return value
   end

   exports.validate = TRACEABILITY_validate

   --- Derive requirement outcomes without treating absent observations as pass.
   -- @param plan table: validated execution plan.
   -- @param digest string: expected content digest.
   -- @param observations any: observations supplied to this operation.
   -- @param array any: array supplied to this operation.
   -- @return table: requirement outcomes without treating absent observations
   -- as pass.
   local function TRACEABILITY_graph(plan, digest, observations, array)
      local verifications, records = {}, {}

      for _, verification in ipairs(plan.traceability.verifications) do
         verifications[verification.id] = verification
      end

      for _, record in ipairs(observations) do
         assert(not records[record.control], "duplicate graph observation")
         records[record.control] = record
      end

      local requirements = array()

      for _, requirement in ipairs(plan.traceability.requirements) do
         local evidence, passed = array(), true

         for _, id in ipairs(requirement.verification) do
            local verification =
               assert(verifications[id], "unknown graph verification")
            local record = assert(
               records[verification.control],
               "missing graph observation"
            )

            evidence[#evidence + 1] = {
               verification = id,
               kind = verification.kind,
               control = verification.control,
               status = record.state,
               artifact = verification.control .. "/result.json",
               sha256 = record.sha256,
            }
            passed = passed and record.state == "PASS"
         end

         requirements[#requirements + 1] = {
            requirement = requirement.id,
            statement = requirement.statement,
            design = requirement.design,
            status = passed and "PASS" or "FAIL",
            evidence = evidence,
         }
      end

      return {
         schema_version = 1,
         scope = plan.scope,
         run_id = plan.run_id,
         plan_sha256 = digest,
         policy_sha256 = plan.policy_sha256,
         source_sha256 = plan.subject.source_sha256,
         promotion_authorized = false,
         product_qualified = false,
         designs = plan.traceability.designs,
         requirements = requirements,
      }
   end

   exports.graph = TRACEABILITY_graph

   return exports
end

return TRACEABILITY_loadModule()

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Exercise graph completeness, ownership and requirement outcome reduction.

--- Reject broken links before they can become a passing evidence graph.
-- @return nil: no values.
local function TRACEABILITY_TEST_main()
   local policy = dofile("scripts/process/lib/policy.lua")
   local traceability = dofile("scripts/process/lib/traceability.lua")
   local evidence_io = dofile("scripts/process/lib/io.lua")
   local count = 0

   --- Load a fresh catalog so mutations never leak between cases.
   -- @return any: a fresh catalog so mutations never leak between cases.
   local function catalog()
      return evidence_io.load("tools/process/controls.json")
   end

   --- Count only mutations rejected by the production catalog boundary.
   -- @param mutate any: mutate supplied to this operation.
   -- @return nil: no values.
   local function rejects(mutate)
      local value = catalog()

      mutate(value.traceability, value)
      assert(not pcall(policy.catalog, value), "invalid traceability accepted")
      count = count + 1
   end

   --- Reject requirements omitted from the catalog.
   -- @param trace table: requirement and verification evidence graph.
   -- @return nil: no values.
   rejects(function(trace)
      trace.requirements = {}
   end)
   --- Reject duplicate requirement identifiers.
   -- @param trace table: requirement and verification evidence graph.
   -- @return nil: no values.
   rejects(function(trace)
      trace.requirements[2].id = trace.requirements[1].id
   end)
   --- Reject requirements without mandatory verifications.
   -- @param trace table: requirement and verification evidence graph.
   -- @return nil: no values.
   rejects(function(trace)
      trace.requirements[1].verification = {}
   end)
   --- Reject verification links outside the catalog.
   -- @param trace table: requirement and verification evidence graph.
   -- @return nil: no values.
   rejects(function(trace)
      trace.requirements[1].verification[1] = "LMA-TEST-UNIT-999"
   end)
   --- Reject repeated verification links.
   -- @param trace table: requirement and verification evidence graph.
   -- @return nil: no values.
   rejects(function(trace)
      trace.requirements[1].verification[2] =
         trace.requirements[1].verification[1]
   end)
   --- Reject a verification owned by another requirement.
   -- @param trace table: requirement and verification evidence graph.
   -- @return nil: no values.
   rejects(function(trace)
      trace.requirements[1].verification[1] =
         trace.requirements[2].verification[1]
   end)
   --- Reject a design link outside the catalog.
   -- @param trace table: requirement and verification evidence graph.
   -- @return nil: no values.
   rejects(function(trace)
      trace.requirements[1].design[1] = "LMA-DES-UNKNOWN-999"
   end)
   --- Reject requirements without an acceptance statement.
   -- @param trace table: requirement and verification evidence graph.
   -- @return nil: no values.
   rejects(function(trace)
      trace.requirements[1].statement = " "
   end)
   --- Reject verifications without a registered control.
   -- @param trace table: requirement and verification evidence graph.
   -- @return nil: no values.
   rejects(function(trace)
      trace.verifications[1].control = "LMA-CTRL-UNKNOWN"
   end)
   --- Reject unsupported verification claims.
   -- @param trace table: requirement and verification evidence graph.
   -- @return nil: no values.
   rejects(function(trace)
      trace.verifications[1].kind = "formal"
   end)
   --- Reject two verification IDs for the same control.
   -- @param trace table: requirement and verification evidence graph.
   -- @return nil: no values.
   rejects(function(trace)
      trace.verifications[2].control = trace.verifications[1].control
   end)
   --- Reject duplicate verification identifiers.
   -- @param trace table: requirement and verification evidence graph.
   -- @return nil: no values.
   rejects(function(trace)
      trace.verifications[2].id = trace.verifications[1].id
   end)
   --- Reject traversal in design paths.
   -- @param trace table: requirement and verification evidence graph.
   -- @return nil: no values.
   rejects(function(trace)
      trace.designs[1].reference = "docs/../outside.md"
   end)
   --- Reject external executable or document references.
   -- @param trace table: requirement and verification evidence graph.
   -- @return nil: no values.
   rejects(function(trace)
      trace.designs[1].reference = "https://example.invalid/design.md"
   end)
   --- Reject unused design nodes.
   -- @param trace table: requirement and verification evidence graph.
   -- @return nil: no values.
   rejects(function(trace)
      trace.designs[5] =
         { id = "LMA-DES-ORPHAN-005", reference = "docs/README.md" }
   end)
   --- Reject undeclared approval assertions.
   -- @param trace table: requirement and verification evidence graph.
   -- @return nil: no values.
   rejects(function(trace)
      trace.requirements[1].approved = true
   end)
   --- Reject controls whose requirement was removed.
   -- @param trace table: requirement and verification evidence graph.
   -- @return nil: no values.
   rejects(function(trace)
      table.remove(trace.requirements)
   end)
   --- Reject required verifications removed from the inventory.
   -- @param trace table: requirement and verification evidence graph.
   -- @return nil: no values.
   rejects(function(trace)
      table.remove(trace.verifications)
   end)
   --- Reject the obsolete catalog schema.
   -- @param _ any: callback argument intentionally unused.
   -- @param value any: value supplied to this operation.
   -- @return nil: no values.
   rejects(function(_, value)
      value.schema_version = 1
   end)

   local value = catalog()
   local controls, trace = policy.catalog(value)
   local records = {}
   local digest = string.rep("a", 64)
   local plan = {
      scope = value.scope,
      run_id = "traceability-tests",
      policy_sha256 = digest,
      subject = { source_sha256 = digest },
      traceability = trace,
   }

   for _, control in ipairs(controls) do
      records[#records + 1] =
         { control = control.id, state = "PASS", sha256 = digest }
   end

   local graph = traceability.graph(plan, digest, records, evidence_io.array)

   assert(
      evidence_io.decode(evidence_io.json(graph)).requirements[1].status
         == "PASS",
      "graph did not survive JSON transport"
   )
   assert(#graph.requirements == 4, "missing graph requirements")
   for _, requirement in ipairs(graph.requirements) do
      assert(
         requirement.status == "PASS",
         "passing verification failed its requirement"
      )
      assert(requirement.evidence[1].sha256 == digest, "result digest changed")
   end

   assert(
      not graph.promotion_authorized and not graph.product_qualified,
      "graph granted product authority"
   )
   count = count + 1

   -- Multiple required verifications reduce to failure if either fails.
   trace.verifications[#trace.verifications + 1] = {
      id = "LMA-TEST-UNIT-005",
      kind = "unit",
      control = "LMA-CTRL-SECOND",
   }
   controls[#controls + 1] =
      { id = "LMA-CTRL-SECOND", requirement = "LMA-ENG-001" }
   trace.requirements[1].verification[2] = "LMA-TEST-UNIT-005"
   traceability.validate(trace, controls, policy)
   records[#records + 1] =
      { control = "LMA-CTRL-SECOND", state = "TIMEOUT", sha256 = digest }
   graph = traceability.graph(plan, digest, records, evidence_io.array)
   assert(
      graph.requirements[1].status == "FAIL",
      "timeout passed its requirement"
   )
   assert(
      graph.requirements[1].evidence[2].status == "TIMEOUT",
      "native failure status lost"
   )
   assert(
      graph.requirements[2].status == "PASS",
      "unrelated requirement changed"
   )
   count = count + 1

   records[#records] = nil
   assert(
      not pcall(traceability.graph, plan, digest, records, evidence_io.array),
      "missing evidence accepted"
   )
   records[#records + 1] = records[1]
   assert(
      not pcall(traceability.graph, plan, digest, records, evidence_io.array),
      "duplicate evidence accepted"
   )
   count = count + 2
   print("Traceability: " .. count .. " graph contract cases passed.")
end

return TRACEABILITY_TEST_main()

-- EOF


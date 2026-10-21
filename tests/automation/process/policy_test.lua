-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Exercise the pilot policy without filesystem or process access.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_process_policy_test_suite_main()
   local P = dofile("scripts/process/lib/policy.lua")
   local count = 0

   --- Count a case only when policy rejects its input.
   -- @param callback function: operation supplied by the caller; errors
   -- propagate.
   -- @return nil: no values.
   local function rejects(callback)
      assert(not pcall(callback), "invalid input accepted")

      count = count + 1
   end

   --- Create an independent valid catalog for each mutation.
   -- @return table: an independent valid catalog for each mutation.
   local function catalog()
      return {
         schema_version = 2,
         scope = "automation-pilot",
         traceability = {
            designs = {
               {
                  id = "LMA-DES-TOOLCHAIN-001",
                  reference = "docs/reference/toolchain.md",
               },
            },
            verifications = {
               {
                  id = "LMA-TEST-UNIT-001",
                  kind = "unit",
                  control = "LMA-CTRL-LOCK-PARSER",
               },
            },
            requirements = {
               {
                  id = "LMA-ENG-001",
                  statement = "Validate toolchain locks.",
                  design = { "LMA-DES-TOOLCHAIN-001" },
                  verification = { "LMA-TEST-UNIT-001" },
               },
            },
         },
         controls = {
            {
               id = "LMA-CTRL-LOCK-PARSER",
               verifier = "toolchain_contract",
               requirement = "LMA-ENG-001",
               procedure = "LMA-PROC-003",
               configuration = "posix-local",
            },
         },
      }
   end

   local controls = P.catalog(catalog())

   assert(#controls == 1, "control selection returned the wrong count")

   count = count + 1

   --- Reject executable commands supplied through catalog data.
   -- @return nil: no values.
   rejects(function()
      local c = catalog()

      c.controls[1].command = "evil"
      P.catalog(c)
   end)

   --- Reject duplicated control identifiers.
   -- @return nil: no values.
   rejects(function()
      local c = catalog()

      c.controls[2] = c.controls[1]
      P.catalog(c)
   end)

   --- Reject a verifier outside the fixed registry.
   -- @return nil: no values.
   rejects(function()
      local c = catalog()

      c.controls[1].verifier = "shell"
      P.catalog(c)
   end)

   --- Reject an unknown requirement identifier.
   -- @return nil: no values.
   rejects(function()
      local c = catalog()

      c.controls[1].requirement = "unknown"
      P.catalog(c)
   end)

   --- Reject a catalog without controls.
   -- @return nil: no values.
   rejects(function()
      local c = catalog()

      c.controls = {}
      P.catalog(c)
   end)

   --- Construct fresh successful evidence for one control.
   -- @return table: fresh successful evidence for one control.
   local function result()
      return {
         control = "LMA-CTRL-LOCK-PARSER",
         state = "PASS",
         exit_code = 0,
         signal = 0,
         observed_tests = 9,
         plan_sha256 = string.rep("a", 64),
         configuration = "posix-local",
      }
   end

   local digest = string.rep("a", 64)

   --- Assess records against the same control set and plan digest.
   -- @param records table: ordered records to inspect.
   -- @return any: assess records against the same control set and plan digest.
   local function gate(records)
      return P.gate(controls, records, digest)
   end

   assert(gate({ result() }).passed, "valid execution failed its gate")

   count = count + 1
   for _, records in ipairs({ {}, { result(), result() } }) do
      assert(not gate(records).passed, "invalid execution passed its gate")

      count = count + 1
   end

   for _, mutation in ipairs({
      { "control", "unknown" },
      { "state", "FAIL" },
      { "state", "TIMEOUT" },
      { "state", "INFRA_ERROR" },
      { "state", "CANCELLED" },
      { "state", "INCONCLUSIVE" },
      { "observed_tests", 0 },
      { "observed_tests", 8 },
      { "exit_code", 1 },
      { "signal", 9 },
      { "plan_sha256", string.rep("b", 64) },
      { "configuration", "foreign" },
   }) do
      local r = result()

      r[mutation[1]] = mutation[2]
      assert(not gate({ r }).passed, "invalid evidence passed: " .. mutation[1])

      count = count + 1
   end

   local future = result()

   future.approved = true

   --- Reject an undeclared approval field in execution evidence.
   -- @return nil: no values.
   rejects(function()
      gate({ future })
   end)
   assert(
      not gate({ result() }).promotion_authorized,
      "local gate authorized promotion"
   )
   assert(
      not gate({ result() }).product_qualified,
      "local gate claimed product qualification"
   )

   print("Process policy: " .. count .. " cases passed.")
end

return tests_process_policy_test_suite_main()

-- EOF


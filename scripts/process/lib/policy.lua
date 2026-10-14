-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Pure rules for the bounded engineering-process pilot.
-- Part of local process planning and evidence assessment.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_process_lib_policy_loadModule()
   local exports = {}

   exports.verifiers = {
      toolchain_contract = {
         requirement = "LMA-ENG-001",
         script = "tests/automation/toolchain/lock_test.lua",
         expected_tests = 9,
         timeout_seconds = 30,
         completion = "Toolchain: valid lock and 8 invalid lock cases passed.",
      },
      documentation_contract = {
         script = "scripts/process/verify.lua",
         arguments = { "documentation" },
         requirement = "LMA-ENG-002",
         expected_tests = 1,
         timeout_seconds = 60,
         completion = "Documentation control: 1 policy gate passed.",
      },
      compilation_contract = {
         script = "scripts/process/verify.lua",
         arguments = { "compilation" },
         requirement = "LMA-ENG-003",
         expected_tests = 1,
         timeout_seconds = 180,
         completion = "Compilation control: 1 compatibility campaign passed.",
      },
      regression_contract = {
         script = "scripts/process/verify.lua",
         arguments = { "regressions" },
         requirement = "LMA-ENG-004",
         expected_tests = 4,
         timeout_seconds = 60,
         completion = "Regression control: 4 policy suites passed.",
      },
   }

   --- Reject missing or unknown fields before interpreting a record.
   -- @param value any: value supplied to this operation.
   -- @param names any: names supplied to this operation.
   -- @return nil: no values.
   local function PROCESS_POLICY_fields(value, names)
      assert(type(value) == "table", "record must be an object")

      local allowed = {}

      for _, name in ipairs(names) do
         allowed[name] = true
         assert(value[name] ~= nil, "missing field: " .. name)
      end

      for name in pairs(value) do
         assert(allowed[name], "unknown field: " .. tostring(name))
      end
   end

   exports.fields = PROCESS_POLICY_fields

   --- Reject sparse arrays and hidden object fields.
   -- @param values any: values consumed in the operation’s declared order.
   -- @return nil: no values.
   local function PROCESS_POLICY_sequence(values)
      assert(type(values) == "table", "expected an array")
      for index in pairs(values) do
         assert(
            type(index) == "number"
               and index % 1 == 0
               and index >= 1
               and index <= #values,
            "invalid array index"
         )
      end
   end

   exports.sequence = PROCESS_POLICY_sequence

   --- Resolve declarative controls only through the trusted verifier registry.
   -- @param value any: value supplied to this operation.
   -- @return any, any: declarative controls only through the trusted verifier
   -- registry.
   local function PROCESS_POLICY_catalog(value)
      exports.fields(
         value,
         { "schema_version", "scope", "controls", "traceability" }
      )
      assert(value.schema_version == 2, "unsupported catalog schema")
      assert(value.scope == "automation-pilot", "unsupported scope")
      assert(
         type(value.controls) == "table" and #value.controls > 0,
         "empty controls"
      )

      exports.sequence(value.controls)

      local seen = {}

      for index, control in pairs(value.controls) do
         assert(
            type(index) == "number" and index % 1 == 0,
            "controls must be an array"
         )
         assert(index >= 1 and index <= #value.controls, "sparse controls")

         exports.fields(
            control,
            { "id", "verifier", "requirement", "procedure", "configuration" }
         )
         assert(
            type(control.id) == "string"
               and control.id:match("^LMA%-CTRL%-[A-Z-]+$"),
            "invalid control ID"
         )
         assert(not seen[control.id], "duplicate control ID")

         seen[control.id] = true
         assert(exports.verifiers[control.verifier], "unknown verifier")
         assert(
            control.requirement
               == exports.verifiers[control.verifier].requirement,
            "unknown requirement for verifier"
         )
         assert(control.procedure == "LMA-PROC-003", "unknown procedure")
         assert(control.configuration == "posix-local", "unknown configuration")
      end

      table.sort(
         value.controls,
         --- Order controls by stable identifier before computing their plan.
         -- @param a table: a supplied to this operation.
         -- @param b table: b supplied to this operation.
         -- @return boolean: order controls by stable identifier before
         -- computing their plan.
         function(a, b)
            return a.id < b.id
         end
      )

      local traceability = dofile("scripts/process/lib/traceability.lua")

      traceability.validate(value.traceability, value.controls, exports)

      return value.controls, value.traceability
   end

   exports.catalog = PROCESS_POLICY_catalog

   --- Accept only a complete set of matching successful observations.
   -- @param controls any: controls supplied to this operation.
   -- @param records table: ordered records to inspect.
   -- @param plan_sha256 any: plan sha256 supplied to this operation.
   -- @return table: accept only a complete set of matching successful
   -- observations.
   local function PROCESS_POLICY_gate(controls, records, plan_sha256)
      exports.sequence(records)

      local expected, seen, failures = {}, {}, {}

      for _, control in ipairs(controls) do
         expected[control.id] = control
      end

      --- Validate one control record and preserve gate diagnostics.
      -- @param record table: structured record supplied by the caller.
      -- @return nil: no values.
      local function process_policy_acceptRecord(record)
         exports.fields(record, {
            "control",
            "state",
            "exit_code",
            "signal",
            "observed_tests",
            "plan_sha256",
            "configuration",
         })

         local control = expected[record.control]

         if not control or seen[record.control] then
            failures[#failures + 1] = "unexpected or duplicate control: "
               .. tostring(record.control)
         else
            seen[record.control] = true

            local verifier = exports.verifiers[control.verifier]

            if
               record.state ~= "PASS"
               or record.exit_code ~= 0
               or record.signal ~= 0
               or record.observed_tests ~= verifier.expected_tests
               or record.plan_sha256 ~= plan_sha256
               or record.configuration ~= control.configuration
            then
               failures[#failures + 1] = "unsatisfied control: "
                  .. record.control
            end
         end
      end

      for _, record in ipairs(records) do
         process_policy_acceptRecord(record)
      end

      for _, control in ipairs(controls) do
         if not seen[control.id] then
            failures[#failures + 1] = "missing control: " .. control.id
         end
      end

      return {
         passed = #failures == 0,
         failures = failures,
         promotion_authorized = false,
         product_qualified = false,
      }
   end

   exports.gate = PROCESS_POLICY_gate

   return exports
end

return scripts_process_lib_policy_loadModule()

-- EOF


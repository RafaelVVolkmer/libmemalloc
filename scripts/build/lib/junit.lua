-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Validate CTest's JUnit dialect independently of report transport and hashes.
-- @return table: public operations constructed by this module.
local function JUNIT_loadModule()
   local exports = {}
   local xml = dofile("scripts/build/lib/xml.lua")
   local canonical = "mock-identity-v1 operations=257 result=0"

   local attributes = {
      testsuite = {
         name = true,
         tests = true,
         failures = true,
         errors = true,
         disabled = true,
         skipped = true,
         hostname = true,
         time = true,
         timestamp = true,
      },
      testcase = { name = true, classname = true, time = true, status = true },
      properties = {},
      property = { name = true, value = true },
      ["system-out"] = {},
      ["system-err"] = {},
   }

   --- Reject unrecognized fields that could carry conflicting outcome states.
   -- @param node table: node supplied to this operation.
   -- @return nil: no values.
   local function junit_attributes(node)
      local allowed = assert(attributes[node.name], "unexpected JUnit element")

      for name in pairs(node.attributes) do
         assert(allowed[name], "unexpected JUnit attribute: " .. name)
      end
   end

   --- Require count attributes to be unsigned integers, without coercion.
   -- @param node table: node supplied to this operation.
   -- @param name string: entry or operation name to resolve.
   -- @param expected any: expected reference value used by this check.
   -- @return nil: no values.
   local function junit_count(node, name, expected)
      local value = node.attributes[name]

      assert(
         value and value:match("^[0-9]+$") and tonumber(value) == expected,
         "incoherent JUnit count: " .. name
      )
   end

   --- Structural containers may contain only whitespace outside their children.
   -- @param node table: node supplied to this operation.
   -- @return nil: no values.
   local function junit_container(node)
      junit_attributes(node)
      assert(table.concat(node.text):match("^%s*$"), "text in JUnit container")
   end

   --- Keep property metadata inert; reject hidden tests or outcome elements.
   -- @param node table: node supplied to this operation.
   -- @return nil: no values.
   local function junit_properties(node)
      junit_container(node)
      for _, property in ipairs(node.children) do
         assert(
            property.name == "property" and #property.children == 0,
            "invalid JUnit property"
         )
         junit_container(property)
      end
   end

   --- Read real testcase output while rejecting every unsuccessful state.
   -- @param node table: node supplied to this operation.
   -- @return any, any: real testcase output while rejecting every unsuccessful
   -- state.
   local function junit_case(node)
      assert(node.name == "testcase", "unexpected JUnit suite element")
      assert(node.attributes.status == "run", "unsuccessful test status")
      local name = assert(node.attributes.name, "missing JUnit test name")

      assert(name ~= "", "empty JUnit test name")
      junit_container(node)
      local seen, output = {}, ""

      for _, child in ipairs(node.children) do
         assert(not seen[child.name], "duplicate JUnit testcase element")
         seen[child.name] = true
         if child.name == "properties" then
            junit_properties(child)
         else
            assert(
               child.name == "system-out" or child.name == "system-err",
               "unsuccessful test evidence or unexpected element"
            )
            junit_attributes(child)
            assert(#child.children == 0, "markup inside JUnit output")
            if child.name == "system-out" then
               output = table.concat(child.text)
            end
         end
      end

      return name, output
   end

   --- Accept only exact executed inventories and a trace belonging to c-api.
   -- @param source any: source value inspected by this operation.
   -- @param expected any: expected reference value used by this check.
   -- @param trace string: canonical cross-target semantic trace from c-api.
   -- @return table: accept only exact executed inventories and a trace
   -- belonging to c-api.
   local function JUNIT_validate(source, expected, trace)
      assert(trace == canonical, "cross-target semantic mismatch")
      local root = xml.parse(source)

      assert(root.name == "testsuite", "missing CTest test suite")
      junit_container(root)
      local names, wanted, outputs = {}, {}, {}

      for _, name in ipairs(expected) do
         assert(not wanted[name], "duplicate expected test")
         wanted[name] = true
      end

      assert(wanted["c-api"], "test evidence inventory mismatch: missing c-api")
      for _, node in ipairs(root.children) do
         local name, output = junit_case(node)

         assert(
            wanted[name] and outputs[name] == nil,
            "test evidence inventory mismatch"
         )
         names[#names + 1] = name
         outputs[name] = output
      end

      assert(#names == #expected, "test evidence inventory mismatch")
      junit_count(root, "tests", #names)
      for _, field in ipairs({ "failures", "disabled", "skipped" }) do
         junit_count(root, field, 0)
      end

      if root.attributes.errors then
         junit_count(root, "errors", 0)
      end

      local found = false
      local output = outputs["c-api"]:gsub("\r\n", "\n")

      for line in (output .. "\n"):gmatch("([^\n]*)\n") do
         if line == canonical then
            found = true
         end
      end

      assert(found, "cross-target semantic mismatch: missing c-api trace")
      table.sort(names)

      return names
   end

   exports.validate = JUNIT_validate

   return exports
end

return JUNIT_loadModule()

-- EOF


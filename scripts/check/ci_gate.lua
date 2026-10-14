-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Reconcile actual reusable-workflow outcomes against the selected graph.
-- @return nil: no values.
local function CI_GATE_main()
   assert(#arg == 0, "ci-gate accepts no arguments")
   local gate = dofile("scripts/check/lib/ci_gate.lua")
   local values = {}

   for _, rule in ipairs(gate.rules) do
      values[rule.env] = os.getenv(rule.env)
      if rule.selection then
         values[rule.selection] = os.getenv(rule.selection)
      end
   end

   gate.validate(values)
   print("CI gate: every selected check succeeded.")
end

return CI_GATE_main()

-- EOF


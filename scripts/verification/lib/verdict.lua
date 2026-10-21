-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Classify failed work without treating failure to prove as a refutation.
-- @return table: classification operations.
local function VERDICT_loadModule()
   --- Only an accepted counterexample theorem may establish REFUTED.
   -- @param stage string: failed pipeline step.
   -- @param result table: process state and captured output.
   -- @return string: incomplete evidence category.
   local function classify(stage, result)
      if result.state ~= "FAIL" or (result.signal or 0) ~= 0 then
         return "INFRA_ERROR"
      end
      local output = result.stdout .. result.stderr
      if output:find("Heap exhausted", 1, true) then
         return "INFRA_ERROR"
      end
      local imports = { produce = true, admit = true }
      if imports[stage] then
         if output:find("unsupported", 1, true) then
            return "UNSUPPORTED"
         end
         return "REJECTED_INPUT"
      end
      if stage == "proof" or stage == "audit" then
         return "INCONCLUSIVE"
      end
      return "INFRA_ERROR"
   end
   return { classify = classify }
end

return VERDICT_loadModule()

-- EOF


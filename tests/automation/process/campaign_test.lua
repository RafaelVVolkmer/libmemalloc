-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Verify campaign finalization preserves failures across phase boundaries.

--- Inject phase outcomes through real orchestration and path checks.
-- @return nil: no values.
local function CAMPAIGN_TEST_main()
   local engine = dofile("scripts/process/lib/engine.lua")
   local evidence_io = dofile("scripts/process/lib/io.lua")
   local root = ".cache/tests/campaign-" .. tostring(evidence_io.uv.hrtime())
   local count = 0

   for _, failed in ipairs({ "none", "plan", "run", "gate", "report" }) do
      for _, throws in ipairs({ false, true }) do
         local calls = {}

         for _, name in ipairs({ "plan", "run", "gate", "report" }) do
            --- Record execution order and inject failure or interruption.
            -- @param options table: operation settings; omitted fields use the
            -- documented defaults.
            -- @return boolean: record execution order and inject failure or
            -- interruption.
            engine[name] = function(options)
               calls[#calls + 1] = name
               assert(
                  options["policy-sha256"] == "reviewed-digest",
                  "policy digest changed between phases"
               )
               assert(options.plan:match("/plan%.json$"))
               assert(options.evidence:match("/evidence$"))
               if failed == name and throws then
                  error("injected " .. name .. " failure")
               end

               return failed ~= name
            end
         end

         local directory = root .. "/" .. failed .. "-" .. tostring(throws)
         local ok, result = pcall(engine.campaign, {
            profile = "local",
            ["run-id"] = "campaign-tests",
            ["policy-sha256"] = "reviewed-digest",
            output = directory,
         })

         assert(
            (ok and result == true) == (failed == "none"),
            "campaign hid a phase failure"
         )
         assert(
            table.concat(calls, ",")
               == (failed == "plan" and "plan" or "plan,run,gate,report"),
            "campaign skipped finalization or ran after failed planning"
         )
         assert(
            not pcall(engine.campaign, { output = directory }),
            "reused campaign accepted"
         )
         assert(evidence_io.uv.fs_rmdir(directory))
         count = count + 1
      end
   end

   assert(evidence_io.uv.fs_rmdir(root))
   print("Campaign: " .. count .. " finalization cases passed.")
end

return CAMPAIGN_TEST_main()

-- EOF


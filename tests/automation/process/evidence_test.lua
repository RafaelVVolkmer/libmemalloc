-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Exercise a real local plan, verifier and evidence gate, then damage records.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_process_evidence_test_suite_main()
   local I = dofile("scripts/process/lib/io.lua")
   local E = dofile("scripts/process/lib/engine.lua")
   local R = dofile("scripts/lib/artifacts.lua")
   local root = ".cache/tests/process-" .. tostring(I.uv.hrtime())
   local pin = I.digest("tools/process/controls.json")
   local options = {
      profile = "local",
      ["run-id"] = "evidence-tests",
      ["policy-sha256"] = pin,
      output = root .. "/plan.json",
   }

   assert(E.plan(options))

   options.plan = options.output
   options.output = root .. "/evidence"
   assert(E.run(options))

   options.evidence = options.output
   assert(E.assess(options).passed, "complete evidence failed assessment")

   local count = 1

   --- Replace fixture bytes without changing the evidence path.
   -- @param path string: filesystem path selected by the caller.
   -- @param data string: fixture bytes consumed by this operation.
   -- @return nil: no values.
   local function overwrite(path, data)
      local file = assert(io.open(path, "wb"))

      assert(file:write(data))
      assert(file:close())
   end

   --- Apply one mutation, require rejection and restore the original bytes.
   -- @param path string: filesystem path selected by the caller.
   -- @param transform any: transform supplied to this operation.
   -- @return nil: no values.
   local function damage(path, transform)
      local before = I.read(path)

      overwrite(path, transform(before))
      assert(
         not E.assess(options).passed,
         "damaged evidence accepted: " .. path
      )

      overwrite(path, before)

      count = count + 1
   end

   --- Replace the planned source digest with an unrelated identity.
   -- @param s any: text or record supplied by the caller.
   -- @return any: replace the planned source digest with an unrelated identity.
   damage(options.plan, function(s)
      local value = I.decode(s)

      value.subject.source_sha256 = string.rep("0", 64)

      return I.json(value)
   end)

   local evidence = options.evidence
   local control = evidence .. "/LMA-CTRL-LOCK-PARSER"

   local graph_path = evidence .. "/evidence.json"
   local graph = I.load(graph_path)

   assert(#graph.requirements == 4, "missing traced requirements")
   for _, requirement in ipairs(graph.requirements) do
      assert(requirement.status == "PASS", "successful requirement failed")
      for _, item in ipairs(requirement.evidence) do
         assert(
            item.sha256 == I.digest(evidence .. "/" .. item.artifact),
            "graph result digest mismatch"
         )
      end
   end

   --- Reject a changed verdict even when its execution evidence is intact.
   -- @param s any: text or record supplied by the caller.
   -- @return any: reject a changed verdict even when its execution evidence is
   -- intact.
   damage(graph_path, function(s)
      local value = I.decode(s)

      value.requirements[1].status = "FAIL"

      return I.json(value)
   end)

   --- Reject a reassigned requirement with unchanged passing observations.
   -- @param s any: text or record supplied by the caller.
   -- @return any: reject a reassigned requirement with unchanged passing
   -- observations.
   damage(graph_path, function(s)
      local value = I.decode(s)

      value.requirements[1].requirement = "LMA-ENG-999"

      return I.json(value)
   end)

   --- Reject artifacts that escape the retained attempt.
   -- @param s any: text or record supplied by the caller.
   -- @return any: reject artifacts that escape the retained attempt.
   damage(graph_path, function(s)
      local value = I.decode(s)

      value.requirements[1].evidence[1].artifact = "../foreign/result.json"

      return I.json(value)
   end)

   --- Reject a graph missing a declared required verification.
   -- @param s any: text or record supplied by the caller.
   -- @return any: reject a graph missing a declared required verification.
   damage(graph_path, function(s)
      local value = I.decode(s)

      value.requirements[1].evidence = I.array()

      return I.json(value)
   end)

   --- Append bytes to an already recorded execution log.
   -- @param s any: text or record supplied by the caller.
   -- @return string: append bytes to an already recorded execution log.
   damage(control .. "/stdout.log", function(s)
      return s .. "tampered\n"
   end)

   --- Change result bytes while retaining their decoded meaning.
   -- @param s any: text or record supplied by the caller.
   -- @return string: change result bytes while retaining their decoded meaning.
   damage(control .. "/result.json", function(s)
      return s .. " "
   end)

   --- Substitute a manifest from another run.
   -- @param s any: text or record supplied by the caller.
   -- @return any: substitute a manifest from another run.
   damage(evidence .. "/manifest.json", function(s)
      local value = I.decode(s)

      value.run_id = "foreign"

      return I.json(value)
   end)

   --- Remove the required control records.
   -- @param s any: text or record supplied by the caller.
   -- @return any: remove the required control records.
   damage(evidence .. "/manifest.json", function(s)
      local value = I.decode(s)

      value.records = I.array()

      return I.json(value)
   end)

   --- Duplicate a control record in the manifest.
   -- @param s any: text or record supplied by the caller.
   -- @return any: duplicate a control record in the manifest.
   damage(evidence .. "/manifest.json", function(s)
      local value = I.decode(s)

      value.records[2] = value.records[1]

      return I.json(value)
   end)

   --- Change the retained plan profile after execution.
   -- @param s any: text or record supplied by the caller.
   -- @return any: change the retained plan profile after execution.
   damage(evidence .. "/plan.json", function(s)
      local value = I.decode(s)

      value.profile = "release"

      return I.json(value)
   end)

   --- Break the start record binding to its approved plan.
   -- @param s any: text or record supplied by the caller.
   -- @return any: break the start record binding to its approved plan.
   damage(control .. "/started.json", function(s)
      local value = I.decode(s)

      value.plan_sha256 = string.rep("0", 64)

      return I.json(value)
   end)

   local log = control .. "/stderr.log"

   assert(os.rename(log, log .. ".held"))
   assert(not E.assess(options).passed, "missing log was accepted")
   assert(os.rename(log .. ".held", log))

   count = count + 1
   I.write(evidence .. "/unexpected.txt", "extra")
   assert(not E.assess(options).passed, "unexpected evidence file was accepted")
   assert(I.uv.fs_unlink(evidence .. "/unexpected.txt"))

   count = count + 1

   local previous = options["policy-sha256"]

   options["policy-sha256"] = string.rep("0", 64)
   assert(not E.assess(options).passed, "changed policy identity was accepted")

   options["policy-sha256"] = previous
   count = count + 1
   assert(not pcall(E.run, options), "reused evidence directory accepted")

   count = count + 1
   assert(E.assess(options).passed, "restored evidence failed assessment")
   assert(
      not E.assess(options).promotion_authorized,
      "local gate authorized promotion"
   )

   options.output = root .. "/gate.json"
   assert(E.gate(options))

   options.output = root .. "/report.md"
   assert(E.report(options))
   assert(
      not pcall(I.output_path, ".cache/tests/../escape"),
      "parent traversal was accepted"
   )

   count = count + 1

   local alias = root .. "/alias"

   assert(I.uv.fs_symlink("evidence", alias))
   assert(
      not pcall(I.output_path, alias .. "/result.json"),
      "symlink output path was accepted"
   )
   assert(I.uv.fs_unlink(alias))

   count = count + 1
   assert(R.exists(root .. "/report.md"))

   print("Process evidence: " .. count .. " cases passed; records: " .. root)
end

return tests_process_evidence_test_suite_main()

-- EOF


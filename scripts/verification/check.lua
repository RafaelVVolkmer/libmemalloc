-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Run proof lint and trust controls; kernel replay is a separate CI step.
-- @return nil: no values.
local function PROOF_CHECK_main()
   local files = dofile("scripts/verification/lib/files.lua")
   local resources = dofile("scripts/verification/lib/resources.lua")
   local ioTools = dofile("scripts/process/lib/io.lua")
   local sequence = 0
   --- Execute proof tools only with verified kernel limits and keep receipts.
   -- @param command string: command with individually quoted file arguments.
   -- @return boolean: whether the tool succeeded rather than rejected input.
   local function execute(command)
      sequence = sequence + 1
      local result = resources.run({ "sh", "-c", command }, {
         timeout_ms = 1800000,
         max_bytes = 16777216,
      })
      local directory = ".cache/logs/lean"
      assert(
         ioTools.exec.run({ "mkdir", "-p", directory }).state == "PASS",
         "cannot create Lean log directory"
      )
      local prefix = directory .. "/command-" .. tostring(sequence)
      files.write(prefix .. ".log", result.stdout .. result.stderr)
      files.write(
         prefix .. ".json",
         ioTools.json({
            state = result.state,
            exit_code = result.exit_code,
            signal = result.signal,
            resources = result.resources,
         })
      )
      io.write(result.stdout)
      io.stderr:write(result.stderr)
      assert(
         result.state == "PASS" or result.state == "FAIL",
         "Lean execution " .. result.state .. "; see " .. prefix .. ".log"
      )
      return result.state == "PASS"
   end
   assert(
      (arg[1] == nil or arg[1] == "--kernel") and arg[2] == nil,
      "usage: lua scripts/verification/check.lua [--kernel]"
   )
   local lock = dofile("scripts/toolchain/lib/lock.lua").load().lean
   assert(
      files.read("verification/theorems/lean-toolchain")
         == "leanprover/lean4:v" .. lock.version .. "\n",
      "Lean toolchain lock drift"
   )
   local lake = os.getenv("LMA_LAKE")
   if not lake then
      local path = ".cache/lean/lean-" .. lock.version .. "-linux/bin/lake"
      local file = io.open(path, "rb")
      if file then
         file:close()
         lake = "../../" .. path
      else
         lake = "lake"
      end
   end
   local command = "cd verification/theorems && " .. files.quote(lake)
   if arg[1] == "--kernel" then
      assert(execute(command .. " check"), "isolated kernel replay failed")
      return
   end
   dofile("scripts/verification/lib/style.lua")
   assert(
      execute(command .. " --wfail build LibMemAllocAudit"),
      "Lean build failed"
   )
   -- Lake imports a complete environment for each root. Separate processes
   -- release those environments between checks without reducing lint coverage.
   for _, module in ipairs({
      "LibMemAlloc",
      "LibMemAllocAudit",
   }) do
      assert(
         execute(command .. " --wfail lint --builtin-only " .. module),
         "Lean lint failed: " .. module
      )
   end
   local lean = command
      .. " env lean -DwarningAsError=true"
      .. " -Dlinter.unusedVariables=true -Dlinter.unusedSimpArgs=true"

   lean = lean .. " --root=../../.cache/verification/negative"
   assert(execute("mkdir -p .cache/verification/negative"))
   local controls = {
      {
         name = "Unchecked",
         body = "axiom unchecked : False\n/-- Mathematical statement:"
            .. " False (negative control). -/\n"
            .. "theorem bogus : False := unchecked\n",
         reason = "Forbidden axiom OutsideAllocator.unchecked",
      },
      {
         name = "Unfinished",
         body = "/-- Mathematical statement: False (negative control). -/\n"
            .. "theorem bogus : False := by sorry\n",
         reason = "Forbidden axiom sorryAx",
      },
   }
   for _, control in ipairs(controls) do
      local dependency = control.name .. "Dependency"
      files.write(
         ".cache/verification/negative/" .. dependency .. ".lean",
         "namespace OutsideAllocator\n"
            .. control.body
            .. "end OutsideAllocator\n"
      )
      -- Allow an unfinished dependency only in this deliberate negative
      -- fixture.
      -- The public theorem file below contains neither an axiom nor a sorry.
      assert(
         execute(
            command
               .. " env lean --root=../../.cache/verification/negative "
               .. "-DwarningAsError=false -o "
               .. files.quote(
                  "../../.cache/verification/lean/lib/lean/"
                     .. dependency
                     .. ".olean"
               )
               .. " "
               .. files.quote(
                  "../../.cache/verification/negative/" .. dependency .. ".lean"
               )
               .. " > "
               .. files.quote(
                  "../../.cache/verification/negative/" .. dependency .. ".log"
               )
               .. " 2>&1"
         )
      )
      local path = "../../.cache/verification/negative/"
         .. control.name
         .. ".lean"
      files.write(
         "verification/theorems/" .. path,
         "import LibMemAllocAudit.Support\nimport "
            .. dependency
            .. "\nnamespace Allocator.Negative\n"
            .. "/-- Mathematical statement: False (negative control). -/\n"
            .. "theorem imported_bogus : False := OutsideAllocator.bogus\n"
            .. "end Allocator.Negative\n#audit_allocator\n"
      )
      local log = "../../.cache/verification/negative/"
         .. control.name
         .. ".log"
      local success = execute(
         lean
            .. " "
            .. files.quote(path)
            .. " > "
            .. files.quote(log)
            .. " 2>&1"
      )
      assert(not success, "audit accepted " .. control.name)
      assert(
         files
            .read("verification/theorems/" .. log)
            :find(control.reason, 1, true),
         "negative control failed for the wrong reason: " .. log
      )
   end
   for _, control in ipairs({
      {
         "UnusedVariable",
         "-- Mathematical statement: ∀ unused ∈ ℕ, True.\n"
            .. "example (unused : Nat) : True := by trivial\n",
         "linter.unusedvariables",
      },
      {
         "UnusedSimp",
         "-- Mathematical statement: ∀ n ∈ ℕ, n + 0 = n.\n"
            .. "example (n : Nat) : n + 0 = n := by simp [Nat.mul_comm]\n",
         "linter.unusedsimpargs",
      },
   }) do
      local path = "../../.cache/verification/negative/"
         .. control[1]
         .. ".lean"
      local log = "../../.cache/verification/negative/" .. control[1] .. ".log"
      files.write(
         "verification/theorems/" .. path,
         "import Std\n" .. control[2]
      )
      assert(
         not execute(
            lean
               .. " "
               .. files.quote(path)
               .. " > "
               .. files.quote(log)
               .. " 2>&1"
         ),
         "linter accepted " .. control[1]
      )
      assert(
         files
            .read("verification/theorems/" .. log)
            :lower()
            :find(control[3], 1, true),
         "linter control failed for the wrong reason: " .. log
      )
   end
   print(
      "Proof checks passed; imported axiom, sorry and lint controls rejected."
   )
end

return PROOF_CHECK_main()

-- EOF


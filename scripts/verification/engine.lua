-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

-- Validate the reusable engines without claiming acceptance of a production feature.
-- Product proofs use explicit source and contract inputs through c.lua.

--- Execute the formal engine module within its explicit boundary.
-- @return table|nil: module interface when applicable.
local function FORMAL_ENGINE_main()
   local env = dofile("scripts/verification/lib/engine_env.lua")
   local io, uv = env.io, env.io.uv
   local lua = os.getenv("LIBMEMALLOC_LUA") or uv.exepath()
   local files = dofile("scripts/verification/lib/files.lua")
   --- Parse the stage command without accepting duplicate or unknown options.
   -- @return table: validated option values.
   local function parseOptions()
      local options = {}
      for _, value in ipairs(arg) do
         if value ~= "--engine" then
            local key, setting = value:match("^%-%-([a-z-]+)=(.+)$")
            assert(key and ({
               stage = true,
               ["run-id"] = true,
            })[key], "unknown option")
            assert(not options[key], "duplicate option")
            options[key] = setting
         end
      end
      return options
   end
   local options = parseOptions()
   local stages = {
      start = 0,
      prepare = 1,
      lean = 2,
      haskell = 3,
      proof = 4,
      tests = 5,
      check = 6,
   }
   local selected = options.stage
   assert(not selected or stages[selected], "unsupported campaign stage")
   assert(not selected or options["run-id"], "staged commands require --run-id")
   local runId = options["run-id"]
      or os.date("!%Y%m%dT%H%M%SZ")
         .. "-"
         .. tostring(uv.os_getpid()):gsub("%.0$", "")
   assert(
      runId:match("^[A-Za-z0-9][A-Za-z0-9_-]*$") and #runId <= 64,
      "invalid run identity"
   )
   --- Create a disposable evidence or tool directory.
   -- @param path string: directory to create.
   -- @return nil: no values.
   local function mkdir(path)
      assert(
         io.exec.run({ "mkdir", "-p", path }).state == "PASS",
         "cannot create formal output directory"
      )
   end
   mkdir(".cache/verification/reports")
   mkdir(".cache/verification/attempts")
   mkdir(".cache/formal")
   dofile("scripts/verification/lib/lock.lua").guard()
   local attempt = env.root .. "/.cache/verification/attempts/" .. runId
   --- Open a resumable attempt or allocate a fresh evidence directory.
   -- @return table|nil: predecessor receipt, absent for a new attempt.
   local function openAttempt()
      local previous
      if selected and selected ~= "start" then
         previous = io.decode(files.read(attempt .. "/report.json"))
         assert(
            stages[selected] == previous.completed_stage + 1
               or (selected == "check" and previous.completed_stage == 6),
            "stage prerequisite is incomplete"
         )
      else
         assert(uv.fs_mkdir(attempt, 448), "attempt directory already exists")
      end
      return previous
   end
   local previous = openAttempt()
   local report = previous
      or {
         schema = "lma-formal-report/v1",
         status = "INCOMPLETE",
         technical_evidence_passed = false,
         feature_approved = false,
         attempt = attempt,
         steps = io.array(),
         run_id = runId,
         completed_stage = 0,
         profiles = io.array({ "engine-validation", "lean-ir-mock" }),
         limitations = io.array({
            "No source-to-IR preservation theorem",
            "No binary correctness theorem",
            "Engine regression evidence is not a proof of a production operation",
            "Liquid Haskell checks Refined.hs; the complete "
               .. "Haskell engine is not refinement-proved",
         }),
      }
   local cached, stepIndices = {}, {}
   for index, step in ipairs(report.steps) do
      cached[step.name] = step
      stepIndices[step.name] = index
   end
   -- Keep predecessor receipts even when admission or revalidation fails.
   report.steps = io.array(report.steps)
   report.failure = nil
   local stop = {}
   --- Persist the current receipt and latest-run summary.
   -- @return nil: no values.
   local function save()
      files.atomic_write(attempt .. "/report.json", io.json(report) .. "\n")
      files.atomic_write(
         ".cache/verification/reports/formal-engine.json",
         io.json(report) .. "\n"
      )
   end
   --- Execute a checked command or replay its matching retained receipt.
   -- @param name string: stable step name.
   -- @param argv table: literal command arguments.
   -- @param cwd string|nil: working directory.
   -- @param rejected boolean|nil: require an expected negative result.
   -- @return string: combined output for verification.
   local function run(name, argv, cwd, rejected)
      local commandIdentity = io.digest_bytes(
         io.json({ argv = io.array(argv), cwd = cwd or env.root })
      )
      local old = cached[name]
      if old and old.state == (rejected and "FAIL" or "PASS") then
         assert(
            old.command_identity == commandIdentity
               and old.expected_rejection == (rejected == true),
            "stage command changed: " .. name
         )
         assert(
            io.digest(attempt .. "/" .. name .. ".log") == old.log_sha256,
            "altered step log: " .. name
         )
         return files.read(attempt .. "/" .. name .. ".log", 16777216)
      end
      print("formal: " .. name)
      local result = env.resources.run(
         argv,
         { cwd = cwd, timeout_ms = 1800000, max_bytes = 16777216 }
      )
      files.write(
         attempt .. "/" .. name .. ".log",
         result.stdout .. result.stderr
      )
      local index = stepIndices[name] or #report.steps + 1
      report.steps[index] = {
         name = name,
         state = result.state,
         resources = result.resources,
         expected_rejection = rejected == true,
         log_sha256 = io.digest(attempt .. "/" .. name .. ".log"),
         command_identity = commandIdentity,
      }
      stepIndices[name], cached[name] = index, report.steps[index]
      save()
      if rejected then
         assert(
            result.state == "FAIL",
            name .. " did not reject the negative control"
         )
      else
         assert(
            result.state == "PASS",
            name .. ": " .. result.state .. "; see " .. attempt
         )
      end
      return result.stdout .. result.stderr
   end
   --- Hash every retained artifact used by subsequent stages.
   -- @return table: sorted artifact paths and digests.
   local function artifactInventory()
      local rows = io.array()
      for _, name in ipairs({
         "BadRefined.hs",
         "BadPermission.hs",
      }) do
         if uv.fs_stat(attempt .. "/" .. name) then
            rows[#rows + 1] =
               { path = name, sha256 = io.digest(attempt .. "/" .. name) }
         end
      end
      return rows
   end
   --- Record a completed stage and stop if selected by the command.
   -- @param stage string: completed stage name.
   -- @return nil: no values.
   local function checkpoint(stage)
      if not selected or selected == stage then
         report.completed_stage = stages[stage]
         report.artifacts = artifactInventory()
         report.status = stage == "check" and "PASS" or "IN_PROGRESS"
         report.technical_evidence_passed = stage == "check"
         save()
         if selected then
            error(stop, 0)
         end
      end
   end
   --- Hash the working sources and automation bound to this attempt.
   -- @return table: input paths and content digests.
   local function inventory()
      local paths = files.inventory()
      paths[#paths + 1] = "core/mock.c"
      paths[#paths + 1] = "core/mock.h"
      table.sort(paths)
      local rows = io.array()
      for _, path in ipairs(paths) do
         rows[#rows + 1] = { path = path, sha256 = io.digest(path) }
      end
      return rows
   end
   --- Bind the engine sources and retained artifacts to this campaign.
   -- @return nil: no values.
   local function startStage()
      local inputs = inventory()
      local identity = io.digest_bytes(io.json(inputs))
      if previous then
         assert(
            identity == previous.input_identity,
            "sources changed; start a new campaign"
         )
         for _, artifact in ipairs(previous.artifacts or {}) do
            assert(
               io.digest(attempt .. "/" .. artifact.path) == artifact.sha256,
               "altered campaign artifact: " .. artifact.path
            )
         end
      end
      report.inputs, report.input_identity = inputs, identity
      report.requirement = "LMA-ENGINE-EVIDENCE-001"
      report.revision = io.capture({ "git", "rev-parse", "HEAD" }):match("%x+")
      report.worktree_dirty = io.capture({ "git", "status", "--porcelain" })
         ~= ""
      checkpoint("start")
   end
   --- Check compiler versions, binary digests and dependency locks.
   -- @return nil: no values.
   local function prepareStage()
      report.tools =
         dofile("scripts/verification/lib/toolchain.lua").validate(env, run)
      checkpoint("prepare")
   end
   --- Check engines and their rejection controls without selecting an operation.
   -- @return nil: no values.
   local function main()
      startStage()
      prepareStage()
      run("lean-audit", { lua, "scripts/verification/check.lua" })
      run("lean-kernel", { lua, "scripts/verification/check.lua", "--kernel" })
      checkpoint("lean")
      run(
         "engine-build",
         env.cabal(
            "build",
            { "libmemalloc-verifier:exe:libmemalloc-verifier", "-fliquid" }
         )
      )
      local refined = env.root
         .. "/verification/engine/src/LibMemAlloc/Verifier/Refined.hs"
      --- Check refined Haskell afresh and require the expected plugin verdict.
      -- @param name string: step identifier.
      -- @param path string: refined source file.
      -- @param rejected boolean|nil: require UNSAFE for a negative control.
      -- @return nil: no values.
      local function liquid(name, path, rejected)
         local log = run(
            name,
            env.cabal("exec", {
               "--",
               "ghc",
               "-package",
               "liquidhaskell",
               "-fplugin=LiquidHaskell",
               "-fplugin-opt=LiquidHaskell:--fullcheck",
               "-fplugin-opt=LiquidHaskell:--check-derived",
               "-fplugin-opt=LiquidHaskell:--smttimeout=5000",
               "-fforce-recomp",
               "-fno-code",
               path,
            }),
            nil,
            rejected
         )
         assert(
            log:find(rejected and "LIQUID: UNSAFE" or "LIQUID: SAFE", 1, true),
            "Liquid plugin did not produce the required verdict"
         )
      end
      liquid("liquid", refined)
      local bad =
         files.read(refined):gsub("left %+ right\n", "left + right + 1\n")
      assert(bad ~= files.read(refined), "Liquid Haskell mutation site changed")
      files.write(attempt .. "/BadRefined.hs", bad)
      liquid("liquid-negative", attempt .. "/BadRefined.hs", true)
      local badPermission, permissionCount =
         files.read(refined):gsub("phase == 2\n", "phase >= 1\n")
      assert(permissionCount == 1, "permission negative control changed")
      files.write(attempt .. "/BadPermission.hs", badPermission)
      liquid("liquid-permission-negative", attempt .. "/BadPermission.hs", true)
      checkpoint("haskell")
      run("mock-proof", {
         lua,
         "scripts/verification/c.lua",
         "core/mock.c",
         "verification/contracts/mock.json",
         runId,
      })
      checkpoint("proof")
      run(
         "engine-tests",
         env.cabal("test", { "libmemalloc-verifier:engine-tests", "-fliquid" })
      )
      run(
         "formal-boundaries",
         { lua, "tests/automation/process/formal_boundary_test.lua" }
      )
      checkpoint("tests")
      assert(
         io.digest_bytes(io.json(inventory())) == report.input_identity,
         "sources changed during campaign"
      )
      checkpoint("check")
   end
   --- Preserve intentional stage completion or describe a failed command.
   -- @param err any: thrown sentinel or error.
   -- @return table|string: stage sentinel or diagnostic.
   local function failureTrace(err)
      return err == stop and stop or debug.traceback(err)
   end
   local ok, failure = xpcall(main, failureTrace)
   --- Finalize a completed stage or retain its diagnostic before failing.
   -- @param success boolean: whether execution returned normally.
   -- @param diagnostic any: stage sentinel or error detail.
   -- @return nil: no values.
   local function finish(success, diagnostic)
      if diagnostic == stop then
         success = true
      end
      if not success then
         report.failure, report.status, report.technical_evidence_passed =
            diagnostic, "INCOMPLETE", false
      end
      save()
      assert(success, diagnostic)
      print(
         "Formal stage "
            .. (selected or "all")
            .. ": "
            .. report.status
            .. "; "
            .. attempt
            .. "/report.json"
      )
   end
   finish(ok, failure)
end

return FORMAL_ENGINE_main()

-- EOF


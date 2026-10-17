-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Check an actual translation unit using an operation-independent contract.
-- @return nil: no values.
local function VERIFY_C_main()
   local env = dofile("scripts/verification/lib/engine_env.lua")
   local io, uv = env.io, env.io.uv
   local files = dofile("scripts/verification/lib/files.lua")
   local verdict = dofile("scripts/verification/lib/verdict.lua")
   local preprocessing = dofile("scripts/verification/lib/preprocessing.lua")
   --- Require safe, supported paths and a bounded run identity.
   -- @param source string: C input path.
   -- @param contract string: binding path.
   -- @param id string: run identity.
   -- @return nil: no values.
   local function validatePaths(source, contract, id)
      assert(
         source:match("^[%w_./%-]+%.c$")
            and not source:find("..", 1, true)
            and not source:match("^verification/"),
         "invalid C source path"
      )
      assert(
         contract:match("^[%w_./%-]+%.json$")
            and not contract:find("..", 1, true),
         "invalid contract path"
      )
      assert(id:match("^[%w_-]+$") and #id <= 64, "invalid run identity")
   end
   --- Validate the source, contract and optional refutation inputs.
   -- @return string, string, string, string|nil: selected inputs.
   local function inputs()
      local source, contract, id = arg[1], arg[2], arg[3]
      local witness = arg[4] == "--refute" and arg[5] or nil
      assert(
         source and contract and id and (not arg[4] or witness) and not arg[6],
         "usage: lua scripts/verification/c.lua SOURCE "
            .. "CONTRACT RUN_ID [--refute INPUTS]"
      )
      validatePaths(source, contract, id)
      return source, contract, id, witness
   end
   local source, contract, id, witness = inputs()
   local root = env.root .. "/.cache/verification/generic"
   assert(
      io.exec.run({ "mkdir", "-p", root }).state == "PASS",
      "cannot create verification output root"
   )
   local attempt = root .. "/" .. id
   assert(uv.fs_mkdir(attempt, 448), "attempt directory already exists")
   local report = {
      schema = "lma-generic-report/v1",
      controller_pid = uv.os_getpid(),
      status = "INCOMPLETE",
      profile = "lean-ir",
      source = source,
      contract = contract,
      steps = io.array(),
      source_refinement = "OPEN",
      binary_correctness = "OPEN",
      scalar_refinement = "OPEN",
   }
   --- Persist a complete receipt before beginning another operation.
   -- @return nil: no values.
   local function save()
      files.atomic_write(attempt .. "/report.json", io.json(report) .. "\n")
   end
   --- Record controller work that may fail outside a subprocess.
   -- @param name string: current operation.
   -- @return nil: no values.
   local function checkpoint(name)
      report.active_stage = name
      save()
   end
   checkpoint("initialization")
   --- Execute one evidence step and preserve its output before checking
   -- success.
   -- @param name string: evidence step name.
   -- @param argv table: literal command arguments.
   -- @param cwd string|nil: working directory.
   -- @return string: combined output.
   local function run(name, argv, cwd)
      print("generic: " .. name)
      local step = { name = name, state = "RUNNING", argv = io.array(argv) }
      report.steps[#report.steps + 1] = step
      checkpoint(name)
      local result = env.resources.run(
         argv,
         { cwd = cwd, timeout_ms = 1800000, max_bytes = 16777216 }
      )
      local output = result.stdout .. result.stderr
      files.write(attempt .. "/" .. name .. ".log", output)
      step.state, step.resources = result.state, result.resources
      step.log_sha256 = io.digest(attempt .. "/" .. name .. ".log")
      if result.state ~= "PASS" then
         report.status = verdict.classify(name, result)
         report.failed_stage = name
      end
      save()
      assert(result.state == "PASS", name .. " failed; see " .. attempt)
      return output
   end
   --- Bind proof inputs to owned sources, policies and the actual C unit.
   -- @return string: source identity digest.
   local function identity()
      local paths = files.inventory()
      paths[#paths + 1], paths[#paths + 2] = source, contract
      if witness then
         paths[#paths + 1] = witness
      end
      local rows = io.array()
      for _, path in ipairs(paths) do
         rows[#rows + 1] = { path = path, sha256 = io.digest(path) }
      end
      return io.digest_bytes(io.json(rows))
   end
   --- Build the locked admission engine independently of any producer override.
   -- @return string: executable path.
   local function verifier()
      run(
         "engine-build",
         env.cabal("build", { "libmemalloc-verifier:exe:libmemalloc-verifier" })
      )
      local binary = run(
         "engine-binary",
         env.cabal(
            "list-bin",
            { "libmemalloc-verifier:exe:libmemalloc-verifier" }
         )
      ):match("([^\n]+)\n?$")
      assert(binary and uv.fs_stat(binary), "missing verifier")
      return binary
   end
   --- Build, audit and independently replay the reconstructed theorem.
   -- @param proof string: generated Lean project directory.
   -- @param precondition string: admitted, validated contract predicate.
   -- @return nil: no values.
   local function auditProof(proof, precondition)
      checkpoint("proof-inputs")
      files.write(
         proof .. "/lean-toolchain",
         files.read("verification/theorems/lean-toolchain")
      )
      files.write(
         proof .. "/lakefile.toml",
         'name = "lma-generic"\ndefaultTargets = ["Generated"]\n'
            .. '[[lean_lib]]\nname = "Expected"\n'
            .. '[[lean_lib]]\nname = "Generated"\n'
            .. '[[require]]\nname = "libmemalloc-verification"\npath = '
            .. string.format("%q", env.root .. "/verification/theorems")
            .. "\n"
      )
      for _, name in ipairs({ "Expected", "Generated" }) do
         local path = proof .. "/" .. name .. ".lean"
         dofile("scripts/verification/lib/math_comments.lua").lean(
            files.read(path),
            path
         )
      end
      run("proof", { env.lake, "--wfail", "build" }, proof)
      local audit = witness
            and [[import Generated
import LibMemAllocAudit.Support
-- Mathematical statement: the expected claim has an admitted counterexample.
example : ¬ Expected.Claim := Generated.refuted
#audit_theorem Generated.refuted
]]
         or [[import Generated
import LibMemAllocAudit.Support
import LibMemAllocImp.C.Unsigned
import LibMemAllocImp.Certificates.Program
-- Mathematical statement: Expected.Claim.
example : Expected.Claim := Generated.verified
-- Mathematical statement: the certificate covers exactly the admitted program.
example : Allocator.Certificates.checkCoverage Expected.program Generated.coverage = true :=
  Generated.coverageAccepted
-- Mathematical statement: unsigned execution refines the admitted program and precondition.
example : Allocator.Translation.Refines 18446744073709551615 Expected.program
    (fun s : Allocator.C.Unsigned.State => %s s.cells)
    Allocator.C.Unsigned.State.cells
    (Allocator.C.Unsigned.Executes 18446744073709551615 Expected.program)
    (Allocator.C.Unsigned.Safe 18446744073709551615 Expected.program) :=
  Generated.unsignedRefinement
#audit_theorem Generated.verified
#audit_theorem Generated.coverageAccepted
#audit_theorem Generated.unsignedRefinement
]]
      files.write(proof .. "/Audit.lean", string.format(audit, precondition))
      run(
         "audit",
         { env.lake, "env", "lean", "-DwarningAsError=true", "Audit.lean" },
         proof
      )
      local theoremNames = witness and "Generated.refuted"
         or "Generated.verified Generated.coverageAccepted "
            .. "Generated.unsignedRefinement"
      local command = files.quote(env.lake)
         .. " env leanexport Generated -- "
         .. theoremNames
         .. " > "
         .. files.quote(attempt .. "/proof.ndjson")
      run("export", { "sh", "-c", command }, proof)
      run(
         "kernel",
         { env.lake, "check", "--from-export", attempt .. "/proof.ndjson" },
         proof
      )
   end
   --- Import C, reconstruct the expected claim, audit and replay its theorem.
   -- @return nil: no values.
   local function verify()
      checkpoint("inputs")
      report.input_identity = identity()
      local binding = io.decode(files.read(contract))
      assert(
         binding.schema == "lma-translation/v1",
         "unsupported translation contract"
      )
      assert(binding.symbol:match("^[A-Za-z_][A-Za-z0-9_]*$"), "invalid symbol")
      checkpoint("toolchain")
      local admitted, tools = pcall(
         dofile("scripts/verification/lib/toolchain.lua").validate,
         env,
         run
      )
      if not admitted then
         report.status, report.failed_stage = "INFRA_ERROR", "toolchain"
         error(tools)
      end
      report.tools = tools
      local trusted = verifier()
      local binary = os.getenv("LMA_VERIFIER") or trusted
      report.admission_sha256 = io.digest(trusted)
      report.verifier_sha256 = io.digest(binary)
      assert(
         io.digest(env.prefix .. "/bin/cn") == env.cn_sha256,
         "CN binary drift"
      )
      report.frontend_sha256 = env.cn_sha256
      local macros = run(
         "target",
         { "cc", "-std=c99", "-dM", "-E", "-x", "c", "/dev/null" }
      )
      for _, macro in ipairs({
         "__SIZEOF_LONG__ 8",
         "__SIZEOF_POINTER__ 8",
         "__SIZEOF_INT__ 4",
         "__CHAR_BIT__ 8",
         "__x86_64__ 1",
         "__linux__ 1",
      }) do
         assert(
            macros:find("#define " .. macro .. "\n", 1, true),
            "unsupported target"
         )
      end
      -- Preserve native compiler macros; normalize only admitted linkage metadata.
      local flags = preprocessing.command(source)
      local compiler =
         run("compiler", { "sh", "-c", "command -v cc" }):match("([^\n]+)")
      assert(compiler, "missing C compiler")
      compiler = assert(uv.fs_realpath(compiler))
      report.compiler_path = compiler
      report.compiler_sha256 = io.digest(compiler)
      report.target_macros_sha256 = io.digest_bytes(macros)
      report.compile_profile = io.array(flags)
      local plain = run("preprocess", flags)
      files.write(attempt .. "/preprocessed.c", plain)
      report.preprocessed_sha256 = io.digest_bytes(plain)
      checkpoint("normalization")
      local normalizedOk, normalized, removed =
         pcall(preprocessing.normalize, plain)
      if not normalizedOk then
         report.status, report.failed_stage = "UNSUPPORTED", "normalization"
         error(normalized)
      end
      files.write(attempt .. "/program.c", normalized)
      report.frontend_input_sha256 = io.digest_bytes(normalized)
      report.removed_default_visibility = removed
      local ail = run(
         "frontend",
         env.command({
            env.prefix .. "/bin/cn",
            "verify",
            "--skip=" .. binding.symbol,
            "--ast=ail",
            attempt .. "/program.c",
         })
      )
      files.write(attempt .. "/program.ail", ail)
      report.ail_sha256 = io.digest(attempt .. "/program.ail")
      -- Only the locked importer may choose the statement to be proved.
      run("admit", {
         trusted,
         "produce-generic",
         report.input_identity,
         contract,
         attempt .. "/program.ail",
         attempt .. "/admitted",
      })
      checkpoint("admitted-artifacts")
      local expected = files.read(attempt .. "/admitted/Expected.lean")
      local certificate = files.read(attempt .. "/admitted/certificate.json")
      report.expected_sha256 = io.digest_bytes(expected)
      report.certificate_sha256 = io.digest_bytes(certificate)
      local precondition = binding.contract.pre
      assert(
         precondition:match("^[A-Za-z_][A-Za-z0-9_.]*$"),
         "invalid precondition"
      )
      --- Reject a producer that changes the admitted inputs or statement.
      -- @param proof string: reconstructed project directory.
      -- @return nil: no values.
      local function checkAdmission(proof)
         checkpoint("admission")
         local claimOk, claim = pcall(files.read, proof .. "/Expected.lean")
         local certOk, cert =
            pcall(files.read, attempt .. "/recipe/certificate.json")
         if
            not claimOk
            or not certOk
            or claim ~= expected
            or cert ~= certificate
         then
            report.status, report.failed_stage = "INCONCLUSIVE", "admission"
            assert(claimOk, claim)
            assert(certOk, cert)
            error("producer changed the admitted claim or certificate")
         end
      end
      local proof = attempt .. "/proof"
      run("produce", {
         binary,
         "produce-generic",
         report.input_identity,
         contract,
         attempt .. "/program.ail",
         attempt .. "/recipe",
      })
      checkAdmission(attempt .. "/recipe")
      run("reconstruct", {
         binary,
         "replay-generic",
         report.input_identity,
         contract,
         attempt .. "/program.ail",
         attempt .. "/recipe/certificate.json",
         proof,
      })
      if witness then
         run("counterexample", {
            binary,
            "refute-generic",
            report.input_identity,
            contract,
            attempt .. "/program.ail",
            witness,
            proof,
         })
      end
      checkAdmission(proof)
      auditProof(proof, precondition)
      checkAdmission(proof)
      assert(
         identity() == report.input_identity,
         "sources changed during proof"
      )
      assert(
         run("preprocess-recheck", flags) == plain,
         "preprocessed headers changed during proof"
      )
      assert(
         io.digest(compiler) == report.compiler_sha256,
         "C compiler changed during proof"
      )
      assert(
         io.digest(trusted) == report.admission_sha256,
         "admission engine changed during proof"
      )
      assert(
         io.digest(attempt .. "/program.ail") == report.ail_sha256,
         "admitted AIL changed during proof"
      )
      report.export_sha256 = io.digest(attempt .. "/proof.ndjson")
      report.status = witness and "REFUTED" or "PASS"
      report.scalar_refinement = witness and "NOT_APPLICABLE" or "PASS"
   end
   local ok, failure = xpcall(verify, debug.traceback)
   report.failure = not ok and tostring(failure) or nil
   if not ok then
      report.failed_stage = report.failed_stage or report.active_stage
      if report.status == "INCOMPLETE" then
         report.status = "INFRA_ERROR"
      end
   end
   report.active_stage = nil
   save()
   assert(ok, failure)
   print(
      "Generic IR proof: " .. report.status .. "; " .. attempt .. "/report.json"
   )
end

return VERIFY_C_main()

-- EOF


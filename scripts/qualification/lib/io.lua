-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Verify qualification plans and bind task outputs to their producer
-- identities.
-- Part of planned qualification tasks and producer/consumer evidence.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_qualification_lib_io_loadModule()
   local QUALIFICATION_SHA256_HEX_LENGTH = 64

   local build_io = dofile("scripts/build/lib/io.lua")
   local artifact_io = build_io.release
   local qualification_model = dofile("scripts/qualification/lib/model.lua")
   local catalog = dofile("tools/build/qualification.lua")
   local exports = {
      B = build_io,
      R = artifact_io,
      Q = qualification_model,
      catalog = catalog,
   }

   --- Batch hashing still reads every byte; no object or digest cache is
   -- consulted.
   -- @param paths table: paths selected by the owning operation.
   -- @return table: batch hashing still reads every byte; no object or digest
   -- cache is consulted.
   local function QUALIFICATION_IO_hashes(paths)
      local command = { "sha256sum", "--" }

      for _, path in ipairs(paths) do
         command[#command + 1] = path
      end

      assert(#paths > 0, "empty digest inventory")

      local result = {}

      for line in build_io.output(command):gmatch("[^\n]+") do
         local hash, path = line:match("^(%x+)  (.+)$")

         assert(
            hash
               and #hash == QUALIFICATION_SHA256_HEX_LENGTH
               and not result[path],
            "invalid digest output"
         )

         result[path] = hash
      end

      return result
   end

   exports.hashes = QUALIFICATION_IO_hashes

   --- Validate the plan and every declared source digest before accepting task
   -- work.
   -- @param path string: plan manifest path.
   -- @return table, table, table: reconstructed graph, run identity and
   -- catalog.
   local function QUALIFICATION_IO_open(path)
      local plan =
         qualification_model.plan(catalog, build_io.query(path, ".campaign"))
      local identity = {
         plan_sha256 = build_io.digest(path),
         campaign_id = build_io.query(path, ".campaign_id"),
         attempt_id = build_io.query(path, ".attempt_id"),
         source_revision = build_io.query(path, ".source_revision"),
         source_date_epoch = build_io.query(path, ".source_date_epoch"),
      }

      assert(
         identity.source_revision
            == build_io.output({ "git", "rev-parse", "HEAD" }),
         "checkout revision differs"
      )
      assert(
         identity.source_date_epoch:match("^%d+$"),
         "invalid source timestamp"
      )
      assert(
         identity.campaign_id == (os.getenv("GITHUB_RUN_ID") or "local"),
         "foreign workflow run"
      )
      assert(
         identity.attempt_id == (os.getenv("GITHUB_RUN_ATTEMPT") or "1"),
         "rerun the entire workflow; partial attempts are not accepted"
      )

      local rows =
         build_io.query(path, ".source_inputs[] | [.path, .sha256] | @tsv")
      local paths, wanted = {}, {}

      for line in rows:gmatch("[^\n]+") do
         local input, digest = line:match("^([^\t]+)\t(%x+)$")

         artifact_io.safe_path(assert(input, "malformed source entry"))
         assert(not wanted[input], "duplicate source input")

         paths[#paths + 1] = input
         wanted[input] = digest
      end

      local actual = exports.hashes(paths)

      for input, digest in pairs(wanted) do
         assert(actual[input] == digest, "source input changed: " .. input)
      end

      local manifest = ".cache/qualification/source-inputs.json"

      build_io.write(manifest, build_io.query(path, ".source_inputs") .. "\n")

      identity.source_sha256 = build_io.digest(manifest)

      return plan, identity, catalog
   end

   exports.open = QUALIFICATION_IO_open

   --- Create an initial infrastructure-failure record in a fresh task
   -- directory.
   -- @param root string: evidence root.
   -- @param task table: planned task.
   -- @param identity table: verified run identity.
   -- @return table, string: mutable report and directory owned by this attempt.
   local function QUALIFICATION_IO_result(root, task, identity)
      local directory = root .. "/" .. task.id
      local path = directory .. "/report.json"
      local report = {
         schema = 1,
         id = task.id,
         stage = task.stage,
         status = "INFRA_ERROR",
         commands = artifact_io.array(),
         files = artifact_io.array(),
         dependencies = artifact_io.array(),
      }

      for key, value in pairs(identity) do
         report[key] = value
      end

      assert(
         not artifact_io.exists(directory),
         "output must be fresh: " .. directory
      )

      build_io.mkdir(directory)

      build_io.json(path, report)

      return report, directory
   end

   exports.result = QUALIFICATION_IO_result

   --- Hash task outputs after execution; the report excludes its own digest.
   -- @param report table: completed or failed task record.
   -- @param directory string: output tree to seal, including retained failure
   -- logs.
   -- @return nil: no values.
   local function QUALIFICATION_IO_seal(report, directory)
      report.files = artifact_io.array()

      local inventory, paths = artifact_io.files(directory), {}

      for _, path in ipairs(inventory) do
         paths[#paths + 1] = directory .. "/" .. path
      end

      local hashes = exports.hashes(paths)

      for _, path in ipairs(inventory) do
         if path ~= "report.json" then
            report.files[#report.files + 1] =
               { path = path, sha256 = hashes[directory .. "/" .. path] }
         end
      end

      build_io.json(directory .. "/report.json", report)
   end

   exports.seal = QUALIFICATION_IO_seal

   --- Reject corrupt, missing, extra or foreign evidence before dependency
   -- reuse.
   -- @param root string: downloaded evidence root.
   -- @param task table: expected task and artifact contract.
   -- @param identity table: accepted campaign and source identity.
   -- @return string, table: verified directory and manifest fields.
   local function QUALIFICATION_IO_verify(root, task, identity)
      local directory = root .. "/" .. task.id
      local path = directory .. "/report.json"
      local inventory, paths = artifact_io.files(directory), {}

      for _, file in ipairs(inventory) do
         paths[#paths + 1] = directory .. "/" .. file
      end

      local hashes = exports.hashes(paths)
      local record = {}

      for _, key in ipairs({
         "id",
         "stage",
         "status",
         "plan_sha256",
         "source_sha256",
         "campaign_id",
         "attempt_id",
      }) do
         record[key] = build_io.query(path, "." .. key)
      end

      record.files = tonumber(build_io.query(path, ".files | length"))
      qualification_model.accept(task, record, identity)

      local seen = { ["report.json"] = true }

      for line in
         build_io
            .query(path, ".files[] | [.path, .sha256] | @tsv")
            :gmatch("[^\n]+")
      do
         local file, hash = line:match("^([^\t]+)\t(%x+)$")

         artifact_io.safe_path(assert(file, "malformed evidence entry"))
         assert(not seen[file], "duplicate evidence file")

         seen[file] = true
         assert(
            hashes[directory .. "/" .. file] == hash,
            "corrupt evidence: " .. file
         )
      end

      for _, file in ipairs(inventory) do
         assert(seen[file], "unlisted evidence file: " .. file)
      end

      for _, file in ipairs(qualification_model.artifacts(task, catalog)) do
         assert(seen[file], "missing required artifact: " .. file)
      end

      return directory, record
   end

   exports.verify = QUALIFICATION_IO_verify

   --- Bind the consumer to the exact verified producer manifest.
   -- @param report table: mutable consumer evidence.
   -- @param root string: evidence root.
   -- @param task table: required producer.
   -- @param identity table: accepted campaign identity.
   -- @return string: verified producer directory.
   local function QUALIFICATION_IO_dependency(report, root, task, identity)
      local directory = exports.verify(root, task, identity)

      report.dependencies[#report.dependencies + 1] =
         { id = task.id, sha256 = build_io.digest(directory .. "/report.json") }

      return directory
   end

   exports.dependency = QUALIFICATION_IO_dependency

   --- Retain command output and fail on a nonzero exit status.
   -- @param report table: mutable command evidence.
   -- @param directory string: output directory.
   -- @param label string: unique command-log stem.
   -- @param command table: argument vector without shell interpolation.
   -- @param environment table|nil: explicit environment overrides.
   -- @return string: captured command output; raises after retaining failures.
   local function QUALIFICATION_IO_execute(
      report,
      directory,
      label,
      command,
      environment
   )
      assert(
         build_io.run(report, directory, label, command, environment),
         "command failed: " .. label
      )

      return build_io.read(directory .. "/" .. label .. ".log")
   end

   exports.execute = QUALIFICATION_IO_execute

   --- Construct the expected trace independently of the compiled fixture.
   -- @param operations number: contracted operation count.
   -- @return string: canonical expected output.
   local function QUALIFICATION_IO_trace(operations)
      return string.format(catalog.fixture.trace, operations)
   end

   exports.trace = QUALIFICATION_IO_trace

   return exports
end

return scripts_qualification_lib_io_loadModule()

-- EOF


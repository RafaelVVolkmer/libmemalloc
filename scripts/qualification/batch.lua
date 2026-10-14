-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Prepare once, execute isolated cases, retain every result and fail closed.
-- Part of planned qualification tasks and producer/consumer evidence.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_qualification_batch_main()
   dofile("scripts/workspace/lib/lock.lua").guard("shared")
   local evidence_io = dofile("scripts/qualification/lib/io.lua")
   local execution_api = dofile("scripts/qualification/lib/execution.lua")
   local build_io, artifact_io = evidence_io.B, evidence_io.R
   local options = artifact_io.options(arg, {
      batch = true,
      plan = true,
      input = true,
      output = true,
   })
   local plan_path = options.plan or ".cache/qualification/plan.json"
   local plan, identity, catalog = evidence_io.open(plan_path)
   local batch =
      execution_api.batch(plan, assert(options.batch, "--batch required"))
   local input = options.input or ".cache/qualification/evidence"
   local output = options.output or ".cache/qualification/output"
   local policy = catalog.execution

   artifact_io.safe_path(input)

   artifact_io.safe_path(output)
   assert(output:match("^%.cache/"), "batch output must stay in .cache")

   local manifest = output .. "/batches/" .. batch.id .. ".json"

   assert(not artifact_io.exists(manifest), "batch output must be fresh")

   local report = {
      id = batch.id,
      stage = batch.stage,
      status = "FAIL",
      tasks = artifact_io.array(),
      commands = artifact_io.array(),
      logs = artifact_io.array(),
      isolation = policy.isolation,
      processes_per_job = policy.processes_per_job,
      tools = artifact_io.array({
         build_io.tool("setsid"),
         build_io.tool("pgrep"),
         build_io.tool("timeout"),
      }),
   }

   for key, value in pairs(identity) do
      report[key] = value
   end

   build_io.json(manifest, report)

   local workspace = artifact_io.platform.temporary_directory("tests")
   local environment_valid = true

   --- Run one isolated case and retain its result even on failure.
   -- @param id string: stable identity used to match the requested entry.
   -- @return nil: no values.
   local function qualification_batch_runCase(id)
      local task = evidence_io.Q.task(plan, id)
      local work = workspace .. "/" .. id
      local result = { id = id, status = "FAIL" }

      report.tasks[#report.tasks + 1] = result

      local ok, failure = xpcall(
         --- Execute a task in a fresh workspace and retain cleanup failures.
         -- @return nil: no values.
         function()
            assert(environment_valid, "a previous case left the runner unclean")
            assert(not artifact_io.exists(work), "case workspace must be fresh")

            build_io.mkdir(work .. "/tmp")

            build_io.mkdir(work .. "/home")

            -- setsid gives this case a process session whose surviving children
            -- can
            -- be detected and terminated after the case leader exits.
            local command = {
               "setsid",
               "--wait",
               "sh",
               "-c",
               'printf "%s\\n" "$$" > "$1"; shift; exec "$@"',
               "qualification-case",
               work .. "/session.pid",
               "timeout",
               "--kill-after=" .. policy.kill_grace_seconds,
               tostring(policy.task_timeout_seconds),
               "env",
               "-i",
               "PATH=" .. assert(os.getenv("PATH"), "PATH required"),
               "HOME=" .. work .. "/home",
               "TMPDIR=" .. work .. "/tmp",
               "TMP=" .. work .. "/tmp",
               "TEMP=" .. work .. "/tmp",
               "LC_ALL=C",
               "TZ=UTC",
               "CCACHE_DISABLE=1",
               "SOURCE_DATE_EPOCH=" .. identity.source_date_epoch,
               "LIBMEMALLOC_QUALIFICATION_BATCH=" .. batch.id,
            }

            for _, name in ipairs({
               "GITHUB_RUN_ID",
               "GITHUB_RUN_ATTEMPT",
               "ImageVersion",
            }) do
               local value = os.getenv(name)

               if value then
                  command[#command + 1] = name .. "=" .. value
               end
            end

            for _, value in ipairs({
               "lua",
               "scripts/qualification/run.lua",
               "--task=" .. id,
               "--plan=" .. plan_path,
               "--input=" .. input,
               "--output=" .. output .. "/evidence",
            }) do
               command[#command + 1] = value
            end

            local succeeded, log =
               build_io.run(report, output .. "/logs/" .. batch.id, id, command)

            report.logs[#report.logs + 1] = {
               path = "logs/" .. batch.id .. "/" .. id .. ".log",
               sha256 = build_io.digest(log),
            }

            --- Wait for bounded cleanup and reject surviving case subprocesses.
            -- @return nil: no values.
            local function qualification_batch_cleanupSession()
               if artifact_io.exists(work .. "/session.pid") then
                  local session =
                     build_io.read(work .. "/session.pid"):match("^(%d+)\n$")

                  assert(session, "invalid process session identity")

                  local probe = {
                     "pgrep",
                     "--runstates",
                     policy.live_process_states,
                     "-s",
                     session,
                  }
                  local children

                  -- Sanitizer symbolizers may finish after the instrumented
                  -- process.
                  -- Zombies are already terminated; allow live helpers bounded
                  -- cleanup.
                  for check = 1, policy.cleanup_checks do
                     children = artifact_io.platform.command_output(probe)
                     if not children or children == "" then
                        break
                     end

                     if check < policy.cleanup_checks then
                        assert(
                           artifact_io.platform.command_succeeded({
                              "sleep",
                              policy.cleanup_pause_seconds,
                           }),
                           "process cleanup wait failed"
                        )
                     end
                  end

                  --- Terminate remaining case processes and verify the runner
                  -- is
                  -- reusable.
                  -- @return nil: no values.
                  local function qualification_batch_killSurvivors()
                     if children and children ~= "" then
                        for pid in children:gmatch("%d+") do
                           artifact_io.platform.command_succeeded({
                              "kill",
                              "-KILL",
                              pid,
                           })
                        end

                        local remaining =
                           artifact_io.platform.command_output(probe)

                        environment_valid = not remaining or remaining == ""
                        error("case left subprocesses alive: " .. children)
                     end
                  end

                  qualification_batch_killSurvivors()
               end
            end

            qualification_batch_cleanupSession()

            assert(succeeded, "case process failed; inspect " .. log)

            evidence_io.verify(output .. "/evidence", task, identity)

            -- A test may not alter its downloaded input artifacts, even on its
            -- last
            -- invocation in a batch. Byte verification is independent of
            -- permissions.
            local dependencies = evidence_io.Q.dependencies(task, catalog)

            for _, dependency in ipairs(dependencies) do
               evidence_io.verify(
                  input,
                  evidence_io.Q.task(plan, dependency),
                  identity
               )
            end

            result.status = "PASS"
         end,
         debug.traceback
      )

      if not ok then
         result.error = tostring(failure):gsub("[\128-\255]", "?")
         if
            not artifact_io.exists(
               output .. "/evidence/" .. id .. "/report.json"
            )
         then
            local missing, directory =
               evidence_io.result(output .. "/evidence", task, identity)

            missing.error = result.error
            build_io.write(
               directory .. "/batch-error.log",
               result.error .. "\n"
            )

            evidence_io.seal(missing, directory)
         end
      end

      build_io.json(manifest, report)

      print(id .. ": " .. result.status)

      io.flush()
   end

   for _, id in ipairs(batch.tasks) do
      qualification_batch_runCase(id)
   end

   artifact_io.platform.remove_temporary_directory(workspace)

   local passed = true

   for _, result in ipairs(report.tasks) do
      passed = passed and result.status == "PASS"
   end

   report.status = passed and "PASS" or "FAIL"
   build_io.json(manifest, report)

   local summary = os.getenv("GITHUB_STEP_SUMMARY")

   --- Append the batch result to the hosted step summary when requested.
   -- @return nil: no values.
   local function qualification_batch_writeSummary()
      if summary then
         local file = assert(io.open(summary, "a"))

         assert(
            file:write(
               "Batch `" .. batch.id .. "`: **" .. report.status .. "**.\n\n"
            )
         )
         assert(
            file:write("Each row has its own manifest and execution log.\n\n")
         )
         assert(file:write("| Case | Result |\n| --- | --- |\n"))
         for _, result in ipairs(report.tasks) do
            assert(
               file:write(
                  "| `" .. result.id .. "` | " .. result.status .. " |\n"
               )
            )
         end

         assert(file:close())
      end
   end

   qualification_batch_writeSummary()

   print(batch.id .. ": " .. report.status)
   assert(passed, "batch contains failed cases; inspect " .. manifest)
end

return scripts_qualification_batch_main()

-- EOF


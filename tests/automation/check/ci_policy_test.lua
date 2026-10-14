-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer
-- <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Execute action policy scripts with adversarial inputs and no cloud access.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_lint_ci_policy_test_suite_main()
   local platform = dofile("scripts/lib/platform.lua")
   local download = ".github/actions/verified-download/action.yml"
   local cache = ".github/actions/cache-plane/action.yml"
   local attempt = ".github/actions/qualification-attempt/action.yml"
   local count = 0

   --- Read the workflow or policy under test.
   -- @param path string: filesystem path selected by the caller.
   -- @return any: the workflow or policy under test.
   local function read(path)
      local handle = assert(io.open(path, "rb"))
      local source = handle:read("*a")

      assert(handle:close())

      return source
   end

   --- Stage a workflow mutation in the temporary repository.
   -- @param path string: filesystem path selected by the caller.
   -- @param source any: source value inspected by this operation.
   -- @return nil: no values.
   local function write(path, source)
      local handle = assert(io.open(path, "wb"))

      assert(handle:write(source))
      assert(handle:close())
   end

   --- Copy a real entrypoint into the isolated test repository.
   -- @param path string: filesystem path selected by the caller.
   -- @param target any|nil: selected target configuration or path.
   -- @return any: copy a real entrypoint into the isolated test repository.
   local function script(path, target)
      local blocks = {}
      local current = nil

      for line in (read(path) .. "\n"):gmatch("(.-)\n") do
         if line == "      run: |" then
            current = {}
            blocks[#blocks + 1] = current
         elseif current and (line == "" or line:match("^        ")) then
            current[#current + 1] = line:gsub("^        ", "")
         else
            current = nil
         end
      end

      return table.concat(
         assert(blocks[target or 1], "Missing action script"),
         "\n"
      )
   end

   --- Run one policy case against the selected environment values.
   -- @param path string: filesystem path selected by the caller.
   -- @param values table: values consumed in the operation’s declared order.
   -- @param expected any: expected reference value used by this check.
   -- @param output_pattern any: output pattern supplied to this operation.
   -- @return nil: no values.
   local function run(path, values, expected, output_pattern)
      local directory = platform.temporary_directory()

      --- Restore environment state after the policy case succeeds or fails.
      -- @return nil: no values.
      local success, failure = xpcall(function()
         local bin = directory .. "/bin"

         platform.run({ "mkdir", "-p", "--", bin })

         -- Only the availability probe uses this stub; no cloud request is
         -- sent.
         write(bin .. "/aws", "#!/bin/sh\nexit 0\n")
         platform.run({ "chmod", "700", bin .. "/aws" })

         local output = directory .. "/output"

         write(output, "")

         local environment = {
            LUA = os.getenv("LIBMEMALLOC_LUA") or arg[-1] or "lua",
            PATH = bin .. ":" .. assert(os.getenv("PATH")),
            RUNNER_TEMP = directory,
            LIBMEMALLOC_CACHE_ROOT = directory,
            RUNNER_OS = "Linux",
            RUNNER_ARCH = "X64",
            GITHUB_OUTPUT = output,
            GITHUB_STEP_SUMMARY = directory .. "/summary",
            TOOL_NAME = "fixture",
            TOOL_VERSION = "1.0",
            TOOL_FILENAME = "fixture.tar.gz",
            TOOL_SHA256 = string.rep("a", 64),
            TOOL_ORIGIN = "https://example.invalid",
            TOOL_DIRECTORY = "releases/v1",
            EVENT_NAME = "pull_request",
            REF_NAME = "main",
            DEFAULT_BRANCH = "main",
            PLAN_ATTEMPT = "1",
            CURRENT_ATTEMPT = "1",
         }

         for key, value in pairs(values) do
            environment[key] = value
         end

         -- CWE-78: values are quoted argv, never substituted into the Bash
         -- body.
         local arguments = { "env", "-i" }

         for key, value in pairs(environment) do
            arguments[#arguments + 1] = key .. "=" .. value
         end

         for _, value in ipairs({
            "timeout",
            "10",
            "bash",
            "--noprofile",
            "--norc",
            "-euo",
            "pipefail",
            "-c",
            script(path),
         }) do
            arguments[#arguments + 1] = value
         end

         local actual = platform.command_succeeded_silent(arguments)

         assert(actual == expected, path .. ": unexpected policy result")

         local result = read(output)

         if not expected then
            assert(result == "", "Invalid input wrote GitHub outputs")
         end

         if output_pattern then
            assert(result:find(output_pattern), "Missing expected cache output")
         end

         if path == attempt then
            assert(
               read(directory .. "/summary"):find("Re-run all jobs", 1, true),
               "attempt preflight did not explain recovery"
            )
         end

         count = count + 1
      end, debug.traceback)

      platform.remove_temporary_directory(directory)
      assert(success, failure)
   end

   run(download, {}, true, "fixture/1%.0/" .. string.rep("a", 64))
   run(
      download,
      { TOOL_DIRECTORY = "releases/%40biomejs/biome%402.5.10" },
      true
   )

   for _, case in ipairs({
      { "TOOL_NAME", ".." },
      { "TOOL_VERSION", ".." },
      { "TOOL_FILENAME", "" },
      { "TOOL_FILENAME", "../outside" },
      { "TOOL_FILENAME", "file\ninjected=true" },
      { "TOOL_SHA256", "invalid" },
      { "TOOL_ORIGIN", "http://example.invalid" },
      { "TOOL_ORIGIN", "https://example.invalid?query" },
      { "TOOL_DIRECTORY", "../outside" },
      { "TOOL_DIRECTORY", "%2e%2e/outside" },
      { "LIBMEMALLOC_CI_TOOL_CACHE_DIR", "/tmp/cache\ninjected=true" },
   }) do
      run(download, { [case[1]] = case[2] }, false)
   end

   for _, path in ipairs({ download, cache }) do
      for _, event in ipairs({
         "pull_request",
         "merge_group",
         "push",
         "workflow_dispatch",
      }) do
         local trusted = event == "push" or event == "workflow_dispatch"

         run(path, {
            EVENT_NAME = event,
            LIBMEMALLOC_CI_S3_CACHE_BUCKET = "fixture",
         }, true, "shared_cache_write=" .. tostring(trusted))
      end

      run(path, {
         LIBMEMALLOC_CI_S3_CACHE_BUCKET = "fixture",
         LIBMEMALLOC_CI_S3_CACHE_PREFIX = "safe\nunsafe",
      }, false)
      run(path, {
         LIBMEMALLOC_CI_S3_CACHE_BUCKET = "fixture",
         LIBMEMALLOC_CI_S3_CACHE_ENDPOINT = "http://cache.example.invalid",
      }, false)
      run(path, {
         LIBMEMALLOC_CI_S3_CACHE_BUCKET = "fixture",
         LIBMEMALLOC_CI_S3_CACHE_ENDPOINT = "http://localhost:80@host.invalid",
      }, false)
      run(path, {
         LIBMEMALLOC_CI_S3_CACHE_BUCKET = "fixture",
         EVENT_NAME = "push",
         REF_NAME = "feature",
      }, true, "shared_cache_write=false")
   end

   run(cache, {
      LIBMEMALLOC_CI_BAZEL_REMOTE_CACHE = "grpc://cache.example.invalid:9092",
   }, false)

   local injected_cache = "https://x.invalid\nbuild --config=evil"

   run(cache, {
      LIBMEMALLOC_CI_BAZEL_REMOTE_CACHE = injected_cache,
   }, false)
   run(cache, {
      LIBMEMALLOC_CI_BAZEL_REMOTE_INSTANCE = "x\nbuild --action_env=TOKEN",
   }, false)

   run(attempt, {}, true)
   run(attempt, { PLAN_ATTEMPT = "2", CURRENT_ATTEMPT = "2" }, true)
   run(attempt, { PLAN_ATTEMPT = "1", CURRENT_ATTEMPT = "2" }, false)
   run(attempt, { PLAN_ATTEMPT = "" }, false)
   run(attempt, { PLAN_ATTEMPT = "1\ninjected=true" }, false)
   run(cache, { INPUT_MODE = "required" }, false)
   run(
      cache,
      { INPUT_MODE = "disabled", EVENT_NAME = "push" },
      true,
      "shared_cache_write=false"
   )
   run(cache, { LIBMEMALLOC_CACHE_ROOT = "/tmp/safe\ninjected=true" }, false)
   run(
      cache,
      { EVENT_NAME = "push", DEFAULT_BRANCH = "", REF_NAME = "" },
      true,
      "shared_cache_write=false"
   )

   local fetch = script(download, 2)

   local unresolved = dofile("scripts/github/lib/cache_plane.lua").resolve({
      LIBMEMALLOC_CACHE_ROOT = "/tmp/policy-only",
      EVENT_NAME = "push",
   }, false)

   assert(
      not unresolved.shared_cache_write,
      "missing branches authorize writes"
   )
   assert(not unresolved.bazel_write, "missing branches authorize Bazel writes")
   count = count + 1

   for _, required in ipairs({
      "--proto-redir '=https'",
      "--max-time 300",
      "mktemp",
      "sha256sum --check --strict",
   }) do
      assert(fetch:find(required, 1, true), "Missing download defense")
   end

   dofile("scripts/check/lib/workflows.lua").documentation(
      read(".github/workflows/documentation.yml")
   )

   print(
      string.format("CI security: %d adversarial policy cases passed.", count)
   )
end

return tests_lint_ci_policy_test_suite_main()

-- EOF


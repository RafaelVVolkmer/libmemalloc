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
   -- @param padding number|nil: indentation of the run field.
   -- @return any: copy a real entrypoint into the isolated test repository.
   local function script(path, target, padding)
      local blocks = {}
      local current = nil
      local prefix = string.rep(" ", padding or 6)
      local body = prefix .. "  "

      for line in (read(path) .. "\n"):gmatch("(.-)\n") do
         if line == prefix .. "run: |" then
            current = {}
            blocks[#blocks + 1] = current
         elseif current and (line == "" or line:sub(1, #body) == body) then
            current[#current + 1] = line:sub(#body + 1)
         else
            current = nil
         end
      end

      return table.concat(
         assert(
            blocks[target == -1 and #blocks or target or 1],
            "Missing action script"
         ),
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

   -- Execute the workflow's verification command with a recording binary.
   local verification = platform.temporary_directory()
   platform.run({ "mkdir", "-p", verification .. "/tools" })
   write(
      verification .. "/tools/gittuf",
      '#!/bin/sh\nprintf \'%s\\n\' "$@" > "$LIBMEMALLOC_CACHE_ROOT/arguments"\n'
         .. 'exit "$VERIFY_EXIT"\n'
   )
   platform.run({ "chmod", "700", verification .. "/tools/gittuf" })
   local main_verification = "verify-ref\n--from-entry\n"
      .. "fdb4556ded199f692bf9d20c6830fbb56cf954e4\nrefs/heads/main\n"
   for _, case in ipairs({
      { "refs/heads/main", "0", main_verification, true },
      {
         "refs/tags/fixture",
         "0",
         "verify-ref\n--latest-only\nrefs/tags/fixture\n",
         true,
      },
      {
         "refs/tags/fixture",
         "1",
         "verify-ref\n--latest-only\nrefs/tags/fixture\n",
         false,
      },
      { "refs/heads/main", "1", main_verification, false },
      {
         "refs/heads/develop",
         "0",
         "verify-ref\nrefs/heads/develop\n",
         true,
      },
      { "refs/pull/12/merge", "0", main_verification, true, "pull_request" },
      { "refs/pull/12/merge", "1", main_verification, false, "pull_request" },
   }) do
      local passed = platform.command_succeeded_silent({
         "env",
         "GITHUB_REF=" .. case[1],
         "GITHUB_EVENT_NAME=" .. (case[5] or "push"),
         "BASE_REF=main",
         "VERIFY_EXIT=" .. case[2],
         "LIBMEMALLOC_CACHE_ROOT=" .. verification,
         "bash",
         "-c",
         script(".github/workflows/security.yml", -1, 8),
      })
      assert(passed == case[4], "gittuf verification failure was ignored")
      assert(
         read(verification .. "/arguments") == case[3],
         "wrong gittuf verification scope"
      )
      count = count + 1
   end
   platform.remove_temporary_directory(verification)

   -- Exercise real Git transfers: RSL messages do not retain old tag objects.
   local directory = platform.temporary_directory()
   local restore = directory .. "/restore.sh"
   local select_reference = directory .. "/select-reference.sh"

   write(restore, script(".github/actions/gittuf-objects/action.yml"))
   write(select_reference, script(".github/workflows/security.yml", 7, 8))

   local fixture = [=[
set -euo pipefail
cd "$1"
restore="$2"
select_reference="$3"
export TARGET_REF=refs/tags/fixture
git init --quiet --initial-branch=main seed
git -C seed commit --quiet --allow-empty -m initial
base="$(git -C seed rev-parse HEAD)"
git -C seed tag -a fixture -m original
old="$(git -C seed rev-parse refs/tags/fixture)"
tree="$(git -C seed mktree </dev/null)"
entry="$(printf 'RSL Reference Entry\n\nref: %s\ntargetID: %s\nnumber: 1\n' \
  "$TARGET_REF" "$old" | git -C seed commit-tree "$tree")"
git -C seed update-ref refs/gittuf/reference-state-log "$entry"
git -C seed tag --force -a fixture -m replacement
git -C seed commit --quiet --allow-empty -m next
git clone --quiet --no-local seed replica
cd replica

# Match actions/checkout with an exact SHA and no local main branch.
export GITHUB_SHA="$(git rev-parse HEAD)"
git checkout --quiet --detach "$GITHUB_SHA"
git branch --delete --force main
export GITHUB_EVENT_NAME=push GITHUB_REF=refs/heads/main
bash "$select_reference"
[[ "$(git rev-parse refs/heads/main)" == "$GITHUB_SHA" ]]
[[ "$(git rev-parse HEAD)" == "$GITHUB_SHA" ]]

# Manual branch runs also materialize the exact event commit.
export GITHUB_EVENT_NAME=workflow_dispatch GITHUB_REF=refs/heads/develop
bash "$select_reference"
[[ "$(git rev-parse refs/heads/develop)" == "$GITHUB_SHA" ]]

# PRs select their checked-out trusted base, not the synthetic merge SHA.
git checkout --quiet --detach "$base"
export GITHUB_EVENT_NAME=pull_request GITHUB_REF=refs/pull/12/merge
export BASE_REF=main BASE_SHA="$base"
bash "$select_reference"
[[ "$(git rev-parse refs/heads/main)" == "$base" ]]

# Reject checkout mismatches and malformed references before writing refs.
export BASE_SHA="$GITHUB_SHA"
if bash "$select_reference"; then exit 1; fi
[[ "$(git rev-parse refs/heads/main)" == "$base" ]]
export BASE_SHA="$base" BASE_REF='main..invalid'
if bash "$select_reference"; then exit 1; fi

# Keep the signed annotated tag object instead of replacing it with HEAD.
export GITHUB_EVENT_NAME=push GITHUB_REF=refs/tags/fixture
export GITHUB_SHA="$base"
tag="$(git rev-parse refs/tags/fixture)"
bash "$select_reference"
[[ "$(git rev-parse refs/tags/fixture)" == "$tag" ]]
[[ "$(git cat-file -t refs/tags/fixture)" == tag ]]
git checkout --quiet --detach refs/heads/develop
export GITHUB_SHA="$(git rev-parse HEAD)"
if bash "$select_reference"; then exit 1; fi
[[ "$(git rev-parse refs/tags/fixture)" == "$tag" ]]
export GITHUB_REF=refs/pull/12/merge
if bash "$select_reference"; then exit 1; fi

git fetch --quiet origin \
  refs/gittuf/reference-state-log:refs/gittuf/reference-state-log
if git cat-file -e "$old" 2>/dev/null; then
  printf '%s\n' 'Fixture unexpectedly contains the replaced tag.' >&2
  exit 1
fi
refs="$(git show-ref)"
fetch_head="$(cat .git/FETCH_HEAD)"
bash "$restore"
git cat-file -e "$old^{commit}"
[[ "$(git show-ref)" == "$refs" ]]
[[ "$(cat .git/FETCH_HEAD)" == "$fetch_head" ]]

# Already recovered targets must not require a working remote.
git remote set-url origin "$1/absent"
bash "$restore"

# Unrelated references must not block the selected tag's recovery.
missing=1111111111111111111111111111111111111111
other="$(printf 'RSL Reference Entry\n\nref: refs/tags/other\ntargetID: %s\n' \
  "$missing" | git commit-tree "$tree" -p "$entry")"
git update-ref refs/gittuf/reference-state-log "$other"
bash "$restore"

# A required target unavailable from origin must fail closed.
bad="$(printf 'RSL Reference Entry\n\nref: %s\ntargetID: %s\n' \
  "$TARGET_REF" "$missing" | git commit-tree "$tree" -p "$entry")"
git update-ref refs/gittuf/reference-state-log "$bad"
if bash "$restore" >missing.log 2>&1; then
  exit 1
fi
grep -q 'Cannot recover gittuf target' missing.log

# RSL values are data, never shell commands or fetch options.
bad="$(printf 'RSL Reference Entry\n\nref: %s\ntargetID: %s\n' \
  "$TARGET_REF" '$(touch injected)' | git commit-tree "$tree" -p "$entry")"
git update-ref refs/gittuf/reference-state-log "$bad"
if bash "$restore" >invalid.log 2>&1; then
  exit 1
fi
grep -q 'Invalid object ID' invalid.log
[[ ! -e injected ]]

git update-ref -d refs/gittuf/reference-state-log
if bash "$restore" >absent.log 2>&1; then
  exit 1
fi
]=]
   local success = platform.command_succeeded({
      "env",
      "-i",
      "PATH=" .. assert(os.getenv("PATH")),
      "HOME=" .. directory,
      "GIT_CONFIG_NOSYSTEM=1",
      "GIT_CONFIG_GLOBAL=/dev/null",
      "GIT_AUTHOR_NAME=CI fixture",
      "GIT_AUTHOR_EMAIL=fixture@example.invalid",
      "GIT_COMMITTER_NAME=CI fixture",
      "GIT_COMMITTER_EMAIL=fixture@example.invalid",
      "timeout",
      "30",
      "bash",
      "--noprofile",
      "--norc",
      "-c",
      fixture,
      "gittuf-fixture",
      directory,
      restore,
      select_reference,
   })

   platform.remove_temporary_directory(directory)
   assert(success, "gittuf reference or object recovery regression failed")
   count = count + 14

   print(
      string.format("CI security: %d adversarial policy cases passed.", count)
   )
end

return tests_lint_ci_policy_test_suite_main()

-- EOF


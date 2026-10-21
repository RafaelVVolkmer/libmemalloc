-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Exercise the hosted commit selector with a local remote and rewritten refs.

--- Require absent old commits to fall back to a real baseline, never skip work.
-- @return nil: no values.
local function COMMIT_RANGE_TEST_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local platform = artifacts.platform
   local root = platform.temporary_directory("tests")
   local repository = root .. "/repository"
   local remote = root .. "/remote.git"
   local cache = root .. "/.cache"
   local source = artifacts.read(".github/workflows/commit-policy.yml")
   local block = assert(
      source:match("%- name: Select commits(.-)%- name: Validate commit"),
      "commit selector step missing"
   )
   local script = assert(block:match("run: |\n(.*)"), "selector body missing")

   script = script:gsub("\n          ", "\n"):gsub("^          ", "")
   local count = 0

   --- Run isolated Git without contributor hooks, identities or signing keys.
   -- @param ... any: remaining arguments forwarded with their original
   -- ordering.
   -- @return any: run isolated Git without contributor hooks, identities or
   -- signing keys.
   local function git(...)
      local command = {
         "git",
         "-C",
         repository,
         "-c",
         "user.name=Fixture",
         "-c",
         "user.email=fixture@example.org",
         "-c",
         "commit.gpgSign=false",
         "-c",
         "core.hooksPath=/dev/null",
      }

      for _, value in ipairs({ ... }) do
         command[#command + 1] = value
      end

      return artifacts.output(command)
   end

   --- Create local ref histories and clean both repositories on failure.
   -- @return nil: no values.
   local ok, failure = xpcall(function()
      artifacts.mkdir(repository)
      artifacts.mkdir(cache .. "/tools")
      git("init", "--quiet", "--initial-branch=main")
      git("commit", "--allow-empty", "-m", "baseline")
      local baseline = git("rev-parse", "HEAD")

      platform.run({ "git", "clone", "--quiet", "--bare", repository, remote })
      git("remote", "add", "origin", remote)
      git("switch", "--quiet", "-c", "feature/test")
      git("commit", "--allow-empty", "-m", "candidate")
      local head = git("rev-parse", "HEAD")

      --- Execute the real Bash body and compare the selected revision set.
      -- @param before any: before supplied to this operation.
      -- @param ref any: ref supplied to this operation.
      -- @param event any: event supplied to this operation.
      -- @param base any: base supplied to this operation.
      -- @param expected any: expected reference value used by this check.
      -- @return nil: no values.
      local function check(before, ref, event, base, expected)
         local command = {
            "env",
            "EVENT_NAME=" .. event,
            "BEFORE_SHA=" .. before,
            "GITHUB_SHA=" .. head,
            "GITHUB_REF=" .. ref,
            "PR_BASE_SHA=" .. base,
            "PR_HEAD_SHA=" .. head,
            "MERGE_BASE_SHA=" .. base,
            "MERGE_HEAD_SHA=" .. head,
            "DEFAULT_BRANCH=main",
            "BASELINE_REF=",
            "LIBMEMALLOC_CACHE_ROOT=" .. cache,
            "bash",
            "--noprofile",
            "--norc",
            "-euo",
            "pipefail",
            "-c",
            script,
         }

         platform.run_in_directory(repository, command)
         local actual = artifacts.read(cache .. "/tools/commit-policy-shas")

         assert(actual == expected, "selector omitted or added revisions")
         count = count + 1
      end

      check(baseline, "refs/heads/feature/test", "push", "", head .. "\n")
      check(
         string.rep("0", 40),
         "refs/heads/feature/test",
         "push",
         "",
         head .. "\n"
      )
      check(
         string.rep("a", 40),
         "refs/heads/feature/test",
         "push",
         "",
         head .. "\n"
      )
      check(
         string.rep("a", 40),
         "refs/heads/main",
         "push",
         "",
         baseline .. "\n" .. head .. "\n"
      )
      check("", "refs/pull/1/merge", "pull_request", baseline, head .. "\n")
      check("", "refs/heads/queue", "merge_group", baseline, head .. "\n")
      check(
         "",
         "refs/heads/feature/test",
         "workflow_dispatch",
         "",
         head .. "\n"
      )
   end, debug.traceback)

   platform.remove_temporary_directory(root)
   assert(ok, failure)
   print("Commit selection: " .. count .. " history cases passed.")
end

return COMMIT_RANGE_TEST_main()

-- EOF


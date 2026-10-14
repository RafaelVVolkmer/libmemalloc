-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Exercise actual Git hooks, destination baselines and OpenPGP signatures.
-- Uses disposable repositories and an ephemeral signing key; never publishes
-- to a network remote or changes the contributor's identity or keyring.

--- Require real commits, merges, tags and rejected pushes to match policy.
-- @return nil: no values.
local function HOOK_INTEGRATION_main()
   local platform = dofile("scripts/lib/platform.lua")
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local executor = dofile("scripts/process/lib/exec.lua")
   local uv = require("luv")
   local directory = platform.temporary_directory("tests")
   local repository = directory .. "/repository"
   local remote = directory .. "/remote.git"
   local keyring = directory .. "/keys"
   local interpreter = assert(platform.resolve_tool("LIBMEMALLOC_LUA", "lua"))
   local environment = uv.os_environ()

   environment.GNUPGHOME = keyring
   environment.GIT_CONFIG_NOSYSTEM = "1"
   environment.GIT_CONFIG_GLOBAL = "/dev/null"
   environment.GIT_CONFIG_COUNT = nil
   environment.GIT_DIR = nil
   environment.GIT_WORK_TREE = nil
   environment.GIT_INDEX_FILE = nil
   local env, count = {}, 0

   for key, value in pairs(environment) do
      env[#env + 1] = key .. "=" .. value
   end

   artifacts.mkdir(repository)
   artifacts.mkdir(keyring)
   -- POSIX 0700 protects the ephemeral private key.
   assert(uv.fs_chmod(keyring, 448))

   --- Run an isolated child and retain failure details.
   -- @param command table: executable and literal command arguments.
   -- @param passed boolean: success status produced by the operation.
   -- @param input any: input selected by the caller.
   -- @return any: run an isolated child and retain failure details.
   local function expect(command, passed, input)
      local result = executor.run(command, {
         env = env,
         cwd = repository,
         stdin = input,
         timeout_ms = 30000,
      })

      count = count + 1
      assert(
         (result.state == "PASS") == passed,
         table.concat(command, " ") .. "\n" .. result.stdout .. result.stderr
      )

      return (result.stdout:gsub("[\r\n]+$", ""))
   end

   --- Read the current commit identity without relying on branch caches.
   -- @return any: the current commit identity without relying on branch caches.
   local function head()
      return expect({ "git", "rev-parse", "HEAD" }, true)
   end

   --- Exercise new work through hooks above an unsigned historical baseline.
   -- @return nil: no values.
   local passed, failure = xpcall(function()
      for _, name in ipairs({ "scripts", "tools", ".githooks" }) do
         platform.run({ "cp", "-R", name, repository .. "/" .. name })
      end

      for _, name in ipairs({ ".gitconfig", ".gitmessage", ".gitignore" }) do
         platform.run({ "cp", name, repository .. "/" .. name })
      end

      expect({
         "gpg",
         "--batch",
         "--pinentry-mode",
         "loopback",
         "--passphrase",
         "",
         "--quick-generate-key",
         "Test User <test@example.org>",
         "ed25519",
         "sign",
         "0",
      }, true)
      expect({ "git", "init", "--quiet", "--initial-branch=main" }, true)
      expect({ "git", "init", "--bare", "--initial-branch=main", remote }, true)
      for key, value in pairs({
         ["user.name"] = "Test User",
         ["user.email"] = "test@example.org",
         ["user.signingkey"] = "test@example.org",
      }) do
         expect({ "git", "config", key, value }, true)
      end

      expect({
         "git",
         "-c",
         "commit.gpgSign=false",
         "commit",
         "--allow-empty",
         "-m",
         "Legacy baseline",
      }, true)
      expect({ "git", "remote", "add", "origin", remote }, true)
      expect({ "git", "push", "--quiet", "origin", "main" }, true)
      local baseline = head()

      expect({ interpreter, "scripts/workspace/hooks.lua", "install" }, true)
      expect({ "git", "switch", "--quiet", "-c", "feature/hook-test" }, true)

      local message = "fix: handle allocation failure\n\n"
         .. "Signed-off-by: Test User <test@example.org>\n"

      artifacts.write(repository .. "/message", message)
      expect({ "git", "commit", "--allow-empty", "--file", "message" }, true)
      local signed = head()

      expect({ "git", "verify-commit", signed }, true)
      expect({ "git", "push", "--quiet", "origin", "feature/hook-test" }, true)
      expect({ "git", "tag", "-s", "v1.2.3", "-m", "fixture release" }, true)
      expect({ "git", "push", "--quiet", "origin", "v1.2.3" }, true)
      expect({ "git", "push", "--quiet", "origin", ":refs/tags/v1.2.3" }, false)

      -- A real merge is exempt from message grammar in both hooks and CI.
      expect(
         { "git", "switch", "--quiet", "-c", "feature/merge-test", baseline },
         true
      )
      expect({ "git", "commit", "--allow-empty", "--file", "message" }, true)
      expect({ "git", "commit", "--allow-empty", "--file", "message" }, true)
      expect({
         "git",
         "merge",
         "--no-ff",
         "feature/hook-test",
         "-m",
         "Merge branch feature/hook-test",
      }, true)
      local merge = head()

      expect({ interpreter, "scripts/check/commits.lua", merge }, true)
      expect({ "git", "push", "--quiet", "origin", "feature/merge-test" }, true)

      -- A merge-shaped subject with one parent receives no exemption.
      expect({
         "git",
         "-c",
         "core.hooksPath=/dev/null",
         "commit",
         "--allow-empty",
         "-m",
         "Merge branch forged",
      }, true)
      expect({ interpreter, "scripts/check/commits.lua", head() }, false)
      expect(
         { "git", "push", "--quiet", "origin", "feature/merge-test" },
         false
      )

      expect({ "git", "switch", "--quiet", "feature/hook-test" }, true)
      expect({
         "git",
         "-c",
         "core.hooksPath=/dev/null",
         "-c",
         "commit.gpgSign=false",
         "commit",
         "--allow-empty",
         "--file",
         "message",
      }, true)
      expect({ "git", "push", "--quiet", "origin", "feature/hook-test" }, false)
      artifacts.write(
         repository .. "/invalid-message",
         "fix: missing signoff\n"
      )
      expect({ interpreter, ".githooks/commit-msg", "invalid-message" }, false)

      -- The first-push baseline must be advertised and available locally.
      expect(
         { "git", "config", "libmemalloc.baselineRef", "refs/heads/absent" },
         true
      )
      local zero = string.rep("0", #signed)
      local record = "refs/heads/feature/hook-test "
         .. signed
         .. " refs/heads/feature/new-branch "
         .. zero
         .. "\n"

      expect(
         { interpreter, ".githooks/pre-push", "origin", remote },
         false,
         record
      )
      expect({ "git", "config", "--unset", "libmemalloc.baselineRef" }, true)
      expect(
         { interpreter, ".githooks/pre-push", "origin", remote },
         true,
         record
      )

      artifacts.write(repository .. "/fixture.txt", "bad whitespace  \n")
      expect({ "git", "add", "fixture.txt" }, true)
      artifacts.write(repository .. "/fixture.txt", "clean working tree\n")
      expect({ interpreter, ".githooks/pre-commit" }, false)
   end, debug.traceback)

   executor.run({ "gpgconf", "--kill", "gpg-agent" }, {
      env = env,
      timeout_ms = 5000,
   })
   platform.remove_temporary_directory(directory)
   assert(passed, failure)
   print(string.format("Signed hook integration: %d operations passed.", count))
end

return HOOK_INTEGRATION_main()

-- EOF


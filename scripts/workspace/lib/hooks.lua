-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Enforce local branch, signing, secret and commit-message rules.
-- Part of workspace automation. Git supplies the index and pre-push protocol;
-- no hook stages files, changes messages, fetches refs or publishes data.

--- Construct hooks around the canonical policy and process modules.
-- @return table: public operations constructed by this module.
local function HOOKS_loadModule()
   local platform = dofile("scripts/lib/platform.lua")
   local policy = dofile("scripts/workspace/lib/git_policy.lua")
   local messages = dofile("scripts/workspace/lib/commit_message.lua")
   local exports = {}
   local signature_marker = "\ngpgsig -----BEGIN PGP SIGNATURE-----"

   --- Read Git output and reject a failed process, including partial stdout.
   -- @param arguments table: ordered arguments for the selected operation.
   -- @return any: git output and reject a failed process, including partial
   -- stdout.
   local function HOOKS_output(arguments)
      local output = platform.command_output(arguments)

      return output and output:gsub("[\r\n]+$", "") or nil
   end

   --- Read an effective Git setting without producing missing-key noise.
   -- @param key string: record field or catalog key to select.
   -- @param boolean any: boolean supplied to this operation.
   -- @return any: an effective Git setting without producing missing-key noise.
   local function HOOKS_config(key, boolean)
      local command = { "git", "config", "--get" }

      if boolean then
         command[#command + 1] = "--bool"
      end

      command[#command + 1] = key

      return HOOKS_output(command)
   end

   --- Return a hook failure with a diagnostic suitable for Git's stderr.
   -- @param message string: diagnostic text retained by this operation.
   -- @return number: a hook failure with a diagnostic suitable for Git's
   -- stderr.
   local function HOOKS_fail(message)
      io.stderr:write("libmemalloc hook: " .. message .. "\n")

      return 1
   end

   --- Validate configuration before Git requests the OpenPGP signature.
   -- @return any, string: validate configuration before Git requests the
   -- OpenPGP signature.
   local function HOOKS_signing()
      if HOOKS_config("commit.gpgSign", true) ~= "true" then
         return false, "enable commit.gpgSign before committing"
      end

      if (HOOKS_config("gpg.format") or "openpgp") ~= "openpgp" then
         return false, "gpg.format must be openpgp"
      end

      local key = HOOKS_config("user.signingkey")
      local program = HOOKS_config("gpg.openpgp.program")
         or HOOKS_config("gpg.program")
         or "gpg"

      if not key or not platform.command_exists(program) then
         return false, "configure user.signingkey and an OpenPGP executable"
      end

      return platform.command_succeeded_silent({
         program,
         "--batch",
         "--list-secret-keys",
         "--",
         key,
      }),
         "OpenPGP secret key unavailable"
   end

   --- Check the current branch, signing setup and staged diff only.
   -- @return any: check the current branch, signing setup and staged diff only.
   local function HOOKS_preCommit()
      local branch = HOOKS_output({
         "git",
         "symbolic-ref",
         "--quiet",
         "--short",
         "HEAD",
      })

      if branch and not policy.branch(branch) then
         return HOOKS_fail("invalid Gitflow branch: " .. branch)
      end

      local signed, diagnostic = HOOKS_signing()

      if not signed then
         return HOOKS_fail(diagnostic)
      end

      if
         not platform.command_succeeded({
            "git",
            "diff",
            "--cached",
            "--check",
         })
      then
         return HOOKS_fail("staged whitespace errors")
      end

      if not platform.command_exists("gitleaks") then
         io.stderr:write(
            "libmemalloc hook: Gitleaks unavailable; "
               .. "local secret scan skipped\n"
         )

         return 0
      end

      if
         not platform.command_succeeded({
            "gitleaks",
            "git",
            "--config",
            "tools/security/git/gitleaks.toml",
            "--pre-commit",
            "--redact",
            "--staged",
            ".",
         })
      then
         return HOOKS_fail("staged secret scan failed")
      end

      return 0
   end

   --- Read a stored message or normalize Git comments from an editable one.
   -- @param arguments table: ordered arguments for the selected operation.
   -- @return any: a stored message or normalize Git comments from an editable
   -- one.
   local function HOOKS_message(arguments)
      if arguments[1] == "--commit" then
         local commit = arguments[2]

         if not commit or not commit:match("^%x+$") or #arguments ~= 2 then
            return nil
         end

         return HOOKS_output({
            "git",
            "show",
            "--no-patch",
            "--format=%B",
            commit,
            "--",
         })
      end

      if #arguments ~= 1 then
         return nil
      end

      local file = io.open(arguments[1], "rb")

      if not file then
         return nil
      end

      local message = assert(file:read("*a"))

      file:close()

      -- The installed Git configuration fixes the comment character to #.
      return messages.normalize(message)
   end

   --- Apply the merge exemption using Git metadata rather than message text.
   -- @param commit any: commit supplied to this operation.
   -- @return any: apply the merge exemption using Git metadata rather than
   -- message text.
   local function HOOKS_isMerge(commit)
      if commit then
         local parents = assert(
            HOOKS_output({
               "git",
               "show",
               "--no-patch",
               "--format=%P",
               commit,
               "--",
            }),
            "cannot read commit parents"
         )

         return messages.is_merge(parents)
      end

      return HOOKS_output({
         "git",
         "rev-parse",
         "--quiet",
         "--verify",
         "MERGE_HEAD",
      }) ~= nil
   end

   --- Apply the same structural rules as CI, then available local prose tools.
   -- @param arguments table: ordered arguments for the selected operation.
   -- @return any: apply the same structural rules as CI, then available local
   -- prose tools.
   local function HOOKS_commitMessage(arguments)
      local message = HOOKS_message(arguments)

      if not message then
         return HOOKS_fail("expected message file or --commit HEX")
      end

      local merge =
         HOOKS_isMerge(arguments[1] == "--commit" and arguments[2] or nil)
      local errors = messages.validate(message, merge)

      for _, diagnostic in ipairs(errors) do
         HOOKS_fail(diagnostic)
      end

      if #errors > 0 then
         return 1
      end

      if merge then
         return 0
      end

      local prose = dofile("scripts/workspace/lib/commit_prose.lua")

      return prose.check(message) and 0 or 1
   end

   --- Verify cryptographic signature data only from the commit header.
   -- @param commit any: commit supplied to this operation.
   -- @return any: verify cryptographic signature data only from the commit
   -- header.
   local function HOOKS_verifyCommit(commit)
      local object = HOOKS_output({ "git", "cat-file", "commit", commit })
      local header = object and object:match("^(.-)\n\n")

      return header ~= nil
         and header:find(signature_marker, 1, true) ~= nil
         and platform.command_succeeded_silent({
            "git",
            "verify-commit",
            commit,
         })
   end

   --- Verify the baseline against the destination's current advertisement.
   -- A missing local object requires an explicit fetch; hooks do not fetch.
   -- @param remote any: remote supplied to this operation.
   -- @return any: verify the baseline against the destination's current
   -- advertisement.
   local function HOOKS_baseline(remote)
      assert(type(remote) == "string" and remote ~= "", "missing push remote")

      local advertisement = assert(
         HOOKS_output({ "git", "ls-remote", "--symref", "--", remote }),
         "cannot verify destination baseline"
      )
      local configured = HOOKS_config("libmemalloc.baselineRef")
      local symbolic, objects = nil, {}

      for line in advertisement:gmatch("[^\r\n]+") do
         symbolic = line:match("^ref: (refs/heads/[^%s]+)%s+HEAD$") or symbolic
         local object, ref = line:match("^(%x+)%s+(%S+)$")

         if object then
            objects[ref] = object
         end
      end

      if next(objects) == nil then
         assert(not configured, "configured baseline absent on empty remote")

         return nil
      end

      local ref = configured or symbolic

      assert(
         ref and ref:match("^refs/heads/"),
         "set libmemalloc.baselineRef to a reviewed destination branch"
      )

      local object = assert(objects[ref], "baseline absent from destination")
      local local_object = HOOKS_output({
         "git",
         "rev-parse",
         "--verify",
         object .. "^{commit}",
      })

      assert(
         local_object == object,
         "fetch the destination baseline before pushing a new reference"
      )

      return object
   end

   --- Enumerate the update relative to an advertised destination object.
   -- @param record table: structured record supplied by the caller.
   -- @param baseline any: baseline supplied to this operation.
   -- @return any: enumerate the update relative to an advertised destination
   -- object.
   local function HOOKS_commits(record, baseline)
      local previous = not policy.zero(record.previous) and record.previous
         or baseline
      local revision = record.object

      if previous then
         if
            not HOOKS_output({ "git", "merge-base", previous, record.object })
         then
            return nil
         end

         revision = previous .. ".." .. record.object
      end

      return HOOKS_output({ "git", "rev-list", "--reverse", revision, "--" })
   end

   --- Validate a pushed ref and require signed annotated release tags.
   -- @param record table: structured record supplied by the caller.
   -- @return boolean: validate a pushed ref and require signed annotated
   -- release tags.
   local function HOOKS_checkReference(record)
      if not policy.reference(record) then
         return false
      end

      if policy.zero(record.object) then
         return true
      end

      if record.target:match("^refs/tags/") then
         local kind = HOOKS_output({ "git", "cat-file", "-t", record.object })

         if
            kind ~= "tag"
            or not platform.command_succeeded_silent({
               "git",
               "-c",
               "gpg.format=openpgp",
               "verify-tag",
               record.object,
            })
         then
            return false
         end
      end

      return HOOKS_output({
         "git",
         "rev-parse",
         "--verify",
         record.object .. "^{commit}",
      }) ~= nil
   end

   --- Validate each outgoing commit once across all updated references.
   -- @return integer: zero on success, otherwise the hook diagnostic status.
   -- @param commits string: commits supplied to this operation.
   -- @param seen table: seen supplied to this operation.
   local function hooks_checkCommits(commits, seen)
      local status = 0

      for commit in commits:gmatch("[^\r\n]+") do
         if not seen[commit] then
            seen[commit] = true
            if not HOOKS_verifyCommit(commit) then
               status = HOOKS_fail("OpenPGP verification failed: " .. commit)
            else
               local message = HOOKS_message({ "--commit", commit })

               if
                  not message
                  or #messages.validate(message, HOOKS_isMerge(commit)) > 0
               then
                  status =
                     HOOKS_fail("commit-message policy failed: " .. commit)
               end
            end
         end

         if status ~= 0 then
            break
         end
      end

      return status
   end

   --- Consume Git's pre-push records without trusting remote-tracking caches.
   -- @param arguments table: ordered arguments for the selected operation.
   -- @return any: consume Git's pre-push records without trusting
   -- remote-tracking caches.
   local function HOOKS_prePush(arguments)
      local seen = {}
      local baseline, baseline_loaded = nil, false

      --- Load the advertised baseline once, only for new references.
      -- @param record table: structured record supplied by the caller.
      -- @return any: the advertised baseline once, only for new references.
      local function hooks_loadBaseline(record)
         local status = 0

         if policy.zero(record.previous) and not baseline_loaded then
            local verified, value = pcall(
               HOOKS_baseline,
               arguments and (arguments[2] or arguments[1])
            )

            if verified then
               baseline, baseline_loaded = value, true
            else
               status = HOOKS_fail(value)
            end
         end

         return status
      end

      --- Verify one update before enumerating or validating its commits.
      -- @param line string: source line to inspect.
      -- @return any: verify one update before enumerating or validating its
      -- commits.
      local function hooks_checkUpdate(line)
         local record = policy.record(line)
         local status = 0

         if not record or not HOOKS_checkReference(record) then
            status = HOOKS_fail("invalid or immutable push reference: " .. line)
         elseif not policy.zero(record.object) then
            status = hooks_loadBaseline(record)
            if status == 0 then
               local commits = HOOKS_commits(record, baseline)

               if commits then
                  status = hooks_checkCommits(commits, seen)
               else
                  status = HOOKS_fail(
                     "cannot enumerate outgoing commits; "
                        .. "fetch the destination before retrying"
                  )
               end
            end
         end

         return status
      end

      local status = 0

      for line in io.lines() do
         status = hooks_checkUpdate(line)
         if status ~= 0 then
            break
         end
      end

      return status
   end

   exports.pre_commit = HOOKS_preCommit
   exports.commit_message = HOOKS_commitMessage
   exports.pre_push = HOOKS_prePush

   return exports
end

return HOOKS_loadModule()

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Validate Gitflow names and immutable release references.
-- Part of contributor workspace policy; contains no process or network calls.

--- Construct pure reference validators shared by both Git hooks.
-- @return table: pure reference validators shared by both Git hooks.
local function GIT_POLICY_loadModule()
   local GIT_POLICY_SHA1_HEX_LENGTH = 40
   local GIT_POLICY_SHA256_HEX_LENGTH = 64

   --- Split a dotted SemVer identifier list.
   -- @param value string: dotted identifier list.
   -- @return table|nil: identifiers or nil for an empty identifier.
   local function split_identifiers(value)
      local result = {}
      local start = 1

      while true do
         local dot = value:find(".", start, true)
         local item

         if dot then
            item = value:sub(start, dot - 1)
         else
            item = value:sub(start)
         end

         if item == "" then
            return nil
         end

         table.insert(result, item)

         if not dot then
            break
         end

         start = dot + 1
      end

      return result
   end

   --- Validate a SemVer identifier.
   -- @param value string: identifier.
   -- @return boolean: true when [0-9A-Za-z-]+.
   local function valid_semver_identifier(value)
      return value ~= "" and value:match("^[0-9A-Za-z%-]+$") ~= nil
   end

   --- Check whether a string is numeric.
   -- @param value string: candidate.
   -- @return boolean: true when all characters are digits.
   local function is_numeric(value)
      return value:match("^%d+$") ~= nil
   end

   --- Validate one normal SemVer numeric component.
   -- @param value string: MAJOR, MINOR, or PATCH.
   -- @return boolean: true when valid with no leading zeroes.
   local function valid_core_number(value)
      if not is_numeric(value) then
         return false
      end

      if #value > 1 and value:sub(1, 1) == "0" then
         return false
      end

      return true
   end

   --- Split one optional suffix without interpreting its identifier content.
   -- @return string, string|nil: prefix and suffix, preserving empty suffixes.
   -- @param value any: value supplied to this operation.
   -- @param separator any: separator supplied to this operation.
   local function git_policy_suffix(value, separator)
      local index = value:find(separator, 1, true)
      local prefix, suffix = value, nil

      if index then
         prefix, suffix = value:sub(1, index - 1), value:sub(index + 1)
      end

      return prefix, suffix
   end

   --- Validate the three required numeric version components.
   -- @return string|nil: the first core diagnostic, or nil when valid.
   -- @param version string: tool or artifact version identity.
   local function git_policy_core(version)
      local major, minor, patch = version:match("^(%d+)%.(%d+)%.(%d+)$")
      local diagnostic

      if not major then
         diagnostic = "SemVer tags must begin with MAJOR.MINOR.PATCH."
      elseif
         not valid_core_number(major)
         or not valid_core_number(minor)
         or not valid_core_number(patch)
      then
         diagnostic = "MAJOR, MINOR, and PATCH must be non-negative integers "
            .. "without leading zeroes."
      end

      return diagnostic
   end

   --- Diagnose one suffix component without changing first-error precedence.
   -- @return string|nil: the component diagnostic, or nil when valid.
   -- @param value any: value supplied to this operation.
   -- @param prerelease any: prerelease supplied to this operation.
   -- @param label string: diagnostic or evidence label for this operation.
   local function git_policy_identifier(value, prerelease, label)
      local ret = nil

      if not valid_semver_identifier(value) then
         ret = label .. " identifiers may contain only [0-9A-Za-z-]."
      elseif prerelease and is_numeric(value) then
         if #value > 1 and value:sub(1, 1) == "0" then
            ret = "numeric pre-release identifiers must not contain "
               .. "leading zeroes."
         end
      end

      ::function_output::

      return ret
   end

   --- Validate optional dotted identifiers with the prerelease numeric rule.
   -- @return string|nil: the first suffix diagnostic, or nil when valid.
   -- @param value any: input value; validation belongs to this operation’s
   -- contract.
   -- @param prerelease any: prerelease supplied to this operation.
   local function git_policy_identifiers(value, prerelease)
      local ret = nil
      local label = prerelease and "pre-release" or "build"
      local identifiers = split_identifiers(value)
      local index = 1

      if not identifiers then
         ret = "SemVer " .. label .. " identifiers cannot be empty."
      else
         while index <= #identifiers and ret == nil do
            ret = git_policy_identifier(identifiers[index], prerelease, label)
            index = index + 1
         end
      end

      ::function_output::

      return ret
   end

   --- Validate suffix syntax before numeric core and identifier rules.
   -- @param version string: tool or artifact version identity.
   -- @return any, any, any, string: validate suffix syntax before numeric core
   -- and identifier rules.
   local function git_policy_versionParts(version)
      local core_and_pre, build = git_policy_suffix(version, "+")
      local core, prerelease = git_policy_suffix(core_and_pre, "-")
      local diagnostic

      if version:sub(1, 1) == "v" then
         diagnostic =
            "SemVer tags must use the literal version without a 'v' prefix."
      elseif build and (build == "" or build:find("+", 1, true)) then
         diagnostic = "invalid SemVer build metadata."
      elseif prerelease == "" then
         diagnostic = "SemVer pre-release identifiers cannot be empty."
      end

      return core, prerelease, build, diagnostic
   end

   --- Validate a complete SemVer value without changing diagnostic precedence.
   -- @return boolean, string|nil: validity and the first diagnostic.
   -- @param version string: tool or artifact version identity.
   local function validate_semver(version)
      local core, prerelease, build, diagnostic =
         git_policy_versionParts(version)

      diagnostic = diagnostic or git_policy_core(core)
      if not diagnostic and prerelease then
         diagnostic = git_policy_identifiers(prerelease, true)
      end

      if not diagnostic and build then
         diagnostic = git_policy_identifiers(build, false)
      end

      return diagnostic == nil, diagnostic
   end

   --- Accept stable release identifiers with the repository's v prefix.
   -- @param value any: value supplied to this operation.
   -- @return any: accept stable release identifiers with the repository's v
   -- prefix.
   local function GIT_POLICY_stable(value)
      local version = value:match("^v(%d+%.%d+%.%d+)$")

      return version ~= nil and validate_semver(version)
   end

   --- Accept a maintenance major, minor series or stable release.
   -- @param value any: value supplied to this operation.
   -- @return any: accept a maintenance major, minor series or stable release.
   local function git_policy_support(value)
      local major = value:match("^v(%d+)%.x$")
      local series, minor = value:match("^v(%d+)%.(%d+)%.x$")
      local valid

      if major then
         valid = valid_core_number(major)
      elseif series then
         valid = valid_core_number(series) and valid_core_number(minor)
      else
         valid = GIT_POLICY_stable(value)
      end

      return valid
   end

   --- Accept a lowercase feature slug without repeated or trailing hyphens.
   -- @param value any: value supplied to this operation.
   -- @return boolean|nil: accept a lowercase feature slug without repeated or
   -- trailing hyphens.
   local function git_policy_feature(value)
      return value:match("^[a-z0-9][a-z0-9%-]*$") ~= nil
         and value:sub(-1) ~= "-"
         and not value:find("--", 1, true)
   end

   local branch_validators = {
      feature = git_policy_feature,
      release = GIT_POLICY_stable,
      hotfix = GIT_POLICY_stable,
      support = git_policy_support,
   }

   --- Accept Gitflow branches using the module-owned immutable dispatch table.
   -- @param name string: entry or operation name to resolve.
   -- @return any: accept Gitflow branches using the module-owned immutable
   -- dispatch table.
   local function GIT_POLICY_branch(name)
      local kind, value = name:match("^([^/]+)/([^/]+)$")
      local valid = name == "main" or name == "develop"

      if branch_validators[kind] then
         valid = branch_validators[kind](value)
      end

      return valid
   end

   --- Require a v-prefixed SemVer tag, preserving prerelease identifiers.
   -- @param name string: entry or operation name to resolve.
   -- @return any: require a v-prefixed SemVer tag, preserving prerelease
   -- identifiers.
   local function GIT_POLICY_tag(name)
      return name:sub(1, 1) == "v" and validate_semver(name:sub(2))
   end

   --- Recognize Git's absent-object sentinel without assuming SHA-1.
   -- @param value any: value supplied to this operation.
   -- @return boolean: recognize Git's absent-object sentinel without assuming
   -- SHA-1.
   local function GIT_POLICY_zero(value)
      return value:match("^0+$") ~= nil
   end

   --- Parse exactly four fields and validate object IDs before invoking Git.
   -- @param line string: source line to inspect.
   -- @return nil|table: exactly four fields and validate object IDs before
   -- invoking Git.
   local function GIT_POLICY_record(line)
      local source, object, target, previous =
         line:match("^(%S+) (%S+) (%S+) (%S+)$")

      if not source or not target:match("^refs/") then
         return nil
      end

      local supported_length = #object == GIT_POLICY_SHA1_HEX_LENGTH
         or #object == GIT_POLICY_SHA256_HEX_LENGTH

      if
         not object:match("^%x+$")
         or not previous:match("^%x+$")
         or not supported_length
         or #object ~= #previous
      then
         return nil
      end

      return {
         source = source,
         object = object,
         target = target,
         previous = previous,
      }
   end

   --- Reject invalid destinations and edits to published release tags.
   -- @param record table: structured record supplied by the caller.
   -- @return any: reject invalid destinations and edits to published release
   -- tags.
   local function GIT_POLICY_reference(record)
      local branch = record.target:match("^refs/heads/(.+)$")
      local tag = record.target:match("^refs/tags/(.+)$")

      if branch then
         return GIT_POLICY_zero(record.object) or GIT_POLICY_branch(branch)
      end

      if tag then
         if GIT_POLICY_zero(record.object) then
            return not GIT_POLICY_tag(tag)
         end

         return GIT_POLICY_tag(tag)
            and (
               GIT_POLICY_zero(record.previous)
               or record.object == record.previous
            )
      end

      return true
   end

   return {
      branch = GIT_POLICY_branch,
      tag = GIT_POLICY_tag,
      zero = GIT_POLICY_zero,
      record = GIT_POLICY_record,
      reference = GIT_POLICY_reference,
   }
end

return GIT_POLICY_loadModule()

-- EOF


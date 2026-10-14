-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Validate the mechanical rules in the libmemalloc commit-message guide.
-- Part of repository state, cache placement and change selection.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_workspace_lib_commit_message_loadModule()
   local COMMIT_SUBJECT_MAX_CHARACTERS = 70

   local exports = {}
   local types = {
      feat = true,
      fix = true,
      build = true,
      chore = true,
      ci = true,
      docs = true,
      style = true,
      refactor = true,
      perf = true,
      test = true,
      revert = true,
   }

   --- Validate the commit subject and required metadata against the repository
   -- policy.
   -- @param message string: diagnostic text retained by this operation.
   -- @param merge any: merge supplied to this operation.
   -- @return table: validate the commit subject and required metadata against
   -- the repository policy.
   local function WORKSPACE_COMMIT_MESSAGE_validate(message, merge)
      if merge then
         return {}
      end

      local errors = {}

      --- Normalize message lines and record length errors.
      -- @return table: message lines and record length errors.
      local function commit_message_collectLines()
         local lines = {}

         for line in (message:gsub("\r\n", "\n") .. "\n"):gmatch("(.-)\n") do
            lines[#lines + 1] = line

            local length = utf8.len(line)

            if not length or length > COMMIT_SUBJECT_MAX_CHARACTERS then
               errors[#errors + 1] =
                  "line exceeds 70 characters or is invalid UTF-8"
            end
         end

         return lines
      end

      local lines = commit_message_collectLines()

      local subject = lines[1] or ""
      local kind, remainder = subject:match("^([a-z]+)(.*)$")

      --- Validate the Conventional Commit type, scope and description.
      -- @return nil: no values.
      local function commit_message_checkSubject()
         if not kind or not types[kind] then
            errors[#errors + 1] = "unknown Conventional Commit type"
         else
            if remainder:sub(1, 1) == "(" then
               remainder = remainder:match("^%([^%s()]+%)(.*)$") or ""
            end

            if not remainder:match("^!?: %S.*$") then
               errors[#errors + 1] = "expected type(scope): description"
            end
         end
      end

      commit_message_checkSubject()

      if lines[2] and lines[2] ~= "" then
         errors[#errors + 1] = "expected a blank line after the subject"
      end

      -- Only the final paragraph is a trailer block; a quoted DCO in the body
      -- must not satisfy the contribution policy.
      local trimmed = message:gsub("%s+$", "")
      local footer = trimmed:match(".*\n\n(.*)$") or ""
      local signed = false

      for line in (footer .. "\n"):gmatch("(.-)\n") do
         if line:match("^Signed%-off%-by: %S.* <[^%s<>]+@[^%s<>]+>$") then
            signed = true
         end
      end

      if not signed then
         errors[#errors + 1] = "missing valid Signed-off-by trailer"
      end

      return errors
   end

   --- Strip editor comments and the scissors suffix from an unstored message.
   -- @param message string: diagnostic text retained by this operation.
   -- @return string: strip editor comments and the scissors suffix from an
   -- unstored message.
   local function COMMIT_MESSAGE_normalize(message)
      local lines = {}

      for line in (message:gsub("\r\n", "\n") .. "\n"):gmatch("(.-)\n") do
         if
            line == "# ------------------------ >8 ------------------------"
         then
            break
         end

         if line:sub(1, 1) ~= "#" then
            lines[#lines + 1] = line:gsub("%s+$", "")
         end
      end

      return table.concat(lines, "\n"):gsub("^\n+", ""):gsub("%s+$", "") .. "\n"
   end

   --- Identify merge commits from Git parent IDs, never from subject text.
   -- @param parents string: parents supplied to this operation.
   -- @return boolean: identify merge commits from Git parent IDs, never from
   -- subject text.
   local function COMMIT_MESSAGE_isMerge(parents)
      local count = 0

      for _ in parents:gmatch("%x+") do
         count = count + 1
      end

      return count > 1
   end

   exports.is_merge = COMMIT_MESSAGE_isMerge

   exports.normalize = COMMIT_MESSAGE_normalize

   exports.validate = WORKSPACE_COMMIT_MESSAGE_validate

   return exports
end

return scripts_workspace_lib_commit_message_loadModule()

-- EOF


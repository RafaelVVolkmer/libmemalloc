-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer
-- <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Generic Git helpers for Lua tooling.
-- The module is dependency-injected with scripts/lib/platform.lua.
-- Part of shared host, path and artifact primitives.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_lib_git_loadModule()
   local exports = {}

   --- Create a Git helper bound to one platform implementation.
   -- @param platform table: process helper module.
   -- @param repository string|nil: repository working tree for git -C.
   -- @return table: Git helper methods.
   local function GIT_new(platform, repository)
      assert(type(platform) == "table", "platform module is required")

      local prefix = { "git" }

      if repository and repository ~= "" then
         prefix[#prefix + 1] = "-C"
         prefix[#prefix + 1] = repository
      end

      local git = {}

      --- Capture stdout from Git.
      -- @param arguments table: Git arguments excluding the executable.
      -- @return string|nil: stdout, or nil when Git fails.
      local function GIT_output(arguments)
         local command = {}

         for _, value in ipairs(prefix) do
            command[#command + 1] = value
         end

         for _, value in ipairs(arguments) do
            command[#command + 1] = value
         end

         return platform.command_output(command)
      end

      git.output = GIT_output

      --- Resolve the repository root directory.
      -- @return string|nil: repository root, or nil on failure.
      local function GIT_root()
         local output = git.output({ "rev-parse", "--show-toplevel" })

         if not output then
            return nil
         end

         output = output:gsub("%s+$", "")
         if output == "" then
            return nil
         end

         return output
      end

      git.root = GIT_root

      --- Resolve one revision to its object identifier.
      -- @param revision string: revision expression.
      -- @return string|nil: resolved object identifier, or nil on failure.
      local function GIT_resolve(revision)
         local output = git.output({
            "rev-parse",
            "--verify",
            "--quiet",
            revision .. "^{commit}",
         })

         if not output then
            return nil
         end

         output = output:gsub("%s+$", "")
         if output == "" then
            return nil
         end

         return output
      end

      git.resolve = GIT_resolve

      --- Resolve the first parent of a revision.
      -- @param revision string: revision expression.
      -- @return string|nil: parent object identifier, or nil when unavailable.
      local function GIT_parent(revision)
         return git.resolve(revision .. "^")
      end

      git.parent = GIT_parent

      --- Collect tracked repository paths using NUL delimiters.
      -- @return table|nil: sorted paths, or nil when Git fails.
      local function GIT_trackedFiles()
         local output = git.output({ "ls-files", "-z" })

         if output == nil then
            return nil
         end

         local files = {}

         for path in output:gmatch("([^%z]+)") do
            files[#files + 1] = path
         end

         table.sort(files)

         return files
      end

      git.tracked_files = GIT_trackedFiles

      --- Include new sources and omit deletions without changing the index.
      -- @return nil|table: include new sources and omit deletions without
      -- changing the index.
      local function GIT_workingFiles()
         local inventory = git.output({
            "ls-files",
            "-z",
            "--cached",
            "--others",
            "--exclude-standard",
         })
         local deleted = git.output({ "ls-files", "-z", "--deleted" })

         if not inventory or not deleted then
            return nil
         end

         local excluded, seen, files = {}, {}, {}

         for path in deleted:gmatch("([^%z]+)") do
            excluded[path] = true
         end

         for path in inventory:gmatch("([^%z]+)") do
            if not excluded[path] and not seen[path] then
               seen[path] = true
               files[#files + 1] = path
            end
         end

         table.sort(files)

         return files
      end

      git.working_files = GIT_workingFiles

      --- Collect changed paths between two revisions using NUL delimiters.
      -- @param base string: base revision.
      -- @param head string: head revision.
      -- @return table|nil: changed paths, or nil when Git diff fails.
      local function GIT_changedFiles(base, head)
         local output = git.output({
            "diff",
            "--name-only",
            "-z",
            base,
            head,
         })

         if output == nil then
            return nil
         end

         local files = {}

         for path in output:gmatch("([^%z]+)") do
            files[#files + 1] = path
         end

         return files
      end

      git.changed_files = GIT_changedFiles

      return git
   end

   exports.new = GIT_new

   --- Check whether a revision consists only of zeroes.
   -- @param revision string: Git revision text.
   -- @return boolean: true for Git's all-zero sentinel.
   local function GIT_zeroRevision(revision)
      return revision ~= "" and revision:match("^0+$") ~= nil
   end

   exports.zero_revision = GIT_zeroRevision

   return exports
end

return scripts_lib_git_loadModule()

-- EOF


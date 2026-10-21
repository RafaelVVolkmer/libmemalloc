-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer
-- <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Classify changed repository paths for selective CI execution.
-- Full validation can be forced for trusted integration and release events.
-- Part of repository state, cache placement and change selection.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_workspace_changes_main()
   local raw_script = tostring(arg[0] or ""):gsub("\\", "/")
   local script_dir = raw_script:match("^(.*)/[^/]+$") or "scripts/workspace"
   local scripts_root = script_dir:match("^(.*)/workspace$") or "scripts"
   local repo_root = scripts_root:match("^(.*)/scripts$") or "."
   local library_root = scripts_root .. "/lib"
   local paths = dofile(library_root .. "/paths.lua")
   local platform = dofile(paths.join(library_root, "platform.lua"))
   local git_module = dofile(paths.join(library_root, "git.lua"))
   local policy = dofile(paths.join(library_root, "policy.lua"))
   local git = git_module.new(platform, repo_root)

   local categories = {
      "actions",
      "bazel",
      "c",
      "ci",
      "engineering",
      "html",
      "css",
      "javascript",
      "typescript",
      "json",
      "haskell",
      "lean",
      "lua",
      "markdown",
      "nushell",
      "powershell",
      "python",
      "security",
      "shell",
      "spelling",
      "toml",
      "yaml",
   }

   local changed = policy.new(categories)

   --- Print a fatal diagnostic and terminate.
   -- @param message string: diagnostic text.
   -- @return nil: no values.
   local function workspace_changes_fail(message)
      io.stderr:write("libmemalloc changed-areas: error: " .. message .. "\n")

      os.exit(1)
   end

   --- Parse command-line options.
   -- @return string: base revision.
   -- @return string: head revision.
   -- @return boolean: whether every category must run.
   local function workspace_changes_parseArguments()
      local base = ""
      local head = "HEAD"
      local force_all = false
      local index = 1

      while index <= #arg do
         local option = arg[index]

         if option == "--base" then
            index = index + 1
            base = arg[index]
               or workspace_changes_fail("--base requires a value.")
         elseif option == "--head" then
            index = index + 1
            head = arg[index]
               or workspace_changes_fail("--head requires a value.")
         elseif option == "--force-all" then
            index = index + 1

            local parsed = policy.parse_boolean(arg[index])

            if type(parsed) == "boolean" then
               force_all = parsed
            else
               workspace_changes_fail(
                  "expected boolean value, got '"
                     .. tostring(arg[index])
                     .. "'."
               )
            end
         else
            workspace_changes_fail(
               "unknown option '" .. tostring(option) .. "'."
            )
         end

         index = index + 1
      end

      return base, head, force_all
   end

   local impact = dofile("tools/ci/changes.lua")

   --- Match one reviewed path rule; exact names never act as Lua patterns.
   -- @param path string: normalized repository-relative source path.
   -- @param rule table: exact names and anchored patterns from the catalog.
   -- @return boolean: whether this rule contributes impact categories.
   local function workspace_changes_matches(path, rule)
      local matched = false

      for _, name in ipairs(rule.exact) do
         matched = matched or path == name
      end

      for _, pattern in ipairs(rule.patterns) do
         matched = matched or path:match(pattern) ~= nil
      end

      return matched
   end

   --- Union selected categories; the all marker expands the full policy.
   -- @param areas table: reviewed category names, never caller-owned commands.
   -- @return nil: no values.
   local function workspace_changes_mark(areas)
      for _, area in ipairs(areas) do
         if area == "all" then
            changed.mark_all()
         else
            changed.mark(area)
         end
      end
   end

   --- Classify one source by independent path rules and extension policy.
   -- @param input string: repository-relative Git path; no filesystem effects.
   -- @return nil: no values.
   local function workspace_changes_classify(input)
      local path = paths.normalize(input)
      local extension = path:match("%.([^.]+)$")

      for _, rule in ipairs(impact.rules) do
         if workspace_changes_matches(path, rule) then
            workspace_changes_mark(rule.areas)
         end
      end

      workspace_changes_mark(impact.extensions[extension] or {})
   end

   --- Write deterministic category outputs for GitHub Actions or local use.
   -- @return nil: no values.
   local function workspace_changes_emitOutputs()
      local output_path = os.getenv("GITHUB_OUTPUT")
      local handle = nil

      if output_path and output_path ~= "" then
         handle = io.open(output_path, "ab")
         if not handle then
            workspace_changes_fail("cannot open GITHUB_OUTPUT for append.")
         end
      end

      for category, value in changed.each() do
         local line = category .. "=" .. tostring(value) .. "\n"

         if handle then
            handle:write(line)
         else
            io.write(line)
         end
      end

      if handle then
         handle:close()
      end
   end

   local base, head, force_all = workspace_changes_parseArguments()

   if force_all or git_module.zero_revision(base) then
      changed.mark_all()
   else
      if base == "" then
         base = git.parent(head) or ""
      end

      --- Classify a verified revision range or conservatively select every
      -- gate.
      -- @return nil: no values.
      local function workspace_changes_classifyRange()
         if base == "" or not git.resolve(base) then
            changed.mark_all()
         else
            local files = git.changed_files(base, head)

            if type(files) ~= "table" then
               workspace_changes_fail(
                  "git diff failed for '" .. base .. ".." .. head .. "'."
               )
            else
               for _, path in ipairs(files) do
                  workspace_changes_classify(path)
               end
            end
         end
      end

      workspace_changes_classifyRange()
   end

   workspace_changes_emitOutputs()
end

return scripts_workspace_changes_main()

-- EOF


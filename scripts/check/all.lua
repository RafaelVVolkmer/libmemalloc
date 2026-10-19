-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Execute applicable local gates and retain every result, including failures.
-- Part of local and CI verification gates.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_check_all_main()
   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local git = dofile("scripts/lib/git.lua").new(artifact_io.platform, ".")

   local CHECK_TIMEOUT_SECONDS = 10 * 60
   local options = artifact_io.options(
      arg,
      { output = true, root = true, offline = true, ["schema-cache"] = true }
   )

   local output = options.output or ".cache/logs/checks"

   artifact_io.safe_path(output)
   assert(
      not artifact_io.exists(output),
      "check output must be a new directory"
   )

   artifact_io.mkdir(output)

   local inventory = assert(git.working_files(), "cannot list repository files")
   local markdown, yaml, json, toml, python = {}, {}, {}, {}, {}

   --- Add one source to the applicable language inventories.
   -- @param path string: filesystem path selected by the caller.
   -- @return nil: no values.
   local function check_all_classifySource(path)
      if path:match("%.md$") then
         markdown[#markdown + 1] = path
      end

      if path:match("%.ya?ml$") then
         yaml[#yaml + 1] = path
      end

      if path:match("%.jsonc?$") then
         json[#json + 1] = path
      end

      if path:match("%.toml$") then
         toml[#toml + 1] = path
      end

      if path:match("%.py$") then
         python[#python + 1] = path
      end
   end

   for _, path in ipairs(inventory) do
      check_all_classifySource(path)
   end

   assert(#markdown > 0, "run from a repository working tree")

   local results, failed = artifact_io.array(), 0

   --- Run one bounded local gate, record unavailable tools and preserve failed
   -- results.
   -- @param name string: entry or operation name to resolve.
   -- @param command table: executable and literal command arguments.
   -- @param files table: ordered source or artifact paths.
   -- @param seconds number|nil: timeout override for a long formal campaign.
   -- @return nil: no values.
   local function check_all_check(name, command, files, seconds)
      if files then
         for _, path in ipairs(files) do
            command[#command + 1] = path
         end
      end

      local log = output .. "/" .. name .. ".log"
      local available = artifact_io.platform.command_exists(command[1])
      local state = "UNAVAILABLE"

      if available then
         local bounded =
            { "timeout", tostring(seconds or CHECK_TIMEOUT_SECONDS) }

         for _, value in ipairs(command) do
            bounded[#bounded + 1] = value
         end

         local success = artifact_io.platform.command_succeeded(
            artifact_io.platform.join_command(bounded)
               .. " >"
               .. artifact_io.platform.shell_quote(log)
               .. " 2>&1"
         )

         state = success and "PASS" or "FAIL"
      else
         artifact_io.write(log, "Missing required tool: " .. command[1] .. "\n")
      end

      if state ~= "PASS" then
         failed = failed + 1
      end

      results[#results + 1] = {
         name = name,
         state = state,
         command = artifact_io.array(command),
         log = log,
         sha256 = artifact_io.digest(log),
      }

      print(name .. ": " .. state)

      io.flush()

      artifact_io.document(output .. "/results.json", {
         checks = results,
         failures = failed,
         scope = "repository working tree; hosted events excluded",
      })
   end

   check_all_check("tool-versions", {
      "lua",
      "scripts/workspace/doctor.lua",
      "--profile=all",
   })

   for _, script in ipairs({
      "eof",
      "install",
      "toolchain",
      "workflows",
      "doc_tools",
      "documentation",
      "sdd",
      "lua",
      "web",
      "c",
      "cmake",
      "modules",
      "doc_examples",
      "mermaid",
      "openssf",
   }) do
      check_all_check(script, { "lua", "scripts/check/" .. script .. ".lua" })
   end

   check_all_check("lean-audit", { "lua", "scripts/verification/check.lua" })
   check_all_check(
      "haskell",
      { "lua", "scripts/verification/check-haskell.lua" }
   )
   check_all_check(
      "formal-engine",
      { "lua", "scripts/verification/engine.lua" },
      nil,
      5400
   )

   check_all_check(
      "automation-tests",
      { "lua", "scripts/check/automation.lua" }
   )
   check_all_check(
      "c-documentation",
      { "lua", "scripts/check/c_documentation.lua" }
   )

   check_all_check("markdown", {
      "lua",
      "scripts/check/format.lua",
      "markdown",
      ".cache/tools/md/node_modules/.bin/markdownlint",
   }, markdown)

   check_all_check("spelling", { "lua", "scripts/check/spelling.lua" })
   check_all_check("commit-links", {
      "lua",
      "tests/automation/workspace/commit_links_test.lua",
   })

   local links = {
      "lua",
      "scripts/check/links.lua",
   }

   if options.offline then
      links[#links + 1] = "--offline"
   end

   check_all_check("links", links)

   check_all_check("actions", { "actionlint" })
   check_all_check(
      "editorconfig",
      { "ec", "-disable-indentation", "-exclude", "^LICENSE$" }
   )

   check_all_check("zizmor", {
      "zizmor",
      "--offline",
      "--config",
      "tools/security/actions/zizmor.yml",
      "--pedantic",
      "--strict-collection",
      ".github",
   })

   check_all_check(
      "yaml",
      { "yamllint", "-c", "tools/lint/code/yaml/yamllint.yml" },
      yaml
   )

   check_all_check("json", {
      "biome",
      "check",
      "--config-path=tools/lint/code/json/biome-config.json",
   }, json)

   check_all_check(
      "toml",
      { "taplo", "check", "--config", "tools/lint/code/taplo/taplo.toml" },
      toml
   )

   check_all_check(
      "toml-format",
      { "lua", "scripts/check/format.lua", "toml", "taplo" },
      toml
   )

   check_all_check("reuse", { "reuse", "lint" })

   check_all_check("gitleaks", { "lua", "scripts/check/secrets.lua" })

   check_all_check(
      "renovate",
      { "renovate-config-validator", "--strict", ".github/renovate.json5" }
   )

   --- Run Python source checks only when owned Python files exist.
   -- @return nil: no values.
   local function check_all_python()
      if #python > 0 then
         check_all_check(
            "ruff",
            { "ruff", "check", "--config", "tools/lint/code/python/ruff.toml" },
            python
         )

         check_all_check("ruff-format", {
            "lua",
            "scripts/check/format.lua",
            "python",
            "ruff",
         }, python)

         check_all_check("pyright", {
            "pyright",
            "--pythonpath",
            os.getenv("LIBMEMALLOC_QUALITY_PYTHON") or "python3",
            "--project",
            -- Use the repository profile rather than tool defaults.
            "tools/lint/code/python/pyrightconfig.json",
         }, python)

         check_all_check("bandit", { "bandit", "-q" }, python)
      end
   end

   check_all_python()

   if not options.offline then
      check_all_check("npm-audit", {
         "npm",
         "audit",
         "--prefix",
         "tools/lint/code/md",
         "--package-lock-only",
         "--ignore-scripts",
         "--omit=dev",
         "--audit-level=low",
      })
   end

   if options.root then
      check_all_check(
         "reproducibility",
         { "lua", "scripts/check/reproducible.lua", "--root=" .. options.root }
      )

      check_all_check(
         "release-evidence",
         { "lua", "scripts/check/openssf.lua", "--root=" .. options.root }
      )

      check_all_check("release-negative-tests", {
         "lua",
         "tests/automation/release/release_test.lua",
         "--root=" .. options.root,
      })
   end

   --- Verify signatures and pinned schemas for a requested release root.
   -- @return nil: no values.
   local function check_all_verifyReleaseSchemas()
      if options.root then
         check_all_check("signature-tests", {
            "lua",
            "tests/automation/release/signature_test.lua",
            "--root=" .. options.root,
         })

         local schemas = {
            "lua",
            "scripts/release/check_schemas.lua",
            "--root=" .. options.root,
         }

         if options["schema-cache"] then
            schemas[#schemas + 1] = "--cache=" .. options["schema-cache"]
         else
            assert(
               not options.offline,
               "offline SBOM validation requires --schema-cache"
            )
         end

         check_all_check("sbom-schemas", schemas)
      end
   end

   check_all_verifyReleaseSchemas()

   print(
      string.format(
         "%d checks, %d failures; report: %s/results.json",
         #results,
         failed,
         output
      )
   )

   os.exit(failed == 0 and 0 or 1)
end

return scripts_check_all_main()

-- EOF


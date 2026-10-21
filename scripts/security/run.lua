-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Execute one OpenSSF integration and retain failures and blocked
-- prerequisites.
-- Dependencies install into .cache; remote assessments use read-only authority.
-- Part of security-adapter planning, execution and evidence reports.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_security_run_main()
   local RUN_WWW_BESTPRACTICES_DEV_EN_PROJECTS_URL =
      "https://www.bestpractices.dev/en/projects/"
   local RUN_GITHUB_COM_URL = "https://github.com/"
   local RUN_RAW_GITHUBUSERCONTENT_COM_SECURITY_INSIGHTS_V_URL =
      "https://raw.githubusercontent.com/ossf/security-insights/v"

   dofile("scripts/workspace/lib/lock.lua").guard("shared")
   local release = dofile("scripts/lib/artifacts.lua")
   local change = dofile("scripts/lib/change.lua")
   local tools = dofile("scripts/toolchain/lib/lock.lua").load()
   local projects = dofile("tools/security/openssf/projects.lua")
   local identity = dofile("tools/security/openssf/identity.lua")
   local options =
      release.options(arg, { project = true, root = true, install = true })
   local name = assert(options.project, "--project is required")
   local project = assert(projects[name], "unknown OpenSSF project")
   local output = ".cache/logs/openssf/" .. name
   local cache = release.output({ "git", "rev-parse", "--show-toplevel" })
      .. "/.cache"
   local bin = cache .. "/tools/openssf/bin"
   local result =
      { project = name, state = "RUNNING", scope = "mock qualification" }

   release.mkdir(output)

   release.mkdir(bin)

   --- Execute a bounded command and preserve both output streams.
   -- @param command table: quoted arguments without shell interpolation.
   -- @param label string: report name controlled by this script.
   -- @return nil: no values.
   local function security_run_execute(command, label)
      local bounded = { "timeout", "900" }

      for _, value in ipairs(command) do
         bounded[#bounded + 1] = value
      end

      local success = release.platform.command_succeeded(
         release.platform.join_command(bounded)
            .. " >"
            .. release.platform.shell_quote(output .. "/" .. label .. ".log")
            .. " 2>&1"
      )

      assert(success, label .. " failed; inspect its retained log")
   end

   --- Download public assessment data without credentials or redirects to HTTP.
   -- @return string: path to the retained public assessment.
   local function security_run_badge()
      local destination = output .. "/best-practices.json"
      local project_id = os.getenv("BEST_PRACTICES_PROJECT_ID")

      if not project_id or project_id == "" then
         project_id = identity.badge_project
      end

      assert(project_id:match("^%d+$"), "invalid public badge project ID")

      security_run_execute({
         "curl",
         "--fail",
         "--silent",
         "--show-error",
         "--location",
         "--proto",
         "=https",
         "--proto-redir",
         "=https",
         "--max-time",
         "90",
         RUN_WWW_BESTPRACTICES_DEV_EN_PROJECTS_URL .. project_id .. ".json",
         "-o",
         destination,
      }, "fetch")
      assert(
         release.query(destination, ".repo_url")
            == RUN_GITHUB_COM_URL .. identity.repository,
         "badge repository mismatch"
      )

      return destination
   end

   local success, message = xpcall(
      --- Execute the selected security adapter and retain blocked or failed
      -- prerequisites.
      -- @return nil: no values.
      function()
         if project.mode == "blocked" then
            result.state = "BLOCKED"
            error(project.reason)
         end

         --- Install the pinned scanner into the isolated project environment.
         -- @return nil: no values.
         local function security_run_installScanner()
            if options.install and project.module then
               security_run_execute({
                  "env",
                  "GOBIN=" .. bin,
                  "go",
                  "install",
                  project.module .. "@" .. project.version,
               }, "install")
               change.record(true)
            elseif options.install and project.package then
               security_run_execute(
                  { "python3", "-m", "venv", cache .. "/tools/openssf/venv" },
                  "venv"
               )
               change.record(true)

               security_run_execute({
                  cache .. "/tools/openssf/venv/bin/pip",
                  "install",
                  "--disable-pip-version-check",
                  project.package,
               }, "install")
            end
         end

         security_run_installScanner()

         local mode = project.mode

         if mode == "badge" or mode == "baseline" then
            --- Read badge evidence and validate its declared license when
            -- applicable.
            -- @return nil: no values.
            local function security_run_assessBadge()
               local path = security_run_badge()

               result.badge_level = release.query(path, ".badge_level")
               result.baseline_percentage =
                  release.query(path, ".badge_percentage_baseline_1")
               result.reported_license = release.query(path, ".license")
               result.claim = (
                  "Assessment retrieved; this does not award "
                  .. "Gold or a baseline level."
               )

               if mode == "badge" then
                  assert(
                     result.reported_license == identity.license,
                     (
                        "public badge license disagrees with this branch; "
                        .. "maintainer review required"
                     )
                  )
               end
            end

            security_run_assessBadge()
         elseif mode == "gemara" then
            security_run_execute({
               bin .. "/cue",
               "vet",
               "-c",
               "-d",
               "#ControlCatalog",
               "github.com/gemaraproj/gemara@v" .. tools.gemara.version,
               "tools/security/openssf/controls.yml",
            }, "catalog-validation")

            result.claim = (
               "Draft local control catalog matches Gemara; no "
               .. "assessment or certification claim."
            )
         elseif mode == "insights" then
            local schema = output .. "/security-insights.cue"

            security_run_execute({
               "curl",
               "--fail",
               "--silent",
               "--show-error",
               "--location",
               "--proto",
               "=https",
               "--proto-redir",
               "=https",
               "--max-time",
               "90",
               RUN_RAW_GITHUBUSERCONTENT_COM_SECURITY_INSIGHTS_V_URL
                  .. tools.security_insights.version
                  .. "/spec/schema.cue",
               "-o",
               schema,
            }, "schema-download")
            assert(
               release.digest(schema) == tools.security_insights.sha256,
               "Security Insights schema digest mismatch"
            )

            security_run_execute({
               bin .. "/cue",
               "vet",
               "-c",
               "-d",
               "#SecurityInsights",
               schema,
               ".github/security-insights.yml",
            }, "schema-validation")

            result.claim = (
               "Draft branch metadata matches its schema; "
               .. "maintainer approval remains required."
            )
         elseif mode == "criticality" then
            security_run_execute({
               bin .. "/criticality_score",
               "-depsdev-disable",
               "-format=json",
               RUN_GITHUB_COM_URL .. identity.repository,
            }, "assessment")
         elseif mode == "osv" then
            security_run_execute({
               bin .. "/osv-scanner",
               "scan",
               "source",
               "--lockfile=tools/lint/code/md/package-lock.json",
               "--format=json",
               "--output=" .. output .. "/advisories.json",
            }, "scan")

            result.claim = (
               "OSV-backed dependency scan, including matching "
               .. "malicious-package advisories."
            )
         elseif mode == "introspection" then
            security_run_execute({
               cache .. "/tools/openssf/venv/bin/fuzz-introspector",
               "full",
               "--target-dir",
               "core",
               "--language",
               "c",
               "--module-only",
               "--out-dir",
               output .. "/report",
            }, "analysis")

            result.claim =
               "Static source introspection only; no fuzz coverage claim."
         elseif mode == "scorecard" then
            assert(
               release.exists(".cache/logs/scorecard.json"),
               "Scorecard action report missing"
            )

            release.run({
               "cp",
               ".cache/logs/scorecard.json",
               output .. "/assessment.json",
            })

            result.claim =
               "Repository assessment only; inspect individual checks."
         else
            local root =
               assert(options.root, "--root is required for artifact checks")

            release.verify(root)

            --- Merge and validate the selected project SBOM artifacts.
            -- @return nil: no values.
            local function security_run_mergeSbom()
               if mode == "sbom" then
                  security_run_execute({
                     bin .. "/bomctl",
                     "import",
                     "--alias",
                     "libmemalloc-fixture",
                     root .. "/sbom/product/release/spdx.json",
                  }, "import")

                  security_run_execute({
                     bin .. "/bomctl",
                     "export",
                     "libmemalloc-fixture",
                     "--format",
                     "cyclonedx-1.6",
                     "--output-file",
                     output .. "/converted.cyclonedx.json",
                  }, "export")

                  result.claim = (
                     "Bomctl import/export uses Protobom; review "
                     .. "conversion field preservation."
                  )
               elseif mode == "binary" then
                  security_run_execute({
                     cache .. "/tools/openssf/venv/bin/cve-bin-tool",
                     root .. "/bins",
                     "--format",
                     "json",
                     "--output-file",
                     output .. "/binary-scan.json",
                  }, "scan")
               elseif mode == "signature" then
                  security_run_execute({
                     "lua",
                     "tests/automation/release/signature_test.lua",
                     "--root=" .. root,
                  }, "signatures")

                  result.claim = (
                     "Offline disposable-key regression; production "
                     .. "keyless signing is a separate job."
                  )
               elseif mode == "provenance" then
                  security_run_execute(
                     { "lua", "scripts/check/openssf.lua", "--root=" .. root },
                     "provenance"
                  )

                  result.claim = (
                     "Mock statement consistency; no SLSA "
                     .. "build-level qualification."
                  )
               else
                  error("project has no qualified adapter")
               end
            end

            security_run_mergeSbom()
         end
      end,
      debug.traceback
   )

   if success then
      result.state = "PASS"
   elseif result.state ~= "BLOCKED" then
      result.state = "FAIL"
   end

   result.detail = success and "Command completed; inspect scope and reports."
      or tostring(message)
   release.document(output .. "/result.json", result)

   print(name .. ": " .. result.state)
   assert(success, result.detail)
   change.record(false)
end

return scripts_security_run_main()

-- EOF


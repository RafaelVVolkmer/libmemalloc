-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Map playbook tasks to existing Lua command boundaries.
-- Ansible and local users share this registry; domain commands own arguments.

--- Return task prefixes without granting arbitrary command execution.
-- @return table: task prefixes without granting arbitrary command execution.
local function PLAYBOOK_loadModule()
   local tasks = {
      ["clean"] = { "scripts/workspace/clean.lua" },
      ["quality-setup"] = { "scripts/toolchain/install/quality.lua" },
      ["setup"] = { "scripts/workspace/hooks.lua", "install" },
      ["status"] = { "scripts/workspace/hooks.lua", "status" },
      ["ansible-test"] = { "tests/automation/process/ansible_test.lua" },
      ["ansible-setup-test"] = {
         "tests/automation/workspace/ansible_setup_test.lua",
      },
      ["doctor"] = { "scripts/workspace/doctor.lua" },
      ["setup-repair"] = { "scripts/workspace/hooks.lua", "repair" },
      ["setup-uninstall"] = { "scripts/workspace/hooks.lua", "uninstall" },
      ["hooks-test"] = {
         "tests/automation/workspace/hooks_integration_test.lua",
      },
      ["tests"] = { "scripts/check/automation.lua" },
      ["docs-check"] = { "scripts/check/documentation.lua" },
      ["sdd-check"] = { "scripts/check/sdd.lua" },
      ["sdd-test"] = { "tests/automation/check/sdd_test.lua" },
      ["docs-eval"] = { "scripts/documentation/main.lua", "eval" },
      ["docs-build"] = { "scripts/documentation/main.lua", "build" },
      ["checks"] = { "scripts/check/all.lua" },
      ["lua-check"] = { "scripts/check/lua.lua" },
      ["build"] = { "scripts/build/local.lua" },
      ["build-plan"] = { "scripts/build/plan.lua" },
      ["build-run"] = { "scripts/build/run.lua" },
      ["build-report"] = { "scripts/build/report.lua" },
      ["qualification-plan"] = { "scripts/qualification/plan.lua" },
      ["qualification-run"] = { "scripts/qualification/run.lua" },
      ["qualification-report"] = { "scripts/qualification/report.lua" },
      ["analysis"] = { "scripts/analysis/run.lua" },
      ["reproducible-prepare"] = { "scripts/reproducible/prepare.lua" },
      ["reproducible-vary"] = { "scripts/reproducible/vary.lua" },
      ["release-build"] = { "scripts/release/build.lua" },
      ["release-verify"] = { "scripts/release/verify.lua" },
      ["security-plan"] = { "scripts/security/plan.lua" },
      ["security-run"] = { "scripts/security/run.lua" },
      ["security-report"] = { "scripts/security/report.lua" },
      ["spec-labels"] = {
         "scripts/github/specifications.lua",
         "--operation=sync",
      },
      ["spec-reconcile"] = {
         "scripts/github/specifications.lua",
         "--operation=enforce",
      },
      ["process-test"] = { "tests/automation/process/integration_test.lua" },
      ["process-plan"] = { "scripts/process/main.lua", "plan" },
      ["process-run"] = { "scripts/process/main.lua", "run" },
      ["process-gate"] = { "scripts/process/main.lua", "gate" },
      ["process-report"] = { "scripts/process/main.lua", "report" },
      ["process-ci"] = { "scripts/process/main.lua", "campaign" },
   }
   local metadata = {
      ["clean"] = {
         description = "Clean disposable metadata, caches and temporary files",
         dependencies = { "git" },
         effects = "workspace",
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["quality-setup"] = {
         description = "Install the locked local and CI quality tools",
         dependencies = { "git", "curl", "tar", "unzip" },
         effects = "workspace",
         timeout_seconds = 7200,
         simulation = "plan",
      },
      ["process-ci"] = {
         description = "Run controls and retain requirement evidence",
         dependencies = {
            "git",
            "jq",
            "sha256sum",
            "cmake",
            "gcc-13",
            "g++-13",
         },
         effects = "read",
         timeout_seconds = 600,
         simulation = "plan",
      },
      ["process-test"] = {
         description = "Test process controls and reject tampered evidence",
         dependencies = {
            "git",
            "jq",
            "sha256sum",
            "cmake",
            "gcc-13",
            "g++-13",
         },
         effects = "read",
         timeout_seconds = 300,
         simulation = "plan",
      },
      ["setup"] = {
         description = "Activate the reviewed Git configuration",
         effects = "workspace",
         dependencies = { "git" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["status"] = {
         description = "Inspect effective workspace Git settings",
         effects = "read",
         dependencies = { "git" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["setup-repair"] = {
         description = "Repair the owned Git include after moving a checkout",
         effects = "workspace",
         dependencies = { "git" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["setup-uninstall"] = {
         description = "Remove the owned Git include without changing identity",
         effects = "workspace",
         dependencies = { "git" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["doctor"] = {
         description = "Diagnose local automation dependencies",
         effects = "read",
         dependencies = {},
         timeout_seconds = 60,
         simulation = "plan",
      },
      ["ansible-test"] = {
         description = "Exercise native Ansible with literal task arguments",
         effects = "read",
         dependencies = { "git" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["ansible-setup-test"] = {
         description = "Test native setup, tool reuse "
            .. "and quality preparation",
         effects = "read",
         dependencies = { "git", "python3" },
         timeout_seconds = 300,
         simulation = "plan",
      },
      ["hooks-test"] = {
         description = "Test signed commits and local pushes",
         effects = "read",
         dependencies = { "git", "gpg", "gpgconf" },
         timeout_seconds = 180,
         simulation = "plan",
      },
      ["tests"] = {
         description = "Run the self-contained automation regression suites",
         effects = "read",
         dependencies = {
            "git",
            "cmake",
            "cc",
            "c++",
            "jq",
            "sha256sum",
            "node",
         },
         timeout_seconds = 3600,
         simulation = "plan",
      },
      ["sdd-check"] = {
         description = "Validate SDD IDs, scope and planned verification",
         effects = "read",
         dependencies = {},
         timeout_seconds = 60,
         simulation = "plan",
      },
      ["sdd-test"] = {
         description = "Reject broken specification plans with mutation tests",
         effects = "read",
         dependencies = {},
         timeout_seconds = 60,
         simulation = "plan",
      },
      ["docs-check"] = {
         description = "Validate documentation structure and decision fields",
         effects = "read",
         dependencies = { "git" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["docs-eval"] = {
         description = "Evaluate authored documentation and embedded examples",
         effects = "read",
         dependencies = { "git", "node", "doxygen" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["docs-build"] = {
         description = "Generate the Doxygen site",
         effects = "read",
         dependencies = { "git", "node", "doxygen" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["checks"] = {
         description = "Run the local repository verification driver",
         effects = "read",
         dependencies = { "git" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["lua-check"] = {
         description = "Validate Lua structure, format, syntax and analysis",
         effects = "read",
         dependencies = { "git" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["build"] = {
         description = "Build and compare two isolated CMake installations",
         effects = "read",
         dependencies = { "git", "cmake", "ninja", "cc", "jq", "sha256sum" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["build-plan"] = {
         description = "Plan the selected compiler campaign",
         effects = "read",
         dependencies = { "git", "cmake", "cc" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["build-run"] = {
         description = "Execute a reviewed build campaign",
         effects = "read",
         dependencies = { "git", "cmake", "cc" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["build-report"] = {
         description = "Assess collected build evidence",
         effects = "read",
         dependencies = { "git", "cmake", "cc" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["qualification-plan"] = {
         description = "Plan product qualification experiments",
         effects = "read",
         dependencies = { "git", "cmake", "cc" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["qualification-run"] = {
         description = "Execute selected qualification experiments",
         effects = "read",
         dependencies = { "git", "cmake", "cc" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["qualification-report"] = {
         description = "Assess qualification evidence",
         effects = "read",
         dependencies = { "git", "cmake", "cc" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["analysis"] = {
         description = "Run the selected independent C analysis group",
         effects = "read",
         dependencies = { "git" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["reproducible-prepare"] = {
         description = "Prepare reproducibility inputs and tools",
         effects = "read",
         dependencies = { "git" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["reproducible-vary"] = {
         description = "Run the declared build variations",
         effects = "read",
         dependencies = { "git" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["release-build"] = {
         description = "Build and inventory release artifacts",
         effects = "read",
         dependencies = { "git", "cmake", "cc" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["release-verify"] = {
         description = "Verify release identities and signatures",
         effects = "read",
         dependencies = { "git", "cmake", "cc" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["security-plan"] = {
         description = "Plan security service controls",
         effects = "read",
         dependencies = { "git" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["security-run"] = {
         description = "Execute selected security service controls",
         effects = "remote",
         dependencies = { "git" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["security-report"] = {
         description = "Assess security evidence",
         effects = "read",
         dependencies = { "git" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["spec-labels"] = {
         description = "Synchronize official specification labels on GitHub",
         effects = "remote",
         dependencies = { "git", "gh" },
         timeout_seconds = 120,
         simulation = "plan",
      },
      ["spec-reconcile"] = {
         description = "Enforce specification issue labels on GitHub",
         effects = "remote",
         dependencies = { "git", "gh" },
         timeout_seconds = 120,
         simulation = "plan",
      },
      ["process-plan"] = {
         description = "Bind source and runtime to process controls",
         effects = "read",
         dependencies = { "git", "jq", "sha256sum" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["process-run"] = {
         description = "Execute the reviewed process plan",
         effects = "read",
         dependencies = { "git", "jq", "sha256sum" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["process-gate"] = {
         description = "Assess scoped process evidence",
         effects = "read",
         dependencies = { "git", "jq", "sha256sum" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
      ["process-report"] = {
         description = "Render the process evidence assessment",
         effects = "read",
         dependencies = { "git", "jq", "sha256sum" },
         timeout_seconds = 1800,
         simulation = "plan",
      },
   }

   for _, stage in ipairs({
      "start",
      "prepare",
      "lean",
      "haskell",
      "proof",
      "tests",
      "check",
   }) do
      local name = "formal-" .. stage
      tasks[name] = { "scripts/verification/engine.lua", "--stage=" .. stage }
      metadata[name] = {
         description = "Run the "
            .. stage
            .. " stage of the formal C verification campaign",
         resource_profile = "formal",
         dependencies = {
            "git",
            "jq",
            "sha256sum",
            "cc",
            "flock",
            "systemctl",
            "systemd-run",
         },
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      }
   end

   for name, command in pairs(tasks) do
      local record = assert(metadata[name], "missing task metadata: " .. name)

      record.command = command
      tasks[name] = record
   end

   for name, record in pairs(dofile("tools/process/workflows.lua")) do
      if tasks[name] then
         assert(
            #tasks[name].command == 1
               and tasks[name].command[1] == record.command[1],
            "conflicting workflow task: " .. name
         )
      else
         tasks[name] = record
      end
   end

   --- Assign every registered workflow a bounded host resource profile.
   -- @return nil: no values.
   local function profiles()
      for name, record in pairs(tasks) do
         if not record.resource_profile then
            local heavy = name:find("build", 1, true)
               or name:find("analysis", 1, true)
               or name == "tests"
               or name == "checks"
               or name == "lua-check"
            record.resource_profile = heavy and "build" or "standard"
         end
      end
   end
   profiles()

   return tasks
end

return PLAYBOOK_loadModule()

-- EOF


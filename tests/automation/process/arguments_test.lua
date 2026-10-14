-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Challenge side-effect-free task plans with real domain argument contracts.
-- @return nil: no values.
local function ARGUMENTS_TEST_main()
   local validator = dofile("scripts/process/lib/arguments.lua")
   local tasks = dofile("tools/process/playbook.lua")
   local cases = {
      { "build", { "--profile=debug", "--jobs=4", "--coverage" }, true },
      { "build", { "--profile=invalid" }, false },
      { "build", { "--jobs=0" }, false },
      { "build", { "--coverage=false" }, false },
      { "build", { "--output=../outside" }, false },
      { "build", { "--unknown=value" }, false },
      { "build", { "--profile=debug", "--profile=release" }, false },
      { "build", { "--profile" }, false },
      { "build-plan", { "--campaign=invalid" }, false },
      { "build-plan", { "--profile=invalid" }, false },
      { "build-run", {}, false },
      { "quality-setup", { "--profile=invalid" }, false },
      { "quality-setup", { "--profile=build" }, true },
      { "analysis", { "--group=invalid" }, false },
      { "setup", {}, true },
      { "setup", { "--extra" }, false },
      { "clean", { "--scope=all", "--dry-run" }, true },
      { "clean", { "--scope=tools" }, false },
      { "clean", { "--dry-run=true" }, false },
      {
         "docs-build",
         {
            "--source=core",
            "--source=core",
            "--output=.cache/docs/literal $HOME",
         },
         true,
      },
      { "docs-build", { "--output=one", "--output=two" }, false },
      { "docs-build", { "--source" }, false },
      { "spec-reconcile", { "--issue=123" }, true },
      { "spec-reconcile", {}, false },
      { "spec-reconcile", { "--issue=0" }, false },
      { "spec-labels", { "--issue=123" }, false },
      { "toolchain-resolve", { "--field", "ansible_core.version" }, true },
      { "toolchain-resolve", { "--field", "missing.version" }, false },
      { "nix-setup", { "--anything" }, false },
   }

   for _, case in ipairs(cases) do
      local passed, message = pcall(validator.validate, tasks[case[1]], case[2])

      assert(passed == case[3], case[1] .. ": " .. tostring(message))
   end

   print(
      "Task planning: "
         .. #cases
         .. " argument contracts passed without domain execution."
   )
end

return ARGUMENTS_TEST_main()

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Side-effect-free CLI contracts for playbook planning.
-- Commands not listed accept no domain arguments; special grammars live in the
-- validator.
-- @return table: side-effect-free CLI contracts for playbook planning.
local function ARGUMENTS_CATALOG_loadModule()
   return {
      ["scripts/verification/check-haskell.lua"] = {
         ["lint"] = "flag",
         ["test"] = "flag",
      },
      ["scripts/verification/bootstrap-engine.lua"] = {
         ["haskell-only"] = "flag",
      },
      ["scripts/verification/check.lua"] = {
         ["engine"] = "flag",
         ["kernel"] = "flag",
      },
      ["scripts/verification/engine.lua"] = {
         ["stage"] = "value",
         ["run-id"] = "value",
      },
      ["scripts/check/workflows.lua"] = {},
      ["scripts/github/cache_plane.lua"] = {},
      ["scripts/analysis/run.lua"] = {
         ["group"] = "value",
      },
      ["scripts/build/local.lua"] = {
         ["arch"] = "value",
         ["assurance"] = "value",
         ["compiler"] = "value",
         ["coverage"] = "flag",
         ["jobs"] = "value",
         ["linker"] = "value",
         ["lld"] = "value",
         ["os"] = "value",
         ["output"] = "value",
         ["profile"] = "value",
         ["sanitizers"] = "value",
         ["toolchain"] = "value",
      },
      ["scripts/build/plan.lua"] = {
         ["campaign"] = "value",
         ["output"] = "value",
         ["profile"] = "value",
      },
      ["scripts/build/report.lua"] = {
         ["campaign"] = "value",
         ["input"] = "value",
         ["output"] = "value",
         ["plan"] = "value",
         ["profile"] = "value",
      },
      ["scripts/build/run.lua"] = {
         ["campaign"] = "value",
         ["no-cache"] = "flag",
         ["output"] = "value",
         ["plan"] = "value",
         ["profile"] = "value",
      },
      ["scripts/check/all.lua"] = {
         ["offline"] = "flag",
         ["output"] = "value",
         ["root"] = "value",
         ["schema-cache"] = "value",
      },
      ["scripts/check/c.lua"] = {
         ["doxygen-only"] = "flag",
      },
      ["scripts/check/c_analysis.lua"] = {
         ["campaign"] = "value",
         ["output"] = "value",
      },
      ["scripts/check/links.lua"] = {
         ["offline"] = "flag",
         ["tool"] = "value",
      },
      ["scripts/check/openssf.lua"] = {
         ["production"] = "flag",
         ["root"] = "value",
      },
      ["scripts/check/reproducible.lua"] = {
         ["root"] = "value",
      },
      ["scripts/check/spelling.lua"] = {
         ["tool"] = "value",
      },
      ["scripts/check/web.lua"] = {
         ["css"] = "boolean",
         ["html"] = "boolean",
         ["javascript"] = "boolean",
         ["typescript"] = "boolean",
      },
      ["scripts/github/specifications.lua"] = {
         ["issue"] = "value",
         ["operation"] = "value",
      },
      ["scripts/process/main.lua"] = {
         ["evidence"] = "value",
         ["output"] = "value",
         ["plan"] = "value",
         ["policy-sha256"] = "value",
         ["profile"] = "value",
         ["run-id"] = "value",
      },
      ["scripts/qualification/batch.lua"] = {
         ["batch"] = "value",
         ["input"] = "value",
         ["output"] = "value",
         ["plan"] = "value",
      },
      ["scripts/qualification/plan.lua"] = {
         ["campaign"] = "value",
         ["output"] = "value",
      },
      ["scripts/qualification/report.lua"] = {
         ["input"] = "value",
         ["output"] = "value",
         ["plan"] = "value",
      },
      ["scripts/qualification/run.lua"] = {
         ["input"] = "value",
         ["output"] = "value",
         ["plan"] = "value",
         ["task"] = "value",
      },
      ["scripts/release/build.lua"] = {
         ["mock"] = "flag",
         ["output"] = "value",
         ["version"] = "value",
      },
      ["scripts/release/check_schemas.lua"] = {
         ["cache"] = "value",
         ["root"] = "value",
      },
      ["scripts/release/conan.lua"] = {
         ["allow-mock"] = "flag",
         ["identity"] = "value",
         ["issuer"] = "value",
         ["publish"] = "flag",
         ["remote"] = "value",
         ["root"] = "value",
      },
      ["scripts/release/package.lua"] = {
         ["key"] = "value",
         ["offline"] = "flag",
         ["output"] = "value",
         ["root"] = "value",
         ["sign"] = "flag",
      },
      ["scripts/release/sign.lua"] = {
         ["key"] = "value",
         ["offline"] = "flag",
         ["output"] = "value",
         ["root"] = "value",
      },
      ["scripts/release/verify.lua"] = {
         ["identity"] = "value",
         ["issuer"] = "value",
         ["key"] = "value",
         ["offline"] = "flag",
         ["root"] = "value",
         ["trusted-root"] = "value",
         ["unsigned"] = "flag",
      },
      ["scripts/reproducible/compare.lua"] = {
         ["first"] = "value",
         ["output"] = "value",
         ["second"] = "value",
      },
      ["scripts/reproducible/normalizers.lua"] = {
         ["input"] = "value",
         ["install"] = "flag",
         ["output"] = "value",
      },
      ["scripts/reproducible/prepare.lua"] = {
         ["output"] = "value",
      },
      ["scripts/reproducible/vary.lua"] = {
         ["output"] = "value",
         ["profile"] = "value",
         ["source"] = "value",
      },
      ["scripts/security/report.lua"] = {
         ["input"] = "value",
         ["output"] = "value",
      },
      ["scripts/security/run.lua"] = {
         ["install"] = "flag",
         ["project"] = "value",
         ["root"] = "value",
      },
      ["scripts/toolchain/install/build.lua"] = {
         ["cache-only"] = "flag",
         ["profile"] = "value",
      },
      ["scripts/toolchain/install/c_analysis.lua"] = {
         ["group"] = "value",
      },
      ["scripts/toolchain/install/c_scanners.lua"] = {
         ["cppcheck"] = "value",
         ["flawfinder"] = "value",
      },
      ["scripts/toolchain/install/quality.lua"] = {
         ["profile"] = "value",
      },
      ["scripts/toolchain/python.lua"] = {
         ["directory"] = "value",
         ["groups"] = "value",
         ["reinstall"] = "flag",
      },
      ["scripts/toolchain/sync.lua"] = {
         ["check"] = "flag",
      },
      ["scripts/workspace/clean.lua"] = {
         ["dry-run"] = "flag",
         ["scope"] = "value",
      },
      ["scripts/workspace/doctor.lua"] = {
         ["profile"] = "value",
      },
      ["tests/automation/documentation/driver_test.lua"] = {
         ["eval-only"] = "flag",
      },
      ["tests/automation/release/release_test.lua"] = {
         ["root"] = "value",
      },
      ["tests/automation/release/signature_test.lua"] = {
         ["root"] = "value",
      },
      ["tests/automation/reproducible/comparison_test.lua"] = {
         ["input"] = "value",
      },
   }
end

return ARGUMENTS_CATALOG_loadModule()

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Map native manifests and Action repositories to their central identities.
-- @return table: map native manifests and Action repositories to their central
-- identities.
local function MANIFESTS_loadModule()
   return {
      templates = {
         ["verification/theorems/lean-toolchain"] = "lean-toolchain.in",
         ["tools/python/pyproject.toml"] = "pyproject.toml.in",
         ["tools/nix/flake.nix"] = "flake.nix.in",
         ["tools/lint/code/quality/package.json"] = "quality.json.in",
         ["tools/lint/code/md/package.json"] = "md.json.in",
         ["tools/lint/code/web/package.json"] = "web.json.in",
      },
      actions = {
         ["actions/cache"] = "cache_action",
         ["actions/checkout"] = "checkout_action",
         ["actions/deploy-pages"] = "deploy_pages_action",
         ["actions/download-artifact"] = "download_artifact_action",
         ["actions/setup-node"] = "setup_node_action",
         ["actions/upload-artifact"] = "upload_artifact_action",
         ["actions/upload-pages-artifact"] = "upload_pages_artifact_action",
         ["github/codeql-action"] = "codeql_action",
         ["ossf/scorecard-action"] = "scorecard_action",
         ["renovatebot/github-action"] = "renovate_action",
         ["streetsidesoftware/cspell-action"] = "cspell_action",
      },
   }
end

return MANIFESTS_loadModule()

-- EOF


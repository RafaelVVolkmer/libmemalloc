-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Each requested project has an explicit execution or qualification boundary.
-- BLOCKED entries fail their Actions job; they never count as scanner success.

--- Construct this module within its own initialization scope.
-- @return table: this module within its own initialization scope.
local function tools_security_openssf_projects_loadModule()
   local tools = dofile("scripts/toolchain/lib/lock.lua").load()

   return {
      ["best-practices"] = { mode = "badge" },
      ["osps-baseline"] = { mode = "baseline" },
      bomctl = {
         mode = "sbom",
         module = "github.com/bomctl/bomctl",
         version = "v" .. tools.bomctl.version,
      },
      protobom = {
         mode = "sbom",
         module = "github.com/bomctl/bomctl",
         version = "v" .. tools.bomctl.version,
      },
      ["criticality-score"] = {
         mode = "criticality",
         module = "github.com/ossf/criticality_score/v2/cmd/criticality_score",
         version = "v" .. tools.criticality_score.version,
      },
      ["cve-binary-tool"] = {
         mode = "binary",
         package = "cve-bin-tool==" .. tools.cve_binary_tool.version,
      },
      ["fuzz-introspector"] = {
         mode = "introspection",
         package = "git+https://github.com/ossf/fuzz-introspector.git@"
            .. tools.fuzz_introspector.revision
            .. "#subdirectory=src",
      },
      ["malicious-packages"] = {
         mode = "osv",
         module = "github.com/google/osv-scanner/v2/cmd/osv-scanner",
         version = "v" .. tools.osv_scanner.version,
      },
      ["osv-schema"] = {
         mode = "osv",
         module = "github.com/google/osv-scanner/v2/cmd/osv-scanner",
         version = "v" .. tools.osv_scanner.version,
      },
      scorecard = { mode = "scorecard" },
      sigstore = { mode = "signature" },
      slsa = { mode = "provenance" },
      ["security-insights"] = {
         mode = "insights",
         module = "cuelang.org/go/cmd/cue",
         version = "v" .. tools.cue.version,
      },
      gemara = {
         mode = "gemara",
         module = "cuelang.org/go/cmd/cue",
         version = "v" .. tools.cue.version,
      },
      gittuf = {
         mode = "blocked",
         reason = (
            "Initialize maintainer trust roots and a signed "
            .. "reference policy before source verification."
         ),
      },
      guac = {
         mode = "blocked",
         reason = (
            "Provision an authenticated GUAC endpoint and "
            .. "approve ingestion of release evidence."
         ),
      },
      ["package-analysis"] = {
         mode = "blocked",
         reason = (
            "Provision a disposable package-execution sandbox "
            .. "isolated from signing jobs and credentials."
         ),
      },
      openvex = {
         mode = "blocked",
         reason = (
            "Approve product-specific vulnerability statements;"
            .. " do not invent not_affected claims."
         ),
      },
      ["repository-service-tuf"] = {
         mode = "blocked",
         reason = (
            "Provision RSTUF, establish offline root custody, "
            .. "and approve online signing identities."
         ),
      },
      sbomit = {
         mode = "blocked",
         reason = (
            "Qualify build-time collectors and an in-toto "
            .. "verification policy before issuing SBOMit "
            .. "evidence."
         ),
      },
   }
end

return tools_security_openssf_projects_loadModule()

-- EOF


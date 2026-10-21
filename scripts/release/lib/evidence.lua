-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Build and validate SBOM, provenance and release-evidence relationships.
-- Part of release construction, verification and artifact identity.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_release_lib_evidence_loadModule()
   local EVIDENCE_LIBMEMALLOC_INVALID_SBOM_URL =
      "https://libmemalloc.invalid/sbom/"
   local EVIDENCE_IN_TOTO_IO_STATEMENT_V1_URL =
      "https://in-toto.io/Statement/v1"
   local EVIDENCE_SLSA_DEV_PROVENANCE_V1_URL = "https://slsa.dev/provenance/v1"
   local EVIDENCE_GITHUB_COM_RAFAELVVOLKMER_LIBMEMALLOC_URL =
      "https://github.com/RafaelVVolkmer/libmemalloc/"

   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local exports = {}

   --- Construct the scoped dependency inventory bound to the release identity
   -- and
   -- files.
   -- @param root string: root directory for this operation.
   -- @param scope string: scope supplied to this operation.
   -- @param version string: tool or artifact version identity.
   -- @param build_digest any: build digest supplied to this operation.
   -- @param records table: ordered records to inspect.
   -- @param timestamp any: timestamp supplied to this operation.
   -- @return nil: no values.
   local function RELEASE_EVIDENCE_sbom(
      root,
      scope,
      version,
      build_digest,
      records,
      timestamp
   )
      local components, files, relations =
         artifact_io.array(), artifact_io.array(), artifact_io.array()
      local dependencies = artifact_io.array()

      for index, record in ipairs(records) do
         local id = "SPDXRef-File-" .. index
         local ref = "file:" .. record.path

         components[#components + 1] = {
            type = "file",
            name = record.path,
            ["bom-ref"] = ref,
            hashes = artifact_io.array({
               { alg = "SHA-256", content = record.sha256 },
            }),
         }

         dependencies[#dependencies + 1] = ref
         files[#files + 1] = {
            SPDXID = id,
            fileName = "./" .. record.path,
            checksums = artifact_io.array({
               { algorithm = "SHA256", checksumValue = record.sha256 },
            }),
            licenseConcluded = "NOASSERTION",
            copyrightText = "NOASSERTION",
         }

         relations[#relations + 1] = {
            spdxElementId = "SPDXRef-Package",
            relationshipType = "CONTAINS",
            relatedSpdxElement = id,
         }
      end

      relations[#relations + 1] = {
         spdxElementId = "SPDXRef-DOCUMENT",
         relationshipType = "DESCRIBES",
         relatedSpdxElement = "SPDXRef-Package",
      }

      local destination = root .. "/sbom/" .. scope

      artifact_io.document(destination .. "/cyclonedx.json", {
         bomFormat = "CycloneDX",
         specVersion = "1.6",
         version = 1,
         metadata = {
            timestamp = timestamp,
            component = {
               type = "library",
               name = "libmemalloc-mock",
               version = version,
               ["bom-ref"] = "product:" .. scope,
            },
         },
         components = components,
         dependencies = artifact_io.array({
            { ref = "product:" .. scope, dependsOn = dependencies },
         }),
      })

      artifact_io.document(destination .. "/spdx.json", {
         spdxVersion = "SPDX-2.3",
         dataLicense = "CC0-1.0",
         SPDXID = "SPDXRef-DOCUMENT",
         name = "libmemalloc-mock-" .. scope:gsub("/", "-"),
         documentNamespace = EVIDENCE_LIBMEMALLOC_INVALID_SBOM_URL
            .. build_digest
            .. "/"
            .. scope,
         creationInfo = {
            created = timestamp,
            creators = artifact_io.array({ "Tool: libmemalloc-lua-release" }),
         },
         packages = artifact_io.array({
            {
               SPDXID = "SPDXRef-Package",
               name = "libmemalloc-mock",
               versionInfo = version,
               downloadLocation = "NOASSERTION",
               filesAnalyzed = false,
               licenseConcluded = "NOASSERTION",
               licenseDeclared = "NOASSERTION",
               copyrightText = "NOASSERTION",
            },
         }),
         files = files,
         relationships = relations,
      })
   end

   exports.sbom = RELEASE_EVIDENCE_sbom

   --- Describe the recorded build inputs, execution and outputs for one release
   -- variant.
   -- @param root string: root directory for this operation.
   -- @param variant any: variant supplied to this operation.
   -- @param records table: ordered records to inspect.
   -- @param inputs any: inputs supplied to this operation.
   -- @param version string: tool or artifact version identity.
   -- @param execution any: execution supplied to this operation.
   -- @return nil: no values.
   local function RELEASE_EVIDENCE_provenance(
      root,
      variant,
      records,
      inputs,
      version,
      execution
   )
      local subjects, materials = artifact_io.array(), artifact_io.array()

      for _, record in ipairs(records) do
         subjects[#subjects + 1] =
            { name = record.path, digest = { sha256 = record.sha256 } }
      end

      for _, record in ipairs(inputs) do
         materials[#materials + 1] = {
            uri = "file:" .. record.path,
            digest = { sha256 = record.sha256 },
         }
      end

      artifact_io.document(
         root .. "/attestations/slsa/" .. variant .. "/provenance.intoto.json",
         {
            _type = EVIDENCE_IN_TOTO_IO_STATEMENT_V1_URL,
            subject = subjects,
            predicateType = EVIDENCE_SLSA_DEV_PROVENANCE_V1_URL,
            predicate = {
               buildDefinition = {
                  buildType = (
                     EVIDENCE_GITHUB_COM_RAFAELVVOLKMER_LIBMEMALLOC_URL
                     .. "build/mock-linux/v1"
                  ),
                  externalParameters = {
                     version = version,
                     variant = variant,
                     mock = true,
                  },
                  internalParameters = {},
                  resolvedDependencies = materials,
               },
               runDetails = {
                  builder = {
                     id = (
                        EVIDENCE_GITHUB_COM_RAFAELVVOLKMER_LIBMEMALLOC_URL
                        .. "local-mock-builder"
                     ),
                  },
                  metadata = { invocationId = execution },
               },
            },
         }
      )
   end

   exports.provenance = RELEASE_EVIDENCE_provenance

   --- Require a report to cover each expected subject exactly once.
   -- @param root string: candidate directory.
   -- @param report string: report path.
   -- @param expression string: jq projection to path and SHA-256 TSV rows.
   -- @param expected table: required paths mapped to their payload digests.
   -- @return nil: raises on duplicate, missing, foreign or changed subjects.
   local function evidence_subjects(root, report, expression, expected)
      local seen = {}
      for row in artifact_io.query(report, expression):gmatch("[^\n]+") do
         local path, sha = row:match("^([^\t]+)\t([a-f0-9]+)$")
         artifact_io.safe_path(assert(path, "missing evidence path"))
         assert(not seen[path], "duplicate evidence subject: " .. path)
         assert(expected[path] == sha, "unexpected evidence subject: " .. path)
         assert(
            artifact_io.digest(root .. "/" .. path) == sha,
            "evidence subject mismatch: " .. path
         )
         seen[path] = true
      end
      for path in pairs(expected) do
         assert(seen[path], "missing evidence subject: " .. path)
      end
   end

   --- Bind the product inventory to the fixed mock build profile and variants.
   -- @param root string: candidate directory.
   -- @return table, string: per-variant subject maps and canonical basename.
   local function evidence_products(root)
      local manifest = artifact_io.input_manifest(root)
      local digest = artifact_io.digest(manifest)
      assert(
         artifact_io.query(root .. "/identity/build-id.json", ".sha256")
            == digest,
         "build input mismatch"
      )
      artifact_io.query(
         manifest,
         ".mock == true and " .. '(.variants | sort == ["debug", "release"])'
      )
      local version =
         artifact_io.semver(artifact_io.query(manifest, ".version"))
      local basename = "libmemalloc-" .. version .. "-" .. digest:sub(1, 16)
      local variants, all = {}, {}
      local suffixes = { ".a", ".so", ".map", "-static", "-shared" }
      for _, variant in ipairs({ "release", "debug" }) do
         local expected = {}
         for _, suffix in ipairs(suffixes) do
            local path = "bins/" .. variant .. "/" .. basename .. suffix
            expected[path] = artifact_io.digest(root .. "/" .. path)
            all[path] = expected[path]
         end
         variants[variant] = expected
      end
      local inventory = root .. "/identity/artifacts.json"
      artifact_io.query(inventory, ".mock == true")
      evidence_subjects(
         root,
         inventory,
         ".artifacts[] | [.path, .sha256] | @tsv",
         all
      )
      for _, path in ipairs(artifact_io.files(root)) do
         assert(
            not path:match("^bins/") or all[path],
            "unregistered product: " .. path
         )
      end
      variants.all = all
      return variants, basename
   end

   --- Validate complete byte-comparison coverage of the product inventory.
   -- @param root string: candidate directory.
   -- @return boolean: true only after all ten distinct products match.
   local function RELEASE_EVIDENCE_reproducible(root)
      local products = evidence_products(root)
      local report = root .. "/attestations/reproducibility.json"
      artifact_io.query(
         report,
         ".mock == true and (.comparisons | "
            .. 'all(.[]; .status == "PASS" and .first == .second))'
      )
      evidence_subjects(
         root,
         report,
         ".comparisons[] | [.path, .first] | @tsv",
         products.all
      )
      return true
   end

   exports.reproducible = RELEASE_EVIDENCE_reproducible

   --- Check suite identities, variant subjects and retained execution logs.
   -- @param root string: candidate directory.
   -- @param variant string: release or debug.
   -- @param basename string: canonical product basename.
   -- @return nil: raises on incomplete or incorrectly bound test evidence.
   local function evidence_tests(root, variant, basename)
      local report = root .. "/test_logs/" .. variant .. "/index.json"
      artifact_io.query(
         report,
         ".mock == true and (.tests | length == 3 "
            .. 'and all(.[]; .status == "PASS") and '
            .. "(map(.suite) | sort == "
            .. '["reproducibility", "shared-smoke", "static-smoke"]))'
      )
      local execution = artifact_io.query(report, ".execution")
      artifact_io.safe_path(execution)
      assert(not execution:find("/", 1, true), "invalid test execution")
      for suite, suffix in pairs({
         ["static-smoke"] = "-static",
         ["shared-smoke"] = "-shared",
         reproducibility = ".a",
      }) do
         local select = ".tests[] | select(.suite == "
            .. artifact_io.json(suite)
            .. ")"
         local path = "bins/" .. variant .. "/" .. basename .. suffix
         evidence_subjects(
            root,
            report,
            select .. " | [.subject, .sha256] | @tsv",
            { [path] = artifact_io.digest(root .. "/" .. path) }
         )
         if suite == "reproducibility" then
            artifact_io.query(
               report,
               select .. ' | .comparison == "attestations/reproducibility.json"'
            )
         else
            local log = "test_logs/"
               .. variant
               .. "/"
               .. suite
               .. "/"
               .. execution
               .. "/stdout.log"
            artifact_io.query(
               report,
               select
                  .. " | .exit_code == 0 and "
                  .. '(.timeout_seconds | type == "number" and . > 0)'
            )
            evidence_subjects(
               root,
               report,
               select .. " | [.log, .log_sha256] | @tsv",
               { [log] = artifact_io.digest(root .. "/" .. log) }
            )
         end
      end
   end

   --- Reject incomplete product, provenance, SBOM and test inventories.
   -- @param root string: candidate directory.
   -- @return boolean: true only after every required relationship is checked.
   local function RELEASE_EVIDENCE_validate(root)
      local products, basename = evidence_products(root)
      RELEASE_EVIDENCE_reproducible(root)
      for _, variant in ipairs({ "release", "debug" }) do
         local directory = root .. "/sbom/product/" .. variant
         local cdx, spdx =
            directory .. "/cyclonedx.json", directory .. "/spdx.json"
         artifact_io.query(
            cdx,
            '.bomFormat == "CycloneDX" and '
               .. '.specVersion == "1.6" and all(.components[]; '
               .. '.hashes[0].alg == "SHA-256")'
         )
         artifact_io.query(
            spdx,
            '.spdxVersion == "SPDX-2.3" and '
               .. '.dataLicense == "CC0-1.0" and all(.files[]; '
               .. '.checksums[0].algorithm == "SHA256")'
         )
         evidence_subjects(
            root,
            cdx,
            ".components[] | [.name, .hashes[0].content] | @tsv",
            products[variant]
         )
         evidence_subjects(
            root,
            spdx,
            '.files[] | [(.fileName | ltrimstr("./")), '
               .. ".checksums[0].checksumValue] | @tsv",
            products[variant]
         )
         local provenance = root
            .. "/attestations/slsa/"
            .. variant
            .. "/provenance.intoto.json"
         artifact_io.query(
            provenance,
            "._type == "
               .. artifact_io.json(EVIDENCE_IN_TOTO_IO_STATEMENT_V1_URL)
               .. " and .predicateType == "
               .. artifact_io.json(EVIDENCE_SLSA_DEV_PROVENANCE_V1_URL)
               .. " and .predicate.buildDefinition.externalParameters"
               .. ".variant == "
               .. artifact_io.json(variant)
         )
         evidence_subjects(
            root,
            provenance,
            ".subject[] | [.name, .digest.sha256] | @tsv",
            products[variant]
         )
         evidence_tests(root, variant, basename)
      end
      return true
   end

   exports.validate = RELEASE_EVIDENCE_validate

   return exports
end

return scripts_release_lib_evidence_loadModule()

-- EOF


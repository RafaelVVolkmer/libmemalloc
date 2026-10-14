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

   --- Reject release evidence whose subjects, inventories or required
   -- observations
   -- disagree.
   -- @param root string: root directory for this operation.
   -- @return boolean: reject release evidence whose subjects, inventories or
   -- required observations disagree.
   local function RELEASE_EVIDENCE_validate(root)
      local identity = root .. "/identity/build-id.json"
      local digest = artifact_io.query(identity, ".sha256")

      for _, variant in ipairs({ "release", "debug" }) do
         local directory = root .. "/sbom/product/" .. variant

         artifact_io.query(
            directory .. "/cyclonedx.json",
            (
               '.bomFormat == "CycloneDX" and .specVersion == "1.'
               .. '6" and (.components | length >= 4)'
            )
         )

         artifact_io.query(
            directory .. "/spdx.json",
            (
               '.spdxVersion == "SPDX-2.3" and .dataLicense == '
               .. '"CC0-1.0" and (.files | length >= 4)'
            )
         )

         for _, format in ipairs({ "cyclonedx", "spdx" }) do
            local expression = format == "cyclonedx"
                  and ".components[] | [.name, .hashes[0].content] | @tsv"
               or (
                  '.files[] | [(.fileName | ltrimstr("./")), .'
                  .. "checksums[0].checksumValue] | @tsv"
               )

            for row in
               artifact_io
                  .query(directory .. "/" .. format .. ".json", expression)
                  :gmatch("[^\n]+")
            do
               local path, sha = row:match("^([^\t]+)\t([a-f0-9]+)$")

               artifact_io.safe_path(assert(path, "missing SBOM path"))
               assert(
                  artifact_io.digest(root .. "/" .. path) == sha,
                  "SBOM subject mismatch"
               )
            end
         end

         local provenance = root
            .. "/attestations/slsa/"
            .. variant
            .. "/provenance.intoto.json"

         artifact_io.query(
            provenance,
            (
               "._type == "
               .. artifact_io.json(EVIDENCE_IN_TOTO_IO_STATEMENT_V1_URL)
               .. " and .predicateType == "
               .. artifact_io.json(EVIDENCE_SLSA_DEV_PROVENANCE_V1_URL)
               .. " and (.subject | length >= 4)"
            )
         )

         for row in
            artifact_io
               .query(provenance, ".subject[] | [.name, .digest.sha256] | @tsv")
               :gmatch("[^\n]+")
         do
            local path, sha = row:match("^([^\t]+)\t([a-f0-9]+)$")

            artifact_io.safe_path(assert(path, "missing provenance path"))
            assert(
               artifact_io.digest(root .. "/" .. path) == sha,
               "provenance subject mismatch"
            )
         end

         local logs = root .. "/test_logs/" .. variant .. "/index.json"

         artifact_io.query(
            logs,
            (
               ".mock == true and (.tests | length == 3 and all(."
               .. '[]; .status == "PASS"))'
            )
         )

         for row in
            artifact_io
               .query(logs, ".tests[] | [.subject, .sha256] | @tsv")
               :gmatch("[^\n]+")
         do
            local path, sha = row:match("^([^\t]+)\t([a-f0-9]+)$")

            artifact_io.safe_path(assert(path, "missing test path"))
            assert(
               artifact_io.digest(root .. "/" .. path) == sha,
               "test subject mismatch"
            )
         end
      end

      assert(
         digest == artifact_io.digest(artifact_io.input_manifest(root)),
         "build input mismatch"
      )

      return true
   end

   exports.validate = RELEASE_EVIDENCE_validate

   return exports
end

return scripts_release_lib_evidence_loadModule()

-- EOF


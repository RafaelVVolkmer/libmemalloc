-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Validate complete SBOM schemas after checking their trusted digests.
-- Part of release construction, verification and artifact identity.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_release_check_schemas_main()
   local CHECK_SCHEMAS_RAW_GITHUBUSERCONTENT_COM_CYCLONEDX_URL =
      "https://raw.githubusercontent.com/CycloneDX/"
   local CHECK_SCHEMAS_RAW_GITHUBUSERCONTENT_COM_SPDX_SPDX_SPEC_URL =
      "https://raw.githubusercontent.com/spdx/spdx-spec/"

   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local options = artifact_io.options(arg, { root = true, cache = true })
   local root = assert(options.root, "--root is required")

   artifact_io.verify(root)

   local lock = dofile("scripts/toolchain/lib/lock.lua").parse(
      artifact_io.read("tools/toolchain/lock.toml")
   )

   local temporary = options.cache or artifact_io.platform.temporary_directory()
   local schemas = {
      cyclonedx = {
         lock = lock.cyclonedx_schema,
         url = (
            CHECK_SCHEMAS_RAW_GITHUBUSERCONTENT_COM_CYCLONEDX_URL
            .. "specification/1.6/schema/bom-1.6.schema.json"
         ),
      },
      spdx = {
         lock = lock.spdx_schema,
         url = (
            CHECK_SCHEMAS_RAW_GITHUBUSERCONTENT_COM_SPDX_SPDX_SPEC_URL
            .. "v2.3/schemas/spdx-schema.json"
         ),
      },
   }

   for name, schema in pairs(schemas) do
      local path = temporary .. "/" .. name .. ".schema.json"

      if not options.cache then
         artifact_io.run({
            "curl",
            "--fail",
            "--silent",
            "--show-error",
            "--location",
            "--max-time",
            "60",
            "--proto",
            "=https",
            "--proto-redir",
            "=https",
            schema.url,
            "--output",
            path,
         })
      end

      assert(
         artifact_io.digest(path) == schema.lock.sha256,
         "untrusted SBOM schema"
      )

      local command = { "check-jsonschema", "--schemafile", path }

      for _, document in ipairs(artifact_io.files(root .. "/sbom")) do
         if document:match("/" .. name .. "%.json$") then
            command[#command + 1] = root .. "/sbom/" .. document
         end
      end

      assert(#command > 3, "missing SBOM documents")

      artifact_io.run(command)
   end

   if not options.cache then
      artifact_io.platform.remove_temporary_directory(temporary)
   end

   print("CycloneDX and SPDX documents passed their pinned upstream schemas.")
end

return scripts_release_check_schemas_main()

-- EOF


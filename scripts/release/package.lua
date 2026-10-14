-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Create the mock distribution archive from a verified release tree.
-- Part of release construction, verification and artifact identity.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_release_package_main()
   local PACKAGE_INDEX_ID_HEX_LENGTH = 16

   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local options = artifact_io.options(
      arg,
      { root = true, output = true, sign = true, key = true, offline = true }
   )

   local root = assert(options.root, "--root is required")
   local output = options.output or "release/_packages"

   artifact_io.safe_path(output)

   artifact_io.verify(root)

   local identity =
      artifact_io.query(root .. "/identity/build-id.json", ".short")

   assert(identity:match("^[a-f0-9]+$"), "invalid build identity")

   local index_digest =
      artifact_io.digest(root .. "/integrity/release-index.json")
   local archive = output
      .. "/libmemalloc-mock-"
      .. identity
      .. "-"
      .. index_digest:sub(1, PACKAGE_INDEX_ID_HEX_LENGTH)
      .. ".tar.gz"

   assert(not artifact_io.exists(archive), "archive already exists")

   artifact_io.mkdir(output)

   local epoch =
      artifact_io.query(artifact_io.input_manifest(root), ".source_date_epoch")

   assert(epoch:match("^%d+$"), "invalid epoch")

   local command = artifact_io.platform.join_command({
      "tar",
      "--sort=name",
      "--format=gnu",
      "--mtime=@" .. epoch,
      "--owner=0",
      "--group=0",
      "--numeric-owner",
      "--mode=u+rwX,go+rX,go-w",
      "-C",
      root,
      "-cf",
      "-",
      ".",
   })

   command = "set -o pipefail; "
      .. command
      .. " | gzip -n >"
      .. artifact_io.platform.shell_quote(archive)
   artifact_io.run({ "bash", "-c", command })

   artifact_io.document(archive .. ".json", {
      archive = archive:match("([^/]+)$"),
      sha256 = artifact_io.digest(archive),
      release_index_sha256 = index_digest,
      mock = true,
   })
   if options.sign then
      if options.offline then
         assert(
            options.key
               and artifact_io.query(
                     root .. "/identity/build-id.json",
                     ".mock"
                  )
                  == "true",
            "offline signing requires a mock and explicit test key"
         )
      end

      for _, path in ipairs({ archive, archive .. ".json" }) do
         local signing = {
            "cosign",
            "sign-blob",
            "--yes",
            "--bundle",
            path .. ".sigstore.json",
         }

         if options.key then
            signing[#signing + 1] = "--key"
            signing[#signing + 1] = options.key
         end

         if options.offline then
            signing[#signing + 1] = "--tlog-upload=false"
            signing[#signing + 1] = "--use-signing-config=false"
         end

         signing[#signing + 1] = path
         artifact_io.run(signing)

         artifact_io.format_json(path .. ".sigstore.json")
      end
   end

   print(archive)
end

return scripts_release_package_main()

-- EOF


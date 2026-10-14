-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Seal a new signed copy; leave the unsigned candidate immutable.
-- Part of release construction, verification and artifact identity.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_release_sign_main()
   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local options = artifact_io.options(
      arg,
      { root = true, output = true, key = true, offline = true }
   )
   local root = assert(options.root, "--root is required")
   local output = assert(options.output, "--output is required")

   artifact_io.safe_path(output)
   assert(not artifact_io.exists(output), "signed destination already exists")

   artifact_io.verify(root)

   dofile("scripts/release/lib/evidence.lua").validate(root)
   if options.offline then
      assert(options.key, "offline signing requires an explicit test key")

      local mock = artifact_io.query(root .. "/identity/build-id.json", ".mock")

      assert(mock == "true", "offline signing is limited to mocks")
   end

   artifact_io.mkdir(output:match("^(.*)/[^/]+$") or ".")

   artifact_io.run({ "cp", "-R", "--", root, output })

   -- Actions directory artifacts normalize permissions; restore declared
   -- consumers.
   for _, path in ipairs(artifact_io.files(output)) do
      if path:match("^bins/.*%-static$") or path:match("^bins/.*%-shared$") then
         artifact_io.run({ "chmod", "755", output .. "/" .. path })
      end
   end

   --- Create a signature bundle for the exact artifact path under the selected
   -- signing policy.
   -- @param path string: filesystem path selected by the caller.
   -- @param bundle string: bundle supplied to this operation.
   -- @return nil: no values.
   local function release_sign_sign(path, bundle)
      artifact_io.mkdir(bundle:match("^(.*)/[^/]+$"))

      local command = { "cosign", "sign-blob", "--yes", "--bundle", bundle }

      if options.key then
         command[#command + 1] = "--key"
         command[#command + 1] = options.key
      end

      if options.offline then
         command[#command + 1] = "--tlog-upload=false"
         command[#command + 1] = "--use-signing-config=false"
      end

      command[#command + 1] = path
      artifact_io.run(command)

      artifact_io.format_json(bundle)
   end

   --- Sign one selected payload with the configured signing boundary.
   -- @param path string: filesystem path selected by the caller.
   -- @return nil: no values.
   local function release_sign_signPayload(path)
      if
         path:match("^bins/")
         or path:match("^sbom/")
         or path:match("^attestations/")
         or path:match("^security/vex/")
      then
         release_sign_sign(
            output .. "/" .. path,
            output .. "/signatures/sigstore/files/" .. path .. ".sigstore.json"
         )
      end
   end

   for _, path in ipairs(artifact_io.files(output)) do
      release_sign_signPayload(path)
   end

   artifact_io.index(output)

   release_sign_sign(
      output .. "/integrity/release-index.json",
      output .. "/signatures/release-index.sigstore.json"
   )

   artifact_io.verify(output)

   print("Signed copy: " .. output)
end

return scripts_release_sign_main()

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Verify detached release signatures under the configured trust identities.
-- Part of release construction, verification and artifact identity.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_release_verify_main()
   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local options = artifact_io.options(arg, {
      root = true,
      identity = true,
      issuer = true,
      key = true,
      unsigned = true,
      offline = true,
      ["trusted-root"] = true,
   })

   local root = assert(options.root, "--root is required")

   --- Verify the artifact and signature bundle under the configured trust
   -- policy.
   -- @param path string: filesystem path selected by the caller.
   -- @param bundle any: bundle supplied to this operation.
   -- @return nil: no values.
   local function release_verify_verify(path, bundle)
      local command = {
         "cosign",
         "verify-blob",
         "--bundle",
         bundle,
      }

      if options.key then
         command[#command + 1] = "--key"
         command[#command + 1] = options.key
      else
         assert(
            options.identity and options.issuer,
            "an external signer identity and issuer are required"
         )

         for _, value in ipairs({
            "--certificate-identity",
            options.identity,
            "--certificate-oidc-issuer",
            options.issuer,
         }) do
            command[#command + 1] = value
         end
      end

      if options["trusted-root"] then
         command[#command + 1] = "--trusted-root"
         command[#command + 1] = options["trusted-root"]
      end

      if options.offline then
         assert(
            options.key and options["trusted-root"],
            (
               "offline fixture verification requires an "
               .. "external key and trust file"
            )
         )

         local identity = root .. "/identity/build-id.json"
         local is_mock = artifact_io.query(identity, ".mock") == "true"

         assert(is_mock, "offline test mode requires a mock")

         command[#command + 1] = "--insecure-ignore-tlog"
      end

      command[#command + 1] = path
      artifact_io.run(command)
   end

   if options.unsigned ~= true then
      release_verify_verify(
         root .. "/integrity/release-index.json",
         root .. "/signatures/release-index.sigstore.json"
      )
   end

   artifact_io.verify(root)

   dofile("scripts/release/lib/evidence.lua").validate(root)
   if options.unsigned ~= true then
      for _, path in ipairs(artifact_io.files(root)) do
         if
            path:match("^bins/")
            or path:match("^sbom/")
            or path:match("^attestations/")
         then
            release_verify_verify(
               root .. "/" .. path,
               root .. "/signatures/sigstore/files/" .. path .. ".sigstore.json"
            )
         end
      end
   end

   local unsigned_message = "Unsigned mock integrity verified; "
      .. "authenticity not established."

   print(
      options.unsigned and unsigned_message
         or "Authenticated release integrity verified."
   )
end

return scripts_release_verify_main()

-- EOF


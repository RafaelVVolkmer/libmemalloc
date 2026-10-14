-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Exercise real Cosign cryptography without OIDC, uploads, or production keys.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_release_signature_test_suite_main()
   local R = dofile("scripts/lib/artifacts.lua")
   local options = R.options(arg, { root = true })
   local root = assert(options.root, "--root is required")

   R.verify(root)

   local private = R.platform.temporary_directory("tests")
   local destination = ".cache/tests/signatures/" .. private:match("([^/]+)$")

   --- Exercise signature acceptance and tampering before key cleanup.
   -- @return nil: no values.
   local success, failure = xpcall(function()
      for _, name in ipairs({ "expected", "unexpected" }) do
         R.run({
            "env",
            "COSIGN_PASSWORD=",
            "cosign",
            "generate-key-pair",
            "--output-key-prefix",
            private .. "/" .. name,
         })
      end

      local trust = private .. "/test-trust.json"

      R.document(trust, {
         mediaType = (
            "application/vnd.dev.sigstore.trustedroot+j" .. "son;version=0.1"
         ),
         tlogs = R.array(),
         certificateAuthorities = R.array(),
         ctlogs = R.array(),
         timestampAuthorities = R.array(),
      })
      R.run({
         "env",
         "COSIGN_PASSWORD=",
         "lua",
         "scripts/release/sign.lua",
         "--root=" .. root,
         "--output=" .. destination,
         "--key=" .. private .. "/expected.key",
         "--offline",
      })

      --- Verify the candidate with the selected public key.
      -- @param key string: record field or catalog key to select.
      -- @return any: verify the candidate with the selected public key.
      local function verify(key)
         return R.platform.command_succeeded_silent({
            "lua",
            "scripts/release/verify.lua",
            "--root=" .. destination,
            "--key=" .. private .. "/" .. key .. ".pub",
            "--trusted-root=" .. trust,
            "--offline",
         })
      end

      assert(verify("expected"), "valid signature rejected")

      for _, path in ipairs(R.files(destination)) do
         if path:match("%.sigstore%.json$") then
            local full_path = destination .. "/" .. path
            local formatted = R.output({
               "jq",
               "--sort-keys",
               "--indent",
               "2",
               ".",
               full_path,
            })

            assert(
               R.read(full_path) == formatted .. "\n",
               "unformatted signature envelope: " .. path
            )
         end
      end

      assert(not verify("unexpected"), "unexpected signer accepted")

      local index = destination .. "/integrity/release-index.json"
      local original = R.read(index)

      R.write(index, original .. " ")
      assert(not verify("expected"), "tampered index signature accepted")

      R.write(index, original)

      local payload = R.query(
         destination .. "/identity/artifacts.json",
         ".artifacts[0].path"
      )

      R.safe_path(payload)

      original = R.read(destination .. "/" .. payload)
      R.write(destination .. "/" .. payload, original .. "tampered")
      assert(not verify("expected"), "tampered signed payload accepted")

      R.write(destination .. "/" .. payload, original)
      assert(verify("expected"), "restored signed tree rejected")

      R.write(
         ".cache/tests/signatures/" .. private:match("([^/]+)$") .. ".pub",
         R.read(private .. "/expected.pub")
      )
      print(
         (
            "Signature tests: valid signer, wrong signer, "
            .. "modified index, modified payload, and restored "
            .. "tree passed."
         )
      )
   end, debug.traceback)

   R.platform.remove_temporary_directory(private)
   assert(success, failure)
end

return tests_release_signature_test_suite_main()

-- EOF


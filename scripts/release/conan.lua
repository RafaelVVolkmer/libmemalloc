-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Publish the verified mock package through the selected Conan remote.
-- Part of release construction, verification and artifact identity.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_release_conan_main()
   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local options = artifact_io.options(arg, {
      root = true,
      publish = true,
      remote = true,
      identity = true,
      issuer = true,
      ["allow-mock"] = true,
   })

   local root = assert(options.root, "--root is required")

   artifact_io.verify(root)

   dofile("scripts/release/lib/evidence.lua").validate(root)
   if options.publish then
      assert(
         options["allow-mock"]
            and os.getenv("LIBMEMALLOC_CONAN_MOCK_CHANNEL") == "true",
         "mock upload requires an explicitly enabled test channel"
      )
      assert(
         options.identity and options.issuer,
         "remote publication requires an expected signing identity"
      )
      assert(
         options.remote and options.remote:match("^https://[%w./_:%-]+$"),
         "an HTTPS Conan remote is required"
      )
      assert(
         not options.remote:find("@", 1, true),
         "credentials must not appear in the remote URL"
      )

      artifact_io.run({
         "lua",
         "scripts/release/verify.lua",
         "--root=" .. root,
         "--identity=" .. options.identity,
         "--issuer=" .. options.issuer,
      })
   end

   local version =
      artifact_io.query(root .. "/identity/target.json", ".version")

   artifact_io.semver(version)

   local full_root = artifact_io.output({ "realpath", "--", root })
   local generated = artifact_io.platform.temporary_directory("cd")
   local receipts = ".cache/cd/publications/"
      .. artifact_io.digest(root .. "/integrity/release-index.json")
      .. "/conan-"
      .. generated:match("([^/]+)$")

   artifact_io.mkdir(receipts)

   local references = {}

   --- Exercise Conan package creation for one build variant.
   -- @param variant any: variant supplied to this operation.
   -- @return nil: no values.
   local function release_conan_packageVariant(variant)
      for _, shared in ipairs({ "True", "False" }) do
         artifact_io.run({
            "conan",
            "export-pkg",
            "packaging/conan",
            "--version=" .. version,
            "--output-folder=" .. generated .. "/" .. variant .. "-" .. shared,
            "--format=json",
            "--out-file="
               .. receipts
               .. "/"
               .. variant
               .. "-"
               .. shared
               .. ".json",
            "--no-remote",
            "-s",
            "build_type=" .. variant,
            "-o",
            "&:shared=" .. shared,
            "-c",
            "user.libmemalloc:release_root=" .. full_root,
         })

         local receipt = receipts .. "/" .. variant .. "-" .. shared .. ".json"
         local package_folder =
            artifact_io.query(receipt, '.graph.nodes["0"].package_folder')

         references[#references + 1] = artifact_io.query(
            receipt,
            '.graph.nodes["0"] | .ref + ":" + .package_id + "#" + .prev'
         )

         local executable = generated
            .. "/consumer-"
            .. variant
            .. "-"
            .. shared
         local library = package_folder
            .. "/lib/libmemalloc"
            .. (shared == "True" and ".so" or ".a")

         artifact_io.run({
            "gcc",
            "-Wall",
            "-Wextra",
            "-Werror",
            "core/main.c",
            "-I" .. package_folder .. "/include",
            library,
            "-o",
            executable,
         })

         artifact_io.run({
            "env",
            "LD_LIBRARY_PATH=" .. package_folder .. "/lib",
            "timeout",
            "10",
            executable,
         })
      end
   end

   for _, variant in ipairs({ "Release", "Debug" }) do
      release_conan_packageVariant(variant)
   end

   artifact_io.platform.remove_temporary_directory(generated)
   if options.publish then
      artifact_io.run({ "conan", "remote", "add", "release", options.remote })

      -- Credentials are read by Conan from CONAN_LOGIN_USERNAME_RELEASE and
      -- CONAN_PASSWORD_RELEASE; they are never embedded into argv or reports.
      artifact_io.run({
         "conan",
         "remote",
         "auth",
         "release",
         "--with-user",
         "--force",
         "--strict",
      })

      for _, reference in ipairs(references) do
         assert(
            reference:match(
               "^libmemalloc%-mock/[%w.+%-]+#[a-f0-9]+:[a-f0-9]+#[a-f0-9]+$"
            ),
            "unexpected Conan reference"
         )

         artifact_io.run({
            "conan",
            "upload",
            reference,
            "--remote=release",
            "--confirm",
            "--check",
         })
      end

      print(
         "Published the explicitly authorized mock package to the test remote."
      )
   else
      print(
         (
            "Conan mock packages exported to the local cache; "
            .. "no remote upload performed."
         )
      )
   end

   dofile("scripts/lib/change.lua").record(true)
end

return scripts_release_conan_main()

-- EOF


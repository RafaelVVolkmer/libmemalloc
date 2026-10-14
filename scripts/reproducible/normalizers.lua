-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Qualify alternative normalizers on copies, never on the compared originals.
-- Part of independent reconstruction and byte-comparison campaigns.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_reproducible_normalizers_main()
   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local tools = dofile("scripts/toolchain/lib/lock.lua").load()
   local options =
      artifact_io.options(arg, { input = true, output = true, install = true })
   local input = assert(options.input, "--input is required")
   local output = assert(options.output, "--output is required")

   for _, path in ipairs({ input, output }) do
      artifact_io.safe_path(path)
      assert(path:match("^%.cache/"), "paths must stay in .cache")
   end

   assert(not artifact_io.exists(output), "normalizer evidence must be fresh")

   artifact_io.mkdir(output)

   local root = artifact_io.output({ "pwd" })
   local bin = root .. "/.cache/tools/reproducible/bin"
   local result =
      { schema = 1, scope = "diagnostic copies only", state = "FAIL" }

   local success, message = xpcall(
      --- Evaluate normalizer tools on copies while preserving original artifact
      -- bytes.
      -- @return nil: no values.
      function()
         if options.install then
            artifact_io.run({
               "cargo",
               "install",
               "add-determinism",
               "--locked",
               "--version",
               tools.add_determinism.version,
               "--root",
               ".cache/tools/reproducible",
            })

            artifact_io.run({
               "env",
               "GOBIN=" .. bin,
               "go",
               "install",
               "github.com/google/oss-rebuild/cmd/stabilize@"
                  .. tools.oss_rebuild.revision,
            })
         end

         result.tools = {
            add_det = artifact_io.output({ bin .. "/add-det", "--version" }),
            linkdupes = artifact_io.output({
               -- Preserve the installed tool identity in the result.
               bin .. "/linkdupes",
               "--version",
            }),
            stabilize_revision = tools.oss_rebuild.revision,
            stabilize_sha256 = artifact_io.digest(bin .. "/stabilize"),
         }

         local files = artifact_io.files(input)

         assert(#files > 0, "no packages to normalize")
         for _, name in ipairs(files) do
            assert(name:match("^[%w-]+%.tar%.gz$"), "unexpected package format")

            local original = input .. "/" .. name
            local original_hash = artifact_io.digest(original)

            for _, adapter in ipairs({ "strip", "add-det", "stabilize" }) do
               local copy = output .. "/" .. adapter .. "/" .. name

               artifact_io.mkdir(output .. "/" .. adapter)

               artifact_io.run({ "cp", "--", original, copy })

               --- Apply each candidate normalizer to diagnostic copies for an
               -- idempotence comparison.
               -- @return nil: no values.
               local function reproducible_normalizers_normalize()
                  if adapter == "strip" then
                     artifact_io.run({
                        "strip-nondeterminism",
                        "--type=gzip",
                        "--timestamp=1",
                        copy,
                     })
                  elseif adapter == "add-det" then
                     artifact_io.run({
                        "env",
                        "SOURCE_DATE_EPOCH=1",
                        bin .. "/add-det",
                        "--handler=gzip",
                        copy,
                     })
                  else
                     artifact_io.run({
                        bin .. "/stabilize",
                        "--infile=" .. root .. "/" .. copy,
                        "--outfile=" .. root .. "/" .. copy .. ".next",
                     })

                     artifact_io.run({ "mv", "--", copy .. ".next", copy })
                  end
               end

               reproducible_normalizers_normalize()

               local digest = artifact_io.digest(copy)

               reproducible_normalizers_normalize()
               assert(
                  artifact_io.digest(copy) == digest,
                  "normalizer is not idempotent"
               )

               -- Compare file contents while allowing diagnostic metadata
               -- changes.
               local before, after = copy .. ".before", copy .. ".after"

               artifact_io.mkdir(before)

               artifact_io.mkdir(after)

               artifact_io.run({
                  "tar",
                  "-xzf",
                  original,
                  "-C",
                  before,
                  "--no-same-owner",
               })

               artifact_io.run({
                  "tar",
                  "-xzf",
                  copy,
                  "-C",
                  after,
                  "--no-same-owner",
               })

               artifact_io.run({
                  "diff",
                  "-r",
                  "--no-dereference",
                  before,
                  after,
               })
            end

            assert(
               artifact_io.digest(original) == original_hash,
               "original package was modified"
            )
         end

         local directory = output .. "/hardlinks"

         artifact_io.mkdir(directory)

         artifact_io.run({ "cp", input .. "/" .. files[1], directory .. "/a" })

         artifact_io.run({ "cp", directory .. "/a", directory .. "/b" })

         artifact_io.run({
            "env",
            "SOURCE_DATE_EPOCH=1",
            bin .. "/linkdupes",
            "--ignore-selinux-context",
            directory,
         })
         assert(
            artifact_io.output({ "stat", "-c", "%i", directory .. "/a" })
               == artifact_io.output({ "stat", "-c", "%i", directory .. "/b" }),
            "linkdupes did not create a shared inode"
         )

         result.claim =
            "Idempotence and file contents verified; SELinux is not qualified."
      end,
      debug.traceback
   )

   result.state = success and "PASS" or "FAIL"
   result.detail = success and "Original package bytes were preserved."
      or message
   artifact_io.document(output .. "/result.json", result)
   assert(success, message)
end

return scripts_reproducible_normalizers_main()

-- EOF


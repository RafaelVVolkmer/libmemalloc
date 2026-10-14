-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Exercise canonical release paths, serialization and tamper rejection.
-- Part of repository automation regression tests; run from the root.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_release_release_test_suite_main()
   local R = dofile("scripts/lib/artifacts.lua")
   local options = R.options(arg, { root = true })
   local count = 0

   --- Count assertions while preserving their failure descriptions.
   -- @param condition boolean: condition that this assertion must establish.
   -- @param name string: entry or operation name to resolve.
   -- @return nil: no values.
   local function check(condition, name)
      assert(condition, name)

      count = count + 1
   end

   --- Require a supplied invalid operation to fail.
   -- @param callback function: operation supplied by the caller; errors
   -- propagate.
   -- @param name string: entry or operation name to resolve.
   -- @return nil: no values.
   local function rejects(callback, name)
      check(not pcall(callback), name)
   end

   for _, path in ipairs({
      "../secret",
      "/absolute",
      "a/../b",
      "a//b",
      "a\nb",
      "a\\b",
      "a/./b",
      "a/",
      "",
   }) do
      --- Reject a path outside the canonical release-path grammar.
      -- @return nil: no values.
      rejects(function()
         R.safe_path(path)
      end, "unsafe path accepted")
   end

   check(
      R.safe_path("bins/debug/libmemalloc-0.0.0-mock.a") ~= nil,
      "valid path rejected"
   )
   check(
      R.json({ z = 1, a = R.array({ true, "\n" }) })
         == '{"a":[true,"\\n"],"z":1}',
      "noncanonical encoding"
   )
   check(
      R.json({}) == "{}" and R.json(R.array()) == "[]",
      "empty type ambiguity"
   )
   check(
      R.pretty_json({ z = {}, a = R.array({ true, "\n", '"\\,{}[]:' }) })
         == (
            '{\
  "a": [\
    true,\
    "\\n",\
    "\\"\\\\,{}[]:"\
  ' .. '],\
  "z": {}\
}\
'
         ),
      "readable JSON changed escaping, ordering, or indentation"
   )
   check(
      R.pretty_json(R.array()) == "[]\n",
      "readable empty array changed type"
   )

   --- Reject fractional numbers in the restricted JSON profile.
   -- @return nil: no values.
   rejects(function()
      R.json(0.5)
   end, "float escaped restricted profile")

   --- Reject non-ASCII text in the restricted JSON profile.
   -- @return nil: no values.
   rejects(function()
      R.json("\195\169")
   end, "non-ASCII escaped restricted profile")

   --- Reject repeated command-line options.
   -- @return nil: no values.
   rejects(function()
      R.options({ "--root=a", "--root=b" }, { root = true })
   end, "duplicate option")

   --- Reject command-line options outside the allowlist.
   -- @return nil: no values.
   rejects(function()
      R.options({ "--unknown" }, {})
   end, "unknown option")

   local temporary = R.platform.temporary_directory()

   --- Exercise release integrity mutations before temporary-tree cleanup.
   -- @return nil: no values.
   local success, failure = xpcall(function()
      local root = temporary .. "/fixture"

      R.write(root .. "/identity/build-inputs.jcs.json", "{}")
      R.document(
         root .. "/identity/build-id.json",
         { sha256 = R.digest(root .. "/identity/build-inputs.jcs.json") }
      )
      R.write(root .. "/bins/payload", "fixture\n")
      R.index(root)
      check(R.verify(root), "valid fixture failed")

      R.document(root .. "/identity/build-inputs.json", {})

      --- Reject competing input manifests in the same release.
      -- @return nil: no values.
      rejects(function()
         R.input_manifest(root)
      end, "ambiguous manifest accepted")
      assert(os.remove(root .. "/identity/build-inputs.jcs.json"))

      R.document(root .. "/identity/build-id.json", {
         sha256 = R.digest(R.input_manifest(root)),
      })
      R.index(root)
      check(R.verify(root), "readable manifest fixture failed")

      R.write(root .. "/bins/payload", "tampered\n")

      --- Reject payload bytes that differ from the recorded digest.
      -- @return nil: no values.
      rejects(function()
         R.verify(root)
      end, "tamper accepted")
      R.write(root .. "/bins/payload", "fixture\n")
      R.write(root .. "/unexpected", "extra")

      --- Reject a file absent from the signed inventory.
      -- @return nil: no values.
      rejects(function()
         R.verify(root)
      end, "extra file accepted")
      assert(os.remove(root .. "/unexpected"))
      assert(os.remove(root .. "/bins/payload"))

      --- Reject a missing inventoried payload.
      -- @return nil: no values.
      rejects(function()
         R.verify(root)
      end, "missing file accepted")
      R.run({ "ln", "-s", "/etc/passwd", root .. "/bins/payload" })

      --- Reject a payload replaced by a symbolic link.
      -- @return nil: no values.
      rejects(function()
         R.verify(root)
      end, "linked payload accepted")
      assert(os.remove(root .. "/bins/payload"))

      R.write(root .. "/bins/payload", "fixture\n")

      local original = R.read(root .. "/integrity/release-index.json")

      R.document(root .. "/integrity/release-index.json", {
         schema = 1,
         files = R.array({
            { path = "../outside", size = 0, sha256 = string.rep("a", 64) },
         }),
      })

      --- Reject an inventory path that escapes the release root.
      -- @return nil: no values.
      rejects(function()
         R.verify(root)
      end, "index traversal accepted")
      R.write(root .. "/integrity/release-index.json", original)
      check(R.verify(root), "restored fixture failed")
      if options.root then
         check(R.verify(options.root), "built candidate failed")
         if R.exists(options.root .. "/identity/build-inputs.json") then
            for _, path in ipairs(R.files(options.root)) do
               if path:match("%.json$") then
                  local full_path = options.root .. "/" .. path
                  local formatted = R.output({
                     "jq",
                     "--sort-keys",
                     "--indent",
                     "2",
                     ".",
                     full_path,
                  })

                  check(
                     R.read(full_path) == formatted .. "\n",
                     "unformatted release JSON: " .. path
                  )
               end
            end
         end

         check(
            dofile("scripts/release/lib/evidence.lua").validate(options.root),
            "evidence failed"
         )
         check(not R.platform.command_succeeded_silent({
            "lua",
            "scripts/check/openssf.lua",
            "--root=" .. options.root,
            "--production",
         }), "mock passed production gate")
         check(not R.platform.command_succeeded_silent({
            "lua",
            "scripts/release/conan.lua",
            "--root=" .. options.root,
            "--publish",
            "--remote=https://example.invalid",
         }), "unauthorized upload accepted")
      end
   end, debug.traceback)

   R.platform.remove_temporary_directory(temporary)
   assert(success, failure)

   print(string.format("Release policy: %d assertions passed.", count))
end

return tests_release_release_test_suite_main()

-- EOF


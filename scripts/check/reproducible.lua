-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Verify the recorded byte comparisons against the current release payloads.
-- Part of local and CI verification gates.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_check_reproducible_main()
   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local options = artifact_io.options(arg, { root = true })
   local root = assert(options.root, "--root is required")

   artifact_io.verify(root)

   local report = root .. "/attestations/reproducibility.json"

   artifact_io.query(
      report,
      (
         ".comparisons | length == 10 and all(.[]; .status "
         .. '== "PASS" and .first == .second and (.first | '
         .. 'test("^[a-f0-9]{64}$")))'
      )
   )

   for row in
      artifact_io
         .query(report, ".comparisons[] | [.path, .first] | @tsv")
         :gmatch("[^\n]+")
   do
      local path, digest = row:match("^([^\t]+)\t([a-f0-9]+)$")

      artifact_io.safe_path(assert(path, "missing comparison path"))
      assert(
         artifact_io.digest(root .. "/" .. path) == digest,
         "rebuild report does not match payload"
      )
   end

   print(
      (
         "Ten mock payloads match both clean builds; "
         .. "independent-builder qualification remains pending."
      )
   )
end

return scripts_check_reproducible_main()

-- EOF


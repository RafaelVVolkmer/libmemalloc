-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Submodule content and revision both belong to the evaluated source identity.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_process_subject_test_suite_main()
   local I = dofile("scripts/process/lib/io.lua")
   local R = dofile("scripts/lib/artifacts.lua")
   local previous = assert(I.uv.cwd())
   local root = R.platform.temporary_directory("tests")

   --- Run Git with isolated fixture identity and disabled signing.
   -- @param directory string: working or output directory selected by the
   -- caller.
   -- @param arguments table: ordered arguments for the selected operation.
   -- @return any: run Git with isolated fixture identity and disabled signing.
   local function git(directory, arguments)
      local command = {
         "git",
         "-C",
         directory,
         "-c",
         "user.name=Fixture",
         "-c",
         "user.email=fixture@example.invalid",
         "-c",
         "commit.gpgsign=false",
      }

      for _, value in ipairs(arguments) do
         command[#command + 1] = value
      end

      return I.capture(command)
   end

   --- Write subject bytes into the temporary repository.
   -- @param path string: filesystem path selected by the caller.
   -- @param contents string: input bytes to process.
   -- @return nil: no values.
   local function write(path, contents)
      R.write(path, contents)
   end

   --- Exercise subject identity changes before releasing the repository.
   -- @return nil: no values.
   local ok, failure = xpcall(function()
      git(root, { "init", "-q" })

      local child = root .. "/vendor/theme"

      write(child .. "/style.css", "body {}\n")
      git(child, { "init", "-q" })
      git(child, { "add", "." })
      git(child, { "commit", "-qm", "Initial theme" })
      git(root, { "add", "vendor/theme" })
      git(root, { "commit", "-qm", "Initial parent" })
      assert(I.uv.chdir(root))

      local baseline = I.subject()

      assert(
         #baseline.inputs == 2 and not baseline.dirty,
         "clean source inventory changed"
      )
      assert(baseline.inputs[1].mode == 160000, "submodule Git mode was lost")

      write(child .. "/style.css", "body { color: red; }\n")

      local changed = I.subject()

      assert(
         changed.dirty and changed.source_sha256 ~= baseline.source_sha256,
         "submodule edit did not change source identity"
      )

      write(child .. "/style.css", "body {}\n")
      write(child .. "/extra.css", "p {}\n")
      assert(
         I.subject().source_sha256 ~= baseline.source_sha256,
         "submodule addition did not change source identity"
      )
      assert(I.uv.fs_unlink(child .. "/extra.css"))
      assert(I.uv.fs_unlink(child .. "/style.css"))
      assert(
         I.subject().inputs[2].sha256 == "DELETED",
         "submodule deletion was not recorded"
      )

      write(child .. "/style.css", "body {}\n")
      git(child, { "commit", "--allow-empty", "-qm", "New theme revision" })
      assert(
         I.subject().source_sha256 ~= baseline.source_sha256,
         "submodule revision did not change source identity"
      )
      assert(os.rename(child .. "/.git", child .. "/git-held"))
      assert(not pcall(I.subject), "uninitialized submodule was accepted")
      assert(os.rename(child .. "/git-held", child .. "/.git"))
   end, debug.traceback)

   assert(I.uv.chdir(previous))

   R.platform.remove_temporary_directory(root)
   assert(ok, failure)

   print(
      (
         "Source identity: submodule revision, "
         .. "edits, additions and deletions passed."
      )
   )
end

return tests_process_subject_test_suite_main()

-- EOF


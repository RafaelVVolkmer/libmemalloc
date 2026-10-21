-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Require an EOF comment and surrounding blank lines in owned text formats.
-- Part of local and CI verification gates.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_check_eof_main()
   local release = dofile("scripts/lib/artifacts.lua")
   local git = dofile("scripts/lib/git.lua").new(release.platform, ".")
   local paths = assert(git.working_files(), "cannot list working sources")

   local markers = {
      lua = "-- EOF",
      lean = "-- EOF",
      c = "/* EOF */",
      dox = "/* EOF */",
      h = "/* EOF */",
      py = "# EOF",
      yml = "# EOF",
      yaml = "# EOF",
      toml = "# EOF",
      nix = "# EOF",
      sh = "# EOF",
      cmake = "# EOF",
      md = "<!-- EOF -->",
      jsonc = "// EOF",
      json5 = "// EOF",
      psd1 = "# EOF",
      nuon = "# EOF",
      ini = "# EOF",
      cocci = "/* EOF */",
   }

   local hash_names = {
      "doxygen/config/Doxyfile",
      "doxygen/config/Doxyfile.formats",
      "CMakeLists.txt",
      "infra/ansible/ansible.cfg",
      ".gitconfig",
      ".gitignore",
      ".gitattributes",
      ".editorconfig",
      ".github/CODEOWNERS",
      ".mailmap",
      ".gitmessage",
   }
   local hash_patterns = {
      "/CMakeLists%.txt$",
      "/%.clang%-format$",
      "/%.clang%-tidy$",
      "/%.codespellrc$",
      "/shellcheckrc$",
      "/%.lycheeignore$",
      "%.env%.example$",
      "%.cmake%.in$",
      "%.pc%.in$",
   }

   local failures = 0
   local checked = 0
   local seen = {}

   --- Select the EOF grammar for an owned path without reading its bytes.
   -- @param path string: repository-relative source or configuration path.
   -- @return string|nil: required marker, or nil for formats without comments.
   local function check_eof_marker(path)
      local suffix = path:match("%.([%w]+)$")
      local marker = markers[suffix]

      for _, name in ipairs(hash_names) do
         if path == name then
            marker = "# EOF"
         end
      end

      for _, pattern in ipairs(hash_patterns) do
         if path:match(pattern) then
            marker = "# EOF"
         end
      end

      if path:match("%.c%.in$") or path:match("%.cpp%.in$") then
         marker = "/* EOF */"
      end

      if path:match("^%.githooks/[^/]+$") then
         marker = "-- EOF"
      end

      return marker
   end

   --- Check the final marker of one owned source file.
   -- @param path string: filesystem path selected by the caller.
   -- @return nil: no values.
   local function check_eof_validateSource(path)
      local marker = check_eof_marker(path)

      if marker and not seen[path] and release.exists(path) then
         local contents = release.read(path)
         local expected = "\n\n" .. marker .. "\n\n"

         seen[path] = true
         checked = checked + 1

         if contents:sub(-#expected) ~= expected then
            io.stderr:write(
               path .. ": expected blank line, EOF comment, blank line\n"
            )

            failures = failures + 1
         end
      end
   end

   for _, path in ipairs(paths) do
      check_eof_validateSource(path)
   end

   print(
      string.format("EOF: %d files checked; %d failures.", checked, failures)
   )
   assert(failures == 0, "EOF convention failed")
end

return scripts_check_eof_main()

-- EOF


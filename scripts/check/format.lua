-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Check formatter output while preserving the repository EOF blank line.
-- Formatters remove trailing empty lines. Check that one terminal exception
-- separately; do not ignore any other formatter difference.
-- Part of local and CI verification gates.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_check_format_main()
   local FORMAT_FIRST_INPUT_INDEX = 3

   local release = dofile("scripts/lib/artifacts.lua")
   local language = assert(arg[1], "language is required")
   local formatter = assert(arg[2], "formatter is required")
   local directory = release.platform.temporary_directory("tests")
   local config_root = release.output({ "git", "rev-parse", "--show-toplevel" })
   local adapters = dofile("tools/lint/formatters.lua")
   local adapter = assert(adapters[language], "unknown formatter language")
   local command = { formatter }

   for _, argument in ipairs(adapter.arguments) do
      command[#command + 1] = argument:gsub(
         "{root}",
         --- Substitute the repository root without treating percent bytes as
         -- replacements.
         -- @return any: substitute the repository root without treating percent
         -- bytes as replacements.
         function()
            return config_root
         end
      )
   end

   local success, message = xpcall(
      --- Check staged formatter inputs while preserving cleanup on formatter
      -- failure.
      -- @return nil: no values.
      function()
         for index = FORMAT_FIRST_INPUT_INDEX, #arg do
            local path = arg[index]
            local contents = release.read(path)
            local destination = directory .. "/" .. path

            release.safe_path(path)

            if adapter.terminal_marker then
               -- EOF validation owns the marker and its exact surrounding blank
               -- lines.
               local marker = adapter.terminal_marker:gsub("([^%w])", "%%%1")

               contents = contents:gsub("\n\n" .. marker .. "\n\n$", "\n")
            end

            release.write(destination, (contents:gsub("\n+$", "\n")))

            command[#command + 1] = destination
         end

         assert(#arg >= FORMAT_FIRST_INPUT_INDEX, "no formatter input files")

         release.run(command)
      end,
      debug.traceback
   )

   release.platform.remove_temporary_directory(directory)
   assert(success, message)
end

return scripts_check_format_main()

-- EOF


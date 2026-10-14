-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Record argument bytes for the Ansible transport regression.
-- This fixture runs only in the test's disposable repository.

--- Encode argument boundaries without relying on a JSON or YAML parser.
-- @return nil: no values.
local function ARGUMENTS_main()
   local file = assert(io.open(".cache/captured-arguments.txt", "wb"))

   for _, value in ipairs(arg) do
      local encoded = value:gsub(
         ".",
         --- Preserve each byte in a printable hexadecimal pair.
         -- @param character string: captured character or byte sequence.
         -- @return any: preserve each byte in a printable hexadecimal pair.
         function(character)
            return string.format("%02x", character:byte())
         end
      )

      assert(file:write(encoded, "\n"))
   end

   assert(file:close())
end

return ARGUMENTS_main()

-- EOF


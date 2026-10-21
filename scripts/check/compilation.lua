-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Verify the library and fixture consumer captured by CodeQL.
-- @return nil: no values.
local function COMPILATION_main()
   local io = dofile("scripts/build/lib/io.lua")
   local sources = dofile("scripts/build/lib/sources.lua")
   assert(#arg == 1, "usage: compilation.lua compile_commands.json")
   sources.check(
      io.lines(io.query(arg[1], ".[ ].file")),
      sources.expected(io.root, "", { "build-interface" })
   )
   print("Compilation capture matches the reviewed source inventory.")
end

return COMPILATION_main()

-- EOF


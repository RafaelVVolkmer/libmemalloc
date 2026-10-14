-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Enforce the Lua initialization boundary without executing inspected code.
-- Part of the Lua quality gate; consumes listings from the pinned compiler.

--- Create the validator and its compiler-listing contract.
-- @return table: public operations constructed by this module.
local function LUA_STRUCTURE_loadModule()
   local exports = {}
   local bootstrap = {
      "VARARGPREP",
      "CLOSURE",
      "MOVE",
      "VARARG",
      "TAILCALL",
      "RETURN",
      "RETURN",
   }

   --- Accept only one local factory followed by its returned invocation.
   -- @param listing string: output from luac -l -p for one source file.
   -- @return boolean: whether the outer chunk contains only the bootstrap.
   local function LUA_STRUCTURE_validate(listing)
      local outer = listing:match("\nmain .-\n(.-)\nfunction ")

      if not outer then
         return false
      end

      local position = 0
      local expected = {}

      for _, value in ipairs(bootstrap) do
         if value ~= "VARARG" or outer:match("%]%s+VARARG%s") then
            expected[#expected + 1] = value
         end
      end

      for opcode in outer:gmatch("%[%d+%]%s+([A-Z]+)") do
         position = position + 1
         if opcode ~= expected[position] then
            return false
         end
      end

      return position == #expected
   end

   exports.validate = LUA_STRUCTURE_validate

   return exports
end

return LUA_STRUCTURE_loadModule()

-- EOF


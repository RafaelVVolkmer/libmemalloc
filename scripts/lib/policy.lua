-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer
-- <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Generic ordered boolean-policy state for Lua tooling.
-- Part of shared host, path and artifact primitives.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_lib_policy_loadModule()
   local exports = {}

   --- Parse a strict textual boolean.
   -- @param value string|nil: textual boolean value.
   -- @return boolean|nil: parsed value, or nil for invalid input.
   local function POLICY_parseBoolean(value)
      if value == "true" or value == "1" then
         return true
      end

      if value == "false" or value == "0" or value == nil then
         return false
      end

      return nil
   end

   exports.parse_boolean = POLICY_parseBoolean

   --- Create an ordered boolean policy set.
   -- @param keys table: ordered policy keys.
   -- @return table: policy state object.
   local function POLICY_new(keys)
      local order = {}
      local values = {}

      for _, key in ipairs(keys) do
         if values[key] ~= nil then
            error("duplicate policy key: " .. tostring(key), 2)
         end

         order[#order + 1] = key
         values[key] = false
      end

      local state = {}

      --- Mark one policy key true.
      -- @param key string: known policy key.
      -- @return nil: no values.
      local function POLICY_mark(key)
         if values[key] == nil then
            error("unknown policy key: " .. tostring(key), 2)
         end

         values[key] = true
      end

      state.mark = POLICY_mark

      --- Mark every policy key true.
      -- @return nil: no values.
      local function POLICY_markAll()
         for _, key in ipairs(order) do
            values[key] = true
         end
      end

      state.mark_all = POLICY_markAll

      --- Read one policy key.
      -- @param key string: known policy key.
      -- @return boolean: current policy value.
      local function POLICY_get(key)
         if values[key] == nil then
            error("unknown policy key: " .. tostring(key), 2)
         end

         return values[key]
      end

      state.get = POLICY_get

      --- Iterate policy keys in their declared order.
      -- @return function: iterator yielding key and boolean value.
      local function POLICY_each()
         local index = 0

         return
         --- Yield the next policy entry in its declared order.
         -- @return any, any: yield the next policy entry in its declared order.
         function()
            index = index + 1

            local key = order[index]

            if not key then
               return nil
            end

            return key, values[key]
         end
      end

      state.each = POLICY_each

      return state
   end

   exports.new = POLICY_new

   return exports
end

return scripts_lib_policy_loadModule()

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Parse the deliberately limited TOML schema used by toolchain.lock.toml.
-- Unsupported TOML syntax fails closed instead of being partially interpreted.
-- Part of versioned tool identities and host provisioning.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_toolchain_lib_lock_loadModule()
   local exports = {}

   --- Load the sole repository authority for tool identities.
   -- @return table: Validated lock entries keyed by tool name.
   local function TOOLCHAIN_LOCK_load()
      local file = assert(io.open("tools/toolchain/lock.toml", "rb"))
      local contents = assert(file:read("*a"))

      assert(file:close())

      return exports.parse(contents)
   end

   exports.load = TOOLCHAIN_LOCK_load

   local field_lengths = {
      sha256 = 64,
      remote_sha256 = 64,
      macos_arm64_sha256 = 64,
      macos_x86_64_sha256 = 64,
      revision = 40,
   }
   local allowed_fields = {
      version = true,
      reported_version = true,
      revision = true,
      sha256 = true,
      remote_sha256 = true,
      macos_arm64_sha256 = true,
      macos_x86_64_sha256 = true,
   }

   --- Validate a schema field before publishing it to the parsed tool record.
   -- @param key string: supported field name from the limited TOML grammar.
   -- @param value string: parsed token; digests must be lowercase hexadecimal.
   -- @return nil: no values.
   local function toolchain_lock_validateField(key, value)
      assert(allowed_fields[key], "unknown lock field: " .. key)

      local length = field_lengths[key]

      if length then
         assert(#value == length and value:match("^[a-f0-9]+$"), "bad " .. key)
      end
   end

   --- Parse the supported lock grammar; reject duplicate, unknown or malformed
   -- identities.
   -- @param source any: source value inspected by this operation.
   -- @return table: the supported lock grammar; reject duplicate, unknown or
   -- malformed identities.
   local function TOOLCHAIN_LOCK_parse(source)
      local tools = {}
      local current = nil
      local schema = false

      --- Parse one supported TOML line without accepting unknown fields.
      -- @param raw string: raw supplied to this operation.
      -- @return nil: no values.
      local function toolchain_lock_parseLine(raw)
         local line = raw:match("^%s*(.-)%s*$")

         if line ~= "" and line:sub(1, 1) ~= "#" then
            local section = line:match("^%[tools%.([%w_]+)%]$")

            if line == "schema_version = 1" and not schema and not current then
               schema = true
            elseif section then
               assert(not tools[section], "duplicate tool: " .. section)

               tools[section] = {}
               current = tools[section]
            else
               local key, value = line:match('^([%w_]+)%s*=%s*"([%w._+%-]+)"$')

               assert(current and key and value, "invalid lock line: " .. line)
               assert(not current[key], "duplicate field: " .. key)
               toolchain_lock_validateField(key, value)

               current[key] = value
            end
         end
      end

      for raw in (source .. "\n"):gmatch("(.-)\n") do
         toolchain_lock_parseLine(raw)
      end

      assert(schema and next(tools), "missing schema or tools")

      for name, tool in pairs(tools) do
         assert(tool.version or tool.revision, "missing identity: " .. name)
      end

      return tools
   end

   exports.parse = TOOLCHAIN_LOCK_parse

   --- Serialize tool identities in stable key order for workflow outputs.
   -- @param tools table: tools supplied to this operation.
   -- @return string: serialize tool identities in stable key order for workflow
   -- outputs.
   local function TOOLCHAIN_LOCK_json(tools)
      local names = {}

      for name in pairs(tools) do
         names[#names + 1] = name
      end

      table.sort(names)

      local entries = {}

      for _, name in ipairs(names) do
         local fields = {}

         for key, value in pairs(tools[name]) do
            fields[#fields + 1] = '"' .. key .. '":"' .. value .. '"'
         end

         table.sort(fields)

         entries[#entries + 1] = '"'
            .. name
            .. '":{'
            .. table.concat(fields, ",")
            .. "}"
      end

      return "{" .. table.concat(entries, ",") .. "}"
   end

   exports.json = TOOLCHAIN_LOCK_json

   return exports
end

return scripts_toolchain_lib_lock_loadModule()

-- EOF


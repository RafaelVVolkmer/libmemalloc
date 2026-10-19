-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Read the explicit CMake source lists and validate captured multiplicities.
-- @return table: reviewed inventory and exact compilation capture checks.
local function BUILD_SOURCES_loadModule()
   local exports = {}
   local file = assert(io.open("cmake/sources.cmake", "rb"))
   local content = assert(file:read("*a"))
   assert(file:close())
   local seen = {}
   for name, body in content:gmatch("set%((LMA_[A-Z_]+)%s+([^%)]+)%)") do
      assert(not exports[name], "duplicate source list: " .. name)
      local paths = {}
      for path in body:gmatch("%S+") do
         assert(path:match("^core/[%w_]+%.[ch]$"), "invalid source: " .. path)
         assert(not seen[path], "duplicate source: " .. path)
         seen[path] = true
         paths[#paths + 1] = path
      end
      assert(#paths > 0, "empty source list: " .. name)
      exports[name] = paths
   end
   for _, name in ipairs({
      "LMA_LIBRARY_SOURCES",
      "LMA_CONSUMER_SOURCES",
      "LMA_CORE_HEADERS",
   }) do
      assert(exports[name], "missing source list: " .. name)
   end

   --- Assemble the expected units for the selected executable targets.
   -- @param root string: absolute repository root.
   -- @param build string: absolute build directory.
   -- @param tests table: actual target names admitted by configuration.
   -- @return table: source paths, with one entry per compilation.
   function exports.expected(root, build, tests)
      local paths = {}
      for _, path in ipairs(exports.LMA_LIBRARY_SOURCES) do
         paths[#paths + 1] = root .. "/" .. path
      end
      for _, name in ipairs(tests) do
         if name == "build-interface" then
            for _, path in ipairs(exports.LMA_CONSUMER_SOURCES) do
               paths[#paths + 1] = root .. "/" .. path
            end
         elseif name == "c-api" then
            paths[#paths + 1] = build .. "/api.c"
         elseif name == "target-model" then
            paths[#paths + 1] = build .. "/target.c"
         else
            assert(
               name:match("^cpp%-%d+$"),
               "unknown compilation target: " .. name
            )
            paths[#paths + 1] = build .. "/consumer.cpp"
         end
      end
      return paths
   end

   --- Reject missing, extra or substituted units, including duplicate entries.
   -- @param actual table: captured absolute source paths.
   -- @param expected table: reviewed source paths with target multiplicities.
   -- @return nil: no values; a mismatch raises an actionable diagnostic.
   function exports.check(actual, expected)
      local counts = {}
      for _, path in ipairs(expected) do
         path = path:gsub("\\", "/")
         counts[path] = (counts[path] or 0) + 1
      end
      for _, path in ipairs(actual) do
         path = path:gsub("\\", "/")
         assert((counts[path] or 0) > 0, "unexpected compiled source: " .. path)
         counts[path] = counts[path] - 1
      end
      for path, count in pairs(counts) do
         assert(count == 0, "missing compiled source: " .. path)
      end
   end
   return exports
end

return BUILD_SOURCES_loadModule()

-- EOF


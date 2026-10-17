-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Track a process lifetime without trusting a reused numeric identifier.
-- @return table: host identity operations.
local function IDENTITY_loadModule()
   local uv = require("luv")
   local host = uv.os_uname().sysname
   local exports = {}

   --- Read a Linux start token, rejecting dead and zombie processes.
   -- @param pid number: process identifier to inspect.
   -- @return string|nil: stable kernel identity while the process is alive.
   function exports.token(pid)
      if host == "Darwin" then
         return dofile("scripts/process/native/darwin.lua").identity(pid)
      end
      assert(host == "Linux", "process tokens require a POSIX host")
      local file = io.open("/proc/" .. tostring(pid) .. "/stat", "r")
      if not file then
         return nil
      end
      local line = file:read("*l")
      file:close()
      local fields = {}
      for value in (line:match("^%d+ %(.+%) (.*)$") or ""):gmatch("%S+") do
         fields[#fields + 1] = value
      end
      return fields[1] ~= "Z" and fields[1] ~= "X" and fields[20] or nil
   end
   return exports
end

return IDENTITY_loadModule()

-- EOF


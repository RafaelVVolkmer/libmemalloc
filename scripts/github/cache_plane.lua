-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Apply validated cache policy after the caller has prepared Lua.
-- @return nil: writes deterministic runner outputs and a redacted summary.
local function CACHE_PLANE_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local policy = dofile("scripts/github/lib/cache_plane.lua")
   local settings = {}

   for _, name in ipairs(policy.environment) do
      settings[name] = os.getenv(name) or ""
   end

   local result =
      policy.resolve(settings, artifacts.platform.command_exists("aws"))
   local names = {
      "enabled",
      "bazelrc",
      "bazel_write",
      "shared_cache_enabled",
      "shared_cache_write",
      "registry_enabled",
      "proxy_enabled",
   }
   local rows = {}
   local summary = {
      "### Libmemalloc CI cache plane",
      "",
      "| Service | State |",
      "| --- | --- |",
   }

   for _, name in ipairs(names) do
      rows[#rows + 1] = name .. "=" .. tostring(result[name])
      if name ~= "bazelrc" then
         summary[#summary + 1] = "| "
            .. name
            .. " | "
            .. tostring(result[name])
            .. " |"
      end
   end

   summary[#summary + 1] = "\nMode: `"
      .. result.mode
      .. "`. Endpoints are intentionally not logged."
   artifacts.write(result.bazelrc, result.contents)
   local output = assert(io.open(assert(os.getenv("GITHUB_OUTPUT")), "a"))

   assert(output:write(table.concat(rows, "\n") .. "\n"))
   assert(output:close())
   local report = assert(io.open(assert(os.getenv("GITHUB_STEP_SUMMARY")), "a"))

   assert(report:write(table.concat(summary, "\n") .. "\n"))
   assert(report:close())
end

return CACHE_PLANE_main()

-- EOF


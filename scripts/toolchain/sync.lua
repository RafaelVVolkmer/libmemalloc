-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Generate native manifests and Action pins from the central toolchain lock.
-- @return nil: no values.
local function SYNC_main()
   assert(
      #arg == 0 or (#arg == 1 and arg[1] == "--check"),
      "usage: sync.lua [--check]"
   )
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local git = dofile("scripts/lib/git.lua").new(artifacts.platform, ".")
   local manifests = dofile("scripts/toolchain/lib/manifests.lua")
   local lock = dofile("scripts/toolchain/lib/lock.lua").load()
   local outputs =
      manifests.outputs(lock, artifacts.read, assert(git.working_files()))
   local names, changed = {}, 0

   for path in pairs(outputs) do
      names[#names + 1] = path
   end

   table.sort(names)

   --- Compare each projection and write only changed bytes.
   -- @return nil: no values.
   local function sync_outputs()
      for _, path in ipairs(names) do
         local current = artifacts.exists(path) and artifacts.read(path) or ""
         if current ~= outputs[path] then
            changed = changed + 1
            if arg[1] == "--check" then
               io.stderr:write("Toolchain projection differs: " .. path .. "\n")
            else
               artifacts.write(path, outputs[path])
               print("Updated " .. path)
            end
         end
      end
   end

   sync_outputs()
   assert(
      arg[1] ~= "--check" or changed == 0,
      "run lua scripts/toolchain/sync.lua"
   )
   print("Toolchain projections: " .. changed .. " differences.")
   dofile("scripts/lib/change.lua").record(arg[1] ~= "--check" and changed > 0)
end

return SYNC_main()

-- EOF


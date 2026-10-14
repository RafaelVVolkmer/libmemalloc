-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Clean disposable build metadata, caches and temporary files in this
--- checkout.
-- @return nil: no values.
local function CLEAN_main()
   dofile("scripts/workspace/lib/lock.lua").guard("exclusive")
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local cleaner = dofile("scripts/workspace/lib/clean.lua")
   local options = artifacts.options(arg, { scope = true, ["dry-run"] = true })

   assert(
      not options["dry-run"] or options["dry-run"] == true,
      "--dry-run takes no value"
   )
   local plan = cleaner.repository_plan(options.scope or "all")
   local preserve = os.getenv("LIBMEMALLOC_TASK_DIRECTORY")
   local removed = 0
   if not options["dry-run"] then
      removed = cleaner.execute(plan, preserve)
   end

   dofile("scripts/lib/change.lua").record(removed > 0)
   print(artifacts.text_json({
      scope = options.scope or "all",
      dry_run = options["dry-run"] == true,
      paths = artifacts.array(plan.paths),
      removed_entries = removed,
      preserved_task_directory = preserve,
   }))
end

return CLEAN_main()

-- EOF


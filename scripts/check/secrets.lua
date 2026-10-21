-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Scan a disposable snapshot of Git sources, including new working files.
-- The hosted history scan remains a separate control.

--- Retain scanner failures while always removing the private source snapshot.
-- @return nil: no values.
local function SECRETS_main()
   assert(#arg == 0, "secrets accepts no arguments")
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local sources = dofile("scripts/check/lib/sources.lua")
   local directory = artifacts.platform.temporary_directory("tmp")
   --- Scan the source snapshot while preserving cleanup on scanner failure.
   -- @return nil: no values.
   local ok, failure = xpcall(function()
      local count = sources.snapshot(".", directory)

      assert(count > 0, "empty source inventory")
      artifacts.run({
         "gitleaks",
         "dir",
         "--no-banner",
         "--redact",
         "--config",
         "tools/security/git/gitleaks.toml",
         directory,
      })
      print(string.format("Gitleaks: %d source files scanned.", count))
   end, debug.traceback)

   artifacts.platform.remove_temporary_directory(directory)
   assert(ok, failure)
end

return SECRETS_main()

-- EOF


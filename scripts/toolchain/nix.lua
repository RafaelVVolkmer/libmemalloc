-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Prepare the project's Nix shell and Python tools when Nix is available.
-- @return nil: no values.
local function NIX_main()
   dofile("scripts/workspace/lib/lock.lua").guard("shared")
   assert(#arg == 0, "nix-setup accepts no arguments")
   local artifacts = dofile("scripts/lib/artifacts.lua")
   if not artifacts.platform.command_exists("nix") then
      print("Nix setup skipped: nix is not available.")
      dofile("scripts/lib/change.lua").record(false)

      return
   end

   artifacts.mkdir(".cache/tools/nix")
   artifacts.run({
      "nix",
      "--extra-experimental-features",
      "nix-command flakes",
      "develop",
      "--no-update-lock-file",
      "--profile",
      ".cache/tools/nix/profile",
      "./tools/nix#default",
      "--command",
      "lua",
      "scripts/toolchain/python.lua",
      "--groups=automation,quality,python-lint",
      "--directory=.cache/tools/python-dev",
   })
   print("Nix environment prepared. Enter with nix develop ./tools/nix.")
   dofile("scripts/lib/change.lua").record(true)
end

return NIX_main()

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Install checksum-verified C analyzers into the repository cache.
-- Part of versioned tool identities and host provisioning.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_toolchain_install_c_scanners_main()
   dofile("scripts/workspace/lib/lock.lua").guard("shared")
   local release = dofile("scripts/lib/artifacts.lua")
   local tools = dofile("scripts/toolchain/lib/lock.lua").load()
   local options = release.options(arg, { cppcheck = true, flawfinder = true })
   local root = release.output({ "git", "rev-parse", "--show-toplevel" })
   local destination = root .. "/.cache/tools/c-scanners"

   for _, name in ipairs({ "cppcheck", "flawfinder" }) do
      local archive = assert(options[name], "missing --" .. name)

      assert(
         release.digest(archive) == tools[name].sha256,
         name .. " digest mismatch"
      )
   end

   release.mkdir(destination .. "/source")

   release.run({
      "tar",
      "-xzf",
      options.cppcheck,
      "--strip-components=1",
      "-C",
      destination .. "/source",
   })

   release.run({
      "cmake",
      "-S",
      destination .. "/source",
      "-B",
      destination .. "/build",
      "-DCMAKE_BUILD_TYPE=Release",
      "-DBUILD_GUI=OFF",
      "-DUSE_MATCHCOMPILER=OFF",
      "-DCMAKE_INSTALL_PREFIX=" .. destination .. "/cppcheck",
   })

   release.run({
      "cmake",
      "--build",
      destination .. "/build",
      "--parallel",
      "2",
   })

   release.run({ "cmake", "--install", destination .. "/build" })

   release.run({ "python3", "-m", "venv", destination .. "/flawfinder" })

   release.run({
      destination .. "/flawfinder/bin/pip",
      "install",
      "--no-index",
      "--no-deps",
      "--disable-pip-version-check",
      options.flawfinder,
   })
   dofile("scripts/lib/change.lua").record(true)
end

return scripts_toolchain_install_c_scanners_main()

-- EOF


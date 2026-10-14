-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Install selected analysis tools; policy versions live only in the TOML lock.
-- Part of versioned tool identities and host provisioning.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_toolchain_install_c_analysis_main()
   dofile("scripts/workspace/lib/lock.lua").guard("shared")
   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local tools = dofile("scripts/toolchain/lib/lock.lua").load()
   local options = artifact_io.options(arg, { group = true })
   local group = assert(options.group, "--group is required")
   local policy = dofile("tools/analysis/c/provision.lua")
   local selected = assert(policy.groups[group], "unknown analysis tool group")

   artifact_io.run({ "sudo", "apt-get", "update", "-qq" })

   local install = {
      "sudo",
      "apt-get",
      "install",
      "-y",
      "--no-install-recommends",
      "python3-venv",
   }

   for _, package in ipairs(selected.packages) do
      install[#install + 1] = package.name
         .. (package.lock and tools[package.lock].version or "")
   end

   artifact_io.run(install)

   local directory = policy.directory_prefix .. group

   artifact_io.run({ "python3", "-m", "venv", directory })

   local pip =
      { directory .. "/bin/pip", "install", "--disable-pip-version-check" }

   for _, name in ipairs(selected.python) do
      pip[#pip + 1] = name .. "==" .. tools[name].version
   end

   if #selected.python > 0 then
      artifact_io.run(pip)

      artifact_io.write(
         directory .. "/dependencies.txt",
         artifact_io.output({ directory .. "/bin/pip", "freeze", "--all" })
            .. "\n"
      )
   end

   local github_path = os.getenv("GITHUB_PATH")

   if github_path then
      local root = artifact_io.output({ "git", "rev-parse", "--show-toplevel" })
      local file = assert(io.open(github_path, "a"))

      assert(file:write(root .. "/" .. directory .. "/bin\n"))
      assert(file:close())
   end

   dofile("scripts/lib/change.lua").record(true)
end

return scripts_toolchain_install_c_analysis_main()

-- EOF


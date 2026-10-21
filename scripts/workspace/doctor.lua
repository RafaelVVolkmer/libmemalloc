-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Diagnose automation prerequisites without changing the checkout.
-- Reports managed and selected tools; domain campaigns keep their own checks.

--- Print actionable dependency failures for the local automation profile.
-- @return nil: no values.
local function DOCTOR_main()
   local DOCTOR_ANSIBLE_MIN_MINOR = 16
   local DOCTOR_ANSIBLE_MAX_MINOR_EXCLUSIVE = 22

   local options =
      dofile("scripts/lib/artifacts.lua").options(arg, { profile = true })

   if options.profile then
      local versions = dofile("scripts/toolchain/lib/versions.lua")
      local platform = dofile("scripts/lib/platform.lua")
      local lock = dofile("scripts/toolchain/lib/lock.lua").load()

      assert(
         versions.check(platform, lock, options.profile),
         "tool versions differ from lock"
      )

      return
   end

   local platform = dofile("scripts/lib/platform.lua")
   local runtime = dofile("scripts/workspace/lib/runtime.lua")
   local lock = dofile("scripts/toolchain/lib/lock.lua").load()
   local failed = 0

   --- Report a dependency result while collecting all missing prerequisites.
   -- @param name string: entry or operation name to resolve.
   -- @param passed boolean: success status produced by the operation.
   -- @param detail any: detail supplied to this operation.
   -- @return nil: no values.
   local function report(name, passed, detail)
      print((passed and "OK " or "MISSING ") .. name .. ": " .. detail)
      if not passed then
         failed = failed + 1
      end
   end

   local interpreter = runtime.resolve("lua", "LIBMEMALLOC_LUA", "lua")
   local version = interpreter
      and platform.command_output({
         interpreter,
         "-e",
         "print(_VERSION); print(require('luv').version_string())",
      })

   report(
      "Lua and luv",
      version ~= nil,
      version and version:gsub("\n", " ") or "run ansible-playbook playbook.yml"
   )

   --- Accept the native playbook range and retain the CI pin in diagnostics.
   -- @return nil: no values.
   local function doctor_checkController()
      local controller =
         runtime.resolve("ansible", "LIBMEMALLOC_ANSIBLE", "ansible-playbook")
      local identity = controller
         and platform.command_output({ controller, "--version" })
      local major, minor = (identity or ""):match("%[core (%d+)%.(%d+)")
      local compatible = major == "2"
         and tonumber(minor) >= DOCTOR_ANSIBLE_MIN_MINOR
         and tonumber(minor) < DOCTOR_ANSIBLE_MAX_MINOR_EXCLUSIVE

      report(
         "Ansible (native 2.16-2.21; CI " .. lock.ansible_core.version .. ")",
         compatible,
         controller or "on Ubuntu: sudo apt install ansible-core"
      )
   end

   doctor_checkController()

   for _, name in ipairs({
      "git",
      "jq",
      "sha256sum",
      "cmake",
      "cc",
      "c++",
      "gpg",
   }) do
      report(name, platform.command_exists(name), "required on host PATH")
   end

   print("Inspect hooks: ansible-playbook playbook.yml -e lma_task=status.")
   os.exit(failed == 0 and 0 or 1)
end

return DOCTOR_main()

-- EOF


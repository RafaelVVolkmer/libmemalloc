-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Activate or inspect versioned Git defaults for this checkout.
-- Part of workspace setup; preserves identity, keys and custom hook ownership.

--- Include the reviewed settings once and report their effective hooks path.
-- @return nil: no values.
local function HOOKS_main()
   local platform = dofile("scripts/lib/platform.lua")
   local action = arg[1] or "status"
   local actions =
      { status = true, install = true, repair = true, uninstall = true }

   assert(
      #arg <= 1 and actions[action],
      "expected status, install, repair or uninstall"
   )

   --- Read a configuration value without confusing absence with empty output.
   -- @param key string: record field or catalog key to select.
   -- @param local_only any: local only supplied to this operation.
   -- @return any: a configuration value without confusing absence with empty
   -- output.
   local function setting(key, local_only)
      local command = { "git", "config" }

      if local_only then
         command[#command + 1] = "--local"
         command[#command + 1] = "--no-includes"
      end

      command[#command + 1] = "--get"
      command[#command + 1] = key
      local value = platform.command_output(command)

      return value and value:gsub("[\r\n]+$", "") or nil
   end

   --- Remove only an exact value owned by this setup operation.
   -- @param key string: record field or catalog key to select.
   -- @param value any: input value; validation belongs to this operation’s
   -- contract.
   -- @return nil: no values.
   local function remove(key, value)
      if value then
         platform.command_succeeded_silent({
            "git",
            "config",
            "--local",
            "--fixed-value",
            "--unset-all",
            key,
            value,
         })
      end
   end

   local changed = false
   local expected = ".githooks"
   local current = setting("core.hooksPath")
   local local_hooks = setting("core.hooksPath", true)
   local root = assert(
      platform.command_output({ "git", "rev-parse", "--show-toplevel" })
   ):gsub("[\r\n]+$", "")
   local settings = root .. "/.gitconfig"
   local owned = setting("libmemalloc.managedConfig", true)
   local configured = platform.command_output({
      "git",
      "config",
      "--local",
      "--no-includes",
      "--get-all",
      "include.path",
   }) or ""
   local included = false

   for path in configured:gmatch("[^\r\n]+") do
      included = included or path == settings
   end

   --- Apply only the requested repository Git configuration transition.
   -- @return nil: no values.
   local function hooks_applyAction()
      if action == "uninstall" then
         --- Remove only repository-owned includes and hook configuration.
         -- @return nil: no values.
         local function hooks_removeSettings()
            changed = owned ~= nil or included or local_hooks == expected
            remove("include.path", owned or (included and settings or nil))
            remove("libmemalloc.managedConfig", owned)
            if local_hooks == expected then
               remove("core.hooksPath", expected)
            end

            included = false
         end

         hooks_removeSettings()
      elseif action == "install" or action == "repair" then
         --- Preserve custom hooks and require repair for a moved checkout.
         -- @return nil: no values.
         local function hooks_validateOwnership()
            assert(
               not local_hooks or local_hooks == expected,
               "custom local hooks path already configured: "
                  .. tostring(local_hooks)
            )
            assert(
               not current or current == expected,
               "custom hooks path already configured: " .. tostring(current)
            )
            assert(
               action == "repair" or not owned or owned == settings,
               "checkout moved: use the setup-repair task"
            )
         end

         hooks_validateOwnership()

         local file = assert(io.open(settings, "rb"))

         assert(file:close())

         changed = not included or owned ~= settings
         if owned and owned ~= settings then
            remove("include.path", owned)
         end

         if not included then
            platform.run({
               "git",
               "config",
               "--local",
               "--add",
               "include.path",
               settings,
            })
         end

         if owned ~= settings then
            platform.run({
               "git",
               "config",
               "--local",
               "libmemalloc.managedConfig",
               settings,
            })
         end

         included = true
      end
   end

   hooks_applyAction()
   dofile("scripts/lib/change.lua").record(changed)

   current = setting("core.hooksPath")

   print("Git configuration changed: " .. tostring(changed))
   print("Git hooks: " .. (current or "default .git/hooks"))
   print("Repository Git settings: " .. (included and settings or "inactive"))
end

return HOOKS_main()

-- EOF


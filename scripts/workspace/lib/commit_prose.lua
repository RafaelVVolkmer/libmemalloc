-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Run installed prose tools over a private commit-message copy.
-- Part of local hooks; missing tools warn, installed tools must pass.

--- Create the optional checker using the shared process implementation.
-- @return table: the optional checker using the shared process implementation.
local function COMMIT_PROSE_loadModule()
   local platform = dofile("scripts/lib/platform.lua")
   local configurations = {
      {
         "cspell",
         "tools/lint/spell/cspell/cspell.jsonc",
         "--config",
         "--no-progress",
         "--no-must-find-files",
      },
      { "codespell", "tools/lint/spell/codespell/.codespellrc", "--config" },
      {
         "typos",
         "tools/lint/spell/typos/typos.toml",
         "--config",
         "--isolated",
      },
      { "vale", "tools/lint/spell/vale/.vale.ini", "--config", "--no-global" },
      { "lychee", "tools/lint/spell/lychee/lychee.toml", "--config" },
   }

   --- Check prose without changing the user's commit-message file.
   -- @param message string: diagnostic text retained by this operation.
   -- @return boolean: check prose without changing the user's commit-message
   -- file.
   local function COMMIT_PROSE_check(message)
      local directory = platform.temporary_directory("tmp")
      local path = directory .. "/commit-message.md"
      local file = assert(io.open(path, "wb"))

      assert(file:write(message))
      assert(file:close())

      local passed = true

      --- Apply one prose scanner to the temporary commit-message source.
      -- @param config table: config supplied to this operation.
      -- @return nil: no values.
      local function commit_prose_runScanner(config)
         local name = config[1]
         local applicable = name ~= "lychee" or message:find("https?://")

         if applicable and not platform.command_exists(name) then
            io.stderr:write(
               "libmemalloc hook: optional tool missing: " .. name .. "\n"
            )
         elseif applicable then
            local settings = io.open(config[2], "rb")

            --- Require scanner settings and retain its diagnostics on failure.
            -- @return nil: no values.
            local function commit_prose_checkConfiguration()
               if not settings then
                  io.stderr:write(
                     "libmemalloc hook: missing " .. config[2] .. "\n"
                  )
                  passed = false
               else
                  settings:close()

                  local command = { name, config[3], config[2] }

                  for index = 4, #config do
                     command[#command + 1] = config[index]
                  end

                  local succeeded

                  if name == "cspell" or name == "lychee" then
                     -- The temporary copy lives under excluded .cache paths.
                     command[#command + 1] = name == "lychee" and "-"
                        or "stdin://commit-message.md"
                     local input_command = platform.join_command(command)
                        .. " < "
                        .. platform.shell_quote(path)

                     succeeded = platform.command_succeeded(input_command)
                  else
                     command[#command + 1] = path
                     succeeded = platform.command_succeeded(command)
                  end

                  if not succeeded then
                     passed = false
                  end
               end
            end

            commit_prose_checkConfiguration()
         end
      end

      for _, config in ipairs(configurations) do
         commit_prose_runScanner(config)
      end

      platform.remove_temporary_directory(directory)

      return passed
   end

   return { check = COMMIT_PROSE_check }
end

return COMMIT_PROSE_loadModule()

-- EOF


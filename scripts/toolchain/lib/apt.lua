-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Provision signed Ubuntu packages only after a complete index refresh.
-- @return table: bounded package and repository installation operations.
local function APT_loadModule()
   local exports = {}
   local attempts = 4

   --- Retry a complete command because HTTP 503 may exhaust APT acquisition.
   -- @param artifacts table: command execution ports.
   -- @param command table: literal command vector.
   -- @param phase string: operation named in retained diagnostics.
   -- @return nil: raises after the final unsuccessful attempt.
   local function apt_retry(artifacts, command, phase)
      for attempt = 1, attempts do
         print(string.format("APT %s: attempt %d/%d", phase, attempt, attempts))
         if artifacts.platform.command_succeeded(command) then
            return
         end
         assert(attempt < attempts, "APT " .. phase .. " failed after retries")
         artifacts.run({ "sleep", tostring(5 * 2 ^ (attempt - 1)) })
      end
   end

   --- Require signed, complete indexes and bounded package acquisition.
   -- @param artifacts table: command execution ports.
   -- @param arguments table: APT operation and package arguments.
   -- @param phase string: diagnostic phase name.
   -- @return nil: raises if acquisition or package installation fails.
   local function apt_run(artifacts, arguments, phase)
      local command = {
         "sudo",
         "apt-get",
         "-o",
         "Acquire::Retries=3",
         "-o",
         "Acquire::http::Timeout=30",
         "-o",
         "Acquire::https::Timeout=30",
         "-o",
         "APT::Update::Error-Mode=any",
      }
      for _, argument in ipairs(arguments) do
         command[#command + 1] = argument
      end
      apt_retry(artifacts, command, phase)
   end

   --- Register optional compiler sources without an unchecked implicit update.
   -- @param artifacts table: command execution ports.
   -- @param packages table: distribution package names or exact versions.
   -- @param repository string|nil: explicitly required signed compiler PPA.
   -- @return nil: installs packages or fails before dependent work can run.
   function exports.install(artifacts, packages, repository)
      if repository then
         apt_run(artifacts, {
            "install",
            "--yes",
            "--no-install-recommends",
            "software-properties-common",
         }, "repository prerequisites")
         apt_retry(artifacts, {
            "sudo",
            "add-apt-repository",
            "--yes",
            "--no-update",
            repository,
         }, "repository registration")
      end

      apt_run(artifacts, { "update" }, "index refresh")
      local arguments = { "install", "--yes", "--no-install-recommends" }
      for _, package in ipairs(packages) do
         arguments[#arguments + 1] = package
      end
      apt_run(artifacts, arguments, "package installation")
   end

   return exports
end

return APT_loadModule()

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Check commit links with real Lychee and deterministic offline fixtures.
-- Run from the repository root with Lychee installed.

--- Require excluded temporary messages to retain link validation.
-- @return nil: no values.
local function COMMIT_LINKS_TEST_main()
   local platform = dofile("scripts/lib/platform.lua")
   local artifacts = dofile("scripts/lib/artifacts.lua")

   assert(platform.command_exists("lychee"), "Lychee is required")
   local directory = platform.temporary_directory("tests")
   local target = directory .. "/existing.txt"
   local calls = 0
   local fixture_platform = setmetatable({
      --- Isolate link validation from optional spelling tools.
      -- @param name string: entry or operation name to resolve.
      -- @return boolean: isolate link validation from optional spelling tools.
      command_exists = function(name)
         return name == "lychee"
      end,
      --- Retain the production configuration and avoid network dependencies.
      -- @param command table: executable and literal command arguments.
      -- @return any: retain the production configuration and avoid network
      -- dependencies.
      join_command = function(command)
         table.insert(command, 2, "--offline")

         return platform.join_command(command)
      end,
      --- Run the actual scanner and retain its success or failure.
      -- @param command table: executable and literal command arguments.
      -- @return any: run the actual scanner and retain its success or failure.
      command_succeeded = function(command)
         calls = calls + 1

         return platform.command_succeeded(command)
      end,
   }, { __index = platform })
   local environment = setmetatable({
      --- Inject only the scanner environment into the production module.
      -- @param path string: filesystem path selected by the caller.
      -- @return any: inject only the scanner environment into the production
      -- module.
      dofile = function(path)
         assert(path == "scripts/lib/platform.lua", "unexpected module")

         return fixture_platform
      end,
   }, { __index = { assert = assert, io = io, ipairs = ipairs } })
   local prose = assert(
      loadfile("scripts/workspace/lib/commit_prose.lua", "t", environment)
   )()
   local signoff = "\nSigned-off-by: Test User <test@example.org>\n"

   --- Keep HTTP detection active while checking local targets offline.
   -- @param scheme any: scheme supplied to this operation.
   -- @param path string: filesystem path selected by the caller.
   -- @return string: keep HTTP detection active while checking local targets
   -- offline.
   local function message(scheme, path)
      return "docs: explain link validation\n\nRefs: "
         .. scheme
         .. "://example.org\nRefs: file://"
         .. path
         .. signoff
   end

   --- Exercise real link outcomes while retaining fixture cleanup on failure.
   -- @return nil: no values.
   local passed, failure = xpcall(function()
      artifacts.write(target, "fixture\n")
      assert(prose.check(message("https", target)), "existing link rejected")
      assert(
         not prose.check(message("http", target .. ".missing")),
         "broken link accepted: the temporary message was skipped"
      )
      assert(calls == 2, "messages with links must invoke Lychee")
      assert(prose.check("docs: explain validation\n" .. signoff))
      assert(calls == 2, "message without links invoked Lychee")
   end, debug.traceback)

   platform.remove_temporary_directory(directory)
   assert(passed, failure)
   print("Commit links: valid, broken and absent links checked.")
end

return COMMIT_LINKS_TEST_main()

-- EOF


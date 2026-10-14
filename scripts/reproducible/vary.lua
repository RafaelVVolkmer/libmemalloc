-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Run an explicit environment campaign and preserve the tool's full evidence.
-- Part of independent reconstruction and byte-comparison campaigns.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_reproducible_vary_main()
   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local policy = dofile("tools/reproducible/policy.lua")
   local options =
      artifact_io.options(arg, { profile = true, source = true, output = true })
   local profile = assert(options.profile, "--profile is required")
   local variations =
      assert(policy.variations[profile], "unknown variation profile")
   local source = assert(options.source, "--source is required")
   local output = assert(options.output, "--output is required")

   for _, path in ipairs({ source, output }) do
      artifact_io.safe_path(path)
      assert(path:match("^%.cache/"), "paths must stay in .cache")
   end

   assert(not artifact_io.exists(output), "campaign output must be fresh")

   artifact_io.mkdir(output)

   local result = {
      schema = policy.schema,
      scope = policy.scope,
      profile = profile,
      variations = variations,
      product_qualified = false,
      state = "INFRA_ERROR",
   }
   local success, message = xpcall(
      --- Run the declared environment variations and retain reconstruction
      -- evidence.
      -- @return nil: no values.
      function()
         if profile == "filesystem" then
            artifact_io.run({ "test", "-c", "/dev/fuse" })
         end

         local command = {
            "reprotest",
            "--variations=" .. variations,
            "--store-dir=" .. output .. "/builds",
            "--source-root=" .. source,
            "lua scripts/reproducible/build.lua",
            "payload/*.tar.gz",
            "--",
            "null",
         }
         local log = output .. "/reprotest.log"
         local invocation = artifact_io.platform.join_command(command)
            .. " >"
            .. artifact_io.platform.shell_quote(log)
            .. " 2>&1"

         assert(
            artifact_io.platform.command_succeeded(invocation),
            "reprotest failed: " .. log
         )
      end,
      debug.traceback
   )

   result.state = success and "PASS" or "FAIL"
   result.detail = success and "Declared environment variations passed."
      or message
   artifact_io.document(output .. "/result.json", result)
   assert(success, message)

   print("reprotest " .. profile .. ": PASS")
end

return scripts_reproducible_vary_main()

-- EOF


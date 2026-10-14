-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Exercise central projections, rejected drift and installer argv boundaries.
-- @return nil: no values.
local function MANIFESTS_TEST_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local manifests = dofile("scripts/toolchain/lib/manifests.lua")
   local lock = dofile("scripts/toolchain/lib/lock.lua").load()
   local policy = dofile("tools/toolchain/manifests.lua")
   local primitives = {
      assert = assert,
      ipairs = ipairs,
      pairs = pairs,
      next = next,
      table = table,
      type = type,
      tostring = tostring,
      print = print,
      string = string,
      error = error,
   }

   --- Require every projected identity to react to a central edit.
   -- @return nil: no values.
   local function manifests_test_templates()
      for path, template in pairs(policy.templates) do
         local source = artifacts.read("tools/toolchain/templates/" .. template)
         local expected = manifests.render(source, lock)

         assert(expected == artifacts.read(path), "projection drift: " .. path)
         for name, field in source:gmatch("@([%w_]+)%.([%w_]+)@") do
            local original = lock[name][field]

            lock[name][field] = "changed-identity"
            assert(
               manifests.render(source, lock) ~= expected,
               "ignored central edit"
            )
            lock[name][field] = original
         end
      end

      assert(
         not pcall(manifests.render, "@missing.version@", lock),
         "unknown tool accepted"
      )
      assert(
         not pcall(manifests.render, "@lua.missing@", lock),
         "unknown field accepted"
      )
      local workflow = "uses: github/codeql-action/upload-sarif@old # v0\n"
      local generated = manifests.workflow(workflow, lock)

      assert(generated:find(lock.codeql_action.revision, 1, true))
      assert(
         manifests.workflow(generated, lock) == generated,
         "non-idempotent projection"
      )
      assert(
         not pcall(manifests.workflow, "uses: unknown/action@v1\n", lock),
         "unknown action accepted"
      )
      assert(
         not pcall(manifests.workflow, 'uses: "unknown/action@v1"\n', lock),
         "quoted unknown action accepted"
      )
      assert(
         not pcall(manifests.workflow, "uses: actions/checkout\n", lock),
         "missing action revision accepted"
      )
      assert(
         manifests
            .workflow('uses: "actions/checkout@old"\n', lock)
            :find(lock.checkout_action.revision, 1, true)
      )
      assert(
         manifests.workflow("uses: ./.github/actions/setup-lua\n", lock)
            == "uses: ./.github/actions/setup-lua\n",
         "local action was changed"
      )
   end

   --- Verify check mode rejects drift without mutating the checkout.
   -- @return nil: no values.
   local function manifests_test_check()
      local writes, drift = 0, false
      local fake = setmetatable({}, { __index = artifacts })

      --- Inject drift into one generated manifest while reading real templates.
      -- @param path string: filesystem path selected by the caller.
      -- @return any: inject drift into one generated manifest while reading
      -- real templates.
      fake.read = function(path)
         local contents = artifacts.read(path)

         return drift
               and path == "tools/python/pyproject.toml"
               and (contents .. "# stale\n")
            or contents
      end
      --- Count attempted writes; check mode must keep this count at zero.
      -- @return nil: no values.
      fake.write = function()
         writes = writes + 1
      end
      local environment = setmetatable({
         arg = { "--check" },
         --- Discard command progress so assertions own the test output.
         -- @return nil: no values.
         print = function() end,
         --- Discard expected drift diagnostics in the isolated command fixture.
         -- @return nil: no values.
         io = { stderr = { write = function() end } },
         --- Replace only locking and artifact ports; keep policy loading real.
         -- @param path string: filesystem path selected by the caller.
         -- @return any: replace only locking and artifact ports; keep policy
         -- loading real.
         dofile = function(path)
            if path == "scripts/workspace/lib/lock.lua" then
               --- Omit repository locking for this in-memory command fixture.
               -- @return nil: no values.
               return { guard = function() end }
            end

            return path == "scripts/lib/artifacts.lua" and fake or dofile(path)
         end,
      }, { __index = primitives })
      local command =
         assert(loadfile("scripts/toolchain/sync.lua", "t", environment))

      command()
      drift = true
      assert(not pcall(command), "check mode accepted edited manifest")
      assert(writes == 0, "check mode wrote files")
      environment.arg = {}
      command()
      assert(writes == 1, "sync did not repair exactly the stale projection")
   end

   manifests_test_templates()
   manifests_test_check()
   print("Tool manifests: projections and drift rejection passed.")
end

return MANIFESTS_TEST_main()

-- EOF


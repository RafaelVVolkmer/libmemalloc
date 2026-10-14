-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Verify the isolated behavior owned by this suite.
-- @return nil: no values.
local function GIT_POLICY_TEST_main()
   local policy = dofile("scripts/workspace/lib/git_policy.lua")
   local valid_branches = {
      "main",
      "develop",
      "feature/gc-layout",
      "release/v0.2.0",
      "hotfix/v0.2.1",
      "support/v1.x",
      "support/v1.2.x",
      "support/v1.2.3",
   }
   local invalid_branches = {
      "Feature/name",
      "feature/-name",
      "feature/name-",
      "feature/a--b",
      "feature/a/b",
      "release/0.2.0",
      "release/v01.2.3",
      "support/v01.x",
   }

   for _, branch in ipairs(valid_branches) do
      assert(policy.branch(branch), branch)
   end

   for _, branch in ipairs(invalid_branches) do
      assert(not policy.branch(branch), branch)
   end

   for _, tag in ipairs({ "v1.2.3", "v1.2.3-rc.1", "v1.2.3+build.01" }) do
      assert(policy.tag(tag), tag)
   end

   for _, tag in ipairs({ "1.2.3", "v01.2.3", "v1.2.3-01", "v1.2.3+" }) do
      assert(not policy.tag(tag), tag)
   end

   local object = string.rep("a", 40)
   local previous = string.rep("b", 40)
   local zero = string.rep("0", 40)

   --- Encode one Git pre-push record with caller-selected object identities.
   -- @param target any: selected target configuration or path.
   -- @param current any: current supplied to this operation.
   -- @param old any: old supplied to this operation.
   -- @return string: one Git pre-push record with caller-selected object
   -- identities.
   local function record(target, current, old)
      return "refs/heads/main " .. current .. " " .. target .. " " .. old
   end

   assert(not policy.record("malformed input"), "malformed record accepted")
   assert(
      not policy.record(record("refs/heads/main", "--help", zero)),
      "option-shaped object accepted"
   )
   assert(
      policy.record(
         record("refs/heads/main", string.rep("a", 64), string.rep("0", 64))
      )
   )
   assert(
      not policy.reference(
         assert(policy.record(record("refs/tags/v1.2.3", object, previous)))
      ),
      "published tag replacement accepted"
   )
   assert(
      not policy.reference(
         assert(policy.record(record("refs/tags/v1.2.3", zero, previous)))
      ),
      "published tag deletion accepted"
   )
   assert(
      policy.reference(
         assert(policy.record(record("refs/heads/legacy", zero, previous)))
      ),
      "published tag deletion accepted"
   )

   print("Git reference policies passed.")
end

return GIT_POLICY_TEST_main()

-- EOF


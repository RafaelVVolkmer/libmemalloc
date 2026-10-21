-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Mutation tests for specification identity, scope and evidence boundaries.
-- @return nil: no values.
local function SDD_TEST_main()
   local policy = dofile("scripts/check/lib/sdd.lua")
   local count = 0
   local inventory = {
      cases = 1,
      controls = { ["LMA-CORE-001"] = { 1, 0 } },
   }
   local valid = [[
<a id="lma-core-001"></a>
## LMA-CORE-001: Owned resources

**Phase:** P0. **Status:** PROPOSED.

**M0:** REQUIRED. **G0:** REQUIRED.

<a id="lma-core-001-r01"></a> **LMA-CORE-001-R01.** MUST preserve bytes.

<a id="lma-test-case-0001"></a>
### LMA-TEST-CASE-0001

**Status:** PLANNED.

**Control:** [LMA-CORE-001](spec.md#lma-core-001).

**Verification:** SCENARIO.

**Requirements:**
[LMA-CORE-001-R01](spec.md#lma-core-001-r01)

**Precondition/capacity:** A valid allocation with known bytes.

**Procedure:** Fail the replacement reservation and inspect the old bytes.

**Acceptance oracle:** Every old byte equals its pre-call snapshot.

**Evidence:** Before/after byte snapshots and the reservation failure event.

]]

   --- Assert rejection reason, not only a nonzero failure count.
   -- @param source any: source value inspected by this operation.
   -- @param expected any: expected reference value used by this check.
   -- @return nil: no values.
   local function check(source, expected)
      local failures = policy.check({ ["spec.md"] = source }, inventory)
      local diagnostic = table.concat(failures, "\n")
      if expected then
         assert(diagnostic:find(expected, 1, true), diagnostic)
      else
         assert(#failures == 0, diagnostic)
      end

      count = count + 1
   end

   --- Replace one literal fragment; fail if the mutation was not applied.
   -- @param old any: old supplied to this operation.
   -- @param replacement any: replacement supplied to this operation.
   -- @param expected any: expected reference value used by this check.
   -- @return nil: no values.
   local function mutate(old, replacement, expected)
      local first, last = assert(valid:find(old, 1, true))

      check(
         valid:sub(1, first - 1) .. replacement .. valid:sub(last + 1),
         expected
      )
   end

   check(valid)
   check(valid .. '<a id="lma-core-001"></a>\n', "duplicate anchor")
   check(valid .. "\n## LMA-CORE-001: Duplicate\n", "duplicate definition")
   mutate('<a id="lma-core-001-r01"></a>', "", "missing anchor")
   mutate(
      "spec.md#lma-core-001-r01",
      "other.md#lma-core-001-r01",
      "wrong target"
   )
   mutate("[LMA-CORE-001-R01]", "[LMA-CORE-001-R99]", "unknown linked ID")
   mutate("**Phase:** P0", "**Phase:** P9", "invalid or missing Phase")
   mutate("**Phase:** P0", "", "invalid or missing Phase")
   mutate("**M0:** REQUIRED", "**M0:** MAYBE", "invalid or missing M0")
   mutate("**G0:** REQUIRED", "", "invalid or missing G0")
   mutate(
      "**G0:** REQUIRED",
      "**G0:** DEFERRED",
      "G0 must retain required M0 controls"
   )
   mutate(
      "**Status:** PLANNED",
      "**Status:** PASS",
      "invalid or missing Status"
   )
   mutate(
      "**Status:** PROPOSED",
      "**Status:** APPROVED",
      "invalid or missing Status"
   )
   mutate(
      "**Verification:** SCENARIO",
      "**Verification:** EXECUTED",
      "invalid or missing Verification"
   )
   mutate("**Control:**", "**Owner:**", "missing Control link")
   mutate("**Requirements:**", "**References:**", "no valid individual")
   mutate("**Precondition/capacity:**", "**Setup:**", "Precondition/capacity")
   mutate("**Procedure:**", "**Steps:**", "missing or empty Procedure")
   mutate("**Evidence:**", "**Files:**", "missing or empty Evidence")
   mutate("**Acceptance oracle:**", "**Result:**", "missing acceptance oracle")
   mutate(
      "Every old byte equals its pre-call snapshot.",
      "requirements and invariants of linked control remain satisfied.",
      "generic acceptance oracle"
   )
   mutate(
      "Every old byte equals its pre-call snapshot.",
      "the properties explained in the scenario remain satisfied.",
      "generic acceptance oracle"
   )
   mutate(
      "**LMA-CORE-001-R01.**",
      "**LMA-CORE-002-R01.**",
      "missing or foreign owner control"
   )
   mutate(
      "### LMA-TEST-CASE-0001",
      "### LMA-TEST-CASE-0002",
      "published case removed"
   )
   mutate(
      "## LMA-CORE-001: Owned resources",
      "## Unidentified resources",
      "published control removed"
   )
   mutate(
      "[LMA-CORE-001-R01](spec.md#lma-core-001-r01)",
      "[LMA-CORE-001-R01](spec.md#lma-core-001-r01)\n"
         .. "[LMA-CORE-001-R01](spec.md#lma-core-001-r01)",
      "duplicate requirement"
   )
   check(valid .. '\n<a id="lma-core-001-r99"></a>\n', "orphan ID anchor")
   check(
      valid
         .. '\n<a id="lma-core-001-r02"></a> '
         .. "**LMA-CORE-001-R02.** MUST keep a bounded reserve.\n\n",
      "requirement has no planned verification"
   )
   mutate(
      "**Verification:** SCENARIO",
      "**Verification:** REVIEW",
      "missing review clause"
   )

   local review = valid:gsub("SCENARIO", "REVIEW")
      .. "\n- `LMA-CORE-001-R01`: MUST preserve bytes.\n\n"

   check(review)
   check(
      review:gsub("`: MUST preserve bytes", "`: MUST discard bytes"),
      "stale review clause"
   )
   check(valid .. "\n```md\n" .. valid .. "\n```\n")
   check(valid .. "\n<!--\n" .. valid .. "\n-->\n")
   check(valid .. "\n~~~~md\n```md\n" .. valid .. "\n```\n~~~~\n")
   check("", "published control removed")

   local documents = {}

   for _, path in ipairs(dofile("tools/specs/catalog.lua")) do
      local file = assert(io.open(path, "rb"))

      documents[path] = assert(file:read("a"))
      assert(file:close())
   end

   local failures, counts =
      policy.check(documents, dofile("tools/specs/ids.lua"))

   assert(#failures == 0, table.concat(failures, "\n"))
   assert(
      counts.coverage.scenario > 0 and counts.coverage.review_only > 0,
      "scenario and review-only allocations must remain distinct"
   )
   count = count + 1
   print(string.format("SDD: %d plan and mutation checks passed.", count))
end

return SDD_TEST_main()

-- EOF


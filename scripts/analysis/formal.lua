-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Run bounded proof campaigns and check that each C source has a disposition.
-- Positive/negative probes qualify the executor only; they prove no allocator.
-- Part of C analysis; gates.json declares campaigns, bounds and exclusions.

--- Validate the proof executor, then require complete source accountability.
-- @return nil: no values.
local function FORMAL_main()
   local FORMAL_MS_PER_SECOND = 1000
   local FORMAL_PROPERTY_FAILURE_EXIT = 10

   local io_tools = dofile("scripts/lib/artifacts.lua")
   local execution = dofile("scripts/process/lib/exec.lua")
   local manifest = "tools/analysis/c/gates.json"
   local directory = ".cache/ci/c-analysis/formal"
   local cbmc = os.getenv("LIBMEMALLOC_CBMC") or "cbmc"
   local unwind = io_tools.query(manifest, ".formal.unwind")
   local timeout = tonumber(io_tools.query(manifest, ".formal.timeout_seconds"))
   local report = {
      schema = 1,
      campaigns = io_tools.array(),
      excluded = io_tools.array(),
      product_state = "NOT_APPLICABLE",
      manifest_sha256 = io_tools.digest(manifest),
   }

   assert(timeout and timeout > 0, "Invalid proof timeout")
   assert(
      unwind:match("^%d+$") and tonumber(unwind) > 0,
      "Invalid unwind bound"
   )
   io_tools.mkdir(directory)

   --- Require actual property results, not just an exit code or empty report.
   -- @param name string: entry or operation name to resolve.
   -- @param sources any: sources supplied to this operation.
   -- @param expected any: expected reference value used by this check.
   -- @return nil: no values.
   local function prove(name, sources, expected)
      local command = {
         cbmc,
         "--json-ui",
         "--bounds-check",
         "--pointer-check",
         "--signed-overflow-check",
         "--unwinding-assertions",
         "--unwind",
         unwind,
      }

      for _, source in ipairs(sources) do
         command[#command + 1] = source
      end

      local result =
         execution.run(command, { timeout_ms = timeout * FORMAL_MS_PER_SECOND })
      local path = directory .. "/" .. name .. ".json"

      io_tools.write(path, result.stdout)
      io_tools.write(directory .. "/" .. name .. ".stderr", result.stderr)
      assert(result.exit_code == expected, "CBMC outcome mismatch: " .. name)
      local count =
         tonumber(io_tools.query(path, "[.[] | .result[]?] | length"))
      local failures = tonumber(
         io_tools.query(
            path,
            '[.[] | .result[]? | select(.status != "SUCCESS")] | length'
         )
      )

      assert(count and count > 0, "CBMC produced no properties")
      assert(
         (expected == 0 and failures == 0)
            or (expected == FORMAL_PROPERTY_FAILURE_EXIT and failures > 0),
         "CBMC property mismatch"
      )
   end

   --- Run both proof fixtures while retaining a report on tool failure.
   -- @return nil: no values.
   local success, message = xpcall(function()
      report.version = io_tools.output({ cbmc, "--version" })
      local positive = directory .. "/positive.c"
      local negative = directory .. "/negative.c"

      io_tools.write(
         positive,
         "#include <assert.h>\nunsigned nondet_uint(void);\n"
            .. "int main(void) { unsigned x = nondet_uint(); "
            .. "assert((x & 15u) <= 15u); return 0; }\n"
      )
      io_tools.write(
         negative,
         "#include <assert.h>\nint main(void) { assert(0); return 0; }\n"
      )
      prove("executor-positive", { positive }, 0)
      prove("executor-negative", { negative }, FORMAL_PROPERTY_FAILURE_EXIT)

      local covered = {}
      local count =
         tonumber(io_tools.query(manifest, ".formal.campaigns | length"))

      for index = 0, count - 1 do
         local base = ".formal.campaigns[" .. index .. "]"
         local name = io_tools.query(manifest, base .. ".id")

         assert(name:match("^[a-z][a-z0-9-]+$"), "Invalid campaign id")
         local sources = {}

         for source in
            io_tools.query(manifest, base .. ".sources[]"):gmatch("[^\n]+")
         do
            io_tools.safe_path(source)
            sources[#sources + 1] = source
            covered[source] = true
         end

         local harness = io_tools.query(manifest, base .. ".harness")

         io_tools.safe_path(harness)
         sources[#sources + 1] = harness
         prove(name, sources, 0)
         report.campaigns[#report.campaigns + 1] = { id = name, state = "PASS" }
      end

      if count > 0 then
         report.product_state = "PASS"
      end

      local inventory = io_tools.output({
         "git",
         "ls-files",
         "--cached",
         "--others",
         "--exclude-standard",
         "-z",
      })
      local roots = io_tools.query(manifest, ".source_roots[]")

      for source in inventory:gmatch("([^%z]+)%z") do
         for root in roots:gmatch("[^\n]+") do
            if
               source:sub(1, #root + 1) == root .. "/"
               and source:match("%.c$")
               and io_tools.exists(source)
               and not covered[source]
            then
               local reason = io_tools.query(
                  manifest,
                  ".formal.excluded_sources["
                     .. io_tools.json(source)
                     .. "] // empty"
               )

               assert(
                  #reason > 0,
                  "C source has no proof disposition: " .. source
               )
               report.excluded[#report.excluded + 1] = {
                  source = source,
                  reason = reason,
               }
               covered[source] = true
            end
         end
      end
   end, debug.traceback)

   report.executor_state = success and "PASS" or "FAIL"
   report.error = not success and tostring(message) or nil
   io_tools.document(directory .. "/report.json", report)
   assert(success, message)
   print("Formal executor: PASS; product proofs: " .. report.product_state)
end

return FORMAL_main()

-- EOF


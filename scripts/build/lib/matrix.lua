-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Pure planning and gate policy. No capability is inferred from an absent
-- result.
-- Part of build-matrix planning, execution and retained results.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_build_lib_matrix_loadModule()
   local MATRIX_ABI_WORD_BYTES = { [4] = true, [8] = true }

   local exports = {}
   local MATRIX_MAX_GROUPS = 256
   local levels = { pr = 1, integration = 2, nightly = 3, exhaustive = 4 }

   --- Reject malformed profiles, duplicate identifiers and unsupported build
   -- policy values.
   -- @param catalog table: reviewed catalog of supported entries.
   -- @return nil: no values.
   local function BUILD_MATRIX_validate(catalog)
      assert(catalog.schema == 1, "unsupported matrix schema")

      local seen = {}

      for _, profile in ipairs(catalog.profiles) do
         assert(
            profile.id:match("^[a-z][a-z0-9_-]+$") and not seen[profile.id],
            "duplicate or unsafe profile"
         )
         assert(levels[profile.tier], "unknown campaign tier")
         assert(
            profile.support == nil
               or profile.support == "required"
               or profile.support == "experimental",
            "unknown support policy"
         )
         assert(MATRIX_ABI_WORD_BYTES[profile.pointer], "invalid pointer model")
         assert(MATRIX_ABI_WORD_BYTES[profile.long], "invalid long model")
         assert(
            profile.endian == 0 or profile.endian == 1,
            "invalid byte order"
         )
         assert(#profile.c > 0, "empty C contract")

         local dialects = {}

         for _, dialect in ipairs(profile.c) do
            assert(
               catalog.c_versions[dialect] and not dialects[dialect],
               "invalid C dialect"
            )

            dialects[dialect] = true
         end

         seen[profile.id] = true
      end
   end

   exports.validate = BUILD_MATRIX_validate

   --- List the required C and C++ compatibility tests for one build case.
   -- @param catalog table: validated dialect policy.
   -- @return table: fresh, sorted test names owned by the caller.
   local function build_matrix_requiredTests(catalog)
      local names = { "c-api", "target-model" }

      for _, cpp in ipairs(catalog.cpp_requested) do
         names[#names + 1] = "cpp-" .. cpp
      end

      table.sort(names)

      return names
   end

   --- Copy a dense test list so cells retain independent mutable inventories.
   -- @param values table: ordered test names owned by the profile plan.
   -- @return table: fresh list containing the same names in the same order.
   local function build_matrix_copyTests(values)
      local result = {}

      for index, value in ipairs(values) do
         result[index] = value
      end

      return result
   end

   --- Expand the selected campaign into explicit profile and dialect cases.
   -- @param catalog table: reviewed catalog of supported entries.
   -- @param campaign any: campaign supplied to this operation.
   -- @param filter any: filter supplied to this operation.
   -- @return table: expand the selected campaign into explicit profile and
   -- dialect cases.
   local function BUILD_MATRIX_plan(catalog, campaign, filter)
      exports.validate(catalog)
      assert(levels[campaign], "unknown campaign")

      local groups, cells, selected = {}, {}, false

      --- Select PR variants by reviewed identifiers; broad campaigns keep all.
      -- @param entries any: entries supplied to this operation.
      -- @param family any: family supplied to this operation.
      -- @return any: pR variants by reviewed identifiers; broad campaigns keep
      -- all.
      local function variants(entries, family)
         if campaign ~= "pr" then
            return entries
         end

         local result, by_id = {}, {}

         for _, entry in ipairs(entries) do
            by_id[entry.id] = entry
         end

         for _, id in ipairs(catalog.pr_selection[family]) do
            result[#result + 1] =
               assert(by_id[id], "unknown PR variant: " .. id)
         end

         return result
      end

      --- Expand one contracted compiler profile into campaign cells.
      -- @param profile table: profile supplied to this operation.
      -- @return nil: no values.
      local function build_matrix_expandProfile(profile)
         if
            (not filter and levels[profile.tier] <= levels[campaign])
            or profile.id == filter
         then
            selected = true
            groups[#groups + 1] = {
               profile = profile.id,
               runner = profile.runner,
               host = profile.host,
            }

            --- Compute the profile's required and optional tests once.
            -- @return table, table: ordered test names and optional names.
            local function build_matrix_profileTests()
               local tests, optional_tests, required =
                  { "c-api", "target-model" }, {}, {}

               for _, cpp in ipairs(profile.cpp) do
                  required[cpp] = true
               end

               for _, cpp in ipairs(catalog.cpp_requested) do
                  local name = "cpp-" .. cpp
                  tests[#tests + 1] = name

                  if not required[cpp] then
                     optional_tests[#optional_tests + 1] = name
                  end
               end

               table.sort(tests)

               return tests, optional_tests
            end

            local profile_tests, profile_optional = build_matrix_profileTests()

            --- Append one configuration case with its flags, semantic contract
            -- and
            -- expected tests.
            -- @param configuration any: configuration supplied to this
            -- operation.
            -- @param dialect any: dialect supplied to this operation.
            -- @param suffix any: suffix supplied to this operation.
            -- @param flags any: flags supplied to this operation.
            -- @param semantics any: semantics supplied to this operation.
            -- @param support any|nil: support supplied to this operation.
            -- @return nil: no values.
            local function build_matrix_addCell(
               configuration,
               dialect,
               suffix,
               flags,
               semantics,
               support
            )
               assert(
                  support == nil
                     or support == "required"
                     or support == "experimental",
                  "unknown variant support policy"
               )
               cells[#cells + 1] = {
                  id = profile.id .. "-c" .. dialect .. "-" .. suffix,
                  profile = profile.id,
                  configuration = configuration,
                  dialect = dialect,
                  support = support or profile.support or "required",
                  tests = build_matrix_copyTests(profile_tests),
                  optional_tests = build_matrix_copyTests(profile_optional),
                  flags = flags,
                  link_flags = {},
                  semantic_profile = semantics,
               }
            end

            for _, configuration in ipairs(catalog.configurations) do
               for _, dialect in ipairs(profile.c) do
                  build_matrix_addCell(
                     configuration,
                     dialect,
                     configuration:lower()
                  )
               end
            end

            -- Each platform runs the optimization profiles in every C dialect.
            -- C++ consumers use the same flags and their own language probes.
            --- Add optimization and flag variants for non-MSVC profiles.
            -- @return nil: no values.
            local function build_matrix_expandOptimizations()
               if profile.compiler ~= "MSVC" then
                  for _, dialect in ipairs(profile.c) do
                     for _, mode in
                        ipairs(variants(catalog.optimizations, "optimizations"))
                     do
                        build_matrix_addCell(
                           "Release",
                           dialect,
                           mode.id,
                           (profile.mode_flags or {})[mode.id] or mode.flags,
                           mode.contract,
                           mode.support
                        )
                     end
                  end

                  for _, flags in
                     ipairs(variants(catalog.flag_profiles, "flag_profiles"))
                  do
                     if
                        flags.contract ~= "x86-64"
                        or profile.arch == "X86_64"
                     then
                        build_matrix_addCell(
                           "Release",
                           profile.c[#profile.c],
                           "flags-" .. flags.id,
                           flags.flags,
                           flags.contract,
                           flags.support
                        )
                     end
                  end
               end
            end

            build_matrix_expandOptimizations()

            --- Add reviewed MSVC flag experiments to the profile.
            -- @return nil: no values.
            local function build_matrix_expandMsvc()
               if profile.compiler == "MSVC" then
                  local experiments = dofile("tools/build/msvc-flags.lua")

                  for _, flags in ipairs(variants(experiments, "msvc_flags")) do
                     cells[#cells + 1] = {
                        id = profile.id .. "-c17-flags-" .. flags.id,
                        profile = profile.id,
                        configuration = "Release",
                        dialect = "17",
                        support = flags.support
                           or profile.support
                           or "required",
                        tests = build_matrix_requiredTests(catalog),
                        optional_tests = {
                           "cpp-98",
                           "cpp-03",
                           "cpp-11",
                           "cpp-23",
                           "cpp-26",
                        },
                        flags = flags.flags,
                        link_flags = flags.link or {},
                        semantic_profile = flags.contract,
                     }
                  end
               end
            end

            build_matrix_expandMsvc()
         end
      end

      for _, profile in ipairs(catalog.profiles) do
         build_matrix_expandProfile(profile)
      end

      assert(selected, "no contracted profiles selected")
      assert(
         #groups <= MATRIX_MAX_GROUPS,
         "campaign exceeds GitHub matrix limit"
      )

      return {
         schema = 1,
         campaign = campaign,
         groups = groups,
         cells = cells,
         unavailable = catalog.unavailable,
      }
   end

   exports.plan = BUILD_MATRIX_plan

   --- Find a declared profile by identifier; reject an unknown profile.
   -- @param catalog table: reviewed catalog of supported entries.
   -- @param id string: stable identity used to match the requested entry.
   -- @return any: a declared profile by identifier; reject an unknown profile.
   local function BUILD_MATRIX_profile(catalog, id)
      for _, profile in ipairs(catalog.profiles) do
         if profile.id == id then
            return profile
         end
      end

      error("unknown profile: " .. tostring(id))
   end

   exports.profile = BUILD_MATRIX_profile

   --- Match observed build results to expected cases and report incomplete
   -- qualification.
   -- @param expected any: expected reference value used by this check.
   -- @param results any: results supplied to this operation.
   -- @return boolean, table, table: match observed build results to expected
   -- cases and report incomplete qualification.
   local function BUILD_MATRIX_gate(expected, results)
      local wanted, seen, failures, experiments = {}, {}, {}, {}

      for _, cell in ipairs(expected) do
         wanted[cell.id] = cell
      end

      --- Validate one reported cell before admitting its evidence.
      -- @param result table: result supplied to this operation.
      -- @return nil: no values.
      local function build_matrix_acceptResult(result)
         local cell = assert(wanted[result.id], "unexpected result cell")

         assert(not seen[result.id], "duplicate result cell")

         seen[result.id] = true
         assert(
            result.support == cell.support,
            "result changed its support policy"
         )

         --- Check passed-cell test inventories against required contracts.
         -- @return nil: no values.
         local function build_matrix_verifyTests()
            if result.status == "tests-passed" then
               --- Validate optional omissions and the exact executed-test
               -- inventory.
               -- @return nil: no values.
               local function build_matrix_checkTestInventory()
                  local optional, omitted, executed = {}, {}, {}

                  for _, name in ipairs(cell.optional_tests or {}) do
                     optional[name] = true
                  end

                  for _, name in ipairs(result.unsupported_tests or {}) do
                     assert(
                        optional[name] and not omitted[name],
                        "required, unknown or duplicate unsupported test"
                     )

                     omitted[name] = true
                  end

                  for _, name in ipairs(cell.tests) do
                     if not omitted[name] then
                        executed[#executed + 1] = name
                     end
                  end

                  assert(
                     table.concat(result.tests, "\n")
                        == table.concat(executed, "\n"),
                     "executed test inventory differs"
                  )
                  assert(result.artifacts > 0, "missing artifact inventory")
               end

               build_matrix_checkTestInventory()
            elseif
               cell.support == "required" or result.status ~= "unsupported"
            then
               failures[#failures + 1] = result.id
                  .. ": "
                  .. tostring(result.status)
            else
               experiments[#experiments + 1] = result.id
                  .. ": "
                  .. tostring(result.status)
            end
         end

         build_matrix_verifyTests()
      end

      for _, result in ipairs(results) do
         build_matrix_acceptResult(result)
      end

      for _, cell in ipairs(expected) do
         if not seen[cell.id] then
            failures[#failures + 1] = cell.id .. ": missing"
         end
      end

      return #failures == 0, failures, experiments
   end

   exports.gate = BUILD_MATRIX_gate

   return exports
end

return scripts_build_lib_matrix_loadModule()

-- EOF


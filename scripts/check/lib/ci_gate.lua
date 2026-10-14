-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Share one acceptance contract between the hosted gate and its reference.
-- @return table: public operations constructed by this module.
local function CI_GATE_loadModule()
   local exports = {}
   local rules = {
      { job = "changes", env = "CHANGES_RESULT" },
      { job = "lint", env = "LINT_RESULT" },
      { job = "reuse", env = "REUSE_RESULT" },
      {
         job = "spelling",
         env = "SPELLING_RESULT",
         selection = "SPELLING_CHANGED",
         idle = "success|skipped",
      },
      {
         job = "c-analysis",
         env = "C_ANALYSIS_RESULT",
         selection = "C_CHANGED",
         idle = "success|skipped",
      },
      {
         job = "release-checks",
         env = "RELEASE_RESULT",
         selection = "ENGINEERING_CHANGED",
         idle = "skipped",
      },
      {
         job = "build-matrix",
         env = "BUILD_RESULT",
         selection = "ENGINEERING_CHANGED",
         idle = "skipped",
      },
      {
         job = "qualification",
         env = "QUALIFICATION_RESULT",
         selection = "ENGINEERING_CHANGED",
         idle = "skipped",
      },
      {
         job = "reproducibility",
         env = "REPRODUCIBILITY_RESULT",
         selection = "ENGINEERING_CHANGED",
         idle = "skipped",
      },
   }

   exports.rules = rules

   --- Require explicit detector booleans and successful selected checks.
   -- @param values table: values consumed in the operation’s declared order.
   -- @return boolean: require explicit detector booleans and successful
   -- selected checks.
   local function CI_GATE_validate(values)
      for _, selection in ipairs({
         "ENGINEERING_CHANGED",
         "C_CHANGED",
         "SPELLING_CHANGED",
      }) do
         assert(
            values[selection] == "true" or values[selection] == "false",
            "missing or invalid selection: " .. selection
         )
      end

      for _, rule in ipairs(rules) do
         local expected = "success"
         if rule.selection and values[rule.selection] == "false" then
            expected = rule.idle
         end

         local observed = values[rule.env]
         local accepted = observed == expected
            or (
               expected == "success|skipped"
               and (observed == "success" or observed == "skipped")
            )

         assert(
            accepted,
            rule.job
               .. ": expected "
               .. expected
               .. ", got "
               .. tostring(observed)
         )
      end

      return true
   end

   exports.validate = CI_GATE_validate

   --- Render the reference table from the same rules used by the hosted gate.
   -- @return any: the reference table from the same rules used by the hosted
   -- gate.
   local function CI_GATE_markdown()
      local lines = {
         "<!-- BEGIN GENERATED CI GATE -->",
         "| Job | Selection | Selected result | Unselected result |",
         "| --- | --- | --- | --- |",
      }

      for _, rule in ipairs(rules) do
         local idle = rule.idle
               and ("`" .. rule.idle:gsub("|", "` or `") .. "`")
            or "N/A"

         lines[#lines + 1] = "| `"
            .. rule.job
            .. "` | "
            .. (rule.selection and ("`" .. rule.selection .. "`") or "Always")
            .. " | `success` | "
            .. idle
            .. " |"
      end

      lines[#lines + 1] = "<!-- END GENERATED CI GATE -->"

      return table.concat(lines, "\n")
   end

   exports.markdown = CI_GATE_markdown

   return exports
end

return CI_GATE_loadModule()

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Reconcile every catalog entry even when installation or a service failed.
-- Part of security-adapter planning, execution and evidence reports.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_security_report_main()
   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local projects = dofile("tools/security/openssf/projects.lua")
   local options = artifact_io.options(arg, { input = true, output = true })
   local input = assert(options.input, "--input is required")
   local output = assert(options.output, "--output is required")

   for _, path in ipairs({ input, output }) do
      artifact_io.safe_path(path)
      assert(path:match("^%.cache/"), "assessment paths must stay in .cache")
   end

   local names, entries = {}, artifact_io.array()
   local complete = true

   for name in pairs(projects) do
      names[#names + 1] = name
   end

   table.sort(names)

   local lines = {
      "# OpenSSF integration coverage",
      "",
      "This report does not award Gold, SLSA or OSPS conformance.",
      "",
      "| Project | State | Scope or missing prerequisite |",
      "| --- | --- | --- |",
   }

   --- Escape report text before placing it in a Markdown table cell.
   -- @param value any: input value; validation belongs to this operation’s
   -- contract.
   -- @return any: escape report text before placing it in a Markdown table
   -- cell.
   local function security_report_cell(value)
      return tostring(value):gsub("[\r\n|]", " "):gsub("[<>]", "")
   end

   for _, name in ipairs(names) do
      local path = input .. "/openssf-" .. name .. "/result.json"
      local entry =
         { project = name, state = "INFRA_ERROR", detail = "Missing report" }
      local ok, message = pcall(
         --- Validate one project report and retain missing or malformed
         -- evidence.
         -- @return nil: no values.
         function()
            assert(
               artifact_io.query(path, ".project") == name,
               "foreign project report"
            )

            entry.state = artifact_io.query(path, ".state")
            assert(
               entry.state == "PASS"
                  or entry.state == "FAIL"
                  or entry.state == "BLOCKED",
               "invalid report state"
            )

            entry.detail = artifact_io.query(path, ".claim // .detail")
            if projects[name].mode == "blocked" then
               assert(
                  entry.state == "BLOCKED",
                  "unqualified adapter reported success"
               )
            end
         end
      )

      if not ok then
         entry.state = "INFRA_ERROR"
         entry.detail = tostring(message)
      end

      complete = complete and entry.state == "PASS"
      entries[#entries + 1] = entry
      lines[#lines + 1] = "| "
         .. name
         .. " | "
         .. entry.state
         .. " | "
         .. security_report_cell(entry.detail)
         .. " |"
   end

   artifact_io.document(output .. "/coverage.json", {
      schema = 1,
      complete = complete,
      product_qualified = false,
      projects = entries,
   })

   artifact_io.write(
      output .. "/coverage.md",
      table.concat(lines, "\n") .. "\n"
   )

   local summary = os.getenv("GITHUB_STEP_SUMMARY")

   if summary then
      local file = assert(io.open(summary, "a"))

      assert(file:write(table.concat(lines, "\n") .. "\n"))
      assert(file:close())
   end

   assert(complete, "OpenSSF coverage is incomplete; inspect coverage.json")
end

return scripts_security_report_main()

-- EOF


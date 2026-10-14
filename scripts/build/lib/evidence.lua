-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Read build records in one inert transport and verify retained test bytes.
-- Report paths are relative to their profile and constrained to their cell.

--- Construct evidence validation without evaluating downloaded source text.
-- @return table: public operations constructed by this module.
local function EVIDENCE_loadModule()
   local EVIDENCE_HEX_BASE = 16
   local EVIDENCE_SHA256_HEX_LENGTH = 64
   local EVIDENCE_HEADER_FIELDS = 3
   local EVIDENCE_CELL_FIELDS = 9

   local exports = {}
   local query = [=[
def text: if type == "string" then . else error("expected string") end;
def strings: if type == "array" then map(text) | join("\n")
  else error("expected string array") end;
def row: map(text | @uri) | join("\t");
if .schema != 2 then error("unsupported build report schema") else . end |
([.profile, .campaign, (.plan_sha256 // "")] | row),
(.cells | if type == "array" then . else error("expected cells array") end |
 .[] | [.id, .support, .status, (.tests | strings),
  (.unsupported_tests | strings),
  (.artifacts | if type == "array" then length | tostring
    else error("expected artifact inventory") end),
  (.test_report.path // ""), (.test_report.sha256 // ""),
  (.semantic_trace // "")] | row)
]=]

   --- Decode URI-escaped fields without interpreting tabs or source code.
   -- @param line string: source line to inspect.
   -- @return table: uRI-escaped fields without interpreting tabs or source
   -- code.
   local function fields(line)
      local result = {}

      for value in (line .. "\t"):gmatch("(.-)\t") do
         --- Decode one escaped TSV byte without interpreting later escapes.
         -- @param pair string: captured hexadecimal byte pair.
         -- @return any: one escaped TSV byte without interpreting later
         -- escapes.
         result[#result + 1] = value:gsub("%%(%x%x)", function(pair)
            return string.char(tonumber(pair, EVIDENCE_HEX_BASE))
         end)
      end

      return result
   end

   --- Verify test content independently of the producer's success string.
   -- @param build table: build supplied to this operation.
   -- @param root string: root directory for this operation.
   -- @param cell table: cell supplied to this operation.
   -- @param path string: filesystem path selected by the caller.
   -- @param digest string: expected content digest.
   -- @param trace string: canonical cross-target semantic trace from c-api.
   -- @return nil: no values.
   local function EVIDENCE_test(build, root, cell, path, digest, trace)
      assert(path == cell.id .. "/ctest.xml", "test evidence path mismatch")
      assert(cell.id:match("^[%w_-]+$"), "unsafe cell identity")
      assert(
         #digest == EVIDENCE_SHA256_HEX_LENGTH and digest:match("^[a-f0-9]+$"),
         "invalid test digest"
      )
      assert(
         build.real_path(root .. "/" .. path)
            == build.real_path(root) .. "/" .. path,
         "test evidence follows a link"
      )
      assert(
         build.digest(root .. "/" .. path) == digest,
         "test evidence digest mismatch"
      )
      local junit = dofile("scripts/build/lib/junit.lua")

      junit.validate(build.read(root .. "/" .. path), cell.tests, trace)
   end

   exports.test = EVIDENCE_test

   --- Validate a complete group before admitting any of its cells to the gate.
   -- @param build table: build supplied to this operation.
   -- @param root string: root directory for this operation.
   -- @param profile any: selected configuration profile.
   -- @param campaign any: campaign supplied to this operation.
   -- @param plan_digest any: plan digest supplied to this operation.
   -- @return table: validate a complete group before admitting any of its cells
   -- to the gate.
   local function EVIDENCE_group(build, root, profile, campaign, plan_digest)
      local rows = build.lines(build.query(root .. "/report.json", query))
      local header = fields(assert(rows[1], "missing report identity"))

      assert(
         #header == EVIDENCE_HEADER_FIELDS and header[1] == profile,
         "profile identity mismatch"
      )
      assert(header[2] == campaign, "campaign identity mismatch")
      assert(
         not plan_digest or header[3] == plan_digest,
         "report came from another plan"
      )
      local cells = {}

      for index = 2, #rows do
         local values = fields(rows[index])

         assert(#values == EVIDENCE_CELL_FIELDS, "invalid cell transport")
         local cell = {
            id = values[1],
            support = values[2],
            status = values[3],
            tests = build.array(build.lines(values[4])),
            unsupported_tests = build.array(build.lines(values[5])),
            artifacts = assert(tonumber(values[6])),
         }

         if cell.status == "tests-passed" then
            exports.test(build, root, cell, values[7], values[8], values[9])
         end

         cells[#cells + 1] = cell
      end

      return cells
   end

   exports.group = EVIDENCE_group

   return exports
end

return EVIDENCE_loadModule()

-- EOF


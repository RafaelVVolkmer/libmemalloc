-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Derive the published mascot from the project's layered logo SVG.
-- Part of Doxygen generation and authored-document validation.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_documentation_lib_brand_loadModule()
   local exports = {}

   --- Remove the trailing wordmark layers and apply the configured square crop.
   -- The source has definitions, one masked mascot group, then wordmark groups.
   -- Fail on a changed structure instead of silently publishing a clipped
   -- wordmark.
   -- @param svg string: original logo document, never modified on disk.
   -- @param viewbox string: measured square viewport around the mascot artwork.
   -- @return string: standalone derived SVG retaining the original
   -- license/mask.
   local function DOCUMENTATION_BRAND_mascot(svg, viewbox)
      assert(
         viewbox:match("^%-?[%d.]+ %-?[%d.]+ [%d.]+ [%d.]+$"),
         "invalid mascot viewport"
      )

      local illustration = assert(
         svg:match('^(.-)%s*<g fill%-opacity="1" fill="#5a6988">'),
         "logo wordmark boundary changed"
      )

      assert(illustration:find("</defs>", 1, true), "logo definitions missing")
      assert(illustration:find('<g mask="', 1, true), "logo mascot missing")

      local count

      illustration, count = illustration:gsub(
         "<svg%s+[^>]+>",
         --- Apply the approved mascot crop to the SVG root element.
         -- @param root string: root directory for this operation.
         -- @return any: apply the approved mascot crop to the SVG root element.
         function(root)
            root = root:gsub('viewBox="[^"]+"', 'viewBox="' .. viewbox .. '"')
            root = root:gsub('width="[^"]+"', 'width="720"')
            root = root:gsub('height="[^"]+"', 'height="720"')

            return root:gsub(' style="[^"]+"', "")
         end,
         1
      )
      assert(count == 1, "logo SVG root missing")

      return illustration .. "\n</svg>\n"
   end

   exports.mascot = DOCUMENTATION_BRAND_mascot

   return exports
end

return scripts_documentation_lib_brand_loadModule()

-- EOF


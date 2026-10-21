-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Integrate trusted Doxygen-generated graphs and build a local page catalog.
-- Part of Doxygen generation and authored-document validation.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_documentation_lib_html_loadModule()
   local exports = {}

   --- Inline a non-interactive Graphviz SVG without duplicating document IDs.
   -- @param svg string: svg supplied to this operation.
   -- @param prefix any: prefix supplied to this operation.
   -- @return string: inline a non-interactive Graphviz SVG without duplicating
   -- document IDs.
   local function DOCUMENTATION_HTML_graph(svg, prefix)
      assert(
         not svg:find("<script"),
         "native graphs must use INTERACTIVE_SVG=NO"
      )

      local body = assert(svg:match("(<svg%s.-</svg>)"), "invalid graph SVG")
      local ids = {}

      body = body:gsub(
         'id="([^"]+)"',
         --- Assign graph-local IDs before rewriting their references.
         -- @param id string: stable identity used to match the requested entry.
         -- @return string: assign graph-local IDs before rewriting their
         -- references.
         function(id)
            ids[id] = prefix .. id

            return 'id="' .. ids[id] .. '"'
         end
      )
      body = body:gsub("xlink:href=", "href=")
      body = body:gsub(
         'href="#([^"]+)"',
         --- Retarget a fragment link to its graph-local identifier.
         -- @param id string: stable identity used to match the requested entry.
         -- @return string: retarget a fragment link to its graph-local
         -- identifier.
         function(id)
            return 'href="#' .. (ids[id] or id) .. '"'
         end
      )
      body = body:gsub(
         "url%(%#([^%)]+)%)",
         --- Retarget an SVG paint reference to its graph-local identifier.
         -- @param id string: stable identity used to match the requested entry.
         -- @return string: retarget an SVG paint reference to its graph-local
         -- identifier.
         function(id)
            return "url(#" .. (ids[id] or id) .. ")"
         end
      )
      body = body:gsub(
         "<svg ",
         '<svg class="lma-native-svg" role="group" aria-label="Doxygen graph" ',
         1
      )

      return (
         '<div class="lma-native-graph" tabindex="0" '
         .. 'role="region" aria-label="Doxygen graph">'
      )
         .. body
         .. "</div>"
   end

   exports.graph = DOCUMENTATION_HTML_graph

   --- Extract normalized text for the generated documentation search catalogue.
   -- @param html string: html supplied to this operation.
   -- @return any: normalized text for the generated documentation search
   -- catalogue.
   local function documentation_html_text(html)
      return (
         html
            :gsub("<[^>]+>", "")
            :gsub("%s+", " ")
            :gsub("^%s+", "")
            :gsub("%s+$", "")
      )
   end

   --- Process only generated top-level HTML; original assets remain untouched.
   -- @param directory string: working or output directory selected by the
   -- caller.
   -- @param artifact_io table: artifact filesystem and serialization
   -- operations.
   -- @return nil: no values.
   local function DOCUMENTATION_HTML_publish(directory, artifact_io)
      local catalog = {}

      for _, file in ipairs(artifact_io.files(directory)) do
         if file:match("^[^/]+%.html$") then
            local html = artifact_io.read(directory .. "/" .. file)
            local title = html:match('<div class="title">(.-)</div>')

            if title then
               title = title:gsub('<div class="ingroups">.*', "")
               catalog[#catalog + 1] =
                  { title = documentation_html_text(title), url = file }
            end

            local number = 0

            --- Inline a generated graph with page-local IDs; preserve other
            -- embedded elements.
            -- @param element string: element supplied to this operation.
            -- @return any: inline a generated graph with page-local IDs;
            -- preserve other embedded elements.
            local function documentation_html_embed(element)
               local src = element:match('src="([%w_.-]+%.svg)"')

               if not src then
                  return element
               end

               local svg = artifact_io.read(directory .. "/" .. src)

               if not svg:find('class="graph"', 1, true) then
                  return element
               end

               number = number + 1

               return exports.graph(svg, "lma-dot-" .. number .. "-")
            end

            html =
               html:gsub("<iframe%s[^>]*>.-</iframe>", documentation_html_embed)
            html = html:gsub("<img%s[^>]*>", documentation_html_embed)

            -- Titles may contain nested ingroups divs; preserve their
            -- structure.
            html = html:gsub(
               '<div class="title">',
               '<div class="title" role="heading" aria-level="1">'
            )
            artifact_io.write(directory .. "/" .. file, html)
         end
      end

      table.sort(
         catalog,
         --- Order catalogue entries by generated page URL.
         -- @param a table: a supplied to this operation.
         -- @param b table: b supplied to this operation.
         -- @return boolean: order catalogue entries by generated page URL.
         function(a, b)
            return a.url < b.url
         end
      )

      artifact_io.document(
         directory .. "/documentation-index.json",
         artifact_io.array(catalog)
      )
   end

   exports.publish = DOCUMENTATION_HTML_publish

   return exports
end

return scripts_documentation_lib_html_loadModule()

-- EOF


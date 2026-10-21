-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Verify generated graph links, page markers and script boundaries.
-- Part of repository automation regression tests; run from the root.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_doxygen_html_test_suite_main()
   local html = dofile("scripts/documentation/lib/html.lua")
   local svg = (
      '<?xml version="1.0"?><svg viewBox="0 0 100 '
      .. '60">\n<g id="graph0" '
      .. 'class="graph"><title>Sample</title>\n<g '
      .. 'id="Node1" class="node"><a '
      .. 'xlink:href="function.html#anchor"><text>call'
      .. 'er</text></a></g>\n<g id="Node2" '
      .. 'class="node"><a xlink:href="#Node1"><text>ca'
      .. "llee</text></a></g>\n<path "
      .. 'marker-end="url(#arrow)"/><marker '
      .. 'id="arrow"/></g></svg>'
   )
   local first = html.graph(svg, "first-")
   local second = html.graph(svg, "second-")

   assert(first:find('id="first-Node1"', 1, true))
   assert(second:find('id="second-Node1"', 1, true))
   assert(
      not first:find('id="Node1"', 1, true),
      "IDs may collide between graphs"
   )
   assert(
      first:find('href="function.html#anchor"', 1, true),
      "API links must survive"
   )
   assert(
      first:find('href="#first-Node1"', 1, true),
      "local references must follow renamed IDs"
   )
   assert(
      first:find("url(#first-arrow)", 1, true),
      "markers must follow renamed IDs"
   )
   assert(first:find('viewBox="0 0 100 60"', 1, true), "layout must survive")
   assert(first:find('role="region"', 1, true))
   assert(
      not pcall(html.graph, "<svg><script>example()</script></svg>", "bad-"),
      "script element was accepted in a graph"
   )

   print(
      (
         "Doxygen HTML: graph IDs, links, markers, "
         .. "layout and script rejection passed."
      )
   )
end

return tests_doxygen_html_test_suite_main()

-- EOF


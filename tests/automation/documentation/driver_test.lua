-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Exercise real Doxygen evaluation, input separation and publication assets.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_doxygen_driver_test_suite_main()
   local R = dofile("scripts/lib/artifacts.lua")
   local D = dofile("scripts/documentation/lib/driver.lua")
   local markdown = dofile("scripts/documentation/lib/markdown.lua")

   assert(not arg[1] or arg[1] == "--eval-only", "unknown test option")
   assert(not arg[2], "unexpected test argument")

   R.mkdir(".cache/tests/doxygen")

   local root = R.output({ "mktemp", "-d", ".cache/tests/doxygen/run-XXXXXX" })
   local config = dofile("scripts/documentation/config.lua")
   local lua = os.getenv("LIBMEMALLOC_LUA") or "lua"

   --- Require the expected rejection and its diagnostic.
   -- @param action any: action supplied to this operation.
   -- @param diagnostic any: diagnostic supplied to this operation.
   -- @return nil: no values.
   local function reject(action, diagnostic)
      local ok, message = pcall(action)

      assert(not ok, "expected rejection: " .. diagnostic)
      assert(tostring(message):find(diagnostic, 1, true), tostring(message))
   end

   --- Reject an undeclared driver option.
   -- @return nil: no values.
   reject(function()
      D.options({ "eval", "--unknown=x" })
   end, "unknown option")

   --- Reject an option without its required value.
   -- @return nil: no values.
   reject(function()
      D.options({ "eval", "--source" })
   end, "missing option value")

   --- Reject repeated output destinations.
   -- @return nil: no values.
   reject(function()
      D.options({ "eval", "--output=x", "--output=y" })
   end, "duplicate option")

   --- Reject a source directory that does not exist.
   -- @return nil: no values.
   reject(function()
      D.plan({ mode = "eval", source = { root .. "/missing" } }, config)
   end, "missing input")

   --- Keep generated output below the disposable cache root.
   -- @return nil: no values.
   reject(function()
      D.plan({ mode = "eval", output = "docs/generated" }, config)
   end, "output must stay below")

   --- Reject input paths that escape the repository.
   -- @return nil: no values.
   reject(function()
      D.plan({ mode = "eval", source = { "../core" } }, config)
   end, "path")

   --- Reject a literal code block without its closing fence.
   -- @return nil: no values.
   reject(function()
      markdown.filter("# Page\n\n```lua\nlocal n = 1\n", "docs/bad.md")
   end, "unclosed Markdown fence")

   local diagram = markdown.filter(
      "> ```mermaid\n> flowchart LR\n> A --> B\n> ```\n",
      "docs/diagram.md"
   )

   assert(diagram:find("> @mermaid\n> flowchart LR", 1, true))
   assert(diagram:find("> @endmermaid", 1, true))

   local literal = markdown.filter("```text\nA --> B\n```\n", "docs/literal.md")

   assert(literal:find("@verbatim\nA --> B\n@endverbatim", 1, true))
   assert(
      not literal:find("lma-code", 1, true),
      "literal code received generated controls"
   )
   for label, language in pairs({
      c = "c",
      ["{.cpp}"] = "cpp",
      rs = "rust",
      compile_fail = "rust",
      sh = "bash",
      lua = "lua",
   }) do
      local code = markdown.filter(
         "~~~" .. label .. "\n/** @param[in] x <value> */\n~~~\n",
         "docs/code.md"
      )

      assert(code:find('data-language="' .. language .. '"', 1, true))
      assert(code:find("/** @param[in] x <value> */", 1, true))
   end

   local unknown =
      markdown.filter("```unknown\n<placeholder>\n```\n", "docs/unknown.md")

   assert(
      not unknown:find("lma-code", 1, true),
      "unknown language received generated controls"
   )

   local badge_source = '[![A "badge"][image]][section]\n'
      .. "[image]: https://example.invalid/badge.svg?a=1&b=2\n"
      .. "[section]:\n  #shared\n"
      .. '```text\n[![A "badge"][image]][section]\n```\n'
   local badge = markdown.filter(badge_source, "docs/guide.md")

   assert(
      badge:find(
         'href="#' .. markdown.identifier("docs/guide.md") .. '_shared"',
         1,
         true
      )
   )
   assert(
      badge:find('src="https://example.invalid/badge.svg?a=1&amp;b=2"', 1, true)
   )
   assert(badge:find('alt="A &quot;badge&quot;"', 1, true))
   assert(
      badge:find(
         '@verbatim\n[![A "badge"][image]][section]\n@endverbatim',
         1,
         true
      )
   )

   R.write(
      root .. "/first/api.h",
      [[/** @file api.h
 * @brief Document the first selected implementation.
 */
/** @brief Preserve the input value.
 * @param[in] value Input value.
 * @return The unchanged value.
 */
int identity(int value);
]]
   )
   R.write(
      root .. "/second/extra.h",
      [[/** @file extra.h
 * @brief Document the second selected implementation.
 */
/** @brief Return the extra value.
 * @return The extra value.
 */
int extra(void);
]]
   )
   R.write(
      root .. "/pages/guide.md",
      "# Selected guide\n\n![Selected asset](asset.svg)\n"
         .. '\n<a id="shared"></a>\n## Shared\n\n[Local][shared]\n'
         .. "[Other](../linked/other.md#shared)\n\n[shared]:\n  #shared\n"
         .. "\n[Other by reference][other-section]\n\n"
         .. "[other-section]: ../linked/other.md#shared\n"
         .. "\n> ```lua\n> ---@field example integer\n> "
         .. "local x <close> = acquire()\n> ```\n"
         .. "\n```mermaid\nflowchart LR\nA[Input] --> B[Output]\n```\n"
         .. "\n```c\n/** @param[in] x <value> */\nconst "
         .. 'char *s = "<script>&";\n```\n'
         .. "\n```rust\nfn main() { let value = 1; }\n```\n"
   )
   R.write(
      root .. "/linked/other.md",
      '# Linked page\n\n<a id="shared"></a>\n## Shared\n'
         .. "\n[Back](../pages/guide.md#shared)\n"
   )
   R.write(
      root .. "/pages/asset.svg",
      '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"></svg>'
   )
   R.write(
      root .. "/pages/template.c",
      "This is not compilable C or an implementation.\n"
   )

   --- Keep generated files outside the implementation source tree.
   -- @return nil: no values.
   reject(function()
      D.plan({
         mode = "eval",
         source = { root .. "/pages" },
         output = root .. "/pages/generated",
      }, config)
   end, "output cannot be inside")
   R.mkdir(root .. "/empty")

   --- Reject source directories without C or C++ inputs.
   -- @return nil: no values.
   reject(function()
      D.plan({ mode = "eval", source = { root .. "/empty" } }, config)
   end, "contain no C/C++ input")

   local options = D.options({
      "eval",
      "--source=" .. root .. "/first",
      "--source",
      root .. "/second",
      "--page=" .. root .. "/pages",
      "--images=" .. root .. "/pages",
      "--output=" .. root .. "/eval",
   })
   local plan = D.plan(options, config)

   assert(#plan.sources == 2, "both implementation roots must be selected")

   local selected_pages = {}

   for _, file in ipairs(plan.pages) do
      selected_pages[file] = true
      assert(not markdown.excluded(file), "docs README entered publication")
   end

   assert(selected_pages["README.md"], "project landing page was excluded")
   assert(
      not selected_pages["docs/specs/README.md"],
      "linked README was included"
   )
   assert(markdown.excluded("docs/readme.md"))
   assert(markdown.excluded("docs/nested/ReadMe.Md"))
   assert(
      not markdown.excluded("assets/images/README.md"),
      "image directory README was excluded"
   )

   local readme_link = markdown.filter(
      "[Index](../specs/README.md#overview)\n",
      "docs/runbooks/guide.md"
   )

   assert(
      readme_link:find(
         (
            "https://github.com/RafaelVVolkmer/libmemallo"
            .. "c/blob/main/docs/specs/README.md#overview"
         ),
         1,
         true
      )
   )
   for _, file in ipairs(plan.sources) do
      assert(
         not file:find("template.c", 1, true),
         "page input leaked into sources"
      )
   end

   D.run(options)
   assert(not R.exists(plan.output .. "/html"), "eval must not generate HTML")

   local xml = R.read(plan.output .. "/xml/index.xml")

   assert(
      xml:find("identity", 1, true) and xml:find("extra", 1, true),
      "graph metadata was lost"
   )

   local page_id = xml:match('refid="([^"]+_2guide)" kind="page"')

   assert(page_id, "selected page was not generated")
   assert(
      R.read(plan.output .. "/xml/" .. page_id .. ".xml")
         :find("Selected guide", 1, true)
   )
   assert(
      not xml:find("MOCK_identity", 1, true),
      "--source did not replace core"
   )
   assert(xml:find("_2other", 1, true), "linked page closure is missing")

   local other_id = assert(xml:match('refid="([^"]+_2other)" kind="page"'))

   assert(
      R.read(plan.output .. "/xml/" .. page_id .. ".xml")
         :find("@field example integer", 1, true),
      "quoted Lua example was lost"
   )

   -- A documentation warning must make the CLI fail and leave failed evidence.
   local bad = root .. "/first/api.h"

   R.write(
      bad,
      R.read(bad):gsub("@param%[in%] value", "@param[in] nonexistent")
   )

   local argv = {
      lua,
      "scripts/documentation/main.lua",
      "eval",
      "--source=" .. root .. "/first",
      "--output=" .. root .. "/negative",
   }
   local succeeded = R.platform.command_succeeded_silent(argv)

   assert(not succeeded, "invalid @param unexpectedly passed evaluation")
   assert(R.read(root .. "/negative/warnings.log"):find("nonexistent", 1, true))
   assert(R.read(root .. "/negative/manifest.json"):find('"failed"', 1, true))

   R.write(root .. "/broken.md", "# Broken page\n\n[Missing](#missing)\n")

   local broken_accepted = R.platform.command_succeeded_silent({
      lua,
      "scripts/documentation/main.lua",
      "eval",
      "--page=" .. root .. "/broken.md",
      "--output=" .. root .. "/broken-result",
   })

   assert(not broken_accepted, "broken Markdown anchor passed")
   assert(
      R.read(root .. "/broken-result/warnings.log"):find("missing", 1, true)
   )

   R.run({ lua, "scripts/check/c.lua", "--doxygen-only" })

   --- Exercise generated-site assets, links and retained build evidence.
   -- @return nil: no values.
   local function documentation_test_buildSite()
      if not arg[1] then
         local built = D.run({
            mode = "build",
            output = root .. "/build",
            page = { root .. "/pages" },
            images = { root .. "/pages" },
         })
         local html = R.read(built.output .. "/html/index.html")

         assert(html:find("doxygen-awesome.css", 1, true), "theme is missing")
         assert(R.exists(built.output .. "/html/doxygen-awesome.css"))
         assert(html:find("libmemalloc.css", 1, true))
         assert(html:find('src="code-highlight.js"', 1, true))
         assert(
            html:find('<script defer="defer" src="code-highlight.js"', 1, true),
            "local file viewing requires a classic deferred script"
         )
         assert(
            html:find('data-highlight-base="vendor/highlight/es/"', 1, true)
         )
         assert(
            not html:find("cdn.jsdelivr.net", 1, true),
            "CDN dependency retained"
         )
         assert(
            R.exists(built.output .. "/html/vendor/highlight/es/core.min.js")
         )
         assert(
            R.exists(built.output .. "/html/vendor/mermaid/mermaid.esm.min.mjs")
         )
         assert(R.exists(built.output .. "/html/code-highlight.js"))
         assert(html:find('src="reading.js"', 1, true))
         assert(html:find('href="reading.css"', 1, true))
         assert(html:find("The Magic of Memory Transmutation", 1, true))
         assert(
            html:find(
               'rel="icon" type="image/svg+xml" href="libmemalloc-mascot.svg"',
               1,
               true
            )
         )
         assert(html:find('src="libmemalloc-mascot.svg"', 1, true))
         assert(
            html:find("<title>libmemalloc</title>", 1, true),
            "browser title must be the project name only"
         )
         assert(
            html:find('src="webmcp.js"', 1, true),
            "WebMCP script is missing"
         )
         assert(
            R.exists(built.output .. "/html/documentation-index.json"),
            "page catalog is missing"
         )

         local mascot = R.read(built.output .. "/html/libmemalloc-mascot.svg")

         assert(
            mascot == R.read(built.output .. "/libmemalloc-mascot.svg"),
            "mascot bytes changed"
         )
         assert(mascot:find('viewBox="-28 28 720 720"', 1, true))
         assert(mascot:find('<g mask="', 1, true), "mascot artwork was removed")
         assert(
            not mascot:find('<g fill-opacity="1"', 1, true),
            "wordmark remains in the crop"
         )
         assert(html:find('href="nord.css"', 1, true), "Nord theme is missing")
         assert(html:find('class="lma-github-corner"', 1, true))
         assert(
            html:find(
               'href="https://github.com/RafaelVVolkmer/libmemalloc"',
               1,
               true
            )
         )

         local body_fonts = { "NunitoSans-Regular.ttf", "NunitoSans-Bold.ttf" }

         for _, font in ipairs(body_fonts) do
            assert(
               R.read(built.output .. "/html/" .. font)
                  == R.read("doxygen/web/fonts/" .. font),
               "brand font is missing or differs from its source"
            )
         end

         assert(
            R.read(built.output .. "/html/reading.js")
               == R.read(built.output .. "/web/reading.js"),
            "reading script bytes changed"
         )
         assert(
            R.read(built.output .. "/html/reading.css")
               == R.read("doxygen/web/styles/reading.css"),
            "reading stylesheet bytes changed"
         )
         assert(
            html:find("Proving that dynamic memory allocation", 1, true),
            "project README is not the landing page"
         )

         local menu = R.read(built.output .. "/html/menudata.js")
         local guide = R.read(built.output .. "/html/" .. page_id .. ".html")
         local linked_anchor = markdown.identifier(root .. "/linked/other.md")
            .. "_shared"
         local linked_href = 'href="'
            .. other_id
            .. ".html#"
            .. linked_anchor
            .. '"'
         local _, linked_count =
            guide:gsub(linked_href:gsub("(%W)", "%%%1"), "")

         assert(
            linked_count == 2,
            "inline and reference links must resolve to HTML"
         )
         assert(
            not guide:find("other.md#", 1, true),
            "raw Markdown URL in HTML"
         )
         assert(
            R.read(built.output .. "/html/" .. other_id .. ".html")
               :find('id="' .. linked_anchor .. '"', 1, true),
            "cross-page link has no matching anchor"
         )
         for _, language in ipairs({ "c", "lua", "rust" }) do
            assert(guide:find('data-language="' .. language .. '"', 1, true))
         end

         assert(
            guide:find("&lt;script&gt;&amp;", 1, true),
            "example content must stay escaped"
         )
         assert(
            guide:find('<pre class="mermaid">', 1, true),
            "diagram became literal text"
         )
         assert(
            guide:find("mermaid.esm.min.mjs", 1, true),
            "Mermaid renderer is missing"
         )
         assert(menu:find('text:"Documentation"', 1, true))
         for _, section in ipairs({
            "getting-started",
            "standards",
            "procedures",
            "runbooks",
            "reference",
            "assurance",
         }) do
            assert(
               menu:find('text:"' .. section .. '"', 1, true),
               "missing documentation section: " .. section
            )
         end

         assert(not menu:find("@ref", 1, true), "unresolved navigation target")
         for target in menu:gmatch('url:"([^"]+%.html)"') do
            assert(
               R.exists(built.output .. "/html/" .. target),
               "missing page: " .. target
            )
         end

         local layout = R.read(built.output .. "/layout.xml")
         local reference_branch = assert(
            layout:match(
               '<tab type="usergroup" title="Project references">(.-)</tab>'
            )
         )
         local _, reference_count =
            reference_branch:gsub('<tab type="user"', "")

         assert(
            reference_count == #config.references,
            "unexpected reference page"
         )
         for _, entry in ipairs(config.references) do
            assert(
               reference_branch:find('title="' .. entry.title .. '"', 1, true)
            )
         end

         assert(
            R.read(built.output .. "/html/project_license.html")
               :find("GNU GENERAL PUBLIC LICENSE", 1, true),
            "license text is missing"
         )

         local governance = R.read(built.output .. "/html/md_GOVERNANCE.html")

         assert(
            governance:find(
               'src="assets/images/libmemalloc_governance.svg"',
               1,
               true
            )
         )
         assert(
            not governance:find('src="/assets/', 1, true),
            "root image URL survived HTML rewriting"
         )
         assert(governance:find('alt="Decision Model"', 1, true))
         assert(
            not governance:find("![Decision Model][decision-shield]", 1, true),
            "decision badge reference was not rendered"
         )
         assert(
            not html:find('class="footer"', 1, true),
            "generated attribution remains"
         )

         --- Check that documentation navigation respects README exclusions.
         -- @param file string: file supplied to this operation.
         -- @return nil: no values.
         local function documentation_test_assertNavigation(file)
            if markdown.excluded("docs/" .. file) then
               assert(
                  not layout:find('url="@ref docs/' .. file .. '"', 1, true),
                  "README present in Documentation: " .. file
               )
            elseif file:match("%.md$") then
               assert(
                  layout:find('url="@ref docs/' .. file .. '"', 1, true),
                  "Markdown absent from Documentation: " .. file
               )
            end
         end

         for _, file in ipairs(R.files("docs")) do
            documentation_test_assertNavigation(file)
         end

         local logo = "assets/images/libmemalloc_logo.svg"

         assert(
            R.read(built.output .. "/html/" .. logo) == R.read(logo),
            "logo bytes changed"
         )
         assert(
            R.read(built.output .. "/html/" .. root .. "/pages/asset.svg")
               == R.read(root .. "/pages/asset.svg"),
            "page asset bytes changed"
         )
         assert(
            R.exists(built.output .. "/html/asset.svg"),
            "Markdown image was not copied"
         )
      end
   end

   documentation_test_buildSite()

   print("Doxygen driver tests passed: " .. root)
end

return tests_doxygen_driver_test_suite_main()

-- EOF


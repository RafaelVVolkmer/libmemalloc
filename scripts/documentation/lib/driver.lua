-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Resolve explicit Doxygen inputs and run a build or a documentation gate.
-- Part of Doxygen generation and authored-document validation.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_documentation_lib_driver_loadModule()
   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local exports = {}
   local markdown = dofile("scripts/documentation/lib/markdown.lua")
   local sources = {
      c = true,
      h = true,
      i = true,
      cpp = true,
      hpp = true,
      cc = true,
      hh = true,
      cxx = true,
      hxx = true,
   }
   local pages = { md = true, markdown = true, dox = true }
   local images = {
      png = true,
      jpg = true,
      jpeg = true,
      svg = true,
      gif = true,
      webp = true,
      pdf = true,
      eps = true,
   }
   local repeated = { source = true, page = true, images = true }
   local singles = { output = true, config = true, mainpage = true }

   --- Parse repeatable input options; reject unknown or ambiguous arguments.
   -- @param arguments table: ordered arguments for the selected operation.
   -- @return table: repeatable input options; reject unknown or ambiguous
   -- arguments.
   local function DOCUMENTATION_DRIVER_options(arguments)
      local result = { mode = arguments[1] or "build" }

      assert(
         result.mode == "build" or result.mode == "eval",
         "use build or eval"
      )

      local index = 2

      while index <= #arguments do
         local token = arguments[index]
         local key, value = token:match("^%-%-([%w-]+)=(.+)$")

         if not key then
            key = token:match("^%-%-([%w-]+)$")
            index = index + 1
            value = arguments[index]
         end

         assert(
            key and (repeated[key] or singles[key]),
            "unknown option: " .. token
         )
         assert(
            type(value) == "string" and not value:match("^%-%-"),
            "missing option value"
         )
         if repeated[key] then
            result[key] = result[key] or {}
            result[key][#result[key] + 1] = value
         else
            assert(not result[key], "duplicate option: " .. key)

            result[key] = value
         end

         index = index + 1
      end

      return result
   end

   exports.options = DOCUMENTATION_DRIVER_options

   --- Validate and normalize a repository-relative documentation input path.
   -- @param value any: value supplied to this operation.
   -- @return any: validate and normalize a repository-relative documentation
   -- input path.
   local function documentation_driver_path(value)
      assert(type(value) == "string", "path must be a string")

      value = value:gsub("^%./", ""):gsub("/+$", "")

      return artifact_io.safe_path(value)
   end

   --- Test whether a path has one of the selected source extensions.
   -- @param name string: entry or operation name to resolve.
   -- @param extensions table: extensions supplied to this operation.
   -- @return any: whether a path has one of the selected source extensions.
   local function documentation_driver_kind(name, extensions)
      return extensions[(name:match("%.([^./]+)$") or ""):lower()]
   end

   --- Collect unique documentation inputs from the declared roots; enforce
   -- required inputs.
   -- @param roots any: roots supplied to this operation.
   -- @param extensions any: extensions supplied to this operation.
   -- @param optional any: optional supplied to this operation.
   -- @return table: unique documentation inputs from the declared roots;
   -- enforce required inputs.
   local function documentation_driver_inventory(roots, extensions, optional)
      local list, seen = {}, {}

      --- Inventory one documentation root without duplicate source paths.
      -- @param root string: root directory for this operation.
      -- @return nil: no values.
      local function documentation_driver_collectRoot(root)
         root = documentation_driver_path(root)
         assert(optional or artifact_io.exists(root), "missing input: " .. root)
         if artifact_io.exists(root) then
            local candidates = { root }

            local is_directory = artifact_io.platform.command_succeeded_silent({
               "test",
               "-d",
               root,
            })

            if is_directory then
               candidates = {}
               for _, child in ipairs(artifact_io.files(root)) do
                  candidates[#candidates + 1] = root .. "/" .. child
               end
            end

            for _, candidate in ipairs(candidates) do
               if
                  documentation_driver_kind(candidate, extensions)
                  and not seen[candidate]
               then
                  list[#list + 1] = candidate
                  seen[candidate] = true
               end
            end
         end
      end

      for _, root in ipairs(roots) do
         documentation_driver_collectRoot(root)
      end

      table.sort(list)

      return list
   end

   --- Quote a Doxygen configuration value without changing its path bytes.
   -- @param value any: input value; validation belongs to this operation’s
   -- contract.
   -- @return string: quote a Doxygen configuration value without changing its
   -- path bytes.
   local function documentation_driver_quoted(value)
      -- Doxyfile expands $(ENV); safe_path also excludes that configuration
      -- syntax.
      return '"' .. documentation_driver_path(value) .. '"'
   end

   --- Render a Doxygen assignment from its declared list of values.
   -- @param name string: entry or operation name to resolve.
   -- @param values table: values consumed in the operation’s declared order.
   -- @return string: a Doxygen assignment from its declared list of values.
   local function documentation_driver_setting(name, values)
      local result = {}

      for _, value in ipairs(values) do
         result[#result + 1] = documentation_driver_quoted(value)
      end

      return name .. " = " .. table.concat(result, " ") .. "\n"
   end

   --- Select real files; do not feed documentation C templates to the parser.
   -- @param options table: operation settings; omitted fields use the
   -- documented defaults.
   -- @param config table: config supplied to this operation.
   -- @return table: real files; do not feed documentation C templates to the
   -- parser.
   local function DOCUMENTATION_DRIVER_plan(options, config)
      local implementations = options.source or config.implementations

      assert(
         type(implementations) == "table" and #implementations > 0,
         "at least one implementation root is required"
      )

      local source_files =
         documentation_driver_inventory(implementations, sources, false)

      assert(
         #source_files > 0,
         "selected implementation roots contain no C/C++ input"
      )

      --- Resolve authored pages and their transitive Markdown references.
      -- @return table, any: authored pages and their transitive Markdown
      -- references.
      local function documentation_driver_selectPages()
         --- Combine configured, requested and reference page roots.
         -- @return table: combine configured, requested and reference page
         -- roots.
         local function documentation_driver_pageRoots()
            local selected_pages = {}

            for _, entry in ipairs(config.pages or {}) do
               selected_pages[#selected_pages + 1] = entry
            end

            for _, entry in ipairs(options.page or {}) do
               selected_pages[#selected_pages + 1] = entry
            end

            for _, entry in ipairs(config.references or {}) do
               selected_pages[#selected_pages + 1] = entry.path
            end

            return selected_pages
         end

         local selected_pages = documentation_driver_pageRoots()

         local mainpage =
            documentation_driver_path(options.mainpage or config.mainpage)

         assert(
            not markdown.excluded(mainpage),
            "docs README cannot be a main page"
         )

         selected_pages[#selected_pages + 1] = mainpage

         local page_files = {}
         local seen_pages = {}

         for _, file in
            ipairs(documentation_driver_inventory(selected_pages, pages, false))
         do
            if not markdown.excluded(file) then
               page_files[#page_files + 1] = file
               seen_pages[file] = true
            end
         end

         local page_index = 1

         while page_index <= #page_files do
            local file = page_files[page_index]

            --- Associate a Markdown input with its selected documentation
            -- targets.
            -- @return nil: no values.
            local function documentation_driver_planMarkdown()
               if
                  documentation_driver_kind(
                     file,
                     { md = true, markdown = true }
                  )
               then
                  --- Describe one selected documentation build target.
                  -- @param target any: selected target configuration or path.
                  -- @return nil: no values.
                  local function documentation_driver_planTarget(target)
                     if
                        not seen_pages[target]
                        and not markdown.excluded(target)
                        and artifact_io.exists(target)
                     then
                        documentation_driver_path(target)

                        seen_pages[target] = true
                        page_files[#page_files + 1] = target
                     end
                  end

                  for _, target in
                     ipairs(markdown.references(artifact_io.read(file), file))
                  do
                     documentation_driver_planTarget(target)
                  end
               end
            end

            documentation_driver_planMarkdown()

            page_index = page_index + 1
         end

         table.sort(page_files)
         assert(
            documentation_driver_kind(mainpage, { md = true, markdown = true }),
            "main page must be Markdown"
         )

         return page_files, mainpage
      end

      local page_files, mainpage = documentation_driver_selectPages()

      --- Validate image roots and deduplicate their containing directories.
      -- @return any, table: validate image roots and deduplicate their
      -- containing directories.
      local function documentation_driver_selectImages()
         local image_roots = {}

         for _, entry in ipairs(config.images or {}) do
            if artifact_io.exists(documentation_driver_path(entry)) then
               image_roots[#image_roots + 1] = entry
            end
         end

         for _, entry in ipairs(options.images or {}) do
            assert(
               artifact_io.exists(documentation_driver_path(entry)),
               "missing image root: " .. entry
            )

            image_roots[#image_roots + 1] = entry
         end

         local image_files =
            documentation_driver_inventory(image_roots, images, false)
         local image_directories, seen = {}, {}

         for _, file in ipairs(image_files) do
            local directory = file:match("^(.*)/[^/]+$")

            if directory and not seen[directory] then
               image_directories[#image_directories + 1] = directory
               seen[directory] = true
            end
         end

         return image_files, image_directories
      end

      local image_files, image_directories = documentation_driver_selectImages()

      local output = documentation_driver_path(
         options.output or (".cache/docs/doxygen-" .. options.mode)
      )

      assert(output:match("^%.cache/"), "output must stay below .cache/")
      for _, root in ipairs(implementations) do
         root = documentation_driver_path(root)
         assert(
            output ~= root and output:sub(1, #root + 1) ~= root .. "/",
            "output cannot be inside an implementation root"
         )
      end

      return {
         sources = source_files,
         pages = page_files,
         images = image_files,
         image_directories = image_directories,
         implementations = implementations,
         mainpage = mainpage,
         output = output,
      }
   end

   exports.plan = DOCUMENTATION_DRIVER_plan

   --- Build HTML/XML or evaluate the identical input set without rendering
   -- HTML.
   -- @param options table: operation settings; omitted fields use the
   -- documented defaults.
   -- @return any: hTML/XML or evaluate the identical input set without
   -- rendering HTML.
   local function DOCUMENTATION_DRIVER_run(options)
      local config_path = documentation_driver_path(
         options.config or "scripts/documentation/config.lua"
      )
      local config = dofile(config_path)
      local plan = exports.plan(options, config)
      local lock = dofile("scripts/toolchain/lib/lock.lua").load()
      local executable = os.getenv("LIBMEMALLOC_DOXYGEN") or "doxygen"
      local version = artifact_io
         .output({ executable, "--version" })
         :match("^(%d+%.%d+%.%d+)")

      assert(
         version == lock.doxygen.version,
         "Doxygen version must match toolchain.lock.toml"
      )

      local output = plan.output

      artifact_io.mkdir(output)

      local inputs = {}

      for _, file in ipairs(plan.sources) do
         inputs[#inputs + 1] = file
      end

      for _, file in ipairs(plan.pages) do
         inputs[#inputs + 1] = file
      end

      local resolved = "@INCLUDE = doxygen/config/Doxyfile\n"
         .. documentation_driver_setting("INPUT", inputs)
         .. documentation_driver_setting("INCLUDE_PATH", plan.implementations)
         .. documentation_driver_setting("IMAGE_PATH", plan.image_directories)
         .. documentation_driver_setting(
            "USE_MDFILE_AS_MAINPAGE",
            { plan.mainpage }
         )
         .. documentation_driver_setting("OUTPUT_DIRECTORY", { output })
         .. documentation_driver_setting(
            "WARN_LOGFILE",
            { output .. "/warnings.log" }
         )
         .. "MERMAID_RENDER_MODE = CLIENT_SIDE\n"
         .. "MERMAID_JS_URL = ./vendor/mermaid/mermaid.esm.min.mjs\n"
         .. "RECURSIVE = NO\nEXCLUDE_PATTERNS =\n"

      -- Only explicitly inventoried files reach INPUT; output and vendor trees
      -- cannot enter accidentally through Doxygen's recursive search.
      local layout = output .. "/layout.xml"

      artifact_io.run({ executable, "-l", layout })

      local layout_text = artifact_io.read(layout)

      layout_text = layout_text:gsub(
         '(<tab type="pages"[^>]*/>)',
         --- Insert the documentation navigation beside the hidden default pages
         -- tab.
         -- @param tab string: tab supplied to this operation.
         -- @return string: insert the documentation navigation beside the
         -- hidden default pages tab.
         function(tab)
            return markdown.navigation(plan.pages, config.references)
               .. "\n"
               .. tab:gsub('visible="[^"]+"', 'visible="no"')
         end,
         1
      )
      artifact_io.write(layout, layout_text)

      resolved = resolved
         .. documentation_driver_setting("LAYOUT_FILE", { layout })

      local theme_revision

      --- Stage the local browser assets for a documentation build.
      -- @return nil: no values.
      local function documentation_driver_stageAssets()
         if options.mode == "build" then
            local web_output = output .. "/web"

            artifact_io.run({
               "node",
               ".cache/tools/web/node_modules/typescript/bin/tsc",
               "--project",
               "tools/lint/code/web/tsconfig.json",
               "--outDir",
               web_output,
            })

            local logo = config.logo

            if config.logo_viewbox then
               logo = output .. "/libmemalloc-mascot.svg"

               local brand = dofile("scripts/documentation/lib/brand.lua")

               artifact_io.write(
                  logo,
                  brand.mascot(
                     artifact_io.read(config.logo),
                     config.logo_viewbox
                  )
               )
            end

            local theme = documentation_driver_path(config.theme)

            assert(
               artifact_io.exists(theme .. "/doxygen-awesome.css"),
               (
                  "initialize the theme: git submodule update "
                  .. "--init -- doxygen/vendor/doxygen-awesome-css"
               )
            )

            theme_revision =
               artifact_io.output({ "git", "-C", theme, "rev-parse", "HEAD" })

            -- Extend the matching Doxygen header rather than copying its
            -- template.
            local header = output .. "/header.html"

            artifact_io.run({
               executable,
               "-w",
               "html",
               header,
               output .. "/footer.html",
               output .. "/doxygen.css",
               "doxygen/config/Doxyfile",
            })

            -- Classic deferred scripts also load when opening the site via
            -- file://.
            local script = '<script defer="defer" '
               .. 'src="$relpath^code-highlight.js"'
               .. ' data-highlight-base="$relpath^vendor/highlight/es/"'
               .. "></script>\n"
            local header_text = artifact_io.read(header):gsub(
               "<title>.-</title>",
               "<title>libmemalloc</title>"
            )

            local favicon = ""

            if config.logo_viewbox then
               favicon = '<link rel="icon" type="image/svg+xml" '
                  .. 'href="$relpath^libmemalloc-mascot.svg">\n'
            end

            local extra_header = favicon
               .. '<script src="$relpath^reading.js"></script>\n'
               .. '<script defer="defer" src="$relpath^webmcp.js"></script>\n'
               .. '<script defer="defer" '
               .. 'src="$relpath^navigation.js"></script>\n'
               .. script
               .. "</head>"

            --- Preserve percent bytes in generated markup during replacement.
            -- @return any: preserve percent bytes in generated markup during
            -- replacement.
            local function documentation_driver_insertHeader()
               return extra_header
            end

            artifact_io.write(
               header,
               (
                  header_text:gsub(
                     "</head>",
                     documentation_driver_insertHeader,
                     1
                  )
               )
            )

            local footer = output .. "/footer.html"
            local footer_text = artifact_io
               .read(footer)
               :gsub('<li class="footer">.-</li>', "")
               :gsub('<hr class="footer"/>.-</address>', "")

            footer_text = footer_text:gsub(
               "</body>",
               --- Insert the licensed repository link before the generated body
               -- closes.
               -- @return string: insert the licensed repository link before the
               -- generated body closes.
               function()
                  return artifact_io.read(
                     "doxygen/web/templates/github-corner.html"
                  ) .. "</body>"
               end,
               1
            )
            artifact_io.write(footer, footer_text)

            resolved = resolved
               .. documentation_driver_setting("HTML_HEADER", { header })
               .. documentation_driver_setting("HTML_FOOTER", { footer })
               .. documentation_driver_setting("HTML_EXTRA_FILES", {
                  web_output .. "/code-highlight.js",
                  web_output .. "/reading.js",
                  web_output .. "/webmcp.js",
                  web_output .. "/navigation.js",
                  "doxygen/web/fonts/NunitoSans-Regular.ttf",
                  "doxygen/web/fonts/NunitoSans-Bold.ttf",
                  "doxygen/web/fonts/NunitoSans-OFL.txt",
                  "doxygen/web/fonts/JetBrainsMono-Regular.woff2",
                  "doxygen/web/fonts/JetBrainsMono-Bold.woff2",
                  "doxygen/web/fonts/JetBrainsMono-OFL.txt",
                  "doxygen/licenses/NORD-LICENSE.txt",
                  "doxygen/licenses/GITHUB-CORNER-LICENSE.txt",
               })
               .. documentation_driver_setting("HTML_EXTRA_STYLESHEET", {
                  theme .. "/doxygen-awesome.css",
                  theme .. "/doxygen-awesome-sidebar-only.css",
                  "doxygen/web/styles/libmemalloc.css",
                  "doxygen/web/styles/nord.css",
                  "doxygen/web/styles/reading.css",
               })
               .. documentation_driver_setting(
                  "GENERATE_TAGFILE",
                  { output .. "/libmemalloc.tag" }
               )
               .. documentation_driver_setting("PROJECT_LOGO", { logo })
               .. "GENERATE_HTML = YES\nGENERATE_XML = YES\n"
         else
            resolved = resolved
               .. "GENERATE_HTML = NO\nGENERATE_XML = YES\n"
               .. "XML_PROGRAMLISTING = NO\nHAVE_DOT = NO\n"
               .. "HTML_EXTRA_STYLESHEET =\nHTML_EXTRA_FILES "
               .. "=\nHTML_HEADER =\nHTML_FOOTER =\n"
               .. "GENERATE_TAGFILE =\nPROJECT_LOGO =\n"
         end
      end

      documentation_driver_stageAssets()

      -- Use the selected Lua executable in Doxygen's subprocess as well.
      local lua = os.getenv("LIBMEMALLOC_LUA") or "lua"
      local filter = artifact_io.platform.join_command({
         lua,
         "scripts/documentation/filter.lua",
      })

      assert(
         not filter:find('[\r\n"]') and not filter:find("$(", 1, true),
         "unsupported Lua executable path for the Doxyfile filter"
      )

      local filters = {}

      for extension in pairs(sources) do
         filters[#filters + 1] = '"*.' .. extension .. "=" .. filter .. '"'
      end

      local markdown_filter = artifact_io.platform.join_command({
         lua,
         "scripts/documentation/filter.lua",
      })

      filters[#filters + 1] = '"*.md=' .. markdown_filter .. '"'
      filters[#filters + 1] = '"*.markdown=' .. markdown_filter .. '"'
      table.sort(filters)

      resolved = resolved
         .. "FILTER_PATTERNS = "
         .. table.concat(filters, " ")
         .. "\n"
      artifact_io.write(output .. "/Doxyfile", resolved)

      artifact_io.write(output .. "/warnings.log", "")

      local manifest = {
         mode = options.mode,
         status = "running",
         doxygen = version,
         sources = artifact_io.array(plan.sources),
         pages = artifact_io.array(plan.pages),
         images = artifact_io.array(plan.images),
         theme_revision = theme_revision,
      }

      artifact_io.document(output .. "/manifest.json", manifest)

      local ok, message = pcall(
         --- Run Doxygen and validate its required outputs before accepting the
         -- build.
         -- @return nil: no values.
         function()
            local code = artifact_io.platform.execute({
               executable,
               output .. "/Doxyfile",
            })

            assert(code == 0, "Doxygen exited with status " .. code)
            assert(
               artifact_io.read(output .. "/warnings.log") == "",
               "Doxygen emitted warnings"
            )
            assert(
               artifact_io.exists(output .. "/xml/index.xml"),
               "Doxygen produced no XML index"
            )
            if options.mode == "build" then
               assert(
                  artifact_io.exists(output .. "/html/index.html"),
                  "Doxygen produced no HTML index"
               )

               -- Preserve repository-relative URLs used in literal HTML img
               -- elements.
               for _, file in ipairs(plan.images) do
                  artifact_io.write(
                     output .. "/html/" .. file,
                     artifact_io.read(file)
                  )
               end

               local vendor = output .. "/html/vendor"
               local modules = ".cache/tools/md/node_modules/"

               artifact_io.mkdir(vendor .. "/mermaid/chunks")
               artifact_io.run({
                  "cp",
                  "-R",
                  modules .. "mermaid/dist/chunks/mermaid.esm.min",
                  vendor .. "/mermaid/chunks/",
               })
               artifact_io.write(
                  vendor .. "/mermaid/mermaid.esm.min.mjs",
                  artifact_io.read(
                     modules .. "mermaid/dist/mermaid.esm.min.mjs"
                  )
               )
               artifact_io.write(
                  vendor .. "/mermaid/LICENSE",
                  artifact_io.read(modules .. "mermaid/LICENSE")
               )
               artifact_io.run({
                  "cp",
                  "-R",
                  modules .. "@highlightjs/cdn-assets",
                  vendor .. "/highlight",
               })

               dofile("scripts/documentation/lib/html.lua").publish(
                  output .. "/html",
                  artifact_io
               )
            end
         end
      )

      manifest.status = ok and "passed" or "failed"
      artifact_io.document(output .. "/manifest.json", manifest)
      assert(
         ok,
         tostring(message)
            .. "\n"
            .. artifact_io.read(output .. "/warnings.log")
      )

      print("Doxygen " .. options.mode .. " passed: " .. output)

      return plan
   end

   exports.run = DOCUMENTATION_DRIVER_run

   return exports
end

return scripts_documentation_lib_driver_loadModule()

-- EOF


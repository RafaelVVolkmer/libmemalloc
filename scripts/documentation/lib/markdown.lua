-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Adapt repository Markdown to Doxygen without changing authored documents.
-- Part of Doxygen generation and authored-document validation.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_documentation_lib_markdown_loadModule()
   local MARKDOWN_DOCS_PREFIX = "docs/"

   local MARKDOWN_GITHUB_COM_BLOB_MAIN_URL =
      "https://github.com/RafaelVVolkmer/libmemalloc/blob/main/"

   local exports = {}

   -- Only known language identifiers may enter HTML attributes or asset paths.
   local languages = {
      c = "c",
      h = "c",
      cpp = "cpp",
      ["c++"] = "cpp",
      hpp = "cpp",
      rust = "rust",
      rs = "rust",
      compile_fail = "rust",
      lua = "lua",
      sh = "bash",
      bash = "bash",
      shell = "bash",
      cmake = "cmake",
      yaml = "yaml",
      yml = "yaml",
      json = "json",
      python = "python",
      py = "python",
      javascript = "javascript",
      js = "javascript",
      toml = "ini",
      ini = "ini",
      diff = "diff",
      xml = "xml",
      html = "xml",
      css = "css",
      markdown = "markdown",
      md = "markdown",
   }

   --- Encode a source path as a collision-resistant Doxygen page identifier.
   -- @param path string: filesystem path selected by the caller.
   -- @return string: a source path as a collision-resistant Doxygen page
   -- identifier.
   local function DOCUMENTATION_MARKDOWN_identifier(path)
      return "lma_"
         .. path:gsub(
            "[^%w]",
            --- Encode one path byte without depending on locale-specific
            -- character
            -- classes.
            -- @param byte string: byte supplied to this operation.
            -- @return any: one path byte without depending on locale-specific
            -- character classes.
            function(byte)
               return string.format("_%02x", byte:byte())
            end
         )
   end

   exports.identifier = DOCUMENTATION_MARKDOWN_identifier

   --- Resolve relative path segments before mapping a documentation link.
   -- @param path string: filesystem path selected by the caller.
   -- @return any: relative path segments before mapping a documentation link.
   local function documentation_markdown_normalize(path)
      local parts = {}

      for part in path:gmatch("[^/]+") do
         if part == ".." then
            assert(#parts > 0, "Markdown link escapes the repository")

            table.remove(parts)
         elseif part ~= "." then
            parts[#parts + 1] = part
         end
      end

      return table.concat(parts, "/")
   end

   --- Directory README files are repository indexes, not published pages.
   -- @param path string: filesystem path selected by the caller.
   -- @return boolean|nil: directory README files are repository indexes, not
   -- published pages.
   local function DOCUMENTATION_MARKDOWN_excluded(path)
      path = documentation_markdown_normalize(path)

      return path:match("^docs/") ~= nil
         and path:match("[^/]+$"):lower() == "readme.md"
   end

   exports.excluded = DOCUMENTATION_MARKDOWN_excluded

   --- Build a page-qualified anchor so equal section names on different pages
   -- remain distinct.
   -- @param path string: filesystem path selected by the caller.
   -- @param name string: entry or operation name to resolve.
   -- @return string: a page-qualified anchor so equal section names on
   -- different pages remain distinct.
   local function documentation_markdown_anchor(path, name)
      return exports.identifier(path) .. "_" .. name
   end

   --- Derive the Markdown heading fragment while retaining permitted
   -- separators.
   -- @param title string: title supplied to this operation.
   -- @return any: the Markdown heading fragment while retaining permitted
   -- separators.
   local function documentation_markdown_slug(title)
      return title
         :lower()
         :gsub("<[^>]+>", "")
         :gsub(
            "[%p]",
            --- Retain only the separators supported by heading fragments.
            -- @param c any: c supplied to this operation.
            -- @return any: retain only the separators supported by heading
            -- fragments.
            function(c)
               return (c == "-" or c == "_") and c or ""
            end
         )
         :gsub("%s", "-")
   end

   --- Escape literal text before placing it in generated HTML.
   -- @param value any: value supplied to this operation.
   -- @return any: escape literal text before placing it in generated HTML.
   local function documentation_markdown_escapeHtml(value)
      return value
         :gsub("&", "&amp;")
         :gsub('"', "&quot;")
         :gsub("<", "&lt;")
         :gsub(">", "&gt;")
   end

   --- Collect badge definitions before rendering same-page image links.
   -- Doxygen leaves image-reference syntax literal inside same-page badge
   -- links.
   -- Collect definitions separately because badges commonly precede their URLs.
   -- @param source any: source value inspected by this operation.
   -- @return table: reference labels mapped to their authored image URLs.
   local function documentation_markdown_badgeReferences(source)
      local references, fence, pending = {}, nil, nil

      --- Record a badge reference from one authored Markdown line.
      -- @param source_line string: source line to inspect.
      -- @return nil: no values.
      local function documentation_markdown_collectBadge(source_line)
         local line = source_line
         local marker = line:match("^%s*(```+)") or line:match("^%s*(~~~+)")

         if marker then
            if not fence then
               fence = marker
            elseif
               marker:sub(1, 1) == fence:sub(1, 1) and #marker >= #fence
            then
               fence = nil
            end
         elseif not fence then
            local name, target = line:match("^%s*%[([^%]]+)%]:%s*(.*)$")

            if name then
               pending = name:lower()
            end

            --- Resolve a pending badge reference without consuming fenced
            -- content.
            -- @return nil: no values.
            local function documentation_markdown_resolveBadge()
               if pending then
                  target = (target or line):match("^%s*(%S+)")
                  if target then
                     references[pending] = target
                     pending = nil
                  end
               end
            end

            documentation_markdown_resolveBadge()
         end
      end

      for source_line in (source .. "\n"):gmatch("(.-)\n") do
         documentation_markdown_collectBadge(source_line)
      end

      return references
   end

   --- Scope explicit and implicit anchors to their page; protect code fences.
   -- @param source any: source value inspected by this operation.
   -- @param path string: filesystem path selected by the caller.
   -- @return any: scope explicit and implicit anchors to their page; protect
   -- code fences.
   local function DOCUMENTATION_MARKDOWN_filter(source, path)
      local result, fence, counts, defined = {}, nil, {}, {}
      local references = documentation_markdown_badgeReferences(source)
      local quote_prefix = ""
      local fence_end = "@endverbatim"
      local highlighted = false
      local pending_reference = false
      local directory = path:match("^(.*)/")
      local prefix = directory and (directory .. "/") or ""

      --- Resolve a source link against its page and preserve external
      -- destinations.
      -- @param target string: target supplied to this operation.
      -- @return any: a source link against its page and preserve external
      -- destinations.
      local function documentation_markdown_link(target)
         if target:match("^#") then
            return "#" .. documentation_markdown_anchor(path, target:sub(2))
         end

         if target:match("^[%w+.-]+:") then
            return target
         end

         local local_file = target:match("^([^#]+)")

         if local_file and exports.excluded(prefix .. local_file) then
            return MARKDOWN_GITHUB_COM_BLOB_MAIN_URL
               .. documentation_markdown_normalize(prefix .. local_file)
               .. (target:match("(#.*)$") or "")
         end

         local file, fragment = target:match("^(.-%.md)#(.+)$")

         if file then
            return "@ref "
               .. documentation_markdown_anchor(
                  documentation_markdown_normalize(prefix .. file),
                  fragment
               )
         end

         return target
      end

      --- Transform one Markdown line while preserving fence and table state.
      -- @param source_line string: source line to inspect.
      -- @return nil: no values.
      local function documentation_markdown_filterLine(source_line)
         local line = source_line
         local quote, content = line:match("^(%s*>%s?)(.*)$")

         content = content or line

         local marker, info = content:match("^%s*(```+)(.*)$")

         if not marker then
            marker, info = content:match("^%s*(~~~+)(.*)$")
         end

         if fence then
            --- Close a matching fence or preserve its literal content.
            -- @return nil: no values.
            local function documentation_markdown_continueFence()
               if
                  marker
                  and marker:sub(1, 1) == fence:sub(1, 1)
                  and #marker >= #fence
                  and info:match("^%s*$")
               then
                  result[#result + 1] = quote_prefix .. fence_end
                  if highlighted then
                     result[#result + 1] = quote_prefix
                        .. "@htmlonly </div> @endhtmlonly"
                  end

                  fence = nil
               else
                  assert(
                     not line:find(fence_end, 1, true),
                     "reserved Doxygen fence terminator in " .. path
                  )

                  result[#result + 1] = line
               end
            end

            documentation_markdown_continueFence()
         elseif marker then
            --- Translate an opening fence and initialize its highlighting
            -- state.
            -- @return nil: no values.
            local function documentation_markdown_openFence()
               fence = marker
               quote_prefix = quote or ""

               local is_diagram = info:match("^%s*mermaid%s*$") ~= nil
               local language = info:match("^%s*{%.?([%w_+%-]+)}%s*$")
                  or info:match("^%s*%.?([%w_+%-]+)%s*$")

               language = language and languages[language:lower()]
               highlighted = language ~= nil
               if highlighted then
                  result[#result + 1] = quote_prefix
                     .. '@htmlonly <div class="lma-code" data-language="'
                     .. language
                     .. '"> @endhtmlonly'
               end

               fence_end = is_diagram and "@endmermaid" or "@endverbatim"
               result[#result + 1] = quote_prefix
                  .. (is_diagram and "@mermaid" or "@verbatim")
            end

            documentation_markdown_openFence()
         else
            line = line:gsub(
               "%[%!%[([^%]]*)%]%[([^%]]+)%]%]%[([^%]]+)%]",

               --- Resolve a linked image from its reference definitions.
               -- @param alt any: alt supplied to this operation.
               -- @param image string: image supplied to this operation.
               -- @param destination string: destination path owned by the
               -- invoking operation.
               -- @return string: a linked image from its reference definitions.
               function(alt, image, destination)
                  local src = references[image:lower()]
                  local target = references[destination:lower()]

                  if
                     src
                     and src:match("^https?://")
                     and target
                     and target:match("^#")
                  then
                     return '<a href="'
                        .. documentation_markdown_escapeHtml(
                           documentation_markdown_link(target)
                        )
                        .. '"><img src="'
                        .. documentation_markdown_escapeHtml(src)
                        .. '" alt="'
                        .. documentation_markdown_escapeHtml(alt)
                        .. '"></a>'
                  end
               end
            )

            -- HTML images are relative to generated pages, not the repository
            -- root.
            line = line:gsub('(src%s*=%s*")/assets/', "%1assets/")
            if pending_reference then
               line = line:gsub(
                  "^(%s*)(%S+)",
                  --- Rewrite an inline destination through the page-local link
                  -- resolver.
                  -- @param a any: first comparison entry.
                  -- @param target any: selected target configuration or path.
                  -- @return string: rewrite an inline destination through the
                  -- page-local link resolver.
                  function(a, target)
                     return a .. documentation_markdown_link(target)
                  end
               )
            end

            pending_reference = line:match("^%s*%[[^%]]+%]:%s*$") ~= nil

            -- Explicit HTML anchors are global in Doxygen, unlike in GitHub.
            line = line:gsub(
               '(<a%s+id=")([^"]+)(")',
               --- Record an explicit anchor and qualify it with its source
               -- page.
               -- @param a any: first comparison entry.
               -- @param name string: entry or operation name to resolve.
               -- @param b any: second comparison entry.
               -- @return string: record an explicit anchor and qualify it with
               -- its source page.
               function(a, name, b)
                  defined[name] = true

                  return a .. documentation_markdown_anchor(path, name) .. b
               end
            )
            line = line:gsub(
               "(%]%()([^%)]+)(%))",
               --- Rewrite a quoted destination while preserving surrounding
               -- delimiters.
               -- @param a any: first comparison entry.
               -- @param target any: selected target configuration or path.
               -- @param b any: second comparison entry.
               -- @return string: rewrite a quoted destination while preserving
               -- surrounding delimiters.
               function(a, target, b)
                  return a .. documentation_markdown_link(target) .. b
               end
            )
            line = line:gsub(
               "^(%s*%[[^%]]+%]:%s*)(%S+)",
               --- Rewrite a reference destination through the same resolver as
               -- inline links.
               -- @param a any: first comparison entry.
               -- @param target any: selected target configuration or path.
               -- @return string: rewrite a reference destination through the
               -- same resolver as inline links.
               function(a, target)
                  return a .. documentation_markdown_link(target)
               end
            )

            local after_heading
            local hashes, title = line:match("^(#+)%s+(.+)$")

            --- Normalize an authored heading and emit its stable anchor.
            -- @return nil: no values.
            local function documentation_markdown_emitHeading()
               if hashes then
                  local explicit = title:match("%s*{#([^}]+)}%s*$")

                  if explicit then
                     line = line:gsub(
                        "{#[^}]+}%s*$",
                        "{#"
                           .. documentation_markdown_anchor(path, explicit)
                           .. "}"
                     )
                  else
                     local name = documentation_markdown_slug(title)
                     local count = counts[name] or 0

                     counts[name] = count + 1
                     if count > 0 then
                        name = name .. "-" .. count
                     end

                     --- Emit each implicit heading anchor once, preserving
                     -- heading placement.
                     -- @return nil: no values.
                     local function documentation_markdown_defineAnchor()
                        if not defined[name] then
                           local tag = '<a id="'
                              .. documentation_markdown_anchor(path, name)
                              .. '"></a>'

                           if #hashes == 1 then
                              after_heading = tag
                           else
                              result[#result + 1] = tag
                           end

                           defined[name] = true
                        end
                     end

                     documentation_markdown_defineAnchor()
                  end
               end
            end

            documentation_markdown_emitHeading()

            result[#result + 1] = line
            if after_heading then
               result[#result + 1] = after_heading
            end
         end
      end

      for source_line in (source .. "\n"):gmatch("(.-)\n") do
         documentation_markdown_filterLine(source_line)
      end

      assert(not fence, "unclosed Markdown fence in " .. path)

      return table.concat(result, "\n")
   end

   exports.filter = DOCUMENTATION_MARKDOWN_filter

   --- Find local Markdown link targets, excluding illustrative code blocks.
   -- @param source any: source value inspected by this operation.
   -- @param path string: filesystem path selected by the caller.
   -- @return table: local Markdown link targets, excluding illustrative code
   -- blocks.
   local function DOCUMENTATION_MARKDOWN_references(source, path)
      local targets, fence, pending = {}, nil, false
      local prefix = (path:match("^(.*)/") or ".") .. "/"

      --- Retain one navigation target without duplicating a page entry.
      -- @param target string: target supplied to this operation.
      -- @return nil: no values.
      local function documentation_markdown_record(target)
         target = target:match("^([^#]+)") or ""
         if target:match("%.md$") and not target:match("^[%w+.-]+:") then
            targets[#targets + 1] =
               documentation_markdown_normalize(prefix .. target)
         end
      end

      --- Collect documentation references from one authored Markdown line.
      -- @param source_line string: source line to inspect.
      -- @return nil: no values.
      local function documentation_markdown_collectReferences(source_line)
         local line = source_line
         local content = line:gsub("^%s*>%s?", "")
         local marker = content:match("^%s*(```+)")
            or content:match("^%s*(~~~+)")

         --- Collect only references outside literal fenced blocks.
         -- @return nil: no values.
         local function documentation_markdown_scanReferenceLine()
            if marker then
               --- Open or close the current reference-scanning fence.
               -- @return nil: no values.
               local function documentation_markdown_updateReferenceFence()
                  if not fence then
                     fence = marker
                  elseif
                     marker:sub(1, 1) == fence:sub(1, 1)
                     and #marker >= #fence
                  then
                     fence = nil
                  end
               end

               documentation_markdown_updateReferenceFence()
            elseif not fence then
               if pending then
                  documentation_markdown_record(line:match("^%s*(%S+)") or "")
               end

               for target in line:gmatch("%]%(([^%s%)]+)") do
                  documentation_markdown_record(target)
               end

               local target = line:match("^%s*%[[^%]]+%]:%s*(%S+)")

               if target then
                  documentation_markdown_record(target)
               end

               pending = line:match("^%s*%[[^%]]+%]:%s*$") ~= nil
            end
         end

         documentation_markdown_scanReferenceLine()
      end

      for source_line in (source .. "\n"):gmatch("(.-)\n") do
         documentation_markdown_collectReferences(source_line)
      end

      return targets
   end

   exports.references = DOCUMENTATION_MARKDOWN_references

   --- Generate sidebar directories from the selected original Markdown paths.
   -- @param files table: ordered source or artifact paths.
   -- @param references any|nil: references supplied to this operation.
   -- @return string: sidebar directories from the selected original Markdown
   -- paths.
   local function DOCUMENTATION_MARKDOWN_navigation(files, references)
      local tree = { directories = {}, files = {} }

      for _, file in ipairs(files) do
         if file:match("^docs/.*%.md$") then
            local node = tree
            local relative = file:sub(#MARKDOWN_DOCS_PREFIX + 1)

            for part in relative:gmatch("([^/]+)/") do
               node.directories[part] = node.directories[part]
                  or { directories = {}, files = {} }
               node = node.directories[part]
            end

            node.files[#node.files + 1] = file
         end
      end

      --- Escape a navigation value for its generated XML attribute.
      -- @param value any: value supplied to this operation.
      -- @return any: escape a navigation value for its generated XML attribute.
      local function documentation_markdown_escape(value)
         return value
            :gsub("&", "&amp;")
            :gsub('"', "&quot;")
            :gsub("<", "&lt;")
            :gsub(">", "&gt;")
      end

      --- Render a navigation node and its descendants from the page tree.
      -- @param node table: node supplied to this operation.
      -- @return any: a navigation node and its descendants from the page tree.
      local function documentation_markdown_render(node)
         local output, names = {}, {}

         for name in pairs(node.directories) do
            names[#names + 1] = name
         end

         table.sort(names)
         for _, name in ipairs(names) do
            output[#output + 1] = '<tab type="usergroup" title="'
               .. documentation_markdown_escape(name)
               .. '">'
            output[#output + 1] =
               documentation_markdown_render(node.directories[name])
            output[#output + 1] = "</tab>"
         end

         table.sort(node.files)
         for _, file in ipairs(node.files) do
            output[#output + 1] = '<tab type="user" title="'
               .. documentation_markdown_escape(file:match("[^/]+$"))
               .. '" url="@ref '
               .. documentation_markdown_escape(file)
               .. '"/>'
         end

         return table.concat(output, "\n")
      end

      local result = '<tab type="usergroup" title="Documentation">\n'
         .. documentation_markdown_render(tree)
         .. "\n</tab>"
      local supporting = {}

      for _, entry in ipairs(references or {}) do
         supporting[#supporting + 1] = '<tab type="user" title="'
            .. documentation_markdown_escape(entry.title)
            .. '" url="@ref '
            .. documentation_markdown_escape(entry.target or entry.path)
            .. '"/>'
      end

      if #supporting > 0 then
         result = result
            .. '\n<tab type="usergroup" title="Project references">\n'
            .. table.concat(supporting, "\n")
            .. "\n</tab>"
      end

      return result
   end

   exports.navigation = DOCUMENTATION_MARKDOWN_navigation

   return exports
end

return scripts_documentation_lib_markdown_loadModule()

-- EOF


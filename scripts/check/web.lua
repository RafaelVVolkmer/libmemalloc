-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Validate authored web sources selected by the caller or the CI change map.
-- Uses the hash-locked npm graph; never installs dependencies during a check.

--- Discover owned files and run the applicable language validators.
-- @return nil: no values.
local function WEB_main()
   local io_tools = dofile("scripts/lib/artifacts.lua")
   local allowed =
      { html = true, css = true, javascript = true, typescript = true }
   local options = io_tools.options(arg, allowed)
   local WEB_ARGV_BATCH_SIZE = 64
   local all = next(options) == nil
   local groups = { html = {}, css = {}, javascript = {}, typescript = {} }
   local extensions = {
      html = "html",
      htm = "html",
      css = "css",
      js = "javascript",
      mjs = "javascript",
      cjs = "javascript",
      jsx = "javascript",
      ts = "typescript",
      tsx = "typescript",
      mts = "typescript",
      cts = "typescript",
   }
   local node = os.getenv("LIBMEMALLOC_NODE") or "node"
   local tools = ".cache/tools/web/node_modules/"

   for _, value in pairs(options) do
      assert(
         value == true or value == "true" or value == "false",
         "expected a boolean language selector"
      )
   end

   local git = dofile("scripts/lib/git.lua").new(io_tools.platform, ".")
   local tracked = assert(git.working_files(), "cannot list working sources")

   for _, path in ipairs(tracked) do
      local group = extensions[path:match("%.([^.]+)$")]

      if group and not path:match("^doxygen/vendor/") then
         groups[group][#groups[group] + 1] = path
      end
   end

   --- Run the configured formatter and analyzer for one web language.
   -- @param language any: language supplied to this operation.
   -- @return nil: no values.
   local function web_checkLanguage(language)
      local selected = all
         or options[language] == true
         or options[language] == "true"
      local files = groups[language]

      if selected and #files > 0 then
         local command

         if language == "html" then
            command = {
               node,
               tools .. "html-validate/bin/html-validate.mjs",
               "--config",
               "tools/lint/code/web/htmlvalidate.json",
            }
         else
            command = {
               node,
               tools .. "@biomejs/biome/bin/biome",
               "lint",
               "--config-path",
               "tools/lint/code/web/biome-config.json",
            }
         end

         io_tools.platform.run_batched(command, files, WEB_ARGV_BATCH_SIZE)
         if language == "typescript" then
            io_tools.run({
               node,
               tools .. "typescript/bin/tsc",
               "--project",
               "tools/lint/code/web/tsconfig.json",
               "--noEmit",
            })
         end

         print("Web checks: " .. language .. " (" .. #files .. " files)")
      elseif selected then
         print("Web checks: no indexed " .. language .. " files")
      end
   end

   for _, language in ipairs({ "html", "css", "javascript", "typescript" }) do
      web_checkLanguage(language)
   end
end

return WEB_main()

-- EOF


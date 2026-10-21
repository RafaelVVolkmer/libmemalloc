-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Run one shared source spelling policy locally and in CI.
-- Every scanner receives working sources instead of generated dependency trees.

--- Preserve each scanner result and fail when any selected scanner fails.
-- @return nil: no values.
local function SPELLING_main()
   local SPELLING_ARGV_BATCH_SIZE = 64

   local artifacts = dofile("scripts/lib/artifacts.lua")
   local git = dofile("scripts/lib/git.lua").new(artifacts.platform, ".")
   local options = artifacts.options(arg, { tool = true })
   local prose, text = {}, {}
   local prose_extensions = {
      c = true,
      h = true,
      cpp = true,
      hpp = true,
      md = true,
      markdown = true,
      mdx = true,
      rst = true,
      adoc = true,
   }
   local source_extensions = {
      lua = true,
      py = true,
      cmake = true,
      txt = true,
      yml = true,
      yaml = true,
      json = true,
      jsonc = true,
      toml = true,
      sh = true,
      ps1 = true,
      ts = true,
      js = true,
      cjs = true,
      css = true,
      html = true,
      nix = true,
   }

   --- Assign one source to its applicable spelling inventories.
   -- @param path string: filesystem path selected by the caller.
   -- @return nil: no values.
   local function spelling_collectSource(path)
      local extension = path:match("%.([^./]+)$")

      if prose_extensions[extension] then
         prose[#prose + 1] = path
      end

      if
         (prose_extensions[extension] or source_extensions[extension])
         and path ~= "package-lock.json"
         and not path:match("/package%-lock%.json$")
      then
         text[#text + 1] = path
      end
   end

   for _, path in ipairs(assert(git.working_files())) do
      spelling_collectSource(path)
   end

   local scanners = {
      cspell = {
         "cspell",
         "lint",
         "--config",
         "tools/lint/spell/cspell/cspell.jsonc",
         "--no-progress",
         "--no-summary",
      },
      codespell = {
         "codespell",
         "--config",
         "tools/lint/spell/codespell/.codespellrc",
      },
      typos = { "typos", "--config", "tools/lint/spell/typos/typos.toml" },
      vale = {
         "vale",
         "--no-global",
         "--config",
         "tools/lint/spell/vale/.vale.ini",
         "--minAlertLevel=error",
         "--output=line",
      },
   }

   assert(not options.tool or scanners[options.tool], "unknown spelling tool")
   local failed = 0

   --- Execute one spelling scanner and retain its failure count.
   -- @param name string: entry or operation name to resolve.
   -- @return nil: no values.
   local function spelling_runScanner(name)
      if not options.tool or options.tool == name then
         local files = (name == "cspell" or name == "vale") and prose or text
         local ok, reason = pcall(
            artifacts.platform.run_batched,
            scanners[name],
            files,
            SPELLING_ARGV_BATCH_SIZE
         )

         if not ok then
            failed = failed + 1
            io.stderr:write(tostring(reason) .. "\n")
         end

         print(name .. ": " .. (ok and "PASS" or "FAIL"))
      end
   end

   for _, name in ipairs({ "cspell", "codespell", "typos", "vale" }) do
      spelling_runScanner(name)
   end

   assert(failed == 0, "source spelling failed")
end

return SPELLING_main()

-- EOF


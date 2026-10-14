-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Compare resolved tool versions with the same lock used by hosted jobs.
-- Build compilers keep their separate platform and campaign identities.

--- Construct exact-version probes without installing tools.
-- @return table: public operations constructed by this module.
local function VERSIONS_loadModule()
   local exports = {}
   local probes = {
      node = { "node", "--version" },
      cspell = { "cspell", "--version" },
      codespell = { "codespell", "--version" },
      typos = { "typos", "--version" },
      vale = { "vale", "--version" },
      lychee = { "lychee", "--version" },
      lua = { "lua", "-v" },
      actionlint = { "actionlint", "--version" },
      clang_format = { "clang-format", "--version" },
      clang_tidy = { "clang-tidy", "--version" },
      cppcheck = { "cppcheck", "--version" },
      flawfinder = { "flawfinder", "--version" },
      selene = { "selene", "--version" },
      stylua = { "stylua", "--version" },
      lua_language_server = { "lua-language-server", "--version" },
      build_cmake = { "cmake", "--version" },
      gitleaks = { "gitleaks", "version" },
      zizmor = { "zizmor", "--version" },
      yamllint = { "yamllint", "--version" },
      biome = { "biome", "--version" },
      taplo = { "taplo", "--version" },
      reuse = { "reuse", "--version" },
      ruff = { "ruff", "--version" },
      pyright = { "pyright", "--version" },
      bandit = { "bandit", "--version" },
      doxygen = { "doxygen", "--version" },
      editorconfig_checker = { "ec", "--version" },
   }
   local spelling = {
      node = true,
      cspell = true,
      codespell = true,
      typos = true,
      vale = true,
      lychee = true,
   }

   --- Require a complete version token; reject longer and shorter releases.
   -- @param output string: output supplied to this operation.
   -- @param expected any: expected reference value used by this check.
   -- @return boolean: require a complete version token; reject longer and
   -- shorter releases.
   local function VERSIONS_matches(output, expected)
      if not output then
         return false
      end

      for token in output:gmatch("[%d][%w.+%-]*") do
         if token == expected then
            return true
         end
      end

      return false
   end

   exports.matches = VERSIONS_matches

   --- Report every version mismatch together with its resolved executable path.
   -- @param platform table: host operations supplied by the caller.
   -- @param lock any: lock supplied to this operation.
   -- @param profile any: selected configuration profile.
   -- @return boolean: report every version mismatch together with its resolved
   -- executable path.
   local function VERSIONS_check(platform, lock, profile)
      assert(
         profile == "all" or profile == "spelling",
         "unknown version profile"
      )
      local names, failures = {}, 0

      for name in pairs(probes) do
         if profile == "all" or spelling[name] then
            names[#names + 1] = name
         end
      end

      table.sort(names)

      --- Compare one resolved validator with its reviewed version token.
      -- @param name string: entry or operation name to resolve.
      -- @return nil: no values.
      local function versions_checkTool(name)
         local argv = probes[name]
         local output = platform.command_output(argv)
         local expected = lock[name].reported_version or lock[name].version
         local passed = exports.matches(output, expected)
         local path = platform.command_output({ "which", argv[1] })
            or "unavailable"

         if not passed then
            failures = failures + 1
         end

         print(
            (passed and "OK " or "DRIFT ")
               .. name
               .. " "
               .. lock[name].version
               .. ": "
               .. path:gsub("[\r\n]+$", "")
         )
      end

      for _, name in ipairs(names) do
         versions_checkTool(name)
      end

      return failures == 0
   end

   exports.check = VERSIONS_check

   return exports
end

return VERSIONS_loadModule()

-- EOF


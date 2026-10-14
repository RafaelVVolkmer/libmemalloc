-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Override Linux archive layouts with native Apple Silicon or Intel releases.
-- @return any: override Linux archive layouts with native Apple Silicon or
-- Intel releases.
local function QUALITY_MACOS_loadModule()
   --- Apply only the platform-specific archive fields to a fresh catalog.
   -- @param catalog table: reviewed catalog of supported entries.
   -- @param architecture any: architecture supplied to this operation.
   -- @return any: apply only the platform-specific archive fields to a fresh
   -- catalog.
   return function(catalog, architecture)
      local cpu = assert(
         ({
            arm64 = {
               go = "arm64",
               short = "arm64",
               rust = "aarch64",
               vale = "arm64",
            },
            x86_64 = {
               go = "amd64",
               short = "x64",
               rust = "x86_64",
               vale = "64-bit",
            },
         })[architecture],
         "unsupported macOS architecture"
      )
      local go, short, rust = cpu.go, cpu.short, cpu.rust
      local files = {
         node = "node-v{version}-darwin-" .. short .. ".tar.gz",
         actionlint = "actionlint_{version}_darwin_" .. go .. ".tar.gz",
         editorconfig_checker = "ec-darwin-" .. go .. ".tar.gz",
         gitleaks = "gitleaks_{version}_darwin_" .. short .. ".tar.gz",
         lychee = "lychee-" .. rust .. "-apple-darwin.tar.gz",
         typos = "typos-v{version}-" .. rust .. "-apple-darwin.tar.gz",
         vale = "vale_{version}_macOS_" .. cpu.vale .. ".tar.gz",
         zizmor = "zizmor-" .. rust .. "-apple-darwin.tar.gz",
         stylua = "stylua-macos-" .. rust .. ".zip",
         lua_language_server = "lua-language-server-{version}-darwin-"
            .. short
            .. ".tar.gz",
         doxygen = "doxygen-{version}.src.tar.gz",
      }

      for name, filename in pairs(files) do
         local tool = assert(catalog[name], "missing native tool: " .. name)

         tool.url = tool.url:gsub("[^/]+$", filename)
      end

      catalog.node.bin = "node-v{version}-darwin-" .. short .. "/bin"
      catalog.editorconfig_checker.commands = { ec = "ec-darwin-" .. go }
      catalog.lychee.bin = "lychee-" .. rust .. "-apple-darwin"
      catalog.doxygen.url = "https://github.com/doxygen/doxygen/releases/"
         .. "download/Release_{underscored_version}/"
         .. "doxygen-{version}.src.tar.gz"
      catalog.doxygen.archive = "source"
      catalog.doxygen.bin = "install/bin"

      return catalog
   end
end

return QUALITY_MACOS_loadModule()

-- EOF


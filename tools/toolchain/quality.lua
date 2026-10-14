-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Native quality tools shared by explicit local setup and hosted workflows.
-- Versions and archive digests come exclusively from tools/toolchain/lock.toml.
-- @return any: native quality tools shared by explicit local setup and hosted
-- workflows.
local function QUALITY_CATALOG_loadModule()
   local catalog = {
      node = {
         archive = "tar",
         url = "https://nodejs.org/"
            .. "dist/v{version}/node-v{version}-linux-x64.tar.xz",
         bin = "node-v{version}-linux-x64/bin",
         commands = { "node", "npm", "npx" },
      },
      actionlint = {
         archive = "tar",
         url = "https://github.com/"
            .. "rhysd/actionlint/releases/download/v{version}/"
            .. "actionlint_{version}_linux_amd64.tar.gz",
         bin = ".",
         commands = { "actionlint" },
      },
      editorconfig_checker = {
         archive = "tar",
         url = "https://github.com/"
            .. "editorconfig-checker/editorconfig-checker/releases/"
            .. "download/v{version}/ec-linux-amd64.tar.gz",
         bin = "bin",
         commands = { ec = "ec-linux-amd64" },
      },
      gitleaks = {
         archive = "tar",
         url = "https://github.com/"
            .. "gitleaks/gitleaks/releases/download/v{version}/"
            .. "gitleaks_{version}_linux_x64.tar.gz",
         bin = ".",
         commands = { "gitleaks" },
      },
      lychee = {
         archive = "tar",
         url = "https://github.com/"
            .. "lycheeverse/lychee/releases/download/lychee-v{version}/"
            .. "lychee-x86_64-unknown-linux-gnu.tar.gz",
         bin = "lychee-x86_64-unknown-linux-gnu",
         commands = { "lychee" },
      },
      typos = {
         archive = "tar",
         url = "https://github.com/"
            .. "crate-ci/typos/releases/download/v{version}/"
            .. "typos-v{version}-x86_64-unknown-linux-musl.tar.gz",
         bin = ".",
         commands = { "typos" },
      },
      vale = {
         archive = "tar",
         url = "https://github.com/"
            .. "vale-cli/vale/releases/download/v{version}/"
            .. "vale_{version}_Linux_64-bit.tar.gz",
         bin = ".",
         commands = { "vale" },
      },
      zizmor = {
         archive = "tar",
         url = "https://github.com/"
            .. "zizmorcore/zizmor/releases/download/v{version}/"
            .. "zizmor-x86_64-unknown-linux-gnu.tar.gz",
         bin = ".",
         commands = { "zizmor" },
      },
      stylua = {
         archive = "zip",
         url = "https://github.com/"
            .. "JohnnyMorganz/StyLua/releases/download/v{version}/"
            .. "stylua-linux-x86_64.zip",
         bin = ".",
         commands = { "stylua" },
      },
      lua_language_server = {
         archive = "tar",
         url = "https://github.com/"
            .. "LuaLS/lua-language-server/releases/download/{version}/"
            .. "lua-language-server-{version}-linux-x64.tar.gz",
         bin = "bin",
         commands = { "lua-language-server" },
      },
      doxygen = {
         archive = "tar",
         url = "https://www.doxygen.nl/"
            .. "files/doxygen-{version}.linux.bin.tar.gz",
         bin = "doxygen-{version}/bin",
         commands = { "doxygen" },
      },
   }
   local platform = dofile("scripts/lib/platform.lua")
   if platform.command_output({ "uname", "-s" }) == "Darwin\n" then
      local architecture =
         assert(platform.command_output({ "uname", "-m" })):gsub("%s+$", "")

      return dofile("tools/toolchain/quality_macos.lua")(catalog, architecture)
   end

   return catalog
end

return QUALITY_CATALOG_loadModule()

-- EOF


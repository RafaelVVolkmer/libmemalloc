-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Formatter adapters for the shared read-only check entrypoint.
-- {root} expands to the checkout root; the executable is supplied by the
-- caller.

--- Construct this module within its own initialization scope.
-- @return table: this module within its own initialization scope.
local function tools_lint_formatters_loadModule()
   return {
      haskell = {
         arguments = {
            "--no-cabal",
            "--mode",
            "check",
            "--check-idempotence",
            "--config",
            "{root}/tools/lint/code/haskell/fourmolu.yaml",
         },
      },
      markdown = {
         arguments = {
            "--config",
            "{root}/tools/lint/code/md/markdownlint.jsonc",
         },
      },

      lua = {
         arguments = {
            "--check",
            "--config-path",
            "{root}/tools/lint/code/lua/stylua.toml",
         },
      },

      cmake = {
         arguments = {
            "--check",
            "--config-files",
            "{root}/tools/lint/code/cmake/config.json",
            "--",
         },
      },

      c = {
         arguments = {
            "--dry-run",
            "--Werror",
            "--style=file:{root}/tools/lint/code/c/.clang-format",
         },
      },

      shell_posix = {
         arguments = { "-d", "-ln", "posix" },
      },

      shell_bash = {
         arguments = { "-d", "-ln", "bash" },
      },

      python = {
         arguments = {
            "format",
            "--check",
            "--config",
            "{root}/tools/lint/code/python/ruff.toml",
         },
         -- Ruff treats the final module comment as a new top-level section.
         terminal_marker = "# EOF",
      },

      toml = {
         arguments = {
            "format",
            "--check",
            "--config",
            "{root}/tools/lint/code/taplo/taplo.toml",
         },
      },
   }
end

return tools_lint_formatters_loadModule()

-- EOF


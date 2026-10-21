-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Lint Haskell sources and execute engine unit tests independently of Lean.
-- @return nil: no values.
local function HASKELL_CHECK_main()
   local env = dofile("scripts/verification/lib/engine_env.lua")
   local files = dofile("scripts/verification/lib/files.lua")
   local lock = dofile("scripts/toolchain/lib/lock.lua").load()
   local mode = arg[1]
   assert(
      (mode == nil or mode == "--lint" or mode == "--test") and arg[2] == nil,
      "usage: lua scripts/verification/check-haskell.lua [--lint|--test]"
   )
   local directory = ".cache/logs/haskell"
   assert(
      env.io.exec.run({ "mkdir", "-p", directory }).state == "PASS",
      "cannot create Haskell log directory"
   )
   --- Retain real tool output before propagating its failure.
   -- @param name string: evidence filename without extension.
   -- @param argv table: literal executable and arguments.
   -- @return string: combined process output.
   local function run(name, argv)
      print("haskell: " .. name)
      local result =
         env.resources.run(argv, { timeout_ms = 1800000, max_bytes = 16777216 })
      local output = result.stdout .. result.stderr
      files.write(directory .. "/" .. name .. ".log", output)
      files.write(
         directory .. "/" .. name .. ".resources.json",
         env.io.json({
            state = result.state,
            exit_code = result.exit_code,
            signal = result.signal,
            resources = result.resources,
         })
      )
      print(output)
      assert(result.state == "PASS", name .. ": " .. result.state)
      return output
   end
   --- Check source hints and formatting with the pinned lint tools.
   -- @return nil: no values.
   local function lintSources()
      local hlint = os.getenv("LIBMEMALLOC_HLINT")
         or ".cache/tools/haskell/hlint-" .. lock.hlint.version .. "/hlint"
      local fourmolu = os.getenv("LIBMEMALLOC_FOURMOLU")
         or ".cache/tools/haskell/fourmolu-"
            .. lock.fourmolu.version
            .. "-linux-x86_64/fourmolu"
      assert(
         run("hlint-version", { hlint, "--version" }):find(
            "v" .. lock.hlint.version .. ",",
            1,
            true
         )
      )
      assert(
         run("fourmolu-version", { fourmolu, "--version" }):find(
            lock.fourmolu.version,
            1,
            true
         )
      )
      local inventory = env.io.capture({
         "git",
         "ls-files",
         "--cached",
         "--others",
         "--exclude-standard",
         "-z",
         "--",
         "*.hs",
         "*.lhs",
      })
      local lint = { hlint, "--hint=tools/lint/code/haskell/hlint.yaml" }
      local format = {
         os.getenv("LIBMEMALLOC_LUA") or arg[-1] or "lua",
         "scripts/check/format.lua",
         "haskell",
         fourmolu,
      }
      local seen = {}
      for path in inventory:gmatch("([^%z]+)%z") do
         if not seen[path] then
            lint[#lint + 1], format[#format + 1], seen[path] = path, path, true
         end
      end
      assert(next(seen), "no Haskell sources found")
      run("hlint", lint)
      run("fourmolu", format)
   end
   --- Compile the pure engine profile and execute its regression suite.
   -- @return nil: no values.
   local function testEngine()
      assert(
         run(
            "ghc-version",
            env.command({ env.bin .. "/ghc", "--numeric-version" })
         ):match("^9%.4%.7%s*$"),
         "unsupported GHC"
      )
      local version =
         run("cabal-version", { env.bin .. "/cabal", "--numeric-version" })
      assert(version:match("^3%.16%.1%.0%s*$"), "unsupported Cabal")
      assert(
         files.read(".cache/haskell/cabal.project.freeze")
            == env.haskell_freeze(),
         "Haskell dependency lock drift; rerun "
            .. "bootstrap-engine.lua --haskell-only"
      )
      --- Construct a Cabal command with a separate non-Liquid build directory.
      -- @param action string: Cabal operation.
      -- @param arguments table: operation-specific literal arguments.
      -- @return table: fully configured command.
      local function cabal(action, arguments)
         local argv = {
            env.bin .. "/cabal",
            action,
            "--project-dir=" .. env.root .. "/.cache/haskell",
            "--project-file=cabal.project",
            "--builddir=" .. env.root .. "/.cache/cabal/haskell-build",
            "--ghc-options=-Werror",
         }
         for _, value in ipairs(arguments) do
            argv[#argv + 1] = value
         end
         return env.command(argv)
      end
      run("build", cabal("build", { "all", "--enable-tests" }))
      run(
         "tests",
         cabal("test", {
            "libmemalloc-verifier:engine-tests",
            "--test-show-details=direct",
            "--test-options=+RTS -M256m -RTS",
         })
      )
   end
   if mode ~= "--test" then
      lintSources()
   end
   if mode ~= "--lint" then
      testEngine()
   end
   print("Haskell checks passed.")
end

return HASKELL_CHECK_main()

-- EOF


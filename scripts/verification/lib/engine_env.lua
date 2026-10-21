-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

-- Repository-local, pinned tool locations shared by bootstrap and verification.

--- Execute the formal engine module within its explicit boundary.
-- @return table|nil: module interface when applicable.
local function FORMAL_ENV_loadModule()
   local io = dofile("scripts/process/lib/io.lua")
   local resources = dofile("scripts/verification/lib/resources.lua")
   local root = io.uv.cwd()
   local prefix = root .. "/.cache/tools/formal/cn-root/root/.opam/default"
   local bin = root .. "/.cache/tools/formal/bin"
   local lake = os.getenv("LMA_LAKE")
      or root .. "/.cache/lean/lean-4.35.0-linux/bin/lake"
   local environment = {
      "env",
      "-u",
      "GHCRTS",
      "PATH=" .. bin .. ":" .. prefix .. "/bin:" .. (os.getenv("PATH") or ""),
      "LIBRARY_PATH="
         .. root
         .. "/.cache/tools/formal/ghc/usr/lib/x86_64-linux-gnu",
      "CABAL_DIR=" .. root .. "/.cache/cabal",
      "OPAM_SWITCH_PREFIX=" .. prefix,
      "LD_LIBRARY_PATH="
         .. root
         .. "/.cache/tools/formal/ghc/usr/lib/x86_64-linux-gnu",
      "liquidhaskell_boot_datadir="
         .. root
         .. "/.cache/tools/liquidhaskell-0.9.4.7/liquidhaskell-boot",
      "liquidhaskell_datadir=" .. root .. "/.cache/tools/liquidhaskell-0.9.4.7",
   }
   --- Attach the pinned tool paths and package data directories.
   -- @param args table: child command and arguments.
   -- @return table: complete command arguments.
   local function command(args)
      if args[1] == bin .. "/ghc" or args[1] == bin .. "/cabal" then
         local files = dofile("scripts/verification/lib/files.lua")
         local base = root .. "/.cache/tools/formal/ghc"
         local expected = resources.compiler_script(
            files
               .read(base .. "/usr/bin/ghc-9.4.7")
               :gsub("/usr/lib/ghc", base .. "/usr/lib/ghc")
         )
         assert(
            files.read(bin .. "/ghc") == expected,
            "unbounded or stale GHC wrapper; rerun bootstrap-engine.lua "
               .. "--haskell-only"
         )
      end
      local argv = { table.unpack(environment) }
      for _, value in ipairs(args) do
         argv[#argv + 1] = value
      end
      return argv
   end
   --- Create the source-adjacent caches required by the pinned Liquid plugin.
   -- @return nil: no values.
   local function prepareLiquid()
      local inventory = io.capture({
         "git",
         "ls-files",
         "--cached",
         "--others",
         "--exclude-standard",
         "-z",
         "--",
         "verification/engine/*.hs",
      })
      local directories = {}
      for path in inventory:gmatch("([^%z]+)%z") do
         local directory = assert(path:match("^(.*)/[^/]+$")) .. "/.liquid"
         if not directories[directory] then
            assert(
               io.uv.fs_stat(directory) or io.uv.fs_mkdir(directory, 448),
               "cannot create Liquid cache: " .. directory
            )
            directories[directory] = true
         end
      end
   end
   --- Build a Cabal command using the frozen local project.
   -- @param action string: Cabal subcommand.
   -- @param args table|nil: subcommand arguments.
   -- @return table: complete command arguments.
   local function cabal(action, args)
      if action == "build" or action == "test" then
         prepareLiquid()
      end
      local argv = {
         bin .. "/cabal",
         action,
         "--project-file=" .. root .. "/.cache/formal/cabal.project",
         "--builddir=" .. root .. "/.cache/cabal/liquid-build",
      }
      for _, value in ipairs(args or {}) do
         argv[#argv + 1] = value
      end
      if action == "test" then
         argv[#argv + 1] = "--test-options=+RTS -M256m -RTS"
      end
      return command(argv)
   end
   --- Preserve frozen dependency versions while disabling the refinement
   -- plugin.
   -- @return string: the unit-test profile's generated Cabal freeze contents.
   local function haskellFreeze()
      local files = dofile("scripts/verification/lib/files.lua")
      local contents, count = files
         .read("verification/engine/cabal.project.freeze")
         :gsub("libmemalloc%-verifier %+liquid", "libmemalloc-verifier -liquid")
      assert(count == 1, "missing frozen Liquid Haskell flag")
      return contents
   end
   return {
      root = root,
      prefix = prefix,
      bin = bin,
      lake = lake,
      command = command,
      cabal = cabal,
      prepare_liquid = prepareLiquid,
      haskell_freeze = haskellFreeze,
      io = io,
      resources = resources,
      cn_sha256 = "449c3fbe5b38305ad4fb259d89fe1f67"
         .. "78144ae13c674fd42056ccaed1b30406",
      z3_sha256 = "f4224207d6ffb0b23a1bfad8c653d10a"
         .. "f82f3c7fb41d1c47d0cc138a63179eb8",
      cn_source = "b4a2f009234d9c80380dbf95a9b2325e36a4705d",
      liquid_source = "b3a5ac99a534a539e9758fd008f14d66b241682c",
   }
end

return FORMAL_ENV_loadModule()

-- EOF


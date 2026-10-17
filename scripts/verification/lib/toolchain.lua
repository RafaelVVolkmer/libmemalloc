-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Admit the same pinned toolchain for standalone proofs and full campaigns.
-- @return table: project rendering and shared validation.
local function TOOLCHAIN_loadModule()
   local files = dofile("scripts/verification/lib/files.lua")

   --- Render the only admitted local Cabal project.
   -- @param env table: repository and pinned tool locations.
   -- @return string: exact generated project contents.
   local function project(env)
      local liquid = env.root .. "/.cache/tools/liquidhaskell-0.9.4.7"
      return "packages: "
         .. env.root
         .. "/verification/engine\n"
         .. "          "
         .. liquid
         .. "\n          "
         .. liquid
         .. "/liquidhaskell-boot\n"
         .. "          "
         .. liquid
         .. "/liquid-fixpoint\nindex-state: 2024-08-01T00:00:00Z\n"
         .. "with-compiler: "
         .. env.bin
         .. "/ghc\noptimization: False\njobs: 1\n"
         .. "package libmemalloc-verifier\n  flags: +liquid\n"
         .. "package *\n  extra-lib-dirs: "
         .. env.root
         .. "/.cache/tools/formal/ghc/usr/lib/x86_64-linux-gnu\n"
         .. "  extra-include-dirs: "
         .. env.root
         .. "/.cache/tools/formal/ghc/usr/include/x86_64-linux-gnu\n"
   end

   --- Reject cached configuration drift before invoking any compiler.
   -- @param env table: repository and pinned tool locations.
   -- @return table: configuration digests.
   local function configuration(env)
      local path = env.root .. "/.cache/formal/cabal.project"
      assert(files.read(path) == project(env), "Cabal project drift")
      assert(
         files.read(path .. ".freeze")
            == files.read(
               env.root .. "/verification/engine/cabal.project.freeze"
            ),
         "Cabal lock drift"
      )
      assert(
         not env.io.uv.fs_lstat(path .. ".local"),
         "Cabal local override is not admitted"
      )
      return {
         project_sha256 = env.io.digest(path),
         freeze_sha256 = env.io.digest(path .. ".freeze"),
      }
   end

   --- Check revision and tracked source changes for one pinned dependency.
   -- @param env table: repository and pinned tool locations.
   -- @param run function: bounded command runner retaining receipts.
   -- @param name string: stable dependency identifier.
   -- @param path string: repository-relative checkout path.
   -- @param revision string: required commit identity.
   -- @return nil: no values.
   local function dependency(env, run, name, path, revision)
      local directory = env.root .. "/" .. path
      local actual = run(
         name .. "-source-revision",
         { "git", "-C", directory, "rev-parse", "HEAD" }
      )
      assert(
         actual:match("^([a-f0-9]+)%s*$") == revision,
         "formal dependency revision differs from lock: " .. name
      )
      assert(
         run(
            name .. "-source-diff",
            { "git", "-C", directory, "diff", "HEAD", "--" }
         ) == "",
         "dependency drift: " .. name
      )
   end

   --- Validate configuration, binaries, versions and source revisions identically.
   -- @param env table: repository and pinned tool locations.
   -- @param run function: bounded command runner retaining receipts.
   -- @return table: admitted tool and configuration identities.
   local function validate(env, run)
      local evidence = configuration(env)
      evidence.cn = env.io.digest(env.prefix .. "/bin/cn")
      evidence.z3 = env.io.digest(env.prefix .. "/bin/z3")
      assert(
         evidence.cn == env.cn_sha256 and evidence.z3 == env.z3_sha256,
         "tool digest drift"
      )
      evidence.ghc = run(
         "ghc-version",
         env.command({ env.bin .. "/ghc", "--numeric-version" })
      )
      evidence.lean = run(
         "lean-version",
         { env.lake, "env", "lean", "--version" },
         env.root .. "/verification/theorems"
      )
      assert(evidence.ghc:match("^9%.4%.7%s*$"), "unsupported GHC")
      assert(evidence.lean:find("version 4.35.0", 1, true), "unsupported Lean")
      dependency(env, run, "cn", ".cache/tools/cn-source", env.cn_source)
      dependency(
         env,
         run,
         "liquid",
         ".cache/tools/liquidhaskell-0.9.4.7",
         env.liquid_source
      )
      return evidence
   end
   return {
      project = project,
      configuration = configuration,
      validate = validate,
   }
end

return TOOLCHAIN_loadModule()

-- EOF


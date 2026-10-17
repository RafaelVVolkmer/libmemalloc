-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

-- Linux x86-64 bootstrap. Requires Lua/luv, jq, curl, git, tar, dpkg-deb,
-- a C compiler, libgmp development files and bubblewrap. Downloads are hashed
-- before extraction; source dependencies are checked out at immutable commits.

--- Execute the formal engine module within its explicit boundary.
-- @return table|nil: module interface when applicable.
local function FORMAL_BOOTSTRAP_main()
   local env = dofile("scripts/verification/lib/engine_env.lua")
   local io = env.io
   local files = dofile("scripts/verification/lib/files.lua")
   local haskellOnly = arg[1] == "--haskell-only"
   assert(
      (arg[1] == nil or haskellOnly) and arg[2] == nil,
      "usage: lua scripts/verification/bootstrap-engine.lua [--haskell-only]"
   )
   --- Run a bootstrap command and fail on missing or incomplete output.
   -- @param argv table: literal command arguments.
   -- @return string: successful command output.
   local function run(argv)
      local result =
         env.resources.run(argv, { timeout_ms = 3600000, max_bytes = 8388608 })
      assert(result.state == "PASS", result.stderr .. result.stdout)
      return result.stdout
   end
   --- Create a disposable evidence or tool directory.
   -- @param path string: directory to create.
   -- @return nil: no values.
   local function mkdir(path)
      run({ "mkdir", "-p", path })
   end
   --- Download one immutable artifact and require its reviewed digest.
   -- @param url string: artifact address.
   -- @param path string: cached output path.
   -- @param hash string: expected SHA-256.
   -- @param headers table|nil: additional curl header arguments.
   -- @return nil: no values.
   local function download(url, path, hash, headers)
      if io.uv.fs_stat(path) and io.digest(path) == hash then
         return
      end
      local args = {
         "curl",
         "--fail",
         "--location",
         "--silent",
         "--show-error",
         "--retry",
         "3",
      }
      for _, value in ipairs(headers or {}) do
         args[#args + 1] = value
      end
      args[#args + 1], args[#args + 2], args[#args + 3] = "--output", path, url
      run(args)
      assert(io.digest(path) == hash, "download digest mismatch: " .. path)
   end
   --- Prepare an immutable clean source checkout and its submodules.
   -- @param url string: repository URL.
   -- @param path string: cached checkout.
   -- @param revision string: required commit identity.
   -- @return nil: no values.
   local function checkout(url, path, revision)
      if not io.uv.fs_stat(path) then
         run({ "git", "clone", "--no-checkout", url, path })
      end
      run({ "git", "-C", path, "checkout", "--detach", revision })
      run({ "git", "-C", path, "submodule", "update", "--init", "--recursive" })
      assert(
         run({ "git", "-C", path, "rev-parse", "HEAD" }):match("%x+")
            == revision,
         "dependency revision differs from lock"
      )
      assert(
         run({ "git", "-C", path, "status", "--porcelain" }) == "",
         "modified dependency: " .. path
      )
   end
   mkdir(".cache/downloads/formal")
   mkdir(".cache/tools/formal/bin")
   mkdir(".cache/formal")
   --- Install and relocate the pinned GHC package inside the repository cache.
   -- @return nil: no values.
   local function installGhc()
      local ghc = ".cache/downloads/ghc_9.4.7-3_amd64.deb"
      download(
         "https://archive.ubuntu.com/ubuntu/pool/universe/g/ghc/"
            .. "ghc_9.4.7-3_amd64.deb",
         ghc,
         "3bc66a6aeeb1ccf116c877b6ebfc551ad39ba9b676d905b48d1881c6c2383b59"
      )
      if io.uv.fs_stat(env.bin .. "/ghc") then
         return
      end
      run({ "dpkg-deb", "-x", ghc, ".cache/tools/formal/ghc" })
      local base = env.root .. "/.cache/tools/formal/ghc"
      for _, name in ipairs({
         "ghc",
         "ghc-pkg",
         "hsc2hs",
         "haddock",
         "runghc",
         "hpc",
         "hp2ps",
      }) do
         files.write(
            env.bin .. "/" .. name,
            files
               .read((assert(io.uv.fs_realpath(base .. "/usr/bin/" .. name))))
               :gsub("/usr/lib/ghc", base .. "/usr/lib/ghc")
         )
         run({ "chmod", "+x", env.bin .. "/" .. name })
      end
      local conf = base .. "/var/lib/ghc/package.conf.d"
      local scan = assert(io.uv.fs_scandir(conf))
      while true do
         local name = io.uv.fs_scandir_next(scan)
         if not name then
            break
         end
         if name:match("%.conf$") then
            local path = conf .. "/" .. name
            files.write(
               path,
               files.read(path):gsub("/usr/lib/ghc", base .. "/usr/lib/ghc")
            )
         end
      end
      assert(io.uv.fs_unlink(base .. "/usr/lib/ghc/lib/package.conf.d"))
      assert(io.uv.fs_symlink(conf, base .. "/usr/lib/ghc/lib/package.conf.d"))
      run({ env.bin .. "/ghc-pkg", "recache" })
      for _, name in ipairs({ "ghc", "ghc-pkg" }) do
         assert(io.uv.fs_symlink(name, env.bin .. "/" .. name .. "-9.4.7"))
      end
   end
   installGhc()
   -- Refresh existing caches as well as new installations.
   local compilerBase = env.root .. "/.cache/tools/formal/ghc"
   files.write(
      env.bin .. "/ghc",
      env.resources.compiler_script(
         files
            .read(compilerBase .. "/usr/bin/ghc-9.4.7")
            :gsub("/usr/lib/ghc", compilerBase .. "/usr/lib/ghc")
      )
   )
   run({ "chmod", "+x", env.bin .. "/ghc" })
   local cabal = ".cache/downloads/formal/cabal-3.16.1.0.tar.xz"
   download(
      "https://downloads.haskell.org/~cabal/cabal-install-3.16.1.0/"
         .. "cabal-install-3.16.1.0-x86_64-linux-ubuntu24_04.tar.xz",
      cabal,
      "f7284888f523ff0bb3d8bfc9e7b8c89ab3b95fe87792aefc06019801b9f6ef74"
   )
   if not io.uv.fs_stat(env.bin .. "/cabal") then
      mkdir(".cache/tools/formal/cabal-3.16.1.0")
      run({ "tar", "-xJf", cabal, "-C", ".cache/tools/formal/cabal-3.16.1.0" })
      assert(io.uv.fs_symlink("../cabal-3.16.1.0/cabal", env.bin .. "/cabal"))
   end
   --- Initialize the common package index after preparing the selected tools.
   -- @return nil: no values.
   local function prepareIndex()
      if not io.uv.fs_stat(".cache/cabal/config") then
         run(env.command({ env.bin .. "/cabal", "user-config", "init" }))
      end
      files.write(
         ".cache/cabal/config",
         files
            .read(".cache/cabal/config")
            :gsub("http://hackage", "https://hackage")
      )
      run(env.command({ env.bin .. "/cabal", "update" }))
   end
   if haskellOnly then
      mkdir(".cache/haskell")
      files.write(
         ".cache/haskell/cabal.project",
         "packages: "
            .. env.root
            .. "/verification/engine\n"
            .. "with-compiler: "
            .. env.bin
            .. "/ghc\n"
            .. "index-state: 2024-08-01T00:00:00Z\n"
            .. "optimization: False\njobs: 1\ntests: True\n"
            .. "package libmemalloc-verifier\n  flags: -liquid\n"
      )
      files.write(".cache/haskell/cabal.project.freeze", env.haskell_freeze())
      prepareIndex()
      print(
         "Haskell compiler prepared; CN, Lean and Liquid "
            .. "Haskell are not required for unit tests."
      )
      return
   end
   local layers = {
      {
         "e835e5c349d48576133ed35ff06195429ce77b9ada3e08fba2eec8b0292993df",
         "root/.opam/default/lib/cerberus-lib/runtime",
      },
      {
         "023b9ebe70d638ebfcf82a29df6a10929469895d81e796a022373ed79f55435d",
         "root/.opam/default/bin",
         "root/.opam/default/lib",
      },
      {
         "c4c226a7ef1fd6a8049138506330a0c97c9ca07ae99e02f62ff4eb5eae3c17f1",
         "root/.opam/default/bin",
         "root/.opam/default/lib",
      },
   }
   if
      not io.uv.fs_stat(env.prefix .. "/bin/cn")
      or io.digest(env.prefix .. "/bin/cn") ~= env.cn_sha256
   then
      local token = io.decode(run({
         "curl",
         "-fsSL",
         "https://ghcr.io/token?scope=repository:rems-project/cn:pull",
      })).token
      mkdir(".cache/tools/formal/cn-root")
      for _, layer in ipairs(layers) do
         local path = ".cache/downloads/formal/" .. layer[1] .. ".tar.gz"
         download(
            "https://ghcr.io/v2/rems-project/cn/blobs/sha256:" .. layer[1],
            path,
            layer[1],
            { "-H", "Authorization: Bearer " .. token }
         )
         local args =
            { "tar", "-xzf", path, "-C", ".cache/tools/formal/cn-root" }
         for i = 2, #layer do
            args[#args + 1] = layer[i]
         end
         run(args)
      end
   end
   assert(
      io.digest(env.prefix .. "/bin/cn") == env.cn_sha256,
      "CN binary drift"
   )
   assert(
      io.digest(env.prefix .. "/bin/z3") == env.z3_sha256,
      "Z3 binary drift"
   )
   checkout(
      "https://github.com/rems-project/cn.git",
      ".cache/tools/cn-source",
      env.cn_source
   )
   checkout(
      "https://github.com/ucsd-progsys/liquidhaskell.git",
      ".cache/tools/liquidhaskell-0.9.4.7",
      env.liquid_source
   )
   files.write(
      ".cache/formal/cabal.project",
      dofile("scripts/verification/lib/toolchain.lua").project(env)
   )
   files.write(
      ".cache/formal/cabal.project.freeze",
      files.read("verification/engine/cabal.project.freeze")
   )
   prepareIndex()
   print(
      "Formal toolchain prepared. Run lua "
         .. "scripts/verification/check.lua --engine."
   )
end

return FORMAL_BOOTSTRAP_main()

-- EOF


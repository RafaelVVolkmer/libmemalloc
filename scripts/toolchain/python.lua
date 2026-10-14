-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Synchronize Python groups from the manifest and lock under tools/python.
-- This explicit installer downloads a hash-verified uv when no override exists.
-- Part of tool provisioning; environments remain below .cache/tools.

--- Resolve the reviewed installer and synchronize without rewriting the lock.
-- @return nil: no values.
local function PYTHON_main()
   local PYTHON_GITHUB_COM_RELEASES_DOWNLOAD_URL =
      "https://github.com/astral-sh/uv/releases/download/"

   dofile("scripts/workspace/lib/lock.lua").guard("shared")
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local lock = dofile("scripts/toolchain/lib/lock.lua").load()
   local hosts = dofile("scripts/toolchain/lib/host.lua")
   local host = hosts.current()
   local options = artifacts.options(
      arg,
      { groups = true, directory = true, reinstall = true }
   )

   assert(
      not options.reinstall or options.reinstall == true,
      "--reinstall takes no value"
   )
   local groups = assert(options.groups, "--groups is required")
   local directory = assert(options.directory, "--directory is required")

   assert(groups ~= "", "select at least one Python group")
   artifacts.safe_path(directory)
   assert(
      directory:match("^%.cache/tools/[^/]+"),
      "use .cache/tools for environments"
   )
   local root = artifacts.output({ "git", "rev-parse", "--show-toplevel" })
   local uv_root = ".cache/tools/uv/" .. lock.uv.version
   local uv = os.getenv("LIBMEMALLOC_UV")
      or uv_root .. "/uv-" .. host.target .. "/uv"
   local change = dofile("scripts/lib/change.lua")
   local products = { directory, uv_root }
   local before = change.snapshot(products)

   --- Download and verify the pinned Python environment manager if absent.
   -- @return nil: no values.
   local function python_installUv()
      if not os.getenv("LIBMEMALLOC_UV") and not artifacts.exists(uv) then
         local archive = ".cache/downloads/uv/uv-"
            .. lock.uv.version
            .. (host.key == "linux_x86_64" and "" or "-" .. host.target)
            .. ".tar.gz"

         artifacts.mkdir(".cache/downloads/uv")
         if not artifacts.exists(archive) then
            artifacts.run({
               "curl",
               "--fail",
               "--location",
               "--proto",
               "=https",
               "--tlsv1.2",
               "--max-time",
               "180",
               "--output",
               archive,
               PYTHON_GITHUB_COM_RELEASES_DOWNLOAD_URL
                  .. lock.uv.version
                  .. "/uv-"
                  .. host.target
                  .. ".tar.gz",
            })
         end

         assert(
            artifacts.digest(archive) == hosts.digest(lock.uv, host),
            "uv archive hash mismatch"
         )
         artifacts.mkdir(uv_root)
         artifacts.run({ "tar", "-xzf", archive, "-C", uv_root })
      end
   end

   python_installUv()
   assert(
      artifacts.output({ uv, "--version" }):match("^uv ([^ ]+)")
         == lock.uv.version,
      "uv version differs from tools/toolchain/lock.toml"
   )

   local command = {
      "env",
      "UV_PROJECT_ENVIRONMENT=" .. root .. "/" .. directory,
      uv,
      "sync",
      "--locked",
      "--project",
      root .. "/tools/python",
      "--no-default-groups",
      "--no-install-project",
      "--no-python-downloads",
      "--python",
      os.getenv("LIBMEMALLOC_PYTHON") or "python3",
      "--cache-dir",
      root .. "/.cache/tools/uv-cache",
   }
   local sources, backends = {}, {}
   if options.reinstall then
      command[#command + 1] = "--reinstall"
   end

   --- Select only packages that need an explicitly reviewed source build.
   -- @return nil: no values.
   local function python_selectSources()
      for group in groups:gmatch("[^,]+") do
         if group == "lint" or group == "reuse" then
            sources.reuse, backends["reuse-build"] = true, true
         elseif group == "automation" and host.key == "macos_x86_64" then
            sources.cryptography, backends["crypto-build"] = true, true
            table.insert(
               command,
               2,
               "OPENSSL_DIR="
                  .. (
                     os.getenv("OPENSSL_DIR")
                     or artifacts.output({ "brew", "--prefix", "openssl@3" })
                  )
            )
         end
      end
   end

   python_selectSources()

   --- Permit reviewed source packages with their separately locked backends.
   -- @return nil: no values.
   local function python_prepareSourceBuild()
      if next(sources) then
         -- Install backend wheels before allowing selected source builds.
         local bootstrap = {}

         for _, value in ipairs(command) do
            bootstrap[#bootstrap + 1] = value
         end

         for backend in pairs(backends) do
            bootstrap[#bootstrap + 1] = "--group"
            bootstrap[#bootstrap + 1] = backend
            command[#command + 1] = "--group"
            command[#command + 1] = backend
         end

         bootstrap[#bootstrap + 1] = "--no-build"
         artifacts.run(bootstrap)
         for name in pairs(sources) do
            command[#command + 1] = "--no-build-isolation-package"
            command[#command + 1] = name
         end

         for name in
            artifacts
               .read("tools/python/uv.lock")
               :gmatch('\nname = "([^"\n]+)"')
         do
            if not sources[name] then
               command[#command + 1] = "--no-build-package"
               command[#command + 1] = name
            end
         end
      else
         command[#command + 1] = "--no-build"
      end
   end

   python_prepareSourceBuild()
   for group in groups:gmatch("[^,]+") do
      assert(group:match("^[a-z][a-z-]+$"), "invalid Python group")
      command[#command + 1] = "--group"
      command[#command + 1] = group
   end

   artifacts.run(command)
   change.record(before ~= change.snapshot(products))
end

return PYTHON_main()

-- EOF


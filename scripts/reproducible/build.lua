-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Rebuild complete install trees without consulting a compiler cache.
-- Part of independent reconstruction and byte-comparison campaigns.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_reproducible_build_main()
   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local policy = dofile("tools/reproducible/policy.lua")
   local lock = dofile("scripts/toolchain/lib/lock.lua").load()
   local root = artifact_io.output({ "pwd" })
   local epoch = artifact_io.read("source-epoch.txt"):match("^(%d+)\n$")

   assert(epoch, "a frozen source epoch is required")
   assert(not artifact_io.exists("payload"), "choose a fresh source tree")

   local compiler_version =
      artifact_io.output({ policy.compiler, "-dumpfullversion" })

   assert(
      compiler_version == lock[policy.compiler_lock].version,
      "compiler version differs from the qualified lock"
   )

   local sources = artifact_io.array()

   for _, path in ipairs(artifact_io.files(".")) do
      sources[#sources + 1] = { path = path, sha256 = artifact_io.digest(path) }
   end

   artifact_io.document("./build-environment.json", {
      schema = policy.schema,
      scope = policy.scope,
      compiler = policy.compiler,
      compiler_version = compiler_version,
      cmake = artifact_io.output({ "cmake", "--version" }),
      tar = artifact_io.output({ "tar", "--version" }),
      gzip = artifact_io.output({ "gzip", "--version" }),
      system = artifact_io.output({ "uname", "-a" }),
      source_date_epoch = epoch,
      sources = sources,
   })

   artifact_io.mkdir("payload")

   for _, build_type in ipairs(policy.build_types) do
      for _, linkage in ipairs(policy.linkages) do
         local id = build_type:lower() .. "-" .. linkage
         local build = "work/" .. id
         local install = root .. "/" .. build .. "/install"
         local environment = { "env", "SOURCE_DATE_EPOCH=" .. epoch }

         --- Execute one recorded reconstruction command and retain its failure
         -- status.
         -- @param command table: executable and literal command arguments.
         -- @return nil: no values.
         local function reproducible_build_run(command)
            local argv = {}

            for _, value in ipairs(environment) do
               argv[#argv + 1] = value
            end

            for _, value in ipairs(command) do
               argv[#argv + 1] = value
            end

            artifact_io.run(argv)
         end

         reproducible_build_run({
            "cmake",
            "-S",
            ".",
            "-B",
            build,
            "-G",
            "Unix Makefiles",
            "-DLMA_BUILD_MOCK=ON",
            "-DCMAKE_C_COMPILER=" .. policy.compiler,
            "-DCMAKE_C_COMPILER_LAUNCHER=",
            "-DCMAKE_C_STANDARD=99",
            "-DCMAKE_BUILD_TYPE=" .. build_type,
            "-DCMAKE_INSTALL_PREFIX=/usr",
            "-DCMAKE_INSTALL_LIBDIR=lib",
            "-DBUILD_SHARED_LIBS=" .. (linkage == "shared" and "ON" or "OFF"),
            "-DCMAKE_C_FLAGS=-ffile-prefix-map="
               .. root
               .. "=. "
               .. "-fdebug-prefix-map="
               .. root
               .. "=.",
         })

         -- reprotest varies CPU availability; the build consumes that
         -- variation.
         reproducible_build_run({
            "cmake",
            "--build",
            build,
            "--parallel",
            artifact_io.output({ "nproc" }),
         })

         reproducible_build_run({
            "env",
            "DESTDIR=" .. install,
            "cmake",
            "--install",
            build,
         })

         reproducible_build_run({
            "tar",
            "--sort=name",
            "--format=gnu",
            "--mtime=@" .. epoch,
            "--owner=0",
            "--group=0",
            "--numeric-owner",
            "--mode=u=rwX,go=rX",
            "-cf",
            "payload/" .. id .. ".tar",
            "-C",
            install,
            ".",
         })

         reproducible_build_run({ "gzip", "-n", "payload/" .. id .. ".tar" })
      end
   end
end

return scripts_reproducible_build_main()

-- EOF


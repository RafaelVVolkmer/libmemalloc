-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Build and compare two isolated Linux mock candidates; never publish them.
-- Part of release construction, verification and artifact identity.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_release_build_main()
   local RELEASE_BUILD_ID_HEX_LENGTH = 16
   local RELEASE_PROBE_TIMEOUT_SECONDS = 10

   dofile("scripts/workspace/lib/lock.lua").guard("shared")
   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local execution_api = dofile("scripts/release/lib/evidence.lua")
   local options =
      artifact_io.options(arg, { mock = true, version = true, output = true })

   assert(
      options.mock == true,
      "only --mock builds are qualified by this driver"
   )

   local version = artifact_io.semver(options.version or "0.0.0-mock")

   assert(
      version:find("-", 1, true),
      "mock builds require a prerelease version"
   )

   local output = options.output or "release"

   artifact_io.safe_path(output)
   assert(
      artifact_io.output({ "uname", "-s" }) == "Linux",
      "only native Linux is supported"
   )

   --- Reject unsupported native architectures before collecting release inputs.
   -- @return any: reject unsupported native architectures before collecting
   -- release inputs.
   local function release_build_architecture()
      local architecture = artifact_io.output({ "uname", "-m" })

      assert(
         architecture == "x86_64" or architecture == "aarch64",
         "unsupported architecture"
      )

      return architecture
   end

   local architecture = release_build_architecture()

   local epoch =
      artifact_io.output({ "git", "show", "-s", "--format=%ct", "HEAD" })

   assert(epoch:match("^%d+$"), "invalid source timestamp")

   local timestamp = artifact_io.output({
      "date",
      "-u",
      "-d",
      "@" .. epoch,
      "+%Y-%m-%dT%H:%M:%SZ",
   })
   local source_identity = artifact_io.output({ "git", "rev-parse", "HEAD" })
   local attempt = artifact_io.platform.temporary_directory("build")
   local execution = attempt:match("([^/]+)$")
   local stage = attempt .. "/candidate"

   artifact_io.mkdir(stage)

   local inputs, build_tools = artifact_io.array(), artifact_io.array()
   local tool_paths = {}

   local required_tools = { "gcc", "ar", "as", "ld", "lua", "jq", "sha256sum" }

   for _, name in ipairs(required_tools) do
      local path = artifact_io.output({ "which", name })

      path = artifact_io.output({ "readlink", "-f", path })
      tool_paths[name] = path

      local record = {
         path = "tools/" .. name,
         sha256 = artifact_io.digest(path),
         size = #artifact_io.read(path),
      }

      inputs[#inputs + 1] = record
      build_tools[#build_tools + 1] = record
      artifact_io.write(
         stage
            .. "/materials/objects/sha256/"
            .. record.sha256:sub(1, 2)
            .. "/"
            .. record.sha256,
         artifact_io.read(path)
      )
   end

   -- Record GCC's internal executables and startup/runtime link inputs.
   --- Capture one compiler runtime input in the immutable materials store.
   -- @param name string: entry or operation name to resolve.
   -- @return nil: no values.
   local function release_build_captureToolInput(name)
      local selector = (name == "cc1" or name == "collect2")
            and "-print-prog-name="
         or "-print-file-name="
      local path = artifact_io.output({ tool_paths.gcc, selector .. name })

      if artifact_io.exists(path) then
         local record = {
            path = "toolchain/" .. name,
            sha256 = artifact_io.digest(path),
            size = #artifact_io.read(path),
         }

         inputs[#inputs + 1] = record
         build_tools[#build_tools + 1] = record
         artifact_io.write(
            stage
               .. "/materials/objects/sha256/"
               .. record.sha256:sub(1, 2)
               .. "/"
               .. record.sha256,
            artifact_io.read(path)
         )
      end
   end

   for _, name in ipairs({
      "cc1",
      "collect2",
      "Scrt1.o",
      "crti.o",
      "crtn.o",
      "crtbeginS.o",
      "crtendS.o",
      "libgcc.a",
      "libgcc_s.so",
      "libc.so",
   }) do
      release_build_captureToolInput(name)
   end

   local paths = artifact_io.output({
      "git",
      "ls-files",
      "--cached",
      "--others",
      "--exclude-standard",
      "--",
      "core",
      "scripts",
      "tools/release",
      "packaging",
      "CMakeLists.txt",
      "cmake",
      "CMakePresets.json",
      "tests/fixtures/install",
      ".github/workflows",
      "LICENSE",
   })

   --- Acquire each declared source once and retain its content-addressed bytes.
   -- @return table: acquire each declared source once and retain its
   -- content-addressed bytes.
   local function release_build_snapshotSources()
      local seen, source_records = {}, {}

      for path in paths:gmatch("[^\n]+") do
         if not seen[path] then
            artifact_io.safe_path(path)
            assert(not artifact_io.platform.command_succeeded_silent({
               "test",
               "-L",
               path,
            }), "linked source input")

            seen[path] = true

            local record = artifact_io.record(".", path)

            source_records[path] = record
            inputs[#inputs + 1] = record
            artifact_io.write(
               stage
                  .. "/materials/objects/sha256/"
                  .. record.sha256:sub(1, 2)
                  .. "/"
                  .. record.sha256,
               artifact_io.read(path)
            )
         end
      end

      return source_records
   end

   local source_records = release_build_snapshotSources()

   --- Verify acquired input objects before writing their release manifest.
   -- @return any: verify acquired input objects before writing their release
   -- manifest.
   local function release_build_verifyMaterials()
      for _, record in ipairs(inputs) do
         local object = stage
            .. "/materials/objects/sha256/"
            .. record.sha256:sub(1, 2)
            .. "/"
            .. record.sha256

         assert(
            artifact_io.digest(object) == record.sha256,
            "input changed during acquisition"
         )
      end

      --- Add a source file and its digest to the frozen release input
      -- inventory.
      -- @param path string: filesystem path selected by the caller.
      -- @return any: add a source file and its digest to the frozen release
      -- input inventory.
      local function release_build_source(path)
         local digest =
            assert(source_records[path], "missing source input").sha256

         return artifact_io.read(
            stage
               .. "/materials/objects/sha256/"
               .. digest:sub(1, 2)
               .. "/"
               .. digest
         )
      end

      table.sort(
         inputs,
         --- Order source input records by path before computing release
         -- identities.
         -- @param left table: left supplied to this operation.
         -- @param right table: right supplied to this operation.
         -- @return boolean: order source input records by path before computing
         -- release identities.
         function(left, right)
            return left.path < right.path
         end
      )

      return release_build_source
   end

   local release_build_source = release_build_verifyMaterials()

   local manifest = {
      schema = 1,
      mock = true,
      version = version,
      target = architecture .. "-linux",
      compiler_target = artifact_io.output({ tool_paths.gcc, "-dumpmachine" }),
      source_commit = source_identity,
      source_date_epoch = epoch,
      variants = artifact_io.array({ "release", "debug" }),
      inputs = inputs,
      build_profile = "gcc-c11-mock-no-libc-shared-v1",
      environment = { locale = "C", timezone = "UTC" },
      qualification = (
         "same-host-path-time-variation; not a hermetic or "
         .. "independent-builder claim"
      ),
   }

   artifact_io.document(stage .. "/identity/build-inputs.json", manifest)

   local full_digest = artifact_io.digest(artifact_io.input_manifest(stage))
   local build_id = full_digest:sub(1, RELEASE_BUILD_ID_HEX_LENGTH)
   local basename = "libmemalloc-" .. version .. "-" .. build_id
   local final = output .. "/" .. architecture .. "-linux-" .. build_id

   assert(
      not artifact_io.exists(final),
      "immutable output already exists: " .. final
   )

   artifact_io.document(stage .. "/identity/build-id.json", {
      sha256 = full_digest,
      short = build_id,
      prefix_length = RELEASE_BUILD_ID_HEX_LENGTH,
      mock = true,
   })

   artifact_io.document(stage .. "/identity/target.json", {
      architecture = architecture,
      os = "linux",
      mock = true,
      version = version,
   })

   artifact_io.document(stage .. "/materials/files.json", { files = inputs })

   artifact_io.document(stage .. "/materials/toolchain.json", {
      files = build_tools,
      scope = "recorded compiler inputs; host closure remains unqualified",
   })

   artifact_io.write(
      stage .. "/include/mock.h",
      release_build_source("core/mock.h")
   )

   artifact_io.write(
      stage .. "/licenses/LICENSE",
      release_build_source("LICENSE")
   )

   local products, comparisons = artifact_io.array(), artifact_io.array()

   --- Compile one release variant in the selected independent build directory.
   -- @param directory string: working or output directory selected by the
   -- caller.
   -- @param variant any: variant supplied to this operation.
   -- @param second any: second supplied to this operation.
   -- @return nil: no values.
   local function release_build_compile(directory, variant, second)
      artifact_io.mkdir(directory)

      for _, path in ipairs({ "core/main.c", "core/mock.c", "core/mock.h" }) do
         artifact_io.write(directory .. "/" .. path, release_build_source(path))
      end

      --- Execute a release build command and retain its command/log evidence.
      -- @param command table: executable and literal command arguments.
      -- @return nil: no values.
      local function release_build_run(command)
         local environment = {
            "env",
            "-i",
            "PATH=/usr/bin:/bin",
            "LC_ALL=C",
            "TZ=" .. (second and "Pacific/Honolulu" or "UTC"),
            "SOURCE_DATE_EPOCH=" .. epoch,
         }

         for _, value in ipairs(command) do
            environment[#environment + 1] = value
         end

         assert(
            artifact_io.platform.command_succeeded(
               artifact_io.platform.in_directory(directory, environment)
            ),
            "build command failed"
         )
      end

      local flags = {
         "-std=c11",
         "-Wall",
         "-Wextra",
         "-Werror",
         "-fPIC",
         "-ffile-prefix-map=" .. directory .. "=/libmemalloc",
         "-fdebug-prefix-map=" .. directory .. "=/libmemalloc",
      }

      flags[#flags + 1] = variant == "release" and "-O2" or "-O0"
      if variant == "debug" then
         flags[#flags + 1] = "-g"
      end

      local command = { tool_paths.gcc }

      for _, flag in ipairs(flags) do
         command[#command + 1] = flag
      end

      for _, value in ipairs({ "-c", "core/mock.c", "-o", "mock.o" }) do
         command[#command + 1] = value
      end

      release_build_run(command)

      release_build_run({ tool_paths.ar, "rcsD", basename .. ".a", "mock.o" })

      release_build_run({
         tool_paths.gcc,
         "-shared",
         "-nostdlib",
         "-Wl,--build-id=none",
         "-Wl,-soname,libmemalloc.so.0",
         "-Wl,-Map," .. basename .. ".map",
         "mock.o",
         "-o",
         basename .. ".so",
      })

      --- Link and run a consumer for one library linkage mode.
      -- @param mode any: mode supplied to this operation.
      -- @return nil: no values.
      local function release_build_linkConsumer(mode)
         local executable = basename .. "-" .. mode

         release_build_run({
            tool_paths.gcc,
            "-std=c11",
            "-Wall",
            "-Wextra",
            "-Werror",
            "-Wl,--build-id=none",
            "core/main.c",
            basename .. (mode == "static" and ".a" or ".so"),
            "-o",
            executable,
         })
         if mode == "shared" then
            artifact_io.write(
               directory .. "/libmemalloc.so.0",
               artifact_io.read(directory .. "/" .. basename .. ".so")
            )
         end

         local command_line = {
            "env",
            "LD_LIBRARY_PATH=" .. directory,
            "timeout",
            "10",
            directory .. "/" .. executable,
         }

         local log = directory .. "/" .. mode .. ".log"
         local success = artifact_io.platform.command_succeeded(
            artifact_io.platform.join_command(command_line)
               .. " >"
               .. artifact_io.platform.shell_quote(log)
               .. " 2>&1"
         )

         assert(success, "mock smoke test failed: " .. mode)
      end

      for _, mode in ipairs({ "static", "shared" }) do
         release_build_linkConsumer(mode)
      end
   end

   --- Compare payload bytes for one isolated release build variant.
   -- @param variant any: variant supplied to this operation.
   -- @return nil: no values.
   local function release_build_compareVariant(variant)
      local first, second =
         attempt .. "/a/" .. variant, attempt .. "/different-path/b/" .. variant

      release_build_compile(first, variant, false)

      release_build_compile(second, variant, true)

      local records, tests = artifact_io.array(), artifact_io.array()

      for _, suffix in ipairs({ ".a", ".so", ".map", "-static", "-shared" }) do
         local filename = basename .. suffix
         local digest = artifact_io.digest(first .. "/" .. filename)

         assert(
            digest == artifact_io.digest(second .. "/" .. filename),
            "non-reproducible output: " .. filename
         )

         local path = "bins/" .. variant .. "/" .. filename

         artifact_io.write(
            stage .. "/" .. path,
            artifact_io.read(first .. "/" .. filename)
         )
         if suffix == "-static" or suffix == "-shared" then
            artifact_io.run({ "chmod", "755", stage .. "/" .. path })
         end

         local record = artifact_io.record(stage, path)

         records[#records + 1] = record
         products[#products + 1] = record
         comparisons[#comparisons + 1] =
            { path = path, first = digest, second = digest, status = "PASS" }
      end

      for _, mode in ipairs({ "static", "shared" }) do
         local path = "bins/" .. variant .. "/" .. basename .. "-" .. mode
         local log = "test_logs/"
            .. variant
            .. "/"
            .. mode
            .. "-smoke/"
            .. execution
            .. "/stdout.log"

         artifact_io.write(
            stage .. "/" .. log,
            artifact_io.read(first .. "/" .. mode .. ".log")
         )

         tests[#tests + 1] = {
            suite = mode .. "-smoke",
            status = "PASS",
            subject = path,
            sha256 = artifact_io.digest(stage .. "/" .. path),
            log = log,
            log_sha256 = artifact_io.digest(stage .. "/" .. log),
            exit_code = 0,
            timeout_seconds = RELEASE_PROBE_TIMEOUT_SECONDS,
         }
      end

      tests[#tests + 1] = {
         suite = "reproducibility",
         status = "PASS",
         subject = records[1].path,
         sha256 = records[1].sha256,
         comparison = "attestations/reproducibility.json",
      }

      artifact_io.document(
         stage .. "/test_logs/" .. variant .. "/index.json",
         { mock = true, execution = execution, tests = tests }
      )

      execution_api.sbom(
         stage,
         "product/" .. variant,
         version,
         full_digest,
         records,
         timestamp
      )

      execution_api.provenance(
         stage,
         variant,
         records,
         inputs,
         version,
         execution
      )
   end

   for _, variant in ipairs({ "release", "debug" }) do
      release_build_compareVariant(variant)
   end

   execution_api.sbom(
      stage,
      "build",
      version,
      full_digest,
      build_tools,
      timestamp
   )

   artifact_io.document(
      stage .. "/identity/artifacts.json",
      { mock = true, artifacts = products }
   )

   artifact_io.document(stage .. "/attestations/reproducibility.json", {
      mock = true,
      scope = "same-host clean builds with path and timezone variation",
      comparisons = comparisons,
   })

   artifact_io.document(stage .. "/distribution/install-manifest.json", {
      mock = true,
      shared_name = "libmemalloc.so.0",
      static_name = "libmemalloc.a",
      basename = basename,
   })

   artifact_io.document(stage .. "/compliance/status.json", {
      mock = true,
      gold = "MISSING",
      slsa = "UNQUALIFIED",
      signatures_at_build = "UNSIGNED",
      production_ready = false,
   })

   artifact_io.document(stage .. "/security/status.json", {
      state = "NOT_RUN",
      reason = (
         "No vulnerability or exploitability claims from "
         .. "the release fixture"
      ),
   })

   local sums = {}

   for _, record in ipairs(products) do
      sums[#sums + 1] = record.sha256 .. "  " .. record.path
   end

   artifact_io.write(
      stage .. "/digests/artifacts.sha256",
      table.concat(sums, "\n") .. "\n"
   )

   for _, path in ipairs(artifact_io.files(stage)) do
      if not path:match("^materials/objects/") then
         artifact_io.write(
            stage .. "/digests/files/" .. path .. ".sha256",
            artifact_io.digest(stage .. "/" .. path) .. "\n"
         )
      end
   end

   execution_api.validate(stage)

   artifact_io.index(stage)

   artifact_io.verify(stage)

   artifact_io.mkdir(output)

   artifact_io.run({ "mv", "-T", "--no-clobber", "--", stage, final })
   assert(
      not artifact_io.exists(stage),
      "candidate destination appeared during publication"
   )

   artifact_io.platform.remove_temporary_directory(attempt)

   local github_output = os.getenv("GITHUB_OUTPUT")

   if github_output then
      local handle = assert(io.open(github_output, "a"))

      handle:write("root=" .. final .. "\nbuild_id=" .. build_id .. "\n")

      handle:close()
   end

   print("Mock release verified: " .. final)
end

return scripts_release_build_main()

-- EOF


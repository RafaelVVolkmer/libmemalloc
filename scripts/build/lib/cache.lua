-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Cache authorization and namespace policy, independent of source revisions.
-- Part of build-matrix planning, execution and retained results.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_build_lib_cache_loadModule()
   local exports = {}

   --- Permit shared-cache writes only for trusted events on the default branch.
   -- @param event any: event supplied to this operation.
   -- @param branch any: branch supplied to this operation.
   -- @param default any: default supplied to this operation.
   -- @return boolean|nil: permit shared-cache writes only for trusted events on
   -- the default branch.
   local function BUILD_CACHE_trusted(event, branch, default)
      return default ~= ""
         and branch == default
         and (
            event == "push"
            or event == "workflow_dispatch"
            or event == "schedule"
         )
   end

   exports.trusted = BUILD_CACHE_trusted

   --- Construct isolated compiler-cache settings and enforce remote-cache
   -- prerequisites.
   -- @param build_io table: build filesystem and process operations.
   -- @param profile table: profile supplied to this operation.
   -- @param fingerprint any: fingerprint supplied to this operation.
   -- @param disabled any: disabled supplied to this operation.
   -- @return table, boolean|nil|string: isolated compiler-cache settings and
   -- enforce remote-cache prerequisites.
   local function BUILD_CACHE_environment(
      build_io,
      profile,
      fingerprint,
      disabled
   )
      local root = build_io.root .. "/.cache"
      local environment = {
         SCCACHE_DIR = root .. "/tools/sccache-data",
         SCCACHE_CONF = root .. "/tools/sccache-empty.toml",
         SCCACHE_C_CUSTOM_CACHE_BUSTER = fingerprint,
         SCCACHE_CACHE_SIZE = "2G",
         SCCACHE_IDLE_TIMEOUT = "0",
         CCACHE_DIR = root .. "/tools/ccache",
         CCACHE_COMPILERCHECK = "content",
         CCACHE_EXTRAFILES = root
            .. "/ci/build-cache-identity-"
            .. profile.id
            .. ".json",
         ZIG_GLOBAL_CACHE_DIR = root .. "/tools/zig-cache",
         ZIG_LOCAL_CACHE_DIR = root .. "/build/zig-cache",
      }

      build_io.write(
         environment.SCCACHE_CONF,
         "# Explicit configuration; no user defaults.\n"
      )

      build_io.mkdir(environment.SCCACHE_DIR)

      --- Derive cache write authority from the event, branch and explicit
      -- opt-out.
      -- @return any, any, boolean|nil: cache write authority from the event,
      -- branch and explicit opt-out.
      local function build_cache_authorizeRemote()
         local trusted = exports.trusted(
            os.getenv("GITHUB_EVENT_NAME") or "",
            os.getenv("GITHUB_REF_NAME") or "",
            os.getenv("LIBMEMALLOC_DEFAULT_BRANCH") or ""
         )

         local bucket = os.getenv("LIBMEMALLOC_CI_S3_CACHE_BUCKET") or ""
         local remote = trusted
            and bucket ~= ""
            and not disabled
            and profile.cache == "sccache"

         return trusted, bucket, remote
      end

      local trusted, bucket, remote = build_cache_authorizeRemote()

      --- Validate remote cache authority and configure its transport.
      -- @return nil: no values.
      local function build_cache_configureRemote()
         if remote then
            local endpoint = os.getenv("LIBMEMALLOC_CI_S3_CACHE_ENDPOINT") or ""

            assert(
               endpoint == "" or endpoint:match("^https://[^%s]+$"),
               "shared compiler cache requires HTTPS"
            )
            assert(
               bucket:match("^[a-z0-9][a-z0-9.-]+$"),
               "invalid compiler cache bucket"
            )
            assert(
               os.getenv("LIBMEMALLOC_BUILD_SDK_MANIFEST"),
               "remote reuse requires an immutable SDK manifest"
            )

            environment.SCCACHE_BUCKET = bucket
            environment.SCCACHE_ENDPOINT = endpoint
            environment.SCCACHE_REGION = os.getenv(
               "LIBMEMALLOC_CI_S3_CACHE_REGION"
            ) or "us-east-1"
            environment.SCCACHE_S3_USE_SSL = "true"
            environment.SCCACHE_S3_KEY_PREFIX = "libmemalloc/compiler/v1/"
            environment.SCCACHE_MULTILEVEL_CHAIN = "disk,s3"
         else
            environment.SCCACHE_MULTILEVEL_CHAIN = "disk"
         end
      end

      build_cache_configureRemote()

      if
         os.getenv("LIBMEMALLOC_BUILD_CACHE_REQUIRED") == "true" and trusted
      then
         assert(remote, "required shared compiler cache is unavailable")
      end

      if disabled then
         environment.SCCACHE_RECACHE = "1"
         environment.CCACHE_DISABLE = "1"
      end

      return environment,
         remote and "local+s3" or (disabled and "disabled" or "local")
   end

   exports.environment = BUILD_CACHE_environment

   return exports
end

return scripts_build_lib_cache_loadModule()

-- EOF


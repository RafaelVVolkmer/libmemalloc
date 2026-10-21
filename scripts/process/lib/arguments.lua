-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Validate a task's literal arguments without executing its domain operation.
-- @return table: public operations constructed by this module.
local function ARGUMENTS_loadModule()
   local ARGUMENTS_MAX_JOBS = 256
   local ARGUMENTS_MAX_RUN_ID_BYTES = 64
   local ARGUMENTS_SHA256_HEX_LENGTH = 64

   local catalog = dofile("tools/process/arguments.lua")
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local exports = {}
   local required = {
      ["scripts/verification/engine.lua"] = { "stage", "run-id" },
      ["scripts/analysis/run.lua"] = { "group" },
      ["scripts/build/run.lua"] = { "profile" },
      ["scripts/check/c_analysis.lua"] = { "campaign" },
      ["scripts/check/reproducible.lua"] = { "root" },
      ["scripts/qualification/batch.lua"] = { "batch" },
      ["scripts/qualification/run.lua"] = { "task" },
      ["scripts/release/build.lua"] = { "mock" },
      ["scripts/release/check_schemas.lua"] = { "root" },
      ["scripts/release/conan.lua"] = { "root" },
      ["scripts/release/package.lua"] = { "root" },
      ["scripts/release/sign.lua"] = { "root", "output" },
      ["scripts/release/verify.lua"] = { "root" },
      ["scripts/reproducible/compare.lua"] = { "first", "second", "output" },
      ["scripts/reproducible/normalizers.lua"] = { "input", "output" },
      ["scripts/reproducible/prepare.lua"] = { "output" },
      ["scripts/reproducible/vary.lua"] = { "profile", "source", "output" },
      ["scripts/security/report.lua"] = { "input", "output" },
      ["scripts/security/run.lua"] = { "project", "root" },
      ["scripts/toolchain/install/build.lua"] = { "profile" },
      ["scripts/toolchain/install/c_analysis.lua"] = { "group" },
      ["scripts/toolchain/install/c_scanners.lua"] = {
         "cppcheck",
         "flawfinder",
      },
      ["tests/automation/release/signature_test.lua"] = { "root" },
      ["tests/automation/reproducible/comparison_test.lua"] = { "input" },
   }

   --- Require a supplied option to belong to its domain's accepted values.
   -- @param options table: operation settings; omitted fields use the
   -- documented defaults.
   -- @param key string: record field or catalog key to select.
   -- @param choices table: choices supplied to this operation.
   -- @return nil: no values.
   local function member(options, key, choices)
      local value = options[key]

      assert(
         not value or choices[value],
         "invalid --" .. key .. ": " .. tostring(value)
      )
   end

   local validators = {}

   --- Keep mutually exclusive proof and Haskell modes consistent with their
   -- CLI.
   -- @param options table: parsed flag values.
   -- @return nil: no values.
   validators["scripts/verification/check.lua"] = function(options)
      assert(not (options.kernel and options.engine), "conflicting Lean modes")
   end

   --- Admit only one Haskell check mode at a time.
   -- @param options table: parsed flag values.
   -- @return nil: no values.
   validators["scripts/verification/check-haskell.lua"] = function(options)
      assert(not (options.lint and options.test), "conflicting Haskell modes")
   end

   --- Validate the formal stage identity before command execution.
   -- @param options table: parsed stage, run identity options.
   -- @return nil: no values.
   validators["scripts/verification/engine.lua"] = function(options)
      member(options, "stage", {
         start = true,
         prepare = true,
         lean = true,
         haskell = true,
         proof = true,
         tests = true,
         check = true,
      })
      assert(
         options["run-id"]:match("^[A-Za-z0-9][A-Za-z0-9_-]*$")
            and #options["run-id"] <= ARGUMENTS_MAX_RUN_ID_BYTES,
         "invalid run identity"
      )
   end

   --- Validate build identities using the same catalog as the build driver.
   -- @param options table: operation settings; omitted fields use the
   -- documented defaults.
   -- @return nil: no values.
   local function build_profile(options)
      member(
         options,
         "campaign",
         { pr = true, integration = true, nightly = true, exhaustive = true }
      )
      if options.profile then
         dofile("scripts/build/lib/matrix.lua").profile(
            dofile("tools/build/matrix.lua"),
            options.profile
         )
      end
   end

   validators["scripts/build/plan.lua"] = build_profile
   validators["scripts/build/run.lua"] = build_profile
   validators["scripts/build/report.lua"] = build_profile
   validators["scripts/toolchain/install/build.lua"] = build_profile

   --- Validate quality installer selections without provisioning tools.
   -- @param options table: operation settings; omitted fields use the
   -- documented defaults.
   -- @return nil: no values.
   validators["scripts/toolchain/install/quality.lua"] = function(options)
      member(
         options,
         "profile",
         { all = true, spelling = true, lua = true, build = true }
      )
   end

   --- Validate analysis groups before launching any campaign.
   -- @param options table: operation settings; omitted fields use the
   -- documented defaults.
   -- @return nil: no values.
   validators["scripts/analysis/run.lua"] = function(options)
      member(
         options,
         "group",
         { rules = true, quality = true, extended = true }
      )
   end

   --- Check values accepted by scripts/build/local.lua.
   -- @param options table: operation settings; omitted fields use the
   -- documented defaults.
   -- @return nil: no values.
   validators["scripts/build/local.lua"] = function(options)
      member(options, "profile", { debug = true, release = true })
      member(options, "os", {
         linux = true,
         windows = true,
         macos = true,
         freebsd = true,
         emscripten = true,
      })
      member(options, "arch", {
         x86_64 = true,
         aarch64 = true,
         armv7 = true,
         i686 = true,
         riscv64 = true,
         wasm32 = true,
      })
      member(options, "lld", { static = true, dynamic = true })
      member(options, "assurance", { ["local"] = true, full = true })
      if options.jobs then
         local jobs = tonumber(options.jobs)

         assert(
            jobs and jobs % 1 == 0 and jobs >= 1 and jobs <= ARGUMENTS_MAX_JOBS,
            "--jobs must be 1..256"
         )
      end

      if options.output then
         artifacts.safe_path(options.output)
         assert(options.output:match("^%.cache/"), "output must stay in .cache")
      end
   end

   --- Check values accepted by scripts/workspace/clean.lua.
   -- @param options table: operation settings; omitted fields use the
   -- documented defaults.
   -- @return nil: no values.
   validators["scripts/workspace/clean.lua"] = function(options)
      member(
         options,
         "scope",
         { all = true, build = true, cache = true, temporary = true }
      )
   end

   --- Check values accepted by scripts/github/specifications.lua.
   -- @param options table: operation settings; omitted fields use the
   -- documented defaults.
   -- @return nil: no values.
   validators["scripts/github/specifications.lua"] = function(options)
      member(options, "operation", { sync = true, enforce = true })
      assert(options.operation, "--operation is required")
      if options.operation == "enforce" then
         assert(
            options.issue and options.issue:match("^[1-9]%d*$"),
            "enforce requires --issue=NUMBER"
         )
      else
         assert(not options.issue, "sync does not accept an issue")
      end
   end

   --- Check values accepted by scripts/toolchain/python.lua.
   -- @param options table: operation settings; omitted fields use the
   -- documented defaults.
   -- @return nil: no values.
   validators["scripts/toolchain/python.lua"] = function(options)
      assert(
         options.groups and options.directory,
         "--groups and --directory are required"
      )
      artifacts.safe_path(options.directory)
      assert(
         options.directory:match("^%.cache/tools/[^/]+"),
         "use .cache/tools for environments"
      )
   end

   --- Check values accepted by scripts/process/main.lua.
   -- @param options table: operation settings; omitted fields use the
   -- documented defaults.
   -- @param action any: action supplied to this operation.
   -- @return nil: no values.
   validators["scripts/process/main.lua"] = function(options, action)
      member(options, "profile", { ["local"] = true })
      assert(options.output, "--output required")
      if action == "campaign" or action == "plan" then
         assert(options.profile == "local", "--profile=local required")
         assert(
            options["run-id"]
               and options["run-id"]:match("^[A-Za-z0-9][A-Za-z0-9_-]*$")
               and #options["run-id"] <= ARGUMENTS_MAX_RUN_ID_BYTES,
            "invalid --run-id"
         )
         assert(
            options["policy-sha256"]
               and options["policy-sha256"]:match("^[a-f0-9]+$")
               and #options["policy-sha256"] == ARGUMENTS_SHA256_HEX_LENGTH,
            "invalid --policy-sha256"
         )
      else
         assert(options.plan, "--plan required")
         if action ~= "run" then
            assert(options.evidence, "--evidence required")
         end
      end
   end

   local positional = {}

   --- Check the positional grammar of scripts/documentation/main.lua.
   -- @param arguments table: ordered arguments for the selected operation.
   -- @return boolean: check the positional grammar of
   -- scripts/documentation/main.lua.
   positional["scripts/documentation/main.lua"] = function(arguments)
      if #arguments == 1 and arguments[1] == "--help" then
         return true
      end

      dofile("scripts/documentation/lib/driver.lua").options(arguments)
   end

   --- Check the positional grammar of scripts/workspace/hooks.lua.
   -- @param arguments table: ordered arguments for the selected operation.
   -- @return nil: no values.
   positional["scripts/workspace/hooks.lua"] = function(arguments)
      assert(#arguments == 1 and ({
         install = true,
         status = true,
         repair = true,
         uninstall = true,
      })[arguments[1]], "invalid setup action")
   end

   --- Check the positional grammar of scripts/toolchain/resolve.lua.
   -- @param arguments table: ordered arguments for the selected operation.
   -- @return nil: no values.
   positional["scripts/toolchain/resolve.lua"] = function(arguments)
      if #arguments > 0 then
         assert(
            #arguments == 2 and arguments[1] == "--field",
            "expected --field NAME.KEY"
         )
         local name, key = arguments[2]:match("^([%w_]+)%.([%w_]+)$")
         local lock = dofile("scripts/toolchain/lib/lock.lua").load()

         assert(name and lock[name] and lock[name][key], "unknown lock field")
      end
   end

   --- Check the positional grammar of scripts/workspace/cache.lua.
   -- @param arguments table: ordered arguments for the selected operation.
   -- @return nil: no values.
   positional["scripts/workspace/cache.lua"] = function(arguments)
      assert(#arguments > 0, "supply a command after workspace-cache")
   end

   --- Check the positional grammar of scripts/check/format.lua.
   -- @param arguments table: ordered arguments for the selected operation.
   -- @return nil: no values.
   positional["scripts/check/format.lua"] = function(arguments)
      assert(#arguments >= 3, "expected language, formatter and input files")
   end

   --- Check the positional grammar of scripts/check/commits.lua.
   -- @param arguments table: ordered arguments for the selected operation.
   -- @return nil: no values.
   positional["scripts/check/commits.lua"] = function(arguments)
      assert(
         (#arguments == 1 and arguments[1]:match("^%x+$"))
            or (#arguments == 2 and arguments[1] == "--message-file"),
         "expected SHA or --message-file PATH"
      )
   end

   --- Check the positional grammar of scripts/workspace/changes.lua.
   -- @param arguments table: ordered arguments for the selected operation.
   -- @return nil: no values.
   positional["scripts/workspace/changes.lua"] = function(arguments)
      local seen = {}

      for index = 1, #arguments, 2 do
         local key, value = arguments[index], arguments[index + 1]

         assert(
            not seen[key]
               and (key == "--base" or key == "--head" or key == "--force-all")
               and value,
            "invalid changed-areas argument"
         )
         seen[key] = true
         if key == "--force-all" then
            assert(value == "true" or value == "false", "expected a boolean")
         end
      end
   end

   --- Parse and type-check options without executing the target command.
   -- @param path string: filesystem path selected by the caller.
   -- @param arguments table: ordered arguments for the selected operation.
   -- @return any: and type-check options without executing the target command.
   local function parse(path, arguments)
      local schema = catalog[path] or {}
      local options = artifacts.options(arguments, schema)

      for key, value in pairs(options) do
         local kind = schema[key]

         assert(
            kind ~= "flag" or value == true,
            "--" .. key .. " takes no value"
         )
         assert(
            kind ~= "value" or type(value) == "string",
            "--" .. key .. " requires a value"
         )
         assert(
            kind ~= "boolean"
               or value == true
               or value == "true"
               or value == "false",
            "--" .. key .. " requires a boolean"
         )
      end

      for _, key in ipairs(required[path] or {}) do
         assert(options[key], "--" .. key .. " is required")
      end

      return options
   end

   --- Check the complete domain argv, including the registered fixed prefix.
   -- @param task table: task supplied to this operation.
   -- @param supplied any: supplied supplied to this operation.
   -- @return nil: no values.
   function exports.validate(task, supplied)
      local arguments = {}

      for index = 2, #task.command do
         arguments[#arguments + 1] = task.command[index]
      end

      for _, value in ipairs(supplied) do
         assert(
            type(value) == "string" and not value:find("\0", 1, true),
            "invalid argument bytes"
         )
         arguments[#arguments + 1] = value
      end

      if task.argument_passthrough then
         return
      end

      local path = task.command[1]
      if positional[path] then
         positional[path](arguments)

         return
      end

      local action
      if path == "scripts/process/main.lua" then
         action = table.remove(arguments, 1)
         assert(
            ({
               plan = true,
               run = true,
               gate = true,
               report = true,
               campaign = true,
            })[action],
            "invalid process phase"
         )
      end

      local options = parse(path, arguments)
      if validators[path] then
         validators[path](options, action)
      end
   end

   return exports
end

return ARGUMENTS_loadModule()

-- EOF


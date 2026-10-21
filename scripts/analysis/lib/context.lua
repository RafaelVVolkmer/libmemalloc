-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Linux campaign evidence: explicit inputs, bounded commands, and fresh
-- reports.
-- Part of compiler analysis and module-boundary evidence.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_analysis_lib_context_loadModule()
   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local exports = { release = artifact_io }
   local locked_tools = dofile("scripts/toolchain/lib/lock.lua").load()
   local lock_names = {
      gcc = "gcc_analyzer",
      clang = "clang_analyzer",
      codechecker = "codechecker",
      sparse = "sparse",
   }

   --- Escape non-ASCII bytes before retaining command diagnostics.
   -- @param value any: value supplied to this operation.
   -- @return any: escape non-ASCII bytes before retaining command diagnostics.
   local function analysis_context_ascii(value)
      return (
         value:gsub(
            "[\128-\255]",
            --- Encode a diagnostic byte as a hexadecimal escape.
            -- @param character string: captured character or byte sequence.
            -- @return any: a diagnostic byte as a hexadecimal escape.
            function(character)
               return string.format("\\x%02x", character:byte())
            end
         )
      )
   end

   --- Split analyzer output into nonempty LF-delimited records.
   -- @param value any: value supplied to this operation.
   -- @return table: split analyzer output into nonempty LF-delimited records.
   local function ANALYSIS_CONTEXT_lines(value)
      local result = {}

      for line in value:gmatch("[^\n]+") do
         result[#result + 1] = line
      end

      return result
   end

   exports.lines = ANALYSIS_CONTEXT_lines

   --- Create a fresh analysis campaign and bind its report, commands and source
   -- inventory.
   -- @param campaign_name string: campaign name supplied to this operation.
   -- @param output string: output supplied to this operation.
   -- @return table: a fresh analysis campaign and bind its report, commands and
   -- source inventory.
   local function ANALYSIS_CONTEXT_new(campaign_name, output)
      assert(campaign_name:match("^[a-z][a-z-]+$"), "invalid campaign")

      artifact_io.safe_path(output)
      assert(output:match("^%.cache/"), "analysis output must remain in .cache")
      assert(not artifact_io.exists(output), "analysis output must be fresh")

      artifact_io.mkdir(output)

      local profile = dofile("tools/analysis/c/profile.lua")

      for _, value in pairs(profile) do
         if type(value) == "table" then
            artifact_io.array(value)
         end
      end

      local context = {
         name = campaign_name,
         output = output,
         root = artifact_io.output({ "git", "rev-parse", "--show-toplevel" }),
         profile = profile,
         report = {
            schema_version = 1,
            campaign = campaign_name,
            profile = profile.name,
            status = "RUNNING",
            expected = artifact_io.array(profile.sources),
            analyzed = artifact_io.array(),
            exclusions = artifact_io.array(),
            tools = {},
            commands = artifact_io.array(),
            findings = 0,
            coverage_limitations = artifact_io.array(profile.limitations),
            reuse = "Reports are never restored from build or analysis caches.",
         },
      }

      --- Persist the current campaign report after each observable state
      -- change.
      -- @return nil: no values.
      function context:save()
         artifact_io.document(self.output .. "/report.json", self.report)
      end

      --- Execute one bounded analyzer command and retain its status and output
      -- digest.
      -- @param label string: diagnostic or evidence label for this operation.
      -- @param command table: executable and literal command arguments.
      -- @param stdout any: stdout supplied to this operation.
      -- @return any, string: execute one bounded analyzer command and retain
      -- its status and output digest.
      function context:run(label, command, stdout)
         assert(label:match("^[%w_.-]+$"), "invalid log label")

         local log = self.output .. "/" .. label .. ".log"
         local bounded = { "timeout", "300" }

         for _, value in ipairs(command) do
            bounded[#bounded + 1] = value
         end

         local shell = artifact_io.platform.join_command(bounded)

         if stdout then
            shell = shell
               .. " >"
               .. artifact_io.platform.shell_quote(stdout)
               .. " 2>"
               .. artifact_io.platform.shell_quote(log)
         else
            shell = shell
               .. " >"
               .. artifact_io.platform.shell_quote(log)
               .. " 2>&1"
         end

         local first, _, code = os.execute(shell)
         local exit_code = first == true and 0 or (code or 1)

         self.report.commands[#self.report.commands + 1] = {
            label = label,
            argv = artifact_io.array(command),
            exit_code = exit_code,
            log = log,
            sha256 = artifact_io.digest(log),
         }

         self:save()

         return exit_code, log
      end

      --- Resolve an analyzer and retain the executable identity and version
      -- output.
      -- @param name string: entry or operation name to resolve.
      -- @param executable string: selected executable path or command name.
      -- @param version_argument any|nil: version argument supplied to this
      -- operation.
      -- @return any: an analyzer and retain the executable identity and version
      -- output.
      function context:tool(name, executable, version_argument)
         local path = artifact_io.output({ "which", executable })
         local resolved = artifact_io.output({ "readlink", "-f", path })
         local code, log = self:run(
            "version-" .. name,
            { executable, version_argument or "--version" }
         )

         assert(code == 0, name .. " version probe failed")

         local expected = locked_tools[assert(
            lock_names[name],
            "unqualified analysis tool"
         )].version

         local banner = artifact_io.read(log)
         local matched = false

         for version in banner:gmatch("%d+[%d%.]*") do
            if
               version == expected
               or version:sub(1, #expected + 1) == expected .. "."
            then
               matched = true
            end
         end

         assert(matched, name .. " does not match locked version " .. expected)

         self.report.tools[name] = {
            path = resolved,
            sha256 = artifact_io.digest(resolved),
            version = analysis_context_ascii(banner),
            locked_version = expected,
         }

         return executable
      end

      --- Bind the campaign to source, configuration and compilation database
      -- identities.
      -- @param database any: database supplied to this operation.
      -- @return nil: no values.
      function context:identity(database)
         local inputs = artifact_io.array()
         local files = exports.lines(artifact_io.output({
            "git",
            "ls-files",
            "--cached",
            "--others",
            "--exclude-standard",
            "--",
            "core",
            "CMakeLists.txt",
            "scripts",
            "tools/analysis",
            "tests/automation/analysis",
            "tests/fixtures/analysis",
         }))

         local seen = {}

         for _, path in ipairs(files) do
            if not seen[path] then
               artifact_io.safe_path(path)
               assert(not artifact_io.platform.command_succeeded_silent({
                  "test",
                  "-L",
                  path,
               }), "symlink input: " .. path)

               inputs[#inputs + 1] =
                  { path = path, sha256 = artifact_io.digest(path) }
               seen[path] = true
            end
         end

         table.sort(
            inputs,
            --- Order source records by path for a stable campaign identity.
            -- @param left table: left supplied to this operation.
            -- @param right table: right supplied to this operation.
            -- @return boolean: order source records by path for a stable
            -- campaign identity.
            function(left, right)
               return left.path < right.path
            end
         )

         local identity = {
            campaign = self.name,
            profile = self.profile,
            inputs = inputs,
            tools = self.report.tools,
            target = artifact_io.output({ "uname", "-m" }),
            compilation_database = database and artifact_io.read(database)
               or "not applicable",
         }

         artifact_io.document(self.output .. "/inputs.json", identity)

         self.report.cache_identity =
            artifact_io.digest(self.output .. "/inputs.json")
         self:save()
      end

      --- Verify the declared analysis inventory before selecting any source
      -- file.
      -- @return nil: no values.
      function context:inventory()
         local actual = exports.lines(artifact_io.output({
            "git",
            "ls-files",
            "--cached",
            "--others",
            "--exclude-standard",
            "--",
            "core/*.c",
         }))

         table.sort(actual)
         assert(
            table.concat(actual, "\n")
               == table.concat(self.profile.sources, "\n"),
            "update analysis profile for changed source inventory"
         )
      end

      --- Configure the analysis build with the selected compiler and capture
      -- its
      -- database.
      -- @param compiler any: selected compiler identity.
      -- @return string: configure the analysis build with the selected compiler
      -- and capture its database.
      function context:build(compiler)
         local directory = self.output .. "/build"

         artifact_io.write(directory .. "/.cmake/api/v1/query/codemodel-v2", "")

         local command = {
            "cmake",
            "-S",
            ".",
            "-B",
            directory,
            "-G",
            "Unix Makefiles",
            "-DLMA_BUILD_MOCK=ON",
            "-DLMA_BUILD_MOCK_CONSUMER=ON",
            "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
            "-DCMAKE_BUILD_TYPE=Debug",
            "-DCMAKE_C_STANDARD=99",
            "-DCMAKE_C_EXTENSIONS=OFF",
            "-DCMAKE_C_COMPILER=" .. compiler,
         }

         assert(self:run("configure", command) == 0, "configuration failed")
         assert(
            self:run(
               "build",
               { "cmake", "--build", directory, "--parallel", "2" }
            ) == 0,
            "build failed"
         )

         local database = directory .. "/compile_commands.json"
         local files = exports.lines(artifact_io.query(database, ".[ ].file"))

         table.sort(files)
         assert(
            #files == #self.profile.sources,
            "compilation database source count mismatch"
         )

         for index, source in ipairs(self.profile.sources) do
            assert(
               files[index] == self.root .. "/" .. source,
               "unexpected compilation database source"
            )
         end

         return database
      end

      --- Resolve a declared fixture below the campaign source directory.
      -- @param name string: entry or operation name to resolve.
      -- @return string: a declared fixture below the campaign source directory.
      function context:fixture(name)
         local path = self.output .. "/fixtures/" .. name .. ".c"

         artifact_io.write(
            path,
            artifact_io.read("tests/fixtures/analysis/" .. name .. ".c.in")
         )

         return path
      end

      --- Run the campaign under error capture; save failure evidence before
      -- propagating it.
      -- @param callback function: operation supplied by the caller; errors
      -- propagate.
      -- @return nil: no values.
      function context:finish(callback)
         self:save()

         local success, message = xpcall(callback, debug.traceback)

         if not success then
            self.report.status = "ERROR"
            self.report.error = analysis_context_ascii(message)
         elseif self.report.status == "RUNNING" then
            self.report.status = self.report.findings == 0 and "PASS" or "FAIL"
         end

         self:save()

         print(
            self.name
               .. ": "
               .. self.report.status
               .. "; "
               .. self.output
               .. "/report.json"
         )
         assert(
            self.report.status == "PASS",
            message or "campaign requires review"
         )
      end

      return context
   end

   exports.new = ANALYSIS_CONTEXT_new

   return exports
end

return scripts_analysis_lib_context_loadModule()

-- EOF


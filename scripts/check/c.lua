-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer
-- <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Run repository C formatting and static analysis locally or in CI.
-- Override tool paths with LIBMEMALLOC_CLANG_FORMAT and
-- LIBMEMALLOC_CLANG_TIDY.
-- Part of local and CI verification gates.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_check_c_main()
   local C_ARGV_BATCH_SIZE = 64

   --- Resolve the repository and helper roots from this command path.
   -- @return string, string: repository root and its shared Lua library root.
   local function check_c_roots()
      local raw_script = tostring(arg[0] or ""):gsub("\\", "/")
      local script_dir = raw_script:match("^(.*)/[^/]+$") or "scripts/check"
      local scripts_root = script_dir:match("^(.*)/check$") or "scripts"
      local repo_root = scripts_root:match("^(.*)/scripts$") or "."
      local library_root = scripts_root .. "/lib"

      return repo_root, library_root
   end

   local repo_root, library_root = check_c_roots()
   local paths = dofile(library_root .. "/paths.lua")
   local platform = dofile(paths.join(library_root, "platform.lua"))
   local git_module = dofile(paths.join(library_root, "git.lua"))
   local git = git_module.new(platform, repo_root)

   local format_config = "tools/lint/code/c/.clang-format"
   local tidy_config = "tools/lint/code/c/.clang-tidy"

   --- Print a fatal diagnostic and terminate.
   -- @param message string: diagnostic text.
   -- @return nil: no values.
   local function check_c_fail(message)
      io.stderr:write("libmemalloc check-c: error: " .. message .. "\n")

      os.exit(1)
   end

   --- Resolve one required executable.
   -- @param variable string: environment variable override.
   -- @param default_name string: default executable name.
   -- @return string: executable to invoke.
   local function check_c_tool(variable, default_name)
      local executable = platform.resolve_tool(variable, default_name)

      if not executable then
         check_c_fail(
            "required tool '"
               .. default_name
               .. "' is unavailable; set "
               .. variable
               .. "."
         )
      end

      return executable
   end

   --- Execute one command and convert library errors into stable diagnostics.
   -- @param arguments table: command arguments.
   -- @return nil: no values.
   local function check_c_run(arguments)
      local ok, message = pcall(platform.run_in_directory, repo_root, arguments)

      if not ok then
         check_c_fail(message)
      end
   end

   --- Run one command over files in bounded argv batches.
   -- @param prefix table: command and fixed arguments.
   -- @param files table: paths to append.
   -- @return nil: no values.
   local function check_c_runBatched(prefix, files)
      local ok, message = pcall(
         platform.run_batched_in_directory,
         repo_root,
         prefix,
         files,
         C_ARGV_BATCH_SIZE
      )

      if not ok then
         check_c_fail(message)
      end
   end

   assert(
      not arg[1] or arg[1] == "--doxygen-only",
      "unknown check_c.lua option"
   )
   assert(not arg[2], "check_c.lua accepts at most one option")

   check_c_run({
      platform.resolve_tool("LIBMEMALLOC_LUA", "lua") or "lua",
      "scripts/documentation/main.lua",
      "eval",
   })

   -- A documentation-only entry point is useful in local review and CI.
   if arg[1] == "--doxygen-only" then
      return
   end

   local clang_format = check_c_tool("LIBMEMALLOC_CLANG_FORMAT", "clang-format")
   local clang_tidy = check_c_tool("LIBMEMALLOC_CLANG_TIDY", "clang-tidy")
   local cppcheck = check_c_tool("LIBMEMALLOC_CPPCHECK", "cppcheck")
   local flawfinder = check_c_tool("LIBMEMALLOC_FLAWFINDER", "flawfinder")
   local scanners =
      dofile(paths.join(repo_root, "tools/lint/code/c/scanners.lua"))
   local scanner_tests = dofile(
      paths.join(repo_root, "tests/automation/check/c_scanners_test.lua")
   )

   scanner_tests(platform, cppcheck, flawfinder)

   --- Require the selected C formatter to start successfully.
   -- @return nil: no values.
   local function check_c_probeFormatting()
      if
         not platform.command_succeeded_silent_in_directory(repo_root, {
            clang_format,
            "--style=file:" .. format_config,
            "--dump-config",
         })
      then
         check_c_fail("clang-format configuration is invalid.")
      end
   end

   check_c_probeFormatting()

   --- Require the selected Clang analyzer to start successfully.
   -- @return nil: no values.
   local function check_c_probeAnalysis()
      if
         not platform.command_succeeded_silent_in_directory(repo_root, {
            clang_tidy,
            "--experimental-custom-checks",
            "--config-file=" .. tidy_config,
            "--list-checks",
         })
      then
         check_c_fail("clang-tidy configuration is invalid.")
      end
   end

   check_c_probeAnalysis()

   local tracked = git.working_files()
   local policy_tests =
      dofile(paths.join(repo_root, "tests/automation/check/c_policy_test.lua"))

   policy_tests({
      root = repo_root,
      platform = platform,
      tidy = clang_tidy,
      format = clang_format,
      tidy_config = tidy_config,
      format_config = format_config,
   })

   if type(tracked) ~= "table" then
      check_c_fail("git ls-files failed.")
   end

   local format_files = {}
   local translation_units = {}

   assert(type(tracked) == "table", "git ls-files must return a table.")

   --- Select one source for C formatting and analyzer checks.
   -- @param path string: filesystem path selected by the caller.
   -- @return nil: no values.
   local function check_c_classifySource(path)
      if
         paths.ends_with(path, ".c")
         or paths.ends_with(path, ".h")
         or paths.ends_with(path, ".i")
      then
         format_files[#format_files + 1] = path
      end

      if paths.ends_with(path, ".c") or paths.ends_with(path, ".i") then
         translation_units[#translation_units + 1] = path
      end
   end

   for _, path in ipairs(tracked) do
      check_c_classifySource(path)
   end

   if #format_files == 0 then
      print("No tracked C sources or headers found; policy files are valid.")

      os.exit(0)
   end

   print(string.format("Checking %d C source/header file(s).", #format_files))

   local release = dofile(paths.join(library_root, "artifacts.lua"))
   local analysis_cache = paths.join(repo_root, ".cache/tools/cppcheck")

   release.mkdir(analysis_cache)

   --- Run one configured C scanner over the collected sources.
   -- @param scanner table: scanner supplied to this operation.
   -- @return nil: no values.
   local function check_c_runScanner(scanner)
      local command = { scanner.executable }

      for _, argument in ipairs(scanner.arguments) do
         command[#command + 1] = argument
      end

      if scanner.executable == cppcheck then
         command[#command + 1] = "--cppcheck-build-dir=" .. analysis_cache
      end

      if #scanner.files > 0 then
         check_c_runBatched(command, scanner.files)
      end
   end

   for _, scanner in ipairs({
      {
         executable = cppcheck,
         arguments = scanners.cppcheck,
         files = translation_units,
      },
      {
         executable = flawfinder,
         arguments = scanners.flawfinder,
         files = format_files,
      },
   }) do
      check_c_runScanner(scanner)
   end

   check_c_runBatched({
      platform.resolve_tool("LIBMEMALLOC_LUA", "lua") or "lua",
      "scripts/check/format.lua",
      "c",
      clang_format,
   }, format_files)

   for _, source in ipairs(translation_units) do
      check_c_run({
         clang_tidy,
         "--experimental-custom-checks",
         "--config-file=" .. tidy_config,
         source,
         "--",
         "-std=c23",
         "-I.",
      })
   end
end

return scripts_check_c_main()

-- EOF


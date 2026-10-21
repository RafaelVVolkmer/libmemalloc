-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer
-- <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Cross-platform process helpers for Lua tooling.
-- Keep host-shell quoting and command discovery isolated in this module.
-- Part of shared host, path and artifact primitives.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_lib_platform_loadModule()
   local PLATFORM_ARGV_BATCH_SIZE = 64
   local PLATFORM_SIGNAL_EXIT_BASE = 128

   local exports = {}
   local temporary_directories = {}

   exports.is_windows = os.getenv("OS") == "Windows_NT"
   exports.null_device = exports.is_windows and "NUL" or "/dev/null"

   --- Normalize Lua process-status return values.
   -- @param first boolean|number|nil: first status value.
   -- @param code number|nil: process exit code when available.
   -- @return boolean: true only for a successful process exit.
   local function platform_processSucceeded(first, code)
      if type(first) == "number" then
         return first == 0
      end

      if first == true then
         return true
      end

      return code == 0
   end

   --- Quote one argument for the host command processor.
   -- @param value string: argument to quote.
   -- @return string: quoted argument.
   local function PLATFORM_shellQuote(value)
      value = tostring(value)

      if exports.is_windows then
         value = value:gsub("%%", "%%%%")
         value = value:gsub(
            '(\\*)"',
            --- Double backslashes before a Windows command-line quote.
            -- @param slashes string: backslashes captured immediately before a
            -- quote.
            -- @return string: double backslashes before a Windows command-line
            -- quote.
            function(slashes)
               return slashes .. slashes .. '\\"'
            end
         )
         value = value:gsub("(\\+)$", "%1%1")

         return '"' .. value .. '"'
      end

      return "'" .. value:gsub("'", "'\\''") .. "'"
   end

   exports.shell_quote = PLATFORM_shellQuote

   --- Join an argv-style table into one host-shell command.
   -- @param arguments table: command arguments.
   -- @return string: quoted command string.
   local function PLATFORM_joinCommand(arguments)
      local quoted = {}

      for index, value in ipairs(arguments) do
         quoted[index] = exports.shell_quote(value)
      end

      return table.concat(quoted, " ")
   end

   exports.join_command = PLATFORM_joinCommand

   --- Build a command that executes from one working directory.
   -- @param directory string: working directory.
   -- @param arguments table|string: argv table or complete command string.
   -- @return string: host-shell command.
   local function PLATFORM_inDirectory(directory, arguments)
      local command = arguments

      if type(arguments) == "table" then
         command = exports.join_command(arguments)
      end

      if exports.is_windows then
         return "cd /d " .. exports.shell_quote(directory) .. " && " .. command
      end

      return "cd " .. exports.shell_quote(directory) .. " && " .. command
   end

   exports.in_directory = PLATFORM_inDirectory

   --- Run a command and report whether it completed successfully.
   -- @param arguments table|string: argv table or complete command string.
   -- @return boolean: true when the command exits with status zero.
   local function PLATFORM_commandSucceeded(arguments)
      local command = arguments

      if type(arguments) == "table" then
         command = exports.join_command(arguments)
      end

      -- The Windows CRT passes the command through cmd /c, which strips
      -- an outer quote pair. Preserve the quoted executable and its arguments.
      if exports.is_windows then
         command = '"' .. command .. '"'
      end

      local first, _, code = os.execute(command)

      return platform_processSucceeded(first, code)
   end

   exports.command_succeeded = PLATFORM_commandSucceeded

   --- Capture stdout from a command and fail closed on non-zero exit status.
   -- @param arguments table|string: argv table or complete command string.
   -- @return string|nil: stdout, or nil when the command fails.
   local function PLATFORM_commandOutput(arguments)
      local command = arguments

      if type(arguments) == "table" then
         command = exports.join_command(arguments)
      end

      if exports.is_windows then
         command = '"' .. command .. '"'
      end

      local handle = io.popen(command, "r")

      if not handle then
         return nil
      end

      local output = handle:read("*a")
      local first, _, code = handle:close()

      if not platform_processSucceeded(first, code) then
         return nil
      end

      return output
   end

   exports.command_output = PLATFORM_commandOutput

   --- Create an exclusively owned temporary directory without optional modules.
   -- @param category string|nil: fixed cache category; defaults to tmp.
   -- @param cache_root string|nil: explicit controller cache, otherwise
   -- environment or repository.
   -- @return string: absolute directory path, private to this process.
   local function PLATFORM_temporaryDirectory(category, cache_root)
      local root = cache_root or os.getenv("LIBMEMALLOC_CACHE_ROOT")
      local categories = {
         tmp = true,
         cleanup = true,
         build = true,
         tests = true,
         tools = true,
         ci = true,
         cd = true,
         logs = true,
      }

      category = category or "tmp"
      assert(categories[category], "unsupported cache category")

      if not root then
         root = assert(
            exports.command_output({ "git", "rev-parse", "--show-toplevel" })
         )
         root = root:gsub("[\r\n]+$", "") .. "/.cache"
      end

      assert(
         root:gsub("\\", "/"):match("/%.cache$"),
         "temporary files must remain in the repository cache"
      )

      local parent = root .. "/" .. category
      local arguments = { "mktemp", "-d", parent .. "/run.XXXXXXXXXX" }

      if exports.is_windows then
         arguments = {
            "powershell",
            "-NoProfile",
            "-NonInteractive",
            "-Command",
            "New-Item -ItemType Directory -Force -Path '"
               .. parent:gsub("'", "''")
               .. "' | Out-Null; $p = Join-Path '"
               .. parent:gsub("'", "''")
               .. "' ([guid]::NewGuid()); New-Item -ItemType "
               .. "Directory -Path $p -ErrorAction Stop | Out-Null; "
               .. "[Console]::WriteLine($p)",
         }
      else
         assert(exports.command_succeeded({ "mkdir", "-p", "--", parent }))
      end

      -- CWE-377: the OS creates the directory before its name becomes visible.
      local directory =
         assert(exports.command_output(arguments)):gsub("[\r\n]+$", "")

      assert(directory ~= "" and directory ~= "/", "invalid temporary path")

      temporary_directories[directory] = true

      return directory
   end

   exports.temporary_directory = PLATFORM_temporaryDirectory

   --- Remove only a private directory allocated by this module instance.
   -- @param directory string: exact path returned by temporary_directory.
   -- @return nil: no values.
   local function PLATFORM_removeTemporaryDirectory(directory)
      -- CWE-22: callers cannot use cleanup to remove arbitrary repository
      -- paths.
      assert(
         temporary_directories[directory],
         "temporary directory is not owned"
      )

      local arguments = { "rm", "-r", "--", directory }

      if exports.is_windows then
         arguments = {
            "powershell",
            "-NoProfile",
            "-NonInteractive",
            "-Command",
            "Remove-Item -LiteralPath '"
               .. directory:gsub("'", "''")
               .. "' -Recurse -Force -ErrorAction Stop",
         }
      end

      assert(
         exports.command_succeeded(arguments),
         "temporary directory cleanup failed"
      )

      temporary_directories[directory] = nil
   end

   exports.remove_temporary_directory = PLATFORM_removeTemporaryDirectory

   --- Append host-native stdout and stderr redirection to the null device.
   -- @param command string: command string.
   -- @return string: command with all output suppressed.
   local function PLATFORM_silenceAll(command)
      local null = exports.shell_quote(exports.null_device)

      return command .. " >" .. null .. " 2>&1"
   end

   exports.silence_all = PLATFORM_silenceAll

   --- Run a command while discarding stdout and stderr.
   -- @param arguments table|string: argv table or complete command string.
   -- @return boolean: true when the command exits with status zero.
   local function PLATFORM_commandSucceededSilent(arguments)
      local command = arguments

      if type(arguments) == "table" then
         command = exports.join_command(arguments)
      end

      return exports.command_succeeded(exports.silence_all(command))
   end

   exports.command_succeeded_silent = PLATFORM_commandSucceededSilent

   --- Run a command from one directory and report success.
   -- @param directory string: working directory.
   -- @param arguments table|string: argv table or complete command string.
   -- @return boolean: true when the command exits with status zero.
   local function PLATFORM_commandSucceededInDirectory(directory, arguments)
      return exports.command_succeeded(
         exports.in_directory(directory, arguments)
      )
   end

   exports.command_succeeded_in_directory = PLATFORM_commandSucceededInDirectory

   --- Capture stdout from a command executed from one directory.
   -- @param directory string: working directory.
   -- @param arguments table|string: argv table or complete command string.
   -- @return string|nil: stdout, or nil when the command fails.
   local function PLATFORM_commandOutputInDirectory(directory, arguments)
      return exports.command_output(exports.in_directory(directory, arguments))
   end

   exports.command_output_in_directory = PLATFORM_commandOutputInDirectory

   --- Run a command silently from one directory.
   -- @param directory string: working directory.
   -- @param arguments table|string: argv table or complete command string.
   -- @return boolean: true when the command exits with status zero.
   local function PLATFORM_commandSucceededSilentInDirectory(
      directory,
      arguments
   )
      local command = exports.in_directory(directory, arguments)

      return exports.command_succeeded(exports.silence_all(command))
   end

   exports.command_succeeded_silent_in_directory =
      PLATFORM_commandSucceededSilentInDirectory

   --- Check whether an executable is available through PATH.
   -- @param name string: executable name.
   -- @return boolean: true when resolvable.
   local function PLATFORM_commandExists(name)
      local probe

      if exports.is_windows then
         probe = "where.exe " .. exports.shell_quote(name)
      else
         probe = "command -v " .. exports.shell_quote(name)
      end

      return exports.command_succeeded(exports.silence_all(probe))
   end

   exports.command_exists = PLATFORM_commandExists

   --- Resolve a required executable from an environment override or PATH.
   -- @param variable string: environment variable override.
   -- @param default_name string: executable name used when no override exists.
   -- @return string|nil: executable path/name, or nil when unavailable.
   local function PLATFORM_resolveTool(variable, default_name)
      local value = os.getenv(variable)

      if value and value ~= "" then
         return value
      end

      if exports.command_exists(default_name) then
         return default_name
      end

      return nil
   end

   exports.resolve_tool = PLATFORM_resolveTool

   --- Execute a literal argv vector and preserve the native process status.
   -- @param arguments table: executable and arguments quoted by this adapter.
   -- @return number: exit code, or 128 plus the terminating signal on POSIX.
   local function PLATFORM_execute(arguments)
      local command = exports.join_command(arguments)
      if exports.is_windows then
         command = '"' .. command .. '"'
      end

      local passed, reason, status = os.execute(command)
      local code = status or 1

      if passed == true or passed == 0 then
         code = 0
      elseif reason == "signal" then
         code = PLATFORM_SIGNAL_EXIT_BASE + code
      end

      return code
   end

   exports.execute = PLATFORM_execute

   --- Run one argv table and raise a Lua error on failure.
   -- @param arguments table: command arguments.
   -- @return nil: no values.
   local function PLATFORM_run(arguments)
      if not exports.command_succeeded(arguments) then
         error("command failed: " .. exports.join_command(arguments), 2)
      end
   end

   exports.run = PLATFORM_run

   --- Run one argv table from a working directory and raise on failure.
   -- @param directory string: working directory.
   -- @param arguments table: command arguments.
   -- @return nil: no values.
   local function PLATFORM_runInDirectory(directory, arguments)
      if not exports.command_succeeded_in_directory(directory, arguments) then
         error(
            "command failed: " .. exports.in_directory(directory, arguments),
            2
         )
      end
   end

   exports.run_in_directory = PLATFORM_runInDirectory

   --- Reject batch sizes that cannot make finite forward progress.
   -- @param batch_size number|nil: positive finite integer, or the default.
   -- @return any: reject batch sizes that cannot make finite forward progress.
   local function platform_batchLimit(batch_size)
      local limit = batch_size or PLATFORM_ARGV_BATCH_SIZE

      assert(type(limit) == "number", "batch size must be a number")
      assert(
         limit > 0 and limit < math.huge and limit % 1 == 0,
         "batch size must be a positive finite integer"
      )

      return limit
   end

   --- Run a command over paths in bounded argv batches.
   -- @param prefix table: command and fixed arguments.
   -- @param values table: arguments to append.
   -- @param batch_size number|nil: maximum appended values per invocation.
   -- @return nil: no values.
   local function PLATFORM_runBatched(prefix, values, batch_size)
      local limit = platform_batchLimit(batch_size)
      local first = 1

      while first <= #values do
         local arguments = {}

         for _, value in ipairs(prefix) do
            arguments[#arguments + 1] = value
         end

         local last = math.min(first + limit - 1, #values)

         for index = first, last do
            arguments[#arguments + 1] = values[index]
         end

         exports.run(arguments)

         first = last + 1
      end
   end

   exports.run_batched = PLATFORM_runBatched

   --- Run a command over values in bounded batches from one directory.
   -- @param directory string: working directory.
   -- @param prefix table: command and fixed arguments.
   -- @param values table: arguments to append.
   -- @param batch_size number|nil: maximum appended values per invocation.
   -- @return nil: no values.
   local function PLATFORM_runBatchedInDirectory(
      directory,
      prefix,
      values,
      batch_size
   )
      local limit = platform_batchLimit(batch_size)
      local first = 1

      while first <= #values do
         local arguments = {}

         for _, value in ipairs(prefix) do
            arguments[#arguments + 1] = value
         end

         local last = math.min(first + limit - 1, #values)

         for index = first, last do
            arguments[#arguments + 1] = values[index]
         end

         exports.run_in_directory(directory, arguments)

         first = last + 1
      end
   end

   exports.run_batched_in_directory = PLATFORM_runBatchedInDirectory

   return exports
end

return scripts_lib_platform_loadModule()

-- EOF


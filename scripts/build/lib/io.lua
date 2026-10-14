-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Portable build evidence using CMake host utilities and explicit argv.
-- Part of build-matrix planning, execution and retained results.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_build_lib_io_loadModule()
   local BUILD_STAGE_TIMEOUT_SECONDS =
      { configure = 600, build = 900, test = 300 }
   local BUILD_DEFAULT_TIMEOUT_SECONDS = 120

   local BUILD_SHA256_HEX_LENGTH = 64

   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local exports = {
      release = artifact_io,
      platform = artifact_io.platform,
      array = artifact_io.array,
      read = artifact_io.read,
      output = artifact_io.output,
   }

   exports.root = artifact_io
      .output({ "git", "rev-parse", "--show-toplevel" })
      :gsub("\\", "/")

   --- Split captured command output into nonempty lines.
   -- @param value any: value supplied to this operation.
   -- @return table: split captured command output into nonempty lines.
   local function BUILD_IO_lines(value)
      local result = {}

      for line in value:gmatch("[^\r\n]+") do
         result[#result + 1] = line
      end

      return result
   end

   exports.lines = BUILD_IO_lines

   --- Create parent directories through CMake on the selected host platform.
   -- @param path string: filesystem path selected by the caller.
   -- @return nil: no values.
   local function BUILD_IO_mkdir(path)
      artifact_io.run({ "cmake", "-E", "make_directory", path })
   end

   exports.mkdir = BUILD_IO_mkdir

   --- Write staging bytes after creating parents; reject open, write and close
   -- failures.
   -- @param path string: filesystem path selected by the caller.
   -- @param content string: input bytes to process.
   -- @return nil: no values.
   local function BUILD_IO_write(path, content)
      exports.mkdir(assert(path:match("^(.*)/[^/]+$"), "missing output parent"))

      local file = assert(io.open(path, "wb"))

      assert(file:write(content))
      assert(file:close())
   end

   exports.write = BUILD_IO_write

   --- Persist a formatted JSON record through the shared staging writer.
   -- @param path string: filesystem path selected by the caller.
   -- @param value any: input value; validation belongs to this operation’s
   -- contract.
   -- @return nil: no values.
   local function BUILD_IO_json(path, value)
      exports.write(path, artifact_io.pretty_json(value))
   end

   exports.json = BUILD_IO_json

   --- Hash a file through CMake and validate the complete SHA-256 output.
   -- @param path string: filesystem path selected by the caller.
   -- @return string: hash a file through CMake and validate the complete
   -- SHA-256 output.
   local function BUILD_IO_digest(path)
      local value = artifact_io
         .output({ "cmake", "-E", "sha256sum", path })
         :match("^(%x+)")

      assert(value and #value == BUILD_SHA256_HEX_LENGTH, "invalid file digest")

      return value:lower()
   end

   exports.digest = BUILD_IO_digest

   --- Run a jq filter from a temporary file so shell operators remain data.
   -- @param path string: filesystem path selected by the caller.
   -- @param expression any: expression supplied to this operation.
   -- @return any: run a jq filter from a temporary file so shell operators
   -- remain data.
   local function BUILD_IO_query(path, expression)
      -- A file avoids cmd.exe interpreting operators embedded in jq
      -- expressions.
      local directory = artifact_io.platform.temporary_directory("tmp")
      local filter = directory .. "/filter.jq"

      --- Keep creation and execution inside the same temporary-file lifetime.
      -- @return any: keep creation and execution inside the same temporary-file
      -- lifetime.
      local function build_io_runQuery()
         exports.write(filter, expression)

         return artifact_io.output({ "jq", "-er", "-f", filter, path })
      end

      local success, result = pcall(build_io_runQuery)

      artifact_io.platform.remove_temporary_directory(directory)
      assert(success, result)

      return result
   end

   exports.query = BUILD_IO_query

   --- Resolve a retained path on the host before accepting downloaded evidence.
   -- @param path string: filesystem path selected by the caller.
   -- @return any: a retained path on the host before accepting downloaded
   -- evidence.
   local function BUILD_IO_realPath(path)
      assert(not path:find("[\r\n]"), "line break in evidence path")
      local temporary = exports.platform.temporary_directory("tmp")
      --- Resolve the path inside a protected scope so temporary files are
      -- removed.
      -- @return any: the path inside a protected scope so temporary files are
      -- removed.
      local ok, value = pcall(function()
         local equals = "="

         while path:find("]" .. equals .. "]", 1, true) do
            equals = equals .. "="
         end

         exports.write(
            temporary .. "/path.cmake",
            "file(REAL_PATH ["
               .. equals
               .. "["
               .. path
               .. "]"
               .. equals
               .. "] resolved)\nfile(WRITE [=["
               .. temporary
               .. '/resolved]=] "${resolved}")\n'
         )
         artifact_io.run({ "cmake", "-P", temporary .. "/path.cmake" })

         return exports.read(temporary .. "/resolved")
      end)

      exports.platform.remove_temporary_directory(temporary)
      assert(ok, value)

      return value
   end

   exports.real_path = BUILD_IO_realPath

   --- Execute a build command with explicit environment overrides and retain
   -- its
   -- log identity.
   -- @param report table: report supplied to this operation.
   -- @param directory string: working or output directory selected by the
   -- caller.
   -- @param label string: diagnostic or evidence label for this operation.
   -- @param argv table: dense executable-and-arguments sequence; values remain
   -- literal.
   -- @param environment any: environment supplied to this operation.
   -- @param deadline any|nil: deadline supplied to this operation.
   -- @return boolean, string: execute a build command with explicit environment
   -- overrides and retain its log identity.
   local function BUILD_IO_run(
      report,
      directory,
      label,
      argv,
      environment,
      deadline
   )
      exports.mkdir(directory)

      local command = argv

      --- Construct a literal environment overlay for the supervised child.
      -- @return nil: no values.
      local function build_io_applyEnvironment()
         if environment and next(environment) then
            command = { "cmake", "-E", "env" }

            for key, value in pairs(environment) do
               command[#command + 1] = key .. "=" .. value
            end

            command[#command + 1] = "--"

            for _, value in ipairs(argv) do
               command[#command + 1] = value
            end
         end
      end

      build_io_applyEnvironment()

      local log = directory .. "/" .. label .. ".log"
      local started = os.time()
      local limits = BUILD_STAGE_TIMEOUT_SECONDS
      local limit = deadline or limits[label] or BUILD_DEFAULT_TIMEOUT_SECONDS

      assert(type(limit) == "number" and limit > 0, "invalid command deadline")
      local temporary = exports.platform.temporary_directory("tmp")
      local status_file = temporary .. "/status"

      --- Preserve every argument as literal CMake bracket data.
      -- @param value any: value supplied to this operation.
      -- @return string: preserve every argument as literal CMake bracket data.
      local function literal(value)
         assert(not value:find("%z"), "NUL in command argument")
         local equals = "="

         while value:find("]" .. equals .. "]", 1, true) do
            equals = equals .. "="
         end

         return "[" .. equals .. "[" .. value .. "]" .. equals .. "]"
      end

      --- Run the generated CMake adapter before releasing its temporary
      -- directory.
      -- @return any: run the generated CMake adapter before releasing its
      -- temporary directory.
      local ok, result = pcall(function()
         local arguments = {}

         for _, value in ipairs(command) do
            arguments[#arguments + 1] = literal(value)
         end

         exports.write(
            temporary .. "/run.cmake",
            "execute_process(COMMAND "
               .. table.concat(arguments, " ")
               .. " WORKING_DIRECTORY "
               .. literal(exports.root)
               .. " TIMEOUT "
               .. tostring(limit)
               .. " OUTPUT_FILE "
               .. literal(log)
               .. " ERROR_FILE "
               .. literal(log)
               .. " RESULT_VARIABLE result)\nfile(WRITE "
               .. literal(status_file)
               .. ' "${result}")\n'
         )
         assert(
            exports.platform.command_succeeded({
               "cmake",
               "-P",
               temporary .. "/run.cmake",
            }),
            "command supervisor failed"
         )

         return exports.read(status_file)
      end)

      exports.platform.remove_temporary_directory(temporary)

      --- Distinguish numeric exits from supervisor errors and deadlines.
      -- @return any, any, boolean|nil|string: distinguish numeric exits from
      -- supervisor errors and deadlines.
      local function build_io_classifyResult()
         local detail = ok and result or tostring(result)
         local code = ok and tonumber(detail) or nil
         local state = code and "EXITED"
            or (
               detail:lower():find("timeout", 1, true) and "TIMEOUT" or "ERROR"
            )

         return detail, code, state
      end

      local detail, code, state = build_io_classifyResult()

      local retained = io.open(log, "rb")

      if retained then
         retained:close()
      else
         exports.write(log, detail .. "\n")
      end

      report.commands[#report.commands + 1] = {
         label = label,
         argv = artifact_io.array(argv),
         exit_code = code,
         state = state,
         termination = detail,
         timeout_seconds = limit,
         seconds = os.time() - started,
         log = log,
         sha256 = exports.digest(log),
      }

      return code == 0, log
   end

   exports.run = BUILD_IO_run

   --- Inventory and hash the declared build inputs in deterministic path order.
   -- @return any: inventory and hash the declared build inputs in deterministic
   -- path order.
   local function BUILD_IO_inputs()
      local inputs, seen = artifact_io.array(), {}
      local git = dofile("scripts/lib/git.lua").new(exports.platform, ".")
      local scopes = {
         "core",
         "packaging",
         "cmake",
         "tools/build",
         "scripts",
         "tests/fixtures/compatibility",
      }

      for _, path in
         ipairs(assert(git.working_files(), "cannot list build inputs"))
      do
         local selected = path == "CMakeLists.txt"
            or path == "CMakePresets.json"
            or path == "LICENSE"

         for _, scope in ipairs(scopes) do
            if path:sub(1, #scope + 1) == scope .. "/" then
               selected = true
            end
         end

         if selected and not seen[path] then
            inputs[#inputs + 1] = { path = path, sha256 = exports.digest(path) }
            seen[path] = true
         end
      end

      table.sort(
         inputs,
         --- Order input records by repository-relative path.
         -- @param a table: a supplied to this operation.
         -- @param b table: b supplied to this operation.
         -- @return boolean: order input records by repository-relative path.
         function(a, b)
            return a.path < b.path
         end
      )

      return inputs
   end

   exports.inputs = BUILD_IO_inputs

   --- Resolve an installed tool and return its normalized path and content
   -- digest.
   -- @param name string: entry or operation name to resolve.
   -- @return table: an installed tool and return its normalized path and
   -- content digest.
   local function BUILD_IO_tool(name)
      local lookup = exports.platform.is_windows and { "where.exe", name }
         or { "which", name }
      local path = assert(
         exports.lines(artifact_io.output(lookup))[1],
         "missing tool " .. name
      )

      return { path = path:gsub("\\", "/"), sha256 = exports.digest(path) }
   end

   exports.tool = BUILD_IO_tool

   return exports
end

return scripts_build_lib_io_loadModule()

-- EOF


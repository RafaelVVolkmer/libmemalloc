-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Bounded files, native processes and inert JSON for the local pilot.
-- Part of local process planning and evidence assessment.

-- JSON metadata stays bounded; byte streams use their own execution limit.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_process_lib_io_loadModule()
   local IO_HEX_BASE = 16
   local IO_GITLINK_MODE = 160000

   local IO_MAX_METADATA_BYTES = 4 * 1024 * 1024
   local IO_INTEGER_EXACT_LIMIT = 2 ^ 53
   local IO_SHA256_HEX_LENGTH = 64

   -- POSIX modes: owner-only directory access (0700) and file access (0600).
   local IO_PRIVATE_DIRECTORY_MODE = 448
   local IO_PRIVATE_FILE_MODE = 384

   local uv = require("luv")
   local execution = dofile("scripts/process/lib/exec.lua")
   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local exports = {
      uv = uv,
      exec = execution,
      array = artifact_io.array,
      json = artifact_io.json,
   }

   --- Capture a native process result and reject execution or output failures.
   -- @param argv table: dense executable-and-arguments sequence; values remain
   -- literal.
   -- @param input any: input selected by the caller.
   -- @return any: a native process result and reject execution or output
   -- failures.
   local function PROCESS_IO_capture(argv, input)
      local result = execution.run(argv, { stdin = input })

      assert(
         result.state == "PASS",
         argv[1] .. ": " .. result.state .. ": " .. result.stderr
      )

      return result.stdout
   end

   exports.capture = PROCESS_IO_capture

   --- Read bounded evidence bytes from a regular file owned by the current
   -- attempt.
   -- @param path string: filesystem path selected by the caller.
   -- @return any: bounded evidence bytes from a regular file owned by the
   -- current attempt.
   local function PROCESS_IO_read(path)
      local stat = assert(uv.fs_lstat(path), "missing file: " .. path)

      assert(
         stat.type == "file" and stat.size <= IO_MAX_METADATA_BYTES,
         "non-regular or oversized input: " .. path
      )

      return artifact_io.read(path)
   end

   exports.read = PROCESS_IO_read

   --- Compute the SHA-256 identity of supplied bytes through the native process
   -- adapter.
   -- @param bytes string: byte sequence supplied by the caller.
   -- @return any: the SHA-256 identity of supplied bytes through the native
   -- process adapter.
   local function PROCESS_IO_digestBytes(bytes)
      local digest =
         exports.capture({ "sha256sum" }, bytes):match("^([a-f0-9]+)")

      assert(digest and #digest == IO_SHA256_HEX_LENGTH, "invalid digest")

      return digest
   end

   exports.digest_bytes = PROCESS_IO_digestBytes

   --- Compute the full SHA-256 identity of an evidence file.
   -- @param path string: filesystem path selected by the caller.
   -- @return any: the full SHA-256 identity of an evidence file.
   local function PROCESS_IO_digest(path)
      local stat = assert(uv.fs_lstat(path), "missing digest input: " .. path)

      assert(stat.type == "file", "digest input is not a regular file")

      local digest =
         exports.capture({ "sha256sum", "--", path }):match("^([a-f0-9]+)")

      assert(digest and #digest == IO_SHA256_HEX_LENGTH, "invalid digest")

      return digest
   end

   exports.digest = PROCESS_IO_digest

   -- jq validates JSON and emits typed, URI-escaped records. No source text is
   -- compiled as Lua, and each object key retains its string/array-index kind.
   local flatten = [=[
def walk($p):
  if type == "object" then ["object",$p,""] ,
    (to_entries[] | . as $e | $e.value | walk($p + [["s",$e.key]]))
  elif type == "array" then ["array",$p,""] ,
    (to_entries[] | . as $e | $e.value |
      walk($p + [["i",($e.key + 1 | tostring)]]))
  else [type,$p,tostring] end;
walk([]) |
  [.[0], (.[1] | map(.[0]+":"+(.[1]|@uri)) | join("/")), (.[2]|@uri)] | @tsv
]=]

   --- Decode the accepted JSON subset and reject malformed or trailing input.
   -- @param bytes string: byte sequence supplied by the caller.
   -- @return nil: the accepted JSON subset and reject malformed or trailing
   -- input.
   local function PROCESS_IO_decode(bytes)
      assert(#bytes <= IO_MAX_METADATA_BYTES, "JSON exceeds input limit")

      local rows = exports.capture({ "jq", "-r", flatten }, bytes)
      local root, paths, roots = nil, {}, 0

      --- Decode JSON string escapes after the parser validates the token shape.
      -- @param value any: value supplied to this operation.
      -- @return any: jSON string escapes after the parser validates the token
      -- shape.
      local function process_io_unescape(value)
         return (
            value:gsub(
               "%%(%x%x)",
               --- Decode one hexadecimal byte from a validated JSON escape.
               -- @param pair string: captured hexadecimal byte pair.
               -- @return any: one hexadecimal byte from a validated JSON
               -- escape.
               function(pair)
                  return string.char(tonumber(pair, IO_HEX_BASE))
               end
            )
         )
      end

      --- Decode one inert transport row into the validated record tree.
      -- @param line string: source line to inspect.
      -- @return nil: no values.
      local function process_io_decodeRow(line)
         local kind, path, raw = line:match("^([^\t]+)\t([^\t]*)\t(.*)$")

         assert(kind, "invalid JSON transport")

         local value

         if kind == "object" then
            value = {}
         elseif kind == "array" then
            value = artifact_io.array()
         elseif kind == "string" then
            value = process_io_unescape(raw)
            assert(
               not value:find("[\128-\255]"),
               "pilot metadata requires ASCII strings"
            )
         elseif kind == "number" then
            value = assert(tonumber(process_io_unescape(raw)))
            assert(
               value % 1 == 0 and math.abs(value) < IO_INTEGER_EXACT_LIMIT,
               "unsupported JSON number"
            )
         elseif kind == "boolean" then
            value = raw == "true"
         else
            error("null or unsupported JSON value")
         end

         if path == "" then
            roots = roots + 1
            assert(roots == 1, "multiple JSON documents")

            root = value
         else
            local parent, key = path:match("^(.*)/([^/]+)$")

            if not key then
               parent, key = "", path
            end

            local key_kind, encoded = key:match("^([si]):(.*)$")

            assert(key_kind, "invalid JSON key transport")

            local decoded = process_io_unescape(encoded)

            assert(
               not decoded:find("[\128-\255]"),
               "pilot metadata requires ASCII keys"
            )
            if key_kind == "i" then
               decoded = assert(tonumber(decoded))
            end

            local target = assert(paths[parent], "missing JSON parent")

            assert(target[decoded] == nil, "duplicate JSON transport key")

            target[decoded] = value
         end

         paths[path] = value
      end

      for line in rows:gmatch("[^\n]+") do
         process_io_decodeRow(line)
      end

      assert(roots == 1, "empty JSON input")

      assert(root ~= nil, "missing decoded JSON value")

      return root
   end

   exports.decode = PROCESS_IO_decode

   --- Read and decode an evidence record from its validated path.
   -- @param path string: filesystem path selected by the caller.
   -- @return any: and decode an evidence record from its validated path.
   local function PROCESS_IO_load(path)
      return exports.decode(exports.read(path))
   end

   exports.load = PROCESS_IO_load

   --- Restrict writes to fresh regular cache paths and reject symlink parents.
   -- @param path string: filesystem path selected by the caller.
   -- @return any: restrict writes to fresh regular cache paths and reject
   -- symlink parents.
   local function PROCESS_IO_outputPath(path)
      artifact_io.safe_path(path)
      assert(
         path == ".cache" or path:match("^%.cache/"),
         "outputs must remain in .cache"
      )

      local current = ""

      for part in path:gmatch("[^/]+") do
         current = current == "" and part or current .. "/" .. part

         local stat = uv.fs_lstat(current)

         if stat then
            assert(stat.type ~= "link", "symlink output path")
         end
      end

      return path
   end

   exports.output_path = PROCESS_IO_outputPath

   --- Create a private evidence directory, optionally rejecting an existing
   -- destination.
   -- @param path string: filesystem path selected by the caller.
   -- @param exclusive any: exclusive supplied to this operation.
   -- @return nil: no values.
   local function PROCESS_IO_mkdir(path, exclusive)
      exports.output_path(path)

      local parent = path:match("^(.*)/[^/]+$")

      if parent and not uv.fs_lstat(parent) then
         exports.mkdir(parent)
      end

      local stat = uv.fs_lstat(path)

      if stat then
         assert(
            not exclusive and stat.type == "directory",
            "output already exists"
         )
      else
         assert(uv.fs_mkdir(path, IO_PRIVATE_DIRECTORY_MODE))
      end
   end

   exports.mkdir = PROCESS_IO_mkdir

   --- Write evidence bytes with explicit ownership of the file descriptor and
   -- cleanup.
   -- @param path string: filesystem path selected by the caller.
   -- @param bytes string: byte sequence supplied by the caller.
   -- @return nil: no values.
   local function PROCESS_IO_write(path, bytes)
      exports.output_path(path)

      exports.mkdir(assert(path:match("^(.*)/[^/]+$")))

      local fd = assert(
         uv.fs_open(path, "wx", IO_PRIVATE_FILE_MODE),
         "output already exists: " .. path
      )
      local offset = 0

      while offset < #bytes do
         local written = assert(uv.fs_write(fd, bytes:sub(offset + 1), offset))

         assert(written > 0, "short write")

         offset = offset + written
      end

      assert(uv.fs_close(fd))
   end

   exports.write = PROCESS_IO_write

   --- Serialize one evidence record using the process JSON contract.
   -- @param path string: filesystem path selected by the caller.
   -- @param value any: input value; validation belongs to this operation’s
   -- contract.
   -- @return nil: no values.
   local function PROCESS_IO_document(path, value)
      exports.write(path, artifact_io.pretty_json(value))
   end

   exports.document = PROCESS_IO_document

   --- Include tracked, deleted and non-ignored untracked inputs, in stable
   -- order.
   -- @return table: include tracked, deleted and non-ignored untracked inputs,
   -- in stable order.
   local function PROCESS_IO_subject()
      local names, seen, gitlinks = {}, {}, {}

      --- Collect tracked submodule identities and nested source inventories.
      -- @param directory string: working or output directory selected by the
      -- caller.
      -- @param prefix any: prefix supplied to this operation.
      -- @return nil: no values.
      local function process_io_collect(directory, prefix)
         local entries = exports.capture({
            "git",
            "-C",
            directory,
            "ls-files",
            "--stage",
            "-z",
         })

         for entry in entries:gmatch("[^%z]+") do
            local mode, revision, stage, relative =
               entry:match("^(%d+) (%x+) (%d+)\t(.+)$")

            assert(stage == "0", "unmerged source input")
            if mode == "160000" then
               artifact_io.safe_path(relative)

               local path = prefix .. relative
               local stat =
                  assert(uv.fs_lstat(path), "missing submodule: " .. path)

               assert(stat.type == "directory", "invalid submodule: " .. path)
               assert(
                  uv.fs_lstat(path .. "/.git"),
                  "uninitialized submodule: " .. path
               )

               local head = exports
                  .capture({
                     "git",
                     "-C",
                     path,
                     "rev-parse",
                     "HEAD",
                  })
                  :gsub("%s+$", "")

               gitlinks[path] = exports.digest_bytes(revision .. "\n" .. head)
               process_io_collect(path, path .. "/")
            end
         end

         local listed = exports.capture({
            "git",
            "-C",
            directory,
            "ls-files",
            "-z",
            "--cached",
            "--others",
            "--exclude-standard",
         })

         for relative in listed:gmatch("[^%z]+") do
            local path = prefix .. relative

            artifact_io.safe_path(path)
            if not seen[path] then
               names[#names + 1] = path
               seen[path] = true
            end
         end
      end

      process_io_collect(".", "")

      table.sort(names)

      local inputs = artifact_io.array()

      --- Bind one applicable source to the process subject identity.
      -- @param path string: filesystem path selected by the caller.
      -- @return nil: no values.
      local function process_io_hashSource(path)
         --- Reject unsupported source types while accepting recorded deletions.
         -- @return any: reject unsupported source types while accepting
         -- recorded deletions.
         local function process_io_inspectSource()
            local stat, _, code = uv.fs_lstat(path)

            assert(stat or code == "ENOENT", "cannot inspect source: " .. path)
            assert(
               not stat or stat.type == "file" or gitlinks[path],
               "unsupported source input: " .. path
            )

            return stat
         end

         local stat = process_io_inspectSource()

         inputs[#inputs + 1] = {
            path = path,
            sha256 = gitlinks[path]
               or (stat and exports.digest(path) or "DELETED"),
            mode = gitlinks[path] and IO_GITLINK_MODE
               or (stat and stat.mode or 0),
         }
      end

      for _, path in ipairs(names) do
         process_io_hashSource(path)
      end

      local status = exports.capture({
         "git",
         "status",
         "--porcelain=v1",
         "-z",
         "--untracked-files=all",
      })

      return {
         revision = exports
            .capture({ "git", "rev-parse", "HEAD" })
            :gsub("%s+$", ""),
         source_sha256 = exports.digest_bytes(artifact_io.json(inputs)),
         dirty = status ~= "",
         inputs = inputs,
      }
   end

   exports.subject = PROCESS_IO_subject

   return exports
end

return scripts_process_lib_io_loadModule()

-- EOF


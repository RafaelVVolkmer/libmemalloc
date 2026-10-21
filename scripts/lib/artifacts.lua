-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Linux release primitives. Commands receive quoted argv, never shell input.
-- Part of shared host, path and artifact primitives.

--- Construct this module within its own initialization scope.
-- @return table: public operations constructed by this module.
local function scripts_lib_artifacts_loadModule()
   local ARTIFACTS_SHA256_HEX_LENGTH = 64
   local ARTIFACTS_INTEGER_EXACT_LIMIT = 2 ^ 53

   local exports = {}

   exports.platform = dofile("scripts/lib/platform.lua")

   local array_mt = {}

   --- Mark a table as a JSON array, including an empty array.
   -- @param values table|nil: ordered values owned by the caller.
   -- @return table: the same table with the array marker.
   local function ARTIFACTS_array(values)
      return setmetatable(values or {}, array_mt)
   end

   exports.array = ARTIFACTS_array

   --- Read a trusted local input and reject read or close failures.
   -- @param path string: input filename; callers enforce size and path policy.
   -- @return string: complete input bytes.
   local function ARTIFACTS_read(path)
      local handle, message = io.open(path, "rb")

      assert(handle, message or ("cannot read " .. path))

      local data, read_error = handle:read("*a")

      if not data then
         handle:close()

         error(read_error)
      end

      local closed, close_error = handle:close()

      assert(closed, close_error)

      return data
   end

   exports.read = ARTIFACTS_read

   --- Execute quoted arguments; propagate command failure to the owner.
   -- @param argv table: executable followed by its arguments.
   -- @return nil: no values.
   local function ARTIFACTS_run(argv)
      local succeeded = exports.platform.command_succeeded(argv)

      assert(succeeded, "command failed: " .. argv[1])
   end

   exports.run = ARTIFACTS_run

   --- Capture stdout from a successful command without terminal newlines.
   -- @param argv table: executable followed by its arguments.
   -- @return string: command output, with trailing CR/LF bytes removed.
   local function ARTIFACTS_output(argv)
      local output = exports.platform.command_output(argv)

      assert(output, "command failed: " .. argv[1])

      return (output:gsub("[\r\n]+$", ""))
   end

   exports.output = ARTIFACTS_output

   --- Create a directory and any missing parents.
   -- @param path string: destination controlled by the caller's path policy.
   -- @return nil: no values.
   local function ARTIFACTS_mkdir(path)
      exports.run({ "mkdir", "-p", "--", path })
   end

   exports.mkdir = ARTIFACTS_mkdir

   --- Write local staging bytes; reject write and close failures.
   -- @param path string: destination with a parent directory.
   -- @param data string: bytes to write, replacing an existing staging file.
   -- @return nil: no values.
   local function ARTIFACTS_write(path, data)
      exports.mkdir(assert(path:match("^(.*)/[^/]+$")))

      local handle, message = io.open(path, "wb")

      assert(handle, message)

      local written, write_error = handle:write(data)

      if not written then
         handle:close()

         error(write_error)
      end

      local closed, close_error = handle:close()

      assert(closed, close_error)
   end

   exports.write = ARTIFACTS_write

   --- Test whether a local path exists without following a shell expression.
   -- @param path string: filename to inspect.
   -- @return boolean: true when the host reports an existing path.
   local function ARTIFACTS_exists(path)
      return exports.platform.command_succeeded_silent({ "test", "-e", path })
   end

   exports.exists = ARTIFACTS_exists

   --- Reject absolute, traversal, empty, and unsupported path components.
   -- @param path string: proposed release-relative ASCII path.
   -- @return string: unchanged validated path.
   local function ARTIFACTS_safePath(path)
      assert(type(path) == "string" and #path > 0, "empty path")
      assert(path:match("^[%w_./+%-]+$"), "unsafe path: " .. path)
      assert(path:sub(1, 1) ~= "/" and path:sub(-1) ~= "/", "absolute path")
      assert(not path:find("//", 1, true), "empty path segment")

      for part in path:gmatch("[^/]+") do
         assert(part ~= "." and part ~= "..", "path traversal")
      end

      return path
   end

   exports.safe_path = ARTIFACTS_safePath

   --- Compute a full SHA-256 digest with the selected host tool.
   -- @param path string: regular file selected by the caller.
   -- @return string: lowercase hexadecimal digest.
   local function ARTIFACTS_digest(path)
      local value =
         exports.output({ "sha256sum", "--", path }):match("^([a-f0-9]+)")

      assert(value and #value == ARTIFACTS_SHA256_HEX_LENGTH, "invalid SHA-256")

      return value
   end

   exports.digest = ARTIFACTS_digest

   --- Inventory regular files and reject symlinks or special files.
   -- @param root string: existing tree to inspect.
   -- @return table: sorted paths relative to the root.
   local function ARTIFACTS_files(root)
      assert(exports.exists(root), "missing directory: " .. root)

      local invalid = exports.output({
         "find",
         root,
         "!",
         "-type",
         "d",
         "!",
         "-type",
         "f",
         "-print",
      })

      assert(invalid == "", "release tree contains links or special files")

      local output = exports.output({ "find", root, "-type", "f", "-print0" })
      local paths = {}

      for path in output:gmatch("([^%z]+)%z") do
         paths[#paths + 1] = exports.safe_path(path:sub(#root + 2))
      end

      table.sort(paths)

      return paths
   end

   exports.files = ARTIFACTS_files

   --- Encode a JSON string with the required escapes for control characters.
   -- @param value any: value supplied to this operation.
   -- @param allow_utf8 boolean|nil: whether non-ASCII text is permitted in the
   -- output.
   -- @return string: a JSON string with the required escapes for control
   -- characters.
   local function artifacts_quote(value, allow_utf8)
      assert(
         (allow_utf8 and utf8.len(value) ~= nil)
            or (not allow_utf8 and not value:find("[^%z\1-\127]")),
         "canonical profile requires ASCII strings"
      )

      return '"'
         .. value:gsub(
            '[%z\1-\31\\"]',
            --- Escape one JSON control character without modifying ordinary
            -- text.
            -- @param character string: captured character or byte sequence.
            -- @return any: escape one JSON control character without modifying
            -- ordinary text.
            function(character)
               local escapes = {
                  ['"'] = '\\"',
                  ["\\"] = "\\\\",
                  ["\n"] = "\\n",
                  ["\r"] = "\\r",
                  ["\t"] = "\\t",
                  ["\b"] = "\\b",
                  ["\f"] = "\\f",
               }

               return escapes[character]
                  or string.format("\\u%04x", character:byte())
            end
         )
         .. '"'
   end

   --- Encode a safe integer with canonical zero and no fractional precision.
   -- @param value number: JSON number; nonintegers and unsafe ranges fail.
   -- @return string: decimal integer representation.
   local function artifacts_encodeInteger(value)
      assert(
         math.floor(value) == value
            and math.abs(value) < ARTIFACTS_INTEGER_EXACT_LIMIT,
         "unsafe JSON number"
      )

      return string.format("%.0f", value == 0 and 0 or value)
   end

   --- JCS-compatible restricted profile: ASCII keys/strings, safe integers
   -- only.
   -- @param value any: value supplied to this operation.
   -- @param allow_utf8 boolean|nil: whether non-ASCII text is permitted in the
   -- output.
   -- @return any: jCS-compatible restricted profile: ASCII keys/strings, safe
   -- integers only.
   local function ARTIFACTS_json(value, allow_utf8)
      local kind = type(value)

      if kind == "string" then
         return artifacts_quote(value, allow_utf8)
      elseif kind == "boolean" then
         return tostring(value)
      elseif kind == "number" then
         return artifacts_encodeInteger(value)
      end

      assert(kind == "table", "unsupported JSON type")

      local fields = {}

      if getmetatable(value) == array_mt then
         for _, element in ipairs(value) do
            fields[#fields + 1] = exports.json(element, allow_utf8)
         end

         return "[" .. table.concat(fields, ",") .. "]"
      end

      local keys = {}

      for key in pairs(value) do
         assert(type(key) == "string", "object keys must be strings")

         keys[#keys + 1] = key
      end

      table.sort(keys)

      for _, key in ipairs(keys) do
         fields[#fields + 1] = artifacts_quote(key, allow_utf8)
            .. ":"
            .. exports.json(value[key], allow_utf8)
      end

      return "{" .. table.concat(fields, ",") .. "}"
   end

   exports.json = ARTIFACTS_json

   --- Encode diagnostic text as UTF-8 JSON without claiming canonical identity.
   -- @param value any: input value; validation belongs to this operation’s
   -- contract.
   -- @return any: diagnostic text as UTF-8 JSON without claiming canonical
   -- identity.
   local function ARTIFACTS_textJson(value)
      return exports.json(value, true)
   end

   exports.text_json = ARTIFACTS_textJson

   --- Encode readable JSON with sorted keys, two-space indentation, and LF.
   -- @param value table: Metadata in the restricted JSON profile.
   -- @return string: Deterministic JSON text including its final newline.
   local function ARTIFACTS_prettyJson(value)
      local compact = exports.json(value)
      local output = {}
      local depth = 0
      local quoted = false
      local escaped = false

      --- Format one JSON byte while tracking strings and indentation.
      -- @param index number: one-based position in the current sequence.
      -- @return nil: no values.
      local function artifacts_formatJsonByte(index)
         local character = compact:sub(index, index)

         if quoted then
            output[#output + 1] = character

            --- Track escapes and closing quotes inside a JSON string.
            -- @return nil: no values.
            local function artifacts_trackJsonEscape()
               if escaped then
                  escaped = false
               elseif character == "\\" then
                  escaped = true
               elseif character == '"' then
                  quoted = false
               end
            end

            artifacts_trackJsonEscape()
         elseif character == '"' then
            quoted = true
            output[#output + 1] = character
         elseif character == "{" or character == "[" then
            depth = depth + 1
            output[#output + 1] = character

            --- Indent a nonempty JSON container after its opening delimiter.
            -- @return nil: no values.
            local function artifacts_indentOpenedContainer()
               local following = compact:sub(index + 1, index + 1)

               if following ~= "}" and following ~= "]" then
                  output[#output + 1] = "\n" .. string.rep("  ", depth)
               end
            end

            artifacts_indentOpenedContainer()
         elseif character == "}" or character == "]" then
            depth = depth - 1

            --- Indent a nonempty JSON container before its closing delimiter.
            -- @return nil: no values.
            local function artifacts_indentClosedContainer()
               local previous = compact:sub(index - 1, index - 1)

               if previous ~= "{" and previous ~= "[" then
                  output[#output + 1] = "\n" .. string.rep("  ", depth)
               end
            end

            artifacts_indentClosedContainer()

            output[#output + 1] = character
         elseif character == "," then
            output[#output + 1] = ",\n" .. string.rep("  ", depth)
         elseif character == ":" then
            output[#output + 1] = ": "
         else
            output[#output + 1] = character
         end
      end

      for index = 1, #compact do
         artifacts_formatJsonByte(index)
      end

      return table.concat(output) .. "\n"
   end

   exports.pretty_json = ARTIFACTS_prettyJson

   --- Write a formatted JSON artifact with its terminal newline.
   -- @param path string: filesystem path selected by the caller.
   -- @param value any: input value; validation belongs to this operation’s
   -- contract.
   -- @return nil: no values.
   local function ARTIFACTS_document(path, value)
      exports.write(path, exports.pretty_json(value))
   end

   exports.document = ARTIFACTS_document

   --- Format a newly generated third-party JSON envelope before indexing it.
   -- Signed payload strings remain opaque; this must not rewrite signed files.
   -- @param path string: filesystem path selected by the caller.
   -- @return nil: no values.
   local function ARTIFACTS_formatJson(path)
      local formatted =
         exports.output({ "jq", "--sort-keys", "--indent", "2", ".", path })

      exports.write(path, formatted .. "\n")
   end

   exports.format_json = ARTIFACTS_formatJson

   --- Resolve new readable manifests or immutable legacy canonical manifests.
   -- @param root string: root directory for this operation.
   -- @return boolean|nil|string: new readable manifests or immutable legacy
   -- canonical manifests.
   local function ARTIFACTS_inputManifest(root)
      local readable = root .. "/identity/build-inputs.json"
      local legacy = root .. "/identity/build-inputs.jcs.json"

      assert(
         not (exports.exists(readable) and exports.exists(legacy)),
         "ambiguous input manifests"
      )

      return exports.exists(readable) and readable or legacy
   end

   exports.input_manifest = ARTIFACTS_inputManifest

   --- Evaluate a jq expression and reject a failed or missing result.
   -- @param path string: filesystem path selected by the caller.
   -- @param expression any: expression supplied to this operation.
   -- @return any: evaluate a jq expression and reject a failed or missing
   -- result.
   local function ARTIFACTS_query(path, expression)
      return exports.output({ "jq", "-er", expression, path })
   end

   exports.query = ARTIFACTS_query

   --- Bind a release-relative path to its size and full content digest.
   -- @param root string: root directory for this operation.
   -- @param path string: filesystem path selected by the caller.
   -- @return table: bind a release-relative path to its size and full content
   -- digest.
   local function ARTIFACTS_record(root, path)
      exports.safe_path(path)

      local full = root .. "/" .. path

      return {
         path = path,
         sha256 = exports.digest(full),
         size = tonumber(exports.output({ "stat", "-c", "%s", "--", full })),
      }
   end

   exports.record = ARTIFACTS_record

   --- Parse supported long options; reject unknown, duplicate or malformed
   -- arguments.
   -- @param arguments table: ordered arguments for the selected operation.
   -- @param allowed table: allowed supplied to this operation.
   -- @return table: supported long options; reject unknown, duplicate or
   -- malformed arguments.
   local function ARTIFACTS_options(arguments, allowed)
      local options = {}

      for _, argument in ipairs(arguments) do
         local key, value = argument:match("^%-%-([%w-]+)=(.+)$")

         if not key then
            key = argument:match("^%-%-([%w-]+)$")
            value = true
         end

         assert(
            key and allowed[key] and options[key] == nil,
            "invalid or duplicate option: " .. argument
         )

         options[key] = value
      end

      return options
   end

   exports.options = ARTIFACTS_options

   --- Validate the release version against the supported semantic-version
   -- grammar.
   -- @param version any: tool or artifact version identity.
   -- @return any: validate the release version against the supported
   -- semantic-version grammar.
   local function ARTIFACTS_semver(version)
      local version_pattern = "^%d+%.%d+%.%d+[%w.+%-]*$"

      assert(
         type(version) == "string" and version:match(version_pattern),
         "invalid version"
      )

      exports.run({
         "jq",
         "-en",
         "--arg",
         "v",
         version,
         (
            '$v | test("^(0|[1-9][0-9]*)[.](0|[1-9][0-9]*)[.'
            .. "](0|[1-9][0-9]*)(-([0-9A-Za-z-]+)([."
            .. "][0-9A-Za-z-]+)*)?([+][0-9A-Za-z-]+([."
            .. '][0-9A-Za-z-]+)*)?$")'
         ),
      })

      return version
   end

   exports.semver = ARTIFACTS_semver

   --- Write the release file inventory from the current immutable artifact
   -- tree.
   -- @param root string: root directory for this operation.
   -- @return nil: no values.
   local function ARTIFACTS_index(root)
      local entries = exports.array()

      for _, path in ipairs(exports.files(root)) do
         if
            path ~= "integrity/release-index.json"
            and path ~= "signatures/release-index.sigstore.json"
         then
            entries[#entries + 1] = exports.record(root, path)
         end
      end

      exports.document(
         root .. "/integrity/release-index.json",
         { schema = 1, files = entries }
      )
   end

   exports.index = ARTIFACTS_index

   --- Verify the file set before using names or commands from release metadata.
   -- @param root string: root directory for this operation.
   -- @return boolean: verify the file set before using names or commands from
   -- release metadata.
   local function ARTIFACTS_verify(root)
      local index = root .. "/integrity/release-index.json"
      local rows = exports.query(
         index,
         (
            '.schema == 1 and (.files | type == "array" and '
            .. 'length > 0 and all(.[]; (.path | type == "string")'
            .. ' and (.sha256 | test("^[a-f0-9]{64}$")) and (.'
            .. 'size | type == "number")))'
         )
      )

      assert(rows == "true", "invalid integrity index")

      rows = exports.query(
         index,
         ".files[] | [.path, .sha256, (.size | tostring)] | @tsv"
      )

      local expected = {}

      for line in rows:gmatch("[^\n]+") do
         local path, digest, size = line:match("^([^\t]+)\t([a-f0-9]+)\t(%d+)$")

         assert(path and digest and size, "invalid index entry")

         exports.safe_path(path)
         assert(not expected[path], "duplicate index path")
         assert(
            path ~= "integrity/release-index.json"
               and path ~= "signatures/release-index.sigstore.json",
            "circular index"
         )

         expected[path] = { digest = digest, size = tonumber(size) }
      end

      -- Inspect the entire tree for links before reading any indexed payload.
      local actual = exports.files(root)

      for _, path in ipairs(actual) do
         if
            path ~= "integrity/release-index.json"
            and path ~= "signatures/release-index.sigstore.json"
         then
            local item = assert(expected[path], "unexpected file: " .. path)
            local record = exports.record(root, path)

            assert(
               record.sha256 == item.digest and record.size == item.size,
               "integrity mismatch: " .. path
            )

            expected[path] = nil
         end
      end

      assert(next(expected) == nil, "missing indexed file")

      local manifest = exports.input_manifest(root)

      assert(
         exports.digest(manifest)
            == exports.query(root .. "/identity/build-id.json", ".sha256"),
         "input identity mismatch"
      )

      return true
   end

   exports.verify = ARTIFACTS_verify

   return exports
end

return scripts_lib_artifacts_loadModule()

-- EOF


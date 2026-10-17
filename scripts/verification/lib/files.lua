-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- File operations shared by the proof checks; run from the repository root.
-- @return table: deterministic file inventory and byte-oriented operations.
local function PROOF_FILES_loadModule()
   local exports = {}

   local uv = require("luv")
   local maximum = 16 * 1024 * 1024

   --- Read only the checked regular-file descriptor, with a fixed allocation cap.
   -- @param fd number: open nonblocking descriptor.
   -- @param before table: file metadata checked before opening.
   -- @return string: complete bounded file contents.
   local function readDescriptor(fd, before)
      local opened = assert(uv.fs_fstat(fd))
      assert(
         opened.type == "file"
            and opened.dev == before.dev
            and opened.ino == before.ino
            and opened.size == before.size,
         "file changed while opening"
      )
      local contents = assert(uv.fs_read(fd, before.size + 1, 0))
      local after = assert(uv.fs_fstat(fd))
      assert(
         #contents == before.size and after.size == before.size,
         "file changed or incomplete read"
      )
      return contents
   end

   --- Read a bounded regular file without following a final symbolic link.
   -- @param path string: repository-relative path.
   -- @param limit number|nil: byte cap, default 4 MiB and at most 16 MiB.
   -- @return string: file bytes.
   function exports.read(path, limit)
      limit = limit or 4 * 1024 * 1024
      assert(
         type(limit) == "number"
            and limit >= 0
            and limit <= maximum
            and limit % 1 == 0,
         "invalid proof file limit"
      )
      local before = assert(uv.fs_lstat(path), "missing proof file: " .. path)
      assert(before.type == "file", "non-regular proof file: " .. path)
      assert(before.size <= limit, "oversized proof file: " .. path)
      local flags = uv.constants.O_RDONLY + (uv.constants.O_NONBLOCK or 0)
      -- Linux O_NOFOLLOW is not exported by every supported luv build.
      if uv.os_uname().sysname == "Linux" then
         flags = flags + 0x20000
      end
      local fd = assert(uv.fs_open(path, flags, 0))
      local ok, contents = pcall(readDescriptor, fd, before)
      local closed, failure = uv.fs_close(fd)
      assert(ok, contents)
      assert(closed, failure)
      return contents
   end

   --- Finish and flush all bytes before publishing a replacement receipt.
   -- @param fd number: private temporary regular-file descriptor.
   -- @param contents string: complete receipt bytes.
   -- @return nil: no values.
   local function writeReceipt(fd, contents)
      local offset = 0
      while offset < #contents do
         local count = assert(uv.fs_write(fd, contents:sub(offset + 1), offset))
         assert(count > 0, "incomplete receipt write")
         offset = offset + count
      end
      assert(uv.fs_fsync(fd))
   end

   --- Publish a complete receipt by renaming a private file in the same directory.
   -- @param path string: destination path.
   -- @param contents string: bounded receipt bytes.
   -- @param mode number: final owner and access permissions.
   -- @return nil: no values.
   local function publish(path, contents, mode)
      assert(#contents <= maximum, "oversized receipt")
      local fd, temporary = assert(uv.fs_mkstemp(path .. ".XXXXXX"))
      local ok, failure = pcall(writeReceipt, fd, contents)
      if ok then
         ok, failure = uv.fs_fchmod(fd, mode)
      end
      local closed, closeFailure = uv.fs_close(fd)
      if not ok or not closed then
         uv.fs_unlink(temporary)
         error(failure or closeFailure)
      end
      local renamed, renameFailure = uv.fs_rename(temporary, path)
      if not renamed then
         uv.fs_unlink(temporary)
         error(renameFailure)
      end
   end

   --- Atomically replace a receipt without following the destination link.
   -- @param path string: destination path.
   -- @param contents string: bounded receipt bytes.
   -- @return nil: no values.
   function exports.atomic_write(path, contents)
      publish(path, contents, 384)
   end

   --- Write bounded artifacts without opening producer-controlled output nodes.
   -- @param path string: repository-relative path.
   -- @param contents string: exact output bytes.
   -- @return nil: no values.
   function exports.write(path, contents)
      local previous = uv.fs_lstat(path)
      assert(
         not previous or previous.type == "file",
         "non-regular proof output: " .. path
      )
      publish(path, contents, previous and previous.mode % 512 or 384)
   end

   --- Quote a single POSIX shell argument, including embedded apostrophes.
   -- @param value string: uninterpreted argument.
   -- @return string: shell-quoted argument.
   function exports.quote(value)
      return "'" .. value:gsub("'", "'\\''") .. "'"
   end

   --- Include new sources and reject verification-owned C implementations.
   -- @return table: sorted unique source paths, including untracked additions.
   function exports.inventory()
      local pipe = assert(
         io.popen(
            "git ls-files --cached --others --exclude-standard --"
               .. " verification scripts/verification"
               .. " docs/specs/formal-engine.md docs/reference/formal-engine.md"
               .. " docs/assurance/formal-trust.md docs/runbooks/formal-verification.md"
               .. " tests/automation/process/*test.lua"
               .. " scripts/process scripts/lib/platform.lua"
               .. " tools/process tools/toolchain/lock.toml"
               .. " infra/ansible/playbooks/formal-verification.yml"
               .. " infra/ansible/tasks/formal-stage.yml"
               .. " infra/ansible/tasks/formal-evidence.yml",
            "r"
         )
      )
      local seen, paths = {}, {}
      for path in pipe:lines() do
         assert(path:match("^[%w_./%-]+$"), "unsupported path: " .. path)
         assert(
            not (
                  path:match("^verification/")
                  and (path:match("%.[ch]$") or path:match("%.[ch]%.in$"))
               ),
            "C source belongs in core/ or tests/: " .. path
         )
         if not seen[path] then
            seen[path] = true
            paths[#paths + 1] = path
         end
      end
      assert(pipe:close(), "cannot inventory proof sources")
      assert(#paths > 0, "empty proof source inventory")
      table.sort(paths)
      return paths
   end

   return exports
end

return PROOF_FILES_loadModule()

-- EOF


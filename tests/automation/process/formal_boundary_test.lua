-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Exercise bounded artifact I/O and the shared toolchain admission boundary.
-- @return nil: no values.
local function FORMAL_BOUNDARY_TEST_main()
   local env = dofile("scripts/verification/lib/engine_env.lua")
   local files = dofile("scripts/verification/lib/files.lua")
   local toolchain = dofile("scripts/verification/lib/toolchain.lua")
   local id = "boundary-" .. tostring(env.io.uv.hrtime()):gsub("%.0$", "")
   local root = env.root .. "/.cache/verification/" .. id
   assert(env.io.exec.run({
      "mkdir",
      "-p",
      root .. "/.cache/formal",
      root .. "/verification/engine",
   }).state == "PASS", "cannot create fixtures")
   local script = root .. "/files.lua"
   files.write(
      script,
      [[
local files = dofile("scripts/verification/lib/files.lua")
local uv = require("luv")
local exec = dofile("scripts/process/lib/exec.lua")
local root = arg[1]
local regular = root .. "/regular"
files.write(regular, "12345678")
assert(files.read(regular, 8) == "12345678")
assert(not pcall(files.read, regular, 7))
files.write(root .. "/empty", "")
assert(files.read(root .. "/empty", 0) == "")
assert(exec.run({"mkfifo", root .. "/pipe"}).state == "PASS")
assert(not pcall(files.read, root .. "/pipe"))
assert(not pcall(files.write, root .. "/pipe", "blocked write"))
assert(uv.fs_symlink(regular, root .. "/link"))
assert(not pcall(files.read, root .. "/link"))
assert(not pcall(files.write, root .. "/link", "unintended write"))
assert(not pcall(files.read, root))
local fd = assert(uv.fs_open(root .. "/large", "w", 384))
assert(uv.fs_ftruncate(fd, 4 * 1024 * 1024 + 1))
assert(uv.fs_close(fd))
local ok, failure = pcall(files.read, root .. "/large")
assert(not ok and failure:find("oversized proof file", 1, true))
-- Replace the path after lstat to exercise the descriptor check, not only lstat.
local open = uv.fs_open
for _, kind in ipairs({"fifo", "symlink", "regular"}) do
   files.write(root .. "/race", "old")
   local opened
   uv.fs_open = function(path, flags, mode)
      assert(uv.fs_unlink(path))
      if kind == "fifo" then
         assert(exec.run({"mkfifo", path}).state == "PASS")
      elseif kind == "symlink" then
         assert(uv.fs_symlink(regular, path))
      else
         assert(uv.fs_link(regular, path))
      end
      opened = open(path, flags, mode)
      return opened
   end
   local accepted = pcall(files.read, root .. "/race")
   uv.fs_open = open
   assert(not accepted, "path replacement accepted: " .. kind)
   if opened then assert(uv.fs_fstat(opened) == nil, "descriptor leaked") end
   assert(uv.fs_unlink(root .. "/race"))
end
files.atomic_write(root .. "/receipt", "old")
files.atomic_write(root .. "/receipt", "new")
assert(files.read(root .. "/receipt") == "new")
files.atomic_write(root .. "/link", "receipt")
assert(files.read(regular) == "12345678", "receipt write followed a symlink")
assert(files.read(root .. "/link") == "receipt")
assert(not pcall(files.atomic_write, root, "cannot replace a directory"))
print("Bounded reads, FIFO and symlink rejection, path races, descriptor cleanup and atomic receipts passed.")
]]
   )
   local ioResult = env.resources.run(
      { env.io.uv.exepath(), script, root },
      { timeout_ms = 10000, memory_bytes = 64 * 1024 * 1024 }
   )
   files.write(root .. "/files.log", ioResult.stdout .. ioResult.stderr)
   assert(ioResult.state == "PASS", ioResult.stdout .. ioResult.stderr)
   local fake = {}
   for key, value in pairs(env) do
      fake[key] = value
   end
   fake.root = root
   local project = root .. "/.cache/formal/cabal.project"
   local freeze = files.read("verification/engine/cabal.project.freeze")
   files.write(root .. "/verification/engine/cabal.project.freeze", freeze)
   files.write(project, toolchain.project(fake))
   files.write(project .. ".freeze", freeze)
   local responses = {
      ["ghc-version"] = "9.4.7\n",
      ["lean-version"] = "Lean (version 4.35.0, fixture)\n",
      ["cn-source-revision"] = env.cn_source .. "\n",
      ["cn-source-diff"] = "",
      ["liquid-source-revision"] = env.liquid_source .. "\n",
      ["liquid-source-diff"] = "",
   }
   local calls = 0
   --- Supply controlled tool responses while exercising real configuration files.
   -- @param name string: validation step.
   -- @return string: controlled tool output.
   local function response(name)
      calls = calls + 1
      return assert(responses[name], "unexpected admission command")
   end
   --- Require a specific admission rejection and optionally forbid subprocesses.
   -- @param diagnostic string: required error text.
   -- @param beforeCommands boolean|nil: reject before any tool is launched.
   -- @return nil: no values.
   local function rejects(diagnostic, beforeCommands)
      calls = 0
      local ok, failure = pcall(toolchain.validate, fake, response)
      assert(
         not ok and tostring(failure):find(diagnostic, 1, true),
         tostring(failure)
      )
      assert(
         not beforeCommands or calls == 0,
         "configuration drift reached a tool"
      )
   end
   assert(
      toolchain.validate(fake, response).project_sha256,
      "missing configuration identity"
   )
   files.write(project, toolchain.project(fake) .. "packages: /unreviewed\n")
   rejects("Cabal project drift", true)
   files.write(project, toolchain.project(fake))
   files.write(project .. ".freeze", "constraints: base == 0\n")
   rejects("Cabal lock drift", true)
   files.write(project .. ".freeze", freeze)
   files.write(project .. ".local", "flags: -liquid\n")
   rejects("Cabal local override", true)
   assert(env.io.uv.fs_unlink(project .. ".local"))
   for _, case in ipairs({
      { "ghc-version", "9.4.8\n", "unsupported GHC" },
      { "lean-version", "Lean (version 4.36.0)\n", "unsupported Lean" },
      { "cn-source-revision", string.rep("0", 40) .. "\n", "revision differs" },
      {
         "liquid-source-revision",
         string.rep("0", 40) .. "\n",
         "revision differs",
      },
      { "cn-source-diff", "changed", "dependency drift" },
      { "liquid-source-diff", "changed", "dependency drift" },
   }) do
      local name, value, diagnostic = table.unpack(case)
      local original = responses[name]
      responses[name] = value
      rejects(diagnostic)
      responses[name] = original
   end
   for _, key in ipairs({ "cn_sha256", "z3_sha256" }) do
      local original = fake[key]
      fake[key] = string.rep("0", 64)
      rejects("tool digest drift", true)
      fake[key] = original
   end
   local lake = root .. "/lake"
   files.write(lake, "#!/bin/sh\nprintf 'Lean (version 0.0.0)\\n'\n")
   assert(env.io.uv.fs_chmod(lake, 448))
   local result = env.resources.run({
      "env",
      "LMA_LAKE=" .. lake,
      env.io.uv.exepath(),
      "scripts/verification/c.lua",
      "core/mock.c",
      "verification/engine/test/fixtures/scalar.json",
      id,
   }, { timeout_ms = 30000 })
   local report = env.io.decode(
      files.read(".cache/verification/generic/" .. id .. "/report.json")
   )
   assert(
      result.state == "FAIL"
         and report.status == "INFRA_ERROR"
         and report.failed_stage == "toolchain",
      "standalone toolchain admission was bypassed"
   )
   assert(
      report.failure:find("unsupported Lean", 1, true),
      "wrong toolchain rejection"
   )
   for _, step in ipairs(report.steps) do
      assert(
         step.name ~= "engine-build",
         "unadmitted toolchain reached compilation"
      )
   end
   files.write(
      root .. "/report.json",
      env.io.json({
         status = "PASS",
         artifact_io = ioResult.state,
         standalone_rejection = report.status,
      })
   )
   print(
      "Formal boundaries: bounded I/O, atomic receipts, configuration drift, versions, digests and source revisions passed."
   )
end

return FORMAL_BOUNDARY_TEST_main()

-- EOF


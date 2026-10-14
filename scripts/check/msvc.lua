-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Windows native analysis; use the selected SDK without replacing its models.
-- Part of local and CI verification gates.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_check_msvc_main()
   local artifact_io = dofile("scripts/lib/artifacts.lua")
   local platform = artifact_io.platform
   local tools = dofile("scripts/toolchain/lib/lock.lua").load()
   local profile = dofile("tools/analysis/c/profile.lua")
   local directory = ".cache/ci/msvc"

   assert(platform.is_windows, "MSVC campaign requires Windows")
   assert(
      (os.getenv("VCToolsVersion") or ""):find(
         tools.msvc_analyzer.version,
         1,
         true
      ) == 1,
      "MSVC toolset mismatch"
   )
   assert(
      (os.getenv("WindowsSDKVersion") or ""):find(
         tools.windows_sdk.version,
         1,
         true
      ) == 1,
      "SDK mismatch"
   )
   assert(
      platform.command_succeeded({
         "cmd",
         "/c",
         "mkdir",
         (directory:gsub("/", "\\")),
      }),
      "create fresh MSVC output first"
   )

   --- Write a Windows analysis input and close the owned file handle.
   -- @param path string: filesystem path selected by the caller.
   -- @param content string: input bytes to process.
   -- @return nil: no values.
   local function check_msvc_write(path, content)
      local file = assert(io.open(path, "wb"))

      assert(file:write(content))
      assert(file:close())
   end

   --- Compute the full file identity for the Windows analysis report.
   -- @param path string: filesystem path selected by the caller.
   -- @return any: the full file identity for the Windows analysis report.
   local function check_msvc_digest(path)
      local text =
         artifact_io.output({ "certutil", "-hashfile", path, "SHA256" })

      return assert(text:match("\n(%x+)\r?\n"), "missing Windows file digest")
   end

   local report = {
      campaign = "msvc",
      status = "RUNNING",
      profile = "mock-windows-x64",
      toolset = os.getenv("VCToolsVersion"),
      sdk = os.getenv("WindowsSDKVersion"),
      include_paths = os.getenv("INCLUDE"),
      expected = artifact_io.array(profile.sources),
      analyzed = artifact_io.array(),
      commands = artifact_io.array(),
      inputs = artifact_io.array(),
      limitations = artifact_io.array({
         "Windows hosted mock only; no allocator or concurrency claim.",
      }),
   }

   --- Persist the MSVC campaign report before leaving the current phase.
   -- @return nil: no values.
   local function check_msvc_save()
      check_msvc_write(
         directory .. "/report.json",
         artifact_io.pretty_json(report)
      )
   end

   --- Analyze one source with the configured MSVC policy and retain its
   -- diagnostics.
   -- @param source any: source value inspected by this operation.
   -- @param name string: entry or operation name to resolve.
   -- @return any, string, string: analyze one source with the configured MSVC
   -- policy and retain its diagnostics.
   local function check_msvc_scan(source, name)
      local log = directory .. "/" .. name .. ".log"
      local sarif = directory .. "/" .. name .. ".sarif"
      local command = {
         "cl.exe",
         "/nologo",
         "/c",
         "/std:c17",
         "/W4",
         "/WX",
         "/analyze",
         "/analyze:log",
         sarif,
         "/analyze:log:format:sarif",
         "/analyze:sarif:analyzedfiles",
         "/analyze:sarif:configuration",
         "/analyze:log:includesuppressed",
         "/analyze:log:compilerwarnings",
         "/Icore",
         "/Fo" .. directory .. "/" .. name .. ".obj",
         source,
      }

      local success = platform.command_succeeded(
         platform.join_command(command)
            .. " >"
            .. platform.shell_quote(log)
            .. " 2>&1"
      )

      report.commands[#report.commands + 1] = {
         argv = artifact_io.array(command),
         success = success,
         log = log,
         sha256 = check_msvc_digest(log),
      }

      check_msvc_save()

      return success, log, sarif
   end

   local success, message = xpcall(
      --- Run the declared Windows source and diagnostic fixtures under error
      -- capture.
      -- @return nil: no values.
      function()
         local actual = artifact_io
            .output({ "git", "ls-files", "--", "core/*.c" })
            :gsub("\r", "")

         assert(
            actual == table.concat(profile.sources, "\n"),
            "MSVC source inventory changed"
         )

         for _, path in ipairs({
            "core/main.c",
            "core/mock.c",
            "core/mock.h",
            "tools/toolchain/lock.toml",
            "scripts/check/msvc.lua",
            "tools/analysis/c/profile.lua",
         }) do
            report.inputs[#report.inputs + 1] =
               { path = path, sha256 = check_msvc_digest(path) }
         end

         check_msvc_write(
            directory .. "/inputs.json",
            artifact_io.pretty_json({
               files = report.inputs,
               toolset = report.toolset,
               sdk = report.sdk,
               includes = report.include_paths,
            })
         )

         report.cache_identity = check_msvc_digest(directory .. "/inputs.json")

         for _, name in ipairs({ "clean", "null" }) do
            local path = directory .. "/fixture-" .. name .. ".c"

            check_msvc_write(
               path,
               artifact_io.read("tests/fixtures/analysis/" .. name .. ".c.in")
            )

            local accepted, log = check_msvc_scan(path, "fixture-" .. name)

            if name == "clean" then
               assert(accepted, "MSVC clean fixture rejected")
            else
               assert(
                  not accepted and artifact_io.read(log):find("C6011", 1, true),
                  "MSVC null checker lost"
               )
            end
         end

         for index, source in ipairs(profile.sources) do
            local accepted, _, sarif =
               check_msvc_scan(source, "source-" .. index)

            assert(accepted, "MSVC source analysis failed")
            assert(
               artifact_io.query(
                  sarif,
                  (
                     '[.runs[].results[]? | select(.level != "note" and '
                     .. '.level != "none")] | length'
                  )
               ) == "0",
               "MSVC diagnostics require review"
            )
            assert(
               tonumber(
                  artifact_io.query(sarif, "[.runs[].artifacts[]?] | length")
               ) > 0,
               "missing MSVC analyzed-file evidence"
            )

            report.analyzed[#report.analyzed + 1] = source
         end
      end,
      debug.traceback
   )

   report.status = success and "PASS" or "ERROR"
   if not success then
      report.error = tostring(message):gsub("[\128-\255]", "?")
   end

   check_msvc_save()
   assert(success, message)
end

return scripts_check_msvc_main()

-- EOF


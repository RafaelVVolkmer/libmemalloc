-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Test native Ansible task execution, simulation and literal arguments.
-- Uses a disposable checkout and the already installed controller.

--- Exercise controller behavior without using the contributor Git settings.
-- @return nil: no values.
local function ANSIBLE_TEST_main()
   local platform = dofile("scripts/lib/platform.lua")
   local runtime = dofile("scripts/workspace/lib/runtime.lua")
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local controller = assert(
      runtime.resolve("ansible", "LIBMEMALLOC_ANSIBLE", "ansible-playbook"),
      "install an Ansible controller"
   )
   local directory = platform.temporary_directory("tests")
   local global_config = directory .. "/global.gitconfig"
   local global_contents = "[user]\n\tname = Fixture owner\n"
   local count = 0

   --- Capture one native controller invocation and check its actual exit.
   -- @param options table: operation settings; omitted fields use the
   -- documented defaults.
   -- @param success any: success supplied to this operation.
   -- @return any: one native controller invocation and check its actual exit.
   local function expect(options, success)
      local command = {
         "env",
         "GIT_CONFIG_GLOBAL=" .. global_config,
         "GIT_CONFIG_NOSYSTEM=1",
         controller,
         "playbook.yml",
      }

      for _, value in ipairs(options) do
         command[#command + 1] = value
      end

      local log = directory .. "/command.log"
      local passed = platform.command_succeeded(
         platform.in_directory(directory, command)
            .. " > "
            .. platform.shell_quote(log)
            .. " 2>&1"
      )
      local output = artifacts.read(log)

      assert(passed == success, output)
      count = count + 1

      return output
   end

   --- Encode explicit literal extra-vars using Ansible's unsafe YAML tag.
   -- @param value any: input value; validation belongs to this operation’s
   -- contract.
   -- @return string: explicit literal extra-vars using Ansible's unsafe YAML
   -- tag.
   local function literal(value)
      return "!unsafe " .. artifacts.text_json(value)
   end

   --- Exercise failed children and malformed transport; retain diagnostics.
   -- @return nil: requires controller failure and a visible result summary.
   local function ansible_test_failedResults()
      local path = directory .. "/scripts/process/playbook.lua"
      local original = artifacts.read(path)
      local cases = {
         {
            text = '{"change_status":"unchanged","fixture":"failed-result"}',
            code = 23,
         },
         { text = "", code = 24 },
         { text = "invalid-json", code = 25 },
         { text = "[]", code = 26 },
         { text = "invalid-json", code = 0 },
      }

      for _, case in ipairs(cases) do
         local injection = "local function PLAYBOOK_main()\n"
            .. '   if arg[1] == "--result-json" and arg[2] == "capture" then\n'
            .. "      io.write("
            .. string.format("%q", case.text)
            .. ")\n"
            .. "      os.exit("
            .. case.code
            .. ")\n   end\n"
         local mutant = original:gsub(
            "local function PLAYBOOK_main%(%)\n",
            --- Insert fixture code without replacement-string expansion.
            -- @return string: the controlled dispatcher prefix.
            function()
               return injection
            end,
            1
         )

         artifacts.write(path, mutant)
         local output = expect({ "-e", "lma_task=capture" }, false)

         assert(
            output:find("Show the retained task result", 1, true),
            "failed task lost its summary"
         )
         if case.code ~= 0 then
            assert(
               output:find('"rc": ' .. case.code, 1, true),
               "original exit code was lost"
            )
         else
            assert(
               output:find("without a valid structured task result", 1, true),
               "invalid success report was accepted"
            )
         end
      end

      artifacts.write(path, original)
   end

   --- Assemble the fixture and require both real and simulated behavior.
   -- @return nil: no values.
   local success, failure = xpcall(function()
      artifacts.write(global_config, global_contents)
      for _, name in ipairs({ "scripts", "tools", "infra" }) do
         platform.run({ "cp", "-R", name, directory .. "/" .. name })
      end

      for _, name in ipairs({ "playbook.yml", ".gitconfig" }) do
         platform.run({ "cp", name, directory .. "/" .. name })
      end

      artifacts.mkdir(directory .. "/.cache/tools")
      platform.run({
         "cp",
         ".cache/tools/automation.yml",
         directory .. "/.cache/tools/automation.yml",
      })
      platform.run({
         "cp",
         "tests/fixtures/process/arguments.lua",
         directory .. "/capture.lua",
      })
      platform.run_in_directory(directory, { "git", "init", "--quiet" })

      local registry = directory .. "/tools/process/playbook.lua"
      local source = artifacts.read(registry)

      source = source:gsub(
         "   local tasks = {",
         '   local tasks = { capture = { "capture.lua" },',
         1
      )
      source = source:gsub(
         "   local metadata = {",
         [[
   local metadata = { capture = {
      description = "Capture literal fixture arguments",
      dependencies = {}, effects = "read", simulation = "plan",
      argument_passthrough = true,
      timeout_seconds = 10,
   },]],
         1
      )
      artifacts.write(registry, source)

      local arguments = {
         "path with spaces",
         "dólar",
         "--value=$HOME",
         "$(touch SHOULD_NOT_EXIST)",
         "{{ 7 * 7 }}",
         'quote"and\\slash',
         "line\nbreak",
      }
      local encoded, expected = {}, {}

      for _, value in ipairs(arguments) do
         encoded[#encoded + 1] = literal(value)
         expected[#expected + 1] = value:gsub(
            ".",
            --- Record exact bytes independently of the child encoder.
            -- @param character string: captured character or byte sequence.
            -- @return any: record exact bytes independently of the child
            -- encoder.
            function(character)
               return string.format("%02x", character:byte())
            end
         )
      end

      artifacts.write(
         directory .. "/arguments.yml",
         "lma_task: capture\nlma_arguments: ["
            .. table.concat(encoded, ",")
            .. "]\n"
      )
      local check = expect({ "--check", "-e", "@arguments.yml" }, true)

      assert(check:find("changed=0", 1, true), "check mode reported a change")
      assert(not platform.command_succeeded_silent_in_directory(directory, {
         "git",
         "config",
         "--local",
         "--get",
         "libmemalloc.managedConfig",
      }), "check mode changed Git settings")
      local output = expect({ "-e", "@arguments.yml" }, true)

      assert(
         output:find("changed=1", 1, true),
         "first play did not report Git setup"
      )
      local configured = platform.command_output_in_directory(directory, {
         "git",
         "config",
         "--local",
         "--get",
         "libmemalloc.managedConfig",
      })

      assert(
         configured == directory .. "/.gitconfig\n",
         "setup escaped the repository"
      )
      output = expect({ "-e", "@arguments.yml" }, true)
      assert(
         output:find("changed=0", 1, true),
         "verification reported a change"
      )
      local captured = directory .. "/.cache/captured-arguments.txt"

      assert(
         artifacts.read(captured) == table.concat(expected, "\n") .. "\n",
         "Ansible changed literal argument bytes"
      )
      artifacts.write(
         registry,
         source:gsub(
            'dependencies = {}, effects = "read", simulation = "plan",',
            'dependencies = {}, effects = "workspace", simulation = "plan",',
            1
         )
      )
      output = expect({ "-e", "@arguments.yml" }, true)
      assert(
         output:find("changed=1", 1, true),
         "unknown mutation reported unchanged"
      )
      assert(
         output:find("change_status=unknown", 1, true),
         "unknown mutation warning missing"
      )
      artifacts.write(registry, source)
      assert(
         not artifacts.exists(directory .. "/SHOULD_NOT_EXIST"),
         "Ansible executed argument shell syntax"
      )
      assert(os.remove(captured))
      output = expect({ "--check", "-e", "@arguments.yml" }, true)
      assert(not artifacts.exists(captured), "check mode executed the task")
      assert(output:find("changed=0", 1, true), "simulation reported a change")
      expect({}, true)

      local setup = expect({ "-e", "lma_task=setup" }, true)

      assert(
         setup:find("changed=0", 1, true),
         "repeated setup claimed a change"
      )
      local uninstall = expect({ "-e", "lma_task=setup-uninstall" }, true)

      assert(uninstall:find("changed=1", 1, true), "uninstall lost its change")
      uninstall = expect({ "-e", "lma_task=setup-uninstall" }, true)
      assert(
         uninstall:find("changed=0", 1, true),
         "repeated uninstall claimed a change"
      )
      setup = expect({ "-e", "lma_task=setup" }, true)
      assert(setup:find("changed=1", 1, true), "setup lost its change")

      artifacts.write(directory .. "/.cache/tmp/disposable", "temporary\n")
      local clean_options =
         { "-e", '{"lma_task":"clean","lma_arguments":["--scope=temporary"]}' }

      expect({ "--check", "-e", clean_options[2] }, true)
      assert(
         artifacts.exists(directory .. "/.cache/tmp/disposable"),
         "check mode cleaned files"
      )
      local cleaned = expect(clean_options, true)

      assert(cleaned:find("changed=1", 1, true), "cleanup lost its change")
      assert(
         not artifacts.exists(directory .. "/.cache/tmp/disposable"),
         "cleanup left temporary files"
      )
      cleaned = expect(clean_options, true)
      assert(
         cleaned:find("changed=0", 1, true),
         "repeated cleanup claimed a change"
      )
      assert(
         artifacts.exists(directory .. "/.cache/tools/automation.yml"),
         "cleanup removed managed tools"
      )
      cleaned = expect({ "-e", "lma_task=clean" }, true)
      assert(
         cleaned:find("changed=1", 1, true),
         "full cleanup left old task logs"
      )
      cleaned = expect({ "-e", "lma_task=clean" }, true)
      assert(
         cleaned:find("changed=0", 1, true),
         "cleanup receipts defeated idempotence"
      )
      artifacts.write(directory .. "/.cache/tmp/tracked", "owned input\n")
      platform.run_in_directory(
         directory,
         { "git", "add", ".cache/tmp/tracked" }
      )
      expect(clean_options, false)
      expect({ "--check", "-e", clean_options[2] }, false)
      assert(
         artifacts.exists(directory .. "/.cache/tmp/tracked"),
         "cleanup removed a tracked input"
      )

      for _, options in ipairs({
         { "-e", "lma_task=unknown-task" },
         { "--check", "-e", "lma_task=unknown-task" },
         { "-e", "lma_task=capture", "-e", "lma_arguments=not-a-list" },
         { "-e", '{"lma_task":"capture","lma_arguments":[1]}' },
         {
            "--check",
            "-e",
            '{"lma_task":"build","lma_arguments":["--profile=invalid"]}',
         },
         {
            "--check",
            "-e",
            '{"lma_task":"setup","lma_arguments":["--unknown"]}',
         },
         {
            "--check",
            "-e",
            '{"lma_task":"clean","lma_arguments":["--scope=../"]}',
         },
      }) do
         expect(options, false)
      end

      ansible_test_failedResults()

      assert(
         artifacts.read(global_config) == global_contents,
         "playbook changed global Git configuration"
      )
   end, debug.traceback)

   platform.remove_temporary_directory(directory)
   assert(success, failure)
   print(string.format("Ansible integration: %d operations passed.", count))
end

return ANSIBLE_TEST_main()

-- EOF


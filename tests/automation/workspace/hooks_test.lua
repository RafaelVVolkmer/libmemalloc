-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Check hook reference policy and fail-closed process decisions.
-- Part of workspace regression tests; injected Git responses avoid user keys.

--- Exercise policy and hook orchestration through controlled process ports.
-- @return nil: no values.
local function HOOK_TEST_main()
   local messages = dofile("scripts/workspace/lib/commit_message.lua")
   local object = string.rep("a", 40)
   local previous = string.rep("b", 40)
   local zero = string.rep("0", 40)

   --- Encode one Git pre-push record with caller-selected object identities.
   -- @param target any: selected target configuration or path.
   -- @param current any: current supplied to this operation.
   -- @param old any: old supplied to this operation.
   -- @return string: one Git pre-push record with caller-selected object
   -- identities.
   local function record(target, current, old)
      return "refs/heads/main " .. current .. " " .. target .. " " .. old
   end

   local signature = "gpgsig -----BEGIN PGP SIGNATURE-----"
   local message = "fix: handle allocation failure\n\n"
      .. "Signed-off-by: Test User <test@example.org>\n"

   assert(
      messages.normalize(message .. "# editor comment\n") == message,
      "editor comments remain"
   )
   assert(
      messages.normalize(
         message
            .. "# ------------------------ >8 ------------------------\ndiff\n"
      ) == message,
      "scissors suffix remains"
   )

   --- Run pre-push with a fake Git port, retaining real policy validators.
   -- @param lines any: lines supplied to this operation.
   -- @param behavior any: behavior supplied to this operation.
   -- @return any, table, number: run pre-push with a fake Git port, retaining
   -- real policy validators.
   local function push(lines, behavior)
      local revisions = {}
      local checked = 0
      local environment = setmetatable({
         io = {
            --- Yield supplied protocol records in their original order.
            -- @return any: yield supplied protocol records in their original
            -- order.
            lines = function()
               local position = 0

               --- Advance a record without reading host stdin.
               -- @return any: advance a record without reading host stdin.
               return function()
                  position = position + 1

                  return lines[position]
               end
            end,
            stderr = {
               --- Keep expected rejection messages out of the success log.
               -- @return nil: no values.
               write = function() end,
            },
         },
         --- Replace only process operations; policy remains production code.
         -- @param path string: filesystem path selected by the caller.
         -- @return any: replace only process operations; policy remains
         -- production code.
         dofile = function(path)
            if path ~= "scripts/lib/platform.lua" then
               return dofile(path)
            end

            return {
               --- Dispatch fixture Git data with one explicit failure mode.
               -- @param command table: executable and literal command
               -- arguments.
               -- @return any: dispatch fixture Git data with one explicit
               -- failure mode.
               command_output = function(command)
                  --- Resolve the advertised commit unless it is unavailable.
                  -- @return string: the advertised commit unless it is
                  -- unavailable.
                  local function resolve()
                     local value

                     if behavior ~= "missing-base" then
                        value = command[4]:sub(1, 40)
                     end

                     return value
                  end

                  --- Advertise an empty destination or its symbolic baseline.
                  -- @return string: advertise an empty destination or its
                  -- symbolic baseline.
                  local function advertise()
                     local value = ""

                     if behavior ~= "empty-remote" then
                        value = "ref: refs/heads/main\tHEAD\n"
                           .. previous
                           .. "\trefs/heads/main"
                     end

                     return value
                  end

                  --- Record the exact revision range requested by the hook.
                  -- @return any: record the exact revision range requested by
                  -- the hook.
                  local function enumerate()
                     revisions[#revisions + 1] = command[4]

                     return behavior ~= "enumeration" and object or nil
                  end

                  --- Keep forged signatures in the body instead of the header.
                  -- @return string: keep forged signatures in the body instead
                  -- of the header.
                  local function object_data()
                     local value = "tree abc\n" .. signature .. "\n\nbody"

                     if behavior == "forged" then
                        value = "tree abc\n\n" .. signature
                     end

                     return value
                  end

                  --- Return parent metadata independently from message text.
                  -- @return any: parent metadata independently from message
                  -- text.
                  local function show()
                     local value = behavior == "message" and "fix: no DCO"
                        or message

                     if command[4] == "--format=%P" then
                        value = behavior == "merge"
                              and previous .. " " .. object
                           or previous
                     end

                     return value
                  end

                  --- Simulate related and unrelated histories.
                  -- @return any: simulate related and unrelated histories.
                  local function merge_base()
                     return behavior ~= "unrelated" and previous or nil
                  end

                  --- Leave the optional baseline configuration unset.
                  -- @return nil: leave the optional baseline configuration
                  -- unset.
                  local function configuration()
                     return nil
                  end

                  local commands = {
                     ["rev-parse"] = resolve,
                     ["merge-base"] = merge_base,
                     config = configuration,
                     ["ls-remote"] = advertise,
                     ["rev-list"] = enumerate,
                     ["cat-file"] = object_data,
                     show = show,
                  }
                  local selected =
                     assert(commands[command[2]], "unexpected Git invocation")

                  return selected()
               end,
               --- Count signature checks and inject a failure.
               -- @param command table: executable and literal command
               -- arguments.
               -- @return boolean: count signature checks and inject a failure.
               command_succeeded_silent = function(command)
                  assert(
                     command[2] == "verify-commit",
                     "unexpected signature command"
                  )
                  checked = checked + 1

                  return behavior ~= "signature"
               end,
            }
         end,
      }, {
         __index = {
            assert = assert,
            ipairs = ipairs,
            pairs = pairs,
            next = next,
            type = type,
            pcall = pcall,
            table = table,
            tostring = tostring,
            print = print,
         },
      })
      local hooks =
         assert(loadfile("scripts/workspace/lib/hooks.lua", "t", environment))()

      return hooks.pre_push({ "origin", "/fixture/remote" }), revisions, checked
   end

   assert(
      messages.normalize("# template license\n\n" .. message) == message,
      "template header introduced an empty subject"
   )

   local update = record("refs/heads/main", object, previous)
   local status, revisions, checked = push({ update, update }, "valid")

   assert(status == 0 and checked == 1, "duplicate commits must run once")
   assert(revisions[1] == previous .. ".." .. object, "wrong update range")

   status, revisions =
      push({ record("refs/heads/main", object, zero) }, "valid")
   assert(
      status == 0 and revisions[1] == previous .. ".." .. object,
      "new refs must not exclude unrelated remote-tracking commits"
   )

   status, revisions =
      push({ record("refs/heads/main", object, zero) }, "empty-remote")
   assert(
      status == 0 and revisions[1] == object,
      "empty remote must check history"
   )
   assert(
      push({ record("refs/heads/main", object, zero) }, "missing-base") == 1,
      "missing baseline accepted"
   )
   assert(messages.is_merge(previous .. " " .. object))
   assert(
      #messages.validate("Merge branch topic", true) == 0,
      "genuine merge was not exempt"
   )
   assert(
      #messages.validate("Merge branch topic", false) > 0,
      "ordinary commit received merge exemption"
   )

   for _, failure in ipairs({
      "enumeration",
      "unrelated",
      "forged",
      "signature",
      "message",
   }) do
      assert(push({ update }, failure) == 1, failure)
   end

   assert(push({ "invalid" }, "valid") == 1, "malformed push accepted")
   assert(push({}, "valid") == 0, "empty push rejected")
   print(
      "Git hooks: reference, signature, range and message regressions passed."
   )
end

return HOOK_TEST_main()

-- EOF


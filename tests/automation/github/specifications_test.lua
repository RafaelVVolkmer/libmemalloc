-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Exercise maintainer label authority and API argument boundaries offline.
-- Tests use pure event data and injected API ports; no GitHub mutation occurs.

--- Run positive, negative and repair cases against the production policy.
-- @return nil: no values.
local function SPEC_TEST_main()
   local catalog = dofile(".github/specifications.lua")
   local policy = dofile("scripts/github/lib/specifications.lua")
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local count = 0
   local owner = "RafaelVVolkmer"

   --- Check one authorization result against its explicit expectation.
   -- @param actor any: actor supplied to this operation.
   -- @param permission any: permission supplied to this operation.
   -- @param expected any: expected reference value used by this check.
   -- @return nil: no values.
   local function SPEC_TEST_permission(actor, permission, expected)
      assert(
         policy.authorized(catalog, actor, permission) == expected,
         "authorization differs for " .. actor .. ": " .. permission
      )

      count = count + 1
   end

   for _, role in ipairs({ "read", "triage", "write", "maintain", "admin" }) do
      SPEC_TEST_permission(
         owner,
         role,
         role == "write" or role == "maintain" or role == "admin"
      )
      SPEC_TEST_permission("contributor", role, false)
   end

   SPEC_TEST_permission("github-actions[bot]", "admin", false)

   local events = {
      { action = "labeled", label = "spec", actor = owner },
      { action = "labeled", label = "gc-implementation", actor = owner },
      { action = "unlabeled", label = "spec", actor = "contributor" },
      { action = "labeled", label = "tests", actor = "contributor" },
      {
         action = "unlabeled",
         label = "gc-implementation",
         actor = "github-actions[bot]",
      },
   }
   local desired = policy.desired(catalog, events, { [owner] = "write" })

   assert(
      desired.spec and desired["gc-implementation"] and not desired.tests,
      "unauthorized event changed desired labels"
   )

   events[#events + 1] = { action = "unlabeled", label = "spec", actor = owner }
   assert(
      not policy.desired(catalog, events, { [owner] = "write" }).spec,
      "latest authorized removal was lost"
   )
   assert(
      next(policy.desired(catalog, events, { [owner] = "triage" })) == nil,
      "triage granted reserved-label authority"
   )

   count = count + 3

   for _, label in ipairs(catalog.labels) do
      if label.name ~= "spec" then
         local path = catalog.specification_directory
            .. catalog.specification_prefix
            .. label.name
            .. catalog.specification_suffix

         assert(
            artifacts.exists(path),
            "area has no existing SDD: " .. label.name
         )
      end
   end

   assert(
      not artifacts.exists("docs/specs/libmemalloc-fc-implementation-SDD.md"),
      "obsolete FC area exists"
   )

   count = count + 1

   local mutations = {}
   local observed_change = false
   local synchronized = true
   local port = setmetatable({}, { __index = artifacts })

   --- Supply only the API resources the metadata adapter is allowed to read.
   -- @param argv table: dense executable-and-arguments sequence; values remain
   -- literal.
   -- @return any: supply only the API resources the metadata adapter is allowed
   -- to read.
   function port.output(argv)
      assert(argv[1] == "gh" and argv[2] == "api", "unexpected API executable")

      local path = argv[3]

      if path:match("/permission$") then
         return "write"
      elseif path:match("/events%?per_page=100$") then
         assert(argv[#argv] == "--paginate", "history pagination missing")

         return "labeled\tspec\t"
            .. owner
            .. "\n"
            .. "labeled\ttests\tcontributor\n"
            .. "unlabeled\tspec\tcontributor"
      elseif path:match("/labels%?per_page=100$") then
         assert(argv[#argv] == "--paginate", "label pagination missing")
         if argv[#argv - 1]:find(".color", 1, true) then
            local rows = {}

            for index, label in ipairs(catalog.labels) do
               local initial = not synchronized and index == 1
               local color = initial and "000000" or label.color

               rows[#rows + 1] = label.name
                  .. "\t"
                  .. color
                  .. "\t"
                  .. label.description
            end

            return table.concat(rows, "\n")
         end

         return "tests\nbug"
      end

      error("unexpected API resource: " .. path)
   end

   --- Capture mutations without contacting GitHub.
   -- @param argv table: dense executable-and-arguments sequence; values remain
   -- literal.
   -- @return nil: no values.
   function port.run(argv)
      mutations[#mutations + 1] = argv
   end

   local environment = setmetatable({
      arg = { "--operation=enforce", "--issue=42" },
      os = {
         --- Identify a fixed test repository without exposing real credentials.
         -- @param name string: entry or operation name to resolve.
         -- @return any: identify a fixed test repository without exposing real
         -- credentials.
         getenv = function(name)
            if name == "GITHUB_REPOSITORY" then
               return "example/project"
            elseif name == "GITHUB_ACTOR" then
               return owner
            end
         end,
      },
      --- Inject the API port while loading the actual policy and catalog.
      -- @param path string: filesystem path selected by the caller.
      -- @return any: inject the API port while loading the actual policy and
      -- catalog.
      dofile = function(path)
         if path == "scripts/lib/artifacts.lua" then
            return port
         elseif path == "scripts/lib/change.lua" then
            return {
               --- Retain whether any operation changed the simulated GitHub
               -- state.
               -- @param changed any: changed supplied to this operation.
               -- @return nil: no values.
               record = function(changed)
                  observed_change = observed_change or changed
               end,
            }
         end

         return dofile(path)
      end,
   }, {
      __index = {
         assert = assert,
         type = type,
         ipairs = ipairs,
         pairs = pairs,
         next = next,
         table = table,
         print = print,
         tostring = tostring,
      },
   })

   assert(loadfile("scripts/github/specifications.lua", "t", environment))()
   assert(#mutations == 2, "unrelated labels must survive")
   assert(
      mutations[1][4] == "POST" and mutations[1][7] == "labels[]=spec",
      "authorized spec label was not restored"
   )
   assert(
      mutations[2][4] == "DELETE" and mutations[2][5]:match("/labels/tests$"),
      "unauthorized area label survived"
   )

   count = count + 1

   environment.arg = { "--operation=enforce", "--issue=42;touch /tmp/injected" }
   assert(
      not pcall(
         assert(loadfile("scripts/github/specifications.lua", "t", environment))
      ),
      "malformed issue number was accepted"
   )
   assert(#mutations == 2, "invalid arguments reached the mutation port")

   --- Check remote no-op and update reporting without contacting GitHub.
   -- @return nil: no values.
   local function check_sync()
      mutations, observed_change = {}, false
      environment.arg = { "--operation=sync" }
      assert(loadfile("scripts/github/specifications.lua", "t", environment))()
      assert(
         #mutations == 0 and not observed_change,
         "identical labels were updated"
      )
      synchronized = false
      assert(loadfile("scripts/github/specifications.lua", "t", environment))()
      assert(
         #mutations == 1 and observed_change,
         "changed label was not reported"
      )
   end

   check_sync()

   count = count + 1
   print(
      "Specification policy: "
         .. count
         .. " authority, history and adapter cases passed."
   )
end

return SPEC_TEST_main()

-- EOF


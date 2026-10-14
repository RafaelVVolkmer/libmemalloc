-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Synchronize the label catalog or reconcile reserved labels on one issue.
-- Runs against trusted default-branch code; requires gh authentication.
-- Issue text and proposed source code never enter an executable command.

--- Run the selected metadata operation through explicit GitHub API arguments.
-- @return nil: no values.
local function SPECIFICATIONS_main()
   local io_tools = dofile("scripts/lib/artifacts.lua")
   local catalog = dofile(".github/specifications.lua")
   local policy = dofile("scripts/github/lib/specifications.lua")
   local options = io_tools.options(arg, { operation = true, issue = true })
   local change = dofile("scripts/lib/change.lua")

   change.record(false)
   local repository = os.getenv("GITHUB_REPOSITORY")
      or io_tools.output({
         "gh",
         "repo",
         "view",
         "--json",
         "nameWithOwner",
         "--jq",
         ".nameWithOwner",
      })

   assert(repository:match("^[%w_.-]+/[%w_.-]+$"), "invalid repository")

   local api_root = "repos/" .. repository
   local operation = options.operation

   assert(
      operation == "sync" or operation == "enforce",
      "expected --operation=sync or enforce"
   )

   --- Read paginated metadata with a fixed jq projection.
   -- @param endpoint any: endpoint supplied to this operation.
   -- @param projection any: projection supplied to this operation.
   -- @param paginate any: paginate supplied to this operation.
   -- @return any: paginated metadata with a fixed jq projection.
   local function SPECIFICATIONS_read(endpoint, projection, paginate)
      local command = { "gh", "api", api_root .. endpoint, "--jq", projection }

      if paginate then
         command[#command + 1] = "--paginate"
      end

      return io_tools.output(command)
   end

   --- Query permission only for a roster member, with a validated login.
   -- @param actor string: actor supplied to this operation.
   -- @return any: query permission only for a roster member, with a validated
   -- login.
   local function SPECIFICATIONS_permission(actor)
      assert(actor:match("^[%w-]+$"), "invalid maintainer login")

      return SPECIFICATIONS_read(
         "/collaborators/" .. actor .. "/permission",
         ".permission"
      )
   end

   --- Create or update the catalog without altering unrelated labels.
   -- @return nil: no values.
   local function SPECIFICATIONS_sync()
      assert(not options.issue, "sync does not accept an issue")

      local actor = os.getenv("GITHUB_ACTOR")
         or io_tools.output({ "gh", "api", "user", "--jq", ".login" })

      assert(catalog.maintainers[actor], "actor is not a listed maintainer")
      assert(
         policy.authorized(catalog, actor, SPECIFICATIONS_permission(actor)),
         "maintainer lacks write access"
      )

      local existing = {}

      for row in
         SPECIFICATIONS_read(
            "/labels?per_page=100",
            '.[] | [.name, .color, (.description // "")] | @tsv',
            true
         ):gmatch("[^\n]+")
      do
         local name, color, description =
            row:match("^([^\t]+)\t([^\t]+)\t(.*)$")

         assert(name, "invalid label metadata")
         existing[name] = { color = color, description = description }
      end

      for _, label in ipairs(catalog.labels) do
         local endpoint = api_root .. "/labels"
         local method = "POST"

         if existing[label.name] then
            endpoint = endpoint .. "/" .. label.name
            method = "PATCH"
         end

         local current = existing[label.name]
         if
            not current
            or current.color ~= label.color
            or current.description ~= label.description
         then
            io_tools.run({
               "gh",
               "api",
               "--method",
               method,
               endpoint,
               "--raw-field",
               "name=" .. label.name,
               "--raw-field",
               "color=" .. label.color,
               "--raw-field",
               "description=" .. label.description,
            })
            change.record(true)
         end
      end
   end

   --- Reconcile fresh issue state against authorized history, including
   -- removals.
   -- @return nil: no values.
   local function SPECIFICATIONS_enforce()
      local issue = assert(options.issue, "enforce requires --issue=NUMBER")

      assert(
         type(issue) == "string" and issue:match("^[1-9]%d*$"),
         "invalid issue number"
      )

      local endpoint = "/issues/" .. issue
      local reserved = {}

      for _, label in ipairs(catalog.labels) do
         reserved[label.name] = true
      end

      local history = SPECIFICATIONS_read(
         endpoint .. "/events?per_page=100",
         (
            '.[] | select(.event == "labeled" or '
            .. '.event == "unlabeled") | [.event, '
            .. ".label.name, .actor.login] | @tsv"
         ),
         true
      )
      local events = {}
      local permissions = {}

      for line in history:gmatch("[^\n]+") do
         local action, label, actor =
            line:match("^([^\t]+)\t([^\t]+)\t([^\t]+)$")

         if reserved[label] and catalog.maintainers[actor] then
            permissions[actor] = permissions[actor]
               or SPECIFICATIONS_permission(actor)
            events[#events + 1] =
               { action = action, label = label, actor = actor }
         end
      end

      local desired = policy.desired(catalog, events, permissions)
      local current = {}

      for name in
         SPECIFICATIONS_read(
            endpoint .. "/labels?per_page=100",
            ".[].name",
            true
         ):gmatch("[^\n]+")
      do
         current[name] = true
      end

      --- Reconcile one specification label against the selected issue.
      -- @param label table: diagnostic or evidence label for this operation.
      -- @return nil: no values.
      local function specifications_reconcileLabel(label)
         if desired[label.name] and not current[label.name] then
            io_tools.run({
               "gh",
               "api",
               "--method",
               "POST",
               api_root .. endpoint .. "/labels",
               "--raw-field",
               "labels[]=" .. label.name,
            })
            change.record(true)
         elseif current[label.name] and not desired[label.name] then
            io_tools.run({
               "gh",
               "api",
               "--method",
               "DELETE",
               api_root .. endpoint .. "/labels/" .. label.name,
            })
            change.record(true)
         end
      end

      for _, label in ipairs(catalog.labels) do
         specifications_reconcileLabel(label)
      end
   end

   if operation == "sync" then
      SPECIFICATIONS_sync()
   else
      SPECIFICATIONS_enforce()
   end
end

return SPECIFICATIONS_main()

-- EOF


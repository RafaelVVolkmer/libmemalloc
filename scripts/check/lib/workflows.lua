-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Check the deliberately narrow documentation deployment YAML contract.
-- @return table: consistency validators; unsupported layouts fail closed.
local function WORKFLOWS_loadModule()
   local exports = {}

   --- Require the exact event and branch guard for one publication boundary.
   -- @param block string: source section containing one folded job/step guard.
   -- @param branch string: branch selected by the push trigger.
   -- @return nil: raises on drift or an unrecognized guard layout.
   local function workflows_guard(block, branch)
      local observed = assert(
         block:match("if: >%-\n(.-)\n%s*[%w%-]+:"),
         "missing folded publication guard"
      ):gsub("%s+", " ")
      local expected = " github.ref == 'refs/heads/"
         .. branch
         .. "' && (github.event_name == 'push'"
         .. " || github.event_name == 'workflow_dispatch')"

      assert(
         observed == expected,
         "publication guard differs from push branch or event policy"
      )
   end

   --- Bind the trigger, Pages artifact and deployment to one explicit branch.
   -- @param source string: complete documentation workflow source.
   -- @return string: the consistently configured publication branch.
   local function WORKFLOWS_documentation(source)
      local branch = assert(
         source:match("\n  push:\n    branches: %[(%S+)%]"),
         "documentation push must select one literal branch"
      )
      local package = assert(
         source:match(
            "%- name: Package the accepted site for Pages\n(.-)\n  deploy:"
         ),
         "missing documentation packaging boundary"
      )
      local deploy = assert(
         source:match("\n  deploy:\n(.*)"),
         "missing documentation deployment"
      )

      assert(branch:match("^[%w_./%-]+$"), "unsupported publication branch")
      workflows_guard(package, branch)
      workflows_guard(deploy, branch)
      assert(
         deploy:find("needs: [validate]", 1, true),
         "deployment must depend on validation"
      )

      return branch
   end

   exports.documentation = WORKFLOWS_documentation

   return exports
end

return WORKFLOWS_loadModule()

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Reduce issue-label history to the latest authorized maintainer decisions.
-- The GitHub adapter supplies event data and current repository permissions.

--- Construct the pure authorization and history reducer.
-- @return table: public operations constructed by this module.
local function SPEC_POLICY_loadModule()
   local exports = {}
   local writable = { write = true, maintain = true, admin = true }

   --- Require both the reviewed maintainer roster and repository write access.
   -- @param catalog table: reviewed catalog of supported entries.
   -- @param actor any: actor supplied to this operation.
   -- @param permission any: permission supplied to this operation.
   -- @return boolean|nil: require both the reviewed maintainer roster and
   -- repository write access.
   local function SPEC_POLICY_authorized(catalog, actor, permission)
      return catalog.maintainers[actor] == true and writable[permission] == true
   end

   --- Reconstruct reserved labels, ignoring unauthorized and bot mutations.
   -- Events must follow GitHub's chronological issue-event order.
   -- @param catalog table: reviewed catalog of supported entries.
   -- @param events any: events supplied to this operation.
   -- @param permissions table: permissions supplied to this operation.
   -- @return table: reconstruct reserved labels, ignoring unauthorized and bot
   -- mutations.
   local function SPEC_POLICY_desired(catalog, events, permissions)
      local reserved = {}
      local desired = {}

      for _, label in ipairs(catalog.labels) do
         reserved[label.name] = true
      end

      for _, event in ipairs(events) do
         if
            reserved[event.label]
            and SPEC_POLICY_authorized(
               catalog,
               event.actor,
               permissions[event.actor]
            )
         then
            if event.action == "labeled" then
               desired[event.label] = true
            elseif event.action == "unlabeled" then
               desired[event.label] = nil
            end
         end
      end

      return desired
   end

   exports.authorized = SPEC_POLICY_authorized
   exports.desired = SPEC_POLICY_desired

   return exports
end

return SPEC_POLICY_loadModule()

-- EOF


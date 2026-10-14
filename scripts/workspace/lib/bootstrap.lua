-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Reuse installed tools only when inputs, product bytes and runtime agree.
-- @return table: public operations constructed by this module.
local function BOOTSTRAP_STATE_loadModule()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local exports = {}

   --- Bind a receipt to the reviewed inputs and each installed product.
   -- @param identity table: declared source, tool or artifact identity.
   -- @param products any: products supplied to this operation.
   -- @return nil|string: bind a receipt to the reviewed inputs and each
   -- installed product.
   local function receipt(identity, products)
      local lines = { identity }

      for _, path in ipairs(products) do
         if not artifacts.exists(path) then
            return nil
         end

         lines[#lines + 1] = path .. " " .. artifacts.digest(path)
      end

      return table.concat(lines, "\n") .. "\n"
   end

   --- Rebuild missing, altered or incompatible tools and validate the result.
   -- @param path string: filesystem path selected by the caller.
   -- @param identity table: declared source, tool or artifact identity.
   -- @param products any: products supplied to this operation.
   -- @param probe any: probe supplied to this operation.
   -- @param install any: install supplied to this operation.
   -- @return boolean: rebuild missing, altered or incompatible tools and
   -- validate the result.
   function exports.ensure(path, identity, products, probe, install)
      local expected = receipt(identity, products)
      if
         expected
         and artifacts.exists(path)
         and artifacts.read(path) == expected
         and probe()
      then
         return false
      end

      -- An interrupted repair must not leave an apparently valid receipt.
      if artifacts.exists(path) then
         assert(os.remove(path))
      end

      install()
      assert(probe(), "installed runtime failed its bootstrap probe")
      artifacts.write(
         path,
         assert(receipt(identity, products), "missing bootstrap product")
      )

      return true
   end

   return exports
end

return BOOTSTRAP_STATE_loadModule()

-- EOF


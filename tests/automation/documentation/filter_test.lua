-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Preserve authored code and links through the Doxygen Markdown filter.
-- Part of repository automation regression tests; run from the root.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function tests_doxygen_filter_test_suite_main()
   local comments = dofile("scripts/documentation/lib/c_comments.lua")
   local banner = (
      "/** ========================================"
      .. "====================================\n *     "
      .. "          A P P L I C A T I O N - E N T R Y "
      .. "- P O I N T\n *     Hosted C entry point; "
      .. "retain the name and signature required by "
      .. "C.\n * ======================================"
      .. "==================================== */"
   )
   local contract = (
      "/** ========================================"
      .. "====================================\n * "
      .. "@brief Keep the documented contract.\n * "
      .. "@return Status.\n *         @retval 0 "
      .. "Success.\n * ================================"
      .. "========================================== "
      .. "*/"
   )
   local source = banner .. "\n" .. contract .. "\nint main(void);\n"
   local filtered = comments.doxygen(source)

   assert(
      not filtered:find("A P P L I C A T I O N", 1, true),
      "decorative banner survived filtering"
   )
   assert(
      not filtered:find("====", 1, true),
      "decorative separator survived filtering"
   )
   assert(filtered:find("@brief Keep the documented contract.", 1, true))
   assert(filtered:find("@retval 0 Success.", 1, true))
   assert(filtered:find("int main(void);", 1, true))

   local _, original_lines = source:gsub("\n", "")
   local _, filtered_lines = filtered:gsub("\n", "")

   assert(
      original_lines == filtered_lines,
      "filter changed source line positions"
   )
   assert(comments.doxygen(filtered) == filtered, "filter is not idempotent")

   local unchanged = {
      'const char *text = "/* not a comment */";\n',
      'const char *text = "\\"/* still a string */";\n',
      'const char *text = R"tag(' .. banner .. ')tag";\n',
      "// " .. banner:gsub("\n", "\\\n") .. "\nint value;\n",
      "/** @addtogroup MODULE_CORE_IMPL\n * @{\n */\n/** @} */\n",
      "/** @brief Formula a == b; keep ==== in semantic text. */\n",
      "/** @brief An unterminated comment\n",
      "/**< Trailing member description. */\n",
      "/* An ordinary comment. */\n",
      "/* EOF */\n",
   }

   for _, input in ipairs(unchanged) do
      assert(comments.doxygen(input) == input, input)
   end

   print(
      "Doxygen filter: banners, contracts, literals, groups and lines passed."
   )
end

return tests_doxygen_filter_test_suite_main()

-- EOF


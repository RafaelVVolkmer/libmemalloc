-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Require both C analyzers to accept clean code and reject their defect
-- fixture.

--- Construct this module within its own initialization scope.
-- @return any: this module within its own initialization scope.
local function tests_lint_c_scanners_test_suite_loadModule()
   --- Exercise scanner diagnostics through the supplied executable ports.
   -- @param platform table: host operations supplied by the caller.
   -- @param cppcheck any: cppcheck supplied to this operation.
   -- @param flawfinder any: flawfinder supplied to this operation.
   -- @return nil: no values.
   return function(platform, cppcheck, flawfinder)
      local release = dofile("scripts/lib/artifacts.lua")
      local policy = dofile("tools/lint/code/c/scanners.lua")
      local directory = platform.temporary_directory("tests")
      local clean = directory .. "/clean.c"

      release.write(clean, "int main(void) { return 0; }\n")

      --- Run clean and rejected scanner inputs before releasing temporary
      -- files.
      -- @return nil: no values.
      local success, message = xpcall(function()
         for _, scanner in ipairs({
            {
               tool = cppcheck,
               arguments = policy.cppcheck,
               defect = "int main(void) { int *p = 0; return *p; }\n",
            },
            {
               tool = flawfinder,
               arguments = policy.flawfinder,
               defect = ("#include <string.h>\
void copy(char *p, const char " .. "*q) { strcpy(p, q); }\
"),
            },
         }) do
            local command = { scanner.tool }

            for _, argument in ipairs(scanner.arguments) do
               command[#command + 1] = argument
            end

            command[#command + 1] = clean
            assert(
               platform.command_succeeded_silent(command),
               "clean scanner fixture failed"
            )

            local bad = directory .. "/defect.c"

            release.write(bad, scanner.defect)

            command[#command] = bad
            assert(
               not platform.command_succeeded_silent(command),
               "scanner accepted its defect fixture"
            )
         end
      end, debug.traceback)

      platform.remove_temporary_directory(directory)
      assert(success, message)

      print(
         "C scanners: clean and defective fixtures passed for both analyzers."
      )
   end
end

return tests_lint_c_scanners_test_suite_loadModule()

-- EOF


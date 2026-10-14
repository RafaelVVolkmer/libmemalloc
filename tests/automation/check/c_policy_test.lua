-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer
-- <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Exercise the C policy on valid and invalid source, including custom queries.
-- Called by check_c.lua even when the repository has no C translation units.

--- Construct this module within its own initialization scope.
-- @return any: this module within its own initialization scope.
local function tests_lint_c_policy_test_suite_loadModule()
   --- Run compiler-backed policy cases through the supplied tool profile.
   -- @param options table: operation settings; omitted fields use the
   -- documented defaults.
   -- @return nil: no values.
   return function(options)
      local temporary = options.platform.temporary_directory()
      local files = {}
      local count = 0

      --- Read a source fixture and close its file handle.
      -- @param path string: filesystem path selected by the caller.
      -- @return any: a source fixture and close its file handle.
      local function read(path)
         local file = assert(io.open(options.root .. "/" .. path, "rb"))
         local source = file:read("*a")

         assert(file:close())

         return source
      end

      --- Stage one C policy input under the owned temporary root.
      -- @param name string: entry or operation name to resolve.
      -- @param source any: source value inspected by this operation.
      -- @return string: stage one C policy input under the owned temporary
      -- root.
      local function write(name, source)
         local path = temporary .. "/" .. name
         local file = assert(io.open(path, "wb"))

         assert(file:write(source))
         assert(file:close())

         files[#files + 1] = path

         return path
      end

      --- Capture checker output for diagnostic assertions.
      -- @param arguments table: ordered arguments for the selected operation.
      -- @return any: checker output for diagnostic assertions.
      local function capture(arguments)
         local command = options.platform.in_directory(options.root, arguments)
         local pipe = assert(io.popen(command .. " 2>&1", "r"))
         local output = pipe:read("*a")
         local success = pipe:close()

         assert(success, output)

         return output
      end

      --- Compare one policy decision and diagnostic with its expected outcome.
      -- @param name string: entry or operation name to resolve.
      -- @param selected any: selected supplied to this operation.
      -- @param source any: source value inspected by this operation.
      -- @param expected any: expected reference value used by this check.
      -- @return nil: no values.
      local function check(name, selected, source, expected)
         count = count + 1

         local file = write("case-" .. count .. ".c", source)
         local arguments = {
            options.tidy,
            "--experimental-custom-checks",
            "--config-file=" .. options.tidy_config,
            "--warnings-as-errors=-*",
            "--quiet",
         }

         if selected then
            arguments[#arguments + 1] = "--checks=-*," .. selected
         end

         arguments[#arguments + 1] = file
         arguments[#arguments + 1] = "--"
         arguments[#arguments + 1] = "-std=c23"

         local output = capture(arguments)

         assert(not output:find("clang-tidy-config", 1, true), output)
         if expected then
            assert(
               output:find("[" .. expected .. "]", 1, true),
               name .. "\n" .. output
            )
         else
            assert(not output:find("warning:", 1, true), name .. "\n" .. output)
         end
      end

      --- Run policy mutations while retaining failures for fixture cleanup.
      -- @return nil: no values.
      local success, failure = xpcall(function()
         local standard = read("docs/standards/c/c-code-standard.md")
         local architecture = read("docs/standards/c/c-module-architecture.md")
         local tidy = read(options.tidy_config)
         local format = read(options.format_config)
         local documents = standard .. architecture

         for control in (tidy .. format):gmatch("(%u+%-%d%d%d)") do
            assert(
               documents:find('id="' .. control:lower() .. '"', 1, true),
               "Unknown policy reference: " .. control
            )
         end

         local api_count = 0

         --- Verify one standards declaration against the C policy fixture.
         -- @param line string: source line to inspect.
         -- @return nil: no values.
         local function c_policy_test_checkStandardLine(line)
            local id, api, action = line:match(
               (
                  '^| <a id="cban%-%d+"></a>(CBAN%-%d+)%s*| '
                  .. "`([%w_]+)`%s*| (.-)%s*|"
               )
            )

            if action == "ban" or action == "review" then
               local message = action == "ban" and "direct call prohibited"
                  or "documented API review required"
               local entry = "^"
                  .. api
                  .. "$,,> "
                  .. id
                  .. " / CSTYLE-085: "
                  .. message

               assert(tidy:find(entry, 1, true), "Missing API policy: " .. id)

               api_count = api_count + 1
            end
         end

         for line in standard:gmatch("[^\n]+") do
            c_policy_test_checkStandardLine(line)
         end

         assert(api_count > 0, "The canonical API register must be checked")

         write(
            "policy.h",
            [[
#if !defined(LIBMEMALLOC_POLICY_H)
#define LIBMEMALLOC_POLICY_H
int TEST_run(int value);
#endif
]]
         )

         local valid = [[
#include "policy.h"
static int test_compute(int value)
{
   int ret = 0;
   ret = value;
   goto function_output;
function_output:
   return ret;
}
int TEST_run(int value)
{
   int ret = 0;
   int index = 0;
   for (index = 0; index < value; index++)
   {
      ret = test_compute(index);
   }
   goto function_output;
function_output:
   return ret;
}
]]

         check("complete policy accepts valid module code", nil, valid)
         check("custom queries accept valid code", "custom-*", valid)
         check(
            "semantic aggregate zero initialization",
            "custom-typed-null-pointer",
            "void f(void) { struct Value { int *pointer; } value = { 0 }; }"
         )
         check(
            "cleanup block under the common exit label",
            "custom-return-at-output-label",
            "int f(void) { int ret = 0; function_output: { ret "
               .. "= 1; return ret; } }"
         )
         check(
            "void exit and callback typedef",
            "custom-*",
            [[
typedef void (*callback_t)(void);
void TEST_stop(void) { goto function_output; function_output: return; }
]]
         )
         check(
            "typed null and explicit conversion",
            "custom-*",
            [[
int TEST_cast(void *source)
{
   int ret = 0;
   int *target = (int *)0;
   target = (int *)source;
   goto function_output;
function_output:
   return ret;
}
]]
         )
         check(
            "named aggregate member",
            "custom-anonymous-aggregate-member",
            [[
struct Value { union Data { int number; float fraction; } data; };
]]
         )
         check(
            "immutable static object",
            "custom-no-static-local",
            [[
int TEST_read(void) { static const int value = 0; return value; }
]]
         )

         local cases = {
            { "function-name", "int BadName(void);" },
            { "function-name", "static int TEST_wrong(void);" },
            { "label-name", "void f(void) { WrongLabel: return; }" },
            { "no-continue", "void f(void) { while (1) { continue; } }" },
            { "no-vla", "void f(int size) { int values[size]; }" },
            { "no-static-local", "void f(void) { static int state = 0; }" },
            {
               "no-nested-local-declaration",
               "void f(void) { { int value = 0; } }",
            },
            { "return-at-output-label", "int f(void) { return 0; }" },
            {
               "return-result-variable",
               "int f(void) { function_output: return 0; }",
            },
            { "initialize-local", "void f(void) { int value; value = 0; }" },
            {
               "assignment-as-value",
               "int f(int a) { int b = 0; return (b = a); }",
            },
            { "embedded-increment", "int f(int a) { return a++; }" },
            { "no-comma-operator", "int f(int a) { return (a++, a); }" },
            { "object-pointer-typedef", "typedef int *handle_t;" },
            { "variadic-boundary", "int f(int count, ...);" },
            {
               "anonymous-aggregate-member",
               "struct Value { union { int number; }; };",
            },
            { "assembly-boundary", 'void f(void) { __asm__(""); }' },
            {
               "explicit-void-pointer-conversion",
               "int *f(void *p) { return p; }",
            },
            { "typed-null-pointer", "int *f(void) { return 0; }" },
         }

         for _, case in ipairs(cases) do
            local name = "custom-" .. case[1]

            check(case[1], name, case[2], name)
         end

         check(
            "wrapped branch requires braces",
            "readability-braces-around-statements",
            "void f(int value) {\n if (value)\n value =\n value + 1;\n }",
            "readability-braces-around-statements"
         )
         check(
            "simple branch omits braces",
            "readability-braces-around-statements",
            "void f(int value) {\n if (value)\n value++;\n }"
         )

         for _, loop in ipairs({ "while (value)", "for (; value;)", "do" }) do
            local suffix = loop == "do" and " while (value);" or ""

            check(
               "single statement loop requires braces",
               "custom-loop-braces",
               "void f(int value) { " .. loop .. " value--;" .. suffix .. " }",
               "custom-loop-braces"
            )
         end

         write("once.h", "#pragma once\nint TEST_once(void);\n")
         check(
            "portable include guards",
            "portability-avoid-pragma-once",
            '#include "once.h"\n',
            "portability-avoid-pragma-once"
         )
         check(
            "reserved project identifier",
            "bugprone-reserved-identifier",
            "int __PROJECT_VALUE;",
            "bugprone-reserved-identifier"
         )
         check(
            "one local declarator",
            "readability-isolate-declaration",
            "void f(void) { int a = 0, b = 0; }",
            "readability-isolate-declaration"
         )
         check(
            "discarded result",
            "bugprone-unused-return-value",
            "int read_value(void); void f(void) { read_value(); }",
            "bugprone-unused-return-value"
         )
         check(
            "banned API",
            "bugprone-unsafe-functions",
            "char *gets(char *); void f(char *p) { gets(p); }",
            "bugprone-unsafe-functions"
         )
         check(
            "bounded copy remains available",
            "bugprone-unsafe-functions",
            [[
#include <string.h>
void f(char *to, const char *from, size_t length) { memcpy(to, from, length); }
]]
         )

         local prose = "/**\n *  @return     Result.\n"
            .. " *          @retval     0 Success.\n"
            .. " * "
            .. string.rep("authored ", 14)
            .. "\n */\n"
         local comment_file =
            write("comment.c", prose .. "int TEST_comment(void);\n")
         local comment_result = capture({
            options.format,
            "--style=file:" .. options.format_config,
            comment_file,
         })

         assert(
            comment_result:find(prose, 1, true),
            "preserve authored C comments"
         )

         local enabled = capture({
            options.tidy,
            "--experimental-custom-checks",
            "--config-file=" .. options.tidy_config,
            "--list-checks",
         })

         for _, diagnostic in ipairs({
            "bugprone-argument-comment",
            "bugprone-comment-backslash",
            "readability-todo",
         }) do
            assert(
               not enabled:find(diagnostic, 1, true),
               diagnostic .. " must be disabled"
            )
         end

         local unformatted = write("format.c", valid)
         local formatted = capture({
            options.format,
            "--style=file:" .. options.format_config,
            unformatted,
         })

         local rendered = write("formatted.c", formatted)
         local repeated = capture({
            options.format,
            "--style=file:" .. options.format_config,
            rendered,
         })

         assert(formatted == repeated, "clang-format must be idempotent")
         assert(
            formatted:find("int TEST_run(int value)\n{", 1, true),
            "Allman function layout"
         )
         assert(formatted:find("\n\tint ret", 1, true), "tab indentation")

         local includes = write(
            "ordering.c",
            [[
#include "z.h"
#include <unistd.h>
#include <stdint.h>
#include "ordering.h"

int *g_pointer;
]]
         )

         local ordered = capture({
            options.format,
            "--style=file:" .. options.format_config,
            includes,
         })

         local expected_order = '#include "ordering.h"\
\
#include <stdint.' .. 'h>\
\
#include <unistd.h>\
\
#include "z.h"'

         assert(
            ordered:find(expected_order, 1, true),
            "CSTYLE-028 include groups"
         )
         assert(
            ordered:find("int *g_pointer;", 1, true),
            "CSTYLE-023 pointer placement"
         )

         local literal = 'const char *text = "'
            .. string.rep("diagnostic ", 12)
            .. '";\n'
         local text_file = write("literal.c", literal)
         local text_result = capture({
            options.format,
            "--style=file:" .. options.format_config,
            text_file,
         })

         assert(
            text_result:find(string.rep("diagnostic ", 12), 1, true),
            "CSTYLE-245 diagnostic text"
         )

         print(
            string.format(
               "C policy: %d diagnostic cases, %d API mappings, "
                  .. "and formatting checks passed.",
               count,
               api_count
            )
         )
      end, debug.traceback)

      for _, file in ipairs(files) do
         assert(os.remove(file))
      end

      options.platform.remove_temporary_directory(temporary)
      assert(success, failure)
   end
end

return tests_lint_c_policy_test_suite_loadModule()

-- EOF


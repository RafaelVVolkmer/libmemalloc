-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Enforce the qualified subset of module rules using compiler evidence.
-- Part of local and CI verification gates.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_check_c_architecture_main()
   local analysis = dofile("scripts/analysis/lib/context.lua")
   local artifact_io = analysis.release
   local policy = dofile("tools/analysis/c/modules.lua")
   local architecture = dofile("scripts/analysis/lib/architecture.lua")
   local tools = dofile("scripts/toolchain/lib/lock.lua").load()
   local options = artifact_io.options(arg, { output = true })
   local analysis_context = analysis.new(
      "architecture",
      options.output or ".cache/ci/c-analysis/architecture"
   )
   local report = analysis_context.report

   --- Require the generated include tree to contain exact public header copies.
   -- @return string: require the generated include tree to contain exact public
   -- header copies.
   local function generated_include()
      local generated = analysis_context.root
         .. "/"
         .. analysis_context.output
         .. "/build/"
         .. policy.build_interface.include

      for _, path in ipairs(artifact_io.files(generated)) do
         assert(
            policy.build_interface.headers[path],
            "undeclared generated public header: " .. path
         )
      end

      for path, source in pairs(policy.build_interface.headers) do
         assert(
            artifact_io.read(generated .. "/" .. path)
               == artifact_io.read(source),
            "generated public header differs from its source"
         )
      end

      return generated
   end

   analysis_context:finish(
      --- Compare compiler-observed dependencies and symbols with module policy.
      -- @return nil: no values.
      function()
         analysis_context:inventory()

         local compiler = analysis_context:tool(
            "clang",
            os.getenv("LIBMEMALLOC_CLANG_ANALYZER")
               or ("clang-" .. tools.clang_analyzer.version)
         )

         local database = analysis_context:build(compiler)

         analysis_context:identity(database)

         local paths = analysis.lines(artifact_io.output({
            "git",
            "ls-files",
            "--cached",
            "--others",
            "--exclude-standard",
            "--",
            "core",
         }))

         architecture.public_headers(paths, policy.modules)

         local reply = analysis_context.output .. "/build/.cmake/api/v1/reply"
         local codemodel

         for _, path in ipairs(artifact_io.files(reply)) do
            if path:match("^codemodel%-v2.*%.json$") then
               codemodel = reply .. "/" .. path
            end
         end

         local consumer = artifact_io.query(
            assert(codemodel, "missing CMake codemodel"),
            (
               ".configurations[0].targets[] | select(.name == "
               .. '"memalloc_mock_consumer") | .jsonFile'
            )
         )

         local includes = analysis.lines(
            artifact_io.query(
               reply .. "/" .. consumer,
               '[.compileGroups[].includes[]?.path] | unique | join("\\n")'
            )
         )

         assert(#includes > 0, "consumer has no captured include paths")

         local generated = generated_include()

         for _, include in ipairs(includes) do
            local accepted = include == generated

            for _, module in ipairs(policy.modules) do
               if
                  include .. "/"
                  == analysis_context.root .. "/" .. module.public_include
               then
                  accepted = true
               end
            end

            assert(
               accepted,
               "consumer inherits an undeclared public include path: "
                  .. include
            )
         end

         --- Capture compiler-resolved include dependencies for one source and
         -- include
         -- root.
         -- @param source any: source value inspected by this operation.
         -- @param label string: diagnostic or evidence label for this
         -- operation.
         -- @param include any: include supplied to this operation.
         -- @return table: compiler-resolved include dependencies for one source
         -- and include root.
         local function check_c_architecture_dependencies(
            source,
            label,
            include
         )
            local output = analysis_context.output .. "/" .. label .. ".d"

            assert(analysis_context:run(label .. "-dependencies", {
               compiler,
               "-std=c99",
               "-I" .. include,
               "-M",
               "-MT",
               "deps",
               "-MF",
               output,
               source,
            }) == 0, "dependency extraction failed")

            local resolved = {}

            for _, path in
               ipairs(architecture.dependencies(artifact_io.read(output)))
            do
               local canonical = artifact_io.output({ "readlink", "-f", path })

               if
                  canonical:sub(1, #analysis_context.root + 1)
                  == analysis_context.root .. "/"
               then
                  resolved[#resolved + 1] =
                     canonical:sub(#analysis_context.root + 2)
               end
            end

            return resolved
         end

         --- Capture compiler symbol references for the selected source fixture.
         -- @param source any: source value inspected by this operation.
         -- @param label string: diagnostic or evidence label for this
         -- operation.
         -- @return nil: no values.
         local function check_c_architecture_references(source, label)
            local json = analysis_context.output .. "/" .. label .. "-ast.json"

            assert(analysis_context:run(label .. "-ast", {
               compiler,
               "-std=c99",
               "-Icore",
               "-Werror=cast-function-type-strict",
               "-Xclang",
               "-ast-dump=json",
               "-fsyntax-only",
               source,
            }, json) == 0, "AST or callback type check failed")

            local names = analysis.lines(
               artifact_io.query(
                  json,
                  (
                     '[.. | objects | select(.kind? == "DeclRefExpr" '
                     .. 'and .referencedDecl.kind? == "FunctionDecl") | .'
                     .. 'referencedDecl.name] | unique | join("\\n")'
                  )
               )
            )

            for _, name in ipairs(names) do
               for _, forbidden in ipairs(policy.forbidden_references) do
                  assert(
                     name ~= forbidden,
                     "strict core references forbidden function " .. name
                  )
               end
            end
         end

         -- Macro spelling must not hide another module's private header.
         local base = analysis_context.output .. "/fixture-modules/"
         local source = base .. "alpha/main.c"

         artifact_io.write(source, ('#define INTERNAL "beta/private.h"\
#include ' .. "INTERNAL\
int main(void) { return 0; }\
"))

         artifact_io.write(
            base .. "beta/private.h",
            "/* internal dependency */\n"
         )

         local modules = {
            { name = "alpha", root = base .. "alpha/", public = {} },
            { name = "beta", root = base .. "beta/", public = {} },
         }

         local resolved =
            check_c_architecture_dependencies(source, "fixture-private", base)

         assert(
            not pcall(architecture.check, source, resolved, modules),
            "macro private include escaped ownership checks"
         )

         modules[2].public = { base .. "beta/private.h" }
         assert(
            architecture.check(source, resolved, modules),
            "public dependency rejected"
         )

         local forbidden = analysis_context.output .. "/fixture-forbidden.c"

         artifact_io.write(
            forbidden,
            "#include <stdlib.h>\nvoid *(*provider)(size_t) = malloc;\n"
         )

         local accepted, failure = pcall(
            check_c_architecture_references,
            forbidden,
            "fixture-forbidden"
         )

         assert(
            not accepted
               and tostring(failure):find("forbidden function malloc", 1, true),
            "AST alias fixture did not detect the forbidden reference"
         )

         local callback = analysis_context.output .. "/fixture-callback.c"

         artifact_io.write(
            callback,
            (
               "int function(int value) { return value; }\
typedef "
               .. "void (*callback_type)(void);\
callback_type "
               .. "callback(void) { return (callback_type)function; "
               .. "}\
"
            )
         )

         local callback_code, callback_log =
            analysis_context:run("fixture-callback", {
               compiler,
               "-Werror=cast-function-type-strict",
               "-fsyntax-only",
               callback,
            })

         assert(
            callback_code ~= 0
               and artifact_io
                  .read(callback_log)
                  :find("-Wcast-function-type-strict", 1, true),
            "incompatible callback conversion accepted"
         )

         for index, path in ipairs(analysis_context.profile.sources) do
            local deps = check_c_architecture_dependencies(
               path,
               "source-" .. index,
               "core"
            )

            architecture.check(path, deps, policy.modules)

            check_c_architecture_references(path, "source-" .. index)

            artifact_io.document(
               analysis_context.output
                  .. "/source-"
                  .. index
                  .. "-dependencies.json",
               artifact_io.array(deps)
            )

            report.analyzed[#report.analyzed + 1] = path
         end

         report.coverage_limitations[#report.coverage_limitations + 1] = (
            "Qualified only for the explicit mock module "
            .. "inventory and include root; not complete CMOD "
            .. "enforcement."
         )
      end
   )
end

return scripts_check_c_architecture_main()

-- EOF


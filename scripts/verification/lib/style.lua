-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Enforce the documented, dependency-free subset of Mathlib source style.
-- @return nil: no values.
local function PROOF_STYLE_main()
   local files = dofile("scripts/verification/lib/files.lua")
   local math = dofile("scripts/verification/lib/math_comments.lua")
   local documented = 0
   local modules = {}
   local count = 0
   local model = "LibMemAlloc"
   local audit = "LibMemAllocAudit"
   local tests = "LibMemAllocTests"

   --- Recognize a root and its children without conflating package prefixes.
   -- @param name string: fully qualified module name.
   -- @param root string: library root module name.
   -- @return boolean: whether the module belongs to the library.
   local function belongs(name, root)
      return name == root
         or name:sub(1, #root + 1) == root .. "."
         or (root == model and name:match("^LibMemAllocImp%.") ~= nil)
   end

   --- Enforce import direction and reject missing local module dependencies.
   -- @param name string: importing local module.
   -- @param imported string: dependency module.
   -- @return nil: no values.
   local function checkDependency(name, imported)
      local localImport = belongs(imported, model)
         or belongs(imported, audit)
         or belongs(imported, tests)
      if localImport then
         assert(modules[imported], "missing local module: " .. imported)
         assert(
            not belongs(name, model) or belongs(imported, model),
            "model imports audit or tests: " .. name .. " -> " .. imported
         )
      end
   end
   --- Check lexical rules without claiming to replace Lean's parser.
   -- @param line string: source line without newline.
   -- @param location string: path and line number for diagnostics.
   -- @return nil: no values.
   local function checkLine(line, location)
      assert(not line:find("[\t\r]"), location .. ": use spaces and LF")
      assert(not line:find(" +$"), location .. ": trailing whitespace")
      assert(assert(utf8.len(line)) <= 100, location .. ": over 100 columns")
      local indent = line:match("^( *)")
      assert(#indent % 2 == 0, location .. ": use two-space indentation")
      assert(
         not line:match("^%s*set_option%s+warningAsError%s+false"),
         location .. ": warnings must remain errors"
      )
      assert(
         not line:match("^%s*set_option%s+linter%..-%s+false"),
         location .. ": linter exceptions require a reviewed policy change"
      )
   end

   --- Validate a source and record its explicit imports for reachability.
   -- @param path string: Lean source path.
   -- @return nil: no values.
   local function checkModule(path)
      local source = files.read(path)
      documented = documented + math.lean(source, path)
      local imports = {}
      local previous = ""
      assert(source:sub(-1) == "\n", path .. ": missing final newline")
      assert(
         source:find("SPDX-License-" .. "Identifier:", 1, true),
         path .. ": license header"
      )
      assert(
         source:find("/-!", 1, true),
         path .. ": missing module documentation"
      )
      local number = 0
      for line in source:gmatch("([^\n]*)\n") do
         number = number + 1
         local location = path .. ":" .. number
         checkLine(line, location)
         local imported = line:match("^import ([%w_.]+)$")
         if line:match("^%s*import%s") then
            assert(imported, location .. ": use one module per import line")
         end
         if imported then
            assert(
               previous < imported,
               location .. ": sort and deduplicate imports"
            )
            previous = imported
            imports[#imports + 1] = imported
         end
      end
      local relative = assert(
         path:match("^verification/theorems/(.+)%.lean$"),
         "Lean source outside the Lake project: " .. path
      )
      local name = relative:gsub("/", ".")
      assert(
         belongs(name, model) or belongs(name, audit) or belongs(name, tests),
         "module outside the declared libraries: " .. name
      )
      modules[name] = imports
      count = count + 1
   end
   for _, path in ipairs(files.inventory()) do
      assert(
         not (
               path:match("^verification/.*%.c$")
               or path:match("^verification/.*%.h$")
               or path:match("^verification/.*%.md$")
            ),
         "verification contains C sources or documentation: " .. path
      )
      if path:match("%.lean$") then
         checkModule(path)
      end
   end
   for name, imports in pairs(modules) do
      for _, imported in ipairs(imports) do
         checkDependency(name, imported)
      end
   end
   local visited = {}
   --- Walk local imports so newly added files cannot silently escape lint.
   -- @param name string: module name.
   -- @return nil: no values.
   local function visit(name)
      if modules[name] and not visited[name] then
         visited[name] = true
         for _, imported in ipairs(modules[name]) do
            visit(imported)
         end
      end
   end
   --- Require complete model and test roots before extending the audit graph.
   -- @return nil: no values.
   local function checkRoots()
      for _, root in ipairs({ model, audit }) do
         assert(modules[root], "missing verification entry point: " .. root)
         visit(root)
         if root == model or root == tests then
            for name in pairs(modules) do
               assert(
                  not belongs(name, root) or visited[name],
                  "module is outside its library import graph: " .. name
               )
            end
         end
      end
      for name in pairs(modules) do
         assert(
            visited[name],
            "module is outside the audited import graph: " .. name
         )
      end
   end
   checkRoots()

   --- Report module coverage independently of specification clause coverage.
   -- @return nil: no values.
   local function emitReport()
      local names, report = {}, { "module\tlibrary\tstatus" }
      for name in pairs(modules) do
         names[#names + 1] = name
      end
      table.sort(names)
      for _, name in ipairs(names) do
         local library = belongs(name, model) and model
            or belongs(name, tests) and tests
            or audit
         report[#report + 1] = name .. "\t" .. library .. "\tIMPORTED"
      end
      assert(os.execute("mkdir -p .cache/verification/reports"))
      files.write(
         ".cache/verification/reports/modules.tsv",
         table.concat(report, "\n") .. "\n"
      )
   end
   emitReport()
   print(
      string.format(
         "Lean style: %d modules, %d mathematical statements; "
            .. "import boundaries and audit graph checked.",
         count,
         documented
      )
   )
end

return PROOF_STYLE_main()

-- EOF


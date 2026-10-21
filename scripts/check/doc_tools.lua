-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer
-- <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Verify the npm graph using Node's native JSON reader before installation.
-- Part of local and CI verification gates.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_check_doc_tools_main()
   local platform = dofile("scripts/lib/platform.lua")
   local toolchain = dofile("scripts/toolchain/lib/lock.lua")
   local lock = assert(io.open("tools/toolchain/lock.toml", "rb"))
   local tools = toolchain.parse(assert(lock:read("*a")))

   assert(lock:close())

   local adapter = [==[
// SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const tools = JSON.parse(process.env.TOOLCHAIN_TOOLS);
const graphs = [
   { directory: "quality", identities: {
      cspell: "cspell", renovate: "renovate", pyright: "pyright",
   }, overrides: { "markdown-it": "markdown_it" } },
   { directory: "md", identities: {
      "markdownlint-cli": "markdownlint", "markdown-it": "markdown_it",
      mermaid: "mermaid", jsdom: "jsdom",
      "@highlightjs/cdn-assets": "highlight_js",
   }, overrides: {
      "lodash-es": "lodash_es", "smol-toml": "smol_toml",
      "js-yaml": "js_yaml", katex: "katex",
   } },
   { directory: "web", identities: {
      "@biomejs/biome": "biome", "html-validate": "html_validate",
      typescript: "typescript",
   }, overrides: {} },
];
for (const graph of graphs) {
const manifest = JSON.parse(
   readFileSync(`tools/lint/code/${graph.directory}/package.json`),
);
const lock = JSON.parse(
   readFileSync(`tools/lint/code/${graph.directory}/package-lock.json`),
);
const identities = graph.identities;
const dependencies = { ...manifest.dependencies, ...manifest.devDependencies };
assert.equal(lock.lockfileVersion, 3);
assert.deepEqual(
   Object.keys(dependencies).sort(),
   Object.keys(identities).sort(),
);
for (const [dependency, identity] of Object.entries(
   identities,
)) {
   assert.equal(
      dependencies[dependency],
      tools[identity].version,
      dependency,
   );
   assert.equal(
      lock.packages[""]?.dependencies?.[dependency]
         ?? lock.packages[""]?.devDependencies?.[dependency],
      tools[identity].version,
      dependency,
   );
   assert.equal(
      lock.packages["node_modules/" + dependency]?.version,
      tools[identity].version,
      dependency,
   );
}
// CWE-1395: upstream exact pins need these audited transitive fixes.
const overrides = graph.overrides;
assert.deepEqual(
   Object.keys(manifest.overrides ?? {}).sort(),
   Object.keys(overrides).sort(),
);
for (const [dependency, identity] of Object.entries(overrides)) {
   const version = tools[identity].version;
   assert.equal(manifest.overrides[dependency], version, dependency);
   const copies = Object.entries(lock.packages).filter(([path]) =>
      path.endsWith("node_modules/" + dependency),
   );
   assert.ok(copies.length > 0, dependency);
   for (const [path, item] of copies) {
      assert.equal(item.version, version, path);
   }
}
// CWE-494 / CAPEC-184: require HTTPS and integrity for every package.
for (const [path, item] of Object.entries(lock.packages)) {
   if (!path) continue;
   assert.match(
      item.resolved,
      /^https:\/\/registry\.npmjs\.org\//,
      path,
   );
   assert.match(
      item.integrity,
      /^sha512-[A-Za-z0-9+/]+={0,2}$/,
      path,
   );
   assert.equal(item.link, undefined, path);
}
}
console.log(
   "Document dependencies match the toolchain and integrity policy.",
);
]==]

   platform.run({
      "env",
      "TOOLCHAIN_TOOLS=" .. toolchain.json(tools),
      "node",
      "--input-type=module",
      "--eval",
      adapter,
   })
end

return scripts_check_doc_tools_main()

-- EOF


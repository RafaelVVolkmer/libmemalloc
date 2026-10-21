-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer
-- <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Validate Mermaid with its official parser, without generated script files.
-- Part of local and CI verification gates.

--- Run this command within one explicit execution boundary.
-- @return nil: no values.
local function scripts_check_mermaid_main()
   local platform = dofile("scripts/lib/platform.lua")
   local git_module = dofile("scripts/lib/git.lua")
   local git = git_module.new(platform, ".")

   -- The adapter is JavaScript only because Mermaid exposes a JavaScript API.
   -- Discovery, command execution and CI integration remain in Lua.
   local adapter = [==[
// SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import { lstat, readFile } from "node:fs/promises";
import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { Worker } from "node:worker_threads";
const load = createRequire(
   process.cwd() + "/.cache/tools/md/package.json",
);
const MarkdownIt = load("markdown-it");
const workerSource = String.raw`
(async () => {
   const {
      parentPort,
      workerData,
   } = require("node:worker_threads");
   const load = require("node:module").createRequire(
      process.cwd() + "/.cache/tools/md/package.json",
   );
   const { JSDOM } = load("jsdom");

   // CWE-79 / CWE-918: disable scripts and external resource loading.
   const dom = new JSDOM("");
   globalThis.window = dom.window;
   globalThis.document = dom.window.document;
   const { default: mermaid } = await import(
      require("node:url").pathToFileURL(load.resolve("mermaid"))
         .href
   );
   mermaid.initialize({
      startOnLoad: false,
      securityLevel: "strict",
      maxTextSize: 131072,
   });
   const failures = [];
   for (const diagram of workerData) {
      try {
         await mermaid.parse(diagram.source);
      } catch (error) {
         failures.push({
            file: diagram.file,
            line: diagram.line,
            error: String(error.message).slice(0, 2000),
         });
      }
   }
   dom.window.close();
   parentPort.postMessage(failures);
})().catch((error) => {
   throw error;
});
`;

const markdown = new MarkdownIt();
const maxFileBytes = 4 * 1024 * 1024;
const maxDiagramBytes = 128 * 1024;
const maxDiagrams = 1024;

function extract(source, filename) {
   if (/\.(mmd|mermaid)$/i.test(filename)) {
      return [{ source, line: 1 }];
   }
   return markdown
      .parse(source, {})
      .filter(
         (token) =>
            token.type === "fence" &&
            /^mermaid(?:\s|$)/i.test(token.info.trim()),
      )
      .map((token) => ({
         source: token.content,
         line: token.map[0] + 2,
      }));
}

function validate(diagrams, timeout = 30000) {
   // CWE-400: reuse one bounded worker with a hard deadline.
   // Parse only; do not render or execute diagram callbacks.
   return new Promise((resolve, reject) => {
      let received = false;
      const worker = new Worker(workerSource, {
         eval: true,
         execArgv: [],
         workerData: diagrams,
         resourceLimits: {
            maxOldGenerationSizeMb: 256,
            stackSizeMb: 4,
         },
      });
      const timer = setTimeout(() => {
         void worker.terminate();
         reject(
            new Error("Mermaid validation exceeded its time budget"),
         );
      }, timeout);
      worker.once("message", (result) => {
         received = true;
         clearTimeout(timer);
         resolve(result);
      });
      worker.once("error", (error) => {
         clearTimeout(timer);
         reject(error);
      });
      worker.once("exit", (code) => {
         clearTimeout(timer);
         if (code !== 0)
            reject(new Error(`Mermaid worker exited with ${code}`));
         else if (!received)
            reject(new Error("Mermaid worker exited without a result"));
      });
   });
}

async function main() {
   // CWE-78: Git paths remain argv/data; filenames never become shell source.
   const files = process.argv.slice(1);
   const diagrams = [];
   for (const file of files) {
      const info = await lstat(file);
      // CWE-22: tracked symlinks must not redirect checks outside the checkout.
      if (!info.isFile() || info.size > maxFileBytes) {
         throw new Error(
            `Unsupported file type or size: ${JSON.stringify(file)}`,
         );
      }
      const blocks = extract(await readFile(file, "utf8"), file);
      for (const block of blocks) {
         if (Buffer.byteLength(block.source) > maxDiagramBytes) {
            throw new Error(
               "Diagram exceeds size budget: " +
                  JSON.stringify(file) + ":" + block.line,
            );
         }
         diagrams.push({ ...block, file });
         if (diagrams.length > maxDiagrams)
            throw new Error("Too many Mermaid diagrams");
      }
   }
   if (diagrams.length === 0) {
      console.log("No Mermaid diagrams found.");
      return;
   }
   const failures = await validate(diagrams);
   for (const failure of failures) {
      // CWE-117: JSON encoding keeps untrusted labels out of workflow commands.
      console.error(JSON.stringify(failure));
   }
   if (failures.length) process.exitCode = 1;
   else
      console.log(`Mermaid: ${diagrams.length} diagrams passed.`);
}

const tests = extract(
   "> ~~~mermaid\n> graph TD; A-->B\n> ~~~\n",
   "test.md",
);
assert.equal(tests.length, 1);
assert.equal(tests[0].line, 2);
assert.equal(
   extract("graph TD; A-->B", "file.mermaid").length,
   1,
);
assert.equal(extract("graph TD; A-->B", "file.mmd").length, 1);
const invalid = await validate([
   { source: "graph TD; A-->B", file: "valid", line: 1 },
   { source: "graph TD; A[", file: "invalid", line: 1 },
   { source: "", file: "empty", line: 1 },
]);
assert.deepEqual(
   invalid.map((item) => item.file),
   ["invalid", "empty"],
);
await assert.rejects(validate([], 1), /time budget/);
await main().catch((error) => {
   console.error(JSON.stringify({ error: error.message }));
   process.exitCode = 1;
});
]==]

   -- CWE-88: a tracked filename cannot become a Node command-line option.
   local arguments = { "node", "--input-type=module", "--eval", adapter, "--" }

   for _, file in ipairs(assert(git.working_files())) do
      if
         file:match("%.md$")
         or file:match("%.markdown$")
         or file:match("%.mmd$")
         or file:match("%.mermaid$")
      then
         arguments[#arguments + 1] = file
      end
   end

   platform.run(arguments)
end

return scripts_check_mermaid_main()

-- EOF


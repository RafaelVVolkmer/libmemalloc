-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Prepare a verified scanner overlay without modifying its installed package.
-- @return table: scanner preparation operations.
local function CVE_loadModule()
   local exports = {}
   local copy_source = [[
import importlib.metadata
import json
import pathlib
import shutil
import sys
import tempfile
import cve_bin_tool
metadata = importlib.metadata.distribution("cve-bin-tool")
source = json.loads(metadata.read_text("direct_url.json"))
assert source["vcs_info"]["commit_id"] == sys.argv[2], (
    "scanner revision mismatch")
destination = tempfile.mkdtemp(prefix="cve-", dir=sys.argv[1])
shutil.copytree(pathlib.Path(cve_bin_tool.__file__).parent,
                pathlib.Path(destination) / "cve_bin_tool")
print(destination)
]]

   --- Verify the patch and installed revision before preparing the scanner.
   -- @param artifacts table: filesystem and command operations.
   -- @param python string: isolated scanner interpreter.
   -- @param cache string: owned absolute cache directory.
   -- @param identity table: locked revision and patch digest.
   -- @param execute function: bounded execution with retained logs.
   -- @return string: isolated overlay containing the patched scanner.
   function exports.prepare(artifacts, python, cache, identity, execute)
      local patch = "tools/security/openssf/cve-memory.patch"
      assert(
         artifacts.digest(patch) == identity.sha256,
         "CVE scanner patch hash mismatch"
      )
      local parent = cache .. "/tools/openssf/overlays"
      artifacts.mkdir(parent)
      local source = artifacts.output({
         python,
         "-c",
         copy_source,
         parent,
         identity.revision,
      })
      local root = artifacts.output({ "git", "rev-parse", "--show-toplevel" })
      execute({
         "patch",
         "--batch",
         "--fuzz=0",
         "-p1",
         "--directory=" .. source,
         "--input=" .. root .. "/" .. patch,
      }, "scanner-patch")
      execute({
         "env",
         "PYTHONPATH=" .. source,
         python,
         source .. "/test/test_record_spool.py",
      }, "scanner-regression")
      return source
   end

   return exports
end

return CVE_loadModule()

-- EOF


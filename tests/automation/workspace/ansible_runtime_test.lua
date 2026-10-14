-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Verify native runtime preparation without the deferred task dispatcher.
-- @return nil: no values.
local function ANSIBLE_RUNTIME_TEST_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local runtime = dofile("scripts/workspace/lib/runtime.lua")
   local root = artifacts.platform.temporary_directory("tests")
   local repository =
      artifacts.output({ "git", "rev-parse", "--show-toplevel" })
   artifacts.write(
      root .. "/runtime_test.py",
      [[
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

root, repository = Path(sys.argv[1]), Path(sys.argv[2])
controller, lua, luv = sys.argv[3:6]
checkout = root / "checkout with spaces"
checkout.mkdir()
for name in ("scripts", "tools", "infra"):
    shutil.copytree(repository / name, checkout / name)
subprocess.run(["git", "init", "--quiet", str(checkout)], check=True)
manifest = checkout / ".cache/tools/automation.yml"
manifest.parent.mkdir(parents=True)
manifest_text = "lma_managed_lua: " + json.dumps(lua) + "\n"
manifest_text += "lma_managed_luv: " + json.dumps(luv) + "\n"
bootstrap = checkout / "scripts/workspace/bootstrap.lua"
bootstrap.write_text('error("runtime test must never install dependencies")\n')
harness = checkout / "runtime.yml"
harness.write_text(
    "---\n- hosts: localhost\n  gather_facts: false\n  vars:\n"
    "    lma_workspace: " + json.dumps(str(checkout)) + "\n"
    "    lma_bootstrap_lua: " + json.dumps(lua) + "\n"
    "  tasks:\n    - ansible.builtin.import_tasks: infra/ansible/tasks/runtime.yml\n"
)
child_env = dict(os.environ)
child_env.pop("ANSIBLE_CONFIG", None)
child_env.update({
    "ANSIBLE_LOCAL_TEMP": str(root / "controller-tmp"),
    "LIBMEMALLOC_PYTHON": sys.executable,
    "GIT_CONFIG_GLOBAL": "/dev/null",
    "GIT_CONFIG_NOSYSTEM": "1",
})


def run(playbook, *args, succeeds=True):
    result = subprocess.run(
        [controller, "-i", "localhost,", "-c", "local", playbook, *args],
        cwd=checkout, env=child_env,
        capture_output=True, text=True, timeout=60,
    )
    assert (result.returncode == 0) == succeeds, result.stdout + result.stderr
    return result.stdout


run("runtime.yml", "--check", succeeds=False)
assert not manifest.exists(), "cold check mode installed a runtime"
manifest.write_text(manifest_text)
assert "changed=0" in run("runtime.yml", "--check")
assert "changed=0" in run("runtime.yml")
assert manifest.read_text() == manifest_text
manifest.write_text("lma_managed_lua: /missing/lua\nlma_managed_luv: /missing/?.so\n")
run("runtime.yml", "--check", succeeds=False)
manifest.write_text(manifest_text)
run("infra/ansible/playbooks/prepare.yml")
assert "changed=0" in run("infra/ansible/playbooks/verify-environment.yml")
for category in ("logs", "tests", "tmp"):
    assert (checkout / ".cache" / category).stat().st_mode & 0o777 == 0o700
print("Ansible runtime: cold checks, warm reuse, rejection and preparation passed.")
]]
   )
   artifacts.run({
      assert(os.getenv("LIBMEMALLOC_QUALITY_PYTHON")),
      root .. "/runtime_test.py",
      root,
      repository,
      assert(
         runtime.resolve("ansible", "LIBMEMALLOC_ANSIBLE", "ansible-playbook")
      ),
      assert(runtime.resolve("lua", "LIBMEMALLOC_LUA", "lua")),
      runtime.paths.luv,
   })
   artifacts.platform.remove_temporary_directory(root)
end

return ANSIBLE_RUNTIME_TEST_main()

-- EOF


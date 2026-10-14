-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Exercise native Ansible setup with disposable, offline provisioning ports.
-- @return nil: no values.
local function ANSIBLE_SETUP_TEST_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local runtime = dofile("scripts/workspace/lib/runtime.lua")
   local root = artifacts.platform.temporary_directory("tests")
   local repository =
      artifacts.output({ "git", "rev-parse", "--show-toplevel" })

   artifacts.write(
      root .. "/test.py",
      [[
import json
import os
import platform
from pathlib import Path
import shutil
import subprocess
import sys

root, repository = Path(sys.argv[1]), Path(sys.argv[2])
controller = sys.argv[3]
checkout = root / "checkout with spaces"
checkout.mkdir()
for name in ("scripts", "tools", "infra"):
    shutil.copytree(repository / name, checkout / name)
for name in ("playbook.yml", ".gitconfig"):
    shutil.copy2(repository / name, checkout / name)
subprocess.run(["git", "init", "--quiet", str(checkout)], check=True)
manifest = (repository / ".cache/tools/automation.yml").read_text()
bootstrap = f"""
assert(os.getenv("LIBMEMALLOC_BOOTSTRAP_RUNTIME_ONLY") == "1")
local a = dofile("scripts/lib/artifacts.lua")
a.write(".cache/tools/automation.yml", {json.dumps(manifest)})
a.write(".cache/bootstrap-called", "yes")
print("Bootstrap tools changed: true")
"""
(checkout / "scripts/workspace/bootstrap.lua").write_text(bootstrap)
(checkout / "probe.sh").write_text("#!/bin/sh\nexit 0\n")
(checkout / "scripts/toolchain/install/quality.lua").write_text("""
local a = dofile("scripts/lib/artifacts.lua")
local profile = arg[1]:match("^%-%-profile=(.+)$")
local selected = dofile("tools/toolchain/quality_profiles.lua")[profile]
local count = io.open("quality-installs", "a")
count:write(profile .. " install\\n")
count:close()
local function tool(name)
   local path = ".cache/tools/quality/" .. name
   a.write(path, a.read("probe.sh"))
   a.run({"chmod", "+x", path})
end
for name, item in pairs(dofile("tools/toolchain/quality.lua")) do
   if selected.archives[name] then
      for key, value in pairs(item.commands) do
         tool("bin/" .. (type(key) == "number" and value or key))
      end
   end
end
for _, name in ipairs(selected.commands) do
   tool("bin/" .. name)
   tool("python-" .. profile .. "/bin/" .. name)
end
for _, name in ipairs(selected.rust) do tool("bin/" .. name) end
tool("python-" .. profile .. "/bin/python")
for _, group in ipairs(selected.node) do
   local directory = profile == "spelling" and "quality-spelling" or group
   a.write(".cache/tools/" .. directory .. "/node_modules/.package-lock.json",
      "fixture")
end
if profile == "all" then
   for _, name in ipairs({ "cppcheck", "biome", "cspell", "pyright",
      "renovate-config-validator" }) do tool("bin/" .. name) end
elseif profile == "spelling" then tool("bin/cspell") end
""")
(checkout / "scripts/check/lua.lua").write_text("""
assert(os.getenv("LIBMEMALLOC_LUAC"))
assert(os.getenv("LIBMEMALLOC_QUALITY_PYTHON"):find("python-lua", 1, true))
assert(os.getenv("PATH"):find(".cache/tools/quality/bin", 1, true))
print("fixture quality passed")
""")
for name in ("scripts/build/local.lua", "scripts/check/spelling.lua",
             "scripts/check/all.lua"):
    (checkout / name).write_text('print("fixture task passed")\n')
theme = checkout / "doxygen/vendor/doxygen-awesome-css/doxygen-awesome.css"
theme.parent.mkdir(parents=True)
theme.write_text("fixture")
child_env = dict(os.environ)
child_env.update({
    "ANSIBLE_LOCAL_TEMP": str(root / "controller-tmp"),
    "GIT_CONFIG_GLOBAL": "/dev/null",
    "GIT_CONFIG_NOSYSTEM": "1",
})
child_env.pop("LIBMEMALLOC_QUALITY_PYTHON", None)
child_env.pop("ANSIBLE_CONFIG", None)


def run(*args, code=0):
    result = subprocess.run(
        [controller, "playbook.yml", *args],
        cwd=checkout, env=child_env,
        capture_output=True, text=True, timeout=60,
    )
    assert result.returncode == code, result.stdout + result.stderr
    return result.stdout


# No root configuration and no shell wrapper, including cold check mode.
assert not (checkout / "ansible.cfg").exists()
assert not (checkout / "playbook").exists()
run("--check", code=2)
assert not (checkout / ".cache/bootstrap-called").exists()
output = run("-e", "lma_bootstrap_lua=/missing/lua", code=2)
install = ("brew install lua" if platform.system() == "Darwin"
           else "sudo apt install lua5.4")
assert install in output
assert not (checkout / ".cache/bootstrap-called").exists()
run()
assert (checkout / ".cache/bootstrap-called").exists()
assert "changed=0" in run(), "warm run changed runtime"
assert not (checkout / "quality-installs").exists()
run("-e", "lma_task=lua-check", "--check")
assert not (checkout / "quality-installs").exists()
run("-e", "lma_task=unknown-task", code=2)
assert not (checkout / "quality-installs").exists()
run("-e", "lma_task=lua-check")
assert "changed=0" in run("-e", "lma_task=check-lua")
assert (checkout / "quality-installs").read_text().count("install") == 1
(checkout / ".cache/tools/quality/bin/stylua").unlink()
run("-e", "lma_task=lua-check")
assert (checkout / "quality-installs").read_text().count("install") == 2
# A broken runtime is repaired before dispatch, without replacing the host.
manifest_path = checkout / ".cache/tools/automation.yml"
manifest_path.write_text('lma_managed_lua: /missing/lua\n'
                         'lma_managed_luv: /missing/?.so\n')
run()
assert manifest_path.read_text() == manifest
for task, profile in (("build", "build"), ("check-spelling", "spelling"),
                      ("checks", "all")):
    run("--check", "-e", "lma_task=" + task)
    history = (checkout / "quality-installs").read_text()
    assert profile + " install" not in history
    run("-e", "lma_task=" + task)
    assert "changed=0" in run("-e", "lma_task=" + task)
    history = (checkout / "quality-installs").read_text()
    assert history.count(profile + " install") == 1
# The relocated configuration is optional and uses its own inventory path.
child_env["ANSIBLE_CONFIG"] = str(checkout / "infra/ansible/ansible.cfg")
output = run("--check", "-e", "lma_task=lua-check")
assert "changed=0" in output
inventory = subprocess.run(
    [str(Path(controller).with_name("ansible-inventory")), "--list"],
    cwd=checkout, env=child_env, capture_output=True, text=True, check=True,
)
assert "localhost" in json.loads(inventory.stdout)["_meta"]["hostvars"]
print("Native setup: cold/warm runtime, quality repair, check mode, "
      "config discovery and environment passed.")
]]
   )
   artifacts.run({
      "python3",
      root .. "/test.py",
      root,
      repository,
      assert(
         runtime.resolve("ansible", "LIBMEMALLOC_ANSIBLE", "ansible-playbook")
      ),
   })
   artifacts.platform.remove_temporary_directory(root)
end

return ANSIBLE_SETUP_TEST_main()

-- EOF


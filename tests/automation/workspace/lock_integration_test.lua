-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Challenge real kernel leases with concurrent tasks and terminated owners.
-- @return nil: no values.
local function LOCK_TEST_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local root = artifacts.platform.temporary_directory("tests")
   local repository =
      artifacts.output({ "git", "rev-parse", "--show-toplevel" })

   artifacts.write(
      root .. "/lease.lua",
      [[
dofile("scripts/workspace/lib/lock.lua").guard(arg[1])
local ready = assert(io.open("ready", "w"))
ready:write("ready\n")
ready:close()
require("luv").sleep(30000)
]]
   )
   artifacts.write(
      root .. "/test.py",
      [[
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import time

root, repository, lua = (
    Path(sys.argv[1]),
    Path(sys.argv[2]),
    shutil.which(sys.argv[3]),
)
assert lua, "Lua interpreter unavailable"
for name in ("scripts", "tools"):
    (root / name).symlink_to(repository / name, target_is_directory=True)
subprocess.run(["git", "init", "--quiet", str(root)], check=True)
sentinel = root / ".cache/build/evidence"
sentinel.parent.mkdir(parents=True)
sentinel.write_text("retain while busy\n")


def run(*args):
    return subprocess.run(
        [lua, *args], cwd=root, capture_output=True, text=True, timeout=15
    )


def holder(mode):
    (root / "ready").unlink(missing_ok=True)
    process = subprocess.Popen(
        [lua, "lease.lua", mode], cwd=root, start_new_session=True
    )
    try:
        deadline = time.monotonic() + 10
        while not (root / "ready").exists():
            assert process.poll() is None, "lock holder exited early"
            assert time.monotonic() < deadline, "lock holder timed out"
            time.sleep(0.01)
        return process
    except BaseException:
        stop(process)
        raise


def stop(process):
    if process.poll() is None:
        os.killpg(process.pid, signal.SIGKILL)
    process.wait(timeout=5)


process = holder("shared")
try:
    for args in (
        ("scripts/workspace/clean.lua", "--scope=build"),
        ("scripts/process/playbook.lua", "--direct", "clean", "--scope=build"),
        ("scripts/process/playbook.lua", "clean", "--scope=build"),
        ("scripts/workspace/bootstrap.lua",),
        ("scripts/toolchain/install/quality.lua",),
        ("scripts/process/playbook.lua", "workspace-bootstrap"),
        ("scripts/process/playbook.lua", "quality-setup"),
        ("scripts/process/playbook.lua", "toolchain-install-quality"),
    ):
        result = run(*args)
        assert result.returncode == 75, result.stderr
        assert sentinel.exists(), "busy cleanup removed build evidence"
    result = run(
        "scripts/workspace/with_lock.lua",
        "--",
        lua,
        "scripts/workspace/with_lock.lua",
        "--",
        lua,
        "-e",
        "print('nested shared')",
    )
    assert result.returncode == 0 and "nested shared" in result.stdout, (
        result.stderr
    )
finally:
    stop(process)

process = holder("exclusive")
try:
    for args in (
        ("scripts/build/run.lua",),
        ("scripts/toolchain/install/build.lua",),
        ("scripts/toolchain/install/quality.lua",),
        ("scripts/workspace/bootstrap.lua",),
        ("scripts/process/playbook.lua", "--direct", "build"),
        ("scripts/process/playbook.lua", "build"),
    ):
        result = run(*args)
        assert result.returncode == 75, result.stderr
finally:
    stop(process)

result = run("scripts/workspace/clean.lua", "--scope=build")
assert result.returncode == 0, result.stderr
assert not sentinel.exists(), "kernel lease survived its killed owner"
assert (root / ".cache/locks/workspace.lock").is_file(), (
    "cleanup removed lock identity"
)
print(
    "Workspace locking: concurrent readers, exclusive cleanup, "
    "nesting and crash release passed."
)
]]
   )
   artifacts.run({
      "python3",
      root .. "/test.py",
      root,
      repository,
      arg[-1] or "lua",
   })
   artifacts.platform.remove_temporary_directory(root)
end

return LOCK_TEST_main()

-- EOF


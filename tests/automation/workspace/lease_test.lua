-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Exercise the macOS lease backend with actual competing POSIX processes.
-- @return nil: no values.
local function LEASE_TEST_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local root = artifacts.platform.temporary_directory("tests")
   local backend = dofile("scripts/workspace/lib/lease.lua")

   artifacts.document(
      root .. "/command.json",
      artifacts.array(backend.command("shared", root .. "/workspace.lock"))
   )
   artifacts.write(
      root .. "/test.py",
      [[
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time

root = Path(sys.argv[1])
command = json.loads((root / "command.json").read_text())
ready = root / "ready"


def argv(mode, script):
    return command[:-1] + [mode, sys.executable, "-c", script]


def contender(mode):
    return subprocess.run(argv(mode, "print('lease acquired')"),
                          capture_output=True, text=True, timeout=10)


def holder(mode):
    ready.unlink(missing_ok=True)
    script = ("import time; from pathlib import Path; "
              f"Path({str(ready)!r}).touch(); time.sleep(30)")
    process = subprocess.Popen(argv(mode, script), start_new_session=True)
    deadline = time.monotonic() + 10
    try:
        while not ready.exists():
            assert process.poll() is None, "lease owner exited early"
            assert time.monotonic() < deadline, "lease acquisition stalled"
            time.sleep(0.01)
    except BaseException:
        stop(process)
        raise
    return process


def stop(process):
    if process.poll() is None:
        os.killpg(process.pid, signal.SIGKILL)
    process.wait(timeout=5)


for mode in ("shared", "exclusive"):
    process = holder(mode)
    try:
        result = contender("shared")
        assert result.returncode == (0 if mode == "shared" else 75), result
        result = contender("exclusive")
        assert result.returncode == 75, result
    finally:
        stop(process)
    assert contender("exclusive").returncode == 0, "crashed owner held lease"

lock = root / "workspace.lock"
lock.unlink()
target = root / "retain"
target.write_text("untouched")
lock.symlink_to(target)
assert contender("exclusive").returncode != 0, "followed a lease symlink"
assert target.read_text() == "untouched"
print("POSIX lease: contention, shared access, exec, crash and symlink passed.")
]]
   )
   artifacts.run({ "python3", root .. "/test.py", root })
   artifacts.platform.remove_temporary_directory(root)
end

return LEASE_TEST_main()

-- EOF


-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Exercise runner preparation with isolated package sources and failed APT.
-- @return nil: raises if preparation hides a failure or removes required feeds.
local function BOOTSTRAP_TEST_main()
   local artifacts = dofile("scripts/lib/artifacts.lua")
   local platform = dofile("scripts/lib/platform.lua")
   local directory = platform.temporary_directory()
   local source = artifacts.read(".github/actions/bootstrap-ubuntu/action.yml")
   local body = assert(source:match("      run: |\n(.-)\n    %- name:"))
   local lines = {}

   for line in (body .. "\n"):gmatch("(.-)\n") do
      lines[#lines + 1] = line:gsub("^        ", "")
   end

   -- Redirect only fixed host paths; the production action has no test bypass.
   local script = table
      .concat(lines, "\n")
      :gsub("/etc/apt", directory .. "/apt")
      :gsub("/etc/os%-release", directory .. "/os-release")
   artifacts.write(directory .. "/bootstrap.sh", script)

   local fixture = [=[
set -euo pipefail
cd "$1"
mkdir -p bin apt/sources.list.d apt/apt.conf.d runner
export RUNNER_TEMP="$PWD/runner" GITHUB_OUTPUT="$PWD/outputs"
export PATH="$PWD/bin:$PATH"
printf 'ID=ubuntu\nVERSION_ID=24.04\n' >os-release
printf 'official distribution\n' >apt/sources.list.d/ubuntu.sources
printf 'unrelated Microsoft feed\n' >apt/sources.list.d/microsoft-prod.list
printf 'unrelated deb822 feed\n' >apt/sources.list.d/extra.sources
printf 'legacy feed\n' >apt/sources.list
cat >bin/sudo <<'STUB'
#!/bin/sh
exec "$@"
STUB
cat >bin/apt-cache <<'STUB'
#!/bin/sh
printf 'installed package versions\n'
STUB
cat >bin/apt-get <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >>apt-calls
test ! -f apt/sources.list.d/microsoft-prod.list || exit 99
test ! -f apt/sources.list.d/extra.sources || exit 99
test ! -f apt/sources.list || exit 99
if [ "$1" = "$FAIL_PHASE" ]; then
  printf 'simulated repository failure\n' >&2
  exit 100
fi
STUB
chmod +x bin/*

# Rejected host layouts must leave all package sources untouched.
printf 'ID=debian\nVERSION_ID=13\n' >os-release
if bash bootstrap.sh; then exit 1; fi
test -f apt/sources.list.d/microsoft-prod.list
test ! -f runner/libmemalloc-apt-ready
printf 'ID=ubuntu\nVERSION_ID=24.04\n' >os-release
mv apt/sources.list.d/ubuntu.sources ubuntu.sources
if bash bootstrap.sh; then exit 1; fi
test -f apt/sources.list.d/microsoft-prod.list
mv ubuntu.sources apt/sources.list.d/ubuntu.sources

# Update and installation errors must fail, keep diagnostics, and allow retry.
for phase in update install; do
  export FAIL_PHASE="$phase"
  : >outputs
  if bash bootstrap.sh; then exit 1; fi
  test ! -f runner/libmemalloc-apt-ready
  evidence="$(sed -n 's/^evidence=//p' outputs)"
  test -s "$evidence/bootstrap.log"
  grep -q 'simulated repository failure' "$evidence/bootstrap.log"
done
test -f apt/libmemalloc-disabled-sources/microsoft-prod.list
test -f apt/libmemalloc-disabled-sources/extra.sources
test -f apt/libmemalloc-disabled-sources/sources.list
grep -q 'official distribution' apt/sources.list.d/ubuntu.sources
grep -q 'APT::Update::Error-Mode "any"' apt/apt.conf.d/80libmemalloc
grep -q 'Acquire::Retries "3"' apt/apt.conf.d/80libmemalloc

export FAIL_PHASE=none
bash bootstrap.sh
test -f runner/libmemalloc-apt-ready

# Repeated setup must retain the explicitly added compiler feed and do no APT.
printf 'compiler PPA\n' >apt/sources.list.d/toolchain.sources
cp apt-calls before
bash bootstrap.sh
cmp before apt-calls
test -f apt/sources.list.d/toolchain.sources
]=]

   local success = platform.command_succeeded({
      "env",
      "FAIL_PHASE=none",
      "timeout",
      "30",
      "bash",
      "-c",
      fixture,
      "bootstrap-fixture",
      directory,
   })

   platform.remove_temporary_directory(directory)
   assert(success, "Ubuntu bootstrap regression failed")
   print("Ubuntu bootstrap: sources, failure evidence and repeat setup passed.")
end

return BOOTSTRAP_TEST_main()

-- EOF


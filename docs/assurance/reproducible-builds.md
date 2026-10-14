<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Reproducible and deterministic builds

The executable GitHub Actions implementation and the full upstream tool
applicability inventory are documented in [Reproducible Builds tool coverage](../runbooks/reproducibility.md).

This guide defines acceptance evidence for libmemalloc build outputs. The
current CI packages source and runs a Linux C release fixture with two clean
same-host builds. The additional tool workflow uses separate hosted VMs and
controlled environment variations for mock packages. Neither workflow qualifies
allocator binaries or an independently operated build provider.
The [implemented fixture](../runbooks/release-fixture.md) generates evidence using Lua.
The workflow models below remain design examples for broader qualification.

<details>
<summary><strong>On this page</strong></summary>

- [Definitions and scope](#definitions-and-scope)
- [RBUILD-001: Declared inputs and outputs](#rbuild-001)
- [RBUILD-002: Controlled environment](#rbuild-002)
- [RBUILD-003: Time, paths, and ordering](#rbuild-003)
- [RBUILD-004: Profiles and instrumentation](#rbuild-004)
- [RBUILD-005: Clean independent builds](#rbuild-005)
- [RBUILD-006: Comparison and diagnosis](#rbuild-006)
- [RBUILD-007: Evidence and distribution](#rbuild-007)
- [Workflow models](#workflow-models)
- [Compliance stages](#compliance-stages)
- [References](#references)

</details>

---

## Definitions and scope

**Class:** CORRECTNESS / SUPPLY_CHAIN. **Obligation:** project requirement.

A deterministic build produces identical selected bytes from its declared
inputs. Reproducibility additionally requires enough source, environment, and
instructions for another party to reconstruct those outputs. Define the output
set before comparing it; identical logs are not normally a requirement.
See [Reproducible Builds: definitions](https://reproducible-builds.org/docs/definition/).

A checksum identifies content. A signature authenticates a statement under a
trust policy. Neither alone demonstrates that the content was built from the
published source. Reproducibility does not prove memory safety or a trustworthy
compiler. These are separate evidence obligations.

The product contract is
[release reconstruction](../specs/libmemalloc-compilation-SDD.md#lma-build-014),
with [input trust](../specs/libmemalloc-security-SDD.md#lma-sec-010) and
[campaign evidence](../specs/libmemalloc-tests-SDD.md#lma-test-037).
The [CI reference](../reference/automation.md#cicd-010) describes the current boundary.

---

<a id="rbuild-001"></a>

## RBUILD-001: Declared inputs and outputs

**Class:** ANALYZABILITY. **Obligation:** project requirement.

The build manifest must identify the source commit and dirty-tree policy,
submodules or imported sources, generated inputs, tool binaries, sysroot,
linker, flags, target, ABI, enabled capabilities, and relevant environment.
Record dependency and profile digests in machine-readable build evidence.
Do not add narrative release histories to this guide.

List every required output and its packaging rules before execution. For a
future library, distinguish static archives, shared objects, headers, debug
files, symbol lists, and distribution packages. A missing expected file fails
the comparison; an empty output directory must never pass.

Use the [release identity and directory contract](openssf.md#ossf-010)
for future product outputs under `release/<arch>-<os>-<build-id>/`. Its shortened
input-manifest digest identifies the build; full per-file digests verify output
bytes. Keep independent attempt evidence separate from immutable published
roots. The [integrity sealing order](openssf.md#ossf-013) prevents
self-referential hashes and keeps signatures outside the deterministic payload.

Do not include generated coverage data, training logs, signatures with fresh
timestamps, or benchmark samples in the deterministic payload unless their
format has an explicit reproducibility contract. Preserve them as related
evidence with their own identities.

---

<a id="rbuild-002"></a>

## RBUILD-002: Controlled environment

**Class:** SUPPLY_CHAIN. **Obligation:** project requirement.

Freeze compiler, linker, archiver, build tools, Lua driver, sysroot, and
dependencies. A container reference must resolve to an approved immutable image
digest, with an available recipe and source for its tools. A mutable runner
label or package-manager index does not freeze those inputs.

Separate dependency acquisition from compilation. Verify downloads before the
build, then deny network access during the qualified build where feasible.
Use a fresh writable output directory and read-only inputs. A container shares
its host kernel; record relevant host behavior and do not call it a complete
virtual-machine environment.

Use fixed locale and timezone values when they are contract inputs. Set a
documented `umask`, control concurrency and random seeds where relevant, and
keep absolute host paths out of build metadata. Record tool versions from the
tools invoked, not merely the intended lock entries.

---

<a id="rbuild-003"></a>

## RBUILD-003: Time, paths, and ordering

**Class:** CORRECTNESS. **Obligation:** project requirement.

Derive `SOURCE_DATE_EPOCH` from a documented source timestamp, such as the
committer time of the selected commit. Pass it to tools that support the convention;
setting the variable does not repair a tool that ignores it. Do not use the
wall clock to generate product version strings.
See [SOURCE_DATE_EPOCH](https://reproducible-builds.org/docs/source-date-epoch/).

Normalize source and debug paths through qualified compiler options such as
`-ffile-prefix-map` and `-fdebug-prefix-map`. Verify debug output and diagnostics
still identify source correctly. Avoid `-march=native` for a portable profile;
the target must be declared. Control archive member order, file modes, ownership,
and timestamps. Use deterministic `ar`/`ranlib` modes where supported.

For source packaging, `git archive --format=tar` followed by `gzip -n` avoids
the original-name and timestamp metadata in gzip output. Pin and compare the actual tool
outputs: Git does not promise identical archives across all tool versions.
See [archive metadata](https://reproducible-builds.org/docs/archives/) and
[build paths](https://reproducible-builds.org/docs/build-path/).

---

<a id="rbuild-004"></a>

## RBUILD-004: Profiles and instrumentation

**Class:** CORRECTNESS. **Obligation:** project requirement.

Freeze the exact PGO or MemProf inputs used by a release. Preserve their training
source, workload, merge recipe, tool identity, and compatibility checks. Repeating
training is a different experiment from rebuilding with the same frozen profile.
Reject incompatible profile data instead of suppressing the diagnostic globally.

Keep sanitizer, coverage, fuzzing, and profiling-runtime artifacts separate from
the production library. A successful instrumented build does not satisfy the
core's no-libc or no-CRT contract. Inspect the optimized release's symbols and
dependencies after LTO. Follow the
[profile contract](../specs/libmemalloc-compilation-SDD.md#lma-build-023).

---

<a id="rbuild-005"></a>

## RBUILD-005: Clean independent builds

**Class:** VERIFICATION. **Obligation:** project requirement.

Build from clean source twice with separate writable trees and no shared output
cache. Vary an irrelevant input deliberately, such as the checkout path. Later
qualification should vary hostname, timezone, locale, directory order, wall
clock, and job count where those are not fixed contract inputs.

Two builds on one runner are a local determinism check. Independent reconstruction
requires another environment or rebuilder using the published instructions and
the same declared inputs. Changing the compiler is a separate qualification
experiment; different compilers need not produce identical machine code.

Use [reprotest](https://reproducible-builds.org/tools/) for controlled environment
variation where it supports the target. Treat it as a third-party tool; any
repository-owned orchestration remains Lua. Do not install a new tool into a
release build from an unpinned package source.

---

<a id="rbuild-006"></a>

## RBUILD-006: Comparison and diagnosis

**Class:** VERIFICATION. **Obligation:** project requirement.

Compare the declared payload byte for byte, including required debug files and
archive metadata. Check both the file inventory and file contents. Reject
unexpected output, missing output, unsafe symlinks, and path traversal before
processing downloaded artifacts.

On a mismatch, retain both outputs and a bounded diagnostic report. Use
[diffoscope](https://diffoscope.org/) to investigate nested formats. Run it in
isolation because input files can be hostile. Its explanation is not a passing
comparison: a known difference remains a failure until the build or output
contract is corrected through review. Never strip arbitrary differing bytes
from a release merely to obtain equal checksums.

---

<a id="rbuild-007"></a>

## RBUILD-007: Evidence and distribution

**Class:** SUPPLY_CHAIN. **Obligation:** project requirement.

Preserve source identity, input manifest, exact invocation, tool identities,
environment, output inventory, checksums, comparison result, and diagnostic logs.
Keep the independent reconstruction statement separate from the producer statement.
Publish a reconstruction recipe that does not require private caches or secrets.

Promote only the bytes that passed comparison and product qualification. Sign
or attest them in a separate trusted job after verification. The signer must
verify source, workflow identity, artifact digest, and permitted event; it must
not execute arbitrary files from an untrusted build. Publish verification
instructions and preserve evidence for the support lifetime.

An Actions artifact with 30-day retention is not a permanent release repository.
The current release workflow also starts after the GitHub release is published;
it is not a pre-publication control. Promotion must be redesigned before making
that guarantee or claiming [OpenSSF compliance](openssf.md).

---

## Workflow models

### Model A: source-package determinism

This complete example can be adapted into a separate Actions workflow. It
compares source archives from two fresh clones at different paths. It does not
qualify a binary, freeze the hosted image, or constitute an independent rebuilder.
The action pin is executable dependency configuration, not document metadata.

```yaml
name: Source package determinism

on:
  pull_request: {}
  workflow_dispatch: {}

permissions: {}

jobs:
  compare-source:
    runs-on: ubuntu-24.04
    timeout-minutes: 10
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1
        with:
          persist-credentials: false
          fetch-depth: 0
      - name: Repackage in separate trees
        shell: bash
        env:
          LC_ALL: C
          TZ: UTC
        run: |
          set -euo pipefail
          umask 022
          source_commit="$(git rev-parse HEAD)"
          work="$(mktemp -d "${RUNNER_TEMP}/source-rebuild.XXXXXX")"
          git clone --no-local --no-checkout . "${work}/first"
          git clone --no-local --no-checkout . "${work}/different-path"
          mkdir "${work}/evidence"
          for name in first different-path; do
            git -C "${work}/${name}" archive --format=tar \
              --prefix=libmemalloc/ "${source_commit}" \
              | gzip -n > "${work}/evidence/${name}.tar.gz"
          done
          git --version
          gzip --version
          sha256sum "${work}/evidence/"*.tar.gz
          cmp "${work}/evidence/first.tar.gz" \
            "${work}/evidence/different-path.tar.gz"
```

For persistent evidence, add a pinned artifact-upload action with a bounded
path and explicit retention. Upload diagnostic outputs on failure without
turning the failed comparison into success. Disable source export substitutions
or include their exact configuration in the packaging contract.

### Model B: frozen binary build environment

This reusable workflow is a design template, not runnable against the current
product tree. It requires `scripts/build/reproduce.lua`, an approved builder
image containing Lua and the qualified toolchain, and a fixed `product.tar`
output contract. The missing driver fails the job. Do not replace that check
with an empty success placeholder.

The proposed Lua driver must build without a network, validate output paths,
reject unexpected capabilities, retain logs, and package every declared product
file. It must compare no instrumentation or training output with release bytes.
The image is selected by trusted callers, never pull-request text. Digest
syntax validation does not establish publisher trust; approval of that digest
belongs to the dependency-review process.

```yaml
name: Binary reproducibility model

on:
  workflow_call:
    inputs:
      builder_image:
        required: true
        type: string

permissions: {}

jobs:
  compare-binary:
    runs-on: ubuntu-24.04
    timeout-minutes: 30
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1
        with:
          persist-credentials: false
      - name: Build and compare declared payloads
        shell: bash
        env:
          BUILDER_IMAGE: ${{ inputs.builder_image }}
        run: |
          set -euo pipefail
          test -f scripts/build/reproduce.lua
          [[ "${BUILDER_IMAGE}" =~ ^[a-z0-9./_-]+@sha256:[0-9a-f]{64}$ ]]
          source_commit="$(git rev-parse HEAD)"
          epoch="$(git show -s --format=%ct "${source_commit}")"
          work="$(mktemp -d "${RUNNER_TEMP}/binary-rebuild.XXXXXX")"
          docker pull "${BUILDER_IMAGE}"
          for attempt in first second; do
            mkdir -p "${work}/${attempt}/source" "${work}/${attempt}/out"
            git archive "${source_commit}" \
              | tar -xf - -C "${work}/${attempt}/source"
            docker run --rm --network=none --read-only \
              --cap-drop=ALL --security-opt=no-new-privileges \
              --user "$(id -u):$(id -g)" --pids-limit=256 \
              --memory=4g --cpus=2 --tmpfs /tmp:rw,nosuid,size=1g \
              --mount "type=bind,src=${work}/${attempt}/source,dst=/src,readonly" \
              --mount "type=bind,src=${work}/${attempt}/out,dst=/out" \
              --env "SOURCE_DATE_EPOCH=${epoch}" \
              --env LC_ALL=C --env TZ=UTC --workdir /src \
              --entrypoint lua "${BUILDER_IMAGE}" \
              scripts/build/reproduce.lua --output /out
            test -s "${work}/${attempt}/out/product.tar"
            test ! -L "${work}/${attempt}/out/product.tar"
          done
          sha256sum "${work}/first/out/product.tar" \
            "${work}/second/out/product.tar"
          cmp "${work}/first/out/product.tar" \
            "${work}/second/out/product.tar"
```

The same container path in both attempts tests repetition, not path independence.
Add qualified path-variation runs and a separate rebuilder before claiming
reproducibility. Add disk/output limits and isolated hosts for hostile code;
container CPU and memory limits do not bound all host resources. A release job
must consume verified outputs from a specific successful run, not an artifact
selected by name alone.

---

## Compliance stages

| Stage | Required work | Acceptance evidence | Current boundary |
| --- | --- | --- | --- |
| Inventory | Declare source, tools, profiles, and outputs | Reviewed manifest schema and recipe | Tool locks exist; product manifest pending |
| Determinism | Clean repeated builds with frozen inputs | Matching nonempty payloads and logs | Two clean fixture builds and comparison implemented; product evidence pending |
| Variation | Change irrelevant environment inputs | Recorded comparisons and resolved differences | Separate hosted fixture builds and controlled variations implemented; product coverage pending |
| Independent reconstruction | Give another builder the public recipe | Matching payload and independent statement | Not implemented |
| Release promotion | Qualify product and verify identical bytes before signing | Signed evidence bound to distributed payload | Mock publication and signing implemented; qualified product release pending |
| Continued conformance | Repeat on toolchain, target, or profile changes | Results for each supported tuple | Product matrix pending |

---

## References

- [Reproducible Builds documentation](https://reproducible-builds.org/docs/)
- [Reproducible Builds tools](https://reproducible-builds.org/tools/)
- [diffoscope](https://diffoscope.org/)
- [OpenSSF Gold criteria](https://www.bestpractices.dev/en/criteria/2)
- [libmemalloc compilation specification](../specs/libmemalloc-compilation-SDD.md)

<!-- EOF -->


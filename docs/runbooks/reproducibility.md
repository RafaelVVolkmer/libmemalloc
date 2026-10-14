<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Reproducible Builds tool coverage

<details>
<summary><strong>On this page</strong></summary>

- [Executable Actions contract](#executable-actions-contract)
- [Upstream catalog applicability](#upstream-catalog-applicability)
- [Evidence and local execution](#evidence-and-local-execution)

</details>

---

## Executable Actions contract

[Reproducible Builds tools](../../.github/workflows/reproducible.yml) runs through the required CI gate on
pushes and pull requests, as well as by manual dispatch and weekly schedule. It needs no user-created secrets
or Kubernetes. The scope is the implemented distribution mock, not an allocator correctness claim, a
certification, or independence from GitHub as a build provider.

Two jobs receive separate hosted VMs, prepare the same declared sources and build Debug/Release static/shared
install trees without compiler caches. Each builder records source hashes, the frozen epoch and actual tool
identities. The compiler must match its locked version. The four compressed packages include libraries,
headers, CMake metadata, pkg-config metadata and the license. Source timestamps, archive ownership, ordering
and permissions are inputs to the packaging recipe. Debug paths are mapped during compilation. These
transformations happen before comparison.

A third job requires the exact package inventory and equal SHA-256 digests. It runs diffoscope and preserves
text/HTML diagnostics on differences. Missing packages, unexpected files, tool failures and differing bytes
fail the gate. Some format comparators omit metadata; a diffoscope exit of zero cannot override different raw
hashes.

Reprotest has two explicit profiles from the [policy catalog](../../tools/reproducible/policy.lua):

- `environment`: build path, environment variables, locale, CPU availability, clock, timezone and umask.
- `filesystem`: disorderfs varies directory enumeration using FUSE. Missing FUSE fails the job; the workflow
  does not silently claim that variation passed.

These profiles do not vary the actual kernel, compiler version, hardware ISA, user/group identity or hostname.
Cross-toolchain semantics belong to the [qualification matrix](qualification.md). Add variations through
the catalog and qualify their host requirements before extending the claim.

The normalization job runs strip-nondeterminism, add-det, OSS-Rebuild stabilize and linkdupes on diagnostic
copies. It checks idempotence, extracted contents and preservation of original package hashes. Linkdupes tests
POSIX hardlinks; it explicitly does not qualify SELinux contexts on the Ubuntu runner. Normalized equality
cannot rescue a raw-package failure.

Tool versions or revisions live in [the shared lock](../../tools/toolchain/lock.toml). Apt
authenticates Ubuntu package metadata; Rust uses the published lockfile and Go resolves a pinned revision.
Hosted runner images and transitive operating-system packages are not a hermetic toolchain image.
Reconstructing historical environments still requires preserved package repositories or a separately pinned
image.

---

## Upstream catalog applicability

The [upstream tools page](https://reproducible-builds.org/tools/) describes the ecosystem.
This table records the repository integration and required inputs for each listed tool or family.

| Tool or family                                                     | Repository integration or prerequisite                                                                 |
| ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------ |
| diffoscope                                                         | Required comparison of original packages; negative detector fixture                                    |
| reprotest                                                          | Required controlled environment builds                                                                 |
| disorderfs                                                         | Required filesystem-order campaign on a hosted FUSE-capable runner                                     |
| strip-nondeterminism                                               | Gzip normalization and preservation tests on copies                                                    |
| OSS-Rebuild `stabilize`                                            | Pinned archive normalization on copies; no claim of using the hosted rebuilding service                |
| add-determinism (`add-det`)                                        | Pinned gzip handler; idempotence and content checks                                                    |
| linkdupes                                                          | Pinned hardlink check on copies; SELinux outside the qualified scope                                   |
| trydiffoscope                                                      | Optional external upload service; local diffoscope supplies diagnostics without uploading packages     |
| The Unreproducible Package                                         | Upstream educational corpus; local negative fixtures test detector failures                            |
| diffoci                                                            | Requires distributable OCI images; existing campaigns build mock library packages                      |
| `repro-build`                                                      | Requires an OCI build recipe and pinned image inputs                                                   |
| StageX                                                             | Alternative distribution/toolchain; requires a separately qualified compiler, sysroot and pinned image |
| reproducible-apk-tools, apksigcopier                               | Require Android APK outputs and, for signature copying, the signed upstream APK                        |
| Reproducible Build Maven Plugin, Reproducible Builds Gradle Plugin | Require JVM builds; no Maven or Gradle product exists here                                             |
| sbt-reproducible-builds                                            | Requires an sbt/Scala product                                                                          |
| ismypackagereproducibleyet                                         | Requires published distribution package identities                                                     |
| rebuilderd, Rebuilderd Website                                     | Require a package repository, rebuild backend and independently operated service                       |
| PackageRebuilder                                                   | Requires Debian/Fedora/Qubes packages and an in-toto deployment policy                                 |
| rbtlog                                                             | Android APK recipes and transparency-log deployment                                                    |
| Arch Linux repro, makerepropkg                                     | Require Arch packages and their build information                                                      |
| Debian `debrebuild.pl`, debrebuild                                 | Require Debian source packages and `.buildinfo` records                                                |
| fdroid-verification-server                                         | Requires F-Droid build metadata and an independent verification deployment                             |
| rpmreproduce                                                       | Requires RPM packages and build information                                                            |
| orb                                                                | Requires an opam package/build recipe                                                                  |
| ismyarchverifiedyet, Arch Repro Status                             | Query an Arch rebuilder service; they do not rebuild this source tree                                  |
| Builder-web                                                        | Requires a builder service and persistent artifact publication                                         |
| Trustix                                                            | Requires independent builders, trusted identities and a transparency-log service                       |
| apt-transport-in-toto, dnf-plugin-in-toto                          | Require package-manager repositories, signed layouts and authorized rebuilder identities               |
| Reproducible Builds website style guide                            | Website design guidance, not a build checker                                                           |

Entries with missing product inputs remain outside the executable coverage. Installing a frontend or reporting
its version does not establish that its rebuild or verification protocol ran. Distribution and service
adapters should be added when the corresponding package format, trust policy and deployment exist; they must
not be represented by successful placeholder jobs.

---

## Evidence and local execution

Actions uploads original packages, comparison diagnostics, reprotest build outputs and normalization reports.
The previous [release fixture checks](release-fixture.md) remain a separate contract. The new packages
do not silently replace a release candidate or receive its signatures.

On Ubuntu 24.04 with the locked dependencies installed:

```sh
lua scripts/reproducible/install.lua
lua scripts/reproducible/prepare.lua --output=.cache/reproducible/source
lua scripts/reproducible/vary.lua --profile=environment \
  --source=.cache/reproducible/source --output=.cache/reproducible/environment
lua scripts/reproducible/vary.lua --profile=filesystem \
  --source=.cache/reproducible/source --output=.cache/reproducible/filesystem
```

Use fresh output directories for every invocation. Reprotest requires permission to use its process
personality controls; the filesystem profile also requires `/dev/fuse`. A container without those facilities
is not an equivalent runner.

<!-- EOF -->


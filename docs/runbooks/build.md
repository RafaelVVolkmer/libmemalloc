<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Build a declared profile

For a local Debug/Release build with two installation comparisons, use the
[CMake build controller and presets](../reference/cmake-build.md). The campaign below covers the broader
language and platform matrix.

**Status:** implemented build matrix for the distribution mock.

<details>
<summary><strong>On this page</strong></summary>

- [Prerequisites and execution](#prerequisites-and-execution)
- [Campaign scope](#campaign-scope)
- [Evidence and acceptance](#evidence-and-acceptance)

</details>

---

## Prerequisites and execution

Use a host matching the selected profile in [matrix.lua](../../tools/build/matrix.lua), with its declared
tools installed. A Linux example follows; use a new output directory for each attempt.

```sh
lua scripts/toolchain/install/build.lua --profile=linux-gcc13
lua scripts/build/plan.lua --campaign=pr --profile=linux-gcc13 \
  --output=.cache/ci/build-review-001/plan.json
lua scripts/workspace/cache.lua lua scripts/build/run.lua --campaign=pr --profile=linux-gcc13 \
  --plan=.cache/ci/build-review-001/plan.json \
  --output=.cache/ci/build-review-001/results/linux-gcc13
lua scripts/build/report.lua --campaign=pr --profile=linux-gcc13 \
  --plan=.cache/ci/build-review-001/plan.json \
  --input=.cache/ci/build-review-001/results \
  --output=.cache/ci/build-review-001/report.json
```

The installer may require downloads or host packages; inspect its profile prerequisites before running it.
The planner selects expected cells; the build script retains commands and test evidence; the reporter checks
returned results against the expected work. Reports cover the mock contract and selected profile only.

---

## Campaign scope

For the complete platform matrix, use [build-matrix.yml](../../.github/workflows/build-matrix.yml), which
assigns profiles to their required operating systems. Its campaign choices are `pr`, `integration`, `nightly`
and `exhaustive`. The [nightly workflow](../../.github/workflows/build-nightly.yml) also requests clean builds.
The PR campaign selects 81 cells across seven profiles. It keeps Debug/Release for every contracted C
dialect and all requested C++ consumers, plus `O2`, `alias-strict`, and MSVC `o2`/`security` variants.
Integration retains 420 cells; nightly and exhaustive campaigns retain 606 cells across 13 profiles.
Selection is explicit in `pr_selection`; omitted cells do not become successful result records.

Flags do not imply experimental support. Every contracted cell is required unless its profile or variant
explicitly declares `support = "experimental"`. A capability failure for a required variant fails the gate.

---

## Evidence and acceptance

JUnit evidence is parsed structurally by the shared [validator](../../scripts/build/lib/junit.lua), on both
producer and consumer paths. The accepted XML profile is bounded UTF-8 XML 1.0 with ASCII element/attribute
names, comments, CDATA, predefined entities and numeric references. DTDs, namespaces and other processing
instructions are rejected. Tests must be real, unique elements with `status="run"`; suite counts must agree,
and failed/skipped/disabled tests are rejected. The canonical trace must be a complete line in `c-api`'s
`system-out`. File identity and SHA-256 remain separate checks. Neither XML validation nor a matching hash
establishes trust in the producer; hosted workflow and merge controls remain separate acceptance evidence.

See [qualification](qualification.md) for the separate semantic and PGO graph.

<!-- EOF -->


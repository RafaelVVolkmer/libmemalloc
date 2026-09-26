<!--
SPDX-FileCopyrightText: 2024-2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

<div align="center">

[![Semantic Versioning][semver-shield]][semver-url]
[![Keep A Changelog][changelog-shield]][changelog-url]

</div>

---

<div align="center">

<img
    src="/assets/images/libmemalloc_changelog.svg"
    alt="libmemalloc changelog logo"
    width="50%"
  />

</div>

---

# Changelog

All notable changes to this project will be documented in this file.

This changelog follows the structure of
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Release tags use the following format:

```text
vMAJOR.MINOR.PATCH
```

For the full versioning policy, see:
[Libmemalloc's Versioning Guide](docs/standards/versioning/versioning-guide.md).

Each released version must use the following changelog title pattern:

```md
## [vMAJOR.MINOR.PATCH] - YYYY-MM-DD — libmemalloc <fantasy_release_name>
```

The version must always be linked to the corresponding Git tag at the end of this file:

```md
[v0.2.0]: https://github.com/RafaelVVolkmer/libmemalloc/releases/tag/v0.2.0
```

The release date must use the
[ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html) calendar date
format:

```text
YYYY-MM-DD
```

Example:

```text
2026-05-05
```

Each release must also have a human-readable fantasy name. The release name
should be creative, memorable, and related to the main purpose of the release,
while keeping the Git tag itself strictly technical and SemVer-compatible.

Illustrative titles only; these versions and dates are not release records:

```md
## [v0.1.0] - 2026-05-05 — libmemalloc First Spark

## [v0.2.0] - 2026-06-01 — libmemalloc Runtime Forge

## [v0.3.0] - 2026-07-10 — libmemalloc Arena Bloom

## [v0.4.0] - 2026-08-15 — libmemalloc Collector Awakening

## [v1.0.0] - 2026-12-01 — libmemalloc Stable Flame
```

The entries below record completed changes. Proposed work belongs in the
[roadmap](ROADMAP.md) and specifications, not the release history.

---

## [Unreleased]

### Documentation

- Establish governance, ownership, community conduct, security reporting,
  support, contribution and review procedures.
- Document commit, branch, version and signature conventions.
- Add C engineering guides for code, modules, documentation, failure scenarios,
  compliance evidence and formal verification.
- Add the project logo and document the visual style.
- Add Rust and Lua engineering standards.
- Separate contributor setup into host dependencies, Python and Ansible,
  repository setup and daily commands; include Debian 12/13 instructions.
- Explain the planned core without stdlib or external heap allocations,
  distinguishing resource ownership from zero memory consumption.
- Track M0 dependencies and acceptance evidence in the roadmap.

### Tooling

- Add repository ignore rules, Git file attributes and EditorConfig policy.
- Add community issue and pull request templates.
- Add GPL-3.0-only license files and REUSE metadata.

### Migration Notes

These entries describe repository setup and documentation. They do not announce
an allocator release or changes to a supported allocation API.

---

<!-- ======================================================================= -->
<!-- Versions		                                                     -->
<!-- ======================================================================= -->

[Unreleased]: https://github.com/RafaelVVolkmer/libmemalloc

<!-- ======================================================================= -->
<!-- Standards Badge References                                              -->
<!-- ======================================================================= -->

[semver-shield]: https://img.shields.io/badge/SemVer-2.0.0-3F4551?style=flat-square&logo=semver&logoColor=white&labelColor=1F2328
[semver-url]: https://semver.org/

[changelog-shield]: https://img.shields.io/badge/Keep%20A%20Changelog-1.1.0-E05735?style=flat-square&logo=keepachangelog&logoColor=white&labelColor=1F2328
[changelog-url]: https://keepachangelog.com/en/1.1.0/

<!-- EOF -->


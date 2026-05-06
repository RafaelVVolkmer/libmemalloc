<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Versioning Guide

> [!NOTE]
> Reference specification:
>
> This versioning guideline is based on [Semantic Versioning 2.0.0][semver-url].
>
> `libmemalloc` uses semantic versions to communicate release compatibility,
> public API stability, and the expected migration impact for users.

---

## Version Format

Versions use the following format:

```text
MAJOR.MINOR.PATCH
```

Each field has a specific meaning:

| Field   | Bump when                                                                                                              | Example            |
| ------- | ---------------------------------------------------------------------------------------------------------------------- | ------------------ |
| `MAJOR` | A backward-incompatible public API, ABI, CLI, configuration, file format, or documented behavior change is introduced. | `1.4.2` -> `2.0.0` |
| `MINOR` | A backward-compatible feature, public API addition, or deprecation notice is introduced.                               | `1.4.2` -> `1.5.0` |
| `PATCH` | A backward-compatible bug fix, maintenance correction, documentation correction, or test correction is introduced.     | `1.4.2` -> `1.4.3` |

The release version must be selected from the highest-impact change included
since the previous release. For example, if a release contains both a bug fix
and a new compatible feature, the release is a `MINOR` release.

---

## Pre-1.0.0 Versions

Versions below `1.0.0` represent initial development:

```text
0.y.z
```

During this phase, the public API is not considered stable, and incompatible
changes may still happen as the project evolves.

Recommended project policy:

| Version range           | Meaning                                                              |
| ----------------------- | -------------------------------------------------------------------- |
| `0.x.y`                 | Initial development. APIs, internals, and behavior may still change. |
| `1.0.0`                 | First stable public API release.                                     |
| `x.y.z`, where `x >= 1` | Stable versioning rules apply strictly.                              |

---

## Pre-release Versions

Pre-release versions are used for unstable previews, validation builds, and
release candidates.

Format:

```text
MAJOR.MINOR.PATCH-prerelease
```

Examples:

```text
0.1.0-alpha.1
0.1.0-beta.1
1.0.0-rc.1
```

| Identifier | Meaning                                                                |
| ---------- | ---------------------------------------------------------------------- |
| `alpha.N`  | Early preview. APIs and behavior may still change.                     |
| `beta.N`   | Feature-complete preview. Bugs may still be fixed before release.      |
| `rc.N`     | Release candidate. Intended to become stable if no blockers are found. |

A pre-release version has lower precedence than the corresponding stable
version.

Example:

```text
1.0.0-rc.1 < 1.0.0
```

---

## Build Metadata

Build metadata may be appended with `+`.

Format:

```text
MAJOR.MINOR.PATCH+metadata
```

Examples:

```text
1.0.0+20260505
1.0.0+git.abc1234
1.0.0-rc.1+build.42
```

Build metadata identifies a specific build, revision, or packaging context, but
it does not change version precedence.

---

## Release Selection Rule

Use the highest-impact change to decide the next version:

```text
if any change breaks public compatibility:
    bump MAJOR
else if any change adds compatible public functionality:
    bump MINOR
else if any change fixes behavior or improves compatibility:
    bump PATCH
else if a release is still needed for documentation, tooling, or metadata:
    bump PATCH
else:
    do not publish a new release
```

---

## Tag Format

Release tags should use a leading `v`:

```text
vMAJOR.MINOR.PATCH
```

Examples:

```text
v0.1.0
v0.2.0-alpha.1
v1.0.0
v1.1.0
v2.0.0
```

---

## Quick Summary

```text
MAJOR      -> incompatible public change
MINOR      -> compatible public feature or deprecation
PATCH      -> compatible fix or maintenance correction
0.y.z      -> initial development
1.0.0      -> first stable public API
-alpha.N   -> early preview
-beta.N    -> feature-complete preview
-rc.N      -> release candidate
+metadata  -> build metadata, no precedence change
```

---

## Commit & SemVer Meaning

Conventional Commits gives direct semantic-versioning meaning to these cases:

| Token             | Meaning                                                   | SemVer impact |
| ----------------- | --------------------------------------------------------- | ------------- |
| `fix`             | A bug fix.                                                | `PATCH`       |
| `feat`            | A new feature.                                            | `MINOR`       |
| `BREAKING CHANGE` | A breaking API or behavior change.                        | `MAJOR`       |
| `BREAKING-CHANGE` | Synonym of `BREAKING CHANGE` when used as a footer token. | `MAJOR`       |
| `!`               | Marks a breaking change in the commit prefix.             | `MAJOR`       |

A breaking change can be part of any commit type.

Examples:

```text
feat(api)!: rename MEM_alloc to MEM_malloc

BREAKING CHANGE: The internal heap metadata layout is incompatible with
previous debug tooling.
```

---

## Versioning Checklist

Before publishing a release, verify:

- [ ] the selected version follows `MAJOR.MINOR.PATCH`;
- [ ] breaking public changes bump `MAJOR`;
- [ ] compatible public features bump `MINOR`;
- [ ] compatible fixes and maintenance releases bump `PATCH`;
- [ ] pre-release identifiers use `alpha.N`, `beta.N`, or `rc.N`;
- [ ] build metadata, when used, appears after `+`;
- [ ] the release tag uses `vMAJOR.MINOR.PATCH`;
- [ ] Conventional Commit history matches the selected version bump;
- [ ] `BREAKING CHANGE:` footers are reflected in release notes;
- [ ] release notes and changelog mention API, ABI, and migration impact.

---

<!-- ======================================================================= -->
<!-- References                                                              -->
<!-- ======================================================================= -->

[semver-url]: https://semver.org

<!-- EOF -->

<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# GitFlow Guide

> [!NOTE]
> Reference specification:
>
> This branching guideline is based on the GitFlow model introduced by
> Vincent Driessen and commonly documented as a release-oriented workflow.
>
> - [A successful Git branching model][gitflow-url]

---

## Branch Model

GitFlow separates long-lived integration branches from short-lived work
branches.

Recommended permanent branches:

| Branch    | Purpose                                                                     |
| --------- | --------------------------------------------------------------------------- |
| `main`    | Stable production history. Every release tag is created from this branch.   |
| `develop` | Integration branch for the next release. Feature branches merge here first. |

Recommended temporary branches:

| Branch pattern      | Branches from | Merges into          | Purpose                                           |
| ------------------- | ------------- | -------------------- | ------------------------------------------------- |
| `feature/<name>`    | `develop`     | `develop`            | Isolated development for a new feature or change. |
| `release/<version>` | `develop`     | `main` and `develop` | Final stabilization before a release.             |
| `hotfix/<version>`  | `main`        | `main` and `develop` | Urgent fix for a released version.                |
| `support/<series>`  | `main`        | project-defined      | Optional maintenance line for older versions.     |

---

## Branch Naming

Use lowercase names with hyphens.

Recommended examples:

```text
feature/gc-runtime-state-machine
feature/allocator-free-list-validation
release/v0.2.0
hotfix/v0.2.1
support/v1.x
```

Avoid vague names:

```text
feature/misc
feature/fixes
feature/wip
```

---

## Feature Branches

Feature branches are used for ordinary development.

Create a feature branch from `develop`:

```sh
git switch develop
git pull origin develop
git switch -c feature/gc-runtime-state-machine
```

Commit using the project commit style:

```sh
git commit -s -S -m "feat(gc): add runtime state machine"
```

When ready, merge the feature branch back into `develop` through a pull
request.

Recommended policy:

- keep each feature branch focused on one logical topic;
- rebase or merge from `develop` before opening a pull request;
- require passing CI before merge;
- require DCO sign-off;
- prefer signed commits;
- delete the branch after merge.

---

## Release Branches

Release branches are created when `develop` is ready to be stabilized.

Create a release branch from `develop`:

```sh
git switch develop
git pull origin develop
git switch -c release/v0.2.0
```

Use the release branch for:

- final documentation updates;
- changelog updates;
- version number updates;
- release candidate fixes;
- final CI and compliance checks.

Do not add unrelated features to a release branch.

Finish a release by merging into `main` and tagging the result:

```sh
git switch main
git pull origin main
git merge --no-ff release/v0.2.0
git tag -s v0.2.0 -m "libmemalloc v0.2.0"
git push origin main
git push origin v0.2.0
```

Then merge the release branch back into `develop`:

```sh
git switch develop
git pull origin develop
git merge --no-ff release/v0.2.0
git push origin develop
```

Finally, delete the release branch:

```sh
git branch -d release/v0.2.0
git push origin --delete release/v0.2.0
```

---

## Hotfix Branches

Hotfix branches are used for urgent fixes to already released versions.

Create a hotfix branch from `main`:

```sh
git switch main
git pull origin main
git switch -c hotfix/v0.2.1
```

Apply only the urgent fix, then merge into `main` and tag the patch release:

```sh
git switch main
git merge --no-ff hotfix/v0.2.1
git tag -s v0.2.1 -m "libmemalloc v0.2.1"
git push origin main
git push origin v0.2.1
```

Then merge the hotfix into `develop`:

```sh
git switch develop
git pull origin develop
git merge --no-ff hotfix/v0.2.1
git push origin develop
```

If a `release/<version>` branch is active, merge the hotfix into that release
branch as well.

---

## GitFlow Release Checklist

Before publishing a release:

- [ ] `develop` contains the intended release content;
- [ ] `release/<version>` was created from `develop`;
- [ ] version metadata was updated;
- [ ] changelog was updated;
- [ ] CI passes;
- [ ] DCO sign-off checks pass;
- [ ] commits or merge commits are signed when required;
- [ ] release artifacts are generated from the release tag;
- [ ] the release tag is signed;
- [ ] SBOM and provenance files are generated when applicable;
- [ ] Cosign signatures or attestations are published when applicable;
- [ ] `release/<version>` was merged into `main`;
- [ ] `release/<version>` was merged back into `develop`.

---

## GitFlow Policy for libmemalloc

Recommended policy:

| Rule         | Requirement                                                  |
| ------------ | ------------------------------------------------------------ |
| `main`       | Protected branch. Only release merges and hotfixes.          |
| `develop`    | Protected integration branch. All features merge here first. |
| `feature/*`  | Must branch from `develop`.                                  |
| `release/*`  | Must branch from `develop`.                                  |
| `hotfix/*`   | Must branch from `main`.                                     |
| release tags | Must use `vMAJOR.MINOR.PATCH`.                               |
| release tags | Should be signed with GPG/OpenPGP.                           |
| commits      | Must use Conventional Commits.                               |
| commits      | Must include DCO `Signed-off-by`.                            |
| artifacts    | Should be signed or attested with Cosign when published.     |

Use GitFlow when the project needs explicit release preparation, release
candidates, hotfixes, and long-lived stable release history.

---

## GitFlow Checklist

Before merging work through GitFlow, verify:

- [ ] feature branches start from `develop`;
- [ ] release branches start from `develop`;
- [ ] hotfix branches start from `main`;
- [ ] branch names use lowercase words separated by hyphens;
- [ ] unrelated features are not added to release branches;
- [ ] release branches are merged into both `main` and `develop`;
- [ ] hotfix branches are merged into both `main` and `develop`;
- [ ] release tags are created from `main`;
- [ ] release tags use the `vMAJOR.MINOR.PATCH` format;
- [ ] release tags are signed when publishing a release.

---

<!-- ======================================================================= -->
<!-- References                                                              -->
<!-- ======================================================================= -->

[gitflow-url]: https://nvie.com/posts/a-successful-git-branching-model/

<!-- EOF -->

<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->
<!-- markdownlint-disable MD013 MD033 MD041 -->

---

<div align="center">

<img
    src="../../readme/images/libmemalloc_project_workflow.svg"
    alt="libmemalloc project workflow logo"
    width="50%"
  />

</div>

---

## > Workflow Purpose

This directory documents the project workflows used by `libmemalloc`.

These guides define how the repository is maintained, how changes are
submitted, how releases are versioned, and how provenance is recorded across
commits, tags, and release artifacts.

The workflow documentation is designed to keep repository operations:

- consistent;
- reviewable;
- traceable;
- reproducible;
- versioned;
- signed when required;
- aligned with the project release policy.

---

## > Workflow Guides

The table below summarizes the repository workflows related to coworking and
versioning.

In the current tree, the detailed workflow guides in this directory are the
versioning guides under `versioning/`.

| Guide                                                      | Use for                                                                                                                |
| ---------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| [Commit Message Guide](versioning/commit-message-guide.md) | Required commit message structure, Conventional Commits usage, trailers, DCO sign-off, and structured commit metadata. |
| [GitFlow Guide](versioning/gitflow-guide.md)               | Branching model, feature branches, release branches, hotfix branches, and release flow.                                |
| [Signature Guide](versioning/signature-guide.md)           | DCO sign-off, GPG/OpenPGP commit and tag signing, and Cosign/Sigstore artifact signing.                                |
| [Versioning Guide](versioning/versioning-guide.md)         | Semantic Versioning rules, release tag format, pre-release rules, and version selection policy.                        |

---

## > Workflow Checklist

Before submitting or publishing repository changes, verify:

- [ ] the relevant workflow guide was followed for the change being made;
- [ ] commit messages use the required project format;
- [ ] branch names and merge targets follow the GitFlow policy;
- [ ] version bumps match the effective SemVer impact;
- [ ] DCO sign-off, commit signing, or artifact signing rules were applied
      when required;
- [ ] release tags, release notes, and related metadata are consistent.

---

<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

<div align="center">

[![GitHub CODEOWNERS][codeowners-shield]][codeowners-url]
[![Governance][governance-shield]][governance-url]
[![Maintainers Reference][maintainers-reference-shield]][maintainers-reference-url]

</div>

---

<div align="center">

<img
    src="/readme/images/libmemalloc_maintainers.svg"
    alt="libmemalloc maintainers logo"
    width="50%"
  />

</div>

---

## > Maintainers Purpose

This file is the human-readable maintainer map for `libmemalloc`.

It explains who currently maintains the repository, how maintainership relates
to ownership and review, and how maintainer responsibilities should be handled
over time.

This file should stay consistent with:

- `.github/CODEOWNERS`
- `GOVERNANCE.md`
- `SECURITY.md`
- `.github/CONTRIBUTING.md`

---

## > Current Maintainers

The current maintainer set for this repository is:

- Name: Rafael V. Volkmer
- GitHub ID: `@RafaelVVolkmer`
- Scope: whole repository
- Contact: `rafael.v.volkmer@gmail.com`
- Status: active

At the moment, this repository is maintained by a single active maintainer.

---

## > Maintainer Scope

The current maintainer scope covers the whole repository, including:

- source code and allocator behavior;
- build, CI, tooling, and release workflows;
- documentation and community process files;
- security handling and disclosure coordination;
- ownership, review, and governance updates.

Path-specific ownership is defined in `.github/CODEOWNERS`.

---

## > Maintainer Responsibilities

Maintainers are responsible for protecting the long-term health of the project.

Maintainers should:

- define and protect project direction and scope;
- review changes or delegate review appropriately;
- enforce review, testing, and CI expectations;
- keep security-sensitive handling aligned with `SECURITY.md`;
- approve releases and release-process changes;
- approve ownership and governance changes;
- keep important project risks visible;
- avoid silent bypasses of testing, review, or ownership rules;
- document significant decisions and policy changes;
- keep the repository sustainable for contributors and users.

Maintainers may reject changes that are technically valid but harmful to the
project's maintainability, portability, safety, compatibility, or long-term
direction.

---

## > Relationship to CODEOWNERS

This repository uses `.github/CODEOWNERS` as the path-based ownership map.

Current ownership is effectively:

```text
*                         @RafaelVVolkmer
/.github/                 @RafaelVVolkmer
/docs/                    @RafaelVVolkmer
/LICENSES/                @RafaelVVolkmer
/readme/                  @RafaelVVolkmer
/CHANGELOG.md             @RafaelVVolkmer
/CODE_OF_CONDUCT.md       @RafaelVVolkmer
/GOVERNANCE.md            @RafaelVVolkmer
/LICENSE                  @RafaelVVolkmer
/README.md                @RafaelVVolkmer
/SECURITY.md              @RafaelVVolkmer
```

Maintainers and code owners are related but not identical concepts:

- `CODEOWNERS` controls path-based review routing;
- maintainers are responsible for overall project stewardship;
- a maintainer may also be a reviewer, release owner, documentation owner, or
  security contact in a small project.

---

## > Role Mapping

The governance file currently maps the following roles to the same primary
owner:

- Maintainer
- Reviewer
- Security Contact
- Release Owner
- Documentation Owner
- Tooling Owner
- Community Steward

For the canonical role table, see `GOVERNANCE.md`.

---

## > How to Contact a Maintainer

Primary maintainer contact:

```text
Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
```

Preferred public channels:

- GitHub Issues for concrete bugs, documentation problems, and feature requests
- GitHub Discussions for usage questions and broad design conversations
- Private email for security-sensitive reports as described in `SECURITY.md`

---

## > How to Become a Maintainer

Maintainership should be granted deliberately and based on sustained project
trust, not on a single pull request or one-time contribution.

Signals that someone may be ready for maintainership include:

- repeated high-quality contributions across time;
- consistent, technically sound review feedback;
- good judgment around scope, stability, and project direction;
- ability to communicate clearly and respectfully in public threads;
- reliability in follow-through for reviews, fixes, and documentation;
- willingness to maintain process, not only code.

Typical path:

1. Contribute useful changes consistently.
2. Participate constructively in reviews and technical discussions.
3. Demonstrate understanding of project standards and ownership boundaries.
4. Earn trust in one or more repository areas.
5. Be proposed and approved through the governance process.

Changes to the maintainer set should be reflected in `GOVERNANCE.md`,
`.github/CODEOWNERS`, and this file when applicable.

---

## > Maintainer Expectations

Maintainers are expected to:

- respond to project-critical requests within a reasonable time;
- avoid unnecessary review bottlenecks;
- keep process decisions visible and explainable;
- handle contributor friction with professionalism;
- respect the Code of Conduct and enforce it consistently;
- escalate or defer risky changes when review confidence is insufficient.

Maintainers should also be careful not to create hidden dependency on private
knowledge or undocumented decisions.

---

## > Inactivity and Rotation

Inactivity should be handled respectfully, but it must not leave the project
blocked.

A maintainer may be considered inactive when they are not responding to
project-critical review, release, security, or governance needs for a
reasonable period.

Suggested process:

1. Contact the maintainer publicly in the relevant issue or pull request.
2. Contact privately if appropriate.
3. Wait a reasonable response period.
4. Reassign urgent responsibilities temporarily if needed.
5. Update roles and ownership if inactivity continues.
6. Record the change in `GOVERNANCE.md` or a governance issue.

---

## > Emeritus or Former Maintainers

This file may later include an emeritus section if the maintainer set grows and
then changes over time.

No emeritus maintainers are currently listed.

---

## > Review and Decision Boundaries

Maintainers should use the smallest amount of process necessary to protect the
project, while still ensuring:

- adequate technical review;
- ownership-aware approvals;
- safe handling of release and security changes;
- sustainable maintainer workload;
- clear final accountability when consensus stalls.

When normal discussion does not converge, the maintainer may need to make a
documented final decision consistent with `GOVERNANCE.md`.

---

## > Attribution

This maintainers file follows the repository style used in `SUPPORT.md`,
`ROADMAP.md`, and `REVIEWING.md` and is informed by:

- GitHub Docs: "About code owners"
- the repository's `GOVERNANCE.md`
- the repository's `.github/CODEOWNERS`
- QEMU documentation on the role of maintainers
- Hyperledger sample `MAINTAINERS.md`

Reference links:

- <https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners>
- <https://www.qemu.org/docs/master/devel/maintainers.html>
- <https://toc.hyperledger.org/guidelines/SAMPLE-MAINTAINERS.html>

---

<!-- ======================================================================= -->
<!-- Maintainers Badge References                                            -->
<!-- ======================================================================= -->

[codeowners-shield]: https://img.shields.io/badge/GitHub-CODEOWNERS-2F81F7?style=flat-square&logo=github&logoColor=white&labelColor=1F2328
[codeowners-url]: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners

[governance-shield]: https://img.shields.io/badge/Project-Governance-3FB950?style=flat-square&logo=gitbook&logoColor=white&labelColor=1F2328
[governance-url]: ./GOVERNANCE.md

[maintainers-reference-shield]: https://img.shields.io/badge/Open%20Source-Maintainers%20Reference-2F81F7?style=flat-square&logo=opensourceinitiative&logoColor=white&labelColor=1F2328
[maintainers-reference-url]: https://www.qemu.org/docs/master/devel/maintainers.html

<!-- EOF -->

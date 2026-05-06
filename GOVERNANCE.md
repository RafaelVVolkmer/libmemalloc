<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

<div align="center">

[![Governance][governance-shield]][governance-url]
[![Governance.md][governance-md-shield]][governance-md-url]
[![SustainOSS][sustainoss-shield]][sustainoss-url]
[![Decision Model][decision-shield]][decision-url]

</div>

---

<div align="center">

<img
    src="/readme/images/libmemalloc_governance.svg"
    alt="libmemalloc governance logo"
    width="50%"
  />

</div>

---

<a id="governance-purpose"></a>

## > Governance Purpose

The `libmemalloc` project uses this document to define how project decisions are
made, reviewed, approved, recorded, and updated.

Governance exists to keep the project:

- technically consistent;
- maintainable over time;
- transparent to contributors;
- predictable for maintainers;
- clear about who can approve changes;
- clear about who owns project areas;
- sustainable as the project grows.

This document is based on a lightweight open-source governance model and uses
the [SustainOSS Governance Readiness Checklist][sustainoss-url] as a reference
for reviewing whether project governance is clear, healthy, and sustainable.

It also cites the [Governance.md Guide][governance-md-url] as a general
reference for documenting open-source project governance.

This document does not create a legal entity, foundation, board, or formal
membership structure. It defines repository-level governance for project
maintenance, contributions, reviews, releases, ownership, and decision-making.

---

<a id="project-values"></a>

## > Project Values

The `libmemalloc` governance model values:

- technical accuracy;
- respectful disagreement;
- clear ownership;
- transparent decisions;
- maintainable and portable C code;
- secure and responsible engineering;
- reproducible releases;
- proper attribution and licensing;
- sustainable maintainer workload;
- practical process over bureaucracy.

The project should avoid hidden decisions, unclear ownership, unreviewed critical
changes, and silent bypasses of normal project review.

---

<a id="scope"></a>

## > Scope

This governance document applies to official project spaces and activities,
including:

- GitHub issues;
- pull requests;
- discussions;
- code reviews;
- commits and commit messages;
- documentation;
- release notes;
- project-maintained communication channels;
- public communication when representing the project.

It applies to:

- maintainers;
- reviewers;
- contributors;
- release owners;
- security contacts;
- documentation owners;
- tooling owners;
- community stewards;
- anyone proposing a project-level change.

This document complements, but does not replace:

| Document             | Purpose                                         |
| -------------------- | ----------------------------------------------- |
| `README.md`          | Explains what the project is and how to use it. |
| `CONTRIBUTING.md`    | Explains how to contribute.                     |
| `CODE_OF_CONDUCT.md` | Defines expected behavior and enforcement.      |
| `SECURITY.md`        | Defines vulnerability reporting and handling.   |
| `CODEOWNERS`         | Defines path-based review ownership.            |

---

<a id="governance-readiness-model"></a>

## > Governance Readiness Model

The project uses the SustainOSS Governance Readiness framework as a recurring
checklist.

The framework is interpreted through three dimensions:

| Dimension          | Project interpretation                                                                                                                                    |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Day-to-day         | How the project makes decisions, reviews pull requests, approves releases, assigns owners, and handles normal maintenance.                                |
| Barriers and Needs | What can block healthy governance, such as unclear ownership, maintainer overload, missing reviewers, unresolved conflicts, or unclear release authority. |
| Interventions      | What the project does when normal governance is not working, such as escalation, release freeze, owner rotation, or policy update.                        |

A governance readiness review should happen:

- before a major release;
- when a maintainer is added or removed;
- when a maintainer becomes inactive;
- after a serious release failure;
- when contributors report that decision-making is unclear;
- when review or release work is repeatedly blocked.

---

<a id="governance-principles"></a>

## > Governance Principles

The project follows these governance principles:

| Principle                 | Meaning                                                                                               |
| ------------------------- | ----------------------------------------------------------------------------------------------------- |
| Transparency              | Important decisions should be visible in issues, pull requests, discussions, or decision records.     |
| Traceability              | Significant technical and release decisions should have a durable record.                             |
| Maintainer accountability | Maintainers may make final decisions, but those decisions should be explainable and reviewable.       |
| Least necessary process   | Use the smallest process that still protects users, contributors, maintainers, quality, and security. |
| Clear ownership           | Critical project areas should have explicit owners.                                                   |
| Security awareness        | Security-relevant changes require explicit review.                                                    |
| Sustainable maintenance   | Governance should reduce bottlenecks and avoid relying on unclear or unavailable ownership.           |

---

<a id="roles"></a>

## > Roles

A person may hold more than one role. In a small project, one maintainer may
temporarily hold several roles, but ownership gaps should remain visible.

| Role                | Responsibility                                                                                     |
| ------------------- | -------------------------------------------------------------------------------------------------- |
| Maintainer          | Owns final technical direction, roadmap, merges, releases, and governance.                         |
| Reviewer            | Reviews code, documentation, tests, portability, maintainability, and design.                      |
| Security Contact    | Coordinates vulnerability reports, private fixes, advisories, and security releases.               |
| Release Owner       | Runs release checks, verifies release readiness, publishes release notes, and publishes artifacts. |
| Documentation Owner | Reviews user-facing and developer-facing documentation.                                            |
| Tooling Owner       | Maintains CI, linters, analyzers, scripts, and repository automation.                              |
| Community Steward   | Watches for contributor friction, unclear processes, onboarding gaps, and governance barriers.     |

---

<a id="current-role-assignments"></a>

## > Current Role Assignments

| Role                | Primary owner                                  | Backup owner |
| ------------------- | ---------------------------------------------- | ------------ |
| Maintainer          | [Rafael V. Volkmer][rafaelvvolkmer-github-url] | TBD          |
| Reviewer            | [Rafael V. Volkmer][rafaelvvolkmer-github-url] | TBD          |
| Security Contact    | [Rafael V. Volkmer][rafaelvvolkmer-github-url] | TBD          |
| Release Owner       | [Rafael V. Volkmer][rafaelvvolkmer-github-url] | TBD          |
| Documentation Owner | [Rafael V. Volkmer][rafaelvvolkmer-github-url] | TBD          |
| Tooling Owner       | [Rafael V. Volkmer][rafaelvvolkmer-github-url] | TBD          |
| Community Steward   | [Rafael V. Volkmer][rafaelvvolkmer-github-url] | TBD          |

---

<a id="maintainer-responsibilities"></a>

## > Maintainer Responsibilities

Maintainers are responsible for protecting the long-term health of the project.

Maintainers should:

- define project direction and scope;
- review or delegate review of pull requests;
- enforce required CI and review rules;
- approve releases;
- approve governance changes;
- approve changes to security, release, contribution, and ownership policies;
- keep unresolved project risks visible;
- avoid silent bypasses of review or testing;
- document significant decisions;
- keep the project sustainable for contributors and maintainers.

Maintainers may reject changes that are technically correct but harmful to the
project's maintainability, portability, security, compatibility, or long-term
direction.

---

<a id="reviewer-responsibilities"></a>

## > Reviewer Responsibilities

Reviewers are responsible for checking whether a change is:

- technically correct;
- maintainable;
- portable;
- consistent with project architecture;
- consistent with the coding style;
- covered by appropriate tests;
- documented when behavior changes;
- compatible with public API and ABI expectations;
- free from obvious security, memory, concurrency, or portability regressions.

A reviewer may request additional review from a project owner when the change
affects:

- public API;
- public ABI;
- memory allocator behavior;
- platform support;
- dependency policy;
- security behavior;
- build or CI infrastructure;
- release process;
- governance policy.

---

<a id="decision-process"></a>

## > Decision Process

The default decision model is:

```text
technical discussion
    -> rough consensus
        -> maintainer decision when needed
            -> documented rationale for significant decisions
```

Consensus is preferred, but unanimous agreement is not required.

A maintainer may make the final decision when:

- consensus cannot be reached;
- the decision is blocking progress;
- the issue affects project direction;
- the issue affects compatibility, maintainability, release timing, or security;
- the issue requires a clear owner.

Important decisions should be recorded in one of:

- an issue;
- a pull request comment;
- a discussion;
- a decision record;
- a release checklist;
- a security advisory.

---

<a id="decision-records"></a>

## > Decision Records

Use a decision record or governance issue when a decision affects:

- public API or ABI;
- architecture;
- allocator behavior;
- supported platforms;
- memory model assumptions;
- release process;
- dependency policy;
- coding style;
- governance model.

Suggested decision record format:

```md
# DR-NNN: Decision Title

## Status

Proposed / Accepted / Rejected / Superseded

## Context

Why this decision is needed.

## Decision

What the project decided.

## Consequences

Expected benefits, costs, risks, and trade-offs.

## Links

Related issues, pull requests, tests, benchmarks, or release records.
```

---

<a id="pull-request-governance"></a>

## > Pull Request Governance

A pull request should be classified before review.

| Change type                | Required review                                          |
| -------------------------- | -------------------------------------------------------- |
| Documentation-only         | One reviewer or maintainer                               |
| Internal implementation    | One reviewer or maintainer                               |
| Public API or ABI          | Maintainer approval                                      |
| Memory allocator internals | Maintainer approval and targeted tests                   |
| Build system or CI         | Maintainer or Tooling Owner approval                     |
| Dependency update          | Maintainer or Security Contact review                    |
| Security-relevant change   | Security Contact review                                  |
| Release process change     | Release Owner and maintainer approval                    |
| Governance change          | Maintainer approval and open discussion when appropriate |

A pull request should not be merged when:

- required CI gates fail;
- required owners have not reviewed the change;
- required tests are missing without an approved rationale;
- a security issue is introduced without mitigation;
- the change creates unclear ownership;
- the change conflicts with an accepted project decision.

---

<a id="pull-request-checklist"></a>

## > Pull Request Checklist

Pull requests should answer the relevant parts of this checklist.

```md
## Change classification

- [ ] Functional change
- [ ] Bug fix
- [ ] Security-relevant change
- [ ] Public API/ABI change
- [ ] Build/tooling change
- [ ] Documentation-only change
- [ ] Release-process change
- [ ] Governance change

## Required checks

- [ ] Tests added or updated
- [ ] Documentation updated or not applicable
- [ ] Security impact assessed or not applicable
- [ ] Dependency impact assessed or not applicable
- [ ] Changelog updated or not applicable
- [ ] Required owner reviewed or not applicable
```

---

<a id="codeowners-policy"></a>

## > CODEOWNERS Policy

`CODEOWNERS` defines which maintainers or teams must review changes in specific
repository paths.

The project ownership map is:

```text
*                         @RafaelVVolkmer

/.github/                 @RafaelVVolkmer
/docs/                    @RafaelVVolkmer
/LICENSES/                @RafaelVVolkmer
/readme/                  @RafaelVVolkmer

/.gitkeep                 @RafaelVVolkmer
/CHANGELOG.md             @RafaelVVolkmer
/CODE_OF_CONDUCT.md       @RafaelVVolkmer
/GOVERNANCE.md            @RafaelVVolkmer
/LICENSE                  @RafaelVVolkmer
/README.md                @RafaelVVolkmer
/SECURITY.md              @RafaelVVolkmer
```

Path ownership rules:

- changes to owned paths require review from the listed owner;
- ownership changes require maintainer approval;
- unavailable owners may be bypassed only by a maintainer;
- bypassed ownership should be mentioned in the pull request;
- `CODEOWNERS` must stay consistent with this document.

---

<a id="security-governance"></a>

## > Security Governance

Security vulnerabilities are handled according to `SECURITY.md`.

Security-relevant changes include:

- memory management;
- parsing untrusted input;
- dependency updates with known vulnerabilities;
- build or release pipeline changes;
- secret handling;
- sandboxing or isolation;
- vulnerability fixes;
- changes to hardening flags;
- changes to artifact signing.

Security issues may be handled privately when coordinated disclosure is needed.

Public discussion should avoid exposing sensitive vulnerability details before
users have had a reasonable opportunity to update.

Security releases may use a shorter public discussion period when needed, but
they still require maintainer approval.

---

<a id="release-process"></a>

## > Release Process

A release may be published only after release readiness review.

Minimum release requirements:

| Area          | Requirement                                        |
| ------------- | -------------------------------------------------- |
| CI            | Required workflows pass                            |
| Tests         | Required test suites pass                          |
| Security      | No known unresolved critical issue                 |
| Documentation | Changelog and release notes updated                |
| Ownership     | Required owners reviewed release-impacting changes |
| Tag           | Release tag created by a maintainer                |
| Artifacts     | Release artifacts published when applicable        |

The Release Owner should publish or archive a release checklist with each
release.

---

<a id="governance-readiness-review"></a>

## > Governance Readiness Review

A governance readiness review checks whether the project can still operate
clearly and sustainably.

Use this checklist:

| Area            | Question                                                       | Status                    |
| --------------- | -------------------------------------------------------------- | ------------------------- |
| Decision-making | Is it clear who can make final decisions?                      | Open / OK / Action needed |
| Maintainers     | Are maintainers active and reachable?                          | Open / OK / Action needed |
| Reviews         | Are review responsibilities clear?                             | Open / OK / Action needed |
| Security        | Is vulnerability handling clear?                               | Open / OK / Action needed |
| Releases        | Is release authority clear?                                    | Open / OK / Action needed |
| Onboarding      | Can a new contributor understand how to contribute?            | Open / OK / Action needed |
| Barriers        | Are contributors blocked by unclear process or missing owners? | Open / OK / Action needed |
| Interventions   | Is there a path for escalation and conflict resolution?        | Open / OK / Action needed |

Review output should be recorded as an issue or discussion and linked from any
governance update pull request.

---

<a id="barriers-and-needs"></a>

## > Barriers and Needs

The project should actively watch for governance barriers.

| Barrier                      | Risk                                                 | Intervention                                                            |
| ---------------------------- | ---------------------------------------------------- | ----------------------------------------------------------------------- |
| Single maintainer bottleneck | Reviews and releases stall                           | Add reviewers, delegate ownership, reduce required synchronous approval |
| Unclear ownership            | Critical changes get merged without the right review | Update CODEOWNERS and role table                                        |
| Missing security contact     | Vulnerabilities are handled inconsistently           | Assign a contact or define maintainer fallback                          |
| Release authority unclear    | Releases become inconsistent or risky                | Define Release Owner and release checklist                              |
| Too much process             | Contributors stop participating                      | Simplify gates                                                          |
| Too little process           | Decisions become unclear                             | Add minimal review and ownership rules                                  |
| Dormant maintainers          | Decisions become blocked                             | Apply inactivity policy and rotate owners                               |
| Unresolved conflict          | Technical direction stalls                           | Escalate to maintainer decision with documented rationale               |

---

<a id="interventions"></a>

## > Interventions

Governance interventions are allowed when normal day-to-day governance is not
working.

Possible interventions:

| Intervention               | When to use                                                             |
| -------------------------- | ----------------------------------------------------------------------- |
| Release freeze             | Serious security or release integrity problem                           |
| Maintainer decision        | Consensus cannot be reached and progress is blocked                     |
| Temporary owner assignment | A critical owner is unavailable                                         |
| Policy update              | Existing governance does not cover a recurring problem                  |
| Security embargo           | Coordinated disclosure is needed                                        |
| Retrospective              | A release, vulnerability, incident, or conflict exposed governance gaps |

Each intervention should be documented with rationale and outcome.

---

<a id="inactivity-policy"></a>

## > Inactivity Policy

A maintainer or owner may be considered inactive when they have not responded to
project-critical review or governance requests for a reasonable period.

Suggested process:

1. Contact the person publicly in the relevant issue or pull request.
2. Contact privately if appropriate and available.
3. Wait a reasonable response period.
4. Reassign urgent responsibilities temporarily.
5. Update roles if inactivity continues.
6. Record the change in `GOVERNANCE.md` or a governance issue.

This policy should be used respectfully and only to keep the project healthy.

---

<a id="conflict-resolution"></a>

## > Conflict Resolution

Technical disagreement is normal.

Resolution path:

```text
discussion
    -> concrete proposal
        -> review of trade-offs
            -> maintainer decision if needed
                -> documented outcome
```

Conflicts should be resolved based on:

- user impact;
- security;
- maintainability;
- compatibility;
- portability;
- project scope;
- available maintainer capacity.

Personal attacks, harassment, or bad-faith behavior should be handled under the
project's Code of Conduct.

---

<a id="governance-changes"></a>

## > Governance Changes

Changes to this document require maintainer approval.

A governance change should explain:

- what problem it solves;
- which roles or workflows are affected;
- whether it adds or removes required review;
- whether it changes release authority;
- whether it changes ownership rules.

For major governance changes, leave the pull request open long enough for
maintainers and regular contributors to review.

---

<a id="review-and-updates"></a>

## > Review and Updates

This governance document should be reviewed as the project evolves.

Review is expected when:

- the maintainer set changes;
- a new release process is adopted;
- a security incident occurs;
- governance barriers are reported;
- contributors cannot determine who owns a decision.

Substantial changes should be reviewed like any other repository governance
change.

---

<a id="attribution"></a>

## > Attribution

This governance document is informed by the
[SustainOSS Governance Readiness Checklist][sustainoss-url], the
[Governance.md Guide][governance-md-url], and general open-source governance
practices.

The structure and visual style follow the repository documentation style used by
the project's Code of Conduct template.

---

<!-- ======================================================================= -->
<!-- Badge References                                                       -->
<!-- ======================================================================= -->

[governance-shield]: https://img.shields.io/badge/governance-documented-3FB950?style=flat-square&logo=github&logoColor=white&labelColor=1F2328
[governance-url]: ./GOVERNANCE.md

[governance-md-shield]: https://img.shields.io/badge/Governance.md-guide-2F81F7?style=flat-square&logo=markdown&logoColor=white&labelColor=1F2328
[governance-md-url]: https://governance.md/

[sustainoss-shield]: https://img.shields.io/badge/SustainOSS-governance%20readiness-7D3C98?style=flat-square&logo=opensourceinitiative&logoColor=white&labelColor=1F2328
[sustainoss-url]: https://sustainoss.org/governance-readiness/

[decision-shield]: https://img.shields.io/badge/decision%20model-consensus%20%2B%20maintainer%20final-2F81F7?style=flat-square&logo=git&logoColor=white&labelColor=1F2328
[decision-url]: #decision-process

<!-- EOF -->

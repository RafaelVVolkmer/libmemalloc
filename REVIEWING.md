<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

<div align="center">

[![GitHub PR Reviews][reviews-shield]][reviews-url]
[![CODEOWNERS][codeowners-shield]][codeowners-url]
[![Review Standard][review-standard-shield]][review-standard-url]

</div>

---

<div align="center">

<img
    src="/readme/images/libmemalloc_reviewing.svg"
    alt="libmemalloc reviewing logo"
    width="50%"
  />

</div>

---

## > Reviewing Purpose

This document explains how pull request review should work in `libmemalloc`.

The goal of review is to improve code health, maintainability, safety, and
shared understanding without blocking reasonable progress unnecessarily.

Reviews should be:

- technically grounded;
- respectful and direct;
- scoped to the actual change;
- mindful of security and memory-safety impact;
- clear about which comments are blocking and which are optional.

---

## > Review Standard

The project expects review to improve the repository over time.

Reviewers should look for changes that:

- reduce correctness or maintainability;
- introduce unclear behavior or unsupported assumptions;
- weaken safety checks, diagnostics, or testing;
- create portability, ABI, API, or tooling regressions;
- add complexity without enough justification.

At the same time, review should not require perfection before any useful change
can land. The standard is continuous improvement, not endless delay.

---

## > Review Outcomes

When submitting a GitHub review, use the built-in review states intentionally:

- `Comment`:
  for feedback, questions, or non-blocking observations.
- `Approve`:
  when the change is ready to merge from your perspective.
- `Request changes`:
  when there are issues that should be resolved before merge.

If something is advisory rather than mandatory, say so clearly.

Suggested phrasing:

- `Nit:` small polish suggestion
- `Optional:` worthwhile, but not required for this PR
- `Blocking:` must be addressed before merge
- `Question:` needs clarification before confident review

---

## > What Reviewers Should Check

Reviewers should prioritize the highest-signal risks first:

1. Is the change directionally correct for the project?
2. Is the scope appropriate and sufficiently described?
3. Does the implementation appear correct?
4. Are tests and validation appropriate for the risk level?
5. Are API, ABI, portability, and maintenance impacts understood?
6. Is documentation updated when behavior or workflow changes?

For `libmemalloc`, reviewers should pay extra attention to:

- allocation, free, realloc, and ownership semantics;
- pointer arithmetic and bounds handling;
- integer overflow, truncation, and size calculations;
- metadata layout and invariants;
- undefined behavior risks;
- platform and compiler assumptions;
- concurrency or shared-state hazards;
- diagnostics that may expose sensitive information;
- build, CI, packaging, SBOM, provenance, and SPDX changes.

---

## > Review Checklist

Before approving, try to verify:

- [ ] the PR description explains the problem and the proposed change clearly;
- [ ] the change type and risk level look accurate;
- [ ] the implementation matches the stated intent;
- [ ] tests are appropriate for the change or the absence of tests is justified;
- [ ] documentation impact has been considered;
- [ ] API or ABI impact is described when relevant;
- [ ] security-sensitive changes received appropriate scrutiny;
- [ ] the change does not quietly expand scope beyond the PR description.

---

## > Review Scope and Order

Review comments should usually follow this order:

1. Scope and problem framing
2. Correctness
3. Safety and regression risk
4. Testing
5. Maintainability and readability
6. Documentation and polish

This avoids spending time on small style points before deciding whether the
overall direction of the change is acceptable.

---

## > Large or Risky Pull Requests

For large, risky, or security-sensitive changes, reviewers should prefer:

- smaller reviewable steps when possible;
- explicit discussion of invariants and assumptions;
- clear validation evidence;
- narrow merge criteria;
- follow-up issues for non-critical deferred work.

If a pull request is too large to review responsibly, say so directly and ask
for it to be split or reduced in scope.

---

## > Reviewer Conduct

Review feedback should focus on the change, not the person.

Reviewers should:

- assume good intent;
- ask clarifying questions before making accusations;
- explain the reason behind blocking comments;
- distinguish preference from requirement;
- avoid sarcasm, ridicule, or dismissive language;
- acknowledge good design or careful fixes when relevant.

The repository `CODE_OF_CONDUCT.md` still applies during review.

---

## > Author Expectations

Authors should help reviewers by:

- keeping pull requests focused;
- filling the PR template with real information;
- linking issues, discussions, and validation evidence;
- responding to feedback clearly and concretely;
- saying when a comment will be addressed later instead of silently ignoring it;
- re-requesting review after substantial changes.

If the author intentionally declines a suggestion, they should explain why.

---

## > CODEOWNERS and Ownership

This repository defines a default owner in `.github/CODEOWNERS`.

That means review responsibility may be guided by ownership even when anyone
with read access can still leave comments on a public pull request.

Use ownership to route review efficiently, not to prevent technically useful
feedback from other contributors.

Relevant file:

```text
.github/CODEOWNERS
```

---

## > When to Request Changes

`Request changes` is appropriate when a pull request has one or more of the
following:

- incorrect behavior;
- missing or misleading validation for a risky change;
- unclear or unsafe memory-handling logic;
- breaking API or ABI impact without adequate explanation;
- missing documentation for important user-facing behavior changes;
- unresolved design concerns that materially affect maintainability;
- public disclosure of sensitive security details.

If the issue can be fixed in a follow-up without meaningful risk, prefer a
normal comment instead of blocking the PR.

---

## > When to Approve

Approval means the reviewer believes the pull request is acceptable to merge,
not that it is the only possible implementation.

You may still leave non-blocking comments when approving if:

- the change is sound overall;
- remaining suggestions are optional;
- follow-up work is clearly separable;
- style or polish concerns do not justify blocking the merge.

---

## > Review Turnaround

This repository does not promise strict review SLAs.

Review timing depends on:

- maintainer availability;
- PR size and complexity;
- review quality of the submission;
- whether the change touches sensitive code paths;
- whether prior discussion already aligned the scope.

If a pull request has gone quiet for a reasonable time, a polite follow-up is
appropriate.

---

## > Security and Sensitive Changes

Security-sensitive pull requests may require narrower discussion and more
careful handling.

Reviewers should avoid requesting public disclosure of exploit details, secrets,
private keys, production memory dumps, or undisclosed vulnerability specifics.

For suspected vulnerabilities, follow `SECURITY.md` instead of normal public
review flow.

---

## > Review Templates and Related Files

This reviewing guide works together with:

- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/CONTRIBUTING.md`
- `.github/CODEOWNERS`
- `SECURITY.md`
- `GOVERNANCE.md`
- `CODE_OF_CONDUCT.md`

Review comments should be consistent with the expectations defined in those
files.

---

## > Attribution

This document follows the repository style used in `SUPPORT.md`, `ROADMAP.md`,
and `SECURITY.md` and is informed by:

- GitHub Docs: "About pull request reviews"
- GitHub Docs: "Reviewing changes in pull requests"
- Google Engineering Practices: "The Standard of Code Review"
- Apache Flink: "How to Review a Pull Request"

Reference links:

- <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/about-pull-request-reviews>
- <https://docs.github.com/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests>
- <https://google.github.io/eng-practices/review/reviewer/standard.html>
- <https://flink.apache.org/how-to-contribute/reviewing-prs/>

---

<!-- ======================================================================= -->
<!-- Reviewing Badge References                                              -->
<!-- ======================================================================= -->

[reviews-shield]: https://img.shields.io/badge/GitHub-PR%20Reviews-2F81F7?style=flat-square&logo=github&logoColor=white&labelColor=1F2328
[reviews-url]: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/about-pull-request-reviews

[codeowners-shield]: https://img.shields.io/badge/GitHub-CODEOWNERS-3FB950?style=flat-square&logo=github&logoColor=white&labelColor=1F2328
[codeowners-url]: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners

[review-standard-shield]: https://img.shields.io/badge/Open%20Source-Review%20Standard-2F81F7?style=flat-square&logo=googlechrome&logoColor=white&labelColor=1F2328
[review-standard-url]: https://google.github.io/eng-practices/review/reviewer/standard.html

<!-- EOF -->

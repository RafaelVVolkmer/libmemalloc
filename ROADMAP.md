<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

<div align="center">

[![GitHub Discussions][discussions-shield]][discussions-url]
[![GitHub Milestones][milestones-shield]][milestones-url]
[![Roadmap Reference][roadmap-reference-shield]][roadmap-reference-url]

</div>

---

<div align="center">

<img
    src="/readme/images/libmemalloc_roadmap.svg"
    alt="libmemalloc roadmap logo"
    width="50%"
  />

</div>

---

## > Roadmap Purpose

This roadmap describes the current direction of `libmemalloc`.

It is intended to help contributors and users understand which areas are being
improved, which work is actively being considered, and how implementation
efforts should be prioritized.

The roadmap is a planning tool, not a delivery guarantee.

---

## > Disclaimer

This roadmap reflects the project's current priorities and may change as:

- bugs are discovered;
- design constraints become clearer;
- portability or security work takes precedence;
- contributor availability changes;
- community feedback reveals better sequencing.

Items may move, split, merge, or be removed without notice.

---

## > How to Read This Roadmap

Use these status labels consistently:

- `Exploring`: the problem space is being evaluated.
- `Planned`: the item fits the direction of the project and is expected to be
  worked on.
- `In Progress`: implementation or validation is actively happening.
- `Blocked`: the item is waiting on design, tooling, dependencies, or review.
- `Done`: the planned milestone or scope for this item has been completed.

Use these planning horizons:

- `Near term`: active priorities or work likely to start soon.
- `Mid term`: important work that depends on near-term stabilization.
- `Long term`: directional goals that still need refinement.

---

## > Roadmap Structure

Each roadmap item should include:

- a short title;
- the current status;
- the planning horizon;
- a short rationale explaining why the item matters;
- links to issues, pull requests, discussions, or milestones when available;
- important constraints, risks, or dependencies.

Recommended item format:

```text
### Item Title
Status: Planned
Horizon: Near term

Why:
- one or two sentences on the problem being solved

Tracking:
- issue / discussion / pull request / milestone link

Notes:
- constraints, scope boundaries, migration concerns, or risks
```

---

## > Near-Term Priorities

Use this section for work that is important, actionable, and reasonably scoped.

<!--
### <insert text here>

Status: `Planned`
Horizon: `Near term`

Why:

- <insert text here>
- <insert text here>

Tracking:

- <insert text here>
- <insert text here>

Notes:

- <insert text here>
- <insert text here>
-->

<!--
### <insert text here>

Status: `Planned`
Horizon: `Near term`

Why:

- <insert text here>
- <insert text here>

Tracking:

- <insert text here>
- <insert text here>

Notes:

- <insert text here>
- <insert text here>
-->

---

## > Mid-Term Priorities

Use this section for work that depends on earlier stabilization or broader
design agreement.

<!--
### <insert text here>

Status: `Exploring`
Horizon: `Mid term`

Why:

- <insert text here>
- <insert text here>

Tracking:

- <insert text here>
- <insert text here>

Notes:

- <insert text here>
- <insert text here>
-->

<!--
### <insert text here>

Status: `Exploring`
Horizon: `Mid term`

Why:

- <insert text here>
- <insert text here>

Tracking:

- <insert text here>
- <insert text here>

Notes:

- <insert text here>
- <insert text here>
-->

---

## > Long-Term Direction

Use this section for larger themes that guide decisions but are not yet broken
into small implementation tasks.

<!--
### <insert text here>

Status: `Exploring`
Horizon: `Long term`

Why:

- <insert text here>
- <insert text here>

Tracking:

- <insert text here>
- <insert text here>

Notes:

- <insert text here>
- <insert text here>
-->

<!--
### <insert text here>

Status: `Exploring`
Horizon: `Long term`

Why:

- <insert text here>
- <insert text here>

Tracking:

- <insert text here>
- <insert text here>

Notes:

- <insert text here>
- <insert text here>
-->

---

## > Backlog and Candidate Ideas

Use this section for ideas worth keeping visible but not yet prioritized.

<!--
- <insert text here>
- <insert text here>
- <insert text here>
-->

Backlog items should not be interpreted as commitments.

---

## > Not Planned Right Now

Use this section for ideas that have been discussed but are intentionally not
being prioritized at the moment.

Examples:

- features that add too much complexity for current project scope;
- work that depends on unresolved architecture questions;
- requests better handled by downstream integrations or external tooling.

If an item is moved here, explain why.

---

## > Milestones and Tracking

When possible, roadmap items should map to GitHub tracking artifacts:

- GitHub Issues for concrete tasks or defects;
- GitHub Discussions for design questions and roadmap feedback;
- GitHub Milestones for grouped deliverables or release goals;
- Pull Requests for implementation and review history.

If a roadmap item has no linked artifact yet, that usually means the idea is
still early and should not be treated as committed work.

---

## > How the Roadmap Changes

The roadmap should be updated when:

- a priority materially changes;
- a major item starts or finishes;
- scope is narrowed or expanded;
- a milestone is re-sequenced;
- community discussion changes the direction of the work.

Prefer small, explicit updates over silent drift.

---

## > Community Feedback

Feedback on roadmap direction is welcome through:

- GitHub Discussions:
  <https://github.com/RafaelVVolkmer/libmemalloc/discussions>
- focused Issues for concrete, reproducible needs;
- Pull Requests for documentation clarifications or scoped implementation work.

If you want to propose a new roadmap item, explain:

- the problem being solved;
- why it matters to `libmemalloc`;
- what constraints or trade-offs it introduces;
- whether the idea is near-term, mid-term, or long-term.

---

## > Contribution Alignment

Contributors are encouraged to align major work with the roadmap before opening
large pull requests.

For larger or potentially disruptive changes:

1. Open or link a GitHub Discussion first.
2. Clarify scope, risks, and compatibility impact.
3. Break the work into reviewable milestones when practical.
4. Link the relevant issue, discussion, or milestone from the PR.

Smaller fixes do not need a roadmap item if they are clearly within current
project scope.

---

## > Attribution

This roadmap template follows the repository documentation style used in
`SUPPORT.md` and `SECURITY.md` and is informed by:

- GitHub public roadmap repository structure;
- GitHub Docs on milestones;
- GitHub Docs on discussions;
- the Gemini CLI public roadmap disclaimer pattern.

Reference links:

- <https://github.com/github/roadmap>
- <https://docs.github.com/issues/using-labels-and-milestones-to-track-work/about-milestones>
- <https://docs.github.com/en/discussions/collaborating-with-your-community-using-discussions/about-discussions>
- <https://github.com/google-gemini/gemini-cli/blob/main/ROADMAP.md>

---

<!-- ======================================================================= -->
<!-- Roadmap Badge References                                                -->
<!-- ======================================================================= -->

[discussions-shield]: https://img.shields.io/badge/GitHub-Discussions-2F81F7?style=flat-square&logo=github&logoColor=white&labelColor=1F2328
[discussions-url]: https://github.com/RafaelVVolkmer/libmemalloc/discussions

[milestones-shield]: https://img.shields.io/badge/GitHub-Milestones-3FB950?style=flat-square&logo=github&logoColor=white&labelColor=1F2328
[milestones-url]: https://docs.github.com/issues/using-labels-and-milestones-to-track-work/about-milestones

[roadmap-reference-shield]: https://img.shields.io/badge/Open%20Source-Roadmap%20Reference-2F81F7?style=flat-square&logo=github&logoColor=white&labelColor=1F2328
[roadmap-reference-url]: https://github.com/github/roadmap

<!-- EOF -->

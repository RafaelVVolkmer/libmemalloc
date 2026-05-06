<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

<div align="center">

[![Conventional Commits][conventional-commits-shield]][conventional-commits-url]
[![Git Flow][gitflow-shield]][gitflow-url]
[![Semantic Versioning][semver-shield]][semver-url]
[![Keep A Changelog][changelog-shield]][changelog-url]

</div>

---

<div align="center">

<img
    src="/readme/images/libmemalloc_contributing.svg"
    alt="libmemalloc contributing logo"
    width="50%"
  />

</div>

---

## > Contributing Purpose

Thank you for your interest in contributing to `libmemalloc`.

This document explains how to report bugs, propose features, improve
documentation, open pull requests, report security issues, and follow the
project repository-quality guides.

The contribution process is designed to keep work:

- focused;
- reviewable;
- reproducible;
- documented;
- secure;
- respectful of maintainer time;
- aligned with the project direction.

---

## > Getting Started

`libmemalloc` uses GitHub project tools to keep contributions organized.

| Channel                  | Use for                                                                      |
| ------------------------ | ---------------------------------------------------------------------------- |
| GitHub Issues            | Bugs, feature requests, documentation issues, and concrete support requests. |
| GitHub Discussions       | Open-ended questions, design conversations, usage topics, and early ideas.   |
| Pull Requests            | Code, tests, documentation, tooling, CI, and repository maintenance changes. |
| Private security contact | Suspected vulnerabilities or security-sensitive reports.                     |

Use the most specific channel available. This keeps issue tracking actionable
and avoids mixing bug reports, design conversations, and code review in the same
place.

### Getting Started Checklist

Before contributing, verify:

- [ ] you checked whether a similar issue, discussion, or pull request already exists;
- [ ] you selected the right channel: Issue, Discussion, Pull Request, or private security report;
- [ ] you read the relevant template before submitting;
- [ ] your report or contribution is focused on one topic;
- [ ] you can provide enough context for maintainers to reproduce, discuss, or review it;
- [ ] you did not include secrets, credentials, tokens, or unrelated private data.

---

## > Reporting Bugs

Open a GitHub Issue when you find incorrect behavior, crashes, build failures,
regressions, or unexpected runtime results.

A useful bug report should include:

- the `libmemalloc` version, release tag, branch, or commit hash;
- operating system and architecture;
- compiler, compiler version, and relevant C standard mode;
- build system and toolchain details;
- current `libmemalloc` configuration;
- minimal steps to reproduce the issue;
- expected behavior;
- actual behavior;
- relevant logs, such as build output, test logs, sanitizer output,
  backtraces, or debugger output.

Use the Bug Report template:

```text
.github/ISSUE_TEMPLATE/bug_report.md
```

GitHub shows this template when selecting:

```text
New issue -> Bug report
```

Issues that do not include enough information may be sent back for
clarification.

### Bug Report Checklist

Before opening a bug report, verify:

- [ ] you used the Bug Report issue template;
- [ ] you included the affected `libmemalloc` version or commit;
- [ ] you included OS, architecture, compiler, and toolchain details;
- [ ] you described the current `libmemalloc` configuration;
- [ ] you provided minimal reproduction steps when possible;
- [ ] you described expected and actual behavior;
- [ ] you attached relevant logs, traces, sanitizer output, or debugger output;
- [ ] you did not include private secrets or confidential data.

---

## > Proposing Features

Open a Feature Request issue when you want to propose a new capability,
configuration option, API, behavior, optimization, or supported use case.

A good feature request should describe:

- the problem you are trying to solve;
- the API, behavior, or configuration you have in mind;
- concrete use cases;
- compatibility impact;
- whether the change could be breaking;
- expected performance or memory impact;
- rough design ideas, constraints, or trade-offs.

Use the Feature Request template:

```text
.github/ISSUE_TEMPLATE/feature_request.md
```

For larger or potentially disruptive changes, open a GitHub Discussion first.
This helps align expectations before implementation work begins.

### Feature Request Checklist

Before opening a feature request, verify:

- [ ] you used the Feature Request issue template;
- [ ] you described the problem, not only the proposed solution;
- [ ] you included at least one concrete use case;
- [ ] you explained possible API or configuration changes;
- [ ] you identified compatibility or migration impact;
- [ ] you noted possible performance implications;
- [ ] you opened a Discussion first if the change is large or disruptive.

---

## > Documentation Issues

Open a documentation issue when documentation is missing, unclear, outdated,
incorrect, or difficult to follow.

Use the Documentation Issue template:

```text
.github/ISSUE_TEMPLATE/docs_issue.md
```

A useful documentation issue should include:

- the affected file, section, symbol, or page;
- what is wrong, unclear, missing, or outdated;
- what you expected the documentation to say;
- suggested wording, examples, or references when available.

If the fix is already clear and small, you may open a Pull Request directly and
reference the documentation issue in the PR description.

### Documentation Issue Checklist

Before opening a documentation issue, verify:

- [ ] you used the Documentation Issue template;
- [ ] you identified the affected file, section, page, symbol, or API;
- [ ] you explained what is missing, unclear, outdated, or wrong;
- [ ] you described the expected documentation behavior;
- [ ] you included suggested wording or examples when available;
- [ ] you opened a PR directly if the fix is already clear and small.

---

## > Questions and Discussions

Use GitHub Discussions for general questions, design conversations, usage
questions, and open-ended ideas.

Good Discussion topics include:

- which allocator strategy fits a workload;
- how to integrate `libmemalloc` into another project;
- whether a design direction is worth pursuing;
- trade-offs between APIs, GC modes, logging, testing, and portability;
- early ideas that are not yet ready to become issues or pull requests.

Use the most appropriate Discussion category, such as:

```text
Q&A
Ideas
General
```

There is also a Questions and Help issue template:

```text
.github/ISSUE_TEMPLATE/question_help.md
```

Use that issue template only when the question is close to a concrete bug report
or feature request. Broad questions may be redirected to Discussions.

The issue template configuration file is expected to expose the correct contact
links and disable blank issues:

```text
.github/ISSUE_TEMPLATE/config.yml
```

### Questions and Discussions Checklist

Before opening a question or discussion, verify:

- [ ] the topic is not already answered in existing docs, issues, or discussions;
- [ ] you selected Discussion for broad design or usage questions;
- [ ] you selected an Issue only for concrete bugs, documentation problems, or feature requests;
- [ ] you included enough context about your environment or workload;
- [ ] you avoided mixing unrelated questions in one thread;
- [ ] you did not include private secrets, credentials, or confidential logs.

---

## > Build and Test

Before opening a Pull Request, make sure the project builds cleanly and the
tests pass.

Convenience scripts are available under:

```text
scripts/
```

Example local builds:

```sh
./scripts/build.sh debug
./scripts/build.sh release
```

If Docker builds are supported, a release build may look like this:

```sh
./scripts/build.sh release --docker --platform linux/amd64
```

Run the test suite as documented in `README.md`. Depending on the build
configuration, tests may be run through `ctest` in the build directory or
through a dedicated project script.

When adding or modifying behavior, update or extend test coverage. Pull
Requests that break existing tests or add untested functionality may be asked to
include appropriate tests before being merged.

### Build and Test Checklist

Before opening a Pull Request, verify:

- [ ] debug build passes locally;
- [ ] release build passes locally;
- [ ] Docker build passes when Docker support is relevant;
- [ ] tests pass using the documented test command;
- [ ] new behavior includes new or updated tests;
- [ ] existing tests were not removed without justification;
- [ ] relevant sanitizer, static-analysis, or CI failures were addressed;
- [ ] build logs are included in the PR when they help review.

---

## > Documentation

When changing the public API, update the documentation together with the code.

Update:

- Doxygen-style comments in public headers;
- relevant sections in `README.md`;
- relevant guides under the documentation tree;
- examples, if public behavior changes;
- changelog or release notes when appropriate.

Comments should state intent, ownership, lifetime rules, contracts,
preconditions, postconditions, error behavior, and compatibility constraints.

Avoid comments that only restate the obvious.

If the project publishes Doxygen documentation, keep function, enum, macro, and
struct descriptions synchronized with the real implementation behavior.

### Documentation Checklist

Before submitting documentation changes, verify:

- [ ] public headers have updated Doxygen comments;
- [ ] API contracts describe preconditions and postconditions;
- [ ] ownership, lifetime, and error behavior are documented when relevant;
- [ ] README or guide sections are updated when user behavior changes;
- [ ] examples compile or remain accurate;
- [ ] Doxygen output remains consistent with the implementation;
- [ ] documentation changes are linked from the PR description.

---

## > Pull Request Guidelines

Pull Requests are used for code, documentation, tests, tooling, CI, and
repository maintenance changes.

When opening a Pull Request:

- use a clear title in the same spirit as a good commit summary;
- explain the context and problem being solved;
- summarize the proposed solution;
- describe API, ABI, compatibility, or performance impact;
- describe how the change was tested;
- keep the PR focused on one logical topic.

All Pull Requests are expected to follow the PR template:

```text
.github/pull_request_template.md
```

When GitHub pre-fills the PR description:

- keep the template sections;
- fill in relevant fields;
- include environment details when relevant;
- include tests and commands run;
- include API, ABI, and performance impact;
- include DCO information when requested;
- follow the [Signature Guide][signature-guide] when signing commits, tags,
  artifacts, or attestations;
- do not remove checklists unless they are clearly not applicable.

Smaller, focused PRs are easier to review and more likely to be merged quickly.

If your PR is not ready for review yet, mark it as a Draft.

### Pull Request Checklist

Before opening or marking a PR as ready, verify:

- [ ] the PR uses the repository PR template;
- [ ] the PR title is clear and reviewable;
- [ ] the PR solves one focused problem;
- [ ] the description explains context and solution;
- [ ] API, ABI, compatibility, and performance impact are documented;
- [ ] build and test commands are listed;
- [ ] required tests pass;
- [ ] commits follow the [Commit Message Guide][commit-message-guide];
- [ ] commits include DCO `Signed-off-by`;
- [ ] documentation is updated when public behavior changes;
- [ ] the PR is marked Draft if it is not ready for review.

---

## > Commit Messages

Commits should be clear, reviewable, and easy to trace.

The project uses Conventional Commits style:

```text
type(scope): short imperative summary
```

Examples:

```text
fix(core): reject zero-sized arena alignment overflow
docs(readme): clarify allocator strategy selection
test(unit): cover double-free rejection path
```

Commit bodies should explain motivation, implementation details, and impact when
the change is not obvious.

Follow the [Commit Message Guide][commit-message-guide] for the complete policy.

---

## > DCO and Signing

Contributions should include a Developer Certificate of Origin sign-off when
required by the project workflow.

Example:

```text
Signed-off-by: Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
```

Use:

```sh
git commit -s
```

The project may also require signed commits, signed tags, or signed release
artifacts.

Follow the [Signature Guide][signature-guide] for commit, tag, artifact, and
attestation signing.

### DCO and Signing Checklist

Before submitting commits, verify:

- [ ] commits include `Signed-off-by` when required;
- [ ] the author identity is correct;
- [ ] signed commits are used when required;
- [ ] signed tags or artifacts are prepared for release work when applicable;
- [ ] signing failures are fixed before requesting review.

---

## > Security

If you believe you have found a security issue, do **not** open a public GitHub
issue initially.

Security-sensitive examples include:

- heap corruption;
- use-after-free;
- double free;
- out-of-bounds access;
- integer overflow affecting allocation size;
- allocator metadata corruption;
- potentially exploitable crashes;
- other memory-safety or supply-chain risks.

Send a private report to:

```text
Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
```

You may also find a private vulnerability reporting contact card when creating a
new issue, if GitHub private vulnerability reporting is enabled.

Include:

- a description of the issue;
- steps or a minimal program to reproduce it;
- affected version, branch, or commit;
- environment and toolchain details;
- logs, debugger output, or sanitizer output when available;
- any analysis or proof of concept you are comfortable sharing privately.

See `SECURITY.md` for the complete vulnerability disclosure policy.

### Security Checklist

Before sending a security report, verify:

- [ ] you did not open a public issue for a sensitive vulnerability;
- [ ] you included affected version, branch, or commit;
- [ ] you described the vulnerability class;
- [ ] you included reproduction steps or a minimal program if possible;
- [ ] you included relevant logs, traces, or sanitizer output;
- [ ] you removed secrets and unrelated private data;
- [ ] you used the private reporting email or private security contact flow.

---

## > Repository Quality Guides

The contribution flow is intentionally compact in this file. Detailed project
policies live under:

```text
readme/repository_quality/
```

Use these guides when preparing commits, branches, releases, tags, provenance
files, SBOMs, signatures, and version bumps.

| Guide                                        | Purpose                                                        |
| -------------------------------------------- | -------------------------------------------------------------- |
| [Commit Message Guide][commit-message-guide] | Commit message format and review expectations.                 |
| [GitFlow Guide][gitflow-guide]               | Branching model and release branch conventions.                |
| [Signature Guide][signature-guide]           | Commit, tag, artifact, and attestation signing.                |
| [Versioning Guide][versioning-guide]         | Versioning, release numbering, and compatibility expectations. |

### Repository Quality Checklist

Before opening or merging a Pull Request, verify:

- [ ] commits follow the commit message guide;
- [ ] branch names follow the GitFlow guide when GitFlow is used;
- [ ] DCO sign-off and signing requirements are satisfied;
- [ ] versioning impact is clear when the change affects releases;
- [ ] changelog, release notes, or documentation were updated when needed.

---

## > License

By contributing to this repository, you agree that your contributions will be
licensed under the terms specified in the project `LICENSE` file.

This applies to code, documentation, tests, examples, scripts, workflows, and
other submitted material unless a different license is explicitly stated and
accepted by the project.

Contributions should include appropriate SPDX metadata when required by the
project style.

---

## > Thank You

Thank you for helping make `libmemalloc` better.

Focused issues, reproducible bugs, clear pull requests, useful tests, careful
reviews, and documentation improvements all help the project move forward.

---

<!-- ======================================================================= -->
<!-- Standards Badge References                                              -->
<!-- ======================================================================= -->

[conventional-commits-shield]: https://img.shields.io/badge/Conventional%20Commits-1.0.0-FE5196?style=flat-square&logo=conventionalcommits&logoColor=white&labelColor=1F2328
[conventional-commits-url]: https://www.conventionalcommits.org/
[gitflow-shield]: https://img.shields.io/badge/Git%20Flow-enabled-F05032?style=flat-square&logo=git&logoColor=white&labelColor=1F2328
[gitflow-url]: https://nvie.com/posts/a-successful-git-branching-model/
[semver-shield]: https://img.shields.io/badge/SemVer-2.0.0-3F4551?style=flat-square&logo=semver&logoColor=white&labelColor=1F2328
[semver-url]: https://semver.org/
[changelog-shield]: https://img.shields.io/badge/Keep%20A%20Changelog-1.1.0-E05735?style=flat-square&logo=keepachangelog&logoColor=white&labelColor=1F2328
[changelog-url]: https://keepachangelog.com/en/1.1.0/

<!-- ======================================================================= -->
<!-- Repository Guide References                                             -->
<!-- ======================================================================= -->

[commit-message-guide]: ../docs/workflow/versioning/commit-message-guide.md
[gitflow-guide]: ../docs/workflow/versioning/gitflow-guide.md
[signature-guide]: ../docs/workflow/versioning/signature-guide.md
[versioning-guide]: ../docs/workflow/versioning/versioning-guide.md

<!-- EOF -->

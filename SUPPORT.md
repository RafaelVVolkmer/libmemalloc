<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

<div align="center">

[![GitHub Discussions][discussions-shield]][discussions-url]
[![Support File][support-file-shield]][support-file-url]

</div>

---

<div align="center">

<img
    src="/readme/images/libmemalloc_support.svg"
    alt="libmemalloc contributing logo"
    width="50%"
  />

</div>

---

## > Support Policy

`libmemalloc` provides community support for usage questions, build problems,
documentation gaps, integration topics, and general project guidance.

This file explains which support channel to use, what information to include,
and when a public issue should become a private security report instead.

---

## > Where to Ask for Help

Use the most specific support channel available:

- GitHub Discussions:
  usage questions, design conversations, troubleshooting, and general feedback.
- GitHub Issues:
  reproducible bugs, documentation defects, and feature requests.
- Documentation website:
  project overview, docs, guides, and examples.
- Private security contact:
  suspected vulnerabilities and other security-sensitive reports.

Primary support links:

- GitHub Discussions:
  <https://github.com/RafaelVVolkmer/libmemalloc/discussions>
- Documentation: <https://rafaelvvolkmer.github.io/libmemalloc/>
- Security policy: [SECURITY.md](SECURITY.md)

If a question becomes a confirmed bug, the maintainer may ask you to open a
focused GitHub Issue that links back to the Discussion.

---

## > Preferred Support Flow

For most support requests, follow this order:

1. Check the documentation, `README.md`, and repository workflow guides.
2. Search existing issues and discussions for the same symptom or question.
3. Open a GitHub Discussion for usage, design, portability, or integration
   questions.
4. Open a GitHub Issue if you have a concrete, reproducible defect or a clear
   documentation problem.
5. Use the private security process in [SECURITY.md](SECURITY.md) for
   vulnerabilities or other sensitive reports.

This keeps public support threads easier to search and prevents issues from
becoming catch-all discussion threads.

---

## > What to Include

A good support request should include:

- the `libmemalloc` version, branch, tag, or commit hash;
- operating system and architecture;
- compiler, compiler version, and relevant C standard mode;
- build configuration, feature flags, and toolchain details;
- a concise description of the question, failure, or confusing behavior;
- minimal reproduction steps, when applicable;
- expected behavior and actual behavior;
- logs, traces, sanitizer output, or debugger output when relevant;
- whether the problem is specific to your environment or reproducible elsewhere;
- what documentation, issue, or discussion you already checked.

Please remove secrets, credentials, tokens, private keys, and unrelated private
data before posting logs or build output.

---

## > Supported Topics

Community support is appropriate for topics such as:

- build and test setup;
- compiler or platform compatibility questions;
- allocator API usage;
- integration into another library or application;
- documentation clarification;
- repository workflow questions;
- understanding configuration options, diagnostics, or examples.

Support is provided on a best-effort basis by the maintainer and contributors.

---

## > Response Expectations

This project does not provide paid support or response-time guarantees.

Support availability depends on maintainer time, report quality, topic scope,
and whether the request is reproducible with the available information.

The maintainer may:

- ask for a smaller reproducer;
- request missing environment details;
- redirect a question from Issues to Discussions;
- redirect a public security report to the private security channel;
- close stale or non-actionable support requests.

---

## > Out of Scope

The following are generally outside the scope of normal project support:

- private consulting or guaranteed one-on-one debugging;
- proprietary environment investigation without a minimal reproducer;
- support for heavily modified forks or downstream patches;
- long-term maintenance of unsupported versions;
- public handling of undisclosed vulnerabilities;
- unrelated third-party project troubleshooting.

When possible, the maintainer may still point you to the correct channel,
documentation, or next debugging step.

---

## > Issues, Discussions, and Templates

The repository already defines support-related contribution paths:

- `.github/ISSUE_TEMPLATE/question_help.yml`
- `.github/ISSUE_TEMPLATE/bug_report.yml`
- `.github/ISSUE_TEMPLATE/docs_issue.yml`
- `.github/ISSUE_TEMPLATE/feature_request.yml`
- `.github/ISSUE_TEMPLATE/config.yml`
- `.github/CONTRIBUTING.md`

Use the Questions and Help template only when the request is close to a
concrete issue. Broad usage questions and open-ended design topics belong in
GitHub Discussions.

---

## > Security and Sensitive Reports

Do **not** use public issues or discussions for suspected vulnerabilities,
memory corruption reports with security impact, credential disclosure, or other
sensitive incident details.

Instead, follow the private reporting instructions in [SECURITY.md](SECURITY.md)
and use:

```text
Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
```

Suggested subject:

```text
[SECURITY] libmemalloc vulnerability report
```

---

## > Contact

Support channels:

- Questions and discussion:
  <https://github.com/RafaelVVolkmer/libmemalloc/discussions>
- Project documentation:
  <https://rafaelvvolkmer.github.io/libmemalloc/>
- Security contact:
  `Rafael V. Volkmer <rafael.v.volkmer@gmail.com>`

For repository policy, contribution workflow, and review expectations, also see
`.github/CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, and `GOVERNANCE.md`.

---

## > Attribution

This support file follows the repository style established in `SECURITY.md` and
is informed by:

- GitHub Docs: "Adding support resources to your project"
- GitHub Docs: "About discussions"
- the repository's `.github/CONTRIBUTING.md`
- the repository's `.github/ISSUE_TEMPLATE/config.yml`

Reference links:

- <https://docs.github.com/en/enterprise-cloud@latest/communities/setting-up-your-project-for-healthy-contributions/adding-support-resources-to-your-project>
- <https://docs.github.com/en/discussions/collaborating-with-your-community-using-discussions/about-discussions>

---

<!-- ======================================================================= -->
<!-- Support Badge References                                                -->
<!-- ======================================================================= -->

[discussions-shield]: https://img.shields.io/badge/GitHub-Discussions-2F81F7?style=flat-square&logo=github&logoColor=white&labelColor=1F2328
[discussions-url]: https://github.com/RafaelVVolkmer/libmemalloc/discussions

[support-file-shield]: https://img.shields.io/badge/GitHub-SUPPORT%20file-3FB950?style=flat-square&logo=github&logoColor=white&labelColor=1F2328
[support-file-url]: https://docs.github.com/en/enterprise-cloud@latest/communities/setting-up-your-project-for-healthy-contributions/adding-support-resources-to-your-project

<!-- EOF -->

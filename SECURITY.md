<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

<div align="center">

[![OpenSSF][openssf-shield]][openssf-url]
[![Scorecard][scorecard-shield]][scorecard-url]
[![Security Insights][security-insights-shield]][security-insights-url]
[![OSV][osv-shield]][osv-url]

</div>

---

<div align="center">

<img
    src="/readme/images/libmemalloc_security_policy.svg"
    alt="libmemalloc security policy logo"
    width="50%"
  />

</div>

---

## > Security Policy

The `libmemalloc` project takes security reports seriously.

Because `libmemalloc` is a low-level memory allocation library, security issues
may include memory corruption, incorrect allocation sizes, invalid metadata
handling, unsafe API behavior, build or release integrity problems, and
supply-chain risks.

Please do **not** open a public GitHub issue for a suspected vulnerability until
the issue has been reviewed and a disclosure plan has been agreed.

---

## > Reporting a Vulnerability

Send private security reports to:

```text
Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
```

Use a clear subject line, such as:

```text
[SECURITY] libmemalloc vulnerability report
```

You may also use GitHub's private vulnerability reporting feature if it is
enabled for this repository.

---

## > What to Include

A helpful vulnerability report should include:

- affected version, release tag, branch, or commit hash;
- operating system and architecture;
- compiler, compiler version, and relevant C standard mode;
- build configuration and feature flags;
- a description of the suspected vulnerability;
- minimal steps to reproduce the issue;
- a minimal test case or proof of concept, when safe to share privately;
- sanitizer output, crash logs, debugger output, or backtrace when available;
- whether the issue appears exploitable or only causes a crash;
- whether the issue is already public;
- any suggested fix, mitigation, or affected code path.

Please remove secrets, credentials, private customer data, and unrelated
confidential information before sending logs or reproducers.

---

## > Security Scope

Security-sensitive issues may include:

- heap corruption;
- allocator metadata corruption;
- use-after-free;
- double free;
- out-of-bounds read or write;
- integer overflow or truncation affecting allocation size;
- alignment errors that can cause undefined behavior;
- unsafe behavior under resource exhaustion;
- data race or concurrency issue affecting allocator correctness;
- potentially exploitable crash;
- incorrect hardening behavior;
- unsafe build, release, or artifact-signing behavior;
- dependency, SBOM, provenance, or supply-chain issue.

Non-security bugs, documentation problems, feature requests, and ordinary build
failures should be reported through the normal GitHub issue templates.

---

## > Supported Versions

Security support applies to the actively maintained branch and the latest
published release, unless the project states otherwise in release notes.

| Version                                 | Supported   |
| --------------------------------------- | ----------- |
| `main`                                  | Yes         |
| Latest release                          | Yes         |
| Older releases                          | Best effort |
| Unreleased forks or local modifications | No          |

If a vulnerability affects older releases, the maintainer may decide whether a
backport is practical.

---

## > Handling Process

Security reports are handled using this process:

1. The report is acknowledged.
2. The issue is triaged privately.
3. The affected versions and configurations are identified.
4. The severity and impact are assessed.
5. A fix or mitigation is prepared.
6. Regression tests are added when practical.
7. A release or advisory is prepared when needed.
8. Public disclosure happens after users have had reasonable time to update.

The exact timeline depends on severity, exploitability, affected versions, and
maintainer availability.

---

## > Coordinated Disclosure

The project supports coordinated disclosure.

Reporters are asked to:

- avoid public disclosure before the maintainer has reviewed the report;
- avoid publishing exploit details before a fix or mitigation is available;
- give the project a reasonable opportunity to investigate and respond;
- coordinate timing when a public advisory is needed.

The maintainer will try to:

- acknowledge the report;
- communicate whether the issue is accepted as security-relevant;
- keep the reporter informed of major status changes;
- credit the reporter when requested and appropriate;
- publish release notes or advisories when needed.

---

## > Public Advisories

A public advisory may be created when an issue affects released code and has
security impact.

An advisory should include:

- affected versions;
- fixed versions;
- severity or impact summary;
- affected component or behavior;
- mitigation or upgrade guidance;
- reporter credit, when approved by the reporter;
- references to related commits, releases, or CVE records when applicable.

The advisory should avoid unnecessary exploit details.

---

## > Security Expectations for Contributors

Contributors should:

- avoid committing secrets or credentials;
- avoid adding unsafe dependencies;
- keep dependency updates reviewable;
- add tests for security-relevant bug fixes;
- use private reporting for suspected vulnerabilities;
- avoid publishing sensitive vulnerability details in issues or pull requests;
- follow the repository contribution and review process;
- keep security-sensitive changes focused and easy to audit.

Security-relevant pull requests may require additional review before merge.

---

## > Supply Chain Security

The project may use the following practices for released artifacts:

- SPDX license metadata;
- SBOM generation using SPDX and/or CycloneDX formats;
- dependency vulnerability scanning;
- OpenSSF Scorecard monitoring;
- SLSA or in-toto provenance when available;
- signed tags and artifacts using GPG or Sigstore/Cosign when available;
- pinned GitHub Actions and locked dependencies where practical.

These practices improve release integrity, but they do not by themselves imply
certification or a guarantee that the software is vulnerability-free.

---

## > Vulnerability Classes to Watch

For a C memory allocator, reviewers and contributors should pay special
attention to:

- unchecked integer arithmetic in allocation-size calculations;
- signed/unsigned conversion bugs;
- pointer arithmetic errors;
- metadata overwrite risks;
- incorrect alignment handling;
- invalid free behavior;
- double free behavior;
- use-after-free behavior;
- out-of-bounds access;
- race conditions in shared allocator state;
- inconsistent behavior across compilers or architectures;
- undefined behavior triggered by edge-case inputs.

---

## > Contact

Security contact:

```text
Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
```

For non-security issues, use GitHub Issues or Discussions.

---

## > Attribution

This policy is informed by common open-source vulnerability disclosure practices,
OpenSSF project guidance, OSV ecosystem practices, SPDX, SBOM, SLSA, and
Sigstore/Cosign supply-chain security tooling.

---

<!-- ======================================================================= -->
<!-- OpenSSF / Security Badge References                                     -->
<!-- ======================================================================= -->

[openssf-shield]: https://img.shields.io/badge/OpenSSF-ready-3FB950?style=flat-square&logo=opensourceinitiative&logoColor=white&labelColor=1F2328
[openssf-url]: https://openssf.org/

[scorecard-shield]: https://img.shields.io/ossf-scorecard/github.com/RafaelVVolkmer/libmemalloc?style=flat-square&logo=opensourceinitiative&logoColor=white&label=Scorecard&labelColor=1F2328&color=3FB950
[scorecard-url]: https://securityscorecards.dev/viewer/?uri=github.com/RafaelVVolkmer/libmemalloc

[security-insights-shield]: https://img.shields.io/badge/Security%20Insights-YAML-2F81F7?style=flat-square&logo=yaml&logoColor=white&labelColor=1F2328
[security-insights-url]: https://security-insights.openssf.org/

[osv-shield]: https://img.shields.io/badge/OSV-scanner-2F81F7?style=flat-square&logo=google&logoColor=white&labelColor=1F2328
[osv-url]: https://osv.dev/


<!-- EOF -->

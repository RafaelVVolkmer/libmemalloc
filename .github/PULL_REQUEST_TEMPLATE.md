<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Pull Request

## Specification traceability

Link the approved `spec` issue, its area, SDD revision and control IDs. Use `Refs #NUMBER` for partial work.
Use `Closes #NUMBER` only when this PR completes the issue acceptance conditions. Record verification evidence.

## Summary

Describe the problem, resulting behavior and reason for the change in a few sentences.
State the change type and link related issues; use closing keywords where appropriate.

## Decision and implementation

Explain the affected components, alternatives and reason for the selected implementation.
Link the governing specification or reference and the verification evidence.
Follow the [review procedure](../docs/procedures/decision-making.md).

## Compatibility and impact

Describe API, ABI, ownership, platform and configuration effects. State any migration or deprecation requirements.
Explain security-sensitive paths, performance effects and release/packaging changes within the actual scope.
For benchmarks, identify the baseline, workload, environment, repetitions and observed variability.

## Environment and verification

Identify the source revision, host and target, compiler/tool versions and selected build configuration.
Record exact commands, results and evidence links. Distinguish successful, failed, unavailable and unexecuted checks.

```sh
# Exact build and verification commands.
```

```text
# Results and retained artifact references.
```

Explain any missing verification and its effect on the proposed conclusion.
Describe documentation changes and link updated requirements or references.

## Risk, rollback and review

Describe material risks, rollback or migration steps, assumptions and areas requiring focused review.
Do not include secrets, private data or undisclosed vulnerability details; follow
the [security policy](../SECURITY.md) for private reporting.

## DCO Sign-off

By contributing, you certify that you have the right to submit this work under the project's license
and agree to the repository's Developer Certificate of Origin process.

```text
Signed-off-by: <Your Name> <your.email@example.com>
```

<!-- EOF -->


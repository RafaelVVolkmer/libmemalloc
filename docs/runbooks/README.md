<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Execution runbooks

Run commands from the repository root with each runbook's prerequisites available.
Check its scope before interpreting a passing result.

- [Local checks](local-checks.md): aggregate and individual repository checks.
- [Process pilot](process-pilot.md): Lua plan/run/gate/report and localhost Ansible.
- [Build](build.md): plan and execute a declared build profile.
- [Qualification](qualification.md): mock semantics, instrumentation and PGO evidence.
- [C analysis](c-analysis.md): static analysis, architecture and bounded verification.
- [Reproducibility](reproducibility.md): independent builds, variations and comparison tools.
- [Release fixture](release-fixture.md): mock artifacts, signatures and publication prerequisites.
- [Security services](security-services.md): credentials, identities and service setup.

For documentation generation, use [documentation validation](../getting-started/documentation.md).
For hosted entry points and coverage, use the [workflow catalog](../reference/workflow-catalog.md).

<!-- EOF -->


<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Verification procedure

**Status:** proposed LMA-PROC-003 procedure using existing checks and campaign planners.
**Owner role:** verification owner. **Input:** candidate revision, affected requirements and configuration scope.

1. Identify the applicable [CI controls](../reference/automation.md#ci-control-map) and SDD acceptance cases.
2. Select the [runbook](../reference/workflow-catalog.md) and record expected configurations before execution.
3. Prepare its declared tools and a fresh attempt directory. Retain the source identity and tool versions.
4. Execute the campaign and retain failed, missing and unavailable results alongside successful cases.
5. Reconcile returned evidence with the plan using that campaign's reporter. Review remaining findings and
   the [evidence contract](../reference/evidence.md) before accepting the stated scope.

**Acceptance:** applicable required results cover the selected revision and configurations; reviewers record
permitted dispositions for unresolved findings. A missing result cannot count as a successful check.
Current [qualification](../runbooks/qualification.md) covers the mock contract. The
[process pilot](../runbooks/process-pilot.md) covers parser, documentation, compilation and automation-regression controls.

**Records:** plan, command logs, configuration identity, artifact hashes, report and review decision.
Keep working logs under `.cache/`; retain accepted records under the campaign's artifact policy.

<!-- EOF -->


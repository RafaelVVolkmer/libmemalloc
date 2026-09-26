<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Engineering review procedure

Record engineering rationale in the issue or pull request that introduces the change.
The author explains the problem, selected approach and relevant alternatives. The reviewer checks
correctness and evidence; the authority defined in [governance](../../GOVERNANCE.md#decision-process)
records acceptance for the reviewed revision.

<details>
<summary><strong>On this page</strong></summary>

- [Review content](#review-content)
- [Verification and retention](#verification-and-retention)
- [Maintaining the contract](#maintaining-the-contract)

</details>

---

## Review content

Scale the explanation to the consequences and uncertainty of the change. Identify the governing SDD
requirements or reference contracts, affected components, compatibility effects and unresolved assumptions.
For measurements, declare the baseline, workload, environment and method before comparing results.
Retain failed and inconclusive results alongside successful observations.

---

## Verification and retention

Record exact commands, tool versions, source identity and observed outcomes. Link the tests and
[evidence records](../reference/evidence.md) that support the claimed behavior. Local `.cache/` reports
are disposable; retain accepted evidence in the pull request or approved artifact store.
A successful structural check does not establish product correctness or scientific validity.

---

## Maintaining the contract

Update the governing specification, reference or runbook when accepted behavior changes. Preserve
requirement IDs and anchors. Link the review from the change history instead of creating a separate
numbered architecture record for every implementation choice.

<!-- EOF -->


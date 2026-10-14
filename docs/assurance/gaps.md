<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Qualification and adoption gaps

This register records unresolved qualification and adoption limits. All entries are open. Owner roles
below identify the required responsibility, not an appointment; assign people and reviewers through
[governance](../../GOVERNANCE.md) before accepting evidence.

Historical observations are dated inputs, not assertions about current hosted settings. Preserve their
original receipts, and obtain fresh evidence for the candidate under review.

<details>
<summary><strong>On this page</strong></summary>

- [Open gaps](#open-gaps)
- [Closure and reassessment](#closure-and-reassessment)

</details>

---

## Open gaps

The implementation paths and assessment plans below establish scope. Their presence does not close a gap.

| Area | Owner role | Current boundary | Required closure evidence |
| --- | --- | --- | --- |
| Product | Specification owner | Existing campaigns execute a mock. | Implemented allocator and accepted [SDD cases](../specs/README.md). |
| Process pilot | Verification owner | Four scoped verifiers, `local` profile, requirement graph retained locally and in CI. | Additional adapters and qualified campaigns; see [pilot adoption](../runbooks/process-pilot.md#trust-boundary-and-future-ci-adoption). |
| Ansible | Automation maintainer | Local preparation and verification only. | Qualified remote inventories, platform adapters and host preparation. |
| Merge protection | Repository administrator | On 2026-09-24, GitHub reported `main` as unprotected and returned no repository rulesets. The integration cannot administer branch protection. | Required checks configured on the target branch, plus a failing PR shown as blocked through the normal merge route. |
| Hosted acceptance | Verification owner | Run `35978469373` cancelled detection and REUSE, skipped dependent checks and failed `CI gate`. It does not validate the reviewed commit. | Complete successful CI and matching artifacts for the selected correction commit. |
| CI adoption | Process owner | Existing workflows call their own Lua scripts. | Protected evaluator, policy authority and retained authenticated evidence. |
| Lifecycle | Process owner | Wider procedures remain proposed. | Assigned owners, adopted procedures and records from actual changes. |
| SPICE edition mapping | Assessment owner | TS 33061:2021 uses the 12207:2017 reference baseline. | Approved mapping before assessing a 12207:2026 lifecycle; see [model selection](framework-mappings.md#spice-models-and-edition-baseline). |
| SPICE process adoption | Process owner and assessment owner | Procedure and model mappings are proposed; no capability rating is established. | Adopted process scope, assigned people, representative records, assessor findings and reviewed improvement results under [workflow assurance](workflow.md#spice-process-assessment). |
| TISAX applicability and assessment | Information-security owner and assessment coordinator | Organizational scope, applicable ISA criteria and assessment result remain unestablished. | Applicability decision, selected scope/objectives/edition, operational evidence, provider assessment and authorized exchange under the [security assessment workflow](workflow.md#tisax-information-security-assessment). |
| Framework assessment | Assessment owner | Mappings indicate possible contributions. | Adopted criteria, applicability decisions and reviewer assessments. |
| Release | Release owner | Mock fixture and scoped publication. | Product qualification and accepted [distribution contracts](../specs/libmemalloc-distribution-SDD.md). |
| Security services | Security owner | Some integrations require external identities or credentials. | Prerequisites from [service bootstrap](../runbooks/security-services.md) and [OpenSSF](openssf.md). |

---

## Closure and reassessment

Record the applicable requirement, selected edition, source revision, configuration, retained evidence and
review decision using the [assessment record contract](../reference/evidence.md#record-states-and-ownership).
An owner proposes closure; an authorized reviewer checks the evidence against the stated acceptance scope.
Record justified exclusions and unresolved findings separately. Missing receipts, assignments or required
results prevent closure. Local cache files must be retained under the campaign's evidence policy.

For external standards, retain the selected normative texts and criteria snapshot before assessing clauses.
An inaccessible or unverified edition reference remains a source gap; a publisher catalogue alone does not
establish compliance. Reopen affected decisions when requirements, implementation, tools, target scope or
service settings change. Keep previous decisions and their evidence available for review.

<!-- EOF -->


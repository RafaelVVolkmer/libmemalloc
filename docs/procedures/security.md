<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Security operations procedure

**Status:** proposed procedure links for LMA-PROC-006 through LMA-PROC-009.
The existing [security policy](../../SECURITY.md) remains authoritative for reporting vulnerabilities.

| Trigger | Responsible role | Procedure and required record |
| --- | --- | --- |
| Vulnerability report | Security contact | Follow the security policy; retain restricted triage, remediation and disclosure records. |
| Dependency change | Dependency owner | Review applicability, update pins and run affected checks; retain the decision and results. |
| Service or access change | Maintainer | Follow [service bootstrap](../runbooks/security-services.md); record authorization and continuity arrangements. |
| Incident or recovery exercise | Incident owner | Record containment, recovery, timeline and follow-up work under the applicable security policy. |

Use the [OpenSSF plan](../assurance/openssf.md) for criterion-specific obligations and the
[gap register](../assurance/gaps.md) for missing services or ownership. Keep private operational records in
an authorized restricted store; public documentation may link to a sanitized summary.

When TISAX obligations are adopted, follow the
[organizational assessment workflow](../assurance/workflow.md#tisax-information-security-assessment).
Map applicable ISA items to actual service owners and operational records. Keep internal readiness review,
audit-provider conclusions and permission to share results as distinct decisions.

<!-- EOF -->


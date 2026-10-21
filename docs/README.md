<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Documentation

Start with [development setup](getting-started/development.md) or the [engineering playbook](playbook.md).
The repository implements a C mock and its engineering automation. Product SDDs describe the
planned allocator; passing mock checks does not qualify that product.

| Area | Read it to |
| --- | --- |
| [Specifications](specs/README.md) | Review product requirements, invariants and planned acceptance cases. |
| [Standards](standards/README.md) | Apply language, CI, versioning and reproducibility rules. |
| [Procedures](procedures/README.md) | Follow responsibilities, reviews and acceptance steps. |
| [Runbooks](runbooks/README.md) | Run checks and campaigns with their prerequisites and outputs. |
| [Reference](reference/README.md) | Understand automation, tool versions, caches and evidence contracts. |
| [Assurance](assurance/README.md) | Review framework mappings, applicability and remaining gaps. |

<details>
<summary><strong>On this page</strong></summary>

- [Status vocabulary](#status-vocabulary)
- [Maintaining these pages](#maintaining-these-pages)

</details>

---

## Status vocabulary

**Implemented** identifies an existing executable path and its stated coverage.
**Pilot** identifies an implemented experiment with restricted scope.
**Proposed** identifies a design or procedure whose adoption or implementation remains pending.
Each runbook must name its scope; a successful command alone does not establish product qualification.
Engineering decisions follow the [engineering review procedure](procedures/decision-making.md).

---

## Maintaining these pages

Keep one canonical definition for each requirement and preserve its identifier and anchor.
Link procedures to standards, and link runbooks to executable scripts instead of copying their policies.
Follow the [documentation guide](getting-started/documentation.md) when changing paths, examples or diagrams.
Keep task inventories inside product SDDs; other documentation uses procedures, reference contracts and evidence.

<!-- EOF -->


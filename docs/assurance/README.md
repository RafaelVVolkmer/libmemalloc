<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Assurance

These documents connect local engineering obligations to assessment scope, evidence and acceptance.
The [C compliance and assurance standard](../standards/c/c-compliance.md) defines the canonical C rules;
[product SDDs](../specs/README.md) define planned allocator contracts. The mappings below explain how
selected external references contribute to those obligations without replacing either authority.

- [Reproducible builds](reproducible-builds.md): reconstruction controls, comparisons and assurance boundaries.
- [OpenSSF plan](openssf.md): project obligations, integrations and release evidence.
- [Framework mappings](framework-mappings.md): proposed mappings and adoption boundaries.
- [Workflow assurance](workflow.md): lifecycle gates, SPICE process assessment and TISAX security evidence.
- [Gap register](gaps.md): remaining implementation, execution and assessment work.

Start with the framework mappings to select editions and applicability, use the relevant assurance plan
to identify evidence, then track unresolved work in the gap register. A local requirement is binding under
its declared project scope; a proposed framework mapping still needs adoption and assessment.

Review evidence against its declared scope. Passing an automation control does not grant a badge,
establish organizational capability or qualify the planned allocator.

- [Formal trust boundary](formal-trust.md)

<!-- EOF -->


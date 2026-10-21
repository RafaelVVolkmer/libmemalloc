<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Framework mappings

**Status:** proposed local allocation; public-source review dated 2026-09-26.
This allocation does not assert equivalence, substitution, certification or conformance. Record applicable
versions, models, scope, tailoring, evidence and accountable roles separately before performing an assessment.

<details>
<summary><strong>On this page</strong></summary>

- [Engineering and assurance responsibilities](#engineering-and-assurance-responsibilities)
- [SPICE models and edition baseline](#spice-models-and-edition-baseline)
- [Other baselines and applicability](#other-baselines-and-applicability)
- [Accountable roles and acceptance records](#accountable-roles-and-acceptance-records)

</details>

---

## Engineering and assurance responsibilities

Specification-led development is a project-defined practice. **Software Design Description (SDD)** names a
design artifact; it does not name a development method. The existing `*-SDD.md` files retain their identifiers
and their combined specification/design content. Use the full phrase for the practice and review the design
artifacts as part of it; the suffix alone makes no claim about compliance with a document standard.

| Reference | Proposed use | Judgment and evidence not established by a tool run alone |
| --- | --- | --- |
| Specification-led development and reviewed design descriptions: project-defined practice | Derive implementation and acceptance criteria from reviewed requirements, specifications and design decisions. | Resolution of ambiguity, stakeholder agreement, design rationale and approval of change impact. |
| TDD | Demonstrate a missing behavior, implement it, then refactor under tests. | Review that tests observe the intended contract, fail for the intended reason and do not merely reproduce the implementation. |
| [ISO/IEC/IEEE 12207][lifecycle]: selected edition | Structure development, operation, support, maintenance and retirement; organize requirements, design, configuration, change and release records. | Lifecycle tailoring, assigned responsibilities, approved baselines, change decisions and release acceptance. |
| SPICE: ISO/IEC 330xx, with explicitly selected reference and assessment models | Assess selected process outcomes and capability; use findings to guide improvement. | Assessment scope, evidence sufficiency, assessor judgment, ratings and improvement priorities. |
| Verification and validation: [IEEE 1012][vv], selected edition | Plan and perform V&V across relevant lifecycle activities, including analysis, review, inspection and testing beyond TDD. | Method and acceptance-criteria adequacy, required independence, anomaly disposition and conclusions about intended use. |
| [NIST SSDF][ssdf]: selected final version | Integrate secure development and vulnerability response into the lifecycle. | Security requirements, threat and risk decisions, vulnerability triage, remediation priorities and disclosure decisions. |
| [ISO/IEC 27001][isms]: where adopted as the organizational security basis | Structure scoped information-security management and its operational records. | Organizational scope, accountable people, risk acceptance, access decisions and management review. |
| [TISAX][tisax] and the applicable [ISA catalog][isa]: where required | Maintain assessment-specific evidence for the agreed organizational scope and objectives. | Scope and objective selection, organizational implementation, risk treatment and assessment conclusions. |
| [OpenSSF Best Practices Badge][badge] | Maintain criterion-specific evidence for Passing, Silver and Gold. | Governance, review arrangements, continuity and other human or organizational criteria. |
| [OSPS Baseline][baseline] | Track separately versioned security controls at the applicable maturity level. | Applicability, evidence sufficiency and decisions for the selected Baseline version. |
| [SLSA][slsa]: selected version, track and level | Establish and verify applicable source and build supply-chain controls and attestations. | Trust decisions, control of build identities and infrastructure, exceptions and release authorization. |
| [Reproducible Builds][rb] | Verify that specified artifacts can be recreated identically from recorded source, environment and instructions. | Reproducibility scope, comparison-procedure adequacy and investigation of mismatches. |

These are local assignments, not claims that each reference prescribes exactly the implementation in its row.
ISO 12207 permits iterative lifecycle approaches; it does not mandate TDD. V&V evaluates the sufficiency of
verification evidence and intended-use conclusions; a passing test suite alone cannot establish those judgments.
SSDF complements organizational information-security management. SLSA controls and provenance do not prove
byte reproducibility, and identical rebuilt bytes do not establish a SLSA level. See the separate
[reproducible-build assurance requirements](reproducible-builds.md).

---

## SPICE models and edition baseline

Use the identification **SPICE: ISO/IEC 330xx process assessment, using explicitly selected process reference
and assessment models**. The reference model defines processes and expected outcomes. The assessment model
provides indicators for evaluating those processes within a measurement framework.

| Element | Role | Proposed mapping baseline |
| --- | --- | --- |
| [ISO/IEC 33002][assessment] | Requirements for conducting process assessments. | 2015 |
| [ISO/IEC 33004][models] | Requirements for process reference, assessment and maturity models. | 2015, corrected English version 2017-04 |
| [ISO/IEC 33020][measurement] | Measurement framework for process capability. | 2019 |
| [ISO/IEC TS 33061][pam] | Assessment model for software lifecycle processes. | 2021 |
| [ISO/IEC/IEEE 12207:2017][prm] | Process reference baseline used by TS 33061:2021. | 2017 for this assessment mapping |

The proposed assessment baseline still requires adoption; it establishes no capability rating. The
[TS 33061 preview][pam-preview] explains its relationship to 12207 and the optional use of 33020 for capability.
[TS 33061:2021, clause 2][pam-normative] normatively references 12207:2017. The newer
[12207:2026 edition][lifecycle] was published in
April 2026. A lifecycle using 2026 therefore needs an approved mapping to the selected 2017 assessment baseline:
record changed processes/outcomes, gaps, evidence impact and assessor acceptance. Do not silently replace the
reference model, infer compatibility between editions or claim that 33061 itself mandates a capability level.

The mapping record must identify the assessment purpose, process subset, measurement framework, rating method,
model editions and authorized assessor before execution. Retain licensed normative texts and applicable
corrections for a clause-level assessment; public catalogue abstracts do not establish conformity.

The [SPICE assessment sequence](workflow.md#spice-process-assessment) connects these models to process
selection, evidence sampling, observations, ratings, review and improvement. Local procedure identifiers
remain separate from model identifiers. A passing CI job is execution evidence, not a capability rating.

---

<a id="other-version-and-sector-boundaries"></a>

## Other baselines and applicability

| Reference | Baseline for this proposal | Selection still required |
| --- | --- | --- |
| IEEE 1012 | 2024 | Applicable V&V activities, rigor and independence for the product scope. |
| NIST SSDF | Final version 1.1, SP 800-218 (2022) | Applicable practices and evidence. Draft revisions do not replace this baseline. |
| ISO/IEC 27001 | 2022 | Organizational scope, amendments and actual adoption. |
| SLSA | Specification 1.2 | Source/build track, target level and evidence; no achieved level claimed here. |
| OSPS Baseline | 2026.08.28 | Applicable maturity level and version-specific control assessment. |
| OpenSSF Badge | Criteria snapshot retained for each assessment | Passing, Silver and Gold assessed separately with official criterion IDs. |
| Reproducible Builds | Definition and local artifact scope retained with each campaign | Exact inputs, environment, instructions, independent rebuild and byte comparison. |

Use the [workflow assurance guide](workflow.md) to apply the selected references to changes, reviews,
verification, configuration management, releases and operational security. Its responsibilities and evidence
groupings are local proposals; exact assessment identifiers come from the adopted reference model.

TISAX uses an organizational information-security scope and the applicable ISA criteria. Record objectives,
locations, selected edition, assessment method, evidence owners and authorized result exchange. It is not
a development lifecycle standard or a SPICE capability model. The
[TISAX workflow](workflow.md#tisax-information-security-assessment) separates operational preparation,
external assessment and restricted result handling. ISO/IEC 27001 adoption alone establishes no TISAX result.

---

## Accountable roles and acceptance records

For every applicable process or control, retain this chain in the [evidence record](../reference/evidence.md):

```text
Reference and version
  -> Applicable requirement or criterion
  -> Process owner
  -> Reviewer or approver
  -> Required evidence
  -> Acceptance or exception decision
```

| Local role | Responsibility | Decision record |
| --- | --- | --- |
| Specification owner and maintainer | Resolve public-contract changes and lifecycle tailoring. | Reviewed requirement, impact, baseline and accepted change. |
| Verification owner | Plan V&V, assess evidence sufficiency and resolve anomalies. | Scope, methods, expected results, actual results and acceptance recommendation. |
| Security owner | Decide vulnerability treatment and disclosure under the security policy. | Restricted risk, triage and remediation/disclosure record. |
| Release owner | Authorize publication of the accepted artifact and evidence set. | Exact identities, required reviews and release authorization. |
| Assessment owner and assessor | Select models, scope and criteria; assess outcomes and capability. | Evidence sufficiency, findings, ratings and improvement priorities. |

Assign actual people, delegates and authority through [governance](../../GOVERNANCE.md); this table assigns
functions, not personnel. Roles may be combined only where the adopted criterion and project policy permit it.
When independent review is required, the author cannot be the sole approver. Record reviewer identity and
independence basis; a second role label on the same person does not supply independence. Missing assignments,
required reviews or unresolved model mappings remain gaps in the [gap register](gaps.md).

Each assessment record must include the following project-defined fields. These fields organize evidence;
they are not a substitute for the selected framework's assessment method.

| Field | Required content |
| --- | --- |
| Reference | Publisher link, exact edition or retained criteria snapshot, requirement identifier and review date. |
| Applicability | Product/process boundary, target configuration, adopted tailoring and justification for exclusions. |
| Local control | Stable requirement ID and implementation revision, with links to the governing contract and change. |
| Evidence | Exact source and tool identities, commands or review method, expected and actual results, retained artifacts and integrity checks. Include failures and inconclusive results. |
| Judgment | Named owner and reviewer, independence basis where required, unresolved gaps, acceptance or exception decision and rationale. |
| Maintenance | Conditions requiring reassessment, including changes to references, implementation, dependencies and supported configurations. |

Keep evidence availability separate from assessment outcome. A configured control or an available report
is not an accepted criterion. Missing evidence remains unresolved; justified inapplicability requires
review and cannot be counted as a passing execution. Reopen affected decisions when their inputs change.

[lifecycle]: https://www.iso.org/standard/90219.html
[prm]: https://www.iso.org/standard/63712.html
[assessment]: https://www.iso.org/standard/54176.html
[models]: https://www.iso.org/standard/54178.html
[measurement]: https://www.iso.org/standard/78526.html
[pam]: https://www.iso.org/standard/80362.html
[pam-preview]: https://webstore.ansi.org/preview-pages/ISO/preview_ISO%2BIEC%2BTS%2B33061-2021.pdf
[pam-normative]: https://cdn.standards.iteh.ai/samples/80362/99075afccb4547b89af87f1ee52aacfe/ISO-IEC-TS-33061-2021.pdf
[vv]: https://standards.ieee.org/ieee/1012/7324/
[ssdf]: https://csrc.nist.gov/pubs/sp/800/218/final
[isms]: https://www.iso.org/standard/27001
[slsa]: https://slsa.dev/spec/v1.2/
[rb]: https://reproducible-builds.org/docs/definition/
[tisax]: https://www.enx.com/handbook/
[isa]: https://www.enx.com/en-US/TISAX/downloads/
[badge]: https://www.bestpractices.dev/en/criteria
[baseline]: https://baseline.openssf.org/versions/2026-08-28

<!-- EOF -->


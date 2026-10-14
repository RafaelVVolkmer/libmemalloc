<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Workflow assurance

**Status:** proposed operating and assessment model. Existing automation supplies bounded execution evidence;
process adoption, capability ratings and organizational security assessments remain unestablished.

Use this guide to connect requirements, changes, verification, releases and security operations to reviewed
process evidence. The [framework mappings](framework-mappings.md) select references and editions; the
[procedure catalog](../procedures/change.md#procedure-catalog) assigns local work. Neither document replaces
an assessment against the adopted criteria.

<details>
<summary><strong>On this page</strong></summary>

- [Scope and authority](#scope-and-authority)
- [Workflow and decision gates](#workflow-and-decision-gates)
- [SPICE process assessment](#spice-process-assessment)
- [TISAX information-security assessment](#tisax-information-security-assessment)
- [Adoption and continuing evidence](#adoption-and-continuing-evidence)

</details>

---

## Scope and authority

Lifecycle organization, process assessment and information-security assessment answer different questions.
Use the following allocation for this repository; it is a project proposal, not a claim that the references
prescribe this particular workflow or its tools.

| Reference | Question addressed | Local application |
| --- | --- | --- |
| [ISO/IEC/IEEE 12207][lifecycle] | Which lifecycle processes and outcomes belong in the selected scope? | Define activities and responsibilities from requirements through maintenance and retirement. |
| [SPICE: ISO/IEC 330xx][assessment] | How well are selected processes performed, and what capability does the evidence support? | Assess actual changes, reviews and verification records against the chosen models. |
| [IEEE 1012][verification] | What verification and validation work is appropriate for the accepted scope? | Plan methods, review independence, anomaly handling and intended-use conclusions. |
| [NIST SSDF][ssdf] | How is secure development integrated into the lifecycle? | Include threat analysis, dependency decisions, vulnerability handling and corrective action. |
| [ISO/IEC 27001][isms] | How is information security managed within the organizational boundary? | Assign risk ownership, access responsibilities and operational security records. |
| [TISAX and ISA][tisax] | What security assessment and exchange obligations apply to the selected organizational scope? | Select applicability and retain security evidence and assessment decisions separately from build results. |

The [change procedure](../procedures/change.md) defines the local engineering sequence. Framework selection
adds explicit outcomes, records and review obligations to that sequence. It does not create a second change
process or automatically require another CI job. A requirement for human judgment remains a review activity.

Before adoption, identify the organizational unit, repositories, services, people, locations and assessment
period. Distinguish product requirements from process outcomes and organizational controls. A passing mock
campaign supports only its declared behavior and execution scope.

---

## Workflow and decision gates

The following project-defined gates connect the existing procedures to their assessment records. Assign
actual people and delegates through [governance](../../GOVERNANCE.md); a role name alone is not an assignment.

| Stage and trigger | Responsible role | Required work and records | Exit decision |
| --- | --- | --- | --- |
| Scope: new activity or changed obligations | Process owner and assurance owner | Select applicable references, editions, process boundaries, expected outcomes, resources and reviewers. Record tailoring and exclusions. | Authorized owner accepts the scope and applicable obligations. |
| Plan: proposed behavior or configuration change | Specification owner and configuration owner | Record the request, affected requirements, security/compatibility impact, baseline, acceptance criteria and verification plan. | Reviewer accepts a bounded implementation and verification scope. |
| Implement: accepted change scope | Author and component owner | Link implementation and tests to the request. Retain design decisions, dependency identities and applicable test-first observations. | Change is ready for review with no unexplained difference from the accepted scope. |
| Verify: candidate revision available | Verification owner | Execute the planned checks; retain actual results, missing work, failed attempts, diagnostics and review findings. | Reviewer determines whether required evidence is complete and sufficient. |
| Accept: evidence ready | Reviewer and maintainer | Review behavior, process records, security findings and permitted exceptions for the exact revision. | Authorized decision accepts the change or returns it for correction. |
| Release: accepted candidate | Release owner | Bind accepted source, artifacts, signatures and publication receipts. Verify required authorization and remaining release conditions. | Publication is authorized for the recorded scope and artifact identity. |
| Operate: access change, incident or scheduled review | Security owner and process owner | Retain access decisions, incident response, recovery exercises and process observations. Investigate recurring failures. | Reviewer accepts corrective action only after checking effectiveness. |

Use the [evidence contract](../reference/evidence.md#record-states-and-ownership) for identity, results,
assessment and acceptance. Every handoff names its input revision, owner, expected output and unresolved
conditions. Required missing evidence blocks acceptance; a retry does not erase the earlier result.
Changes after review require an impact decision and renewed affected evidence.

For example, a toolchain update links the dependency request to the changed lock, impact review, affected
campaign plan, actual results and accepted revision. Its CI report demonstrates execution. The review and
configuration records demonstrate how the change was controlled. Restricted access records remain separate.
This is an illustrative evidence chain, not a completed assessment.

---

## SPICE process assessment

SPICE is used here for general process assessment through ISO/IEC 330xx. Keep three elements distinct:
the process reference model defines purposes and outcomes; the process assessment model supplies assessment
indicators; the measurement framework governs capability judgments. The selected software model is
[ISO/IEC TS 33061:2021][software-model], with the edition relationship recorded in the
[SPICE baseline](framework-mappings.md#spice-models-and-edition-baseline).

[ISO/IEC 33002][assessment] addresses assessment conduct, [ISO/IEC 33004][models] addresses the models, and
[ISO/IEC 33020][measurement] addresses process capability measurement. Capability concerns a process's
ability to meet its goals consistently. Record outcomes and attribute ratings for each assessed process;
do not derive a repository-wide capability label from a green workflow or average unrelated test results.
Use the selected framework's rules for ratings and levels, rather than inventing a CI score conversion.

### Assessment sequence

The following is the proposed local implementation of assessment preparation and follow-up. The assessor
must validate its adequacy against the selected normative method before it is used for a formal conclusion.

1. The assessment sponsor records purpose, process subset, organizational boundary, period, intended use of
   results and authorized assessor. The process owner supplies the adopted procedure and actual assignments.
2. The assessor identifies expected outcomes, applicable attributes, evidence needs and the sampling rationale.
   Select completed and unsuccessful changes, exceptions and recurring operations relevant to the scope.
3. The owner supplies versioned records. The assessor traces them to actual work and resolves gaps through
   review, interviews or observation where appropriate. A written policy does not establish its execution.
4. The assessor records observations, evidence quality, gaps and contradictory results before assigning ratings
   under the adopted model. Mark unsupported conclusions as unresolved rather than filling them from templates.
5. The authorized reviewer accepts the report's scope, rationale and limitations. Keep the capability conclusion
   distinct from the maintainer decision to merge code or release an artifact.
6. The process owner assigns improvement actions, target outcomes and review dates. Reassess effectiveness on
   subsequent work; closing an implementation task alone does not establish improved process performance.

### Evidence from ordinary engineering work

These are local evidence groupings, not official process identifiers or an exhaustive clause mapping.
Populate exact model identifiers only after the process subset and edition have been selected.

| Process under review | Candidate records | Question for the assessor |
| --- | --- | --- |
| Requirements and change control | Request, impact analysis, accepted requirements, version history and review decisions. | Was the agreed scope controlled through implementation and later changes? |
| Configuration management | Source/tool identities, approved lock changes, artifact inventories and release records. | Can the assessed baseline be identified, reconstructed and distinguished from other attempts? |
| Verification and anomaly handling | Planned cases, actual results, missing-work reports, defect decisions and confirmation results. | Were required outcomes checked and contrary evidence resolved under the adopted procedure? |
| Process management | Assigned roles, resources, schedules, monitoring records and corrective decisions. | Was work planned, monitored and adjusted when actual results differed? |
| Process improvement | Findings, causes, action owners and observations from later work. | Did the change improve the identified process outcome within the measured scope? |

The process pilot validates a limited requirement/evidence graph. Its schemas and integrity checks can
support these records, but they do not implement an assessor's judgment or establish organizational adoption.

---

## TISAX information-security assessment

TISAX is an assessment and exchange scheme, not a software development method. The [ENX handbook][tisax]
describes registration, assessment and exchange. Select scope, locations, objectives and the applicable
ISA version. Assessment levels describe assessment depth; they are not SPICE capability ratings.
AL 2 uses a plausibility review; AL 3 includes more extensive verification and on-site activities.
Use the handbook for the exact method and permitted alternatives.

The following local preparation model applies only when the organization adopts TISAX obligations. It does
not claim that a repository, contributor or release has a TISAX result. ISO/IEC 27001 evidence may be relevant,
but its reuse needs a criterion-specific scope review and does not establish a TISAX result by itself.

### Responsibilities and working records

The organization selects its information-security owner, assessment coordinator, evidence custodians and
approved reviewers. They record applicable ISA item IDs and map the workflow's services and records to them.
The table proposes repository-related evidence; it does not reproduce ISA controls or cover the organization.

| Workflow area | Proposed operational record | Review responsibility |
| --- | --- | --- |
| Information handling | Inventory and classification of source, credentials, vulnerability reports, artifacts and assessment records. | Information owner decides protection, access, storage and retention. |
| Identity and access | Authorized grants, privilege changes, periodic access reviews and revocation evidence. | Service owner reconciles actual access with approved responsibilities. |
| CI and release services | Runner boundaries, secret access, service settings, signing authority and approved publication records. | Security and release owners review effective settings and unauthorized-use scenarios. |
| Dependencies and service providers | Service inventory, responsibilities, dependency decisions and reviewed security obligations. | Dependency or service owner assesses inherited risk and unresolved obligations. |
| Incidents and continuity | Restricted incident records, recovery exercises, restored-service checks and follow-up decisions. | Incident owner and reviewer assess response and recovery effectiveness. |
| People and responsibilities | Role assignments, relevant preparation, substitutes and access handover records. | Organizational owner confirms that responsibilities can actually be performed. |

### Preparation, assessment and exchange

Maintain one controlled applicability record linking the adopted ISA items to owners, expected evidence and
observed gaps. Conduct an internal readiness review before presenting records to the selected audit provider.
Retain findings, corrective actions and the provider's conclusions under the assessment's own process.
A local issue closed by a developer cannot stand in for the provider's acceptance.

Keep assessment IDs, scope, dates and allowed result use with the accepted record. The [ENX handbook][tisax]
controls result exchange: decide recipients and sharing depth before authorization, including its permanence
rules. Public GitHub artifacts must not become the default store for restricted assessment material.

Use approved private storage and publish only an authorized summary or opaque reference with an access owner.
The [security procedure](../procedures/security.md) governs local operations; the
[gap register](gaps.md) tracks missing assignments, operational evidence and assessment decisions.

---

## Adoption and continuing evidence

The assurance owner records adoption only after the scope, model editions, responsible people, review
method and evidence locations are accepted. Existing CI controls keep their declared scope; unimplemented
organizational practices remain open gaps. No new CI command grants a process rating or security assessment.

For each review period, retain the selected work sample, findings, decisions and follow-up results. Explain
why the sample is relevant and which activities remain outside the conclusion. Successful examples alone
cannot establish that unsuccessful changes, exceptions and recurring operations were controlled.

Revisit applicability and affected assessments when processes, personnel, services, locations, information
protection needs or reference editions change. Preserve earlier decisions and their inputs. The assurance
owner proposes reassessment; the authorized assessor or reviewer decides its scope under the adopted method.

[lifecycle]: https://www.iso.org/standard/90219.html
[assessment]: https://www.iso.org/standard/54176.html
[models]: https://www.iso.org/standard/54178.html
[measurement]: https://www.iso.org/standard/78526.html
[software-model]: https://www.iso.org/standard/80362.html
[verification]: https://standards.ieee.org/ieee/1012/7324/
[ssdf]: https://csrc.nist.gov/pubs/sp/800/218/final
[isms]: https://www.iso.org/standard/27001
[tisax]: https://www.enx.com/handbook/

<!-- EOF -->


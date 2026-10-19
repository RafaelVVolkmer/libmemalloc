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

## Formal feature validation

The [formal engine design](../../docs/reference/formal-engine.md) defines the mock integration
with this procedure. Use the issue's specification revision and expected evidence inventory as inputs.
The operational order is specification, linked issue, Lean model/proofs, Haskell analysis, production C,
joint validation, review and approval, then merge and issue closure.

For affected formal contracts, retain the initial-state and transition proofs, admissible success/failure
cases, program/contract bindings, certificate coverage, kernel replay, Haskell analysis and representation
proofs required by the issue. Retain C tests as a separate evidence kind. Identify the target, toolchain,
working-source content and external assumptions for the same candidate revision.

The verification owner compares results with expected work. A timeout, unsupported construct, failed
replay or missing required proof blocks acceptance. Bounded evidence cannot satisfy an unbounded claim.
The reviewer checks the meaning of the final theorem and its trust profile as well as the tool results.
CN is a frontend only in this workflow; its import success supplies no verification result.

Complete affected specifications, API documentation, model/C mappings, run instructions and trust
records before acceptance. Archive the evidence with the approved revision and link it from the closing
PR. Changes after the run invalidate affected evidence. Existing model checks remain operational;
the [Ansible commands](../../docs/runbooks/formal-verification.md) execute the supported mock slice.

**Records:** plan, command logs, configuration identity, artifact hashes, report and review decision.
Keep working logs under `.cache/`; retain accepted records under the campaign's artifact policy.

<!-- EOF -->


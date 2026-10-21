<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Haskell Compliance and Assurance

Use this guide to determine whether evidence satisfies the local Haskell controls. A language guide is
neither a certification scheme nor proof that the current engine implements the full allocator specification.

<details>
<summary><strong>On this page</strong></summary>

- [Acceptance controls](#acceptance-controls)
- [Verification matrix](#verification-matrix)
- [Commands and source revisions](#commands-and-source-revisions)

</details>

---

## Acceptance controls

<a id="hcomp-001"></a>

### HCOMP-001: Record the effective build and rule evidence

**MUST · reviewed changes.** Record source revision, dirty inputs if present, GHC/base versions, language,
extensions, dependencies, tool configurations and the applicable control IDs. Give each control a disposition:
pass, fail, not applicable or an approved exception. Missing evidence remains unresolved.
For [HSTYLE-LIQUID-001](haskell-code-standard.md#hstyle-liquid-001), retain a complete owned-file and function
inventory with contracts, checked bodies, source digests, effective Liquid Haskell options and per-function
dispositions. Include local/inferred functions through their enclosing definitions and source spans. Reconcile
new, changed and existing functions against that inventory before asserting full coverage.

**Reason and examples:** Conforming: attach the exact warning/test logs and review the exposed API changes.
Nonconforming: cite a successful formatter run for partiality, termination or FFI ownership.

**Verification and limit:** Compare records with the build plan and source diff. This guide does not add a
machine-readable conformance engine; reviewers own the rule-to-evidence assessment.

<a id="hcomp-002"></a>

### HCOMP-002: Apply the declared warning and analysis profile

**MUST · builds.** Preserve the current library flags `-Wall -Wcompat -Wincomplete-uni-patterns -Werror`.
The executable and test components currently use `-Wall -Werror`. Record these differences. Assess proposed
diagnostics on GHC 9.4.7 before changing the profile; do not imply that `-Wall` enables every warning.

**Reason and examples:** Conforming: add a warning with its expected failure case and compatible source changes.
Nonconforming: claim `-Wpartial-fields` or `-Wmissing-export-lists` is active merely because it appears in Kowainik.

**Verification and limit:** Inspect effective command lines. Candidate additions include those two flags and
`-Wincomplete-record-updates`; these are review suggestions, not configured gates. Warnings do not prove totality.

<a id="hcomp-003"></a>

### HCOMP-003: Make deviations reviewable

**MUST · exceptions to any Haskell control.** Record rule ID, affected symbols/profile, reason, alternative
evidence, residual risk, owner, reviewer and expiry or removal condition in the change review. A `SHOULD`
alternative needs its reason; a `MUST` deviation needs explicit acceptance under the
[engineering decision procedure](../../procedures/decision-making.md).

**Reason and examples:** Conforming: an HLint hint is suppressed for a documented strictness requirement,
with a regression. Nonconforming: disable the linter for the whole tree to avoid one finding.

**Verification and limit:** Review suppression scope and expiration. No exception may label a timeout,
unsupported construct or failed proof as success. If the accepted property changes, update its contract.
The whole-tree refinement requirement cannot receive a module-role or visibility exemption. A recorded gap
for an unsupported function remains incomplete; alternative tests cannot relabel that function as
Liquid Haskell audited.

---

## Verification matrix

| Evidence | Controls it supports | Implemented coverage and limits |
| --- | --- | --- |
| Fourmolu 0.21.0.0 | HSTYLE-FORMAT-001 | Configured layout; no semantic assurance |
| HLint 3.10 | HSTYLE-IMPORT-001, HSTYLE-PARTIAL-001 | Suggestions according to hints; review semantic changes and exceptions |
| GHC 9.4.7 | HSTYLE-LANG-001, HSTYLE-API-001, HSTYLE-PARTIAL-001 | Type checking and selected warnings; incomplete coverage of partiality |
| Engine regressions | HSTYLE-ERROR-001, HSTYLE-NUM-001, HSTYLE-PROTOCOL-001 | Executed cases in `test/Main.hs`; no universal claim |
| Liquid Haskell | HSTYLE-LIQUID-001, HTEST-005 | Required for all owned functions; current `Refined.hs` slice leaves whole-tree conformance incomplete |
| Lean audit and kernel replay | HMOD-003 | Required theorem closure under its admitted axioms and semantics |
| Haddock rendering | HDOC-001 through HDOC-003 | Manual authoring check; no configured package documentation gate |
| Mathematical comment review | HSTYLE-MATH-001, HDOC-004 | Required above every Haskell theorem/property; compare formula, refinement and evidence manually |
| QuickCheck / Hedgehog | HTEST-001 through HTEST-003 | Proposed property-test implementations; neither is a current Cabal dependency |
| Review and runtime measurements | Core termination, resource contracts and FFI | Required where tools cannot establish the control; no configured FFI campaign |

---

## Commands and source revisions

Run from the repository root after the [tool preparation](../../../docs/runbooks/formal-verification.md#prepare-tools):

```sh
lua scripts/verification/check-haskell.lua --lint
lua scripts/verification/check-haskell.lua --test
```

Use the [formal campaign](../../../docs/runbooks/formal-verification.md#staged-ansible-campaign) for refinement checks,
generated theorem audit and C integration evidence. Ordinary Haskell tests disable the Liquid Haskell flag;
record that profile in the result. Neither those tests nor the current formal campaign establishes the new
all-function audit requirement. Keep that coverage gap explicit until the checker and inventory cover every
owned function. Documentation changes use the
[documentation validation commands](../../getting-started/documentation.md#validation).

Tool sources, consulted 2026-10-15:

| Source | Relevant sections and revision |
| --- | --- |
| [Fourmolu configuration](https://fourmolu.github.io/config/) | Option definitions; local version 0.21.0.0 and local YAML are authoritative |
| [HLint 3.10 manual](https://github.com/ndmitchell/hlint/blob/v3.10/README.md) | Hints, configuration and ignoring hints |
| [GHC warnings](https://downloads.haskell.org/ghc/9.4.7/docs/users_guide/using-warnings.html) | Version 9.4.7, individual warnings and groups |
| [Local toolchain lock](../../../tools/toolchain/lock.toml) | Binary identities and digests |
| [Engine environment](../../../scripts/verification/lib/engine_env.lua) | GHC/Cabal execution profile, CN and Liquid Haskell revisions |

<!-- EOF -->


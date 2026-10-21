<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# C verification reference

This reference distinguishes executable policy checks and guide examples from product qualification.
Use the [C analysis runbook](../runbooks/c-analysis.md) to select and execute a campaign.

<details>
<summary><strong>On this page</strong></summary>

- [CICD-007: C evidence](#cicd-007)

</details>

---

<a id="cicd-007"></a>

## CICD-007: C evidence

**Class:** CORRECTNESS. **Obligation:** project requirement.

Clang formatting and clang-tidy enforce the configured subset of the C standard.
Fixtures must cover accepted and rejected code. Simple one-line branches follow
[CSTYLE-022](../standards/c/c-code-standard.md#cstyle-022); loop bodies keep braces.
Review [blank-line groups](../standards/c/c-code-standard.md#cstyle-279) and
[call/check adjacency](../standards/c/c-code-standard.md#cstyle-280) where their meaning
cannot be inferred by the tools.

The same C job runs Cppcheck and Flawfinder with the shared
[C analysis policy](../../tools/lint/code/c/README.md). Cppcheck findings fail
the job; Flawfinder reports risk level 1 and above and fails at level 3. Each
analyzer must accept its clean fixture and reject its defect fixture. Executable
versions and download digests come from `tools/toolchain/lock.toml`.

The [example checker](../../scripts/check/doc_examples.lua) extracts its declared named-file inventory
from the C guides and reports the files and translation units checked. It runs GCC, Clang, and a Clang sanitizer profile.
It does not extract all contextual snippets or the SDD appendix automatically.
Negative examples must remain clearly labeled and outside the executable inventory.

The [C campaign matrix](../runbooks/c-analysis.md) adds independent engines, resolved include
and AST checks. Mock-specific ABI and formal campaigns were removed. The built-in
module checker covers a declared subset; `LIBMEMALLOC_MODULE_CHECKER` remains an
override for a qualified external checker. New product sources require profile
qualification and do not inherit evidence from the mock.

See [build quality and publication](build-quality.md) for numeric gates, compatibility consumers,
compilation metadata and the Pages artifact deployment policy.

<!-- EOF -->


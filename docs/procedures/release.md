<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Release procedure

**Status:** proposed LMA-PROC-005 lifecycle procedure; the existing implementation publishes a mock fixture.
**Owner role:** release owner. **Input:** accepted candidate revision, version and reviewed evidence inventory.

1. Apply the [versioning and signature standards](../standards/versioning/README.md).
2. Complete [verification](verification.md) for the exact candidate and inspect qualification gaps.
3. Follow the [release fixture runbook](../runbooks/release-fixture.md) for artifacts, signatures and channel scope.
4. Use the existing protected workflow for authorized publication. Bind the published artifacts to the reviewed
   evidence and record publication receipts.

The [release workflow](../../.github/workflows/release.yml) starts on a published GitHub release.
The process pilot cannot authorize it. Product distribution channels and allocator qualification remain
subject to the [distribution SDD](../specs/libmemalloc-distribution-SDD.md) and [OpenSSF plan](../assurance/openssf.md).

**Acceptance and records:** reviewed candidate identity, complete required results, authorized signing/publication,
artifact inventory and retrievable receipts. Consult [governance](../../GOVERNANCE.md) for decision authority.

<!-- EOF -->


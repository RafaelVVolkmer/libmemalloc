/-
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-/
import LibMemAllocImp.C.Scalar
import LibMemAllocImp.C.Unsigned
import LibMemAllocImp.Certificates.Finite
import LibMemAllocImp.Certificates.Hoare
import LibMemAllocImp.Certificates.Program
import LibMemAllocImp.Semantics.Finite
import LibMemAllocImp.Semantics.Memory
import LibMemAllocImp.Semantics.Program
import LibMemAllocImp.Semantics.Translation

/-!
# Verification engine

Reusable scalar semantics and certificate rules.
-/

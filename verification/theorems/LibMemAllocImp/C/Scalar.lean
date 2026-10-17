/-
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-/
import LibMemAllocImp.Certificates.Hoare

/-!
# Scalar operation contracts

Small independent contracts exercise the generic frontend and obligation generator.
The predicates name behavior; no replacement C implementation is supplied here.
-/

namespace Allocator.C.Scalar

def pre (_ : IR.Store) : Prop := True

def zero (_ : IR.Store) (result : Nat) (_ : IR.Store) : Prop := result = 0

def one (_ : IR.Store) (result : Nat) (_ : IR.Store) : Prop := result = 1

def bounded (s : IR.Store) : Prop := s 0 ≤ 2 ^ 64 - 1

def identity (initial : IR.Store) (result : Nat) (_ : IR.Store) : Prop :=
  result = initial 0

end Allocator.C.Scalar

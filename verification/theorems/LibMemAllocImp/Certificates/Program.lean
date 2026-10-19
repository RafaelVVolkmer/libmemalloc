/-
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-/
import LibMemAllocImp.Semantics.Program

/-!
# Program coverage certificates

The certificate records the full branch tree and instruction count. Matching this
shape proves structural coverage; a separate Satisfies theorem must justify effects
and postconditions. The acceptance driver requires both results for the same program.
-/

namespace Allocator.Certificates

inductive Coverage where
  | ret
  | write : Coverage → Coverage
  | branch : Coverage → Coverage → Coverage
  deriving DecidableEq, Repr

def coverage : IR.Program → Coverage
  | .ret _ => .ret
  | .write _ _ next => .write (coverage next)
  | .branch _ yes no => .branch (coverage yes) (coverage no)

def nodes : Coverage → Nat
  | .ret => 1
  | .write next => 1 + nodes next
  | .branch yes no => 1 + nodes yes + nodes no

def checkCoverage (program : IR.Program) (certificate : Coverage) : Bool :=
  decide (coverage program = certificate)

/-- Mathematical statement:
∀ (program : IR.Program) (certificate : Coverage) (accepted : checkCoverage program
certificate = true), coverage program = certificate
-/
theorem checkCoverage_sound (program : IR.Program) (certificate : Coverage)
    (accepted : checkCoverage program certificate = true) : coverage program = certificate :=
  of_decide_eq_true accepted

/-- Mathematical statement:
∀ (program : IR.Program), 0 < nodes (coverage program)
-/
theorem coverage_nonempty (program : IR.Program) : 0 < nodes (coverage program) := by
  cases program <;> simp [coverage, nodes] <;> omega

end Allocator.Certificates

-- EOF


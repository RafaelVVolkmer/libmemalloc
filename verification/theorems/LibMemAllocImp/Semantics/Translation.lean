/-
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-/
import LibMemAllocImp.Semantics.Program

/-!
# Translation obligations

An explicit contract for lifting an IR result to a concrete semantics. No instance
for ISO C, CN AIL, or a compiler is assumed here. Each frontend must separately
establish safety, progress and preservation for its concrete state relation.
-/

namespace Allocator.Translation

structure Refines {Concrete : Type} (limit : Nat) (program : IR.Program)
    (admitted : Concrete → Prop) (abstract : Concrete → IR.Store)
    (exec : Concrete → Nat → Concrete → Prop) (safe : Concrete → Prop) : Prop where
  safety : ∀ initial, admitted initial → safe initial
  progress : ∀ initial, admitted initial → ∃ result final, exec initial result final
  preservation : ∀ initial result final, admitted initial → exec initial result final →
    IR.run limit program (abstract initial) = some (result, abstract final)

/-- Mathematical statement:
∀ (Concrete : Type) (limit : ℕ) (program : IR.Program) (admitted : Concrete → Prop) (abstract
: Concrete → IR.Store) (exec : Concrete → ℕ → Concrete → Prop) (safe : Concrete → Prop) (pre :
IR.Store → Prop) (post : IR.Store → ℕ → IR.Store → Prop) (translation : Refines limit program
admitted abstract exec safe) (entry : ∀ initial, admitted initial → pre (abstract initial))
(verified : IR.Satisfies limit program pre post), ∀ initial, admitted initial → safe initial ∧
(∃ result final, exec initial result final) ∧ (∀ result final, exec initial result final →
post (abstract initial) result (abstract final))
-/
theorem transfer {Concrete : Type} (limit : Nat) (program : IR.Program)
    (admitted : Concrete → Prop) (abstract : Concrete → IR.Store)
    (exec : Concrete → Nat → Concrete → Prop) (safe : Concrete → Prop)
    (pre : IR.Store → Prop) (post : IR.Store → Nat → IR.Store → Prop)
    (translation : Refines limit program admitted abstract exec safe)
    (entry : ∀ initial, admitted initial → pre (abstract initial))
    (verified : IR.Satisfies limit program pre post) :
    ∀ initial, admitted initial → safe initial ∧
      (∃ result final, exec initial result final) ∧
      (∀ result final, exec initial result final →
        post (abstract initial) result (abstract final)) := by
  intro initial allowed
  refine ⟨translation.safety initial allowed, translation.progress initial allowed, ?_⟩
  intro result final executed
  obtain ⟨irResult, irFinal, irExecution, correct⟩ := verified _ (entry initial allowed)
  -- Mathematical statement: IR.run limit program (abstract initial) = some (result, abstract
  -- final)
  have same := translation.preservation initial result final allowed executed
  rw [irExecution] at same
  -- Mathematical statement: (irResult, irFinal) = (result, abstract final)
  have equal := Option.some.inj same
  cases equal
  exact correct

end Allocator.Translation

-- EOF


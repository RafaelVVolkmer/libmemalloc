/-
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-/
import LibMemAllocImp.Semantics.Program

/-!
# Weakest preconditions

Compute obligations from the entire expected program. A failed expression is False;
branches retain both possibilities. Soundness supplies a terminating safe execution
and its postcondition for this finite IR.
-/

namespace Allocator.IR

def wp (limit : Nat) : Program → (Nat → Store → Prop) → Store → Prop
  | .ret value, post, s =>
    match eval limit s value with
    | none => False
    | some result => post result s
  | .write cell value next, post, s =>
    match eval limit s value with
    | none => False
    | some result => wp limit next post (update s cell result)
  | .branch condition yes no, post, s =>
    match test limit s condition with
    | none => False
    | some result => if result then wp limit yes post s else wp limit no post s

/-- Mathematical statement:
∀ (limit : ℕ) (program : Program) (post : ℕ → Store → Prop) (initial : Store) (obligations :
wp limit program post initial), ∃ result final, run limit program initial = some (result,
final) ∧ post result final
-/
theorem wp_sound (limit : Nat) (program : Program) (post : Nat → Store → Prop)
    (initial : Store) (obligations : wp limit program post initial) :
    ∃ result final, run limit program initial = some (result, final) ∧ post result final := by
  induction program generalizing initial with
  | ret value =>
    cases h : eval limit initial value with
    | none => simp [wp, h] at obligations
    | some result =>
      exact ⟨result, initial, by simp [run, h], by simpa [wp, h] using obligations⟩
  | write cell value next ih =>
    cases h : eval limit initial value with
    | none => simp [wp, h] at obligations
    | some value =>
      obtain ⟨result, final, executed, valid⟩ :=
        ih (update initial cell value) (by simpa [wp, h] using obligations)
      exact ⟨result, final, by simpa [run, h] using executed, valid⟩
  | branch condition yes no yesProof noProof =>
    cases h : test limit initial condition with
    | none => simp [wp, h] at obligations
    | some result =>
      cases result with
      | false =>
        obtain ⟨result, final, executed, valid⟩ :=
          noProof initial (by simpa [wp, h] using obligations)
        exact ⟨result, final, by simpa [run, h] using executed, valid⟩
      | true =>
        obtain ⟨result, final, executed, valid⟩ :=
          yesProof initial (by simpa [wp, h] using obligations)
        exact ⟨result, final, by simpa [run, h] using executed, valid⟩

/-- Mathematical statement:
∀ (limit : ℕ) (program : Program) (pre : Store → Prop) (post : Store → ℕ → Store → Prop)
(obligations : ∀ s, pre s → wp limit program (post s) s), Satisfies limit program pre post
-/
theorem satisfies_of_wp (limit : Nat) (program : Program) (pre : Store → Prop)
    (post : Store → Nat → Store → Prop)
    (obligations : ∀ s, pre s → wp limit program (post s) s) :
    Satisfies limit program pre post := by
  intro initial admitted
  exact wp_sound limit program (post initial) initial (obligations initial admitted)

end Allocator.IR

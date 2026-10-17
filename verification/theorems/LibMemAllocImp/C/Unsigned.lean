/-
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-/
import LibMemAllocImp.Semantics.Translation

/-!
# Executable unsigned C fragment

Unsigned operations wrap modulo limit + 1, unlike the no-wrap IR. The importer
must establish that arithmetic has unsigned-long type and that signed locals are
boolean. This theorem discharges arithmetic lowering, not parsing, object layout,
pointer provenance or compilation. Byte storage outside the scalar footprint is
explicitly preserved. No concrete execution is defined by the IR interpreter.
-/

namespace Allocator.C.Unsigned

structure State where
  cells : IR.Store
  bytes : Nat → Nat

def eval (limit : Nat) (s : IR.Store) : IR.Expr → Option Nat
  | .literal n => some (n % (limit + 1))
  | .read cell => some (s cell % (limit + 1))
  | .add left right => do
    let a ← eval limit s left
    let b ← eval limit s right
    pure ((a + b) % (limit + 1))
  | .sub left right => do
    let a ← eval limit s left
    let b ← eval limit s right
    pure ((a + (limit + 1) - b) % (limit + 1))
  | .mod left right => do
    let a ← eval limit s left
    let b ← eval limit s right
    if b = 0 then none else pure (a % b)

def test (limit : Nat) (s : IR.Store) : IR.Cond → Option Bool
  | .gt a b => do pure ((← eval limit s b) < (← eval limit s a))
  | .eq a b => do pure (decide ((← eval limit s a) = (← eval limit s b)))

def run (limit : Nat) : IR.Program → State → Option (Nat × State)
  | .ret value, s => do pure (← eval limit s.cells value, s)
  | .write cell value next, s => do
    let value ← eval limit s.cells value
    run limit next { s with cells := IR.update s.cells cell value }
  | .branch condition yes no, s => do
    if ← test limit s.cells condition then run limit yes s else run limit no s

/-- Mathematical statement: IR.bounded limit value = some result implies
value = result and result ≤ limit. -/
theorem bounded_value (limit value result : Nat)
    (h : IR.bounded limit value = some result) : value = result ∧ result ≤ limit := by
  unfold IR.bounded at h
  split at h <;> simp_all

/-- Mathematical statement: successful no-wrap expression evaluation agrees
with modular unsigned evaluation and yields a value at most limit. -/
theorem eval_agrees (limit : Nat) (s : IR.Store) (expression : IR.Expr) (result : Nat)
    (h : IR.eval limit s expression = some result) :
    eval limit s expression = some result ∧ result ≤ limit := by
  induction expression generalizing result with
  | literal n =>
    obtain ⟨rfl, bound⟩ := bounded_value _ _ _ h
    exact ⟨by simp [eval, Nat.mod_eq_of_lt (by omega : n < limit + 1)], bound⟩
  | read cell =>
    obtain ⟨rfl, bound⟩ := bounded_value _ _ _ h
    exact ⟨by simp [eval, Nat.mod_eq_of_lt (by omega : s cell < limit + 1)], bound⟩
  | add a b ia ib | sub a b ia ib | mod a b ia ib =>
    cases ha : IR.eval limit s a with
    | none => simp [IR.eval, ha] at h
    | some av =>
      cases hb : IR.eval limit s b with
      | none => simp [IR.eval, ha, hb] at h
      | some bv =>
        obtain ⟨ea, ba⟩ := ia _ ha
        obtain ⟨eb, bb⟩ := ib _ hb
        simp [IR.eval, ha, hb] at h
        simp [eval, ea, eb]
        first
        | obtain ⟨rfl, bound⟩ := bounded_value _ _ _ h
          exact ⟨by simp [Nat.mod_eq_of_lt (by omega : av + bv < limit + 1)], bound⟩
        | obtain ⟨le, rfl⟩ := h
          constructor
          · rw [show av + (limit + 1) - bv = (av - bv) + (limit + 1) by omega]
            simp [Nat.mod_eq_of_lt (by omega : av - bv < limit + 1)]
          · omega
        | exact ⟨h, h.2 ▸ Nat.le_trans (Nat.mod_le _ _) ba⟩

/-- Mathematical statement: successful IR branch evaluation agrees with the
unsigned C fragment's comparison after operand conversions. -/
theorem test_agrees (limit : Nat) (s : IR.Store) (condition : IR.Cond) (result : Bool)
    (h : IR.test limit s condition = some result) : test limit s condition = some result := by
  cases condition with
  | gt a b | eq a b =>
    cases ha : IR.eval limit s a with
    | none => simp [IR.test, ha] at h
    | some av =>
      cases hb : IR.eval limit s b with
      | none => simp [IR.test, ha, hb] at h
      | some bv =>
        obtain ⟨ea, _⟩ := eval_agrees _ _ _ _ ha
        obtain ⟨eb, _⟩ := eval_agrees _ _ _ _ hb
        simpa [IR.test, test, ha, hb, ea, eb] using h

/-- Mathematical statement: every successful IR execution has the same return
and scalar store in the unsigned machine and preserves all backing bytes. -/
theorem run_agrees (limit : Nat) (program : IR.Program) (s : State)
    (result : Nat) (final : IR.Store)
    (h : IR.run limit program s.cells = some (result, final)) :
    run limit program s = some (result, { s with cells := final }) := by
  induction program generalizing s with
  | ret value =>
    cases he : IR.eval limit s.cells value with
    | none => simp [IR.run, he] at h
    | some v =>
      obtain ⟨ev, _⟩ := eval_agrees _ _ _ _ he
      simp [IR.run, he] at h
      obtain ⟨rfl, rfl⟩ := h
      simp [run, ev]
  | write cell value next ih =>
    cases he : IR.eval limit s.cells value with
    | none => simp [IR.run, he] at h
    | some v =>
      obtain ⟨ev, _⟩ := eval_agrees _ _ _ _ he
      simpa [run, ev] using ih { s with cells := IR.update s.cells cell v }
        (by simpa [IR.run, he] using h)
  | branch condition yes no iy ino =>
    cases he : IR.test limit s.cells condition with
    | none => simp [IR.run, he] at h
    | some v =>
      -- Mathematical statement: concrete and abstract tests select the same branch.
      have ev := test_agrees _ _ _ _ he
      cases v
      · simpa [run, ev] using ino s (by simpa [IR.run, he] using h)
      · simpa [run, ev] using iy s (by simpa [IR.run, he] using h)

def Executes (limit : Nat) (program : IR.Program) (s : State) (result : Nat)
    (final : State) : Prop := run limit program s = some (result, final)

def Safe (limit : Nat) (program : IR.Program) (s : State) : Prop :=
  ∃ result final, Executes limit program s result final ∧ final.bytes = s.bytes

/-- Mathematical statement: a no-wrap IR theorem supplies a Refines instance
for the independently evaluated modular unsigned fragment and its scalar projection. -/
theorem refines (limit : Nat) (program : IR.Program) (pre : IR.Store → Prop)
    (post : IR.Store → Nat → IR.Store → Prop) (proof : IR.Satisfies limit program pre post) :
    Translation.Refines limit program (fun s : State => pre s.cells) State.cells
      (Executes limit program) (Safe limit program) := by
  constructor
  · intro s admitted
    obtain ⟨result, final, executed, _⟩ := proof s.cells admitted
    exact ⟨result, { s with cells := final }, run_agrees _ _ _ _ _ executed, rfl⟩
  · intro s admitted
    obtain ⟨result, final, executed, _⟩ := proof s.cells admitted
    exact ⟨result, { s with cells := final }, run_agrees _ _ _ _ _ executed⟩
  · intro s result final admitted executed
    obtain ⟨r, f, abstract, _⟩ := proof s.cells admitted
    -- Mathematical statement: concrete execution is deterministic.
    have same := run_agrees _ _ s _ _ abstract
    rw [executed] at same
    cases Option.some.inj same
    exact abstract

end Allocator.C.Unsigned

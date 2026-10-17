/-
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-/
import LibMemAllocImp.Semantics.Finite

/-!
# Finite certificates

Accept an explicit state set only when it contains the initial state, is closed under
every input in the declared alphabet, and satisfies the invariant. No search result
or state count is trusted. Duplicate states are harmless; missing successors are not.
-/

namespace Allocator.Certificates

def closed (m : Semantics.Machine) (states : List Nat) : Prop :=
  m.initial ∈ states ∧
    ∀ s ∈ states, m.invariant s ∧ ∀ input ∈ m.inputs, m.step s input ∈ states

instance (m : Semantics.Machine) (states : List Nat) : Decidable (closed m states) :=
  inferInstanceAs (Decidable (_ ∧ ∀ s ∈ states, _ ∧ ∀ input ∈ m.inputs, _))

def checkFinite (m : Semantics.Machine) (states : List Nat) : Bool :=
  decide (closed m states)

/-- Mathematical statement:
∀ (m : Semantics.Machine) (states : List ℕ) (accepted : checkFinite m states = true) (s : ℕ)
(reachable : Semantics.Reach m s), m.invariant s
-/
theorem checkFinite_sound (m : Semantics.Machine) (states : List Nat)
    (accepted : checkFinite m states = true) {s : Nat} (reachable : Semantics.Reach m s) :
    m.invariant s := by
  -- Mathematical statement: closed m states
  have h : closed m states := of_decide_eq_true accepted
  -- Mathematical statement: s ∈ states
  have member : s ∈ states := by
    induction reachable with
    | initial => exact h.1
    | next prior input ih => exact (h.2 _ ih).2 _ input
  exact (h.2 s member).1

end Allocator.Certificates

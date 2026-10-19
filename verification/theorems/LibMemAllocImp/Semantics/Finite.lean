/-
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-/

/-!
# Finite exploration

Reachability for a deterministic transition system with an explicit input alphabet.
The alphabet bounds inputs, not the length of executions.
-/

namespace Allocator.Semantics

structure Machine where
  initial : Nat
  inputs : List Nat
  step : Nat → Nat → Nat
  invariant : Nat → Prop
  invariantDecidable : DecidablePred invariant

attribute [instance] Machine.invariantDecidable

inductive Reach (m : Machine) : Nat → Prop
  | initial : Reach m m.initial
  | next {s input : Nat} : Reach m s → input ∈ m.inputs → Reach m (m.step s input)

end Allocator.Semantics

-- EOF


/-
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-/

/-!
# Sequential word programs

A finite control-flow tree over scalar cells. Arithmetic must fit the declared word
bound; failed evaluation is a safety failure, not a discarded execution. This IR
requires absence of unsigned wrap in addition to the C verifier's safety contract.
The C importer and its representation of object fields remain a trust boundary.
-/

namespace Allocator.IR

abbrev Store := Nat → Nat

inductive Expr where
  | literal : Nat → Expr
  | read : Nat → Expr
  | add : Expr → Expr → Expr
  | sub : Expr → Expr → Expr
  | mod : Expr → Expr → Expr
  deriving DecidableEq, Repr

inductive Cond where
  | gt : Expr → Expr → Cond
  | eq : Expr → Expr → Cond
  deriving DecidableEq, Repr

inductive Program where
  | ret : Expr → Program
  | write : Nat → Expr → Program → Program
  | branch : Cond → Program → Program → Program
  deriving DecidableEq, Repr

def update (s : Store) (cell value : Nat) : Store :=
  fun index => if index = cell then value else s index

def bounded (limit value : Nat) : Option Nat :=
  if value ≤ limit then some value else none

def eval (limit : Nat) (s : Store) : Expr → Option Nat
  | .literal n => bounded limit n
  | .read cell => bounded limit (s cell)
  | .add left right => do
    let a ← eval limit s left
    let b ← eval limit s right
    bounded limit (a + b)
  | .sub left right => do
    let a ← eval limit s left
    let b ← eval limit s right
    if b ≤ a then some (a - b) else none
  | .mod left right => do
    let a ← eval limit s left
    let b ← eval limit s right
    if b = 0 then none else some (a % b)

def test (limit : Nat) (s : Store) : Cond → Option Bool
  | .gt left right => do
    let a ← eval limit s left
    let b ← eval limit s right
    pure (decide (b < a))
  | .eq left right => do
    let a ← eval limit s left
    let b ← eval limit s right
    pure (decide (a = b))

def run (limit : Nat) : Program → Store → Option (Nat × Store)
  | .ret value, s => do
    let result ← eval limit s value
    pure (result, s)
  | .write cell value next, s => do
    let result ← eval limit s value
    run limit next (update s cell result)
  | .branch condition yes no, s => do
    let result ← test limit s condition
    if result then run limit yes s else run limit no s

def Satisfies (limit : Nat) (program : Program) (pre : Store → Prop)
    (post : Store → Nat → Store → Prop) : Prop :=
  ∀ initial, pre initial →
    ∃ result final, run limit program initial = some (result, final) ∧ post initial result final

end Allocator.IR

-- EOF


/-
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-/
import Std

/-!
# Regions, generations and fractional permissions

Finite permission units model fractions of a fixed positive budget. Pointers carry
allocation identity and generation, rather than an integer address alone. This is
an abstract ownership algebra; the C frontend does not yet establish this relation.
-/

namespace Allocator.Memory

structure Region where
  identity : Nat
  generation : Nat
  size : Nat
  live : Bool
  deriving DecidableEq, Repr

structure Pointer where
  region : Nat
  generation : Nat
  offset : Nat
  deriving DecidableEq, Repr

structure Permission where
  pointer : Pointer
  length : Nat
  share : Nat
  deriving DecidableEq, Repr

def valid (region : Region) (permission : Permission) : Prop :=
  region.live = true ∧ permission.pointer.region = region.identity ∧
  permission.pointer.generation = region.generation ∧
  permission.pointer.offset + permission.length ≤ region.size

def readable (budget : Nat) (region : Region) (permission : Permission) : Prop :=
  valid region permission ∧ 0 < permission.share ∧ permission.share ≤ budget

def writable (budget : Nat) (region : Region) (permission : Permission) : Prop :=
  valid region permission ∧ 0 < budget ∧ permission.share = budget

def overlaps (a b : Permission) : Prop :=
  a.pointer.region = b.pointer.region ∧ a.pointer.generation = b.pointer.generation ∧
  0 < a.length ∧ 0 < b.length ∧
  a.pointer.offset < b.pointer.offset + b.length ∧
  b.pointer.offset < a.pointer.offset + a.length

def compatible (budget : Nat) (a b : Permission) : Prop :=
  overlaps a b → a.share + b.share ≤ budget

/-- Mathematical statement:
∀ (budget : ℕ) (region : Region) (a b : Permission) (write : writable budget region a) (alias
: overlaps a b) (combined : compatible budget a b), b.share = 0
-/
theorem exclusive_excludes_alias (budget : Nat) (region : Region) (a b : Permission)
    (write : writable budget region a) (alias : overlaps a b)
    (combined : compatible budget a b) : b.share = 0 := by
  -- Mathematical statement: a.share + b.share ≤ budget
  have bound := combined alias
  obtain ⟨_, _, full⟩ := write
  omega

/-- Mathematical statement:
∀ (budget : ℕ) (region : Region) (permission : Permission) (expired : region.live = false), ¬
readable budget region permission
-/
theorem expired_unreadable (budget : Nat) (region : Region) (permission : Permission)
    (expired : region.live = false) : ¬ readable budget region permission := by
  intro h
  -- Mathematical statement: region.live = true
  have live := h.1.1
  simp [expired] at live

/-- Mathematical statement:
∀ (region : Region) (permission : Permission) (stale : permission.pointer.generation ≠
region.generation), ¬ valid region permission
-/
theorem generation_rejects_stale (region : Region) (permission : Permission)
    (stale : permission.pointer.generation ≠ region.generation) :
    ¬ valid region permission := by
  intro h
  exact stale h.2.2.1

/-- Mathematical statement:
∀ (share left : ℕ) (fits : left ≤ share), left + (share - left) = share
-/
theorem split_conserves (share left : Nat) (fits : left ≤ share) :
    left + (share - left) = share := by omega

/-- Mathematical statement:
∀ (budget : ℕ) (region : Region) (permission : Permission) (h : writable budget region
permission), readable budget region permission
-/
theorem write_implies_read (budget : Nat) (region : Region) (permission : Permission)
    (h : writable budget region permission) : readable budget region permission := by
  obtain ⟨validity, positive, full⟩ := h
  exact ⟨validity, by omega, by omega⟩

end Allocator.Memory

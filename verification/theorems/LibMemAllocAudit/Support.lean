/-
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-/
import Lean

/-!
# AuditSupport

Transitive theorem axiom audit with an explicit trust policy.
-/

open Lean Elab Command in
elab "#audit_theorem " id:ident : command => do
  let name ← liftCoreM <| resolveGlobalConstNoOverload id
  let env ← getEnv
  unless (env.find? name).any (·.isTheorem) do
    throwError "Expected theorem {name}"
  for ax in (← collectAxioms name) do
    unless #[``propext, ``Quot.sound, ``Classical.choice].contains ax do
      throwError "Forbidden axiom {ax} in {name}"
  logInfo m!"Axiom audit passed: {name}"

open Lean Elab Command in
elab "#audit_allocator" : command => do
  let env ← getEnv
  let allowed := #[``propext, ``Quot.sound, ``Classical.choice]
  let mut checked : Nat := 0
  for (name, info) in env.constants.toList do
    if (`Allocator).isPrefixOf name && info.isTheorem then
      for ax in (← collectAxioms name) do
        unless allowed.contains ax do
          throwError "Forbidden axiom {ax} in {name}"
      checked := checked + 1
  logInfo m!"Axiom audit: {checked} theorem declarations; \
    only propext, Quot.sound, Classical.choice allowed."

-- EOF


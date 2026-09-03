# Hamiltonian simulation (Trotterization) as a playground page

## Context

No page in the set simulates physics — the original motivation for quantum computers
(Feynman's 1982 proposal). Page 18's VQE gets closest, but it minimizes an energy rather than
evolving a state in time. This page closes that gap with **no `SwiftQiskitCore` changes**:

- The target Hamiltonian, a transverse-field Ising chain, is assembled entrywise from Pauli
  tensor products via `⊗` — page 18's idiom for H₂, reused for a different physical system.
- `Matrix` has no `+`/scalar-multiply/`expm`, so page-level `addM`/`scaleM`/`expm` helpers are
  required (`expm` by scaling-and-squaring Taylor series, built only on `Matrix *`) — the
  ground truth against which the gate-based Trotter circuit is graded.
- The key gate identity, exp(−iθ·Z⊗Z/2) = `cx(0,1); rz(θ,1); cx(0,1)`, uses only existing
  circuit methods (`cx`, `rz`) and Core's exact `RZGate` (which *is* exp(−iθZ/2) with no
  approximation, `Sources/SwiftQiskitCore/Gates/Rotation.swift:48-63`).

## The math, and what the plan verified

All figures were computed by compiling `SwiftQiskitCore` standalone with `swiftc` and running
the page's exact math in a driver executable.

- **`expm` self-check.** exp(−iθX/2) computed via the page's own Taylor/scaling-and-squaring
  `expm` vs. Core's `RXGate.matrix(theta:)`: max entrywise deviation **1.11e-16** at θ=0.7 —
  the helper is trustworthy before it's used as ground truth for anything else.
- **The ZZ-rotation identity, derived and checked, not assumed.** exp(−iθ·Z⊗Z/2) via `expm`
  vs. the gate-built `cx(0,1); rz(θ,1); cx(0,1)`: max entrywise deviation **1.24e-16** at
  θ=0.7. Confirms CX-conjugation maps Z⊗I ↔ Z⊗Z in Core's exact convention, with no sign
  correction needed.
- **Model:** 2-qubit Ising chain H = −J·Z⊗Z − h·(X⊗I + I⊗X), J=1.0, h=0.5. Trotter step:
  exp(−i H_ZZ dt)·exp(−i H_X dt) (order 1) or the symmetrized half-ZZ/full-X/half-ZZ form
  (order 2, Suzuki), built from the ZZ identity and `RXGate` directly.
- **First-order error halves per doubling of n** (t=1.0, deviation from exact
  `expm(−iHt)` vs. Trotterized unitary, max entrywise): n=1 → 0.3744, n=2 → 0.1788,
  n=4 → 0.0879, n=8 → 0.0437, n=16 → 0.0218, n=32 → 0.0109 — each step almost exactly halves
  the error, the textbook O(1/n) scaling.
- **Second-order (Suzuki) error quarters per doubling**: n=1 → 0.1396, n=2 → 0.0294,
  n=4 → 0.00701, n=8 → 0.00173, n=16 → 0.000432, n=32 → 0.000108 — each doubling divides the
  error by ~4, the textbook O(1/n²) scaling, confirmed at *no extra gate cost per step* over
  the naive first-order form's single ZZ application (Suzuki spends two half-ZZ steps but only
  one X-layer, same asymptotic gate count).
- **⟨Z₀⟩(t) tracks the exact curve.** Starting from |00⟩, exact ⟨Z₀⟩(t=1) = 0.671987;
  1st-order Trotter at n=2 gives 0.645963 (visibly off), at n=8 gives 0.670495 (within 0.0015)
  — the observable-level error shrinks the same way the operator-level error does.
- **Why the error exists, shown not asserted.** The commutator [Z⊗Z, X⊗I] = ZZ·X0 − X0·ZZ has
  max entry magnitude **2.0** (manifestly non-zero). A commuting-only Hamiltonian
  (H = −J·Z⊗Z alone, dropping the field term) is **exact at n=1**: max deviation **0.0**
  between `expm(−iHt)` and the single-step Trotter unitary — because with only one term there
  is nothing to split.

## Changes

### New page `Playgrounds.playground/Pages/21Trotter.xcplaygroundpage/Contents.swift`

Console plus one live chart, six sections: the Ising Hamiltonian assembled entrywise; `expm`
self-checked against `RXGate`; the ZZ-rotation identity derived and checked; first- and
second-order Trotter error vs. n; the observable-level ⟨Z₀⟩(t) comparison; the commutator as
the source of the error, with the commuting-Hamiltonian exact case as the contrast.

The live chart reuses `CHSHChartView` unchanged (exact ⟨Z₀⟩(t) as a line, n=2 and n=8
Trotterized points as two scatter series) — no new shared view, no new exposure to the Xcode
27 beta `@State` bug.

### Docs

- `CLAUDE.md`: add the `21Trotter` bullet.
- `PlaygroundDocs/21TROTTERHELP.md`: user-facing guide (deferred with the page).
- This file records the plan.
- `README.md`: a `### 21Trotter` section; the gate tables' "Used in" column (`rz`/`cx` gain a
  Hamiltonian-simulation use alongside page 16's QFT use).
- `STATUSandTODO.md`: an entry alongside pages 19–20.
- `PLAYGROUNDSUPPORT.md`: a `21Trotter` row in "Which pages use what."
- `00TOC.xcplaygroundpage`: a bullet plus the guide-list update.
- Page 20 gets `[Next]`; page 21 gets `[Previous]`/`[Next]`.

## Explicitly not doing

- **No `expm` in Core.** It stays a page-level helper, exactly like page 12's QFT† and page
  18's Hamiltonian — self-checked against an existing exact gate (`RXGate`) rather than
  trusted blindly.
- **No randomized product formulas (qDRIFT)** or orders beyond second (Suzuki) — one order
  comparison makes the 1/n vs. 1/n² point; more orders would repeat it.
- **No fermionic Jordan–Wigner derivation of the Ising Hamiltonian** — it is already a native
  spin (qubit) model, unlike page 18's H₂, which needed the JW transform from fermionic
  operators. That distinction is worth one sentence in the page, not a derivation.

## Verification

1. Every number above was computed by compiling `SwiftQiskitCore`'s sources standalone with
   `swiftc` (bypassing an `ENABLE_DEBUG_DYLIB` requirement on `RunCodeSnippet` for
   executable-target previews) and running the page's exact math in a driver executable.
   `expm` was validated against `RXGate` *before* being trusted for the ZZ-identity and
   Trotter-error checks, in that order.
2. `mcp__xcode-tools__BuildProject` — confirmed green on the `SwiftQiskit` scheme.
3. `swift test` / `RunAllTests` under `SwiftQiskit-Package` — no Core changes proposed; not
   re-run for this plan since only Docs were written.
4. When the page is built: open `21Trotter` in Xcode and run it (console + chart only, no
   Bloch-sphere live view, so no new `@State` exposure beyond what `CHSHChartView` already
   carries); re-copy the `libcups` shim immediately before running
   (`PLAYGROUNDSUPPORT.md` § "Xcode 27 beta workarounds").

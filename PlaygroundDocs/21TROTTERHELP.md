# Trotterization (Hamiltonian simulation) — help & usage guide

User-facing guide to the `21Trotter` playground page. The implementation plan is in
`21TROTTERPLAN.md`.

## What the page shows

No earlier page simulates physics — Feynman's original 1982 motivation for quantum computers.
This page evolves a spin chain in time under a Hamiltonian that doesn't fit in a single gate,
by splitting it into pieces small enough to compile (Trotterization), and shows exactly why
that split introduces error.

## Section by section

**Section 1 — `expm`, self-checked.** `Matrix` has no matrix exponential, so one is built by
scaling-and-squaring Taylor series — and checked against Core's *exact* `RXGate` before being
trusted as ground truth for anything else.

**Section 2 — the ZZ-rotation identity, derived not assumed.** exp(−iθ·Z⊗Z/2) =
`cx(0,1); rz(θ,1); cx(0,1)`, checked against `expm` directly. Core's `RZGate` is exactly
exp(−iθZ/2), so this holds with no sign correction.

**Section 3 — Trotter error scaling.** For H = −J·Z⊗Z − h·(X⊗I + I⊗X): first-order error
roughly halves each time the step count n doubles (O(1/n)); second-order (Suzuki) error
roughly quarters (O(1/n²)) at the same gate cost per step.

**Section 4 — the observable-level view.** ⟨Z₀⟩(t) tracked at n=2 (visibly off) vs. n=8 (much
closer) against the exact curve — the error shows up in a measurable quantity, not just an
abstract operator norm.

**Section 5 — why the error exists.** The commutator [Z⊗Z, X⊗I] is directly computed and shown
non-zero; a Hamiltonian with only one term (nothing to split) is exact at n=1 — cause, not just
symptom.

**Section 6 — live view.** The exact ⟨Z₀⟩(t) curve with Trotterized samples at n=2 and n=8
overlaid, on the shared `CHSHChartView`.

## Running the page

1. Open `Playgrounds.playground` in Xcode and select **`21Trotter`** (or follow `[Next]` from
   `20Tomography`).
2. Make sure the **SwiftQiskit** scheme is active and builds.
3. This page has a SwiftUI live view (`CHSHChartView`, unchanged from pages 15/18). On Xcode
   27 betas, re-copy the `libcups` shim immediately before running (`PLAYGROUNDSUPPORT.md`
   § "Xcode 27 beta workarounds").
4. Run the page. Nothing here is statistical — every number is exact given the fixed
   Hamiltonian, step counts, and `expm` term count.

## Expected output

```text
expm(-iθX/2) vs. RXGate.matrix(θ=0.7): max diff = 1.11e-16
expm(-iθZ⊗Z/2) vs. cx;rz;cx (θ=0.7): max diff = 1.24e-16

1st-order Trotter error (max diff from exact), t=1:
  n=1   0.374436
  n=2   0.178803
  n=4   0.087851
  n=8   0.043722
  n=16   0.021835
  n=32   0.010914

2nd-order (Suzuki) Trotter error:
  n=1   0.139583
  n=2   0.029407
  n=4   0.007011
  n=8   0.001732
  n=16   0.000432
  n=32   0.000108

⟨Z₀⟩ at t=1, exact:            0.671987
⟨Z₀⟩ at t=1, 1st-order n=2:  0.645963
⟨Z₀⟩ at t=1, 1st-order n=8:  0.670495

max |[Z⊗Z, X⊗I]| entry: 2.000000
commuting-only Hamiltonian, n=1 error: 0.00e+00
```

## The live view

`CHSHChartView` plots the exact ⟨Z₀⟩(t) curve (blue line) against Trotterized samples at
n=2 (orange dots, visibly off the curve) and n=8 (green dots, tracking it closely).

## Using it in your own code

```swift
import SwiftQiskitCore

// exp(-iθ·Z⊗Z/2) via the exact gate identity — no expm needed at runtime.
func zzRotation(_ theta: Double) -> Matrix {
    let I2 = Matrix.identity(size: 2)
    let cx = CNOTGate.matrix(qubits: 2, control: 0, target: 1)
    let rz1 = I2.tensor(RZGate.matrix(theta: theta))
    return cx * rz1 * cx
}

// One first-order Trotter step for H = -J·Z⊗Z - h·(X⊗I + I⊗X):
func trotterStep(J: Double, h: Double, dt: Double) -> Matrix {
    let I2 = Matrix.identity(size: 2)
    let uZZ = zzRotation(-2 * J * dt)
    let rx = RXGate.matrix(theta: -2 * h * dt)
    return (rx.tensor(I2)) * (I2.tensor(rx)) * uZZ
    // NOTE: apply n times for evolution over time n·dt.
}
```

## Troubleshooting

- **Page won't run / no output** — the SwiftQiskit scheme must build first.
- **`Failed to load linked library cups`** — the Xcode 27 beta evaluator bug; re-copy the
  shim (`PLAYGROUNDSUPPORT.md`).
- **`expm` self-check doesn't land near 1e-16** — check the scaling-and-squaring loop halves
  the matrix until its max entry magnitude is ≤ 0.5 before the Taylor sum, and squares back up
  the same number of times afterward.
- **Trotter error doesn't shrink with n** — check the *same* Hamiltonian and total time `t` are
  used for both the exact `expm` curve and every Trotterized `n`; increasing `n` while
  changing `t` won't show the O(1/n) trend.

# State tomography — help & usage guide

User-facing guide to the `20Tomography` playground page. The implementation plan is in
`20TOMOGRAPHYPLAN.md`.

## What the page shows

Every earlier page read a state's amplitudes directly off the `StateVector` — something no
real device permits. This page reconstructs a state from `measure(shots:)` statistics alone,
the honest version of "what a real device gives you," and depends on page 19's mixed states
for its most important result.

## Section by section

**Section 1 — basis rotations, pinned before use.** `measure(shots:)` only reads the Z basis.
Getting ⟨X⟩ needs `h`; ⟨Y⟩ needs `sdg` then `h` — checked here by rotating `|+i⟩` (a known
Y-eigenstate) and confirming it collapses deterministically, rather than assumed.

**Section 2 — the estimator.** ⟨A⟩ ≈ (N₀−N₁)/N, checked against the exact
`psi† * A * psi` on a generic tilted state before trusting it statistically.

**Section 3 — error scales as 1/√N.** RMS error of the estimator against the exact value,
over 20 trials per N, falls by roughly √10 each time N grows tenfold.

**Section 4 — unphysical estimates: pure vs. mixed.** The surprising result: for a *pure*
state (sitting exactly on the Bloch ball's boundary), an independently-estimated (x,y,z)
lands outside the unit ball roughly **half the time no matter how large N is** — symmetric
per-axis noise straddles a boundary point equally in both directions. Only a genuinely
*mixed* state's (page 19's territory) frequency shrinks toward zero with N.

**Section 5 — an entangled qubit's marginal, from shots alone.** Reconstructing a Bell pair's
qubit-0 Bloch vector from `measure(shots:)` lands at the origin — page 19's exact ρ_A = I/2,
now measured rather than derived, and page 13's no-cloning restated as "one copy is never
enough."

**Section 6 — why full tomography doesn't scale.** A cost table: n qubits need 3ⁿ measurement
settings — exactly why page 18's VQE measures individual Pauli terms instead.

**Section 7 — live view.** The true ρ_A = I/2 next to the shot-reconstructed marginal from
Section 5, both as `BlochSphereView`s via this page's (page-19-added) `BlochVector(x:y:z:)`.

## Running the page

1. Open `Playgrounds.playground` in Xcode and select **`20Tomography`** (or follow `[Next]`
   from `19Noise`).
2. Make sure the **SwiftQiskit** scheme is active and builds.
3. This page has a SwiftUI live view. On Xcode 27 betas, re-copy the `libcups` shim
   immediately before running (`PLAYGROUNDSUPPORT.md` § "Xcode 27 beta workarounds").
4. Run the page. Almost everything is statistical (shots have no fixed seed) — expect the
   digits to vary slightly run to run; the trends described below are what to check.

## Expected output

```text
|+i⟩ rotated by (Sdg; H): |0⟩: 0.9999999999999998
|1⟩: 0.0

exact   ⟨X⟩=0.612372  ⟨Y⟩=0.612374  ⟨Z⟩=0.499998
N=100000 ⟨X⟩=0.6122   ⟨Y⟩=0.6142   ⟨Z⟩=0.4977     (statistical, within ~0.005-0.01)

N         RMS error in ⟨X⟩ (20 trials)
100     ~0.08
1000     ~0.025
10000    ~0.008
100000   ~0.003        (statistical — falls with N, roughly as 1/√N)

Pure state (tilted |ψ⟩), unphysical (|r|>1) frequency over 1000 trials:
  N=10: ~0.6
  N=50: ~0.55
  N=200: ~0.53
  N=1000: ~0.51
  N=5000: ~0.50        (plateaus near 0.5 — does not trend to 0)

Mixed state (|r|=0.5), unphysical frequency over 1000 trials:
  N=10: ~0.08-0.10
  N=50: 0.0
  N=200: 0.0
  N=1000: 0.0
  N=5000: 0.0           (shrinks to 0 quickly)

Bell-pair qubit-0 marginal from shots: (x,y,z) ≈ (0, 0, 0), |r| ≈ 0.01

qubits   settings (3ⁿ)
1        3
2        9
3        27
4        81
5        243
```

## The live view

Two `BlochSphereView`s: the true ρ_A = I/2 (a point at the sphere's exact center) next to the
shot-reconstructed marginal, which lands very close to — but not exactly at — the same point.

## Using it in your own code

```swift
import SwiftQiskitCore

let H = HadamardGate.matrix
let Sdg = SDaggerGate.matrix

func basisRotation(_ axis: String, _ s: inout StateVector) {
    switch axis {
    case "X": s.apply(H)
    case "Y": s.apply(Sdg); s.apply(H)
    default: break
    }
}

func estimate(_ axis: String, psi: StateVector, shots: Int) -> Double {
    var plus = 0
    for _ in 0..<shots {
        var s = psi
        basisRotation(axis, &s)
        if s.measure() == 0 { plus += 1 }
    }
    return 2 * Double(plus) / Double(shots) - 1   // ⟨A⟩ ≈ (N0 - N1) / N
}
```

## Troubleshooting

- **Page won't run / no output** — the SwiftQiskit scheme must build first.
- **`Failed to load linked library cups`** — the Xcode 27 beta evaluator bug; re-copy the
  shim (`PLAYGROUNDSUPPORT.md`).
- **The unphysical-frequency numbers look "wrong" (not shrinking for the pure state)** —
  that's the expected, if counterintuitive, result: a *pure* state sits exactly on the Bloch
  ball's boundary, so noise pushes the estimate out about as often as in, at any N. Only the
  mixed-state row should shrink toward zero.
- **Y-basis results look flipped** — double-check the rotation order is `sdg` *then* `h`; the
  reverse order does not diagonalize Y (Section 1 shows why).

# VQE (the variational quantum eigensolver) — help & usage guide

User-facing guide to the `18VQE` playground page. The implementation plan is in
`18VQEPLAN.md`.

## What the page shows

Every earlier page runs a fixed circuit. This page runs the loop that defines the NISQ era: a
parameterized circuit ("ansatz") prepares a trial state, a Hamiltonian's expectation value is
measured on it, and a classical optimizer nudges the parameter downhill — hunting for a
ground-state energy without ever diagonalizing the Hamiltonian directly. The target is the
qubit Hamiltonian for H₂ in a minimal basis, small enough that its exact answer is checkable by
hand.

## Section by section

**Section 1 — the Hamiltonian.** `Matrix` has no `+` or scalar multiply, so
H = g0·I⊗I + g1·Z⊗I + g2·I⊗Z + g3·Z⊗Z + g4·Y⊗Y + g5·X⊗X is assembled entrywise (page 12's
QFT† idiom), with the Pauli tensor products built via Core's `⊗`.

**Section 2 — the ansatz.** `x(0); ry(θ,1); cx(1,0)` prepares
cos(θ/2)|10⟩ + sin(θ/2)|01⟩ — one real parameter, provably confined to the {|01⟩,|10⟩}
subspace for every θ (checked: the |00⟩ and |11⟩ amplitudes are exactly 0).

**Section 3 — the energy.** E(θ) = ⟨ψ(θ)|H|ψ(θ)⟩ via page 08's `psi† * H * psi` idiom.

**Section 4 — the exact answer.** Because the ansatz never leaves a 2×2 block of H, that
block's eigenvalues are the exact ground energy — closed form, no eigensolver, used purely to
grade the optimizer.

**Section 5 — parameter-shift gradients.** dE/dθ = [E(θ+π/2) − E(θ−π/2)]/2 is *exact* for a
single-Pauli-rotation gate, not an approximation — pinned against an ordinary finite difference
before trusting it.

**Section 6 — gradient descent.** Plain gradient descent from θ = 0, fixed learning rate,
converging to the exact ground energy within ~10 steps.

**Section 7 — live view.** The E(θ) landscape as a line, the optimizer's own 41 visited points
as a scatter walking downhill into the well — on `CHSHChartView`, unchanged from page 15.

## Running the page

1. Open `Playgrounds.playground` in Xcode and select **`18VQE`** (or follow `[Next]` from
   `17DeutschJozsa`).
2. Make sure the **SwiftQiskit** scheme is active and builds.
3. This page has a SwiftUI live view (`CHSHChartView`, in `Sources/`). On Xcode 27 betas,
   re-copy the `libcups` shim immediately before running (`PLAYGROUNDSUPPORT.md`
   § "Xcode 27 beta workarounds").
4. Run the page. Output is annotated inline with `// Expected:` comments; nothing in this page
   is statistical — every number is exact given the fixed learning rate and starting point.

## Expected output

```text
Hamiltonian assembled from 6 Pauli terms.
ansatz(0.9): |00⟩=0.0  |01⟩=0.4349655...  |10⟩=0.9004471...  |11⟩=0.0

θ        E(θ)
0.000000  -1.830200
1.570796  -0.870000
3.141593  -0.273800
4.712389  -1.234000

exact electronic ground energy = -1.851199 Ha
total with nuclear repulsion   = -1.145699 Ha

θ      param-shift    finite-diff
0.000000  0.182000     0.182000
0.400000  0.470678     0.470678
1.000000  0.753168     0.753168
2.500000  0.319923     0.319923

step   θ           E(θ)
1      -0.182000   -1.850288
10      -0.229744   -1.851199
20      -0.229744   -1.851199
30      -0.229744   -1.851199
40      -0.229744   -1.851199

converged: θ = -0.229744, E = -1.851199
error vs. exact = 0.00e+00
```

## The live view

`CHSHChartView` (shared with page 15) plots two series: the blue E(θ) curve over one full
period, and orange scatter dots at the 41 (θ, E(θ)) points gradient descent actually visited —
clustering tightly into the well near θ ≈ -0.230 by the tenth point.

## Using it in your own code

```swift
import SwiftQiskitCore

let g: [Double] = [-0.4804, 0.3435, -0.4347, 0.5716, 0.0910, 0.0910]
let I2 = Matrix.identity(size: 2)
let terms: [(Double, Matrix)] = [
    (g[0], I2 ⊗ I2), (g[1], PauliZGate.matrix ⊗ I2), (g[2], I2 ⊗ PauliZGate.matrix),
    (g[3], PauliZGate.matrix ⊗ PauliZGate.matrix),
    (g[4], PauliYGate.matrix ⊗ PauliYGate.matrix),
    (g[5], PauliXGate.matrix ⊗ PauliXGate.matrix)
]
var H = Matrix(rows: 4, cols: 4)
for (coefficient, term) in terms {
    for r in 0..<4 { for c in 0..<4 { H[r, c] = H[r, c] + term[r, c] * coefficient } }
}

func ansatz(_ theta: Double) -> StateVector {
    let qc = QuantumCircuit(qubits: 2)
    qc.x(0); qc.ry(theta, 1); qc.cx(1, 0)
    return qc.run()
}

func energy(_ theta: Double) -> Double {
    let psi = ansatz(theta)
    return (psi† * H * psi).real
}

// Exact parameter-shift gradient.
func gradient(_ theta: Double) -> Double {
    (energy(theta + .pi / 2) - energy(theta - .pi / 2)) / 2
}
```

## Troubleshooting

- **Page won't run / no output** — the SwiftQiskit scheme must build first.
- **`Failed to load linked library cups`** — the Xcode 27 beta evaluator bug; re-copy the
  shim (`PLAYGROUNDSUPPORT.md`).
- **Gradient descent doesn't converge / oscillates** — the learning rate of 1.0 is tuned to
  this specific Hamiltonian and ansatz; a much larger rate on a different problem can overshoot.
- **Energy at θ=0 doesn't match -1.830200** — check the ansatz gate order: `x(0)` first, then
  `ry(theta, 1)`, then `cx(1, 0)` — swapping the control/target on the final `cx` changes which
  basis states the ansatz can reach.

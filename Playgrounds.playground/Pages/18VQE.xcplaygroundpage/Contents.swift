//: [Previous](@previous)

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskitCore

// ============================================================
// VQE — the variational quantum eigensolver
// ============================================================
// Every earlier page ran a fixed circuit. This page runs the loop
// that defines the NISQ era: a parameterized circuit (the "ansatz")
// prepares a trial state, a Hamiltonian's expectation value is
// measured on it, and a classical optimizer adjusts the parameter to
// push that energy down — hunting for the ground-state energy without
// ever diagonalizing the Hamiltonian directly.
//
// The target is the qubit Hamiltonian for H₂ in a minimal (STO-3G)
// basis after the Jordan–Wigner transform, near its equilibrium bond
// length — the standard 2-qubit example from the VQE literature
// (O'Malley et al., 2016):
//
//   H = g0·I⊗I + g1·Z⊗I + g2·I⊗Z + g3·Z⊗Z + g4·Y⊗Y + g5·X⊗X

func fmt(_ d: Double) -> String { String(format: "%.6f", d) }

// ============================================================
// Section 1 — the Hamiltonian, built entrywise
// ============================================================
// `Matrix` has no `+` or scalar multiply (page 12's QFT† idiom, page
// 15's tilted observable) — so the six Pauli terms are combined index
// by index, with the Pauli matrices tensored via Core's `⊗`.

let g: [Double] = [-0.4804, 0.3435, -0.4347, 0.5716, 0.0910, 0.0910]
let nuclearRepulsion = 0.7055

let I2 = Matrix.identity(size: 2)
let Z = PauliZGate.matrix
let X = PauliXGate.matrix
let Y = PauliYGate.matrix

let terms: [(coefficient: Double, matrix: Matrix)] = [
    (g[0], I2 ⊗ I2), (g[1], Z ⊗ I2), (g[2], I2 ⊗ Z),
    (g[3], Z ⊗ Z), (g[4], Y ⊗ Y), (g[5], X ⊗ X)
]

var H = Matrix(rows: 4, cols: 4)
for (coefficient, term) in terms {
    for r in 0..<4 {
        for c in 0..<4 {
            H[r, c] = H[r, c] + term[r, c] * coefficient
        }
    }
}
print("Hamiltonian assembled from \(terms.count) Pauli terms.")

// ============================================================
// Section 2 — a one-parameter ansatz
// ============================================================
// `x(0)` then `ry(θ, 1)` then `cx(1, 0)` prepares
// cos(θ/2)|10⟩ + sin(θ/2)|01⟩ — a single real parameter that stays
// inside the 2-electron subspace {|01⟩, |10⟩} for every θ.

func ansatz(_ theta: Double) -> StateVector {
    let qc = QuantumCircuit(qubits: 2)
    qc.x(0)
    qc.ry(theta, 1)
    qc.cx(1, 0)
    return qc.run()
}

let probe = ansatz(0.9)
print("ansatz(0.9): |00⟩=\(probe[0])  |01⟩=\(probe[1])  |10⟩=\(probe[2])  |11⟩=\(probe[3])")
// Expected: |00⟩ and |11⟩ amplitudes exactly 0 at every θ — the
// ansatz never leaves the single-excitation subspace, by construction.

// ============================================================
// Section 3 — the energy, via the Dirac expectation value
// ============================================================
// E(θ) = ⟨ψ(θ)|H|ψ(θ)⟩, exactly page 08's `psi† * H * psi` idiom.

func energy(_ theta: Double) -> Double {
    let psi = ansatz(theta)
    return (psi† * H * psi).real
}

print("\nθ        E(θ)")
for theta in [0.0, Double.pi / 2, Double.pi, 3 * Double.pi / 2] {
    print("\(fmt(theta))  \(fmt(energy(theta)))")
}
// Expected: E(0) = -1.830200, E(π/2) = -0.870000, E(π) = -0.273800,
// E(3π/2) = -1.234000.

// ============================================================
// Section 4 — the exact answer, for grading
// ============================================================
// The ansatz only ever touches the 2×2 block of H spanned by
// {|01⟩, |10⟩}, so that block's eigenvalues are the exact answer —
// no eigensolver needed, just the quadratic formula.

let a = H[1, 1].real, b = H[1, 2].real, d = H[2, 2].real
let exactElectronic = (a + d) / 2 - sqrt(pow((a - d) / 2, 2) + b * b)
print("\nexact electronic ground energy = \(fmt(exactElectronic)) Ha")
print("total with nuclear repulsion   = \(fmt(exactElectronic + nuclearRepulsion)) Ha")
// Expected: -1.851199 Ha electronic, -1.145699 Ha total.

// ============================================================
// Section 5 — parameter-shift gradients
// ============================================================
// dE/dθ = [E(θ+π/2) − E(θ−π/2)] / 2 is not an approximation — for a
// gate whose only θ-dependence is a single Pauli rotation, this
// identity is exact. Pinned here against an ordinary finite
// difference before trusting it to drive an optimizer.

func parameterShiftGradient(_ theta: Double) -> Double {
    (energy(theta + Double.pi / 2) - energy(theta - Double.pi / 2)) / 2
}

func finiteDifferenceGradient(_ theta: Double, epsilon: Double = 1e-6) -> Double {
    (energy(theta + epsilon) - energy(theta - epsilon)) / (2 * epsilon)
}

print("\nθ      param-shift    finite-diff")
for theta in [0.0, 0.4, 1.0, 2.5] {
    print("\(fmt(theta))  \(fmt(parameterShiftGradient(theta)))     \(fmt(finiteDifferenceGradient(theta)))")
}
// Expected: the two columns agree to 6 decimals at every angle.

// ============================================================
// Section 6 — gradient descent to the ground state
// ============================================================
// Plain gradient descent from θ = 0, fixed learning rate — no line
// search, no momentum.

var theta = 0.0
var trajectory: [(theta: Double, energy: Double)] = [(theta, energy(theta))]
let learningRate = 1.0

print("\nstep   θ           E(θ)")
for step in 1...40 {
    let grad = parameterShiftGradient(theta)
    theta -= learningRate * grad
    trajectory.append((theta, energy(theta)))
    if step == 1 || step % 10 == 0 {
        print("\(step)      \(fmt(theta))   \(fmt(energy(theta)))")
    }
}
let converged = energy(theta)
print("\nconverged: θ = \(fmt(theta)), E = \(fmt(converged))")
print("error vs. exact = \(String(format: "%.2e", converged - exactElectronic))")
// Expected: converges by ~step 10 to θ ≈ -0.22974, E = -1.851199,
// error 0.00e+00 against Section 4's closed form.

// ============================================================
// Section 7 — live view: the landscape and the descent
// ============================================================
// The E(θ) landscape as a line, the optimizer's own visited points
// as a scatter walking downhill into the minimum — reusing
// `CHSHChartView` from page 15 unchanged.

var landscape: [CGPoint] = []
var sweep = -0.5
while sweep <= 2 * Double.pi + 0.5 {
    landscape.append(CGPoint(x: sweep, y: energy(sweep)))
    sweep += Double.pi / 40
}

//: ### Live view — the VQE energy landscape and the descent to the minimum
//: The blue curve is E(θ) over one full period; the orange dots are
//: the 41 points gradient descent actually visited, converging into
//: the well near θ ≈ -0.230.

let chart = CHSHChartView(
    title: "VQE: E(θ) landscape and gradient descent",
    xRange: -0.5...(2 * Double.pi + 0.5),
    yRange: -2.0...0.0,
    series: [
        CHSHChartView.Series(
            label: "E(θ) landscape",
            color: .blue,
            points: landscape,
            isLine: true
        ),
        CHSHChartView.Series(
            label: "gradient descent path",
            color: .orange,
            points: trajectory.map { CGPoint(x: $0.theta, y: $0.energy) },
            isLine: false
        )
    ]
)

PlaygroundPage.current.setLiveView(
    chart.frame(width: 560, height: 420)
)

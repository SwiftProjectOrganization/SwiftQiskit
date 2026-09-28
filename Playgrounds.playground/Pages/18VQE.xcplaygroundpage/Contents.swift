//: [Previous](@previous)

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit

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
// Section 1 — the Hamiltonian, built from PauliString/Hamiltonian
// ============================================================
// The six Pauli terms are each a `PauliString` (a label plus a real
// coefficient), summed into a `Hamiltonian` — replacing the earlier
// entrywise `Matrix`-`+`/scalar-`*` accumulation this page used before
// that type landed (page 12's QFT† idiom and page 15's tilted
// observable still use the entrywise form, since they predate it).

let g: [Double] = [-0.4804, 0.3435, -0.4347, 0.5716, 0.0910, 0.0910]
let nuclearRepulsion = 0.7055

let H = Hamiltonian([
    PauliString("II", coefficient: g[0]),
    PauliString("ZI", coefficient: g[1]),
    PauliString("IZ", coefficient: g[2]),
    PauliString("ZZ", coefficient: g[3]),
    PauliString("YY", coefficient: g[4]),
    PauliString("XX", coefficient: g[5]),
])
print("Hamiltonian assembled from \(H.terms.count) Pauli terms.")

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
// Section 3 — the energy, via Hamiltonian.expectation
// ============================================================
// E(θ) = ⟨ψ(θ)|H|ψ(θ)⟩ via `Hamiltonian.expectation(_:)` — internally
// the same `psi† * H * psi` idiom page 08 introduced (see
// `StateVector.expectation`/`PauliString.expectation`), just summed
// term by term instead of against one dense matrix.

func energy(_ theta: Double) -> Double {
    H.expectation(ansatz(theta))
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

let a = H.matrix[1, 1].real, b = H.matrix[1, 2].real, d = H.matrix[2, 2].real
let exactElectronic = (a + d) / 2 - sqrt(pow((a - d) / 2, 2) + b * b)
print("\nexact electronic ground energy = \(fmt(exactElectronic)) Ha")
print("total with nuclear repulsion   = \(fmt(exactElectronic + nuclearRepulsion)) Ha")
// Expected: -1.851199 Ha electronic, -1.145699 Ha total.

// ============================================================
// Section 5 — parameter-shift gradients
// ============================================================
// dE/dθ = [E(θ+π/2) − E(θ−π/2)] / 2 is not an approximation — for a
// gate whose only θ-dependence is a single Pauli rotation, this
// identity is exact. Now via `ParameterShift.gradient(at:_:)` instead
// of hand-deriving the shift formula (the `Hamiltonian`/`ansatz`
// convenience overload expects a closure returning `QuantumCircuit`;
// this page's own `ansatz` already returns the run `StateVector`, so
// the plain cost-closure form fits it directly); pinned here against
// an ordinary finite difference before trusting it to drive an
// optimizer.

func parameterShiftGradient(_ theta: Double) -> Double {
    ParameterShift.gradient(at: [theta]) { params in energy(params[0]) }[0]
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
// search, no momentum — now via `GradientDescent.minimize`.
// `tolerance: 0` keeps it running the full 40 steps rather than
// stopping early once the (exact) gradient reaches ~0, matching this
// page's original unconditional loop.

let descent = GradientDescent.minimize(
    initial: [0.0],
    learningRate: 1.0,
    maxIterations: 40,
    tolerance: 0,
    cost: { params in energy(params[0]) },
    gradient: { params in [parameterShiftGradient(params[0])] }
)

let trajectory = zip(descent.parameterHistory, descent.history)
    .map { (theta: $0[0], energy: $1) }

print("\nstep   θ           E(θ)")
for step in 1...descent.iterations {
    let theta = descent.parameterHistory[step][0]
    let e = descent.history[step]
    if step == 1 || step % 10 == 0 {
        print("\(step)      \(fmt(theta))   \(fmt(e))")
    }
}
let finalTheta = descent.parameters[0]
let converged = descent.value
print("\nconverged: θ = \(fmt(finalTheta)), E = \(fmt(converged))")
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

//: [Next](@next)

//: [Previous](@previous)

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit

// ============================================================
// State tomography — what a real device actually gives you
// ============================================================
// Every page so far has read a state's amplitudes directly off the
// `StateVector` — something no real device permits. `measure(shots:)`
// has been used for statistics (pages 06, 07, 15, 17), but never to
// *reconstruct* an unknown state. This page does that, and depends on
// page 19's mixed states for its most important result.

func fmt(_ d: Double) -> String { String(format: "%.6f", d) }

let X = PauliXGate.matrix
let Y = PauliYGate.matrix
let Z = PauliZGate.matrix

// ============================================================
// Section 1 — basis rotations, pinned before they're trusted
// ============================================================
// `measure(shots:)` only ever reads the Z basis. Getting ⟨X⟩ means
// rotating X into Z first (`h`); ⟨Y⟩ needs `sdg` then `h` — exactly
// what Core's `QuantumCircuit.rotateToZ(_:_:)` does for the
// exhaustive `PauliBasis` (`.x`/`.y`/`.z`, no silent typo falling
// through to Z the way a bare `"x "` or `"Z"`-vs-`"z"` string could).
// The order matters — checked here against a state with a *known* Y
// value rather than assumed.

let plusICircuit = QuantumCircuit(qubits: 1)
plusICircuit.h(0)
plusICircuit.s(0)              // |+i⟩, a +1 eigenstate of Y
plusICircuit.rotateToZ(.y, 0)
print("|+i⟩ rotated by rotateToZ(.y, 0): \(plusICircuit.run())")
// Expected: collapses to |0⟩ (amplitude ≈1, 0) — confirms Sdg-then-H
// is the correct order for a Y-basis measurement. (The reverse order
// does *not* diagonalize Y — worth knowing before trusting either.)

var plusIRx = StateVector.plusI
plusIRx.apply(RXGate.matrix(theta: .pi / 2))
print("|+i⟩ rotated by rx(π/2): \(plusIRx)")
// Expected: also collapses to |0⟩ — a one-gate alternative to
// `sdg; h` for the Y basis. This page keeps `sdg; h` (via
// `rotateToZ`) throughout since it's the textbook decomposition, but
// `rx(π/2)` is worth knowing about for a leaner circuit.

// ============================================================
// Section 2 — the estimator, sign-checked against exact values
// ============================================================
// ⟨A⟩ ≈ (N₀ − N₁)/N from shots, checked against the exact
// `psi† * A * psi` on a generic tilted state (page 04/08's θ≈60°,
// φ≈45°) before trusting it for anything statistical.

func tiltedCircuit() -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: 1)
    qc.ry(1.0472, 0)
    qc.rz(0.7854, 0)
    return qc
}
func exactExpectation(_ psi: Ket, _ A: Matrix) -> Double { (psi† * A * psi).real }

func estimate(_ basis: PauliBasis, circuit: QuantumCircuit, shots: Int) -> Double {
    circuit.measure(shots: shots, basis: [basis]).parityExpectation(qubits: [0])
}

let tilted = tiltedCircuit()
let psi = tilted.run()
print("\nexact   ⟨X⟩=\(fmt(exactExpectation(psi, X)))  ⟨Y⟩=\(fmt(exactExpectation(psi, Y)))  ⟨Z⟩=\(fmt(exactExpectation(psi, Z)))")
print("N=100000 ⟨X⟩=\(fmt(estimate(.x, circuit: tilted, shots: 100_000)))  ⟨Y⟩=\(fmt(estimate(.y, circuit: tilted, shots: 100_000)))  ⟨Z⟩=\(fmt(estimate(.z, circuit: tilted, shots: 100_000)))")
// Expected: exact ≈ (0.6124, 0.6124, 0.5000); shot estimates land
// within about 0.005–0.01 of that at N=100,000 (statistical — the
// exact gap varies run to run).

// ============================================================
// Section 3 — error shrinks as 1/√N
// ============================================================

func rmsError(_ basis: PauliBasis, exact: Double, circuit: QuantumCircuit, shots: Int, trials: Int) -> Double {
    let errors = (0..<trials).map { _ in estimate(basis, circuit: circuit, shots: shots) - exact }
    return (errors.map { $0 * $0 }.reduce(0, +) / Double(trials)).squareRoot()
}

print("\nN         RMS error in ⟨X⟩ (20 trials)")
let exactX = exactExpectation(psi, X)
for n in [100, 1_000, 10_000, 100_000] {
    print("\(n)     \(fmt(rmsError(.x, exact: exactX, circuit: tilted, shots: n, trials: 20)))")
}
// Expected: each column of numbers falls as N grows, at roughly the
// 1/√N rate (each 10× increase in N should shrink the error by
// roughly √10 ≈ 3.16, e.g. ~0.08 → ~0.025 → ~0.008 → ~0.003) — only
// 20 trials per point, so the exact figures are statistical and will
// vary run to run; the declining trend is the point, not the digits.

// ============================================================
// Section 4 — unphysical estimates: pure vs. mixed
// ============================================================
// A per-axis estimate can put the reconstructed vector *outside* the
// Bloch ball. The surprising result: for a genuinely *pure* state
// (sitting exactly on the boundary), that happens roughly half the
// time no matter how large N is — symmetric noise straddles a
// boundary point equally in both directions. Only a truly *mixed*
// state's frequency shrinks toward zero with N.

func reconstructedMagnitude(_ circuit: QuantumCircuit, shots: Int) -> Double {
    let ex = estimate(.x, circuit: circuit, shots: shots)
    let ey = estimate(.y, circuit: circuit, shots: shots)
    let ez = estimate(.z, circuit: circuit, shots: shots)
    return (ex * ex + ey * ey + ez * ez).squareRoot()
}
func unphysicalFrequency(_ circuit: QuantumCircuit, shots: Int, trials: Int) -> Double {
    let hits = (0..<trials).filter { _ in reconstructedMagnitude(circuit, shots: shots) > 1.0 }.count
    return Double(hits) / Double(trials)
}

print("\nPure state (tilted |ψ⟩), unphysical (|r|>1) frequency over 1000 trials:")
for n in [10, 50, 200, 1000, 5000] {
    print("  N=\(n): \(fmt(unphysicalFrequency(tilted, shots: n, trials: 1000)))")
}
// Expected: hovers near 0.5 at every N (statistical over 1000
// trials, so exact figures vary run to run) — it does *not* trend to
// zero, because the true point sits exactly on the ball's boundary.

// A genuinely mixed ensemble: 75% |0⟩, 25% |1⟩ → Bloch (0,0,0.5),
// |r|=0.5, strictly inside the ball (page 19's territory). Each shot
// draws a fresh preparation, so `measure(shots:)` can't sample it in
// one call — build both branches once per basis via `rotateToZ`, and
// have each shot pick between them.
func sampleMixedAndMeasure(zeroBranch: QuantumCircuit, oneBranch: QuantumCircuit) -> Int {
    let branch = Double.random(in: 0..<1) < 0.75 ? zeroBranch : oneBranch
    return branch.runAndMeasure()
}
func estimateMixed(_ basis: PauliBasis, shots: Int) -> Double {
    let zeroBranch = QuantumCircuit(qubits: 1)
    zeroBranch.rotateToZ(basis, 0)
    let oneBranch = QuantumCircuit(qubits: 1)
    oneBranch.x(0)
    oneBranch.rotateToZ(basis, 0)

    var plus = 0
    for _ in 0..<shots {
        if sampleMixedAndMeasure(zeroBranch: zeroBranch, oneBranch: oneBranch) == 0 { plus += 1 }
    }
    return 2 * Double(plus) / Double(shots) - 1
}
func unphysicalFrequencyMixed(shots: Int, trials: Int) -> Double {
    var count = 0
    for _ in 0..<trials {
        let ex = estimateMixed(.x, shots: shots)
        let ey = estimateMixed(.y, shots: shots)
        let ez = estimateMixed(.z, shots: shots)
        if (ex * ex + ey * ey + ez * ez).squareRoot() > 1.0 { count += 1 }
    }
    return Double(count) / Double(trials)
}

print("\nMixed state (|r|=0.5), unphysical frequency over 1000 trials:")
for n in [10, 50, 200, 1000, 5000] {
    print("  N=\(n): \(fmt(unphysicalFrequencyMixed(shots: n, trials: 1000)))")
}
// Expected: shrinks to 0 quickly (0.083 at N=10, 0.0 by N=50) — the
// contrast with the pure-state plateau above is the section's point.

// ============================================================
// Section 5 — reconstructing an entangled qubit's marginal
// ============================================================
// Estimating qubit 0's Bloch vector from a Bell pair, from shots
// alone, should land at the origin — page 19's exact ρ_A = I/2,
// measured rather than derived. Restates page 13's no-cloning result
// as "one copy of an entangled qubit is never enough to see anything."

let bellCircuit = QuantumCircuit(qubits: 2)
bellCircuit.h(0)
bellCircuit.cx(0, 1)

func estimateQubit0(_ basis: PauliBasis, shots: Int) -> Double {
    // Qubit 1's basis is arbitrary here — qubit 0's marginal is
    // maximally mixed, so it reads the same regardless of what basis
    // qubit 1 is measured in.
    bellCircuit.measure(shots: shots, basis: [basis, .z]).parityExpectation(qubits: [0])
}

let bx = estimateQubit0(.x, shots: 50_000)
let by = estimateQubit0(.y, shots: 50_000)
let bz = estimateQubit0(.z, shots: 50_000)
print("\nBell-pair qubit-0 marginal from shots: (x,y,z) = (\(fmt(bx)), \(fmt(by)), \(fmt(bz))), |r| = \(fmt((bx*bx+by*by+bz*bz).squareRoot()))")
// Expected: all three components within ~0.02 of 0 — statistically
// indistinguishable from the origin.

// ============================================================
// Section 6 — why full tomography doesn't scale
// ============================================================
print("\nqubits   settings (3ⁿ)")
for n in 1...5 {
    print("\(n)        \(Int(pow(3.0, Double(n))))")
}
// This is exactly why page 18's VQE measures individual Pauli terms
// of its Hamiltonian rather than reconstructing the full state.

// ============================================================
// Section 7 — live view: true vs. reconstructed Bloch point
// ============================================================

struct TomographyGalleryView: View {
    let truth: (name: String, bloch: BlochVector)
    let reconstructed: (name: String, bloch: BlochVector)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bell-pair qubit 0: true vs. reconstructed marginal").font(.title3.bold())
            HStack(spacing: 16) {
                BlochSphereView(label: truth.name, bloch: truth.bloch, size: 240)
                BlochSphereView(label: reconstructed.name, bloch: reconstructed.bloch, size: 240)
            }
        }
        .padding()
    }
}

PlaygroundPage.current.setLiveView(
    TomographyGalleryView(
        truth: ("true ρ_A = I/2", BlochVector(x: 0, y: 0, z: 0)),
        reconstructed: ("reconstructed from shots", BlochVector(x: bx, y: by, z: bz))
    )
    .frame(width: 620, height: 360)
)

//: [Next](@next)

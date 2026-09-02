//: [Previous](@previous)

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskitCore

// ============================================================
// State tomography — what a real device actually gives you
// ============================================================
// Every page so far has read a state's amplitudes directly off the
// `StateVector` — something no real device permits. `measure(shots:)`
// has been used for statistics (pages 06, 07, 15, 17), but never to
// *reconstruct* an unknown state. This page does that, and depends on
// page 19's mixed states for its most important result.

func fmt(_ d: Double) -> String { String(format: "%.6f", d) }

let H = HadamardGate.matrix
let Sdg = SDaggerGate.matrix
let X = PauliXGate.matrix
let Y = PauliYGate.matrix
let Z = PauliZGate.matrix

// ============================================================
// Section 1 — basis rotations, pinned before they're trusted
// ============================================================
// `measure(shots:)` only ever reads the Z basis. Getting ⟨X⟩ means
// rotating X into Z first (`h`); ⟨Y⟩ needs `sdg` then `h`. The order
// matters — checked here against a state with a *known* Y value
// rather than assumed.

func basisRotation(_ axis: String, _ s: inout StateVector) {
    switch axis {
    case "X": s.apply(H)
    case "Y": s.apply(Sdg); s.apply(H)
    default: break
    }
}

var plusI = StateVector.plusI   // a +1 eigenstate of Y
basisRotation("Y", &plusI)
print("|+i⟩ rotated by (Sdg; H): \(plusI)")
// Expected: collapses to |0⟩ (amplitude ≈1, 0) — confirms Sdg-then-H
// is the correct order for a Y-basis measurement. (The reverse order
// does *not* diagonalize Y — worth knowing before trusting either.)

// ============================================================
// Section 2 — the estimator, sign-checked against exact values
// ============================================================
// ⟨A⟩ ≈ (N₀ − N₁)/N from shots, checked against the exact
// `psi† * A * psi` on a generic tilted state (page 04/08's θ≈60°,
// φ≈45°) before trusting it for anything statistical.

func tiltedState() -> Ket {
    var s = StateVector.zero
    s.apply(RYGate.matrix(theta: 1.0472))
    s.apply(RZGate.matrix(theta: 0.7854))
    return s
}
func exactExpectation(_ psi: Ket, _ A: Matrix) -> Double { (psi† * A * psi).real }

func estimate(_ axis: String, psi: Ket, shots: Int) -> Double {
    var plus = 0
    for _ in 0..<shots {
        var s = psi
        basisRotation(axis, &s)
        if s.measure() == 0 { plus += 1 }
    }
    return 2 * Double(plus) / Double(shots) - 1
}

let psi = tiltedState()
print("\nexact   ⟨X⟩=\(fmt(exactExpectation(psi, X)))  ⟨Y⟩=\(fmt(exactExpectation(psi, Y)))  ⟨Z⟩=\(fmt(exactExpectation(psi, Z)))")
print("N=100000 ⟨X⟩=\(fmt(estimate("X", psi: psi, shots: 100_000)))  ⟨Y⟩=\(fmt(estimate("Y", psi: psi, shots: 100_000)))  ⟨Z⟩=\(fmt(estimate("Z", psi: psi, shots: 100_000)))")
// Expected: exact ≈ (0.6124, 0.6124, 0.5000); shot estimates land
// within about 0.005–0.01 of that at N=100,000 (statistical — the
// exact gap varies run to run).

// ============================================================
// Section 3 — error shrinks as 1/√N
// ============================================================

func rmsError(_ axis: String, exact: Double, psi: Ket, shots: Int, trials: Int) -> Double {
    let errors = (0..<trials).map { _ in estimate(axis, psi: psi, shots: shots) - exact }
    return (errors.map { $0 * $0 }.reduce(0, +) / Double(trials)).squareRoot()
}

print("\nN         RMS error in ⟨X⟩ (20 trials)")
let exactX = exactExpectation(psi, X)
for n in [100, 1_000, 10_000, 100_000] {
    print("\(n)     \(fmt(rmsError("X", exact: exactX, psi: psi, shots: n, trials: 20)))")
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

func reconstructedMagnitude(_ psi: Ket, shots: Int) -> Double {
    let ex = estimate("X", psi: psi, shots: shots)
    let ey = estimate("Y", psi: psi, shots: shots)
    let ez = estimate("Z", psi: psi, shots: shots)
    return (ex * ex + ey * ey + ez * ez).squareRoot()
}
func unphysicalFrequency(_ psi: Ket, shots: Int, trials: Int) -> Double {
    let hits = (0..<trials).filter { _ in reconstructedMagnitude(psi, shots: shots) > 1.0 }.count
    return Double(hits) / Double(trials)
}

print("\nPure state (tilted |ψ⟩), unphysical (|r|>1) frequency over 1000 trials:")
for n in [10, 50, 200, 1000, 5000] {
    print("  N=\(n): \(fmt(unphysicalFrequency(psi, shots: n, trials: 1000)))")
}
// Expected: hovers near 0.5 at every N (statistical over 1000
// trials, so exact figures vary run to run) — it does *not* trend to
// zero, because the true point sits exactly on the ball's boundary.

// A genuinely mixed ensemble: 75% |0⟩, 25% |1⟩ → Bloch (0,0,0.5),
// |r|=0.5, strictly inside the ball (page 19's territory).
func sampleMixedAndMeasure(_ axis: String) -> Int {
    var s: Ket = Double.random(in: 0..<1) < 0.75 ? StateVector.zero : StateVector.one
    basisRotation(axis, &s)
    return s.measure()
}
func estimateMixed(_ axis: String, shots: Int) -> Double {
    var plus = 0
    for _ in 0..<shots { if sampleMixedAndMeasure(axis) == 0 { plus += 1 } }
    return 2 * Double(plus) / Double(shots) - 1
}
func unphysicalFrequencyMixed(shots: Int, trials: Int) -> Double {
    var count = 0
    for _ in 0..<trials {
        let ex = estimateMixed("X", shots: shots)
        let ey = estimateMixed("Y", shots: shots)
        let ez = estimateMixed("Z", shots: shots)
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

let I2 = Matrix.identity(size: 2)
var bell = StateVector(qubits: 2)
bell.apply(H.tensor(I2))
bell.apply(CNOTGate.matrix(qubits: 2, control: 0, target: 1))

func estimateQubit0(_ axis: String, state: Ket, shots: Int) -> Double {
    var plus = 0
    for _ in 0..<shots {
        var s = state
        switch axis {
        case "X": s.apply(H.tensor(I2))
        case "Y": s.apply(Sdg.tensor(I2)); s.apply(H.tensor(I2))
        default: break
        }
        let bit0 = (s.measure() >> 1) & 1   // qubit 0 is the MSB
        if bit0 == 0 { plus += 1 }
    }
    return 2 * Double(plus) / Double(shots) - 1
}

let bx = estimateQubit0("X", state: bell, shots: 50_000)
let by = estimateQubit0("Y", state: bell, shots: 50_000)
let bz = estimateQubit0("Z", state: bell, shots: 50_000)
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

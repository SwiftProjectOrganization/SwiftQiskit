//: [Previous](@previous)

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskitCore

// ============================================================
// Quantum teleportation — moving a qubit with two classical bits
// ============================================================
// Pages 10–12 used entanglement inside an oracle. This page uses it
// as a *resource*: Alice holds an unknown qubit |ψ⟩ and wants Bob to
// have it, without a quantum channel between them — only a
// pre-shared Bell pair and two classical bits.
//
// Register (qubit 0 is the most-significant/leftmost bit):
//
//   q0 — Alice's payload |ψ⟩
//   q1 — Alice's half of a Bell pair
//   q2 — Bob's half of the same Bell pair
//
// The protocol:
//
//   1. cx(0,1); h(0)     Alice rotates into the Bell basis —
//                        this is what "measuring q0,q1 in the Bell
//                        basis" looks like as unitaries
//   2. measure q0 → a, q1 → b, send (a,b) to Bob classically
//   3. Bob applies X^b Z^a to q2
//
// `SwiftQiskitCore` has no mid-circuit measurement, so this page uses
// the *deferred-measurement principle*: replace "measure then apply a
// classical-controlled correction" with a plain controlled gate
// (cx / cz) applied to all branches at once. Sections 1–3 first look
// at the four measurement branches individually with Dirac
// projectors, to see what the deferred version is standing in for.

// ============================================================
// Section 1 — the payload and the resource
// ============================================================
// |ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}·sin(θ/2)|1⟩, the same θ = 60°, φ = 45°
// as pages 04/08 — built here as ry(θ) then rz(φ) on q0. `rz`
// multiplies |0⟩ and |1⟩ by e^{∓iφ/2}, an overall e^{−iφ/2} away from
// the page-04/08 convention — a *global* phase, invisible to every
// probability and fidelity check below.

func pretty(_ state: StateVector, qubits: Int) -> String {
    (0..<state.dimension)
        .filter { state[$0].magnitude > 1e-10 }
        .map { index -> String in
            var label = String(index, radix: 2)
            while label.count < qubits { label = "0" + label }
            return "|\(label)⟩: \(state[index])"
        }
        .joined(separator: "   ")
}

let theta = Double.pi / 3
let phi = Double.pi / 4

let psiCircuit = QuantumCircuit(qubits: 1)
psiCircuit.ry(theta, 0)
psiCircuit.rz(phi, 0)
let psi = psiCircuit.run()

print("|ψ⟩:  \(pretty(psi, qubits: 1))")
// Expected: |0⟩: 0.8001 − 0.3314i   |1⟩: 0.4619 + 0.1913i
print("P(0), P(1):  \(psi.probabilities.map { String(format: "%.4f", $0) })")
// Expected: [0.7500, 0.2500] = [cos²30°, sin²30°]
print(String(format: "Bloch point: x %.4f  y %.4f  z %.4f",
             BlochVector(psi).x, BlochVector(psi).y, BlochVector(psi).z))
// Expected: 0.6124, 0.6124, 0.5000 — exactly page 08's ⟨X⟩, ⟨Y⟩, ⟨Z⟩
// for the same θ, φ: the e^{−iφ/2} global phase leaves the Bloch point
// (and every probability below) untouched.

let qc = QuantumCircuit(qubits: 3)
qc.ry(theta, 0)
qc.rz(phi, 0)
print("\nafter preparing q0 = |ψ⟩:      \(pretty(qc.run(), qubits: 3))")
// Expected: |000⟩ and |100⟩ carrying |ψ⟩'s two amplitudes — q1, q2
// have never touched q0.

qc.h(1)
qc.cx(1, 2)
print("after Bell pair on q1,q2:     \(pretty(qc.run(), qubits: 3))")
// Expected: |000⟩, |011⟩ at 0.5658 − 0.2343i and |100⟩, |111⟩ at
// 0.3266 + 0.1353i — |ψ⟩ ⊗ Φ⁺, still a product across {q0} vs {q1,q2}.

// ============================================================
// Section 2 — Alice's Bell-basis rotation
// ============================================================
// cx(0,1); h(0) is exactly the change of basis that turns "measure
// q0, q1 in the Bell basis" into "measure q0, q1 in the computational
// basis". Afterward the state is ½ Σ_{a,b} |a⟩|b⟩ ⊗ (X^b Z^a|ψ⟩):
// every one of Bob's four possible states is present at once, tagged
// by the (a,b) prefix.

qc.cx(0, 1)
qc.h(0)
let bellBasisState = qc.run()
print("\nafter cx(0,1); h(0):  \(pretty(bellBasisState, qubits: 3))")
// Expected: all eight amplitudes populated, magnitude 0.4001 or
// 0.2310 depending on the prefix — grouped by ab below.

// ============================================================
// Section 3 — the four branches, via Dirac projectors
// ============================================================
// (|ab⟩⟨ab|) ⊗ I₂ — a mixed ⊗ of a Ket*Bra outer product with the
// identity (Quantum/Dirac.swift) — projects onto one measurement
// outcome without ever calling `measure()`. Applying it and slicing
// out q2's two amplitudes recovers exactly Bob's branch state.

let branchCorrections: [String: Matrix] = [
    "00": Matrix.identity(size: 2),
    "01": PauliXGate.matrix,
    "10": PauliZGate.matrix,
    "11": PauliXGate.matrix * PauliZGate.matrix
]

print("\nab   P(ab)    correction   fidelity")
for a in 0...1 {
    for b in 0...1 {
        let label = "\(a)\(b)"
        let projector = (Ket(label) * Bra(label)) ⊗ Matrix.identity(size: 2)
        var projected = bellBasisState
        projected.apply(projector)            // collapses to branch ab, renormalized

        let base = a * 4 + b * 2
        let bobBranch = StateVector([projected[base], projected[base + 1]])
        let probAB = bellBasisState[base].magnitudeSquared
            + bellBasisState[base + 1].magnitudeSquared

        var corrected = bobBranch
        corrected.apply(branchCorrections[label]!)
        let fidelity = (corrected† * psi).magnitudeSquared
        let name = label == "00" ? "I " : label == "01" ? "X " : label == "10" ? "Z " : "XZ"
        print("\(label)   \(String(format: "%.4f", probAB))    \(name)           \(String(format: "%.4f", fidelity))")
    }
}
// Expected: P(ab) = 0.2500 for every branch (Bob's marginal doesn't
// depend on ψ — no signal reaches him before the classical bits do),
// and fidelity 1.0000 once each branch gets *its* correction X^b Z^a.

// ============================================================
// Section 4 — deferred measurement: every branch, corrected at once
// ============================================================
// Instead of measuring (a,b) and looking up a correction, apply the
// corrections as controlled gates: cx(1,2) flips q2 exactly when
// q1 = 1 (the X^b part), and cz(0,2) — page 11's h;cx;h idiom — phases
// q2 exactly when q0 = 1 (the Z^a part). Every branch gets its own
// correction automatically, in superposition.

qc.cx(1, 2)                 // X^b
qc.h(2); qc.cx(0, 2); qc.h(2)   // Z^a, as CZ(0,2)
let finalState = qc.run()

print("\nfinal state:  \(pretty(finalState, qubits: 3))")
let expectedFactored = (Ket.plus ⊗ Ket.plus) ⊗ psi
let maxDiff = (0..<8).map { (finalState[$0] - expectedFactored[$0]).magnitude }.max()!
print("matches |+⟩⊗|+⟩⊗|ψ⟩ to within \(String(format: "%.1e", maxDiff))")
// Expected: ~1e-16 — the register *factors* (page 09's language):
// q0, q1 end in |+⟩ regardless of ψ, and q2 ends in exactly |ψ⟩.

// ============================================================
// Section 5 — no cloning: the payload moved, it didn't copy
// ============================================================
// q2's marginal reproduces |ψ⟩'s probabilities; q0's marginal is a
// fair coin — the payload is *gone* from q0, not duplicated there.

func marginal(_ state: StateVector, bit: Int) -> [Double] {
    var p = [0.0, 0.0]
    for (i, prob) in state.probabilities.enumerated() {
        p[(i >> (2 - bit)) & 1] += prob
    }
    return p
}

print("\nq2 (Bob) marginal:    \(marginal(finalState, bit: 2).map { String(format: "%.4f", $0) })")
print("ψ probabilities:      \(psi.probabilities.map { String(format: "%.4f", $0) })")
// Expected: identical — [0.7500, 0.2500]

print("q0 (Alice) marginal:  \(marginal(finalState, bit: 0).map { String(format: "%.4f", $0) })")
// Expected: [0.5000, 0.5000] — |+⟩, independent of ψ

// `measure(shots:)` replays every recorded operation per shot on a
// fresh circuit, so build one afresh rather than sampling `finalState`.
let shotCircuit = QuantumCircuit(qubits: 3)
shotCircuit.ry(theta, 0)
shotCircuit.rz(phi, 0)
shotCircuit.h(1)
shotCircuit.cx(1, 2)
shotCircuit.cx(0, 1)
shotCircuit.h(0)
shotCircuit.cx(1, 2)
shotCircuit.h(2); shotCircuit.cx(0, 2); shotCircuit.h(2)
let shots = shotCircuit.measure(shots: 1000)
print("\n1000 shots (q0 q1 q2):")
for (state, count) in shots.sortedCounts {
    print("  \(state): \(count)")
}
// Expected: each ab prefix takes ~250 of the 1000 shots, and *within*
// every prefix the last bit splits ~187/~62 — |ψ|²'s 0.75/0.25, the
// same however Alice's two bits happen to fall. (Statistical: ±~25.)

// ============================================================
// Section 6 — superdense coding: the dual protocol
// ============================================================
// Teleportation sends one qubit using two classical bits and one
// e-bit. Superdense coding runs the resource the other way: Alice
// sends *two* classical bits over a single qubit, spending the same
// e-bit. Same Bell pair, same four unitaries, opposite direction.

let sdMessages: [(String, (QuantumCircuit) -> Void)] = [
    ("00", { _ in }),
    ("01", { $0.x(0) }),
    ("10", { $0.z(0) }),
    ("11", { $0.z(0); $0.x(0) })
]

print("\nsent  decoded  P")
for (label, encode) in sdMessages {
    let sdc = QuantumCircuit(qubits: 2)
    sdc.h(0)
    sdc.cx(0, 1)      // shared Bell pair
    encode(sdc)       // Alice encodes 2 bits into her qubit alone
    sdc.cx(0, 1)       // Bob decodes: un-rotate from the Bell basis
    sdc.h(0)
    let probs = sdc.run().probabilities
    let decodedIndex = probs.firstIndex(where: { $0 > 0.999 })!
    var decodedLabel = String(decodedIndex, radix: 2)
    while decodedLabel.count < 2 { decodedLabel = "0" + decodedLabel }
    print(" \(label)     \(decodedLabel)    \(String(format: "%.4f", probs[decodedIndex]))")
}
// Expected: decoded == sent, P = 1.0000, for all four messages —
// Bob's single-qubit measurement recovers both of Alice's bits with
// certainty.

// The four messages prepare the four Bell states, which are exactly
// orthonormal — that orthogonality is *why* decoding is deterministic.
let bellBasis = sdMessages.map { label, encode -> (String, StateVector) in
    let sdc = QuantumCircuit(qubits: 2)
    sdc.h(0); sdc.cx(0, 1)
    encode(sdc)
    return (label, sdc.run())
}
print("\nGram matrix |⟨Bell_i|Bell_j⟩| (should be the identity):")
for (li, si) in bellBasis {
    let row = bellBasis.map { String(format: "%.2f", (si† * $0.1).magnitude) }.joined(separator: "  ")
    print("  \(li): \(row)")
}

//: ### Live view — the payload's Bloch point, before and after
//: |ψ⟩ as prepared, the four *uncorrected* branches X^b Z^a|ψ⟩ Bob
//: would see without Alice's classical bits, and the corrected state
//: he ends up with — every ket here is genuinely 2-dimensional, so
//: `BlochVector` applies directly (stateless view, per
//: PLAYGROUNDSUPPORT.md).

struct TeleportationGalleryView: View {
    let psiStage: (name: String, bloch: BlochVector)
    let branches: [(name: String, bloch: BlochVector)]
    let corrected: (name: String, bloch: BlochVector)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("|ψ⟩ as prepared").font(.title3.bold())
            BlochSphereView(label: psiStage.name, bloch: psiStage.bloch)

            Text("Bob's branch before the classical bits arrive").font(.title3.bold())
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(220)), count: 4), spacing: 16) {
                ForEach(branches, id: \.name) { stage in
                    BlochSphereView(label: stage.name, bloch: stage.bloch, size: 190)
                }
            }

            Text("Bob's state after the correction").font(.title3.bold())
            BlochSphereView(label: corrected.name, bloch: corrected.bloch)
        }
        .padding()
    }
}

var uncorrectedBranches: [(name: String, bloch: BlochVector)] = []
for a in 0...1 {
    for b in 0...1 {
        let label = "\(a)\(b)"
        var branch = psi
        // The correction matrix X^b Z^a is also what *creates* the
        // branch: applying it to |ψ⟩ gives Bob's uncorrected state
        // exactly, and applying it twice returns ±|ψ⟩ (X² = Z² = I,
        // (XZ)² = −I) — a global phase the Bloch point can't see.
        branch.apply(branchCorrections[label]!)
        uncorrectedBranches.append(("ab=\(label)", BlochVector(branch)))
    }
}

// finalState factors as |+⟩⊗|+⟩⊗|ψ⟩ (Section 4), so any q0,q1 slice
// of q2's two amplitudes is proportional to |ψ⟩ — take the |00…⟩ one.
let bobCorrected = StateVector([finalState[0], finalState[1]])

PlaygroundPage.current.setLiveView(
    TeleportationGalleryView(
        psiStage: ("|ψ⟩", BlochVector(psi)),
        branches: uncorrectedBranches,
        corrected: ("Bob, corrected", BlochVector(bobCorrected))
    )
    .frame(width: 980, height: 760)
)

//: [Next](@next)

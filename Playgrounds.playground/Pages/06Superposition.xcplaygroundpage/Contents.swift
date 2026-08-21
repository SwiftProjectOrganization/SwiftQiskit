//: [Previous](@previous)

import SwiftQiskitCore

// A small page-local helper: zero-pad a basis index to a fixed-width binary
// label. `String.leftPadding` (used internally by `QuantumCircuit.measure(shots:)`)
// is not public, so this stays inline rather than moving to Sources/.
func binaryLabel(_ index: Int, qubits: Int) -> String {
    let raw = String(index, radix: 2)
    return String(repeating: "0", count: max(0, qubits - raw.count)) + raw
}

// ============================================================
// Section 1 — Four qubits, one Hadamard each
// ============================================================
// `h(qubit:)` embeds a single Hadamard into the full 2⁴×2⁴ operator via
// `Matrix.tensor(_:)` (see `embedSingleQubitGate` in `QuantumCircuit.swift`).
// Applying it to every qubit sends |0000⟩ to an equal superposition of
// all 2⁴ = 16 four-qubit basis states.

let qc = QuantumCircuit(qubits: 4)
qc.h(0)
qc.h(1)
qc.h(2)
qc.h(3)

let state = qc.run()

// ============================================================
// Section 2 — Inspect the state vector
// ============================================================
// Every amplitude has the same magnitude, 1/4 (so every probability is
// 1/16 = 0.0625) — a uniform superposition over all 16 basis states.

print("4-qubit uniform superposition amplitudes:")
for (index, amplitude) in state.amplitudes.enumerated() {
    print("  |\(binaryLabel(index, qubits: 4))⟩ : \(amplitude)")
}
// Expected: all 16 amplitudes ≈ 0.25 (real, no imaginary part)

print("\nProbabilities: \(state.probabilities)")
// Expected: sixteen entries, each 0.0625

// ============================================================
// Section 3 — Confirm with measurement (1600 shots)
// ============================================================
// With a uniform superposition, every one of the 16 outcomes should show
// up roughly 1600 / 16 = 100 times.

let result = qc.measure(shots: 1600)
print("\nMeasurement counts (1600 shots):")
for (outcome, count) in result.sortedCounts {
    print("  |\(outcome)⟩ : \(count)")
}
// Expected: sixteen states, each landing near 100 (statistical)

// ============================================================
// Section 4 — Partial superposition, for contrast
// ============================================================
// Putting only qubits 0 and 2 into superposition, and leaving 1 and 3 at
// |0⟩, spreads probability over just 4 of the 16 basis states — the two
// untouched qubits stay fixed at 0 in every outcome. This is the contrast
// that makes Section 1's "every qubit in superposition" concrete: it's
// what happens when you *don't* Hadamard every qubit.

let partialCircuit = QuantumCircuit(qubits: 4)
partialCircuit.h(0)
partialCircuit.h(2)
let partialState = partialCircuit.run()

print("\nPartial superposition (qubits 0 and 2 only), nonzero probabilities:")
for (index, probability) in partialState.probabilities.enumerated() where probability > 0 {
    print("  |\(binaryLabel(index, qubits: 4))⟩ : \(probability)")
}
// Expected: |0000⟩, |0010⟩, |1000⟩, |1010⟩ each 0.25 — qubits 1 and 3
// (the second and fourth bit) are always 0.

//: [Next](@next)

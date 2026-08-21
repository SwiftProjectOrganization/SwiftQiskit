//: [Previous](@previous)

import SwiftQiskitCore

// ============================================================
// Section 1 — Bell State  |Φ⁺⟩ = (|00⟩ + |11⟩) / √2
// ============================================================
// Apply Hadamard to qubit 0, then CNOT (control 0 → target 1).
// This creates a maximally-entangled 2-qubit Bell state.

let bellCircuit = QuantumCircuit(qubits: 2)
bellCircuit.h(0)        // |00⟩ → (|00⟩ + |10⟩) / √2
bellCircuit.cx(0, 1)    // → (|00⟩ + |11⟩) / √2

// ============================================================
// Section 2 — Inspect the StateVector
// ============================================================

let bellState = bellCircuit.run()
print("Bell state amplitudes:")
print(bellState)
// Expected: |00⟩ ≈ 0.707, |11⟩ ≈ 0.707, others ≈ 0

let probs = bellState.probabilities
// Expected: [0.5, 0.0, 0.0, 0.5]
print("\nProbabilities: \(probs)")

// Access individual amplitudes
let amp00 = bellState[0]    // Complex ≈ (0.707, 0)
let amp11 = bellState[3]    // Complex ≈ (0.707, 0)
print("Amplitude |00⟩: \(amp00)")
print("Amplitude |11⟩: \(amp11)")

// ============================================================
// Section 3 — Measurement (1000 shots)
// ============================================================

let result = bellCircuit.measure(shots: 1000)
print("\nMeasurement counts (1000 shots):")
for (state, count) in result.sortedCounts {
    let pct = Double(count) / Double(result.shots) * 100
    print("  |\(state)⟩ : \(count)  (\(String(format: "%.1f", pct))%)")
}
// Expected: ~500 × |00⟩, ~500 × |11⟩ — no |01⟩ or |10⟩

// ============================================================
// Section 4 — GHZ State  |GHZ⟩ = (|000⟩ + |111⟩) / √2
// ============================================================
// The Bell recipe, one qubit further: entangle a third qubit by
// adding a second CNOT from the same control. `cx(control, target)`
// works on any distinct pair of an n-qubit register — note that
// cx(0, 2) spans non-adjacent qubits, skipping over qubit 1.

let ghzCircuit = QuantumCircuit(qubits: 3)
ghzCircuit.h(0)      // |000⟩ → (|000⟩ + |100⟩) / √2
ghzCircuit.cx(0, 1)  // → (|000⟩ + |110⟩) / √2

var ghzState = ghzCircuit.run()
print("\nGHZ state amplitudes:")
print(ghzState)
// Expected: |000⟩ ≈ 0.707, |110⟩ ≈ 0.707, others 0

ghzCircuit.cx(0, 2)     // → (|000⟩ + |111⟩) / √2

ghzState = ghzCircuit.run()
print("\nGHZ state amplitudes:")
print(ghzState)
// Expected: |000⟩ ≈ 0.707, |111⟩ ≈ 0.707, others 0

print("\nGHZ probabilities: \(ghzState.probabilities)")
// Expected: [0.5, 0, 0, 0, 0, 0, 0, 0.5]

let ghzResult = ghzCircuit.measure(shots: 1000)
print("\nGHZ measurement counts (1000 shots):")
for (state, count) in ghzResult.sortedCounts {
    print("  |\(state)⟩ : \(count)")
}
// Expected: ~500 × |000⟩, ~500 × |111⟩ — all three qubits always
// agree, never any other outcome.


// Matrix-form equivalent of cx(0,1) — same as Section 1 CNOT, via apply(_:)
let bellCircuit2 = QuantumCircuit(qubits: 2)
bellCircuit2.h(0)
bellCircuit2.apply(CNOTGate.matrix)     // identical to .cx(0, 1) for a 2-qubit circuit
let bellState2 = bellCircuit2.run()
print("\nBell state via apply(CNOTGate.matrix) probabilities: \(bellState2.probabilities)")
// Expected: [0.5, 0.0, 0.0, 0.5]

//: [Next](@next)

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

//: [Next](@next)

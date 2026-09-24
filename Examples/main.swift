//
//  main.swift
//  SwiftQiskitExamples
//
//  Demonstrates creation of a Bell State (|Φ⁺⟩)
//  |Φ⁺⟩ = (|00⟩ + |11⟩) / √2
//

import Foundation
import SwiftQiskit

// =====================================
// Bell State Example
// =====================================

// Create a 2-qubit quantum circuit
let circuit = QuantumCircuit(qubits: 2)

// Apply gates
// H on qubit 0
circuit.h(0)

// CNOT (control: 0 → target: 1)
circuit.cx(0, 1)

// =====================================
// Run circuit (statevector simulation)
// =====================================

let finalState = circuit.run()

print("Final quantum state (StateVector):")
print(finalState)

// =====================================
// Measurement (shots-based simulation)
// =====================================

let shots = 1000
let result = circuit.measure(shots: shots)

print("\nMeasurement results (\(shots) shots):")
for (state, count) in result.sortedCounts {
    let probability = Double(count) / Double(shots)
    print("\(state): \(count) (\(String(format: "%.2f", probability)))")
}

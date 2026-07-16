//: [Previous](@previous)

import SwiftQiskitCore

// Build a custom 1-qubit gate (Identity, manually)
let pauliI = Matrix([
    [Complex.one, Complex.zero ],
    [Complex.zero,  Complex.one]
])
let xCircuit3 = QuantumCircuit(qubits: 1)
xCircuit3.apply(pauliI)
("\npauliI gate applied to |0⟩ → probabilities: \(xCircuit3.run().probabilities)")
// Expected: [1.0, 0.0]


// Build a custom 1-qubit gate (Pauli-X, manually)
let customX = Matrix([
    [Complex.zero, Complex.one ],
    [Complex.one,  Complex.zero]
])
let xCircuit2 = QuantumCircuit(qubits: 1)
xCircuit2.apply(customX)
print("\nCustom X gate applied to |0⟩ → probabilities: \(xCircuit2.run().probabilities)")
// Expected: [0.0, 1.0]

PauliZGate.matrix

//: [Next](@next)

//: [Previous](@previous)

import SwiftQiskitCore

// Build a custom 1-qubit gate (Identity, manually)

let xCircuit1 = QuantumCircuit(qubits: 1)
xCircuit1.x(0)
xCircuit1.run().probabilities

// Build a custom 1-qubit gate (Pauli-X, manually)
let customX = Matrix([
    [Complex.zero, Complex.one ],
    [Complex.one,  Complex.zero]
])
let xCircuit2 = QuantumCircuit(qubits: 1)
xCircuit2.apply(customX)
xCircuit2.run().probabilities

PauliZGate.matrix

let pauliI = Matrix([
    [Complex.one, Complex.zero ],
    [Complex.zero,  Complex.one]
])
let xCircuit3 = QuantumCircuit(qubits: 1)
xCircuit3.apply(pauliI)
print("\npauliI gate applied to |0⟩ → probabilities: \(xCircuit3.run().probabilities)")
// Expected: [1.0, 0.0]

//: [Next](@next)

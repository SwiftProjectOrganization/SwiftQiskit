//: [Previous](@previous)

import Foundation
import SwiftQiskitCore

var qc0 = QuantumCircuit(qubits: 2)
qc0

qc0.h(0)
qc0.cx(0, 1)

let qc0State = qc0.run()
print(qc0State.amplitudes.description)

qc0.measure(shots: 2000)
qc0State.probabilities
print(qc0State.probabilities.description)

//: [Next](@next)

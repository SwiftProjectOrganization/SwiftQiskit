//: [Previous](@previous)

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskitCore

// Single qubit examples. See 02Bloch2d for more qubit examples.
let q0: Ket = .zero
let q1: Ket = .plusI

// Multi qubit creation examples
let sv0: StateVector = Ket("000")
let sv1: StateVector = Ket("010")
let sv2: StateVector = .zero ⊗ .plusI ⊗ .zero ⊗ .zero

// Single qubit circuit examples
// Quantum circuit are needed to apply quantum gates

// The circuit1 and circuit2 stages below
// are shown live on Bloch spheres

var stages1: [(name: String, bloch: BlochVector)] = []
let circuit1 = QuantumCircuit(qubits: 1)

stages1.append(("|0⟩", BlochVector(circuit1.run())))
circuit1.h(0)
stages1.append(("H → |+⟩", BlochVector(circuit1.run())))
circuit1.p(1.571, 0)
stages1.append(("P(π/2) → |+i⟩", BlochVector(circuit1.run())))
circuit1.p(3.142, 0)
stages1.append(("P(π) → |−i⟩", BlochVector(circuit1.run())))
circuit1.run().probabilities

var stages2: [(name: String, bloch: BlochVector)] = []
let circuit2 = QuantumCircuit(qubits: 1)
circuit2.run().probabilities
stages2.append(("|0⟩", BlochVector(circuit2.run())))
circuit2.h(0)
circuit2.run().probabilities
stages2.append(("H → |+⟩", BlochVector(circuit2.run())))
circuit2.z(0)
circuit2.run().probabilities
stages2.append(("Z → |−⟩", BlochVector(circuit2.run())))
circuit2.h(0)
circuit2.run().probabilities
stages2.append(("H → |1⟩", BlochVector(circuit2.run())))

// Operations with Bra and Ket objects

let ket0 = Ket([Complex(1/2), Complex(1/2)])
let bra0 = ket0†
bra0 * ket0
ket0.amplitudes
ket0.probabilities

let ket1 = Ket([Complex(0.8660254037844387), Complex(0.35355339059327373, 0.3535533905932737)])
let bra1 = ket1†
bra1 * ket1

ket1.dimension.magnitude

ket1.amplitudes

ket1.probabilities

ket1†

ket1† * ket1

ket1 ⊗ ket1

(ket1†)†

ket1 * ket1†

ket1† * Matrix.identity(size: 2)

// Live view: the circuit1 and circuit2 stages on Bloch spheres.
// Stateless view (no @State) — required for page code, see PLAYGROUNDSUPPORT.md.

struct CircuitStagesView: View {
    let sections: [(title: String, stages: [(name: String, bloch: BlochVector)])]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(sections, id: \.title) { section in
                Text(section.title)
                    .font(.title3.bold())
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(260)), count: 2), spacing: 16) {
                    ForEach(section.stages, id: \.name) { stage in
                        BlochSphereView(label: stage.name, bloch: stage.bloch)
                    }
                }
            }
        }
        .padding()
    }
}

PlaygroundPage.current.setLiveView(
    CircuitStagesView(sections: [
        ("circuit1", stages1),
        ("circuit2", stages2)
    ])
    .frame(width: 560, height: 1340)
)

//: [Next](@next)

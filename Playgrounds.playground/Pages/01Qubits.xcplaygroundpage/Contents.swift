//: [Previous](@previous)

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskitCore

let q0: Ket = .zero
let q1: Ket = .plusI

// The plusCircuit and minusCircuit stages below are shown live on
// Bloch spheres (see the live view); 02Bloch2d has the full
// six-state gallery.

// |0⟩ — empty circuit
let zeroCircuit = QuantumCircuit(qubits: 1)

let xCircuit: QuantumCircuit = zeroCircuit
xCircuit.x(0)
xCircuit.run().probabilities

// |1⟩ — Pauli-X flips |0⟩
let oneCircuit = QuantumCircuit(qubits: 1)
oneCircuit.run().probabilities
oneCircuit.x(0)
oneCircuit.run().probabilities

// |1⟩ — Pauli-Y flips |0⟩
let yCircuit = QuantumCircuit(qubits: 1)
yCircuit.run().probabilities
yCircuit.y(0)
yCircuit.run().probabilities
yCircuit.z(0)
yCircuit.run().probabilities

// |+⟩ = (|0⟩ + |1⟩)/√2 — Hadamard. P(π/2) and P(π) applied further
// down (in the |+i⟩ section) then rotate it to |+i⟩ and on to |−i⟩;
// each stage's Bloch vector is captured for the live view.
var plusStages: [(name: String, bloch: BlochVector)] = []
let plusCircuit = QuantumCircuit(qubits: 1)
plusStages.append(("|0⟩", BlochVector(plusCircuit.run())))
plusCircuit.h(0)
plusStages.append(("H → |+⟩", BlochVector(plusCircuit.run())))

// |−⟩ = (|0⟩ − |1⟩)/√2 — Hadamard then Pauli-Z (the final H shows HZH = X).
// Each stage's Bloch vector is captured for the live view: probabilities
// can't tell |+⟩ from |−⟩ (both 50/50), but the Bloch sphere can.
var minusStages: [(name: String, bloch: BlochVector)] = []
let minusCircuit = QuantumCircuit(qubits: 1)
minusCircuit.run().probabilities
minusStages.append(("|0⟩", BlochVector(minusCircuit.run())))
minusCircuit.h(0)
minusCircuit.run().probabilities
minusStages.append(("H → |+⟩", BlochVector(minusCircuit.run())))
minusCircuit.z(0)
minusCircuit.run().probabilities
minusStages.append(("Z → |−⟩", BlochVector(minusCircuit.run())))
minusCircuit.h(0)
minusCircuit.run().probabilities
minusStages.append(("H → |1⟩", BlochVector(minusCircuit.run())))

// |+i⟩ = (|0⟩ + i|1⟩)/√2 — Hadamard then S (the phase gate √Z)
let plusICircuit = QuantumCircuit(qubits: 1)
plusICircuit.h(0)
plusICircuit.run().probabilities
plusICircuit.s(0)
plusICircuit.run().probabilities
plusCircuit.p(1.571, 0)
plusStages.append(("P(π/2) → |+i⟩", BlochVector(plusCircuit.run())))
plusICircuit.run().probabilities
plusICircuit.p(3.142, 0)
plusICircuit.run().probabilities
plusCircuit.p(3.142, 0)
plusStages.append(("P(π) → |−i⟩", BlochVector(plusCircuit.run())))
plusICircuit.run().probabilities

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

// Live view: the plusCircuit and minusCircuit stages on Bloch spheres.
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
        ("minusCircuit", minusStages),
        ("plusCircuit", plusStages)
    ])
    .frame(width: 560, height: 1340)
)

//: [Next](@next)

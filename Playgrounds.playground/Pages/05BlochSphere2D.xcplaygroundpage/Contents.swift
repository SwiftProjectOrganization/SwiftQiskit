//: [Previous](@previous)

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskitCore

// ============================================================
// Section 1 — Bloch vector math
// ============================================================
// A single-qubit state |ψ⟩ = α|0⟩ + β|1⟩ maps to a point on the
// Bloch sphere (up to global phase):
//
//   x = 2·Re(ᾱβ)
//   y = 2·Im(ᾱβ)
//   z = |α|² − |β|²
//
// with spherical angles θ = acos(z), φ = atan2(y, x).
//
// The implementation (`BlochVector`) and the sphere canvas
// (`BlochSphereView`) live in the playground's shared Sources
// folder, so every page can use them.

// ============================================================
// Section 2 — Demo states built with SwiftQiskitCore
// ============================================================

// |0⟩ — empty circuit
let zeroCircuit = QuantumCircuit(qubits: 1)

// |1⟩ — Pauli-X flips |0⟩
let oneCircuit = QuantumCircuit(qubits: 1)
oneCircuit.x(0)

// |+⟩ = (|0⟩ + |1⟩)/√2 — Hadamard
let plusCircuit = QuantumCircuit(qubits: 1)
plusCircuit.h(0)

// |−⟩ = (|0⟩ − |1⟩)/√2 — Hadamard then Pauli-Z
let minusCircuit = QuantumCircuit(qubits: 1)
minusCircuit.h(0)
minusCircuit.z(0)

let states: [(name: String, bloch: BlochVector)] = [
    ("|0⟩", BlochVector(zeroCircuit.run())),
    ("|1⟩", BlochVector(oneCircuit.run())),
    ("|+⟩", BlochVector(plusCircuit.run())),
    ("|−⟩", BlochVector(minusCircuit.run()))
]

// Console readout
for state in states {
    let b = state.bloch
    print(
        String(
            format: "%@  x %+.3f  y %+.3f  z %+.3f  (θ %.3f, φ %.3f)",
            state.name, b.x, b.y, b.z, b.theta, b.phi
        )
    )
}
// Expected:
//   |0⟩ → (0, 0, +1)   north pole
//   |1⟩ → (0, 0, −1)   south pole
//   |+⟩ → (+1, 0, 0)   +x axis
//   |−⟩ → (−1, 0, 0)   −x axis

// ============================================================
// Section 3 — Live view
// ============================================================

struct BlochGalleryView: View {
    let states: [(name: String, bloch: BlochVector)]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(260)), count: 2), spacing: 16) {
            ForEach(states, id: \.name) { state in
                BlochSphereView(label: state.name, bloch: state.bloch)
            }
        }
        .padding()
    }
}

PlaygroundPage.current.setLiveView(
    BlochGalleryView(states: states)
        .frame(width: 560, height: 640)
)

//: [Next](@next)

//: [Previous](@previous)

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

// ============================================================
// Tensor networks — a second, independent way to read a circuit
// ============================================================
// `QuantumCircuit.run()` replays every gate as its full 2ⁿ×2ⁿ embedded
// matrix. `TensorNetwork(circuit)` instead keeps each gate as its own
// small *local* tensor — 2^k × 2^k for a k-qubit gate — and the wiring
// that says which qubit legs it plugs into:
//
//   - every qubit wire is a bond-dimension-2 edge (it carries one
//     qubit's two basis values);
//   - a k-qubit gate is a rank-2k tensor: k "incoming" legs and k
//     "outgoing" legs, exactly `local`'s row/column dimension;
//   - the `|0⟩` state each qubit starts in is drawn as a small cap on
//     the far left of its wire, with nothing to its left.
//
// `TensorNetwork.contract()` evaluates the whole diagram from nothing
// but those local tensors and the edges — never the big embedded
// matrices `run()` uses — so comparing the two is a genuine
// cross-check, not the same computation read twice.

func maxAmplitudeError(_ a: StateVector, _ b: StateVector) -> Double {
    var maxError = 0.0
    for i in 0..<a.dimension {
        maxError = max(maxError, (a[i] - b[i]).magnitude)
    }
    return maxError
}

func summarize(_ label: String, _ circuit: QuantumCircuit) -> TensorNetwork {
    let network = TensorNetwork(circuit)
    let error = maxAmplitudeError(network.contract(), circuit.run())
    print("\(label): \(network.nodes.count) nodes, \(network.edges.count) edges, " +
          "contract() vs run() max amplitude error = \(String(format: "%.2e", error))")
    return network
}

// ============================================================
// Section 1 — a Bell pair
// ============================================================
// h(0); cx(0,1): 2 inputs + H + CX + 2 outputs = 6 nodes; H has one
// leg (1 edge), CX has two (2 edges), and the two outputs add 2 more
// — 5 edges in total.

let bell = QuantumCircuit(qubits: 2)
bell.h(0)
bell.cx(0, 1)
let bellNetwork = summarize("Bell pair", bell)
// Expected: 6 nodes, 5 edges, error ≈ 0.00e+00.

// ============================================================
// Section 2 — a GHZ state, with a non-adjacent cx (page 07)
// ============================================================
// h(0); cx(0,1); cx(0,2): the second CX's legs are q0 and q2, skipping
// over q1 — its node's box, drawn below, spans all three wires, with
// q1's wire crossing it dashed to show it isn't one of its legs.

let ghz = QuantumCircuit(qubits: 3)
ghz.h(0)
ghz.cx(0, 1)
ghz.cx(0, 2)
let ghzNetwork = summarize("GHZ (non-adjacent cx)", ghz)

// ============================================================
// Section 3 — rzz unfolds into cx; rz; cx (page 21's identity)
// ============================================================
// `rzz` is built from `pauliRotation`, which for an all-Z string needs
// no basis change: just a CNOT staircase, one `rz`, and the staircase
// undone. On two qubits that's exactly 3 gate nodes — CX, RZ, CX —
// which is the identity page 21 checks against `Matrix.expm()`.

let zz = QuantumCircuit(qubits: 2)
zz.rzz(0.7, 0, 1)
let zzNetwork = summarize("rzz(0.7, 0, 1)", zz)

let zzGateNames = zzNetwork.nodes.compactMap { node -> String? in
    guard case .gate(let name) = node.kind else { return nil }
    return name
}
print("rzz's gate nodes in order: \(zzGateNames)")
// Expected: ["CX", "RZ(0.700)", "CX"].

// ============================================================
// Section 4 — a small (2-qubit) QFT ladder (page 16)
// ============================================================
// The controlled-phase gate CP(θ) page 16 derives from `p`+`cx`:
// p(θ/2, c); cx(c, t); p(-θ/2, t); cx(c, t); p(θ/2, t) — 5 gate nodes
// for one CP. A 2-qubit QFT (no swap) is h(0); CP(π/2, 0, 1); h(1):
// 7 gate nodes end to end.

func cp(_ theta: Double, control: Int, target: Int, on circuit: QuantumCircuit) {
    circuit.p(theta / 2, control)
    circuit.cx(control, target)
    circuit.p(-theta / 2, target)
    circuit.cx(control, target)
    circuit.p(theta / 2, target)
}

let qft = QuantumCircuit(qubits: 2)
qft.h(0)
cp(.pi / 2, control: 0, target: 1, on: qft)
qft.h(1)
let qftNetwork = summarize("2-qubit QFT ladder", qft)

//: The four `print`s above should each report an error on the order
//: of 1e-15 or smaller — `contract()`'s from-scratch evaluation of the
//: small local tensors agrees with `run()`'s full-matrix replay on
//: every one of these circuits, including the non-adjacent `cx` and
//: the 7-gate QFT ladder.

// ============================================================
// Live view — all four networks, drawn circuit-style
// ============================================================
// Qubit wires run left to right; `|0⟩` caps sit on the far left,
// open output legs on the right, and every gate sits in its own time
// column as a labelled box on the wires it touches.

let gallery = VStack(alignment: .leading, spacing: 20) {
    TensorNetworkView(bellNetwork, title: "Bell pair")
    TensorNetworkView(ghzNetwork, title: "GHZ (non-adjacent cx)")
    TensorNetworkView(zzNetwork, title: "rzz → cx; rz; cx")
    TensorNetworkView(qftNetwork, title: "2-qubit QFT ladder")
}
.padding()

PlaygroundPage.current.setLiveView(gallery)

//: [Next](@next)

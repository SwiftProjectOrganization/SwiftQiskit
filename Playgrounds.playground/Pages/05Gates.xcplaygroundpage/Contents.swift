//: [Previous](@previous)

import SwiftQiskitCore

// This page is results-sidebar style, like `01Qubits` — no `print` calls.
// Every gate below runs on a fresh 1-qubit circuit starting at |0⟩; watch the
// sidebar (or Quick Look) for each expression's amplitudes/probabilities.

// ------------------------------------------------------------
// 1 — Doing nothing: a circuit starts at |0⟩
// ------------------------------------------------------------

let qcIdentity = QuantumCircuit(qubits: 1)
qcIdentity.run().probabilities             // [1.0, 0.0] — no gates recorded yet

// ------------------------------------------------------------
// 2 — X: bit flip, |0⟩ → |1⟩
// ------------------------------------------------------------

let qcX = QuantumCircuit(qubits: 1)
qcX.x(0)
let stateX = qcX.run()
stateX.amplitudes                          // [0, 1]
stateX.probabilities                       // [0.0, 1.0]

// ------------------------------------------------------------
// 3 — H: superposition, |0⟩ → (|0⟩ + |1⟩)/√2
// ------------------------------------------------------------

let qcH = QuantumCircuit(qubits: 1)
qcH.h(0)
let stateH = qcH.run()
stateH.amplitudes                          // [0.7071..., 0.7071...]
stateH.probabilities                       // [0.5, 0.5]

// ------------------------------------------------------------
// 4 — Z: phase flip, invisible until you interfere
// ------------------------------------------------------------

let qcZAlone = QuantumCircuit(qubits: 1)
qcZAlone.z(0)
qcZAlone.run().probabilities                // [1.0, 0.0] — Z does nothing to |0⟩

let qcHZ = QuantumCircuit(qubits: 1)
qcHZ.h(0)
qcHZ.z(0)
let stateHZ = qcHZ.run()
stateHZ.amplitudes                          // [0.7071..., -0.7071...] — phase flipped...
stateHZ.probabilities                       // ...but still [0.5, 0.5] — not yet visible

let qcHZH = QuantumCircuit(qubits: 1)
qcHZH.h(0)
qcHZH.z(0)
qcHZH.h(0)
qcHZH.run().probabilities                   // [0.0, 1.0] — the second H turns phase into a bit flip

// ------------------------------------------------------------
// 5 — Y: bit flip and phase flip at once
// ------------------------------------------------------------

let qcY = QuantumCircuit(qubits: 1)
qcY.y(0)
let stateY = qcY.run()
stateY.amplitudes                           // [0, i] — same probabilities as X, different phase
stateY.probabilities                        // [0.0, 1.0]

// ------------------------------------------------------------
// 6 — S / S†: quarter turns around the equator
// ------------------------------------------------------------

let qcS = QuantumCircuit(qubits: 1)
qcS.h(0)
qcS.s(0)
qcS.run().amplitudes                        // [0.7071..., 0.7071i...] — |+i⟩

let qcSdg = QuantumCircuit(qubits: 1)
qcSdg.h(0)
qcSdg.sdg(0)
qcSdg.run().amplitudes                      // [0.7071..., -0.7071i...] — |-i⟩

// ------------------------------------------------------------
// 7 — T / T†: eighth turns; two T's make one S
// ------------------------------------------------------------

let qcTT = QuantumCircuit(qubits: 1)
qcTT.h(0)
qcTT.t(0)
qcTT.t(0)
qcTT.run().amplitudes                       // matches qcS above (up to ~1e-16 rounding)

// ------------------------------------------------------------
// 8 — P(θ): the general phase gate, S/T/Z as special cases
// ------------------------------------------------------------

let qcPHalfPi = QuantumCircuit(qubits: 1)
qcPHalfPi.h(0)
qcPHalfPi.p(.pi / 2, 0)
qcPHalfPi.run().amplitudes                  // P(π/2) == S, matches qcS above

let qcPQuarterPi = QuantumCircuit(qubits: 1)
qcPQuarterPi.h(0)
qcPQuarterPi.p(.pi / 4, 0)
qcPQuarterPi.run().amplitudes               // P(π/4) == T

let qcPPi = QuantumCircuit(qubits: 1)
qcPPi.h(0)
qcPPi.p(.pi, 0)
qcPPi.run().amplitudes                      // P(π) == Z, matches qcHZ above

// ------------------------------------------------------------
// 9 — Rotations RX/RY/RZ(θ): continuous turns about each axis
// ------------------------------------------------------------

let qcRY = QuantumCircuit(qubits: 1)
qcRY.ry(.pi / 2, 0)
qcRY.run().amplitudes                       // [0.7071..., 0.7071...] — same as H|0⟩, reached by a turn

let qcRX = QuantumCircuit(qubits: 1)
qcRX.rx(.pi / 2, 0)
qcRX.measure(shots: 1000)                   // roughly half-and-half, like measuring H|0⟩

let qcRZ = QuantumCircuit(qubits: 1)
qcRZ.h(0)
qcRZ.rz(.pi / 2, 0)
qcRZ.run().probabilities                    // [0.5, 0.5] — same probabilities as qcPHalfPi,
                                             // different raw amplitudes (RZ differs from P by a global phase)

// ------------------------------------------------------------
// 10 — Two qubits, one peek ahead: CNOT entangles
// ------------------------------------------------------------

let qcBell = QuantumCircuit(qubits: 2)
qcBell.h(0)
qcBell.cx(0, 1)
qcBell.run().probabilities                  // [0.5, 0.0, 0.0, 0.5] — the Bell state;
                                             // see 07Entanglement for the full walkthrough

//: [Next](@next)

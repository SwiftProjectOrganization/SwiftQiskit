import SwiftQiskitCore

// ============================================================
// Section 1 — Bell State  |Φ⁺⟩ = (|00⟩ + |11⟩) / √2
// ============================================================
// Apply Hadamard to qubit 0, then CNOT (control 0 → target 1).
// This creates a maximally-entangled 2-qubit Bell state.

let bellCircuit = QuantumCircuit(qubits: 2)
bellCircuit.h(0)        // |00⟩ → (|00⟩ + |10⟩) / √2
bellCircuit.cx(0, 1)    // → (|00⟩ + |11⟩) / √2

// ============================================================
// Section 2 — Inspect the StateVector
// ============================================================

let bellState = bellCircuit.run()
print("Bell state amplitudes:")
print(bellState)
// Expected: |00⟩ ≈ 0.707, |11⟩ ≈ 0.707, others ≈ 0

let probs = bellState.probabilities
// Expected: [0.5, 0.0, 0.0, 0.5]
print("\nProbabilities: \(probs)")

// Access individual amplitudes
let amp00 = bellState[0]    // Complex ≈ (0.707, 0)
let amp11 = bellState[3]    // Complex ≈ (0.707, 0)
print("Amplitude |00⟩: \(amp00)")
print("Amplitude |11⟩: \(amp11)")

// ============================================================
// Section 3 — Measurement (1000 shots)
// ============================================================

let result = bellCircuit.measure(shots: 1000)
print("\nMeasurement counts (1000 shots):")
for (state, count) in result.sortedCounts {
    let pct = Double(count) / Double(result.shots) * 100
    print("  |\(state)⟩ : \(count)  (\(String(format: "%.1f", pct))%)")
}
// Expected: ~500 × |00⟩, ~500 × |11⟩ — no |01⟩ or |10⟩

// ============================================================
// Section 4 — Single-qubit gates on a 1-qubit circuit
// ============================================================

// Pauli-X (bit flip): |0⟩ → |1⟩
let xCircuit = QuantumCircuit(qubits: 1)
xCircuit.x(0)
let xState = xCircuit.run()
print("\nPauli-X on |0⟩ → probabilities: \(xState.probabilities)")
// Expected: [0.0, 1.0]  (100% chance of measuring |1⟩)

// Hadamard: |0⟩ → (|0⟩ + |1⟩) / √2
let hCircuit = QuantumCircuit(qubits: 1)
hCircuit.h(0)
let hState = hCircuit.run()
print("Hadamard on |0⟩ → probabilities: \(hState.probabilities)")
// Expected: [0.5, 0.5]

// Pauli-Z (phase flip): |0⟩ → |0⟩ (no observable change in probabilities, but flips phase of |1⟩)
let zCircuit = QuantumCircuit(qubits: 1)
zCircuit.z(0)
let zState = zCircuit.run()
print("Pauli-Z on |0⟩ → probabilities: \(zState.probabilities)")
// Expected: [1.0, 0.0]  (still in |0⟩; Z adds phase only when in |1⟩)

// Matrix-form equivalent of cx(0,1) — same as Section 1 CNOT, via apply(_:)
let bellCircuit2 = QuantumCircuit(qubits: 2)
bellCircuit2.h(0)
bellCircuit2.apply(CNOTGate.matrix)     // identical to .cx(0, 1) for a 2-qubit circuit
let bellState2 = bellCircuit2.run()
print("\nBell state via apply(CNOTGate.matrix) probabilities: \(bellState2.probabilities)")
// Expected: [0.5, 0.0, 0.0, 0.5]

// ============================================================
// Section 5 — Complex and Matrix types
// ============================================================

// Complex arithmetic
let a = Complex(0.7071, 0)
let b = Complex(0, 1)           // same as Complex.i
let sum = a + b
let product = a * b
let magnitude = a.magnitude     // ≈ 0.7071
print("\nComplex: a=\(a)  b=\(b)  a+b=\(sum)  a*b=\(product)  |a|=\(magnitude)")

// Inspect the Hadamard gate matrix (2×2)
let H = HadamardGate.matrix
print("\nHadamard matrix (\(H.rows)×\(H.cols)):")
print(H)

// Identity matrix
let I2 = Matrix.identity(size: 2)
print("2×2 identity:")
print(I2)

// Build a custom 1-qubit gate (Pauli-X, manually)
let customX = Matrix([
    [Complex.zero, Complex.one ],
    [Complex.one,  Complex.zero]
])
let xCircuit2 = QuantumCircuit(qubits: 1)
xCircuit2.apply(customX)
print("\nCustom X gate applied to |0⟩ → probabilities: \(xCircuit2.run().probabilities)")
// Expected: [0.0, 1.0]

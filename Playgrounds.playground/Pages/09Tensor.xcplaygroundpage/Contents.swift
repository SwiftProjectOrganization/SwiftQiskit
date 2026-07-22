//: [Previous](@previous)

import Foundation
import SwiftQiskitCore

// ============================================================
// Tensor products — and how the unit tests check them
// ============================================================
// The Kronecker (tensor) product ⊗ is how quantum mechanics builds
// composite systems: matrices combine into multi-qubit gates, and
// state vectors combine into multi-qubit registers. Core exposes it
// as `tensor(_:)` / `⊗` on both Matrix and StateVector (design notes
// in Docs/TENSORPLAN.md).
//
// Each section below mirrors one test in
// Tests/SwiftQiskitCoreTests/TensorProductTests.swift, turning its
// #expect assertions into printed checks you can watch run.

let tolerance = 1e-10

// ============================================================
// Section 1 — Identity ⊗ identity gives a larger identity
// ============================================================
// Test: `Identity tensor identity gives larger identity`
// The simplest sanity check: I₂ ⊗ I₂ must be exactly I₄. Matrix is
// Equatable, so the test can use == with no tolerance — every entry
// is exactly 0 or 1.

let i2 = Matrix.identity(size: 2)
print("I₂ ⊗ I₂ == I₄ → \(i2 ⊗ i2 == Matrix.identity(size: 4))")
// Expected: true

// ============================================================
// Section 2 — H ⊗ I has the expected block structure
// ============================================================
// Test: `Hadamard tensor identity has expected entries`
// A ⊗ B replaces every entry aᵢⱼ of A with the block aᵢⱼ·B. With
// A = H and B = I₂ each ±1/√2 of H becomes a ±1/√2·I₂ block:

print("\nH ⊗ I₂ =")
print(HadamardGate.matrix ⊗ Matrix.identity(size: 2))

// The test compares every entry against this matrix, written out
// literally, within 1e-10 (H's entries are irrational, so exact ==
// is the wrong tool here):

let h = 1.0 / sqrt(2.0)
let expectedHI = Matrix([
    [Complex(h), .zero, Complex(h), .zero],
    [.zero, Complex(h), .zero, Complex(h)],
    [Complex(h), .zero, Complex(-h), .zero],
    [.zero, Complex(h), .zero, Complex(-h)]
])

let hi = HadamardGate.matrix ⊗ Matrix.identity(size: 2)
var maxEntryDiff = 0.0
for i in 0..<4 {
    for j in 0..<4 {
        maxEntryDiff = max(maxEntryDiff, (hi[i, j] - expectedHI[i, j]).magnitude)
    }
}
print("max entry difference vs expected: \(maxEntryDiff)")
// Expected: 0.0 (well below the 1e-10 tolerance)

// H ⊗ I is exactly the 4×4 unitary QuantumCircuit builds internally
// when you call h(0) on a 2-qubit circuit — "apply H to qubit 0,
// leave qubit 1 alone".

// ============================================================
// Section 3 — Dimensions multiply
// ============================================================
// Test: `Tensor product of non-square matrices has product dimensions`
// Unlike matrix multiplication, ⊗ never fails on a dimension
// mismatch: an m×n ⊗ p×q product is always defined, with shape
// mp×nq.

let a23 = Matrix(rows: 2, cols: 3, repeating: .one)
let b22 = Matrix(rows: 2, cols: 2, repeating: .i)
let shape = a23.tensor(b22)
print("\n(2×3) ⊗ (2×2) → \(shape.rows)×\(shape.cols)")
// Expected: 4×6

// ============================================================
// Section 4 — The mixed-product identity
// ============================================================
// Test: `Tensor product satisfies mixed-product identity`
// The property that makes ⊗ *the* right composition rule:
//
//   (A ⊗ B)(x ⊗ y) = (Ax) ⊗ (By)
//
// Acting on a composite system with A ⊗ B is the same as acting on
// each part separately and then combining. The test verifies it with
// A = X, B = H and two small vectors.

/// Kronecker product of plain amplitude vectors (as in the test)
func kronVector(_ u: [Complex], _ v: [Complex]) -> [Complex] {
    u.flatMap { ui in v.map { ui * $0 } }
}

let x: [Complex] = [Complex(0.6), Complex(0.8)]
let y: [Complex] = [.zero, .one]

let lhs = (PauliXGate.matrix ⊗ HadamardGate.matrix).multiply(by: kronVector(x, y))
let rhs = kronVector(PauliXGate.matrix.multiply(by: x), HadamardGate.matrix.multiply(by: y))

let maxVectorDiff = zip(lhs, rhs).map { ($0 - $1).magnitude }.max() ?? 0
print("\nmax |(X⊗H)(x⊗y) − (Xx)⊗(Hy)| = \(maxVectorDiff)")
// Expected: 0.0 here (the test allows up to 1e-10 of rounding)

// ============================================================
// Section 5 — Combining registers: |0⟩ ⊗ |0⟩ = |00⟩
// ============================================================
// Test: `Zero state tensor zero state gives two-qubit zero state`
// StateVector's ⊗ puts `self` in the high-order bits (qubit 0 is
// the most-significant bit), so tensoring matches label
// concatenation — page 08 used the same fact with Kets.

let zero1 = StateVector(qubits: 1)
print("\n|0⟩ ⊗ |0⟩ == |00⟩ → \(zero1 ⊗ zero1 == StateVector(qubits: 2))")
// Expected: true

// ============================================================
// Section 6 — Tensor product vs. running a circuit
// ============================================================
// Test: `State tensor product matches embedded gate in circuit`
// The cross-check tying Sections 2 and 5 together: applying H to a
// lone qubit and *then* tensoring with |0⟩ must equal running h(0)
// on a 2-qubit circuit (which applies H ⊗ I to |00⟩).

var plusState = StateVector(qubits: 1)
plusState.apply(HadamardGate.matrix)
let combined = plusState ⊗ StateVector(qubits: 1)

let qc = QuantumCircuit(qubits: 2)
qc.h(0)
let circuitState = qc.run()

let maxStateDiff = (0..<combined.dimension)
    .map { (combined[$0] - circuitState[$0]).magnitude }
    .max() ?? 0
print("\n(H|0⟩) ⊗ |0⟩:")
print(combined)
print("max amplitude difference vs circuit h(0): \(maxStateDiff)")
// Expected: 0.0 — the two constructions are the same unitary

// ============================================================
// Section 7 — What ⊗ *cannot* build: entanglement
// ============================================================
// (Not a unit test — the flip side of the story.) Every state built
// with ⊗ is a *product state*: qubit measurements are independent.
// A two-qubit product state (a|0⟩+b|1⟩) ⊗ (c|0⟩+d|1⟩) has
// amplitudes (ac, ad, bc, bd), so it always satisfies
//
//   α₀₀·α₁₁ = α₀₁·α₁₀     (both equal abcd)
//
// The Bell state |Φ⁺⟩ from page 01 violates this — no choice of
// single-qubit states tensors into it. That is entanglement, and it
// is why cx (unlike h/x/z) cannot be embedded one qubit at a time.

let bell = QuantumCircuit(qubits: 2)
bell.h(0)
bell.cx(0, 1)
let phiPlus = bell.run()

let productSide = phiPlus[0] * phiPlus[3]
let crossSide = phiPlus[1] * phiPlus[2]
print("\n|Φ⁺⟩: α₀₀·α₁₁ = \(productSide), α₀₁·α₁₀ = \(crossSide)")
print("factors as a tensor product → \((productSide - crossSide).magnitude < tolerance)")
// Expected: 0.5 vs 0.0 → false — |Φ⁺⟩ is entangled

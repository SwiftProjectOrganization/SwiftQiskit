//: [Previous](@previous)
/*:
 # Complex numbers and matrices

 `Complex` (`Math/Complex.swift`) and `Matrix` (`Math/Matrix.swift`) are the scalar and
 transformation types every state vector and gate matrix is built from. This page runs the
 code fragments from Chapter 2 of the SwiftQiskitApp INTRODUCTION
 (`Docs/Introduction/02-ComplexAndMatrices.md`) in order: construction, magnitude and phase,
 plain `[Complex]` vectors, inner products and normalization, matrices as transformations,
 unitarity, and the tensor product `⊗`.
 */

import Foundation
import SwiftQiskitCore

// ------------------------------------------------------------
// §2.2 — Complex numbers: construction, * and /, conjugate, magnitude
// ------------------------------------------------------------

let a = Complex(3, 4)
let b = Complex(1, -2)
print(a * b, a / b)
// (3+4i)(1-2i) = 11 - 2i; (3+4i)/(1-2i) = -1+2i

let z = Complex(3, 2)
print(z * z.conjugate, z.magnitudeSquared)
// z · z̄ is always real — exactly why it can serve as a probability (§2.3)

// ------------------------------------------------------------
// §2.3 — Why amplitudes have to be complex: the Born rule
// ------------------------------------------------------------

let amp = Complex(1.0 / sqrt(2.0), 0)
print(amp.magnitudeSquared)
// ≈ 0.5, not exactly 0.5 — ordinary floating-point rounding on 1/√2

// ------------------------------------------------------------
// §2.4 — The complex plane: magnitude and phase
// ------------------------------------------------------------

let theta = 0.7
let phase = Complex(cos(theta), sin(theta))
print(phase, phase.magnitude)
print(PhaseGate.matrix(theta: theta)[1, 1])
// the hand-built e^{iθ} matches PhaseGate.matrix(theta:)[1, 1] bit for bit;
// |e^{iθ}| == 1 always — a pure phase changes direction, never size

// ------------------------------------------------------------
// §2.5 — Vectors of amplitudes
// ------------------------------------------------------------

let zeroState: [Complex] = [.one, .zero]                              // certain to measure 0
let oneState: [Complex] = [.zero, .one]                               // certain to measure 1
let plusState: [Complex] = [Complex(1 / sqrt(2), 0), Complex(1 / sqrt(2), 0)]  // equal superposition

func addVec(_ a: [Complex], _ b: [Complex]) -> [Complex] {
    zip(a, b).map { $0 + $1 }
}
func scale(_ c: Complex, _ v: [Complex]) -> [Complex] {
    v.map { c * $0 }
}
print(addVec([Complex(1, 0), Complex(0, 1)], [Complex(2, 0), Complex(0, -1)]))
print(scale(Complex.i, [Complex(1, 0), Complex(2, 0)]))
// the library has no vector arithmetic of its own on plain [Complex] — these are one-line
// zip/map helpers; Chapter 3 hands this job to StateVector

// ------------------------------------------------------------
// §2.6 — Inner products, the dagger, and orthogonality
// ------------------------------------------------------------

func innerProduct(_ a: [Complex], _ b: [Complex]) -> Complex {
    var sum = Complex.zero
    for i in a.indices { sum = sum + a[i].conjugate * b[i] }
    return sum
}
let v: [Complex] = [Complex(1, 0), Complex.i]
let w: [Complex] = [Complex(1, 0), Complex(0, -1)]
print(innerProduct(v, w))
// 0.0 — v and w are orthogonal (perpendicular, completely distinguishable by measurement)

// ------------------------------------------------------------
// §2.7 — Length and normalization
// ------------------------------------------------------------

func norm(_ v: [Complex]) -> Double {
    sqrt(v.reduce(0.0) { $0 + $1.magnitudeSquared })
}
let raw: [Complex] = [Complex(1, 0), Complex.i]
print(norm(raw))
// √2 — [1, i] is not a legal quantum state as it stands

let normalized = raw.map { $0 * (1.0 / norm(raw)) }
print(normalized, norm(normalized))
// norm 1 up to floating-point rounding — a legal state; StateVector.init normalizes
// automatically from Chapter 3 onward, so this is the last point in the book where a
// non-unit vector can exist at all

// ------------------------------------------------------------
// §2.8 — Matrices as transformations, and why order matters
// ------------------------------------------------------------

let H = HadamardGate.matrix
print(H[0, 0], H.rows, H.cols)

print(H.multiply(by: [Complex.one, Complex.zero]))
// [√2/2, √2/2] — the same amplitudes the app's State Vector panel shows after a single H

let Z = PauliZGate.matrix
let ket0: [Complex] = [.one, .zero]
print((Z * H).multiply(by: ket0))   // "H then Z" → |−⟩
print((H * Z).multiply(by: ket0))   // wrong order → silently gives |+⟩ instead
// apply A then B is B * A, not A * B — QuantumCircuit itself never hits this trap, since
// run() applies each placed gate one at a time rather than forming a single product matrix

// ------------------------------------------------------------
// §2.9 — Unitary matrices, and why == lies
// ------------------------------------------------------------

let I2 = Matrix.identity(size: 2)
for (name, g) in [("H", HadamardGate.matrix), ("X", PauliXGate.matrix),
                   ("S", SGate.matrix), ("T", TGate.matrix)] {
    print(name, g.adjoint * g == I2)
}
// H is exactly as unitary as the others, but its ±1/√2 entries only approximate as a Double,
// so U†U misses I by ~2.22e-16 and exact == reports false — the fix is a tolerance
// comparison, not ==

func maxDiff(_ a: Matrix, _ b: Matrix) -> Double {
    var m = 0.0
    for i in 0..<a.rows { for j in 0..<a.cols {
        m = max(m, (a[i, j] - b[i, j]).magnitude)
    } }
    return m
}
print(maxDiff(H.adjoint * H, I2))
// ≈ 2.22e-16 — well under the 1e-10 tolerance this book uses from here on whenever two
// matrices need to be compared "close enough"

// ------------------------------------------------------------
// §2.10 — The tensor product ⊗
// ------------------------------------------------------------

let a23 = Matrix([[Complex(1), Complex(2), Complex(3)], [Complex(4), Complex(5), Complex(6)]])
print(a23.tensor(I2).rows, a23.tensor(I2).cols)
print(H.tensor(I2))
// each ±1/√2 entry of H became a ±1/√2 · I2 block — the block rule directly; ⊗ places no
// constraint on shapes (an m×n tensored with a p×q always gives mp×nq) and is not commutative

let qc = QuantumCircuit(qubits: 2)
qc.h(0)
print(qc.run().amplitudes)
print((H ⊗ I2).multiply(by: [Complex.one, .zero, .zero, .zero]))
// identical — h(qubit:) builds exactly H ⊗ I internally and applies that to the full state;
// there is no separate code path for "apply a gate to one qubit of several"

//: [Next](@next)

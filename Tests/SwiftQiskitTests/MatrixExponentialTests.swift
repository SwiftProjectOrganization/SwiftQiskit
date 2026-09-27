import Foundation
import Testing
@testable import SwiftQiskit

struct MatrixExponentialTests {

    private let tolerance = 1e-10

    /// Entrywise comparison of two matrices within tolerance
    private func approxEqual(_ a: Matrix, _ b: Matrix, tolerance: Double = 1e-10) -> Bool {
        guard a.rows == b.rows, a.cols == b.cols else { return false }
        for i in 0..<a.rows {
            for j in 0..<a.cols {
                if (a[i, j] - b[i, j]).magnitude >= tolerance { return false }
            }
        }
        return true
    }

    // MARK: - Single-qubit rotations

    /// exp(-iθX/2) matches RXGate.matrix(theta:) exactly (both are the same closed form)
    @Test func `expm reproduces RXGate via exp(-i theta X over 2)`() {
        let theta = 0.7
        let generator = PauliXGate.matrix * Complex(0, -theta / 2)
        #expect(approxEqual(generator.expm(), RXGate.matrix(theta: theta)))
    }

    /// exp(-iθY/2) matches RYGate.matrix(theta:)
    @Test func `expm reproduces RYGate via exp(-i theta Y over 2)`() {
        let theta = 1.3
        let generator = PauliYGate.matrix * Complex(0, -theta / 2)
        #expect(approxEqual(generator.expm(), RYGate.matrix(theta: theta)))
    }

    /// exp(-iθZ/2) matches RZGate.matrix(theta:)
    @Test func `expm reproduces RZGate via exp(-i theta Z over 2)`() {
        let theta = -0.9
        let generator = PauliZGate.matrix * Complex(0, -theta / 2)
        #expect(approxEqual(generator.expm(), RZGate.matrix(theta: theta)))
    }

    // MARK: - Base cases

    /// exp(0) is the identity
    @Test func `expm of the zero matrix is the identity`() {
        let zero = Matrix(rows: 3, cols: 3)
        #expect(approxEqual(zero.expm(), Matrix.identity(size: 3)))
    }

    /// exp(D) for a diagonal D is the entrywise exponential of the diagonal
    @Test func `expm of a diagonal matrix is entrywise exponential`() {
        let diagonal = Matrix([
            [Complex(1.5), .zero],
            [.zero, Complex(-2.0)]
        ])
        let expected = Matrix([
            [Complex(exp(1.5)), .zero],
            [.zero, Complex(exp(-2.0))]
        ])
        #expect(approxEqual(diagonal.expm(), expected))
    }

    // MARK: - Two-qubit ZZ identity (page 21Trotter's derivation)

    /// exp(-iθ·Z⊗Z/2) matches the gate identity cx(0,1); rz(θ,1); cx(0,1) — RZGate is
    /// exactly exp(-iθZ/2), and CX-conjugation maps I⊗Z ↔ Z⊗Z with no sign correction.
    @Test func `expm of Z tensor Z matches the cx-rz-cx identity`() {
        let theta = 0.7
        let zz = PauliZGate.matrix ⊗ PauliZGate.matrix
        let generator = zz * Complex(0, -theta / 2)

        let cx = CNOTGate.matrix
        let rz1 = Matrix.identity(size: 2) ⊗ RZGate.matrix(theta: theta)
        let viaGates = cx * rz1 * cx

        #expect(approxEqual(generator.expm(), viaGates))
    }

    // MARK: - Squaring path (large-norm input)

    /// A generator with norm well above the 0.5 scaling threshold still exponentiates to a
    /// unitary matrix, exercising the squaring loop rather than just a single Taylor sum.
    @Test func `expm stays unitary for a generator with a large norm`() {
        let hising = (PauliZGate.matrix ⊗ PauliZGate.matrix) + (PauliXGate.matrix ⊗ Matrix.identity(size: 2))
        let generator = hising * Complex(0, -10.0)
        let result = generator.expm()
        #expect(result.isUnitary(tolerance: 1e-8))
    }
}

import Foundation
import Testing
@testable import SwiftQiskit

struct MatrixArithmeticTests {

    private let tolerance = 1e-10

    /// Entrywise comparison of two matrices within tolerance
    private func approxEqual(_ a: Matrix, _ b: Matrix) -> Bool {
        guard a.rows == b.rows, a.cols == b.cols else { return false }
        for i in 0..<a.rows {
            for j in 0..<a.cols {
                if (a[i, j] - b[i, j]).magnitude >= tolerance { return false }
            }
        }
        return true
    }

    // MARK: - Addition

    /// Test that + is entrywise
    @Test func `Matrix addition is entrywise`() {
        let a = Matrix([[Complex(1), Complex(2)], [Complex(3), Complex(4)]])
        let b = Matrix([[Complex(5), Complex(6)], [Complex(7), Complex(8)]])
        let expected = Matrix([[Complex(6), Complex(8)], [Complex(10), Complex(12)]])
        #expect(a + b == expected)
    }

    /// Test that adding the zero matrix is a no-op
    @Test func `Adding the zero matrix leaves a matrix unchanged`() {
        let a = HadamardGate.matrix
        let zero = Matrix(rows: 2, cols: 2)
        #expect(a + zero == a)
    }

    /// Test that + is commutative
    @Test func `Matrix addition is commutative`() {
        let a = PauliXGate.matrix
        let b = PauliZGate.matrix
        #expect(a + b == b + a)
    }

    // MARK: - Subtraction

    /// Test that A - A is the zero matrix
    @Test func `Subtracting a matrix from itself gives the zero matrix`() {
        let a = PauliYGate.matrix
        #expect(a - a == Matrix(rows: 2, cols: 2))
    }

    /// Test that A - B matches A + (-1 · B)
    @Test func `Subtraction matches addition of the negated scalar multiple`() {
        let a = HadamardGate.matrix
        let b = PauliXGate.matrix
        #expect(a - b == a + (b * -1.0))
    }

    // MARK: - Scalar multiply

    /// Test scalar multiply by a Double against the identity matrix
    @Test func `Scalar multiply by a Double scales every entry`() {
        let i2 = Matrix.identity(size: 2)
        let scaled = 2.0 * i2
        #expect(scaled[0, 0] == Complex(2))
        #expect(scaled[1, 1] == Complex(2))
        #expect(scaled[0, 1] == .zero)
    }

    /// Test scalar multiply by a Complex against a hand-built literal
    @Test func `Scalar multiply by a Complex matches a hand-built literal`() {
        let x = PauliXGate.matrix
        let scaled = Complex.i * x
        let expected = Matrix([[.zero, Complex.i], [Complex.i, .zero]])
        #expect(scaled == expected)
    }

    /// Test that scalar multiply is order-symmetric on both sides
    @Test func `Scalar multiply is symmetric regardless of operand order`() {
        let m = HadamardGate.matrix
        #expect(m * 3.0 == 3.0 * m)
        #expect(m * Complex.i == Complex.i * m)
    }

    /// Test that multiplying by 1 is a no-op
    @Test func `Scalar multiply by one leaves a matrix unchanged`() {
        let m = PauliZGate.matrix
        #expect(m * 1.0 == m)
    }

    /// Test distributivity of matrix multiplication over addition: (A+B)C == AC + BC
    @Test func `Matrix multiplication distributes over addition`() {
        let a = HadamardGate.matrix
        let b = PauliXGate.matrix
        let c = PauliZGate.matrix
        #expect(approxEqual((a + b) * c, (a * c) + (b * c)))
    }

    // MARK: - Unitarity

    /// Test that known unitary gates (fixed and parameterized) pass `isUnitary`
    @Test func `Known unitary matrices pass isUnitary`() {
        #expect(HadamardGate.matrix.isUnitary())
        #expect(PauliXGate.matrix.isUnitary())
        #expect(CNOTGate.matrix.isUnitary())
        #expect(RXGate.matrix(theta: .pi / 7).isUnitary())
        #expect(Matrix.identity(size: 4).isUnitary())
    }

    /// Test that non-unitary matrices — including a non-square one — fail `isUnitary`
    @Test func `Non-unitary matrices fail isUnitary`() {
        let notNormPreserving = Matrix([[Complex(2), .zero], [.zero, Complex(1)]])
        #expect(!notNormPreserving.isUnitary())

        let nonSquare = Matrix(rows: 2, cols: 3)
        #expect(!nonSquare.isUnitary())
    }

    /// Test that `isUnitary`'s tolerance parameter is honored: a matrix perturbed by less
    /// than a loose tolerance passes, but fails against a tolerance tighter than the error
    @Test func `isUnitary tolerance controls how close counts as unitary`() {
        let epsilon = 1e-6
        let perturbed = Matrix([
            [Complex(1 + epsilon), .zero],
            [.zero, Complex(1)]
        ])
        #expect(perturbed.isUnitary(tolerance: 1e-3))
        #expect(!perturbed.isUnitary(tolerance: 1e-10))
    }

    // MARK: - Trace

    /// Test trace against known gates and a hand-summed literal
    @Test func `Trace sums the diagonal entries`() {
        #expect(PauliXGate.matrix.trace == .zero)
        #expect(PauliZGate.matrix.trace == .zero)
        #expect(Matrix.identity(size: 3).trace == Complex(3))

        let m = Matrix([[Complex(1, 2), Complex(9)], [Complex(-3), Complex(4, -1)]])
        #expect(m.trace == Complex(5, 1))
    }

    /// Test that trace is invariant under a similarity-style conjugation by a unitary —
    /// here H X H = Z, and both X and Z (like all three Paulis) are traceless
    @Test func `Trace is preserved under Hadamard conjugation`() {
        let h = HadamardGate.matrix
        let x = PauliXGate.matrix
        let conjugated = h * x * h
        #expect(approxEqual(conjugated, PauliZGate.matrix))
        #expect((conjugated.trace - x.trace).magnitude < tolerance)
    }

    // MARK: - Permutation Matrix

    /// Test that `Matrix.permutation` reproduces the fixed two-qubit CNOT
    /// (control = qubit 0 → bit 0b10, target = qubit 1 → bit 0b01)
    @Test func `Permutation matches the fixed two-qubit CNOT`() {
        let cnot = Matrix.permutation(size: 4) { col in
            (col & 0b10) != 0 ? col ^ 0b01 : col
        }
        #expect(cnot == CNOTGate.matrix)
    }

    /// Test that every permutation matrix is exactly unitary (0s and 1s only, no rounding)
    @Test func `Permutation matrices are exactly unitary`() {
        let reverse = Matrix.permutation(size: 8) { 7 - $0 }
        #expect(reverse.isUnitary())
        #expect(reverse.adjoint * reverse == Matrix.identity(size: 8))
    }

    /// Test that identity is the trivial permutation
    @Test func `Identity is the trivial permutation`() {
        #expect(Matrix.permutation(size: 5) { $0 } == Matrix.identity(size: 5))
    }

    // MARK: - Real use cases motivating this file

    /// Test that the basis projectors sum to the identity — Chapter 4 §4.3's
    /// completeness check, and `08Dirac`'s completeness comment, which could
    /// previously only be asserted, never computed.
    @Test func `Basis projectors sum to the identity via addition`() {
        let p0 = Ket.zero * Ket.zero†
        let p1 = Ket.one * Ket.one†
        #expect(p0 + p1 == Matrix.identity(size: 2))
    }

    /// Test that a scalar-combined tilted observable matches page 15CHSH's
    /// hand-written A(θ) literal: A(θ) = cos θ·Z + sin θ·X
    @Test func `Scalar-combined tilted observable matches a hand-built literal`() {
        let theta = Double.pi / 5
        let z = PauliZGate.matrix
        let x = PauliXGate.matrix
        let combined = (cos(theta) * z) + (sin(theta) * x)
        let handBuilt = Matrix([
            [Complex(cos(theta), 0), Complex(sin(theta), 0)],
            [Complex(sin(theta), 0), Complex(-cos(theta), 0)]
        ])
        #expect(approxEqual(combined, handBuilt))
    }
}

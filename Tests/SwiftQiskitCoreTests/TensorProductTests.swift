import Foundation
import Testing
@testable import SwiftQiskitCore

struct TensorProductTests {

    private let tolerance = 1e-10

    /// Test that I₂ ⊗ I₂ equals the 4×4 identity
    @Test func `Identity tensor identity gives larger identity`() {
        let i2 = Matrix.identity(size: 2)
        #expect(i2 ⊗ i2 == Matrix.identity(size: 4))
    }

    /// Test that H ⊗ I has the expected block structure
    @Test func `Hadamard tensor identity has expected entries`() {
        let h = 1.0 / sqrt(2.0)
        let expected = Matrix([
            [Complex(h), .zero, Complex(h), .zero],
            [.zero, Complex(h), .zero, Complex(h)],
            [Complex(h), .zero, Complex(-h), .zero],
            [.zero, Complex(h), .zero, Complex(-h)]
        ])

        let result = HadamardGate.matrix ⊗ Matrix.identity(size: 2)

        #expect(result.rows == 4 && result.cols == 4)
        for i in 0..<4 {
            for j in 0..<4 {
                #expect((result[i, j] - expected[i, j]).magnitude < tolerance)
            }
        }
    }

    /// Test tensor product dimensions for non-square matrices
    @Test func `Tensor product of non-square matrices has product dimensions`() {
        let a = Matrix(rows: 2, cols: 3, repeating: .one)
        let b = Matrix(rows: 2, cols: 2, repeating: .i)

        let result = a.tensor(b)

        #expect(result.rows == 4)
        #expect(result.cols == 6)
    }

    /// Test the mixed-product identity (A ⊗ B)(x ⊗ y) = (Ax) ⊗ (By)
    @Test func `Tensor product satisfies mixed-product identity`() {
        let a = PauliXGate.matrix
        let b = HadamardGate.matrix
        let x: [Complex] = [Complex(0.6), Complex(0.8)]
        let y: [Complex] = [.zero, .one]

        // Kronecker product of plain vectors
        func kronVector(_ u: [Complex], _ v: [Complex]) -> [Complex] {
            u.flatMap { ui in v.map { ui * $0 } }
        }

        let lhs = (a ⊗ b).multiply(by: kronVector(x, y))
        let rhs = kronVector(a.multiply(by: x), b.multiply(by: y))

        #expect(lhs.count == rhs.count)
        for (l, r) in zip(lhs, rhs) {
            #expect((l - r).magnitude < tolerance)
        }
    }

    /// Test that |0⟩ ⊗ |0⟩ equals the two-qubit |00⟩ state
    @Test func `Zero state tensor zero state gives two-qubit zero state`() {
        let zero = StateVector(qubits: 1)
        #expect(zero ⊗ zero == StateVector(qubits: 2))
    }

    /// Test that (H|0⟩) ⊗ |0⟩ matches running h(0) on a 2-qubit circuit
    @Test func `State tensor product matches embedded gate in circuit`() {
        var plus = StateVector(qubits: 1)
        plus.apply(HadamardGate.matrix)
        let combined = plus ⊗ StateVector(qubits: 1)

        let qc = QuantumCircuit(qubits: 2)
        qc.h(0)
        let expected = qc.run()

        #expect(combined.dimension == expected.dimension)
        for i in 0..<combined.dimension {
            #expect((combined[i] - expected[i]).magnitude < tolerance)
        }
    }
}

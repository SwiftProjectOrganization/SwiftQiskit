import Foundation
import Testing
@testable import SwiftQiskitCore

struct DiracNotationTests {

    private let tolerance = 1e-10

    /// Test orthonormality of the computational basis
    @Test func `Computational basis kets are orthonormal`() {
        #expect(((Bra("0") * Ket("0")) - .one).magnitude < tolerance)
        #expect((Bra("0") * Ket("1")).magnitude < tolerance)
        #expect((Bra("1") * Ket("0")).magnitude < tolerance)
        #expect(((Bra("1") * Ket("1")) - .one).magnitude < tolerance)
    }

    /// Test ⟨+|0⟩ = 1/√2
    @Test func `Plus state overlaps zero state with amplitude one over root two`() {
        let overlap = Ket.plus† * Ket.zero
        #expect((overlap - Complex(1.0 / sqrt(2.0))).magnitude < tolerance)
    }

    /// Test ⟨ψ|ψ⟩ = 1 for a state with complex amplitudes
    @Test func `Inner product of a normalized state with itself is one`() {
        let psi = Ket([Complex(0.6, 0.3), Complex(-0.2, 0.7)])
        #expect(((psi† * psi) - .one).magnitude < tolerance)
    }

    /// Test conjugate symmetry ⟨φ|ψ⟩ = conj(⟨ψ|φ⟩)
    @Test func `Inner product has conjugate symmetry`() {
        let psi = Ket.plusI
        let phi = Ket([Complex(0.8), Complex(0.0, 0.6)])
        let forward = phi† * psi
        let backward = psi† * phi
        #expect((forward - backward.conjugate).magnitude < tolerance)
    }

    /// Test completeness |0⟩⟨0| + |1⟩⟨1| = I
    @Test func `Basis projectors sum to the identity`() {
        let p0 = Ket.zero * Ket.zero†
        let p1 = Ket.one * Ket.one†
        let identity = Matrix.identity(size: 2)

        for i in 0..<2 {
            for j in 0..<2 {
                #expect((p0[i, j] + p1[i, j] - identity[i, j]).magnitude < tolerance)
            }
        }
    }

    /// Test that dagger is an involution: (ψ†)† = ψ, exactly —
    /// conjugation is exact and re-normalizing a normalized state is a no-op
    @Test func `Double dagger returns the original ket`() {
        let psi = Ket([Complex(0.6, 0.3), Complex(-0.2, 0.7)])
        #expect((psi†)† == psi)
        #expect((Ket.plus†)† == Ket.plus)
    }

    /// Test Pauli-Z expectation values ⟨ψ|Z|ψ⟩
    @Test func `Pauli Z expectation values match theory`() {
        let z = PauliZGate.matrix
        #expect(((Ket.zero† * z * Ket.zero) - .one).magnitude < tolerance)
        #expect(((Ket.one† * z * Ket.one) + .one).magnitude < tolerance)
        #expect((Ket.plus† * z * Ket.plus).magnitude < tolerance)
    }

    /// Test that the Hadamard matrix is self-adjoint
    @Test func `Hadamard is its own adjoint`() {
        #expect(HadamardGate.matrix† == HadamardGate.matrix)
    }

    /// Test adjoint of a non-symmetric matrix with imaginary entries (Pauli-Y)
    @Test func `Adjoint conjugates and transposes entries`() {
        let y = Matrix([
            [.zero, Complex(0, -1)],
            [.i, .zero]
        ])
        let adjoint = y†
        #expect(adjoint[0, 1] == Complex(0, -1))
        #expect(adjoint[1, 0] == .i)
    }

    /// Test basis-label initializer places the amplitude at the right index
    @Test func `Ket from binary label is the matching basis state`() {
        let ket = Ket("10")
        #expect(ket.dimension == 4)
        for i in 0..<4 {
            let expected: Complex = (i == 2) ? .one : .zero
            #expect((ket[i] - expected).magnitude < tolerance)
        }
        #expect(((Bra("01") * Ket("01")) - .one).magnitude < tolerance)
    }

    /// Test ⟨a| ⊗ ⟨b| = (|a⟩ ⊗ |b⟩)†
    @Test func `Bra tensor product matches daggered ket tensor product`() {
        let lhs = Ket.plus† ⊗ Ket.one†
        let rhs = (Ket.plus ⊗ Ket.one)†
        #expect(lhs == rhs)
    }
}

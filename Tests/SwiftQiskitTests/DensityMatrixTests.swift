import Foundation
import Testing
@testable import SwiftQiskit

struct DensityMatrixTests {

    private let tolerance = 1e-8

    // MARK: - Purity & entropy of pure/mixed states

    @Test func `pure state has purity one and entropy zero`() {
        let rho = DensityMatrix(Ket.plus)
        #expect(abs(rho.purity - 1.0) < tolerance)
        #expect(abs(rho.vonNeumannEntropy - 0.0) < tolerance)
    }

    @Test func `an equal mixture of zero and one is maximally mixed`() {
        let rho = DensityMatrix(mixture: [(0.5, Ket.zero), (0.5, Ket.one)])
        #expect(abs(rho.purity - 0.5) < tolerance)
        #expect(abs(rho.vonNeumannEntropy - 1.0) < tolerance)
    }

    @Test func `a partially mixed state's entropy matches hand-computed eigenvalues`() {
        let rho = DensityMatrix(mixture: [(0.8, Ket.zero), (0.2, Ket.one)])

        let eigenvalues = rho.eigenvalues.sorted()
        #expect(eigenvalues.count == 2)
        #expect(abs(eigenvalues[0] - 0.2) < 1e-9)
        #expect(abs(eigenvalues[1] - 0.8) < 1e-9)

        let expectedEntropy = -(0.8 * log2(0.8) + 0.2 * log2(0.2))
        #expect(abs(rho.vonNeumannEntropy - expectedEntropy) < 1e-9)
    }

    // MARK: - Eigenvalues of a complex Hermitian matrix

    @Test func `eigenvalues of a complex 4x4 Hermitian density matrix match the known pure spectrum`() {
        // h;s;cx gives a Bell-like state with a genuinely complex amplitude (the `s`
        // puts an `i` on qubit 0), exercising the eigenvalue solver's complex embedding.
        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        circuit.s(0)
        circuit.cx(0, 1)
        let rho = DensityMatrix(circuit.run())

        #expect(abs(rho.purity - 1.0) < tolerance)

        let eigenvalues = rho.eigenvalues.sorted()
        #expect(eigenvalues.count == 4)
        #expect(abs(eigenvalues[0]) < tolerance)
        #expect(abs(eigenvalues[1]) < tolerance)
        #expect(abs(eigenvalues[2]) < tolerance)
        #expect(abs(eigenvalues[3] - 1.0) < tolerance)
    }

    // MARK: - Partial trace

    @Test func `Bell pair partial trace gives the maximally mixed marginal`() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        circuit.cx(0, 1)
        let rho = DensityMatrix(circuit.run())

        let reduced = rho.partialTrace(keeping: [0])
        #expect(abs(reduced.matrix[0, 0].real - 0.5) < tolerance)
        #expect(abs(reduced.matrix[1, 1].real - 0.5) < tolerance)
        #expect(reduced.matrix[0, 1].magnitude < tolerance)
        #expect(abs(reduced.purity - 0.5) < tolerance)
        #expect(abs(reduced.vonNeumannEntropy - 1.0) < tolerance)
    }

    @Test func `partial trace on a product state isolates each qubit and respects keep order`() {
        // |1⟩ ⊗ |+⟩ ⊗ |0⟩ — a product state, so every reduced state below is exactly pure.
        let circuit = QuantumCircuit(qubits: 3)
        circuit.x(0)
        circuit.h(1)
        let rho = DensityMatrix(circuit.run())

        let reducedQubit1 = rho.partialTrace(keeping: [1])
        let expectedPlus = DensityMatrix(Ket.plus)
        for i in 0..<2 {
            for j in 0..<2 {
                #expect((reducedQubit1.matrix[i, j] - expectedPlus.matrix[i, j]).magnitude < tolerance)
            }
        }

        // Keeping [2, 0] (in that order) puts qubit 2 (|0⟩) in the high-order bit and
        // qubit 0 (|1⟩) in the low-order bit of the reduced register — i.e. |01⟩ — not
        // the ascending-index order [0, 2] would give (|10⟩).
        let reducedReordered = rho.partialTrace(keeping: [2, 0])
        let expectedZeroOne = DensityMatrix(Ket("01"))
        for i in 0..<4 {
            for j in 0..<4 {
                #expect((reducedReordered.matrix[i, j] - expectedZeroOne.matrix[i, j]).magnitude < tolerance)
            }
        }
    }

    // MARK: - Bloch vector & fidelity, against StateVector.expectation

    @Test func `blochVector matches StateVector expectation for each Pauli`() {
        let circuit = QuantumCircuit(qubits: 1)
        circuit.ry(1.0, 0)
        circuit.rz(0.7, 0)
        let state = circuit.run()
        let rho = DensityMatrix(state)

        let bloch = rho.blochVector
        #expect(bloch != nil)
        #expect(abs(bloch!.x - state.expectation(PauliXGate.matrix)) < tolerance)
        #expect(abs(bloch!.y - state.expectation(PauliYGate.matrix)) < tolerance)
        #expect(abs(bloch!.z - state.expectation(PauliZGate.matrix)) < tolerance)
    }

    @Test func `blochVector is nil for a multi-qubit density matrix`() {
        let rho = DensityMatrix(StateVector(qubits: 2))
        #expect(rho.blochVector == nil)
    }

    @Test func `fidelity of a pure state's density matrix to itself is exactly one`() {
        let circuit = QuantumCircuit(qubits: 1)
        circuit.ry(1.0, 0)
        circuit.rz(0.7, 0)
        let state = circuit.run()
        let rho = DensityMatrix(state)

        #expect(abs(rho.fidelity(to: state) - 1.0) < tolerance)
    }

    @Test func `fidelity of the maximally mixed state to any pure state is one half`() {
        let rho = DensityMatrix(mixture: [(0.5, Ket.zero), (0.5, Ket.one)])
        #expect(abs(rho.fidelity(to: Ket.zero) - 0.5) < tolerance)
        #expect(abs(rho.fidelity(to: Ket.plus) - 0.5) < tolerance)
    }

    // MARK: - Applying a unitary

    @Test func `apply matches conjugating the underlying StateVector`() {
        let rho = DensityMatrix(Ket.zero)
        let evolved = rho.apply(HadamardGate.matrix)
        let expected = DensityMatrix(StateVector.plus)
        for i in 0..<2 {
            for j in 0..<2 {
                #expect((evolved.matrix[i, j] - expected.matrix[i, j]).magnitude < tolerance)
            }
        }
    }
}

import Foundation
import Testing
@testable import SwiftQiskit

struct ToffoliTests {

    /// Test that the general factory reproduces the fixed 3-qubit matrix
    @Test func `General matrix matches fixed three-qubit Toffoli`() {
        #expect(ToffoliGate.matrix(qubits: 3, control1: 0, control2: 1, target: 2) == ToffoliGate.matrix)
    }

    /// Test the full 8-row truth table: target flips only when both controls are 1
    @Test func `Truth table flips target only when both controls are 1`() {
        let m = ToffoliGate.matrix

        for a in 0...1 {
            for b in 0...1 {
                for c in 0...1 {
                    var state = Ket("\(a)\(b)\(c)")
                    state.apply(m)

                    let expectedC = (a == 1 && b == 1) ? 1 - c : c
                    #expect(state == Ket("\(a)\(b)\(expectedC)"))
                }
            }
        }
    }

    /// Test that a 4-qubit Toffoli (non-adjacent controls/target) is unitary and self-inverse
    @Test func `Four-qubit Toffoli is unitary and self-inverse`() {
        let m = ToffoliGate.matrix(qubits: 4, control1: 3, control2: 0, target: 1)
        let identity = Matrix.identity(size: 16)

        #expect(m.isUnitary())
        #expect(m * m == identity)
    }

    /// Test that swapping the two controls produces the same matrix
    @Test func `Symmetric in its two controls`() {
        let a = ToffoliGate.matrix(qubits: 4, control1: 3, control2: 0, target: 1)
        let b = ToffoliGate.matrix(qubits: 4, control1: 0, control2: 3, target: 1)
        #expect(a == b)
    }

    /// Test the circuit-level `ccx` method against the raw matrix
    @Test func `Circuit ccx matches the matrix`() {
        let circuit = QuantumCircuit(qubits: 3)
        circuit.x(0)
        circuit.x(1)
        circuit.ccx(0, 1, 2)

        let state = circuit.run()
        #expect(state == Ket("111"))
    }
}

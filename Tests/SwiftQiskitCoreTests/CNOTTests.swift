import Foundation
import Testing
@testable import SwiftQiskitCore

struct CNOTTests {

    private let tolerance = 1e-10

    /// Test that the general factory reproduces the original 2-qubit matrix
    @Test func `General matrix matches fixed two-qubit CNOT`() {
        #expect(CNOTGate.matrix(qubits: 2, control: 0, target: 1) == CNOTGate.matrix)
    }

    /// Test that a 3-qubit CNOT is unitary and self-inverse
    @Test func `Three-qubit CNOT is unitary and self-inverse`() {
        let m = CNOTGate.matrix(qubits: 3, control: 1, target: 2)
        let identity = Matrix.identity(size: 8)

        #expect(m.adjoint * m == identity)
        #expect(m * m == identity)
    }

    /// Test the reverse CNOT cx(1, 0): control = qubit 1 (LSB), target = qubit 0 (MSB)
    @Test func `Reverse CNOT flips most-significant qubit`() {
        let m = CNOTGate.matrix(qubits: 2, control: 1, target: 0)

        var state = Ket("01")
        state.apply(m)
        #expect(state == Ket("11"))

        var fixed = Ket("10")
        fixed.apply(m)
        #expect(fixed == Ket("10"))
    }

    /// Test the identity (H⊗H) · CX(0,1) · (H⊗H) = CX(1,0)
    @Test func `Hadamard conjugation swaps control and target`() {
        let hh = HadamardGate.matrix ⊗ HadamardGate.matrix
        let conjugated = hh * CNOTGate.matrix(qubits: 2, control: 0, target: 1) * hh
        let reversed = CNOTGate.matrix(qubits: 2, control: 1, target: 0)

        for i in 0..<4 {
            for j in 0..<4 {
                #expect((conjugated[i, j] - reversed[i, j]).magnitude < tolerance)
            }
        }
    }

    /// Test a CNOT between non-adjacent qubits on a 3-qubit register
    @Test func `CNOT acts across non-adjacent qubits`() {
        let m = CNOTGate.matrix(qubits: 3, control: 0, target: 2)

        var state = Ket("100")
        state.apply(m)
        #expect(state == Ket("101"))

        var other = Ket("110")
        other.apply(m)
        #expect(other == Ket("111"))
    }

    /// Test that h(0); cx(0,1); cx(1,2) produces the 3-qubit GHZ state
    @Test func `Chained CNOTs build GHZ state`() {
        let qc = QuantumCircuit(qubits: 3)
        qc.h(0)
        qc.cx(0, 1)
        qc.cx(1, 2)

        let state = qc.run()
        let amplitude = 1.0 / sqrt(2.0)

        for i in 0..<state.dimension {
            let expected = (i == 0 || i == 7) ? amplitude : 0.0
            #expect((state[i] - Complex(expected)).magnitude < tolerance)
        }
    }

    /// Test GHZ measurement statistics: only 000 and 111, each near 50%
    @Test func `GHZ measurement yields only all-zeros and all-ones`() {
        let qc = QuantumCircuit(qubits: 3)
        qc.h(0)
        qc.cx(0, 1)
        qc.cx(1, 2)

        let shots = 1000
        let result = qc.measure(shots: shots)

        #expect(result.counts.keys.allSatisfy { $0 == "000" || $0 == "111" })

        let zeros = result.counts["000", default: 0]
        let ones = result.counts["111", default: 0]
        #expect(zeros + ones == shots)
        #expect(zeros > 400 && zeros < 600)
        #expect(ones > 400 && ones < 600)
    }
}

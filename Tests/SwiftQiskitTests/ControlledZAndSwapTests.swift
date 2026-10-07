import Foundation
import Testing
@testable import SwiftQiskit

struct ControlledZAndSwapTests {

    private let tolerance = 1e-12

    /// A generic, entangling-free preparation so every basis state has a distinct amplitude.
    private func prepared(_ qubits: Int) -> QuantumCircuit {
        let circuit = QuantumCircuit(qubits: qubits)
        for q in 0..<qubits {
            circuit.h(q)
            circuit.rz(0.3 + 0.4 * Double(q), q)
        }
        return circuit
    }

    private func expectEqual(_ a: QuantumCircuit, _ b: QuantumCircuit) {
        let x = a.run()
        let y = b.run()
        #expect(x.dimension == y.dimension)
        for i in 0..<x.dimension {
            #expect((x[i] - y[i]).magnitude < tolerance)
        }
    }

    @Test func `CZ equals H CX H on non-adjacent qubits`() {
        let a = prepared(3)
        a.cz(0, 2)
        let b = prepared(3)
        b.h(2); b.cx(0, 2); b.h(2)
        expectEqual(a, b)
    }

    @Test func `CZ is symmetric in its two qubits`() {
        #expect(ControlledZGate.matrix(qubits: 3, control: 0, target: 2)
                == ControlledZGate.matrix(qubits: 3, control: 2, target: 0))
    }

    @Test func `General CZ matrix matches the fixed two-qubit matrix`() {
        #expect(ControlledZGate.matrix(qubits: 2, control: 0, target: 1) == ControlledZGate.matrix)
    }

    @Test func `MCZ with one control equals CZ`() {
        let a = prepared(3)
        a.mcz([2], 0)
        let b = prepared(3)
        b.cz(2, 0)
        expectEqual(a, b)
    }

    @Test func `MCZ with two controls equals H CCX H`() {
        let a = prepared(4)
        a.mcz([0, 3], 1)
        let b = prepared(4)
        b.h(1); b.ccx(0, 3, 1); b.h(1)
        expectEqual(a, b)
    }

    @Test func `MCZ with no controls equals Z`() {
        let a = prepared(2)
        a.mcz([], 1)
        let b = prepared(2)
        b.z(1)
        expectEqual(a, b)
    }

    @Test func `SWAP equals three CNOTs on non-adjacent qubits`() {
        let a = prepared(3)
        a.swap(0, 2)
        let b = prepared(3)
        b.cx(0, 2); b.cx(2, 0); b.cx(0, 2)
        expectEqual(a, b)
    }

    @Test func `SWAP moves an excitation`() {
        let circuit = QuantumCircuit(qubits: 3)
        circuit.x(0)
        circuit.swap(0, 2)
        #expect(circuit.run() == Ket("001"))
    }

    @Test func `New gate matrices are unitary`() {
        #expect(ControlledZGate.matrix.isUnitary())
        #expect(MultiControlledZGate.matrix(qubits: 4, controls: [0, 2, 3], target: 1).isUnitary())
        #expect(SwapGate.matrix(qubits: 4, q0: 3, q1: 0).isUnitary())
        #expect(SwapGate.matrix == SwapGate.matrix(qubits: 2, q0: 1, q1: 0))
    }

    @Test func `Tensor network contraction matches run`() {
        let circuit = prepared(4)
        circuit.cz(0, 3)
        circuit.mcz([1, 3], 0)
        circuit.swap(1, 2)
        let expected = circuit.run()
        let contracted = TensorNetwork(circuit).contract()
        for i in 0..<expected.dimension {
            #expect((expected[i] - contracted[i]).magnitude < tolerance)
        }
    }
}

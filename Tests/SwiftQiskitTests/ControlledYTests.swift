import Foundation
import Testing
@testable import SwiftQiskit

struct ControlledYTests {

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

    @Test func `CY equals S-dagger CX S on non-adjacent qubits`() {
        let a = prepared(3)
        a.cy(0, 2)
        let b = prepared(3)
        b.sdg(2); b.cx(0, 2); b.s(2)
        expectEqual(a, b)
    }

    @Test func `CY with reversed qubit order equals S-dagger CX S`() {
        let a = prepared(3)
        a.cy(2, 0)
        let b = prepared(3)
        b.sdg(0); b.cx(2, 0); b.s(0)
        expectEqual(a, b)
    }

    @Test func `General CY matrix matches the fixed two-qubit matrix`() {
        #expect(ControlledYGate.matrix(qubits: 2, control: 0, target: 1) == ControlledYGate.matrix)
    }

    @Test func `MCY with no controls equals Y`() {
        let a = prepared(2)
        a.mcy([], 1)
        let b = prepared(2)
        b.y(1)
        expectEqual(a, b)
    }

    @Test func `MCY with one control equals CY`() {
        let a = prepared(3)
        a.mcy([2], 0)
        let b = prepared(3)
        b.cy(2, 0)
        expectEqual(a, b)
    }

    @Test func `MCY with two controls equals S-dagger CCX S`() {
        let a = prepared(4)
        a.mcy([0, 3], 1)
        let b = prepared(4)
        b.sdg(1); b.ccx(0, 3, 1); b.s(1)
        expectEqual(a, b)
    }

    @Test func `CY on a set control gives i times the flipped state`() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.x(0)
        circuit.cy(0, 1)
        let state = circuit.run()
        #expect((state[3] - Complex(0, 1)).magnitude < tolerance)
    }

    @Test func `CY matrices are unitary`() {
        #expect(ControlledYGate.matrix.isUnitary())
        #expect(MultiControlledYGate.matrix(qubits: 4, controls: [0, 2, 3], target: 1).isUnitary())
    }

    @Test func `Tensor network contraction matches run`() {
        let circuit = prepared(4)
        circuit.cy(0, 3)
        circuit.mcy([1, 3], 0)
        let expected = circuit.run()
        let contracted = TensorNetwork(circuit).contract()
        for i in 0..<expected.dimension {
            #expect((expected[i] - contracted[i]).magnitude < tolerance)
        }
    }
}

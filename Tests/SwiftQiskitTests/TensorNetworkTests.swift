import Foundation
import Testing
@testable import SwiftQiskit

struct TensorNetworkTests {

    private let tolerance = 1e-10

    // MARK: - Structure

    @Test func `Bell circuit has the expected node and edge counts`() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        circuit.cx(0, 1)

        let network = TensorNetwork(circuit)

        // 2 input + h + cx + 2 output
        #expect(network.nodes.count == 6)
        // h: 1 edge, cx: 2 edges, 2 outputs: 2 edges
        #expect(network.edges.count == 5)
    }

    @Test func `GHZ with a non-adjacent cx has the expected node and edge counts`() {
        let circuit = QuantumCircuit(qubits: 3)
        circuit.h(0)
        circuit.cx(0, 1)
        circuit.cx(0, 2)

        let network = TensorNetwork(circuit)

        // 3 input + h + cx + cx + 3 output
        #expect(network.nodes.count == 9)
        // h: 1, first cx: 2, second cx: 2, 3 outputs: 3
        #expect(network.edges.count == 8)
    }

    @Test func `rzz unfolds into exactly cx, rz, cx`() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.rzz(0.7, 0, 1)

        let network = TensorNetwork(circuit)
        let gateNames = network.nodes.compactMap { node -> String? in
            guard case .gate(let name) = node.kind else { return nil }
            return name
        }

        #expect(gateNames == ["CX", "RZ(0.700)", "CX"])
        // 2 input + 3 gates + 2 output
        #expect(network.nodes.count == 7)
        #expect(network.edges.count == 7)
    }

    @Test func `A 2-qubit QFT ladder built from p and cx has the expected node and edge counts`() {
        func cp(_ theta: Double, control: Int, target: Int, on circuit: QuantumCircuit) {
            circuit.p(theta / 2, control)
            circuit.cx(control, target)
            circuit.p(-theta / 2, target)
            circuit.cx(control, target)
            circuit.p(theta / 2, target)
        }

        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        cp(.pi / 2, control: 0, target: 1, on: circuit)
        circuit.h(1)

        let network = TensorNetwork(circuit)

        // 2 input + (h, p, cx, p, cx, p, h) + 2 output
        #expect(network.nodes.count == 11)
        // gate leg counts 1+1+2+1+2+1+1 = 9, plus 2 output edges
        #expect(network.edges.count == 11)
    }

    @Test func `Gates on disjoint qubits share a layout column`() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        circuit.h(1)

        let network = TensorNetwork(circuit)
        let gateColumns = network.nodes.compactMap { node -> Int? in
            guard case .gate = node.kind else { return nil }
            return node.column
        }

        #expect(gateColumns.count == 2)
        #expect(gateColumns[0] == gateColumns[1])
    }

    @Test func `Every gate tensor is unitary`() {
        let circuit = QuantumCircuit(qubits: 3)
        circuit.h(0)
        circuit.x(1)
        circuit.cx(0, 1)
        circuit.ccx(0, 1, 2)
        circuit.mcx([0, 1], 2)
        circuit.p(0.7, 0)
        circuit.rx(0.3, 1)
        circuit.rzz(0.5, 0, 2)
        circuit.pauliRotation("III", theta: 1.0) // global phase node

        let network = TensorNetwork(circuit)
        for node in network.nodes {
            guard case .gate = node.kind else { continue }
            #expect(node.tensor.isUnitary())
        }
    }

    // MARK: - Contraction matches `run()`

    private func assertContractionMatchesRun(_ circuit: QuantumCircuit) {
        let expected = circuit.run()
        let contracted = TensorNetwork(circuit).contract()

        #expect(expected.dimension == contracted.dimension)
        for i in 0..<expected.dimension {
            #expect((expected[i] - contracted[i]).magnitude < tolerance)
        }
    }

    @Test func `contract matches run for a Bell pair`() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        circuit.cx(0, 1)
        assertContractionMatchesRun(circuit)
    }

    @Test func `contract matches run for a GHZ state with a non-adjacent cx`() {
        let circuit = QuantumCircuit(qubits: 3)
        circuit.h(0)
        circuit.cx(0, 1)
        circuit.cx(0, 2)
        assertContractionMatchesRun(circuit)
    }

    @Test func `contract matches run for a mixed gate set`() {
        let circuit = QuantumCircuit(qubits: 3)
        circuit.p(0.4, 0)
        circuit.rx(0.6, 1)
        circuit.ry(1.1, 2)
        circuit.rz(0.2, 0)
        circuit.s(1)
        circuit.t(2)
        circuit.ccx(0, 1, 2)
        circuit.mcx([0, 2], 1)
        circuit.rzz(0.3, 0, 2)
        assertContractionMatchesRun(circuit)
    }

    @Test func `contract matches run for an all-identity global phase`() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.pauliRotation("II", theta: 0.9)
        assertContractionMatchesRun(circuit)
    }

    @Test func `contract matches run for a raw apply(_:)`() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.apply(CNOTGate.matrix(qubits: 2, control: 0, target: 1))
        assertContractionMatchesRun(circuit)
    }
}

import Foundation
import Testing
@testable import SwiftQiskit
@testable import SwiftQiskitViews

struct TensorNetworkViewTests {

    @Test("instantiates for a Bell-pair network")
    func instantiation() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        circuit.cx(0, 1)

        let network = TensorNetwork(circuit)
        let view = TensorNetworkView(network, title: "smoke test")
        _ = view.body
    }

    @Test("instantiates for a network with a global-phase node")
    func instantiationWithPhaseNode() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.pauliRotation("II", theta: 0.9)

        let network = TensorNetwork(circuit)
        let view = TensorNetworkView(network, title: "phase smoke test")
        _ = view.body
    }
}

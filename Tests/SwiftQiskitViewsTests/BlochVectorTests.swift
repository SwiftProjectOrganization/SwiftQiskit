import Foundation
import Testing
import SwiftQiskit
@testable import SwiftQiskitViews

struct BlochVectorTests {

    private func expectClose(_ a: Double, _ b: Double, tolerance: Double = 1e-9) {
        #expect(abs(a - b) < tolerance)
    }

    // MARK: - Single-qubit pure state

    @Test("empty circuit stays at |0⟩")
    func zeroState() {
        let circuit = QuantumCircuit(qubits: 1)
        let bloch = BlochVector(circuit.run())
        expectClose(bloch.x, 0)
        expectClose(bloch.y, 0)
        expectClose(bloch.z, 1)
    }

    @Test("H rotates |0⟩ to |+⟩")
    func hadamard() {
        let circuit = QuantumCircuit(qubits: 1)
        circuit.h(0)
        let bloch = BlochVector(circuit.run())
        expectClose(bloch.x, 1)
        expectClose(bloch.y, 0)
        expectClose(bloch.z, 0)
    }

    @Test("H then S rotates |+⟩ to |+i⟩")
    func hadamardThenS() {
        let circuit = QuantumCircuit(qubits: 1)
        circuit.h(0)
        circuit.s(0)
        let bloch = BlochVector(circuit.run())
        expectClose(bloch.x, 0)
        expectClose(bloch.y, 1)
        expectClose(bloch.z, 0)
    }

    @Test("X flips |0⟩ to |1⟩")
    func pauliX() {
        let circuit = QuantumCircuit(qubits: 1)
        circuit.x(0)
        let bloch = BlochVector(circuit.run())
        expectClose(bloch.x, 0)
        expectClose(bloch.y, 0)
        expectClose(bloch.z, -1)
        expectClose(bloch.theta, Double.pi)
    }

    // MARK: - Reduced (partial-trace) qubit of a multi-qubit pure state

    @Test("Bell state collapses both qubits' reduced vectors to the origin")
    func bellStateIsMaximallyEntangled() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        circuit.cx(0, 1)
        let state = circuit.run()

        for qubit in 0..<2 {
            let bloch = BlochVector(state, qubit: qubit)
            expectClose(bloch.x, 0)
            expectClose(bloch.y, 0)
            expectClose(bloch.z, 0)
            expectClose(bloch.magnitude, 0)
        }
    }

    @Test("H on q0 only leaves q1 untouched")
    func reducedVectorIsolatesQubits() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        let state = circuit.run()

        let q0 = BlochVector(state, qubit: 0)
        expectClose(q0.x, 1)
        expectClose(q0.y, 0)
        expectClose(q0.z, 0)

        let q1 = BlochVector(state, qubit: 1)
        expectClose(q1.x, 0)
        expectClose(q1.y, 0)
        expectClose(q1.z, 1)
    }

    @Test("reduced init on a 1-qubit state agrees with the plain init")
    func reducedInitAgreesOnOneQubit() {
        let circuit = QuantumCircuit(qubits: 1)
        circuit.h(0)
        circuit.s(0)
        let state = circuit.run()

        let plain = BlochVector(state)
        let reduced = BlochVector(state, qubit: 0)
        expectClose(plain.x, reduced.x)
        expectClose(plain.y, reduced.y)
        expectClose(plain.z, reduced.z)
    }

    // MARK: - DensityMatrix-driven initializers

    @Test("DensityMatrix init agrees with the pure-state init")
    func densityMatrixInitAgreesWithPureState() {
        let circuit = QuantumCircuit(qubits: 1)
        circuit.h(0)
        circuit.s(0)
        let state = circuit.run()

        let fromState = BlochVector(state)
        let rho = DensityMatrix(state)
        let fromRho = BlochVector(rho)
        #expect(fromRho != nil)
        expectClose(fromState.x, fromRho!.x)
        expectClose(fromState.y, fromRho!.y)
        expectClose(fromState.z, fromRho!.z)
    }

    @Test("DensityMatrix init is nil for more than one qubit")
    func densityMatrixInitNilForMultiQubit() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        circuit.cx(0, 1)
        let rho = DensityMatrix(circuit.run())
        #expect(BlochVector(rho) == nil)
    }

    @Test("reduced DensityMatrix init agrees with reduced StateVector init")
    func reducedDensityMatrixInitAgreesWithReducedStateVector() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        let state = circuit.run()
        let rho = DensityMatrix(state)

        for qubit in 0..<2 {
            let fromState = BlochVector(state, qubit: qubit)
            let fromRho = BlochVector(rho, qubit: qubit)
            expectClose(fromState.x, fromRho.x)
            expectClose(fromState.y, fromRho.y)
            expectClose(fromState.z, fromRho.z)
        }
    }

    @Test("reduced DensityMatrix init gives |r| < 1 for a Bell pair")
    func reducedDensityMatrixInitIsMixedForBellPair() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        circuit.cx(0, 1)
        let rho = DensityMatrix(circuit.run())

        let bloch = BlochVector(rho, qubit: 0)
        expectClose(bloch.magnitude, 0)
    }

    // MARK: - Raw coordinates

    @Test("raw init round-trips theta/phi")
    func rawInit() {
        let bloch = BlochVector(x: 1, y: 0, z: 0)
        expectClose(bloch.theta, Double.pi / 2)
        expectClose(bloch.phi, 0)
        expectClose(bloch.magnitude, 1)
    }
}

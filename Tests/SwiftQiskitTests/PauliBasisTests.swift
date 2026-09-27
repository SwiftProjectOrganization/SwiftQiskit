import Foundation
import Testing
@testable import SwiftQiskit

struct PauliBasisTests {

    private let tolerance = 1e-9

    /// Entrywise comparison of two state vectors within tolerance (as in
    /// `AdditionalGatesTests`'s helper of the same name) — needed because composing several
    /// gates (`h`, `s`, `x`) accumulates floating-point noise that makes exact `==` too
    /// strict.
    private func approxEqual(_ a: StateVector, _ b: StateVector) -> Bool {
        guard a.dimension == b.dimension else { return false }
        for i in 0..<a.dimension {
            if (a[i] - b[i]).magnitude >= tolerance { return false }
        }
        return true
    }

    // MARK: - rotateToZ maps eigenstates onto the Z basis

    @Test func `rotateToZ maps plus to zero for the X basis`() {
        let circuit = QuantumCircuit(qubits: 1)
        circuit.h(0)                 // prepare |+⟩
        circuit.rotateToZ(.x, 0)
        #expect(approxEqual(circuit.run(), Ket.zero))
    }

    @Test func `rotateToZ maps minus to one for the X basis`() {
        let circuit = QuantumCircuit(qubits: 1)
        circuit.x(0)
        circuit.h(0)                 // prepare |−⟩
        circuit.rotateToZ(.x, 0)
        #expect(approxEqual(circuit.run(), Ket.one))
    }

    @Test func `rotateToZ maps plus-i to zero for the Y basis`() {
        let circuit = QuantumCircuit(qubits: 1)
        circuit.h(0)
        circuit.s(0)                 // prepare |+i⟩
        circuit.rotateToZ(.y, 0)
        #expect(approxEqual(circuit.run(), Ket.zero))
    }

    @Test func `rotateToZ maps minus-i to one for the Y basis`() {
        let circuit = QuantumCircuit(qubits: 1)
        circuit.x(0)
        circuit.h(0)
        circuit.s(0)                 // prepare |−i⟩
        circuit.rotateToZ(.y, 0)
        #expect(approxEqual(circuit.run(), Ket.one))
    }

    @Test func `rotateToZ is a no-op for the Z basis`() {
        let circuit = QuantumCircuit(qubits: 1)
        circuit.x(0)                 // prepare |1⟩
        circuit.rotateToZ(.z, 0)
        #expect(circuit.run() == Ket.one)
    }

    // MARK: - measure(shots:basis:)

    @Test func `Measuring plus in the X basis is deterministic`() {
        let circuit = QuantumCircuit(qubits: 1)
        circuit.h(0)                 // prepare |+⟩
        let result = circuit.measure(shots: 50, basis: [.x])
        #expect(result.counts == ["0": 50])
    }

    @Test func `measure(shots:basis:) does not mutate the circuit`() {
        let circuit = QuantumCircuit(qubits: 1)
        circuit.h(0)
        let before = circuit.run()
        _ = circuit.measure(shots: 10, basis: [.x])
        let after = circuit.run()
        #expect(before == after)
    }

    // MARK: - Combined with parityExpectation

    @Test func `Bell pair XX parity from basis measurement is close to plus one`() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        circuit.cx(0, 1)

        let result = circuit.measure(shots: 1000, basis: [.x, .x])
        let xx = result.parityExpectation(qubits: [0, 1])
        #expect(abs(xx - 1.0) < 0.1)
    }

    @Test func `Bell pair YY parity from basis measurement is close to minus one`() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        circuit.cx(0, 1)

        let result = circuit.measure(shots: 1000, basis: [.y, .y])
        let yy = result.parityExpectation(qubits: [0, 1])
        #expect(abs(yy - (-1.0)) < 0.1)
    }
}

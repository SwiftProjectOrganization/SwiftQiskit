import Foundation
import Testing
@testable import SwiftQiskit

struct ReadoutTests {

    private let tolerance = 1e-10

    // MARK: - StateVector.marginalProbabilities

    /// Test that a Bell pair's single-qubit marginal is exactly 50/50
    @Test func `Bell pair marginal over one qubit is 50-50`() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        circuit.cx(0, 1)
        let state = circuit.run()

        let marginal = state.marginalProbabilities(over: [0])
        #expect(abs(marginal["0"]! - 0.5) < tolerance)
        #expect(abs(marginal["1"]! - 0.5) < tolerance)
    }

    /// Test that selecting every qubit reproduces the full probability distribution
    @Test func `Marginal over every qubit matches full probabilities`() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        circuit.cx(0, 1)
        let state = circuit.run()

        let marginal = state.marginalProbabilities(over: [0, 1])
        let probs = state.probabilities
        #expect(abs(marginal["00"]! - probs[0]) < tolerance)
        #expect(abs(marginal["01"]! - probs[1]) < tolerance)
        #expect(abs(marginal["10"]! - probs[2]) < tolerance)
        #expect(abs(marginal["11"]! - probs[3]) < tolerance)
    }

    /// Test that the marginal key order follows the argument order, not ascending index
    @Test func `Marginal key order follows the argument`() {
        let state = Ket("01")
        let marginal = state.marginalProbabilities(over: [1, 0])
        #expect(abs(marginal["10"]! - 1.0) < tolerance)
    }

    /// Test that zero-probability keys are present in the result
    @Test func `Zero-probability keys are present`() {
        let state = Ket("00")
        let marginal = state.marginalProbabilities(over: [0, 1])
        #expect(marginal.count == 4)
        #expect(marginal["01"] == 0.0)
        #expect(marginal["10"] == 0.0)
        #expect(marginal["11"] == 0.0)
    }

    // MARK: - SimulationResult.marginalCounts

    /// Test that marginalCounts sums correctly over a subset of qubits
    @Test func `marginalCounts sums correctly`() {
        let result = SimulationResult(shots: 100, counts: [
            "00": 40, "01": 10, "10": 5, "11": 45
        ])

        let marginal = result.marginalCounts(over: [0])
        #expect(marginal["0"] == 50)
        #expect(marginal["1"] == 50)
    }

    // MARK: - SimulationResult.parityExpectation

    /// Test parity +1 when the selected bits always agree
    @Test func `Parity expectation is plus one for perfectly correlated counts`() {
        let result = SimulationResult(shots: 100, counts: ["00": 50, "11": 50])
        #expect(abs(result.parityExpectation(qubits: [0, 1]) - 1.0) < tolerance)
    }

    /// Test parity -1 when the selected bits always disagree
    @Test func `Parity expectation is minus one for perfectly anti-correlated counts`() {
        let result = SimulationResult(shots: 100, counts: ["01": 50, "10": 50])
        #expect(abs(result.parityExpectation(qubits: [0, 1]) - (-1.0)) < tolerance)
    }

    /// Test parity 0 for a uniform split across all four outcomes
    @Test func `Parity expectation is zero for a uniform split`() {
        let result = SimulationResult(shots: 100, counts: ["00": 25, "01": 25, "10": 25, "11": 25])
        #expect(abs(result.parityExpectation(qubits: [0, 1])) < tolerance)
    }

    // MARK: - Statistical checks via measure(shots:)

    /// Test that a Bell pair's ⟨ZZ⟩ estimated from shots is close to the exact value of +1
    @Test func `Bell pair ZZ parity from shots is close to one`() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        circuit.cx(0, 1)
        let result = circuit.measure(shots: 1000)

        let zz = result.parityExpectation(qubits: [0, 1])
        #expect(abs(zz - 1.0) < 0.1)
    }

    /// Test that an independent product state's ⟨ZZ⟩ estimated from shots is close to zero
    @Test func `Product state ZZ parity from shots is close to zero`() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        circuit.h(1)
        let result = circuit.measure(shots: 1000)

        let zz = result.parityExpectation(qubits: [0, 1])
        #expect(abs(zz) < 0.15)
    }
}

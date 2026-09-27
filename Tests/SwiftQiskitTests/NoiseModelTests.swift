import Foundation
import Testing
@testable import SwiftQiskit

struct NoiseModelTests {

    private let tolerance = 1e-8

    // MARK: - No noise reduces to the exact density matrix

    @Test func `runDensityMatrix with no noise model matches DensityMatrix of run()`() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        circuit.cx(0, 1)

        let exact = DensityMatrix(circuit.run())
        let simulated = circuit.runDensityMatrix()

        for i in 0..<4 {
            for j in 0..<4 {
                #expect((exact.matrix[i, j] - simulated.matrix[i, j]).magnitude < tolerance)
            }
        }
    }

    // MARK: - Single-qubit noise lands on exactly the gate's qubit

    @Test func `bit-flip noise after x gives P(1) = 1 - p exactly`() {
        let p = 0.2
        let circuit = QuantumCircuit(qubits: 1)
        circuit.x(0)

        let noise = NoiseModel(singleQubitGate: KrausChannel.bitFlip(p))
        let rho = circuit.runDensityMatrix(noise: noise)

        #expect(abs(rho.probabilities[0] - p) < tolerance)
        #expect(abs(rho.probabilities[1] - (1 - p)) < tolerance)
    }

    // MARK: - Multi-qubit noise lands on every qubit a multi-qubit gate touched

    @Test func `bit-flip noise on the multi-qubit channel hits both qubits a cx touches`() {
        let p = 0.3
        let circuit = QuantumCircuit(qubits: 2)
        circuit.cx(0, 1) // both qubits start at |0⟩, so cx alone is a no-op on |00⟩

        let noise = NoiseModel(multiQubitGate: KrausChannel.bitFlip(p))
        let probabilities = circuit.runDensityMatrix(noise: noise).probabilities

        // Each of the two qubits independently flips with probability p:
        // P(00) = (1-p)², P(11) = p², P(01) = P(10) = p(1-p).
        #expect(abs(probabilities[0] - (1 - p) * (1 - p)) < tolerance)
        #expect(abs(probabilities[1] - p * (1 - p)) < tolerance)
        #expect(abs(probabilities[2] - p * (1 - p)) < tolerance)
        #expect(abs(probabilities[3] - p * p) < tolerance)
    }

    // MARK: - Trajectories converge to the exact density matrix

    @Test func `runTrajectories converges to runDensityMatrix within shot noise`() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        circuit.cx(0, 1)

        let noise = NoiseModel.uniform(KrausChannel.depolarizing(0.1))
        let exact = circuit.runDensityMatrix(noise: noise).probabilities
        let sampled = circuit.runTrajectories(noise: noise, shots: 20_000)

        for (index, probability) in exact.enumerated() {
            let binary = String(index, radix: 2).leftPadding(toLength: circuit.qubits, withPad: "0")
            let observed = Double(sampled.counts[binary] ?? 0) / Double(sampled.shots)
            #expect(abs(observed - probability) < 0.02)
        }
    }
}

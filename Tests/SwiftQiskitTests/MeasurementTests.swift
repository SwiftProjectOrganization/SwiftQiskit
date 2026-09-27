import Foundation
import Testing
@testable import SwiftQiskit

/// Coverage for `QuantumCircuit.measure(shots:)` after it moved from replaying every
/// recorded operation per shot to running the circuit once and sampling the resulting
/// probability distribution `shots` times.
struct MeasurementTests {

    @Test func `Deterministic circuit measures the same outcome every shot`() {
        let qc = QuantumCircuit(qubits: 1)
        qc.x(0)

        let shots = 200
        let result = qc.measure(shots: shots)

        #expect(result.counts["1"] == shots)
        #expect(result.counts["0", default: 0] == 0)
    }

    @Test func `Hadamard circuit measures roughly half and half`() {
        let qc = QuantumCircuit(qubits: 1)
        qc.h(0)

        let shots = 1000
        let result = qc.measure(shots: shots)

        let zeros = result.counts["0", default: 0]
        let ones = result.counts["1", default: 0]
        #expect(zeros + ones == shots)
        #expect(zeros > 400 && zeros < 600)
        #expect(ones > 400 && ones < 600)
    }

    @Test func `Shot counts track the exact run probabilities`() {
        let theta = 2.0 * .pi / 5.0
        let qc = QuantumCircuit(qubits: 1)
        qc.ry(theta, 0)

        let exactProbabilities = qc.run().probabilities
        let shots = 20_000
        let result = qc.measure(shots: shots)

        let observedZero = Double(result.counts["0", default: 0]) / Double(shots)
        let observedOne = Double(result.counts["1", default: 0]) / Double(shots)

        #expect(abs(observedZero - exactProbabilities[0]) < 0.02)
        #expect(abs(observedOne - exactProbabilities[1]) < 0.02)
    }

    /// `measure(shots:)` now samples one `run()`'s distribution `shots` times, instead of
    /// calling `runAndMeasure()` (which replays every operation) once per shot. Both should be
    /// statistically indistinguishable from the exact probabilities for a full measurement of
    /// a pure state — this pins that regression down numerically.
    @Test func `Sampling once matches replaying per shot within statistical tolerance`() {
        let theta = 0.9
        let qc = QuantumCircuit(qubits: 1)
        qc.rx(theta, 0)

        let exactProbabilities = qc.run().probabilities
        let shots = 20_000

        let sampledOnce = qc.measure(shots: shots)
        let sampledOnceZero = Double(sampledOnce.counts["0", default: 0]) / Double(shots)

        var replayedZero = 0
        for _ in 0..<shots {
            if qc.runAndMeasure() == 0 { replayedZero += 1 }
        }
        let replayedZeroFraction = Double(replayedZero) / Double(shots)

        #expect(abs(sampledOnceZero - exactProbabilities[0]) < 0.02)
        #expect(abs(replayedZeroFraction - exactProbabilities[0]) < 0.02)
    }
}

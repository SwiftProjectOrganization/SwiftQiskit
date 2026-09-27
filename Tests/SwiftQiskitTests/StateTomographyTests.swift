import Foundation
import Testing
@testable import SwiftQiskit

struct StateTomographyTests {

    // MARK: - estimate(qubit:result:)

    @Test func `estimate reads N0 minus N1 over N from hand-built counts`() {
        let result = SimulationResult(shots: 10, counts: ["0": 7, "1": 3])
        let e = StateTomography.estimate(qubit: 0, result: result)
        #expect(abs(e - 0.4) < 1e-9)
    }

    // MARK: - estimateBlochVector against a known pure state

    @Test func `estimateBlochVector converges to the exact Pauli expectations of a pure state`() {
        let circuit = QuantumCircuit(qubits: 1)
        circuit.ry(1.0, 0)
        circuit.rz(0.7, 0)
        let exact = circuit.run()

        let exactX = exact.expectation(PauliXGate.matrix)
        let exactY = exact.expectation(PauliYGate.matrix)
        let exactZ = exact.expectation(PauliZGate.matrix)

        let estimated = StateTomography.estimateBlochVector(of: circuit, qubit: 0, shots: 50_000)

        #expect(abs(estimated.x - exactX) < 0.02)
        #expect(abs(estimated.y - exactY) < 0.02)
        #expect(abs(estimated.z - exactZ) < 0.02)
    }

    @Test func `estimateBlochVector does not mutate the receiver`() {
        let circuit = QuantumCircuit(qubits: 1)
        circuit.ry(1.0, 0)
        let before = circuit.run()
        _ = StateTomography.estimateBlochVector(of: circuit, qubit: 0, shots: 500)
        let after = circuit.run()

        #expect((before[0] - after[0]).magnitude < 1e-9)
        #expect((before[1] - after[1]).magnitude < 1e-9)
    }

    // MARK: - A genuinely mixed marginal (Bell pair, qubit 0)

    @Test func `Bell pair qubit 0 marginal reconstructs near the origin and is physical`() {
        let circuit = QuantumCircuit(qubits: 2)
        circuit.h(0)
        circuit.cx(0, 1)

        let estimated = StateTomography.estimateBlochVector(of: circuit, qubit: 0, shots: 50_000)
        #expect(abs(estimated.x) < 0.05)
        #expect(abs(estimated.y) < 0.05)
        #expect(abs(estimated.z) < 0.05)

        let reconstructed = StateTomography.reconstructSingleQubit(x: estimated.x, y: estimated.y, z: estimated.z)
        #expect(reconstructed.isPhysical)
    }

    // MARK: - Physicality and clamping

    @Test func `reconstructSingleQubit flags an out-of-ball vector as unphysical`() {
        let reconstructed = StateTomography.reconstructSingleQubit(x: 0.8, y: 0.8, z: 0.0)
        #expect(!reconstructed.isPhysical)
    }

    @Test func `clampToPhysical rescales an out-of-ball vector onto the unit sphere`() {
        let v = (x: 0.8, y: 0.8, z: 0.0)
        let clamped = StateTomography.clampToPhysical(v)
        let magnitude = sqrt(clamped.x * clamped.x + clamped.y * clamped.y + clamped.z * clamped.z)

        #expect(abs(magnitude - 1.0) < 1e-9)
        // Direction preserved: clamped is a positive scalar multiple of v.
        #expect(abs(clamped.x / clamped.y - v.x / v.y) < 1e-9)
    }

    @Test func `clampToPhysical leaves an already-physical vector unchanged`() {
        let v = (x: 0.3, y: 0.0, z: 0.4)
        let clamped = StateTomography.clampToPhysical(v)

        #expect(abs(clamped.x - v.x) < 1e-9)
        #expect(abs(clamped.y - v.y) < 1e-9)
        #expect(abs(clamped.z - v.z) < 1e-9)
    }
}
